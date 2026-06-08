---
title: "Fiducial Mesh Specification"
status: draft
version: v0.1
date: 2026-06-08
authors:
  - watson
references:
  - planning/MANIFESTO.md
  - planning/MESH-SPEC.md
  - planning/IBX-SPEC.md
  - planning/PILLAR-NAMES.md
---

# Fiducial Mesh Specification

> Single-document specification for Fiducial Mesh. The mesh is described
> end-to-end in this file; pillar files and design notes are folded in.

## Table of Contents

### 1. The Mesh
The thesis (what Fiducial Mesh is, what problem it solves, why it exists),
the design philosophy (human authority + agent capability), the language
policy (Python default, Go for CRB and DPG, no C# anywhere), the pillar
topology (substrate / action / governance), and how to read the rest of
the spec.

### 2. PCS — Platform Control System
What controls the platform. **PCS manages the other pillars via the
plugin system** (control flows PCS → pillars; pillars stay zero-coupled).
Opens with the **plugin-loadout = agent role** framing: the 5
mesh-internal namespaces (deployment / configuration / operations /
administration / diagnostics) ARE five composable role-loadouts;
agents-are-employees; role = toolset granted; capability lives in the
plugin, authority lives in the identity. Covers the cardinal rule (PCS
plugins are a strict superset of Anthropic Claude Code AND OpenAI Codex
plugins, so they install on any agent surface — falls out as a free
target for Copilot CLI / Coding Agent via the open Agent Skills
standard), the artifact hierarchy (Namespace → Plugin → Workflow), the
validation harness, the mesh-internal registry with vendor-marketplace
projections, the default manifest + tested variations model (BOMs), the
AIR/CLCA continuous improvement loop, the bootstrap (agent + bootstrap
plugin IS pcs-init; no custom binary required), and the Mesh-CLI / MCC
delivery shape (Mesh-CLI is a configuration not a product; MCC backend
is conventional Python — the AI is built ZERO times for MCC).

### 3. The Pillars
The substrate pillars PCS orchestrates. Each pillar gets a section
explaining what it does, its substrate matrix (the seam contract —
customer chooses among supported substrates), its telemetry contract,
and how PCS reaches into it via plugins. Order (canonical short codes
per `planning/PILLAR-NAMES.md`): **IBX** (Inbox Exchange — message
routing), **AKB** (Agent Knowledge Base — memory), **ACT** (Agent
Cognitive Telemetry — observation), **IAM** (Identity & Access —
foundational), **PGE** (Policy Guardrail Engine — deterministic
compliance enforcement), **CRB** (Compute Resource Broker — Go;
hardware-aware workload dispatch), **DPG** (Deterministic Proving
Ground — Go driver + adopted microVM; ephemeral isolation for code
execution), **MCC** (Mesh Control Center — operator UI binding the
whole thing).

### 4. Operations
How a Mesh runs in practice. Covers the **four flexibility axes** the
mesh is designed for (HA, scale, performance, OSS ‖ commercial) and
the **"run what you brung"** posture — deployment spectrum runs from
one-box hobbyist to 3 minis + 9975 to datacenter; the mesh adapts to
the substrate the customer has, not the other way around. Then:
**security framework**, **delivery and packaging** (Python default,
Go for CRB + DPG, no C# anywhere), the **AIR/CLCA discipline**
(incidents produce versioned workflow improvements, mechanically),
**how a customer extends the mesh without forking** (substrate matrix
× workflow composition — pillar code stays generic OSS, customer's
workflow encodes their substrate choice), the **agents-own-deployment
posture** (no human-following install procedures; agents read the
plugins and execute), the **documentation model** (this spec + user
guide + workflow matrix), and the **dogfood story** (KI7MT lab as
tenant #1).

### 5. Appendices
Reference material: glossary, language map per pillar, conformance
criteria, the five mesh-internal namespaces (deployment / configuration /
operations / administration / diagnostics), the PCS plugin manifest
reference, cross-pillar binding matrix, and citation list back to the
working notes (which remain in `planning/` and `devel/spec-drafts/`
for provenance).

---

*Status: this is an outline placeholder. Sections 1–5 will be filled in
as the consolidation work proceeds. Each section is being drafted from
the validated specs + the substantial drafts (MANIFESTO, TECHNICAL-OVERVIEW,
DESIGN-PHILOSOPHY, IDENTITY-PILLAR-DESIGN, the PCS design conclusions),
with C# purged everywhere and the Go choices for CRB and DPG locked.*
