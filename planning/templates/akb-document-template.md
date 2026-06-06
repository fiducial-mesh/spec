---
title: "{Document Title — use sentence case}"
doc_type: planning-active  # bounded enum: spec | planning-active | planning-draft | archive | v-results | friction | clca | runbook | shared-context | inbox-derived
status: draft               # draft | validated | deprecated | superseded
version: v0.1
authors:
  - "{watson|bob|patton|einstein|newton|judge}"  # agent_id or human handle
date: "{YYYY-MM-DD}"        # ISO 8601
roles:                      # AKB role projections — which agents see this in retrieval
  - design-intent           # remove/add per content: design-intent | infrastructure | failure-mode | physics | astrophysics
author_id: "{watson|bob|...}"   # used for self-review exemption per akb-reasoning-independence.md
violates_invariant: false      # true ONLY for failure-class chunks (V*-RESULTS, anti-patterns, dead-end docs)
invariant_class: ""            # populate ONLY if violates_invariant=true (e.g., "V25-α", "V27-PIL")
references:                    # related docs — bare paths under ionis-devel/, no leading slash
  - planning/akb-awareness-layer.md
  - planning/akb-lifecycle.md
---

# {Document Title}

**Scope**: One-line description of what this document covers.
**Status**: Mirror the YAML `status` field with any context (e.g., "Draft v0.1 — awaiting Patton review"). Optional but useful for human readers who don't parse frontmatter.

## Purpose / Problem Restatement

What problem does this document address? What's the load-bearing question being answered? Keep this section short — 1-3 paragraphs. State the problem before proposing solutions.

## Approach / Architecture

The substantive content. Use H2 sections (`## Section Name`) to chunk by topic. The AKB ingest pipeline splits chunks at H1/H2/H3 boundaries; each section becomes one or more retrievable chunks.

### Sub-sections as needed

Use H3 for further structure within sections. Header path becomes the chunk's locator in retrieval (e.g., "this-doc > Approach > Sub-section").

### Code blocks, tables, lists welcome

```
Code blocks are preserved through chunking. Use them for schemas,
commands, configuration snippets — anything mechanical.
```

| Tables | Are | Useful |
|---|---|---|
| For structured comparisons | And reference data | And quick lookup |

## Open Questions

Numbered list of unresolved questions. Each should be answerable, not hand-wavy.

1. **Question text** — short description of what's unknown. Recommendation if there is one; if not, say so.
2. **Next question** — same shape.

## Failure Modes To Watch

Bulleted list of anticipated ways this design or process could fail, with mitigation pointers.

- **Failure mode name**: how it manifests. Mitigation: what we do to prevent or detect it.
- **Another failure mode**: same shape.

## Dependencies

What this document depends on operationally — other specs, services, schema elements, agents.

- `akb.chunks` schema (per `akb-lifecycle.md`)
- `akb-mcp` server (Phase-1 build)
- Other docs referenced above

## Success Criteria

How we know this is working. Measurable where possible.

- **Criterion 1**: how it's measured. Target value.
- **Criterion 2**: same shape.

## References

Inline cross-references duplicated here for completeness (also in YAML frontmatter `references` field for machine parsing):

- `planning/akb-awareness-layer.md`
- `planning/akb-lifecycle.md`
- `planning/akb-reasoning-independence.md`

---

**Template usage notes** (delete this section in actual documents):

1. **Frontmatter is required** for AKB-indexed documents. The ingest pipeline reads it to populate `akb.chunks` metadata columns (doc_type, status, roles, author_id, violates_invariant, invariant_class). Missing frontmatter = pipeline falls back to path-based inference, which may misclassify.
2. **Header structure matters for chunking.** Use H1 for the doc title, H2 for major sections, H3 for sub-sections. The AKB ingest splits at these boundaries with 100-token overlap.
3. **`violates_invariant: true`** is reserved for content describing failed approaches, anti-patterns, or dead-ends (V*-RESULTS post-mortems, friction-catalog defect entries). When true, set `invariant_class` to the specific invariant violated.
4. **`roles` array determines which agents see this in retrieval.** Single role for narrow content; multiple roles for cross-cutting; rare cases of "all roles" require explicit justification (cross-role chunk hard cap is 50 per `akb-reasoning-independence.md`).
5. **References use bare repo-relative paths** (no leading slash, no absolute paths). The ingest pipeline resolves them against the canonical doc directory structure.
6. **Research-style papers are exempt from this template.** Papers in `papers/` follow their own academic conventions (abstract, sections, citations). This template is for operational docs: planning, runbooks, specs, post-mortems, friction entries, CLCA cycle outputs.

This template lives at `ionis-devel/planning/templates/akb-document-template.md`. Copy when creating a new AKB document.
