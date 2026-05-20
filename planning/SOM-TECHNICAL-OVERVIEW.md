---
title: "Sovereign Orchestration Mesh (SOM) — Technical Overview"
doc_type: planning-canonical
status: draft
version: v0.1
authors:
  - einstein
  - watson
  - judge
date: "2026-05-20"
roles:
  - design-intent
  - infrastructure
  - failure-mode
  - physics
  - astrophysics
author_id: watson
violates_invariant: false
invariant_class: ""
classification: "External release subject to IP review"
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/PCS-ADOPTION-PLAN.md
  - planning/akb-awareness-layer.md
---

# Sovereign Orchestration Mesh (SOM) — Technical Overview

**Visual reference**: [`diagrams/som-architecture.png`](diagrams/som-architecture.png) — three-plane decomposition.

> **Status — v0.1 draft.** External-facing companion to the lab-internal [`SOM-PROBLEM-STATEMENT.md`](SOM-PROBLEM-STATEMENT.md) (design-driver capture) and [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) (v1.0 production-validation record). This document is the paper / pitch / external-readers version of the SOM architecture; classification "External release subject to IP review." Treat the internal documents as authoritative for the validation record and design driver corpus; this document is the synthesis intended for outside audiences.

## Introduction

The Sovereign Orchestration Mesh (SOM) is a multi-plane, cognitive operating system designed from the ground up for deployment on highly secure, air-gapped customer infrastructure. Its purpose is to orchestrate, secure, and govern complex collaborations among multi-agent AI workforces ("agents at work") while ensuring absolute data sovereignty and deterministic process control. SOM provides the infrastructure standard for running private, agentic workloads without cloud dependencies.

The architecture is **air-gapped ready and exfiltration hostile** by construction, not by configuration. Sovereignty is not just where the workloads run; it is whether the architecture can be operated without trust-bearing paths to a counterparty.

## Structural Planes of the Mesh

SOM is organized into three distinct, hierarchical planes that enforce logical separation between governing policy, cognitive execution, and persistent state. Pillar bindings used throughout this document are the names of record from [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md).

### 1. The Control Plane — Governance Layer

The Control Plane is the authoritative governing body of the mesh. It manages workflow lifecycle, enforces policy, brokers compute resources, and handles all communication between the mesh and human operators.

**Core components — five elements:**

- **IBX (Inbox Exchange)** — primary communication hub and message broker. Responsible for asynchronous message queueing, routing, and state management. IBX handles agent-to-agent message routing and is the critical interface for the human-in-the-loop approval gate. It is the substrate where the **PCT (Principal Control Token)** — the message-from-Principal-to-Singleton artifact — is routed and validated. PCT lives in IBX rather than expanding PCS scope: PCT is a message; IBX is the message system.

- **PGE (Policy Guardrail Engine)** — deterministic, broad-spectrum policy engine that evaluates the *intent* of every message against the lab's established constraints. PGE acts as a **double guardrail**: it enforces policy on agent actions *before* messages reach IBX (catches non-compliant intent at submission, before downstream work is wasted), and it enforces policy on code executed *inside* DPG (catches non-compliant code at runtime, before it touches production state). Intent-side and execution-side compliance gaps are different failure classes; either gate alone misses one class. Vendor-mediated alternatives typically enforce at one point (vendor safety filter on the LLM input/output) and miss the execution-side surface entirely.

- **CRB (Compute Resource Broker)** — hardware-aware scheduler. Dynamically maps compute workloads (neural network inference, heavy data processing, ClickHouse query execution) across the physical infrastructure (Mac Studio M3 Ultra unified memory; Threadripper 9975WX GPU lanes; EPYC replica node) to optimize parallelization and cost-efficient dispatch.

- **PCS (Plugin Control System)** — closed-loop plugin governance with three operational layers:
  - **PCS-Syntax** — declarative law: schemas, required fields, `trust_tier` metadata, security flags, capability declarations. Defines what an MCP server, skill, or runbook must look like.
  - **PCS-Registry** — air-gapped artifact substrate: physical storage for plugin binaries, schema declarations, version history, and signing attestations. The single source of truth that agents query at dispatch time. Substrate is operator-selectable (local Git, OCI distribution-spec registry, dedicated ClickHouse dataset, or hybrid) per the Exit Test discipline.
  - **PCS-Lifecycle** — promotion and enforcement gate: handles submission → Syntax validation → PGE compliance check → Judge approval → Registry ingest, plus the full software-asset-management cycle (versioning, deprecation, retirement, trust-tier mutation, rollback, audit trail).
  
  Crossing the PCS-Lifecycle gate is the **dev-to-production trust transition**. Plugins in source repos or on PyPI are dev artifacts; only after Lifecycle promotion into Registry are they "released" in the sovereign sense. This mirrors OCI / container-registry semantics. The wire protocol agents use to invoke plugins (MCP — Model Context Protocol) is an external standard PCS does not own; PCS sits above MCP and governs what plugins riding that protocol must look like. See [`PCS-REGISTRY-FOLD-IN.md`](PCS-REGISTRY-FOLD-IN.md) for the architectural decision record.

