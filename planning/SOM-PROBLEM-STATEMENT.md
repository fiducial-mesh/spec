---
title: "SOM Problem Statement — Design Drivers from Operational Practice"
doc_type: planning-canonical
status: draft
version: v0.2
authors:
  - watson
  - patton
  - einstein
  - judge
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
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/PCS-ADOPTION-PLAN.md
  - planning/akb-awareness-layer.md
  - planning/REPO-SHAPE-DECISIONS.md
---

# SOM Problem Statement — Design Drivers from Operational Practice

**Visual reference**: [`diagrams/som-architecture.png`](diagrams/som-architecture.png) — three-plane decomposition showing each pillar's structural position.

> This document captures design drivers for the Sovereign Orchestration Mesh (SOM) as they emerged from operational practice in the KI7MT Sovereign AI Lab. Each driver is sourced from a real workload, decision, or observed pattern. **Drivers are inputs to architecture; they are not themselves commitments.** Architectural commitments are made in pillar-specific spec documents (`PCS-ADOPTION-PLAN.md`, the AKB three-spec gate, and the pending IBX / ACT / DPG / CRB / PGE specs), and gated by CLCA review.
>
> Pillar names used throughout this document are the names of record from [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md). Any inconsistency between a pillar reference here and that file is a defect against that file, not against this one.

## Scope

SOM is the seven-pillar platform that orchestrates the lab's multi-agent fleet on sovereign substrate. Its design drivers come from running an actual lab — single operator (KI7MT), five active agent roles (Watson, Bob, Patton, Einstein, Newton), four hosts (M3, 9975WX, EPYC, TrueNAS), four concurrent project workstreams (IONIS-AI, QSO-Graph, PCS, AKB), all on owned hardware with no cloud dependencies. The drivers below are the operational reality that shapes the seven pillars. Section 6 catalogs drivers that are surfaced but not yet committed to a pillar specification.

## 1. The Sovereign Trust Model

**Driver**: Trust in this architecture derives from **architectural ownership**, not vendor SLA. Einstein's framing — *"Architecture is Sovereignty"* — captures the principle: the lab's confidence that its workloads will run correctly tomorrow comes from owning every layer that those workloads touch, not from a service contract that could be terminated, modified, or politically affected.

The Sovereign Trust Model is a refusal to delegate the trust-bearing layer of an architecture to a counterparty whose incentives are misaligned. AWS optimizes for hyperscale consumption; Anthropic for Claude-fleet usage; OpenAI for API revenue. None of those vendors has any structural reason to make a sovereign deployment cheaper, more durable, or easier to migrate. **A vendor cannot credibly build vendor-neutral infrastructure** because doing so erodes their own moat.

Trust derived from ownership is also trust derived from **demonstrated reproducibility**. The lab's Feb 2026 full-pipeline rebuild from scratch was the receipt that the substrate is rebuilable; it proved that a "sovereign" claim wasn't theoretical. SOM's pillars are the formalization of that property at the agent-coordination layer.

## 2. Singleton/Instance Asymmetry

**Driver**: SOM has two structurally distinct kinds of agent work, and conflating them produces predictable bottlenecks.

| Class | Examples | Substitutable? | Failure mode of bad input |
|---|---|---|---|
| **Instance work** | `implementation`, `infrastructure`, `research`, `analysis`, `documentation` | Yes — multiple instances can parallelize under the same role | Wasted compute — work redoes itself |
| **Singleton work** | Patton (failure-mode review), Einstein (physics falsification), Newton (sovereign astro inference), Judge (final authority) | **No — non-substitutable** | Wrong output that downstream work depends on |

The asymmetry is not just about retry. Singletons cannot be **load-balanced**: Bob cannot fill in for Patton on a failure-mode review, Watson cannot substitute for Einstein on physics falsification. Singletons aren't interchangeable; that's what makes them singletons.

The operational consequence: PCT (Principal Control Token — the message-from-Principal-to-Singleton artifact) accuracy gates *throughput* on instances but gates *correctness of irreplaceable work* on singletons. Bad PCT to an instance produces wasted compute; bad PCT to a singleton produces wrong output that cascades into downstream work that depended on its correctness.

