# 05 — Execution Profile

Version: 0.1 | Status: Draft

The Execution Profile is the symmetric counterpart to
`requires_capabilities`. Skills declare what they need; the profile
declares what the environment provides. The control plane matches them.

---

## Three Artifacts

The Execution Profile is a composite of three artifacts with different
lifecycles, owners, and authoring models. The control plane merges
them at invocation time.

### Node Profile

What the hardware provides. True regardless of who's using the node.

| Field | Type | Description |
|-------|------|-------------|
| `node` | string | Node identifier (e.g., `m3.local`) |
| `provides` | list[string] | Hardware/network capabilities |

**Authoring model:** Introspective. In production, auto-generated from
probes (`nvidia-smi`, `lsblk`, etc.). In specs, hand-authored.

```yaml
node: m3.local
provides:
  - python_runtime
  - filesystem_read
  - mps_backend
  - dac_10gbe_link
```

### Agent Profile

What authority the agent has. True regardless of which node it runs on.

| Field | Type | Description |
|-------|------|-------------|
| `agent` | string | Agent identifier (`^[a-z][a-z0-9_-]*$`) |
| `provides` | list[string] | Authority capabilities |
| `max_trust_tier` | string | Highest tier this agent may invoke |

**Authoring model:** Strictly declarative. Hand-authored by the
operator. Authority cannot be auto-discovered. A node that *has* CUDA
isn't the same as an agent that's *allowed to use it*.

```yaml
agent: watson
provides:
  - lotw_write_access
  - training_execution
max_trust_tier: core
```

### Project Context

Current work scope. Dynamic — set per invocation, not per agent or node.

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | Project scope identifier |

Watson on M3 doing IONIS work has different scope than Watson on M3
doing QSO-Graph work. Project context determines which registry
sources are visible.

Project Context schema is minimal in v0.1. Additional optional fields
may be added in future versions without breaking compatibility.

---

## Capability Namespace Convention

Capabilities are conventionally prefixed by source to support
source-attribution (see 07-gates.md, Capability Failure Attribution):

| Prefix | Source | Examples |
|--------|--------|----------|
| `node:` | Node Profile | `node:cuda_float4_tensor`, `node:mps_backend`, `node:mcp_solar` |
| `agent:` | Agent Profile | `agent:lotw_write_access`, `agent:tier_blessed_execution` |

Skills declare `requires_capabilities` with the namespace prefix:

```yaml
requires_capabilities:
  - node:python_runtime
  - agent:lotw_write_access
```

Node Profiles list `node:*` capabilities. Agent Profiles list
`agent:*` capabilities.

Prefixes enable the source-attribution diagnostic in 07 — when a
capability is missing, the prefix tells the operator which profile to
fix. When a capability is present, it tells auditors which profile
supplied it.

### Namespace Prefix Normalization

The control plane MUST strip recognized namespace prefixes (`node:`,
`agent:`) from both requirements and advertisements before evaluating
the subset constraint. This ensures that `qrz_write_access` and
`agent:qrz_write_access` match correctly — prefixes are for human
readers and source-attribution diagnostics, not for evaluation logic.

**Recognized prefixes in v0.1:** `node:`, `agent:`. Unrecognized
prefixes are treated as part of the capability name (not stripped).
The recognized prefix list may be extended in future versions.

Without this rule, a skill declaring `requires_capabilities:
[qrz_write_access]` would fail against an agent providing
`agent:qrz_write_access` — a valid configuration that breaks on a
cosmetic mismatch. The normalization rule prevents this.

Cross-cutting capabilities (e.g., `python_runtime` — is that node or
agent?) should be placed in the Node Profile (it's a hardware/runtime
property). Authority to *use* a node's capability is expressed as an
agent capability.

---

## Capability Handshake

Two layers, both needed:

### Implicit Filtering (Registry Layer)

The registry filters its catalog by the execution profile's
capabilities. An agent asking "what skills are available?" only sees
skills the current profile can satisfy.

This is the **availability** layer — answers "what could I do?"

### Explicit Pre-Flight Check (Control Plane Layer)

Before executing a runbook, the agent presents the full step manifest.
The control plane validates every skill against the execution profile.
Returns verdict + remediation.

This is the **commitability** layer — answers "can I do this exact
sequence?"

### Why Both

Without implicit filtering: agent wastes cycles considering
unreachable skills.

Without explicit pre-flight: agent can construct a runbook where
individual skills pass discovery but the sequence fails (skill 1 only
on Node A, skill 4 only on Node B — both pass discovery alone, both
fail when sequenced).

---

## What the Control Plane Validates

| Check | Rule |
|-------|------|
| Capability satisfaction | `skill.requires_capabilities ⊆ profile.all_capabilities` |
| Trust tier permission | `skill.trust_tier ≤ agent.max_trust_tier` |
| Pre-flight (runbook) | Additive union of all skill requirements ∪ runbook's own `requires_capabilities`, all satisfiable by profile |
| Project scope | Registry source visibility matches project context |

`all_capabilities` is the union of `node.provides` and
`agent.provides`, with recognized prefixes stripped per the Namespace
Prefix Normalization rule above. Skill `requires_capabilities` are
similarly normalized before subset evaluation.
