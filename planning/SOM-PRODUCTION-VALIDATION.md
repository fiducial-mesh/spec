---
title: "SOM Production Validation — The First Proving Grounds"
doc_type: planning-canonical
status: validated
version: v1.0
authors:
  - einstein
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
  - planning/SOM-PILLAR-NAMES.md
  - planning/PCS-ADOPTION-PLAN.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/akb-awareness-layer.md
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
---

# SOM Production Validation — The First Proving Grounds

> **Status — v1.0, three verification passes complete.** All three of Patton's verification passes are committed: Pass 1 (numerical fact-check) in `4cf5aa5`, Pass 2 (pillar-name resolution) in `c995ffa`, Pass 3 (validation evidence audit) in this commit. The document is canonical for internal use. Per Patton's guidance, surface any newly-discovered inconsistency for arbitration before publishing externally; the strength of this framing is checkability, and that checkability is the moat.

## Scope

The Sovereign Orchestration Mesh (SOM) is fundamentally domain-agnostic, engineered to orchestrate secure workloads for defense, quantitative finance, and healthcare. However, an architecture must be stress-tested against unrelenting data to prove its viability.

To validate the SOM architecture at scale, it was deployed as the orchestration substrate for two compute-intensive, highly specialized physics and AI initiatives in the Sovereign Lab: **IONIS-AI** and the **QSO-Graph project**. The validation is checkable, with specific pillars mapped to concrete production workloads.

Pillar bindings used throughout this document are the names of record from [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md). Any inconsistency between a pillar reference here and that file is a defect against that file.

## Fully Validated Pillars (In Production)

### 1. PCS (Plugin Control System)

**Validation**: Governs the entire local MCP (Model Context Protocol) fleet.

**Evidence**: Successfully coordinates the lifecycle, registry synchronization, and versioning of **13 active servers** and **96 tools** across the lab. It enforces strict schema compliance across the distributed mesh, with schema drift actively caught and corrected by the agent review gates.

**Verifier path**: `gh repo list qso-graph --limit 100` enumerates the 12 qso-graph MCP repos; each repo's `README.md` lists its tool count, and each server exposes a `get_version_info` MCP tool that returns the live tool-set. The internal `agent-inbox-mcp` is documented in `CLAUDE.md` § Agent Message Queue. Two-person PR-control discipline is documented in `CLAUDE.md` § Release Workflow.

### 2. IBX (Inbox Exchange)

**Validation**: Manages asynchronous cognitive hand-offs and state without race conditions.

**Evidence**: Successfully routed multi-agent workflows between Watson, Bob, Patton, and Einstein during the development of both the IONIS and QSO-Graph codebases, ensuring action-priority messages were held for final human-in-the-loop (Judge) approval.

**Verifier path**: ClickHouse `SELECT count() FROM messages.inbox WHERE priority IN ('action','urgent') AND status='approved'` returns the historical count of approved action-priority messages. The Judge-approval gate is enforced at the schema layer — the `inbox` ClickHouse user has grants limited to `messages.inbox` only and cannot set `approved` status. The `inbox-ui` repo (Wails/Go/Svelte) holds the approval-gate implementation.

### 3. PGE (Policy Guardrail Engine)

**Validation**: Replaces vendor safety filters with deterministic compliance.

**Evidence**: Enforces the strict MCP-SECURITY-FRAMEWORK across the entire fleet. It programmatically guarantees keyring-only credentials, parameterized SQL, and no unauthorized subprocesses, catching non-compliant agent code before execution.

**Verifier path**: `cat .claude/hooks/subagent-guard.sh` shows the runtime hook that blocks force-push, gates PyPI publish, and blocks credential-file writes; `grep -r "test_security" qso-graph/*/tests/` enumerates the per-server compliance tests; `inbox_search` for `security audit` messages surfaces the documented Watson PASS gates that precede every PyPI release. The framework itself is canonical in `planning/MCP-SECURITY-FRAMEWORK.md`.

