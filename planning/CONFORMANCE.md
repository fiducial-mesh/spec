---
title: "the mesh Conformance — Pluggable-Substrate Self-Certification Contract"
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
  - planning/MESH-SPEC.md
  - planning/MANIFESTO.md
  - planning/DELIVERY-PACKAGING.md
  - planning/ENGINEERING-STANDARDS.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/ACT-SPEC.md
---

# the mesh Conformance — Pluggable-Substrate Self-Certification Contract

**Scope**: The contract for how a the mesh deployment **proves** that a customer-chosen substrate
behind a pluggable seam (persistence, secrets/PKI, IdP, orchestration, discovery/mesh, crypto)
actually satisfies the mesh's stipulated requirements — *before* it carries production load. Defines the
**stipulate → connect → certify** model, **tiered per-seam conformance**, the **support boundary**,
the **CI-vs-ephemeral-RC** execution split, the **attestation record**, and how conformance is the
mechanism that **verifies the mesh-level substrate-substitutability invariant (`MESH-SPEC.md` v1.0
MI-8)**. Cross-cutting spec, not a pillar (cf. `CONCURRENCY-AND-ARCHETYPES.md`,
`DELIVERY-PACKAGING.md`); it does NOT alter any pillar contract — it makes the pluggability
promise *enforceable* rather than aspirational.

**Authorship note (inverted origin)**: Bob-authored (infrastructure lane), wave-2 batch #2, going
*up* the chain Bob → Watson → Patton → Einstein → Judge. Patton flagged this spec for the **tightest
adversarial Einstein pass** — the self-certify harness is where a silent gap propagates furthest
(a backend wrongly attested conformant fails in production, and the mesh gets blamed for the customer's
substrate). Two-person gate preserved; Judge holds merge.

**Status**: **Draft v0.1**, wave-2 batch #2 (first of two; Control-plane follows). Verify the
per-vendor capability matrix (SQL Server 2025 / Oracle 23ai vector-feature GA-vs-preview status,
pgvector version) before promotion to validated — those are young features and move.

## Purpose / Problem Restatement

The mesh's core promise (per `MANIFESTO.md` + the pluggable-substrate decisions) is: **the mesh
stipulates the requirements per seam and ships reference connectors; the customer chooses, implements,
and operates the backend behind each seam.** That promise has a silent-failure mode: *"it's the
customer's job to implement the backend"* degrades into *"the customer plugged in something that
doesn't actually satisfy the interface, it broke in production, and the mesh gets blamed."*

The load-bearing question this spec answers: **how does a deployment prove — mechanically, before
go-live — that a chosen substrate satisfies the seam's contract, and where exactly does the mesh's
responsibility end and the customer's begin?** Without that proof + that boundary line, pluggability
is an aspiration. With it, pluggability is a contract. Conformance is also the **operational
realization of MI-8** — the mesh-level invariant that any one pillar's substrate may be
substituted without breaking the mesh; conformance is *how you check that swap is safe*.

## The Conformance Model — stipulate → connect → certify

Three parties, three artifacts, one boundary:

| The mesh ships | Customer provides | Result |
|---|---|---|
| **Stipulated requirements** per seam (tiered — see below) | A backend choice (their DB / vault / IdP / orchestrator / HSM) | The requirements the backend must meet |
| **Reference connector** (one solid adapter per seam — default + worked example) | Their connector (customer-written, or the reference if it fits) | The adapter implementing the seam interface against the backend |
| **Conformance suite** (the self-certify tool) | A run of the suite against their (backend + connector) | A PASS/FAIL **attestation** per (seam, tier) |

The customer **self-certifies**: they run the mesh's conformance suite against their own substrate and get
a machine-checkable result. The mesh does not deploy, operate, or certify the customer's backend — the mesh
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
| **Crypto provider** | FIPS-validated approved-algorithm module | OS-FIPS OpenSSL (RHEL) | `DELIVERY-PACKAGING.md` DP-CD6, `ENGINEERING-STANDARDS.md` ES-CD13 |

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

