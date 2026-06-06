# 04 — Runbook Spec

Version: 0.1 | Status: Draft

A runbook is orchestration: multiple skills composed in order, with
judgment points where the agent's role changes the approach.

The crisp test: if two different agents would do this identically,
it's a skill. If the agent's role matters, it's a runbook.

---

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | `^[a-z][a-z0-9_-]*$`. Must match filename. |
| `version` | string | Yes | Semver. |
| `owner` | string | Yes | Maintainer of record. |
| `lifecycle_state` | enum | Yes | `draft` \| `active` \| `deprecated` |
| `trust_tier` | enum | Yes | `experimental` \| `community` \| `blessed` \| `core` |
| `on_failure` | enum | No | Default failure handling. See 08-failure-modes.md. |
| `steps` | list | Yes | Ordered steps. At least one required. |
| `requires_capabilities` | list[string] | No | Orchestration-layer capabilities (see Capability Resolution below). |

---

## Capability Resolution

A runbook's effective capability requirements are the **additive union**
of all composed skill requirements plus the runbook's own
`requires_capabilities`:

```
effective = union(skill.requires_capabilities for each skill step)
           ∪ runbook.requires_capabilities
```

The runbook's `requires_capabilities` field is for capabilities the
**orchestration itself** needs beyond what individual skills declare.
For example, a runbook that uses an inbox for judgment steps may need
`inbox_read` even though no individual skill does.

Runbook authors do NOT need to re-enumerate skill requirements — each
skill knows its own. The control plane computes the union automatically
during pre-flight checks (see 07-gates.md).

---

## Steps

Each step is either a **skill invocation** or a **judgment point**.

### Skill Step

```yaml
- kind: skill
  skill_name: solar-brief       # Required. References a skill by name.
  skill_version: "0.1.0"        # Required. Exact version match (no ranges).
  required: true                 # Optional. Default: true.
```

### Judgment Step

```yaml
- kind: judgment
  description: "Go/no-go for upload"
  decision_field: upload_approved     # optional: named boolean the agent produces
  on_negative: hand_off               # optional: what happens if decision is false
  audit_required: true                # optional: whether reasoning must be logged
```

Judgment steps are where the agent applies role-specific reasoning.
They are the only place judgment exists in orchestration (Principle 5).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | Yes | What the agent should evaluate |
| `decision_field` | string | No | Name of the boolean the agent must produce (e.g., `upload_approved`) |
| `on_negative` | enum | No | Action when decision is false: `skip_next` \| `abort` \| `hand_off` \| `report`. Default: `report`. |
| `audit_required` | boolean | No | Whether the agent must log reasoning. Default: `false`. |

**Decision flow:** If `decision_field` is declared, the agent must
produce a boolean. If `true`, the runbook continues. If `false`, the
`on_negative` action fires. If `decision_field` is not declared, the
judgment step is advisory — the agent may log observations but the
runbook always continues.

**Judgment failure:** A judgment step can fail (agent declines, times
out, or produces an error). The runbook's `on_failure` mode applies.
If the judgment step is `required: true` and fails, the runbook stops.
If `required: false`, the runbook continues.

**Audit:** When `audit_required: true`, the control plane must record
the agent's reasoning in the audit log. The audit record includes the
`decision_field` value and any explanation the agent provided.

---

## Inherited Properties

A runbook inherits two properties from its composed skills. The control
plane computes both automatically — the runbook author declares their
own values, but the effective values may be stricter.

### Effective Mutation Profile

```
effective_effect = max(effect of each skill step)
```

Where: `pure < mutate_local < mutate_external`

The runbook does not declare its own `effect`. The effective mutation
profile is derived entirely from composed skills.

### Effective Trust Tier

```
effective_trust_tier = max(declared_trust_tier,
                          max(skill.trust_tier for each composed skill))
```

Where: `experimental < community < blessed < core`

The runbook's declared `trust_tier` is a floor, not a ceiling. If a
`blessed` runbook composes an `experimental` skill, the effective tier
is `experimental` — the agent needs at least `experimental` access, and
the runbook itself is considered `experimental` for promotion purposes.

This prevents trust-tier bypass by composition: an agent with
`max_trust_tier: blessed` cannot invoke a runbook that composes skills
they wouldn't have access to individually.

---

## Abort Legality

Abort legality tracks through execution. Once a `mutate_external` skill
has executed, abort is illegal for the rest of the runbook — regardless
of what subsequent steps do.

| State After Step | Abort Legal? |
|-----------------|-------------|
| Only `pure` skills executed | Yes |
| `mutate_local` executed | Yes (with cleanup) |
| `mutate_external` executed | **No** — escalate to `hand_off` |

The control plane tracks this as a running state during execution. The
spec declares the constraint; the control plane validates attempts.

---

## Version Pinning

`skill_version` requires exact match. Semver range syntax (e.g.,
`^1.0.0`, `>=1.0.0 <2.0.0`) is not supported in v0.1. When a
skill ships a patch (`1.0.0 → 1.0.1`), the runbook must be updated
to reference the new version explicitly. This is the safe default —
semver ranges may be considered in a future version.

---

## Cross-Reference Validation

The control plane validates that every skill referenced in a runbook's
steps exists:
- `skill_name` must match a registered skill in the same project
- `skill_version` must match the registered skill's version
- Missing references are validation errors

---

## Example

```yaml
name: post-contest
version: "1.0.0"
owner: watson
lifecycle_state: active
trust_tier: core
on_failure: hand_off
steps:
  - kind: skill
    skill_name: export-adif
    skill_version: "1.0.0"
    required: true
  - kind: skill
    skill_name: validate-adif
    skill_version: "1.0.0"
    required: true
  - kind: judgment
    description: "Review ADIF. Confirm QSO count. Go/no-go for upload."
    decision_field: upload_approved
    on_negative: hand_off
    audit_required: true
  - kind: skill
    skill_name: lotw-upload
    skill_version: "0.1.0"
    required: true
  - kind: judgment
    description: "Verify LoTW accepted submission. Report rejected records."
```
