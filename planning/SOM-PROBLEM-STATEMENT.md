---
title: "SOM Problem Statement — Design Drivers from Operational Practice"
doc_type: planning-canonical
status: draft
version: v0.6
authors:
  - watson
  - patton
  - einstein
  - judge
date: "2026-06-02"
roles:
  - design-intent
  - infrastructure
  - failure-mode
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-DESIGN-PHILOSOPHY.md
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/PCS-ADOPTION-PLAN.md
  - planning/akb-awareness-layer.md
  - planning/REPO-SHAPE-DECISIONS.md
---

# SOM Problem Statement — Design Drivers from Operational Practice

**Visual reference**: [`diagrams/som-architecture.png`](diagrams/som-architecture.png) (legacy, 7-pillar PNG) and [`diagrams/som_architecture_with_identity_and_arca.svg`](diagrams/som_architecture_with_identity_and_arca.svg) (current, 8-pillar with the IAM pillar and ARCA above the dotted line).

> This document captures design drivers for the Sovereign Orchestration Mesh (SOM) as they emerged from operational practice in the KI7MT Sovereign AI Lab. Each driver is sourced from a real workload, decision, or observed pattern. **Drivers are inputs to architecture; they are not themselves commitments.** Architectural commitments are made in pillar-specific spec documents (`PCS-ADOPTION-PLAN.md`, the AKB three-spec gate, the IAM design package — `SOM-DESIGN-PHILOSOPHY.md` + `SOM-IDENTITY-PILLAR-DESIGN.md` + `SOM-INSTANTIATION-AND-IDP.md` — and the pending IBX / ACT / DPG / CRB / PGE specs), and gated by CLCA review.
>
> Pillar names used throughout this document are the names of record from [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md). Any inconsistency between a pillar reference here and that file is a defect against that file, not against this one.

## Scope

SOM is the eight-pillar platform that orchestrates the lab's multi-agent fleet on sovereign substrate. Its design drivers come from running an actual lab — single operator (KI7MT), five active agent roles (Watson, Bob, Patton, Einstein, Newton), four hosts (M3, 9975WX, EPYC, TrueNAS), four concurrent project workstreams (IONIS-AI, QSO-Graph, PCS, AKB), all on owned hardware with no cloud dependencies. The drivers below are the operational reality that shapes the pillars. Section 6 catalogs drivers that are surfaced but not yet committed to a pillar specification.

The IAM pillar (foundational, added v0.5) is at **design stage with briefs-only implementation** — its drivers are captured but no IAM services are running. References to the IAM pillar in this document describe the design target, not running infrastructure; the implementation gap is held verbatim, never resolved by assumption.

## 0. Architecture Overview — Three Planes (plus an Issuance Plane above the dotted line)

SOM organizes its pillars into three runtime planes plus an issuance plane (see [`diagrams/som_architecture_with_identity_and_arca.svg`](diagrams/som_architecture_with_identity_and_arca.svg) for the visual contract):