### 4. DPG (Deterministic Proving Ground)

**Validation**: Ephemeral isolation for complex code execution.

**Evidence**: During Phase 4.0, agents wrote complex "High-Heat" CUDA kernels (Maidenhead-to-LatLon, Haversine, and Solar Join). These were securely compiled and tested within the DPG boundary to ensure deterministic stability before ever touching the production ClickHouse database.

**Verifier path**: `ionis-cuda/src/` commit history shows isolated kernel-validation commits before integration into the production embedding pipeline; `planning/CUDA-PREFLIGHT.md` documents the 10-epoch 9975WX validation SOP that runs before any M3 full-training commit. Subagent worktree isolation (`isolation: "worktree"` per Anthropic Agent SDK) provides per-task OS-level Git isolation when agents draft code that needs write access.

### 5. CRB (Compute Resource Broker)

**Validation**: Hardware-aware workload dispatch.

**Evidence**: Dynamically routes infrastructure and management state to the M3 Ultra (unified memory), while dispatching heavy 10.8B-row ClickHouse queries and neural network tensor workloads to the Threadripper 9975WX Compute node.

**Verifier path**: `CLAUDE.md` § Infrastructure + DAC Network tables document the 10 Gbps point-to-point topology (`10.60.1.0/24` Thunderbolt 4, MTU 9000) between M3 Ultra and 9975WX; `ip addr` on either host confirms the link state; `CLAUDE.md` § Release Workflow documents the dispatch convention (Bob runs CUDA pre-flight on 9975WX, Watson runs full training on M3, Bob owns RPM packaging).

**Honest framing**: CRB is operationally codified by convention, not yet automated by a broker daemon. Workload assignment lives in `CLAUDE.md` and the per-agent execution context, and is reliable in practice today; a future CRB spec will land daemon-process automation. Until that lands, the pillar's "validation" claim is that the dispatch *discipline* is in production, not that a CRB-daemon is.

## Phase-1 Deployment & Specification-Phase Pillars

To maintain absolute architectural honesty, two pillars are at earlier maturity stages. Status framing here distinguishes what is specified, what is built, and what is still in spec.

### 6. AKB (Agent Knowledge Base)

**Status**: Specification complete (three-spec gate at v0.3, validated through five rounds of dialectical-engine review). **Phase-1 build is active with substantial code on `main`.**

**Evidence**:
- Specifications: `planning/akb-awareness-layer.md`, `planning/akb-reasoning-independence.md`, `planning/akb-lifecycle.md` (all v0.3)
- Five-round review trajectory: `planning/akb-review-trajectory.md`
- Migration plan: `planning/akb-migration-plan.md` (Phase A.1.1 skill taxonomy)
- Pre-bootstrap audit: `planning/akb-cross-role-audit.md` (33/50 cross-role chunk utilization, comfortable headroom)
- Implementation: `KI7MT/akb` repo on `main` at commit `2474cf5` — DDL schema for 7 `akb.*` tables, `apply_ddl.sh` wrapper with env/file-based password resolution, `inference.py` + `chunker.py` + `embedder.py` ingest pipeline, the `akb-mcp` server (`akb_mcp/retrieval.py`, `akb_mcp/tools.py`, `akb_mcp/server.py`) implementing the six-step Tier-1 query flow with four tools, and the Tier-0 generator (`tier0/extractor.py`, `tier0/snapshot.py`, `akb-tier0` CLI, `scripts/verify-tier0.sh`) with strict fence-sentinel matching, atomic snapshot symlink replacement, and `akb.curation_events` provenance logging.

**Live integration verified**: PR #4 (commit `8f7b7bc`) — 7/7 live smoke tests pass in 5.35s on real ClickHouse + BGE-large GPU embeddings on the 9975WX. Tests cover happy-path retrieval, substrate-trap pre-filter on `violates_invariant`, historical-query `invariant_class` surfacing, role projection isolation, Patton+review exemption gate, self-review filter, and `get_version_info` identity. Marked `@pytest.mark.live` and skipped by default; `pytest -m live` runs them.

