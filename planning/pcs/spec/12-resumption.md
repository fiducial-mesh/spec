# 12 — Resumption Semantics

Version: 0.2 | Status: Draft

Agents stop responding mid-runbook. This is not an edge case — it is
the normal failure mode at scale. Causes include context compaction
(graceful degradation), safety filter termination (forced), platform
crashes, network drops, and OOM kills. From the framework's
perspective, **agent unavailability is agent unavailability**
regardless of cause.

PCS v0.1 handles voluntary hand-off (08-failure-modes.md). This
document extends the framework to handle **involuntary termination**
— where the agent dies without executing the hand-off protocol.

---

## The Key Insight

Resumption and retry are the same architectural problem viewed from
different angles:

| Failure Type | Question |
|-------------|----------|
| Retry (skill failed, run again) | Is it safe to repeat this operation? |
| Resume (agent died, fresh agent picks up) | Is it safe to repeat this operation when we don't even know if it completed? |

**Resumption is retry-with-amnesia.** The same `is_idempotent`
primitive from the Skill Spec (03) determines safety. Resumption is
strictly harder because state is uncertain.

This means PCS already has the right foundation. Resumption builds
on top of `is_idempotent` and the Mutation Profile rather than being
a separate system.

---

## Three States on Resumption

When a fresh agent inherits a runbook, each step is in one of three
states:

| Step State | Evidence | Action |
|-----------|----------|--------|
| **Definitely completed** | Audit log shows success outcome | Skip, advance to next step |
| **Definitely not started** | No audit entry for this step | Execute normally |
| **Uncertain** | Attempt logged, no completion record | Depends on mutation profile + idempotency |

The third state — uncertain — is where the framework earns its keep.

---

## Resumption Safety by Mutation Profile

| Effect | `is_idempotent` | Resumption Strategy |
|--------|-----------------|-------------------|
| `pure` | (always true) | Re-run blindly. Safe by definition. |
| `mutate_local` | `true` | Re-run safely; may need cleanup of partial local state |
| `mutate_local` | `false` | Query local state before retry; cannot blindly re-run |
| `mutate_external` | `true` | Re-run safely (server-side idempotency key) |
| `mutate_external` | `false` | **Cannot blindly retry. Must verify actual external state or hand off to human.** |

The last row is the danger zone. PyPI publish, LoTW upload, database
INSERT without unique constraint — non-idempotent external mutations
cannot be safely re-run without verifying actual completion.

---

## Verification Skill

Non-idempotent `mutate_external` skills SHOULD declare a paired
verification skill:

```yaml
name: lotw-upload
version: "0.1.0"
owner: watson
effect: mutate_external
is_idempotent: false
verification_skill: check-lotw-submission     # NEW field
```

The `verification_skill` is a `pure` skill that checks whether the
operation actually completed. It takes the same inputs as the original
skill and returns a boolean: done or not done.

```yaml
name: check-lotw-submission
version: "0.1.0"
owner: watson
effect: pure
inputs:
  type: object
  properties:
    station_callsign:
      type: string
    submission_date:
      type: string
outputs:
  type: object
  properties:
    state:
      type: string
      enum: [done, not_done, pending_propagation, cannot_determine]
    confirmation_id:
      type: string
```

### Verification Timing

External state changes asynchronously after a write. PyPI publish
takes seconds to propagate. LoTW confirmation might take hours. A
verification skill running immediately after the mutation might see
`pending_propagation` rather than `done`.

Verification skills SHOULD return one of four states:

| State | Meaning | Control Plane Action |
|-------|---------|---------------------|
| `done` | Operation confirmed complete | Skip, advance |
| `not_done` | Operation confirmed not executed | Execute |
| `pending_propagation` | Operation may have executed, not yet visible | Wait and retry verification |
| `cannot_determine` | State unknown, verification inconclusive | Hand off to human |

The `pending_propagation` state prevents the dangerous case where
a verification skill returns `not_done` for an operation that
completed but hasn't propagated, causing a duplicate execution.

---

## Control Plane Resumption Logic

When a fresh agent resumes a runbook:

```
For each step in the runbook:
  1. Check audit log: was this step completed?
     → YES: skip, advance to next step
     → NO (no entry): execute normally
     → UNCERTAIN (attempt logged, no completion):
        a. Is the skill pure? → re-run blindly
        b. Is the skill idempotent? → re-run safely
        c. Does the skill have a verification_skill?
           → invoke verification_skill
           → if "done": skip
           → if "not done": execute
           → if "cannot determine": hand off to human
        d. None of the above? → hand off to human
```

This logic composes cleanly with existing v0.1 primitives. It adds
one field (`verification_skill`) and one execution path (the
resumption decision tree above).

---

## How a Fresh Agent Discovers It Should Resume

When an agent starts and finds a runbook with:
- An audit trail showing partial completion
- No completion record for the overall runbook
- The previous agent's session no longer active

The control plane presents the resumption context:

- Runbook name and version
- Which steps completed (from audit log)
- Which step is uncertain (if any)
- The running mutation state (worst-mutation-so-far)
- Whether verification is available for uncertain steps

The fresh agent doesn't need to understand the history. It needs to
understand the current state — which is exactly what the audit log
and the resumption decision tree provide.

---

## Design Discipline for Skill Authors

| Rule | Why |
|------|-----|
| Prefer `pure` where possible | Trivially resumable |
| Prefer idempotent mutations | Use upserts, idempotency keys, conditional writes |
| For non-idempotent `mutate_external`, pair with `verification_skill` | Resumption can query actual state |
| Externalize completion markers | Don't rely on "agent remembers it ran" — write to audit log or external state |
| Design for hand-off as default | Involuntary termination is the common case at scale |

---

## Cross-Platform Implications

PCS teams may operate across multiple platforms — different model
providers, different hardware substrates, different runtime
configurations. Each platform has its own involuntary termination
failure modes (safety filters, context limits, network drops,
resource exhaustion).

The framework is agnostic about *why* an agent stopped. Audit log +
runbook state + the verification skill pattern must be sufficient for
any fresh agent on any platform to resume. The agent's identity and
platform are irrelevant to resumption — only the audit trail and the
mutation state matter.

---

## What the Control Plane Validates

| Check | Rule |
|-------|------|
| `verification_skill` exists | If declared, must resolve to a registered `pure` skill |
| `verification_skill` inputs compatible | Must accept the same inputs as the primary skill (or a subset) |
| Non-idempotent `mutate_external` without `verification_skill` | Warning — resumption requires human hand-off for uncertain state |
| Resumption state derivable from audit | Audit log must contain step-level records (not just runbook-level) |

---

## Relationship to Existing Spec

| Spec Document | What Resumption Adds |
|--------------|---------------------|
| 03 — Skill Spec | `verification_skill` field (optional) |
| 04 — Runbook Spec | Step-level audit requirement for resumption |
| 08 — Failure Modes | Involuntary termination as a first-class failure mode |
| 09 — Audit | Step-level completion records (not just invocation records) |
