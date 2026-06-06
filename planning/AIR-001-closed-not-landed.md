---
title: "AIR-001 — Closed-Not-Landed: nine issues marked complete with no artifact on main"
doc_type: incident-report
status: draft-investigation
air_id: AIR-001
version: v0.1
authors:
  - patton
date: "2026-06-04"
roles:
  - failure-analysis
author_id: patton
severity: high
incident_class: workflow
disposition: open
references:
  - planning/SOM-SPEC.md
  - planning/IBX-SPEC.md
  - CLAUDE.md
---

# AIR-001 — Closed-Not-Landed

**Blameless post-mortem.** This report names mechanisms and missing controls, never
individuals. Its single purpose is to prevent recurrence. Every identified deficiency
terminates in a CLCA action (a specific control change), not in attribution. If any
sentence below reads as assigning fault to a person, it is mis-written and should be
rewritten as a property of the workflow.

---

## 1. Problem Description

Nine GitHub issues in `som-spec` — the pillar-spec template (#6, #24) and the seven
pillar-spec v1.1 refreshes (#10 IBX, #11 IAM-Core, #12 ACT, #13 PCS-Daemon, #14 DPG,
#15 CRB, #16 PGE) — were marked **CLOSED-COMPLETED**, but **none of their deliverables
exist on `main`**:

- The seven pillar specs contain **no "Substrate Matrix" or "Telemetry Contract" section**
  (grep = 0 across all seven). Spot-verified against the file: `IBX-SPEC.md` is still
  `version: v1.0`, dated `2026-06-02` — the #10 "v1.1 refresh" never bumped the version
  or added the sections.
- The pillar-spec **template file does not exist** in `planning/` (find = nothing),
  though #6/#24 that would create it are closed.

The issue tracker asserted "done" nine times. The repository contains none of it. The
gap was discovered only when an agent attempted to **build IBX against the spec** and
found the section it needed was absent — i.e., caught at the most expensive possible
point (build time), by accident, not by any control designed to catch it.

**Why this is high severity despite being "only" spec sections:** the tracker is the
team's shared source of truth for what work remains. A tracker that reports nine false
completions is a corrupted control surface — every downstream decision that trusts
"issue closed = work done" (build sequencing, blocker-clearing, campaign-close
declarations) is now built on false state. The blast radius is not the nine sections;
it is every decision that trusted the tracker.

## 2. Timeline

*(Reconstructed from inbox evidence and repo state, 2026-06-04. Times approximate to
the message record.)*

| Time | Event | Source |
|------|-------|--------|
| (Wave-1, PRs #25/#28) | Mesh-level foundations land correctly: **SOM-MI-11** (telemetry contract) and **SOM-MI-8 / § Tested Substrate Profiles** (substrate matrix at mesh level) are committed to `SOM-SPEC.md` and verified. | `SOM-SPEC.md`, prior Patton close-outs |
| (the "close-all-20" push) | Nine issues (#6, #24, #10–#16) are moved to CLOSED-COMPLETED as part of a bulk close. The per-pillar Substrate-Matrix / Telemetry-Contract sections and the template are **not committed**. | issue tracker vs repo state |
| 2026-06-04 ~21:52 | An agent begins building IBX, hits spec question #10 (v1.1 gap) + a CD4 substrate question — first signal something is missing at the spec layer. | inbox `1eb7222d` |
| 2026-06-04 ~22:09 | Investigation widens: grep confirms **all seven** pillar specs lack the sections and the template file is absent. The scope is recognized as "bigger than #10" — nine closed issues, zero landed artifacts. Build is **blocked**. | inbox `6316686f` |
| 2026-06-04 ~22:15 | Disposition call: the work is **(B) Owed** — the closes outran the commits — not (A) intentionally centralized. Template-first, then the seven instantiations. | inbox `d53993b2` |
| 2026-06-04 (this report) | AIR-001 opened. | this document |

## 3. Events Leading to the Incident

The conditions that made this possible, stated as workflow properties:

1. **A bulk-close operation existed** that could move many issues to COMPLETED in one
   motion, without a per-issue artifact check.
2. **Issue closure and artifact landing were decoupled.** Closing an issue is a tracker
   action; landing an artifact is a commit. Nothing bound the two — an issue could close
   whether or not its PR merged or its file changed.
3. **The mesh-level foundations genuinely landed** (SOM-MI-11, SOM-MI-8). This is the
   trap: because the *centralized* version of the work was real and correct, a plausible
   reading existed ("the per-pillar sections were folded into the mesh invariants, so the
   issues are satisfied") that made the closes look defensible. Partial-truth masked the
   gap. (Whether (A)-centralized was ever the actual intent is immaterial to prevention —
   the point is the workflow could not *tell* (A) from (B), and neither could the team
   until someone grepped.)
4. **The session-start control routine checks the wrong surfaces.** Per CLAUDE.md, agents
   check the inbox, `gh pr list`, and `git pull` at session start. None of these verifies
   *closed-issue ↔ artifact-exists*. A closed issue with no landed artifact is invisible
   to every standing check.
5. **The review chain verifies PR diffs, not issue-completion claims.** Spec review
   (Patton) verifies that what is *in a PR* is correct against the file. It has no step
   that asks "for every issue this PR/sprint claims to close, did the deliverable land?"
   Review trusted the tracker's completion claim — the one summary the file-based
   discipline never thought to distrust.

## 4. Five Whys

**Problem:** Nine issues were CLOSED-COMPLETED with no artifact on `main`.

- **Why 1 — Why were the issues closed with nothing landed?**
  Because issue closure was performed as a bulk administrative action decoupled from any
  check that the corresponding artifact had been committed.

- **Why 2 — Why was closure decoupled from artifact-landing?**
  Because the workflow has no control that binds an issue's CLOSED state to the existence
  of its deliverable. Closing is a tracker gesture; landing is a commit; nothing
  reconciles them.

- **Why 3 — Why did no standing check catch the decoupling afterward?**
  Because the session-start control routine (inbox / `gh pr list` / `git pull`) and the
  review chain (PR-diff verification) both check surfaces that assume the tracker is
  truthful. No control verifies the tracker *against the repo*. The team's entire
  verification energy points at PRs and files; the issue-tracker's claims are an
  unverified input.

- **Why 4 — Why does the verification effort assume the tracker is truthful?**
  Because the file-based discipline was built to distrust *prose summaries of file
  content* ("verify against the file, never the summary") — but it was never extended to
  distrust *tracker summaries of work-completion*. The discipline had a blind spot exactly
  one level up from where it was pointed: it verifies "is this content correct," never
  "does the claimed-complete deliverable exist."

- **Why 5 (root) — Why did the completion-claim escape the distrust discipline?**
  Because **"done" was never defined as a verifiable, mechanical state.** There is no
  definition-of-done that a machine can check. "Closed" is a human/agent assertion, and
  the workflow treats an assertion as equivalent to a fact. The root cause is the absence
  of a mechanical definition-of-done binding issue-closure to artifact-existence —
  everything above is a symptom of that single missing control.

**Root cause:** *"Done" is an unverified assertion, not a mechanically-checked state.*
There is no control that makes an issue's CLOSED status false until its deliverable is
present on `main`.

## 5. Identified Deficiencies + CLCA

Each deficiency below gets its own corrective/preventive action. CLCA = Corrective Loop /
Closed-loop Action: the corrective fixes *this* occurrence; the preventive removes the
*class*. Tracked to resolution in §6.

### D-1 — No mechanical definition-of-done (ROOT)
- **Corrective:** Reconcile the nine issues now — reopen #6/#24/#10–#16 (or supersede with
  fresh issues) so the tracker reflects reality; the work is **(B) Owed** per the
  disposition call.
- **Preventive:** Define "done" mechanically. An issue may not be CLOSED-COMPLETED unless
  a check confirms its deliverable exists — minimally, the issue references the merged PR
  *and* the PR touched the file(s) the issue names. Candidate enforcement: a CI/cron job
  (or `gh`-based check) that flags any CLOSED-COMPLETED issue whose linked PR is unmerged
  or whose named artifact is absent. **Owner: process design (Watson + Bob), Judge ratifies.**

### D-2 — Issue-closure decoupled from artifact-landing
- **Corrective:** For these nine, re-link each to the actual landing PR when the work
  lands.
- **Preventive:** Adopt a closing convention: issues close *via* merge (PR description
  `Closes #N`), never by bulk hand-close. A hand-close requires an explicit
  artifact-reference comment. Removes the bulk-close-without-artifact path (event #1/#2).
  **Owner: process design; encode in CLAUDE.md § Release Workflow.**

### D-3 — Session-start routine doesn't verify tracker against repo
- **Corrective:** Run a one-time reconciliation grep (the one Bob ran) across all
  CLOSED-COMPLETED issues now.
- **Preventive:** Add a standing check to the session-start routine: a
  closed-issue ↔ artifact reconciliation (alongside inbox / `gh pr list` / `git pull`).
  Cheap if scripted. **Owner: process design; encode in CLAUDE.md.**

### D-4 — Review chain trusts completion-claims it never verifies
- **Corrective:** (none needed for past PRs — their *content* was correct; the gap was
  uncovered work, not wrong work.)
- **Preventive:** Extend the review discipline: a sprint/PR that *claims to close issues*
  gets one added reviewer check — "for each issue closed, the deliverable is present in
  this diff or a named merged PR." This is the file-based discipline extended one level up,
  from "verify content" to "verify completion." **Owner: Patton (review discipline);
  self-imposed, no ratification needed — I author the gap, I close it.**

### D-5 — Partial-truth (real mesh-level work) masked the gap
- **Corrective:** Document explicitly in SOM-SPEC that SOM-MI-11 / SOM-MI-8 are
  mesh-level and whether per-pillar sections are (A) satisfied-centrally or (B) still
  owed — so the ambiguity that made the closes look defensible cannot recur. (Disposition:
  (B) owed, per `d53993b2`.)
- **Preventive:** When work is folded/centralized, the superseded issues are closed with
  an explicit "satisfied by <artifact>" reference, never a bare close. Makes (A) vs (B)
  always mechanically distinguishable. **Owner: process design.**

## 6. Resolution Tracking (to conclusion)

AIR-001 is **OPEN** until every deficiency's preventive action is landed and verified.

| Def | Corrective | Preventive | State |
|-----|-----------|-----------|-------|
| D-1 | reopen/supersede 9 issues | mechanical definition-of-done (CI/gh check) | ☐ open |
| D-2 | re-link to landing PRs | close-via-merge convention in CLAUDE.md | ☐ open |
| D-3 | one-time reconciliation grep | session-start reconciliation check | ☐ open |
| D-4 | (none) | review verifies completion-claims (Patton) | ☐ open |
| D-5 | document MI-11/MI-8 (A/B) disposition | "satisfied-by" close convention | ☐ open |

**Closure criterion:** AIR-001 moves to RESOLVED when all five preventive actions are
committed and a verification pass confirms each control is actually in place (not merely
described) — the verification is itself a guard against this incident's own root cause
(a control described but not landed is the exact failure being fixed).

**Disposition owner:** Judge (final close). **Investigation owner:** Patton.

---

## Note on AIR-as-a-pillar

This document is AIR-001, an *incident*. The **AIR pillar** (the standing system: schema,
lifecycle, CLCA-tracking) is a separate proposal that requires Judge sign-off per SOM-CD1
(eight pillars) + SOM-PILLAR-NAMES discipline. AIR-001 does not wait on that ratification —
the incident is live and its deficiencies need CLCA now. The pillar spec is how the *next*
incident is caught; AIR-001 is how *this* one is fixed. They proceed in parallel; neither
blocks the other.
