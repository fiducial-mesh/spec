---
title: "AKB Migration Plan — Existing Corpus → Ingested KB"
doc_type: planning-active
status: draft
version: v0.3
authors:
  - watson
date: "2026-06-07"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/akb-awareness-layer.md
  - planning/akb-reasoning-independence.md
  - planning/akb-lifecycle.md
  - planning/akb-review-trajectory.md
  - planning/templates/akb-document-template.md
  - spec/planning/REPO-SHAPE-DECISIONS.md
  - shared-context/skills/akb-doc/SKILL.md
---

# AKB Migration Plan — Existing Corpus → Ingested KB

**Scope**: How the existing ~442 markdown files across the workspace get ingested into AKB during Phase-1 build, without requiring manual conversion of every file.

**Status**: Draft v0.3 — reconciles the 2026-06-06 org-folder workspace reorg (per memory `workspace-layout-org-folders`) + folds Bob's 9975 friction data (inbox `5be7666a`). Changes: (1) Phase A.1 path-rule table re-keyed from the dead `ionis-devel/...` prefix onto explicit `<owner>/<repo>/...` org-folder paths; (2) old `som-pcs-registry/`, `som-pcs-control-plane/`, `spec/spec/` rows dropped — superseded by `fiducial-mesh/spec/planning/` and the per-pillar `*-SPEC.md` rule; (3) Phase C corpus walk made explicitly multi-root across the four org-folders (corpus is no longer under a single `ionis-devel/` tree); (4) new Phase A.1.5 — operational-runbook scope addition (`fiducial-mesh/devel/apps/*/ansible/README.md`-class deploy runbooks), per Bob's design-input #1 grounded in AIR-002's "deploy ≠ merge" friction; (5) three new Open Questions surfaced by the org-folder split (canonical home for AGENT-FRICTION-CATALOG, lab-vs-IONIS shared-context duplicates, stale `ionis-ai/ionis-devel/planning/akb-migration-plan.md` cleanup); (6) hook-trigger extension (Bob design-input #2 — `git push` / `gh pr` / deploy) cross-referenced; lands in `akb-awareness-layer.md` v0.5 (separate PR — out of scope here since hook triggers are query-time, not ingest-path inference). v0.2 changelog retained: skill canonical path is `shared-context/skills/`, with `.claude/skills/` retained as per-host install fallback (per Bob `50460657`); Patton's per-document cap-unit ruling resolves former Open Question 2; Phase A.1.2 frontmatter authoring discipline codifies the default-narrow contract surfaced by the SOM-4 over-broad-tagging lesson (per `c6773933`); Phase A.1 path-rule table updated to mirror code at `39d752d` including templates-excluded and tier0 dedicated rule; live-ingest pre-write gate landed separately in `akb-lifecycle.md` v0.4; Tier-0 generator contract landed in `akb-awareness-layer.md` v0.4.

## Purpose

AKB Phase-1 needs to ingest the existing corpus. Doing this by manually adding YAML frontmatter to all 442 files would take dozens of hours and is **not the right approach**. The ingest pipeline can infer most metadata from path + git + content. Frontmatter is needed only for *override cases* where inference would be wrong.

This document defines the migration strategy: **path-based inference for the bulk, explicit frontmatter only for overrides, curation pass to correct anything inference gets wrong.**

## Migration Strategy: Inference-First

### Phase A — Inference Rules (defines automatic classification)

The ingest pipeline assigns metadata using these rules in priority order:

1. **If frontmatter exists** — use it as-is (no inference, frontmatter wins)
2. **If no frontmatter** — apply path-based inference per the rules below
3. **`author_id`** — derived from `git log` first-author of the file (most-recent author for ongoing-edit docs may also be useful; first-author defines initial authorship)
4. **`date`** — from `git log` first commit of the file
5. **`last_modified`** — from `git log` most recent commit

### Phase A.1 — Path-Based Inference Rules

Paths are keyed by `<owner>/<repo>/...` matching the org-folder workspace layout (per memory `workspace-layout-org-folders`, established 2026-06-06). The corpus walk is multi-root — see § Phase C for the canonical root list.

**Lab master + lab-level operational content** (`ki7mt/ki7mt-ai-lab-devel/`):

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `ki7mt/ki7mt-ai-lab-devel/CLAUDE.md` | `spec` | all roles (cross-role; see § A.1.3 allowlist) | `false` |
| `ki7mt/ki7mt-ai-lab-devel/SOVEREIGN-STACK.md` | `shared-context` | `design-intent`, `infrastructure` | `false` |
| `ki7mt/ki7mt-ai-lab-devel/skills/**/SKILL.md` | `runbook` | per-skill (see Skill Role Inference below) | `false` |
| `ki7mt/ki7mt-ai-lab-devel/shared-context/**.md` | `shared-context` | `design-intent` (default; per-doc override via frontmatter) | `false` |
| `ki7mt/ki7mt-ai-lab-devel/planning/**.md` | `runbook` | `infrastructure` | `false` |
| `ki7mt/ki7mt-ai-lab-devel/V20-*.md`, `IONIS-THESIS.md`, `README.md` | `shared-context` | `design-intent`, `physics` | `false` |

