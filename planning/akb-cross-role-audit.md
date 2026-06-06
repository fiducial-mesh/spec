---
title: "AKB Cross-Role Chunk Audit — Pre-Bootstrap Inventory"
doc_type: planning-active
status: validated
version: v0.1
authors:
  - watson
date: "2026-05-19"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/akb-reasoning-independence.md
  - planning/akb-migration-plan.md
  - planning/akb-lifecycle.md
---

# AKB Cross-Role Chunk Audit — Pre-Bootstrap Inventory

**Scope**: Counts cross-role chunk candidates against the hard cap of 50 (per `akb-reasoning-independence.md`). Identifies which canonical docs would be assigned visibility to ALL roles by path-based inference, estimates chunk counts, and recommends action if over cap.

**Status**: Validated v0.1 — current corpus, current Phase A.1 inference rules. Re-run before initial bootstrap if either changes.

## What Counts as Cross-Role

Per `akb-reasoning-independence.md` § Role-Projected Retrieval:

> **Cross-role chunks** (visible to all roles) — small, deliberate, bounded:
> - Tier 0 core content
> - V16 physics laws
> - Security framework
> - Active CLAUDE.md essentials
>
> **Hard cap on cross-role chunks**: N=50 total cross-role chunks.

"Cross-role" specifically means chunks visible to ALL five roles (`design-intent`, `infrastructure`, `failure-mode`, `physics`, `astrophysics`). A chunk visible to 2-3 roles is multi-role but not cross-role; only "all roles" counts against the budget.

## Cross-Role Candidates from Path-Based Inference

Per `akb-migration-plan.md` Phase A.1, these path patterns assign "all roles":

| Pattern | File(s) currently matching | Size (bytes) | Est. chunks |
|---|---|---|---|
| `ionis-devel/CLAUDE.md` | `CLAUDE.md` | 26,378 | ~12 |
| `ionis-devel/planning/MCP-SECURITY-FRAMEWORK.md` | `MCP-SECURITY-FRAMEWORK.md` | 14,706 | ~6 |
| `ionis-devel/shared-context/architecture-philosophy.md` | `architecture-philosophy.md` | 21,443 | ~9 |
| `ionis-devel/.claude/skills/**/SKILL.md` | `akb-doc/SKILL.md` | 6,463 | ~3 |
| Tier 0 source with explicit 5-role frontmatter | `planning/tier0/akb-tier0-content.md` | 5,839 (file) / 740 (extracted Tier 0) | ~3 |
| **Total cross-role chunks (current corpus)** | | | **~33** |

**Status against cap**: 33 / 50 → **66% utilization**. Comfortable headroom. Bootstrap may proceed without demotions.

## Chunk Count Estimation Methodology

Chunks per file estimated as `ceil(byte_count / 2500)`:
- 800-token chunk cap × ~3.5 chars/token = ~2800 chars per chunk before overlap
- 100-token overlap = ~350 char reduction in effective unique content
- Result: ~2500 effective unique bytes per chunk for English markdown

This is approximate. True chunks counted by `ingest/chunker.py` at bootstrap may differ ±20% per file due to:
- Header-based boundary splits (more headers → more chunks)
- Token vs. byte ratio variation (multibyte unicode, code blocks)
- Overlap calculation specifics

If true count differs from estimate by > 15% across the audit total, re-run with actual chunker output and update the bootstrap-validation acceptance criteria.

## Growth Headroom Analysis

Cap utilization currently 66%. Sources of growth that consume the budget:

| Growth source | Estimated rate | Time to fill remaining 17 chunks |
|---|---|---|
| New `.claude/skills/**/SKILL.md` files | Sporadic (driven by skill authoring cadence) | ~5-10 new skills before saturation, assuming ~3 chunks each |
| Changes to existing cross-role files (CLAUDE.md, MCP-SECURITY-FRAMEWORK, architecture-philosophy) | Slow — these are foundational and rarely doubled in size | Low pressure |
| New planning docs assigned cross-role via curation override | Bar B-gated; rare by design | Negligible |

**Implication**: skill proliferation is the most likely budget pressure. Future skills should default to single-role or 2-3 roles, not all-roles. Update Phase A.1 inference rule for `.claude/skills/**/SKILL.md` from "all roles (cross-role)" → role-by-content-type once skills diversify beyond the current `akb-doc` (which is genuinely cross-cutting).

