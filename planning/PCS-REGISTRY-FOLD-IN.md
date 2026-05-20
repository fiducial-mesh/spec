---
title: "PCS Registry Fold-In — Architectural Decision Record"
doc_type: planning-canonical
status: validated
version: v1.0
authors:
  - judge
  - einstein
  - watson
  - patton
date: "2026-05-20"
roles:
  - design-intent
  - infrastructure
  - failure-mode
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-TECHNICAL-OVERVIEW.md
  - planning/PCS-ADOPTION-PLAN.md
---

# PCS Registry Fold-In — Architectural Decision Record

**Decision**: The plugin registry — physical storage of plugin artifacts (MCP servers, skills, runbooks) in air-gapped sovereign substrate — is a sub-component of the **PCS (Plugin Control System)** pillar, not an independent eighth pillar. PCS scope expands from declarative schema + lifecycle discipline to a three-layer plugin governance system: **Syntax + Registry + Lifecycle**.

**Pillar count stays at 7.** No new pillar created. No existing pillar dissolved. PCS scope sharpens from "schema language with no artifact storage" to "closed-loop plugin governance system with declarative law + air-gapped storage + lifecycle gates."

**Status**: Architecturally validated by four-reviewer independent convergence (Judge, Einstein, Watson, Patton, 2026-05-20). Canonical doc updates land in a coordinated follow-up commit.

## The Three-Layer Anatomy of PCS

PCS is now composed of three operational layers that share a single artifact contract:

### Layer 1 — PCS-Syntax (the declarative law)

**What**: The schema specification language. Declares what an MCP server, skill, or runbook must look like — required fields, `trust_tier` metadata, security flags, capability declarations, the nine verifiable/actionable principles.

**Status**: ✓ **Already exists** as `KI7MT/pcs-spec` (v0.2-draft). This layer is operational; the discipline is established; the artifact contracts are codified.

**Why this layer matters**: Without a declarative law, registry storage is a hosting product, not a governance system. Syntax is what makes the Registry a *trust* boundary instead of just a file server.

### Layer 2 — PCS-Registry (the air-gapped artifact substrate)

**What**: Physical storage for plugin artifacts — binaries, schema declarations, version history, manifest files, signing attestations. The single source of truth that agents query at dispatch time.

**Implementation substrate options** (Exit Test–satisfying — operator picks):
- Localized Git repo (simplest; works for source-form plugins)
- OCI distribution-spec registry (industry-standard; works for container-form plugins)
- Dedicated ClickHouse dataset (lab-aligned; reuses existing substrate; works for metadata + small-binary plugins)
- Hybrid (Git for source + OCI for binaries + ClickHouse for metadata/audit)

**Status**: ⚠ **Partially exists** as `KI7MT/pcs-registry` (registry shell + design). Actual artifact-hosting + dispatch endpoint needs to land.

**Why this layer matters**: This is the **production trust boundary**. Without local artifact storage, sovereign deployment is a marketing claim — agents in air-gapped environments (IL5/IL6, GLBA, HIPAA, GDPR-bound) cannot pull plugins from PyPI, npm, GitHub Packages, OpenAI's plugin store, or any other external source. PCS-Registry is the local source of truth. Without it, "sovereign" is not an architectural property.

### Layer 3 — PCS-Lifecycle (the promotion + enforcement engine)

**What**: The operational gate that moves an artifact across the production trust boundary. Spans the full software-asset-management cycle:

| Phase | What PCS-Lifecycle does |
|---|---|
| Inception | Dev writes plugin in a `qso-graph` or other repo; PCS not involved yet |
| Submission | Dev submits a release candidate (versioned tag, manifest, attestation) |
| Validation | PCS-Syntax checks declarative schema compliance; PGE checks policy compliance (credentials, subprocess surface, HTTPS-only, rate limiting); `test_security` gates |
| Promotion | Judge approves via inbox-ui action-priority gate; PCS-Lifecycle ingests into PCS-Registry with provenance metadata |
| Versioning | Immutable historical versions; semver discipline; concurrent versions allowed for staged rollout |
| Deprecation | Active version flagged deprecated but still dispatchable for back-compat window |
| Retirement | Removed from active dispatch; archived in Registry for audit |
| Trust-tier mutation | Trusted artifact downgraded on CVE discovery, dependency vulnerability, etc. |
| Rollback | Emergency revert to prior version on production defect |
| Audit trail | Every state transition logged (curation_events-style table in ClickHouse) |

