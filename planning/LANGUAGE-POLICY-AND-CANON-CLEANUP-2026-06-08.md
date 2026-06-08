---
title: "Language Policy + C# Canon Purge + Categorization Cleanup — Consolidated Plan"
doc_type: design-reference
status: draft-notes
version: v0.1
date: 2026-06-08
authors:
  - watson
  - bob
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/MESH-SPEC.md
  - planning/ACT-SPEC.md
  - planning/MCC-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/PILLAR-NAMES.md
---

# Language Policy + C# Canon Purge + Categorization Cleanup

**Purpose**: Consolidates three tangled workstreams produced by today's
Judge+Bob+Watson dialogue into one readable plan, landed on GitHub so Judge
can review without needing the 9975 inbox. **This document is the plan for
review and decision**, not the cleanup itself; execution follows after
Judge's confirmation of the open decision points in §6.

**Scope**: This document covers (1) the Fiducial Mesh language policy as
Judge ratified today, (2) the C# audit of what survives the spec cleanup
and must be rewritten, and (3) the resolution of the planning-cleanup PR
F1 (213 cross-references across staying validated specs).

**Why this exists in one doc**: the three workstreams are mechanically
coupled. The C# purge edits canon files; the categorization decides which
moving files stay vs. go; the language policy frames both. Splitting them
into three issues/PRs loses the through-line. One readable file makes the
decision surface visible to Judge in one place.

**Source data**: All cross-reference counts and C# line numbers come from
Bob's `git grep` ground-truth pass on `origin/main` (2026-06-08).
Categorization recommendations and the C#-purge sequence are Bob's
analysis. The consolidation, language-map presentation, decision-surface
framing, and the execution sequence are Watson's.

---

## 1. Language Policy (Judge ratified, 2026-06-08)

**Policy in one sentence:** Python is the Fiducial Mesh default language;
any non-Python language deviation requires an argued case demonstrating
why Python cannot serve.

### 1.1 Ratified deviations (Judge, 2026-06-08)

| Pillar / area | Language | Justification |
|---------------|----------|---------------|
| **CRB** (Control Runtime / Broker) | **Go** | Hot concurrent broker; Go's concurrency primitives + GC characteristics fit the workload class Python doesn't |
| **DPG** (Sandbox / Execution Substrate) | **Go** driver + adopted microVM | Driver layer needs the Go ecosystem for OCI/containerd integration; the microVM itself is adopted (gVisor / Kata floor), not built |

### 1.2 Default-Python pillars

