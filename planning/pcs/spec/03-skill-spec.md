# 03 — Skill Spec

Version: 0.1 | Status: Draft

A skill is a single-purpose, agent-agnostic, versioned capability.
The crisp test: if two different agents would do this identically,
it's a skill. If the agent's role changes the approach, it's a runbook.

---

## Fields

Ten fields. Each tied to a binding principle. Every field passes the
three-part litmus test.

| Field | Type | Required | Principle | Description |
|-------|------|----------|-----------|-------------|
| `name` | string | Yes | Identity | `^[a-z][a-z0-9_-]*$`. Must match filename. |
| `version` | string | Yes | P3 (lifecycle) | Semver: `^\d+\.\d+\.\d+$` |
| `owner` | string | Yes | P2 (ownership) | Maintainer of record. Non-empty. |
| `lifecycle_state` | enum | Yes | P3 (deprecation) | `draft` \| `active` \| `deprecated` |
| `trust_tier` | enum | Yes | P4 (tiered trust) | `experimental` \| `community` \| `blessed` \| `core` |
| `effect` | enum | Yes | P7 (side-effect) | `pure` \| `mutate_local` \| `mutate_external` |
| `is_idempotent` | boolean | Conditional | P7 (side-effect) | Required when `effect != pure`. See below. |
| `requires_capabilities` | list[string] | No | P6 (symmetry) | What the execution context must provide. |
| `inputs` | object | No | P5 (stateless) | JSON Schema for the skill's input contract. |
| `outputs` | object | No | P5 (stateless) | JSON Schema for the skill's output contract. |
| `acknowledged_external_risk` | boolean | Conditional | P7 (side-effect) | Required `true` when `effect: mutate_external` and `trust_tier: experimental`. See 06-lifecycle.md (rationale), 07-gates.md (enforcement). |

---

## Idempotency Constraint (Option C)

The `is_idempotent` field uses a constrained-hybrid model:

| Effect | `is_idempotent` Rule |
|--------|---------------------|
| `pure` | Defaults to `true`. Cannot be set to `false`. A pure skill is always idempotent by definition. |
| `mutate_local` | Must be explicitly declared (`true` or `false`). No default. |
| `mutate_external` | Must be explicitly declared (`true` or `false`). No default. |

**Rationale:** "May be safe if idempotent" is a hint to a human, not a
machine-actionable directive. The control plane needs an explicit
boolean to decide retry safety. Forcing explicit declaration where it
matters prevents the failure mode where a non-idempotent
`mutate_local` skill silently corrupts state on retry.

---

## Naming Rules

- `name` must match `^[a-z][a-z0-9_-]*$`
- Filename (without `.yaml` extension) must be **byte-identical** to
  the `name` field. Not "equivalent" — identical. `grid-decode.yaml`
  must contain `name: grid-decode`. `grid_decode.yaml` with
  `name: grid-decode` is a validation error.
- Both filenames and name fields use the same regex. Hyphens and
  underscores are both legal in both.
- The control plane validates this match at registration.

---

## Example

```yaml
name: grid-decode
version: "0.1.0"
owner: ki7mt
lifecycle_state: active
trust_tier: blessed
effect: pure
requires_capabilities: []
inputs:
  type: object
  properties:
    grid:
      type: string
      pattern: "^[A-R]{2}[0-9]{2}([a-x]{2})?$"
  required:
    - grid
outputs:
  type: object
  properties:
    latitude:
      type: number
    longitude:
      type: number
    precision:
      type: string
      enum: [field, square, subsquare]
  required:
    - latitude
    - longitude
    - precision
```

---

## What the Control Plane Validates

| Check | Rule |
|-------|------|
| Required fields present | `name`, `version`, `owner`, `lifecycle_state`, `trust_tier`, `effect` |
| Name matches filename | `name` field == filename without extension |
| Name matches pattern | `^[a-z][a-z0-9_-]*$` |
| Version is semver | `^\d+\.\d+\.\d+$` |
| Owner non-empty | `min_length: 1` |
| Lifecycle state valid | One of `draft`, `active`, `deprecated` |
| Trust tier valid | One of `experimental`, `community`, `blessed`, `core` |
| Effect valid | One of `pure`, `mutate_local`, `mutate_external` |
| Idempotency constraint | Option C rules (see above) |
| Inputs/outputs schema | Valid JSON Schema if provided |
| External risk acknowledgment | `mutate_external + experimental` requires `acknowledged_external_risk: true` |

**Note on `acknowledged_external_risk`:** This field secures
accountability, not code execution. It does not prevent a deceptive
author from registering risky skills — it creates a durable audit
record of the author's explicit acceptance of the risk. The defense
isn't "stop the bad code from existing"; it's "ensure no one can
pretend they didn't know." The boolean is an auditable declaration
of intent, not a physical lock.
