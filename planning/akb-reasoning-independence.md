---
title: "AKB Reasoning Independence — Specification"
doc_type: spec
status: validated
version: v0.4
authors:
  - watson
  - patton
  - bob
  - einstein
date: "2026-06-02"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/akb-awareness-layer.md
  - planning/akb-lifecycle.md
  - planning/akb-review-trajectory.md
  - planning/templates/akb-document-template.md
---

# AKB Reasoning Independence — Specification

**Status**: Validated v0.4 — codifies Patton's cap-unit ruling (cross-role cap is per-document, not per-chunk) surfaced during Bob's bootstrap dry-run and confirmed in inbox `8238714a`. The architectural framework is unchanged from v0.3; the v0.4 update sharpens the cap unit from chunk to document to match the operational reality and the ruling. Other v0.3 properties (role-projected retrieval, selective exemption, generalized self-review exemption, explicit task-type detection, substrate-trap-aware query flow) all stand unchanged.
**Scope**: Preserve diversity of reasoning substrates across agents while sharing the AKB substrate
**Authors**: Watson (drafted v0.3), Patton (v0.4 ruling on cap-unit), with structural input from Bob and Einstein
**Date**: 2026-06-02 (v0.4)

## Problem Restatement

The dialectical engine works because agents reason from **different priors over the same evidence**. Watson reasons from design-intent priors; Patton reasons from failure-mode skeptical priors; Einstein reasons from physics-first priors; Bob reasons from operational priors. When one agent is wrong, another agent's different substrate catches it — **independence of error distributions** is the load-bearing property.

A naive AKB-as-shared-substrate **converges** the reasoning substrates. When Watson, Patton, Einstein, and Bob all query the same AKB and receive the same top-K chunks, reasoning starts from the same biased anchor. Error diversity dies. Same structural pattern as V25-α — multiplicative paths the optimizer collapses to one.

Einstein verified this concern survives physics-first review: *"Specs 2/3 preserve orthogonal agent basis-vectors."* The mechanism in this spec is what makes that statement true.

## Architecture: Role-Projected Retrieval + Selective Exemption

Two mechanisms compose:

1. **Role-projected retrieval** — same underlying AKB, different *views* per agent role
2. **Selective exemption** — specific agents on specific task types do not query AKB at all

### Role-Projected Retrieval

**Storage**: single source of truth in `akb.chunks`. No data duplication. Projection happens at retrieval time, not at storage time.

**Mechanism**: each chunk carries a `roles: Array(LowCardinality(String))` column at ingest. Queries from a given agent filter by role.

**Default projections per role**:

| Agent | Role | Primary projection |
|---|---|---|
| Watson | design / training | `design-intent`: specs, master architecture, planning, design rationale |
| Bob | infrastructure / ops | `infrastructure`: fleet-ops, runbooks, friction catalog, deployment, build/release |
| Patton | skeptical review | `failure-mode`: CLCA cycles, V*-RESULTS, dead-end docs, anti-pattern docs |
| Einstein | physics / architecture | `physics`: ARCHITECTURAL-METHODOLOGY, MODEL-VERSION-HISTORY, physics-grounded analysis |
| Newton | sovereign-local astro | `astrophysics`: solar, ionospheric, propagation domain content |

**Default role assignment at ingest** (directory-path based):
- `spec/spec/` → `[design-intent, infrastructure]`
- `archive/planning/V*-RESULTS.md` → `[failure-mode, design-intent]`
- `planning/PHASE-5-*.md` → `[design-intent, physics]`
- `planning/AGENT-FRICTION-CATALOG.md` → `[infrastructure, failure-mode]`
- `shared-context/MODEL-VERSION-HISTORY.md` → `[design-intent, physics, failure-mode]`
- `shared-context/architecture-philosophy.md` → all roles
- CLCA cycle outputs → `[failure-mode]`

**Cross-role content** (visible to all roles) — small, deliberate, bounded:
- Tier 0 core content (`planning/tier0/akb-tier0-content.md`)
- V16 physics laws (sections in CLAUDE.md)
- Security framework (`planning/MCP-SECURITY-FRAMEWORK.md`)
- Project source of truth (`CLAUDE.md`)
- Architecture philosophy (`shared-context/architecture-philosophy.md`)
- A small number of skills genuinely applicable to every agent (`akb-doc`, `security-review`)

### Cross-Role Document Budget

