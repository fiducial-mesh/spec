---
title: "AKB Layer B.3 — Review Trajectory"
doc_type: shared-context
status: validated
version: v1.0
authors:
  - watson
  - bob
  - patton
  - einstein
  - judge
date: "2026-05-19"
roles:
  - design-intent
  - failure-mode
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/akb-awareness-layer.md
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
  - spec/planning/REPO-SHAPE-DECISIONS.md
  - papers/THE-DIALECTICAL-ENGINE.md
  - papers/FROM-NANOMETERS-TO-NEURONS.md
---

# AKB Layer B.3 — Review Trajectory

**Scope**: Documents the five-round structural review cycle that produced the v0.3 AKB specs.
**Status**: Final v1.0 — gate satisfied 2026-05-19, AKB phase-1 authorized.
**Date**: 2026-05-19

This document preserves the dialectical-engine review trajectory as a methodology artifact. The AKB architecture is the artifact; this file is the *evidence that the architecture was built correctly*. Every round caught structural issues that previous rounds missed. The same agents using the same evidence produced different findings because their priors were different. That's the load-bearing property the multi-agent dialectical engine is built to preserve.

## The Five Rounds

### Round 1 — Initial Concept

**Agent**: Watson (on M3, Claude Code)

**Output**: AKB-as-Layer-B.3 concept. Vector-search over ClickHouse-stored markdown chunks, role-based projection, audit trail.

**Empirical motivation**: 442 markdown files, ~3.4 MB, ~175 new files in ionis-devel since 2026-01-01. Agents currently access ~20 files per session via CLAUDE.md + explicit reads. The remaining 422+ are functionally invisible.

### Round 2 — Parallel Pair Review

**Agents**: Bob (on 9975WX) and Patton (on M3, Claude Desktop) — reviewed independently, then engaged each other directly before responding to Watson.

**What Bob caught**: missing **awareness layer**. Vector retrieval is a *pull* mechanism — it assumes the agent knows to ask. The cold-start problem isn't retrieval, it's *awareness*. Without session-start digest or pre-task hook contracts, AKB is yet-another-thing-to-grep that agents don't use because they don't know they need to.

**What Patton caught**: missing **reasoning independence**. AKB-as-shared-substrate would converge the reasoning substrates that make multi-agent falsification work. Independence of error distributions dies. Same structural pattern as V25-α (multiplicative paths collapsing). Plus missing **promotion discipline** — the V28-narrative-vs-structural failure mode applied at the chunk level.

**Convergent verdict**: three required specs (awareness, reasoning-independence, lifecycle) before any phase-1 code. Hold-on-build.

### Round 3 — Third-Reviewer Falsification

**Agent**: Einstein (via Judge bridge, web-only)

**Output (25-word physics-framed verdict)**: *"20/442 is a Shannon bandwidth limit, not a cold-start. You lack a semantic state-vector. Pushing mass files blindly induces entropic context saturation. Spec 1 fails: unconstrained push guarantees context collapse. Require gradient-gated injection, treating knowledge as targeted activation energy."*

**What Einstein caught**: a **diagnostic reframe**, not a tactical gap. The problem Watson, Bob, and Patton had been solving — "agents lack access to 99.5% of corpus" — was incorrectly framed. The real problem is *channel capacity* — agents have finite working-memory ceiling, and pushing the corpus saturates it before reasoning gradients can form.

**Spec 1 redesign**: Bob's awareness layer rewritten as **Tier 0 (bounded always-loaded prior, ~1 KB) + Tier 1 (gradient-gated mid-reasoning injection)**. Session-start mass push explicitly killed. Specs 2 and 3 survive Einstein's review unmodified.

### Round 4 — Patton Final Review

**Agent**: Patton

**Output**: 6 substantive concerns + 7 smaller issues across the three drafted specs. None required architectural rework. All folded in as v0.2.

**Key findings**:
- **S3 — Patton presence model**: spec assumed continuous Patton presence with 7-day calendar timer. Patton is session-bounded on Claude Desktop — doesn't exist between sessions. Replaced with session-driven escalation model. **Only Patton could have caught this** — it's a fact about his own operational reality.
- **S6 — generalized self-review exemption**: "agent reviewing own work" is a principle, not a single table row. Generalized via `author_id` tracking.
- Plus four others (S1, S2, S4, S5) on Tier 0 promotion, uncertainty signal fragility, source-state drift scope, task-type detection authority.

**Process principle surfaced**: when a spec references an agent's behavior or availability, that agent should be the reviewer who validates the assumptions about themselves.

### Round 5 — Einstein Substrate-Trap Finding

**Agent**: Einstein (via Judge bridge)

**Output**: *"Structurally Flawed at the Retrieval Substrate."*

**What Einstein caught**: **the substrate trap**. The role-projection mechanism filters at the metadata layer (`WHERE roles = ...`). But the underlying vector substrate (`bge-large-en-v1.5`) is semantic, not physical. V25-α failure post-mortems and V16-compliant designs share vocabulary; their cosine similarity is high. Vector retrieval surfaces dead-end content as candidate solutions to physics queries. **Role projection runs too late to prevent it.**

