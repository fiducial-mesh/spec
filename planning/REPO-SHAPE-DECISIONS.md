---
title: "Repo Shape Decisions — Diagnostic for Single-Repo vs. Multi-Repo Choices"
doc_type: shared-context
status: draft
version: v0.3
authors:
  - watson
  - patton
  - bob
date: "2026-06-04"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-ENGINEERING-STANDARDS.md
  - planning/SOM-SPEC.md
---

# Repo Shape Decisions — Diagnostic for Single-Repo vs. Multi-Repo Choices

**Scope**: Records the decision rule for "should this system be one repo or multiple repos?" so future architecture decisions can be answered against the diagnostic instead of re-derived each time.

**Status**: Draft v0.3 — extends the som-core monorepo decision to **all SOM implementation pillars**, recognizes the **one-cohesive-Spec** directive (Judge 2026-06-04), and adds the **§ Actual-State Reconciliation** section enumerating existing SOM-prefixed repos and their target destinations under the cohesive-deployment model. AKB-as-cohesive-peer is explicitly named (no satellite carve-out per Judge directive). Builds on v0.2 (the original som-core anchoring example) and v0.1 (the diagnostic itself).

**v0.3 changes** (from v0.2, 2026-06-02):
- § The Two Anchoring Examples → § The Three Anchoring Examples — AKB anchoring example updated to reflect its **fold-in to som-core** as a cohesive peer (the original AKB-as-standalone single-repo decision was correct for Phase-1; the v0.3 update recognizes that Judge's "one cohesive Spec / Solution / Deployment" directive folds Phase-N AKB implementation into som-core history-preserving)
- som-core anchoring example expanded — was "C# core pillar microservices (IAM/ARCA, PGE, IBX, CRB, PCS-Daemon)"; now **all eight pillars** (IAM, IBX, PCS, ACT, AKB, CRB, PGE, DPG) per Judge's no-core/satellite directive (2026-06-04)
- § Where Specs Live — simplified per Judge's "one Spec → som-spec" directive: som-spec is THE Spec; sections within it (filenames stay as artifacts of how sections were drafted; the cohesion is what matters). The product-spec extraction path (som-pcs-spec as separate repo) is reframed as "in flight" — the v0.3 cohesion directive folds it into som-spec on next touch
- New § Actual-State Reconciliation — enumerates existing SOM-prefixed repos (som-core, som-akb, som-pcs-spec, som-pcs-registry, som-pcs-registry-demo, som-pcs-control-plane, som-devel) with target destinations under the cohesive-deployment model
- References updated for Judge 2026-06-04 directives (no-core/satellite, one-Spec)

**v0.2 changes** (from v0.1, 2026-05-19):
- Third worked example added (som-core monorepo) alongside PCS multi-repo + AKB single-repo
- Repo references updated for the 2026-06-02 `pcs-* → som-pcs-*` rename family
- `§ Where Specs Live` updated to reflect the framework-SoT-repo (som-spec) pattern that emerged from the SOM corpus migration
- Document migrated `ionis-devel/planning/REPO-SHAPE-DECISIONS.md` → `som-spec/planning/REPO-SHAPE-DECISIONS.md` (lives where the wave-2 specs that cite it live)

## Purpose

The "one repo or multiple repos?" question recurs every time a new system is designed for this lab. Two correct answers exist in the project history — PCS chose multi-repo, AKB chose single-repo — and they're correct under different conditions. Without a diagnostic, the next decision risks cargo-culting whichever pattern is most salient at the time. This document captures the diagnostic so future decisions can be made deliberately.

## The Diagnostic

Apply these four questions to the proposed system:

| Question | If YES → | If NO → |
|---|---|---|
| 1. Do components have **independent lifecycles** (release cadences, versioning, deployment timing)? | Multi-repo | Single-repo |
| 2. Is there **tight data-structure coupling** between components (shared schemas, shared protocols requiring atomic change)? | Single-repo | Multi-repo |
| 3. Do components have **different audiences or licenses** (some public, some private; some external-facing, some internal)? | Multi-repo | Single-repo |
| 4. Do components have **different deployment surfaces** (one to PyPI, another to systemd, another to Kubernetes)? | Multi-repo | Single-repo |

**Score the four answers.** If the answers cluster toward multi-repo, split. If they cluster toward single-repo, keep it together. Mixed signals = single-repo until evidence forces a split (the cost of splitting later is lower than the cost of premature splitting).

## The Two Anchoring Examples

### PCS — Correctly Multi-Repo

The PCS family chose `pcs-spec`, `pcs-registry`, `pcs-control-plane`, `pcs-registry-demo`. Applied to the diagnostic:

| Question | PCS answer |
|---|---|
| Independent lifecycles? | **YES** — spec is version-locked; registry iterates; demo is disposable |
| Tight data-structure coupling? | **NO** — spec defines contracts; impls evolve independently within them |
| Different audiences/licenses? | **YES** — spec eventually public; registry private; demo illustrative-public |
| Different deployment surfaces? | **YES** — registry is a service; spec is documentation; demo is example code |

Four YES on multi-repo signals. Correct call.

### AKB — Phase-1 Single-Repo; Phase-N Folds Into som-core (v0.3 update)

**Phase-1 (correct as decided)**: AKB Phase-1 lived as `KI7MT/akb` (renamed to `som-akb` on the v0.2 rename touch). All four diagnostic signals pointed single-repo at decision time:

| Question | AKB Phase-1 answer |
|---|---|
| Independent lifecycles? | **NO** — schema changes ripple through ingest, MCP, Tier 0 simultaneously |
| Tight data-structure coupling? | **YES** — `akb.chunks` shape is referenced by every component |
| Different audiences/licenses? | **NO** — all Layer B private; no external distribution in Phase-1 |
| Different deployment surfaces? | **NO** — everything deploys to 9975 with shared auth + backup chain |

All four signals point single-repo. The Phase-1 decision was correct under those conditions.

**Phase-N (v0.3)**: AKB **folds into som-core as a cohesive peer** alongside the other seven pillars, history-preserving via `git filter-repo --to-subdirectory-filter` (the som-spec-extraction playbook). The fold-in is consistent with the diagnostic — every reason AKB was single-repo at Phase-1 still applies; what changed is that the *same* coupling argument now binds AKB to the *other seven pillars* via mesh-level invariants (SOM-MI-1..13). The natural extension of "AKB schema changes ripple through ingest/MCP/Tier 0 simultaneously" is "the bounded ACT event-type enum extension is a four-pillar shared curation event (SOM-VP-1) ripping through PCS + DPG + CRB + PGE simultaneously — and AKB events join that pattern when AKB emits to ACT." Cohesion grows; the diagnostic outcome doesn't change, only its scope.

**Causality is load-bearing**: the boundary expanded **because AKB's coupling profile changed**, not because Judge's directive changed the answer. At Phase-1, AKB was externally-isolated — different audience from the mesh, different deployment surface, independent lifecycle. At Phase-N, AKB is externally-coupled to the mesh through shared event-types (ACT), shared identity (IAM), shared substrate (SOM-MI-8), and shared release cadence (SOM-MI-10 mesh conformance). That coupling-profile change is what the diagnostic reads to produce the Phase-N answer. **Judge's directive 2026-06-04 *ratified* that change; it did not *cause* it** — the directive recognized the coupling profile had matured to mesh-bound and confirmed the fold-in is the right shape. The diagnostic decided; the directive ratified. If a future reader concludes "directives can override the diagnostic," they will have read this section wrong; the diagnostic's authority is independent of any directive, and the directive's role here is to acknowledge a coupling-profile change the diagnostic was already going to find.

**The Phase-1 vs Phase-N reading**: this is what the diagnostic looks like *correctly evolving with system maturity*. At Phase-1, AKB was internally coupled but externally isolated (different audience from the mesh, different deployment surface — just 9975, different lifecycle from any other system in the lab). At Phase-N, AKB is internally coupled AND externally coupled to the mesh through shared event types + shared identity + shared substrate + shared release cadence. The diagnostic predicted single-repo at Phase-1; the diagnostic predicts the *next-larger* single-repo (som-core, all 8 pillars) at Phase-N. The decision didn't reverse; the boundary of "what is the relevant system" expanded — driven by the coupling-profile change, ratified by Judge's directive.

**This is NOT a satellite carve-out.** Judge's 2026-06-04 directive explicitly rejects any "core vs satellite" pillar tier. AKB is a cohesive peer in som-core, equal to IAM/IBX/PCS/ACT/CRB/PGE/DPG. The previous discussion of AKB-as-satellite (from the operability test framing in Bob's architecture rollup §2, 2026-06-04 evening) is superseded by Judge's same-day directive: there is no satellite tier. Eight pillars, one solution, one deployment.