| Plane | Concern | Pillars |
|---|---|---|
| **Issuance Plane** (above the dotted line) | Sovereign root of trust; mints identities and steps out; offline, never in the action path | **ARCA** (the Agentic Root CA, the issuance authority component of SOM's IAM pillar) |
| **Control Plane** | Governance, scheduling, message routing, human approval gate, identity verification + authorization | **Identity verification + authorization** (the runtime half of SOM's IAM pillar, beneath PGE — authorization consumes verified identity), PCS, PGE, CRB, IBX, plus **Judge** as the human-in-the-loop element |
| **Compute Plane** | Where agent work executes; sandboxed isolation for generated code | **Workforce** (the five-callsign cluster — Watson, Bob, Patton, Einstein, Newton) + DPG |
| **State Plane** | Append-mostly persistent substrates that other planes write into and read from | AKB (bidirectional, role-projected retrieval), ACT (unidirectional telemetry emission) |

The dotted line between the Issuance Plane and the runtime planes is a deliberate security property, not tidiness: because ARCA is never in the action path, it can be kept offline, and an offline authority cannot be attacked over the network during operation. Runtime verification is local (signature + trust chain), never a callback. The air-gap is therefore an assumption of the design rather than a constraint fighting it. Identity verification + authorization on the Control Plane consume already-issued identity, so the IAM pillar is the layer the whole runtime stands on — every other guarantee above it (PCS, PGE, CRB, IBX, Workforce, DPG, AKB, ACT, Judge) inherits its rigor. **Current state: design only — no ARCA, Vault, Roster, login, or credentials are built; the IAM row on `SOM-PRODUCTION-VALIDATION.md` is the implementation-status record.**

Two structural observations follow from this shape:

1. **IBX is the hub.** Every Control-Plane pillar (PCS, PGE, CRB) and Judge route to Workforce *through* IBX. That's why PCT (Principal Control Token — the message-from-Principal-to-Singleton artifact) lives in IBX rather than expanding PCS scope: PCT is a message; IBX is the message system. The layer distinction is load-bearing — PCS is plugin schema/governance, MCP is the wire protocol agents use to invoke plugins, IBX is the message-routing substrate. Bob and Patton converged on PCT-in-IBX independently from different priors; Section 6.8 discusses why that convergence is itself a structural property worth naming.

2. **Workforce is a first-class named container** for the five-callsign cluster, not a loose aggregation. The naming makes explicit that singletons (Patton, Einstein, Newton) and anchored personas (Watson, Bob) belong to one bounded set, which is the structural object the Singleton/Instance Asymmetry (Section 2) operates on.

The whole stack rests on **Customer Infrastructure (Sovereign / Air-gapped)** — owned hardware, no cloud dependencies, no managed-service substrate. The architecture is air-gapped ready and **exfiltration hostile** by construction, not by configuration.

## 1. The Sovereign Trust Model

**Driver**: Trust in this architecture derives from **architectural ownership**, not vendor SLA. Einstein's framing — *"Architecture is Sovereignty"* — captures the principle: the lab's confidence that its workloads will run correctly tomorrow comes from owning every layer that those workloads touch, not from a service contract that could be terminated, modified, or politically affected.

The Sovereign Trust Model is a refusal to delegate the trust-bearing layer of an architecture to a counterparty whose incentives are misaligned. AWS optimizes for hyperscale consumption; Anthropic for Claude-fleet usage; OpenAI for API revenue. None of those vendors has any structural reason to make a sovereign deployment cheaper, more durable, or easier to migrate. **A vendor cannot credibly build vendor-neutral infrastructure** because doing so erodes their own moat.

Trust derived from ownership is also trust derived from **demonstrated reproducibility**. The lab's Feb 2026 full-pipeline rebuild from scratch was the receipt that the substrate is rebuilable; it proved that a "sovereign" claim wasn't theoretical. SOM's pillars are the formalization of that property at the agent-coordination layer.

A stronger framing: the architecture is **air-gapped ready and exfiltration hostile**. Sovereignty is not just where the workloads run (on-premises deployment); it is whether the architecture can be operated without trust-bearing paths to a counterparty. Every pillar is engineered to satisfy this — credentials never leave the host that owns them, telemetry stays in lab-controlled storage, vector retrieval queries never reach an external service. The bet is not that any single layer is impenetrable; it is that no layer creates an exfiltration path *by design*.

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

### Relationship to the three agent archetypes (related but distinct axes)

The Singleton/Instance distinction is one axis (substitutability — can a different agent do this work, or not). The companion design `SOM-CONCURRENCY-AND-ARCHETYPES.md` (Patton + Watson, 2026-06-02) surfaced a second axis (archetype — what governance intensity does this work warrant) that is **related but distinct, not fully orthogonal**: the archetype *determines* the identity-vs-session pattern that work uses, so the two axes are coupled at the structural layer.

- **Worker** (many concurrent sessions of one identity, narrow authority, automated): worker-pool work is structurally one identity with N concurrent sessions. A worker pool of *distinct identities* would be meaningless identity sprawl — workers are interchangeable; that's the point.
- **Reasoner** (few concurrent sessions of a broad-authority identity, human-gated for high-stakes): few sessions of one identity (Patton/Einstein/Newton singletons).
- **Quorum Voter** (N independent voters reasoning over the same unit of work, consensus aggregates the outcome, used when being wrong is expensive): structurally requires **N distinct identities**, NOT N sessions of one — voter independence depends on it. Pairing quorum with shared-identity-sessions would produce N identical executions that fail identically and silently destroy the entire value of the quorum.

So the archetype choice constrains the identity-vs-session pattern. The substitutability axis (Singleton/Instance) and the archetype axis are both real and both load-bearing, but they are not freely-combinable — quorum cannot ride the worker-pool identity pattern, and a Singleton archetype is always one of {Reasoner, Quorum-voter-instance} rather than a Worker. The archetype design is referenced rather than duplicated here; consult that doc for the concurrency model, the identity-vs-session distinction, the confidence-aggregation pattern, the four hard rules on label-oracle non-loop, and the seven open items pending Judge rulings.

## 3. Sovereignty vs. Vendor-Mediated Architecture (VMA)

**Driver**: Every SOM pillar exists because a vendor-mediated alternative would compromise the Sovereign Trust Model. The eight-pillar shape is not arbitrary — it's the orthogonal decomposition of architectural concerns that vendors otherwise mediate.

| Vendor-Mediated Architecture (VMA) provides | SOM pillar replaces it with |
|---|---|
| Cloud IdP (Okta / Auth0 / AWS Cognito / Azure AD) → identity issuance + credential management + RBAC | **SOM's IAM pillar** (ARCA + Vault + Roster + Publish pipeline + pluggable IdP) — design-stage, briefs-only implementation |
| OpenAI plugin store / MS Copilot extension registry / Anthropic MCP catalog → plugin governance + storage + lifecycle | **PCS** (Syntax + Registry + Lifecycle) |
| Slack / Discord / vendor inboxes → async hand-off | **IBX** |
| Pinecone / OpenAI Vector Store → retrieval | **AKB** |
| Datadog / Honeycomb → cognitive telemetry | **ACT** |
| AWS Lambda / containerd → ephemeral isolation | **DPG** |
| AWS Batch / Slurm → compute scheduling | **CRB** |
| Anthropic safety filters / vendor RBAC → policy enforcement | **PGE** |

The structural property that makes SOM defensible is that the eight pillars are **necessary AND sufficient**: drop one and the lab is fragile in a predictable way (no identity root → no IAM → no attribution and no authenticated principal; no plugin contracts → no PCS → schema drift across the fleet; no inbox → no IBX → reasoning context dissipates between sessions; etc.). Necessary-AND-sufficient decompositions are rare in software architecture, and SOM hits both. The IAM pillar (foundational, design-stage) is the layer the other seven are downstream of — for the seven validated pillars to actually inherit Tier-0 rigor (no-bypass, fail-strict, attribution-true-at-every-layer), the IAM design must be built; until then the seven validated pillars run against a brief-asserted identity, not a credential-verified one.

**On PCS specifically** — PCS replaces vendor app stores and proprietary plugin registries (OpenAI's plugin store, Microsoft Copilot extension registry, ChatGPT GPT marketplace, Anthropic's MCP catalog) with a customer-owned, air-gapped plugin governance and storage system. The customer's plugins live in the customer's PCS-Registry, validated by the customer's PCS-Syntax, promoted through the customer's PCS-Lifecycle. No external network surface required for agents to discover, retrieve, or invoke production plugins. This is the sovereignty argument's strongest pillar-level claim — vendor app stores are the single most legible lock-in mechanism in agentics today, and PCS-as-sovereign-registry is the architectural answer. See [`PCS-REGISTRY-FOLD-IN.md`](PCS-REGISTRY-FOLD-IN.md) for the three-layer anatomy and the dev/prod trust-boundary framing.

Layer A / Layer B framing applies to this driver directly: VMA-mediated architectures expose the trust-bearing surface to the vendor (Layer B = vendor's control plane). SOM keeps Layer B internal — pillars *consume* commodity substrate (ClickHouse, Linux, Mish activation, BGE embeddings) but their semantic contracts are the lab's. The defensible IP lives in the private control plane; the public consumable (papers, methods, dataset outputs) is Layer A.

**Note on PGE's double-guardrail enforcement**: PGE acts at two distinct enforcement points — **agent-action policy** *before* messages reach IBX (catches non-compliant intent at submission time, before downstream work is wasted) and **sandbox-execution policy** *inside* DPG (catches non-compliant code at runtime, before it touches production state). The two-point enforcement is structurally important because intent-side and execution-side compliance gaps are different failure classes; either gate alone misses one class. VMA models typically enforce at one point (vendor safety filter on the LLM input/output) and miss the execution-side surface entirely.

## 4. The Exit Test

**Driver**: A claim of sovereignty that is never tested is not sovereignty. The Exit Test is the codified constraint: **at any pillar, can the substrate be swapped without rewriting the architecture?**

| Pillar | Current substrate | Substitutable substrate (Exit Test pass = yes) |
|---|---|---|
| IAM | (not built) Design names integrate-don't-build for Vault and pluggable crypto provider; Roster as standalone or federated to corporate IdP via abstract interface | HashiCorp Vault / cloud KMS/HSM / PKCS#11 (Vault); LDAP / AD / Okta-OIDC / PIV-CAC (IdP); standard PKI primitives (ARCA) — pass-by-design (cannot be verified until built) |
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

See [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) (v1.1, Patton sign-off `3b509ee3` for v1.0 rows; IAM row added in v1.1 as design-stage). Status summary at the time of this document's authoring:

- **Fully Validated** (with verifier paths in the manifesto): PCS, IBX, PGE, DPG, CRB (CRB validation claim is "the dispatch discipline is in production," not "CRB-daemon" — that distinction is honest framing, not papering)
- **Specification complete + Phase-1 build active**: AKB (KI7MT/akb on `main` at `2474cf5` with 4 tools, six-step Tier-1 flow, live integration smoke test passing 7/7)
- **Specification phase**: ACT (named pillar, no spec, no code)
- **Design-stage, briefs-only implementation**: SOM's IAM pillar (foundational, eighth, added 2026-06-01). Design at `SOM-DESIGN-PHILOSOPHY.md` + `SOM-IDENTITY-PILLAR-DESIGN.md` + `SOM-INSTANTIATION-AND-IDP.md`; no Vault, no Roster, no ARCA, no login, no credentials, no enforcement built yet. The IAM row is **not** a validation claim and may not be cited as a validated pillar until built and verified.

The production-validation document is itself an artifact of the lab being its own proof customer (Section 6 design driver: "lab as proof customer"). The v1.0 production rows are publishable; the v1.1 IAM row is not — it is design-stage and carries explicit no-promotion language.

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

**Locked decision**: PCT lives in IBX (Option B). Both Bob and Patton concurred independently — *PCT is a message; IBX is the message system. PCS owns syntactic meta-rules, not specific schemas. Pillar-owns-its-own-schemas keeps the eight pillars orthogonal and prevents PCS from becoming a junk drawer.*

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

**§6.5 remains open. The IAM pillar design (provisional) is the intended structural answer; no credential governance is implemented — current state is briefs-only.** The IAM pillar design — `SOM-DESIGN-PHILOSOPHY.md`, `SOM-IDENTITY-PILLAR-DESIGN.md`, `SOM-INSTANTIATION-AND-IDP.md`, landed 2026-06-01 — answers the *question* "should credentials be a pillar" (yes, a foundational one, absorbing credential governance via ARCA + Vault + Publish-pipeline + scoped per-agent credentials bound to job code). It does **not** close this driver, because the *driver* — credential governance at lab and customer scale — is not yet built. The lab still has the seven credential classes and five access patterns named above; the design says how they will be replaced, not that they have been. The bar to close §6.5 is the same as the bar to promote the IAM pillar on `SOM-PRODUCTION-VALIDATION.md`: working IAM substrate, verification pass, Patton sign-off. Until then, this driver stays open as a live design-lab record of the implementation gap.

### 6.6 Build-for-self-first → product-for-others strategy

**Driver**: SOM is built BY the lab FOR the lab first, then offered externally. This is the Linux / Git / Kubernetes / HashiCorp pattern. Open: what does "offered externally" mean for SOM specifically? Open-source? Tier'd licensing? Consulting wrapper? Foundation-hosted? Not committed.

### 6.7 CLCA as through-line

**Driver**: Closed-Loop Corrective Action (CLCA) — from KI7MT's manufacturing 8D background — applies at every layer: data sources, builds, training, testing, agent-ops, pillar specs. Every dead-end (V23-V27, the "Vault" naming collision, the `mcp/akb_mcp/` scaffold-shadowing) was a CLCA cycle.

Open: how is CLCA codified as a SOM-level primitive vs. operational discipline? Each pillar spec already references CLCA review gates; whether CLCA is itself a pillar or a cross-cutting discipline is not yet committed.

### 6.8 The "prove us wrong" epistemological stance (and the dialectical engine)

**Driver**: The lab operates from *academic rigor, not academic claim*. The discipline is: we use real data, real workloads, real failure modes; we publish what we learn; we expect external falsification; **we'd rather be wrong cleanly than right by claim**. Eight architectural dead ends (V23-V27) are documented because the failures matter as much as the successes.

This stance shapes paper authorship, documentation style, and validation framing. It is not (yet) a pillar — it is the cultural substrate underneath all eight pillars. Open: does this discipline need formalization, or is it best left as an unwritten norm? Two-layer IP framing (Layer A public outputs, Layer B private control plane) gives it operational structure; whether it needs further codification is open.

**The dialectical engine — and Independence of Error Distributions**: Multi-agent systems only generate novel insight when agents reason *independently*. VMA models break this property because all agents share the same corporate safety filter and upstream training bias — their errors are correlated, and agreement between them carries less information than it appears to. SOM agents run on operator-controlled models with **mathematically independent error distributions**, which is what permits genuine dialectical falsification rather than shared-blind-spot consensus. Independence is not an aspiration — it is a measurable structural property of the agent fleet.

The dialectical engine's value follows from this: catching errors is one half of what it does; the other half is **producing high-confidence architectural commitments through independent reasoning**. When Bob and Patton converged on PCT-in-IBX from different priors — Bob from "PCS owns syntactic meta-rules, not specific schemas," Patton from "PCT is a message; IBX is the message system" — the conclusion carried more weight than either reasoning path alone, because two independent priors cannot share a blind spot. That convergence is the same epistemic property as scientific reproducibility: an architectural commitment that survives multiple independent derivations is invariant under the reasoning substrate. Worth marking explicitly because it is the load-bearing reason the dialectical engine produces durable outputs, not just clean reviews.

## Sequencing and Forward Look

This document captures drivers. Pillar specifications operationalize them. Order of likely future spec work:

1. **AKB Phase-1 completion** (build is active; live integration smoke test passed)
2. **IBX spec** — formalizes message routing, PCT schema, Judge-approval gates
3. **ACT spec** — schema + storage backend choice
4. **IAM build scope** — design landed 2026-06-01 in `SOM-DESIGN-PHILOSOPHY.md` + `SOM-IDENTITY-PILLAR-DESIGN.md` + `SOM-INSTANTIATION-AND-IDP.md`; build scope (Vault + Roster + ARCA + Publish pipeline + agent-side login flow) follows AKB Phase-1 completion. Adding the IAM design does **not** advance its sequence position — current state is briefs-only and the build commitment is intentionally not made by this document.
5. **DPG / CRB / PGE specs** — these are currently operational by convention; formal specs follow as the pillars mature
6. **Slim Enterprise Org product positioning** — open question, follows pillar maturation

When a pillar spec lands and changes a status row, `SOM-PILLAR-NAMES.md` updates first (per its CLCA edit procedure), then this document and `SOM-PRODUCTION-VALIDATION.md` update in follow-up commits.

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record, v1.1)
- [`SOM-PRODUCTION-VALIDATION.md`](SOM-PRODUCTION-VALIDATION.md) — production-validation manifesto (v1.1, IAM design-stage row added)
- [`SOM-DESIGN-PHILOSOPHY.md`](SOM-DESIGN-PHILOSOPHY.md) — IAM conceptual frame (provisional, briefs-only implementation)
- [`SOM-IDENTITY-PILLAR-DESIGN.md`](SOM-IDENTITY-PILLAR-DESIGN.md) — IAM foundational design (provisional, briefs-only implementation)
- [`SOM-INSTANTIATION-AND-IDP.md`](SOM-INSTANTIATION-AND-IDP.md) — IAM onboarding + login + IdP interface (provisional, briefs-only implementation)
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS spec (production)
- [`akb-awareness-layer.md`](akb-awareness-layer.md), [`akb-reasoning-independence.md`](akb-reasoning-independence.md), [`akb-lifecycle.md`](akb-lifecycle.md) — AKB three-spec gate
- [`REPO-SHAPE-DECISIONS.md`](REPO-SHAPE-DECISIONS.md) — single-vs-multi-repo diagnostic
- `CLAUDE.md` — operational reference for the lab as a whole
