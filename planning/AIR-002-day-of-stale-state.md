---
title: "AIR-002 — Day of Stale State: cascading operating-environment failures"
doc_type: incident-report
status: draft-investigation
air_id: AIR-002
version: v0.1
authors:
  - watson
date: "2026-06-07"
roles:
  - failure-analysis
  - design-intent
author_id: watson
severity: high
incident_class: operating-environment
disposition: open
references:
  - planning/AIR-001-closed-not-landed.md
  - planning/AIR-SPEC-DESIGN-NOTES.md
  - planning/AKB-SPEC.md
  - planning/MESH-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - papers/THE-DIALECTICAL-ENGINE.md
---

# AIR-002 — Day of Stale State

**Blameless post-mortem.** This report names mechanisms and missing controls, never individuals. Its single purpose is to prevent recurrence and to provide structured evidence for the lab's foundational claim — that a multi-agent mesh requires explicit substrate against which "stale state" is the dominant operating-environment failure mode. Every identified deficiency terminates in a CLCA action (a specific control change). If any sentence below reads as assigning fault to a person, it is mis-written and should be rewritten as a property of the workflow.

---

## 1. Problem Description

A single operating day (2026-06-07) produced **ten distinct failures** across the multi-agent fleet. No single failure was catastrophic. In aggregate they consumed substantial human attention, agent token budget, and clock time, and they exposed a coherent class of operating-environment defect:

> **Stale state somewhere in the operating environment — agent memory, brief document, configuration file, repo reference, identifier numbering, name convention, or PAT scope — caused an agent (or the operator) to take an action consistent with the stale state but inconsistent with current reality. The action then required corrective work.**

The failures were not agent reasoning errors. Each agent acted correctly on the information it possessed; the information was stale, fragmented, or partial. The pattern is the evidence — it is exactly the operating-environment failure class the lab's pillar architecture is being built to close, and is the load-bearing claim of the "Operating Across the Gap" paper.

**Why this is high severity despite no single failure being catastrophic**: the failures are *expected* in an environment without the substrate the lab is being built to provide. They demonstrate the *cost of operating in the gap* — the per-day, per-agent, per-decision tax that the pillar architecture is intended to remove. A repeated cascade of this shape signals the operating-environment substrate is not yet adequate to support the dialectical-engine workload — and the workload will only grow.

## 2. Timeline

*(Reconstructed from session conversation, inbox evidence, and commit timestamps. Times approximate. All times UTC unless noted.)*

| Time | Event | Mechanism / source |
|------|-------|--------------------|
| 02:07 | An agent session sends an `action`-priority message addressed to its peer. The session's MCP backend is the deprecated ClickHouse store; the recipient and the operator both read from the post-cutover PostgreSQL store. The message lands invisibly. | Half-flipped inbox cutover; restart did not pick up the new MCP config |
| (session start, M3) | An agent's session brief is read from disk. The brief is dated ~3 weeks stale and references retired technical decisions (C# stack, ClickHouse inbox, pre-rebrand repo names, pre-restructure paths). | Brief documents are not auto-refreshed; no awareness layer surfaces drift |
| (early session) | The M3 agent generates a status synthesis based partly on stale memory entries. The peer agent on the build host corrects the stale C# direction by pointing at the current open-source posture and Python stack. | Agent memory drift; no automatic memory revision on framework reset |
| (mid-session) | A 404 on a known-good repository triggers diagnosis. The PAT in use grants access to repository names that have been transferred under a different org; GitHub returns 301 redirects the MCP server does not follow. A second sibling PAT in the same directory grants access to the post-transfer org names but not to the pre-transfer scopes. | PAT scope drift across org rename; multiple PAT files, no rotation discipline |
| (mid-session) | An operator merges a draft pillar spec PR before peer review can fold in the build-side findings (substrate ruling, telemetry framing, span namespace). | Early merge before review chain completes; no merge-gate on review-chain-still-open |
| (mid-session) | A spec fold-in PR is opened that introduces a Closed Decision number colliding with two unchanged forward-references already in the merged spec. | No CD-number-collision check at commit time; CD list and inline CD references are not link-typed |
| (mid-session) | A subsequent build-side PR is authored from the pre-renumbering draft of the spec; CD-number references in the PR description and DDL comments are off-by-one relative to the merged spec. | Spec ↔ code reference drift; CDs are referenced as opaque strings, not as resolvable IDs |
| (mid-session) | An agent attempts a GitHub PR review with the APPROVE event; the GitHub API rejects the event because the PAT identity is identical to the PR-author identity. | Pre-IAM PAT identity collapse; agents and the operator share a single GitHub identity |
| (mid-session) | An operator-side filter regression in the MCC web pane hides agent-to-peer messages from the operator's view. The operator cannot find a message they expected to see. The agents are sending; the messages land in the store; the aggregator drops them on render. | MCC filter regression; no aggregation-pane conformance gate |
| (mid-session) | An operator sends a test message intended to exercise the inbox cutover. The send leaves no row in either backend. The mechanism the operator used is not a working send-side path. | MCC send-path coverage gap; no clear "operator-as-sender" build standard |
| (continuing) | Memory entries in agent memory directories carry stale identifiers (retired branding tokens, old identifier classes, deprecated substrate names). A bulk-update pass leaves residue. | No memory drift-detection; memory updates rely on agent recall of "everywhere this term appears" |
| (end of day) | An agent CD-numbering oversight (CD15 reused for substrate ruling, colliding with mesh-level CD15 forward references) is caught GH-native by peer review. Renumber lands. | Effective: peer-review catch worked. Underlying: no automated check would have caught this absent peer review. |

