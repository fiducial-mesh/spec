---
title: "AKB Awareness Layer — Specification"
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
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
  - planning/akb-review-trajectory.md
  - planning/templates/akb-document-template.md
---

# AKB Awareness Layer — Specification

**Status**: Validated v0.4 — codifies the Tier-0 generator implementation contract that Bob's P1.7 build landed (extractor + snapshot + atomic symlink + fence-sentinels). v0.3 specified Tier-0 *conceptually* (size budget, contents, delivery, promotion gate) but did not specify the implementation discipline; Bob built it correctly under the conceptual spec, and v0.4 catches the spec up to the implementation so future rebuilds, model swaps, and source-content changes route through the same discipline.
**Scope**: How knowledge from the AKB reaches agents at the right moment
**Authors**: Watson (drafted v0.3), Bob (v0.4 Tier-0 generator contract), with structural input from Patton, Einstein
**Date**: 2026-06-02 (v0.4)

## Problem Restatement

The earlier framing — *"agents see only ~0.5% of the corpus per session"* — was wrong. Einstein's diagnostic reframe corrected it:

> *"20/442 is a Shannon bandwidth limit, not a cold-start. You lack a semantic state-vector. Pushing mass files blindly induces entropic context saturation."*

The real problem has two parts:
1. **Channel capacity**: agents have a finite working-memory ceiling. Pushing the full corpus saturates the channel and degrades reasoning.
2. **Semantic state-vector absence**: agents lack a compressed representation of "where am I in the problem space" that would gate which knowledge is relevant.

**Unconstrained push** (session-start digest, pre-task hook injection of top-N chunks) makes both worse — it spends bandwidth before the agent has formed a reasoning gradient that would tell it what to filter for.

## Architecture: Two-Tier

### Tier 0 — Bounded Always-Loaded Core (~1 KB)

**Purpose**: Provide the **prior** needed for reasoning gradients to form. Without Tier 0, an agent cannot articulate "I need to look up V25-α" because the agent does not know V25-α happened. Pure gradient-gating presumes the agent can articulate when it needs knowledge; Tier 0 is the bounded set that doesn't depend on articulation.

**Contents** (in priority order, ~1 KB total):

1. **Eight-dead-end list** — V23-V28+ characterized in one line each (`V25-α: 2D SFI sidecar → multiplicative-axis collapse`)
2. **V16 physics laws** — numbered, one-line each, marked LOCKED
3. **Security framework non-negotiables** — credentials in keyring only, no subprocess, HTTPS only, parameterized SQL only
4. **Current phase indicator** — production version (V22-γ), active workstream (Phase 5 Isaac Protocol)
5. **Layer A/B reminder** — what's public vs. private (one sentence)

**Size budget**: ~1 KB raw text, ~250 tokens. Hard cap — if Tier 0 grows beyond this, content must be promoted to Tier 1 or compressed.

**Update mechanism**:
- Auto-extraction proposes candidates on commit to canonical docs (CLAUDE.md, archive/planning/V*-RESULTS, MCP-SECURITY-FRAMEWORK)
- **Tier 0 promotion requires Judge approval per Bar B in `akb-lifecycle.md`**. Tier 0 is structurally higher trust than `validated`; auto-extraction proposes, humans confirm. Auto-regex on LOCKED markers is brittle (new LOCKED content would auto-promote without review), so promotion is gated on explicit human action.
- Rebuilt as a snapshot artifact after each Judge-approved promotion event, not generated per-query
- Versioned with timestamp + git commit hash + curation event ID

**Delivery**: injected into every agent session at start, in a clearly-marked block. Agent treats it as standing context, not user input.

### Tier 0 Generator Implementation Contract (v0.4)

The conceptual spec above (contents, size budget, delivery) is unchanged from v0.3. v0.4 adds the implementation contract that the P1.7 build landed (commit `5c09bf1`, merged at `2474cf5`). The contract governs how the generator extracts Tier-0 atomic facts from source documents, materializes them into the snapshot artifact, and exposes them to the agent session-start injection mechanism.

