# 11 — Procedures

Version: 0.2 | Status: Draft

A procedure is a reusable invocation pattern — the operational
knowledge layer that skills compose against. Procedures encode how
to invoke a tool, handle authentication, manage environment state,
or execute a recurring operational pattern. They are the foundation
that domain skills build on.

**Procedures are substrate-aware** (Principle 10). Unlike skills,
procedures may reference specific shells, tools, and execution
mechanisms. This is intentional — procedures are the layer where
substrate-aware operational knowledge is encoded once, so that skills
don't have to carry it. The litmus test (01-principles.md) applies
to skill fields, not procedure fields.

This is the layered architecture mature systems converge to: Python
has `stdlib` underneath domain packages; Linux has `libc` underneath
applications; mature operations have a foundation plugin underneath
domain plugins. PCS names this pattern explicitly.

---

## Why Procedures Exist

Without procedures, operational knowledge gets duplicated across
skills. Every skill that calls `gh` needs to know about org-specific
PATs. Every skill that commits needs to handle GPG signing. Every
skill that queries ClickHouse needs the connection string.

At 10 skills, this duplication is tolerable. At 50, it dominates.
At 100+, it's unmanageable — updates to shared patterns (new auth
flow, new tool version, new environment variable) require touching
N skills.

Procedures solve this by encoding the operational knowledge once:

- **Without procedures:** 15 skills each contain "set GITHUB_TOKEN,
  unset GH_TOKEN, call gh with org pat" inline
- **With procedures:** 15 skills declare `uses_procedures: [gh-with-org-pat]`,
  one procedure encodes the invocation pattern

---

## Procedure Spec

```yaml
name: gh-with-org-pat
version: "0.1.0"
owner: bob
description: "Invoke gh CLI with org-specific PAT, suppressing keyring token"
effect: mutate_external
parameters:
  - name: org
    type: string
    required: true
    description: "GitHub organization (e.g., KI7MT, IONIS-AI, qso-graph)"
  - name: gh_args
    type: list[string]
    required: true
    description: "Arguments to pass to gh"
invocation:
  shell: bash
  template: |
    GITHUB_TOKEN= GH_TOKEN="$(cat ~/.config/gh-tokens/${org}.pat)" gh ${gh_args}
output_shape:
  type: string
  description: "Raw gh CLI output"
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | `^[a-z][a-z0-9_-]*$`. Must match filename. |
| `version` | string | Semver. |
| `owner` | string | Maintainer of record. |
| `description` | string | What this procedure does. |
| `effect` | enum | `pure` \| `mutate_local` \| `mutate_external`. **Required** — no default. Authors must declare the procedure's side-effect profile explicitly. |
| `parameters` | list | Typed parameters the procedure accepts. |
| `invocation` | object | How the procedure is executed. |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `output_shape` | object | JSON Schema for the procedure's output. |
| `requires_capabilities` | list[string] | Capabilities needed (same as skills). |

---

## Invocation

The `invocation` object declares how the procedure executes:

```yaml
invocation:
  shell: bash                    # or: python, sh, any interpreter
  template: |                    # template with ${parameter_name} substitution
    command --flag ${param}
  working_dir: null              # optional: override working directory
  timeout_seconds: 30            # optional: execution timeout
```

### Working Directory

If `working_dir` is unset, the procedure inherits the working
directory of the invoking skill. Authors should set `working_dir`
explicitly for procedures whose behavior depends on filesystem state
(e.g., `git-commit-no-sign` must run in the target repo directory).

### Template Substitution and Security

The template uses `${parameter_name}` for substitution from the
declared parameters. The control plane validates that all referenced
parameters are declared in the `parameters` list.

**Substitution rules:**

- Parameters are **shell-quoted by default** — the control plane
  wraps each substituted value in single quotes to prevent shell
  injection. A parameter set to `'; rm -rf / #` is safely quoted.
- Procedures that need unquoted parameters (e.g., for glob expansion
  or variable interpolation) use the explicit syntax `${param:raw}`.
