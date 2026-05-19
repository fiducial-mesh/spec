---
title: "SOM Pillar Names — Names of Record"
doc_type: planning-canonical
status: validated
version: v1.0
authors:
  - watson
  - patton
date: "2026-05-19"
roles:
  - design-intent
  - infrastructure
  - failure-mode
  - physics
  - astrophysics
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/PCS-ADOPTION-PLAN.md
  - planning/akb-awareness-layer.md
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
  - planning/akb-migration-plan.md
---

# SOM Pillar Names — Names of Record

**Scope**: Authoritative binding expansions for the seven pillar acronyms used across the Sovereign Orchestration Mesh (SOM). Every SOM document, spec, manifesto, paper, and pitch references this file. Anyone editing pillar names updates this file first.

**Discipline**: this is the names-of-record file in the sense of a manufacturing change-control register — not a wiki, not a draft. A pillar's binding does not change without a CLCA cycle. If a downstream document spells a pillar differently, the document is wrong, not this file.

## The Seven Pillars

| Short | Binding Expansion | Scope | Spec | Implementation |
|-------|-------------------|-------|------|----------------|
| **PCS** | Plugin Control System | Lifecycle, registry sync, versioning, and schema compliance for plugins (MCP servers, skills, runbooks) consumed by the agent fleet | `planning/PCS-ADOPTION-PLAN.md` | `qso-graph/*-mcp` fleet (13 servers); skills under `.claude/skills/` |
| **IBX** | Inbox Exchange | Asynchronous message routing and cognitive hand-off between agents, with action-priority messages held for Judge approval | (pending pillar spec) | `agent-inbox-mcp` (server) + `inbox-ui` (Judge desktop app) backed by `messages.inbox` (ClickHouse) |
| **AKB** | Agent Knowledge Base | Vector-indexed, role-projected, tier-stratified persistent context substrate with curation gates and self-review independence | `planning/akb-awareness-layer.md`, `planning/akb-reasoning-independence.md`, `planning/akb-lifecycle.md` | `KI7MT/akb` repo (Phase-1 build active; schema landed at `f29516f` on `main`) |
| **ACT** | Agent Cognitive Telemetry | Standardized span and token-tracking schemas providing an immutable, locally hosted audit trail for multi-agent cognitive loops | (pending pillar spec) | (pending; planned target — ClickHouse storage) |
| **DPG** | Deterministic Proving Ground | Ephemeral isolation boundary for complex code execution (build, test, validate) before code touches production state | (pending pillar spec) | Phase-4 "High-Heat" CUDA kernel validation flow (precedent) |
| **CRB** | Compute Resource Broker | Hardware-aware workload dispatch — routes between unified-memory hosts (Apple M3) and compute-host GPU (RTX PRO 6000) | (pending pillar spec) | DAC-link (`10.60.1.0/24`) routing + per-host venv + manual dispatch convention (codified, not yet automated) |
| **PGE** | Policy Guardrail Engine | Deterministic compliance enforcement — keyring-only credentials, parameterized SQL, subprocess gating — applied across the fleet without vendor-mediated safety filters | `planning/MCP-SECURITY-FRAMEWORK.md`, `.claude/hooks/subagent-guard.sh` | Per-server `test_security.py` suites; PreToolUse hook on Watson/Bob; CI release gates |

## Binding Rules

1. **The short code is canonical** — `PCS`, `IBX`, `AKB`, `ACT`, `DPG`, `CRB`, `PGE`. Always uppercase, no hyphens, no spaces. Documents may use either short code or full binding on first reference, then short code throughout.

2. **The binding expansion is fixed** — the words "Plugin Control System" map to PCS and only to PCS. Documents must not introduce competing expansions (e.g., "Plugin Container Service") without first updating this file via CLCA.

3. **Scope claims are bounded by the Scope column above** — extensions to a pillar's scope require an explicit revision of that pillar's row plus a citation to a pillar spec landing the extension. Watson and Bob may draft, but Judge gates the merge.

4. **Implementation references are descriptive, not binding** — the Implementation column documents current state. Implementations move; bindings don't. When an implementation changes, only that cell updates; the short/binding/scope remain stable.

## Pillar Status

| Pillar | Spec | Implementation Status |
|--------|------|----------------------|
| PCS | ✓ `PCS-ADOPTION-PLAN.md` | Production — governs 13-server MCP fleet |
| IBX | Pending dedicated spec; behaviors documented in CLAUDE.md "Agent Message Queue" + agent-inbox-mcp README | Production — used daily for Watson/Bob/Patton/Einstein hand-offs and Judge approvals |
| AKB | ✓ Three-spec gate (awareness, reasoning-independence, lifecycle) at v0.3, validated | Phase-1 build active — DDL landed; MCP server P1.5 next |
| ACT | Pending pillar spec | Specification phase — schema not yet drafted |
| DPG | Pending pillar spec | Operational precedent (CUDA kernel validation flow); not yet generalized into reusable substrate |
| CRB | Pending pillar spec | Codified-but-manual — DAC topology + dispatch conventions live in CLAUDE.md; no broker daemon yet |
| PGE | Operational (`MCP-SECURITY-FRAMEWORK.md` is its de facto spec) | Production — per-server security tests + PreToolUse hook + release gates |

## Why Names of Record Matter

Manufacturing quality has a name for the failure mode this file prevents: **change without provenance**. A pillar referenced by three different names across five documents is a defect, because downstream consumers (other agents, future Judge reads, external papers, vendor diligence) cannot trust that all references mean the same thing.

This file is the registry. Documents reference it. Disagreements resolve to it. Edits to it pass through CLCA.

## Editing Procedure (CLCA)

1. **Identify defect** — a binding is wrong, ambiguous, or missing.
2. **Proposed change** — draft the edit in this file. Include rationale (what was wrong, what the new binding implies for downstream documents).
3. **Action plan** — list every document that would need to update to track the change. If the count is large, weigh whether the existing binding is salvageable.
4. **Verify** — Watson + Patton dual-review. Physics-touching or invariant-touching changes also require Einstein.
5. **Land** — Judge approves the merge. Downstream documents update in follow-up commits, each citing this file's revision.

## References

- `planning/PCS-ADOPTION-PLAN.md` — current spec for PCS
- `planning/MCP-SECURITY-FRAMEWORK.md` — operational spec for PGE
- `planning/akb-*.md` — three-spec gate for AKB
- `CLAUDE.md` "Agent Message Queue" — operational reference for IBX
- `CLAUDE.md` "Infrastructure" / "DAC Network" — operational reference for CRB
