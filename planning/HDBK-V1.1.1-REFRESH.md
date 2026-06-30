# HDBK-001 v1.1.1 Refresh — Plan + Punch-List

**Version call:** v1.1.1 (corrective patch), **not** v1.2. The normative
Standard gains **no new or changed requirements** — this is handbook accuracy
+ attribution alignment, so semver says patch. (If Judge wants v1.2, trivial
to rebump.)

**Branch:** `v1.1.1` (off `main`, with `watson/cut-spec-free` folded in —
this line supersedes PR #119; the spec-drafts cleanup ships inside v1.1.1).

**Process (publication/documentation track, Judge 2026-06-29):** these docs
review through **Watson (author) → Patton (adversarial) → Einstein
(first-principles) → Judge (merge)** → tag v1.1.1. **Not** the code gate-2
3-panel — Bob, Turing, and Hopper are on the MCC frame code, not the doc
iterations.

## Source of the punch-list
Sync-gap analysis of HDBK-001 against the released v1.1 SPEC-001 (2026-06-29).
Method: grep-grounded term/count/coverage diff, cite-by-grep.

## Clean — verified, no action
- **Versions** — every `v1.0` is historical (revision history, changelog,
  baselines, `v1.0–v1.1` ranges); frontmatter is v1.1.
- **Stale terms** — Samba is correctly an *alternative*; zero "Agentic
  Incident"; the GPL refs are about *software/plugins* (correctly GPLv3,
  not the CC-BY docs).

## Must-fix
1. **Attribution (STD + HDBK)** — `authors: ["Fiducial Mesh Group"]` →
   `"Gregory A. Beam (KI7MT), for the Fiducial Mesh Group"`. Copyright +
   license already correct (Agentics Labs LLC / CC-BY-4.0).
2. **Stale requirement counts (HDBK)** — IAM §5.2 `14 → 15`; PGE §5.3 `14 → 15`
   (STD has `[FM-IAM-0001..0015]`, `[FM-PGE-0001..0015]`).
3. **Uncovered v1.1 requirements (narrative gaps):**
   - `[FM-PGE-0015]` named-quorum-verifier — **0 mentions in HDBK** (STD 9×).
     The `[FM-INV-0004]` quorum mechanism's implementing requirement.
   - `[FM-MCC-0013]` `substrate_unavailable` terminal event — term absent;
     the partial-load/terminal-event work (#116/#117) not reflected in MCC §5.8.
   - `[FM-MCC-0012]` partial-load — under-covered (HDBK 3 vs STD 12).
   - `[FM-IAM-0015]` — the 15th IAM requirement, uncovered.

## Should-fix
- `[FM-INV-0006]` reasoning-runtime seam — concept present (10×) but never
  tied to the invariant ID / included in the invariant enumeration (HDBK
  effectively presents 5 invariants, not 6).
- **AIR** (After-Incident Report) — thin (HDBK 1× vs STD 4×); give it the
  incident → AKB Tier-1 → CLCA treatment the paper now carries.

## Execution order
1. Plan doc (this file) + branch.
2. Frontmatter: version → v1.1.1, status → draft, author alignment (both docs).
3. HDBK count corrections (IAM/PGE → 15).
4. HDBK narrative: PGE-0015, IAM-0015, MCC-0013 + MCC-0012, INV-0006, AIR.
5. Release-gate: status → released, date, revision-history row, PDF.
6. Chain → merge → tag.