| Pillar / area | Language |
|---------------|----------|
| IBX (Inbox Exchange) | Python |
| AKB (Agent Knowledge Base) | Python |
| PCS (Platform Control System) | Python |
| PGE (Policy / Governance Enforcement) | Python |
| ACT — Detect Layer | Python |
| ACT — **Record Layer** | **Python** *(was C# per CD2 — flip; see §2)* |
| All MCP servers (`*-mcp` PyPI suffix convention) | Python |
| Workflows + plugins (the PCS-managed agentic tooling) | Python (skills are `SKILL.md`; agents are markdown+YAML or TOML) |

### 1.3 Likely next argued deviation (watch, not decided)

| Pillar / area | Default | Watch for argued deviation |
|---------------|---------|---------------------------|
| **IAM** | Python | Crypto / PKI / Samba AD integration may push to a different stack. Currently Python is the default; if a substrate constraint surfaces (e.g., a load-bearing library only well-supported in another runtime), the case gets argued explicitly and decided. |

### 1.4 Surface-layer choices

| Surface | Language | Note |
|---------|----------|------|
| **MCC-UI** | **JS/TS SPA** (browser context = argued — only language the browser runs natively) | Was ASP.NET Core + Blazor; flip per §2. The SPA is a dashboard only — *no LLM loop in the browser*. |
| **MCC backend** | **Python** | Was C#/.NET solution; flip per §2. Conventional web/orchestration backend over the same Python stack the pillars use. |
| **mesh-CLI / installer** | **Go**, OR (per today's MCC framing) Claude Code + PCS plugins (config not product) | Was .NET AOT mesh-CLI. Two paths: a Go static binary if a discrete CLI is needed at all, OR none — Claude Code + the PCS plugins IS the CLI. Today's MCC framing leans toward the latter (Mesh-CLI is a configuration, not a product). |

### 1.5 Out of scope for v0.1

Non-RHEL OS bases (Ubuntu, Debian, SUSE, Alpine), other-IDE plugin surfaces
(VS Code Chat participants, Copilot Extensions API), and any pillar
deviation not enumerated above. These can be argued later through the
spec-deviation process; v0.1 ships with the table above.

---

## 2. C# Canon Purge — Audit and Edit Map

C# was the working language assumption in earlier spec drafts (the "C#
spine" decision that the language-policy change retires). Bob's
`git grep` ground-truth pass on `origin/main` identified every C# / .NET
reference; this section maps each to its disposition.

### 2.1 Canon files — STAY in spec, MUST be rewritten

These three files survive the planning-cleanup (validated status) but
contain C# / .NET commitments that contradict the language policy. They
need surgical edits to flip the language commitment to Python (or, for
MCC-UI, JS/TS).

#### `ACT-SPEC.md` — flip Record Layer to Python

| Location | Current | Target |
|----------|---------|--------|
| L88 (§tech-stack) | "Record Layer is C#" | "Record Layer is Python" |
| **CD2** (L407) | Same as above as a Closed Decision | **Flip CD2** to Python |

**Justification**: OpenTelemetry has a first-class Python SDK; no
argued reason for C# survives. ACT Detect Layer is already Python; the
flip aligns both halves on one runtime.

**Affected**: 2 edits (one in §tech-stack, one in CD2). Minor scope.

#### `MESH-SPEC.md` — flip mesh-level web + .NET solution language

| Location | Current | Target |
|----------|---------|--------|
| L205–207 | "Web (ASP.NET Core + Blazor)" | "Web (JS/TS SPA + Python backend)" |
| L296 | "Mesh.Console / one .NET solution" | (Drop the single-.NET-solution framing entirely; the mesh is per-pillar Python packages in a uv workspace, with Go pillars compiled independently — already captured by `fiducial-mesh/core` README) |
| **CD14** (L516) | "Record Layer (C#)" | **Flip CD14** to Python (paired with the ACT-SPEC CD2 flip) |

**Justification**: ASP.NET/Blazor was the surface-layer choice tied to the
retired C# spine; the JS/TS SPA + Python backend choice (§1.4) is what
ratified today. "One .NET solution" presumed a single-runtime monorepo;
the actual architecture is per-pillar packages with sanctioned Go
exceptions for CRB + DPG.

**Affected**: 3 substantive edits + closing CD14.

#### `MCC-SPEC.md` — flip the entire surface-layer stack

| Lines | Current | Target |
|-------|---------|--------|
| L93, L178, L194, L204, L209, L343, L394, L396 | ASP.NET Core + Blazor + Mesh.Console references throughout | JS/TS SPA + Python backend; remove Mesh.Console references |

**Bonus alignment**: this edit *also* incorporates today's MCC delivery
shape (Bob's message of 18:30 + the Mesh-CLI/MCC convergence):
- MCC-TUI = Claude Code + PCS plugins (doer surface)
- MCC-UI = JS/TS dashboard SPA (observe, trigger known-good, approve gated, read AIR + telemetry — **no LLM loop in the browser**)
- MCC backend = conventional Python web/orchestration backend (NOT an AI system; AI lives in the CLI)
- `inbox-ui` (the Wails approve/reject app) is the MCC-UI approval-gate pane in embryo — generalizes into the dashboard

So purging the C# from MCC-SPEC is **the same edit** as folding in today's
MCC framing. Two birds. Eight C# lines → one coherent rewrite that lands
both changes.

**Affected**: ~8 line edits, but the rewrite is also a partial v1.1 of
MCC-SPEC.md if Judge wants it bumped to validated.

### 2.2 Moving drafts — retire or rewrite, do NOT promote with C# language intact

These files are already moving to devel (status: draft); they should
not be considered for the Tier-2 promotion list while still C#-stained.

| File | C# hits | Disposition |
|------|---------|-------------|
| `ENGINEERING-STANDARDS.md` | **50** | **RETIRE** (the C#/.NET build-discipline doc is the old C#-spine relic). A Python (+Go for CRB/DPG) replacement needs to be written fresh; canon refs to it (~4) get purged or redirected. |
| `DELIVERY-PACKAGING.md` | 6 | **REWRITE for Go** (or for Claude Code + plugins per the Mesh-CLI framing). `.NET AOT mesh CLI installer` is the C# remnant. Stays in devel until rewritten. |
| `REPO-SHAPE-DECISIONS.md` | (multiple) | **Stale framing**: ".NET solution / C# core monorepo" — the actual core is the uv/Python workspace at `fiducial-mesh/core`. Stays in devel; may be retired in favor of the live README. |

### 2.3 Clean / benign — leave as-is

| File | Status |
|------|--------|
| `AKB-SPEC.md` | 3 false-positive matches (incidental `.NET` mentions in unrelated context); no real C# language commitment. **Leave.** |
| `DPG-SPEC.md` | 1 hit — `.NET` named *only as a future sandboxed workload type*, not as the language DPG is built in. Legit and language-agnostic. **Leave.** |

---

## 3. Planning-Cleanup Categorization (spec#66 F1 resolution)

Bob's `git grep` ground-truth: **213 cross-references** across all 13
staying validated specs reference files that moved to devel in
spec#66. My original "move all `status: draft`" rule rips normative
grounding out from under the canon; the right resolution is to promote
the heavily-cited and architecturally-foundational drafts and keep them
in `spec/planning/`, then sweep the remaining smaller-count refs.

### 3.1 Tier 1 — auto-promote + keep in spec

Files already typed `doc_type: planning-canonical`; the `status: draft`
flag is the only thing keeping them out of the validated canon. Bump
status to `validated` and keep them in `spec/planning/`.

| File | Refs to it | Current frontmatter | Action |
|------|------------|--------------------|--------|
| `MANIFESTO.md` | **57** | `doc_type: planning-canonical`, `status: draft` | Bump to `validated`; keep in spec |
| `TECHNICAL-OVERVIEW.md` | **20** | `doc_type: planning-canonical`, `status: draft` | Bump to `validated`; keep in spec |

**Effect**: 77 of the 213 refs become valid (file is back in spec). No
content edit needed beyond the status bump.

### 3.2 Tier 2 — decision required (Judge)

These are foundational-but-untyped or substantive-but-uncertain docs.
Bob's recommendations + my read of the trade-offs:

| File | Refs | Current frontmatter | Bob's REC | Watson's read |
|------|------|--------------------|-----------|---------------|
| `DESIGN-PHILOSOPHY.md` | 13 | (no frontmatter) | **PROMOTE** | Concur. Foundational conceptual thesis (human authority + agent capability + capability/constraint duality). Add frontmatter as part of promotion. |
| `CONCURRENCY-AND-ARCHETYPES.md` | **44** | `doc_type: spec` | **PROMOTE if model's agreed** | Concur conditional. The concurrency model is Patton+Watson-authored and was the foundation for the IBX worker-pool dispatch CD7. If the model is settled (it appears to be — IBX v1.1 builds against it), promote. |
| `IDENTITY-PILLAR-DESIGN.md` | 21 | (no frontmatter) | **PROMOTE** (identity = foundation) | Concur — OR keep as design-behind-IAM-CORE-SPEC reference. Either way, IAM-CORE-SPEC.md is the canonical pillar spec; IDENTITY-PILLAR-DESIGN.md is the design-rationale layer. If Judge prefers the canonical-pillar-spec as the only canon entry, this one stays as informational reference in devel and its 21 refs get redirected to IAM-CORE-SPEC. |
| `INSTANTIATION-AND-IDP.md` | 18 | (no frontmatter; self-declares as design-target) | **KEEP IN DEVEL** | Concur. Doc self-declares "design to build toward, NOT operational." Its 18 refs go to the residual sweep — likely most can re-point to IAM-CORE-SPEC. |

### 3.3 Tier 3 — KEEP MOVING (genuine drafts, retire/rewrite/scaffold)

These files stay in `devel/spec-drafts/` per the original cleanup PR:

- The PCS 12-section scaffold (`pcs/spec/01-principles.md` … `12-resumption.md`) — folds into the eventual `PCS-SPEC.md` rewrite; doesn't need promotion as standalone
- `PCS-ADOPTION-PLAN.md` — operational planning doc, not spec
- `AGENT-FRICTION-CATALOG.md` — empirical analysis, not spec
- All AIRs (`AIR-001-*`, `AIR-002-*`) — incident reports, not spec
- `AIR-SPEC-DESIGN-NOTES.md` — design notes for the AIR concept
- All `akb-*` design dialogue (6 files) — design-trajectory material, not canonical spec
- `tier0/akb-tier0-content.md` — AKB-internal Tier 0 content
- `templates/akb-document-template.md` — AKB template, not spec
- `PCS-PLATFORM-REDESIGN-NOTES.md` (today's design notes) — design-reference, not spec
- The C# drafts above (`ENGINEERING-STANDARDS`, `DELIVERY-PACKAGING`, `REPO-SHAPE-DECISIONS`) — retire/rewrite per §2.2
- `MCC-SPEC.md`, `AKB-SPEC.md`, `IAM-INCREMENT-2.md`, `IAM-STARTER-ROLES-TABLE.md`, `MANIFESTO.md`/`TECHNICAL-OVERVIEW.md`/`CONFORMANCE.md` etc. that were in the original cleanup but where the disposition is now per Tiers 1/2 above

### 3.4 Residual cross-reference math

| Promotion scope | Refs resolved | Refs remaining to sweep |
|-----------------|---------------|------------------------|
| Tier 1 only (MANIFESTO + TECHNICAL-OVERVIEW) | 77 | 136 |
| Tier 1 + Tier 2 (all 4 promoted per Bob's recs) | 188 | **25** |
| Tier 1 + Tier 2 minus IDENTITY-PILLAR-DESIGN (if Judge prefers canonical-only) | 167 | 46 |

The Tier-1-plus-all-Tier-2 case puts the remaining sweep at ~25 refs —
mostly into the PCS scaffold (which folds into PCS-SPEC.md anyway, so
many of those refs auto-resolve when the PCS spec rewrite lands). The
post-cleanup cross-ref repair becomes surgical, not a major undertaking.

---

## 4. Execution Sequence (proposed)

This is the order of operations I recommend, decoupled into reviewable
units. Each step is its own PR / commit-group so review surface stays
manageable.

### Step 0 — This document

You're reading it. Lands as PR on `spec` repo for Judge's confirmation
of the Tier 2 decisions (§3.2) and the execution sequence (§4).

### Step 1 — C# canon purge (separate prior PR)

Edit the three canon files (ACT-SPEC, MESH-SPEC, MCC-SPEC) to flip C#
to Python (or JS/TS for MCC-UI), per §2.1. Each file's CD-bump (CD2,
CD14) gets a fresh CD or a CD-supersession noted in the file.

**Why separate from the cleanup PR**: these are substantive canon
edits (touching CDs); they deserve their own review surface rather
than being buried inside a file-move PR. Bob to review GH-native;
Judge merges.

**Affected**: 3 files, ~15 line edits total, plus the MCC-SPEC content
fold-in for today's MCC framing.

### Step 2 — Update spec#66 + devel#14 PRs (the cleanup)

Once Step 1 lands, the canon files are C#-clean. Then update the
cleanup PRs:

- Move MANIFESTO, TECHNICAL-OVERVIEW (Tier 1) back from `devel/spec-drafts/` to `spec/planning/`; bump status to validated
- Move Tier 2 promotions back (per Judge's §3.2 decision); add/update frontmatter to validated
- Sweep the residual cross-refs (~25 if all Tier 2 promoted) — either re-point to canonical specs or rewrite as GitHub URLs into devel where appropriate
- Update both PR descriptions to reflect the new categorization
- Update the `spec/planning/README.md` and `devel/spec-drafts/README.md` to reflect the new file lists

**Affected**: ~10 file moves, ~25 cross-ref edits, 2 README updates.

### Step 3 — Bob's CI gate work (parallel, separate PR)

Bob owns: CI gate enforcing `status: validated` AND `doc_type:
planning-canonical|spec` for any file landing in `spec/planning/` — plus
enforcing the language policy (no-C#/.NET, Python-default-with-argued-deviations).

### Step 4 — Bob's vendor-conformance probes (parallel)

Bob's vendor-conformance probes for the PCS-SPEC.md rewrite (open item
#1 from PCS-PLATFORM-REDESIGN-NOTES.md): Anthropic + Codex manifest
parser unknown-key tolerance; Copilot `.claude/skills/` interop claim
validation.

### Step 5 — PCS-SPEC.md rewrite (after Steps 1–4)

The actual canonical PCS spec, written end-to-end into `spec/planning/`
following `PILLAR-SPEC-TEMPLATE.md` v1.1 structure. Source material:
`PCS-PLATFORM-REDESIGN-NOTES.md` (with §15 bootstrap-correction folded
in per Bob's N1) + Bob's structured delta on Mesh-CLI/MCC framing (N2)
+ the PCS 12-section scaffold content + PCS-DAEMON-SPEC + PCS-REGISTRY-FOLD-IN.

---

## 5. What Bob owns vs what Watson owns

Per the simplified spec workflow ([[feedback_spec_workflow_simplified]]),
Watson writes specs end-to-end; Bob implements. The two-person review is
GH-native. For this work specifically:

| Workstream | Owner | Notes |
|------------|-------|-------|
| This consolidated doc | Watson | Authoring + landing on GitHub |
| Tier 2 promotion decisions | **Judge** | Decision point, not work |
| C# canon edits (ACT-SPEC, MESH-SPEC, MCC-SPEC) | Watson (edits) → Bob (review) → Judge (merge) | Step 1 |
| spec#66 + devel#14 cleanup updates | Watson (edits) → Bob (review) → Judge (merge) | Step 2 |
| CI gate enforcement | **Bob** (owns end-to-end) | Step 3 |
| Vendor-conformance probes | **Bob** (owns end-to-end) | Step 4 |
| PCS-SPEC.md rewrite | Watson (end-to-end) → Bob (review) → Judge (merge) | Step 5 |
| ENGINEERING-STANDARDS rewrite (Python+Go) | TBD (owner-decision needed) | Stays in devel until rewritten |
| DELIVERY-PACKAGING rewrite (Go or "no CLI") | TBD (owner-decision needed) | Stays in devel until rewritten |

---

## 6. Decision points for Judge

Read this section first. The rest of the doc is supporting analysis;
this section is what needs your input.

### 6.1 Tier 2 promotion calls (§3.2)

Per Bob's recommendations + my reads:

| File | Bob's REC | Judge's decision |
|------|-----------|------------------|
| `DESIGN-PHILOSOPHY.md` (13 refs) | PROMOTE + add frontmatter | ☐ Promote ☐ Keep in devel |
| `CONCURRENCY-AND-ARCHETYPES.md` (44 refs) | PROMOTE if model's agreed | ☐ Promote ☐ Keep in devel |
| `IDENTITY-PILLAR-DESIGN.md` (21 refs) | PROMOTE (or keep as design-behind-IAM-CORE-SPEC) | ☐ Promote ☐ Keep as design-behind-IAM-CORE ☐ Other |
| `INSTANTIATION-AND-IDP.md` (18 refs) | KEEP IN DEVEL (self-declares as design-target) | ☐ Keep in devel ☐ Promote ☐ Other |

### 6.2 Sequencing call (§4)

Should the C# canon purge (Step 1) land as a **separate prior PR**, or
as **part of the cleanup PR** (spec#66 expanded scope)?

- ☐ Separate prior PR (Watson's lean — keeps review surfaces focused)
- ☐ Fold into cleanup PR (one larger PR; less coordination, more diff to review)

### 6.3 ENGINEERING-STANDARDS rewrite ownership

Bob has 50 C# hits in this file — it's the largest single concentration
of the retired C#-spine. The rewrite needs to be a Python+Go(CRB+DPG)
engineering-discipline doc. Owner decision:

- ☐ Watson authors the replacement
- ☐ Bob authors the replacement
- ☐ Joint draft + Patton review

### 6.4 DELIVERY-PACKAGING rewrite ownership

Same question for `DELIVERY-PACKAGING.md`. The new shape depends on
whether mesh-CLI is a Go static binary OR "Claude Code + plugins is the
CLI" (per today's MCC framing).

- ☐ Mesh-CLI is a Go static binary (write the Go packaging doc)
- ☐ Mesh-CLI is Claude Code + PCS plugins; no separate installer (drop the doc)
- ☐ Watson decides
- ☐ Bob decides

### 6.5 Anything else

If there's a workstream this doc missed or a framing you'd prefer
different, surface it on the PR — that's why this lands on GitHub
before execution starts.

---

## 7. References

- Bob's full analysis package (inbox 2026-06-08, message `e57882f3-fd66-4106-b6dc-f33b1bffa14e`)
- Bob's PR review verdict on spec#66 + devel#14 (inbox `d2dba669-11de-4b54-acd5-16dd860e53fa`)
- Bob's Mesh-CLI + MCC delivery shape note (inbox `0b21e97f-09d5-4ffd-ae5f-f8f1ce087806`)
- Today's PCS Platform Redesign design notes (`devel/spec-drafts/PCS-PLATFORM-REDESIGN-NOTES.md`)
- Bob's memory note `project_mesh_cli_and_mcc.md` (his 9975 memory, full Mesh-CLI/MCC convergence detail)
- `spec/planning/PILLAR-SPEC-TEMPLATE.md` (v1.1, the structural contract every pillar spec satisfies)
- `spec/planning/PILLAR-NAMES.md` (canonical pillar identifiers)

---

*Drafted by Watson on M3 based on Bob's analysis from 9975. Land target:
spec repo, branch `watson/language-policy-canon-cleanup-2026-06-08`,
PR for Judge's confirmation of §6.*