**Canonical source**: `ionis-devel/planning/tier0/akb-tier0-content.md` is the single authoritative source for Tier-0 atomic facts. The generator reads from this file, not from individual canonical docs (CLAUDE.md, V*-RESULTS, MCP-SECURITY-FRAMEWORK directly). This indirection is deliberate — it makes the Tier-0 set explicit and auditable rather than an implicit projection of canonical-doc structure.

**Source-content discipline**:
- Each Tier-0 atomic fact in the source file is bounded by **fence sentinels** — explicit markers that delimit a single fact from surrounding prose. Example shape: `<!-- BEGIN T0 dead-end-v25α --><content><!-- END T0 dead-end-v25α -->`. The exact sentinel form is the generator's implementation detail; the discipline is that facts are *explicitly delimited*, not heuristically extracted.
- Sentinels must be unique within the source file. The extractor MUST fail-strict on duplicate or unbalanced sentinels rather than silently producing partial output.
- Atomic-fact identifier (the sentinel name) is the generator's reference key and must be stable across edits — changing a sentinel name is a content-rename, not an edit, and requires the same Bar B Tier-0 promotion gate per `akb-lifecycle.md`.

**Generator pipeline** (`tier0/extractor.py` + `tier0/snapshot.py` + `akb-tier0` CLI):

1. **Parse**: read `planning/tier0/akb-tier0-content.md` and extract all fence-sentinel-delimited regions
2. **Validate**: assert each region is well-formed (begin/end balanced, name unique, content non-empty); fail-strict on any violation
3. **Size check**: compute total byte size of concatenated regions; **assert ≤ 1024 bytes (the Tier-0 hard cap from §Tier 0 above)**. The build fails with explicit error if the snapshot would exceed the cap — there is no silent truncation.
4. **Materialize**: write the snapshot to a versioned file (e.g., `tier0-snapshots/snapshot-<timestamp>-<git-hash>.md`) with a provenance header naming the source commit hash and the curation event ID that authorized the build
5. **Atomic symlink replacement**: update `tier0-snapshots/latest.md` to point at the new snapshot via `os.replace` (atomic on POSIX). Agents that read the symlink during the swap see either the old snapshot or the new one — never a partially-written file
6. **Log curation event**: write `event_type='tier0_snapshot'` to `akb.curation_events` with the snapshot path, byte size, source commit hash, and the Bar B Judge-approval message ID