## 3. The Ten Failures — root cause, recovery, would-have-been-caught-by

Each failure below is named by *mechanism*, not by agent. Recovery actions taken during the day are recorded; "would have been caught by" names the pillar mechanism that addresses the class structurally.

### F-1. Stale agent brief on session start

**Mechanism**: An agent's session brief was read from disk and treated as authoritative. The brief had not been refreshed against the framework reset, repo restructure, inbox cutover, or stack pivot. The agent's initial synthesis to the operator reflected the brief's stale state.

**Recovery**: Operator (and a peer agent) corrected the synthesis mid-session. Brief was rewritten on the same day.

**Would have been caught by**: **AKB awareness layer** (`akb-awareness-layer.md`). Tier-0 session-start prior would have included current framework state; Tier-1 hooks on session start would have surfaced "current state of <agent role>" before the agent acted on the brief. Per `AKB-SPEC.md` addendum B, agent briefs are first-class AKB corpus content for exactly this reason.

### F-2. Send routed to the deprecated backend during a half-flipped cutover

**Mechanism**: An agent's MCP backend config on disk pointed at the post-cutover backend. The running process had loaded the pre-cutover backend at startup and was not re-reading config. The agent's `inbox_send` operation routed to the deprecated backend, where the message remained invisible to the operator's aggregator (which reads only the post-cutover backend).

**Recovery**: Diagnosis showed the message in the deprecated store. The agent's MCP process required a hard process restart (not a window restart) to pick up the new config. After the second restart, sends routed correctly.

**Would have been caught by**: **`get_version_info` discipline** at every session start (now codified in `PATTON-BRIEFING.md` § Inbox). Identity-attesting the running MCP server before any inbox call distinguishes pre- and post-cutover backends with certainty — the trap that data-shape inspection alone cannot solve, because the two backends were in sync for migrated content.

### F-3. PAT scope drift across org rename

**Mechanism**: A retired GitHub PAT had been issued against the pre-rename repo scopes (`KI7MT/som-*`). The repos transferred to `fiducial-mesh/*` and now return 301 redirects on the old names. The MCP server does not follow redirects. The PAT's actual grants were not updated to the new org scopes. A second sibling PAT existed with the post-rename grants. The wrapper script referenced the old PAT.

**Recovery**: Direct probes against the GitHub API confirmed which PAT had which grants. The wrapper script was swapped to reference the post-rename PAT as a stopgap. The proper consolidation (re-issuing the original PAT with all required scopes via the GitHub UI) is operator-only and pending.

**Would have been caught by**: **IAM + Vault** (`IAM-CORE-SPEC.md` + mesh substrate). Centralized secret store with rotation discipline; agent identities tied to entities not to per-host PAT files; scope changes propagate from a single source. The Vault MCP server (HashiCorp official, beta) is the proximate fit; the IAM seam owns the principle.

