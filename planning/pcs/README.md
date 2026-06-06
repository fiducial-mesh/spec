# PCS — Plugin Control System

A governance standard for managing plugins across AI agent platforms.

## The Problem

You're running multiple AI coding agents — Claude Code, Codex, Cursor,
Cline, or some combination. Each agent has its own skills, tools, and
MCP servers. Some were built by your team, some were borrowed from
colleagues, some came from the internet. Nobody knows which ones are
tested, which are abandoned, which contradict each other, and which
ones write to production databases without telling you.

This gets worse fast. At 10 plugins, you can keep track. At 100, you
can't. At 1,000 (which is where enterprises are headed), you need a
system.

## The Solution

PCS is a specification — a set of rules that define what a well-governed
plugin looks like, how it's validated, how it moves through a lifecycle,
and how it gets deployed to any agent platform.

PCS does not run your plugins. It governs them.

**Three components:**

| Component | What It Does |
|-----------|-------------|
| **pcs-spec** (this repo) | The standard. Defines what a conformant plugin looks like. |
| **pcs-control-plane** | The validator. Checks whether a plugin meets the standard. Manages publication and lifecycle. |
| **pcs-registry** | The catalog. Serves validated plugins to agents. Discovery and resolution API. |

The spec declares. The control plane validates. The registry serves.
Agents execute.

## What the Spec Defines

This repository contains the complete governance standard. Ten
documents, each covering one concern:

| # | Document | What It Covers |
|---|----------|---------------|
| 01 | [Principles](spec/01-principles.md) | Nine binding design principles. The litmus test for every spec decision. |
| 02 | [Plugin Structure](spec/02-plugin-structure.md) | Standard directory layout. How plugins are organized on disk. Discovery rules so tools can find everything by convention. |
| 03 | [Skill Spec](spec/03-skill-spec.md) | What a skill declaration looks like — ten fields covering identity, ownership, lifecycle, trust, side effects, capabilities, and contracts. |
| 04 | [Runbook Spec](spec/04-runbook-spec.md) | How multi-step workflows are declared — skill composition with judgment points where the agent applies reasoning. |
| 05 | [Execution Profile](spec/05-execution-profile.md) | How the environment advertises what it can do — hardware capabilities, agent authority, and project context. The other half of the capability handshake. |
| 06 | [Lifecycle](spec/06-lifecycle.md) | How plugins move from draft to production to retirement. Trust tiers (experimental through core) and what it takes to promote. |
| 07 | [Gates](spec/07-gates.md) | Five validation checkpoints — registration, pre-execution, post-execution, pre-promotion, and pre-compilation. What gets checked, when, and what happens on failure. |
| 08 | [Failure Modes](spec/08-failure-modes.md) | What happens when things go wrong. Side-effect classification (read-only vs. writes to external systems), abort rules, and escalation paths. |
| 09 | [Audit](spec/09-audit.md) | What gets logged and how defects are handled. Required audit fields and the CLCA (Closed-Loop Corrective Action) process for continuous improvement. |
| 10 | [Compilation](spec/10-compilation.md) | How canonical plugin specs get translated into platform-specific formats — Claude Code SKILL.md, Codex AGENTS.md, Cline rules, Cursor MDC files. |

## Key Concepts

### Skills vs. Runbooks

A **skill** is a single-purpose, deterministic capability. Any agent
executes it the same way. Example: look up a callsign, decode a grid
square, fetch weather data.

A **runbook** is orchestration — multiple skills composed with judgment
points where the agent's role matters. Example: a post-contest workflow
that exports logs, validates them, gets human approval, then uploads.

The test: if two different agents would do it identically, it's a skill.
If the agent's role changes the approach, it's a runbook.

### Trust Tiers

Plugins move through four trust levels:

| Tier | Meaning |
|------|---------|
| **Experimental** | New, untested, author-only use |
| **Community** | Peer-reviewed, shared |
| **Blessed** | Cross-reviewed, operator-approved |
| **Core** | Fully audited, load-bearing |

Each tier has defined requirements to enter. Agents declare the highest
tier they're allowed to use. A sandbox agent can't pull from core; a
production runbook can't invoke experimental skills.

### Side-Effect Classification

Every skill declares what it does to the world:

| Effect | What It Means |
|--------|--------------|
| **Pure** | Read-only. Safe to retry or abort anytime. |
| **Mutate Local** | Writes to local disk. Abort needs cleanup. |
| **Mutate External** | Writes to external systems. Abort is illegal after execution. |

This is what prevents an agent from accidentally retrying a database
write or aborting after publishing to a package registry.

### Platform-Agnostic

The spec knows nothing about Claude, Codex, Cline, or Cursor. Plugin
authors write one canonical spec. Compilers translate it to whatever
platform needs it. Adding a new platform means writing a new compiler,
not changing the spec.

## Examples

The `examples/` directory contains sample plugin declarations
demonstrating each concept:

```
examples/
├── grid-decode.yaml              # Pure skill — grid square decoder
├── paper-status.yaml             # Pure skill — document status check
├── inbox-check.yaml              # Pure skill — message inbox query
├── export-schema.yaml            # Mutate-local — write a file (idempotent)
├── lotw-upload.yaml              # Mutate-external — upload to external service
├── release-preflight.yaml        # Borderline case — split from a runbook
├── runbook-propagation-brief.yaml  # All-pure runbook
├── runbook-post-contest.yaml       # Mixed-effect runbook with abort constraint
└── profiles/
    ├── node-m3.yaml              # Node hardware capabilities
    ├── node-9975wx.yaml          # Node with GPU capabilities
    ├── agent-watson.yaml         # Agent with write authority
    └── agent-bob.yaml            # Agent with different authority
```

## JSON Schema

`schema/skill-spec.v0.1.schema.json` contains the machine-readable
JSON Schema for the v0.1 Skill Spec. Use it to validate skill YAML
files in any language or editor that supports JSON Schema.

## Who This Is For

- **Plugin authors** — read [02](spec/02-plugin-structure.md) and
  [03](spec/03-skill-spec.md). That's enough to create a conformant
  plugin.
- **Control plane implementers** — read all ten documents in order.
  Everything you need to build a validator, compiler, and lifecycle
  manager.
- **Operators and reviewers** — read [01](spec/01-principles.md) and
  [07](spec/07-gates.md). That's the governance model.

## License

GPL-3.0-or-later
