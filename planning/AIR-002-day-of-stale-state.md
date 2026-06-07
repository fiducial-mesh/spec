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

> **The operating environment's representation of reality diverged from reality, and decisions trusted the representation.** The agent (or operator) acted correctly with respect to the information surface it had access to, but that surface did not match the world. Each failure required corrective work to reconcile the two.

The failures were not agent reasoning errors. Each agent acted correctly on the information it possessed; the information surface was incomplete in one of several distinct ways. The pattern itself is the evidence — it is exactly the operating-environment failure class the lab's pillar architecture is being built to close, and is the load-bearing claim of the "Operating Across the Gap" paper.

### Sub-types within the operating-environment class

Per Patton's #56 Check 3 (failure-class membership) — five sub-types appear in the day's ten failures. Recognizing the sub-types sharpens the paper argument: the pillar architecture addresses the *meta-class*, not just any one sub-type.

| Sub-type | Definition | Failures (this AIR) |
|---|---|---|
| **stale-state** | The surface was once true; reality moved; the surface didn't | F-1, F-2, F-3, F-6, F-8 |
| **missing-control / gate** | No check existed that would have caught the inconsistency at the right moment | F-4, F-5 |
| **conformance-defect** | The code/UI doesn't honor the contract it claims | F-9 |
| **coverage-gap** | A path that should exist hasn't been built or specified | F-10 |
| **identity-architecture** | A standing structural constraint of the operating environment (no drift; the architecture itself is the constraint) | F-7 |

AIR-001 (`closed-not-landed`) fits the meta-class but as a **false-completion** sub-type (the tracker asserted a state that was never true), not stale-state. The cross-class corpus (§ 4) preserves the meta-class membership while letting each instance carry its precise sub-type label.

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

Each failure below is named by *mechanism*, not by agent, and tagged with its sub-type per § 1. Recovery actions taken during the day are recorded; "would have been caught by" names the pillar mechanism that addresses the sub-type structurally.

