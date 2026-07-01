# Fiducial Mesh — Specification & Handbook

**Cradle-to-grave traceability for AI-assisted engineering — as a substrate-pluggable, open specification.**

Autonomous agents are entering regulated engineering environments faster than the trust, audit, and lifecycle disciplines those environments require. Unless a platform binds **every agent action to a verified principal**, **every policy decision to a recorded determination**, **every knowledge citation to its source**, and **every state-affecting operation to an append-only audit ledger**, the output of an agentic system cannot pass the certification gates that FAA-certified avionics, FDA-regulated devices, nuclear control systems, and the EU AI Act impose.

Fiducial Mesh specifies those primitives — and keeps them **portable across the operator's own choice of substrate** (secret store, directory, database, isolation runtime, telemetry backend), so sovereignty is a property of the architecture, not a vendor relationship.

This repository holds the two canonical documents.

| Document | What it is |
|----------|------------|
| [**`FIDUCIAL-MESH-SPEC-001`**](FIDUCIAL-MESH-SPEC-001.md) | **The Specification** — normative requirements (RFC 2119 keywords, numbered `FM-*` IDs, per-pillar Conformance Profiles). This is what you build to. |
| [**`FIDUCIAL-MESH-HDBK-001`**](FIDUCIAL-MESH-HDBK-001.md) | **The Handbook** — the companion narrative: rationale, design history, worked examples. This is what you read to understand the Specification. |

**Current version: v1.2.1** (see [tags](../../tags) and [releases](../../releases)).

## The shape

Eight pillar contracts plus a pluggable host frame (MCC). Each pillar specifies *what capability it requires from substrate*, not *which product provides it* — and conformance is mechanically verified against a named profile set.

| Pillar | | Plane |
|---|---|---|
| **IBX** | Inbox Exchange — agent message/work queue | State |
| **IAM** | Identity & Access Management — sovereign agent identity lifecycle | Issuance + Control |
| **PGE** | Policy Guardrail Engine — deterministic, owned policy enforcement | Control |
| **ACT** | Agent Cognitive Telemetry — append-only audit + observability | State |
| **AKB** | Agent Knowledge Base — grounded, citable knowledge retrieval | State |
| **PCS** | Plugin Control System — plugin/workflow lifecycle + conformance + registry | Control |
| **CRB** | Compute Resource Broker — workload dispatch | Control |
| **DPG** | Deterministic Proving Ground — ephemeral execution isolation | Compute |
| **MCC** | Mesh Control Center — the host frame that composes the pillars (*not* a pillar) | — |

The load-bearing structural commitment is the **Management + Control dyad**: runtime control (admission, dispatch, isolation, enforcement) is structurally separated from management (identity lifecycle, telemetry/audit, knowledge, conformance) — *exhibited by the contract structure itself*, not maintained by operator discipline.

Seven top-level invariants (`[FM-INV-0001]` … `[FM-INV-0007]`) bind every pillar; everything in the pillar requirements binds back to them.

## Reading order

1. **Specification §0–§4** — conventions, scope, the invariants. Everything below §4 binds back to it.
2. **The pillar §5 / §6 sections you care about** — each is self-contained: requirements, then a Conformance Profile (sovereign reference + supported alternatives + test set).
3. **Pull in the Handbook for the *why*** — design history, regulatory crosswalk, worked examples.

## How it's developed

In the open, through a **multi-agent dialectical review chain** — author → adversarial review → first-principles review → human integrator. No single reviewer, however expert, reliably sees the blind spot in their own work; the method defeats that across independent vantages. This discipline is itself part of the credited design, and it is documented in the Handbook.

## License & citation

- **Specification & Handbook** — **CC-BY-4.0** ([`LICENSE`](LICENSE)).
- **Mesh software** (separate repositories) — GPL-3.0.

Copyright © 2026 **Agentics Labs LLC**. Authored by **Gregory A. Beam (KI7MT), for the Fiducial Mesh Group**.

Archived, citable DOIs (CC-BY-4.0):

- **Specification** (SPEC-001 v1.2.1) — [`10.5281/zenodo.21109753`](https://doi.org/10.5281/zenodo.21109753)
- **Handbook** (HDBK-001 v1.2.1) — [`10.5281/zenodo.21110034`](https://doi.org/10.5281/zenodo.21110034)

Contributions follow the discipline in the organization's [`CONTRIBUTING`](https://github.com/fiducial-mesh/.github/blob/main/CONTRIBUTING.md); drift from the Specification is a finding, not a feature.