### F-4. Early merge before review chain completed

**Mechanism**: A spec PR was merged before the peer reviewer (Patton/Bob equivalent) had folded in build-side findings (substrate ruling, telemetry framing, span namespace). The findings were captured in PR comments + memory + downstream PRs, so no information was lost — but the canonical spec carried known-stale claims for the duration of multiple subsequent fold-in PRs.

**Recovery**: Three follow-up PRs (substrate fold-in, CD-collision fix, HTTP-API addendum) landed the findings post-merge. The merged-but-stale window was hours, not days.

**Would have been caught by**: **PCS deploy concern** (`PCS-DAEMON-SPEC.md` § Pre-merge gates). A spec PR's deploy concern includes "review chain closed" as a prerequisite. The merge gate fires on the review state, not on the operator's discretion.

### F-5. CD-number collision in fold-in PR

**Mechanism**: The fold-in PR introduced `CD15` as a new ID, colliding with two unchanged forward-references already in the merged spec (Substrate Matrix Conformance footer + "How this spec fits the mesh"), both pointing at mesh-level CD15 (conformance-enforced substrate-neutrality). CD numbers were treated as plain text rather than as resolvable IDs.

**Recovery**: Peer review caught the collision GH-native. The fold-in PR was amended to renumber the new ID to CD16 and to add a pillar-level CD15 that resolves the existing forward references at the AKB-pillar layer.

**Would have been caught by**: **PCS Spec-Harness-Registry primitive (MI-12)** applied to spec CD numbering. CDs as link-typed IDs; CI check at commit time for collision. A spec linter for CD-number monotonicity within a pillar spec + cross-spec CD-reference resolution.

### F-6. Spec ↔ code reference drift on CD-number renumber

**Mechanism**: A build-side PR was authored from the pre-renumbering draft of the spec. The PR description, DDL comments in two files, and the implementation rationale all referenced "CD15" — which after the post-renumbering merge denoted a different concept than what the build was implementing. The references were textually correct against an obsolete revision of the spec.

**Recovery**: Watson peer review caught the off-by-one in the review verdict. Bob renumbers on the next pass.

**Would have been caught by**: **Resolvable-IDs discipline at the spec ↔ code seam.** If CDs are referenced via stable resolvers (URLs to a versioned spec snapshot, or content-hashes), a stale reference would either resolve cleanly to the old version (preserving the intended meaning) or fail to resolve (forcing an explicit update). Plain-text CD numbers offer neither guarantee. Same root as F-5; same MI-12 fix.

### F-7. PAT identity collapse blocking `APPROVE`/`REQUEST_CHANGES` on agent PR review

**Mechanism**: Agents and the operator share a single GitHub identity (the PAT carries `KI7MT`). GitHub blocks the `APPROVE` and `REQUEST_CHANGES` events when the reviewer identity matches the PR-author identity. Agents must post review verdicts as `COMMENT` events with the verdict framed in the body — a known but undocumented (for some agents) operating constraint.

**Recovery**: Agent retries the review as a `COMMENT` event with explicit verdict framing in the body. Memory entry codifying the convention written so it sticks across sessions.

**Would have been caught by**: **IAM + GitHub App migration** (per `IAM-CORE-SPEC.md` future migration). Each agent receives a distinct GitHub identity via a per-agent GitHub App installation; review events resolve cleanly. This is acknowledged as a near-future migration in current pillar briefs.

### F-8. Hot reconfiguration without verified reload

**Mechanism**: A configuration change on disk was applied; the consuming process was restarted at the window/UI level (not at the process level). The OS-cached config was reused. The change appeared to be live (config-on-disk inspection passes) but had not actually been loaded by the running process. The mismatch surfaced only when an action that depended on the new config produced a wrong result.

**Recovery**: Identification of the discrepancy required `get_version_info` against the running MCP server. Once identified, a hard process restart (⌘Q + relaunch on macOS) loaded the new config.

**Would have been caught by**: **AIR-001 D-4 generalized** — "done" is a verified state, never a self-claim. Applied to configuration reload: the after-restart state must be probed (via `get_version_info` or equivalent identity-attestation tool) before the operator declares the cutover complete. The discipline is documentary today (in briefs); the structural fix is an automated post-reload smoke check baked into the deploy/restart workflow.

