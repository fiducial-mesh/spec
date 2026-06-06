# Repo + Plugin Ownership Matrix

**Status**: **v1.0 — approved by KI7MT + Watson (2026-05-17)**
**Date**: 2026-05-17
**Authors**: KI7MT (intent + approval), Bob (drafting), Watson (review + approval)
**Related**:
- [PCS Adoption Plan](https://github.com/fiducial-mesh/spec/blob/main/planning/PCS-ADOPTION-PLAN.md)
- [Agent Friction Catalog](AGENT-FRICTION-CATALOG.md)
- [Workspace Consistency Rationale](WORKSPACE-CONSISTENCY-RATIONALE.md)

---

## Why this exists

Before any serious PCS plugin development starts, we need clear ownership boundaries — who can write what, who reviews what, who tags releases, who deploys. Without explicit boundaries, the dumping-ground pattern repeats at a different layer.

This is the canonical assignment doc. Future-Bob, future-Watson, future-anyone reads this when ambiguity surfaces.

---

## Three layers of ownership that must align

| Layer | Mechanism | Declares |
|---|---|---|
| **Agent capabilities** | PCS agent profile (e.g., `profiles/agents/bob.yaml`) | What this agent is *allowed* to do |
| **Repo write authority** | GitHub CODEOWNERS + branch protection | Who can merge/review at the git layer |
| **Plugin authorship** | `owner` field per skill/runbook (PCS spec v0.1) | Who maintains a specific artifact |

If all three align, no agent crosses up. If they drift, you get organizational chaos at a new layer.

---

## Per-repo ownership matrix

### PCS framework repos (KI7MT scope)

| Repo | Primary owner | Cross-review | Notes |
|---|---|---|---|
| `spec` | **Watson** (architecture) | Bob (operator feedback), Patton (structural) | KI7MT final authority on spec direction |
| `som-pcs-control-plane` | **Watson** (implementation) | Bob (dogfood reports) | Watson coded it |
| `som-pcs-registry` | **Watson** (implementation) | Bob (dogfood reports) | Watson coded it |
| `pcs-registry-demo` | **Watson** (demo content) | Bob | Community-facing, public reference |

### Operations repos (three-way split)

| Repo | Org | Primary owner | Cross-review | Notes |
|---|---|---|---|---|
| `fleet-ops` | **KI7MT** (confirmed 2026-05-17) | **Bob** (9975WX + ops across 4 hosts) | KI7MT | Fleet-wide infrastructure spans IONIS-AI *and* qso-graph projects — sits in KI7MT substrate scope, not project scope. EPYC Proxmox VM lifecycle is the one boundary case (could be Watson or Bob depending on workload) |
| `ionis-ai-ops` | IONIS-AI (private) | **Mixed — see sub-plugin ownership below** | Cross-review required on whole repo | Largest ambiguity zone |
| `qso-graph-ops` | qso-graph (public) | **Bob** (fleet maintenance) | Patton (structural review for public artifacts) | Public visibility — release/spec-upgrade work |

### `ionis-ai-ops` sub-plugin ownership

The mixed-ownership zone needs per-plugin clarity:

| Plugin | Primary owner | Cross-review |
|---|---|---|
| `training/` | Watson (M3, PyTorch, MPS — training is Watson's lane) | Bob if data-pipeline integration |
| `datasets/` | Bob (ClickHouse → SQLite → SourceForge — data pipeline ops) | Watson if downstream training impact |
| `ingest/` | Bob (WSPR/PSKR/RBN/contest/solar ingest pipelines) | — |
| `publishing/` | Bob (ham-stats render, ionis-docs build) | Watson if predictions content involved |

Rule of thumb: **whoever operates the host where the work runs is the primary owner.** Cross-review surfaces when a change affects the other's domain.

### Meta layer

| Repo | Org | Primary owner | Cross-review | Notes |
|---|---|---|---|---|
| `ionis-devel` | IONIS-AI | **KI7MT** (final approver) | All agents *read*; KI7MT approves writes | Profiles, vocab, cross-project runbooks, planning notes — the meta-coordination layer |

### Cross-project runbooks (special case)

Lives in `ionis-devel/runbooks/`. These compose skills from multiple ops repos (e.g., "release new ionis-mcp" = qso-graph publish + IONIS dataset pin bump).

- **Author**: Co-authored when domain expertise spans. Primary = whoever owns the more critical step. KI7MT-only for meta-layer runbooks (profiles, vocabulary, cross-project coordination).
- **Constituent skills come from**: their respective domain repos
- **Approval gate**: explicit KI7MT sign-off (these touch both products)
- **Review**: Patton (structural), Watson (if research-side impact), Bob (if fleet-side impact)

> **Note on foundation plugins (PCS v0.2 constraint)**: per the project-scoped sharing rule in `spec/spec/11-procedures.md`, foundation plugins must live within the same project tree as the domain plugins that depend on them. Each ops repo gets its own foundation plugin (`fleet-ops-core`, `ionis-ai-ops-core`, `qso-graph-ops-core`). Cross-project procedure sharing is deferred to a future spec version. The three-way ops split is consistent with this — each ops repo is self-contained at the framework level.

### Product repos (per-repo, opt-in)

| Repo group | Primary owner | Notes |
|---|---|---|
| MCP servers (13 in qso-graph + agent-inbox-mcp + adif-mcp) | **Bob** (release maintenance, CI, PR workflow) | Patton audits security; established last week during fleet rollout |
| ionis-apps, ionis-cuda, ionis-core | **Bob** (Go + CUDA + DDL — fleet runs them) | Watson if model-training integration |
| ionis-mcp | **Bob** (PyPI release, dataset pinning) | Watson if research-output content |
| ionis-training | **Watson** (model training is M3-side) | Bob if data-pipeline integration |
| ionis-validate | **Watson** (model validation harness) | Bob (test path infrastructure) |
| ionis-jupyter | **Watson** (research notebooks) | — |
| ionis-docs, ionis-hamstats | **Bob** (publish workflows on 9975WX) | Watson if predictions content |

### Personal/new repos (KI7MT scope)

| Repo | Owner | Notes |
|---|---|---|
| `research-papers` (new, private) | **KI7MT** (authored work) | Agent contributions credited inline |
| `qso-graph/llm-stack` (exists) | **KI7MT** with Bob assisting | Already public at qso-graph since 2026-03-13 — keep as-is |
| `agent-inbox` (public MIT) | **KI7MT** | Already public, established |
| `inbox-ui` (Wails desktop) | **KI7MT** with Bob assisting | Personal tooling |

---

## Agent capabilities (proposed profile content)

Sketches of what each agent profile would declare. Final profiles get authored in `ionis-devel/profiles/agents/`.

### Bob (9975WX, Claude Code)

```yaml
agent: bob
host_affinity: 9975wx
max_trust_tier: blessed
provides:
  - 9975wx_admin
  - clickhouse_query_execute
  - mcp_fleet_release
  - mcp_fleet_registry_sync
  - data_pipeline_ops
  - daily_ops_check
  - ansible_run_playbook
  - cross_host_dac_link
  - sourceforge_upload
  - copr_build_trigger
  - pypi_publish_trigger
  - github_pr_merge_qso_graph
  - github_pr_merge_ionis_ai_ops
authorized_repos:
  primary:
    - qso-graph/*
    - IONIS-AI/ionis-ai-ops (plugins/datasets, plugins/ingest, plugins/publishing)
    - KI7MT/fleet-ops  # fleet-wide infra, KI7MT substrate scope
  cross_review:
    - IONIS-AI/ionis-devel
```

### Watson (M3, Claude Code)

```yaml
agent: watson
host_affinity: m3
max_trust_tier: blessed
provides:
  - m3_admin
  - training_execution
  - mps_backend
  - pcs_spec_authoring
  - pcs_control_plane_implementation
  - pcs_registry_implementation
  - jupyter_notebook_execute
  - paper_drafting
authorized_repos:
  primary:
    - KI7MT/pcs-* (all four PCS repos)
    - IONIS-AI/ionis-training
    - IONIS-AI/ionis-validate
    - IONIS-AI/ionis-jupyter
    - IONIS-AI/ionis-ai-ops (plugins/training, plugins/publishing predictions)
  cross_review:
    - IONIS-AI/ionis-devel
    - KI7MT/research-papers
```

### Patton (M3, Claude Desktop)

```yaml
agent: patton
max_trust_tier: core
provides:
  - structural_review
  - failure_analysis
  - security_audit
  - clca_cycle_authoring
authorized_repos:
  primary:
    - (review-only on all repos)
  cross_review:
    - All repos
```

### Einstein (Cloud, Gemini)

```yaml
agent: einstein
max_trust_tier: blessed
provides:
  - conceptual_review
  - physics_validation
  - architecture_review
authorized_repos:
  primary:
    - (review-only)
  cross_review:
    - KI7MT/spec (architecture review)
    - IONIS-AI/ionis-devel (physics/architecture content)
```

### Newton (9975WX, local llama)

```yaml
agent: newton
host_affinity: 9975wx
max_trust_tier: community
provides:
  - local_inference
  - mcp_tool_relay
authorized_repos:
  primary:
    - (read-only at present)
```

### Judge (KI7MT, human)

```yaml
agent: judge
max_trust_tier: core
provides:
  - all_capabilities
authorized_repos:
  primary:
    - All repos
  notes:
    - Final approver on cross-project runbooks
    - Approves promotion to `blessed` and `core` trust tiers
    - Sole authority on KI7MT scope repos
```

---

## Pre-launch checklist (before any plugin development)

Once these decisions are confirmed (Watson reviews and replies):

1. **Author agent profiles** in `ionis-devel/profiles/agents/`. Each agent gets a YAML file declaring `provides` capabilities, `max_trust_tier`, and authorized scope.
2. **Author node profiles** in `ionis-devel/profiles/nodes/`. 9975WX, M3, EPYC, TrueNAS. Each declares hardware capabilities.
3. **Author vocabulary.yaml** in `ionis-devel/`. Shared capability names referenced across profiles + skills.
4. **Create empty target repos** per the PCS Adoption Plan (fleet-ops, ionis-ai-ops, qso-graph-ops, research-papers, llm-stack).
5. **Set CODEOWNERS** in each repo aligning git-layer enforcement with PCS profile declarations.
6. **Pilot first plugin** (`morning-health-check` per the PCS Adoption Plan).
7. **Iterate** as ambiguity surfaces. Update this matrix as the authoritative reference.

---

## Resolved questions (Watson reply 2026-05-17, msg `70808656`)

1. **fleet-ops org scope** → **IONIS-AI** (private operational infra fits alongside ionis-ai-ops and qso-graph-ops). KI7MT personal scope stays for substrate/personal tools (PCS, agent-inbox, llm-stack).
2. **ionis-ai-ops sub-plugin split** → **agreed as proposed**. "Whoever operates the host where the work runs is primary" is the durable rule. Training → Watson (M3/MPS); datasets/ingest/publishing → Bob (9975WX/ClickHouse); cross-review on publishing when predictions content is involved.
3. **Cross-project runbook authorship** → **co-authored when domain expertise spans**. Primary = whoever owns the more critical step. KI7MT-only for meta-layer runbooks (profiles, vocabulary, cross-project coordination).
4. **Trust tier `blessed` for both** → **agreed**. Production-operational, not yet `core` load-bearing. Promote to `core` when operational history justifies it.
5. **Missing from profiles** → **nothing missing**. Ready to become real YAML in `profiles/agents/`.

---

## What this enables

When this lands and the profiles are authored:

- **Bob can answer** "is this skill in my lane?" by checking `authorized_repos.primary`
- **Watson can answer** "should I review this Bob PR?" by checking `cross_review`
- **Future agents** added to the project inherit clear scope from day one
- **CODEOWNERS** at the git layer enforces the same boundaries automatically
- **PCS profiles** at the framework layer reason about capability boundaries the same way
- **Audit log** can show "Bob acted within his declared scope" or flag scope violations

The matrix is the *durable answer* to who-owns-what, so the dumping-ground pattern doesn't repeat at the ops-repo layer.
