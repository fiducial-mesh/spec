# HDBK-001 v1.2.1 — Corrective increment (punch-list + resolution)

**Version call:** **v1.2.1 (corrective patch)**, not v1.3. The normative
SPEC is **untouched** (v1.2, tagged). This is **handbook-only accuracy**:
factual errors, an internal invariant-count contradiction, a security-
critical lifecycle-state omission, two stale "will-land-in-the-SPEC"
forward-references that have since landed, and stale cross-references /
counts. Semver says patch.

**Branch:** `v1.2.1` (off `main`).

**Process (publication/documentation track):** Watson (author) → Patton
(adversarial) → Einstein (first-principles) → Judge (merge) → tag v1.2.1.
**Not** the code gate-2 3-panel (Bob, Turing, Hopper are on MCC-frame
code, not the doc iterations).

## Source of the punch-list
A thorough HDBK-vs-v1.2-SPEC review (the SPEC got deep review; the HDBK
got the least). Four parallel read-only reviewers over Parts 1–4, each
grounding findings in quoted text + grep; **every finding then
Watson-verified against the canonical SPEC text** (cite-by-grep /
panel-call-by-test) before fixing. Method killed nothing on faith — the
"8 vs 11 subtypes" count, for instance, was recounted directly off the
`[FM-PGE-0011]` discriminator table (11 backtick rows L2353–2363).

## BLOCK — factual errors / spec contradictions (now fixed)
1. **§1.5.1 — "not yet in the SPEC"** (L472–478). The model-substrate /
   reasoning-runtime seam was described as *queued, not yet in the SPEC* —
   but it **is** `[FM-INV-0006]` (SPEC §4.5), and the same HDBK section
   (L432) already says so. Self-contradiction + the most credibility-
   damaging line for a defensive-publication artifact. **Fix:** rewrote
   the paragraph to point at `[FM-INV-0006]` + the `non-sovereign-reasoning`
   `divergence_type` per `[FM-PGE-0011]` + the `[FM-INV-0006.1]`
   transitional clause; framed the deviation discipline as the
   *operational expression* of the invariant.
2. **§1.7 — "Three invariants"** (L641). Contradicted §1.8 L937 ("The
   seven foundational invariants in §1.7…"). **Fix:** Three → **Seven**.
3. **§1.7.3 + §3.5 — "8 active subtypes"** of `[FM-PGE-0011]` (L887,
   L1883). Actual count is **11** (verified off the discriminator table).
   **Fix:** 8 → **11** (both locations).
4. **§2.6 — lifecycle routes emergency → Withdrawn** and **omits the
   Quarantined state entirely**. SPEC `[FM-PCS-0012]` requires emergency →
   **Quarantined** ("not Withdrawn"; Withdrawn is graceful retirement,
   Quarantined is the compromised, non-resolvable state). The most
   security-load-bearing lifecycle state was missing. **Fix:** redrew the
   diagram (`↓ (emergency)` → `Quarantined → Purged`), added the
   Quarantined resolvability row, and added a paragraph mirroring the
   SPEC's emergency-revocation semantics.

## FIX — coherence / stale (now fixed)
5. **§1.5 — broken cross-ref `§2.13`** → `§2.12` (the Mesh-CLI + MCC
   delivery shape lives in §2.12).
6. **§2.8 — "will land in the Specification… when authored"** (stale).
   The project-signing-root discipline **is** codified: SPEC §7.1
   `[FM-PKG-0002]` (key-purpose-separated artifact-signing authority,
   distinct from ARCA identity root `[FM-IAM-0002]`). **Fix:** rewrote to
   cite the landed requirement.
7. **§2.2 — role brace-set lists 4** {installer, administrator, operator,
   diagnostician}; the table below lists **5**. **Fix:** added
   `configurator` → {installer, configurator, operator, administrator,
   diagnostician} (matches the 5-namespace table + Appendix D).
8. **§3.4 — IAM "Bound SPEC requirements" enum skips `[FM-IAM-0002]`**
   (per-organization ARCA sovereignty — the load-bearing "no vendor root
   above the org's identity root" claim). **Fix:** inserted `[FM-IAM-0002]`
   after `[FM-IAM-0001]`.
9. **Appendix F — mislabels SPEC Appendix D** as *"Normative cross-pillar
   binding matrix (currently Reserved)"*. SPEC L6669 = *"Cross-pillar
   binding matrix (non-normative; forthcoming)"*. **Fix:** corrected the
   label + status to match.

## Frontmatter
- `version: v1.2 → v1.2.1`, `status: released → draft` (review pass);
  closing line → `v1.2.1`. Date + `status: released` land at the
  release-gate after the chain clears.

## Verified-clean (no action)
- All Part-3 per-pillar counts (IBX 12 / IAM 15 / PGE 15 / ACT 12 /
  AKB 14 / DPG 14 / CRB 13 / MCC 14).
- §1.6 pillar/plane map, §1.7.1–1.7.5 tours, §4.2/§4.4.1, §4.8 dogfood
  (disclosure-clean — no raw secrets), Appendix G provenance.

## Deferred (NOT in this increment — scope discipline)
- NITs: §2 failure-mode over-claim list, missing `[FM-AKB-0011]` cite,
  "platform" common-noun sweep, glossary VMA catalogue, §4.7 present-tense
  "ships four docs", external-repo doc refs. Low-severity; batch later.
- `[FM-INV-0008]` Secret Isolation — separate normative increment
  (Einstein non-blocking; `PCS-COHERENCE-V1.1.2.md` Gap 3).
- Validator → §5.3 security-floor wiring — `PCS-COHERENCE-V1.1.2.md` Gap 1.

## After tag
Paper (`ki7mt/research-papers` `drafts/FIDUCIAL-MESH.md`) re-adheres
against the corrected HDBK before its own team review.
