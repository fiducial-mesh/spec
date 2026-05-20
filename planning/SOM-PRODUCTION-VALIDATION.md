---
title: "SOM Production Validation — The First Proving Grounds"
doc_type: planning-canonical
status: draft
version: v1.0-draft
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

> **Status — draft only.** This document is canonical only after all three of Patton's verification passes have been committed (Pass 1 numerical fact-check, Pass 2 pillar-name resolution, Pass 3 validation evidence audit). Until then, do not share externally, cite in papers, or include in pitches. The strength of the production-validation framing is checkability; that checkability is the moat.

## Scope

The Sovereign Orchestration Mesh (SOM) is fundamentally domain-agnostic, engineered to orchestrate secure workloads for defense, quantitative finance, and healthcare. However, an architecture must be stress-tested against unrelenting data to prove its viability.

To validate the SOM architecture at scale, it was deployed as the orchestration substrate for two compute-intensive, highly specialized physics and AI initiatives in the Sovereign Lab: **IONIS-AI** and the **QSO-Graph project**. The validation is checkable, with specific pillars mapped to concrete production workloads.

Pillar bindings used throughout this document are the names of record from [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md). Any inconsistency between a pillar reference here and that file is a defect against that file.

## Fully Validated Pillars (In Production)

### 1. PCS (Plugin Control System)

**Validation**: Governs the entire local MCP (Model Context Protocol) fleet.

**Evidence**: Successfully coordinates the lifecycle, registry synchronization, and versioning of **13 active servers** and **96 tools** across the lab. It enforces strict schema compliance across the distributed mesh, with schema drift actively caught and corrected by the agent review gates.

### 2. IBX (Inbox Exchange)

**Validation**: Manages asynchronous cognitive hand-offs and state without race conditions.

**Evidence**: Successfully routed multi-agent workflows between Watson, Bob, Patton, and Einstein during the development of both the IONIS and QSO-Graph codebases, ensuring action-priority messages were held for final human-in-the-loop (Judge) approval.

### 3. PGE (Policy Guardrail Engine)

**Validation**: Replaces vendor safety filters with deterministic compliance.

**Evidence**: Enforces the strict MCP-SECURITY-FRAMEWORK across the entire fleet. It programmatically guarantees keyring-only credentials, parameterized SQL, and no unauthorized subprocesses, catching non-compliant agent code before execution.

### 4. DPG (Deterministic Proving Ground)

**Validation**: Ephemeral isolation for complex code execution.

**Evidence**: During Phase 4.0, agents wrote complex "High-Heat" CUDA kernels (Maidenhead-to-LatLon, Haversine, and Solar Join). These were securely compiled and tested within the DPG boundary to ensure deterministic stability before ever touching the production ClickHouse database.

### 5. CRB (Compute Resource Broker)

**Validation**: Hardware-aware workload dispatch.

**Evidence**: Dynamically routed infrastructure and management state to the M3 Ultra (unified memory), while dispatching heavy 10.8B-row ClickHouse queries and neural network tensor workloads to the Threadripper 9975WX Compute node.

## Phase-1 Deployment Pillars (Active Engineering)

To maintain absolute architectural honesty, two pillars are currently transitioning from design to active Phase-1 deployment to support Phase 5.0 distributed orchestration:

### 6. AKB (Agent Knowledge Base)

**Status**: Phase-1 Deployment. Transitioning the lab's documentation, schemas, and historical decisions into an isolated, role-projected ClickHouse vector store to provide agents with persistent, localized context without third-party database exposure.

### 7. ACT (Agent Cognitive Telemetry)

**Status**: Phase-1 Deployment. Implementing the standardized span and token-tracking schemas into the ClickHouse storage backend to provide an immutable, locally hosted audit trail for all multi-agent cognitive loops.

## Workload Benchmarks

The SOM substrate has successfully supported the following verifiable data constraints:

- **IONIS-AI Model Training**: Orchestrated the ingestion and formatting of **30,902,535 rows** (~31 million) of amateur radio observation data to successfully train the **IONIS V20 model (203,573 parameters; ~203K)**. V20 is the V16-physics replication baseline that served as the SOM-validation milestone; current production is V22-gamma (207,157 parameters).
- **The Vault (ClickHouse)**: Managed the underlying data orchestration for a Gold Layer containing **10.8 billion rows** of compressed propagation data.
- **QSO-Graph (Active Research)**: SOM is currently orchestrating the data extraction and multi-agent statistical analysis of **493,894 contest-log submissions** — defined as distinct `(operator-callsign, contest-name, contest-year)` tuples — drawn from 18 major HF contests over the years 2005–2025, to support an active research paper and concept document on Cognitive Fatigue in Amateur Radio Contesting. Each submission represents a single continuous contest session and forms the unit of analysis for fatigue trajectory characterization.

## Constraint on This Document

Until Patton's three verification passes are all committed, this document is **draft-only**. Specifically:

- Pass 1 (Numerical fact-check) — applied in this commit.
- Pass 2 (Pillar-name resolution) — committed in `c995ffa`; see `SOM-PILLAR-NAMES.md`.
- Pass 3 (Validation evidence audit) — pending.

Do not share, cite, or include in pitches until status changes to validated.

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record)
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS spec
- [`MCP-SECURITY-FRAMEWORK.md`](MCP-SECURITY-FRAMEWORK.md) — PGE operational spec
- [`akb-awareness-layer.md`](akb-awareness-layer.md), [`akb-reasoning-independence.md`](akb-reasoning-independence.md), [`akb-lifecycle.md`](akb-lifecycle.md) — AKB three-spec gate
- `CLAUDE.md` — operational reference for IBX (Agent Message Queue) and CRB (DAC Network)