### som-core — Correctly Monorepo (added v0.2, 2026-06-02; expanded v0.3, 2026-06-04)

**v0.3 update**: Per Judge's 2026-06-04 "no core/satellite distinction; one cohesive Solution" directive, the som-core monorepo scope expands from "C# core pillar microservices" to **all eight SOM pillar implementations**: IAM, IBX, PCS, ACT, AKB, CRB, PGE, DPG. There is no "core / satellite" tier — every pillar is a cohesive peer in the same solution. AKB folds in history-preserving (per Bob's architecture rollup §1, 2026-06-04); previous v0.2 framing of AKB-as-separate-single-repo is superseded by the cohesive-Solution directive while preserving the historical correctness of the AKB Phase-1 single-repo decision (see updated AKB anchoring example above).

Applied to the diagnostic (Watson + Bob design 2026-06-02; Judge directive 2026-06-04 expanded scope):

| Question | som-core answer (v0.3 scope: all 8 pillars) |
|---|---|
| Independent lifecycles? | **NO** — the eight pillars share release cadence; the cross-pillar seams co-evolve (a change to the PCT nine-field surface in IBX touches IAM authorization rules + PGE Gate 1 evaluation simultaneously; a change to the bounded ACT event-type enum touches every pillar that emits events); SOM-MI-10 commits "eight pillar contracts + thirteen mesh invariants" as the conformance unit — they release together |
| Tight data-structure coupling? | **YES** — the PCT nine-field surface is shared across IBX↔IAM↔PGE; event types are shared across every pillar emitting to ACT; identity claims flow IAM↔PGE↔CRB↔DPG↔PCS-Daemon; policy rules flow PGE↔DPG↔CRB↔PCS-Daemon; the AKB chunk schema is shared between AKB ingest + MCP + retrieval surfaces. Every mesh-level invariant (SOM-MI-1..13) is a contract that crosses pillar boundaries and demands atomic change |
| Different audiences/licenses? | **NO** — all eight pillars are uniformly KI7MT-internal under the same license posture; the future `som-ai` public split (when SOM goes public) moves them together, not individually |
| Different deployment surfaces? | **NO** — all pillar services ship as OCI containers on UBI base per `SOM-DELIVERY-PACKAGING.md` DP-CD1, under the same orchestrator surface (Quadlet → Nomad → Helm tier mapping per DP-CD2); the entire mesh is one delivery contract; the Three-Layer Deployment Model (per `SOM-SPEC.md` § Three-Layer Deployment Model) commits this — *Substrate (customer brings) + Mesh (we ship) + MCC (we ship)* is one deployment story |

