# 06 — Lifecycle & Trust Tiers

Version: 0.1 | Status: Draft

Every skill and runbook has a lifecycle state and a trust tier. Both
are schema fields declared by the author and validated by the control
plane.

---

## Lifecycle States

```
draft ──► active ──► deprecated
```

| State | Meaning | Constraints |
|-------|---------|-------------|
| `draft` | Work in progress. Not ready for use. | May not be invoked in production. Must have `trust_tier: experimental`. |
| `active` | Ready for use. | Normal operation. |
| `deprecated` | Superseded or retiring. | Still callable. Control plane emits a warning + logs deprecation notice on every invocation. |

### Lifecycle × Trust Tier Coupling

`lifecycle_state` and `trust_tier` are orthogonal axes with one
coupling rule:

- `lifecycle_state: draft` forces `trust_tier: experimental`.
  The control plane rejects any other combination at registration.
- Promotion beyond `experimental` requires `lifecycle_state: active`.
- Deprecation (`lifecycle_state: deprecated`) is permitted at any
  trust tier — a `core` skill can be deprecated (with migration plan).

This keeps the model clean: two independent fields, one coupling rule
that prevents nonsensical states like `draft + blessed`.

### Deprecation Fields (on deprecated skills)

When `lifecycle_state: deprecated`, the following optional fields
provide migration guidance:

| Field | Type | Description |
|-------|------|-------------|
| `deprecated_at` | date string | When deprecation was declared |
| `sunset_at` | date string | When the skill will be removed |
| `migration` | string | What to use instead |

```yaml
lifecycle_state: deprecated
deprecated_at: "2026-06-01"
sunset_at: "2026-07-01"
migration: "Use solar-brief@2.0.0 instead"
```

The control plane:
- Warns on every invocation of a deprecated skill
- Blocks invocation after `sunset_at` if provided
- Includes `migration` text in the warning

---

## Trust Tiers

```
experimental ──► community ──► blessed ──► core
```

| Tier | Meaning | Who Can Invoke | Requirements to Enter |
|------|---------|----------------|----------------------|
| `experimental` | Untested, personal, WIP | Author only (or agents with `max_trust_tier: experimental`) | Author creates it |
| `community` | Works, shared, not fully audited | Agents with `max_trust_tier ≥ community` | Peer review (1 reviewer) |
| `blessed` | Reviewed, tested, approved | Agents with `max_trust_tier ≥ blessed` | Cross-review + operator sign-off |
| `core` | Load-bearing, non-negotiable | Agents with `max_trust_tier ≥ core` | Full audit (security + failure analysis) |

### Tier Enforcement

The control plane enforces tier access via the execution profile:

```
skill.trust_tier ≤ agent.max_trust_tier
```

The tier ordering is: `experimental < community < blessed < core`.
An agent with `max_trust_tier: community` cannot invoke a `blessed`
skill.

### Promotion

Promotion from one tier to the next is a state mutation — it changes
the `trust_tier` field in the skill spec. Promotion is NOT handled by
the three core PCS components (they are read/check/serve only). State
mutation lives in the CI/publish pipeline.

The spec defines **what is required** for promotion. The CI pipeline
implements the gate.

| Transition | Requirements |
|-----------|-------------|
| `experimental → community` | Passes all control plane validation checks. At least one peer review. |
| `community → blessed` | Cross-review (two reviewers). Operator sign-off. All declared validation gates pass (see 07-gates.md, Registration + Pre-Execution). |
| `blessed → core` | Full security audit. Failure analysis review. Cannot deprecate without migration plan. |

### Demotion and Deprecation

- Any tier can transition to `deprecated` (lifecycle state change, not tier change)
- `core` skills cannot be deprecated without a migration plan and consumer notification
- Demotion (lowering trust tier) is permitted but should be accompanied by a CLCA cycle documenting why

---

## Interaction: Mutation Profile × Trust Tier

A `mutate_external` skill at `experimental` tier can write to external
systems before it's been reviewed. This is enforced at **registration**
(not at promotion review — that's too late).

**Rule (soft block):** The registration gate warns on
`effect: mutate_external` combined with `trust_tier: experimental`.
Registration succeeds only if the author explicitly acknowledges the
risk by including `acknowledged_external_risk: true` in the skill spec.
Without acknowledgment, registration is rejected.

This forces the author to confront the risk, leaves an audit trail,
and doesn't hard-block legitimate early-stage code that does mutate
external state.

The control plane enforces this check. See 07-gates.md, Registration
Gate. See 08-failure-modes.md for the abort constraints that apply
once a `mutate_external` skill executes.
