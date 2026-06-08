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
What controls the platform. PCS is the action layer — it manages
plugins, workflows, the registry, validation, and projects across agent
surfaces. Covers the cardinal rule (PCS plugins are a strict superset of
Anthropic Claude Code and OpenAI Codex plugins, so they install on any
agent surface), the artifact hierarchy (Namespace → Plugin → Workflow),
the validation harness, the mesh-internal registry with vendor-marketplace
projections, the default manifest model, the AIR/CLCA continuous
improvement loop, and the bootstrap (agent-as-installer) story.

### 3. The Pillars
The substrate pillars PCS orchestrates. Each pillar gets a section
explaining what it does, its substrate matrix, its telemetry contract,
and how PCS reaches into it via plugins. Order: IBX (Inbox Exchange),
AKB (Agent Knowledge Base), ACT (Activity/Telemetry), IAM (Identity
and Access Management), PGE (Policy and Governance Enforcement),
CRB (Control Runtime / Broker — Go), DPG (Sandbox / Execution
Substrate — Go), MCC (Mesh Control Center).

### 4. Operations
How a Mesh runs in practice. Security framework, delivery and packaging,
the AIR/CLCA discipline, the documentation model (spec + user guide +
workflow matrix). Also covers how a customer extends the mesh without
forking (substrate matrix × workflow composition) and the dogfood story
(KI7MT lab as tenant #1).

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