- The control plane validates that `raw` substitutions are documented
  in the procedure's description with a justification.
- The `raw` modifier is an explicit opt-out of safety, not a default.

---

## Skills Reference Procedures

Skills declare which procedures they use:

```yaml
# In a skill spec
name: tag-and-push
version: "0.1.0"
owner: bob
lifecycle_state: active
trust_tier: blessed
effect: mutate_external
is_idempotent: false
uses_procedures:
  - gh-with-org-pat
  - git-commit-no-sign
  - tag-repo-explicit-target
requires_capabilities:
  - git_write_access
```

The control plane validates that every referenced procedure exists
in the same plugin or in a declared foundation plugin.

---

## Foundation Plugin Pattern

A foundation plugin provides the operational stdlib that domain
plugins compose against:

```
plugins/
├── fleet-ops-core/            # Foundation plugin
│   ├── plugin.yaml
│   └── procedures/
│       ├── gh-with-org-pat.yaml
│       ├── git-commit-no-sign.yaml
│       ├── tag-repo-explicit-target.yaml
│       ├── clickhouse-query.yaml
│       └── ssh-to-host.yaml
├── mcp-fleet/                 # Domain plugin (composes against core)
│   ├── plugin.yaml
│   ├── skills/
│   │   ├── fleet-test.yaml
│   │   └── version-rollout.yaml
│   └── procedures/            # Plugin-local procedures (if any)
│       └── ...
```

Domain plugins declare their foundation dependency with version
pinning:

```yaml
# In plugin.yaml
name: mcp-fleet
version: "0.1.0"
owner: bob
description: "MCP server fleet management"
depends_on:
  - name: fleet-ops-core
    version: "0.1.0"            # Exact version required
```

The control plane validates that foundation plugins exist at the
declared version and that all referenced procedures resolve.

---

## Directory Layout

Procedures live alongside skills and runbooks in the plugin directory:

```
plugins/<name>/
├── plugin.yaml
├── skills/
├── runbooks/
├── procedures/                 # NEW
│   ├── <procedure-name>.yaml
│   └── ...
├── bodies/
└── tests/
```

---

## Procedure Lifecycle and Trust Tiers

Procedures follow the same lifecycle and trust tier model as skills
(see 06-lifecycle.md).

**Trust tier inheritance rule:** A skill's effective trust tier is
bounded by its least-trusted procedure:

```
effective_skill_trust = min(declared_skill_tier,
                           min(procedure_tier for each used procedure))
```

A `blessed` skill that uses an `experimental` procedure has effective
trust `experimental`. The control plane treats it as `experimental`
for tier gating. This mirrors the runbook trust-tier-inheritance rule
from 04-runbook-spec.md.

---

## Cross-Plugin Procedure Sharing

Procedures can be shared across plugins through the foundation plugin
pattern. A domain plugin references another plugin's procedures via
`depends_on` in its `plugin.yaml`. The control plane resolves
procedure references by searching:

1. The skill's own plugin `procedures/` directory
2. Any plugins declared in `depends_on`

Resolution order is explicit — no implicit search path.

**In v0.2, procedure resolution is project-scoped.** Foundation
plugins must exist within the same project tree as the domain plugin
that references them. Cross-project procedure sharing is planned for
a future version, likely as a source type in the registry's
`pcs-registry.yaml`.

---

## What the Control Plane Validates

| Check | Rule |
|-------|------|
| Procedure schema valid | All required fields present, parameters typed, `effect` declared |
| Procedure name matches filename | Byte-identical, same as skills |
| Template references valid | All `${param}` in template match declared parameters |
| Raw substitutions documented | Any `${param:raw}` must be justified in description |
| Skill procedure references resolve | Every `uses_procedures` entry exists in the resolution path |
| Foundation dependency exists | Every `depends_on` plugin exists in the project at declared version |
| Trust tier compatibility | Effective skill tier = min(declared, min(procedure tiers)) |
| Working directory explicit | Warning if `mutate_local` procedure has no `working_dir` |
