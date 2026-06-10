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
| §6 | **PCS** — the eighth pillar (plugin & workflow requirements) | Filled |
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
| 6 | **PCS** — Platform Control System (the eighth pillar) | Filled (18 requirements + Conformance Profile) |

**Spec is complete.** §5 covers 7 substrate pillars (§§5.1–5.7) + the MCC host frame (§5.8); §6 covers the eighth pillar, **PCS**. Pillar count is 8; MCC is host, not pillar #9. All 8 pillars have numbered requirements + a Conformance Profile.

**Review chain status:**

| Pass | Doc | Reviewer | PR | Status |
|------|-----|----------|-----|--------|
| Pass-1 STD | STD-001 (7 substrate pillars + MCC host) | Watson + Bob+panel | #87 | Merged |
| Pass-2 STD | STD-001 | Patton adversarial | #88 | Merged |
| Pass-1 HDBK | HDBK-001 (refresh) | Watson + Bob+panel | #89 | Merged |
| Pass-2 HDBK | HDBK-001 | Patton adversarial | #90 | Merged |
| STD companion | STD-001 (Shamir precision + model-substrate seam) | Watson + Bob+panel | #91 | Merged |
| PR-B-PCS | STD-001 §6 PCS (eighth pillar) | Watson + Bob+panel | #92 | Merged |
| Pass-3 STD | STD-001 complete (with §6 PCS) | Patton adversarial | #93 | Merged |
| Pass-4 STD | STD-001 complete + post-Pass-3-fold | Einstein first-principles | #94 | Merged |
| Pass-5 STD | STD-001 post-Pass-4-fold | Einstein second-order first-principles | #95 | Merged |
| Pass-6 STD | STD-001 post-Pass-5-fold | Einstein third-order first-principles | #96 | Merged |
| **Pass-7 STD** | **STD-001 post-Pass-6-fold (Einstein sign-off + Thompson trust-boundary acknowledgment)** | **Einstein sign-off** | **#97 (in flight)** | **In flight** |

The complete STD-001 covers 8 pillars + MCC host frame + 6 invariants + 11 active divergence_type subtypes + named quorum verifier. HDBK-001 is the companion. Pass-4 STD is Einstein's first-principles pass on the post-Pass-3 artifact — focused on what only fundamental-limit reading finds (DAG reachability, CAP/FLP, Little's Law, Nyquist, orthogonality, Lamport, cryptographic domain separation, Halting problem). Reviewed via attached-files (no GH access for Einstein).

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