### F-9. MCC filter regression hiding messages from operator view

**Mechanism**: An aggregator pane on the operator's web UI carried a filter regression. Messages addressed to peers (not to the operator directly) were dropped on render. The messages existed in the store; the aggregator did not render them. The operator searched MCC, did not find the messages, and reported absence.

**Recovery**: The build-side agent identified the filter regression and shipped a fix in the same session.

**Would have been caught by**: **MCC conformance gate** under MCC-SPEC. An aggregation pane's contract includes "render every message in the store satisfying the pane's stated filter predicate"; conformance tests verify by inserting a known message and asserting it renders. Today this is doctrine, not automated.

### F-10. Operator send-path coverage gap

**Mechanism**: The operator attempted to send a test message via what they believed was the appropriate send-side path. The send left no row in either backend (PG or CH). The mechanism the operator used was not a working send-side path; the failure was silent.

**Recovery**: Diagnosis via direct queries against both backends confirmed the message never persisted. The operator's send-side tool surface is under-specified relative to the agents'.

**Would have been caught by**: **MCC send-side contract** under MCC-SPEC. The pane must offer a verified "send as operator" path with the same persist-or-fail-loud semantics as agent `inbox_send` calls. Same conformance class as F-9; the send path was simply not yet built or not yet documented.

## 4. Cross-references — historical build failures sharing this class

Today is not the first time the lab has hit operating-environment failures. The "stale state in the gap" class has surfaced repeatedly. Each of the following is a candidate for paper consolidation:

- **AIR-001 (`AIR-001-closed-not-landed.md`)** — nine GitHub issues marked complete with no artifact on `main`. Same class: stale state in the tracker drove downstream decisions built on false state. Resolution path was per-issue corrective fold-in + new template + the AIR-001 D-4 discipline that "done is verified, never claimed."
- **V25-α through V28 architectural dead ends** (per `MODEL-VERSION-HISTORY.md`) — eight successive IONIS model architectures that "looked right narratively" but broke structurally because the underlying substrate did not carry the constraint the narrative implied. Same recurring failure mode: narrative-correct, structurally wrong. The dialectical engine's role in catching these is a load-bearing claim of `THE-DIALECTICAL-ENGINE.md`; the substrate-trap pre-filter in `akb-awareness-layer.md` is the AKB-layer analog of the same correction.
- **MCC filter regression (F-9 above)** — operator-side surface regression that hides peer-to-peer traffic. Same class: aggregator rendering rule drifted from store reality.
- **Workspace flatten/restructure (2026-05-17 / 2026-06-06)** — repo paths moved twice in three weeks. Each move left stale path references in briefs, scripts, MCP configs, and agent memory that surfaced as individual failures in subsequent sessions. Same class: path identifiers in operating-environment-state outliving the path reality.
- **Inbox cutover CH → PG (2026-06-06 / 2026-06-07)** — the cutover itself is well-executed at the substrate layer (event-sourced PG store, migration tool, multi-host flip plan) but the per-agent operational discipline to verify each side flipped cleanly was incomplete on the day it ran. F-2 + F-8 are the visible consequences. Cutovers without verified per-step identity attestation are themselves a failure class.

The paper should treat AIR-001, AIR-002, and the V-version dead ends as a coherent corpus: same class (narrative outpacing the substrate), different surfaces (workflow, model architecture, operating environment).

## 5. Disposition — CLCA actions per failure

Each failure terminates in a specific control change, not in attribution. Some actions are already taken in the same session; others are queued.