**Recommendation for migration plan revision**: split skills into two classes:
- **Cross-role skills** (visible to all): documentation-creation, security-review, fleet-ops orchestration (rare class)
- **Domain skills** (visible to relevant role only): dx-brief → physics, fleet-test → infrastructure, etc.

Phase A.1 rule should reflect this split rather than blanket "all roles" for the entire `.claude/skills/**/SKILL.md` glob. Surface this as a migration-plan revision for Bob's pre-bootstrap consideration.

## Pre-Bootstrap Action Items

1. **No demotions required** for current corpus — within budget
2. **Update Phase A.1 inference rule for `.claude/skills/`** — recommend split per content type (above). Watson can fold into `akb-migration-plan.md` if you want it landed now; alternatively defer to post-bootstrap curation pass
3. **Add bootstrap-validation gate**: bootstrap fails if cross-role chunk count exceeds 50 at ingest completion. Per `akb-lifecycle.md`, this is a curator-time invariant that the bootstrap process must enforce. Watson recommends adding to `KI7MT/akb/scripts/bootstrap.py` as an explicit check.

## Per-File Chunk Verification at Bootstrap

When `bootstrap.py` runs, capture per-file chunk counts and compare against this audit. Acceptance criteria:

| File | Audit estimate | Acceptance range (±15%) |
|---|---|---|
| `CLAUDE.md` | 12 | 10-14 chunks |
| `MCP-SECURITY-FRAMEWORK.md` | 6 | 5-7 chunks |
| `architecture-philosophy.md` | 9 | 7-11 chunks |
| `akb-tier0-content.md` | 3 | 2-4 chunks |
| `akb-doc/SKILL.md` | 3 | 2-4 chunks |
| **Total cross-role** | **33** | **28-40 chunks** |

If actual total is in 28-40 range, audit confirmed. If outside, investigate which file(s) diverged and either (a) update the chunk-count estimation methodology, (b) update the inference rules, or (c) refactor the file(s) for chunkability.

## Open Questions

1. **Skill proliferation pressure**: as more skills land in `.claude/skills/`, the "all roles" default becomes increasingly wrong. When does the cross-role assignment for skills get split? Recommended: before any second skill ships that doesn't warrant all-role visibility (likely the next skill added; akb-doc was correctly all-roles because it applies to every agent authoring docs).
2. **Multi-role vs cross-role distinction**: docs with 2-3 roles aren't budget-consumers, but they're still common. Total multi-role count isn't capped; only cross-role (all-5) is. Confirm with Patton this distinction is preserved in the spec wording (it is in current spec; flagged here for emphasis).
3. **Cap calibration after operational signals**: 50 may turn out to be too restrictive (real-world content has many docs that legitimately need cross-cutting visibility) or too permissive (cross-role retrieval producing too-noisy results). Plan to re-evaluate at the monthly AKB CLCA cycle after 30 days of operation.

## Failure Modes To Watch

- **Skill proliferation overflowing the cap**: as the skill count grows, default "all roles" inflates the cross-role count. Mitigation: revise Phase A.1 inference for `.claude/skills/**/SKILL.md` to be role-conscious.
- **Estimation methodology drift**: 2500-bytes-per-chunk is approximate. If chunker reality consistently differs, the budget tracking becomes unreliable. Mitigation: switch to actual chunk counts from `bootstrap.py` output once available; treat this audit's estimates as initial guidance only.
- **Cross-role budget gaming**: pressure to mark new content "all roles" to maximize visibility. Mitigation: hard cap enforced at bootstrap + curation; "all roles" requires explicit justification via curation event.

## Dependencies

- `akb-reasoning-independence.md` for the cross-role definition and cap
- `akb-migration-plan.md` Phase A.1 for the inference rules
- `akb-lifecycle.md` for chunking parameters
- `bootstrap.py` (in `KI7MT/akb`, pending) for actual chunk counts at ingest

## Success Criteria

- **Bootstrap completes** without cross-role overflow (total ≤ 50)
- **Per-file actual chunk count within 15% of estimate** for all cross-role candidates
- **Skill inference revisited** before second skill ships
- **Audit re-run** at monthly CLCA cycle for first three months

## References

- `planning/akb-reasoning-independence.md`
- `planning/akb-migration-plan.md`
- `planning/akb-lifecycle.md`
- `planning/tier0/akb-tier0-content.md`
