# PCS Specification

Version: 0.2-draft | Status: Draft

The Plugin Control System (PCS) specification. This directory contains
the complete governance rulebook for PCS-governed plugin projects.
Everything a control plane implementer needs to build a conformant
validator, compiler, and registry.

## Documents

### Core (v0.1)

| Document | What It Defines |
|----------|----------------|
| [01-principles.md](01-principles.md) | Why PCS exists, design principles, litmus test, component roles |
| [02-plugin-structure.md](02-plugin-structure.md) | Directory layout, manifests, naming, discovery |
| [03-skill-spec.md](03-skill-spec.md) | Skill Spec — fields, constraints, schema |
| [04-runbook-spec.md](04-runbook-spec.md) | Runbook Spec — steps, judgment, composition |
| [05-execution-profile.md](05-execution-profile.md) | Node + Agent + Project Context, capability handshake |
| [06-lifecycle.md](06-lifecycle.md) | States, trust tiers, promotion, deprecation |
| [07-gates.md](07-gates.md) | Validation gates — when, what, how |
| [08-failure-modes.md](08-failure-modes.md) | Effect classification, abort rules, escalation |
| [09-audit.md](09-audit.md) | What gets logged, required fields, CLCA process |
| [10-compilation.md](10-compilation.md) | Platform targets, compiler contract, cross-platform mapping |

### Extensions (v0.2-draft)

| Document | What It Defines |
|----------|----------------|
| [11-procedures.md](11-procedures.md) | Reusable invocation patterns — the operational stdlib layer below skills |
| [12-resumption.md](12-resumption.md) | Involuntary termination handling — verification skills, resumption decision tree |

## Reading Order

For implementers building a control plane: read 01 through 12 in order.
Each document builds on the previous.

For plugin authors: read 02 (structure), 03 (skills), 11 (procedures),
and 06 (lifecycle). That's enough to create a conformant plugin.

For reviewers: read 01 (principles), 07 (gates), and 12 (resumption).
That's the governance model and failure handling.

For operators: read 01 (why PCS exists) and 08 + 12 (what happens
when things go wrong).
