# 07 — Validation Gates

Version: 0.1 | Status: Draft

Gates are checkpoints where the control plane validates a candidate
against the spec. The spec declares what is checked. The control plane
executes the check. Gates never decide — they only report pass/fail
against declared rules.

---

## Gate Types

| Gate | When It Fires | What It Checks |
|------|--------------|----------------|
| **Registration** | When a skill/runbook is added to a project | Schema conformance, naming rules, filename match |
| **Pre-Execution** | Before a skill or runbook runs | Capability handshake, trust tier, lifecycle state |
| **Post-Execution** | After a skill or runbook completes | Output shape (if declared), audit record emission |
| **Pre-Promotion** | Before trust tier changes | Promotion requirements met (review count, test results) |
| **Pre-Compilation** | Before generating platform artifacts | All referenced skills exist, cross-references resolve |

---

## Registration Gate

Fires when a new skill or runbook YAML is added to a project.

| Check | Rule | Severity |
|-------|------|----------|
| Schema valid | All required fields present, correct types | Error — blocks registration |
| Name matches filename | `name` field == filename without extension | Error — blocks registration |
| Name matches pattern | `^[a-z][a-z0-9_-]*$` | Error — blocks registration |
| Version is semver | `^\d+\.\d+\.\d+$` | Error — blocks registration |
| Owner non-empty | `min_length: 1` | Error — blocks registration |
| Effect valid | One of `pure`, `mutate_local`, `mutate_external` | Error — blocks registration |
| Idempotency constraint | Option C rules (see 03-skill-spec.md) | Error — blocks registration |
| Inputs/outputs valid | Valid JSON Schema if provided | Warning — logged but not blocking |
| Mutation × tier risk | `mutate_external + experimental` requires `acknowledged_external_risk: true` | Error — blocks registration without acknowledgment |
| Draft tier coupling | `lifecycle_state: draft` requires `trust_tier: experimental` | Error — blocks registration |

---

## Pre-Execution Gate

Fires before the control plane allows a skill or runbook to execute.

| Check | Rule | Severity |
|-------|------|----------|
| Lifecycle active | `lifecycle_state != draft` | Error — blocks execution |
| Deprecation warning | `lifecycle_state == deprecated` | Warning — logged, execution continues |
| Sunset block | `sunset_at` is past | Error — blocks execution |
| Trust tier permitted | `skill.trust_tier ≤ agent.max_trust_tier` | Error — blocks execution |
| Capabilities satisfied | `skill.requires_capabilities ⊆ profile.all_capabilities` | Error — blocks execution, reports missing capabilities with source attribution (see below) |
| Pre-flight (runbooks) | All skill steps satisfiable | Error — blocks execution, reports first failure |

---

### Capability Failure Attribution

When a capability check fails, the control plane must report not just
*which capability* is missing but *which profile component* should have
provided it. Different root causes require different remediations:

| Missing From | Meaning | Remediation |
|-------------|---------|-------------|
| Node Profile | Hardware/runtime not available on this node | Install dependency or route to a different node |
| Agent Profile | Authority not granted to this agent | Request authority grant from operator |
| Project Context | Wrong project scope for this work | Switch project context |

The control plane determines attribution by checking each profile
component individually against the missing capability.

---

## Post-Execution Gate

Fires after a skill or runbook completes.

| Check | Rule | Severity |
|-------|------|----------|
| Output shape | If `outputs` schema declared, result matches schema | Warning — logged |
| Audit record | Invocation logged with required fields | Error — must succeed |
| Abort legality | If runbook aborted, check mutation state | Error — reject illegal abort, escalate |

---

## Pre-Promotion Gate

Fires when the CI/publish pipeline attempts to change a skill's
trust tier.

| Transition | Required Evidence |
|-----------|------------------|
| `experimental → community` | All registration checks pass. At least 1 peer review on record. |
| `community → blessed` | All registration checks pass. At least 2 cross-reviews. Operator sign-off on record. All declared tests pass. |
| `blessed → core` | All above. Security audit on record. Failure analysis review on record. |
| Any → `deprecated` | Migration plan provided for `core` tier. Consumer notification for `blessed` and `core`. |

The spec declares what evidence is required. The CI pipeline collects
the evidence. The control plane validates that the evidence exists.

---

## Pre-Compilation Gate

Fires before a compiler generates platform artifacts.

| Check | Rule | Severity |
|-------|------|----------|
| All skills exist | Every skill referenced by runbooks exists in the project | Error — blocks compilation |
| Cross-references resolve | Runbook `skill_name` + `skill_version` matches a registered skill | Error — blocks compilation |
| Body files present | Each skill has a matching body file | Warning — compiler generates default body |
| Plugin manifest valid | `plugin.yaml` exists and validates | Error — blocks compilation |

---

## Gate Interaction with Failure Modes

When a gate check fails, the behavior depends on the failure mode
declared in the skill or runbook's `on_failure` field (see
08-failure-modes.md).

| Gate Result | `report` | `ask_operator` | `retry` | `abort` | `hand_off` |
|------------|---------|---------------|--------|--------|-----------|
| Registration error | Block + log | Block + log | Block + log | Block + log | Block + log |
| Pre-execution error | Log + skip | Send to inbox | N/A | Block + log | Route to target |
| Post-execution warning | Log | Log | Log | Log | Log |
| Promotion error | Block | Block + notify | N/A | Block | Block |

Registration and promotion errors always block regardless of failure
mode — you can't register an invalid spec or promote without evidence.
`retry` is not applicable to registration or promotion gates.