**Shared-root note (per Patton #56 Check 3)**: F-2 (send to deprecated backend) and F-8 (hot reconfiguration without verified reload) share one root cause — a process that did not reload its configuration after the on-disk file changed. F-2 is the visible consequence in the inbox-cutover context; F-8 is the generalized mechanism statement. They are listed separately because the consequence and the generalization produce different CLCA actions (F-2 → `get_version_info` discipline at session-start; F-8 → post-reload smoke check in the deploy/restart workflow), but readers should understand they are one root surfacing twice.

### F-1. Stale agent brief on session start *(sub-type: stale-state)*

**Mechanism**: An agent's session brief was read from disk and treated as authoritative. The brief had not been refreshed against the framework reset, repo restructure, inbox cutover, or stack pivot. The agent's initial synthesis to the operator reflected the brief's stale state.

**Recovery**: Operator (and a peer agent) corrected the synthesis mid-session. Brief was rewritten on the same day.

**Would have been caught by**: **AKB awareness layer** (`akb-awareness-layer.md`). Tier-0 session-start prior would have included current framework state; Tier-1 hooks on session start would have surfaced "current state of <agent role>" before the agent acted on the brief. Per `AKB-SPEC.md` addendum B, agent briefs are first-class AKB corpus content for exactly this reason.

### F-2. Send routed to the deprecated backend during a half-flipped cutover *(sub-type: stale-state; shares root with F-8)*

**Mechanism**: An agent's MCP backend config on disk pointed at the post-cutover backend. The running process had loaded the pre-cutover backend at startup and was not re-reading config. The agent's `inbox_send` operation routed to the deprecated backend, where the message remained invisible to the operator's aggregator (which reads only the post-cutover backend).

**Recovery**: Diagnosis showed the message in the deprecated store. The agent's MCP process required a hard process restart (not a window restart) to pick up the new config. After the second restart, sends routed correctly.

**Would have been caught by**: **`get_version_info` discipline** at every session start (now codified in `PATTON-BRIEFING.md` § Inbox). Identity-attesting the running MCP server before any inbox call distinguishes pre- and post-cutover backends with certainty — the trap that data-shape inspection alone cannot solve, because the two backends were in sync for migrated content.

### F-3. PAT scope drift across org rename *(sub-type: stale-state; converges with F-7 on a single fix)*

**Mechanism**: A retired GitHub PAT had been issued against the pre-rename repo scopes (`KI7MT/som-*`). The repos transferred to `fiducial-mesh/*` and now return 301 redirects on the old names. The MCP server does not follow redirects. The PAT's actual grants were not updated to the new org scopes. A second sibling PAT existed with the post-rename grants. The wrapper script referenced the old PAT.

**Recovery**: Direct probes against the GitHub API confirmed which PAT had which grants. The wrapper script was swapped to reference the post-rename PAT as a stopgap. The proper consolidation (re-issuing the original PAT with all required scopes via the GitHub UI) is operator-only and pending.

**Would have been caught by**: **IAM + Vault-stored creds + Vault-Agent file templating + GitHub App identity** (per Bob #56 lane-correction). The lab's existing discipline is **agent-out-of-secret-path**: agents must never read or route secrets directly. The right shape is — Vault *stores* the credentials; the **Vault Agent** templates them into the file the consumer wrapper already reads (the `IBX_DB_FILE` indirection pattern). The service holds the scoped Vault identity; the agent never routes it. A "Vault MCP" where the agent live-reads creds via MCP tools is structurally **wrong** — it puts the agent back in the secret-read path and violates the same rule it tries to fix. Additionally, **GitHub PATs are not Vault-mintable as dynamic secrets**; rotation-native GitHub identity is **GitHub App installation tokens** (1-hour, per-identity), which is **F-7's fix**. F-3 and F-7 converge on **one solution**: per-agent GitHub App identity + Vault stores the App private key + Vault Agent templates the short-lived installation token into the wrapper-read file. This is **fleet-ops / IAM lane**, sequenced behind AKB Phase-1 by priority — not an AKB deliverable.

### F-4. Early merge before review chain completed *(sub-type: missing-control / gate)*

**Mechanism**: A spec PR was merged before the peer reviewer (Patton/Bob equivalent) had folded in build-side findings (substrate ruling, telemetry framing, span namespace). The findings were captured in PR comments + memory + downstream PRs, so no information was lost — but the canonical spec carried known-stale claims for the duration of multiple subsequent fold-in PRs.

**Recovery**: Three follow-up PRs (substrate fold-in, CD-collision fix, HTTP-API addendum) landed the findings post-merge. The merged-but-stale window was hours, not days.

**Would have been caught by**: **PCS deploy concern** (`PCS-DAEMON-SPEC.md` § Pre-merge gates). A spec PR's deploy concern includes "review chain closed" as a prerequisite. The merge gate fires on the review state, not on the operator's discretion.

### F-5. CD-number collision in fold-in PR *(sub-type: missing-control / gate)*

**Mechanism**: The fold-in PR introduced `CD15` as a new ID, colliding with two unchanged forward-references already in the merged spec (Substrate Matrix Conformance footer + "How this spec fits the mesh"), both pointing at mesh-level CD15 (conformance-enforced substrate-neutrality). CD numbers were treated as plain text rather than as resolvable IDs.

**Recovery**: Peer review caught the collision GH-native. The fold-in PR was amended to renumber the new ID to CD16 and to add a pillar-level CD15 that resolves the existing forward references at the AKB-pillar layer.

**Would have been caught by**: **PCS Spec-Harness-Registry primitive (MI-12)** applied to spec CD numbering. CDs as link-typed IDs; CI check at commit time for collision. A spec linter for CD-number monotonicity within a pillar spec + cross-spec CD-reference resolution.

### F-6. Spec ↔ code reference drift on CD-number renumber *(sub-type: stale-state)*

**Mechanism**: A build-side PR was authored from the pre-renumbering draft of the spec. The PR description, DDL comments in two files, and the implementation rationale all referenced "CD15" — which after the post-renumbering merge denoted a different concept than what the build was implementing. The references were textually correct against an obsolete revision of the spec.

**Recovery**: Watson peer review caught the off-by-one in the review verdict. Bob renumbers on the next pass.

**Would have been caught by**: **Resolvable-IDs discipline at the spec ↔ code seam.** If CDs are referenced via stable resolvers (URLs to a versioned spec snapshot, or content-hashes), a stale reference would either resolve cleanly to the old version (preserving the intended meaning) or fail to resolve (forcing an explicit update). Plain-text CD numbers offer neither guarantee. Same root as F-5; same MI-12 fix.

### F-7. PAT identity collapse blocking `APPROVE`/`REQUEST_CHANGES` on agent PR review *(sub-type: identity-architecture; converges with F-3 on a single fix)*

**Mechanism**: Agents and the operator share a single GitHub identity (the PAT carries `KI7MT`). GitHub blocks the `APPROVE` and `REQUEST_CHANGES` events when the reviewer identity matches the PR-author identity. Agents must post review verdicts as `COMMENT` events with the verdict framed in the body — a known but undocumented (for some agents) operating constraint.

**Recovery**: Agent retries the review as a `COMMENT` event with explicit verdict framing in the body. Memory entry codifying the convention written so it sticks across sessions.

**Would have been caught by**: **Per-agent GitHub App identity** (the same fix F-3 converges on). Each agent receives a distinct GitHub identity via a per-agent GitHub App installation; review events resolve cleanly because reviewer-identity ≠ author-identity. Vault stores the App private key; Vault Agent templates short-lived (1-hour) installation tokens into the file each agent's wrapper reads. The IAM seam owns the principle; fleet-ops lane delivers the build. This single fix closes F-3 (PAT scope drift) and F-7 (identity collapse blocking review events) at once.

### F-8. Hot reconfiguration without verified reload *(sub-type: stale-state; generalized mechanism of F-2)*

**Mechanism**: A configuration change on disk was applied; the consuming process was restarted at the window/UI level (not at the process level). The OS-cached config was reused. The change appeared to be live (config-on-disk inspection passes) but had not actually been loaded by the running process. The mismatch surfaced only when an action that depended on the new config produced a wrong result.

**Recovery**: Identification of the discrepancy required `get_version_info` against the running MCP server. Once identified, a hard process restart (⌘Q + relaunch on macOS) loaded the new config.

**Would have been caught by**: **AIR-001 D-4 generalized** — "done" is a verified state, never a self-claim. Applied to configuration reload: the after-restart state must be probed (via `get_version_info` or equivalent identity-attestation tool) before the operator declares the cutover complete. The discipline is documentary today (in briefs); the structural fix is an automated post-reload smoke check baked into the deploy/restart workflow.

### F-9. MCC filter regression hiding messages from operator view *(sub-type: conformance-defect)*

**Mechanism**: An aggregator pane on the operator's web UI carried a filter regression. Messages addressed to peers (not to the operator directly) were dropped on render. The messages existed in the store; the aggregator did not render them. The operator searched MCC, did not find the messages, and reported absence.

**Recovery**: The build-side agent identified the filter regression and shipped a fix in the same session.

**Would have been caught by**: **MCC conformance gate** under MCC-SPEC. An aggregation pane's contract includes "render every message in the store satisfying the pane's stated filter predicate"; conformance tests verify by inserting a known message and asserting it renders. Today this is doctrine, not automated.

### F-10. Operator send-path coverage gap *(sub-type: coverage-gap)*

**Mechanism**: The operator attempted to send a test message via what they believed was the appropriate send-side path. The send left no row in either backend (PG or CH). The mechanism the operator used was not a working send-side path; the failure was silent.

**Recovery**: Diagnosis via direct queries against both backends confirmed the message never persisted. The operator's send-side tool surface is under-specified relative to the agents'.

**Would have been caught by**: **MCC send-side contract** under MCC-SPEC. The pane must offer a verified "send as operator" path with the same persist-or-fail-loud semantics as agent `inbox_send` calls. Same conformance class as F-9; the send path was simply not yet built or not yet documented.

## 4. Cross-references — historical build failures sharing the meta-class

Today is not the first time the lab has hit operating-environment failures. The meta-class — *the environment's representation of reality diverged from reality, and decisions trusted the representation* — has surfaced repeatedly across different surfaces. Each instance below is tagged with its sub-type. The cross-class corpus is what the paper consolidates from.

- **AIR-001** (`planning/AIR-001-closed-not-landed.md`) — nine GitHub issues marked complete with no artifact on `main`. **Sub-type: false-completion** (per AIR-001's own `incident_class: workflow` — the tracker asserted a state that was *never* true, not stale-once-true). Downstream decisions trusted the false state. Resolution path was per-issue corrective fold-in + new template + the AIR-001 D-4 discipline that "done is verified, never claimed." Same meta-class as AIR-002; different sub-type (false-completion vs. stale-state-dominant).
- **V25-α through V28 architectural dead ends** (per `ionis-ai/ionis-devel/shared-context/MODEL-VERSION-HISTORY.md`, confirmed live; this path lives in the IONIS lineage, not the mesh spec repo) — eight successive IONIS model architectures that "looked right narratively" but broke structurally because the underlying substrate did not carry the constraint the narrative implied. **Sub-type: narrative-vs-substrate divergence** (the architecture's *description* and the architecture's *math* told different stories). Same recurring failure mode: narrative-correct, structurally wrong. The dialectical engine's role in catching these is a load-bearing claim of `papers/THE-DIALECTICAL-ENGINE.md`; the substrate-trap pre-filter in `akb-awareness-layer.md` is the AKB-layer analog of the same correction. Same meta-class as AIR-002 + AIR-001; this is the *third surface* (ML architecture) the meta-class manifests on.
- **MCC filter regression** (this AIR's F-9) — operator-side surface drift hiding peer-to-peer traffic. **Sub-type: conformance-defect**. Same meta-class.
- **Workspace flatten/restructure** (2026-05-17 / 2026-06-06) — repo paths moved twice in three weeks. Each move left stale path references in briefs, scripts, MCP configs, and agent memory that surfaced as individual failures in subsequent sessions. **Sub-type: stale-state** (path identifiers outlived the path reality). Same meta-class.
- **Inbox cutover CH → PG** (2026-06-06 / 2026-06-07) — the cutover itself is well-executed at the substrate layer (event-sourced PG store, migration tool, multi-host flip plan) but the per-agent operational discipline to verify each side flipped cleanly was incomplete on the day it ran. F-2 + F-8 are the visible consequences. **Sub-type: stale-state + missing-control** (no required post-reload identity-attestation step in the cutover playbook). Cutovers without verified per-step identity attestation are themselves a failure class — see F-8 disposition.

The paper should treat AIR-001, AIR-002, and the V-version dead ends as a coherent corpus: **same meta-class** (the environment's representation of reality diverged from reality, decisions trusted it), **different surfaces** (workflow / model architecture / operating environment), **different sub-types**. The pillar architecture targets the meta-class. The sub-type taxonomy lets the paper argue specifically about *which* pillar mechanism addresses *which* sub-type.

## 5. Disposition — CLCA actions per failure

Each failure terminates in a specific control change, not in attribution. Per AIR-001 D-4 (per Patton #56 Check 1), every "Done" row carries explicit Evidence with a citable artifact. State is one of:

- **Done (repo-tracked)** — commit SHA / file path in a git-tracked repo
- **Done (workspace-root file)** — file path under `/Users/gbeam/workspace/`; **not yet git-tracked** (pending Judge-deferred "all briefs to lab repo as SOT" move)
- **Done (user-local memory)** — file path under `~/.claude/projects/.../memory/`; **not repo-resolvable** by definition (memory is per-user, per-host local)
- **Queued** — tracked-to-pillar-spec; no artifact landed yet

| # | CLCA action | State | Evidence |
|---|-------------|-------|----------|
| F-1a | Briefs become first-class AKB corpus content (addendum B); Tier-1 hook on session start fires "current state of <agent role>" query | **Done (repo-tracked)** — addendum B authored | `planning/AKB-SPEC.md` § Pillar-specific addenda § B, merged `ef92fb2` (PR #53) |
| F-1b | Patton brief rewritten against current state | **Done (workspace-root file)** | `/Users/gbeam/workspace/PATTON-BRIEFING.md` — full inspection passes for Patton himself (operating under it per his #56 Check 2). NOT git-tracked yet; pending lab-repo SOT move |
| F-1c | Einstein brief rewritten | **Done (workspace-root file, unverified by reviewer)** | `/Users/gbeam/workspace/EINSTEIN-BRIEFING.md` — outside Patton's PAT scope; reviewer cannot independently verify. Same lab-repo SOT move dependency |
| F-1d | Newton brief touched | **Not done this session** — Newton brief existed pre-session and was not rewritten | Brief at `/Users/gbeam/workspace/NEWTON-BRIEFING.md`; refresh queued |
| F-2 | `get_version_info` mandated as first session-start probe; codified in Patton brief | **Done (workspace-root file)** for Patton | `/Users/gbeam/workspace/PATTON-BRIEFING.md` § Inbox — verified by Patton himself in #56 Check 2. NOT git-tracked; lab-repo SOT move dependency. **Queued** for Einstein/Newton/CLAUDE.md fleet-wide propagation |
| F-3+F-7 | **Single converged fix** (per Bob #56): per-agent GitHub App identity + Vault stores App private key + Vault Agent templates short-lived (1-hour) installation tokens into the wrapper-read file (`IBX_DB_FILE`-style indirection). Agent never reads creds directly. Fleet-ops / IAM lane | **Queued** to fleet-ops / IAM lane | Not yet scheduled; sequenced behind AKB Phase-1 by priority. Stopgap in place: wrapper points at `fiducial-mesh.pat` (file inspection at `/Users/gbeam/.local/bin/patton-github-mcp.sh` confirms) |
| F-3 stopgap | Wrapper PAT swap to `fiducial-mesh.pat` | **Done (workspace + dotfile)** | `/Users/gbeam/.local/bin/patton-github-mcp.sh` line 45 (`PAT_FILE="/Users/gbeam/.config/gh-tokens/fiducial-mesh.pat"`). Not git-tracked; per-host dotfile |
| F-4 | PCS deploy concern adds "review chain closed" as merge prerequisite for spec PRs | **Queued** to PCS spec | No artifact yet; tracked as a follow-up in PCS pillar lane |
| F-5 | CD numbering check at commit time — CI linter for collision against existing CD references in same spec; CD as link-typed ID | **Queued** to MI-12 / PCS spec | No artifact yet |
| F-6 | Same root as F-5; same fix applies. Additionally: build-side PR authoring should resolve CD references at PR-creation time against the latest merged spec, not against a working draft | **Queued** to MI-12 / PCS spec | Same as F-5 |
| F-7 immediate | `gh pr review --comment` with verdict framing is the only working path until F-3+F-7 converged fix lands | **Done (user-local memory)** | `~/.claude/projects/-Users-gbeam-workspace/memory/feedback_pr_review_comment_event_only.md` — user-local, not repo-resolvable by design |
| F-8 | AIR-001 D-4 generalized to configuration reload: post-restart identity-attestation is the close-out check | **Done (workspace-root file)** for the inbox MCP via the `get_version_info` mandate in F-2; **queued** for fleet-wide propagation (other reconfigurable surfaces) | Same artifact as F-2; fleet propagation tracked as follow-up |
| F-9 | MCC conformance gate on aggregator filter rules; insertion-test pattern (insert a known message, assert it renders under each pane's stated filter) | **Queued** to MCC spec; **stopgap fix landed by build-side agent same session** | Stopgap commit on MCC side (referenced in session inbox traffic, not yet linked here — Bob owns the commit pointer) |
| F-10 | MCC send-side contract for operator-as-sender; same persist-or-fail-loud semantics as agent `inbox_send` | **Queued** to MCC spec | No artifact yet |

### D-4 honesty note on the workspace-root + user-local Done rows

Several "Done" rows above sit at workspace-root file paths (briefs) or user-local memory paths (PR-review convention codification). These are **not git-resolvable today**, which means a future agent or auditor cannot verify them from the repo alone. This is a known structural gap — Judge has acknowledged the briefs should eventually live in the lab repo as single source of truth ("we'll get to it"), and user-local memory is per-user-per-host by design.

Until the lab-repo SOT move lands, the honest disposition is: these CLCA actions *are* done in operational terms (Patton operates under his refreshed brief; the memory rule prevents recurrence in Watson's sessions), but they are **not D-4-grade evidence** in the AIR-001 sense (a control described, not landed-to-a-repo). The lab-repo SOT move itself becomes part of the disposition story; tracking it here so it doesn't get lost.

## 6. Synthesis — pillar mapping (why we are building)

The failures above are not random. Each one maps to a load-bearing claim about why a specific pillar exists. The pillar architecture is the structural answer to "the environment's representation of reality diverges from reality and decisions trust it."

| Failure pattern | Load-bearing claim | Pillar / mechanism |
|---|---|---|
| Brief drift across multiple axes | Agents need a knowledge substrate with awareness layers | **AKB** (Tier 0 + Tier 1; briefs-as-corpus per addendum B) |
| Cutover state hidden from data inspection | Hot reconfiguration needs identity-attestable smoke verification | **AKB awareness + AIR-001 D-4 generalized** (`get_version_info` as the first session-start probe) |
| PAT scope drift + identity collapse blocking PR review events (F-3 + F-7) | Agent identity needs to be distinct from operator identity, with centralized credential rotation; agents must stay out of the secret-read path | **IAM + Vault-stored creds + Vault Agent file templating + per-agent GitHub App identity** (fleet-ops lane; the right shape is service-templated tokens via the `IBX_DB_FILE` indirection pattern, NOT agent-live-reading creds via a Vault MCP) |
| Operator aggregator hiding peer traffic | Aggregation panes need conformance gates over rendering rules | **MCC + ACT** (filter-correctness conformance tests; render-vs-store discrepancy alarms) |
| Stale CD references in code | Specs need single-source-of-truth + named, link-typed version progression | **PCS** (deploy concern + Spec-Harness-Registry primitive MI-12) |
| Memory references retired names | Agent memory needs drift detection + scheduled re-verification | **AKB lifecycle + decay signals** (`zero-query chunks` flagged; periodic CLCA cycle) |
| Hot reconfig not verified | Configuration changes need post-reload smoke as part of the apply cycle | **AIR-001 D-4 generalized; PCS deploy concern** |
| Path-rules referencing dead `ionis-devel/` | Ingest paths need reconciliation discipline as part of pillar build prerequisites | **AKB migration plan + Bob's OQ1** |
| Spec ↔ code reference numbering drift | Spec ↔ code coupling needs Spec-Harness-Registry primitive | **MI-12 (Spec-Harness-Registry)** |
| Operator send-path coverage gap | Operator-as-sender needs an explicit, persist-or-fail-loud build standard | **MCC send-side contract** (same conformance class as the aggregator filter gates) |

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

- `AKB-SPEC.md` (lands the awareness-layer + lifecycle structure that addresses F-1, F-8, brief-drift class; addendum B explicitly wires briefs-as-corpus)
- `IAM-CORE-SPEC.md` + fleet-ops Vault discipline (addresses F-3 + F-7 converged — agent-out-of-secret-path principle, service-templated tokens, per-agent GitHub App identity)
- `MCC-SPEC.md` (addresses F-9 aggregator conformance gates, F-10 operator send-side contract)
- `PCS-DAEMON-SPEC.md` (addresses F-4 review-chain-closed merge gate, F-5/F-6 CD numbering + spec↔code coupling)
- `AIR-SPEC-DESIGN-NOTES.md` (the cross-cutting AIR class lives here; today's AIR-002 is the second concrete instance after AIR-001)
- `MESH-SPEC.md` MI-12 (Spec-Harness-Registry primitive — the structural fix for F-5/F-6)
- `papers/THE-DIALECTICAL-ENGINE.md` (the methodology paper this AIR's § 7 consolidates into)
- `ionis-ai/ionis-devel/shared-context/MODEL-VERSION-HISTORY.md` (V25-α…V28 dead-end record cited in § 4; path verified to resolve as of 2026-06-07)

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
