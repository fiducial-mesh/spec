# Agent Friction Catalog — The Empirical Case for the Procedure Layer

**Status**: Draft v0.1
**Date**: 2026-05-17
**Authors**: KI7MT (methodology), Bob/Claude-9975 (session-derived evidence)
**Related**:
- [PCS Spec v0.1](https://github.com/KI7MT/som-pcs-spec)
- [PCS Adoption Plan](https://github.com/KI7MT/som-spec/blob/main/planning/PCS-ADOPTION-PLAN.md)
- Memory: `project_pcs_contribution_flow.md`

---

## The methodology

> *"What this is, is spending hours and hours with agents and watching what trips them up."* — KI7MT, 2026-05-17

The PCS spec wasn't designed from first principles. It was discovered through observation: many sessions, many agents, many real tasks, with one observer noting *the patterns of failure that recur regardless of model or domain*.

That observational methodology is the methodology. The friction catalog below is one session's worth of evidence — Bob/Claude-9975 working on KI7MT's project for ~8 hours of cross-repo operational work — but the patterns it surfaces aren't unique to this session, this agent, or this project.

---

## The friction catalog (one session, ~8 hours, real operational work)

Errors observed during the May 17, 2026 session covering: fleet `get_version_info` rollout, ADIF 3.1.7 upgrade, MCP Registry sync pilot, PCS adoption planning. Cross-repo, cross-org, multi-stage CI/PR/tag/publish workflows.

| # | Error class | Concrete manifestation | Tokens/time cost |
|---|---|---|---|
| 1 | **CWD persistence** | Tagged `v0.1.5` on `IONIS-AI/agent-inbox-mcp` instead of `qso-graph/n1mm-mcp` because `cd` from previous command didn't persist | Destructive rollback (tag deletion local + remote) + user authorization required |
| 2 | **Env var shadowing** | `gh` CLI used stale `GITHUB_TOKEN` env var instead of keyring; 401 errors despite valid keyring token | Multiple retries before diagnosis |
| 3 | **Per-org PAT scoping** | Fine-grained PATs don't span GitHub orgs; discovered by hitting 404s on cross-org operations | 3 sequential failures while building org-specific PATs |
| 4 | **PAT permission discovery** | Pull requests: Write missing, then Workflows: Write, then Contents: Write — each discovered sequentially through failures | 3-4 retries with permission updates between each |
| 5 | **GPG signing TTY** | `agent-inbox-mcp` had no local `commit.gpgsign=false` override; GPG agent couldn't prompt for passphrase in non-interactive shell | Required user authorization to set local override |
| 6 | **Subagent-guard regex false positive** | Branch `feature/get-version-info` contains `-f` substring; hook flagged as force-push pattern | One blocked operation, command restructure |
| 7 | **Ruff E501** | Adding `"3.1.7"` to allowed set pushed line 11 to 99 chars (cap: 95) | CI failure, manual fix |
| 8 | **Missing manifest schema** | `validate-manifest` CLI broken on `main` since unrelated commit removed `resources/schemas/` | Archaeology + restoration before adoption could proceed |
| 9 | **Read-before-Edit** | Multiple `Edit` tool calls failed because file not yet read in session | 4-5 minor retries across the session |
| 10 | **Bash parallel cancellation** | When first command in parallel batch fails, all others cancelled; effective concurrency lost | 2-3 instances of "retry serially" |
| 11 | **Stale CWD across commands** | Caught after the wrong-tag incident; never trust `cd` to persist in Bash tool sessions | Required deliberate restructure of all subsequent commands |
| 12 | **Silent gh auth failures** | gh CLI returned empty output on auth issue — looked like success, was actually silent failure | Diagnosis cycle |
| 13 | **Token leak protection** | Manually unsetting `GITHUB_TOKEN` in front of each gh invocation | Friction tax on every command |
| 14 | **Org URL casing** | `IONIS-AI/ionis-devel` failed with "could not resolve" before realizing PAT scope, not casing | Diagnostic cycle |
| 15 | **MCP registry stale data** | All 13 servers showed pre-rollout versions in registry; discovered registry doesn't auto-sync from PyPI | Real bug, but surfaced through diagnostic friction |

**Subtotal**: ~15 distinct error classes in one session. Each cost 30 seconds to several minutes of agent + operator time. Aggregate session-level cost: estimated 30-45 minutes of pure friction.

---

## Pattern recognition

The errors above cluster into structural categories:

| Category | Errors | Root cause |
|---|---|---|
| **Authentication / token management** | 2, 3, 4, 13 | Each org/scope has different auth requirements; agent reconstructs from scratch each time |
| **Environmental state assumptions** | 1, 9, 10, 11 | Agent assumes shell state (cwd, env, prior tool reads) persists when it doesn't |
| **CI/CD permission discovery** | 4 | No declarative "this workflow needs these PAT permissions" — discovered by failure |
| **Tooling syntax/limit reconstruction** | 7, 14 | Agent reconstructs lint rules, naming conventions, casing rules on each invocation |
| **Cross-system stale state** | 8, 15 | One system's state (PyPI) doesn't propagate to another system (MCP Registry, schema files in repo) |

Every one of these is **preventable by a procedure** that encodes the operational knowledge once and is referenced by all skills that need it.

---

## The procedure-layer proposal

Each error class maps directly to a procedure that would have prevented it:

| Error class | Procedure that prevents it |
|---|---|
| CWD persistence | `procedure: tag-repo-explicit-target` — requires explicit repo path arg, never infers from cwd |
| Env var shadowing | `procedure: gh-with-org-pat` — wraps `GITHUB_TOKEN= GH_TOKEN=$(cat ~/.config/gh-tokens/<org>.pat) gh ...` |
| Per-org PAT scoping | `procedure: gh-org-pat-lookup` — fails fast with clear error if PAT for target org missing |
| PAT permission gaps | `procedure: gh-pre-flight-pat` — checks PAT capabilities against operation requirements before executing |
| GPG signing TTY | **Resolved at the substrate layer** (2026-05-17) via `~/.gitconfig` `includeIf` overriding `commit.gpgsign=false` for each host's `$WORKSPACE_ROOT/`. No procedure needed once the includeIf is in place. Procedure `git-commit-no-sign` is still useful as a defensive backup if the includeIf is ever missing (fresh host, etc.). |
| Subagent-guard regex | `procedure: safe-branch-name` — validates branch names against subagent-guard regex |
| Ruff E501 | `procedure: ruff-pre-check` — runs ruff before commit (already a CI gate; could be a pre-commit procedure) |
| Bash parallel cancellation | `procedure: safe-parallel-bash` — declares independence assumptions explicitly |
| Read-before-Edit | Tool wrapper enforcing the discipline (not strictly a procedure) |

Approximately **6-8 procedures** would eliminate ~80% of the errors observed in this session.

---

## The architectural pattern: foundation + domain

KI7MT's production setup at Oracle uses this pattern with the `jira-core` foundation plugin:

```
jira-core (foundation — operational stdlib for the service)
├── procedures/
│   ├── ssh-invoke
│   ├── oci-cli-call
│   ├── get-bearer-token
│   ├── jira-api-call
│   └── ... operational stdlib

Domain plugins (each uses jira-core procedures):
├── incident-response/
├── patching/
├── upgrades/
├── nginx-management/
└── observability/
```

The equivalent for the 9975WX work would be:

```
9975wx-core (or fleet-ops-core)
├── procedures/
│   ├── gh-with-org-pat
│   ├── tag-repo-explicit-target
│   ├── git-commit-no-sign
│   ├── safe-branch-name
│   ├── safe-parallel-bash
│   ├── clickhouse-query
│   ├── ssh-to-m3
│   ├── ssh-to-epyc
│   └── ssh-to-truenas

Domain plugins:
├── mcp-release/      (uses 9975wx-core procedures)
├── data-pipeline/    (uses 9975wx-core procedures)
├── daily-ops/        (uses 9975wx-core procedures)
└── incident-response/(uses 9975wx-core procedures)
```

This is the layered architecture mature systems converge to:

- Python: `stdlib` underneath domain packages
- Linux: `libc` underneath applications
- Mature ops: foundation plugin underneath domain plugins

---

## The PCS v0.1 gap

PCS v0.1 has Skills and Runbooks as first-class concepts. **Procedures as defined here — the reusable operational invocation knowledge layer — are not first-class in the spec.**

Today, this knowledge implicitly lives inside skill bodies, which produces:

- Operational knowledge duplicated across skills
- Updates to a shared procedure (new tool version, new auth flow) require touching N skills
- Token cost per skill invocation includes reconstruction of the invocation pattern
- New skills bootstrap by copy-paste from old skills (drift accumulates)

Without procedures, the framework cannot deliver its productivity dividend at scale. Below ~20 skills, this is invisible. Above ~50 skills, it dominates.

---

## Proposal: PCS v0.2 — Procedures as first-class

**Add to plugin directory layout**:

```
plugins/<name>/
├── plugin.yaml
├── procedures/           # NEW — operational stdlib
│   ├── <procedure-name>.yaml
│   └── ...
├── skills/               # Existing
├── runbooks/             # Existing
├── bodies/               # Existing
└── tests/                # Existing
```

**Procedure spec schema** (initial sketch):

```yaml
name: gh-with-org-pat
version: "0.1.0"
description: "Invokes gh CLI with the correct org-scoped PAT, unsetting stale env tokens"
parameters:
  - name: org
    type: string
    enum: [KI7MT, IONIS-AI, qso-graph]
    required: true
  - name: gh_args
    type: array
    items: string
    required: true
invocation: |
  GITHUB_TOKEN= GH_TOKEN="$(cat ~/.config/gh-tokens/${org}.pat)" gh ${gh_args}
output_shape:
  exit_code: integer
  stdout: string
  stderr: string
```

**Skills reference procedures**:

```yaml
# in a skill spec
uses_procedures:
  - gh-with-org-pat
  - git-commit-no-sign
```

**Control plane validation**:

- Verify all referenced procedures exist in the same plugin or are imported from another plugin
- Verify parameter passing matches procedure spec
- Procedures must pass schema validation independently

---

## Open design questions

1. **Cross-plugin procedure sharing**: should procedures defined in `9975wx-core` be referenceable from domain plugins? If yes, what's the import syntax? (e.g., `uses_procedures: [9975wx-core/gh-with-org-pat]`)
2. **Versioning**: should procedures use semver like skills, or follow a simpler "current-only" model?
3. **Trust tier**: do procedures have trust tiers, or do they inherit from the skill that invokes them?
4. **Composition**: can procedures call other procedures, or are they leaf-level only?

These are real design decisions for the v0.2 RFC, not blockers for filing the gap observation.

---

## Resumption semantics — a second v0.2 spec gap

### The failure mode

Agents don't always exit gracefully. Three real ways an agent can stop responding mid-runbook:

1. **Claude compaction** — token budget approaching limit, agent state is compressed; in-context memory partially degrades but session continues
2. **Codex filter wall** — safety filter triggers (often unpredictably on log patterns or unusual content); session is **forcibly terminated**; operator has to start fresh
3. **Platform-level termination** — model rotation, network drop, server crash, OOM on local llama — same effect as Codex wall but from the platform side

The first is graceful degradation. The latter two are involuntary mid-flight termination. **A production-grade framework must handle all three.**

### The connection to idempotency

Resumption semantics and idempotency are the same architectural problem viewed from different angles:

| Failure type | Same underlying question |
|---|---|
| Retry (skill failed, run again) | "Is it safe to repeat this operation?" |
| Resume (agent died, fresh agent picks up) | "Is it safe to repeat this operation when we don't even know if it completed?" |

**Resumption is retry-with-amnesia.** Same property (`is_idempotent`) determines safety; the resumption case is strictly harder because state is uncertain.

### Three states for any step on resumption

When a fresh agent inherits a runbook:

| Step state | What you know | What you can do |
|---|---|---|
| **Definitely completed** | Audit log shows success outcome | Skip, move to next |
| **Definitely not started** | No audit entry, no evidence | Execute normally |
| **Uncertain** (agent died DURING execution) | Attempt logged, no completion record | Depends entirely on idempotency |

### Resumption safety per mutation profile

| Effect + Idempotency | Resumption strategy |
|---|---|
| `pure` (always idempotent by definition) | Re-run blindly. Same input → same output. Safe. |
| `mutate_local` + `is_idempotent: true` | Re-run safely. May need cleanup of partial state. |
| `mutate_local` + `is_idempotent: false` | Need state query before retry. |
| `mutate_external` + `is_idempotent: true` | Re-run safely (idempotency key on server side dedupes). |
| `mutate_external` + `is_idempotent: false` | **Cannot blindly retry. Must verify external state OR hand off to human.** |

The last row is the danger zone. A PyPI publish, SourceForge upload, database INSERT without unique constraint, LoTW QSO submission — any non-idempotent mutate_external operation cannot safely be re-run without first checking actual completion state.

### Proposed v0.2 primitive: `verification_skill`

For non-idempotent mutate_external skills, pair them with a verification skill:

```yaml
name: write-contract-to-db
effect: mutate_external
is_idempotent: false
verification_skill: check-contract-in-db   # NEW in v0.2 proposal
```

The control plane's resumption logic:

1. Check audit log: was this step completed?
2. If completed → skip
3. If uncertain → invoke `verification_skill` to determine actual state
4. If verification says "already done" → skip
5. If verification says "not done" → execute
6. If verification cannot determine → hand off to human

### What v0.1 has vs. what resumption needs

**v0.1 has**:
- `is_idempotent` field
- Mutation profile classification
- `abort-illegal-after-mutate_external` rule
- Audit log emission

**v0.1 doesn't have** (gaps for resumption):
- Explicit "resumption" as a first-class operation (separate from voluntary `hand_off`)
- `verification_skill` reference pattern for non-idempotent operations
- Spec for how a fresh agent discovers it should resume vs. start fresh
- Convention for how runbook state is queried at resumption time
- Step-type for `kind: resume_checkpoint` or similar

These are v0.2 RFC candidates. **Good news**: the foundational property (`is_idempotent`) is already first-class. Resumption is built *on top of* idempotency, not orthogonal to it. The primitive was designed correctly; the resumption semantics layer just hasn't been formalized.

### Design discipline this implies for skill authors

| Rule | Why |
|---|---|
| Prefer pure where possible | Trivially resumable; no state to track |
| Prefer idempotent mutations | Idempotency keys, upserts, conditional writes — operation can repeat safely |
| For non-idempotent skills, pair with verification | Resumption case needs to query actual state |
| Externalize completion markers | Don't rely on "agent remembers it ran" — write to audit log or external state |
| Design for hand-off as the default | Compaction, filter walls, timeouts, model rotation all force hand-off involuntarily |

### Why this matters for cross-platform deployments

Multi-agent setups (Claude, Codex, Gemini, local llama) have different failure modes. Each platform has its own way of involuntarily terminating sessions:

- Claude: compaction, occasional hard timeouts
- Codex: filter walls (sudden, inscrutable)
- Gemini: safety filters, model rotation
- Local llama: server crashes, OOM, model swap

**From PCS's perspective, agent unavailability is agent unavailability.** The framework must be agnostic about why an agent stopped responding. Audit log + runbook state + evidence chain must be sufficient for any fresh agent on any platform to resume.

This is a stronger architectural commitment than v0.1 makes explicit. v0.1's `hand_off` semantics assume the previous agent is alive and explicit about transferring. Real operations require recovery from involuntary termination too.

---

## How this gets filed

This document is the source artifact. From here:

1. Send Watson an inbox message proposing the procedure layer + resumption semantics for PCS v0.2 — link to this doc
2. Open a discussion issue on `KI7MT/som-pcs-spec` referencing this evidence
3. Use the friction catalog as the "why this is needed" section of any RFC

---

## The methodology, in writing

The PCS spec is the distillation of hours of agents being watched.

- Watch what trips them up
- Categorize the patterns
- Build scaffolding that prevents the failure modes
- Repeat at higher scale

That's the methodology. It's the same shape as research science: hypothesis-free observation, pattern recognition, mechanism design.

KI7MT has been running this methodology informally for years across:
- 9975WX personal lab (33 repos, 60+ recurring tasks)
- Oracle production (65 servers, 100+ skills under ATAC, 12-15 plugin categories)
- Multiple agent platforms (Claude, Codex, Cline, Cursor)
- Multiple domains (incident response, patching, monitoring, dev workflows)

The PCS spec is one snapshot of what that methodology has produced. The procedure-layer observation in this document is another increment.

**Each hour of agent watching produces more spec evidence.** Save the observations; codify the patterns; tighten the framework.

---

## Addendum: Resolutions (2026-05-17, post-session)

Some friction items can be resolved at the substrate layer (host config, hook config, etc.) without requiring a procedure or a skill. Capturing these here because they're cheaper than the procedure approach when applicable.

### Error #5 — GPG signing TTY: resolved via `~/.gitconfig` `includeIf`

**What**: Project repos under each host's `$WORKSPACE_ROOT/` no longer attempt GPG-signed commits because `[commit] gpgsign = false` is inherited via a path-scoped include. Per-host roots: 9975WX `/home/ki7mt/workspace/`, M3 `/Users/gbeam/workspace/`.

**How** (9975WX — adjust the `gitdir:` path per host):

```ini
# ~/.gitconfig
[commit]
	gpgsign = true                          # default everywhere

[includeIf "gitdir:/home/ki7mt/workspace/"]
	path = ~/.gitconfig-ionis-ai

# ~/.gitconfig-ionis-ai
[commit]
	gpgsign = false                         # project-tree override
```

> `~/.gitconfig` `includeIf "gitdir:..."` does **not** env-expand — so the literal `WORKSPACE_ROOT` value has to be baked in per host. Manage via Ansible (`claude-configs.yml`) so any host provisioned for the project gets the right path automatically.

**Why this beats the per-repo override approach**:
- Set once, works for every future clone under the project tree
- No per-repo user authorization needed
- Hobby/upstream repos elsewhere continue to sign normally
- Discoverable: anyone reading `~/.gitconfig` sees the includeIf and the rationale (comment block)

**Long-term**: fold into `claude-configs.yml` Ansible playbook so any new host provisioned for the project gets the includeIf automatically. M3 already received a heads-up (Watson inbox `info` priority, 2026-05-17).

**Backup**: a `git-commit-no-sign` procedure is still worth authoring as a defensive primitive in case the includeIf is missing on a fresh host. Procedures cost nothing to keep available; the substrate fix is the *primary* line of defense.

### Pattern: prefer substrate fix over procedure when both are options

When friction surfaces, evaluate in this order:
1. **Substrate fix** — config, hook, environment. Solves the class entirely. Single point of maintenance.
2. **Procedure** — encodes the operational invocation. Solves the class but requires referencing in every skill.
3. **Skill body** — last resort. Solves only that skill; rest still hit the friction.

Friction #5 is the first documented case where substrate beat procedure cleanly.

### Error #16 — Chat → terminal trailing whitespace: resolved at the editor layer

**What**: Commands posted by Bob or Watson into the chat panel render with trailing whitespace when copied into the VS Code integrated terminal. Visual annoyance during agent ↔ operator handoff. Shells silently ignore the trailing spaces so it's not functionally broken, but it makes pasted commands look wrong and clutters terminal scrollback.

**Confirmed not fixable at the agent output layer** (2026-05-17 session). Tested four markdown formats — triple-backtick fenced, plain fenced, single-backtick inline, language-tagged fenced — all produced the same padding. It's terminal-side rendering, not source-side.

**Resolution**: operator-side fix in VS Code.
- Command palette: `Trim Trailing Whitespace`
- Settings: `editor.trimAutoWhitespace = true` (auto-strips on enter)
- Files-Save: `Files: Trim Trailing Whitespace On Save` (for file edits)

**Pattern**: not every friction has an agent-side fix. Some live at the operator's tooling. Document it so future agents don't waste effort trying to fix it at the wrong layer.

### Error #17 — Host-coupled absolute paths baked into code, configs, and unit files

**What** (2026-05-17 session): the 9975WX workspace flatten (`/mnt/ai-stack/ionis-ai/` → `/home/ki7mt/workspace/`) hit roughly 13 distinct surfaces of path coupling — each one was either a 30-second fix or a half-hour stumble. Categories include `~/.claude.json` MCP `command:` paths (13 refs), `.claude/settings.local.json` permission rules (6 refs), `~/.gitconfig` `includeIf` `gitdir:` (1), systemd unit `ExecStart` body (1), systemd `/etc/systemd/` symlinks (2), `~/.claude/projects/<slug>/` (1), `.venv/bin/*` console-script shebangs (100 scripts), `.venv/lib/*.pth` editable src paths (9), profile yaml paths (1), and doc tables of literal paths (multiple).

**Resolution**: a portability audit doc (`planning/PORTABILITY-AUDIT.md`) is planned but deferred until 9975 rebuild + PR #50 + fleet-test are all complete. Until then, per-surface fixes follow `$WORKSPACE_ROOT` env expansion where supported, per-host profile lookups (`profiles/nodes/<host>.yaml`) where not, and treat the venv as derived state (rebuild, don't migrate).

**Pattern**: pure `WORKSPACE_ROOT` substitution is not sufficient — some surfaces (gitconfig `gitdir:`, `~/.claude.json` MCP `command:`, systemd unit bodies) don't env-expand at the layer they consume the path, so they need template rendering at install time. Other surfaces (venv shebangs, `.pth` files, jupyter kernelspecs) are **derived state** — should be rebuilt on each host, not migrated.
