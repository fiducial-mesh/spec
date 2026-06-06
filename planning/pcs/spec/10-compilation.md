# 10 — Compilation

Version: 0.1 | Status: Draft

PCS skills are substrate-agnostic. Compilers translate canonical specs
into platform-native artifacts. The spec defines the compilation
contract — what the compiler reads, what it produces, and what
invariants it maintains.

---

## Compilation Contract

A compiler:

1. **Reads** canonical skill specs from `plugins/*/skills/*.yaml`
2. **Reads** prose bodies from `plugins/*/bodies/*.md` (optional —
   generates default body from spec metadata if absent)
3. **Produces** platform-native artifacts in `compiled/<platform>/`
4. **Preserves** all governance metadata in the output (the compiled
   artifact must be traceable back to the canonical spec)

A compiler must NOT:

- Modify canonical specs
- Add governance logic (that's the control plane)
- Make access-control decisions (that's the registry)
- Introduce fields that don't exist in the canonical spec

---

## Platform Targets

### Claude Code

**Output structure:**
```
compiled/claude/<skill-name>/SKILL.md
```

**SKILL.md format:**
```markdown
---
name: <skill-name>
description: <generated from spec metadata>
user-invocable: true
argument-hint: <derived from spec inputs, optional>
---

<body content — from bodies/<name>.md or generated default>
```

**Claude-specific conventions:**
- YAML frontmatter fields: `name`, `description`, `user-invocable`,
  `argument-hint`
- Body uses `$ARGUMENTS` token for parameter substitution
- One directory per skill under `.claude/skills/`

### OpenAI Codex (future)

**Output structure:**
```
compiled/codex/AGENTS.md
compiled/codex/config.toml
```

**Codex-specific conventions:**
- Instructions file: `AGENTS.md` (markdown, no frontmatter required)
- MCP server config: `[mcp_servers.<name>]` in TOML
- Directory walk discovery: `AGENTS.md` at each level

### Cline (future)

**Output structure:**
```
compiled/cline/<skill-name>.md
```

**Cline-specific conventions:**
- Markdown with optional YAML frontmatter
- `globs` array for file-pattern scoping
- Placed in `.clinerules/` directory

### Cursor (future)

**Output structure:**
```
compiled/cursor/<skill-name>.mdc
```

**Cursor-specific conventions:**
- MDC format (YAML frontmatter + markdown)
- `alwaysApply`, `globs`, `priority` fields
- Placed in `.cursor/rules/` directory

---

## Cross-Platform Mapping

### Cross-Platform Field Mapping

Every field in the canonical spec must have a defined fate at
compilation. Fields either map to a platform-native construct or are
preserved as metadata in frontmatter (ignored by the runtime but
parseable by tooling).

| PCS Field | Claude | Codex | Cline | Cursor |
|-----------|--------|-------|-------|--------|
| `name` | frontmatter `name` | Section heading | frontmatter `description` | frontmatter `description` |
| `version` | frontmatter `pcs-version` (metadata) | N/A | N/A | N/A |
| `owner` | frontmatter `pcs-owner` (metadata) | N/A | N/A | N/A |
| `description` | frontmatter `description` | Prose paragraph | Body content | Body content |
| `inputs` | `argument-hint` + `$ARGUMENTS` | Function parameters | N/A | N/A |
| `outputs` | Body "Returns" section | Function return type | N/A | N/A |
| `effect` | frontmatter `pcs-effect` (metadata) + body safety note | N/A | N/A | N/A |
| `is_idempotent` | frontmatter `pcs-idempotent` (metadata) + body safety note | N/A | N/A | N/A |
| `requires_capabilities` | Body "Required capabilities" line | N/A | N/A | N/A |
| `trust_tier` | Not in output (enforced by control plane) | Not in output | Not in output | Not in output |
| `lifecycle_state` | Not in output (enforced by control plane) | Not in output | Not in output | Not in output |

### Governance Metadata in Compiled Output

**Trust tier and lifecycle state** are never compiled into platform
artifacts. The control plane enforces them at invocation time.

**Effect, idempotency, version, and owner** are preserved in compiled
output as platform-specific metadata fields. The runtime ignores them;
tooling can parse them. For Claude Code, these appear as `pcs-*`
prefixed frontmatter fields:

```yaml
---
name: lotw-upload
description: "LoTW upload (mutate external)"
user-invocable: true
argument-hint: adif_records, station_callsign
pcs-version: "0.1.0"
pcs-owner: watson
pcs-effect: mutate_external
pcs-idempotent: false
---
```

This keeps compiled artifacts **self-describing** — a tool reading the
SKILL.md can extract governance metadata without consulting the
canonical spec. No sidecar files required.

**Rule for unmappable fields:** If a platform has no native slot for a
PCS field, the compiler preserves it as prefixed metadata in whatever
frontmatter/header the platform supports. If the platform has no
frontmatter at all, the compiler emits a comment block at the top of
the file.

---

## Default Body Generation

When no body file exists for a skill, the compiler generates a default
body from the spec metadata:

1. Description line (from `name` + `effect` + capabilities)
2. Safety note (derived from `effect` and `is_idempotent`)
3. Required capabilities list (if any)
4. `$ARGUMENTS` placeholder (if `inputs` has properties)

The generated body is functional but minimal. Authors should provide
custom bodies for production skills.

---

## Compilation Validation

The control plane runs a pre-compilation gate (see 07-gates.md) before
any compiler executes:

| Check | Rule |
|-------|------|
| All referenced skills exist | Runbook `skill_name` resolves |
| Plugin manifest valid | `plugin.yaml` present and valid |
| Body files present | Warning if missing (compiler generates default) |
| Target directory writable | `compiled/<platform>/` exists or can be created |

---

## Adding a New Target

To add support for a new platform:

1. Define the output structure for `compiled/<new-platform>/`
2. Define the platform-specific file format
3. Define the mapping from PCS fields to platform fields
4. Implement the compiler as a separate tool (peer to the control
   plane, not part of it — compilers are not one of the three core
   PCS components)
5. Add the platform to this document's cross-platform mapping table

The canonical spec does not change. Only the compiler and this
reference table are updated.