**CONF-CD2 — The three-part contract is fixed: The mesh stipulates requirements + ships a reference
connector + ships a conformance suite; the customer chooses/implements/operates the backend and runs
the suite.** The mesh never deploys or operates a customer backend.

**CONF-CD3 — Explicit support boundary.** The mesh supports the **interface + the reference connector**;
the customer owns everything **below the connector line** (their backend's provisioning, tuning,
patching, availability, DR). The boundary is a stated contract line, material for regulated
customers. A failure below the line is a customer-substrate issue, not a the mesh defect — and the
conformance attestation is the evidence that draws the line.

**CONF-CD4 — The conformance suite is the self-certify tool, and a PASS is the install-time gate.**
The customer runs it; `DELIVERY-PACKAGING.md` DP-CD8's install-time connector-probe **invokes the
conformance suite against the chosen backend before go-live**, completing the **three-gate install
composite** — host-prerequisites pre-flight (DP-CD7) → external-infrastructure connector-probe (DP-CD8)
→ backend conformance suite (this spec). A non-conformant backend fails the install fast, with a
structured diagnostic, not silently at first production load.

**CONF-CD5 — Two-tier execution: reference backends in CI routinely; real enterprise backends
ephemerally pre-RC.** Per `ENGINEERING-STANDARDS.md` ES-CD10 (Testcontainers) + the
EPYC/Proxmox harness: the suite runs (1) every CI build against the *reference* backends
(Postgres+pgvector, Samba AD, OpenBao), and (2) **pre-RC against the real enterprise backends**
(SQL Server 2025 Developer, Oracle 23ai Free, real MS AD) spun up ephemerally and torn down. **RC
gate**: an RC is not cut until the suite passes against the real backends. **Maintain the test
*definition*, not standing infrastructure** — no DBAs, no standing enterprise instances; instances
live only for the run.

**CONF-CD6 — Every conformance run produces a signed attestation record** (`{seam, tier/profile,
backend identity + version, connector version, interface version, suite version, pass-set, timestamp}`)
emitted to **ACT** as an audit artifact. **ACT event-type**: the `conf.*` namespace (e.g.
`conf.attestation_emitted`) — *new*, so it extends ACT's bounded enum only via a curation event per
MI-6 (tracked as **CONF-VP-1**, same pattern as the wave-1 `pcs.*`/`dpg.*`/`crb.*`/`pge.*`
namespaces); pre-curation bounded fallback is `act.detection_signal` with `signal_type=conf_attestation`.
**Signing identity**: the attestation is signed by the **customer's own IdP-issued identity** (per the
CD13 external-anchor invariant) — the mesh does NOT mint conformance-signing identities; conformance
*consumes* verified identity from IAM (MI-3) and never *produces* it. Self-cert is an honest-broker
model (CONF-OQ2 tracks whether regulated tiers need witnessed verification). The attestation is the
durable proof of *what was certified against what, when* — the regulated audit trail for the
support-boundary contract (CONF-CD3).

**CONF-CD7 — Conformance verifies MI-8 — per-seam pass is *necessary*; cross-seam interaction
tests are required for *sufficient*.** A substrate swap that passes the (seam, tier) suite satisfies
*that seam's* contract — the necessary condition. But MI-8 has two halves: (a) substrate satisfies
seam contract (per-seam), AND (b) no pillar's substrate creates lock-in for another (cross-seam) — and
per-seam tests do not catch (b) (e.g. Postgres-as-IBX creating an implicit dependency pgvector-as-AKB
cannot satisfy fires no per-seam test). So the mesh-level Exit Test (`MESH-SPEC.md` MI-8) requires
**both**: (1) the conjunction of per-seam conformance passes (necessary), AND (2) a **cross-seam
interaction test set** exercising seam-substrate combinations *together* under the actual mesh query
patterns (the sufficient layer; see CONF-OQ5). Per-seam conformance alone is necessary, not sufficient.

