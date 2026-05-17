# PCS Adoption Plan — Repo Reorganization Before Plugin Development

**Status**: Planning / Draft v0.1
**Date**: 2026-05-17
**Owner**: KI7MT
**Contributors**: Bob (9975WX-side analysis)
**Related**:
- [pcs-spec](https://github.com/KI7MT/pcs-spec)
- [pcs-control-plane](https://github.com/KI7MT/pcs-control-plane)
- [pcs-registry](https://github.com/KI7MT/pcs-registry)
- [pcs-registry-demo](https://github.com/KI7MT/pcs-registry-demo)

---

## The thesis

Reorganize GitHub repos by clear separation of concerns **before** starting serious PCS plugin development. Plugins/skills/runbooks placed into a clean organizational structure are easier to maintain than ones retroactively migrated from convenient-at-the-time placement.

The reorganization itself isn't a refactor *for its own sake* — it's natural maturation of an organically-grown project. PCS adoption is the forcing function that makes the cleanup worth doing now.

---

## Current state — what grew organically

Some repos ended up where they did based on what was convenient at the time, not long-term fit:

- **`qso-graph/llm-stack`** — placed in qso-graph as part of early containerization learning. Actually a personal infrastructure stack pattern, not a public ham radio MCP. Reference implementation stays (it's useful), but personal deployments need their own home.
- **`IONIS-AI/ionis-devel`** — became a multi-agent shared workspace. Holds papers, planning notes, operational SOPs, profiles, CLAUDE.md, archived content, research artifacts. Worked early on for easy access; now mixing concerns that should be separated.
- **Operational work** (Ansible playbooks, daily ops, monitoring, ingest pipelines, release workflows) lives in scattered locations across the project tree.

This pattern was correct early on. As the project matures and PCS is being adopted, the unclear boundaries compound friction.

---

## Target state — three-way ops split + supporting cleanup

### Three operational repos, by area of concern

| Repo | Org | Visibility | Organizing axis | Scope |
|---|---|---|---|---|
| **`KI7MT/fleet-ops`** | KI7MT | Private | **Host** | Infrastructure — 4 hosts (9975WX, M3, EPYC, TrueNAS), Ansible, daily ops, monitoring, backups, VM lifecycle |
| **`IONIS-AI/ionis-ai-ops`** | IONIS-AI | Private | **Concern** | IONIS research operations — training, datasets, ingest pipeline, publishing (hamstats render) |
| **`qso-graph/qso-graph-ops`** | qso-graph | Public | **Concern** | Public ham radio MCP fleet operations — release, registry sync, spec upgrades, fleet-wide checks |

**Why different axes**: `fleet-ops` is inherently host-shaped (daily ops on 9975WX ≠ daily ops on TrueNAS). The product ops (`ionis-ai-ops`, `qso-graph-ops`) are concern-shaped because the work is logically organized by what it accomplishes; host affinity is a capability attribute, not an organizing axis.

### Supporting structural changes

| Action | Why |
|---|---|
| **NEW: `KI7MT/llm-stack`** | Personal LLM stack consolidation — M3 (training-first + future inference), 9975WX (Newton production), future hosts. Currently no unified home for personal deployments. |
| **STAYS: `qso-graph/llm-stack`** | Public reference implementation for community. Different audience, different purpose from personal deployments. |
| **NEW: `KI7MT/research-papers`** | Papers/publications are authored work outputs, not coordination artifacts. Cleaner under personal KI7MT scope until decided otherwise. |
| **REFINED: `IONIS-AI/ionis-devel`** | Becomes meta-layer: profiles, vocabulary, cross-project runbooks, planning notes, shared agent context. Slims from current "dumping ground" shape. |

### ionis-devel post-cleanup shape

```
ionis-devel/
├── pcs.yaml                # Optional — declares as PCS meta-project (profiles + vocab + cross-project runbooks)
├── profiles/               # Node + agent profiles
│   ├── nodes/              #   9975wx, m3, epyc, truenas
│   └── agents/             #   bob, watson, patton, einstein, newton
├── vocabulary.yaml         # Shared capability names
├── planning/               # Active planning notes (this doc, PCS discussion, V22 roadmap, etc.)
├── shared-context/         # Cross-agent shared docs
├── runbooks/               # Cross-project PCS runbooks (when ready)
├── archive/                # Historical planning (already organized)
├── resources/              # Test paths, version history, reference data
├── contests/               # Per-contest analysis (informs next contest)
└── CLAUDE.md               # Project root context
```

---

## Per-host LLM stack structure (for `KI7MT/llm-stack`)

```
llm-stack/
├── README.md
├── hosts/
│   ├── 9975wx/                   # Newton: Llama 3.3 70B Q5_K_M, llama.cpp CUDA, RTX PRO 6000
│   ├── m3/                       # If/when M3 serves LLMs (metal backend)
│   └── (RTX 5080 stays in qso-graph/llm-stack as public reference)
├── shared/                        # configs/scripts/prompts used across hosts
└── ansible/                       # (optional, later) — Ansible-driven deploys
```

Hardware inventory (2026-05-17):
- **RTX 5080 / 16 GB** — Blackwell, runs 7B class (Qwen 7B Q5_K_M @ 138 tok/s, 6.4 GB VRAM). Reference impl in qso-graph.
- **9975WX / RTX PRO 6000 / 96 GB** — Newton (Llama 3.3 70B Q5_K_M @ 30 tok/s, ~57 GB VRAM used)
- **M3 Ultra / 96 GB unified MPS** — training-first; could serve 70B via metal

Future: an `llm-routing` plugin in PCS that routes queries to the right tier (heavy / light / training-handoff) based on declared capabilities.

---

## Migration order

**Principle: forward-only, by natural opportunity.** Don't refactor all 33 repos at once.

### Phase 1 — Org-level repo setup (one-time, ~30 min)

1. Create `KI7MT/fleet-ops` (empty: just `README.md` + `pcs.yaml` + `plugins/`)
2. Create `IONIS-AI/ionis-ai-ops` (empty same shape)
3. Create `qso-graph/qso-graph-ops` (empty same shape)
4. Create `KI7MT/research-papers` (empty: `README.md` + `papers/`)
5. Create `KI7MT/llm-stack` (empty: `README.md` + `hosts/` + `shared/`)

**Gate before proceeding**: Watson/control-plane confirms an empty PCS project (just `pcs.yaml` + `plugins/`, no actual plugin contents) passes validation. If not, file a CLCA cycle on pcs-spec before any plugin work.

### Phase 2 — Pilot plugin

Single skill, single repo, lowest risk:

`fleet-ops/plugins/9975wx-daily/skills/morning-health-check.yaml`

Why this one:
- Pure read-only (`effect: pure`)
- Daily value (run it every session start)
- Forces real audit log usage
- Composes existing checks (disk, GPU, ClickHouse, timers, backups, fleet versions, ingest currency)
- Failure surfaces wouldn't take down anything important — pure observation

Run it daily for a week. **Decide based on signal**: real win → fan out to Phase 3. Ceremony tax → keep PCS for new greenfield work only.

### Phase 3 — Incremental migration (long-running)

When natural opportunity arises (touching the affected files for unrelated reasons), pull content into the new structure:

| From | To |
|---|---|
| `ionis-devel/papers/*` | `KI7MT/research-papers/papers/*` |
| Scattered llm-stack content | `KI7MT/llm-stack/hosts/*/` |
| Scattered Ansible playbooks | `KI7MT/fleet-ops/plugins/ansible/` |
| Daily ops scripts (any host) | `KI7MT/fleet-ops/plugins/<host>-daily/` |
| Release workflows (MCP fleet) | `qso-graph/qso-graph-ops/plugins/release/` |
| Registry sync work | `qso-graph/qso-graph-ops/plugins/release/` |
| Dataset workflows | `IONIS-AI/ionis-ai-ops/plugins/datasets/` |
| Training workflows | `IONIS-AI/ionis-ai-ops/plugins/training/` |
| Ingest pipelines (operational SOPs) | `IONIS-AI/ionis-ai-ops/plugins/ingest/` |
| Ham-stats publishing | `IONIS-AI/ionis-ai-ops/plugins/publishing/` |

### Phase 4 — Per-repo PCS adoption (opt-in, long-running)

Existing code repos (MCPs, ionis-apps, ionis-cuda, etc.) opt into PCS governance individually. Each gets its own `pcs.yaml` + per-repo plugin describing its OWN release/test/governance flow.

Forward-only. Not all repos need to adopt at once. Some may never need to.

---

## The sequencing principle (non-negotiable)

**No PCS plugin development on production surfaces until Phase 1 is complete.**

Why: plugins placed into a clean structure are easier to maintain than plugins retroactively migrated. The 30 minutes spent in Phase 1 saves N hours of "where should this live?" friction over months of development.

**After Phase 1**: pilot one plugin (Phase 2), evaluate, then proceed incrementally with Phases 3 and 4 as natural opportunity arises.

---

## What this plan deliberately doesn't do

- **No synthetic refactor commits.** Content moves when touched for other reasons.
- **No forced PCS adoption on existing repos.** Per-repo adoption is opt-in. MCP servers don't need PCS to keep shipping; PCS is layered on, not migrated to.
- **No big-bang reorganization.** Each phase is independent. Phase 1 makes Phase 2 possible; Phase 2 generates signal that decides if Phase 3 happens at all.

---

## The bigger maturity pattern this surfaces

This is the latest in a series of maturity passes:

| When | What | Reason |
|---|---|---|
| 2026-03 | Consolidated 13 MCP servers under qso-graph org | Public-facing identity, single org for community discovery |
| 2026-05-15/16 | Fleet `get_version_info` rollout + ADIF 3.1.7 + registry sync pilot | Standardized version reporting, made stale-registry visible |
| 2026-05-17 (this plan) | Three-way ops split + repo cleanup | PCS adoption forcing function; clarity before plugin development |

Each step was a "convenience now → structure later" maturity pass. None of them were defects — they were healthy growth. The pattern itself is the deliverable: ship organically, recognize the seams, restructure when seams matter.

---

## Cross-references

- Memory: `project_pcs_contribution_flow.md` (Bob's contribution lanes, dev flow with inbox-mediated Watson review)
- Memory: `project_pcs_api_vm.md` (the EPYC API deployment for pcs-registry)
- Memory: `project_get_version_info_rollout.md` (the existing MCP fleet sync work)
- pcs-spec docs:
  - `01-principles.md` (the binding constraints + IP boundary)
  - `02-plugin-structure.md` (the canonical project layout)
  - `05-execution-profile.md` (node + agent + project context)
- Watson's inbox message 2026-05-15 (`544966c4-9927-489c-9364-5bd5199d5c74`) — PCS heads-up that triggered this conversation

---

## Open questions

| Question | Resolution path |
|---|---|
| Does the control plane accept a PCS project with zero plugins (only profiles + vocab)? | Test on `ionis-devel` if/when it gets `pcs.yaml`. If rejected, file CLCA on pcs-spec. |
| How are cross-host runbooks (step A on M3, step B on EPYC, step C on 9975WX) expressed in v0.1? | Likely a v0.2 spec extension. Workaround in v0.1: wrap each cross-host step as a separate skill with `effect: mutate_external` and a remote target. Bob to draft real example as it surfaces during dogfooding. |
| How are scheduled (cron/systemd) executions expressed? Spec assumes agent-invoked. | Open spec gap. Bob to propose extension (treat scheduler as an agent with limited authority, OR add `scheduled` execution mode) once first cron-driven runbook is needed. |
| Should `ionis-devel` get a `pcs.yaml`? | Yes — declare as PCS meta-project with no plugins. Clean semantics. (Pending control-plane confirmation per first open question.) |
