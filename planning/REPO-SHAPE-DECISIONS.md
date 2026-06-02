---
title: "Repo Shape Decisions — Diagnostic for Single-Repo vs. Multi-Repo Choices"
doc_type: shared-context
status: draft
version: v0.2
authors:
  - watson
  - patton
  - bob
date: "2026-06-02"
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

**Status**: Draft v0.2 — adds the **som-core monorepo** as the third anchoring example (per Patton's `94899c4c` adjudication of `SOM-ENGINEERING-STANDARDS.md` v0.1 ES-CD16; surfaced through Bob's wave-2 origin-inversion authorship). Migrated from `ionis-devel/planning/` to `som-spec/planning/` on the same touch — per Patton's migration-completeness requirement: shared-context diagnostics that wave-2 specs cite must live inside the framework source of truth, not back in ionis-devel.

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

### AKB — Correctly Single-Repo

AKB Phase-1 lives as `KI7MT/akb` (rename to `som-akb` pending PR #8 merge — held intentionally not to rename under active review) containing schema, ingest pipeline, MCP server, Tier 0 generator, hooks, and bootstrap tooling. Applied to the diagnostic:

| Question | AKB answer |
|---|---|
| Independent lifecycles? | **NO** — schema changes ripple through ingest, MCP, Tier 0 simultaneously |
| Tight data-structure coupling? | **YES** — `akb.chunks` shape is referenced by every component |
| Different audiences/licenses? | **NO** — all Layer B private; no external distribution in Phase-1 |
| Different deployment surfaces? | **NO** — everything deploys to 9975 with shared auth + backup chain |

All four signals point single-repo. Multi-repo would force atomic-changes-across-N-repos for every schema iteration, the exact pain PCS multi-repo was designed to avoid for *its* problem. Solving the same problem with the same pattern when underlying conditions differ produces the opposite result.

### som-core — Correctly Monorepo (added v0.2, 2026-06-02)

The C# core pillar microservices (IAM/ARCA, PGE, IBX, CRB, PCS-Daemon) live in one `KI7MT/som-core` solution + repo, NOT one repo per pillar. The decision was committed in `SOM-ENGINEERING-STANDARDS.md` v0.1 **ES-CD16** (Bob-authored wave-2; Patton + Watson sign-off `94899c4c`). Applied to the diagnostic:

| Question | som-core answer |
|---|---|
| Independent lifecycles? | **NO** — the pillars share release cadence; the cross-pillar seams co-evolve (a change to the PCT nine-field surface in IBX touches IAM authorization rules + PGE Gate 1 evaluation simultaneously; a change to the bounded ACT event-type enum touches every pillar that emits events); per-pillar PRs routinely touch multiple projects within one solution |
| Tight data-structure coupling? | **YES** — the PCT nine-field surface is shared across IBX↔IAM↔PGE; event types are shared across every pillar emitting to ACT; identity claims flow IAM↔PGE↔CRB↔DPG↔PCS-Daemon; policy rules flow PGE↔DPG↔CRB↔PCS-Daemon. Every mesh-level invariant (SOM-MI-1..10) is a contract that crosses pillar boundaries and demands atomic change |
| Different audiences/licenses? | **NO** — all pillars are uniformly KI7MT-internal under the same license posture; the future `som-ai` public split (when SOM goes public) moves them together, not individually |
| Different deployment surfaces? | **NO** — all pillar services ship as OCI containers on UBI base per `SOM-DELIVERY-PACKAGING.md` DP-CD1, under the same orchestrator surface (Quadlet → Nomad → Helm tier mapping per DP-CD2); the entire mesh is one delivery contract |

Four NOs / one YES (on tight-coupling) = unambiguously single-repo. Same diagnostic outcome as AKB, **different path through the diagnostic**: AKB is "one system, internally coupled" (Q1/Q2 dominant via single-system-cohesion); som-core is "N pillars coupled by co-evolving cross-pillar seams" (Q1/Q2 dominant via mesh-contract-cohesion). Both correctly land single-repo for different reasons. This is what the diagnostic is supposed to do — produce the right answer regardless of which path the system's coupling profile takes through the four questions.

**Distinction from PCS**: PCS chose multi-repo because plugin lifecycles are independent (each plugin is a separate artifact with its own release cadence + external audience). The C# core pillars are the opposite: their release cadence is shared, their seams co-evolve, their audience is uniform. Same mesh, different shape because the coupling profile differs.

**The Layer-2 extension surface stays multi-repo.** Per ES-CD16, the som-core monorepo is the *core services*, NOT the extension surface. Plugin authors (PCS plugins) and connector authors (Layer-2 SDK consumers) use separate repos — each plugin/connector has independent lifecycle, distinct audience (potentially external), and distinct deployment surface (PCS plugins ride MCP; connectors are language-agnostic via the SDK). The diagnostic applies to each level of the architecture independently — `som-core` is monorepo because the *pillars* are coupled, and the plugin/connector ecosystem above it is multi-repo because the *plugins* are independent. Same mesh; two different repo-shape decisions at two different layers.

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

## Where Specs Live — A Separate Decision (v0.2 evolution)

Repo-shape decisions for *implementation code* don't automatically apply to *specs*. Spec location is governed by a separate principle, and v0.2 records the pattern evolution after the 2026-06-02 SOM corpus migration to a dedicated framework SoT repo (`som-spec`).

**Specs are methodology IP, not just contracts.** When a spec documents how the dialectical engine produced the design (review rounds, falsification cycles, structural findings), the spec belongs in the framework source of truth alongside other methodology artifacts — *not* next to the implementation code it describes.

**Three locations for specs**, in increasing externalization:

1. **Project hub (`ionis-devel/planning/`)** — work-in-flight specs where the framework SoT hasn't crystallized yet; methodology artifacts tied to specific lab work (AKB specs at v0.3 originally; IONIS model V-RESULTS post-mortems). The "in-flight or lab-specific" layer.
2. **Framework SoT repo (`som-spec`)** — framework-level specs that bind the mesh contract regardless of any specific deployment (the eight pillar specs IAM/IBX/ACT/PCS-Daemon/DPG/CRB/PGE/SOM-SPEC + the framework-shaping diagnostics like this doc). Migrated 2026-06-02 history-preservingly when the framework crystallized.
3. **Product-spec repos (`som-pcs-spec`)** — externally-consumable, version-locked contracts where third parties consume the spec as the contract. The Layer-2 SDK and PCS plugins read these.

Applied to current systems:

- **PCS spec → `KI7MT/som-pcs-spec`** (renamed from `pcs-spec` 2026-06-02) because PCS is *externally consumable* (plugin authors are the third-party audience) and version-locked.
- **AKB three-spec gate → `ionis-devel/planning/`** (for now) because AKB specs are *Layer B private* and tied to the dialectical-engine methodology trajectory the From-Nanometers-to-Neurons / Dialectical-Engine papers reference; the project hub is the right home until AKB becomes externally consumable.
- **SOM framework corpus → `KI7MT/som-spec`** (migrated 2026-06-02) because the SOM corpus IS the framework SoT — eight pillar specs + the integrative SOM-SPEC + framework-shaping diagnostics (including this doc). Cross-repo references from product specs (`som-pcs-spec`) to framework specs work cleanly with both repos as KI7MT-private siblings.

**Rule (v0.2 refined)**: specs migrate from project hub → framework SoT when the framework crystallizes; they extract from framework SoT to product-spec repo when the product becomes externally consumable. Each migration is a deliberate transition, not implicit. **Shared-context diagnostics that wave-2 specs cite must live in the framework SoT alongside those specs** — that's the migration discipline Patton flagged in `94899c4c`.

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
- `KI7MT/akb` (rename to `som-akb` pending PR #8 merge) — the single-repo precedent
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
- Patton inbox `94899c4c` (2026-06-02) — adjudication of som-spec PR #1; flagged the migration-completeness gap that this v0.2 closes