**Tier-0 generator verified**: PR #5 (commit `2474cf5`) — real-data run of `akb-tier0 build` against the canonical Watson W2 source produced a 740/1024-byte snapshot (28% headroom), captured source git commit in the provenance header, wrote atomic `latest.md` symlink, and logged a `tier0_snapshot` event to `akb.curation_events`. Headroom safeguard test asserts ≤ 95% of cap.

**Verifier path**: `git -C ~/workspace/akb log --oneline origin/main` shows the build progression; `pytest tests/` runs 40/40 unit tests in the default mock-driven suite (12 retrieval + 19 inference + 9 tier0); `pytest -m live` runs the 7-test live smoke suite against real CH + GPU.

**What's not in production yet**: P1.6 hooks (planned, not yet built); P2.8 bootstrap orchestrator (`scripts/bootstrap.py` — next on Bob's queue, walks the canonical doc directories and exercises the full ingest pipeline on the ~442-markdown corpus); `akb.exemptions` curator-population workflow (Phase-2+; the table is schema-first per Patton's `b36289e` discipline, with hard-coded fallback rules applying when empty); reranker model integration (deferred until `akb.queries` outcome flags justify activation).

### 7. ACT (Agent Cognitive Telemetry)

**Status**: Specification phase. The pillar is named and scoped (standardized span and token-tracking schemas for an immutable locally hosted audit trail of multi-agent cognitive loops). No code shipped.

**Honest framing**: ACT has neither a dedicated spec nor an implementation yet. The intent is concrete enough that ACT is a pillar of record (see `SOM-PILLAR-NAMES.md`), but the spec gate has not been built. Spec work follows AKB Phase-1 completion.

## Workload Benchmarks

The SOM substrate has successfully supported the following verifiable data constraints:

- **IONIS-AI Model Training**: Orchestrated the ingestion and formatting of **30,902,535 rows** (~31 million) of amateur radio observation data to successfully train the **IONIS V20 model (203,573 parameters; ~203K)**. V20 is the V16-physics replication baseline that served as the SOM-validation milestone; current production is V22-gamma (207,157 parameters).
- **The Vault (ClickHouse)**: Managed the underlying data orchestration for a Gold Layer containing **10.8 billion rows** of compressed propagation data.
- **QSO-Graph (Active Research)**: SOM is currently orchestrating the data extraction and multi-agent statistical analysis of **493,894 contest-log submissions** — defined as distinct `(operator-callsign, contest-name, contest-year)` tuples — drawn from 18 major HF contests over the years 2005–2025, to support an active research paper and concept document on Cognitive Fatigue in Amateur Radio Contesting. Each submission represents a single continuous contest session and forms the unit of analysis for fatigue trajectory characterization.

## Constraint on This Document

Until Patton's three verification passes are all committed, this document is **draft-only**. Specifically:

- Pass 1 (Numerical fact-check) — committed in `4cf5aa5`.
- Pass 2 (Pillar-name resolution) — committed in `c995ffa`; see `SOM-PILLAR-NAMES.md`.
- Pass 3 (Validation evidence audit) — applied in this commit.

Do not share, cite, or include in pitches until status changes to validated.

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record)
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS spec
- [`MCP-SECURITY-FRAMEWORK.md`](MCP-SECURITY-FRAMEWORK.md) — PGE operational spec
- [`akb-awareness-layer.md`](akb-awareness-layer.md), [`akb-reasoning-independence.md`](akb-reasoning-independence.md), [`akb-lifecycle.md`](akb-lifecycle.md) — AKB three-spec gate
- `CLAUDE.md` — operational reference for IBX (Agent Message Queue) and CRB (DAC Network)
