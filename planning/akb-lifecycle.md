---
title: "AKB Lifecycle — Specification"
doc_type: spec
status: validated
version: v0.4
authors:
  - watson
  - bob
  - patton
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
  - planning/akb-reasoning-independence.md
  - planning/akb-review-trajectory.md
  - planning/akb-migration-plan.md
  - planning/templates/akb-document-template.md
---

# AKB Lifecycle — Specification

**Status**: Validated v0.4 — codifies the live-ingest pre-write gate that Bob and Patton invented during the 2026-06-02 Phase-1 dry-run / pre-write sequencing. The architectural framework is unchanged from v0.3; v0.4 adds the bootstrap-and-backfill pre-write gate as a formal CLCA step rather than an ad-hoc inbox arrangement, and updates ingest references to match `akb-migration-plan.md` v0.2 (canonical skill path is `shared-context/skills/`, templates excluded, tier0 dedicated rule).
**Scope**: How AKB content gets in, stays correct, gets out
**Authors**: Watson (drafted v0.3), Bob and Patton (v0.4 pre-write gate), with structural input from Einstein
**Date**: 2026-06-02 (v0.4)

## Problem Restatement

Unspec'd lifecycle is how knowledge bases rot — the same 442-markdowns problem, relocated to vector space with worse observability. Without explicit rituals for ingest, promotion, conflict resolution, decay, and rollback, the AKB accumulates stale, contradictory, narrative-correct-but-structurally-misleading content over time and becomes worse than no AKB at all.

This spec answers Bob's 10 lifecycle questions and codifies Patton's promotion discipline (Bar C with stratification).

## Ingest Model

**Triggers** (in priority order):

1. **Git post-commit hook**: when a tracked markdown file changes in canonical doc directories, queue for re-ingest.
2. **File watcher**: for content outside git (e.g., generated reports, inbox-derived chunks).
3. **Manual ingest**: explicit promotion of artifacts (CLCA cycle outputs, Patton verdicts, Einstein analyses). Performed by curator.
4. **Initial bootstrap**: full corpus walk + chunk + embed. **Each bootstrap is a versioned event** logged in `akb.curation_events` with `event_type='bootstrap'`, batch_id, source-corpus git-commit hash, and chunk count. First bootstrap = `bootstrap-v1`; subsequent full rebuilds (e.g., after embedding-model swap, after schema migration) = `bootstrap-v2`, `-v3`, etc. Replayable from audit log.

### Pre-Write Gate (Bootstrap and Backfill)

**Required for any operation that would write ≥ 20 chunks** in a single ingest event — bootstrap, embedding-model-swap rebuild, schema-migration rebuild, large backfill of new doc directories. Routine git-post-commit re-ingests on individual file edits are NOT gated; they flow through the standard chunking + embedding path.

**The gate, in sequence**:

