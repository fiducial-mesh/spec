---
title: "SOM Spec — Sovereign Orchestration Mesh Integrative Capstone"
doc_type: spec
status: validated
version: v1.0
authors:
  - watson
  - patton
date: "2026-06-02"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-TECHNICAL-OVERVIEW.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
  - planning/IBX-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/PCS-DAEMON-SPEC.md
  - planning/DPG-SPEC.md
  - planning/CRB-SPEC.md
  - planning/PGE-SPEC.md
  - planning/MCP-SECURITY-FRAMEWORK.md
---

# SOM Spec — Sovereign Orchestration Mesh Integrative Capstone

**Scope**: Formalizes the contract for **SOM** (Sovereign Orchestration Mesh) at the integrative level — composing the eight pillar specs (IAM, IBX, PCS, AKB, ACT, DPG, CRB, PGE) into a single mesh contract that verifies the **seams between pillars** compose without gaps or double-coverage. Covers the **three-plane architecture** (Issuance Plane above the dotted line + Control Plane + Workforce Plane) per `SOM-PROBLEM-STATEMENT.md` v0.6 §0, the **complete pillar inventory** with v1.0 contract state, the **cross-pillar dependency graph** (rendered for inspectability per Patton's `f346fdab` forward note: *"I may want the dependency graph rendered so the seams are inspectable, not just prose"*), the **seven IAM Increment-2 rulings** enumerated in ONE place with the complete cross-pillar coupling matrix, the **four-pillar shared ACT v1.x curation event** tracked as a campaign-level open obligation rather than distributed across four VPs, the **post-merge forward-reference sweep** named at campaign level rather than left distributed, the **load-bearing architectural invariants** that hold across all eight pillars, and the **mesh-level Exit Test** discipline that ensures no pillar's substrate choice creates lock-in for the others.

**Status**: **Validated v1.0** — item 7 of the spec-campaign queue, the **integrative capstone** that closes the campaign. Per Patton's `f346fdab` forward note on item 7: *"this one is different in kind from the pillar specs — it's the integrative capstone, so the thing I'll be testing is NOT 'does each pillar's contract hold' (we've verified that eight times now) but 'do the SEAMS between them compose without gaps or double-coverage.' The specific risks: (1) every pillar marks its DRs as coupling to the seven IAM Increment-2 rulings — the SOM spec should confirm those seven rulings are enumerated in ONE place and that no pillar silently front-ran one; (2) the four-pillar shared ACT curation event (pcs/dpg/crb/pge) is now a real cross-cutting obligation that the SOM spec should track as a campaign-level open item, not leave distributed across four VPs; (3) the post-merge forward-reference sweep (MCP-SECURITY-FRAMEWORK → PGE-SPEC across DPG/PCS-Daemon/CRB/IAM) is campaign-level cleanup the SOM spec should name."*

**Named up front per Patton's directive — this spec verifies SEAM COMPOSITION, not pillar contracts.** Each pillar's contract was validated by Patton through PR #61 (AKB three-spec gate) → PR #62 (Concurrency design) → PR #63 (IBX v1.0) → PR #64 (IAM core) → PR #65 (ACT) → PR #66 (PCS-Daemon) → PR #67 (DPG) → PR #68 (CRB) → PR #69 (PGE). What this spec adds is the **mesh-level** assertion that the eight pillar contracts compose into a coherent SOM contract — every seam traces to a committed surface on both sides; no seam has a gap (one side commits a surface the other does not consume); no seam has double-coverage (two pillars commit overlapping enforcement at the same chokepoint).

**Three campaign-level open items** named in this spec (Patton's three risks) and tracked at mesh level rather than distributed across pillar specs:

1. **Seven IAM Increment-2 rulings, enumerated once.** Every pillar that defers behavior to a Judge ruling cites which of the seven IAM Increment-2 DRs it couples to. This spec enumerates the seven in ONE place (§ Seven IAM Increment-2 Rulings) and renders the complete cross-pillar coupling matrix so a single audit verifies no pillar silently front-ran a ruling.
2. **Four-pillar shared ACT v1.x curation event.** VP-PCS-1 + VP-DPG-1 + VP-CRB-1 + VP-PGE-1 each propose a new ACT event-type namespace (`pcs.*`, `dpg.*`, `crb.*`, `pge.*`). Per Patton's standing direction across `4759a355` + `294ec70a` + `ea67f2ac` + `f346fdab`, these resolve in **one shared curation event** to prevent the half-extended-enum failure mode. This spec promotes that obligation from "distributed across four pillar VPs" to **campaign-level open item SOM-VP-1**.
3. **Post-merge forward-reference sweep.** DPG, PCS-Daemon, CRB, and IAM each carry references to `MCP-SECURITY-FRAMEWORK.md` as the de facto PGE source. After PGE v1.0 capstone (PR #69, commit `8be0f5c`), those references should update to `PGE-SPEC.md`. This spec promotes the sweep from "post-merge cosmetic flagged at each pillar review" to **campaign-level cleanup SOM-OQ-1**.

**What this spec does NOT do**:
- Does NOT re-derive pillar contracts. Each pillar's CDs/DRs/VPs/OQs are authoritative in its own spec; this spec references them, never restates them.
- Does NOT introduce new pillars. The mesh is the eight named pillars; future pillar additions follow the SOM-PILLAR-NAMES discipline + Judge sign-off, not this spec.
- Does NOT alter any pillar's substrate choices or Exit Test commitments. Each pillar's substrate substitutability holds at the pillar level; this spec adds the mesh-level discipline that *no pillar's substrate choice may create lock-in for another pillar*.
- Does NOT close any DR or VP. The campaign-level items SOM-VP-1 and SOM-OQ-1 are *tracking items*, not resolutions. Resolutions happen when Judge rules and curation events fire.

## Purpose / Problem Restatement

Per `SOM-PROBLEM-STATEMENT.md` v0.6 §0: SOM is a **mesh of pillars**, not a monolithic platform. Each pillar provides a substitutable substrate primitive at its level (IAM provides identity; IBX provides message routing; PCS provides plugin governance; AKB provides knowledge retrieval; ACT provides audit and detection; DPG provides ephemeral isolation; CRB provides hardware dispatch; PGE provides policy enforcement). The *mesh* property is what holds when those pillars compose: an operator can substitute any one pillar's substrate (e.g., swap ClickHouse for Postgres at the IBX substrate layer) without breaking the contracts the other pillars depend on.

**The integrative capstone exists because the mesh property is not free.** Eight independently-validated pillar contracts can still compose into a broken mesh if:
- Pillar A commits a surface that pillar B does not consume (gap)
- Pillar A and pillar B both commit enforcement at the same chokepoint without coordination (double-coverage)
- Pillar A defers a decision to a ruling that pillar B has already silently front-run (consistency violation)
- Pillar A's substrate choice creates an obligation pillar B's substrate cannot satisfy (mesh-level lock-in)

This spec verifies, at mesh level, that none of those failure modes is present in the v1.0 pillar set. Where a Judge ruling is required to lock down a seam, this spec ensures the deferral is tracked in ONE place rather than scattered across pillars where it could be missed.

**The mesh contract is what holds.** A deployment that satisfies all eight pillar contracts + the mesh-level invariants in this spec **is a conformant SOM deployment**. A deployment that satisfies pillar contracts but violates a mesh invariant (e.g., embeds policy rules in DPG outside the PGE single-source-of-truth commitment) is NOT conformant, regardless of how good each individual pillar implementation looks.

## Pillar Inventory (v1.0 Mesh State)

The eight pillars and their v1.0 contract state. This is the canonical mesh inventory; future pillar additions update this section first.

| # | Pillar | Spec | Status | Implementation State |
|---|--------|------|--------|---------------------|
| 1 | **IAM** (Identity & Access Management) | `IAM-CORE-SPEC.md` v1.0 (PR #64) | Specified — briefs-only, no Vault/Roster/ARCA built | Design-stage; runtime services not built |
| 2 | **IBX** (Inbox) | `IBX-SPEC.md` v1.0 (PR #63) | Specified + operational at v1.0 contract | `agent-inbox-mcp` + ClickHouse `messages.inbox` substrate live |
| 3 | **PCS** (Plugin Control System) | `PCS-DAEMON-SPEC.md` v1.0 (PR #66) + `KI7MT/pcs-spec` artifacts | Specified — Syntax v0.2-draft, Registry shell+design, Lifecycle specified | Plugin consumers live (`qso-graph/*-mcp` fleet, skills); Daemon build target |
| 4 | **AKB** (Agent Knowledge Base) | Three-spec gate v0.3 (PR #61): `akb-awareness-layer.md`, `akb-reasoning-independence.md`, `akb-lifecycle.md` | Specified — Phase-1 build active on `KI7MT/akb` `main` | Six-tool MCP server + Tier-0 generator live; bootstrap orchestrator next |
| 5 | **ACT** (Audit & Cognitive Telemetry) | `ACT-SPEC.md` v1.0 (PR #65) | Specified — neither Record Layer nor Detect Layer built | Design-stage; downstream consumers may build against stable contract |
| 6 | **DPG** (Deterministic Proving Ground) | `DPG-SPEC.md` v1.0 (PR #67) | Specified — CUDA pre-flight + worktree-isolation as v1.0 reference substrate | Reference substrates operational; runner daemon build target |
| 7 | **CRB** (Compute Resource Broker) | `CRB-SPEC.md` v1.0 (PR #68) | Specified — codified-by-convention today, broker daemon build target | Convention live (CLAUDE.md § Infrastructure + § AI Agents); daemon build target |
| 8 | **PGE** (Policy Guardrail Engine) | `PGE-SPEC.md` v1.0 (PR #69) | Specified — pure capstone of de facto enforcement surface | Operational: `MCP-SECURITY-FRAMEWORK.md` + `subagent-guard.sh` + per-server `test_security.py` + CI release gates |

**Plus the cross-cutting concurrency design** (`SOM-CONCURRENCY-AND-ARCHETYPES.md`, PR #62) — not a pillar, but a load-bearing cross-cutting contract referenced by IBX v1.0 + IAM v1.0 + DPG v1.0 + CRB v1.0.

### Validation status (where each pillar sits on the design-vs-built line)

This is a structural property of the mesh: every pillar's *contract* is now committed at v1.0; every pillar's *implementation* is at a known maturity level. The honest framing per `SOM-PRODUCTION-VALIDATION.md` v1.1:

- **Operational at v1.0 contract** (3 pillars): IBX, PGE (de facto framework + hooks + tests + CI), plus parts of PCS (plugin consumers live)
- **Phase-1 build active** (1 pillar): AKB (substantial code on `main`; live integration verified by PR #4 + PR #5)
- **Codified-by-convention** (1 pillar): CRB (convention is reliable in practice; daemon build target)
- **Specified, build target** (3 pillars): IAM (briefs-only), ACT, DPG runner daemon (substrates operational, daemon build target)

The mesh contract holds across all maturity levels because each pillar's *contract* is what couples to other pillars; the implementation behind the contract is opaque to the mesh.

## Three-Plane Architecture

Per `SOM-PROBLEM-STATEMENT.md` v0.6 §0 + `SOM-TECHNICAL-OVERVIEW.md` v0.2. SOM has three architecturally distinct planes:

### Issuance Plane (Above the Dotted Line)

**Above the dotted line** in IAM v1.0's separation discipline. Contains identity issuance authority (ARCA) and the issuance-time keypair generation + signing infrastructure.

- **Inhabitants**: ARCA (identity issuance authority — design-stage, not built)
- **Property**: never in the action path. ARCA can be kept offline. An offline authority cannot be attacked over the network during operation.
- **Coupling to runtime planes**: signed identity artifacts (keypairs + birth certificates + brief schemas) cross the dotted line at provisioning time. Runtime verification is local (signature + trust chain), never a callback. The air-gap is therefore an **assumption of the design**, not a constraint fighting it.

The Issuance Plane's only consumer is the Control Plane's identity-verification surface (Vault, Roster, runtime IAM).

### Control Plane (Beneath the Dotted Line, Above the Workforce)

Contains the governance, scheduling, message-routing, human-approval-gate, and identity-verification + authorization surfaces.

- **Inhabitants**: IAM runtime services (Vault, Roster, Publish Pipeline) + PCS (Syntax, Registry, Lifecycle, Daemon) + PGE (rule corpus + enforcement surfaces) + CRB (broker daemon when built) + IBX (message routing) + **Judge** (human-in-the-loop element)
- **Property**: consumes already-issued identity from the Issuance Plane; mediates between Workforce work and substrate writes.
- **Coupling to other planes**: receives PCT submissions from Workforce (via IBX); emits authorization decisions, dispatch decisions, plugin promotion decisions; emits ACT events for Judge audit and ITDR consumption.

### Workforce Plane (Beneath the Control Plane)

Contains the active agents that perform work — Reasoners (Watson, Bob, Patton, Einstein, Newton) + Workers (DPG runners, future agent pools) — plus the substrate surfaces work touches (AKB for knowledge retrieval, DPG for ephemeral isolation).

- **Inhabitants**: Workforce agents (Watson, Bob, Patton, Einstein, Newton) + DPG runners + AKB retrieval pipeline + the workloads the agents execute
- **Property**: every action submits through IBX, evaluates through PGE Gate 1, dispatches through CRB, may execute inside DPG with PGE Gate 2 enforcement, emits ACT events at every step.
- **Coupling to Control Plane**: every Workforce action is mediated by a Control Plane chokepoint (IBX for submission, PGE for policy, CRB for dispatch). No Workforce action bypasses the Control Plane.

### The dotted line is load-bearing

Per `SOM-PROBLEM-STATEMENT.md` v0.6 §0: the dotted line between Issuance and Control is **a deliberate security property, not tidiness**. Because ARCA is never in the action path, it can be kept offline; an offline authority cannot be attacked over the network during operation. Runtime verification is local (signature + trust chain), never a callback. The air-gap is the design assumption; every pillar's runtime behavior respects this separation.

## Cross-Pillar Dependency Graph

Per Patton's `f346fdab` forward note. Rendered as ASCII so the seams are inspectable.

```
                            ┌─────────────────────────────────────────────┐
                            │  ISSUANCE PLANE (above the dotted line)     │
                            │                                             │
                            │   ARCA — identity issuance authority        │
                            │   (design-stage, not built; offline)        │
                            └────────────────────┬────────────────────────┘
                                                 │ signed identity artifacts
                                                 │ (keypair + birth cert + brief)
                                                 │ cross at provisioning time
─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ DOTTED LINE
                                                 ▼
                            ┌─────────────────────────────────────────────┐
                            │  CONTROL PLANE                              │
                            │                                             │
                            │   ┌──────┐  consumes identity ┌──────────┐  │
                            │   │ IAM  │◄───────────────────│  PGE     │  │
                            │   │ runtime    (PGE consumes  │  rule    │  │
                            │   │ services)  verified id;   │  corpus  │  │
                            │   │           does NOT mint)  │          │  │
                            │   └──┬───┘                    └────┬─────┘  │
                            │      │                             │        │
                            │      │ principal-id field          │        │
                            │      │ in every PCT                │ rules consumed by:
                            │      ▼                             │ DPG (Gate 2)
                            │   ┌──────┐                         │ PCS-Daemon (promotion gate)
                            │   │ IBX  │◄────────────────────────┘ CRB (dispatch chokepoint)
                            │   │      │  PGE Gate 1 at IBX
                            │   │ PCT  │  submission chokepoint
                            │   │route │
                            │   └──┬───┘
                            │      │                             ┌──────────┐
                            │      │ dispatch PCTs               │   CRB    │
                            │      ├────────────────────────────►│ broker   │
                            │      │                             │ daemon   │
                            │      │                             │ (build target)
                            │      │ plugin lifecycle PCTs       └────┬─────┘
                            │      ▼                                  │
                            │   ┌──────┐                              │ routes to:
                            │   │ PCS  │                              │ workforce hosts
                            │   │ Reg+ │                              │
                            │   │ Daemon                              │
                            │   └──────┘                              │
                            │                                         │
                            │   ┌──────┐                              │
                            │   │Judge │  (human-in-the-loop)         │
                            │   │      │  approval gate for action/   │
                            │   │      │  urgent priority messages    │
                            │   └──────┘                              │
                            └─────────────────────────────────────────┼────┐
                                                                      │    │
─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─┤ Control/Workforce boundary
                                                                      ▼    │
                            ┌─────────────────────────────────────────────┐│
                            │  WORKFORCE PLANE                            ││
                            │                                             ││
                            │   Agents: Watson, Bob, Patton,              ││
                            │           Einstein, Newton                  ││
                            │   Plus: DPG runners, future Worker pools    ││
                            │                                             ││
                            │   ┌──────┐ ephemeral isolation              ││
                            │   │ DPG  │ for sandboxed exec               ││
                            │   │ runner                                  ││
                            │   │ pool │◄────── workloads dispatched here ┘│
                            │   └──┬───┘                                   │
                            │      │ PGE Gate 2 inside DPG boundary        │
                            │      │                                       │
                            │   ┌──────┐                                   │
                            │   │ AKB  │ knowledge retrieval               │
                            │   │ MCP  │ (Tier-1 query flow)               │
                            │   └──────┘                                   │
                            └─────────────────────────────────────────────┘

  ╔══════════════════════════════════════════════════════════════════════╗
  ║  ACT — Audit & Cognitive Telemetry                                   ║
  ║  CROSS-PLANE: receives events from ALL pillars; serves Judge audit   ║
  ║  + ITDR consumers. Record Layer (C#) + Detect Layer (Python).        ║
  ║  Couples to IAM session attribution + IBX action audit + PGE rule    ║
  ║  decisions + PCS lifecycle + DPG execution + CRB dispatch +          ║
  ║  Workforce reasoning telemetry.                                      ║
  ║                                                                      ║
  ║  Event namespaces: iam.* ibx.* pcs.* dpg.* crb.* pge.* workforce.*   ║
  ║                                                                      ║
  ║  Pre-curation-event, cross-pillar specs use act.detection_signal     ║
  ║  with payload-encoded signal_type=<pillar>_* per the bounded         ║
  ║  fallback pattern (PCS/DPG/CRB/PGE specs all reference this).        ║
  ╚══════════════════════════════════════════════════════════════════════╝
```

### Critical seams in the graph

- **IAM → IBX**: principal-id field in every PCT. IBX consumes verified identity; does not mint.
- **IAM → PGE**: PGE consumes verified identity for authorization rules (CD6 in PGE v1.0); does not mint.
- **IBX → PGE Gate 1**: every PCT submission evaluated against agent-action policy at submission chokepoint.
- **DPG → PGE Gate 2**: every sandbox execution evaluated against sandbox-execution policy inside boundary; PGE specifies, DPG enforces.
- **CRB → PGE**: dispatch chokepoint consumes PGE rules; CRB does NOT carry its own policy corpus (CRB v1.0 CD6).
- **PCS-Daemon → PGE**: promotion gate consumes PGE rules; `policy_compliance_pass` required for promotion.
- **Workforce → ACT**: every agent action emits ACT events; subagent-guard hook is the runtime enforcement surface.
- **CRB ⊥ DPG**: explicit orthogonality per Patton ruling `251c9511`. CRB = where to run; DPG = how to isolate. Compose at workload level; do NOT subsume each other.

## Seam Composition Verification

For each cross-pillar coupling, verify:
- **Both sides commit the seam**: the providing pillar declares the surface in its spec; the consuming pillar declares consumption.
- **No gap**: nothing provided is unconsumed; nothing consumed is unprovided.
- **No double-coverage**: no two pillars enforce at the same chokepoint without explicit coordination.

| Seam | Provider commit | Consumer commit | Composition |
|------|-----------------|-----------------|-------------|
| IAM → IBX (principal-id) | IAM v1.0 § Coupling Boundary: IBX ↔ IAM | IBX v1.0 CD on nine-field PCT (field 1 principal-id) | ✓ Composes |
| IAM → ACT (session attribution) | IAM v1.0 § Coupling Boundary: ACT ↔ IAM | ACT v1.0 CD on session-granular attribution | ✓ Composes |
| IAM → PCS-Lifecycle (plugin identity) | IAM v1.0 § Coupling Boundary: PCS-Lifecycle ↔ IAM | PCS-Daemon v1.0 § Daemon's own identity | ✓ Composes |
| IAM → PGE (authorization lookup) | IAM v1.0 § Coupling Boundary: PGE ↔ IAM | PGE v1.0 CD6 (consumes, does not mint) | ✓ Composes |
| IAM → CRB (broker daemon identity) | IAM v1.0 § Coupling Boundary discipline | CRB v1.0 CD5 (own ARCA-issued identity when built) | ✓ Composes |
| IAM → DPG (runner identity) | IAM v1.0 § Coupling Boundary discipline | DPG v1.0 § Runner identity | ✓ Composes |
| IBX → PGE (Gate 1 chokepoint) | IBX v1.0 § Submission chokepoint | PGE v1.0 CD3 + § Coupling Boundary: IBX ↔ PGE | ✓ Composes |
| IBX → CRB (dispatch PCT transport) | IBX v1.0 nine-field PCT contract | CRB v1.0 § Coupling Boundary: IBX ↔ CRB | ✓ Composes |
| IBX → PCS-Daemon (lifecycle PCT transport) | IBX v1.0 nine-field PCT contract | PCS-Daemon v1.0 § IBX consume-side | ✓ Composes |
| IBX → DPG (execution-request PCT transport) | IBX v1.0 nine-field PCT contract | DPG v1.0 § IBX consume-side | ✓ Composes |
| IBX → ACT (action audit emission) | IBX v1.0 § audit emission | ACT v1.0 CD on ibx.* event namespace | ✓ Composes |
| PGE → DPG (Gate 2 specification) | PGE v1.0 CD12 (single source of policy truth) | DPG v1.0 CD8 (consumes from PGE) | ✓ Composes |
| PGE → CRB (dispatch-chokepoint rules) | PGE v1.0 § Coupling Boundary: CRB ↔ PGE | CRB v1.0 CD6 (consumes from PGE; no own corpus) | ✓ Composes |
| PGE → PCS-Daemon (promotion-gate rules) | PGE v1.0 § Coupling Boundary: PCS-Daemon ↔ PGE | PCS-Daemon v1.0 § policy_compliance_pass | ✓ Composes |
| PGE → ACT (rule decision emission) | PGE v1.0 CD9 (pge.* events) | ACT v1.0 CD4 (bounded enum extension via VP) | ⏳ Composes via SOM-VP-1 |
| CRB ⊥ DPG (orthogonality) | CRB v1.0 CD6 + § Coupling Boundary: DPG ↔ CRB | DPG v1.0 explicit non-subsumption | ✓ Composes (orthogonal) |
| ACT cross-plane consumer | ACT v1.0 CD on ingest-from-all-pillars | All pillars emit `<pillar>.*` events | ⏳ Composes via SOM-VP-1 for four pillars |
| Workforce → PGE (subagent-guard hook) | PGE v1.0 § Coupling Boundary: Workforce ↔ PGE | CLAUDE.md § Subagent Policy + `.claude/hooks/subagent-guard.sh` | ✓ Composes |
| AKB → Workforce (Tier-1 retrieval) | AKB three-spec gate (PR #61) | Per-agent MCP config (akb-mcp) | ✓ Composes |

**Result**: 17 of 19 enumerated seams compose cleanly at v1.0. 2 of 19 (PGE→ACT, ACT cross-plane four-pillar) compose via the shared curation event SOM-VP-1. No seam has a gap or double-coverage; orthogonality between CRB and DPG is explicit; no pillar silently front-runs an Increment-2 ruling.

## Seven IAM Increment-2 Rulings (Enumerated in ONE Place)

Per Patton's risk #1 (`f346fdab`). The seven IAM Increment-2 rulings, with the complete cross-pillar coupling matrix. **Single source of truth** for ruling enumeration; every pillar's DR that couples to a ruling must reference this row.

| Ruling | Question | Mechanism committed v1.0 | Cross-pillar couplings |
|--------|----------|--------------------------|------------------------|
| **DR-IAM-1** | Concurrency cap values per tier | Cap enforced at instantiation (IAM CD4); per-identity caps per pool | DR-DPG-4 (Worker-pool cap), DR-CRB-4 (broker cap), DR-ACT-4 (baseline reset cadence with DR-IAM-3) |
| **DR-IAM-2** | Bootstrap credential + JIT-broker scope | Bootstrap requirement named; mechanism per form factor (host token / OAuth / pre-provisioned) | DR-PCS-1 (Daemon startup), DR-DPG-1 (runner startup), DR-CRB-1 (broker startup), ACT ingest trust-by-network-boundary today |
| **DR-IAM-3** | Revocation window + downstream-checking scope | Fail-strict-on-stale-state principle committed; short-lived self-expiring cert direction | DR-ACT-4 (baseline reset cadence with DR-IAM-1) |
| **DR-IAM-4** | Terminator failure-mode (session-level vs identity-level) + total-flood scope | Axis committed (both session-level suspend AND identity-level terminate per IAM CD4); operational mechanics deferred | **Cross-pillar audit-vs-runtime split (load-bearing pattern)**: DR-ACT-3 (audit invariant NOT deferred; runtime delivery deferred), DR-PCS-3 (same shape), DR-DPG-3 (same shape), DR-CRB-3 (same shape), DR-PGE-3 (same shape). **Audit retention is NEVER deferred regardless of how DR-IAM-4 lands.** |
| **DR-IAM-5** | Per-session-credential format and lifetime | Per-session credentials exist (IAM CD4); session-issuance API surface named | DR-ACT-2 (Record Layer ingest authentication strengthening), DR-PCS-2 (Daemon session credentials), DR-DPG-2 (runner session credentials), DR-CRB-2 (broker session credentials) |
| **DR-IAM-6** | Sovereignty-as-claim-vs-mode | Sovereign deployment is v1.0 default | DR-PCS-4 (Daemon deployment substrate flexibility) |
| **DR-IAM-7** | ITDR scope | IAM event-publishing surface suitable for ITDR consumption | DR-ACT-1 (Detect Layer scope; couples with IBX DR1) |

### Verification: no pillar silently front-ran a ruling

Every pillar's DR that defers behavior to one of the seven cites the corresponding `DR-IAM-N` ruling explicitly. The coupling matrix above is reverse-derived from the pillar spec DRs (grep'd at commit time across IBX, IAM, ACT, PCS-Daemon, DPG, CRB, PGE specs). **Pass — no silent front-running detected.**

### The DR-IAM-4 audit-vs-runtime split pattern

This is the most architecturally important pattern that emerged across the campaign. Every pillar with in-flight work that could outlive a session termination — ACT (in-flight events), PCS-Daemon (in-flight promotions), DPG (in-flight executions), CRB (in-flight dispatches), PGE (in-flight rule evaluations) — applies the same split:

- **Audit invariant**: every event emitted up to the termination point is preserved. Append-only is non-negotiable regardless of DR-IAM-4 ruling. This is the **mesh-level commitment** to audit completeness.
- **Runtime continuation**: deferred to DR-IAM-4 ruling. Whether in-flight work continues, aborts, is re-issued, or is signaled-and-retried is the runtime question Judge's ruling reshapes.

This pattern is mesh-level discipline that v1.0 SOM commits. **No pillar's DR-IAM-4 coupling may defer the audit invariant**; only runtime continuation is deferable. This rule applies to any future pillar that gains in-flight work.

## Campaign-Level Open Items (Mesh Tracking)

### SOM-VP-1: Four-pillar shared ACT v1.x curation event

Per Patton's risk #2 (`f346fdab`). Promoted from distributed across VP-PCS-1 + VP-DPG-1 + VP-CRB-1 + VP-PGE-1 to **mesh-level campaign open**.

**The obligation**: a single ACT v1.x curation event extends the bounded event-type enum (per ACT v1.0 CD4) to absorb four new namespaces simultaneously:

- `pcs.*` (PCS-Daemon promotion events) — VP-PCS-1, PR #66
- `dpg.*` (DPG execution events) — VP-DPG-1, PR #67
- `crb.*` (CRB dispatch events) — VP-CRB-1, PR #68
- `pge.*` (PGE rule decision events) — VP-PGE-1, PR #69

**Why mesh-level, not distributed**: if the curation event extends three of four (e.g., `pcs.*`, `dpg.*`, `crb.*` land but `pge.*` is left out), the mesh has a half-extended enum — three pillars emit native events while one is stuck on the bounded-fallback (`act.detection_signal` with payload-encoded `signal_type=`). The mesh-level open item makes the four-pillar atomic motion the campaign-level obligation rather than the per-pillar coincidence.

**Pre-curation-event bounded fallback** (consistent across all four pillars): `act.detection_signal` with payload-encoded `signal_type=<pillar>_<event_name>` (e.g., `pcs_promotion_started`, `dpg_execution_request_rejected`, `crb_dispatch_requested`, `pge_action_policy_rejected`). The fallback is operationally complete — the events are recorded; only the typed-event surface is deferred.

**Resolution trigger**: when Bob's ACT Record Layer build reaches the curation-event-emission milestone, the single shared event closes SOM-VP-1 atomically across all four pillars.

### SOM-OQ-1: Post-merge forward-reference sweep

Per Patton's risk #3 (`f346fdab`). Promoted from per-pillar post-merge flag to **mesh-level cleanup**.

**The cleanup**: after PGE v1.0 capstone (PR #69, commit `8be0f5c`), references to `MCP-SECURITY-FRAMEWORK.md` as de facto PGE source should update to `PGE-SPEC.md` in the following pillar specs:

| Pillar spec | Reference location | Update to |
|-------------|-------------------|-----------|
| `DPG-SPEC.md` v1.0 | CD8 + § Coupling Boundary: DPG ↔ PGE | `PGE-SPEC.md` v1.0 + CD12 single-source-of-policy-truth |
| `PCS-DAEMON-SPEC.md` v1.0 | § promotion-gate references | `PGE-SPEC.md` v1.0 |
| `CRB-SPEC.md` v1.0 | § Coupling Boundary: PGE ↔ CRB | `PGE-SPEC.md` v1.0 + CD12 |
| `IAM-CORE-SPEC.md` v1.0 | § Coupling Boundary: PGE ↔ IAM (if applicable) | `PGE-SPEC.md` v1.0 |

**Why mesh-level**: the sweep is cosmetic at each pillar but campaign-level coherent — until it completes, the mesh has stale references that misdirect readers about where the canonical PGE source lives. Promoting to mesh tracking ensures the sweep doesn't fall between pillar reviews.

**Resolution trigger**: next touch of each pillar spec (no forced revision required; the sweep happens as part of routine next-version commits). The mesh status closes when all four references update.

**Not blocking**: SOM-OQ-1 is **post-merge cosmetic**, not a v1.0 SOM spec blocker. Per Patton's `ea67f2ac` close-out on PR #68 and `f346fdab` close-out on PR #69, this is sweep-on-next-touch discipline.

### SOM-OQ-2: PGE rule-lifecycle reconciliation (per Patton `f346fdab` flag)

Per Patton's `f346fdab` non-blocking flag on PGE: CD10 + § Rule Lifecycle's "no period of two contradictory rules in flight" (global corpus invariant) and OQ-P2's snapshot-at-evaluation-start (per-evaluation isolation) are individually correct but sit in slight tension. Both can be true — global ordering for *new* evaluations, snapshot isolation for *in-flight* ones — but the PGE spec doesn't explicitly reconcile them.

**Mesh-level commitment**: the two are **composable invariants**, not contradictory ones:
- The global ordering invariant (`pge.rule_retired` before `pge.rule_added`) governs what **new evaluations starting after the swap** see.
- The snapshot-isolation invariant (per-evaluation rule-corpus version) governs what **in-flight evaluations crossing the swap** see — they keep their old rule until completion.

**Resolution trigger**: next touch of `PGE-SPEC.md` adds one reconciling sentence (sweep-on-next-touch per the established discipline).

## Mesh-Level Invariants

Beyond the pillar-level CDs, v1.0 SOM commits these **mesh invariants** that hold across all eight pillars:

**SOM-MI-1**: **Audit retention is non-negotiable across all pillars.** Every pillar with in-flight work emits ACT events for that work; the events are preserved regardless of session termination, runtime failure, or policy rejection. Runtime continuation may be deferred to Judge ruling; audit retention may not.

**SOM-MI-2**: **PGE is the single source of policy truth across the mesh.** DPG, PCS-Daemon, CRB, and any future pillar that enforces policy at a chokepoint consume rules from PGE; none embed their own corpus. The mesh's policy surface is uniform; deviation is a mesh-conformance violation.

**SOM-MI-3**: **IAM is the single source of verified identity across the mesh.** PGE, IBX, PCS-Daemon, CRB, DPG, ACT consume verified identity from IAM; none mint or verify identity locally. The mesh's identity surface is uniform; deviation is a mesh-conformance violation.

**SOM-MI-4**: **The dotted line between Issuance and Control planes is observed by every pillar.** No pillar's runtime behavior depends on ARCA's online availability. Runtime identity verification is local (signature + trust chain), never a callback to the Issuance Plane.

**SOM-MI-5**: **The double-guardrail (PGE Gate 1 + Gate 2) is preserved across substrate substitutions.** A future substrate swap that centralizes enforcement at a single service (e.g., OPA cluster) must still apply both gates at distinct chokepoints. CD3 in PGE v1.0 is architectural commitment, not implementation detail.

**SOM-MI-6**: **Bounded event-type enums require explicit curation events for extension.** ACT v1.0 CD4 establishes the discipline; PCS / DPG / CRB / PGE all follow it via SOM-VP-1. Any future pillar that emits ACT events follows the same pattern.

**SOM-MI-7**: **Worker-pool dispatch (SKIP-LOCKED claim + lease/timeout + idempotency + mid-action-safe termination) is the canonical pattern for parallel workloads of a single identity.** DPG v1.0 CD7 commits this; future pillars with parallel-worker concerns follow.

**SOM-MI-8**: **Substrate substitutability per Exit Test holds at every pillar.** A deployment that substitutes any one pillar's substrate (e.g., NATS for ClickHouse at IBX; OPA for per-server tests at PGE; Nomad for DAC at CRB) must not break the mesh contract. The mesh-level Exit Test is the conjunction of pillar-level Exit Tests; substrate choice in one pillar may not create lock-in for another.

**SOM-MI-9**: **The seven IAM Increment-2 rulings are the single deferral surface for Judge.** All ruling-pending behavior across pillars couples to one of the seven (or to IBX DR1 + DR-IAM-7 for ITDR). No pillar introduces an Increment-2 ruling outside the seven without Judge sign-off + SOM-PILLAR-NAMES update.

**SOM-MI-10**: **Mesh conformance is verifiable.** A deployment is conformant if and only if it satisfies all eight pillar contracts + the ten mesh invariants. Conformance is testable; the success criteria below name the tests.

## Closed Decisions (CDs — v1.0 Mesh Commitments)

**SOM-CD1**: **Eight pillars compose into one mesh** per the inventory and dependency graph above. No additional pillars at v1.0; pillar additions follow SOM-PILLAR-NAMES discipline + Judge sign-off.

**SOM-CD2**: **Three-plane architecture is structural** (Issuance + Control + Workforce). The dotted line between Issuance and Control is load-bearing security property.

**SOM-CD3**: **Seam composition is the mesh contract.** All cross-pillar couplings trace to committed surfaces on both sides (§ Seam Composition Verification). No gaps; no double-coverage; orthogonality where ruled (CRB ⊥ DPG per `251c9511`).

**SOM-CD4**: **Seven IAM Increment-2 rulings enumerated in ONE place** (§ Seven IAM Increment-2 Rulings). All pillar DRs that defer to a ruling cite the corresponding DR-IAM-N row. No silent front-running.

**SOM-CD5**: **The DR-IAM-4 audit-vs-runtime split is mesh-level discipline.** Audit invariant is never deferred; only runtime continuation is. Applies to all current and future pillars.

**SOM-CD6**: **Four-pillar shared ACT v1.x curation event tracked at mesh level** (SOM-VP-1). Resolves four pillar VPs atomically; prevents half-extended-enum failure mode.

**SOM-CD7**: **Post-merge forward-reference sweep tracked at mesh level** (SOM-OQ-1). Sweep-on-next-touch discipline; not blocking.

**SOM-CD8**: **Ten mesh-level invariants** (§ Mesh-Level Invariants SOM-MI-1..10) hold across all pillars regardless of pillar version. Deviation is a mesh-conformance violation.

**SOM-CD9**: **Substrate substitutability is mesh-level**, not just pillar-level. SOM-MI-8: no pillar's substrate may create lock-in for another. The mesh-level Exit Test is the conjunction of pillar-level Exit Tests.

**SOM-CD10**: **PGE is single source of policy truth (SOM-MI-2); IAM is single source of verified identity (SOM-MI-3); ACT is single source of cross-pillar audit (SOM-MI-1).** Three uniform-surface commitments that distinguish a mesh from a federation of independent pillars.

**SOM-CD11**: **Audit completeness is testable.** SOM-MI-1 + SOM-MI-6 + ACT v1.0 CD3 (append-only) compose: every action emits events; every event lands; the chain is verifiable.

**SOM-CD12**: **This spec is integrative, not derivative.** It does not re-derive pillar contracts; it asserts mesh-level composition. Each pillar's spec remains authoritative for that pillar; this spec is authoritative for the mesh.

## Deferred-Pending-Increment-2-Rulings (DRs)

**SOM-DR-1**: **Mesh-level deployment topology for non-sovereign modes** (couples to DR-IAM-6). If Judge rules sovereignty-as-one-mode (not the only mode), the mesh's deployment topology extends — e.g., hybrid cloud + sovereign, customer-cloud + sovereign-audit. The mesh contract is substrate-agnostic per SOM-MI-8; topology extensions are spec-level additions when DR-IAM-6 resolves.

**SOM-DR-2**: **Mesh-level ITDR consumption pattern** (couples to DR-IAM-7 + DR-ACT-1 + IBX DR1). When the Detect Layer's ITDR scope is ruled, the mesh's threat-detection pattern (who subscribes, what severity thresholds escalate, what auto-response actions are allowed) closes at the mesh level. v1.0 commits ACT's event-publishing surface is suitable; the consumption pattern resolves with the ITDR ruling.

**SOM-DR-3**: **Mesh-level concurrency-cap policy** (couples to DR-IAM-1 + DR-DPG-4 + DR-CRB-4). When Judge rules cap values per tier, the mesh's concurrent-instance budget closes. v1.0 commits the cap mechanism (per IAM CD4); the budget closes at ruling time.

## Validation-Pending (VP — Campaign-Level)

**SOM-VP-1**: **Four-pillar shared ACT v1.x curation event.** Promoted from VP-PCS-1 + VP-DPG-1 + VP-CRB-1 + VP-PGE-1. See § SOM-VP-1 above.

## Open Questions (genuinely open, v1.0)

**SOM-OQ-1**: **Post-merge forward-reference sweep.** Promoted from per-pillar non-blocking flags. See § SOM-OQ-1 above.

**SOM-OQ-2**: **PGE rule-lifecycle reconciliation.** Per Patton `f346fdab` non-blocking flag. See § SOM-OQ-2 above.

**SOM-OQ-3**: **Future ninth pillar.** `SOM-PROBLEM-STATEMENT.md` v0.6 §6 names credential management as a candidate ninth pillar (the HashiCorp Vault-as-separate-product pattern). v1.0 commits eight pillars; addition pressure resolves when a real credential-rotation workload surfaces that PGE-as-rule-engine cannot cleanly govern. SOM-PILLAR-NAMES + Judge sign-off gate any addition.

**SOM-OQ-4**: **Mesh-level performance contract.** Each pillar's substrate has its own performance properties (IBX = ClickHouse throughput; ACT = append-only event-store latency; DPG = boundary-provision latency; CRB = dispatch decision latency). The mesh-level question is whether these compose to a performance contract end-to-end (e.g., "a PCT submitted to IBX, evaluated by PGE Gate 1, dispatched by CRB, executed in DPG, audited by ACT completes within N seconds"). v1.0 does not commit such an end-to-end contract; resolves when production workloads pressure-test the composition.

**SOM-OQ-5**: **Mesh-level versioning policy.** Each pillar has its own version (IBX v1.0, IAM v1.0, etc.). The mesh-level question is whether SOM versions independently (SOM v1.0 = today's pillar set; SOM v1.1 = some pillars advance) or in lockstep. v1.0 SOM = today's pillar set; future-versioning policy is post-v1.0.

## Failure Modes To Watch

- **Pillar drift from mesh invariants.** A future pillar version introduces a CD that violates a mesh invariant (e.g., embeds a policy corpus in DPG outside PGE single-source). **Mitigation**: SOM-CD12 commits the mesh-level authority of these invariants; code review on any pillar version checks mesh conformance; conformance test (§ Success Criteria) catches the violation.
- **Half-extended ACT enum.** SOM-VP-1's four-pillar curation event lands for three of four pillars (e.g., `pcs.*` + `dpg.*` + `crb.*` extend but `pge.*` is missed). **Mitigation**: SOM-CD6 makes the four-pillar atomic motion mesh-level commitment; the curation event is reviewed as one motion at promotion time.
- **Forward-reference sweep stalls.** SOM-OQ-1 sits stale because no pillar version touches its PGE reference. **Mitigation**: mesh-level review at next SOM spec touch flags any stale references; the sweep can complete in a single coordinated commit if it doesn't naturally close during routine pillar touches.
- **Silent ruling front-run.** A future pillar version implements behavior that should have waited for one of the seven IAM Increment-2 rulings. **Mitigation**: SOM-CD4 + § Seven IAM Increment-2 Rulings is the single source of truth; pillar review against this section catches violations.
- **Substrate lock-in through pillar coupling.** Pillar A's substrate choice (e.g., a Postgres-specific feature at IBX substrate) creates an implicit obligation that pillar B's substrate cannot satisfy (e.g., CRB substrate that depends on Postgres-specific message routing). **Mitigation**: SOM-MI-8 + mesh-level Exit Test discipline; substrate choices are reviewed for cross-pillar implications.
- **Three-plane drift.** A future pillar introduces a runtime callback to the Issuance Plane (e.g., online ARCA verification at action time), violating SOM-MI-4. **Mitigation**: SOM-CD2 commits the three-plane structure; pillar review checks plane placement and dotted-line preservation.
- **Audit-vs-runtime split misapplied.** A future pillar with in-flight work defers audit retention to ruling rather than only runtime continuation (violating SOM-CD5). **Mitigation**: SOM-MI-1 + the DR-IAM-4 split pattern documented in § Seven IAM Increment-2 Rulings; pillar review checks both invariants.
- **Mesh-level versioning ambiguity.** v1.0 doesn't commit a versioning policy (SOM-OQ-5); a pillar advances to v2.0 without mesh-level reckoning of compatibility. **Mitigation**: pillar version bumps are reviewed for mesh-conformance impact; if a pillar v2.0 breaks a mesh invariant, mesh-level review is required.
- **CRB-DPG boundary drift.** Future CRB or DPG version adds surface that subsumes the other's concern (CRB adds isolation; DPG adds hardware routing). **Mitigation**: Patton ruling `251c9511` orthogonality preserved at mesh level via SOM-CD3 seam composition; code review on either pillar's next version rejects the change.
- **Mesh inventory drift from SOM-PILLAR-NAMES.** A pillar's status changes in `SOM-PRODUCTION-VALIDATION.md` but the SOM inventory section doesn't update. **Mitigation**: mesh-level review on every SOM-PILLAR-NAMES or SOM-PRODUCTION-VALIDATION change checks consistency with this spec's pillar inventory.

## Dependencies

- **`SOM-PILLAR-NAMES.md`** v1.1 — canonical pillar codes (IAM, IBX, PCS, AKB, ACT, DPG, CRB, PGE)
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — per-pillar validation status (operational / specification / Phase-1 build active / codified-by-convention)
- **`SOM-PROBLEM-STATEMENT.md`** v0.6 — design drivers (workload classification, double-guardrail, three-plane structure, Exit Test)
- **`SOM-TECHNICAL-OVERVIEW.md`** v0.2 — three-plane framing
- **`SOM-CONCURRENCY-AND-ARCHETYPES.md`** v1.0 — cross-cutting concurrency design (Reasoner + Worker archetypes, label-oracle)
- **`IAM-CORE-SPEC.md`** v1.0 — identity contract; the seven Increment-2 rulings live here
- **`IBX-SPEC.md`** v1.0 — message-routing contract; PCT nine-field surface
- **`ACT-SPEC.md`** v1.0 — audit + cognitive telemetry contract; bounded event-type enum
- **`PCS-DAEMON-SPEC.md`** v1.0 — plugin lifecycle daemon contract
- **`DPG-SPEC.md`** v1.0 — ephemeral isolation contract
- **`CRB-SPEC.md`** v1.0 — compute resource broker contract
- **`PGE-SPEC.md`** v1.0 — policy guardrail engine contract; single source of policy truth
- **`MCP-SECURITY-FRAMEWORK.md`** v1.0 — PGE rule corpus reference
- **AKB three-spec gate** (`akb-awareness-layer.md`, `akb-reasoning-independence.md`, `akb-lifecycle.md`) v0.3 — knowledge base contract
- **`CLAUDE.md`** § Security clauses, § Subagent Policy, § Infrastructure, § AI Agents — process-level mesh conventions

## Success Criteria

- **All eight pillar contracts hold.** Per-pillar Success Criteria sections in each pillar spec. **Measure**: each pillar's spec is at validated v1.0 status (verified — IAM #64, IBX #63, ACT #65, PCS-Daemon #66, DPG #67, CRB #68, PGE #69, AKB three-spec gate #61).
- **All ten mesh invariants hold.** SOM-MI-1..10. **Measure**: conformance test suite (post-v1.0 build target) verifies each invariant on a candidate deployment.
- **Seam composition is complete.** § Seam Composition Verification table is full at v1.0; no row says "gap" or "double-coverage." **Measure**: table reviewed at every SOM spec touch; new seams added when new pillar versions introduce couplings.
- **Seven IAM Increment-2 rulings enumerated in ONE place.** § Seven IAM Increment-2 Rulings is the canonical table; every pillar DR that couples to a ruling cites the corresponding row. **Measure**: cross-spec grep for `DR-IAM-N` references; every reference matches a row.
- **No silent front-running of Increment-2 rulings.** **Measure**: § Seven IAM Increment-2 Rulings table is reverse-derived from pillar DRs; reverse-derivation is reproducible (run the grep, compare to table).
- **Four-pillar shared curation event tracked at mesh level.** SOM-VP-1 is the campaign-level open. **Measure**: ACT v1.x release notes reference SOM-VP-1 closure; the curation event covers all four pillars.
- **Forward-reference sweep tracked at mesh level.** SOM-OQ-1. **Measure**: at every next-pillar-spec-version, the reference table updates to PGE-SPEC.md; SOM-OQ-1 closes when all four references update.
- **Three-plane structure preserved.** SOM-MI-4 dotted-line invariant + plane placement per § Three-Plane Architecture. **Measure**: code review on any pillar version checks plane placement.
- **Substrate substitutability holds at mesh level.** SOM-MI-8. **Measure**: substrate-swap exercise at deployment migration verifies mesh contract holds across changes.
- **Patton dialectical sign-off at v1.0.** Single review gate per the simplified workflow; file-based review per the post-PR-#65 discipline. **Measure**: Patton's sign-off inbox message.
- **Spec campaign closes.** Item 7 of the queue (this spec) is the last item. **Measure**: post-merge, the spec campaign queue is empty; Bob's spec-blocker (per Judge directive 2026-06-02) lifts.

## References

- `planning/SOM-PILLAR-NAMES.md` v1.1 — canonical pillar codes
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — per-pillar status
- `planning/SOM-PROBLEM-STATEMENT.md` v0.6 — design drivers + three-plane structure
- `planning/SOM-TECHNICAL-OVERVIEW.md` v0.2 — three-plane framing
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` v1.0 — cross-cutting concurrency
- `planning/IAM-CORE-SPEC.md` v1.0 — IAM contract; seven Increment-2 rulings
- `planning/IBX-SPEC.md` v1.0 — IBX contract; PCT nine-field surface
- `planning/ACT-SPEC.md` v1.0 — ACT contract; bounded event enum
- `planning/PCS-DAEMON-SPEC.md` v1.0 — PCS-Daemon contract
- `planning/DPG-SPEC.md` v1.0 — DPG contract
- `planning/CRB-SPEC.md` v1.0 — CRB contract
- `planning/PGE-SPEC.md` v1.0 — PGE contract; single source of policy truth
- `planning/MCP-SECURITY-FRAMEWORK.md` v1.0 — PGE rule corpus reference
- `planning/akb-awareness-layer.md`, `planning/akb-reasoning-independence.md`, `planning/akb-lifecycle.md` v0.3 — AKB three-spec gate
- `CLAUDE.md` § Security, § Subagent Policy, § Infrastructure, § AI Agents