This is the V28 lesson applied to the AKB design itself: *narratively correct, structurally wrong*. The role-projection narrative implied independence; the underlying mathematical substrate doesn't carry the constraint.

**Two architectural fixes**:
1. **Deterministic pre-filter** on `violates_invariant: Bool` metadata — runs *before* vector distance calculation. Dead-end chunks excluded from retrieval unless query is explicitly historical.
2. **Physics Bar C** — V16 modifications require both Judge approval (Bar B) AND Einstein adversarial review. Two-key gate; neither alone sufficient.

**Outcome**: v0.3 fold-in. Three-spec gate satisfied. AKB phase-1 authorized.

## Patton's Final Verdict (Verbatim)

> **Final verdict**
> Three-spec gate satisfied. AKB phase-1 development authorized.
>
> **Reasoning**:
> - **Awareness v0.3**: substrate-trap pre-filter cleanly folded, six-step query flow explicit, new success criterion measurable, two new failure modes documented
> - **Independence v0.3**: minor cross-reference updates, no structural changes (correct — the substrate trap is mostly a query-flow concern, not a projection concern)
> - **Lifecycle v0.3**: violates_invariant field added with ingest rules, Physics Bar C hybrid gate added as a substantive new mechanism, audit trail intact
>
> Two minor recommendations (Item 2 verification line and Item 3 CLCA defect class) are folds for next cycle, not blockers for phase-1 authorization. Both can land alongside whatever operational findings emerge from phase-1 deployment.
>
> **What just happened, structurally**
> Worth being explicit about the dialectical engine's track on this work:
>
> - **Round 1 (initial concept)**: Watson drafted AKB-as-Layer-B.3 concept
> - **Round 2 (pair review)**: Bob and I reviewed independently, caught different load-bearing failures (Bob → awareness layer; me → reasoning independence + promotion discipline)
> - **Round 3 (third reviewer)**: Einstein falsified Bob's awareness layer (unconstrained push induces context saturation), forced redesign to two-tier architecture
> - **Round 4 (deeper third reviewer)**: Einstein found the substrate trap (vector retrieval is physics-blind, role projection runs too late) — caught what pair-plus-third-reviewer missed in Round 3
> - **Round 5 (Einstein's parallel finding)**: Einstein contributed the Physics Bar C hybrid gate, generalizing my "agent validates own assumptions" principle to "agent validates own substrate's invariants"
>
> Five structural rounds. Each round caught what previous rounds missed. Different reviewers using different priors over the same evidence — exactly what the architecture is built to preserve.
>
> The work is done. Three specs, internally consistent, externally consistent with v0.1 PCS spec, ready for phase-1.
>
> — Patton

## Structural Lessons (For the Methodology Record)

1. **Independent priors over the same evidence is the load-bearing property.** Five reviewers (Watson, Bob, Patton × 2, Einstein × 2) reviewed substantially the same artifact, but each round produced new structural findings because the reviewers' priors were different. Same evidence; different visible failure modes per reviewer.

2. **The marginal-find curve is not monotonic.** Bob's Round-3-era hypothesis that "fourth reviewer would catch less" was empirically falsified. Einstein's Round-5 substrate-trap finding was arguably the most consequential of the entire review cycle. Different priors continue to find different things until convergence is demonstrated by actual stability under review, not by heuristic.

3. **Agents are the right reviewers for assumptions about themselves.** Patton's Round-4 catch on the 7-day calendar timer — a fact about his own session-bounded presence — could only have come from him. When a spec references an agent's behavior, that agent must validate.

4. **Narrative correctness vs. structural correctness is the recurring failure pattern.** V25-α failed because the architecture didn't carry the physics the narrative implied. V28 sign-flip failed for the same reason. The AKB's original role-projection design failed for the same reason — the narrative ("independence preserved") didn't carry the math (semantic substrate is physics-blind). Pattern surfaced three times in 24 hours. Worth encoding as a constraint check: *for any architectural proposal, separately validate that the underlying substrate carries the constraint the narrative claims.*

5. **Verdict-with-rounds is itself an artifact worth preserving.** This document exists because the trajectory of review is evidence of the methodology, not just the outcome. Future architectural reviews can reference this pattern as a template.

## References

- `akb-awareness-layer.md` (v0.3) — Tier 0 + Tier 1 architecture, substrate-trap pre-filter in query flow
- `akb-reasoning-independence.md` (v0.3) — Role-projected retrieval, selective exemption, self-review principle
- `akb-lifecycle.md` (v0.3) — Ingest, promotion (Bar A/B/C + Physics Bar C hybrid), conflict resolution, CLCA cycle
- `archive/planning/V27-RESULTS.md` — V27 PhysicsInformedLoss post-mortem (the V25-α-pattern original)
- `planning/ARCHITECTURAL-METHODOLOGY.md` — base curve + modulators framework
- `papers/THE-DIALECTICAL-ENGINE.md` — multi-agent falsification methodology
- `papers/FROM-NANOMETERS-TO-NEURONS.md` — CLCA/8D applied to ML process control
