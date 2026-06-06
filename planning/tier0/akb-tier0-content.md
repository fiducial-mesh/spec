---
title: "AKB Tier 0 Source Content"
doc_type: shared-context
status: validated
version: v0.1
authors:
  - watson
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
  - planning/akb-awareness-layer.md
  - CLAUDE.md
  - planning/MCP-SECURITY-FRAMEWORK.md
---

# AKB Tier 0 Source Content

**Scope**: Canonical source content for the AKB Tier 0 bounded session-start prior.

**Status**: Validated v0.1 — first version of the Tier 0 source. Subject to Judge approval per Bar B promotion gate (see `akb-lifecycle.md`).

## Purpose

This file is the **source of truth** that `tier0/extractor.py` and `tier0/snapshot.py` (in `KI7MT/akb`) read to build the Tier 0 snapshot that gets injected into every agent session at start. The bounded content between the fence markers below is the authoritative Tier 0 content — the generator extracts that block, validates it against the ≤ 1024 byte hard cap, and writes a versioned snapshot artifact.

**Hard cap**: the content between the two HTML-comment fence sentinels below must be ≤ 1024 bytes raw text, ~250 tokens. The generator enforces this with a build-time check; if the cap is exceeded, snapshot build fails and human curator must trim. The fence sentinels are the only place in this file where their literal tokens appear — so simple line-anchored awk/sed extraction can't be tricked by prose references. **Extraction pattern**: match lines beginning with `<!--` and containing the open/close fence tokens; do not pattern-match prose mentions.

## Promotion Gate

This file changes only via **Bar B (Judge approval)** per `akb-lifecycle.md` § V16-Touching Promotion. The content describes load-bearing invariants (V16 physics laws, dead-ends, security non-negotiables) — promotion is gated on explicit human approval, not auto-extraction. Auto-extraction *proposes* candidates from upstream canonical docs (CLAUDE.md, V*-RESULTS files, MCP-SECURITY-FRAMEWORK); Judge confirms before snapshot rebuild.

## Tier 0 Snapshot Source

The content below is what reaches agents at session start. Edit thoughtfully — every byte counts against the cap.

<!-- TIER0_FENCE_OPEN -->
## Dead Ends — DO NOT RETRY
V22 scalar-SFI-clamp; V23 IRI-trunk; V24 remove-sun-sidecar; V25α 2D-SFI; V25β SFI×freq forced; V26 band-heads; AUDIT widen-clamp/Xavier; V27 PIL-loss; V28 sign-flip (mult-axis collapse).

## V16 Laws — LOCKED
IonisGate(256d); HuberLoss(δ=1); gate-variance loss; defibrillator init; weight-clamp[0.5,2.0] post-step; data=WSPR+DXE+Contest.

## Security Non-Negotiables
Creds in keyring only; no subprocess/shell/eval; HTTPS+parameterized SQL only; pre-release audit + Watson sign-off.

## Current Phase
V22-γ production (Pearson +0.492, KI7MT 16/17). Active: Phase 5 Isaac Protocol (synthetic negatives).

## Layers
A=public (IONIS, MCPs, papers, data); B=private (PCS, AKB, control plane, methodology).
<!-- TIER0_FENCE_CLOSE -->

## Generation Notes

When `tier0/snapshot.py` runs, it:

1. **Reads this file** at the canonical path
2. **Extracts the content** between the two fence sentinels (HTML comment containing the open token, then the close token)
3. **Validates byte count** ≤ 1024; build fails if over cap
4. **Computes content hash** for change detection
5. **Writes versioned snapshot** to a known location (e.g., `tier0/snapshots/tier0-{git-commit}-{timestamp}.md`)
6. **Logs curation event** in `akb.curation_events` with `event_type='tier0_snapshot'`, batch_id, source-file git commit hash
7. **Agent runtime** fetches the latest validated snapshot at session start

## Freshness

This file is **manually curated**, not auto-generated. Rebuild Tier 0 snapshot ONLY after:

1. Curator (Watson or equivalent) updates this file with a proposed change
2. Judge approves via Bar B in inbox-ui
3. Curation event written, snapshot built, version-marked

No silent updates. Changes here are load-bearing and visible to every agent every session — discipline is non-negotiable.

## Update Triggers (when to propose changes)

- **New dead-end documented** (e.g., V29 fails) — add to list, increment count if >8
- **V16 law modified** — RARE; requires Physics Bar C two-key gate (Einstein + Judge)
- **Security framework update** — propagate the change here within one curation cycle
- **Phase transition** (e.g., Phase 5 → Phase 6) — update "Current Phase" line
- **Layer A/B boundary change** — update reminder line

## Verification

`scripts/verify-tier0.sh` (in `KI7MT/akb`) will check:

- File parses (YAML frontmatter valid)
- Content fence markers present and well-formed
- Byte count ≤ 1024 between markers
- All referenced V*-RESULTS / V16 / security frameworks exist in their canonical locations

Run before any commit that touches this file.

## Open Questions

1. **Token vs. byte budget**: 1024 bytes raw text is the hard cap; token count varies by tokenizer. Should we also enforce a token cap (e.g., ≤ 256 tokens for Anthropic models)? Recommend: byte cap is the contract; token monitoring is observability. Track but don't gate on it.
2. **Multiple Tier 0 variants per role**: should physics-role agents see a slightly different Tier 0 than infrastructure-role agents? E.g., Newton might benefit from astrophysics-specific priors. Currently no — Tier 0 is cross-role (the bounded essentials that everyone needs). Tier 1 + role projection handles per-role variation. Revisit if operational signals suggest cross-role Tier 0 is causing channel pressure.
3. **Frequency of Bar B approval cycles**: monthly? Per commit-to-canonical? Hybrid event-driven + monthly safety net per `akb-awareness-layer.md` § Open Questions. Default: commit-event triggers proposal, batched weekly for Judge review.