Four NOs / one YES (on tight-coupling) = unambiguously single-repo across all eight pillars.

**Polyglot inside som-core is fine.** Per `project_som_csharp_target_stack`, the C# pillars use .NET 10 LTS; ACT specifically uses Python (ML/analytics adjacency); the Python ACT lives as `som-core/python/act/`. Shared `/contracts` and `/conventions` directories at the solution root govern cross-language seams. The Python pillar is a *build job* in the same CI workflow, not a repo split. The MCC (`Som.Console` project per SOM-CD14) lives in the same solution.

**Distinction from PCS**: PCS chose multi-repo because *plugin* lifecycles are independent (each plugin is a separate artifact with its own release cadence + external audience). The eight SOM pillars are the opposite: their release cadence is shared, their seams co-evolve, their audience is uniform. Same mesh, different shape because the coupling profile differs.

**The Layer-2 extension surface stays multi-repo.** The som-core monorepo is the *mesh services* (eight pillars + MCC + ACT). It is NOT the extension surface. Plugin authors (PCS plugins) and connector authors (Layer-2 SDK consumers) use separate repos — each plugin/connector has independent lifecycle, distinct audience (potentially external), and distinct deployment surface (PCS plugins ride MCP; connectors are language-agnostic via the SDK). The diagnostic applies to each level of the architecture independently — `som-core` is monorepo because the *pillars* are coupled, and the plugin/connector ecosystem above it is multi-repo because the *plugins* are independent. Same mesh; two different repo-shape decisions at two different layers.

