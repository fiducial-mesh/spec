---
title: "SOM Conformance — Pluggable-Substrate Self-Certification Contract"
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
  - planning/SOM-DELIVERY-PACKAGING.md
  - planning/SOM-ENGINEERING-STANDARDS.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/ACT-SPEC.md
---

# SOM Conformance — Pluggable-Substrate Self-Certification Contract

**Scope**: The contract for how a SOM deployment **proves** that a customer-chosen substrate
behind a pluggable seam (persistence, secrets/PKI, IdP, orchestration, discovery/mesh, crypto)
actually satisfies SOM's stipulated requirements — *before* it carries production load. Defines the
**stipulate → connect → certify** model, **tiered per-seam conformance**, the **support boundary**,
the **CI-vs-ephemeral-RC** execution split, the **attestation record**, and how conformance is the
mechanism that **verifies the mesh-level substrate-substitutability invariant (`SOM-SPEC.md` v1.0
SOM-MI-8)**. Cross-cutting spec, not a pillar (cf. `SOM-CONCURRENCY-AND-ARCHETYPES.md`,
`SOM-DELIVERY-PACKAGING.md`); it does NOT alter any pillar contract — it makes the pluggability
promise *enforceable* rather than aspirational.

**Authorship note (inverted origin)**: Bob-authored (infrastructure lane), wave-2 batch #2, going
*up* the chain Bob → Watson → Patton → Einstein → Judge. Patton flagged this spec for the **tightest
adversarial Einstein pass** — the self-certify harness is where a silent gap propagates furthest
(a backend wrongly attested conformant fails in production, and SOM gets blamed for the customer's
substrate). Two-person gate preserved; Judge holds merge.

**Status**: **Draft v0.1**, wave-2 batch #2 (first of two; Control-plane follows). Verify the
per-vendor capability matrix (SQL Server 2025 / Oracle 23ai vector-feature GA-vs-preview status,
pgvector version) before promotion to validated — those are young features and move.

## Purpose / Problem Restatement

SOM's core promise (per `SOM-PROBLEM-STATEMENT.md` + the pluggable-substrate decisions) is: **SOM
stipulates the requirements per seam and ships reference connectors; the customer chooses, implements,
and operates the backend behind each seam.** That promise has a silent-failure mode: *"it's the
customer's job to implement the backend"* degrades into *"the customer plugged in something that
doesn't actually satisfy the interface, it broke in production, and SOM gets blamed."*

The load-bearing question this spec answers: **how does a deployment prove — mechanically, before
go-live — that a chosen substrate satisfies the seam's contract, and where exactly does SOM's
responsibility end and the customer's begin?** Without that proof + that boundary line, pluggability
is an aspiration. With it, pluggability is a contract. Conformance is also the **operational
realization of SOM-MI-8** — the mesh-level invariant that any one pillar's substrate may be
substituted without breaking the mesh; conformance is *how you check that swap is safe*.

## The Conformance Model — stipulate → connect → certify

Three parties, three artifacts, one boundary:

| SOM ships | Customer provides | Result |
|---|---|---|
| **Stipulated requirements** per seam (tiered — see below) | A backend choice (their DB / vault / IdP / orchestrator / HSM) | The requirements the backend must meet |
| **Reference connector** (one solid adapter per seam — default + worked example) | Their connector (customer-written, or the reference if it fits) | The adapter implementing the seam interface against the backend |
| **Conformance suite** (the self-certify tool) | A run of the suite against their (backend + connector) | A PASS/FAIL **attestation** per (seam, tier) |

The customer **self-certifies**: they run SOM's conformance suite against their own substrate and get
a machine-checkable result. SOM does not deploy, operate, or certify the customer's backend — SOM
ships the contract and the test that proves it.

## Conformance Surfaces (the pluggable seams)

Each seam has its own stipulated-requirements contract and conformance profile:

| Seam | Stipulated capability (abstract) | Reference backend | Couples to |
|---|---|---|---|
| **Persistence — relational** | transactional CRUD, ordered writes, append-only event store | PostgreSQL | IBX, ACT |
| **Persistence — vector** | relational + vector-similarity search + metadata pre-filter | PostgreSQL + pgvector | AKB |
| **Secrets / PKI** | issue/store/rotate/zeroize secrets; PKI issue + chain verification | OpenBao (lab) / Vault | IAM (`IAM-CORE-SPEC.md`) |
| **IdP (human + federation)** | LDAP/Kerberos/OIDC identity + role lookup | Samba AD (lab) / MS AD | IAM pluggable-IdP |
| **Orchestration** | schedule/deploy/heal workloads; health-driven lifecycle | Nomad (candidate) / Quadlet | Control-plane (wave-2 #2 item 2), CRB |
| **Discovery / mesh** | service discovery + mTLS transport + non-secret KV | Consul | IAM transport, IBX |
| **Crypto provider** | FIPS-validated approved-algorithm module | OS-FIPS OpenSSL (RHEL) | `SOM-DELIVERY-PACKAGING.md` DP-CD6, `SOM-ENGINEERING-STANDARDS.md` ES-CD13 |

**The interface is defined around the abstract capability, never around the reference backend's
shape** (the established pluggability rule). The reference connector satisfies the interface; it does
not *define* it.

## Tiered Conformance — the tier sets which backends qualify

Conformance is **per-(seam, tier)**, not a single pass/fail. A backend is conformant *for a tier*,
because requirements differ by deployment tier and by pillar capability needs.

- **Solo / SMB / sovereign-lab tier** — free/OSS reference stack (Postgres+pgvector, OpenBao,
  Nomad/Quadlet, Samba AD). The core must run at this tier; enterprise rigor is *additive*.
- **Enterprise / regulated tier** — house backends (SQL Server 2025 / Oracle 23ai, Vault/CyberArk/HSM,
  k8s/OpenShift, MS AD) + FIPS-validated crypto + the regulated audit story.

**Capability gates are real, not cosmetic.** Worked example — the **vector-persistence seam (AKB)**:

| Backend | Vector-persistence conformance (AKB profile) |
|---|---|
| PostgreSQL + pgvector | ✓ qualifies |
| Oracle 23ai (AI Vector Search) | ✓ qualifies |
| SQL Server 2025 | ✓ qualifies — exact `VECTOR_DISTANCE` is GA (sufficient at AKB's ~2.3K-chunk scale; ANN index preview not required) |
| MySQL | ✗ **weak** — does not meet the vector-similarity + pre-filter floor; non-conformant for the AKB profile |

The same backends are all trivially conformant for the *relational-persistence (IBX)* profile. So
"the tier sets which backends qualify" is **per-(seam, profile)** — a backend can pass IBX-relational
and fail AKB-vector. This is why conformance is profiled, not monolithic.

## Closed Decisions (Draft — pending review chain)

**CONF-CD1 — Conformance is per-(seam, tier/profile), not monolithic.** A backend is certified for a
specific seam at a specific tier/capability-profile; "conformant" without that qualification is
meaningless. The stipulated requirements are tiered; the tier sets the qualifying set.

**CONF-CD2 — The three-part contract is fixed: SOM stipulates requirements + ships a reference
connector + ships a conformance suite; the customer chooses/implements/operates the backend and runs
the suite.** SOM never deploys or operates a customer backend.

**CONF-CD3 — Explicit support boundary.** SOM supports the **interface + the reference connector**;
the customer owns everything **below the connector line** (their backend's provisioning, tuning,
patching, availability, DR). The boundary is a stated contract line, material for regulated
customers. A failure below the line is a customer-substrate issue, not a SOM defect — and the
conformance attestation is the evidence that draws the line.

**CONF-CD4 — The conformance suite is the self-certify tool, and a PASS is the install-time gate.**
The customer runs it; `SOM-DELIVERY-PACKAGING.md` DP-CD8's install-time connector-probe **invokes the
conformance suite against the chosen backend before go-live** — a non-conformant backend fails the
install fast, with a structured diagnostic, not silently at first production load.

**CONF-CD5 — Two-tier execution: reference backends in CI routinely; real enterprise backends
ephemerally pre-RC.** Per `SOM-ENGINEERING-STANDARDS.md` ES-CD10 (Testcontainers) + the
EPYC/Proxmox harness: the suite runs (1) every CI build against the *reference* backends
(Postgres+pgvector, Samba AD, OpenBao), and (2) **pre-RC against the real enterprise backends**
(SQL Server 2025 Developer, Oracle 23ai Free, real MS AD) spun up ephemerally and torn down. **RC
gate**: an RC is not cut until the suite passes against the real backends. **Maintain the test
*definition*, not standing infrastructure** — no DBAs, no standing enterprise instances; instances
live only for the run.

**CONF-CD6 — Every conformance run produces a signed attestation record** (`{seam, tier/profile,
backend identity + version, connector version, interface version, suite version, pass-set, timestamp}`)
emitted to **ACT** as an audit artifact. The attestation is the durable proof of *what was certified
against what, when* — the regulated audit trail for the support-boundary contract (CONF-CD3).

**CONF-CD7 — Conformance is the verification mechanism for SOM-MI-8.** A substrate swap at any seam
that passes the (seam, tier) conformance suite is, by construction, a swap that does not break the
mesh contract for that seam. The mesh-level Exit Test (`SOM-SPEC.md` SOM-MI-8) is operationally
*the conjunction of per-seam conformance passes*. No seam's substrate choice may create an obligation
another seam's conformant substrate cannot satisfy.

**CONF-CD8 — No silent partial conformance.** A backend either passes the full (seam, tier) suite or
it is **non-conformant for that tier** — full stop. A backend that meets some-but-not-all requirements
is either (a) conformant at a *lower* explicitly-named tier, or (b) carries a **documented, named,
operator-accepted bounded gap** (a split-store fallback, a deferred capability) recorded in the
attestation. **A silent partial pass is inadmissible** — the same discipline as `SOM-MI-1` /
`SOM-ENGINEERING-STANDARDS.md` ES-OQ4's map/curate/explicit-bounded-drop: you may bound a gap, you
may not hide one.

**CONF-CD9 — Conformance is versioned with the interface (SemVer).** An attestation is valid for the
interface version it was run against; an interface major bump invalidates prior attestations for that
seam and requires re-certification (couples the Layer-2 SDK versioning in
`SOM-ENGINEERING-STANDARDS.md`). The conformance suite ships *with* the connector SDK so the
self-certify capability tracks the interface it tests.

**CONF-CD10 — The reference connector + its conformance pass is the worked example for
customer-written connectors.** A customer writing their own connector targets the same suite; passing
it is the definition of "their connector is correct." The reference is default + teaching artifact,
not a privileged path.

## Deferred-Pending-Increment-2-Rulings (DRs)

**CONF-DR1 (couples DR-IAM-6)**: the **tier set itself** depends on the sovereignty-as-one-mode-vs-
only-mode ruling. If Judge rules sovereignty as *one* mode, new tiers (cloud-backed, hybrid) appear
and each needs its own conformance profile (e.g., Azure SQL vector, AWS KMS). v0.1 commits the
sovereign + enterprise-on-prem tiers; cloud tiers are additive on the ruling.

**CONF-DR2 (couples DR-IAM-2 + DR-IAM-5)**: the **stipulated requirements for the secrets/PKI + IdP
seams** aren't final until the bootstrap-credential (DR-IAM-2) and per-session-credential (DR-IAM-5)
rulings land — the conformance suite for those seams tests against the *pre-ruling* default contract,
and tightens when the rulings resolve.

**CONF-DR3 (couples DR-IAM-1)**: **concurrency-cap conformance** (does the orchestration/persistence
backend support enforcing per-identity caps) couples to the cap-values ruling; v0.1 tests the cap
*mechanism* exists, not specific values.

## Open Questions

1. **Performance conformance scope** — does conformance include performance SLAs (latency/throughput)
   or only *functional capability*? v0.1: **functional only**; perf conformance couples to the
   unresolved mesh-level performance contract (`SOM-SPEC.md` SOM-OQ-4) and is deferred until production
   workloads pressure-test it. Recommendation: keep functional and perf conformance as separate
   profiles so a backend can be functionally-conformant but perf-flagged.
2. **Attestation trust model** — is the self-cert attestation self-signed by the customer (honest-
   broker model) or must it be counter-verifiable for regulated tiers? v0.1: self-signed + ACT-logged.
   Regulated tiers may need a verifiable/witnessed attestation — open.
3. **Conformance drift on backend upgrade** — a backend major upgrade (Postgres 16→17, SQL Server CU)
   can regress conformance. Re-cert cadence / drift-detection is unspecified. Recommendation: tie
   re-cert to the install-time probe (CONF-CD4) running on every upgrade touch, not just first install.
4. **MySQL-class "weak" backends** — formally a *lower named tier* (relational-only, no vector) or
   *excluded*? v0.1 treats it as non-conformant for the vector profile but conformant for relational;
   whether that's a named "relational-only tier" or just two independent profile results is a
   labeling choice to settle.

## Failure Modes To Watch

- **Attestation theater** — the suite passes but doesn't actually exercise the capability the pillar
  needs (e.g., tests vector insert but not pre-filtered similarity at scale). Mitigation: per-pillar
  profiles (CONF-CD1) derived from the *actual* pillar query patterns, not generic capability checks;
  Patton's adversarial pass specifically probes whether the suite tests what the pillar truly needs.
- **Silent partial pass** — a backend meets 9/10 requirements and gets called conformant. Mitigation:
  CONF-CD8 — full-pass-or-named-lower-tier-or-documented-gap; no silent partials.
- **Support-boundary erosion** — a customer-substrate failure gets escalated as a SOM defect.
  Mitigation: CONF-CD3 explicit boundary + CONF-CD6 attestation as the evidence line.
- **Reference-shaped interface** — the interface accidentally encodes a Postgres-ism, so "conformant"
  silently means "Postgres-like." Mitigation: interface defined around abstract capability (model
  rule); the conformance suite runs against ≥2 dissimilar backends in CI to catch reference-coupling.
- **Standing-infra creep** — the "real backend" pre-RC instances become permanent. Mitigation: CONF-CD5
  maintain-test-definition-not-infra; instances are ephemeral per run.
- **Stale attestation** — a backend upgrade regresses conformance but the old attestation still reads
  PASS. Mitigation: CONF-OQ3 re-cert-on-upgrade-touch; attestation carries backend version (CONF-CD6).

## Dependencies

- `SOM-SPEC.md` v1.0 — **SOM-MI-8** (substrate substitutability, the invariant conformance verifies)
  + the mesh-level Exit Test discipline.
- `SOM-PROBLEM-STATEMENT.md` — the pluggable-substrate design driver + the stipulate/connect/certify
  responsibility split.
- `SOM-DELIVERY-PACKAGING.md` v0.1 — **DP-CD8** install-time connector-probe invokes the conformance
  suite (CONF-CD4); DP-CD6 FIPS crypto provider is a conformance seam.
- `SOM-ENGINEERING-STANDARDS.md` v0.1 — **ES-CD10** Testcontainers/EPYC ephemeral RC testing is the
  execution mechanism (CONF-CD5); the conformance harness is the Layer-2 SDK hinge; ES-CD9 persistence
  connector interface.
- `IAM-CORE-SPEC.md` v1.0 — secrets/PKI + IdP seams; the DR-IAM rulings CONF-DR1/2/3 couple to.
- `IBX-SPEC.md` v1.0 + `ACT-SPEC.md` v1.0 — the relational + vector + append-only persistence profiles;
  ACT receives the attestation record (CONF-CD6).

## Success Criteria

- **A customer runs `som` conformance against their backend and gets a per-(seam, tier) PASS/FAIL +
  attestation** without reading SOM source. **Measure**: the Layer-2 SDK conformance harness produces
  a machine-checkable attestation for the reference backends in CI.
- **The install gate refuses a non-conformant backend** with a structured diagnostic (which seam,
  which requirement, why). **Measure**: a deliberately-deficient backend (e.g., MySQL behind the AKB
  vector seam) fails the DP-CD8 probe at install, not at first query.
- **A substrate swap that passes conformance does not break the mesh.** **Measure**: the substrate-swap
  exercise (SOM-MI-8) is realized as a conformance run; passing the (seam, tier) suite is the swap's
  go/no-go.
- **No silent partials.** **Measure**: every attestation is full-pass, named-lower-tier, or
  documented-bounded-gap; CI rejects an attestation that claims conformance with unmet requirements.
- **Reference-coupling caught.** **Measure**: the suite runs against ≥2 dissimilar backends per seam
  in CI; an interface change that only passes the reference backend fails the second.
- **Patton adversarial sign-off** + the **tight wave-2 Einstein cross-substrate pass** (per the
  framing-survives-the-relay discipline). **Measure**: Patton's file-based sign-off; a real (not
  praise) Einstein pass confirmed pointed at this file.

## References

- `planning/SOM-SPEC.md` v1.0 — SOM-MI-8 substrate substitutability; mesh Exit Test
- `planning/SOM-PROBLEM-STATEMENT.md` — pluggable-substrate driver + responsibility split
- `planning/SOM-DELIVERY-PACKAGING.md` v0.1 — DP-CD8 install-time conformance probe; DP-CD6 crypto seam
- `planning/SOM-ENGINEERING-STANDARDS.md` v0.1 — ES-CD10 ephemeral RC testing; Layer-2 SDK harness
- `planning/IAM-CORE-SPEC.md` v1.0 — secrets/PKI + IdP seams; the seven Increment-2 rulings
- `planning/IBX-SPEC.md` v1.0 — relational persistence profile
- `planning/ACT-SPEC.md` v1.0 — append-only persistence profile; attestation audit sink