**Fiducial Mesh framework specs** (`fiducial-mesh/spec/`):

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `fiducial-mesh/spec/planning/akb-*.md` | `spec` | `design-intent`, `infrastructure` | `false` |
| `fiducial-mesh/spec/planning/AKB-SPEC.md`, `IBX-SPEC.md`, `IAM-CORE-SPEC.md`, `ACT-SPEC.md`, `PCS-*.md`, `CRB-SPEC.md`, `DPG-SPEC.md`, `PGE-SPEC.md`, `MCC-SPEC.md`, `MESH-SPEC.md` (pillar specs) | `spec` | `design-intent`, `infrastructure` | `false` |
| `fiducial-mesh/spec/planning/AIR-SPEC-*.md`, `AIR-001-*.md`, `AIR-002-*.md` (AIR spec/discussion docs, **NOT** the AIR reports themselves) | `spec` | `design-intent`, `failure-mode` | `false` |
| `fiducial-mesh/spec/planning/MANIFESTO.md`, `DESIGN-PHILOSOPHY.md`, `ENGINEERING-STANDARDS.md`, `OWNERSHIP-MATRIX.md`, `REPO-SHAPE-DECISIONS.md`, `CONFORMANCE.md`, `DELIVERY-PACKAGING.md`, `CONCURRENCY-AND-ARCHETYPES.md`, `IDENTITY-PILLAR-DESIGN.md`, `INSTANTIATION-AND-IDP.md`, `IAM-INCREMENT-2.md`, `IAM-STARTER-ROLES-TABLE.md`, `PCS-ADOPTION-PLAN.md`, `PCS-REGISTRY-FOLD-IN.md` | `spec` | `design-intent`, `infrastructure` | `false` |
| `fiducial-mesh/spec/planning/pcs/**.md` | `spec` | `design-intent`, `infrastructure` | `false` |
| `fiducial-mesh/spec/planning/tier0/akb-tier0-content.md` | `shared-context` | all roles (intentional cross-role atomic facts; see `akb-awareness-layer.md` § Tier 0 Generator Implementation Contract) | `false` |
| `fiducial-mesh/spec/planning/templates/**` | `planning-draft` | none — **EXCLUDED** (template scaffolding, not content; covers `akb-document-template.md` + any future template) | `false` |
| `fiducial-mesh/spec/planning/AGENT-FRICTION-CATALOG.md` | `friction` | `infrastructure`, `failure-mode` | per-entry (see Phase B); **canonical home — see Open Question 6** | per-entry |

**AIR incident reports** (`fiducial-mesh/air/reports/`):

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `fiducial-mesh/air/reports/AIR-*.md` | `air-report` (per `akb-lifecycle.md` § doc_type Bounded Enumeration) | `failure-mode`, `design-intent` + pillar-specific roles per the AIR's `incident_class` / affected pillars | **`false`** (NOT `true`) — see Phase A.1.4 below |

**Mesh deploy + ops runbooks** (`fiducial-mesh/devel/`) — added in v0.3 per Phase A.1.5:

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `fiducial-mesh/devel/apps/*/ansible/README.md` | `runbook` | `infrastructure` | `false` |
| `fiducial-mesh/devel/apps/*/ansible/**.md` (other ops notes) | `runbook` | `infrastructure` | `false` |

**IONIS model planning + archive** (`ionis-ai/ionis-devel/`):

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `ionis-ai/ionis-devel/planning/PHASE-*.md` | `planning-active` | `design-intent`, `physics` | `false` |
| `ionis-ai/ionis-devel/planning/MCP-SECURITY-FRAMEWORK.md` | `spec` | all roles (cross-role; see § A.1.3 allowlist) | `false` |
| `ionis-ai/ionis-devel/planning/ARCHITECTURAL-METHODOLOGY.md` | `spec` | `design-intent`, `physics` | `false` |
| `ionis-ai/ionis-devel/planning/MASTER-ARCHITECTURE.md` | `spec` | `design-intent`, `physics` | `false` |
| `ionis-ai/ionis-devel/planning/*.md` (other) | `planning-active` | `design-intent` | `false` |
| `ionis-ai/ionis-devel/planning/notes/**.md` | `planning-draft` | none (excluded from default ingest) | `false` |
| `ionis-ai/ionis-devel/archive/planning/V*-RESULTS.md` | `v-results` | `failure-mode`, `design-intent` | **`true`** with appropriate `invariant_class` |
| `ionis-ai/ionis-devel/archive/planning/*.md` (other) | `archive` | matches what doc described | per-content |
| `ionis-ai/ionis-devel/shared-context/MODEL-VERSION-HISTORY.md` | `shared-context` | `design-intent`, `physics`, `failure-mode` | `false` |
| `ionis-ai/ionis-devel/shared-context/architecture-philosophy.md` | `shared-context` | all roles (cross-role; see § A.1.3 allowlist); **see Open Question 7** | `false` |
| `ionis-ai/ionis-devel/shared-context/domain-wisdom.md` | `shared-context` | `physics`, `astrophysics`; **see Open Question 7** | `false` |
| `ionis-ai/ionis-devel/shared-context/TRAINING-SOPS.md` | `runbook` | `design-intent`, `infrastructure` | `false` |
| `ionis-ai/ionis-devel/resources/*.md` | `shared-context` | `design-intent` | `false` |

**Skills (per-host install fallback)**:

| Path Pattern | `doc_type` | Default `roles` | `violates_invariant` |
|---|---|---|---|
| `.claude/skills/**/SKILL.md` (any host) | `runbook` | per-skill (see Skill Role Inference below) | `false` |

**Excluded paths** (not ingested by default):

| Path Pattern | Rule |
|---|---|
| `papers/**.md` (any repo) | **EXCLUDED** — research-style, not AKB-ingested |
| `**/.git/**` | **EXCLUDED** — git internals |
| `**/node_modules/**`, `**/.venv/**`, `**/__pycache__/**` | **EXCLUDED** — build/runtime artifacts |
| `**/temp/**`, `**/notes/**` (workspace-root scratch dirs) | **EXCLUDED** — transient |
| `qso-graph/**` | **DEFERRED** — per-MCP READMEs + planning not in scope for bootstrap v1; revisit when MCP doc surface stabilizes |