**CONF-CD8 — No silent partial conformance.** A backend either passes the full (seam, tier) suite or
it is **non-conformant for that tier** — full stop. A backend that meets some-but-not-all requirements
is either (a) conformant at a *lower* explicitly-named tier, or (b) carries a **documented, named,
operator-accepted bounded gap** (a split-store fallback, a deferred capability) recorded in the
attestation. **A silent partial pass is inadmissible** — the same discipline as `MI-1` /
`ENGINEERING-STANDARDS.md` ES-OQ4's map/curate/explicit-bounded-drop: you may bound a gap, you
may not hide one.

**CONF-CD9 — Conformance is versioned with the interface (SemVer).** An attestation is valid for the
interface version it was run against; an interface major bump invalidates prior attestations for that
seam and requires re-certification (couples the Layer-2 SDK versioning in
`ENGINEERING-STANDARDS.md`). The conformance suite ships *with* the connector SDK so the
self-certify capability tracks the interface it tests.

**CONF-CD10 — The reference connector + its conformance pass is the worked example for
customer-written connectors.** A customer writing their own connector targets the same suite; passing
it is the definition of "their connector is correct." The reference is default + teaching artifact,
not a privileged path.

**CONF-CD11 — Conformance profile derivation is owned by the pillar.** The (seam, tier/profile)
conformance profile for any pillar is **derived from that pillar's actual query/usage patterns**, not
from generic capability checklists. The pillar spec is the source of truth for what its substrate must
support; the conformance-spec author reviews for completeness but does not invent profile content.
Concretely: AKB's vector profile lists AKB's *actual* query shapes (pre-filtered similarity at
chunk-scale + the metadata predicates AKB uses); IBX's relational profile lists IBX's *actual*
SKIP-LOCKED claim + idempotency patterns. A pillar change that alters substrate exercise requires the
corresponding profile update before the next conformance run. This is what keeps CONF-CD8 honest — you
cannot *fail* an attestation-theater profile, so the profile must be true to the pillar to be worth running.

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

## Validation-Pending (VP)

**CONF-VP-1 — `conf.*` ACT event-type namespace.** The attestation emission (CONF-CD6) introduces a
`conf.*` event-type; per ACT v1.0 CD4 + MI-6 the bounded enum extends only via a curation event.
CONF-VP-1 routes through the **VP-1** curation discipline (the same atomic-curation pattern as the
wave-1 `pcs.*`/`dpg.*`/`crb.*`/`pge.*` namespaces); pre-curation operational fallback is
`act.detection_signal` with `signal_type=conf_attestation`. Resolves when the ACT v1.x curation event lands.

## Open Questions

1. **Performance conformance scope** — does conformance include performance SLAs (latency/throughput)
   or only *functional capability*? v0.1: **functional only**; perf conformance couples to the
   unresolved mesh-level performance contract (`MESH-SPEC.md` OQ-4) and is deferred until production
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
5. **Cross-seam interaction test set** (per CONF-CD7 sufficiency layer) — does the harness ship the
   cross-seam interaction tests at v0.1, defer them, or run them as a separate mesh-integration layer
   distinct from per-seam conformance? Recommendation: a separate mesh-integration layer consuming the
   same backends at the pre-RC tier (CONF-CD5) — per-seam conformance in CI, cross-seam pre-RC — so the
   sufficiency check exists without bloating the per-seam self-certify suite.

## Failure Modes To Watch

- **Attestation theater** — the suite passes but doesn't actually exercise the capability the pillar
  needs (e.g., tests vector insert but not pre-filtered similarity at scale). Mitigation: per-pillar
  profiles (CONF-CD1) derived from the *actual* pillar query patterns, not generic capability checks;
  Patton's adversarial pass specifically probes whether the suite tests what the pillar truly needs.
- **Silent partial pass** — a backend meets 9/10 requirements and gets called conformant. Mitigation:
  CONF-CD8 — full-pass-or-named-lower-tier-or-documented-gap; no silent partials.
- **Support-boundary erosion** — a customer-substrate failure gets escalated as a the mesh defect.
  Mitigation: CONF-CD3 explicit boundary + CONF-CD6 attestation as the evidence line.
