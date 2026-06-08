# `planning/` — The canonical Fiducial Mesh specification

This directory contains **only validated, approved spec documents** that
describe the contract Fiducial Mesh holds with its implementers, customers,
and operators.

**Discipline:** a document lives here only when its frontmatter records
`status: validated` (or equivalent approved status) and it has passed
review. Drafts, design dialogues, working notes, AIR reports, and any
spec scaffolding that has not been formalized live in the companion
[`fiducial-mesh/devel`](https://github.com/fiducial-mesh/devel) repository
under `spec-drafts/`.

## What's here

### Mesh-level framework (4)

| File | Role |
|------|------|
| [`MESH-SPEC.md`](MESH-SPEC.md) | Mesh-level invariants (MI-*), Closed Decisions, conformance contract |
| [`PILLAR-NAMES.md`](PILLAR-NAMES.md) | Canonical pillar identifiers + status |
| [`PILLAR-SPEC-TEMPLATE.md`](PILLAR-SPEC-TEMPLATE.md) | Required section structure + six non-negotiables every pillar spec satisfies |
| [`PRODUCTION-VALIDATION.md`](PRODUCTION-VALIDATION.md) | Cross-pillar validation framework |

### Pillar specs (6)

One canonical specification per pillar:

| File | Pillar |
|------|--------|
| [`IBX-SPEC.md`](IBX-SPEC.md) | Inbox Exchange — message routing substrate |
| [`ACT-SPEC.md`](ACT-SPEC.md) | Activity / telemetry pillar |
| [`PGE-SPEC.md`](PGE-SPEC.md) | Policy / governance enforcement |
| [`CRB-SPEC.md`](CRB-SPEC.md) | Control runtime / broker |
| [`DPG-SPEC.md`](DPG-SPEC.md) | Sandbox / execution substrate |
| [`IAM-CORE-SPEC.md`](IAM-CORE-SPEC.md) | Identity & access management — core |

### PCS legacy components (2, validated)

The new canonical `PCS-SPEC.md` is being assembled from the design conclusions
in `devel/spec-drafts/PCS-PLATFORM-REDESIGN-NOTES.md`. Until that lands, these
two validated PCS components are the spec surface:

| File | Role |
|------|------|
| [`PCS-DAEMON-SPEC.md`](PCS-DAEMON-SPEC.md) | PCS execution daemon — `pct-v1` consumer contract |
| [`PCS-REGISTRY-FOLD-IN.md`](PCS-REGISTRY-FOLD-IN.md) | PCS registry deployment-architecture commitments |

### Approved governance (1)

| File | Role |
|------|------|
| [`OWNERSHIP-MATRIX.md`](OWNERSHIP-MATRIX.md) | Repo + plugin ownership matrix (approved by KI7MT + Watson 2026-05-17) |

### Diagrams

[`diagrams/`](diagrams/) — architecture diagrams referenced by the specs above.

## What's NOT here

Anything in `draft`, `draft-investigation`, `draft-notes`, `provisional`, or
working-document status lives in
[`fiducial-mesh/devel/spec-drafts/`](https://github.com/fiducial-mesh/devel/tree/main/spec-drafts).
That includes:

- **Drafts being formalized**: AKB-SPEC, MCC-SPEC, MANIFESTO,
  TECHNICAL-OVERVIEW, CONFORMANCE, DELIVERY-PACKAGING, ENGINEERING-STANDARDS,
  IAM-INCREMENT-2, IAM-STARTER-ROLES-TABLE, CONCURRENCY-AND-ARCHETYPES,
  REGULATED-WORKFLOW-OVERLAY, REPO-SHAPE-DECISIONS
- **AIR reports** (post-mortems): AIR-001-*, AIR-002-*, AIR-SPEC-DESIGN-NOTES
- **AKB design dialogue**: akb-awareness-layer, akb-cross-role-audit,
  akb-lifecycle, akb-migration-plan, akb-reasoning-independence,
  akb-review-trajectory + tier0/ + templates/akb-document-template
- **IAM working drafts**: IDENTITY-PILLAR-DESIGN, INSTANTIATION-AND-IDP,
  AGENT-FRICTION-CATALOG, DESIGN-PHILOSOPHY
- **PCS scaffold + design notes**: `pcs/` (12-section v0.2-draft scaffold),
  PCS-ADOPTION-PLAN, PCS-PLATFORM-REDESIGN-NOTES (the design conclusions doc
  that drives the eventual PCS-SPEC.md rewrite)

## Promotion workflow

```
devel/spec-drafts/<doc>         ← drafts, design dialogue, AIRs live here
       │
       │   draft formalized; status: validated; review passed
       ↓
spec/planning/<doc>             ← canonical, approved spec lives here
```

A draft is promoted by:
1. Frontmatter status field updated to `validated` (or equivalent approved status)
2. Review passed (GH-native review, per the workflow in CLAUDE.md)
3. Judge merges
4. `git mv` from devel to spec at merge time (or as a follow-on commit)

Cross-references between repos use GitHub URLs. Cross-references inside this
directory use relative paths.

---

*Last reorganized: 2026-06-08. This README documents the discipline that
keeps the canonical spec clean.*