- **Judge (Human Approval Gate)** — mandatory, human-in-the-loop approval interface intercepting "Judge-gated action-priority messages" flagged by IBX. The Judge retains final authority over critical actions. Operator approval is a first-class architectural element, not a side concern.

### 2. The Compute Plane — Execution Layer

The Compute Plane is where the autonomous workforce resides and where generated code is tested. It is structurally decoupled from governance to prevent the shared-bias corruption found in cloud-mediated systems.

**Core components:**

- **Workforce** — a bounded, named cluster of specialized autonomous AI agents (Watson, Bob, Patton, Einstein, Newton) performing distinct roles (training, infrastructure, failure-mode review, physics/architecture, sovereign-local astrophysics). The cluster includes both anchored personas (host-bound: Watson on M3, Bob on 9975WX) and singletons (non-substitutable role-bound: Patton for failure-mode review, Einstein for physics falsification, Newton for sovereign astro inference). The Singleton/Instance Asymmetry — that singletons cannot be load-balanced and bad input to them cascades into downstream wrong output — is a structural property that shapes the Control Plane's PCT discipline.

- **DPG (Deterministic Proving Ground)** — secure, ephemeral, isolated sandboxing environment. All agent-generated code (Python, CUDA, Bash) is routed to DPG where it is compiled, tested for deterministic stability, and executed in a single-use container, with all output captured and returned to IBX. DPG **bridges stochastic reasoning and deterministic execution** — agents may reason probabilistically, but the code they emit is validated under deterministic conditions before it touches production state.

### 3. The State Plane — Persistency Layer

The State Plane is the memory of the SOM. It manages all knowledge retrieval and keeps an immutable record of every action. The State Plane's two pillars are append-mostly substrates that other planes write into and read from.

**Core components:**

- **AKB (Agent Knowledge Base)** — isolated, high-performance columnar / vector database substrate. Provides persistent, long-term contextual memory to the Workforce, tracking established constraints, past architectural decisions, current project specifications, and *invariant-class* dead-end content. AKB uses **role-projected retrieval** — each agent sees only chunks visible to its role(s), and the retrieval engine enforces a substrate-trap pre-filter that excludes `violates_invariant=true` chunks from non-historical queries (so dead-end content surfaces only when explicitly requested). The retrieval contract is bidirectional with the Workforce: agents query AKB; agents also propose chunk-level flags and promotions via curator-gated workflows.

- **ACT (Agent Cognitive Telemetry)** — immutable, locally hosted audit ledger. Every reasoning span, token consumed, reasoning step, and compute cost is streamed out-of-band to high-performance columnar storage. ACT transforms opaque AI "thought processes" into queryable, persistent database rows for debugging, cost accounting, and regulatory compliance. The flow into ACT is unidirectional — Workforce and DPG emit telemetry; nothing flows back out except via curator review.

### Substrate

The whole stack rests on **Customer Infrastructure (Sovereign / Air-gapped)** — owned hardware, no cloud dependencies, no managed-service substrate. Customer hardware shape varies (Big Iron / Slim Enterprise / single-host fleet), but the architecture is the same in every case: every pillar runs locally, every credential lives in OS-resident stores, every byte of state stays inside the customer's trust boundary.

## Design Thesis

The SOM architecture is a direct response to the operational, security, and IP vulnerabilities of **Vendor-Mediated Architecture (VMA)** — the cloud-based agent platforms currently converging on the "Agentic Mesh" buzzword. SOM differentiates itself structurally on five drivers.

### 1. Architecture is Sovereignty

VMA models require customers to place absolute trust in the vendor's authorization policy, opaque orchestration, and managed databases — effectively surrendering control of their decision logic. SOM rejects this dependency. It operates under the mandate that **sovereignty is not just on-premises deployment, but the sovereignty of architecture**. Every SOM pillar is engineered to provide a private, local alternative to a VMA component:

| VMA component (vendor-mediated) | SOM pillar (sovereign) |
|---|---|
| Datadog / Honeycomb telemetry | ACT |
| Pinecone / OpenAI Vector Store | AKB |
| OpenAI / Anthropic tool registries | PCS |
| Slack / Discord / vendor inboxes | IBX |
| AWS Lambda / containerd ephemeral isolation | DPG |
| AWS Batch / Slurm compute scheduling | CRB |
| Anthropic safety filters / vendor RBAC | PGE |

The seven-pillar shape is the orthogonal decomposition of architectural concerns that vendors otherwise mediate. The decomposition is **necessary AND sufficient**: drop one and the lab is fragile in a predictable way. Necessary-AND-sufficient decompositions are rare in software architecture, and SOM hits both.

### 2. Deterministic Proving Ground (the sandbox mandate)

As agents move from read-only tasks to write-enabled code generation, the risk of unvalidated execution rises. Big Tech handles this probabilistically (vendor safety filters on the LLM input/output) or by obfuscating the execution layer in the cloud. SOM enforces a **local, ephemeral isolation boundary** at DPG, bridging the gap between stochastic reasoning and deterministic execution. Code emitted by agents is compiled and tested in a single-use container before it can touch production state.

