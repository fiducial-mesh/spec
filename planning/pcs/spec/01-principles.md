# 01 — Design Principles

Version: 0.1 | Status: Draft

---

## Why PCS Exists

Humans need a consistent workspace and tooling to be productive.
Agents need the same thing — more acutely, because they have no
inherent cross-session memory.

The same workspace inconsistency that costs a human developer 30%
productivity costs an agent 100% productivity per session, because the
agent has to reconstruct the entire mental model from scratch every
time. Multiply that by N agents and M sessions, and inconsistency
becomes the dominant cost in any multi-agent operation.

PCS is built on this principle: **workspace consistency is the contract
that makes multi-agent, multi-session work possible at all.**

Every convention in this spec — standard directories, predictable
filenames, JSON Schema everywhere, explicit trust tiers, required
audit logs — exists to externalize what agents cannot carry across
sessions. The spec is the workspace's contract with its agents:
agents agree to operate within convention; the workspace agrees to
make convention adherence pay off.

The hard problem is admitted, then solved. PCS isn't selling magic
continuity. It's selling **engineered continuity** — a careful
decomposition of memory across operator, workspace, documents, audit
log, and spec, designed to be robust against any one component
failing.

| Memory Type | Who Holds It | What It Preserves |
|------------|-------------|-------------------|
| In-session depth | Agent | Reasoning chains, synthesis, creative work |
| Cross-session continuity | Operator (human) | Project context, past decisions, learnings |
| Workspace structure | Filesystem + spec | Conventions, layouts, procedures — invariant |
| Audit log | Control plane | Factual record of what happened |
| Documents | Repo files | Pointers, decisions, rationales |

The framework works because it doesn't ask agents to be long-term
memory. It asks the workspace to encode what agents need to bootstrap
each session.

*This section frames the engineering problem PCS solves.*

---

## Component Roles

PCS has three components. Each has a single responsibility.

**pcs-spec — The Rules.**
Schemas, principles, contracts. All policy lives here. If a rule needs
to change, it changes here and nowhere else.

**pcs-control-plane — The Inspector.**
Pure validation. Takes a candidate and reports whether it satisfies the
spec. Stateless. No opinions. Agnostic to what any plugin does — only
checks whether it conforms.
```
(spec, candidate) → verdict
```

**pcs-registry — The Curated Catalog.**
Returns only artifacts that have passed control-plane inspection.
No validation logic. Pure curation and resolution.
```
(query, context) → list of validated artifacts
```

The spec declares. The control plane checks. The registry serves.

Promotion mechanics (trust tier transitions, lifecycle changes) are out
of scope for these three components — they are read/declare/check only.
State mutation lives in the CI/publish pipeline.

---

## Principles

Every principle is a verifiable/actionable control. No thesis
statements. If a principle can't be tested — by a schema field, a
structural constraint, or a process discipline — it isn't a principle.

1. **Every action is auditable.**
   Enforcement: control plane process constraint (runtime validation +
   audit emission).

2. **Every artifact has an owner.**
   Enforcement: schema field `owner` (required, non-empty).

3. **Deprecation is a state, not an event.**
   Enforcement: schema field `lifecycle_state` enum
   (`draft` | `active` | `deprecated`).

4. **Trust is tiered, not binary.**
   Enforcement: schema field `trust_tier` enum
   (`experimental` | `community` | `blessed` | `core`).

5. **The agent layer brings judgment and conversational state; the
   skill layer is a pure, stateless definition of inputs, outputs,
   and capability requirements.**
   Enforcement: structural schema constraint — skill schema contains no
   orchestration, state, or role context fields.

6. **Capability requirements and capability advertisements are
   symmetric.**
   Enforcement: schema field `requires_capabilities` checked against
   execution profile at invocation time.

7. **Every skill declares its side-effect profile.**
   Enforcement: schema fields `effect` + `is_idempotent` + control
   plane abort-rejection rule for `mutate_external`.

8. **Skills, runbooks, and vocabulary are project-portable.**
   Enforcement: source-derived scoping + registry source manifest.

9. **PCS itself is governed by CLCA.**
   Enforcement: process discipline — CLCA cycles logged as mandatory
   ledger; every structural change triggers a cycle.

10. **Procedures are substrate-aware operational primitives. Skills
    compose against procedures and remain substrate-agnostic;
    procedures encode the operational specifics once.**
    Enforcement: the litmus test applies to skill fields, not
    procedure fields. Procedures may reference specific shells,
    tools, and execution mechanisms. This is intentional — procedures
    are the layer where substrate-aware operational knowledge is
    encoded so that skills don't have to carry it.

---

## Portability

Portability is a structural design constraint from day one — not a
future migration.

**"Build portable, deploy Claude first."**

- The core PCS spec is canonical and substrate-agnostic.
- Claude is the first compilation target — operationally important,
  but not privileged in the spec.
- Claude-specific concerns live in a compiler/adapter layer.
- Adding future targets (Codex, Cline, Cursor) is additive — write a
  new compiler, don't refactor the spec.

---

## The Litmus Test

Every field in the spec must pass all three checks:

1. **Lexical Check** — does the field avoid vendor-specific vocabulary?
2. **Executor Check** — if the underlying runner was swapped from an
   LLM agent to a deterministic cron job, would the field still make
   logical sense?
3. **What-vs-How Check** — does the field describe *what capability*
   the skill requires, rather than *how* the substrate provides it?

The What-vs-How Check is the strongest. It alone catches all known
leak patterns.

**Executor Check footnote:** Some PCS fields won't make sense under
every executor (e.g., evidence requirements assume an evaluator). That
doesn't indicate a leak — it indicates capability gating. The field is
fine; the executor just doesn't consume it.

### Known Leak Patterns

| Category | Leaked Field | Why It Leaks | Clean Alternative |
|----------|-------------|--------------|-------------------|
| Execution Paradigm | `resume_state_schema`, `max_turn_duration_ms` | Assumes turn-based agent loop | Avoid; execution model belongs in compiler |
| Context/Memory | `requires_token_budget: 4000` | Assumes LLM with linear context window | `max_payload_bytes` |
| I/O Auth | `required_env_vars: ["API_KEY"]` | Dictates credential delivery mechanism | `requires_capability: qrz_read_access` |