- **Reference-shaped interface** — the interface accidentally encodes a Postgres-ism, so "conformant"
  silently means "Postgres-like." Mitigation: interface defined around abstract capability (model
  rule); the conformance suite runs against ≥2 dissimilar backends in CI to catch reference-coupling.
- **Standing-infra creep** — the "real backend" pre-RC instances become permanent. Mitigation: CONF-CD5
  maintain-test-definition-not-infra; instances are ephemeral per run.
- **Stale attestation** — a backend upgrade regresses conformance but the old attestation still reads
  PASS. Mitigation: CONF-OQ3 re-cert-on-upgrade-touch; attestation carries backend version (CONF-CD6).

## Dependencies

- `MESH-SPEC.md` v1.0 — **MI-8** (substrate substitutability, the invariant conformance verifies)
  + the mesh-level Exit Test discipline.
- `MANIFESTO.md` — the pluggable-substrate design driver + the stipulate/connect/certify
  responsibility split.
- `DELIVERY-PACKAGING.md` v0.1 — **DP-CD8** install-time connector-probe invokes the conformance
  suite (CONF-CD4); DP-CD6 FIPS crypto provider is a conformance seam.
- `ENGINEERING-STANDARDS.md` v0.1 — **ES-CD10** Testcontainers/EPYC ephemeral RC testing is the
  execution mechanism (CONF-CD5); the conformance harness is the Layer-2 SDK hinge; ES-CD9 persistence
  connector interface.
- `IAM-CORE-SPEC.md` v1.0 — secrets/PKI + IdP seams; the DR-IAM rulings CONF-DR1/2/3 couple to.
- `IBX-SPEC.md` v1.0 + `ACT-SPEC.md` v1.0 — the relational + vector + append-only persistence profiles;
  ACT receives the attestation record (CONF-CD6).

## Success Criteria

- **A customer runs `som` conformance against their backend and gets a per-(seam, tier) PASS/FAIL +
  attestation** without reading the mesh source. **Measure**: the Layer-2 SDK conformance harness produces
  a machine-checkable attestation for the reference backends in CI.
- **The install gate refuses a non-conformant backend** with a structured diagnostic (which seam,
  which requirement, why). **Measure**: a deliberately-deficient backend (e.g., MySQL behind the AKB
  vector seam) fails the DP-CD8 probe at install, not at first query.
- **A substrate swap that passes conformance does not break the mesh.** **Measure**: the substrate-swap
  exercise (MI-8) is realized as a conformance run; passing the (seam, tier) suite is the swap's
  go/no-go.
- **No silent partials.** **Measure**: every attestation is full-pass, named-lower-tier, or
  documented-bounded-gap; CI rejects an attestation that claims conformance with unmet requirements.
- **Reference-coupling caught.** **Measure**: the suite runs against ≥2 dissimilar backends per seam
  in CI; an interface change that only passes the reference backend fails the second.
- **Patton adversarial sign-off** + the **tight wave-2 Einstein cross-substrate pass** (per the
  framing-survives-the-relay discipline). **Measure**: Patton's file-based sign-off; a real (not
  praise) Einstein pass confirmed pointed at this file.

## References

- `planning/MESH-SPEC.md` v1.0 — MI-8 substrate substitutability; mesh Exit Test
- `planning/MANIFESTO.md` — pluggable-substrate driver + responsibility split
- `planning/DELIVERY-PACKAGING.md` v0.1 — DP-CD8 install-time conformance probe; DP-CD6 crypto seam
- `planning/ENGINEERING-STANDARDS.md` v0.1 — ES-CD10 ephemeral RC testing; Layer-2 SDK harness
- `planning/IAM-CORE-SPEC.md` v1.0 — secrets/PKI + IdP seams; the seven Increment-2 rulings
- `planning/IBX-SPEC.md` v1.0 — relational persistence profile
- `planning/ACT-SPEC.md` v1.0 — append-only persistence profile; attestation audit sink