The cascade is not undetected forever — it is corrected by the same dialectical engine that produces it. The next reviewer in the chain notices the bad downstream effect, surfaces the original PCT miscalibration, and a CLCA cycle logs it. The system has self-correction; the cascade framing is about *blast radius before correction*, not about unrecoverable failure.

For Slim Enterprise Orgs (Section 6), this matters disproportionately because singletons are the bottleneck the mesh cannot parallelize away. The mesh can spawn Watson-instances; it cannot spawn Patton-instances. **The discipline of PCT-crafting is therefore a load-bearing operator skill**, not a nice-to-have. PCT formalization (which pillar owns its schema, what fields are required, what validation gates apply) is a Section-6 open driver.

## 3. Sovereignty vs. Vendor-Mediated Architecture (VMA)

**Driver**: Every SOM pillar exists because a vendor-mediated alternative would compromise the Sovereign Trust Model. The seven-pillar shape is not arbitrary — it's the orthogonal decomposition of architectural concerns that vendors otherwise mediate.

| Vendor-Mediated Architecture (VMA) provides | SOM pillar replaces it with |
|---|---|
| OpenAI / Anthropic tool registries → plugin contracts | **PCS** |
| Slack / Discord / vendor inboxes → async hand-off | **IBX** |
| Pinecone / OpenAI Vector Store → retrieval | **AKB** |
| Datadog / Honeycomb → cognitive telemetry | **ACT** |
| AWS Lambda / containerd → ephemeral isolation | **DPG** |
| AWS Batch / Slurm → compute scheduling | **CRB** |
| Anthropic safety filters / vendor RBAC → policy enforcement | **PGE** |

The structural property that makes SOM defensible is that the seven pillars are **necessary AND sufficient**: drop one and the lab is fragile in a predictable way (no plugin contracts → no PCS → schema drift across the fleet; no inbox → no IBX → reasoning context dissipates between sessions; etc.). Necessary-AND-sufficient decompositions are rare in software architecture, and SOM hits both.