## Actual-State Reconciliation (v0.3)

This section enumerates the SOM-prefixed repos that exist today on `KI7MT` and their **target destinations** under the v0.3 cohesive-Solution directive. The v0.3 changes superseded some v0.2-era decisions (notably AKB-as-separate-repo); this section makes the path forward explicit so future agents and operators don't trip on stale repo state.

### Existing SOM-prefixed repos (audit, 2026-06-04)

| Repo | Current state | Target destination | Migration shape |
|------|---------------|--------------------|-----------------|
| **`som-spec`** | Active. The Spec. 24 issues filed-and-resolved 2026-06-04 spec sprint. | **Stays standalone.** This is THE Spec; one cohesive Spec per Judge 2026-06-04. | No migration. Continues as the framework SoT repo. |
| **`som-core`** | Placeholder. Created 2026-06-02; LICENSE only. | **Target monorepo for all 8 pillar implementations + MCC** (`Som.Console`). | Implementations land here as they're authored. Empty today; populated by future PRs. |
| **`som-akb`** | Phase-1 AKB implementation. Active, schema/ingest/MCP/Tier 0 code live. | **Folds into som-core history-preserving** as `som-core/akb/` (or similar; sub-path TBD by Bob's implementation pass). | `git filter-repo --to-subdirectory-filter` — preserves commit history and IP provenance timestamps. som-akb repo can be archived after the fold-in PR merges in som-core. |
| **`som-pcs-spec`** | Has the 12-file detailed PCS spec under `spec/`: principles, plugin-structure, skill-spec, runbook-spec, execution-profile, lifecycle, gates, failure-modes, audit, compilation, procedures, resumption. | **Folds into som-spec as `som-spec/planning/pcs/`** per Judge 2026-06-04 "one Spec" directive. The detailed PCS spec content is *sections* of THE Spec, not a separate Spec. | History-preserving migration. som-pcs-spec repo can be archived after the fold-in PR merges in som-spec. References to `KI7MT/pcs-spec` in SOM-SPEC.md pillar inventory should be corrected to `som-spec/planning/pcs/` on the same touch. |
| **`som-pcs-registry`** | Implementation code for the PCS Registry service. Has `DESIGN.md` (v0.1 read-only API + v0.2 mutation planning). | **Folds into som-core** as the PCS-Registry service alongside PCS-Daemon. | History-preserving migration as part of the som-core populating PR. `DESIGN.md` is design IP; either folds into som-spec PCS section as design notes OR rides along into som-core as `docs/`. Bob's call on placement. |
| **`som-pcs-control-plane`** | Runtime test harness + gates + evidence + audit. README only at time of audit; implementation may have grown. | **Folds into som-core** as PCS control-plane components. | History-preserving migration on the som-core populating PR. |
| **`som-pcs-registry-demo`** | Demo / illustrative code. README only. | **STAYS SEPARATE.** Different audience (illustrative, potentially public), different deployment surface (sample), independent lifecycle. Diagnostic applies → multi-repo correctly. | No migration. Stays as `KI7MT/som-pcs-registry-demo`. |
| **`som-devel`** | Reframed 2026-06-03 as SOM-apps deployment hub (per som-devel PR #3). Currently contains substrate-Vault POC migration. | **Unclear under v0.3 cohesion directive.** Either (a) folds into fleet-ops/substrate (already partially migrated per som-devel PR #3 → fleet-ops PR #13) and is archived, OR (b) becomes the per-customer deployment hub where the som-core build is composed for a specific customer environment. Bob to make the call on implementation pass; flagged here so future agents don't assume it stays in current form. | Bob's call. |

### Migration sequencing (recommended)

1. **som-core populating PRs** (Bob's lane when implementation begins) — bring AKB, PCS-Registry, PCS-control-plane content in history-preserving via `git filter-repo`
2. **som-spec/planning/pcs/ fold-in** (Watson or Bob) — bring the 12 som-pcs-spec files in as a sub-section of THE Spec; correct SOM-SPEC.md pillar inventory references from `KI7MT/pcs-spec` to the new path
3. **Archive the migrated repos** — som-akb, som-pcs-spec, som-pcs-registry, som-pcs-control-plane get archived after their PR fold-ins merge (GitHub archive feature preserves visibility but prevents new commits)
4. **som-devel decision** — Bob decides between archive-after-fleet-ops-completes vs. evolve-into-customer-deployment-hub
5. **som-pcs-registry-demo stays as-is** — different audience justifies independent repo

### What this section is NOT

This is not a build plan. It's the reconciliation between v0.2's repo-shape decisions (which gave rise to the existing fragmentation) and v0.3's cohesion directive (which collapses most of that fragmentation). The actual implementation work — `git filter-repo` invocations, archival sequencing, broken-reference repair across the SOM corpus — is Bob's lane to execute when he begins populating som-core.

## When to Revisit a Single-Repo Decision

A single-repo decision is not permanent. Re-evaluate when any of these triggers fires:

| # | Trigger | Action |
|---|---|---|
| 1 | A component needs **PyPI distribution** to external consumers | Extract that component to its own repo (e.g., `akb-mcp` would extract to sibling of `qso-graph/*-mcp` if external agents need to install it) |
| 2 | Schema or contract needs **independent versioning** divergent from implementation | Extract `<system>-spec/` (rare; usually stays with platform unless externally consumed) |
| 3 | A UI or sub-system **grows beyond the scope of its container** (e.g., curation UI outgrows inbox-ui) | Extract to its own repo |
| 4 | **External adopters** appear for the system itself, warranting public spec | Mirror PCS pattern: extract spec to public repo |
| 5 | Operational tempo demands **real-time multi-reviewer concurrent gating** or other concurrent multi-actor operations that the queue-and-session model can't handle | Extract the gating infrastructure to its own repo with independent deployment |

If none of the triggers fire, single-repo continues to be the right shape. Premature splitting buys nothing and costs coordination overhead.

## Where Specs Live — One Spec Per Judge Directive (v0.3)

Repo-shape decisions for *implementation code* don't automatically apply to *specs*. Spec location is governed by a separate principle, and v0.3 simplifies it per Judge's 2026-06-04 directive: **one cohesive Spec → som-spec.**

**Specs are methodology IP, not just contracts.** When a spec documents how the dialectical engine produced the design (review rounds, falsification cycles, structural findings), the spec belongs in the framework source of truth alongside other methodology artifacts.

**One location for SOM specs**: `KI7MT/som-spec`. Sections within som-spec where useful (eight pillar sections + integrative SOM-SPEC.md + cross-cutting diagnostics like this one). Filenames are artifacts of how sections were drafted — the cohesion is what matters. New content goes into som-spec as a section by preference; existing filenames (IBX-SPEC.md, ACT-SPEC.md, etc.) are not retroactively renamed (busywork that doesn't help anyone), but the framing is "one cohesive Spec."

**Externally-consumable spec content (Layer-2 SDK, PCS plugin contracts) lives as som-spec sections, not separate repos.** The v0.2 framing of "product-spec repos (som-pcs-spec) as a distinct externalization tier" is superseded by the cohesion directive — see § Actual-State Reconciliation for the som-pcs-spec → som-spec/planning/pcs/ migration plan.

**The AKB three-spec gate**: currently lives at `ionis-devel/planning/` (the project hub) because AKB specs were tied to the dialectical-engine methodology trajectory the From-Nanometers-to-Neurons / Dialectical-Engine papers reference. **Status under v0.3**: as AKB folds into som-core (cohesive peer), the AKB specs follow — migrate `ionis-devel/planning/akb-*.md` → `som-spec/planning/akb/` on the same touch. The methodology IP framing (linking to papers in `KI7MT/research-papers`) survives the move; what changes is that AKB is no longer "Layer B private with no external distribution" — it's a cohesive peer in the public-or-customer-deployable SOM mesh.

**Rule (v0.3)**: specs live in som-spec. Migrations from project hub (`ionis-devel/planning/`) or product-spec extraction tier into som-spec happen on the same touch as the corresponding implementation fold-in (e.g., AKB specs migrate when som-akb folds into som-core; PCS detailed spec migrates when som-pcs-spec folds in). One Spec, one Solution, one Deployment — the spec-location rule mirrors the implementation rule.

## The Inbox-UI Scope-Creep Note

When the AKB curation UI is built, it will extend `inbox-ui` rather than become a new repo. That's the right call by the diagnostic (same backup chain, same access controls, same Wails framework, single-repo for tight coupling between inbox state and curation state).

But this commits `inbox-ui` to becoming a **multi-purpose curator surface**, not just an inbox UI. Two implications worth being explicit about when curation UI work begins:

1. **Name will lag function.** `inbox-ui` will increasingly contain non-inbox features (chunk promotion review, conflict resolution, role override approval, Tier 0 promotion gating). At some point the name becomes a lagging indicator. Future rename candidates: `judge-ui`, `curator-ui`, `control-ui`. Not blocking; flag for the future.

2. **Auth model needs deliberate extension.** Current `inbox-ui` has Judge approve/reject for `action`/`urgent` messages. Curation surface needs similar primitives for different operations (chunk promotion, conflict resolution, role override, Tier 0 promotion). Worth confirming the existing auth model extends cleanly to new operation types or whether new permission categories are needed. Probably the latter — Bar A/B/C have different actors, and the inbox model is single-actor (Judge).

These aren't blockers on the repo decision. Captured here so the implications are visible when curation UI work starts.

## When to Reuse the Diagnostic

Apply this diagnostic any time you're scoping:

- A new system from scratch (greenfield: one repo or several?)
- An extension to an existing system (does it warrant its own repo, or does it fold into the parent's?)
- A refactor of an existing multi-repo system (should it consolidate?)
- A split of an existing single-repo system (does any of the five triggers fire?)

**Diagnostic answers replace gut-check pattern-matching.** Future agents and humans can apply the four questions + five triggers to a candidate system and reach the same answer reliably.

## Open Questions

1. **What about systems where some components fit one answer and others fit the opposite?** AKB's curation UI fits "extend existing system" (inbox-ui), while its platform fits "new single repo." Multiple answers can coexist within a single named system; the diagnostic applies per-component, not per-system.
2. **Should the diagnostic be enforced** via a check (e.g., new-repo creation requires citing this doc), or kept as guidance? Probably guidance for now; revisit if the lab ever onboards engineers who skip the diagnostic.
3. **How often should this doc be updated?** Probably when a new system makes a repo-shape decision that doesn't match the existing examples — add the new case to the anchoring examples to expand the precedent base.

## Failure Modes To Watch

- **Pattern cargo-culting** without applying the diagnostic. Future designer says "let's do it the AKB way" or "let's do it the PCS way" without checking which conditions apply. Mitigation: this doc; ask "did you apply the four-question diagnostic?" in any repo-shape decision review.
- **Diagnostic over-fit to existing examples**. The PCS / AKB anchoring examples reflect specific 2026 architectural needs. Future systems may have properties neither example captures cleanly. Mitigation: when this happens, the doc evolves — add the new example, refine the questions if needed.
- **Premature splitting** because of speculative future need. The five triggers are designed to be observable, not speculative — "we might want PyPI distribution someday" doesn't fire trigger 1; "external consumers are asking" does.
- **Late splitting** because the cost of splitting feels too high once code accumulates. Counter: single-repo → multi-repo splits are routine engineering. The cost is real but bounded; the cost of premature splitting was paid every day for the prior period.

## Dependencies

- `planning/SOM-ENGINEERING-STANDARDS.md` v0.1 ES-CD16 — som-core monorepo decision (Bob, 2026-06-02)
- `planning/SOM-SPEC.md` v1.0 SOM-MI-8 — substrate-substitutability invariant the repo-shape decisions inherit
- PCS family repos (`som-pcs-spec`, `som-pcs-registry`, `som-pcs-control-plane`, `som-pcs-registry-demo`) — the multi-repo precedent (renamed from `pcs-*` 2026-06-02; GitHub redirects live)
- `KI7MT/som-core` — the C# core monorepo per ES-CD16
- `KI7MT/som-akb` (renamed from `KI7MT/akb` on the v0.2 rename touch; folds into som-core at Phase-N per v0.3 § Actual-State Reconciliation) — the single-repo precedent
- `ionis-devel/planning/akb-migration-plan.md` — AKB single-repo decision and rationale (lives in project hub per `§ Where Specs Live` v0.2)
- `ionis-devel/shared-context/architecture-philosophy.md` — CLCA process, design principles

## Success Criteria

- **Future repo-shape decisions cite this doc** rather than re-derive from scratch
- **At least one additional anchoring example** added within 12 months as new systems make their own repo-shape decisions
- **No instances of premature splitting** observed in next 12 months (measured by: no system extracted from a parent repo without one of the five triggers having fired)
- **No instances of overdue splitting** observed in next 12 months (measured by: when a trigger fires, split happens within one workstream cycle)

## References

- `planning/SOM-ENGINEERING-STANDARDS.md` v0.1 ES-CD16 — som-core monorepo decision (third anchor source)
- `planning/SOM-SPEC.md` v1.0 — mesh contract that the C# core pillars satisfy collectively (the source of the co-evolving-seams property)
- `ionis-devel/planning/akb-migration-plan.md` — AKB single-repo decision
- `ionis-devel/planning/akb-review-trajectory.md` — methodology IP framing for AKB specs in project hub
- Patton inbox `2026-05-19` — the structural sharpening that produced the original diagnostic (v0.1)
- Patton inbox `94899c4c` (2026-06-02) — adjudication of som-spec PR #1; flagged the migration-completeness gap that v0.2 closed
- Judge chat directives 2026-06-04 — "no core/satellite distinction; AKB stays as cohesive peer" and "one cohesive Spec → som-spec; sections within where useful" — drove the v0.3 cohesive-Solution + cohesive-Spec consolidation
- Bob inbox `af219768-bece-498e-b9d3-5c1190a0a33a` (2026-06-04 09:09) — architecture rollup §§1 (one .NET solution `som-core`), §2 (deploy-axis-vs-repo-axis distinction), §6 (build standards) — input to the v0.3 som-core scope expansion
