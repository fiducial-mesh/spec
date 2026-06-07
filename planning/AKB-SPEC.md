---
title: "AKB Spec — Agent Knowledge Base pillar"
doc_type: spec
status: draft
version: v0.1
authors:
  - watson
date: "2026-06-07"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/MESH-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/akb-awareness-layer.md
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
  - planning/akb-migration-plan.md
  - planning/akb-cross-role-audit.md
  - planning/akb-review-trajectory.md
  - planning/templates/akb-document-template.md
  - planning/tier0/akb-tier0-content.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/IBX-SPEC.md
---

# AKB Spec — Agent Knowledge Base pillar

**Scope**: The Agent Knowledge Base pillar — how multi-agent knowledge is ingested, projected per agent role, surfaced at the right moment in agent reasoning, and curated over time without drift.

**Status**: **Draft v0.1** — distills the six v0.4 AKB design documents (awareness-layer, reasoning-independence, lifecycle, migration-plan, cross-role-audit, review-trajectory) into a consolidated pillar manifest against `PILLAR-SPEC-TEMPLATE.md` v1.0. The design documents remain as supporting / reference material; this spec is the canonical contract.

**Implementation home**: `fiducial-mesh/core/python/akb` — alongside `python/ibx` and `python/mcc` in the Fiducial Mesh core monorepo.

## Purpose / Problem Restatement

The mesh has a growing corpus of authored knowledge — specs, planning docs, post-mortems, runbooks, security frameworks, friction catalog entries — fragmented across multiple repos under `ionis-ai/`, `fiducial-mesh/`, `ki7mt/`, and `qso-graph/`. Agents currently see only the subset they explicitly read per session (CLAUDE.md + a handful of files). The rest is functionally invisible.

The naive fix — "push the corpus into context at session start" — fails on two physics grounds (Einstein, Round 3 of the review trajectory):

1. **Channel capacity**. Agents have a finite working-memory ceiling. Bulk push saturates the channel before a reasoning gradient can form to tell the agent what to filter for. Context collapses.
2. **Semantic-state-vector absence**. Without a compressed prior, agents can't articulate "I need to look up V25-α" because they don't know V25-α happened.

The AKB pillar's contract is therefore: **bounded prior at session start (Tier 0)**, **gradient-gated injection mid-reasoning (Tier 1)**, **role-projected retrieval** to preserve dialectical-engine reasoning independence, and **substrate-trap-aware query flow** so the vector substrate (which is physics-blind) cannot surface dead-end content as candidate solutions to physics queries.

The pillar exists because brief-drift, knowledge-rot, and accidental-context-saturation are observable failure classes in the current mesh, not hypothetical ones.

## Approach / Architecture

### Two-tier delivery