**Headroom safeguard** (Bob's P1.7 discipline): the build asserts the snapshot is **≤ 95% of the 1024-byte cap** (= 972 bytes) as a warning threshold, not just at the hard cap. The 5% headroom is for last-mile size variance (different newline conventions, sentinel growth, etc.) and gives operators a signal that the next Tier-0 promotion will likely trigger demotion of an existing entry.

**Promotion path** (unchanged from v0.3, integrated with the generator):
- Auto-extraction proposes candidates on commit to canonical docs (CLAUDE.md, archive/planning/V*-RESULTS, MCP-SECURITY-FRAMEWORK). The proposal lands in `akb.promotion_candidates` with `target_tier=tier0`.
- **Judge approves via Bar B** per `akb-lifecycle.md` § Promotion Discipline. Approval triggers an edit to `planning/tier0/akb-tier0-content.md` (the source) with a new fence-sentinel-delimited region added.
- The edit goes through standard git commit + post-commit hook; the next generator run picks up the new region, validates, builds the new snapshot, and atomically replaces the symlink.
- No Judge approval = no source edit = no snapshot regeneration. The Judge gate is at the *content* layer, not the *build* layer.

**Re-generation triggers**:
- Source change to `planning/tier0/akb-tier0-content.md` on **`main`** of `ionis-devel` (git post-commit hook on the merged source) → trigger generator
- Operator command (`akb-tier0 build`) for **manual rebuild from the merged main source only** — see deployment-bypass clause below
- Bootstrap of AKB itself triggers Tier-0 generation as a build step, reading from the source state on `main` at the bootstrap event

**Regeneration cannot bypass review — explicit clauses** (per Patton's PR-#61 confirmation):

1. **Source edits are Bar-B-gated**: any change to `planning/tier0/akb-tier0-content.md` requires PR review and Judge merge to `ionis-devel/main` — same as any canonical doc. The Bar B Judge approval per `akb-lifecycle.md` § Promotion Discipline gates the *content* layer, before any build runs.
2. **Deployed snapshot must be built from merged source only**: the snapshot artifact deployed to the AKB runtime (the file the `latest.md` symlink points at) MUST be built from the source state on `main` of `ionis-devel`. Local builds via `akb-tier0 build` against unmerged or developer-edited source produce snapshots that are **explicitly NOT deployable** — they are for development and verification only. Deploying a local-build snapshot bypasses Bar B review and is a defect requiring rollback to the last merged-source-built snapshot.
3. **Operator manual rebuild is a re-execution, not a re-review**: running `akb-tier0 build` against current merged main source rebuilds the snapshot deterministically. The content is unchanged (because source is unchanged); the snapshot is identical to the last build modulo timestamp. There is no path from `akb-tier0 build` to "new Tier-0 facts in the snapshot" without first editing source through a PR.
4. **The build is downstream of review, not a substitute for it**: the generator is deterministic and stateless w.r.t. content authority. It cannot grant Tier-0 status to anything not already in the source; it cannot bypass any review gate; it cannot emit content that was not committed to `main` via a Judge-merged PR. The build is mechanical; review is governance; the two layers are deliberately separable but the deployment chain locks them together.

**What this prevents**:
- An operator with build access cannot deploy "their preferred Tier-0 set" by running `akb-tier0 build` against a local fork.
- A compromised build script cannot insert content not present in source — the generator reads only fence-sentinel-delimited regions, and adding regions requires source-file commit through review.
- A regeneration run after a content-author mistake (deleted a fence sentinel locally) cannot deploy partial content — the deployment chain reads merged source, not local working tree.

**Failure modes the contract prevents**:
- **Silent oversize snapshot**: hard-cap assertion at build time rejects oversized output rather than letting it land
- **Partially-written snapshot read by agent mid-build**: atomic symlink replacement guarantees readers see complete files only
- **Drift between source content and snapshot**: snapshot's provenance header records the source commit hash; verification check compares header to current source on demand
- **Unauthorized promotion**: promotion requires source-file edit, source-file edit requires PR review and Judge merge — no out-of-band path from "I think this should be Tier 0" to "agents see this in every session"

**Verifier path** (Bob's P1.7 verification, per `scripts/verify-tier0.sh`):
- Re-parse the snapshot, assert byte count matches, assert provenance header is well-formed
- Compare snapshot content to the source-file fence regions; assert match
- Confirm symlink target is the latest versioned snapshot
- Replay the curation event chain and confirm Bar B Judge approval ID is present for every fact in the snapshot

### Tier 1 — Gradient-Gated Injection

**Purpose**: Mid-reasoning, signal-driven knowledge perturbation along the agent's current reasoning gradient. Treats knowledge as **targeted activation energy**, not background context.

**Trigger mechanisms** (MVP — only two; implicit triggers deferred):

1. **Explicit agent query**: agent calls `akb_query(terms, role_context)` based on its own assessment. Standard MCP tool call.
2. **Hook-based mandatory triggers**: certain operations force a query in their domain *before* execution. Runtime-enforced via settings.json hooks, not agent discretion. Examples:
   - Before `Edit` or `Write` on a file matching pattern P → `akb_query(domain_for_P)`
   - Before `git commit` → `akb_query(changed_files_domain)`
   - Before MCP plugin invocation → `akb_query(plugin_history)`

**Deferred trigger types** (not in MVP):
- *Implicit uncertainty signal* (phrase-pattern matching on "I'm not sure," "let me check") was considered and **explicitly dropped from MVP**. Two reasons: (1) phrase-pattern matching is unreliable — agents express uncertainty in many ways, false negatives go silent; (2) gameable in the wrong direction — once agents know phrase-X triggers a query, they may avoid phrase-X to skip it, or over-use it; either way the signal degrades. Revisit only if real operational data from explicit + hook triggers proves insufficient.

### Tier 1 Query Flow — Deterministic Pre-Filter Before Vector Search

Einstein's substrate-trap finding (v0.3 addition): the underlying embedding model is a semantic similarity model. It clusters by linguistic proximity, not physical correctness. V25-α failure post-mortems and V16-compliant design proposals share vocabulary; their cosine similarity is high. **Vector retrieval alone surfaces dead-end content as candidate solutions to physics queries.** Role projection filters *after* the physics-blind retrieval step and therefore cannot prevent this.

**Fix**: query flow executes deterministic pre-filtering *before* vector distance is calculated.

**Authoritative query flow**:

```
1. Deterministic pre-filter:
   - Exclude chunks where violates_invariant=true
   - EXCEPT when query is explicitly historical (e.g., "what did V27 try?"
     or invariant_class matches the user's intent)
2. Vector similarity search on the filtered set
3. Role projection (WHERE roles = caller_role) per akb-reasoning-independence.md
4. Selective-exemption check (per akb-reasoning-independence.md)
5. Reranker on remaining candidates
6. Return top-K with metadata
```

Vector math is downstream of physics math, not upstream. The substrate is still semantic, but the chunks the substrate operates on are pre-filtered to exclude known-violators of the physical invariants the lab cares about.

**Why this matters operationally**: without step 1, a Watson query for "SFI sidecar architecture" returns chunks describing the V25-α 2D-collapse failure as high-similarity candidates because they share vocabulary with V16-compliant solutions. Step 1 makes the dead-end list a query-time blocklist, not just a prior in Tier 0. The eight-dead-end list now serves three purposes: prior in Tier 0, query-time exclusion in Tier 1, and constraint check in promotion discipline (`akb-lifecycle.md`).

### Injection Mechanism

- Top-N chunks returned (default N=5, configurable per trigger)
- Each chunk carries metadata: `source_file:header_path`, retrieved-at timestamp, confidence tier, relevance score, `violates_invariant` flag (will always be `false` for non-historical queries; `true` only when query was explicitly historical and chunk was deliberately included)
- Volume budget: max 10 chunks (~3 KB total) per injection event
- Format: structured block, clearly delimited from agent reasoning ("AKB context:")

**Hook contract** (runtime ↔ agent):
- Hook fires before tool execution, blocks if AKB query is mandatory and not yet performed
- Agent receives AKB results as additional context, then proceeds
- AKB unavailability = empty results, **never an error** (fail-open per Patton's T-6)
- Agent must handle empty/down case identically — robustness from day one

### Agent ↔ Runtime Contract

**Session start**:
1. Agent receives Tier 0 as standing context
2. Agent declares intent (implicit from initial prompt or explicit role marker)
3. Runtime registers session for hook triggers based on declared role + intent

**During session**:
1. Agent reasons; runtime monitors tool calls
2. Mandatory hooks fire on protected operations (edit, commit, plugin invoke)
3. Agent can also query explicitly via `akb_query` MCP tool at any time

**Session end**:
1. Query log + outcome signals persisted to `akb.queries` table (see `akb-lifecycle.md` § Decay Signals for how this table feeds back into curation)
2. Feedback loop closes — what was retrieved, was it used, was the outcome successful. **Outcome signals are consumed by the lifecycle layer's decay-signal mechanism**, not by awareness layer directly.

## Why Session-Start Push Is Dead

Bob's original Awareness Layer proposal was session-start auto-injection of task-relevant digest + pre-task hook injecting top-N. Einstein falsified this: **unconstrained push guarantees context collapse.** Same structural pattern as V25-α — multiplicative paths the optimizer collapses to one. Pushing the corpus saturates the channel before the gradient can form.

**What replaces it**:
- Tier 0 (bounded, gradient-prior providing) **YES** — small enough not to saturate
- Tier 1 mid-reasoning gradient-gated injection **YES** — signal-driven, targeted
- Session-start mass push **NO** — saturates before reasoning starts
- Pre-task hook injection of unfiltered top-N **NO** — same failure mode, slightly later

The mechanism is **mid-reasoning, gradient-triggered, signal-gated**. Not session-start. Not task-start. Mid-reasoning, when a gradient exists and can target what's actually needed.

## Open Questions

1. **Tier 0 update cadence**: per-commit-to-canonical (event-driven) vs. daily snapshot (timer-driven). Recommend: commit-event-driven rebuild *proposal*, then Judge approval batched on weekly cadence to avoid Tier 0 churn. Tier 0 stability matters more than freshness — agents reason against a moving Tier 0 unreliably.
2. **Tier 1 injection latency tolerance**: synchronous (block agent until AKB returns) vs. async (agent continues, AKB results arrive in subsequent turn)? Synchronous is simpler; async preserves reasoning flow. Start synchronous, evaluate.
3. **Role context handling**: does the agent declare its role explicitly, or does the runtime infer from session context (which agent slot, which host)? See `akb-reasoning-independence.md` § Task-Type Detection — same explicit-declaration-as-primary principle applies.

## Failure Modes To Watch

- **Tier 0 bloat**: ~1 KB cap must be enforced. Without enforcement, Tier 0 grows until it itself causes saturation. Cap is non-negotiable.
- **Hook bypass**: agents can technically construct edits that bypass hook triggers (e.g., direct API calls). Hook enforcement must be at the runtime tool-call layer, not at the agent layer.
- **Query specificity collapse**: if agents learn to query vaguely (low specificity), top-N returns mostly noise. Reranker quality matters more than corpus depth.
- **AKB unavailability silent failure**: fail-open is correct, but agents must still know AKB was unavailable (status field), so they don't trust empty results as "no relevant knowledge exists."
- **Substrate trap (Einstein, v0.3)**: vector retrieval is physics-blind. Mitigation: deterministic pre-filter on `violates_invariant` before vector search (see § Tier 1 Query Flow). Without this, semantic similarity surfaces dead-end content as candidate solutions to physics queries.
- **Invariant-flag miscoding**: a chunk that should be `violates_invariant=true` ingested as `false` (or vice versa) makes the pre-filter unreliable. Mitigation: per-doc-type default rules at ingest, override via curation event with audit trail. Periodic CLCA review of `violates_invariant` assignments on high-traffic chunks.

## Dependencies

- Tier 0 generation pipeline (extractor from CLAUDE.md + archive/V*-RESULTS + security framework) with Judge-approval gate per `akb-lifecycle.md` § Promotion Discipline (Bar B)
- MCP wrapper for `akb_query` (Layer B.3 build)
- Runtime hook framework (settings.json or PCS plugin)

## Success Criteria

- **Tier 0 always present**: every agent session begins with the bounded core, verified by inspection. Tier 0 byte size measured at session start, must be ≤ 1024 bytes.
- **No session-start mass push**: zero documents > 5 KB injected at session start, measured by session-start context-block inspection.
- **Hooks fire reliably**: mandatory triggers cannot be bypassed by agents in standard flows. Measured by: % of protected tool calls that have a corresponding hook-fired `akb.queries` entry within the prior 30 seconds (target: ≥ 95%).
- **Channel capacity preserved**: total bytes injected by AKB (Tier 0 + cumulative Tier 1) over a session ≤ 25% of the agent's effective working-context budget. Measured as `sum(akb_injection_bytes) / context_window_bytes` per session, p50 ≤ 0.10, p95 ≤ 0.25.
- **Gradient gating works**: queries fired mid-reasoning have measurably higher relevance than session-start digests would have had (A/B testable — log Tier 1 injection chunks separately from a control "session-start digest of same byte budget" and compare downstream agent-flag-as-useful rates).
- **Substrate trap prevented**: for non-historical queries, zero returned chunks have `violates_invariant=true`. Measured as `count(returned_chunks WHERE violates_invariant=true AND query.is_historical=false) / count(total_returned_chunks)` = 0. Hard target — any non-zero result is a defect requiring CLCA.