**Skill canonical path note** (per Bob's `50460657` bootstrap dry-run finding): the canonical skill source the lab-devel corpus walk surfaces is `ki7mt/ki7mt-ai-lab-devel/skills/<name>/SKILL.md` (relocated from the previous `ionis-devel/shared-context/skills/` path by the 2026-06-06 reorg — content moved with the rest of the lab corpus). `.claude/skills/<name>/SKILL.md` is the per-host install location (Claude Code lays skills out there at install time); it is supported by the same rule and routes through the same `SKILL_ROLE_MAP` so per-host development paths remain ingestible. **Both paths fire the same rule with the same role lookup.** Pre-fix, the ingest pipeline matched only `.claude/skills/`, leaving 14 corpus skills silently default-roled and invisible to role-projected retrieval; the fix landed in `KI7MT/akb` at `39d752d`.

### Phase A.1.1 — Skill Role Inference (refined per `akb-cross-role-audit.md`)

Initial inference rule assigned `all roles` to every `.claude/skills/**/SKILL.md` glob match. That was wrong: most skills serve a specific role, not all of them. Blanket cross-role assignment would saturate the 50-chunk hard cap as skills proliferate.

**Refined rule** — split skills by content type:

| Skill class | Examples | Assigned roles |
|---|---|---|
| **Cross-role skills** (genuinely applicable to every agent) | `akb-doc` (document creation; every agent authoring), `security-review` (every agent shipping code), future agent-onboarding skills | `[design-intent, infrastructure, failure-mode, physics, astrophysics]` — all roles |
| **Design/research skills** | `propagation`, future model-architecture-review skill | `[design-intent, physics]` |
| **Infrastructure skills** | `fleet-test`, `release`, `pipeline-check`, `update-config`, `keybindings-help` | `[infrastructure]` |
| **Failure-mode / review skills** | future code-review skill, audit skills | `[failure-mode]` |
| **Physics / domain skills** (primary surface IS the physics — space weather / propagation measurement) | `solar-brief`, `wspr-brief` | `[physics]` |
| **Operating skills** (radio-operating activities — DX cluster, park activations — not propagation physics; narrowed per issue #79, Judge triage 2026-06-02) | `dx-brief`, `pota-brief` | `[infrastructure]` |
| **Astrophysics skills** | `newton` (model health check), future astrophysics-specific skills | `[astrophysics]` |

**Default if uncertain**: single most-relevant role. Cross-role assignment requires explicit justification in the skill's frontmatter.

**Heuristic for classification at ingest**: parse the skill's frontmatter `description` field; match keywords against the role taxonomy. Initial pass can be manual; later automate via curation events.

**Why this matters**: per `planning/akb-cross-role-audit.md`, the current cross-role budget is at 66% utilization with only ONE skill (`akb-doc`). If every future skill defaults to all-roles, the cap saturates by the ~5th-10th skill. The refined rule keeps the cap available for content that actually warrants cross-cutting visibility.

**Skill source-of-truth note**: the SKILL_ROLE_MAP keys on the skill name (the directory name under `skills/`), not on the canonical-vs-install path. The same skill name routes through the same role assignment regardless of whether it was found at `shared-context/skills/<name>/SKILL.md` or `.claude/skills/<name>/SKILL.md`. Changing a skill's role assignment requires editing the SKILL_ROLE_MAP and noting the change in the Phase A.1.1 classification table above; the change applies to every path where that skill appears.

### Phase A.1.2 — Frontmatter Authoring Discipline (new section, v0.2)

**Surfaced by the SOM-4 over-broad-tagging issue (PR #60, 2026-06-02):** four Fiducial Mesh mesh-architecture canonical docs (now at `fiducial-mesh/spec/planning/`) were carrying inherited all-five-roles frontmatter (`design-intent + infrastructure + failure-mode + physics + astrophysics`), over-tagging them on the role axis. Mesh-arch docs are not propagation physics — physics and astrophysics agents should not be retrieving Fiducial Mesh pillar names as relevant context to ionospheric or astro queries. Patton ruled `c6773933` to fix the source of truth pre-bootstrap rather than maintain a curation-layer correction.

**The Frontmatter Authoring Contract** (binding for all docs ingested into AKB):

1. **Default narrowly.** When in doubt, assign the *minimal* roles array that captures the doc's intended audience. A doc that is primarily design-and-infra reads has `roles: [design-intent, infrastructure]`. Adding `failure-mode` because Patton might also read it is *not* a reason — Patton reads source files directly per the self-review exemption in `akb-reasoning-independence.md`.
2. **All-5-roles requires explicit justification.** A doc carrying `roles: [design-intent, infrastructure, failure-mode, physics, astrophysics]` is a *cross-role* assignment subject to the 50-document hard cap (per `akb-reasoning-independence.md` § Cross-Role Chunk Budget). The cap is per-document, not per-chunk (per Patton's ruling, see Open Question 2 resolved below). Cross-role assignment must be defensible — examples: `akb-tier0-content.md` (Tier-0 atomic facts every agent gets), `CLAUDE.md` (project source of truth), `MCP-SECURITY-FRAMEWORK.md` (non-negotiable security regardless of agent role). Mesh-architecture docs, planning docs, and most specs are NOT cross-role candidates.
3. **Inherited convention is not an authoritative role assignment.** The ionis-devel corpus has historical docs that pre-date AKB and carry frontmatter inherited from when the project was purely physics-domain. Inherited all-roles patterns must be *audited*, not preserved by default. PR #60 was the first such audit; future ingest-time audits run per the periodic re-balancing cadence in `akb-reasoning-independence.md` § Re-Balancing Triggers.
4. **Physics and astrophysics are domain roles, not interest categories.** Adding `physics` to a doc's roles means "an agent reasoning from physics-first priors will surface this in a propagation query." If that's not what the doc does, it doesn't get `physics`. Same for `astrophysics` — Newton's content, not "anything that might mention space weather."
5. **Frontmatter is contract, not signal.** The roles array commits the doc to a specific projection space. Authoring the frontmatter is an act with consequences for what agents retrieve; the same care applies as to writing the prose.

**How this applies to the canonical chain**:
- New AKB-ingested docs created via the `akb-doc` skill follow this contract by default (the skill's template demands explicit role choice).
- Inherited docs ingest with their current frontmatter; mis-tagging is corrected at audit time (PR #60 was the first audit cycle).
- The Phase D curation pass surfaces remaining drift; mis-tagged docs found post-bootstrap are corrected via source-level frontmatter PR plus a curation event noting the correction.

### Phase A.1.3 — Inherited-Over-Tagging Detection Hook (mandatory bootstrap check)

**Per Patton's PR-#61 review (2026-06-02)**: a written prohibition without a detection mechanism is exactly how the SOM-4 drift happened in the first place. The SOM-4 over-tagging was *caught* by Bob's bootstrap dry-run cross-role count, not by an authorial principle. The frontmatter authoring contract (§A.1.2) encodes "we should remember not to"; this section encodes "the system catches it." Both are required; either alone is insufficient.

**The hook — bootstrap-time check** (extends the dry-run report in `akb-lifecycle.md` § Pre-Write Gate):

For each document being ingested, the dry-run inspects the frontmatter `roles` array against the document's `doc_type` and source path. The check identifies **suspected over-broad-role assignments** — documents carrying physics or astrophysics roles whose `doc_type` + path combination does not match the expected physics/astrophysics-domain pattern.

**Expected physics-domain patterns** (the allowlist that does NOT trigger the flag) — paths org-folder-qualified as of v0.3:
- `ionis-ai/ionis-devel/shared-context/domain-wisdom.md` (Newton's domain content)
- `ionis-ai/ionis-devel/shared-context/MODEL-VERSION-HISTORY.md` (model lineage, physics-grounded)
- `ionis-ai/ionis-devel/planning/ARCHITECTURAL-METHODOLOGY.md` (physics-design)
- `ionis-ai/ionis-devel/planning/MASTER-ARCHITECTURE.md` (physics-design)
- `ionis-ai/ionis-devel/planning/PHASE-*.md` (physics workstream)
- `ionis-ai/ionis-devel/archive/planning/V*-RESULTS.md` (V-version post-mortems; `failure-mode` + `design-intent` legitimately, often `physics` too)
- `fiducial-mesh/spec/planning/tier0/akb-tier0-content.md` (intentional cross-role, includes physics atomic facts)
- `ki7mt/ki7mt-ai-lab-devel/CLAUDE.md` (universal project source-of-truth; intentional all-5 by inference design — added per issue #79, Judge triage 2026-06-02)
- `ki7mt/ki7mt-ai-lab-devel/skills/solar-brief/SKILL.md` (space-weather briefing — primary surface IS the physics; added per issue #79)
- `ki7mt/ki7mt-ai-lab-devel/skills/wspr-brief/SKILL.md` (WSPR propagation measurement briefing — primary surface IS the physics; added per issue #79)
- Documents whose `description` field in frontmatter explicitly contains physics/propagation/ionospheric terminology

**Expected astrophysics-domain patterns** (the allowlist that does NOT trigger the astrophysics flag):
- `ionis-ai/ionis-devel/shared-context/domain-wisdom.md` (Newton's primary content)
- `ki7mt/ki7mt-ai-lab-devel/skills/newton/SKILL.md` (Newton's health check)
- `fiducial-mesh/spec/planning/tier0/akb-tier0-content.md`
- `ki7mt/ki7mt-ai-lab-devel/CLAUDE.md` (universal project source-of-truth; intentional all-5 by inference design — added per issue #79)

**Anything else carrying `physics` or `astrophysics`** is **flagged as a suspected over-broad-role assignment** and surfaces in the dry-run report. Examples that would have been caught pre-PR-#60 (paths since rehomed to `fiducial-mesh/spec/planning/`):
- `fiducial-mesh/spec/planning/PILLAR-NAMES.md`-class docs carrying physics + astrophysics → flag (mesh-arch doc, not physics)
- `fiducial-mesh/spec/planning/MANIFESTO.md` carrying physics + astrophysics → flag
- Any other `fiducial-mesh/spec/planning/*.md` mesh-architecture doc carrying physics + astrophysics → flag (these are pillar/framework specs, not propagation physics)

**Resolution discipline** (per Patton's `c6773933` ruling on source-vs-projection):
- Each flagged document must be either (a) corrected at the source-frontmatter level via PR before the bootstrap proceeds, or (b) explicitly added to the expected-patterns allowlist with justification in the bootstrap-event log.
- The fix is at the source, not the projection. A curation-event "exception" that lets the over-tagged document pass without source fix is **not** an acceptable resolution at bootstrap time.

**Bootstrap-time gate**: the bootstrap fails with the list of suspected over-broad-role documents and does NOT write to `akb.chunks`. Operator must address each flagged document (correct or allowlist-with-justification) and re-run dry-run.

**Why this check is here, not just the prohibition**:
- A new mesh-arch doc landing in the corpus tomorrow with inherited all-5-roles frontmatter is exactly the SOM-4 failure mode repeating itself. The principle in §A.1.2 says "default narrowly"; this hook says "if you didn't, the system catches it before live ingest."
- Mirrors the cross-role document cap check (§Cross-Role Document Budget in `akb-reasoning-independence.md`) — the same "detection at the chokepoint" discipline, applied to a different drift class.
- Patton's reasoning: prohibitions alone are how drift accumulates; detection hooks are how drift is prevented. Both are required for the contract to be operational.

**Future extensions** (deferred but flagged):
- Failure-class detection: documents in `planning/` paths with `violates_invariant=false` but title or frontmatter description suggests post-mortem content. Flag for manual classification at dry-run.
- Stale-trajectory detection: `akb-review-trajectory.md`-class documents (methodology evidence) that age out of relevance. Defer to Phase D curation.

### Phase A.1.4 — AIR-report ingest rules (`fiducial-mesh/air/reports/AIR-*.md`)

Added 2026-06-07 per Judge directive. AIRs (Agentic Incident Reports) live in the dedicated `fiducial-mesh/air` repository (per `AIR-SPEC-DESIGN-NOTES.md` § 7.1) and are ingested into AKB so the lessons each AIR captures become **retrievable across sessions** rather than living in agent memory. This closes the AIR + AKB + PCS containment loop articulated in `AIR-SPEC-DESIGN-NOTES.md` § 1.

**The load-bearing rule: `violates_invariant: false`**

AIRs document operational lessons that should be **surfaced** at decision points, not filtered out by the substrate-trap pre-filter (per `akb-awareness-layer.md` § Tier 1 Query Flow / Einstein round 5). This is **distinct from `v-results`**:

| Doc class | `violates_invariant` | Why |
|---|---|---|
| `v-results` | `true` | Dead-end architectures (V25-α…V28). The pre-filter excludes them from non-historical queries so a Watson query for "SFI sidecar architecture" doesn't surface V25-α as a candidate solution. |
| `air-report` | **`false`** | Operational lessons. The whole point is to **surface** AIR-002's F-3 (PAT scope drift) when an agent's hook-trigger fires before `git push` or `gh pr`. Marking `true` would defeat the AIR + AKB containment. |

The `invariant_class` field stays empty for `air-report` chunks. The AIR ID + failure-ID (F-N) are addressable via the per-chunk `header_path` (e.g., `AIR-002 > Section 3 > F-3. PAT scope drift across org rename`), not via the substrate-trap-pre-filter metadata.

**Role assignment per AIR**:

- **Baseline roles** (always present): `failure-mode`, `design-intent`
- **Pillar-specific roles** added per the AIR's affected pillars / `incident_class`:
  - AIR with `incident_class: workflow` (AIR-001) → no additional pillar role; baseline only
  - AIR with `incident_class: operating-environment` (AIR-002) → adds roles for the affected pillars (e.g., AKB, IBX, MCC, IAM, PCS — whichever the F-N failures span)
  - AIR with `incident_class: substrate` → adds `infrastructure`
  - AIR with `incident_class: security` → carries `audience: restricted` per `AIR-SPEC-DESIGN-NOTES.md` § 1.4; **does not flow into general AKB at all** — security findings stay out of ACT and AKB by structural exclusion (§ 1.4 of the design notes); only metadata (class, time, severity) may exist in SEC's restricted plane
- Inference at ingest time: the AIR's frontmatter `incident_class` + the F-N sub-section's stated affected pillar (when named) drive role assignment

**Chunking**: each F-N sub-section within an AIR chunks independently (header-based split at H3 boundaries inside § 3). A query about "PAT scope drift" surfaces AIR-002 § 3 § F-3, not the whole AIR. The per-chunk `header_path` carries the AIR ID → section → F-N hierarchy.

**Tier-1 surface mechanism (per AKB-SPEC CD14)**: AIR chunks surface via Tier-1 query when the hook triggers fire at decision points — code-author-side (`Edit`, `Write`, `git commit`, MCP plugin invoke) AND infra-decision-side (`git push`, `gh pr create` / `gh pr review`, deploy commands, substrate config edits). An agent about to push code that touches inbox MCP fires an AKB query → AIR-002 F-2 + F-8 surface as relevant context. This is the operational realization of "AKB makes the lesson retrievable across sessions so it doesn't live in memory" (AIR-SPEC-DESIGN-NOTES § 1).

**Tier-0 exclusion**: AIRs do NOT go into Tier-0 (the bounded ~1 KB session-start prior). Tier-0 is reserved for the V16 laws, eight dead ends, security non-negotiables, current phase, layer reminder. AIRs are too rich for Tier-0; they belong in Tier-1 (gradient-gated retrieval at decision points).

**Curation event on AIR merge**: when a new AIR merges to `fiducial-mesh/air/main`, a git-post-commit hook (or equivalent) triggers re-ingest into AKB. The curation event is logged with `event_type='air_ingest'`, the AIR ID, the source commit, and the per-F-N chunk count.

**`incident_class: security` exclusion** (critical): security-class AIRs route to a restricted destination per AIR-SPEC-DESIGN-NOTES § 1.4. They are **categorically excluded from AKB ingest** — security finding payloads never land in AKB (or ACT) because broadcast-by-design substrates are incompatible with need-to-know audiences. The ingest pipeline drops AIRs with `incident_class: security` or `audience: restricted` and logs a curation event noting the exclusion. SEC pillar (when ratified per CD1) owns the restricted store for these.

### Phase A.1.5 — Operational-Runbook Corpus Scope (new in v0.3)

**Surfaced by AIR-002 "Day of Stale State" (`fiducial-mesh/air/reports/AIR-002-day-of-stale-state.md`) + Bob's 9975 friction data (inbox `5be7666a`, 2026-06-07):** the v0.2 corpus walk centered on edit/commit/physics-class content. The decision points that cost hours during AIR-002's cascade — `git push`, `gh pr create`, "deploy ≠ merge" — were operational/infrastructure decisions whose authoritative knowledge lives in deploy runbooks (e.g., the IBX Ansible playbooks' `README.md`), not in the planning corpus. With v0.2 path rules, those runbooks would have been silently excluded; AIR-002's F-7 ("agent decision-point hooks didn't fire on the right verbs") and F-3 ("PAT scope drift across org rename") both have their resolutions sitting in those runbooks.

**The fold-in**: deploy/ops runbooks under `fiducial-mesh/devel/apps/*/ansible/**.md` are in scope for the corpus walk and ingest as `doc_type: runbook` with `roles: [infrastructure]`. The path table § Mesh deploy + ops runbooks codifies this. The vehicle (`runbook` doc_type, the `friction` doc_type + `AGENT-FRICTION-CATALOG.md` as the catalog of resolved + open friction) already existed in v0.2; v0.3 adds the path rules that route the actual artifacts into it.

**Coupled — but separate PR**: the *trigger* side of this loop — extending Tier-1 hook triggers from edit/commit/physics-only to also include `git push`, `gh pr create`, `gh pr review`, deploy commands — is a query-time concern, not an ingest-path-rule concern. It lands in `akb-awareness-layer.md` v0.5 as a sibling PR. The two halves only close the AIR-002 containment loop together: A.1.5 makes the runbook *retrievable*; the awareness-layer trigger extension makes the *retrieval fire* at the moment the agent needs it. See Open Question 8 below.

**What this does NOT promise**: the path rule covers `ansible/**.md` for `fiducial-mesh/devel/apps/*` paths. Per-app subdirectory runbooks (deploy notes, troubleshooting docs, gh-token conventions) that live elsewhere in the mesh-devel tree are not auto-included by this rule — they get explicit per-path additions when they materialize, or per-doc frontmatter override. The intent is to plug the deploy-runbook hole AIR-002 exposed, not to over-broaden into "every .md under fiducial-mesh/devel/".

### Phase A.2 — Cross-Role Chunk Budget

The cross-role chunk hard cap is **50 total** (per `akb-reasoning-independence.md`). Sources of cross-role chunks from path-based inference:

- `CLAUDE.md` — likely 10-20 chunks (~60% of cap)
- `MCP-SECURITY-FRAMEWORK.md` — likely 5-10 chunks
- `shared-context/architecture-philosophy.md` — likely 5-10 chunks
- `.claude/skills/**/SKILL.md` — variable, depends on skill count

Initial budget likely **at or near 50**. Cross-role status for any new chunks requires deprecation of an existing cross-role chunk. Phase D curation includes pruning cross-role assignments to fit budget.

## Phase B — Override Frontmatter (manual, low-volume)

Add explicit YAML frontmatter only for docs where path-based inference would be **wrong**. Categories likely needing overrides:

### B.1 — Per-entry classification within multi-entry docs

`planning/AGENT-FRICTION-CATALOG.md` contains many entries; some are still-active (`violates_invariant=false` because they document the resolution), others document defective patterns (`violates_invariant=true`). The path-based default assigns `friction` doc_type but cannot per-entry-classify within a single file.

**Approach**: ingest the file with default metadata; use AKB curation events post-bootstrap to flag specific chunks that should have `violates_invariant=true` (e.g., the "what was broken" portions of each entry). No frontmatter change to the source file; the override happens at the chunk level via curation.

### B.2 — Archive docs that document successful patterns

Most `archive/**` content defaults to `archive` doc_type with `deprecated` tier — historical reference, low retrieval priority. But some archived docs describe patterns that are still valid (e.g., methodology docs that pre-date current naming conventions but remain conceptually sound).

**Approach**: identify these during Phase D curation. Override via curation event to bump tier from `deprecated` → `validated` for chunks that remain authoritative.

### B.3 — New documents going forward

All new operational documents (after Phase-1 ships) use the AKB template per `akb-doc` skill. Explicit frontmatter is the contract. Path-based inference becomes the fallback for legacy content only.

## Phase C — Initial Bootstrap

After Phase A inference rules are implemented in the ingest pipeline:

1. **Bootstrap event logged** in `akb.curation_events` with `event_type='bootstrap'`, batch_id, **per-root source-corpus git-commit hashes** (one per canonical root — multi-root corpus, see § C.1 below), timestamp
2. **Multi-root corpus walk** across the canonical roots listed in § C.1 (the v0.2 "full corpus walk under one tree" model is dead — see Phase Reorg Note)
3. **Chunk + embed** each file using BGE-large-en-v1.5 on 9975 GPU
4. **Insert into `akb.chunks`** with inferred metadata; per-chunk `repo` field tracks the originating org-folder repo for downstream filtering
5. **Sample validation** — Watson or Bob spot-checks ~20 chunks across the corpus (at least 3 per canonical root) to verify metadata assignment is reasonable
6. **Bootstrap-v1 marked complete** in `akb.curation_events`

Expected runtime: ~20-30 minutes for full corpus on 9975 RTX PRO 6000. Idempotent (re-runnable if anything goes wrong; chunk_ids are deterministic per `akb-lifecycle.md`).

### C.1 — Canonical Roots (multi-root corpus walk)

Bootstrap walks **all** of the following roots (paths are workspace-root-relative; each host resolves them from its `$WORKSPACE_ROOT` per memory `workspace-layout-org-folders`):

| Root | What it contributes |
|---|---|
| `ki7mt/ki7mt-ai-lab-devel/` | Lab master CLAUDE.md, sovereign-stack docs, lab skills, lab-level planning (packaging, venv, workspace consistency) |
| `fiducial-mesh/spec/` | Fiducial Mesh framework specs (pillar specs, AKB design family, AIR spec/discussion docs, design philosophy + ownership matrix, tier-0 content, templates [excluded], AGENT-FRICTION-CATALOG canonical copy) |
| `fiducial-mesh/air/` | AIR incident reports (`reports/AIR-*.md`) |
| `fiducial-mesh/devel/` | Mesh deploy + ops runbooks (`apps/*/ansible/**.md`) — new in v0.3 per § A.1.5 |
| `ionis-ai/ionis-devel/` | IONIS model planning (PHASE-*, architectural methodology, master architecture, MCP security framework, V*-RESULTS archive, model version history, training SOPs, domain wisdom, training-side architecture philosophy, resources) |

**Excluded roots** (do not walk):
- `qso-graph/**` — per-MCP READMEs + planning, deferred until MCP doc surface stabilizes (table § Excluded paths)
- `ki7mt/research-papers/**` and any `papers/**` — research-style, not AKB-ingested (existing exclusion)
- Workspace-root scratch (`temp/`, `notes/`)
- Any `.git/`, `.venv/`, `node_modules/`, `__pycache__/`

**Per-root git-commit hash capture**: the bootstrap event records `{root: git_commit_sha}` for each canonical root so re-ingest deltas are computable per repo. A corpus state where only `fiducial-mesh/spec/` advanced re-walks only that root on incremental ingest (Phase E steady state).

**Phase Reorg Note**: prior to the 2026-06-06 org-folder workspace reorg, the corpus walk assumed a single `ionis-devel/` root with ~442 markdown files. After the reorg, the corpus is fragmented across the four canonical roots above (lab content split out of `ionis-devel` into `ki7mt/ki7mt-ai-lab-devel`; mesh framework specs split into `fiducial-mesh/spec`; AIR reports into `fiducial-mesh/air`; IONIS model content remains in `ionis-ai/ionis-devel`). The total markdown count is comparable to the pre-reorg ~442; the fragmentation is the change Phase C now accounts for. Single-root walk logic ingested at most one root and silently dropped the rest — the change is structural, not just a path prefix update.

## Phase D — Post-Bootstrap Curation Pass

Once bootstrap is complete, run a structured curation pass to correct anything inference got wrong:

### D.1 — Failure-class flagging

Patton-veto review pass (per `akb-lifecycle.md` Bar C):
- All chunks with `doc_type=v-results` — verify `violates_invariant=true` correctly assigned and `invariant_class` accurately names the failure
- All chunks from V27-RESULTS, V25-α post-mortem, V28 kill verdict — verify these are flagged as historical references not currently-recommended approaches
- Friction-catalog defect-description chunks — flag with `violates_invariant=true` via curation events

### D.2 — Cross-role budget enforcement

Audit chunks tagged with multiple roles. Verify total count of cross-role chunks ≤ 50. Demote over-broad assignments to single-role where appropriate.

### D.3 — Tier 0 candidate identification

Walk the corpus for content that should be promoted into Tier 0 (Bar B, Judge-gated per `akb-awareness-layer.md`):
- Eight-dead-end list (from V*-RESULTS files) — extract one-liners
- V16 physics laws (from CLAUDE.md) — verify accurate
- Security framework non-negotiables (from MCP-SECURITY-FRAMEWORK.md)
- Current phase indicator (from CLAUDE.md)
- Layer A/B reminder (from existing docs)

Judge approves Tier 0 candidates via inbox-ui Bar B workflow.

### D.4 — Initial promotion candidates

Procedural / reference content (per `akb-lifecycle.md` Bar A) auto-promotes after threshold retrievals. No manual action.

Failure-class / architectural content (Bar C) enters `akb.promotion_candidates` queue. Patton's next session reviews batch (per session-driven model in `akb-lifecycle.md`).

V16-touching content (hybrid Bar B + Physics Bar C) requires Judge + Einstein parallel review. Rare — most content doesn't touch V16 invariants.

## Phase E — Going Forward (Steady State)

After Phase D, the corpus is initialized in AKB. From this point:

1. **New docs use the `akb-doc` skill** with explicit frontmatter — no path-based inference for new content
2. **Existing docs continue to be ingested via git post-commit hook** — re-chunk + re-embed on changes; metadata preserved from existing AKB record unless frontmatter is added
3. **Curation events accumulate** — promotions, demotions, conflict resolutions logged in `akb.curation_events`
4. **Monthly AKB CLCA cycle** — review top-N flagged chunks, zero-query chunks, conflict registry; corrective actions logged

## Migration Effort Estimate

| Phase | Effort | Notes |
|---|---|---|
| A — Inference rules implementation | ~1 day (Bob) | Part of Phase-1 ingest pipeline build, not separate work |
| B — Override frontmatter | ~0 hours initially | Deferred to Phase D; not blocking bootstrap |
| C — Initial bootstrap | ~30 min runtime + 1 hour validation | Single CLCA cycle |
| D.1 — Failure-class flagging (Patton) | 1-2 Patton sessions | Session-driven, not calendar-driven |
| D.2 — Cross-role budget | ~2-4 hours (Watson or curator) | Manual review of ~50 candidates |
| D.3 — Tier 0 promotion | 1-2 Judge sessions via inbox-ui | Bar B approval cycle |
| D.4 — Bar C queue first pass | Variable (Patton bandwidth) | Probably 2-3 sessions |
| **Total migration cost** | **~1 week elapsed** | After Phase-1 ingest pipeline is operational |

**Critical comparison**: manual conversion of 442 files at 5 minutes each = ~37 hours of focused work. Inference-first approach reduces this to ~1 week elapsed with most work done by Bob (pipeline) + Patton (review batches) + auto-inference doing the bulk.

## Open Questions

1. **Inference accuracy target**: what % of chunks should have correct metadata from path-based inference alone before Phase D curation begins? Recommend 85%+ — if below this, the inference rules need tightening before bootstrap.
2. ~~**Cross-role budget overflow handling**~~ — **RESOLVED 2026-06-02 per Patton (via Bob inbox `8238714a`):** the cross-role hard cap is **per-document, not per-chunk**. Phase A bootstrap-time check counts the number of *distinct documents* whose frontmatter assigns all five roles; the cap is **N=50 documents**. Bob's bootstrap dry-run measures cross-role at 8 documents / 50 after PR #60 frontmatter correction, well under the cap. If a future ingest event would push the count to 51, bootstrap fails with overflow report and PR-#60-style frontmatter sweep is the resolution (correct the source, not the projection). Codified in `akb-reasoning-independence.md` § Cross-Role Document Budget (v0.4).
3. **V*-RESULTS `invariant_class` assignment**: can this be auto-extracted from filename pattern (e.g., `V27-RESULTS.md` → `invariant_class=V27-PIL`), or does it require manual mapping? Recommend automatic from filename for VNN-RESULTS files; manual for archive entries with non-standard naming.
4. **Patton's first-batch capacity**: Phase D.1 may surface 50-200 failure-class chunks needing review. Can Patton review that volume in 1-2 sessions, or do we batch differently?
5. **Existing trajectory artifacts (`akb-review-trajectory.md`)**: should the review trajectory itself be ingested? It's methodology evidence, not lifecycle content. Recommend yes, with `doc_type=shared-context`, `roles=design-intent, failure-mode`, `violates_invariant=false`.
6. **AGENT-FRICTION-CATALOG canonical home** (new in v0.3, Judge): the org-folder reorg leaves two copies — `fiducial-mesh/spec/planning/AGENT-FRICTION-CATALOG.md` (newer, mesh-wide friction including IBX/AKB/PCS) and `ionis-ai/ionis-devel/planning/AGENT-FRICTION-CATALOG.md` (older, IONIS-model-and-MCP-era friction; still references the retired `KI7MT/som-pcs-spec` URLs). v0.3 path table tentatively names the `fiducial-mesh/spec/` copy as canonical (newer + mesh-wide scope), pending Judge ruling. Recommend: declare `fiducial-mesh/spec/planning/AGENT-FRICTION-CATALOG.md` canonical, retire the `ionis-ai/ionis-devel/` copy with a redirect note. Alternative: keep both as scope-disjoint (mesh-wide vs IONIS-specific) with distinct names. If unresolved by bootstrap time, the dry-run inherits the v0.3 tentative ruling.
7. **lab-vs-IONIS `shared-context` duplicates** (new in v0.3, Judge): `architecture-philosophy.md` and `domain-wisdom.md` exist in both `ki7mt/ki7mt-ai-lab-devel/shared-context/` (lab-level copy from the reorg split) and `ionis-ai/ionis-devel/shared-context/` (IONIS-side copy, has IONIS-specific paragraphs the lab copy doesn't). Ingesting both produces duplicate chunks with different `chunk_id` (different `repo` field). Three resolution shapes: (a) declare one canonical, retire the other; (b) keep both — they're scope-disjoint enough to justify separate entries; (c) flag at dry-run via a duplicate-content detector and force per-doc Judge ruling. v0.3 path table currently lists only the `ionis-ai/ionis-devel/` versions for `architecture-philosophy` + `domain-wisdom` (older split, still primary surface). Pending Judge ruling.
8. **Hook-trigger extension cross-reference** (new in v0.3, Bob design-input #2): Bob proposed extending Tier-1 hook triggers to include `git push`, `gh pr create`, `gh pr review`, and deploy commands (grounded in AIR-002's F-7 "agent decision-point hooks didn't fire on the right verbs"). The trigger spec lives in `akb-awareness-layer.md` § Tier-1 Injection Mechanism, not here. This OQ tracks the cross-reference; the actual fold lands in `akb-awareness-layer.md` v0.5 as a sibling PR after this one merges. Without that fold, A.1.5's runbook corpus addition is *retrievable but not retrieved* — the loop closes only when both halves land.

## Failure Modes To Watch

- **Inference misclassification at scale**: a wrong path-based rule produces 100+ wrong-metadata chunks. Mitigation: Phase C sample validation catches systematic errors; Phase D curation corrects individual chunks.
- **Cross-role budget creep**: easy to mark things "visible to all" during initial inference; hard cap of 50 must be enforced at ingest. Mitigation: bootstrap-time validation fails if cap exceeded; manual reduction required before retry.
- **Patton-veto queue overflow**: Phase D.1 may generate more candidates than Patton can review per session. Mitigation: queue-size escalation per `akb-lifecycle.md` (threshold = 25 awaiting). Judge invokes Patton on cadence for batched review.
- **Stale chunks in archive**: archived docs may describe defunct infrastructure that's still queryable. Mitigation: `archive` doc_type defaults to `deprecated` tier; agents see explicit "historical" warning when retrieving archive chunks.
- **Inbox-derived content gaps**: high-value inbox messages (Patton verdicts, Bob/Watson coordination outputs) aren't auto-ingested. Mitigation: manual promotion via curator action; future enhancement could auto-promote info-priority messages above a threshold.

## Dependencies

- AKB Phase-1 build operational (per `akb-awareness-layer.md`, `akb-reasoning-independence.md`, `akb-lifecycle.md`)
- PostgreSQL + pgvector `akb.*` schema deployed (per AKB-SPEC CD16; v0.2 said ClickHouse — superseded by Judge ruling 2026-06-07)
- Ingest pipeline implementing Phase A inference rules
- BGE-large-en-v1.5 embedding service on 9975
- `akb-mcp` server registered in agent MCP configs
- Tier 0 promotion mechanism (Bar B) functional via MCC (the Judge approval-window control plane on iam-1; supersedes the retired inbox-ui per memory `fiducial-mesh-mcc-built-2026-06-06`)

## Success Criteria

- **Bootstrap completes** without errors; `akb.curation_events` records `bootstrap-v1` with chunk count and **per-root corpus git-commit hashes** (one per canonical root per § C.1)
- **Inference accuracy ≥ 85%** measured by sample validation across ~20 random chunks
- **Cross-role chunk count ≤ 50** at bootstrap completion
- **All V*-RESULTS chunks flagged `violates_invariant=true`** with correct `invariant_class`
- **Tier 0 promoted** with Judge approval; first session-start delivery measured ≤ 1024 bytes
- **First Bar C review batch completed** by Patton's second session post-bootstrap
- **Phase E steady state reached**: new docs use `akb-doc` skill; no further migration work required

## References

- `planning/akb-awareness-layer.md` — Tier 0 + Tier 1 architecture (paths relative to this repo: `fiducial-mesh/spec/`)
- `planning/akb-reasoning-independence.md` — role projection, cross-role cap
- `planning/akb-lifecycle.md` — ingest model, promotion discipline, decay signals
- `planning/akb-review-trajectory.md` — five-round design review methodology
- `planning/AKB-SPEC.md` — formal AKB pillar spec (the contract this migration plan operationalizes)
- `planning/templates/akb-document-template.md` — canonical template
- `planning/REPO-SHAPE-DECISIONS.md` — fiducial-mesh-org repo shape diagnostic referenced from the path table rationale
- `ki7mt/ki7mt-ai-lab-devel/skills/akb-doc/SKILL.md` — invocation skill for new doc creation (lab-level skill, relocated by the 2026-06-06 reorg from the old `ionis-devel/shared-context/skills/` location); `.claude/skills/akb-doc/SKILL.md` is the per-host install fallback
- `fiducial-mesh/air/reports/AIR-002-day-of-stale-state.md` — F-7 hook-trigger-gap finding that grounds Phase A.1.5 + Open Question 8