| # | CLCA action | Owner / state |
|---|-------------|---------------|
| F-1 | Briefs become first-class AKB corpus content (codified `AKB-SPEC.md` addendum B); Tier-1 hook on session start fires "current state of <agent role>" query | AKB Phase-1 build queue |
| F-1 | Briefs rewritten same-session against current state | **Done** (Patton, Einstein, Newton briefs refreshed 2026-06-07) |
| F-2 | `get_version_info` mandated as the first session-start probe before any inbox call; codified in `PATTON-BRIEFING.md` § Inbox; convention to propagate to all agent briefs | **Done** for Patton; **queued** for fleet briefs |
| F-3 | Stopgap PAT swap in wrapper to `fiducial-mesh.pat`; proper fix is operator-only PAT consolidation via GitHub UI to cover all six target scopes | Operator-only fix pending |
| F-3 | Vault MCP (HashiCorp official, beta) evaluated as the structural replacement for per-host PAT files | Queued — Bob's lane after AKB Phase-C |
| F-4 | PCS deploy concern adds "review chain closed" as a merge prerequisite for spec PRs | Queued to PCS spec |
| F-5 | CD numbering check at commit time — CI linter for collision against existing CD references in the same spec; CD as link-typed ID | Queued to MI-12 / PCS spec |
| F-6 | Same root as F-5; same fix applies. Additionally: build-side PR authoring should resolve CD references at PR-creation time against the latest merged spec, not against a working draft | Queued to MI-12 / PCS spec |
| F-7 | GitHub App migration per IAM future plan; each agent gets a distinct GitHub identity. Until then: `gh pr review --comment` with verdict framing is the only working path; codified in agent memory | **Done** (memory codification); IAM migration is future-pillar work |
| F-8 | AIR-001 D-4 ("done is verified, never claimed") generalized to configuration reload: post-restart identity-attestation is the close-out check | **Done** (`get_version_info` mandate codifies this for the inbox MCP); pattern should propagate fleet-wide |
| F-9 | MCC conformance gate on aggregator filter rules; insertion-test pattern (insert a known message, assert it renders under each pane's stated filter) | Queued to MCC spec |
| F-10 | MCC send-side contract for operator-as-sender; same persist-or-fail-loud semantics as agent `inbox_send` | Queued to MCC spec |

## 6. Synthesis — pillar mapping (why we are building)

The failures above are not random. Each one maps to a load-bearing claim about why a specific pillar exists. The pillar architecture is the structural answer to "stale state in the operating environment causes coherent error cascades."

| Failure pattern | Load-bearing claim | Pillar / mechanism |
|---|---|---|
| Brief drift across multiple axes | Agents need a knowledge substrate with awareness layers | **AKB** (Tier 0 + Tier 1; briefs-as-corpus) |
| Cutover state hidden from data inspection | Hot reconfiguration needs identity-attestable smoke verification | **AKB awareness + AIR-001 D-4** (`get_version_info` as the first session-start probe) |
| PAT scope + name drift | Agent secrets need centralized rotation under a single identity authority | **IAM + Vault** (Vault MCP candidate; future GitHub App migration) |
| Operator aggregator hiding peer traffic | Aggregation panes need conformance gates over rendering rules | **MCC + ACT** (filter-correctness conformance tests; render-vs-store discrepancy alarms) |
| Stale CD references in code | Specs need single-source-of-truth + named, link-typed version progression | **PCS** (deploy concern + Spec-Harness-Registry primitive MI-12) |
| Memory references retired names | Agent memory needs drift detection + scheduled re-verification | **AKB lifecycle + decay signals** (`zero-query chunks` flagged; periodic CLCA cycle) |
| `APPROVE` blocked on own PR | Agent identity must be distinct from operator identity | **IAM + GitHub App migration** |
| Hot reconfig not verified | Configuration changes need post-reload smoke as part of the apply cycle | **AIR-001 D-4 generalized; PCS deploy concern** |
| Path-rules referencing dead `ionis-devel/` | Ingest paths need reconciliation discipline as part of pillar build prerequisites | **AKB migration plan + Bob's OQ1** |
| Spec ↔ code reference numbering drift | Spec ↔ code coupling needs Spec-Harness-Registry primitive | **MI-12 (Spec-Harness-Registry)** |

The lab is being built because operating *without* this substrate produces today's cascade. The substrate is not optional; it is the precondition for the dialectical engine to produce value instead of error.

## 7. Consolidation candidates for "Operating Across the Gap"

The paper's argument is: a sovereign multi-agent mesh has an operating-environment failure class that scales with the number of agents × the number of state-bearing surfaces (memory, brief, config, repo, identifier, name, scope). Today's ten failures are the day-level demonstration of that scaling.

Suggested paper sections that map cleanly from this AIR:

1. **The failure class itself** — § 1 above, lightly reframed to emphasize that today is a *typical* day under-substrate, not an unusual one. The argument is not "we had a bad day"; the argument is "this is what the bill looks like in a day."
2. **The cascade structure** — § 2 timeline + § 3 per-failure detail. Evidence in the paper for "small failures cascade through small recoveries; the cost is real even when each individual failure is recoverable."
3. **Mapping failure → pillar** — § 6 table is paper-ready. Each row is a paragraph the paper can expand.
4. **Cross-history** — § 4 ties today to AIR-001 + V25-α-through-V28 + the workspace restructures + the inbox cutover. The paper's argument lands harder when it can show the *same class* of failure has surfaced in workflow (AIR-001), in ML architecture (V dead ends), in operating environment (today), and in infrastructure migrations (workspace + inbox).
5. **The dialectical engine in the recovery loop** — every failure today was caught by *another agent* (peer review, build-side findings, operator catch, post-restart probe). The engine is functioning correctly; the substrate is what amplifies its catch-rate from "necessary but tiring" to "necessary and bounded."

When the paper consolidates from this AIR, it should preserve the blameless framing and the "claim → evidence" structure. The AIR is the source-of-truth artifact; the paper is the consolidation.

## 8. Dependencies

- `AKB-SPEC.md` (lands the awareness-layer + lifecycle structure that addresses F-1, F-8, brief-drift class)
- `IAM-CORE-SPEC.md` (addresses F-3, F-7 — agent identity, secret-store discipline)
- `MCC-SPEC.md` (addresses F-9, F-10 — aggregation conformance, operator surfaces)
- `PCS-DAEMON-SPEC.md` (addresses F-4, F-5, F-6 — merge gates, CD numbering, spec↔code coupling)
- `AIR-SPEC-DESIGN-NOTES.md` (the cross-cutting AIR class lives here; today's AIR-002 is the second concrete instance)
- `MESH-SPEC.md` MI-12 (Spec-Harness-Registry primitive — the structural fix for F-5/F-6)
- `papers/THE-DIALECTICAL-ENGINE.md` (the methodology paper this AIR's § 7 consolidates into)

## 9. Open Questions

1. **Where does AIR-002 live going forward?** AIR-001 is in `fiducial-mesh/spec/planning/`. AIR-002 follows the same location. If the AIR class grows into an incident management system (per `AIR-SPEC-DESIGN-NOTES.md`), the storage seam may move; the artifact path here is the current canonical until the AIR pillar/spec settles.
2. **Frequency expectation**: how often is a "day of stale state" the actual operating shape? If it is daily, the per-day cost is the load-bearing data the paper needs. If it is exceptional, the framing in § 1 needs softening. Recommend the next 10 operating days be lightly logged (one-line per detected failure) to calibrate, then revisit this AIR.
3. **Should AIR-002 stay a single artifact, or split into per-failure mini-AIRs?** Argument for single: the cascade structure is itself evidence. Argument for split: per-failure CLCA tracking is easier. Recommend **single artifact** with the per-failure CLCA table in § 5 serving the tracking need.
4. **Paper-consolidation cadence**: paper updates should pull from AIR-002 at major drafts, not on every micro-edit. Suggest a marker (e.g., front-matter `paper_consolidated_at: <date>`) so future drafts know what has and hasn't been folded.

## 10. References

- `planning/AIR-001-closed-not-landed.md` — first AIR; same blameless template
- `planning/AIR-SPEC-DESIGN-NOTES.md` — AIR-class design reference (Judge-gated)
- `planning/AKB-SPEC.md` — the AKB pillar addressing F-1, F-8, the brief-drift class, and the awareness-layer mechanism
- `planning/MESH-SPEC.md` — mesh-level invariants (MI-12 Spec-Harness-Registry, the structural fix for F-5/F-6)
- `planning/PILLAR-SPEC-TEMPLATE.md` — the template every pillar spec builds to
- `papers/THE-DIALECTICAL-ENGINE.md` — methodology paper; the consolidation target
- `shared-context/MODEL-VERSION-HISTORY.md` — V25-α through V28 dead ends, cross-class evidence