**Hard cap on cross-role documents**: **N=50 total documents** whose frontmatter assigns all five roles (or the equivalent role-projection-spanning declaration). Patton's ruling, codified 2026-06-02 (per inbox `8238714a` after Bob's bootstrap dry-run surfaced the unit ambiguity). The cap is **per-document, not per-chunk.**

**Why per-document, not per-chunk** (Patton's reasoning):
- The cross-role budget is a budget on *governance attention* — every cross-role document is a doc the cross-role-projection cost must be paid for at retrieval time. Counting per-chunk would let a single 50-chunk doc consume the entire budget while a 1-chunk doc consumes 1/50th. That mis-prices governance attention.
- A document's all-roles assignment is the authorial commitment to cross-role visibility. Per-document counts that commitment once, regardless of how the doc happens to chunk.
- Bob's bootstrap measures cross-role at the document level via frontmatter inspection — operationally clean, no chunk-counting required at validation time.

**Bootstrap-time check**: count `DISTINCT source_doc WHERE roles ⊇ KNOWN_ROLES` against the cap.

**Current utilization** (post-PR-#60 frontmatter correction): **8 documents / 50** — comfortable headroom. The 4 Fiducial Mesh mesh-arch docs were corrected in PR #60 because they were mis-tagged cross-role; the remaining 8 are intentional (CLAUDE.md, MCP-SECURITY-FRAMEWORK.md, architecture-philosophy.md, akb-tier0-content.md, akb-doc skill, security-review skill, plus a few more).

**Overflow handling**: if a future ingest event would push the count to 51, **bootstrap fails with overflow report**. Resolution is a PR-#60-style frontmatter sweep: identify the most over-broad-tagged docs (mesh-arch docs wrongly carrying physics/astrophysics, planning docs wrongly carrying all-roles, etc.) and correct the source frontmatter. Maintaining a curation-layer correction on top of wrong source frontmatter is forbidden per Patton's `c6773933` ruling — fix the source, not the projection.

**Cap is non-negotiable.** Adding document N+1 to the cross-role set requires demoting an existing cross-role document, and the demotion must be defensible (the doc's audience genuinely narrowed; the doc is no longer canonical-for-every-agent).

**Per-chunk role override via curation event**: a chunk inside a single-role document can still be promoted to additional roles via curation event, modifying its `roles` array independently of the document's frontmatter. This does NOT consume cross-role document budget (the document remains single-role; only the specific chunk crosses). Use sparingly; over-reliance on per-chunk overrides defeats the per-document budget discipline.

### Per-Chunk Count — Preserved as Non-Blocking Review Signal

Patton's per-document cap ruling **demoted** the per-chunk count from blocking constraint to review signal; it did not delete it. The per-chunk cross-role count remains useful even when the document cap is not exceeded.

**Why it stays in the reports**:
- A single 50-chunk document with all-roles assignment consumes 1/50 of the document budget but represents 50 chunks of cross-role retrieval bandwidth. The document cap admits this; the per-chunk count surfaces it for review.
- Two 1-chunk documents consume 2/50 of the budget for 2 chunks of bandwidth — much lighter on retrieval cost. Same document count, different chunk count, materially different operational impact.
- Per-chunk count is the second-order signal that catches over-large cross-role documents the per-document cap cannot see.

**Where the per-chunk count surfaces**:
- Bootstrap dry-run report (per `akb-lifecycle.md` § Pre-Write Gate dry-run output) — listed as informational, NOT blocking.
- Periodic re-balancing review (per § Re-Balancing Triggers below) — curator inspects per-chunk counts for cross-role documents and flags individual documents whose chunk count has grown materially.
- AKB CLCA cycle review — high per-chunk cross-role contributors get scrutinized for whether they should be split into narrower per-section documents.

**Action threshold on per-chunk count** (advisory, not blocking):
- Documents contributing > 20 cross-role chunks each warrant a curator review (is the whole document genuinely cross-role, or could the cross-role content be extracted into a smaller dedicated doc?).
- Total per-chunk cross-role count > 200 across the corpus is a "rising tide" signal; the per-document cap will likely tighten in a future spec revision.

**Distinction from the v0.3 hard cap**: v0.3 said "N=50 total cross-role *chunks*" as the blocking cap. v0.4 says "N=50 total cross-role *documents*" as the blocking cap, with per-chunk count preserved as the advisory signal. The architectural intent (limit cross-role retrieval bandwidth) is unchanged; the operational measure (cap unit) is corrected to match Patton's ruling and Bob's empirical bootstrap measurement.

### Selective Exemption

Some agent × task-type combinations should **not query AKB at all**. The motivating example:

**Patton on review tasks**: Patton's role is independent skepticism. AKB represents the consensus view. Routing Patton's reviews through the consensus view *destroys his function*. He becomes a confirmation of the same biases the other agents share, instead of an independent counter-force.

**Mechanism**: `akb_exemption` table keyed on (agent, task_type) → query allowed/forbidden, with one generalized principle that supersedes specific rows.

### Generalized Principle — Self-Review Exemption

**Rule**: *Any agent reviewing their own work is exempt from AKB queries on that task.*

**Why generalized**: the single table row `Watson | review of own proposal | NO` extends to all agents — Bob reviewing his own runbook, Einstein reviewing his own physics analysis, anyone reviewing their own work. The principle, not the row, is load-bearing. Stating it as a rule means the exemption fires correctly even for combinations not enumerated in the table.

**Mechanism**: every AKB-relevant artifact (proposal, runbook, post-mortem, design doc) carries an `author_id` field. Self-review exemption rule: `EXEMPT IF (querying_agent_id == artifact.author_id) AND (task_type == 'review')`. Authorship tracked at artifact-creation time; cannot be retroactively edited without curation event.

### Table — Specific Exemptions (in addition to the generalized rule)

| Agent | Task type | AKB query allowed? |
|---|---|---|
| Patton | review (any artifact) | NO (independence required — Patton's entire function is independent skepticism; AKB is consensus view) |
| Patton | research | YES |
| Patton | AKB-CLCA-review | YES, but only against `akb.queries` log + raw corpus, not against `akb.chunks` index (he's reviewing the AKB itself) |
| Einstein | falsification | NO (must produce independent verdict) |
| Einstein | research | YES |
| Watson | implementation | YES |
| Bob | implementation | YES |
| Newton | astrophysics research | YES (read-only on `astrophysics` projection) |

The table is illustrative; the principle in § Generalized Principle is binding.

### Task-Type Detection — Explicit-First

**Explicit declaration is the primary mechanism, not implicit detection.** S5 from review: implicit detection is the weakest link, and if it fails the entire exemption regime fails. Make it explicit and binding:

1. **Primary path — explicit declaration**:
   - Agent receives task with explicit `task_type:` marker (auto-populated from inbox `subject` tag, or manually declared)
   - Session opens with marker; marker cannot change mid-session without explicit acknowledgment + audit log entry
   - AKB queries during marker-tagged session are gated by exemption table
   - **This path carries authority.** Without explicit marker, default behavior applies.

2. **Suggestion path — implicit detection** (informational, NOT authoritative):
   - Heuristic detection of likely task type from session context (e.g., subject contains "Re: ... — review")
   - When detected without explicit marker, **suggested marker logged for audit**
   - Does NOT change query gating — agent operates under default unless explicit marker present
   - Audit log may surface patterns where implicit detection consistently fires; that's a signal to require explicit marker for that pattern in the future

3. **Default behavior** (no marker, no implicit suggestion): AKB query allowed, log session as `task_type: unspecified` for audit review.

**Why this matters**: making implicit detection authoritative would let ambiguous/multi-task sessions silently bypass exemptions. Making explicit primary means the exemption regime fails *visibly* (session has no marker) rather than *silently* (implicit detection guessed wrong).

## Independence Verification

The architecture is only useful if it produces what it claims to. Verify periodically:

**Independence test**: same query phrased identically, issued by different agents on different task types. Compare top-K chunk overlap.

| Comparison | Expected overlap | Failure threshold |
|---|---|---|
| Same agent, same task type, repeated query | High (>80%) | <80% = instability |
| Same agent, different task types | Medium (40-70%) | >80% = task-type projection failing |
| Different agents, same task type | Low (10-40%) | >50% = role projection failing |
| Different agents, different task types | Very low (<20%) | >40% = role+task projections both failing |

Run as a periodic CI job (weekly). Failures flag for re-balancing.

### Re-Balancing Triggers (Measurable, Not Vague)

Re-balancing is triggered by specific measurable signals, not a vague "periodic via curator review":

1. **CI failure**: any independence-test threshold breach (table above) triggers an open ticket flagged for curator review within 7 days
2. **Monthly minimum cadence**: regardless of CI signal, curator review of role projections runs once per calendar month — protects against silent drift where CI passes but projections have shifted in ways the test doesn't capture
3. **Curation-event volume threshold**: when `akb.curation_events` accumulates ≥ 100 events touching role assignments since last re-balance, trigger immediate review (high-churn signal)

Re-balancing without a trigger is forbidden — prevents curator drift where role definitions get edited without observable cause.

## Why Shared Substrate + Projection Beats Separate AKBs

**Alternative considered: per-agent isolated AKBs.** Each agent has its own AKB; no sharing.

Rejected because:
- Massive duplication of effort (curate same chunk N times)
- Inconsistency over time (different agents' AKBs drift apart)
- Loses the JOIN advantage (cross-agent query patterns aren't queryable)
- Doesn't preserve audit trail of who-saw-what

**Shared substrate + role projection** preserves the advantages of single source of truth (one curation effort, one audit trail, one JOIN surface) while preserving independence at the retrieval layer.

## The Patton-Exemption Question

If Patton-on-review-tasks is fully exempted from AKB, **how does Patton catch what's *in* the AKB that's wrong?**

Two answers:

1. **Patton operates on the raw corpus, not the AKB.** When reviewing, Patton reads the source files directly (CLAUDE.md, V*-RESULTS, planning docs). He's not blind to the knowledge; he's reading it un-mediated. The AKB is a retrieval optimization; Patton's review bypasses the optimization to preserve independent assessment.
2. **Patton specifically reviews the AKB itself** as a separate task type. Periodic CLCA cycle: Patton inspects high-traffic AKB chunks, looks for narrative-correct-but-structurally-misleading content (his V28 lesson), flags for re-review or demotion. This is the **promotion-discipline counter-force** from `lifecycle.md`.

## Implementation Path

**Phase 1 (proof of concept)**:
- Add `roles: Array(LowCardinality(String))` column to `akb.chunks`
- Add `akb_exemption` table
- MCP wrapper filters by role at query time — **applied AFTER deterministic pre-filter on `violates_invariant`** (see `akb-awareness-layer.md` § Tier 1 Query Flow). Role projection cannot prevent substrate-trap retrievals on its own; it operates on the already-pre-filtered candidate set.
- Default role assignments via directory-path heuristic at ingest

**Phase 2 (refinement)**:
- Per-chunk role override via curation events
- Task-type detection from session context
- Independence verification CI job

**Phase 3 (maturity)**:
- Periodic re-balancing of projections based on observed independence metrics
- Automated detection of projection failures (overlap above threshold)
- Curator dashboard for projection adjustments

## Open Questions

1. **Granularity of roles**: too few roles → projections collapse toward shared substrate. Too many → projections become hyper-narrow and miss relevant content. Start with 5 (one per agent), evaluate.
2. **Task-type vocabulary**: bounded enumeration required. Initial set: `implementation`, `review`, `research`, `falsification`, `post-mortem`, `AKB-CLCA-review`, `unspecified`. New task types require curation event to add. The set must stay small enough that the exemption table remains tractable.
3. **Patton's AKB-CLCA-review cycle**: how often does Patton do AKB-itself review? Weekly? Per-N-promotion-events? Driven by query log signals? See `akb-lifecycle.md` § Decay Signals and § CLCA Cycle for AKB Itself for the operational answer.

## Failure Modes To Watch

- **Projection drift**: roles defined once at ingest, never adjusted. Over time, the assumptions baked into directory-path defaults stop matching reality. Mitigation: periodic re-balancing via curator review.
- **Exemption escapes**: agent in exempt mode finds a workaround (asks another agent to query, reads chunks via raw file read). Mitigation: audit log on exempt-mode sessions; flag suspicious patterns.
- **Cross-role bloat**: pressure to mark chunks "visible to all" because nobody wants to be excluded. Mitigation: hard budget cap on cross-role chunks; promote only with explicit justification.
- **Independence test as Goodhart's law**: agents optimize for low overlap regardless of relevance. Mitigation: independence is a sanity check, not an optimization target.

## Dependencies

- AKB storage with `roles` column
- MCP wrapper aware of caller role
- `akb_exemption` table + lookup logic
- Independence verification CI job (Phase 2+)

## Success Criteria

- **Default role projections in place**: every chunk has at least one role at ingest
- **Patton-on-review exempted**: verified by inspection of inbox patterns
- **Independence test passes**: weekly overlap measurements within expected ranges
- **Audit trail intact**: every role assignment + exemption decision logged in `akb.curation_events`
- **No projection escapes**: no chunk visible to all roles unless explicitly justified