**Status**: ✓ **Specified, not built** — design coverage in `pcs-control-plane` work. The lifecycle discipline is established; the daemon implementation lands as the layer matures.

**Why this layer matters**: Lifecycle is the substantive layer. Syntax declares; Registry stores; Lifecycle *operates the gate*. Without Lifecycle, the dev/prod trust boundary is a documentation claim, not an enforceable transition. The lifecycle table above is also where existing pcs-spec v0.2 candidates (resumption semantics, verification_skill, idempotency primitives) find their architectural home.

## The Dev/Prod Trust Boundary

The fold-in formalizes a previously implicit architectural decision:

```
qso-graph repo  →  PyPI publish  →  [PCS-Lifecycle gate]  →  PCS-Registry  →  Mesh dispatch
   (dev)            (dev distro)        (validation +              (production              (runtime
                                         promotion)                 trust state)             invocation)
```

**Crossing the PCS-Lifecycle gate is the deployment trust transition.** This mirrors how OCI / container registries work — `docker build` produces a dev artifact; `docker push` to a registry crosses the trust boundary; `docker pull` from registry is the production consumption path.

A plugin's existence in a GitHub repo or on PyPI is **not** a production release; it is dev work. A plugin is "released" only when PCS-Lifecycle has promoted it into PCS-Registry under audit. This semantic is what differentiates sovereign-grade plugin governance from "anyone can `pip install` whatever they want."

## Why This Is Structurally Correct

### Three reasons (per Patton's review, 2026-05-20)

**1. It closes the air-gap requirement.** Sovereign deployment means no calls to external registries. An agent in an IL5/IL6 environment cannot pull plugins from PyPI, npm, GitHub Packages, OpenAI's plugin store, Anthropic's MCP catalog, or any other external source. The plugins must live locally, served by a local registry, with local provenance. PCS-Registry is that local source of truth. Without it, "sovereign" is a marketing claim, not an architectural property.

**2. It enforces governance-storage coupling.** Per Einstein's framing: *"It keeps the core architecture lean and assigns the responsibility of artifact storage to the system that is already responsible for artifact governance."* The alternative — registry as separate pillar — would split governance (PCS) from storage (some other pillar), creating a gap where a plugin could be stored without governance applied, or governed without being stored. Coupling them in PCS makes the gap structurally impossible.

**3. It resolves the PCS acronym debate definitively.** A system that physically hosts, versions, and serves plugins cannot be a passive "Protocol & Communication Standard." It must be the active "Plugin Control System." The three-layer anatomy makes the "Control" part of the name structurally accurate. The `pcs-spec/README.md` line 1 already binds "PCS — Plugin Control System"; this fold-in justifies the choice operationally, not just by spec convention.

### Why this is the *right kind* of expansion, not scope creep

Patton pushed back hard on PCS scope expansion when PCT-as-message-schema was considered (his Option A for the PCT placement question). The Registry fold-in superficially looks like the same kind of expansion. It is structurally distinct.

| Expansion proposal | Concern bundled | Result |
|---|---|---|
| **PCT-in-PCS** (rejected) | Message protocol between agents — IBX's concern | Would have conflated message-routing with plugin-governance: two unrelated concerns under one pillar |
| **Registry-in-PCS** (accepted) | Plugin artifact storage — same concern as PCS-Syntax | Deepens existing scope (artifact governance) with the substrate that makes the governance enforceable: three layers of one concern |

