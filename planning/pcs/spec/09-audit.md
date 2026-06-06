# 09 — Audit & CLCA

Version: 0.1 | Status: Draft

Principle 1: every action is auditable. Principle 9: PCS itself is
governed by CLCA. This document defines what gets logged and how
defects are handled.

---

## Audit Requirements

Every skill and runbook invocation produces an audit record. This is
a control plane responsibility — the spec declares the required fields;
the control plane emits and stores them.

### Required Audit Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique record identifier |
| `timestamp` | ISO 8601 | When the invocation started |
| `agent` | string | Who invoked it |
| `kind` | enum | `skill` or `runbook` |
| `name` | string | Skill/runbook name |
| `version` | string | Skill/runbook version |
| `project` | string | Project context at invocation time |
| `node` | string | Node where execution occurred |
| `result` | enum | `success` \| `failure` \| `aborted` \| `handed_off` |
| `duration_ms` | integer | Execution time in milliseconds |
| `gates_evaluated` | list | Which gates were checked and their verdicts |
| `inputs_summary` | string | Truncated representation of inputs (no secrets) |
| `output_summary` | string | Truncated representation of output |

### Optional Audit Fields

| Field | Type | Description |
|-------|------|-------------|
| `data_versions` | object | Versions of MCP servers, models, or datasets used |
| `error` | string | Error message if `result != success` |
| `mutation_state` | string | Worst mutation at time of completion |
| `escalation` | object | Where the work was handed off, if applicable |

### Audit Storage

The spec does not prescribe a storage backend. The control plane
chooses its own (SQLite, Postgres, flat files, etc.). The spec only
requires:

1. Audit records are durable (survive process restart)
2. Audit records are queryable (by agent, name, date range, result)
3. Audit records include all required fields
4. No secrets in audit records (credentials, API keys, tokens)
5. Retention is implementation-defined. Production deployments should
   consider regulatory and operational requirements.

---

## Step-Level Audit (v0.2)

For resumption semantics (12-resumption.md), the audit log must
include **step-level records** for runbook execution, not just
runbook-level records.

Each step in a runbook produces its own audit entry with:

| Field | Description |
|-------|-------------|
| `runbook_id` | The parent runbook's audit record ID |
| `step_index` | Position in the runbook's step list |
| `step_kind` | `skill` or `judgment` |
| `step_name` | Skill name (for skill steps) or description hash (for judgment) |
| `result` | `success` \| `failure` \| `skipped` \| `uncertain` |

The `uncertain` result state indicates the step was attempted but
the agent terminated before recording completion. This is the state
that triggers the resumption decision tree in 12-resumption.md.

Without step-level audit, the resumption logic cannot determine
which steps completed and which are uncertain.

---

## CLCA Process

CLCA (Closed-Loop Corrective Action) is the methodology PCS uses to
evolve. Every structural defect — in the spec, in the control plane,
in the registry, or in published plugins — triggers a CLCA cycle.

### CLCA Cycle Structure

| Step | Description |
|------|-------------|
| **Identify** | What is the defect? Concrete reproduction. |
| **Measure** | How severe? What's the blast radius? |
| **Isolate** | What variable caused it? Root cause. |
| **Correct** | Fix the defect. |
| **Verify** | Confirm the fix holds. Independent verification. |
| **Prevent** | What prevents recurrence? Update the spec, add a test, add a gate. |

### CLCA Records

Each CLCA cycle produces a record with:

| Field | Type | Description |
|-------|------|-------------|
| `cycle_id` | string | Sequential identifier |
| `date_opened` | ISO 8601 | When the cycle was opened |
| `date_closed` | ISO 8601 | When the cycle was verified closed |
| `triggered_by` | string | Who/what surfaced the defect (review, incident, audit, ad-hoc) |
| `affected_components` | list | Which components affected: `spec`, `control-plane`, `registry`, or `plugins:<name>` |
| `defect` | string | What was wrong |
| `root_cause` | string | Why it was wrong |
| `corrective_action` | string | What was done to fix it |
| `verified_by` | string | Independent verifier (must differ from who fixed it) |
| `prevention` | string | What prevents recurrence |

The planning-notes CLCA Cycles table (`ionis-devel/planning/notes/control-plane-discussion.md`) serves as the canonical worked example — nine cycles documenting the evolution of this spec.

### Where CLCA Records Live

The spec recommends a dedicated CLCA log as a first-class artifact —
institutional memory deserves its own home, not buried in audit trails
or commit messages. The format and location are an implementation
choice for the control plane or project governance.

### CLCA Applies to PCS Itself

The PCS spec is not exempt from its own discipline. Defects in the
spec trigger CLCA cycles documented in the spec's own history. This
is the right kind of recursion — the discipline that governs plugins
also governs the governance system.