### 3. The Dialectical Engine — Independence of Error Distributions

Multi-agent systems only generate novel insight when agents reason **independently**. VMA models break this property because all agents share the same corporate safety filter and upstream training bias — their errors are correlated, and agreement between them carries less information than it appears to. **SOM agents run on operator-controlled models with mathematically independent error distributions**, which is what permits genuine dialectical falsification rather than shared-blind-spot consensus.

The value of independence is not just *catching errors* — it is **producing high-confidence architectural commitments through independent reasoning**. An architectural commitment that survives multiple independent derivations is invariant under the reasoning substrate. The same epistemic property as scientific reproducibility, applied to agent-mediated design.

### 4. Hardware-Aware Compute Resource Broker

Enterprises are realizing that throwing infinite cloud compute at problems is inefficient. SOM's CRB understands the specific topology of the customer's hardware — knowing when to dispatch contexts to unified-memory hosts (Apple M-series, AMD EPYC), when to route tensor workloads to GPU lanes (RTX PRO 6000, NVIDIA H100), and when to schedule ClickHouse queries against multi-NVMe storage. The agents stay hardware-agnostic; CRB does the dispatch.

### 5. The Exit Test — no vendor lock-in

VMA models are designed for lock-in: leaving means rewriting. **SOM enforces a per-pillar substitutability constraint**. The operator can replace any pillar (AKB ClickHouse backend with Qdrant or pgvector; IBX with Kafka or RabbitMQ; CRB convention-codified dispatch with a Nomad daemon) without architectural collapse. The Exit Test is a CLCA gate that catches *slow sovereignty erosion* — the feature that seemed harmless in isolation but created lock-in surface over six months of accumulated decisions. Sovereignty is testable by the operator's ability to sever ties without rewriting the architecture.

## Validated Production Benchmarks

The design principles of SOM were not developed purely through theorizing; they were stress-tested by supporting high-heat, specialized physics and model-training workloads in the KI7MT Sovereign AI Lab. The validation is quantifiable, replayable, and documented in [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) (v1.0, Patton-signed-off):

- **IONIS-AI model training (SOM validation milestone)** — Orchestrated the ingestion and feature engineering of **30,902,535 rows** (~31 million) of amateur radio observation data to train the IONIS V20 model (203,573 parameters; the V16-physics replication baseline that served as the SOM-validation milestone). The current production model is V22-γ (207,157 parameters); V20 remains the reference point because its training run was the one SOM orchestrated end-to-end as the first validation workload.
- **ClickHouse Gold Layer** — Managed the underlying data orchestration for a Gold Layer containing **11.45 billion rows** of compressed propagation data (as of 2026-05-20). At SOM-validation milestone (early 2026) this stood at 10.8 billion rows; the live ingest pipeline grows it continuously, and the validation framing was per-the-milestone, not per-current-state. Both numbers are checkable and citable.
- **QSO-Graph active research** — SOM is currently orchestrating the data extraction and multi-agent statistical analysis of **493,894 contest-log submissions** — defined as distinct `(operator-callsign, contest-name, contest-year)` tuples — drawn from 18 major HF contests over 2005–2025, supporting an active research paper and concept document on Cognitive Fatigue in Amateur Radio Contesting. Each submission represents a single continuous contest session and forms the unit of analysis for fatigue trajectory characterization.

The lab is the canonical Slim Enterprise Org — resource-constrained, sovereignty-required, multi-project, single-operator orchestrating five agent roles. **Dogfooding is the strongest validation a platform can have**: SOM built BY the lab FOR the lab has built-in feedback loops on every defect; the operators live with the friction they're asking outside customers to live with.

## Conclusion — Architecting for Deterministic Execution

The Sovereign Orchestration Mesh provides the necessary backend plumbing to run private, autonomous agent workforces on bare metal without sacrificing control of intellectual property. The SOM blueprint transforms agents-at-work from a high-risk probabilistic toy into a manageable, industrial-grade software primitive.

By codifying sovereignty into the architecture itself — Plugin Control System, Inbox Exchange, Agent Knowledge Base, Agent Cognitive Telemetry, Deterministic Proving Ground, Compute Resource Broker, Policy Guardrail Engine — SOM answers the critical question facing regulated industries:

> *How do we own the infrastructure, not just rent the inference?*

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record)
- [`SOM-PROBLEM-STATEMENT.md`](SOM-PROBLEM-STATEMENT.md) — design-driver capture (internal, v0.3)
- [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) — production-validation record (v1.0, Patton-signed-off)
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS spec lineage
- [`akb-awareness-layer.md`](akb-awareness-layer.md), [`akb-reasoning-independence.md`](akb-reasoning-independence.md), [`akb-lifecycle.md`](akb-lifecycle.md) — AKB three-spec gate
- [`MCP-SECURITY-FRAMEWORK.md`](MCP-SECURITY-FRAMEWORK.md) — PGE operational spec
- `diagrams/som-architecture.png` — three-plane decomposition visual
