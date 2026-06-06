# 08 — Failure Modes & Mutation Profile

Version: 0.1 | Status: Draft

Every skill declares its side-effect profile. The control plane uses
this to enforce failure-mode constraints. The spec declares what's
legal; the control plane validates and rejects illegal attempts.

---

## Effect Classification (Mutation Profile)

Every skill declares one of exactly three effect states:

| Effect | Meaning | Recovery |
|--------|---------|----------|
| `pure` | Read-only, deterministic | Safe to retry infinitely, safe to abort anytime |
| `mutate_local` | Changes local disk/state only | Abort requires cleanup; retry depends on `is_idempotent` |
| `mutate_external` | Writes to external systems | Abort is **illegal** after execution |

### Why Three, Not More

More granularity (`mutate_filesystem`, `mutate_database`,
`mutate_network`) adds decisions without changing recovery semantics.
The three-way split captures the real semantic boundaries:
**idempotent | recoverable | unrecoverable-by-agent**.

### Why This Lives in the Spec, Not the Control Plane

Effect classification is a property of the skill — it travels with
the skill wherever it's deployed. The control plane uses it to make
policy decisions but doesn't define it.

---

## Idempotency

The `is_idempotent` field (Option C, constrained hybrid) tells the
control plane whether retry is safe.

| Effect | `is_idempotent` Rule |
|--------|---------------------|
| `pure` | Always `true`. Cannot be `false`. |
| `mutate_local` | Must be explicitly declared. |
| `mutate_external` | Must be explicitly declared. |

**What the control plane does with this:**
- `is_idempotent: true` → retry is permitted
- `is_idempotent: false` → retry is forbidden; control plane rejects
  retry attempts

---

## Failure Modes

Skills and runbooks declare a default failure handling mode via
`on_failure`:

| Mode | Behavior | When to Use |
|------|----------|-------------|
| `report` | Log failure, return error summary, continue | Non-critical skills (briefings, status checks) |
| `ask_operator` | Send `action` message to operator inbox, block | Human judgment needed |
| `retry` | Retry up to N times with backoff, then escalate | Transient failures (timeout, rate limit) |
| `abort` | Stop execution, log, notify operator | Critical path failure |
| `hand_off` | Route to specific agent or role. State and authority transfer per Hand-Off Semantics below. | Needs different expertise; required after mutate_external failure |

---

## Abort Legality

Abort legality depends on what has already executed in a runbook:

| State After Execution | `abort` Legal? | `retry` Legal? |
|----------------------|---------------|----------------|
| Only `pure` skills executed | Yes | Yes |
| `mutate_local` executed, `is_idempotent: true` | Yes (with cleanup) | Yes |
| `mutate_local` executed, `is_idempotent: false` | Yes (with cleanup) | **No** |
| `mutate_external` executed | **No** — must use `hand_off` | Depends on `is_idempotent` |

**The critical constraint:** Once a `mutate_external` skill has
executed, abort is illegal. The control plane validates abort attempts
against the running mutation state and rejects illegal ones, escalating
to `hand_off`.

This is the constraint that justifies the entire Mutation Profile. A
control plane that allows `abort` after a PyPI publish or a LoTW upload
is doing something wrong — and without the Mutation Profile, it has no
way to know that.

---

## Hand-Off Semantics

`hand_off` is the only legal escalation after a `mutate_external` skill
has executed. The spec defines what hand_off means structurally.

### Target Declaration

Skills and runbooks may declare a hand-off target:

```yaml
on_failure: hand_off
handoff_to: judge              # or a role name, or "auto"
```

| Value | Meaning |
|-------|---------|
| Agent name (e.g., `judge`) | Route directly to this agent |
| Role name (e.g., `operator`) | Route to whoever fills this role |
| `auto` | Control plane determines target from execution profile |
| Not specified | Defaults to `auto` |

### State Semantics

When hand_off fires, the control plane MUST:

1. **Pause the runbook** — not kill it. Execution state is preserved.
2. **Transfer the execution context** to the target: runbook name,
   failed step index, error description, and running mutation state
   (worst-mutation-so-far). The receiving agent inherits the same
   abort constraints.
3. **Transfer authority** — the receiving agent inherits authority to
   complete the runbook from the failed step onward.

The spec declares *what state must be transferred*. The mechanism
(message queue, webhook, database flag, file drop, exit code) is an
implementation choice for the control plane. Different implementations
may use different transports; all must satisfy the state-transfer
requirement.

### Resumption

The receiving agent may:
- **Resume** — continue from the failed step
- **Retry the failed step** — if `is_idempotent: true` for that step
- **Skip the failed step** — if `required: false`
- **Abort** — only if no `mutate_external` steps have executed (same
  constraint applies to the receiving agent)

### Why This Matters

In the abort-illegal-after-mutate_external case, `hand_off` is the
**only legal escalation**. Without clear semantics, every implementer
would define it differently and runbook behavior becomes non-portable.

---

## Runbook Failure Semantics

A runbook's failure handling interacts with its composed skills:

1. **All-pure runbook** — any failure mode is legal at any point
2. **Runbook with `mutate_local` steps** — abort requires cleanup of
   local state; retry is safe only if the failed step is idempotent
3. **Runbook with `mutate_external` steps** — once that step executes,
   the runbook's failure mode is constrained: only `hand_off` and
   `report` are legal; `abort` is rejected by the control plane

The control plane tracks the "worst mutation so far" as running state
and applies constraints accordingly.

**Formal ordering:** `pure < mutate_local < mutate_external`.
"Worst mutation so far" is the maximum over all executed steps using
this ordering. Within `mutate_local`, `is_idempotent: false` is
treated as stricter than `is_idempotent: true` for retry decisions
(retry is forbidden if any executed `mutate_local` step has
`is_idempotent: false`).