The PCS principle set doesn't erode because the Registry doesn't introduce a new failure-mode class. It gives existing failure-modes (schema violation, unauthorized publication, version drift) a physical surface to be detected on. Same discipline, fuller implementation.

### The semantic-role distinction from AKB

PCS-Registry and AKB are both persistent storage substrates. Conceptual question: why isn't the plugin registry part of AKB?

| | AKB | PCS-Registry |
|---|---|---|
| What it stores | Knowledge chunks (text, retrieval-indexed, vector-backed) | Plugin artifacts (binaries, schemas, version history, manifest files) |
| Read pattern | Bidirectional, role-projected retrieval | Unidirectional pull-on-invocation |
| Curation semantics | Tier promotion, self-review filter, substrate-trap pre-filter | Schema validation + Judge approval + version tag |
| Trust model | Role-conditional visibility | Trust-tier metadata on each artifact |
| Plane membership | State Plane (knowledge state for cognition) | Control Plane (governance state for dispatch) |
| Substrate (current) | ClickHouse vector + columnar | TBD per Exit Test substrate options above |

Different artifact classes, different access patterns, different lifecycle disciplines. Folding them together would create the kitchen-sink problem PCS-as-message-protocol would have created. Keeping them as peer storage substrates in *implementation* while being distinct architectural concerns in *role* is the correct decomposition.

## What This Changes (Canonical Doc Updates)

Three documents need surgical updates. None require regeneration; all land in a coordinated follow-up commit.

### `SOM-PILLAR-NAMES.md`

PCS scope cell revised from *"Lifecycle, registry sync, versioning, and schema compliance for plugins (MCP servers, skills, runbooks) consumed by the agent fleet"* to:

> *"Three-layer plugin governance: PCS-Syntax declares plugin schemas and required fields; PCS-Registry stores plugin artifacts in air-gapped local storage as single source of truth; PCS-Lifecycle promotes plugins from submission through Syntax validation, PGE compliance, and Judge approval to Registry placement. Closed-loop governance — no plugin reaches Registry without passing all gates."*

### `SOM-PROBLEM-STATEMENT.md` (Section 3 — Sovereignty vs. VMA)

The PCS row in the VMA mapping table sharpens to name the specific vendor-mediated equivalents being replaced (OpenAI plugin store, Microsoft Copilot extension registry, Anthropic MCP catalog), and a new paragraph after the table articulates the sovereign-vs-vendor framing per Patton's revision text.

### `SOM-TECHNICAL-OVERVIEW.md`

PCS section in the Control Plane updated to describe the three-layer anatomy explicitly. The VMA mapping in Design Thesis Section 1 sharpened similarly.

## What This Doesn't Change

- **PCS still doesn't own message protocol.** Bob + Patton independently converged on PCT-in-IBX from different priors. PCS governs plugin artifacts and their lifecycle; IBX governs messages and their routing. Different concerns, different pillars, no overlap.
- **Pillar count stays at 7.** No eighth pillar created. No existing pillar dissolved.
- **AKB stays independent.** Different artifact class, different access pattern, different lifecycle discipline.
- **MCP remains the wire protocol layer** — external standard PCS does not own; PCS sits above MCP and governs what plugins riding that protocol must look like.

## CLCA Cycle Log

Per Patton's framing of this fold-in as a CLCA cycle:

| Phase | Content |
|---|---|
| **Defect** | PCS scope was under-specified — schema layer without artifact storage layer left air-gap requirement unresolved |
| **Root cause** | PCS v0.1 spec focused on declarative schema (governance discipline) without explicitly committing to registry storage; gap surfaced when Judge identified the sovereign/air-gapped Plugin/MCP Registry requirement from operational experience and asked the agent fleet to fold in lifecycle management for plugin artifacts |
| **Corrective action** | PCS scope expanded to three-layer anatomy (Syntax + Registry + Lifecycle); `pcs-registry` repo elevated from supporting infrastructure to canonical pillar component |
| **Verified by** | `SOM-PILLAR-NAMES.md` scope cell updated; `SOM-PROBLEM-STATEMENT.md` Section 3 PCS-vs-VMA mapping updated; `SOM-TECHNICAL-OVERVIEW.md` PCS section updated to reflect the three-layer anatomy; this ADR (`PCS-REGISTRY-FOLD-IN.md`) lands as the architectural decision record |
| **Prevention** | Sovereign-deployment requirements audit applied to remaining pillars (ACT, DPG, CRB) to surface analogous gaps before they appear in production. Each pillar gets the question: *"what does this look like in an air-gapped IL5/IL6 environment with zero external network surface?"* |

