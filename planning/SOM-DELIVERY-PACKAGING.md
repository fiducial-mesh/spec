---
title: "SOM Delivery & Packaging — Air-Gap-Native Distribution Contract"
doc_type: spec
status: draft
version: v0.1
authors:
  - bob
date: "2026-06-02"
roles:
  - infrastructure
author_id: bob
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/PCS-DAEMON-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/PGE-SPEC.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/SOM-ENGINEERING-STANDARDS.md
---

# SOM Delivery & Packaging — Air-Gap-Native Distribution Contract

**Scope**: How a conformant SOM deployment is **packaged, distributed, installed, and upgraded** —
across the dual-tier target (enterprise + solo/SMB) and, critically, into **air-gapped /
FIPS / SCIF** environments where the highest-value deployments live. This is a **cross-cutting
spec, not a pillar** (cf. `SOM-CONCURRENCY-AND-ARCHETYPES.md`): every pillar's runtime artifacts
flow through this delivery contract. It does NOT alter any pillar contract; it specifies the
substrate on which the mesh ships.

**Authorship note (inverted origin)**: Bob-authored (infrastructure lane), going *up* the
review chain Watson → Patton → Einstein rather than down — per the wave-2 origin-inversion
ruling (Judge, 2026-06-02). The two-person gate is preserved: Watson reviews; Judge holds merge.

**Status**: **Draft v0.1**, wave-2. Unblocked by `SOM-SPEC.md` v1.0 closing the spec campaign.
Awaiting Watson code/spec review → Patton sign-off → Einstein cross-substrate pass (the second
Einstein pass Patton scoped for wave-2 specs, `dc6ca481`).

## Purpose

For SOM's prize target (sovereign / air-gapped / FIPS / SCIF), **delivery is part of the moat
and part of the security posture** — not packaging glue. A signed, SBOM'd, offline-installable
bundle with verifiable provenance is itself an **audit asset** and one of the "hard air-gap
parts" that constitute the engineering moat. A delivery layer that *generates* audit findings
(non-validated crypto, unsigned artifacts, internet-dependent install) defeats the value
proposition before a single pillar runs.

Two governing principles carried from the mesh:
- **Forks are bad. One change, fit the framework.** One artifact set; one topology model;
  swappable renderers. Variation lives in the seam, never in a fork.
- **Dual-tier without divergence.** Enterprise rigor is *additive* to a solo-minimal core
  (cf. dual-tier discipline). The lab-on-Rocky reference proves the exact stack the customer
  runs on RHEL (binary-compatible family).

## Closed Decisions (Draft — pending review chain)

**DP-CD1 — Artifact unit: OCI containers on a UBI base + RPM for host-resident bits.**
Containers are the unit for the C#-plus-Python mesh (one image per pillar service; identical
image on both tiers). Base on **Red Hat UBI** (`ubi9-minimal`) → base image is itself
RHEL-supported + FIPS-capable, and the identical image runs on the Rocky/Alma lab tier.
.NET 10 publishes container images directly (no Dockerfile). Host-level pieces that cannot
containerize — the **PCS-Daemon** (controls host plugins, cf. `PCS-DAEMON-SPEC.md`), the
GPU/driver layer, and the **`som` CLI** — ship as **RPM** (existing COPR muscle). Dual-format
by necessity.

**DP-CD2 — Runtime: Podman + Quadlet (systemd), not Docker.** Rootless, no root daemon,
SELinux-native (`:Z` labels), FIPS-friendly — the RHEL-native choice, and it removes the
SELinux friction a root Docker daemon creates. Tier mapping: **Quadlet** (solo/SMB + lab
reference, single box) → **Nomad** (small cluster, when the orchestrator decision lands —
consistent with the control-plane-deferred posture) → **Helm/k8s** (enterprise).

**DP-CD3 — One topology model, N renderers** (forks-are-bad applied to delivery). The mesh
topology + wiring is declared **once** (a site-profile / values document) and *emitted* to
Quadlet units | Nomad jobspecs | Helm chart. No divergent install paths; the renderer is the
seam.

**DP-CD4 — Air-gap is a hard requirement: a single signed offline bundle.** One self-contained
artifact = all images (OCI layout) + RPMs + manifests + checksums + signatures. Sneakernet /
CDS across the gap → `skopeo copy` into the customer's local registry (Harbor / Quay / zot) →
RPMs from a local mirror (RHEL Satellite or `reposync`). **Zero internet, zero phone-home** —
the SCIF no-egress baseline AND a security feature. The installer assumes no network, period.

**DP-CD5 — Supply-chain integrity is the build, enforced mechanically.** **cosign key-pair**
signing (NOT keyless/Fulcio — that needs internet; air-gap requires offline-verifiable keys,
public key shipped out-of-band) + **SBOM** (SPDX/CycloneDX) + **SLSA provenance** per artifact;
**GPG-signed RPMs**. The build produces all of it; **CI gates on it** — the same enforce-
mechanically discipline as the license-audit gate and the FIPS-hygiene gate in
`SOM-ENGINEERING-STANDARDS.md`. Delivery integrity is a build property, not a pre-release
checkbox.