1. **Dry-run**: the ingest pipeline runs with `--dry-run` flag against the target corpus. Output is a deterministic report (no writes to `akb.chunks`):
   - Total documents walked, total chunks produced
   - Per-rule-id classification counts (how many docs matched each Phase A rule)
   - Cross-role **document** count against the per-document cap in `akb-reasoning-independence.md` (blocking — bootstrap fails if exceeded)
   - Cross-role **chunk** count, reported as a **non-blocking review signal** (per Patton's `c6773933` framing — useful for spotting documents that consume disproportionate cross-role retrieval bandwidth even when within the document cap)
   - **Inherited-over-tagging suspects** per `akb-migration-plan.md` § A.1.3 — list of documents carrying `physics` or `astrophysics` outside the expected-domain allowlist (blocking — bootstrap fails until each flagged document is source-corrected or added to the allowlist with justification)
   - Default-rule (no-specific-match) count — should be **zero** for a clean bootstrap
   - Violations of the pre-filter contract (`violates_invariant=true` chunks not marked, or docs missing `invariant_class` where required)
   - List of explicitly-excluded files (templates, notes, papers)
2. **Patton review** (mandatory, action-priority inbox message from Bob → Patton):
   - Patton receives the dry-run report and the integration PR (if any frontmatter / inference / rule changes are bundled with the bootstrap)
   - Patton's job at this gate is **no-overclaim-in-classification** review — same discipline as no-overclaim review on canonical Fiducial Mesh docs. Specifically: are any documents reading as cross-role that aren't; are any failure-class docs not marked `violates_invariant=true`; are any inherited-frontmatter-pattern over-tagging issues surfaced (the SOM-4 lesson, per `c6773933`).
   - Patton can require source-frontmatter corrections (PR-#60-style) before the gate clears. Source fixes are landed pre-write, not as post-ingest curation events (per Patton's `c6773933` ruling: fix the source, not the projection).
3. **Patton sign-off → Judge approval**:
   - When Patton clears the dry-run, he sends an info-priority message confirming the gate passes.
   - Judge issues the `--apply` directive (separate explicit step — Judge does NOT auto-approve based on Patton's sign-off alone).
   - The `--apply` directive is logged in `akb.curation_events` with `event_type='bootstrap_approved'`, the dry-run report hash, and the Patton sign-off message ID.
4. **Live write**: ingest pipeline runs without `--dry-run`, writes to `akb.chunks`. The `bootstrap-vN` curation event is logged on completion with the same dry-run report hash as v0.4 evidence the live write matched the approved dry-run.

**Why this gate matters**:
- A bootstrap silently mis-classifying 14 corpus skills (Bob's `50460657` dry-run finding) would have produced invisible-to-retrieval chunks. Pre-write detected it before any chunk landed.
- A bootstrap silently saturating the cross-role document cap (the SOM-4 over-broad-tagging that PR #60 corrected) would have required either a curation-layer correction (rejected by Patton's `c6773933`) or a full rebuild. Pre-write detected it before write.
- Pre-write is the cheap CLCA gate; post-write cleanup is the expensive one. This formalizes "contain at the source, not at the projection."

**Skipping the gate is a defect, not a shortcut.** A bootstrap that runs without the dry-run + Patton sign-off + Judge `--apply` chain bypasses the most consequential governance step in the AKB lifecycle and must be rolled back via the next bootstrap version.

**Canonical doc directories** (auto-ingested):
- `ionis-devel/CLAUDE.md`
- `ionis-devel/planning/**.md`
- `ionis-devel/archive/planning/**.md`
- `ionis-devel/shared-context/**.md`
- `spec/spec/**.md`
- `som-pcs-registry/**.md`
- `som-pcs-control-plane/**.md`

**Excluded by default** (require manual promotion):
- `ionis-devel/planning/notes/` (working drafts)
- `*/README.md` outside ionis-devel (auto-generated content)
- LaTeX build artifacts (`.aux`, `.log`, `.toc`)

## Chunking + Embedding

**Chunking strategy**: header-based split with token cap
- Split at H1/H2/H3 boundaries
- Further split chunks > 800 tokens at paragraph boundaries
- 100-token overlap between adjacent chunks
- Preserve full header path (e.g., `CLAUDE.md > IONIS Model > V16 Physics Laws`)

**Embedding model**: `BAAI/bge-large-en-v1.5` (1024-dim) on 9975 RTX PRO 6000
- Initial corpus (~3.4 MB, ~10-15K chunks): 15-20 min one-time
- Incremental ingest: per-chunk embedding takes <50ms

**Per-chunk metadata**:
- `source_file`, `repo`, `header_path`, `position`
- `last_modified`, `git_author`, `git_commit`
- `doc_type` — bounded enum, see below
- `roles: Array(LowCardinality(String))` (per role-projection spec)
- `confidence` (per promotion discipline below)
- `author_id` (per `akb-reasoning-independence.md` § Generalized Principle — used for self-review exemption)
- **`violates_invariant: Bool`** (per Einstein's substrate-trap finding — used for deterministic pre-filter at query time; see `akb-awareness-layer.md` § Tier 1 query flow)
- **`invariant_class: LowCardinality(String)`** (which invariant the chunk violates, e.g., `V25-α`, `V27-PIL`, `V16-clamp` — empty string if `violates_invariant=false`)

### `doc_type` Bounded Enumeration

`doc_type` is a closed enum, not open-ended. Adding a new value requires explicit curation event. Initial set:

| Value | Source pattern | Notes |
|---|---|---|
| `spec` | `spec/spec/**.md`, `CLAUDE.md`, security framework | Authored spec content, highest authority |
| `planning-active` | `planning/**.md` (non-archive, non-notes) | Current planning, may evolve |
| `planning-draft` | `planning/notes/**.md` | Working drafts (default excluded from ingest) |
| `archive` | `archive/**.md` | Historical reference, marked `deprecated` by default |
| `v-results` | `archive/planning/V*-RESULTS.md` | Version post-mortems, immutable historical record |
| `friction` | `planning/AGENT-FRICTION-CATALOG.md` (per-entry) | Friction catalog entries |
| `clca` | CLCA cycle output artifacts | Defect → root-cause → corrective-action records |
| `runbook` | `**/RUNBOOK.md`, `*-runbook.md` | Operational procedures |
| `shared-context` | `shared-context/**.md` | Cross-agent reference material |
| `inbox-derived` | Inbox messages promoted to AKB (e.g., Patton verdicts, Bob/Watson coordination outputs) | Manual ingest only |
| `air-report` | Agentic Incident Reports — failure post-mortems with CLCA actions | Sourced from `fiducial-mesh/air/reports/AIR-*.md` per `akb-migration-plan.md` § Phase A.1. **`violates_invariant: false`** (operational lessons to be **surfaced** at decision points, not filtered out by the substrate-trap pre-filter — distinct from `v-results` which carries `true`). Tier-1 hook triggers per AKB-SPEC CD14 surface AIR chunks at decision points (before `git push`, `gh pr`, deploy commands, substrate config edits). Closes the AIR + AKB + PCS containment loop articulated in `AIR-SPEC-DESIGN-NOTES.md` § 1. |

**No `etc.`** Adding `paper`, `data-doc`, `interview`, etc. requires a curation event documenting why the new type is needed and what queries it serves.

### `violates_invariant` Assignment at Ingest

Einstein's substrate-trap finding: the underlying vector model (`bge-large-en-v1.5`) clusters by linguistic proximity, not physical correctness. A V25-α failure post-mortem and a V16-compliant design proposal use identical vocabulary; their cosine similarity is high. **Vector retrieval alone will surface dead-end content as candidate solutions to physics queries.** Role-projection (a metadata WHERE clause) does not fix this because it filters *after* the physics-blind retrieval step.

**Fix**: chunks carry a hard `violates_invariant: Bool` flag set at ingest. The query engine executes deterministic pre-filtering before vector distance is calculated.

**Default `violates_invariant=true` assignment** (at ingest):
- All chunks from `archive/planning/V*-RESULTS.md` describing failed approaches
- Chunks from `planning/AGENT-FRICTION-CATALOG.md` describing resolved-defective patterns
- CLCA cycle outputs marked as root-cause findings for dead-ends
- Any chunk explicitly tagged anti-pattern in source markdown (via convention like `<!-- antipattern: V25-α -->`)
- Chunks describing the eight-dead-end list itself (when ingested as full context)

**`invariant_class` set to**: the specific invariant the chunk violates (`V25-α`, `V27-PIL`, `V16-clamp-widen`, etc.). Used for explicit-history queries that intentionally retrieve violators (e.g., "what did V27 try and why did it fail?").

**Default `violates_invariant=false`** for everything else — current specs, runbooks, validated approaches.

**Override per chunk via curation event**: if a chunk is incorrectly flagged at ingest, curator can correct via curation event. Always logged in `akb.curation_events` with reason.

**Re-evaluation on ingest of new dead-ends**: when a new failure (V29, V30, etc.) gets documented, the new V*-RESULTS file's chunks ingest with `violates_invariant=true`. No re-evaluation of existing chunks needed — invariant assignment is per-chunk-at-ingest, not retroactive.

## Trust-Tier Assignment at Ingest

**Directory-path defaults**:

| Source | Default tier | Rationale |
|---|---|---|
| `spec/spec/` | `validated` | Authored spec content |
| `archive/planning/V*-RESULTS.md` | `validated` | Historical post-mortems, immutable |
| `shared-context/architecture-philosophy.md` | `validated` | Foundational principles |
| `CLAUDE.md` | `validated` | Project source of truth |
| `planning/PHASE-*-*.md` | `draft` | Active planning, may evolve |
| `planning/AGENT-FRICTION-CATALOG.md` | `validated` | Per-entry validated state |
| `planning/notes/` | `draft` | Working drafts |
| Other `planning/**` | `draft` | Default for new content |
| `archive/**` (non-V*) | `deprecated` | Historical reference only |

**Human override**: curator can promote/demote any chunk via `akb.curation_events`. Default is the floor, not the ceiling.

## Promotion Discipline — Bar C with Stratification

Per Patton's recommendation, promotion stratifies by content class:

### Automated Promotion (Bar A — allowed for procedural content)

Eligible content classes:
- Procedural docs (how-to, runbooks, setup instructions)
- Reference content (factual lookups, band IDs, constants, schemas)
- Routine planning (e.g., next-quarter planning notes that aren't architectural decisions)

Promotion signal: query log + outcome signal indicates chunk was retrieved, used, and produced successful outcome N times. After threshold, auto-promoted to `validated`.

### Patton-Veto Required (Bar C — adversarial review)

**Mandatory** for:
- Failure-class chunks (post-mortems, V*-RESULTS content, dead-end documentation)
- Architectural decisions (V-version rationale, design choices, locked constraints)
- Anti-pattern chunks ("don't do X" content)
- CLCA cycle outputs (especially root-cause analyses)

**Mechanism**:
1. Promotion candidate → `akb.promotion_candidates` table with status `awaiting_review`
2. Candidate becomes visible in Patton's session-start queue (next time Patton is invoked)
3. Patton inspects chunk + source context + retrieval test results
4. Single block by Patton → status `rejected`, audit logged
5. Approval by Patton → status `promoted`, chunk promoted to `validated`

### Patton Presence Model — Session-Driven, Not Calendar-Driven

**Critical correction (S3 from Patton's own review)**: the earlier design assumed continuous Patton presence with a 7-day calendar timer. That model is wrong. **Patton is session-bounded on Claude Desktop. He does not exist between sessions.** A 7-day wall-clock timer assumes a Patton-process exists during those 7 days waiting to fire — there is no such process.

Promotion gating must use a **session-driven** model:

1. **At each Patton session**, his Tier 0 / queue surface lists pending promotion candidates ordered by age and priority
2. **Promotion gate fires on Patton's decision when he is next invoked**, not on a wall-clock countdown
3. **Two escalation paths from queue overflow**:
   - **Cadence-driven invocation**: Judge invokes Patton specifically for promotion-review on regular cadence (e.g., weekly batches of pending candidates). Predictable tempo.
   - **Queue-size escalation**: when `akb.promotion_candidates` count exceeds threshold (initial: 25 awaiting review) Judge gets a `akb_queue_overflow` notification and decides whether to invoke Patton or handle directly via Bar B

**What replaces the 7-day timer**:
- No automatic Judge-escalation by wall-clock time alone
- Queue-size and Judge-cadence are the operational levers
- Candidates can sit awaiting review indefinitely if no signal triggers attention — that's acceptable, "better draft than wrongly-promoted"

**Process principle this surfaces**: when a spec references an agent's behavior or availability, that agent should be the reviewer who validates the assumptions about themselves. Only Patton could have caught this — it's a fact about his own operational reality.

### Human-Only Promotion (Bar B — Judge-gated)

Reserved for:
- Spec changes affecting non-V16 LOCKED content (security framework, MCP contracts)
- Cross-cutting architectural decisions affecting multiple agents

Mechanism: `akb.promotion_candidates` → Judge review via inbox-ui → manual approve/reject.

### V16-Touching Promotion (Bar B + Physics Bar C hybrid)

Per Einstein's review: V16 physics laws are mathematically bounded physics constraints, not just LOCKED policy decisions. Human operators are vulnerable to cognitive fatigue and narrative persuasion. **Any proposed modification to V16 invariants requires both Judge approval AND Einstein adversarial review** — a two-key gate, neither sufficient alone.

**Triggers** (chunk class that fires this bar):
- Any change to documents containing V16 physics laws (CLAUDE.md V16 section, archive/V*-RESULTS that re-litigate V16, ARCHITECTURAL-METHODOLOGY changes touching the locked invariants)
- Any chunk being promoted that proposes a modification to a V16 law (HuberLoss, weight clamp, gate variance loss, defibrillator init, data recipe, IonisGate architecture)
- Any chunk whose `invariant_class` matches a V16-touching pattern

**Mechanism**:
1. Promotion candidate enters `akb.promotion_candidates` with status `awaiting_judge` AND `awaiting_physics_review`
2. Judge reviews in inbox-ui — can approve/reject the policy-side
3. Einstein reviews in parallel — can approve/reject the physics-side
4. **Both must approve before promotion**. Either side blocks → chunk stays `draft`. Block reasons logged.
5. Audit trail: both approval/rejection events captured separately in `akb.curation_events`

**Why two-key**: V16 modifications are the highest-stakes content class. Judge has organizational/operational authority; Einstein has physics-first priors that catch narrative-correct-but-mathematically-wrong proposals (V28-sign-flip-style failure mode applied to V16 itself). Either reviewer alone is a single point of cognitive failure.

**Process principle**: when a content class has mathematically bounded correctness conditions, promotion requires both human policy authority and the agent whose priors check the mathematical constraint. Generalize as needed for future content classes with similar properties.

## Update Strategy on Source-Doc Edits

**File hash tracking**: each ingested chunk records its source file's hash at ingest time.

**On source file change** (git post-commit hook):
1. Compute new file hash
2. Re-chunk the modified file
3. Diff new chunks vs. old chunks by content hash
4. **Unchanged chunks**: preserve as-is (chunk_id retained)
5. **Modified chunks**: re-embed, increment version, preserve chunk_id, mark `pending-review` if was `validated`
6. **New chunks**: ingest fresh with default tier per directory
7. **Removed chunks**: mark `deprecated` (don't delete — preserves audit trail)

**Renames**: tracked via git mv. If content unchanged, chunk_id continuity preserved. If both renamed and edited, treated as new + deprecated old.

**Deletions**: same as removed chunks — mark `deprecated`, retain.

### Source-State Drift Scope — MVP Exclusion

Drift detection above is **git-based only**. Non-git source state is **explicitly excluded from MVP**:

- ClickHouse schemas (DDL changes don't appear in markdown)
- MCP server versions and capabilities (deployed-binary state)
- Live propagation data shape (WSPR feed format, PSKR collector schema)
- Live infrastructure config (running services, ports, credentials in keyring)

**Why excluded**: chunks describing these would go stale silently — git doesn't see DDL changes or live infra. Including them creates known-stale content. Better to exclude than to ship certain rot.

**MVP rule**: only ingest content from git-tracked markdown sources. Chunks about live infrastructure state are out of scope until a non-git drift mechanism is designed.

**Follow-up requirement** (post-MVP): design non-git drift detection per source type:
- ClickHouse: schema-fingerprint comparison on ingest
- MCP versions: version-tag fingerprint
- Live infra: explicit "freshness probe" per chunk class

Documented as **gap** to track. Phase-1 ships with this gap explicit, not papered over.

## Conflict Resolution at Query Time

### Precedence Rules (Patton's)

Hard precedence, never overridden:

1. **Spec** (spec, V16 laws, security framework, MCP-SECURITY-FRAMEWORK) — absolute authority. Never overridden by AKB.
2. **Source code + current configuration** — current state of the world. Second authority.
3. **Validated AKB chunks** — encoded judgment. Lower authority than spec.
4. **Draft AKB chunks** — explicitly contingent. Lower authority than validated.
5. **Archive** — historical reference only. Never authoritative for current state.

**Conflict between authorities** (e.g., AKB says X, spec says Y): spec wins, AKB chunk auto-marked `pending-review`.

### Same-Tier Conflicts

Two same-tier chunks disagreeing on the same domain:

- Return BOTH in retrieval results with explicit divergence flag
- Log to `akb.conflicts` table with status `open`
- Agent sees the conflict marker, escalates to human or makes context-specific judgment
- Curator periodically reviews `akb.conflicts` and resolves (promote one, demote the other, mark both as superseded)

**Detection**: at ingest time, if a new chunk overlaps semantically (cosine similarity > 0.85) with an existing same-domain chunk and they answer the same question differently, flag for review.

## Deprecation Markers

**Chunk-level deprecation** (preferred):
- Individual chunks can be deprecated without invalidating the rest of the source doc
- Reasons: superseded by newer content, found to be wrong, source state changed
- Deprecated chunks still queryable but flagged `historical` — agents see them with explicit warning

**Doc-level deprecation**:
- Entire doc moved to archive → all chunks from that doc auto-deprecated
- Used for whole-document retirements

**One-way for 30 days**: deprecation is reversible only after 30 days, and only with two-reviewer approval. Prevents "oops deprecated, oops un-deprecated" gaming and accidental restoration of bad content.

## Decay Signals

Chunks must justify their continued presence. Decay mechanisms:

1. **Zero-query chunks** (90 days, no retrievals): flagged for review. Either undiscoverable (curator examines) or genuinely irrelevant (deprecate).
2. **Negative outcome signals**: agent feedback indicates chunk was retrieved but led to wrong outcome. Demote from `validated` to `draft`, flag for re-review.
3. **High-traffic + low-outcome**: retrieved often but outcomes are mixed. Indicates ambiguous or misleading content. Flag for Patton-veto review even if previously `validated`.
4. **Source-state drift**: chunk describes current state, but source file has changed. Auto-marked `pending-review` via update strategy above.

**Monthly CLCA cycle for the AKB**:
- Review top-N flagged chunks
- Review zero-query chunks for relevance
- Update promotion-rigor expectations based on observed failures
- Curator + Patton sign off on month's cleanup

## Embedding Model Swap Migration

When `bge-large-en-v1.5` is replaced (e.g., by a successor model):

1. **Dual-write period**: new embedding column (`embedding_v2`) added; new content embeds in both old and new models
2. **Backfill**: old chunks re-embedded with new model, written to `embedding_v2`
3. **Validation**: A/B test retrieval quality — same queries against old vs. new embeddings, measure relevance
4. **Cutover**: switch primary query path to `embedding_v2` after validation passes
5. **Cleanup**: drop `embedding` (v1) column after 30-day cooldown
6. **Rollback**: if v2 worse in production, revert primary to v1, drop v2

**Required for cutover**: A/B retrieval quality must be ≥ old model on representative query set.

## Rollback Path

**Bad curation events** are reversed, not deleted:

1. Every curation event has full state diff in `akb.curation_events`
2. Reverse event = create inverse curation event with reason `rollback-of-{event_id}`
3. Original event preserved for audit
4. Bulk rollback (e.g., bad auto-promotion run): events tagged with batch_id, reverse all with single batch operation

**Catastrophic rollback** (AKB corrupted, vector index broken):
- Restore from zfs-backup → TrueNAS snapshot
- Replay curation events from log up to desired point
- Validate by smoke-testing key queries before bringing back online

## CLCA Cycle for AKB Itself

The AKB is subject to its own CLCA discipline:

**Defect detection**: agent acted on AKB chunk, outcome was wrong.

**Root cause analysis** (typical causes):
- Chunk promoted without adequate review (Bar A used where Bar C should have)
- Chunk was correct when promoted, source state changed, no drift detection
- Wrong chunk surfaced for question (retrieval miss, not curation miss)
- Narrative-correct but structurally misleading (Patton's V28 lesson)

**Corrective action**:
- Demote chunk from `validated` → `draft` or `deprecated`
- Fix promotion rigor for that chunk class (e.g., add to Bar C list)
- Add anti-pattern entry to AKB itself (recursive)

**Verification**:
- Same query no longer surfaces wrong chunk
- Promotion process audit confirms no similar chunks pending in promotion queue

**Prevention**:
- Promotion bar adjusted for chunk class
- Pattern added to `akb.curation_events` as cautionary precedent

**Cycle 0 equivalent**: AKB documents its own promotion-rigor expectations as Tier 0 / Tier 1 content. Recursive — the AKB knows what it's supposed to be.

## Human-in-the-Loop Curator

**Judge**: final arbiter on ambiguous promotion, spec changes, cross-cutting decisions. Reviews `akb.promotion_candidates` weekly or on escalation.

**Patton**: designated reviewer for failure-class promotion (Bar C primitive). Reviews on **his next invocation** (session-driven, not calendar-driven — see § Patton Presence Model above). Queue surfaces at session-start in his Tier 0.

**Watson, Bob**: can flag chunks via `akb.curation_events` (advisory). Cannot directly promote/demote. Can mark conflicts, suggest deprecation, propose promotion candidates.

**Einstein**: designated physics-reviewer for V16-touching promotion (Physics Bar C). Veto authority on the physics-side of V16 hybrid gate. Can flag any chunk via `akb.curation_events` (advisory). No promotion authority outside V16-touching content.

**Newton**: read-only by default. Can flag chunks (advisory) but no promotion authority.

## Open Questions

1. **Promotion rate target**: what's the operational expectation? If "many chunks/day," Bar A is implied (and LB-2 is unresolved). If "review-gated," Bar C is implied (operational tempo matters). Recommend: start slow, evaluate after 30 days of operation.
2. **Queue-size escalation threshold**: initial value is 25 candidates awaiting review. May need tuning against actual ingest volume. Start at 25, adjust monthly.
3. **Conflict-flag threshold**: cosine similarity > 0.85 for "potentially conflicting" is a guess. Calibrate against the actual corpus.
4. **Cross-role conflict propagation**: if a conflict is in `failure-mode` projection only, does it affect `design-intent` projection? Likely no, but conflicts spanning multiple projections need explicit handling.
5. **Non-git drift detection mechanism**: follow-up requirement noted under § Source-State Drift Scope. Design per source type (ClickHouse schemas, MCP versions, live infra config) once MVP ships.

## Failure Modes To Watch

- **Promotion queue overflow**: if Patton is overwhelmed by promotion candidates, queue stalls and content stagnates as `draft`. Mitigation: tighten ingest filters; not everything needs promotion.
- **Rollback chains**: a rollback that requires a rollback that requires a rollback. Indicates broken curation discipline. Mitigation: rollback of rollback requires Judge approval.
- **Drift detection blind spots**: source state changes that don't trigger a git commit (e.g., live infrastructure state, ClickHouse schema). Out of scope for git-based drift detection — *explicitly excluded from MVP* per § Source-State Drift Scope. Needs separate mechanism per source type before infrastructure-state chunks can be ingested.
- **Conflict registry rot**: `akb.conflicts` grows unbounded if conflicts aren't actively resolved. Mitigation: monthly conflict-resolution cadence as part of AKB CLCA cycle.

## Dependencies

- `akb.documents`, `akb.chunks`, `akb.curation_events`, `akb.conflicts`, `akb.queries`, `akb.promotion_candidates` tables
- Git post-commit hook for ingest trigger
- File watcher for non-git markdown content (NOT for infra state — explicitly excluded from MVP)
- MCP tool `akb_promote`, `akb_flag`, `akb_query` (read + curation operations)
- Patton session-start queue surface (Tier 0 / runbook injection) — **not** calendar timer
- Judge queue-overflow notification mechanism (when `akb.promotion_candidates` exceeds threshold)
- Embedding pipeline (BGE-large local on 9975)

## Success Criteria

- **Ingest pipeline operational**: git changes auto-trigger re-ingest within 5 minutes
- **Promotion stratification working**: failure-class chunks never auto-promoted; procedural chunks promoted automatically after signal
- **Conflict registry < 50 open**: open conflicts resolved on monthly cadence
- **Decay signal acted on**: zero-query chunks reviewed within 30 days of flag
- **Rollback exercised**: at least one intentional rollback test per quarter (dogfooding)
- **CLCA cycle running**: monthly AKB-CLCA cycle producing at least one corrective-action entry