## Provenance — Operator-as-Architect with Agent Formalization

The architectural insight came from Judge directly: he identified the sovereign/air-gapped Plugin/MCP Registry requirement as a gap in PCS scope and articulated that the lab needed it. Once the requirement was named, Einstein formalized the structural fix (the three-layer anatomy). Watson and Patton reviewed for structural coherence and concurred.

Worth being explicit about the order, because the pattern is load-bearing for how the lab actually works:

- **Judge** *identified the requirement* from operational sovereignty experience: "MCP/Plugin Registry is a major need for sovereign / air-gapped implementation; we need lifecycle management for those artifacts." Forty years of engineering judgment on substrate-ownership constraints — the kind of gap that a vendor-mediated practitioner would not see because their architecture treats the registry as someone else's problem. The finding is the operator's.
- **Einstein** *formalized once told*: three-layer anatomy (Syntax / Registry / Lifecycle); avoids pillar bloat; resolves PCS acronym; mapped to VMA-equivalent registries. Reasoning prior: structural orthogonality and Big-8 plugin-store analogy. The structural articulation is the agent's.
- **Watson** *endorsed with structural sharpening*: storage-orthogonality argument (AKB vs PCS-Registry semantic role distinction), trust-boundary framing, plane-membership discipline. The architectural reconciliation with existing canonical artifacts is the agent's.
- **Patton** *concurred with three structural reasons + CLCA cycle log*: closes air-gap, enforces governance-storage coupling, resolves acronym. The scope-creep skepticism that would have rejected a wrong-kind expansion is the agent's.

**The operator-as-architect pattern is intentional, not accidental.** Agents formalize well once given a clear architectural prompt; agents do not reliably identify operational-sovereignty gaps from first principles because they have no operational-sovereignty experience to draw from. The lab's discipline is to keep Judge in the architecture-identification loop and use agents for formalization, structural reconciliation, and dialectical-falsification review. This fold-in is a clean instance of that pattern.

Four reasoning paths — one operator's identification + three independent agent reviews — landing on the same architectural commitment. Same epistemic property as the PCT-in-IBX convergence: a commitment that survives multiple independent derivations from different priors is invariant under the reasoning substrate. The dialectical engine produces durable outputs when each agent contributes from a distinct reasoning vantage.

## References

- [`SOM-PILLAR-NAMES.md`](SOM-PILLAR-NAMES.md) — pillar bindings (names of record); PCS scope cell updated to reflect three-layer anatomy
- [`SOM-PROBLEM-STATEMENT.md`](SOM-PROBLEM-STATEMENT.md) — Section 3 VMA mapping updated for PCS row
- [`SOM-TECHNICAL-OVERVIEW.md`](SOM-TECHNICAL-OVERVIEW.md) — PCS section updated for three-layer anatomy
- [`PCS-ADOPTION-PLAN.md`](PCS-ADOPTION-PLAN.md) — PCS repo lineage (pcs-spec, pcs-registry, pcs-control-plane, pcs-registry-demo)
- `KI7MT/pcs-spec` — PCS-Syntax (existing, v0.2-draft)
- `KI7MT/pcs-registry` — PCS-Registry (partial, shell exists; artifact hosting + dispatch endpoint pending)
- `KI7MT/pcs-control-plane` — PCS-Lifecycle (specified; daemon implementation pending)