**DP-CD6 — FIPS-clean by construction (delivery side).** The bundle must not be the *source*
of FIPS-140-3 findings: no bundled non-validated crypto module; crypto defers to the platform's
FIPS-validated provider; the install path uses only approved hashes (so a FIPS crypto-policy
host doesn't choke). Framework-clean ≠ deployment-certified — the deployment still supplies the
validated module + FIPS mode — but SOM never generates the finding. (Couples to the
`SOM-ENGINEERING-STANDARDS.md` FIPS-hygiene gate.)

**DP-CD7 — Installer: one `som` CLI, .NET Native AOT single-file binary.** Keeps the core C#
(the customer's house language in the IHFA case); AOT → no .NET runtime dependency on the box
to bootstrap it; single static file, air-gap-copyable. (Go static binary is the documented
fallback if AOT proves fiddly — existing ionis-apps muscle.) Flow: `load-bundle →
verify-signatures → select-connectors (DB/IdP/secrets/crypto via site profile) →
conformance-probe chosen backends → render+apply (Quadlet|Nomad|Helm) → health-check`.

**DP-CD8 — Connector selection is config at install, not a fork.** The site profile declares
which DB / IdP / secrets / crypto connector + endpoints; the conformance suite verifies the
chosen backend satisfies the interface **before go-live**. The pluggability model applied at
delivery time (cf. IAM pluggable-IdP, the pluggable persistence layer).

## OS dual-tier (pluggability applied to the base OS)

- **Lab / SMB tier → Rocky / Alma** (free, RHEL-binary-compatible, FIPS-mode-capable). What the
  9975 runs.
- **Enterprise / regulated tier → RHEL** (carries the FIPS-140 validation *certificate* + vendor
  support + the air-gap entitlement story; pays in subscription friction — Satellite or offline
  manifests for air-gapped repo access).
- Same binary-compatible family → SOM artifacts work across both. Lab-on-Rocky proves the exact
  stack the customer runs on RHEL. Free below, supported above, one codebase.

## Dependencies

- `SOM-SPEC.md` v1.0 — mesh contract; substrate-substitutability invariant (SOM-MI-8) the
  delivery layer must not violate (no pillar's packaging may create lock-in for another).
- `PCS-DAEMON-SPEC.md` v1.0 — the host-resident daemon shipped as RPM; plugin artifacts flow to
  the air-gapped Registry per PCS lifecycle.
- `IAM-CORE-SPEC.md` v1.0 — artifact signing trust chain relates to the Issuance-Plane offline
  authority (signed artifacts cross the dotted line at provisioning time).
- `PGE-SPEC.md` v1.0 + `MCP-SECURITY-FRAMEWORK.md` — security posture the delivery integrity gates
  enforce.
- `SOM-ENGINEERING-STANDARDS.md` v0.1 — the license-audit + FIPS-hygiene CI gates this spec's
  DP-CD5/DP-CD6 reuse.

## Success Criteria

- **Single offline bundle installs the full mesh on an air-gapped box** with zero network access
  (litmus: disconnect, sneakernet, `som` install succeeds).
- **Every artifact is signed + SBOM'd + provenance-attested**, verifiable offline; CI fails on a
  missing/invalid signature, SBOM, or non-approved-crypto usage.
- **One topology model renders to all three runtimes** (Quadlet / Nomad / Helm) without a forked
  install path.
- **Solo-minimal litmus**: `som dev up` stands up the whole mesh on free components (Rocky +
  Podman/Quadlet + Postgres+pgvector + OpenBao) in an afternoon.
- **FIPS-clean**: a FIPS-mode RHEL install generates zero FIPS-140-3 findings attributable to SOM
  packaging.

## Failure Modes To Watch

- **Phone-home creep** — a dependency or telemetry default reaches the internet at install/run,
  breaking the air-gap guarantee. Mitigation: DP-CD4 zero-egress assertion; conformance test runs
  the installer on a network-isolated box.
- **Keyless-signing assumption** — adopting cosign keyless/Fulcio (needs internet) silently
  breaks air-gap verification. Mitigation: DP-CD5 mandates key-pair signing; CI verifies offline.
- **Bundled non-validated crypto** — a managed/bundled crypto lib becomes an instant FIPS finding.
  Mitigation: DP-CD6 + the FIPS-hygiene gate (CA5350/CA5351) in `SOM-ENGINEERING-STANDARDS.md`.
- **Renderer fork** — divergent Helm vs Quadlet install logic drifts. Mitigation: DP-CD3 single
  topology model; the renderers are pure emitters, reviewed as one.
- **Docker-daemon reintroduction** — convenience pressure to use Docker reintroduces the
  root-daemon SELinux friction. Mitigation: DP-CD2 Podman/Quadlet is the committed runtime.

## Open Questions

- **DP-OQ1**: registry choice for the air-gap reference (Harbor vs Quay vs zot) — pick a reference,
  keep it pluggable.
- **DP-OQ2**: where the delivery spec sits in the repo taxonomy after the `pcs-*` → `som-*` shift
  and the `som-spec` migration (this file may move with the SOM corpus).
- **DP-OQ3**: AOT vs Go for the `som` CLI — AOT is the lean-C# default; confirm AOT handles the
  process/file/network orchestration cleanly before foreclosing the Go fallback.