**Tier 0 — bounded always-loaded prior (≤ 1024 bytes)**
- Injected at every agent session start as standing context (not user input)
- Contains: eight-dead-end list (one line each), V16 physics laws (LOCKED), security non-negotiables, current production phase, Layer A/B reminder
- Source of truth: a single fence-sentinel-delimited markdown file (canonical path `planning/tier0/akb-tier0-content.md` in the spec repo today; ingested into the AKB build's snapshot pipeline)
- Promotion gated by Bar B (Judge approval per the Lifecycle section)

**Tier 1 — gradient-gated mid-reasoning injection**
- Two trigger classes: **explicit agent query** (`akb_query(terms, role_context)` MCP tool) and **hook-based mandatory triggers** (runtime-enforced via settings.json hooks)
- Hook trigger domains:
  - Code-author-side: `Edit` / `Write` on protected file patterns; `git commit`; MCP plugin invocation
  - **Infra-decision-side (new, per Bob 2026-06-07)**: `git push`; `gh pr create` / `gh pr review`; deploy commands; substrate config edits. These are the decision points where today's cutover-trap pain class lives — pushing into a half-flipped backend, sending into the wrong inbox, deploying a stale snapshot — and they fire *before* the irreversible step
- Volume budget: ≤ 10 chunks per injection event, ≤ 3 KB total
- Fail-open: AKB unavailability returns empty results, **never an error**; agents handle empty / down identically (Patton's T-6)

### Query flow — deterministic pre-filter before vector search

The vector substrate (e.g., `bge-large-en-v1.5`) clusters by linguistic proximity, not physical correctness. V25-α failure post-mortems and V16-compliant designs share vocabulary; their cosine similarity is high. Vector retrieval alone surfaces dead-end content as candidate solutions to physics queries.

The authoritative query flow is (Einstein, Round 5 of the review trajectory):

1. **Deterministic pre-filter** — exclude chunks where `violates_invariant=true`, EXCEPT when the query is explicitly historical (e.g., `invariant_class` matches the user's intent)
2. **Vector similarity** search on the filtered set
3. **Role projection** — `WHERE roles ⊇ caller_role`
4. **Selective-exemption check** — exempt agent/task combinations skip the query entirely (Patton-on-review, Einstein-on-falsification)
5. **Reranker** on remaining candidates
6. Return top-K with metadata (`source_file:header_path`, retrieved-at timestamp, confidence tier, relevance score, `violates_invariant` flag)

**Vector math is downstream of physics math**, not upstream. The substrate stays semantic; the chunks the substrate operates on are pre-filtered to exclude known invariant-violators.

### Storage shape

Single source of truth in `akb.chunks` — no per-agent duplication. Projection happens at retrieval time, not storage time. Each chunk carries:

- `source_file`, `repo`, `header_path`, `position` — provenance
- `last_modified`, `git_author`, `git_commit` — change tracking
- `doc_type` — bounded enum (`spec | planning-active | planning-draft | archive | v-results | friction | clca | runbook | shared-context | inbox-derived`)
- `roles: Array(LowCardinality(String))` — projection axis (`design-intent | infrastructure | failure-mode | physics | astrophysics`)
- `confidence` — trust tier (`draft | validated | deprecated | superseded`)
- `author_id` — used for self-review exemption
- `violates_invariant: Bool` — pre-filter key
- `invariant_class: LowCardinality(String)` — specific invariant when `violates_invariant=true` (e.g., `V25-α`, `V27-PIL`, `V16-clamp`)

### Reasoning independence — role projection + selective exemption

The dialectical engine works because agents reason from **different priors over the same evidence**. A naive shared substrate converges those priors — same query, same top-K, error diversity dies. Two mechanisms preserve independence:

1. **Role-projected retrieval** — same underlying chunks, different *views* per agent role (Watson sees `design-intent`, Patton sees `failure-mode`, etc.). Default role assigned at ingest by directory-path heuristic; per-chunk overrides via curation event
2. **Selective exemption** — specific agent × task-type combinations bypass the AKB entirely. Patton-on-review queries the raw corpus instead; Einstein-on-falsification produces independent verdicts. Generalized via `author_id`: any agent reviewing their own work is exempt

**Cross-role budget**: a hard cap of **50 distinct documents** (per-document, not per-chunk — Patton's ruling, codified after Bob's bootstrap dry-run surfaced the unit ambiguity) whose frontmatter spans all five roles. Per-chunk cross-role count is preserved as a non-blocking advisory signal.

### Promotion — stratified by content class

| Bar | Content class | Mechanism |
|-----|---------------|-----------|
| **A — Auto** | Procedural docs, reference content, routine planning | Query log + outcome signal indicates N successful uses → auto-promoted to `validated` |
| **B — Judge-gated** | Spec changes (security framework, MCP contracts), cross-cutting architectural decisions, Tier-0 content | Judge approval via MCC inbox-ui |
| **C — Patton-veto** | Failure-class chunks (V*-RESULTS, dead-end docs), architectural decisions, anti-patterns, CLCA outputs | Candidate queues; Patton reviews on **next invocation** (session-driven, not 7-day-calendar) |
| **Physics Bar C** | V16-touching changes | Both Judge **and** Einstein must approve — two-key gate, neither alone sufficient |

Patton presence is session-bounded on Claude Desktop. No wall-clock-timer escalation; queue-size threshold (initial: 25 awaiting) triggers a `akb_queue_overflow` notification to Judge.

### Bootstrap pre-write gate

Any ingest event writing ≥ 20 chunks (bootstrap, embedding-model swap, schema migration, large backfill) must pass through a dry-run + Patton review + Judge `--apply` chain. Routine git-post-commit re-ingests on single-file edits are NOT gated; they flow through the standard chunking + embedding path.

Dry-run report blocks the gate on:
- Cross-role document count > 50
- Inherited-over-tagging suspects outside the expected-domain allowlist
- Default-rule (no-specific-match) count > 0
- Pre-filter contract violations (`violates_invariant=true` chunks missing `invariant_class`, etc.)

The gate is the cheap CLCA chokepoint; post-write cleanup is the expensive one. Skipping it is a defect requiring rollback, not a shortcut.

### Corpus walk — multi-org-folder (post-rebrand, post-restructure)

The corpus is fragmented across the workspace's org-folder layout:

```
~/workspace/
├── ionis-ai/             # IONIS lineage (model + analytics)
│   ├── ionis-devel/      # planning, archive/V*-RESULTS, shared-context, papers
│   └── ionis-mcp/        # MCP server docs
├── fiducial-mesh/        # the mesh
│   ├── spec/             # this repo
│   ├── core/             # implementation monorepo (where AKB lives)
│   └── devel/            # build-plan, ansible plays
├── ki7mt/                # KI7MT personal
│   ├── ki7mt-ai-lab-devel/    # master CLAUDE.md, IONIS-THESIS.md, SOVEREIGN-STACK.md
│   └── fleet-ops/        # runbooks, ansible
└── qso-graph/            # ham radio MCPs
    └── *-mcp/            # READMEs (selective ingest)
```

Path-inference rules in the supporting migration-plan doc must be reconciled to this layout. (Bob's lane — see § Open Questions OQ1.)

## Substrate Matrix

Per MI-8 + § Tested Substrate Profiles in `MESH-SPEC.md`, this pillar's substrate substitutability is defined as **passing the multi-profile conformance run** against the matrix below. Wording is **role + version floor** (never vendor-named) so the matrix names a *contract*, not a *product*.

| Seam | Contract | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|----------|-------------------------------------|----------------------------------------|
| **Chunk + embedding store** | Vector similarity search + filtered SQL on metadata; ANSI SQL + JSONB-equivalent + vector type with cosine distance + HNSW indexing | PostgreSQL 15 + pgvector 0.5 | Qdrant 1.7 (Apache-2.0, single-binary Rust, Prometheus-native, strong metadata filtering — escalation alternate when vector search becomes the *primary* workload, i.e. > ~50–100M vectors); Milvus 2.x (only at billion-vector / Kubernetes scale) |
| **Embedding service** | Text → fixed-dimension vector via local API or HTTP; deterministic for the same model+content | BAAI/bge-large-en-v1.5 (1024-dim, local GPU) | voyage-3-large; text-embedding-3-large; nomic-embed-text-v1.5 |
| **Corpus source** | Git-tracked markdown across the lab's org-folder repos | GitHub (multi-org: `ionis-ai/*`, `fiducial-mesh/*`, `ki7mt/*`, `qso-graph/*`) | GitLab; self-hosted Gitea; mirrored git on TrueNAS |
| **Tier-0 snapshot store** | Atomic file replacement with versioned chain + content hash provenance | Local POSIX filesystem with `os.replace` | Object store with versioning (S3-API compatible) |
| **Curation event store** | Append-only event log with replay; structured JSON or row-per-event | PostgreSQL `akb.curation_events` (same Substrate as chunks) | Any append-only event substrate honoring the contract |
| **Telemetry sink** | OTLP-on-the-wire (traces + metrics) + JSON logs to stderr | Customer-selected via `OTEL_EXPORTER_OTLP_ENDPOINT` | Same — sink is per-deployment |

**Conformance**: CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set. A seam change that fails any tested profile does not merge (CD15).

**Out-of-set substrates**: A deployment using a substrate not listed above is **not covered by this pillar's substitutability claim** — it requires a new profile definition (CONF-CD11) + conformance suite extension + the multi-profile run passing before merging.

## Telemetry Contract

Per MI-11, AKB emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr. The sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; the mesh does not name the backend.

**Implementation context (per Bob, 2026-06-07)**: AKB is the **first MI-11 telemetry implementation** in the built mesh. The other built pillars (IBX, MCC) shipped before the MI-11 telemetry contract landed and carry **zero OpenTelemetry instrumentation today**. The retrofit of IBX + MCC to the telemetry contract is queued for the ACT era. AKB's emission therefore exercises the MI-11 contract from clean ground — no pattern to be "consistent with" except the spec itself.

Naming convention follows the fleet pattern already in `CRB-SPEC`, `DPG-SPEC`, `ACT-SPEC`, `PCS-DAEMON-SPEC`: `mesh.akb.<operation>` for spans, `mesh.akb.<metric>` for metrics. The retired `som.*` prefix is not used.

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| Tier-1 query against `akb.chunks` | `mesh.akb.query` | `role`, `task_type`, `is_historical`, `returned_count`, `top_k_relevance` |
| Tier-0 snapshot build | `mesh.akb.tier0_snapshot` | `source_commit`, `byte_size`, `fact_count` |
| Single-document ingest (chunk + embed) | `mesh.akb.ingest_document` | `source_file`, `doc_type`, `chunk_count`, `embedding_model_version` |
| Bootstrap event (full corpus walk) | `mesh.akb.bootstrap` | `event_type`, `batch_id`, `source_corpus_commits`, `chunk_count` |
| Promotion event (any bar) | `mesh.akb.promote` | `bar`, `chunk_id`, `from_tier`, `to_tier`, `approver_identity` |
| Curation event (role/tier/invariant change) | `mesh.akb.curate` | `event_type`, `chunk_id`, `field_changed`, `before`, `after` |
| Hook-triggered query | `mesh.akb.hook_query` | `hook_kind` (edit/commit/push/pr/deploy), `triggering_tool`, `query_terms` |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `mesh.akb.query_latency_ms` | histogram | ms | End-to-end Tier-1 query latency (pre-filter + vector + rerank) |
| `mesh.akb.queries_total` | counter | events | Tier-1 queries fired, labels: agent, role, task_type, hook_kind |
| `mesh.akb.chunks_total` | gauge | rows | Live chunk count in `akb.chunks` (excludes deprecated) |
| `mesh.akb.cross_role_documents` | gauge | docs | Current cross-role document count (against 50-document cap) |
| `mesh.akb.tier0_bytes` | gauge | bytes | Current Tier-0 snapshot size (against 1024-byte cap) |
| `mesh.akb.promotion_queue_depth` | gauge | candidates | `akb.promotion_candidates` count, labels: bar, status |
| `mesh.akb.injection_bytes_per_session` | histogram | bytes | Bytes injected per session (Tier 0 + cumulative Tier 1) |
| `mesh.akb.zero_query_chunks` | gauge | rows | Chunks unretrieved in last 90 days (decay-signal feed) |
| `mesh.akb.conflicts_open` | gauge | rows | Open conflicts in `akb.conflicts` |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| Tier-0 snapshot built | info | `source_commit`, `byte_size`, `headroom_pct` |
| Bootstrap pre-write gate cleared | info | `dry_run_report_hash`, `patton_sign_off_msg_id`, `judge_apply_msg_id` |
| Bootstrap pre-write gate blocked | warn | `block_reason`, `over-broad-tagged_docs[]`, `default_rule_count` |
| Promotion approved | info | `bar`, `chunk_id`, `approver_identity` |
| Promotion blocked | warn | `bar`, `chunk_id`, `block_reason`, `blocker_identity` |
| AKB unavailability (fail-open path taken) | error | `caller_agent`, `triggering_hook`, `last_known_health` |
| Substrate-trap pre-filter rejection | info | `chunk_id`, `invariant_class`, `query_was_historical` |
| Cross-role budget breach detected | warn | `doc_count`, `cap`, `offending_docs[]` |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name`, `service.version`, `deployment.environment` — resource attributes
- `identity`, `session`, `trace_id`, `span_id` — event attributes
- `cost-center` — when ACT chargeback applies (per CD on ACT integration)

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT`
- **Logs**: JSON to stderr (stdout is reserved for MCP protocol channel)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields

### Explicitly NOT in this spec

- Collector deployment topology
- Backend choice (App Insights, Datadog, Grafana/Tempo, Azure Monitor, etc.)
- Dashboards, alerts, retention policies, sampling strategy

These are deployment-side concerns governed by the Telemetry-sink seam.

## Closed Decisions

| CD | Decision | Source |
|----|----------|--------|
| **CD1** | Two-tier delivery: Tier 0 always-loaded prior ≤ 1024 bytes + Tier 1 gradient-gated injection. Session-start mass push is forbidden | awareness-layer §Architecture |
| **CD2** | Substrate-trap pre-filter on `violates_invariant` runs *before* vector similarity. Vector math is downstream of physics math | awareness-layer §Tier 1 Query Flow; Einstein Round 5 |
| **CD3** | Role projection at retrieval time, not storage time. Single source of truth in `akb.chunks` with per-chunk `roles` array. No per-agent isolated AKBs | reasoning-independence §Role-Projected Retrieval |
| **CD4** | Promotion stratified by content class: Bar A (auto for procedural), Bar B (Judge), Bar C (Patton-veto for failure-class), Physics Bar C (Judge + Einstein two-key for V16-touching) | lifecycle §Promotion Discipline |
| **CD5** | Self-review exemption generalized: any agent reviewing their own work is exempt from AKB queries on that task. Mechanism: `(querying_agent_id == artifact.author_id) AND (task_type == 'review')` | reasoning-independence §Generalized Principle |
| **CD6** | Patton presence is session-driven, not calendar-driven. No 7-day-timer escalation; queue-size threshold + Judge cadence are the operational levers | lifecycle §Patton Presence Model |
| **CD7** | Cross-role hard cap is per-document N=50, not per-chunk. Per-chunk count preserved as non-blocking advisory signal | reasoning-independence §Cross-Role Document Budget; Patton ruling `8238714a` |
| **CD8** | Bootstrap pre-write gate (dry-run + Patton review + Judge `--apply`) required for any ingest event writing ≥ 20 chunks. Skipping the gate is a defect, not a shortcut | lifecycle §Pre-Write Gate |
| **CD9** | Tier-0 source-edits are Bar-B-gated; deployed snapshots only from merged-`main` source. Local builds via `akb-tier0 build` are explicitly NOT deployable | awareness-layer §Tier 0 Generator Implementation Contract |
| **CD10** | Frontmatter authoring contract: default narrowly on roles; all-5-roles requires explicit justification subject to the per-document cap | migration-plan §A.1.2 |
| **CD11** | Inherited-over-tagging detection hook at bootstrap dry-run blocks until each flagged document is source-corrected or added to the expected-pattern allowlist with justification | migration-plan §A.1.3; Patton ruling `c6773933` |
| **CD12** | Source-state drift detection is git-based only in MVP. Non-git drift (PostgreSQL schemas, MCP server versions, deployed infrastructure config) is explicitly excluded and tracked as a follow-up requirement, not papered over | lifecycle §Source-State Drift Scope |
| **CD13** | Fail-open on AKB unavailability: hooks return empty results, never error. Agents handle empty / down identically. Status field on results so agents don't trust empty as "no relevant knowledge exists" | awareness-layer §Failure Modes; Patton T-6 |
| **CD14** | **(New, 2026-06-07)** Tier-1 hook trigger domains include both code-author-side (edit, commit, plugin invoke) *and* infra-decision-side (git push, gh pr create / review, deploy commands, substrate config edits). Today's cutover-trap pain class lives in the infra-decision-side; firing the AKB hook before the irreversible step is the design lever that catches it | Bob 2026-06-07 |
| **CD15** | **Conformance-enforced substrate-neutrality** — AKB's substitutability claim is defined as passing the multi-profile conformance run (CONF-CD1..11) against **≥ 2 products per seam** from the § Substrate Matrix supported set. A seam change that fails any tested profile does not merge. Instantiates mesh-level CD15 at the pillar layer; the references at § Substrate Matrix Conformance and § How this spec fits the mesh resolve here | mesh-level CD15 / CONF-CD framework |
| **CD16** | **(New, 2026-06-07)** AKB chunk + embedding store is **PostgreSQL + pgvector**, on the same Postgres the mesh already runs (IBX, PCS). ClickHouse is **explicitly excluded** as an AKB substrate alternative. Principle: *keep off ClickHouse anything that doesn't need OLAP* — AKB's chunk store (tens of thousands of vectors, < 50M) is not an analytical workload and belongs on the shared OLTP substrate ("one system, one backup, one monitoring stack, one team that already knows the infra"). pgvector handles ~50M-class vector workloads at high recall well within OLTP envelope. Escalation alternates (when vector search becomes the *primary* workload): Qdrant > ~50–100M vectors; Milvus only at billion-vector / Kubernetes scale. The CH→PG migration of the existing `python/akb` build maps onto the live IBX pattern, **split by mutability** (per Bob, PR #54): **mutable content tables** — `chunks`, `documents` (re-embedded on source file edit, chunk_id stable) — `ReplacingMergeTree(version)` → `INSERT … ON CONFLICT (chunk_id) DO UPDATE` upsert (the dedup-on-version semantic preserved at the PG layer); **immutable audit tables** — `curation_events`, `queries` (append-only by spec) — `MergeTree` → plain append-only PG tables matching the live `ibx.status_event` shape exactly. Common: HNSW `vector_similarity` → pgvector `USING hnsw (embedding vector_cosine_ops)`; CH user grant → PG role scoped to `akb` schema. Low-risk because the append-only pattern is already built + tested in IBX | Judge 2026-06-07, resolving Bob's PR #53 substrate conflict; Bob refinement 2026-06-07 on PR #54 |
| **CD17** | **(New, 2026-06-07)** AKB exposes an **HTTP API** (FastAPI, same pattern as MCC) alongside the MCP server and CLI. The HTTP layer is a thin wrapper over the same service module the CLI calls — no duplicate logic. OpenAPI spec is **generated and committed** to the repo at `fiducial-mesh/core/python/akb/openapi.json` per the export-and-commit pattern in `fiducial-mesh/core#9`. Docs wire against the committed file path, not the live URL. **Rationale**: MCC's AKB pane must be a thin client of the AKB API surface per the CLI-first/UI-second discipline (AC#4); shelling out to the CLI or reading `akb.chunks` directly via SQL would couple MCC to the storage schema and break the "MCC is a client, never privileged" boundary. The HTTP API also gives external clients (CI, customer monitoring, future GH App integrations) a typed interface that the MCP stdio surface cannot serve | Judge 2026-06-07 |
| **CD18** | **(New, 2026-06-07)** AIRs authored to `fiducial-mesh/air/reports/AIR-*.md` are **first-class AKB corpus content** with `doc_type: air-report`, `violates_invariant: false` (operational lessons surface at decision points — distinct from `v-results` which carry `true`), and baseline `roles: [failure-mode, design-intent]` + pillar-specific roles per the AIR's `incident_class`. Tier-1-only (not Tier-0). Surfaced via the CD14 infra-decision hook triggers — agent about to `git push` / `gh pr` / deploy fires AKB query → AIR-002 F-2/F-3 surface as relevant lessons. Security-class AIRs (`incident_class: security` or `audience: restricted`) are **categorically excluded** from ingest per `AIR-SPEC-DESIGN-NOTES.md` § 1.4. **Rationale**: closes the AIR + AKB + PCS containment loop articulated in `AIR-SPEC-DESIGN-NOTES.md` § 1 — AIR captures, AKB retrieves, PCS enforces. See addendum E + `akb-migration-plan.md` § Phase A.1.4 | Judge 2026-06-07 |

## Open Questions

| OQ | Question | Status / Recommendation |
|----|----------|-------------------------|
| **OQ1** | **Phase A path-inference rules need reconciliation to the org-folder layout.** Migration plan keys on `ionis-devel/...`; the corpus is now fragmented across `ionis-ai/`, `fiducial-mesh/`, `ki7mt/`, `qso-graph/`. Bob's reconciliation pass (lane: infrastructure) updates the table; this spec absorbs the result | **Blocking** — must resolve before Phase-C bootstrap |
| **OQ2** | Outcome-signal protocol for decay signals — who marks an outcome as "successful" or "wrong"? Agent self-flag at task end? Curator review? Hook-driven outcome inference? Unspecified in current design docs | **Blocking** — Bar A auto-promotion + zero-query-chunk decay both depend on this; needs resolution before steady-state operation |
| **OQ3** | Patton-on-AKB-CLCA-review mechanism — Patton "operates on the raw corpus, not the AKB" but how does he see `akb.chunks` for AKB review itself when he's exempt from `akb_query` on review tasks? Direct SQL? Dedicated AKB-CLCA-review query tool? | **Non-blocking** — first CLCA cycle can use ad-hoc SQL; formalize before second cycle |
| **OQ4** | Fence-sentinel parsing hardening for Tier-0 — current contract is line-anchored regex over a file whose prose may reference the literal fence tokens. Spec acknowledges with "do not pattern-match prose mentions" but the contract is fragile | **Non-blocking** — operational today; harden via reserved-pattern + position constraint or AST extraction before second Tier-0 model swap |
| **OQ5** | Tier-0 update cadence — per-commit-to-canonical (event-driven) vs. daily snapshot (timer-driven) vs. weekly Judge-batched proposals. Tier-0 stability matters more than freshness | Recommend commit-event-driven proposal + weekly Judge batching; revisit after 30 days |
| **OQ6** | Tier-1 injection latency tolerance — synchronous (block agent until AKB returns) vs. asynchronous (results arrive next turn). Synchronous is simpler; async preserves reasoning flow | Start synchronous, evaluate |
| **OQ7** | Granularity of roles — too few collapses projections toward shared substrate; too many produces hyper-narrow projections. Start with 5 (one per agent) | Evaluate at monthly CLCA cycle |
| **OQ8** | Task-type vocabulary — bounded enum. Initial set: `implementation`, `review`, `research`, `falsification`, `post-mortem`, `AKB-CLCA-review`, `unspecified`. New types require curation event | Adjust as operational signals reveal gaps |
| **OQ9** | Cross-org corpus walking — current path-inference rules assume single-repo walk; the post-restructure corpus spans 4+ org folders. Walk strategy: per-org-folder pass with separate inference rules, or unified walker with prefix-based rules? | Bob's reconciliation (OQ1) decides shape |

## Failure Modes

- **Tier-0 bloat**: ≤ 1024-byte cap must be enforced at build time. Without enforcement, Tier-0 grows until it itself causes saturation. Cap is non-negotiable; build asserts hard cap + 95% headroom warning
- **Hook bypass**: agents can construct edits that bypass hook triggers via direct API calls. Hook enforcement must be at the runtime tool-call layer, not the agent layer
- **Query specificity collapse**: agents learn to query vaguely; top-N returns mostly noise. Reranker quality matters more than corpus depth
- **AKB unavailability silent failure**: fail-open is correct (CD13), but agents must know AKB was unavailable (status field), so they don't trust empty results as "no relevant knowledge exists"
- **Substrate trap**: vector retrieval is physics-blind; mitigation is the deterministic pre-filter (CD2). Without it, semantic similarity surfaces dead-end content as candidate solutions to physics queries
- **Invariant-flag miscoding**: a chunk that should be `violates_invariant=true` ingested as `false` (or vice versa) makes the pre-filter unreliable. Mitigation: per-doc-type default rules at ingest + periodic CLCA review on high-traffic chunks
- **Projection drift**: roles defined once at ingest, never adjusted. Over time, directory-path defaults stop matching reality. Mitigation: independence-test CI + monthly minimum re-balance cadence
- **Exemption escapes**: agent in exempt mode finds workarounds (asks another agent to query, reads chunks via raw file read). Mitigation: audit log on exempt-mode sessions; flag suspicious patterns
- **Cross-role bloat**: pressure to mark chunks "visible to all" because nobody wants to be excluded. Mitigation: hard per-document cap (CD7) + inherited-over-tagging detection hook (CD11)
- **Independence test as Goodhart's law**: agents optimize for low overlap regardless of relevance. Mitigation: independence is a sanity check, not an optimization target
- **Promotion queue overflow**: Patton overwhelmed by candidates; queue stalls. Mitigation: tighten ingest filters + queue-size escalation threshold to Judge
- **Rollback chains**: rollback that requires a rollback that requires a rollback indicates broken curation discipline. Mitigation: rollback-of-rollback requires Judge approval
- **Brief-drift recurrence**: today's pain (agent briefs going stale on multiple axes simultaneously, no awareness layer pulling current state) is structurally the same class AKB is meant to address. If AKB does not ingest agent briefs as first-class corpus content + fire hooks on agent session start that detect brief staleness, the failure recurs. (See also OQ1's reconciliation: briefs at workspace root must be in the corpus walk.)

## Dependencies

- **IBX**: bootstrap pre-write gate routes Patton sign-off and Judge `--apply` via inbox messages. `action`-priority Bob→Patton message + `info`-priority Patton sign-off + `action` Bob→Judge approval request, all gated by IBX's Judge-approval semantics
- **IAM** (when it lands; pre-IAM uses stub identity): `identity` attribute on every query span / log event, used for self-review exemption matching and audit trail attribution
- **MCC**: Judge's approval window for Bar B (Judge-only) and Physics Bar C (Judge + Einstein parallel) promotion gates. Renders the `akb.promotion_candidates` queue and the Tier-0 promotion review pane
- **PCS**: AKB content classes overlap with PCS-governed artifact classes (skill runbooks belong to AKB; the skill artifact itself is PCS-governed). Boundary: PCS owns the artifact contract (contents+test+deploy); AKB owns the operational knowledge content. See `project_pcs_5stage_pipeline.md` boundary memory
- **ACT** (when it lands): `cost-center` attribute on AKB operations enables chargeback / metering of AKB compute (embedding GPU time, query latency budget)
- **PGE** (when it lands): role projection + selective exemption are policy decisions; PGE owns the policy enforcement framework that AKB's exemption table plugs into long-term

## Acceptance Criteria — five non-negotiables

### 1. Secure

The pillar conforms to `planning/MCP-SECURITY-FRAMEWORK.md`:
- Credentials in OS keyring only (DSN files mode 0600 with `IBX_DB_FILE`-style indirection where applicable)
- No `subprocess`, `shell=True`, `eval`, or `exec` on untrusted input
- HTTPS-only for external connections (embedding service if remote, telemetry sink)
- Parameterized SQL for all `akb.*` queries; no string interpolation
- Input validation on agent-supplied query terms; rate limiting on external embedding API calls

### 2. Instrumented-by-default

AKB emits OTLP traces + OTLP metrics per § Telemetry Contract. Every operation that hits the substrate (query, ingest, promote, curate, bootstrap, tier0_snapshot, hook_query) emits a span. Mandatory, not "should be considered." ACT depends on this to meter AKB compute cost.

### 3. JSON logs

AKB emits structured JSON logs to stderr with the required keys (`timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session`). Trace correlation via `trace_id` + `span_id` mandatory.

### 4. CLI-first, UI-second

Every AKB management function is runnable on a CLI before any UI exists:

- `akb query <terms> --role <role> --task-type <type>` — Tier-1 query
- `akb ingest <path> [--dry-run]` — single-doc or directory ingest
- `akb bootstrap --dry-run | --apply` — bootstrap with required pre-write gate
- `akb promote <chunk_id> --bar A|B|C|physics-c [--approver <identity>]`
- `akb curate <chunk_id> --field <name> --to <value> --reason <text>`
- `akb tier0 build` — rebuild Tier-0 snapshot from merged-main source
- `akb tier0 verify` — verify current snapshot integrity
- `akb status` — chunk counts, queue depth, cross-role utilization, Tier-0 bytes

MCC's AKB pane is a thin client of these commands. MCC never bypasses the CLI/API surface.

### 5. Audit emission

Every state-affecting AKB operation (promote, demote, role-change, ingest, bootstrap, tier0_snapshot, curation event) emits an MI-1 audit event with `identity`, `session`, `operation`, `outcome`, `timestamp` + pillar-specific fields. Path A (emission-as-build-standard) is the current commitment, pending resolution of `KI7MT/specs#22`.

## Pillar-specific addenda

### A. Migration to AKB-conformant frontmatter

Existing corpus docs predate AKB frontmatter conventions. The path-based inference rules (supporting doc: `akb-migration-plan.md`) bridge this. New docs authored via the `akb-doc` skill carry explicit frontmatter; legacy docs inherit from path-based defaults. The post-bootstrap curation pass (Phase D in the migration plan) corrects misclassifications without requiring blanket manual rewrite.

### B. Agent briefs as corpus content (load-bearing per the brief-drift failure mode)

Agent briefs at workspace root (`PATTON-BRIEFING.md`, `EINSTEIN-BRIEFING.md`, `NEWTON-BRIEFING.md`) and the per-agent CLAUDE.md symlink chain are first-class AKB corpus content. The path-inference reconciliation (OQ1) must include them. Tier-1 hook on session start (`before agent session begins`) optionally fires a query for "current state of <agent role>" to surface brief drift before the agent acts on stale assumptions.

This is the operational fix to today's cutover-trap pain. The brief-drift problem is not separately solvable — it's AKB-class by construction, but only if briefs are in the corpus.

### C. Bootstrap event versioning + replay

Every bootstrap is a versioned event (`bootstrap-v1`, `-v2`, …) in `akb.curation_events` with `event_type='bootstrap'`, `batch_id`, source-corpus git-commit hashes (one per org folder walked), and chunk count. Embedding-model swaps, schema migrations, and large backfills bump the bootstrap version. Replay from audit log is possible by re-running the chain with `--from-event=<id>`.

### D. HTTP API + OpenAPI export (per CD17)

AKB exposes three surfaces over the same service module, in order of typical use:

1. **MCP server (`akb-mcp`)** — agent-facing, stdio transport. The primary surface for agent reasoning (`akb_query`, `akb_promote`, etc.). This is the only surface today.
2. **CLI (`akb …`)** — human + script-facing, terminal transport. Per AC#4, every management function ships on the CLI. The canonical headless test surface.
3. **HTTP API (FastAPI)** — MCC + external-client-facing, network transport. Same pattern as MCC. Thin wrapper over the service module; no logic the CLI doesn't have.

**MCC integration**: MCC's AKB pane renders via the HTTP API (status, chunk-counts, queue-depth, Tier-0 byte-utilization, recent curation events, promotion-candidate queue, conflict registry). MCC is a *client* of this API, never a privileged path that bypasses it.

**OpenAPI export-and-commit** (per `fiducial-mesh/core#9`, mirroring the MCC pattern): the FastAPI app generates OpenAPI on build; a CI step exports the JSON and commits it to `fiducial-mesh/core/python/akb/openapi.json`. Documentation wires against the **committed file path**, not the live URL (so docs don't break when the service is down or the host moves). The OpenAPI artifact is the contract; the live endpoint is the implementation.

**HTTP endpoint surface (initial sketch — finalized at build)**:

| Method + path | Maps to | Notes |
|---|---|---|
| `GET /v1/health` | service liveness | no auth |
| `GET /v1/version` | `get_version_info` | matches MCP `get_version_info` |
| `GET /v1/status` | aggregate counters | chunks_total, cross_role_documents, tier0_bytes, promotion_queue_depth — same metrics as the § Telemetry Contract `som.akb.*` gauges |
| `POST /v1/query` | `akb_query(role, terms, …)` | mirror of MCP tool; for non-MCP clients |
| `GET /v1/chunks/{id}` | read single chunk | for MCC chunk-detail view |
| `GET /v1/chunks` | paged list with filters | MCC chunk browser |
| `GET /v1/promotion-candidates` | paged queue | MCC promotion-review pane |
| `POST /v1/promote` | `akb_promote` (Bar A/B/C/physics-c) | identity-gated per AC#1 + PGE policy |
| `POST /v1/curate` | curation event | identity-gated |
| `GET /v1/curation-events` | paged audit | MI-1 audit replay surface |
| `GET /v1/conflicts` | paged conflict registry | |
| `POST /v1/tier0/build` | rebuild snapshot | identity-gated; Bar B gate is at the source-edit layer (per CD9) |
| `GET /v1/tier0/snapshot` | latest snapshot metadata | byte size, source commit, fact count |

**What stays out of the HTTP layer**: bootstrap (`akb bootstrap --apply`) and embedding-model swap are operator-only and stay in the CLI. These shouldn't be runnable from MCC or external clients — the pre-write gate + Judge `--apply` chain is fundamentally a human-in-the-loop operation.

**Authentication / authorization**: HTTP API enforces caller identity via the IAM seam (pre-IAM uses a stub identity per CD5/CD13 / fail-open). Per-endpoint authorization plugs into the PGE policy framework when it lands. Until then, the HTTP API is bound to localhost or to the lab's internal network, never exposed publicly.

### E. AIRs as AKB corpus content (per CD18)

Agentic Incident Reports (AIRs) authored to `fiducial-mesh/air/reports/AIR-*.md` are **first-class AKB corpus content**. This is the operational realization of the AIR + AKB + PCS containment loop articulated in `AIR-SPEC-DESIGN-NOTES.md` § 1 — AIR captures the incident; AKB makes the lesson retrievable across sessions; PCS turns the preventive into an enforced gate.

**Ingest rule** (per `akb-migration-plan.md` § Phase A.1.4):

- `doc_type: air-report` (new bounded-enum value added to `akb-lifecycle.md` § doc_type Bounded Enumeration)
- **`violates_invariant: false`** — the load-bearing call. AIRs are operational lessons to be **surfaced** at decision points, not filtered out by the substrate-trap pre-filter. Distinct from `v-results` (which carries `true` because V dead-end architectures should NOT surface as candidates). Marking AIRs `true` would defeat the containment loop.
- **Baseline `roles`**: `[failure-mode, design-intent]`. Pillar-specific roles added per the AIR's affected pillars (e.g., AIR-002 spans AKB, IBX, MCC, IAM, PCS).
- **Tier-1 only** — AIRs don't go into Tier-0 (too rich for the 1 KB bounded prior). They surface via Tier-1 gradient-gated retrieval.

**Why AIRs surface at decision points (the CD14 connection)**:

CD14 added infra-decision-side hook triggers — before `git push`, `gh pr create / review`, deploy commands, substrate config edits. These triggers fire AKB queries at exactly the moments operational lessons should land. AIR-002's F-2 ("send to deprecated backend during half-flipped cutover") and F-3 ("PAT scope drift across org rename") are the precise lessons an agent needs *before* pushing code that touches inbox MCP or running `gh pr` against a renamed org. The hook fires, the AKB query surfaces F-2 + F-3 chunks, the agent operates with the lesson present.

**Security AIR exclusion**:

AIRs with `incident_class: security` or `audience: restricted` are **categorically excluded** from AKB ingest (per `AIR-SPEC-DESIGN-NOTES.md` § 1.4). Security finding payloads never land in AKB or ACT — broadcast-by-design substrates are incompatible with need-to-know audiences. SEC pillar (when ratified per CD1) owns the restricted store for these. The ingest pipeline drops security-class AIRs and logs a curation event noting the exclusion.

**Chunking + addressability**:

Each F-N sub-section within an AIR chunks independently (header-based split at H3 boundaries inside § 3 of the AIR). A query about "PAT scope drift" surfaces AIR-002 § 3 § F-3, not the whole AIR. The per-chunk `header_path` carries `AIR-NNN > Section > F-N`.

**Curation event on AIR merge**:

When a new AIR merges to `fiducial-mesh/air/main`, a git-post-commit hook (or equivalent CI workflow) triggers re-ingest. The curation event is logged with `event_type='air_ingest'`, the AIR ID, the source commit, and the per-F-N chunk count.

## How this spec fits the mesh

- **MI-1 (audit)**: AKB's `akb.curation_events` is the per-pillar audit stream — append-only, replayable, full state-diff per event
- **MI-8 (substrate substitutability)**: Substrate Matrix above lists 6 seams with sovereign + alternative substrates; conformance via multi-profile CONF-CD1..11
- **MI-11 (telemetry contract)**: Telemetry Contract above instantiates the mesh-level mechanism
- **MI-12 (Spec-Harness-Registry primitive)**: AKB itself is governed by this primitive — the spec (this doc) + the conformance harness (CONF-CD tests against multiple substrates) + the registry of approved-substrate profiles
- **CD15 (conformance-enforced substrate-neutrality)**: a seam change that breaks any tested profile does not merge

## References

- `planning/MESH-SPEC.md` — mesh-level invariants this manifest instantiates
- `planning/PILLAR-SPEC-TEMPLATE.md` v1.0 — the template this spec builds to
- `planning/akb-awareness-layer.md` v0.4 — Tier 0 + Tier 1 architecture, substrate-trap pre-filter
- `planning/akb-reasoning-independence.md` v0.4 — role-projected retrieval, selective exemption, self-review principle
- `planning/akb-lifecycle.md` v0.4 — ingest, promotion, conflict resolution, decay signals, pre-write gate
- `planning/akb-migration-plan.md` v0.2 — path-based inference rules, override frontmatter, bootstrap procedure (needs OQ1 reconciliation)
- `planning/akb-cross-role-audit.md` v0.1 — pre-bootstrap cross-role inventory
- `planning/akb-review-trajectory.md` v1.0 — five-round dialectical review methodology record
- `planning/templates/akb-document-template.md` — canonical AKB document template
- `planning/tier0/akb-tier0-content.md` v0.1 — Tier-0 source content
- `planning/MCP-SECURITY-FRAMEWORK.md` — security framework referenced by Acceptance Criterion 1
- `planning/IBX-SPEC.md` — sibling pillar; Bar B / Patton-sign-off routing uses IBX
- `papers/THE-DIALECTICAL-ENGINE.md` — multi-agent falsification methodology
- `papers/FROM-NANOMETERS-TO-NEURONS.md` — CLCA/8D applied to ML process control