Layer A / Layer B framing applies to this driver directly: VMA-mediated architectures expose the trust-bearing surface to the vendor (Layer B = vendor's control plane). SOM keeps Layer B internal — pillars *consume* commodity substrate (ClickHouse, Linux, Mish activation, BGE embeddings) but their semantic contracts are the lab's. The defensible IP lives in the private control plane; the public consumable (papers, methods, dataset outputs) is Layer A.

## 4. The Exit Test

**Driver**: A claim of sovereignty that is never tested is not sovereignty. The Exit Test is the codified constraint: **at any pillar, can the substrate be swapped without rewriting the architecture?**

| Pillar | Current substrate | Substitutable substrate (Exit Test pass = yes) |
|---|---|---|
| PCS | Markdown specs + JSON schemas | YAML / MsgPack / any structured serializer — pass |
| IBX | ClickHouse `messages.inbox` + custom MCP | Kafka / RabbitMQ / Redis Streams — pass (with re-implementation effort) |
| AKB | ClickHouse vector indexes + BGE embeddings | Qdrant / Weaviate / pgvector — pass |
| ACT | (pending) ClickHouse spans | OpenTelemetry-compatible backend — pass-by-design |
| DPG | git worktrees + isolated CUDA builds | Containerized DPG / nspawn / firecracker — pass |
| CRB | DAC link + per-host dispatch convention | Nomad / Slurm — pass (with daemon implementation) |
| PGE | MCP-SECURITY-FRAMEWORK + per-server tests | OPA / Cedar / per-pillar policy engine — pass |

The Exit Test is the operational answer to a real failure mode: **sovereign-built-but-never-shipped** is a way to die. Substrate-agnostic claims fail at the moment of actual migration unless the rebuild path was tested. The 2026-02 lab rebuild was the first Exit Test pass at the substrate layer; pillar-level Exit Tests will follow as each pillar matures.

A pillar that fails the Exit Test isn't a sovereign pillar — it's a lock-in defect. The test is therefore a CLCA gate, not a feature: it determines whether the pillar can ship.

## 5. Production Validation

The SOM Production Validation manifesto — what pillars are validated, at what level of evidence, with what verifier paths — is a separate canonical document. This Problem Statement does not duplicate that work; it references it.

See [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) (v1.0 at commit `647c232`, Patton sign-off `3b509ee3`). Status summary at the time of this document's authoring:

- **Fully Validated** (with verifier paths in the manifesto): PCS, IBX, PGE, DPG, CRB (CRB validation claim is "the dispatch discipline is in production," not "CRB-daemon" — that distinction is honest framing, not papering)
- **Specification complete + Phase-1 build active**: AKB (KI7MT/akb on `main` at `7ec8ea4` with 4 tools, six-step Tier-1 flow, 31/31 unit tests; live integration smoke test passing post-sign-off)
- **Specification phase**: ACT (named pillar, no spec, no code)

The production-validation document is itself an artifact of the lab being its own proof customer (Section 6 design driver: "lab as proof customer"). It is publishable.

## 6. Open Design Drivers (Surfaced, Not Committed)

This is the load-bearing section. It captures drivers that have emerged from operational reality but have not yet been folded into pillar specifications. Without this section, the document ossifies; with it, the document stays useful as a live design-lab record.

### 6.1 Slim Enterprise Org market positioning

**Driver**: SOM's natural customer is **resource-constrained + sovereignty-required + multi-project + single-operator (or small team)**. The "Slim Enterprise Org" framing names this segment.

| Segment | Big-8 cloud serves | Sovereignty required? | Resource-constrained? |
|---|---|---|---|
| FAANG-tier | Yes | No | No |
| Defense contractors | Gap (FedRAMP) | Yes | Yes |
| Regional banks | Gap (GLBA / data residency) | Yes | Yes |
| Hospitals | Gap (HIPAA / ePHI) | Yes | Yes |
| EU mid-market | Gap (Schrems-II / GDPR) | Yes | Yes |
| Government labs | Gap (classification) | Yes | Yes |
| Mid-size research | Gap (IP retention) | Yes | Yes |

The lab itself is the canonical Slim Enterprise Org — same shape, same constraints. **Dogfooding is the strongest validation a platform can have**, and SOM built BY the lab FOR the lab has built-in feedback loops on every defect. Open question: how does this positioning translate into product packaging (open-source vs. tier'd vs. consulting)? Not committed.

### 6.2 The Workload Classification driver (CRB scope)

**Driver**: Most Slim Enterprise Org work is **not GPU-bound**. It's database analytics, agent reasoning, document workflows, and audit. The bottleneck isn't "not enough compute" — it's **lacking visibility into which workloads can run in parallel on existing compute**.

CRB's eventual spec should distinguish at minimum:
- GPU-bound (training, large-batch embedding, BGE re-encoding)
- DB-bound (ClickHouse queries against `wspr.bronze`, `contest.bronze`, `akb.chunks`)
- Reasoning-bound (agent inference, MCP tool calls, documentation drafting)

The bottleneck pattern observed today (single-operator + N-agents, work serializes through human) is the operational pain point that motivates CRB scheduling. Workload classification is a CRB-spec open driver.

### 6.3 PCT-as-message-schema (IBX scope)

**Driver**: PCT (Principal Control Token) — the message-from-Principal-to-Singleton artifact — has been operationally enforced all session without being formally named. The Singleton/Instance Asymmetry (Section 2) makes PCT accuracy structurally load-bearing.

**Locked decision**: PCT lives in IBX (Option B). Both Bob and Patton concurred independently — *PCT is a message; IBX is the message system. PCS owns syntactic meta-rules, not specific schemas. Pillar-owns-its-own-schemas keeps the seven pillars orthogonal and prevents PCS from becoming a junk drawer.*

**Open**: the eight-field PCT contract (task, context, scope, success criteria, authority bounds, version, audit, ...), validation gates, malformation detection, versioning policy. These live in a future IBX pillar spec.

### 6.4 ACT scope boundaries

**Driver**: ACT (Agent Cognitive Telemetry) is a named pillar but has no spec and no code. Open scope questions:

- Is ACT only span/token-tracking, or also reasoning-trace capture (full token streams, tool-call inputs/outputs)?
- Is ACT real-time queryable (operator dashboard) or batch-only (post-hoc audit)?
- Does ACT consume from IBX (correlation with messages) or stand alone?

ACT spec work follows AKB Phase-1 completion. Surfacing these questions now keeps the eventual spec disciplined.

### 6.5 Credentials-as-next-pillar

**Driver**: The lab currently has seven credential classes (ClickHouse `default`, ClickHouse `akb`, ClickHouse `inbox`, MCP-server-specific API keys, per-host SSH, ZFS encryption, GitHub PATs) across five different access patterns (env vars, mode-600 files, OS keyring, `~/.ssh/`, out-of-band). No central audit, no rotation policy, no per-agent scoping. **It works for one operator + four hosts; it doesn't scale to multi-project + multi-host + sovereign-customer.**

Open question: is credential management an eighth pillar, or is it absorbed into PGE (policy enforcement) or IBX (auth contract for message routing)? The HashiCorp pattern would suggest a dedicated pillar (Vault is its own product, not part of Consul or Nomad). Not committed.

**Resolution trigger**: resolved when SOM faces a first credential-rotation workload that PGE-as-rule-engine cannot cleanly govern. The decision depends on what credential workloads SOM actually faces at scale — defense IL5/IL6 has different requirements than healthcare PII which has different requirements than financial trading. Forcing the answer in v0.1 would be premature; letting the question stay open until concrete workloads pressure-test it preserves optionality.

### 6.6 Build-for-self-first → product-for-others strategy

**Driver**: SOM is built BY the lab FOR the lab first, then offered externally. This is the Linux / Git / Kubernetes / HashiCorp pattern. Open: what does "offered externally" mean for SOM specifically? Open-source? Tier'd licensing? Consulting wrapper? Foundation-hosted? Not committed.

### 6.7 CLCA as through-line

**Driver**: Closed-Loop Corrective Action (CLCA) — from KI7MT's manufacturing 8D background — applies at every layer: data sources, builds, training, testing, agent-ops, pillar specs. Every dead-end (V23-V27, the "Vault" naming collision, the `mcp/akb_mcp/` scaffold-shadowing) was a CLCA cycle.

Open: how is CLCA codified as a SOM-level primitive vs. operational discipline? Each pillar spec already references CLCA review gates; whether CLCA is itself a pillar or a cross-cutting discipline is not yet committed.

### 6.8 The "prove us wrong" epistemological stance

**Driver**: The lab operates from *academic rigor, not academic claim*. The discipline is: we use real data, real workloads, real failure modes; we publish what we learn; we expect external falsification; **we'd rather be wrong cleanly than right by claim**. Eight architectural dead ends (V23-V27) are documented because the failures matter as much as the successes.

This stance shapes paper authorship, documentation style, and validation framing. It is not (yet) a pillar — it is the cultural substrate underneath all seven pillars. Open: does this discipline need formalization, or is it best left as an unwritten norm? Two-layer IP framing (Layer A public outputs, Layer B private control plane) gives it operational structure; whether it needs further codification is open.

## Sequencing and Forward Look

This document captures drivers. Pillar specifications operationalize them. Order of likely future spec work:

1. **AKB Phase-1 completion** (build is active; live integration smoke test passed)
2. **IBX spec** — formalizes message routing, PCT schema, Judge-approval gates
3. **ACT spec** — schema + storage backend choice
4. **DPG / CRB / PGE specs** — these are currently operational by convention; formal specs follow as the pillars mature
5. **Slim Enterprise Org product positioning** — open question, follows pillar maturation

When a pillar spec lands and changes a status row, `SOM-PILLAR-NAMES.md` updates first (per its CLCA edit procedure), then this document and `SOM-PRODUCTION-VALIDATION.md` update in follow-up commits.

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record)
- [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) — production-validation manifesto (v1.0, Patton-signed-off)
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS spec (production)
- [`akb-awareness-layer.md`](akb-awareness-layer.md), [`akb-reasoning-independence.md`](akb-reasoning-independence.md), [`akb-lifecycle.md`](akb-lifecycle.md) — AKB three-spec gate
- [`REPO-SHAPE-DECISIONS.md`](REPO-SHAPE-DECISIONS.md) — single-vs-multi-repo diagnostic
- `CLAUDE.md` — operational reference for the lab as a whole
