# Fiducial Mesh — Specification Repository

This repository holds the **approved specification documents** and the
**LaTeX/PDF build** for Fiducial Mesh. It is the canonical home of
the Standard and Handbook. Working drafts, design notes, and
competitive analyses live elsewhere (see *Where the rest lives*
below).

Authored by the **Fiducial Mesh Group**.
Licensed **GPL-3.0** (see `LICENSE`).

## What's in this repo

| File | What it is |
|------|------------|
| `FIDUCIAL-MESH-STD-001.md` | **The Standard** — normative requirements (RFC 2119 keywords, numbered `FM-*` IDs). NASA-STD shape. |
| `FIDUCIAL-MESH-HDBK-001.md` | **The Handbook** — companion narrative. Non-normative rationale, design history, and worked examples. Cites the Standard in reverse. |
| `Makefile` | pandoc + lualatex build for both PDFs. |
| `LICENSE` | GPL-3.0. |

Nothing else lives here on purpose. If it isn't approved spec or the
build that renders it, it lives in `../devel/`.

## Standard — section map

The Standard is organized NASA-STD-style:

| Section | Contents | State |
|---------|----------|-------|
| §0 | Conventions (RFC 2119, requirement-ID discipline, verification methods) | Complete |
| §1 | Scope | Complete |
| §2 | Applicable Documents | Complete |
| §3 | Acronyms & Definitions | Complete |
| §4 | Top-Level Invariants (`FM-INV-NNNN`) | Complete |
| §5 | Pillar requirements — 7 substrate pillars (§§5.1–5.7) + MCC host frame (§5.8) | Filled |
| §6 | **PCS** — the eighth pillar (plugin & workflow requirements) | Reserved |
| §7 | Operational requirements | Reserved |
| App. A | PCT Schema (normative) | Complete |
| App. B–E | Manifest schema, namespace conventions, cross-pillar binding, regulatory crosswalk | Reserved |
| App. F | Argued cases & deviations registry | Reserved |

### §5 + §6 pillar fill state (8 pillars + the host frame)

| § | Slot | Status |
|---|------|--------|
| 5.1 | **IBX** — Inbox Exchange (pillar) | Filled (12 requirements + Conformance Profile) |
| 5.2 | **IAM** — Identity & Access Management (pillar) | Filled (14 requirements + Conformance Profile) |
| 5.3 | **PGE** — Policy Guardrail Engine (pillar) | Filled (14 requirements + Conformance Profile) |
| 5.4 | **ACT** — Agent Cognitive Telemetry (pillar) | Filled (12 requirements + Conformance Profile) |
| 5.5 | **AKB** — Agent Knowledge Base (pillar) | Filled (14 requirements + Conformance Profile) |
| 5.6 | **DPG** — Deterministic Proving Ground (pillar) | Filled (14 requirements + Conformance Profile) |
| 5.7 | **CRB** — Compute Resource Broker (pillar) | Filled (13 requirements + Conformance Profile) |
| 5.8 | **MCC** — Mesh Control Center (**host frame**, not a pillar; see `[FM-MCC-0011]`) | Filled (14 requirements + Conformance Profile) |
| 6 | **PCS** — Platform Control System (the eighth pillar) | Reserved |

§5 is complete — 7 substrate pillars (§§5.1–5.7) + the MCC host frame (§5.8). The eighth and final pillar, **PCS**, lives in §6 (reserved). Pillar count is 8; MCC is host, not pillar #9.

**Review chain status:** Pass-1 full-spec review (Watson + Bob+panel) merged via PR #87 — hardened the consistency / completeness layer (cross-pillar refs, deviation-clause uniformity, divergence_type registry, appendix resolution, language-neutrality). **Pass-2 adversarial review (Patton) in flight** — landing on PR #88.

Reserved sections are placeholders with the dependencies that already
bind them (e.g., the audit-emission requirements every pillar
inherits). Filled pillars carry numbered requirements + a Conformance
Profile that lists sovereign reference, supported alternatives, and
test set per substrate seam.

## Building the PDFs

```bash
make pdf       # build both
make std       # Standard only
make hdbk      # Handbook only
make clean     # remove build/
```

Requires `pandoc`, `lualatex` (MacTeX or TeX Live), and STIX Two
fonts. Built PDFs land in `build/`. See the `Makefile` header for
font and tooling notes.

## Reading order

1. **Start with the Standard's §0–§4.** Conventions, scope,
   invariants. Everything in §5+ binds back to §4.
2. **Read the pillar §5 sections you care about.** Each pillar is
   self-contained: requirements, then its Conformance Profile.
3. **Pull in the Handbook for rationale.** Whenever a requirement's
   *why* matters — design history, worked example, regulatory
   crosswalk — the Handbook is where that lives.

The Standard is what you build to. The Handbook is what you read to
understand the Standard.

## Where the rest lives

| Concern | Location |
|---------|----------|
| Working drafts, pillar source material, design notes | `../devel/spec-drafts/` |
| Architecture decisions still under dialogue | `../devel/architecture-notes/` |
| Competitive analysis (Claude Enterprise, Codex, etc.) | `../devel/competitive/` |
| Implementation (Python monorepo) | `../core/` |

## Contributing

The Fiducial Mesh Group authors and maintains this Standard
collectively. Changes to the Standard follow the dialectical
discipline documented in the Handbook (multi-agent review, argued
cases for substrate-profile extensions per `[FM-INV-0003.2]`,
quorum for catastrophic-class changes per `[FM-INV-0004]`).
