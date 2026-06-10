---
title: "FIDUCIAL-MESH-STD-001 — Fiducial Mesh Platform Standard"
doc_type: standard
status: draft
version: v0.1
date: 2026-06-09
authors:
  - "Fiducial Mesh Group"
companion_to: FIDUCIAL-MESH-HDBK-001.md
references:
  - https://datatracker.ietf.org/doc/html/rfc2119
  - https://modelcontextprotocol.io/specification
  - https://code.claude.com/docs/en/plugins-reference
  - https://developers.openai.com/codex/plugins/build
  - https://agentskills.io/specification
---

# FIDUCIAL-MESH-STD-001 — Fiducial Mesh Platform Standard

## §0 Standard conventions

This Standard defines the normative requirements for the Fiducial Mesh
platform. It is the source of truth for what conformant implementations
**shall** do. Rationale, design history, and operational narrative live
in the companion handbook [`FIDUCIAL-MESH-HDBK-001`](FIDUCIAL-MESH-HDBK-001.md).

### §0.1 Requirement language (RFC 2119)

The key words **shall**, **shall not**, **should**, **should not**,
**may**, and **may not** in this document are to be interpreted as
described in IETF RFC 2119. Non-RFC-2119 prose carries no normative
weight; it is explanatory only.

### §0.2 Requirement identifiers

Every normative requirement in this Standard is assigned a unique
identifier of the form `[FM-<area>-NNNN]` (e.g., `[FM-INV-0001]`,
`[FM-PCS-0042]`). Sub-clauses use decimal extensions (`[FM-INV-0003.2]`).

Requirement identifiers are **immutable and append-only.** Once
assigned, an identifier **shall not** be renumbered, reused, or
reassigned to a different requirement. Deprecated requirements
**shall** be marked `[FM-<area>-NNNN][DEPRECATED]` and **shall** remain
in the Standard with their deprecation rationale recorded. New
requirements **shall** be assigned the next unused integer in their
area's sequence. Identifiers are referenced from the conformance
harness, conformance profiles, regulatory crosswalks, and customer
attestations; identifier stability is the foundation those downstream
artifacts depend on.

### §0.3 Companion handbook discipline

The companion handbook (`FIDUCIAL-MESH-HDBK-001`) explains, illustrates,
and motivates the requirements in this Standard. The handbook **shall**
cite Standard requirements by identifier; it **shall not** restate the
normative text of a requirement. Bi-directional restating produces
drift; this Standard is the single source of truth for normative
content.

### §0.4 Conformance profiles

Every conformance-profile row defined for a substrate seam **shall**
bind to one or more requirement identifiers in this Standard. A
profile row without a bound identifier is not a conformant artifact;
the conformance harness rejects it. Substrate matrices declared per
pillar are conformance profiles in this sense.

### §0.5 Verification methods

Every numbered requirement in this Standard **shall** carry a
`Verification:` annotation specifying how conformance to the
requirement is verified. The annotation appears as the final line of
each requirement block.

Allowed verification methods:

| Method | Meaning |
|--------|---------|
| **Inspection** | Visual or document review — verified by reading code, configuration, or documentation against the requirement text. |
| **Analysis** | Mathematical, logical, or formal proof — verified by demonstration that the implementation cannot violate the requirement (e.g., type-system guarantees, cryptographic argument). |
| **Demonstration** | Operational behavior shown — verified by exercising the system end-to-end and observing the required behavior. |
| **Test** | Formal test procedure — verified by an executable test case that fails when the requirement is violated. |
| **Conformance-test** | Automated test in the Fiducial Mesh conformance harness — verified mechanically against the deployed substrate. Subset of Test, distinguished because Conformance-test is binding for substrate-matrix profile rows per §0.4. |
| **Static-check** | Automated lint, grep, AST analysis, or signature check — verified at build or commit time without running the system. |

A requirement that cannot be assigned a verification method is not
ready to merge into this Standard — by construction, "a requirement
the harness cannot check is not done." The verification method is the
bridge from this Standard to the conformance harness.

### §0.6 Out of scope for this Standard

This Standard adopts NASA Technical Standard structural conventions
(numbered requirements, RFC 2119 keywords, normative appendices, the
STD/HDBK companion pattern). It does **not** adopt:

- Approval-signature pages, change-authority forewords, or formal
  change-request trappings
- Mandatory configuration-control-board procedures
- Document classification markings (Fiducial Mesh ships GPLv3 OSS)
- Cancellation and supersession procedures specific to federal-agency
  standards processes

Changes to this Standard follow the Fiducial Mesh GH-native PR
convention: author-review-merge by the project's two-person review
discipline, with Judge as the merge gate.

---

## §1 Scope

This Standard defines the normative platform-level requirements
Fiducial Mesh implementations **shall** satisfy. It covers the
foundational invariants every pillar inherits, the cross-pillar
contracts (validation harness tiers, registry behavior,
substrate-matrix conformance discipline), the per-pillar
requirements for the **eight pillars** (IBX, IAM, PGE, ACT, AKB,
DPG, CRB in §§5.1–5.7; PCS in §6) plus the **MCC host frame**
(§5.8) that hosts them, and the operational disciplines (security
framework, delivery and packaging substrate, AIR/CLCA continuous-
improvement loop).

This Standard is **substrate-pluggable**: it defines what
implementations and deployments **shall** do, not what specific
backend products **shall** be used. Customer choice across the
substrate-matrix seams is a first-class property; conformance is
verified by passing the multi-profile conformance run against the
declared matrix rows.

This Standard is **language-neutral.** It defines *behavior*, not
the language an implementation is written in. A conforming
implementation **may** be written in any language or framework;
conformance is established solely by passing the multi-profile
conformance run, which is blind to implementation language. The
Standard specifies substrate *capabilities* where they are
contract-relevant (e.g., transactional claim semantics,
JSONB-equivalent query support, FIPS-validated cryptographic
modules) and the *workload runtimes* a pillar must accept — but it
**shall not** mandate the implementation language or framework of
any pillar. Reference-implementation language choices live in the
engineering-standards companion document, not in this Standard.

This Standard targets **on-premises sovereign deployment**.
Vendor-managed cloud substrate is **not in scope**; the architecture
is air-gapped-ready and exfiltration-hostile by construction.

---

## §2 Applicable Documents

The following documents form a part of this Standard to the extent
specified herein.

### §2.1 Government and standards-body documents

| Reference | Title |
|-----------|-------|
| IETF RFC 2119 | Key words for use in RFCs to Indicate Requirement Levels |
| NIST SP 800-53 | Security and Privacy Controls for Information Systems |
| FIPS 140-3 | Security Requirements for Cryptographic Modules |
| ICD 705 | Sensitive Compartmented Information Facilities |

### §2.2 Industry / open standards

| Reference | Title |
|-----------|-------|
| Model Context Protocol Specification | `modelcontextprotocol.io/specification` |
| Open Agent Skills Standard | `agentskills.io/specification` |
| Anthropic Claude Code Plugin Reference | `code.claude.com/docs/en/plugins-reference` |
| OpenAI Codex Plugin Specification | `developers.openai.com/codex/plugins/build` |
| Maven Coordinate Conventions | groupId:artifactId:version |
| Shamir's Secret Sharing (1979) | K-of-N threshold cryptography |

### §2.3 Companion documents

| Reference | Role |
|-----------|------|
| [`FIDUCIAL-MESH-HDBK-001`](FIDUCIAL-MESH-HDBK-001.md) | Companion handbook — rationale, philosophy, worked examples |

---

## §3 Acronyms and Definitions

### §3.1 Acronyms

| Acronym | Expansion |
|---------|-----------|
| ACT | Agent Cognitive Telemetry (pillar) |
| AD | Active Directory (Microsoft directory service; Samba AD is the open-source equivalent) |
| AIR | After-Incident Report |
| AKB | Agent Knowledge Base (pillar) |
| ARCA | Agentic Root Certificate Authority |
| BOM | Bill of Materials (versioned signed registry artifact pinning a coherent plugin set) |
| CLCA | Closed Loop Corrective Action (Ford 8D discipline) |
| CRB | Compute Resource Broker (pillar) |
| CUDA | Compute Unified Device Architecture (NVIDIA GPU computing platform) |
| DPG | Deterministic Proving Ground (pillar) |
| FIPS | Federal Information Processing Standards |
| GPU | Graphics Processing Unit |
| HDBK | Handbook (NASA document type) |
| HSM | Hardware Security Module |
| IAM | Identity and Access Management (pillar) |
| IBX | Inbox Exchange (pillar) |
| IdP | Identity Provider |
| KMS | Key Management Service |
| LDAP | Lightweight Directory Access Protocol |
| MCC | Mesh Control Center (host frame; **not** a pillar — see `[FM-MCC-0011]`) |
| MCP | Model Context Protocol |
| MFA | Multi-Factor Authentication |
| MPS | Metal Performance Shaders (Apple GPU computing API) |
| OCI | Oracle Cloud Infrastructure (used in this Standard exclusively for the Oracle cloud provider; not to be confused with the Open Container Initiative) |
| OIDC | OpenID Connect |
| OTLP | OpenTelemetry Protocol |
| PCS | Platform Control System (pillar) |
| PCT | Principal Control Token |
| PGE | Policy Guardrail Engine (pillar) |
| PIV-CAC | Personal Identity Verification — Common Access Card |
| PKCS | Public-Key Cryptography Standards |
| ROCm | Radeon Open Compute platform (AMD GPU computing platform) |
| SAML | Security Assertion Markup Language |
| SCIF | Sensitive Compartmented Information Facility |
| SHA | Secure Hash Algorithm |
| STD | Standard (NASA document type) |
| TLS | Transport Layer Security |
| VMA | Vendor-Mediated Architecture |

### §3.2 Definitions

**Capability.** A platform-level affordance that enables some class of
action. Distinguished from *policy* (which gates the use of an
already-provisioned capability) and from *identity scope* (which
authorizes a specific principal to invoke a capability).

**Catastrophic-class capability.** A capability whose mis-use would
have consequences that cannot be operationally reversed within the
audit horizon, including (non-exhaustively): policy-overlay
apply/revoke, root-CA revocation, mass identity action, trust-root
key rotation, irreversible substrate decommission. See `[FM-INV-0004]`.

**Conformance profile.** A row in a pillar's substrate matrix
declaring a specific substrate as supported. Each profile row binds to
one or more requirement identifiers and is verified by the
multi-profile conformance run.

**Plugin (PCS plugin).** A bundle that satisfies the cardinal-rule
superset of an Anthropic Claude Code plugin and an OpenAI Codex plugin
and additionally carries the PCS extension territory (`.pcs/`,
`workflows/`).

**Quorum (K-of-N).** A threshold attestation pattern in which K
independent identities, drawn from a pre-provisioned set of N,
**shall** each independently sign an attestation before a gated
operation is permitted. See `[FM-INV-0004]`.

**Workflow.** A composed, parameterized, version-controlled operation
defined within a plugin. Workflows compose plugin components (skills,
hooks, MCP servers, agents, runbooks) with declared parameters and an
ordered lifecycle.

---

## §4 Top-Level Invariants

This section defines the platform-level invariants that **shall** hold
across every pillar and every workflow. Pillar-specific requirements
in subsequent sections inherit and refine these invariants but
**shall not** relax them.

### §4.1 Authentication and fail-strict

#### `[FM-INV-0001]` No bypass — authenticated principal required

The platform **shall not** permit any action, data access, or approval
to occur without an authenticated principal.

No actor — human, agent, plugin, or service — **shall** be granted
operation by virtue of network location, container co-residency, or
implementation language. There **shall not** exist a "trusted because
internal" path. No standing god-rights account **shall** exist; no
bootstrap path that runs before identity verification is operational
**shall** exist.

*Verification: Conformance-test* — the harness exercises representative
operation paths without a valid principal and asserts denial.

#### `[FM-INV-0002]` Fail strict

Under error, ambiguity, unavailability, or unverifiable state, the
platform **shall** halt the affected operation and **shall not**
proceed.

A principal whose credential cannot be confirmed valid **shall** stop.
An action whose authorization cannot be resolved **shall** be denied.
An identity verification request that cannot be completed **shall not**
default to "allow." When in doubt, the platform **shall** halt.

*Verification: Conformance-test* — the harness injects each
fail-strict condition (unreachable IAM, unverifiable credential,
ambiguous authorization) and asserts halt-not-proceed.

##### `[FM-INV-0002.1]` Fail-strict deadline

Every fail-strict point that depends on an external acknowledgment
(IAM identity-context lookup, ACT emission-confirmation per
`[FM-ACT-0009]`, PGE policy decision per `[FM-PGE-0008]`, any other
cross-pillar verification that may not return in bounded time)
**shall** be governed by a **fail-strict deadline** — a positive
duration beyond which absence-of-ack is treated as negative-ack and
the operation halts per `[FM-INV-0002]`.

The deadline **shall** be operator-configurable per deployment with
a documented default. Each requirement that invokes "the fail-strict
deadline" anchors here.

**Worker-pool safety constraint.** The fail-strict deadline **shall
be strictly shorter** than the minimum worker-pool lease /
visibility-timeout window any conformant pillar exposes — including
but not limited to `[FM-IBX-0009]` claim-queue substrate lease and
the worker-pool lease windows of any `[FM-IBX-0007]`-consuming pillar
(DPG runners per `[FM-DPG-0007]`, future pillar workers). This
constraint prevents the failure mode in which an upstream operation
holds a worker-pool claim past the lease window while waiting for an
external ack: the lease expires, the message is re-claimed by another
worker, and the original ack-wait races the new execution producing
duplicate work. Idempotency keys at the message layer guard the
terminal-status transition but **do not** guard against the duplicate
execution path; the deadline constraint is what makes the duplicate
execution structurally impossible.

A deployment whose declared deadline is greater than or equal to the
minimum worker-pool lease window is non-conforming. Implementations
**should** publish the resolved (deadline, min-lease-window) pair at
deployment-attestation time per the §F.3 registry integrity
requirements.

*Verification: Static-check + Conformance-test* — Static-check
verifies the deployment configuration declares a deadline strictly
less than the minimum worker-pool lease window; Conformance-test
exercises an external-ack point with injected delay greater than the
deadline and asserts the operation halts (and that no duplicate
execution occurs); exercises with delay just less than the deadline
and asserts the operation completes normally.

### §4.2 Capability provisioning as primary defense

#### `[FM-INV-0003]` Capability provisioning is the primary defense

The mesh **shall** provision the minimum capability set consistent with
its declared purpose. Policy **shall** gate use of provisioned
capabilities; policy **shall not** be used to expand the capability
surface beyond what has been explicitly provisioned with an argued
case.

*Verification: Inspection* — each provisioned capability in the
Standard cites an argued-case section per `[FM-INV-0003.2]`; review
verifies presence and adequacy.

##### `[FM-INV-0003.1]` Extensions compose within the provisioned surface

PCS plugins, workflows, and components **shall** compose only within
the capability surface already provisioned by the pillar implementations
and their declared substrate matrices. A plugin **shall not** introduce
a capability that the underlying pillars do not already expose.

*Verification: Conformance-test* — the validation harness rejects any
plugin whose declared capability surface (`.pcs/plugin.pcs.json`
policy block, per §6 and Appendix B) references a capability not
present in the deployment's provisioned-capability registry.

##### `[FM-INV-0003.2]` Net-new capability requires argued-case plus quorum

Provisioning a net-new platform-level capability — a new pillar, an
extended substrate matrix row, a new agent surface, or any other
expansion of what the platform allows — **shall** require an *argued
case* and **shall** be gated at apply time by the quorum mechanism
defined in `[FM-INV-0004]`.

An **argued case** for the purposes of this Standard is a written
rationale satisfying all of the following:

1. It is committed to a designated section of this Standard or to a
   referenced amendment document (default location: Appendix F,
   reserved for argued cases and deviations, to be created in
   subsequent PRs).
2. It answers the `[FM-INV-0003.3]` decision test affirmatively, with
   explicit identification of the consumer(s) and the operational need.
3. It specifies the policy gates, identity scopes, audit emissions,
   and (where applicable) quorum-class classification per
   `[FM-INV-0004]` that govern the new capability.
4. It is signed by an identity authorized to author Standard
   amendments (per the IAM publishing-rights model — see §5 IAM
   requirements when landed).
5. It is bound to a requirement identifier in this Standard via the
   conformance-profile mechanism per §0.4.

A capability without an argued case satisfying these five criteria is
not "provisioned" within the meaning of `[FM-INV-0003]` and the
platform **shall not** treat it as authorized for use.

*Verification: Inspection* — at amendment merge, the review process
confirms presence of the five-element argued case bound to a
requirement identifier.

##### `[FM-INV-0003.3]` Decision test for new capability proposals

When a new capability is proposed for the mesh, the proposal **shall**
answer the question: *"Do we want any principal — anywhere, ever — to
be able to perform this operation?"* If the answer is no, the
capability **shall not** be provisioned; policy cannot make a
non-existent capability safer than its non-existence. If the answer
is yes, the proposal **shall** specify the policy gates, identity
scopes, audit emissions, and (where applicable) quorum-class
classification per `[FM-INV-0004]` that govern its use.

*Verification: Inspection* — proposal review confirms the test is
answered explicitly with one of {no, yes-with-gates}; an unanswered
or ambiguous test blocks merge.

### §4.3 Quorum authority for catastrophic-class capabilities

#### `[FM-INV-0004]` Quorum authority for catastrophic-class capabilities

For any capability classified as catastrophic-class, authority
**shall** be distributed across N independent identities via
**K-of-N multi-signature attestation enforced by an independent
verifier**. Single-identity wielding of a catastrophic-class
capability **shall** be **non-conformant by construction** — the
verifier counts attestations and the operation does not apply
without K-of-N signatures from independent identities.

**Mechanism precision.** Two distinct mechanisms appear under the
quorum authority discipline; they are not the same and **shall not**
be conflated:

- **Mesh-init quorum-bootstrap ceremony per `[FM-INV-0004.4]`** —
  uses **Shamir's Secret Sharing** to split the quorum-authority
  master at initialization. K-of-N independent holders receive
  cryptographic shards; the master can be reconstructed only when
  K shards are presented together. This is the *init-time*
  Shamir-shard model, parallel to the Vault unseal pattern.
- **Runtime catastrophic-class operations** (applying or revoking
  policy overlays; mass identity action; ARCA revocation;
  substrate decommission, etc.) — use **K-of-N multi-signature
  attestation counting**. K independent identities each sign an
  attestation; the verifier counts attestations and applies the
  operation only when K signatures are present. Nothing is
  reconstructed from shards at runtime.

The Standard binds both patterns; the *which-applies-when* is
mechanical and depends only on whether the operation is the
init-time ceremony per `[FM-INV-0004.4]` (Shamir) or a runtime
catastrophic-class operation (multi-sig attestation).

**Verifier integrity** is the load-bearing assumption for the
runtime multi-sig pattern: a compromised verifier that proceeds
with fewer than K attestations is a runtime-side defect classified
per `[FM-INV-0005]` (platform enforcement floor is authoritative).
The multi-sig pattern itself does not defend against verifier
compromise; the platform-floor invariant does.

Catastrophic-class capabilities include, non-exhaustively: applying
or revoking a policy overlay; revoking the ARCA root CA; minting a
new overlay-author identity; rotating the trust-root key chain;
mass identity action affecting the entire workforce; substrate
decommission or irreversible data destruction.

*Verification: Conformance-test* — the harness submits a runtime
catastrophic-class operation request signed by fewer than K
independent identities and asserts the operation is not applied;
exercises the mesh-init quorum-bootstrap ceremony per
`[FM-INV-0004.4]` and asserts shard-based reconstruction requires
K independent holders presenting shards; verifies the
verifier-integrity assumption is documented in the deployment's
attestation per `[FM-INV-0005]`.

##### `[FM-INV-0004.1]` Asymmetric apply-vs-revoke thresholds

The K threshold for applying (arming) a catastrophic-class operation
**shall** be greater than or equal to the K threshold for revoking
(firing) the same operation, where applicable. Emergency revocation
**shall not** be blocked by a quorum threshold equivalent to the apply
threshold.

*Verification: Inspection* — each catastrophic-class capability's PGE
policy declaration cites both K-apply and K-revoke values; review
confirms K-apply ≥ K-revoke.

##### `[FM-INV-0004.2]` Time-bounded attestation windows

Each attestation toward a K-of-N quorum **shall** carry an expiration
timestamp. If K-of-N attestations are not collected within the
configured window, all collected attestations **shall** expire and the
quorum process **shall** restart. Stale attestations **shall not** be
retained for later use beyond their declared window.

**Time model + clock-skew tolerance.** Attestation timestamps span
N independent identity holders on N independent hosts / HSMs;
expiry evaluation **shall** therefore be governed by an explicit
time model:

1. Timestamps **shall** be issued against an **authenticated time
   source** the deployment declares (e.g., a Roughtime or NTS-
   authenticated network time service; the local HSM clock when
   the holder operates from a hardware token). Wall-clock-only
   attestation without a documented authenticated time source is
   non-conforming for catastrophic-class operations.
2. Expiry evaluation **shall** be performed at the **verifier
   side** (the apply-side gate aggregating the K-of-N
   attestations), not at the attester side; this prevents an
   attester with a fast clock from emitting attestations that
   appear pre-expired at the verifier.
3. The verifier **shall** apply an **operator-configurable skew
   tolerance** (default: 30 seconds) when comparing attester-
   stamped expiry to verifier wall-clock. An attestation whose
   declared expiry is within the tolerance window of verifier
   wall-clock **shall** be treated as valid; expiry outside the
   tolerance window is honored.
4. Emergency revocation per `[FM-INV-0004.1]` (the fast-path
   apply / lower threshold for revoke) **shall not** be blocked by
   clock-skew misclassification — when the verifier observes an
   apparent expiry that would block emergency revocation, the
   skew tolerance applies asymmetrically (larger window on the
   revoke side, default: 5 minutes) to keep emergency revocation
   unblocked even under sustained skew.

A deployment **shall** publish its declared time source + skew
tolerance values as part of its attestation per the §F.3 registry
integrity requirements.

*Verification: Conformance-test* — the harness submits an attestation,
advances clock past the window without reaching K-of-N, and asserts
all attestations have expired and the operation cannot apply with the
expired attestation set; **injects clock skew at the attester side
within the tolerance window and asserts the attestation is honored;
injects skew exceeding the tolerance and asserts the attestation is
rejected; exercises emergency revocation under sustained skew and
asserts the asymmetric tolerance keeps the revoke path open**.

##### `[FM-INV-0004.3]` Role-typed quorum membership

A catastrophic-class operation **may** specify role requirements
in addition to the K-of-N threshold. When role-typed quorum is
specified, the K attesting identities **shall** collectively cover the
required role set, and the absence of any required role **shall**
prevent the operation regardless of total attestation count.

**Role specification.** Each catastrophic-class capability's PGE
policy declaration **shall** identify required roles by name, where a
"role" is an identity attribute (assigned via the IAM identity-role
mapping defined in §5 IAM requirements when landed) drawn from the
operator's named role registry. The role registry is operator-defined
at mesh initialization; common entries include `hipaa-compliance-officer`,
`fedramp-iso`, `ciso`, `legal-counsel`.

**Role verification at attestation time.** When an attestation is
submitted, the quorum verifier **shall** (1) verify the attesting
identity's signature against IAM's trust chain, (2) read the
attesting identity's assigned roles from IAM, and (3) record both
the identity and its role set in the quorum-collection state. Quorum
completion requires K signed attestations AND coverage of every
declared required role at least once across the K signers.

*Verification: Conformance-test* — the harness submits K signed
attestations missing a declared required role and asserts the
operation is not applied; then resubmits with the role covered and
asserts the operation applies.

##### `[FM-INV-0004.4]` Bootstrap at mesh initialization

The initial K-of-N quorum membership **shall** be established at mesh
initialization, parallel to the `vault operator init` ceremony, via
a documented **mesh-init quorum-bootstrap ceremony** that satisfies
all of the following:

1. **N independent identity holders** are physically present (or
   attested-presence equivalent via accredited remote ceremony) for
   the ceremony.
2. **Each holder receives a single Shamir shard** of the
   quorum-authority master, with custody chain recorded — shard
   transfer is direct holder-to-holder-keyring or holder-to-HSM, never
   via a shared storage medium.
3. **Initial role assignments are documented and signed** by all N
   holders — each holder's assigned roles (per `[FM-INV-0004.3]`) are
   recorded and counter-signed.
4. **The ceremony itself is a recorded ACT audit event** — timestamp,
   N value, K threshold, holder identity fingerprints (not shards),
   role assignments, and a ceremony attestation signed by each holder
   are emitted to the ACT pillar as a single immutable record, under
   the **genesis event class** defined in `[FM-INV-0004.5]`.
5. **From ceremony completion onward**, all subsequent modifications
   to quorum membership — including addition, removal, replacement,
   or rotation of members — **shall** themselves require existing
   K-of-N quorum.

*Verification: Inspection* — mesh-init record in ACT is reviewed for
all five ceremony elements; absence of any element invalidates the
bootstrap and requires re-ceremony.

##### `[FM-INV-0004.5]` Genesis event class — bootstrap exemption from IAM-attributed audit

A bounded set of **genesis events** **shall** be permitted to land in
ACT without satisfying `[FM-ACT-0003]` IAM-`principal-id` attribution.
The genesis-event class exists exclusively to make the mesh-init
quorum-bootstrap ceremony per `[FM-INV-0004.4]` and the equivalent
IAM-init ceremony (the initial ARCA root + Roster seeding) emittable
to ACT without a circular dependency on the very identity system
those ceremonies bring into existence.

A genesis event **shall**:

1. Carry an `event_class = "genesis"` attribute distinct from the
   `[FM-ACT-0004]` event-type taxonomy's runtime event classes.
2. Carry a `genesis_subtype` enumerated from a closed list defined
   here: `mesh-init-quorum-bootstrap` (per `[FM-INV-0004.4]`),
   `iam-init-arca-root` (initial ARCA root certificate ceremony),
   `iam-init-roster-seed` (initial Roster substrate seeding bringing
   IAM to operational state per `[FM-IAM-0014]`). Extension to this
   closed list requires the argued-case discipline per
   `[FM-INV-0003.2]` and is itself catastrophic-class per
   `[FM-INV-0004]`.
3. Be attested by **holder identity fingerprints** rather than IAM
   principal-ids — the same K-of-N attestation that established the
   ceremony per `[FM-INV-0004.4]` items 1–3.
4. Seed the per-session cryptographic chain per `[FM-ACT-0005]` —
   the first runtime session of any pillar after genesis
   **shall** chain-link its initial event to the corresponding
   genesis event's hash, making the genesis record the chain's
   verifiable root anchor.
5. Be the **only** ACT events permitted to bypass `[FM-ACT-0003]`
   attribution. Once any genesis ceremony per item 2 completes,
   subsequent events of that ceremony's class **shall not** be
   emittable — the genesis class is one-shot per `genesis_subtype`
   per deployment lifetime. A second `mesh-init-quorum-bootstrap`
   event in the same deployment is non-conforming.
6. Be classified catastrophic-class per `[FM-INV-0004]` — a re-
   issuance ceremony for a previously-emitted genesis subtype (e.g.,
   re-bootstrapping the IAM root after a compromise) **shall** itself
   require K-of-N quorum per the existing membership, and the new
   ceremony's event carries a `supersedes_genesis` reference to the
   prior genesis record. Consumers querying "current genesis" for a
   given `genesis_subtype` **shall** resolve to the **head of the
   supersedes chain** (the most-recent genesis event for that subtype
   with no further `supersedes_genesis` reference pointing to it);
   superseded genesis events remain in ACT for audit but **shall
   not** be honored as current. Replay/downgrade attacks against
   the head resolution are blocked by item 6's quorum-gating of the
   re-issuance ceremony itself — a forged supersede cannot be
   appended without K-of-N attestation.

ACT requirements that otherwise demand IAM-`principal-id` attribution
or full chain-link predecessors (`[FM-ACT-0001]`, `[FM-ACT-0003]`,
`[FM-ACT-0005]`, `[FM-ACT-0009]`) **shall** read this sub-clause as
the sole carve-out — the carve-out is closed under the three
enumerated subtypes and does not extend to any other class of event.

*Verification: Inspection of mesh-init record + Conformance-test
of post-init chain seeding* — Inspection verifies the genesis
events for each enumerated subtype carry the holder-fingerprint
attestation and are present in ACT before any IAM-attributed
event; Conformance-test exercises the first runtime session after
genesis and asserts its chain initial event references the
genesis event's hash as predecessor; attempts to emit a second
`mesh-init-quorum-bootstrap` event in the same deployment and
asserts rejection; verifies any other class of unattributed
event submission is rejected.

### §4.4 Platform enforcement floor

#### `[FM-INV-0005]` Platform enforcement floor is authoritative

The platform's enforcement floor — including but not limited to
authentication (`[FM-INV-0001]`), fail-strict (`[FM-INV-0002]`),
capability provisioning (`[FM-INV-0003]`), and quorum authority
(`[FM-INV-0004]`) — **shall** be authoritative and independent of
plugin or workflow self-declaration. A plugin's PCS manifest policy
declaration **shall** constitute a declaration of intent, not an
enforcement contract.

*Verification: Conformance-test* — the harness submits a plugin that
self-declares less restrictive policy than the platform floor and
asserts the platform-floor restrictions still apply at runtime.

##### `[FM-INV-0005.1]` Default-deny on declaration omission

Absence of a policy declaration field in a plugin's PCS manifest
**shall not** confer permission. A plugin that omits a `judge_gates`
or `quorum_required` declaration **shall not** thereby acquire
permission to perform those operations without the platform's gates.
Absent **shall not** mean permitted; absent **shall** mean unspecified,
and the platform **shall** apply its floor.

*Verification: Conformance-test* — the harness submits a plugin
manifest omitting a `judge_gates` field, attempts an operation the
platform classifies as judge-gated, and asserts the platform gate
applies.

##### `[FM-INV-0005.2]` Divergence between declaration and enforcement is auditable

A **divergence event** is defined as any runtime occurrence where the
operation about to be executed would be permitted by the calling
plugin's declared policy block (or by the absence of declaration) but
is denied or gated by the platform's enforcement floor. Each divergence
event **shall** be emitted to the ACT pillar as a single ACT
audit-event class `pcs.policy.divergence` with the following required
attributes:

- `plugin_id` — the plugin's coordinate (namespace:artifact:version)
- `operation` — the platform-classified operation name
- `plugin_declared` — what the plugin's policy block declared (or
  `null` for omission)
- `platform_enforced` — what the platform floor applied
- `caller_identity` — the calling principal
- `timestamp`, `trace_id`, `span_id` per `[FM-INV-0001]` audit
  invariants

A **CLCA trigger** is defined as a count of `pcs.policy.divergence`
events emitted by a single `plugin_id` within an operator-configured
window exceeding an operator-configured threshold. Default values
(when no operator configuration is supplied): window = 24 hours,
threshold = 10 events. When the threshold is exceeded, the platform
**shall** emit a derived event `pcs.policy.divergence.clca-trigger`
to ACT with the offending `plugin_id` and the triggering event count;
this derived event is the canonical signal CLCA workflows consume.

*Verification: Conformance-test* — the harness induces a divergence
event, asserts `pcs.policy.divergence` is emitted with all required
attributes; then induces threshold-exceeding repetition and asserts
`pcs.policy.divergence.clca-trigger` is emitted.

##### `[FM-INV-0005.3]` Enforcement granularity

The platform's enforcement floor **shall** cover the broader surface of
state-affecting operations classified by PGE policy as requiring
approval, not solely the headline catastrophic-class operations
enumerated in `[FM-INV-0004]`. Per-operation classification belongs to
PGE policy; the enforcement floor binds regardless of plugin
declaration.

*Verification: Inspection* — PGE policy registry enumerates
state-affecting operations with their classification; review confirms
the registry covers at minimum {catastrophic-class operations per
`[FM-INV-0004]`, judge-gated operations per `[FM-INV-0005]`, and the
explicit state-affecting operation list each pillar specification
declares in its §5 requirements when landed}.

### §4.5 Reasoning-runtime substrate

#### `[FM-INV-0006]` Reasoning-runtime substrate seam

The **reasoning runtime** — the inference engine the deployment's
agents themselves run on — is a deployment-level substrate seam
parallel to the persistent-store, secret-store, and identity-
provider seams. Its substitutability is contract-relevant: where
the reasoning runs determines what content reaches what
counterparty. The Standard binds this seam at the deployment
level, not at any individual pillar.

The substrate seam **shall** be declared by every deployment at
attestation per `[FM-INV-0005]` and per §F.3 of the registry-
integrity requirements. The declaration **shall** name:

1. **Runtime substrate class** — `sovereign-local-inference` /
   `vendor-hosted-reasoning` / `hybrid` per the deployment's
   workload-class assignment (per-workload-class declaration
   permitted; e.g., doer-tier on local inference,
   escalation-tier on vendor-hosted reasoning).
2. **Sovereign reference**: local inference (the reasoning model
   runs inside the customer trust boundary; no callback;
   prompts + working context never leave the boundary).
3. **Data-flow consequence** for any workload class not on the
   sovereign reference — what content reaches the vendor, under
   whose identity, with what retention, and what the vendor's
   stated data-handling commitments are.

A deployment whose reasoning runtime is the sovereign reference
across every workload class is **conformant** to this requirement.
A deployment with any workload class on a non-sovereign reasoning
runtime is **operating under a recognized deviation** per
`[FM-INV-0006.1]`.

##### `[FM-INV-0006.1]` Vendor-hosted reasoning — transitional deviation

A deployment **may** operate one or more workload classes on a
**vendor-hosted reasoning runtime** (e.g., Anthropic Claude Code /
Codex / equivalent vendor-cloud inference services) as a
recognized **transitional deviation** until sovereign local
inference is operational for the affected workload class. The
deviation **shall**:

1. Be registered in Appendix F per §F.2 with explicit sunset
   condition: "sovereign local inference operational per
   `[FM-INV-0006]` Sovereign reference for the affected workload
   class — model substrate inside the customer trust boundary; no
   callback for that class."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "vendor-hosted-reasoning"` per
   `[FM-PGE-0011]` discriminator (canonical emitter: PGE, via the
   policy that classifies the session's reasoning-runtime
   substrate as non-sovereign) for **every session** under the
   deviation. Per-session emission is the granularity — the
   deviation is per-workload-class, but the audit signal is
   per-session so the deployment's actual usage pattern is visible
   in ACT.
3. Document, in the Appendix F entry per §F.2 `deviation_scope`
   field, the **data-flow consequence** required by `[FM-INV-0006]`
   item 3 — what content reaches the vendor + identity attribution
   + retention + vendor's data-handling commitments.
4. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when sovereign local inference is
   declared operational for the affected workload class. Mirror
   of the `[FM-IBX-0010]` / `[FM-IAM-0014]` / `[FM-PGE-0005]`
   Gate-2 / `[FM-ACT-0008]` / `[FM-DPG-0013]` / `[FM-CRB-0010]` /
   `[FM-MCC-0012]` transitional pattern.

A deployment operating under the vendor-hosted-reasoning deviation
**shall not** be claimed conformant to `[FM-INV-0006]` Sovereign
reference on the basis of the deviation — it is conformant to the
deviation clause only for the affected workload classes. Saying so
plainly is the hostile-auditor baseline: vendor-hosted reasoning
**is** data egress to the vendor regardless of how careful
prompt-engineering is, and the deviation discipline names that
honestly rather than implying the air-gap claim of `[FM-INV-0001]`
adjacent invariants extends to the reasoning runtime.

*Verification (operational): Conformance-test* — when sovereign
local inference is operational for a workload class, the harness
exercises representative sessions and asserts no
vendor-hosted-reasoning divergence events are emitted for that
class.
*Verification (deviation period): Inspection of deviation registry
+ Conformance-test of per-session emission* — Appendix F entry
present with sunset condition + data-flow consequence; per-session
`vendor-hosted-reasoning` divergence events emitted to ACT for
every session of the affected workload class.

---

## §5 Pillar requirements

Per-pillar normative requirements. Each pillar section follows the
same shape: scope of the pillar, dependencies on other pillars and
mesh-level invariants, numbered requirements with `Verification:`
annotations, and a Conformance Profile binding substrate-matrix rows
to requirement IDs per §0.4.

Sections §5.2–§5.8 are reserved for future PRs. The IBX requirements
in §5.1 are the canonical template for the remaining seven pillars.

### §5.1 IBX — Inbox Exchange

**Scope.** IBX is the Control-Plane message-routing substrate. Every
asynchronous hand-off between mesh agents and every Judge-approval
gate routes through IBX. PCT (Principal Control Token), defined
below, lives in IBX rather than in PCS scope because PCT is a
*message* and IBX is the *message system*.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply to all IBX operations.
- IBX consumes verified-principal context from the IAM pillar (§5.2 when landed). Today (pre-IAM-build), the `sender` field is asserted by brief and verified by post-hoc convention; once IAM is operational, the `principal-id` PCT field (`[FM-IBX-0004]`) is the verification seam.
- IBX emits to ACT (§5.4 when landed) per `[FM-IBX-0012]`.

#### `[FM-IBX-0001]` PCT nine-field contract

Every message routed through IBX **shall** carry a Principal Control
Token (PCT) conforming to the normative PCT schema defined in
**Appendix A**. A message that does not carry all nine PCT fields per
Appendix A **shall** be rejected by IBX at the routing layer and
**shall not** be delivered to its recipient.

*Verification: Conformance-test* — the harness submits messages with
each Appendix-A field omitted in turn and asserts rejection in every
case; submits a complete nine-field PCT and asserts successful
routing.

#### `[FM-IBX-0002]` PCT field-name stability

The nine PCT field names defined in Appendix A **shall not** be
renamed or removed in any `pct-v1.x` revision. Validation detail,
field-value constraints, and deprecation-with-replacement semantics
**may** be added in v1.x; field identity is immutable across the v1
schema.

*Verification: Static-check* — a schema-diff tool compares the
deployed `pct-v1.x` schema against the v1.0 baseline (Appendix A) and
asserts no field has been renamed or removed.

#### `[FM-IBX-0003]` Server-enforced Judge gate for action-priority messages

Messages tagged with priority `action` or `urgent` **shall not** be
delivered to recipients for execution until they have been explicitly
approved by the Judge (the human-in-the-loop principal). Server-side
enforcement is mandatory: agent-side code **shall not** be the only
gate, and agents **shall not** be able to bypass the gate by
self-approving.

The Judge approval **shall** be performed via a credential that is
distinct from any agent credential and is granted only to the
identity authorized to act as Judge.

*Verification: Conformance-test* — the harness submits an
action-priority message, asserts the recipient cannot retrieve the
message in an actionable state without a Judge-approval transition;
attempts to set the approval status using a non-Judge credential and
asserts denial.

#### `[FM-IBX-0004]` Message status workflow

Messages routed through IBX **shall** transit a defined status
workflow:

```
unread → read → approved → in_progress → done
                     ↘
                       rejected
```

The terminal states are `done` and `rejected`. Transitions to
`approved` and `rejected` **shall** be writable only by the Judge
credential per `[FM-IBX-0003]`. All other transitions **may** be
written by agent credentials with scope `inbox.message.transition` per
the IAM-defined scope catalogue.

Messages with priority `info` **may** be acted on without an
`approved` transition; the Judge gate applies only to `action` and
`urgent` priority.

*Verification: Conformance-test* — the harness exercises each
transition with each credential class and asserts permitted/denied per
the table; asserts info-priority does not require Judge approval.

#### `[FM-IBX-0005]` Append-mostly substrate

Status mutations on messages **shall** be implemented as append-only
event rows in the underlying substrate, materialized into a
latest-state view. Direct UPDATEs to a `status` column on the canonical
message row **shall not** be the substrate's representation of state.

Rationale (informative): append-only state mutation preserves the
full audit chain required by `[FM-INV-0001]`-class audit invariants
and §7 operational requirements when landed; an UPDATE-in-place model
discards the transition history.

*Verification: Static-check* — the substrate DDL is analyzed
programmatically (AST or grep over migrations) for UPDATE statements
targeting the canonical status state; any such statement is a
non-conformance.

#### `[FM-IBX-0006]` Identity-vs-session distinction in PCT

The PCT `principal-id` field (per `[FM-IBX-0001]`) **shall** name
*which identity* sent the message — a stable IAM-issued identifier
that persists across sessions of that identity. The substrate-layer
session identifier (the specific connection, agent process, or
authenticated session through which the message was submitted)
**shall** be recorded separately by IBX and **shall not** be conflated
with `principal-id`.

This distinction is load-bearing for worker-pool dispatch
(`[FM-IBX-0007]`), per-session forensics, and quorum-voter
independence per `[FM-INV-0004]`: a worker-pool is one identity with N
concurrent sessions; a quorum vote requires N distinct identities.

*Verification: Inspection* — the IBX substrate schema is reviewed for
two distinct fields (identity, session) with documented semantics;
runtime check: the harness submits two messages from one identity in
two sessions and asserts they share `principal-id` but differ on
session identifier.

#### `[FM-IBX-0007]` Worker-pool claim dispatch semantics

When a message is dispatched to a worker-pool (multiple sessions of
one identity competing to claim work), IBX **shall** provide
exactly-once claim semantics with the following properties:

1. **SKIP-LOCKED-equivalent claim** — concurrent claim attempts on the
   same message resolve to exactly one winner; the loser receives a
   "not claimed" response and may re-try on a different message.
2. **Lease / visibility timeout** — a claimed message that is not
   marked `done` or `rejected` within the operator-configured lease
   window returns to the claimable pool and may be claimed by a
   different session.
3. **Retry semantics** — a message that returns to the claimable pool
   via lease expiration **shall** carry an incremented retry counter;
   messages exceeding the operator-configured retry threshold
   **shall** transition to a poison-queue terminal state.
4. **Idempotency keys** — workers **shall** be able to provide an
   idempotency key on `done` transitions; duplicate `done`
   submissions with the same idempotency key **shall not** double-count
   the operation.
5. **Mid-action-safe termination** — a worker process termination
   mid-claim **shall** result in lease expiration and re-claim; the
   substrate **shall not** lose the message.

*Verification: Conformance-test* — the harness exercises each of the
five properties with adversarial timing (concurrent claims, late
heartbeats, duplicate completions, abrupt process termination) and
asserts the expected behavior.

#### `[FM-IBX-0008]` Routing-audit storage seam

The routing-audit storage substrate **shall** satisfy the conformance
profile for ANSI SQL with JSONB-equivalent semi-structured query
support. The sovereign reference implementation is PostgreSQL 17+;
supported alternatives are listed in the IBX Conformance Profile.

*Verification: Conformance-test* — the multi-profile conformance suite
runs the IBX routing-audit test set against each declared supported
substrate; passing the suite on the substrate is the verification.

#### `[FM-IBX-0009]` Worker-pool claim queue substrate seam

The worker-pool claim queue substrate **shall** satisfy the
conformance profile for transactional SKIP-LOCKED-equivalent claim
semantics. OLAP / append-only substrates that do not provide row-level
transactional claim **shall not** be claimed as conformant for this
seam.

*Verification: Conformance-test* — the multi-profile conformance suite
runs the IBX claim-queue test set (concurrent claims, lease expiration,
poison queue) against each declared supported substrate.

#### `[FM-IBX-0010]` Identity verification seam

IBX **shall** consume verified-principal context from the IAM pillar
(§5.2 when landed) at message-submission time. The PCT `principal-id`
field **shall** be cryptographically verifiable against the IAM
Roster's identity records; an unverifiable `principal-id` **shall**
cause the message to be rejected at submission per `[FM-INV-0002]`
(Fail strict).

**Transitional deviation — sunset on IAM operational availability.**
A deployment operating prior to the IAM pillar's operational
availability (per §5.2 when landed) **may** record asserted-but-
unverified identity in the substrate's audit trail. **This path is a
recognized deviation, not satisfaction of this requirement.** A
deployment operating under the transitional deviation **shall not**
be claimed conformant to `[FM-IBX-0010]`; it is conformant to the
deviation clause only, and **shall** transition to full conformance
when IAM becomes operational.

The transitional deviation **shall**:

1. Be registered in the deployment's deviation registry (Appendix F)
   with explicit sunset condition: "IAM operational per the
   `[FM-IAM-NNNN]` requirement marking IAM operational state, to be
   defined in §5.2."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` for every
   assertion-only identity claim, with attributes naming the
   deviation and the asserted identity.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when IAM operational state is declared per
   §5.2.

This deviation is not a "satisfying path" — it is acknowledged
operational reality with a clock. The `[FM-INV-0001]` no-bypass
invariant is not relaxed; the deviation registry + divergence-event
emission is how the platform tracks the bounded departure until the
sunset condition is reached.

*Verification (post-IAM): Conformance-test* — the harness submits
messages with valid and invalid `principal-id` and asserts accept /
reject per cryptographic verification against the IAM Roster.
*Verification (deviation period): Inspection of deviation registry +
Static-check of divergence-event emission rate* — for any deployment
claiming the transitional path, the deviation registry entry is
reviewed for presence + sunset condition; ACT is queried for the
expected divergence-event emission per assertion-only identity claim.

#### `[FM-IBX-0011]` Telemetry emission

IBX **shall** emit OTLP-format traces, metrics, and logs to the
deployment's configured OTLP backend. Span names **shall** follow the
`mesh.ibx.*` namespace per the per-pillar telemetry contract; required
attributes **shall** include `identity`, `session`, `trace_id`,
`span_id`, plus event-specific fields.

*Verification: Conformance-test* — the harness invokes representative
IBX operations and asserts emission of the expected span / metric /
log records to a test OTLP sink, with required attributes present.

#### `[FM-IBX-0012]` Audit emission per state-affecting operation

Every message-status transition `[FM-IBX-0004]` **shall** emit an
audit-class event to ACT (§5.4 when landed) carrying the transitioning
identity, the message identifier, the from-state, the to-state, the
timestamp, and the trace/span correlation IDs. Audit emission failure
**shall** be treated as fail-strict per `[FM-INV-0002]` — the
transition itself **shall not** be applied if its audit emission
cannot be confirmed.

*Verification: Conformance-test* — the harness exercises each
transition class and asserts audit-event emission with all required
fields; induces audit-sink unavailability and asserts the transition
is denied (fail-strict semantics).

### §5.1.1 IBX Conformance Profile

The IBX pillar's substrate substitutability claim covers exactly the
rows in this Conformance Profile. Conformance is verified by passing
the IBX multi-profile conformance suite against the listed
implementations. The Test Set column names the test-set identifier
the conformance harness runs against each seam — the harness
auto-discovers which test set to execute per declared substrate.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Routing-audit storage | `[FM-IBX-0008]` | PostgreSQL 17+ | Oracle 19+, MySQL 8+ | `ibx-routing-audit-v1` |
| Worker-pool claim queue | `[FM-IBX-0007]`, `[FM-IBX-0009]` | PostgreSQL 17+ | (none currently — OLAP unsuitable; alternatives require transactional claim semantics) | `ibx-claim-queue-v1` |
| Identity verification | `[FM-IBX-0010]` | Per IAM pillar (§5.2) | Whatever IAM declares conformant | `ibx-identity-v1` (post-IAM); `ibx-identity-deviation-v1` (transitional per `[FM-IBX-0010]` deviation clause) |
| Telemetry sink | `[FM-IBX-0011]` | OTLP-on-the-wire | Any OTLP-compatible backend declared conformant by ACT (§5.4) | `ibx-telemetry-v1` |

Out-of-set substrates **shall not** be claimed as supported under
this profile. Extending the profile requires the argued-case
discipline per `[FM-INV-0003.2]` and a multi-profile conformance run
proving the new substrate passes the IBX test suite.

### §5.2 IAM — Identity & Access Management

**Scope.** IAM is the foundational pillar — the root of trust every
other pillar's authorization, isolation, audit, segregation-of-duties,
and human-approval guarantee is downstream of. IAM is specified to
Tier-0 rigor; a flaw in IAM is not a local defect but a flaw in every
guarantee above it. IAM consists of four services (ARCA, Vault,
Roster, Publish pipeline) across two planes (Issuance Plane above the
dotted line; Control Plane runtime).

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply to all IAM operations at Tier-0 rigor; they **cannot be relaxed** by any IAM-level policy.
- `[FM-INV-0005]` (Platform enforcement floor authoritative) binds — IAM does not honor plugin self-declared identity claims that contradict its own verification.
- FIPS-Day-1 substrate discipline per §4.2 applies — Vault PKI, TLS endpoints, and signing engines run FIPS-validated mode from initial provisioning for FIPS-regulated deployments.
- IAM is consumed by IBX (§5.1) per `[FM-IBX-0010]`, PGE (§5.3) per the identity-context contract `[FM-IAM-0011]` (IAM provides identity context; PGE makes the allow|deny decision), and every other pillar's audit emission.

**Transitional posture (universal across IAM requirements):** IAM
ships in stages. Until `[FM-IAM-0014]` (IAM operational-state
declaration) is met, a deployment **may** operate the deviation
described in `[FM-IAM-0014]` (identity-by-brief) — a recognized
deviation, **not** satisfaction of `[FM-IAM-0003]` through
`[FM-IAM-0006]`. The same deviation-registry + divergence-event
discipline used by `[FM-IBX-0010]` applies; see Appendix F.

#### `[FM-IAM-0001]` Issuance-runtime separation (dotted line)

The Issuance Plane (ARCA) and the Control Plane (Vault, Roster, IAM
runtime services) **shall** be structurally separated. ARCA **shall
not** be reachable from runtime services during normal operation; the
runtime **shall not** call back to ARCA for verification. Identity
verification at runtime **shall** be local — performed against a
trust chain that includes ARCA's public certificate(s) but does not
require network access to ARCA itself.

This separation is what permits ARCA to be operated offline. The
contract this Standard commits is that the runtime cannot reach ARCA
during normal operation; ARCA's physical location, custody chain,
and ceremony for touch-events are deployment items.

*Verification: Conformance-test* — the harness asserts that runtime
identity verification succeeds with ARCA unreachable (offline / no
network route); asserts that no runtime code path attempts to reach
ARCA outside the documented birth and re-attestation events
(`[FM-IAM-0003]`).

#### `[FM-IAM-0002]` Per-organization ARCA sovereignty

Each deploying organization **shall** operate its own ARCA. The mesh
**shall not** ship a vendor-operated or vendor-rooted CA serving
multiple customer deployments. There **shall not** exist a "Fiducial
Mesh root" above any customer's ARCA; identity in each deployment is
sovereign to the organization.

*Verification: Inspection* — review of the ARCA trust chain shows the
root is held by the deploying organization, not by a vendor or by a
shared upstream root.

#### `[FM-IAM-0003]` Identity issuance — birth and lifecycle entry

Every principal (agent, human, service) in the mesh **shall** be
issued an identity by ARCA through the Publish pipeline
(`[FM-IAM-0008]`). The issuance ceremony **shall** produce:

1. A keypair, with the **private key stored in Vault** under the
   in-boundary-signing contract (`[FM-IAM-0006]`); the private key
   **shall not** be transferred in plaintext outside the Vault
   boundary at any point during or after issuance.
2. A **birth certificate** — an ARCA-signed binding of the public-key
   fingerprint to the principal's `principal-id`, the issuance
   timestamp, and the principal-type stamp (`[FM-IAM-0010]`).
3. An entry in the **Roster** (`[FM-IAM-0007]`) recording the
   non-secret identity fields and the initial job-code / role
   assignment.

*Verification: Inspection (current) / Conformance-test (post-IAM-operational)*
— review of the issuance code path verifies the three-component
output (keypair generated with private key in Vault, birth
certificate signed by ARCA binding fingerprint to principal-id +
timestamp + principal-type, Roster entry created with non-secret
identity fields and initial job-code / role); once operational, the
harness exercises issuance and asserts all three components are
produced and that the private key is unreachable outside the Vault
boundary at every observable point of the ceremony.

##### `[FM-IAM-0003.1]` Identity-permanent / authority-mutable separation

The `principal-id` and public-key fingerprint **shall** be **immutable**
for the lifetime of the identity — they are the *who*. The job-code,
role, brief, and authorization-scope assignments **shall** be
**mutable** through the lifecycle operations (`[FM-IAM-0004]`,
`[FM-IAM-0005]`) — they are the *what is currently authorized*. The
two **shall not** be conflated; an identity that is suspended or whose
role changes retains the same fingerprint.

*Verification: Inspection (current) / Conformance-test (post-IAM-operational)*
— review of the issuance + lifecycle code paths verifies that
`principal-id` and public-key fingerprint are non-mutable fields in
the Roster schema, that suspend / resume / role-change operations
per `[FM-IAM-0004]` and `[FM-IAM-0005]` do not modify them, and that
the harness can re-verify a suspended-then-resumed identity carries
the same fingerprint it was born with.

#### `[FM-IAM-0004]` Identity lifecycle — suspend / resume

A principal's identity **may** be transitioned between `active`,
`suspended`, and `active`-again states without revoking the underlying
credential. A suspended identity **shall not** be able to authenticate
any new actions; in-flight actions **shall** be evaluated per the
Fail-strict invariant — under the suspended state the platform halts
the principal's operations.

**Worker-pool semantics on suspend.** When a suspended principal-id
holds in-flight claims against a worker-pool per `[FM-IBX-0007]` /
`[FM-IBX-0009]` (e.g., DPG runners per `[FM-DPG-0007]`, future
worker pillars), "halt the principal's operations" is **claim-
draining**, not claim-aborting: in-flight claims **shall** be
permitted to run to their next safe checkpoint (existing
mid-action-safe termination semantics per `[FM-IBX-0007]`) and
**shall** emit their terminal audit events before claim release.
**New claims shall not be acquired**; the suspend takes effect at
the next claim-acquisition boundary. The per-session distinction
per `[FM-IBX-0006]` is preserved — suspend halts *new* sessions
of the principal, while existing sessions complete their current
claim and then terminate without re-claiming.

This rule prevents the failure mode in which suspend on a
worker-pool identity aborts in-flight claims, which then re-enter
the pool whose only conformant claimant is now suspended,
producing a poison-queue from a deliberately reversible suspend.
A poison-queue produced by claim-abort would persist past resume
and may require operator-side intervention to drain — that's an
irreversible-effect-from-reversible-operation pattern this rule
explicitly prevents.

Suspension **shall** be writable only by an identity holding the
`iam.principal.suspend` scope; resume by an identity holding
`iam.principal.resume`. The two scopes **may** be held by the same
role per the operator's IAM role catalog, or split per
segregation-of-duties policy.

*Verification: Conformance-test* — the harness exercises suspend on
an active principal, asserts subsequent authentication attempts halt;
exercises resume, asserts authentication succeeds again; verifies
scope-required writes succeed only with the correct credential;
**exercises suspend on a worker-pool principal-id with in-flight
claims and asserts (a) the in-flight claims complete and emit
terminal audit events, (b) no new claims are acquired after suspend,
(c) the pool's claim queue does not enter a poison-queue state, and
(d) resume restores claim acquisition normally**.

#### `[FM-IAM-0005]` Identity revocation — terminate

A principal's identity **may** be terminated permanently. Termination
**shall**:

1. Revoke the principal's credentials via the Vault revocation
   primitive (`[FM-IAM-0006]`).
2. Mark the Roster entry as `terminated` with the termination
   timestamp and reason; the entry **shall not** be deleted (audit
   chain preservation).
3. Distribute the revocation through the mesh's revocation
   propagation channel so that all consumers verify the principal's
   credential against the post-revocation trust state.

A terminated identity's `principal-id` and fingerprint **shall not**
be reissued or reused; termination is permanent for the namespace.

Termination is a catastrophic-class action when applied to a class of
identities (mass revocation) per `[FM-INV-0004]`; per-principal
termination requires the `iam.principal.terminate` scope, which
**may** be subject to additional governance (e.g., quorum) per the
operator's IAM policy.

*Verification: Conformance-test* — the harness exercises termination,
asserts subsequent authentication denied, Roster entry preserved with
terminated state, revocation propagated to downstream consumers.

#### `[FM-IAM-0006]` Vault — in-boundary signing

The Vault service **shall** provide in-boundary signing — private
keys held by Vault **shall not** be exported outside the Vault trust
boundary in plaintext at any point. Signing operations **shall** be
performed inside Vault (or its delegated HSM); only signatures (not
keys) **shall** leave the boundary.

Tier-graded discipline:

- **Tier-0** (high-assurance / FIPS / DoD-SCIF deployments per §4.2):
  hardware-backed dual-control signing — HSM (e.g., PKCS#11) with
  attested non-exfiltration; no software-only mode permitted.
- **Tier-2** (commercial / lab default): software single-operator
  signing acceptable; in-boundary contract still applies.

*Verification: Conformance-test* — the harness attempts to export a
private key via every documented Vault API; asserts every attempt
fails. For Tier-0, additionally asserts the signing engine is
HSM-backed via Vault's reported configuration.

#### `[FM-IAM-0007]` Roster contract — non-secret identity store

The Roster **shall** store the non-secret identity record for every
principal: `principal-id`, public-key fingerprint, principal-type
(`[FM-IAM-0010]`), job-code, role, brief, status (active / suspended
/ terminated), and any operator-defined non-secret attributes.

The Roster **shall not** store secret material — private keys,
credentials, or tokens belong in Vault (`[FM-IAM-0006]`).

The Roster **shall** be broadly readable to any authenticated
principal in the mesh — Roster reads are not gated by need-to-know
restrictions for non-secret fields; identity attribution requires
visibility. **Write access** to the Roster **shall** be restricted to
the Publish pipeline (`[FM-IAM-0008]`); no other path **shall**
modify Roster records.

*Verification: Inspection of substrate ACLs + Conformance-test* —
review of the Roster substrate configuration verifies read-broad +
write-restricted-to-Publish-pipeline-identity; harness attempts to
write directly via non-Publish credentials and asserts denial.

#### `[FM-IAM-0008]` Publish pipeline — single privileged onboarding path

There **shall** exist exactly one privileged onboarding actor — the
Publish pipeline — that can write a new principal's identity into
Vault (private key) and Roster (identity record). The Publish
pipeline **shall**:

1. Receive a birth certificate signed by ARCA (`[FM-IAM-0003]`).
2. Store the private key in Vault under the in-boundary contract
   (`[FM-IAM-0006]`).
3. Record the Roster entry with all required fields per
   `[FM-IAM-0007]`.
4. Emit a single immutable audit event (per `[FM-IAM-0013]`) recording
   the issuance.

No other path **shall** create principals. Bypass attempts (direct
Vault writes, direct Roster writes by non-Publish identities) **shall**
be denied by the substrates' ACLs and **shall** emit a divergence
event per `[FM-INV-0005.2]`.

*Verification: Conformance-test* — the harness submits issuance
requests through the Publish pipeline and asserts the three-component
state is produced atomically; submits a direct Vault or Roster write
bypassing Publish and asserts denial + divergence-event emission.

#### `[FM-IAM-0009]` Pluggable IdP federation interface

IAM **shall** expose a pluggable federation adapter interface that
allows the deployment's existing identity provider (Active Directory,
LDAP, OIDC, SAML, PIV-CAC for federal environments) to participate as
an authentication source for human principals. The adapter contract
**shall** include: identity-assertion verification, claim mapping
into the Roster's principal-id space, MFA / policy enforcement on the
IdP side surfaced through verification metadata.

Agent principals **shall not** authenticate through the IdP
federation path; agents authenticate via ARCA-issued credentials per
`[FM-IAM-0003]`. The IdP federation surface is for human principals
and (optionally) service principals.

*Verification: Inspection + Conformance-test* — review of the IdP
adapter interface against the four contract elements; the harness
exercises one supported IdP type (LDAP minimum for sovereign-ref
verification) and asserts successful federation including claim
mapping.

#### `[FM-IAM-0010]` Principal-type stamp

Every principal's Roster entry **shall** carry a principal-type stamp
with one of the values: `agent`, `human`, `service`. The stamp
**shall** be set at issuance (`[FM-IAM-0003]`) and **shall** be
immutable — a principal's type does not change for the lifetime of
the identity.

The principal-type **shall** be available to downstream consumers
(PGE for policy decisions, ACT for audit attribution, IBX for
routing) without requiring re-verification against IAM.

*Verification: Static-check + Conformance-test* — Static-check of
issuance code asserts every issuance path sets the stamp; harness
attempts to mutate principal-type post-issuance and asserts denial.

#### `[FM-IAM-0011]` Identity-context contract for PGE consumers

IAM **shall** expose an **identity-context** resolution contract to
PGE (§5.3) and other policy-consuming pillars. **IAM provides
identity context; IAM does NOT make the allow|deny decision.** The
decision is PGE's responsibility (per §5.3 when landed); IAM's
responsibility is to provide PGE with the verified identity and the
identity-bound claims PGE needs to make the decision.

Given a verified `principal-id`, IAM **shall** return an identity
context comprising:

1. **Verified identity** — `principal-id` + public-key fingerprint
   (per `[FM-IAM-0003]`)
2. **Principal-type stamp** — `agent | human | service` (per
   `[FM-IAM-0010]`)
3. **Status** — `active | suspended | terminated` (per `[FM-IAM-0004]`
   / `[FM-IAM-0005]`); a non-`active` status **shall** cause PGE to
   deny independent of policy
4. **Job-code** + **role** — the identity's current
   authorization-relevant attributes from the Roster (per
   `[FM-IAM-0007]`)
5. **Scope set** — the IAM-issued scopes bound to this identity at
   the time of resolution
6. **Identity-context version** — a monotonic version token that
   increments when any of fields 3–5 change; this is what PGE
   attributes decisions to in its audit chain (PGE additionally
   records its own policy version per its §5.3 requirements)

Resolution **shall** be deterministic — the same `principal-id`
**shall** produce the same identity context absent intervening
suspend/resume/terminate or role-change operations. The
identity-context version **shall** be monotonic across the lifetime
of the identity.

This is the seam at which PGE consumes IAM identity context. PGE
combines this context with its policy registry to produce the
`allow | deny` decision; IAM is not in the decision path.

*Verification: Conformance-test* — the harness queries the contract
with known `principal-id` values and asserts the six-element context
is returned with correct values; exercises suspend/role-change/resume
and asserts the identity-context version increments monotonically;
asserts the contract returns context only — no `allow | deny` field
is part of the contract surface.

#### `[FM-IAM-0012]` Telemetry emission

IAM **shall** emit OTLP-format traces, metrics, and logs per the
mesh-wide telemetry discipline. Span names **shall** follow the
`mesh.iam.*` namespace per the per-pillar telemetry contract;
required attributes **shall** include `principal-id`, `session`,
`trace_id`, `span_id`, plus event-specific fields (operation,
target-principal, scope, decision).

*Verification: Conformance-test* — the harness invokes representative
IAM operations and asserts emission of expected span / metric / log
records to a test OTLP sink, with required attributes present.

#### `[FM-IAM-0013]` Audit emission per state-affecting operation

Every IAM state-affecting operation (issuance, suspend, resume,
terminate, role change, scope grant, scope revoke) **shall** emit an
audit-class event to ACT (§5.4 when landed) carrying the acting
identity, target identity, operation, from-state, to-state, deciding
policy version, timestamp, and trace/span correlation IDs. Audit
emission failure **shall** be treated as fail-strict per
`[FM-INV-0002]` — the operation itself **shall not** be applied if
its audit emission cannot be confirmed.

*Verification: Conformance-test* — the harness exercises each
state-affecting operation and asserts audit emission with required
fields; induces audit-sink unavailability and asserts the operation
is denied (fail-strict semantics).

#### `[FM-IAM-0014]` IAM operational-state declaration

A deployment's IAM pillar is declared **operational** for the purpose
of this Standard when **all** of the following hold:

1. **ARCA is built and signing** intermediate CAs per `[FM-IAM-0001]`
   (issuance-runtime separation operational; offline-root posture in
   place).
2. **Vault is online with in-boundary signing** per `[FM-IAM-0006]`
   at the deployment's declared tier (Tier-0 HSM-backed for
   FIPS / DoD; Tier-2 software for commercial).
3. **Roster is online + writable only via the Publish pipeline** per
   `[FM-IAM-0007]` + `[FM-IAM-0008]`.
4. **Cryptographic identity verification path is exercising real
   signatures** for every principal in the deployment — no
   `principal-id` is satisfied by brief-assertion alone.

Until all four conditions hold, the deployment operates under the
**identity-by-brief transitional deviation**: a recognized deviation,
not satisfaction of `[FM-IAM-0003]` through `[FM-IAM-0006]`. The
deviation **shall**:

1. Be registered in Appendix F deviation registry with explicit
   sunset condition: "this requirement's four conditions all hold."
2. Emit divergence events to ACT per `[FM-INV-0005.2]` for every
   identity claim under the deviation.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when the four conditions hold.

This is the requirement that sunsets the `[FM-IBX-0010]` transitional
deviation (and any analogous deviations in other pillars). When
`[FM-IAM-0014]` is satisfied, those deviations expire.

*Verification: Conformance-test* — all four conditions are
mechanically verified before operational-state declaration is
accepted:

- **Condition 1** (ARCA signing intermediates): the harness queries
  ARCA's published certificate state and asserts at least one valid
  intermediate signed by the root; asserts root is unreachable from
  the runtime network per `[FM-IAM-0001]`.
- **Condition 2** (Vault in-boundary signing operational): the
  harness exercises `[FM-IAM-0006]` Conformance-test against the
  declared deployment tier; passes both per-tier discipline and the
  no-export assertion.
- **Condition 3** (Roster online + Publish-write-only): the harness
  exercises `[FM-IAM-0007]` and `[FM-IAM-0008]` Conformance-tests
  and asserts both pass.
- **Condition 4** (no principal on brief alone): the harness queries
  ACT for active `pcs.policy.divergence` events satisfying **all
  three** filter criteria — (a) `divergence_type =
  "identity-by-brief"` **exactly** (not merely the
  `pcs.policy.divergence` event class, which multiplexes seven
  active `divergence_type` subtypes per the `[FM-PGE-0011]`
  discriminator table); (b) emitted by the **canonical emitter
  IBX** per `[FM-PGE-0011]`'s canonical-emitter rule (records from
  other pillars are corroborative-only, not authoritative for this
  query); (c) **active** (not yet sunset per the deviation's
  Appendix F entry per §F.2 `status = active`). The query is
  measured over the prior operator-configured observation window
  (default: 7 days). **Zero events satisfying all three filters**
  is the mechanical satisfaction of Condition 4; any non-zero
  count blocks operational-state declaration. The class-level
  filter (`event_type = pcs.policy.divergence` without the
  `divergence_type` discriminator) is **not** the correct query —
  using it traps the deployment in non-operational state forever
  because sibling deviations (e.g., `gate-2-supplemental-only`,
  `detect-layer-not-operational`) emit into the same event class
  at steady state during their own deviation windows and would
  otherwise hold the count non-zero independently of the
  identity-by-brief signal this requirement actually depends on.

Attestation layer (additive to Conformance-test): operational-state
declaration **shall** additionally carry a written attestation by
the deployment's ARCA-custody role + the IAM-administration role,
recorded in ACT. The attestation is corroborative — it does **not**
substitute for the mechanical Conformance-test.

### §5.2.1 IAM Conformance Profile

The IAM pillar's substrate substitutability claim covers exactly the
rows in this Conformance Profile. Conformance is verified by passing
the IAM multi-profile conformance suite against the listed
implementations — once IAM is built per `[FM-IAM-0014]`.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| ARCA — offline issuance | `[FM-IAM-0001]`, `[FM-IAM-0002]`, `[FM-IAM-0003]` | smallstep CA (offline mode) — pending Tier-0 ceremony ratification | HashiCorp Vault PKI (offline-mode), AWS Private CA, Azure Key Vault HSM-backed CA, custom OpenSSL offline stack | `iam-arca-v1` |
| Vault — credential store + in-boundary signing | `[FM-IAM-0006]`, `[FM-IAM-0008]` | HashiCorp Vault (Tier-0 with PKCS#11 HSM; Tier-2 soft-mode) | Azure Key Vault (HSM Tier-0), AWS KMS + Secrets Manager (CloudHSM Tier-0), OCI Vault (dedicated HSM), Thales CipherTrust Manager, standalone PKCS#11 HSM on-prem | `iam-vault-v1` |
| Roster — identity store | `[FM-IAM-0007]`, `[FM-IAM-0008]`, `[FM-IAM-0010]` | Standalone Roster adapter (lab starting point) | Active Directory, LDAP / OpenLDAP, Microsoft Entra ID, Keycloak, AWS Cognito, Auth0, custom JSON-on-disk with Publish-pipeline write discipline | `iam-roster-v1` |
| IdP federation | `[FM-IAM-0009]` | Lab Roster (single-adapter starting point, AD-shaped) | LDAP, AD (on-prem), Microsoft Entra ID with Conditional Access, OIDC providers (Okta, Auth0, Google Workspace), PIV-CAC, AWS IAM Identity Center | `iam-idp-v1` |
| Identity-context lookup (PGE seam) | `[FM-IAM-0011]` | In-pillar Roster identity resolver (returns context only; no allow\|deny) | Any identity-store adapter exposing the six-element context per `[FM-IAM-0011]` — LDAP-attribute mapper, Active Directory attribute query, OIDC userinfo + claim mapping, custom Roster adapter | `iam-identity-context-v1` |
| Telemetry sink | `[FM-IAM-0012]` | OTLP-on-the-wire (any OTLP-compatible backend per ACT §5.4) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring, AWS CloudWatch (with OTLP adapter) | `iam-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported. Extending
the profile requires the argued-case discipline per `[FM-INV-0003.2]`
and a multi-profile conformance run proving the new substrate passes
the IAM test suite.

**Transitional deployments** (pre-`[FM-IAM-0014]`) run the
`iam-deviation-v1` test set instead of the operational conformance
suite — verifying deviation-registry presence and divergence-event
emission per the IAM transitional deviation clause in
`[FM-IAM-0014]`.

### §5.3 PGE — Policy Guardrail Engine

**Scope.** PGE is the mesh's deterministic, owned, auditable policy
enforcement pillar. It is the sovereign alternative to
vendor-mediated safety filters (which are opaque, non-deterministic,
at the wrong layer, and subject to vendor policy drift). PGE consumes
identity context from IAM per `[FM-IAM-0011]` and produces allow|deny
decisions against an operator-owned policy corpus. PGE enforces the
platform floor per `[FM-INV-0005]` and the catastrophic-class quorum
discipline per `[FM-INV-0004]`.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply to all PGE decisions.
- `[FM-INV-0004]` (Quorum authority): PGE is the enforcement point for catastrophic-class quorum gating.
- `[FM-INV-0005]` (Platform enforcement floor authoritative) — PGE is the consumer that makes the floor binding regardless of plugin self-declaration.
- `[FM-IAM-0011]` (Identity-context contract) — PGE consumes the six-element identity context from IAM; PGE makes the allow|deny decision, IAM does not.
- PGE emits to ACT (§5.4 when landed) per `[FM-PGE-0008]`.
- PGE consumes policy overlays from PCS (§6 when landed) per `[FM-PGE-0012]`.

#### `[FM-PGE-0001]` Policy decision authority

PGE **shall** be the single mesh component that produces `allow | deny`
decisions on policy-gated operations. The decision **shall** be
produced from:

1. The verified identity context returned by IAM per `[FM-IAM-0011]`
2. The action being requested (operation name + target resource +
   parameters)
3. PGE's policy corpus (per `[FM-PGE-0003]`) including any active
   overlays (per `[FM-PGE-0012]`)

No other pillar **shall** produce policy decisions; pillars **shall**
either invoke PGE for a decision or operate inside the surface PGE
has already gated. IAM **shall not** return allow|deny; it returns
context only per `[FM-IAM-0011]`.

*Verification: Conformance-test* — the harness asserts that policy
decision queries against PGE return `{allow|deny, reason, rule-id,
policy-version}` with no other pillar's decision interceding;
asserts IAM does not expose a decision-producing surface.

#### `[FM-PGE-0002]` Deterministic evaluation

PGE policy evaluation **shall** be deterministic: the same input
(identity context + action + active overlays + policy version)
**shall** produce the same decision. Non-determinism in the decision
path **shall** be treated as a defect.

This is the property that vendor-mediated safety filters lack and is
load-bearing for audit reconstructability and conformance testing.

*Verification: Conformance-test* — the harness submits identical
policy-decision queries from independent sessions and asserts
identical decisions across all sessions; verifies decisions are
identical across a configured number of repetitions for randomized-
sample input sets.

#### `[FM-PGE-0003]` Two-stratum rule corpus

The PGE rule corpus **shall** be organized into two strata:

- **Stratum 1 — Non-negotiable guarantees**: invariants that bind
  across every deployment of the mesh (e.g., the security framework's
  10 non-negotiables — no `subprocess`+`shell=True`, no `eval`/`exec`
  on untrusted input, parameterized SQL only, HTTPS-only egress,
  keyring-only credentials, etc.). Stratum 1 rules **shall not** be
  weakened by overlays; they are the floor of `[FM-INV-0005]`.
- **Stratum 2 — Implementation patterns**: rules and patterns that
  may vary per deployment, per regulatory regime, or per customer
  posture. Overlays (per `[FM-PGE-0012]`) operate at Stratum 2; they
  **may** add new Stratum 2 rules or modify Stratum 2 thresholds.

A rule's stratum classification **shall** be immutable for the rule's
lifetime; moving a rule between strata is a new rule with a new
identifier.

*Verification: Static-check* — the rule corpus is parsed and each
rule's stratum tag is verified against the corpus schema; the harness
attempts to apply an overlay weakening a Stratum 1 rule and asserts
rejection.

#### `[FM-PGE-0004]` Per-rule stable identifiers + decision attribution

Every rule in the corpus **shall** carry a stable identifier of the
form `pge-<stratum>-<area>-NNNN` (e.g., `pge-s1-injection-0007`).
Identifiers are immutable + append-only per the same discipline as
requirement IDs in this Standard (§0.2): once assigned, never
renumbered, never reused; deprecated rules are marked and retained.

Every PGE decision **shall** record the matching rule identifier (or
the explicit "no rule matched → default" path) in its audit emission
per `[FM-PGE-0008]`. Audit consumers reconstruct which rule fired by
identifier; no audit chain ever references "rule text" alone.

*Verification: Static-check + Conformance-test* — Static-check
asserts every rule in the corpus has a unique identifier matching the
schema; Conformance-test exercises representative decisions and
asserts the rule-id field is present and correct in the emitted audit
record.

#### `[FM-PGE-0005]` Double-guardrail enforcement

PGE **shall** apply policy enforcement at **two distinct chokepoints**
in the mesh execution surface, both of which **shall** be in place
for a deployment to claim PGE-conformance:

- **Gate 1 — Intent gate** at IBX submission (per `[FM-IBX-0003]`
  / `[FM-IBX-0004]`): the PCT's principal, scope assertion, action
  declaration, and authority claim are evaluated against the rule
  corpus before the message reaches downstream pillars. Non-compliant
  submissions fail closed at IBX.
- **Gate 2 — Execution gate** at the DPG ephemeral boundary (§5.6
  when landed): code emitted by agents is evaluated against the rule
  corpus before execution. Non-compliant code fails closed at DPG;
  it **shall not** touch production state.

Either gate alone **shall not** be claimed conformant — both are
required. The double-guardrail is the structural property that
distinguishes PGE from vendor-mediated safety filters (which enforce
at one layer and miss the execution surface entirely).

Supplemental surfaces (CI release gate per `publish.yml`, PreToolUse
hook per `[FM-PGE-0007]`, per-server test suite) **may** layer
additional enforcement; supplemental enforcement does **not**
substitute for either Gate 1 or Gate 2.

**Transitional deviation — Gate-2 sunset on DPG operational
availability.** Gate-2 enforcement lives in the DPG pillar per
`[FM-DPG-0005]`. Until `[FM-DPG-0005]` is declared operational
(per the Appendix F sunset condition), a deployment **may**
operate the supplemental enforcement surfaces (PreToolUse hook +
per-server test suite + CI release gate) **only** for execution-
side policy without satisfying Gate-2. **This is a recognized
deviation, not satisfaction of this requirement.** Same shape as
`[FM-IBX-0010]` and `[FM-IAM-0014]` transitional deviations.

The transitional Gate-2 deviation **shall**:

1. Be registered in Appendix F with explicit sunset condition:
   "`[FM-DPG-0005]` operational — generalized DPG runner
   executing the PGE rule corpus inside the ephemeral boundary
   across the deployment's executable-emission surface."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "gate-2-supplemental-only"` per
   `[FM-PGE-0011]` discriminator (canonical emitter: PGE) for every
   execution-side policy evaluation operating under the deviation.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when `[FM-DPG-0005]` operational state is
   declared in Appendix F.

A deployment operating under the Gate-2 transitional deviation
**shall not** be claimed conformant to `[FM-PGE-0005]`; it is
conformant to the deviation clause only.

*Verification: Conformance-test (post-DPG)* — the harness submits
non-compliant intent through IBX and asserts rejection at Gate 1;
submits compliant intent that emits non-compliant code into DPG and
asserts rejection at Gate 2; verifies removing either gate causes
the conformance suite to fail.
*Verification (deviation period): Inspection of deviation registry +
Static-check of supplemental-surface coverage + Conformance-test of
Gate 1 alone* — Gate 1 conformance verified per the post-DPG harness;
Gate-2 deviation entry verified in Appendix F; supplemental surfaces
(PreToolUse hook + CI gate + per-server tests) verified to cover the
execution-side rule set even though they do not constitute Gate-2.

#### `[FM-PGE-0006]` No vendor-mediated bypass

PGE policy enforcement **shall not** delegate to or be substituted by
a vendor-mediated safety filter (Anthropic safety filters, OpenAI
moderation endpoints, or any vendor-side policy surface). A
deployment that relies on vendor-side enforcement for any rule in the
corpus **shall not** be claimed PGE-conformant for that rule.

This is capability-minimization per `[FM-INV-0003]` applied to policy
enforcement: the capability "trust an external vendor to enforce our
policy" is not provisioned in the mesh.

*Verification: Inspection* — review of the policy enforcement code
path verifies no rule decision is routed to a vendor-mediated
endpoint; the rule corpus is owned and evaluated within the mesh's
trust boundary.

#### `[FM-PGE-0007]` Hook integration

PGE **shall** integrate with Claude Code and OpenAI Codex hook surfaces
(PreToolUse, PostToolUse, PermissionRequest, SessionStart) per the
respective vendor plugin specifications. The hook integration **shall**
be the runtime mechanism by which Gate 1 and Gate 2 intercept actions
at the agent surface.

When a hook fires, PGE **shall** evaluate the action against the rule
corpus and return the gate decision before the underlying tool
executes; a `deny` decision **shall** prevent tool execution.

*Verification: Conformance-test* — the harness exercises PreToolUse
hook fires with compliant and non-compliant tool calls and asserts
the gate decision is enforced before the tool executes (compliant
proceeds; non-compliant blocked).

#### `[FM-PGE-0008]` Audit emission per decision

Every PGE decision (every Gate 1 and Gate 2 evaluation, plus every
supplemental-surface evaluation) **shall** emit an audit-class event
to ACT (§5.4 when landed) carrying: the deciding rule identifier (per
`[FM-PGE-0004]`), the decision (`allow | deny`), the policy version
in force, the identity context fingerprint (per `[FM-IAM-0011]`), the
action evaluated, the timestamp, and the trace/span correlation IDs.

Audit emission failure **shall** be treated as fail-strict per
`[FM-INV-0002]`: PGE **shall not** apply a decision if its audit
emission cannot be confirmed; the action **shall** be denied.

*Verification: Conformance-test* — the harness exercises decisions
and asserts audit emission with all required fields; induces audit-
sink unavailability and asserts decisions deny rather than proceed
without audit.

#### `[FM-PGE-0009]` Catastrophic-class enforcement

For operations classified as catastrophic-class per `[FM-INV-0004]`,
PGE **shall** require K-of-N quorum attestation before issuing an
`allow` decision. The quorum-verification path is per `[FM-INV-0004]`;
PGE is the enforcement point that consumes the verified quorum result.

A catastrophic-class operation request that lacks K-of-N quorum at
decision time **shall** be denied independent of policy; presence
of quorum is necessary but not sufficient (the rule corpus may
additionally deny based on identity context or content).

*Verification: Conformance-test* — the harness submits
catastrophic-class operation requests with insufficient quorum and
asserts deny; submits with sufficient quorum but a rule-corpus deny
condition active and asserts deny; submits with sufficient quorum
and a clean rule-corpus state and asserts allow.

#### `[FM-PGE-0010]` Platform enforcement floor

PGE **shall** apply the platform enforcement floor per `[FM-INV-0005]`
regardless of plugin self-declaration. A plugin's PCS-manifest policy
block (per §6 when landed) is a declaration of intent, not an
enforcement contract; PGE **shall not** weaken its floor based on a
plugin's declared posture.

PGE-recognized floor operations include (at minimum):

- All Stratum 1 rules per `[FM-PGE-0003]`
- All catastrophic-class operations per `[FM-PGE-0009]`
- All judge-gated operations per the operator's PGE policy registry

Plugins **may** add stricter constraints in their policy block; PGE
**shall** honor stricter declarations. Plugins **shall not** be able
to relax the floor through declaration omission, soft-failure
patterns, or silent declarations.

*Verification: Conformance-test* — the harness submits a plugin
whose policy block declares a Stratum 1 operation as permitted
without further gating; PGE asserts the floor regardless and denies
or gates per the floor's classification. The deny + audit emission
is recorded.

#### `[FM-PGE-0011]` Divergence-event emission

When PGE detects a divergence between a plugin's declared policy
block (per §6 when landed) and the platform enforcement floor PGE
applies, PGE **shall** emit a `pcs.policy.divergence` event to ACT
per `[FM-INV-0005.2]` with the required attributes (`plugin_id`,
`operation`, `plugin_declared`, `platform_enforced`,
`caller_identity`, timestamp+trace) plus the `divergence_type`
discriminator per the following clause.

**Divergence-type discriminator.** `pcs.policy.divergence` events
**shall** carry a `divergence_type` attribute distinguishing the
divergence subclass. Each subclass has a single canonical emitter
pillar; an event of a given `divergence_type` value is authoritative
when emitted by its canonical pillar:

| `divergence_type` | Canonical emitter | What it represents |
|-------------------|-------------------|--------------------|
| `policy-block-mismatch` | **PGE (this requirement)** | Plugin's declared policy block disagrees with PGE's enforced floor |
| `identity-by-brief` | **IBX (per `[FM-IBX-0010]`)** | Assertion-only identity claim under the IBX-0010 / IAM-0014 transitional deviation |
| `gate-2-supplemental-only` | **PGE (per `[FM-PGE-0005]` Gate-2 transitional clause)** | Execution-side policy enforcement via supplemental surfaces only; DPG Gate-2 not yet operational |
| `detect-layer-not-operational` | **PGE (per `[FM-ACT-0008]` transitional clause)** | Deployment lacks an operational Detect Layer; detection-class compliance is failing, not deferred |
| `subagent-worktree-precursor` | **PGE (per `[FM-DPG-0013]` transitional clause)** | Workload uses the subagent-worktree pattern as a precursor; full DPG ephemeral-isolation contract not satisfied |
| `crb-codified-by-convention` | **PGE (per `[FM-CRB-0010]` transitional clause)** | Dispatch decision made under operator/agent convention; CRB broker daemon not yet operational |
| `mcc-partial-load` | **PGE (per `[FM-MCC-0012]` transitional clause)** | Dispatch targets a pillar not yet loaded into MCC as a plugin |
| `akb-fail-open-on-irreversible-hook` | **AKB (per `[FM-AKB-0011]` infra-decision-side escalation)** | AKB retrieval failed-open on a `[FM-AKB-0010]` domain-2 hook (`git push`, `gh pr`, deploy, substrate config) — the irreversible-step moment a suppressed warning is most load-bearing |
| `vendor-hosted-reasoning` | **PGE (per `[FM-INV-0006.1]` transitional clause)** | The session's reasoning runtime is a vendor-hosted inference service (Anthropic Claude Code, OpenAI Codex, equivalent) rather than the sovereign-local-inference reference — prompts and working context reach the vendor; per-session emission so the deployment's actual usage pattern is visible in ACT |
| (future subtypes) | Their respective canonical emitter pillar | Per the requirement that introduces the subtype |

**Pattern note.** PGE is the canonical emitter for substrate-policy and
deployment-state divergences (the rows above with PGE as emitter); IBX
owns identity-state divergences (`identity-by-brief`). The pattern is
*PGE emits when the divergence is observable from a policy decision;
IBX emits when the divergence is observable from a message-routing
decision*. Future subtypes **shall** be assigned to the pillar whose
decision surface first observes the divergence.

**Fallback emitter — canonical emitter unloaded during deviation
window.** A subset of `divergence_type` subtypes track exactly the
deviation classes during which their canonical emitter may not be
loaded — most notably `mcc-partial-load` per `[FM-MCC-0012]`, which
explicitly contemplates a deployment where PGE itself has not yet
been loaded into MCC as a plugin. To prevent the failure mode in
which the divergence tracking a partial-load state is itself silently
not emitted because its canonical emitter is part of the unloaded
set, the **MCC frame** per `[FM-MCC-0001]` **shall** serve as
**fallback emitter** for any `divergence_type` whose canonical
emitter is unloaded during the deviation window. Specifically:

- For `mcc-partial-load`, `gate-2-supplemental-only`,
  `subagent-worktree-precursor`, `crb-codified-by-convention`, and
  `detect-layer-not-operational`: when PGE is not loaded as an MCC
  plugin and a dispatch / decision satisfying the divergence
  condition is routed through MCC, the **MCC frame shall emit the
  divergence event in PGE's stead**, marking the event
  `emitter_role = "fallback"` and `originally_canonical = "PGE"`.
- Fallback-emitted events satisfy `[FM-INV-0005.2]` audit
  requirements identically to canonical-emitter events. Downstream
  consumers (e.g., `[FM-IAM-0014]` Condition 4) **shall** treat
  fallback-emitted events as equivalent to canonical-emitter events
  for query purposes, with `emitter_role` available as an
  observability attribute.
- Once the canonical emitter (PGE) loads into MCC per the
  `[FM-MCC-0006]` plugin contract, emission authority for the
  subtype **shall** revert to PGE; the MCC frame **shall not**
  continue to emit the subtype once PGE is loaded.

The fallback emitter is bounded to deviation windows in which the
canonical emitter is, by the very deviation being tracked,
provably unloaded. Fallback emission **shall not** be exercised
for any other reason.

Other pillars **may** emit corroborative records of an out-of-subtype
event for cross-pillar observability, but the canonical emitter for
each `divergence_type` is the authoritative source for that subtype.
Downstream consumers — including `[FM-IAM-0014]` Condition 4 reading
`identity-by-brief` events to verify sunset — operate against the
canonical-emitter records for the subtype they're verifying. All
subtypes flow into the same `pcs.policy.divergence` event class in
ACT, distinguishable by the `divergence_type` discriminator.

When the count of `divergence_type = "policy-block-mismatch"` events
from one `plugin_id` exceeds the operator-configured threshold within
the configured window, PGE **shall** emit the derived
`pcs.policy.divergence.clca-trigger` event per `[FM-INV-0005.2]`.
CLCA-trigger derivation **shall** operate per-`divergence_type`;
counts and thresholds for other subtypes are owned by the canonical
emitter of that subtype (e.g., `identity-by-brief` CLCA-trigger
derivation is IBX's per `[FM-IBX-0010]`).

*Verification: Conformance-test* — the harness induces a
`policy-block-mismatch` divergence by submitting a plugin manifest
with a relaxed policy block; asserts `pcs.policy.divergence` is
emitted with all required attributes plus `divergence_type =
"policy-block-mismatch"`; exceeds the threshold by repetition and
asserts the `pcs.policy.divergence.clca-trigger` event is also
emitted with the correct discriminator scope.

#### `[FM-PGE-0012]` Policy overlay consumption

PGE **shall** consume policy overlays distributed via the PCS
registry (§6 when landed) and apply them additively at Stratum 2
above the deployment's baseline policy. Overlay application
**shall**:

1. Be evaluated against `[FM-PGE-0003]` Stratum 1 invariants — an
   overlay attempting to weaken a Stratum 1 rule **shall** be
   rejected at apply time.
2. Carry a quorum attestation per `[FM-INV-0004]` if the overlay
   class is catastrophic (per `[FM-INV-0004]` and any operator-
   declared overlay-quorum policy).
3. Be auditable — each overlay's apply, deprecate, and revoke events
   are recorded in ACT per `[FM-PGE-0008]` and the audit chain
   attributes subsequent decisions to the overlay-augmented policy
   version.

Overlays composing across regimes (e.g., HIPAA + GDPR + FedRAMP-High
on one deployment) **shall** be applied in the operator-declared
order; PGE **shall** evaluate decisions against the composed effective
policy.

*Verification: Conformance-test* — the harness applies a Stratum 2
overlay, asserts subsequent decisions reflect the overlay-augmented
policy; attempts to apply a Stratum 1-weakening overlay and asserts
rejection; applies a catastrophic-class overlay without quorum and
asserts rejection.

#### `[FM-PGE-0013]` Fail-strict on policy-engine unavailability

If the PGE policy-evaluation engine is unavailable (engine process
down, policy corpus unreadable, audit sink unreachable per
`[FM-PGE-0008]`), policy-gated operations **shall** fail closed per
`[FM-INV-0002]`. PGE unavailability **shall not** default to "allow"
or "skip enforcement."

This **shall** apply at both Gate 1 and Gate 2: IBX **shall** reject
submissions when PGE cannot evaluate; DPG **shall** refuse code
execution when PGE cannot evaluate.

*Verification: Conformance-test* — the harness induces PGE engine
unavailability and submits compliant operations; asserts deny at both
gates; restores PGE and asserts compliant operations succeed.

#### `[FM-PGE-0014]` Telemetry emission

PGE **shall** emit OTLP-format traces, metrics, and logs per the
mesh-wide telemetry discipline. Span names **shall** follow the
`mesh.pge.*` namespace per the per-pillar telemetry contract;
required attributes **shall** include `decision`, `rule-id`,
`policy-version`, `principal-id` (from the consumed identity
context), `trace_id`, `span_id`.

Note: PGE's own telemetry (`mesh.pge.*` traces/metrics/logs) is
distinct from the `pge.*_evaluated` audit-class events PGE emits to
ACT per `[FM-PGE-0008]`. The two flow to different consumers — ACT
for audit reconstructability; the deployment's OTLP sink for
operational observability.

*Verification: Conformance-test* — the harness invokes representative
PGE operations and asserts emission of expected span/metric/log
records to a test OTLP sink with required attributes present;
confirms the `mesh.pge.*` namespace.

### §5.3.1 PGE Conformance Profile

The PGE pillar's substrate substitutability claim covers exactly the
rows in this Conformance Profile. Conformance is verified by passing
the PGE multi-profile conformance suite against the listed
implementations.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Rule corpus storage | `[FM-PGE-0003]`, `[FM-PGE-0004]` | Git-versioned Markdown narrative + per-component executable rule files (one per enforcement surface) | OPA Rego policy bundle, Cedar policy file, database-backed corpus with explicit version table, hybrid (Markdown for Stratum 1 + Rego for Stratum 2) | `pge-corpus-v1` |
| Policy evaluation engine | `[FM-PGE-0001]`, `[FM-PGE-0002]`, `[FM-PGE-0013]` | Distributed per-surface enforcement composed of: a build-time test-runtime policy suite exercising the rule corpus, a runtime tool-call guard hook on the agent surface, and a CI release gate | OPA (Open Policy Agent) 0.60+ with Rego eval, Cedar runtime with declarative policy engine, per-pillar embedded policy engines, hybrid centralized + per-surface | `pge-engine-v1` |
| Enforcement surface | `[FM-PGE-0005]`, `[FM-PGE-0007]`, `[FM-PGE-0009]`, `[FM-PGE-0010]` | Distributed multi-surface — PreToolUse hook + IBX submission chokepoint + DPG ephemeral boundary + CI release gate + per-server test suite | OPA-sidecar middleware at IBX/DPG, Cedar runtime sidecar, custom enforcement library per-pillar, hybrid | `pge-enforcement-v1` |
| Overlay consumption | `[FM-PGE-0012]` | Signed overlay bundles consumed from PCS registry (§6 when landed) | Any signed bundle format declared conformant by PCS (§6 + Appendix B when landed) | `pge-overlay-v1` |
| Telemetry sink | `[FM-PGE-0014]` | OTLP-on-the-wire (any OTLP-compatible backend per ACT §5.4) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `pge-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported. Extending
the profile requires the argued-case discipline per `[FM-INV-0003.2]`
and a multi-profile conformance run proving the new substrate passes
the PGE test suite. The double-guardrail composition (`[FM-PGE-0005]`)
and the single-source-of-policy-truth invariant are preserved across
substrate change.

### §5.4 ACT — Agent Cognitive Telemetry

**Scope.** ACT is the mesh's immutable, locally-hosted audit ledger.
Every reasoning span, tool call, token consumed, signed action, IAM
event, IBX message, quorum vote, Judge approval, policy decision, and
divergence event flows to ACT. ACT is the consumer of the mesh's
audit emission stream; every other pillar **shall** emit
state-affecting events here. ACT enables non-repudiation, per-session
forensics, regulatory compliance audit, and the dialectical-engine
evidence trail.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply — ACT emission failure is fail-strict (the upstream operation halts) per the per-pillar audit-emission requirements.
- ACT consumes events emitted by every other pillar: `[FM-IBX-0012]` (IBX status transitions), `[FM-IAM-0013]` (IAM state-affecting operations), `[FM-PGE-0008]` (PGE decisions), `[FM-PGE-0011]` (`pcs.policy.divergence` events with `divergence_type` discriminator), and per-pillar audit requirements in future pillars (§§5.5–5.8).
- ACT is queried by `[FM-IAM-0014]` Condition 4 for `divergence_type = "identity-by-brief"` events to verify the IAM operational-state sunset.
- ACT honors the **genesis event carve-out** per `[FM-INV-0004.5]` — the bounded class of mesh-init and IAM-init ceremony events that bypass `[FM-ACT-0003]` IAM-attribution exclusively for the purpose of bringing the identity system into existence; outside of this closed carve-out, no unattributed events are accepted.

#### `[FM-ACT-0001]` Append-only event store

The ACT event store **shall** be append-only at the substrate layer.
No event, once committed, **shall** be modifiable, deletable, or
shadowed by an in-place rewrite, **except** via the
retention-expiration ceremony governed by `[FM-ACT-0011]` — which is
itself audited (the ceremony emits `act.retention.expired`), bound to
the operator-configured retention rule per regulatory regime, and
gated such that reduction below the regime's minimum is a
catastrophic-class operation requiring quorum per `[FM-INV-0004]`.
The `[FM-ACT-0011]` ceremony is the sole permitted removal path.
Corrections **shall** be expressed as a new event with a
`correcting_event_id` field referencing the event being corrected;
the original event **shall** remain in the store (the
`correcting_event_id` mechanism is not a removal path — it is a
forward-only correction).

The append-only property is what makes the audit chain
tamper-evident; modify-in-place semantics would destroy the property.
The retention-expiration carve-out is bounded — it removes *whole
events past their retention window* per a published rule, it does not
permit targeted edits or selective deletions, and the ceremony itself
leaves an audit record.

*Verification: Conformance-test* — the harness attempts every
documented substrate write path (UPDATE, DELETE, REPLACE) targeting
committed events outside the `[FM-ACT-0011]` ceremony; asserts every
such attempt fails. Inserts new events including a
`correcting_event_id` reference and asserts both events are
queryable. Exercises the `[FM-ACT-0011]` retention-expiration
ceremony and asserts the `act.retention.expired` audit record is
emitted with the rule applied and event count.

#### `[FM-ACT-0002]` Unidirectional cognitive-event emission

Cognitive events **shall** flow into ACT from emitting pillars and
**shall not** flow back into the mesh's decision pipeline except via
explicit curator-gated review. ACT is the terminal store for audit
emission; pillars **shall not** read recent events from ACT to make
runtime decisions (with the documented exceptions: `[FM-IAM-0014]`
Condition 4 sunset verification, and `[FM-PGE-0011]` CLCA-trigger
derivation, both of which are explicit queries against ACT
specifically because the audit trail IS the source of truth for those
specific checks).

Curator-review workflows (CLCA action review, AIR drafting,
compliance audit) **may** read from ACT freely; their outputs
**shall not** loop directly back into pillar-decision pipelines
without an explicit review step.

*Verification: Inspection* — review of each pillar's runtime code
path verifies no read-from-ACT-into-decision pattern exists except
the documented exceptions; the documented exceptions are explicitly
listed and reviewed against the requirements that invoke them.

#### `[FM-ACT-0003]` Session-granular attribution

Every cognitive event **shall** carry attribution to the specific
session under which it occurred. Session attribution **shall**
include both the `principal-id` (the identity per `[FM-IAM-0006]`)
and a session identifier distinct from `principal-id` per
`[FM-IBX-0006]`'s identity-vs-session distinction.

Session-granular attribution is load-bearing for per-session
incident response: suspend one session of one identity while other
sessions of the same identity continue operating per
`[FM-IAM-0004]`. Without session granularity, the only response
unit is "the whole identity."

**Genesis-event carve-out.** Events of the genesis class per
`[FM-INV-0004.5]` are the sole exception to this attribution
requirement — by construction they exist to bring the IAM
`principal-id` system into existence and therefore cannot reference
it. Genesis events carry holder-fingerprint attestation per
`[FM-INV-0004.5]` item 3 in place of the `principal-id` /
session-id pair. No other class of event **shall** be permitted to
land in ACT without the full `principal-id` + session-id
attribution.

*Verification: Conformance-test* — the harness invokes operations
from multiple sessions of the same identity and asserts each event
in ACT carries distinct session identifiers; asserts session
identifiers persist with their events through the storage layer;
asserts every non-genesis event in the store carries a
`principal-id`; asserts a non-genesis event submitted without
attribution is rejected.

#### `[FM-ACT-0004]` Event-type taxonomy

Every event in ACT **shall** carry a typed `event_type` discriminator
drawn from a stable, versioned event-type taxonomy. The taxonomy
**shall** include at minimum:

- **`iam.*`** — IAM state-affecting events per `[FM-IAM-0013]`
- **`ibx.*`** — IBX message-transition events per `[FM-IBX-0012]`
- **`pge.*_evaluated`** — PGE decision events per `[FM-PGE-0008]`
- **`pcs.policy.divergence`** — Divergence events per `[FM-INV-0005.2]` + `[FM-PGE-0011]` (with `divergence_type` discriminator)
- **`pcs.policy.divergence.clca-trigger`** — Derived CLCA-trigger events per `[FM-INV-0005.2]`
- **`act.chain_checkpoint`** — Chain-verification checkpoints per `[FM-ACT-0005]`
- **`act.detection_signal`** — Detection-layer outputs per `[FM-ACT-0008]` when operational

Event-type identifiers are immutable + append-only per the same
discipline as requirement IDs (§0.2). Deprecated event types
**shall** be marked and retained; new types **may** be added.

*Verification: Static-check* — the event-type registry is parsed and
verified against the substrate schema; the harness submits events of
each enumerated type and asserts schema-conformant storage.

#### `[FM-ACT-0005]` Per-session cryptographic chaining

Events within a session **shall** be cryptographically chained: each
event's record **shall** include a hash incorporating the prior
event's hash within the same session, forming a per-session
tamper-evidence chain. The session boundary defines chain scope —
cross-session correlation **shall** use `trace_id` / `span_id`
correlation per `[FM-INV-0001]` audit invariants, not the per-session
hash chain.

Chain-verification checkpoints **shall** be emitted as
`act.chain_checkpoint` events at operator-configured cadence (event
count or wall-clock interval); checkpoints aggregate the chain hash
across the prior session window and **shall** be independently
verifiable from substrate state without trust in ACT's runtime.

**Genesis-event chain seeding.** The first runtime session of any
pillar after mesh init **shall** chain-link its initial event to
the corresponding genesis event's hash per `[FM-INV-0004.5]` item
4 — the genesis event is the verifiable root anchor of the chain.
This is the sole permitted predecessor that is itself
unattributed; subsequent links require full attribution per
`[FM-ACT-0003]`. A chain that does not trace back to a genesis-
event anchor for its initial link is non-conforming.

**Retention-boundary re-anchoring.** When the `[FM-ACT-0011]`
retention-expiration ceremony removes a chain predecessor, the
ceremony's own `act.retention.expired` event **shall** serve as
the **new anchor** for survivor events whose immediate predecessor
was expired. The `act.retention.expired` event itself **shall**
record the hash of the most-recent surviving chain-checkpoint at
the expiration boundary, so the chain remains independently
verifiable up-to and from the boundary with a documented
discontinuity at the boundary record. Survivor events **shall not**
rewrite their hash-link fields in place; the re-anchoring is
expressed by the chain-verification routine treating
`act.retention.expired` events as valid predecessors with the
boundary semantics. The same re-anchoring discipline applies at
the `[FM-ACT-0010]` cold-storage tier boundary when implemented.

*Verification: Static-check + Conformance-test* — Static-check
verifies hash-chain field presence in the event schema; the harness
constructs a tampered event in storage (e.g., by direct substrate
write outside the ACT API) and asserts chain re-verification detects
the tampering at the next checkpoint; verifies the first runtime
event after genesis chain-links to the genesis hash; exercises the
`[FM-ACT-0011]` ceremony on a chain-bearing session and asserts
chain re-verification across the expiration boundary passes via the
`act.retention.expired` re-anchor.

#### `[FM-ACT-0006]` Hash algorithm policy

The chain-hash algorithm **shall** be a collision-resistant
cryptographic hash function suitable for chaining. The sovereign
reference is **SHA-256**; FIPS-validated implementations are required
for deployments invoking the §4.2 FIPS-Day-1 discipline. Hash
upgrades (e.g., SHA-256 → SHA-3-256) **shall** be performed via a
documented migration ceremony that preserves verification of the
pre-migration chain through the migration boundary.

*Verification: Inspection* — review of the ACT runtime configuration
verifies the active hash algorithm + FIPS-validated implementation
in regulated deployments.

#### `[FM-ACT-0007]` Three-consumer-class access pattern support

The ACT event store **shall** support three concurrent consumer
classes without compromise to any of them:

1. **Compliance / Audit** — point lookups by `(identity, session,
   time range)` for human-supervised review. Latency-tolerant; query
   patterns simple.
2. **Detection** — pattern analytics for behavioral-anomaly and
   policy-violation detection (per `[FM-ACT-0008]` when
   operational). Latency-sensitive; query patterns ML-driven.
3. **CLCA / Post-Mortem** — JOIN-heavy reconstructive queries across
   identities, sessions, and time ranges, to trace cascades or
   identify CLCA action targets. Latency-irrelevant; query patterns
   ad-hoc.

The substrate choice **shall** demonstrate it can serve all three
patterns under representative load without degrading any of them.

*Verification: Conformance-test* — the harness exercises
representative queries from each class concurrently against a
populated event store and asserts SLO-conformant latency for
detection + correctness for audit and CLCA query patterns.

#### `[FM-ACT-0008]` Detect Layer (transitional clause)

ACT **may** expose a Detect Layer that consumes events from the
event store and emits `act.detection_signal` events back into the
store for behavioral-anomaly detection and policy-violation
correlation. The Detect Layer is a runtime ML component reading
ACT's event stream and producing inferences.

**Transitional deviation — sunset on Detect Layer operational
availability.** A deployment operating without Detect Layer **may**
satisfy this Standard's other requirements without satisfying
`[FM-ACT-0008]`; the Detect Layer is a future capability whose
absence is a recognized deviation, **scoped strictly to the
Compliance/Audit and CLCA consumer classes**. Absence of an
operational Detect Layer **shall** constitute non-conformance with
respect to detection-class compliance — a deployment without Detect
Layer **shall not** be represented as satisfying any
detection-class compliance requirement (regulatory or otherwise),
and the deviation period does not extend coverage to those
requirements. The deviation **shall**:

1. Be registered in Appendix F with explicit sunset condition:
   "Detect Layer operational per `[FM-ACT-0008]`" — declared by the
   operator when the Detect Layer is built, tested, and connected to
   the event store.
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "detect-layer-not-operational"` per
   `[FM-PGE-0011]` discriminator (canonical emitter: PGE, via the
   policy that classifies a deployment without an operational
   Detect Layer as non-conformant to detection-class compliance) at
   deployment-attestation time and on each operator-configured
   attestation review cycle, recording the deviation's continued
   application.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when the Detect Layer is declared
   operational. Mirror of the `[FM-IBX-0010]` / `[FM-IAM-0014]` /
   `[FM-PGE-0005]` Gate-2 / `[FM-DPG-0013]` / `[FM-CRB-0010]` /
   `[FM-MCC-0012]` transitional pattern.
4. Not be cited as satisfaction of detection-class compliance
   requirements (e.g., regulatory requirements demanding active
   behavioral monitoring) that the Detect Layer addresses — an
   absent Detect Layer is failing such requirements, not deferring
   them.

*Verification (operational): Conformance-test* — the harness
verifies Detect Layer consumes events and emits
`act.detection_signal` records to the store.
*Verification (deviation period): Inspection of deviation registry*
— deviation entry present in Appendix F with sunset condition; the
deployment does not claim conformance to detection-class compliance
requirements without Detect Layer.

#### `[FM-ACT-0009]` Fail-strict on ACT unavailability

Per the per-pillar audit-emission requirements (`[FM-IBX-0012]`,
`[FM-IAM-0013]`, `[FM-PGE-0008]`, and analogous future pillar
requirements), an upstream operation **shall not** complete if its
audit emission cannot be confirmed by ACT. ACT unavailability —
substrate down, network partition, ingestion queue saturated —
**shall** result in the upstream operation failing strict per
`[FM-INV-0002]`.

**Emission-confirmation contract.** "Confirmed by ACT" is defined as
the following synchronous, durable-commit ack sequence; pillar audit
emissions and ACT implementations **shall** conform to it so the
cross-pillar fail-strict is testable from both sides:

1. **Emit.** The upstream pillar submits the event to ACT's ingestion
   endpoint with a request-scoped `emission_id` (uniquely
   identifying this emission attempt) and the full event payload
   including its `event_type`, attribution per `[FM-ACT-0003]`, and
   chain-link fields per `[FM-ACT-0005]`.
2. **Commit.** ACT **shall** durably append the event to the
   event-store substrate (the append must be persistent across the
   substrate's documented crash-recovery boundary — a memory-buffered
   write that has not flushed to durable storage **shall not** be
   acknowledged) and write the chain-link fields per
   `[FM-ACT-0005]`.
3. **Ack.** ACT **shall** return an acknowledgement to the upstream
   pillar referencing the `emission_id` and including the committed
   event's stored identifier. The acknowledgement **shall** be
   returned only after step 2 completes successfully.
4. **Proceed.** The upstream pillar's operation **shall not** be
   considered complete until the acknowledgement is received within
   the timeout bound established by `[FM-INV-0002]`.

If the acknowledgement is not received within the timeout, or is
explicitly negative, the upstream operation **shall** fail strict —
the lack-of-ack and the negative-ack are equivalent in their effect
on the upstream caller per `[FM-INV-0002]`. Implementations **may**
implement retry-with-idempotency on the upstream side keyed on
`emission_id`; ACT **shall** treat duplicate `emission_id`
submissions as idempotent (return the prior acknowledgement) rather
than as new events.

ACT **shall not** silently drop events under load. If sustained
ingest exceeds capacity, ACT **shall** apply backpressure such that
upstream emissions block (with timeout per `[FM-INV-0002]` →
fail-strict) rather than complete without persistence. Acknowledging
a buffered-but-not-yet-durable event **shall not** be permitted.

*Verification: Conformance-test* — the harness induces ACT
unavailability (substrate down, ingestion saturation, ack-path
faults) and submits upstream operations across pillars; asserts
every operation fails strict on lack-of-ack or negative-ack within
the `[FM-INV-0002]` timeout; restores ACT and asserts operations
resume successfully. Exercises the idempotency contract by
re-submitting the same `emission_id` and asserts ACT returns the
prior acknowledgement without producing a second stored event.

#### `[FM-ACT-0010]` Cold-storage tier (deferred)

ACT **may** offload events older than an operator-configured age to
a cold-storage tier with cheaper-per-byte economics; the cold tier
**shall** retain chain verifiability per `[FM-ACT-0005]` across the
migration boundary and **shall** remain readable on demand for
compliance queries.

This requirement is intentionally deferred — sovereign-reference
selection waits on operational sizing data. Operators **shall not**
implement a cold-storage tier that breaks chain verifiability.

*Verification: Inspection (deferred)* — when a cold-storage tier is
implemented, chain re-verification across the warm/cold boundary
**shall** pass as a conformance gate; until then, this requirement is
not exercised.

#### `[FM-ACT-0011]` Retention controls per regulatory regime

Event retention **shall** be operator-configurable per regulatory
regime via the PGE overlay model (per `[FM-PGE-0012]`). Different
event types **may** have different retention windows (e.g.,
`iam.*` events retained longer than `act.detection_signal` events
under a HIPAA overlay). Retention reduction past the regime's
minimum **shall** be classified as a catastrophic-class operation
per `[FM-INV-0004]` and **shall** require quorum.

Events past their retention window **shall** be removed via the
documented retention-expiration ceremony, which **shall** itself
emit an `act.retention.expired` event recording the count of removed
events and the retention rule applied. Direct deletion via substrate
APIs **shall not** be permitted; expiration is the only documented
removal path.

*Verification: Static-check + Conformance-test* — Static-check
verifies retention policy configuration is loaded from PGE overlay;
Conformance-test exercises retention-expiration and verifies the
`act.retention.expired` event is emitted with the correct attributes;
direct-deletion attempts via substrate API are rejected.

#### `[FM-ACT-0012]` ACT's own telemetry emission

ACT **shall** emit OTLP-format traces, metrics, and logs for its own
operational observability per the mesh-wide telemetry discipline.
Span names **shall** follow the `mesh.act.*` namespace; required
attributes per the per-pillar telemetry contract.

Note: ACT's *own* operational telemetry (`mesh.act.*`) is distinct
from ACT's role as the consumer of every other pillar's audit emission
(the `iam.*` / `ibx.*` / `pge.*` / `pcs.policy.divergence` etc. event
classes flowing into ACT's event store). The two flow to different
sinks — the operational OTLP sink for ACT-pillar observability;
ACT's own event store for the audit class.

*Verification: Conformance-test* — the harness invokes representative
ACT operations and asserts emission of expected span/metric/log
records to the operational OTLP sink with `mesh.act.*` namespace.

### §5.4.1 ACT Conformance Profile

The ACT pillar's substrate substitutability claim covers exactly the
rows in this Conformance Profile. Conformance is verified by passing
the ACT multi-profile conformance suite against the listed
implementations.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Event store | `[FM-ACT-0001]`, `[FM-ACT-0004]`, `[FM-ACT-0007]`, `[FM-ACT-0009]` | ClickHouse 23.8+ with append-only `act.events` table | PostgreSQL 17+ with columnar extension (cstore_fdw / pg_columnar), NATS JetStream 2.10+ (event-store mode), Apache Kafka 3.6+ (compacted topics), OpenTelemetry backend (Tempo + Loki) | `act-event-store-v1` |
| Chain-verification crypto | `[FM-ACT-0005]`, `[FM-ACT-0006]` | SHA-256 (FIPS-validated implementation when §4.2 FIPS-Day-1 applies) | SHA-3-256, BLAKE3 (newer FIPS path), HMAC-keyed variants for additional tamper resistance | `act-chain-crypto-v1` |
| Detect Layer ML runtime | `[FM-ACT-0008]` | ML inference runtime with structured-data preprocessing, capable of consuming ACT's event stream and emitting `act.detection_signal` records at SLO-conformant latency per `[FM-ACT-0007]` (Detect Layer operational); transitional deviation per `[FM-ACT-0008]` | Any conforming ML-inference runtime satisfying the consume-stream-and-emit-detection-signal capability — embedded inference servers (Triton Inference Server, BentoML, custom), stream-processing engines with ML hooks, ONNX-Runtime-class portable inference | `act-detect-v1` (operational) / `act-detect-deviation-v1` (transitional) |
| Cold-storage tier | `[FM-ACT-0010]` | Deferred — sovereign-ref selection pending operational sizing | S3-compatible object storage (MinIO, AWS S3, Azure Blob, OCI Object Storage), Apache Iceberg + Parquet on S3-compatible, ClickHouse cold-storage tier with tiered TTL | `act-cold-storage-v1` (when implemented) |
| Telemetry sink | `[FM-ACT-0012]` | OTLP-on-the-wire (any OTLP-compatible backend) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `act-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported. Extending
the profile requires the argued-case discipline per `[FM-INV-0003.2]`
and a multi-profile conformance run proving the new substrate passes
the ACT test suite.

### §5.5 AKB — Agent Knowledge Base

**Scope.** AKB is the mesh's authored-knowledge substrate: the
specs, planning docs, post-mortems, security frameworks, agent
briefs, AIRs (Agentic Incident Reports), design notes, and
friction-catalog entries that comprise the **reference corpus** an
agent reasons *against*. AKB ingests that corpus, projects it per
agent role, and surfaces it at session-start (bounded prior) and
mid-reasoning (gradient-gated injection) without inducing
context-saturation or substrate-trap failures. The pillar exists
because brief-drift, knowledge-rot, and substrate-trap (vector
retrieval surfacing dead-end content as candidate solutions to
physics queries) are observable failure classes in the current
mesh, not hypothetical ones.

**Scope boundary — AKB vs PCS.** AKB is the reference layer (what
an agent *reads to reason*); PCS owns the executable layer (what an
agent *runs*). Runbooks, workflows, skills, and other executable
artifacts are **PCS-governed and out of AKB scope** — they live
under the PCS artifact contract (contents + test + deploy), not in
the AKB corpus. The reverse is also true: an AIR or design note
about a runbook is AKB corpus; the runbook itself is not. This
boundary prevents the duplication that would otherwise let an
agent reason against a stale copy of an executable that PCS has
since updated.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply, with the explicit exception that AKB retrieval **fails open** per `[FM-AKB-0011]` — AKB unavailability does not halt agents. Fail-open is a deliberate departure from fail-strict, scoped strictly to retrieval; state-affecting operations (promote, curate, bootstrap, ingest, tier0-build) fail strict per the standard.
- AKB emits state-affecting operations as `akb.*` events into ACT via the `[FM-ACT-0009]` emission-confirmation contract; the event-type taxonomy is enumerated under `[FM-ACT-0004]`.
- AKB queries take `principal-id` from IAM per `[FM-IAM-0006]` and use it for the self-review exemption per `[FM-AKB-0006]`.
- AKB queries and ingest paths are subject to PGE policy per `[FM-PGE-0008]` (deny on policy violation; AKB **shall not** bypass).
- Role-projection axes, exemption tables, and promotion-gate identities **shall** be expressed as PGE-managed policy artifacts when PGE is operational; until then, AKB carries its own table per the substrate matrix.

#### `[FM-AKB-0001]` Two-tier delivery

AKB **shall** deliver knowledge to agents in exactly two tiers, and
**shall not** surface knowledge by any other mechanism:

1. **Tier 0 — bounded always-loaded prior.** Injected at every
   agent session start as standing context, not as user input.
   Contains the irreducible facts every agent needs to reason at all
   (current production phase, locked physics laws, dead-end list,
   security non-negotiables). Source-of-truth is a single
   fence-sentinel-delimited markdown artifact; the deployed snapshot
   **shall** be content-hash-addressed.
2. **Tier 1 — gradient-gated mid-reasoning injection.** Triggered
   by explicit agent query (`akb_query`) or by hook-fired query at
   designated decision points per `[FM-AKB-0010]`. Per-injection
   volume budget: at most 10 chunks and at most 3 KB total.

Session-start mass push of the full corpus **shall not** be
permitted. The naive "load everything" pattern saturates channel
capacity before a reasoning gradient can form, and is what AKB
exists to prevent.

*Verification: Conformance-test* — the harness exercises agent
session start and verifies Tier-0 is loaded as standing context;
exercises Tier-1 hook + explicit-query paths and verifies per-event
volume budget; asserts no other knowledge surface exists.

#### `[FM-AKB-0002]` Tier-0 size cap (hard)

The deployed Tier-0 snapshot **shall not** exceed **1024 bytes**.
The cap is enforced at build time — a build whose snapshot exceeds
the cap **shall** fail and **shall not** produce a deployable
artifact. AKB **shall** emit a build-time warning at 95% of the cap
(975 bytes) so headroom is observable before the cap binds.

The cap is non-negotiable: Tier-0 is the always-loaded prior; growth
without bound makes Tier-0 itself the saturation source it was
designed to prevent.

*Verification: Static-check + Conformance-test* — Static-check
verifies the build-time enforcement; Conformance-test attempts to
deploy an over-cap snapshot and asserts the build rejects it.

#### `[FM-AKB-0003]` Tier-0 source provenance

A deployable Tier-0 snapshot **shall** be built only from
merged-`main` source on the canonical source artifact. Locally-built
snapshots (built from working-tree or feature-branch source) **may**
be used for development and conformance testing but **shall not** be
deployed to a live agent session. Tier-0 source edits **shall** be
gated by the Bar-B promotion gate per `[FM-AKB-0008]` — Judge
approval via the MCC review path.

*Verification: Conformance-test* — the harness attempts to deploy a
snapshot built from a non-`main` source commit and asserts the
deployment is rejected; verifies a snapshot deployed via the Bar-B
path carries the corresponding promotion record.

#### `[FM-AKB-0004]` Deterministic pre-filter before vector similarity

Tier-1 retrieval **shall** execute a deterministic pre-filter on
chunk metadata *before* the vector-similarity step. The pre-filter
**shall**, at minimum, exclude chunks where `violates_invariant =
true`, **except** when the query is explicitly historical (the query
carries an `is_historical = true` flag and the chunk's
`invariant_class` matches the query's stated subject).

Vector retrieval is physics-blind: failure-mode post-mortems and
invariant-compliant designs share vocabulary, so cosine similarity
alone surfaces dead-end content as candidate solutions to physics
queries. The pre-filter makes vector math downstream of physics
math.

AIRs carry `violates_invariant = false` per `[FM-AKB-0012]` and
therefore **shall** pass the pre-filter for non-historical queries
— AIRs are operational lessons whose surfacing at decision points
is the intended behavior, not failure-class content the pre-filter
is meant to exclude. The pre-filter targets only chunks whose
`violates_invariant = true`.

Role projection per `[FM-AKB-0005]`, selective exemption per
`[FM-AKB-0006]`, and the reranker (when present) **shall** apply
*after* the pre-filter. A retrieval implementation that runs vector
similarity over the unfiltered chunk set, even if it then filters,
does not conform — the pre-filter is the search-space contract, not
a post-rank trim.

*Verification: Conformance-test* — the harness seeds the chunk
store with mixed `violates_invariant`-true and -false chunks of
near-identical cosine distance to a non-historical query; asserts
the returned set contains only `violates_invariant = false` chunks;
re-runs with `is_historical = true` + matching `invariant_class` and
asserts the historical chunks return.

#### `[FM-AKB-0005]` Role projection at retrieval

AKB **shall** maintain a single source of truth in the chunk store
— no per-agent or per-role chunk duplication. Per-agent reasoning
independence **shall** be expressed via *projection at retrieval
time*: each chunk carries a `roles` array, and a query against
`role = R` returns the subset of chunks whose roles include `R`.

The dialectical engine relies on agents reasoning from different
priors over the same evidence; storage-time duplication would diverge
the underlying evidence, and a shared single-projection retrieval
would converge the priors. Role projection at retrieval is the
mechanism that satisfies both invariants simultaneously.

*Verification: Conformance-test* — the harness ingests a chunk with
`roles = [r1, r2]`; queries from `role = r1`, `role = r2`, and
`role = r3` and asserts the chunk appears for `r1` and `r2` only;
verifies there is exactly one row per `chunk_id` in the underlying
chunk store.

#### `[FM-AKB-0006]` Self-review exemption

A querying agent **shall be** exempt from AKB query results that
include chunks they themselves authored, when the querying task is a
review-class task. The exemption is matched on `(querying_agent_id
== chunk.author_id) AND (task_type ∈ review-class)`, where the
review-class task-type vocabulary is bounded and audited per the
substrate matrix.

The mechanism preserves the dialectical-engine guarantee: an agent
reviewing their own artifact **shall not** be primed by their own
prior reasoning surfaced through AKB. The exemption is enforced at
retrieval time, not at storage time; the chunks remain in the
corpus for other agents.

*Verification: Conformance-test* — the harness submits a chunk
authored by agent `A`; queries from agent `A` with a review-class
task-type and asserts the chunk is excluded from results; queries
from agent `A` with a non-review task-type and asserts the chunk
returns; queries from agent `B` with a review-class task-type and
asserts the chunk returns.

#### `[FM-AKB-0007]` Cross-role per-document cap

The number of corpus documents whose `roles` frontmatter spans
**all** role projections in the deployed role set **shall not**
exceed **50**. The cap is per-document, not per-chunk; per-chunk
cross-role count is preserved as a non-blocking advisory signal.
The cap is enforced at the bootstrap pre-write gate per
`[FM-AKB-0009]` — a bootstrap whose dry-run report shows more than
50 such documents **shall be** rejected.

Without the cap, the pressure to mark chunks "visible to all"
collapses role projection toward a shared substrate and defeats
`[FM-AKB-0005]`.

*Verification: Conformance-test* — the harness constructs a corpus
with 51 all-roles documents and submits a bootstrap dry-run; asserts
the dry-run rejects with the cross-role-cap reason; reduces to 50
and asserts the dry-run accepts.

#### `[FM-AKB-0008]` Stratified promotion gates

Promotion of an AKB chunk to a higher confidence tier **shall** be
gated by content class:

- **Bar A — Auto** — procedural, reference, or routine planning
  chunks **may** be auto-promoted to `validated` on `N`-successful-
  uses query-log signal (with `N` configurable per deployment).
- **Bar B — Judge-gated** — spec changes, cross-cutting
  architectural decisions, and Tier-0 source content **shall**
  require Judge approval via the MCC review path before promotion.
- **Bar C — Patton-veto** — failure-class chunks (V-results,
  dead-end docs, anti-patterns, CLCA outputs) **shall** queue for
  Patton review on next invocation, with rejection landing as a
  rejection-class promotion event.
- **Physics Bar C — Two-key** — chunks touching V16-class locked
  physics invariants **shall** require both Judge **and** Einstein
  approval; neither alone is sufficient.

Bar-B and Bar-C promotion gates **shall not** auto-promote on query
signal; the rejection of a Bar-B/Bar-C chunk by its gate **shall**
be a recorded event, not a silent re-queue.

*Verification: Conformance-test* — the harness exercises promotion
attempts under each bar with valid and invalid approvers; asserts
Bar A auto-promotes only on the documented signal; Bar B / Bar C /
Physics Bar C require the documented identities and reject when
unmet.

#### `[FM-AKB-0009]` Bootstrap pre-write gate

Any ingest event writing **20 or more chunks** in a single
transaction — bootstrap, embedding-model swap, schema migration,
large backfill — **shall** pass through a three-step pre-write
gate:

1. **Dry-run.** Produce a dry-run report covering cross-role
   document count (`[FM-AKB-0007]`), inherited-over-tagging suspects
   (chunks whose roles inherit from a path-default outside the
   expected-domain allowlist), default-rule (no-specific-match)
   count, and pre-filter contract violations (`violates_invariant =
   true` chunks missing `invariant_class`, etc.).
2. **Patton review.** Patton **shall** review the dry-run report
   and produce a sign-off or rejection.
3. **Judge `--apply`.** Judge **shall** issue an explicit `--apply`
   action via the MCC path. The `--apply` step **shall** reference
   the dry-run report hash and the Patton sign-off identifier.

Single-file edit re-ingests below the 20-chunk threshold **may**
proceed via the standard chunking + embedding path without the
gate. The threshold is non-negotiable; the gate is the cheap CLCA
chokepoint and skipping it is a defect requiring rollback.

*Verification: Conformance-test* — the harness submits a 20-chunk
ingest without the gate and asserts rejection; submits with the gate
chain and asserts acceptance only on a non-empty dry-run + Patton
sign-off + Judge `--apply` matching the dry-run hash.

#### `[FM-AKB-0010]` Hook trigger domains

Tier-1 hook-fired queries **shall** trigger at both of two domains,
not just one:

1. **Code-author-side** — `Edit` / `Write` on protected file
   patterns; `git commit`; MCP plugin invocation on a designated set
   of plugins.
2. **Infra-decision-side** — `git push`; `gh pr create` /
   `gh pr review`; deploy commands; substrate config edits.

The infra-decision-side domain is load-bearing: it fires *before*
the irreversible step (the push, the PR, the deploy), so the
operational lesson surfaces at the moment the agent is about to act
on potentially stale assumptions. A hook implementation that fires
only on the code-author side leaves the infra-decision pain class
uncovered and does not conform.

Hook enforcement **shall** be at the runtime tool-call layer per
`[FM-INV-0001]` — agent-layer-only enforcement is bypassable.

*Verification: Conformance-test* — the harness exercises each
listed trigger and asserts an AKB query is fired before the
underlying action completes; constructs an agent-layer bypass
attempt and asserts the runtime layer still fires the hook.

#### `[FM-AKB-0011]` Fail-open on AKB unavailability with status

AKB **retrieval** unavailability (substrate down, network partition,
embedding service unreachable) **shall** return empty results with
a `status` field indicating the unavailability cause. Retrieval
unavailability **shall not** error, **shall not** halt the agent,
and **shall not** be silently indistinguishable from a "no relevant
chunks" return.

The status-field requirement is the load-bearing half: empty results
without a status field would be indistinguishable from a successful
retrieval that legitimately found nothing — agents would treat an
outage as "no relevant knowledge exists," producing the precise
failure class AKB is meant to prevent.

The fail-open scope is **retrieval only**. State-affecting AKB
operations (promote, curate, ingest, bootstrap, tier0-build)
**shall** fail strict per `[FM-INV-0002]` — silent state mutation
on substrate failure is non-conforming.

**Infra-decision-side fail-open escalation.** A fail-open
retrieval triggered by an `[FM-AKB-0010]` **infra-decision-side**
hook (domain 2: `git push`, `gh pr create` / `gh pr review`,
deploy commands, substrate config edits — the irreversible-step
hooks) is structurally distinguishable from a fail-open
retrieval triggered by an explicit `akb_query` or a code-author-
side hook (domain 1: edits, commits, plugin invocations). The
infra-decision-side fail-open occurs at the exact moment a
known-dead-end warning or AIR would be most load-bearing, and an
adversary who can induce fail-open (degrading the embedding
service, partitioning the substrate) at that moment silently
suppresses the warning. A `status` field returned to the agent
is necessary but not sufficient against this attack — nothing in
the per-call contract requires the agent to escalate on a
non-empty status.

To close the suppression-oracle path, every fail-open retrieval
triggered by an `[FM-AKB-0010]` domain-2 hook **shall**:

1. Emit a `pcs.policy.divergence` event to ACT per
   `[FM-INV-0005.2]` with `divergence_type = "akb-fail-open-on-
   irreversible-hook"` per `[FM-PGE-0011]` discriminator
   (canonical emitter: AKB, in line with the pattern note's
   "first observes the divergence" rule — AKB observes the
   fail-open synchronously). The event payload **shall** include
   the triggering hook kind, the principal-id, and the
   unavailability cause from the `status` field.
2. Be classified by PGE policy as a **soft gate** on the
   irreversible action — the operator (or an operator-
   configurable agent policy) **shall** acknowledge the fail-open
   before the action proceeds. The default operator policy
   **shall** require explicit acknowledgement; a deployment that
   permits silent proceed under fail-open **shall** be classified
   as operating under a recognized deviation requiring its own
   Appendix F entry per §F.2.

Routine `akb_query` calls and `[FM-AKB-0010]` domain-1 (code-
author-side) hook fail-opens remain governed by the base
fail-open behavior in the prior paragraphs — no escalation, no
divergence event, no soft gate. Scoping the escalation to
domain 2 keeps the cost of fail-open proportional to the
reversibility cost of the action it precedes.

*Verification: Conformance-test* — the harness induces retrieval
substrate unavailability and asserts queries return empty results
with a non-empty status field; induces state-affecting-path
unavailability and asserts the operation fails strict per
`[FM-INV-0002]`; **induces fail-open at an `[FM-AKB-0010]`
domain-2 hook trigger and asserts the divergence event is emitted
to ACT with the correct `divergence_type` AND that the
irreversible action is gated pending acknowledgement under the
default operator policy**.

#### `[FM-AKB-0012]` AIRs as Tier-1 corpus; security AIRs excluded

Agentic Incident Reports (AIRs) **shall** be first-class AKB Tier-1
corpus content with `doc_type = air-report`. AIRs **shall** carry
`violates_invariant = false` regardless of the incident's content
(AIRs are operational lessons to be surfaced at decision points;
marking them `true` would filter them out via the
`[FM-AKB-0004]` pre-filter and defeat the containment loop).

AIRs whose classification is `incident_class = security` or
`audience = restricted` **shall be** categorically excluded from
AKB ingest. The ingest pipeline **shall** drop such AIRs and
**shall** record an audit event documenting the exclusion;
broadcast-by-design substrates are incompatible with need-to-know
audiences. The mesh's restricted-audience store for security
findings is **out of AKB scope and out of this Standard's current
pillar set** — it is provisional on the ratification of a
restricted-audience pillar (e.g., a SEC pillar under
consideration), and **shall** be specified there when ratified.
Until then, the categorical exclusion is the contract; security
findings are not orphaned but are simply not AKB's responsibility
to route.

AIRs **shall** chunk at sub-section granularity (H3-or-deeper
headers within the AIR's findings section), so a query about a
specific finding returns the relevant chunk rather than the full
AIR.

*Verification: Conformance-test* — the harness ingests a
non-security AIR and asserts it lands with the prescribed metadata
and sub-section chunks; ingests a security-class AIR and asserts it
is dropped with the corresponding audit event recorded.

#### `[FM-AKB-0013]` Audit emission via ACT

Every state-affecting AKB operation — `promote`, `demote`,
`role-change`, `ingest`, `bootstrap`, `tier0-snapshot`,
`curate`, `air-ingest`, `air-exclusion` — **shall** emit an event
of corresponding `akb.*` type into ACT via the `[FM-ACT-0009]`
emission-confirmation contract. The operation **shall not** be
considered complete until ACT acknowledges the emission within the
`[FM-INV-0002]` timeout per the `[FM-ACT-0009]` ack sequence; on
lack-of-ack or negative-ack the operation **shall** fail strict.

The `akb.*` event-type namespace **shall** be enumerated in the
ACT event-type taxonomy per `[FM-ACT-0004]`.

Retrieval queries are not state-affecting and **shall not** be
required to emit per-query audit events to ACT; per-query telemetry
flows to the operational OTLP sink per `[FM-AKB-0014]`. Query-log
data used for Bar-A auto-promotion is a separate stream maintained
by AKB itself.

*Verification: Conformance-test* — the harness exercises each
state-affecting operation and asserts the corresponding `akb.*`
event lands in ACT with the per-`[FM-ACT-0009]` ack sequence
respected; induces ACT unavailability and asserts the operation
fails strict.

#### `[FM-AKB-0014]` AKB telemetry emission

AKB **shall** emit OTLP-format traces, metrics, and logs for its
own operational observability. Span names **shall** follow the
`mesh.akb.*` namespace (e.g., `mesh.akb.query`,
`mesh.akb.tier0_snapshot`, `mesh.akb.bootstrap`,
`mesh.akb.promote`, `mesh.akb.curate`, `mesh.akb.hook_query`).
Required attributes follow the mesh-wide telemetry contract.

The telemetry stream — covering query latency, queries-total,
chunks-total, cross-role-document count against the
`[FM-AKB-0007]` cap, Tier-0 bytes against the `[FM-AKB-0002]`
cap, promotion-queue depth, injection-bytes-per-session, and
zero-query-chunks — is distinct from the audit-event emission per
`[FM-AKB-0013]`. The two flow to different sinks: this
requirement targets the operational OTLP sink; the audit events
flow to ACT.

*Verification: Conformance-test* — the harness invokes
representative AKB operations and asserts emission of spans /
metrics / logs to the operational OTLP sink with the
`mesh.akb.*` namespace and required attributes.

### §5.5.1 AKB Conformance Profile

The AKB pillar's substrate substitutability claim covers exactly
the rows in this Conformance Profile. Conformance is verified by
passing the AKB multi-profile conformance suite against the listed
implementations.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Chunk + embedding store | `[FM-AKB-0004]`, `[FM-AKB-0005]`, `[FM-AKB-0006]`, `[FM-AKB-0007]` | PostgreSQL 15+ with pgvector 0.5+ (HNSW, cosine distance) | Qdrant 1.7+ (vector-primary escalation, ~50–100M+ vectors), Milvus 2.x (billion-vector scale only) | `akb-chunk-store-v1` |
| Embedding service | `[FM-AKB-0004]` (vector layer) | BAAI/bge-large-en-v1.5 (1024-dim, local GPU) | voyage-3-large, text-embedding-3-large, nomic-embed-text-v1.5 | `akb-embedding-v1` |
| Corpus source | `[FM-AKB-0009]` (corpus walk), `[FM-AKB-0012]` (AIR ingest) | Git-tracked markdown across the lab's org-folder repos (GitHub multi-org) | GitLab, self-hosted Gitea, mirrored git on local NAS | `akb-corpus-source-v1` |
| Tier-0 snapshot store | `[FM-AKB-0002]`, `[FM-AKB-0003]` | Local POSIX filesystem with `os.replace`-atomic publish + content-hash chain | S3-compatible object store with versioning (MinIO, AWS S3, Azure Blob, OCI Object Storage) | `akb-tier0-snapshot-v1` |
| Curation event store | `[FM-AKB-0008]`, `[FM-AKB-0013]` | PostgreSQL `akb.curation_events` (same substrate as chunks) | Any append-only event substrate honoring the contract (ACT-conformant store, NATS JetStream, Kafka compacted topics) | `akb-curation-events-v1` |
| Telemetry sink | `[FM-AKB-0014]` | OTLP-on-the-wire (any OTLP-compatible backend) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `akb-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported. Extending
the profile requires the argued-case discipline per `[FM-INV-0003.2]`
and a multi-profile conformance run proving the new substrate passes
the AKB test suite.

### §5.6 DPG — Deterministic Proving Ground

**Scope.** DPG is the mesh's ephemeral-isolation boundary: the
single-use, attested compute environment in which agent-emitted
code is compiled, tested, validated, and either returned through
the attested channel or destroyed with the boundary. DPG closes the
gap between stochastic reasoning and deterministic execution —
agents may reason probabilistically, but the code they emit
**shall** be validated under deterministic conditions inside DPG
before it touches production state. The pillar exists because the
two industry alternatives — vendor-mediated safety filters (not
auditable from outside the vendor) and cloud-hosted sandboxes
(sovereignty loss) — both fail the mesh's invariants.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply — code intended to affect production state **shall** pass through DPG; a path that reaches production while bypassing DPG is non-conforming.
- DPG accepts execution requests as `action`-priority PCTs per `[FM-IBX-0007]` worker-pool dispatch semantics; result PCTs are returned to the original requester via the standard IBX path.
- DPG runners hold IAM-issued identities per `[FM-IAM-0006]` (Vault in-boundary signing) and `[FM-IAM-0011]` (identity-context contract); the runner's principal-id is what executions run AS at the substrate level.
- DPG executes PGE policy as the second guardrail per `[FM-PGE-0005]` Gate-2 — DPG operational under `[FM-DPG-0005]` is the sunset condition for the `[FM-PGE-0005]` Gate-2 transitional deviation.
- DPG state-affecting operations (every execution lifecycle) emit `dpg.*` events to ACT per the `[FM-ACT-0009]` ack contract and the `[FM-ACT-0004]` taxonomy.
- DPG and CRB own orthogonal concerns (*how to isolate* vs *where to run*); the seam composes at decision time and **shall not** be subsumed by either pillar.

#### `[FM-DPG-0001]` Three architecturally distinct components

DPG **shall** be implemented as three architecturally distinct
components:

1. **Runner** — the service that accepts execution requests,
   provisions the ephemeral boundary, runs the requested code,
   applies validation gates, and returns the structured execution
   record. Substrate-coupled (implementation tracks substrate); the
   runner's behavior contract (accept → provision → run → validate
   → return) is substrate-agnostic.
2. **Boundary** — the single-use isolation primitive in which the
   execution runs. Substrate-specific internals; the contract per
   `[FM-DPG-0002]` holds across all conforming substrates.
3. **Validation Gates** — the pass/fail checks applied to the
   execution's outputs before return through the attested channel.
   Substrate-agnostic; consume only the execution's outputs.

The separation lets substrate choice evolve at the deployment layer
without altering the runner's behavior contract or the gates'
interface. A monolithic implementation that fuses any two of these
into a single component does not conform.

*Verification: Inspection* — the implementation's component
boundaries are reviewed against the runner / boundary / gates
separation; the gates **shall** be exercised independently of the
substrate (a gate's test suite is runnable against a stub
execution result).

#### `[FM-DPG-0002]` Five ephemeral-isolation properties (non-negotiable)

Every DPG ephemeral boundary **shall** satisfy all five of the
following properties. A substrate that fails any property is not
DPG-conformant and **shall not** be claimed supported.

1. **Single-use creation and destruction.** The boundary is
   created for one execution, used, and destroyed. No state
   persists across executions in the substrate; two consecutive
   executions in the same runner see fresh boundaries. **Device
   memory on any accelerator the execution touched** (e.g., GPU
   VRAM exposed to the execution per `[FM-DPG-0010]` CUDA-class
   workloads on `gpu_bound` / `mps_bound` hosts per
   `[FM-CRB-0009]`) **shall** be explicitly scrubbed at boundary
   teardown — uncleared accelerator memory is gross state
   persistence, not a micro-arch side channel, and is therefore
   in scope at the contract layer. For cross-trust-tier workloads
   sharing a physical accelerator across executions of different
   tenants or trust levels, a Tier-0 substrate (separate-kernel
   per execution, e.g., GPU-passthrough microVM) **shall** be
   selected per `[FM-CRB-0009]`'s isolation-tier-as-eligibility-
   input contract; the accelerator-memory scrub requirement does
   not by itself satisfy cross-tenant isolation guarantees that
   require kernel-level separation.
2. **Filesystem isolation.** The boundary has its own filesystem
   view. Reads from outside the boundary are permitted only via
   explicit input declarations in the execution request; writes
   from inside cannot reach outside except via the attested return
   channel. Isolation is substrate-enforced — not dependent on
   the executing code's good behavior.
3. **Network isolation — default-deny.** The boundary has no
   network access by default. Network egress requires explicit
   per-execution declaration (hostnames + ports); declared egress
   is routed through a substrate-provisioned proxy. Inbound
   network **shall not** be permitted — no listening sockets
   reachable from outside the boundary.
4. **Resource limits.** Every execution runs under explicit CPU,
   memory, wall-clock-time, and disk-write limits declared in the
   request. Exceeding any limit terminates the execution with a
   `resource_limit_exceeded` outcome. Limits **shall** be
   substrate-enforced (cgroups, VM resource configuration, or
   equivalent).
5. **Process and identity isolation.** The execution runs as a
   dedicated execution user with no host privilege beyond what
   the boundary substrate provisions. The execution **shall not**
   be able to escalate to the host's user identity; even
   root-level operations inside the boundary **shall not** affect
   anything outside it.

What the boundary does **not** guarantee at this Standard:
side-channel-attack resistance (timing / cache / Spectre-class)
is out of scope at the contract layer — deployments handling
sensitive data **shall** select a Tier-0 substrate per the
Conformance Profile.

*Verification: Conformance-test* — the harness runs the adversarial
containment battery (fork-bomb containment, unauthorized-egress
containment, out-of-boundary-write containment, privilege-escalation
containment, persistent-state containment, **accelerator-memory
residue containment**) against every conformance-claimed substrate;
asserts every attempt is contained. The accelerator-memory residue
test runs an execution that writes a marker pattern to GPU VRAM,
tears down the boundary, runs a second execution on the same
physical accelerator, and asserts the marker pattern is not
readable in the second execution's address space.

#### `[FM-DPG-0003]` Single attested return channel

DPG executions **shall** return outputs through exactly one
canonical, attested channel: the structured execution record
returned to the requester per the result PCT shape. Side channels
(network egress to non-declared targets, filesystem writes outside
the boundary, IPC to host processes outside the runner) **shall
not** be provisioned by the substrate and **shall not** be
permitted by the runner.

The execution record **shall** carry a `boundary_audit_summary`
capturing what the substrate observed: process tree, network
egress attempted vs. allowed, filesystem reads outside declared
inputs, resource-limit-exceeded events. The summary is part of the
attestation surface — it is what makes "what did this code
actually do" answerable from the audit trail.

*Verification: Conformance-test* — the harness submits executions
that attempt side-channel exfiltration (network egress to
undeclared target, filesystem write to host path); asserts each
attempt is contained by the substrate AND recorded in the
`boundary_audit_summary` of the returned execution record.

#### `[FM-DPG-0004]` Four mandatory validation gates

Every DPG execution **shall** be subject to four mandatory
validation gates before its result is permitted to return through
the attested channel. The four gates are non-negotiable per
execution; per-request `validation_specification` entries **may**
add gates but **shall not** remove or weaken any of the four:

1. **Syntax conformance** — the execution's source and any
   declared output artifacts are validated against the relevant
   PCS-governed Syntax per the requested `workload_type`.
2. **PGE compliance** (Gate-2 enforcement point) — the PGE rule
   corpus is evaluated against the execution per `[FM-DPG-0005]`.
3. **Test-suite execution** — the request's declared test suite
   runs inside the boundary; per-test pass/fail is recorded.
4. **Resource-limit attestation** — actual CPU / memory /
   wall-clock-time / disk consumed are recorded against the
   declared limits.

An execution **passes** only when all four mandatory gates plus
any request-declared additional gates report success. Any gate
failure marks the execution `validation_failed` and **shall**
prevent the result from advancing to downstream consumers
(PCS-Daemon promotion, production-state writes, Registry
deployment).

*Verification: Conformance-test* — the harness submits sample
executions that fail each of the four gates in turn; asserts the
execution is marked `validation_failed` with the failing gate
recorded; asserts the result does not advance to any downstream
consumer.

#### `[FM-DPG-0005]` PGE double-guardrail — Gate-2 enforcement

DPG **shall** execute the PGE rule corpus per `[FM-PGE-0005]`
inside the ephemeral boundary as the second guardrail in the
mesh's double-guardrail enforcement model. The rule corpus
evaluated inside DPG **shall** be the same corpus PGE applies at
the IBX submission chokepoint (Gate 1) — PGE owns the rules; DPG
is the substrate; the runner is the policy executor for inside-
boundary evaluation.

A DPG implementation operational against this requirement
**discharges** the `[FM-PGE-0005]` Gate-2 transitional deviation —
i.e., declaration of `[FM-DPG-0005]` operational state is the
sunset condition for the `[FM-PGE-0005]` Gate-2 deviation
registered in Appendix F. Until `[FM-DPG-0005]` is operational,
the `[FM-PGE-0005]` Gate-2 deviation remains in force per its
transitional clause; deployments are conformant to the deviation
clause only.

PGE rules evaluated inside DPG **shall** catch the failure class
intent-side enforcement structurally misses: code that *looks*
compliant at submission but *behaves* non-compliant when
executed (e.g., a test that triggers a subprocess-injection only
at runtime).

*Verification: Conformance-test* — the harness submits executions
whose code passes Gate-1 (IBX intent gate) but violates a PGE rule
at runtime; asserts DPG evaluates the rule inside the boundary and
marks the execution `validation_failed`; cross-references the
`[FM-PGE-0005]` post-DPG conformance suite (both pillars'
conformance is exercised by the same test set).

#### `[FM-DPG-0006]` DPG runner identity

DPG runners **shall** hold their own IAM-issued principal-id
(job code: `dpg-runner` or equivalent) per `[FM-IAM-0006]`
in-boundary signing. Runners **shall not** use the operator's
credentials, the requester's credentials, or any shared
service-account credential.

The execution inside the boundary **shall** run AS the runner's
identity at the substrate level (the boundary user account is
derived from the runner's principal-id). Even malicious execution
code cannot escape to the operator's identity because the runner
never held it.

Authorization to invoke DPG **shall** be checked against the
requester's principal-id at the chokepoint per `[FM-IAM-0011]`
identity-context contract — the runner inspects the originating
PCT's principal-id and confirms the requester is authorized to
execute the requested workload class. Per `[FM-IAM-0011]`,
"not authorized" is terminal: the runner emits
`execution_request_rejected` and halts; it **shall not** reason
about routing around access controls.

*Verification: Conformance-test* — the harness verifies the
runner's principal-id is distinct from the requester's and from
the operator's; submits an execution from an unauthorized
principal-id and asserts `execution_request_rejected` is emitted;
verifies the boundary user account at the substrate maps to the
runner's principal-id.

#### `[FM-DPG-0007]` Worker-pool dispatch

DPG runners **shall** participate in the IBX worker-pool dispatch
contract per `[FM-IBX-0007]` for parallel execution. Pool claim
**shall** be exactly-once via the SKIP-LOCKED-style atomic claim
substrate per `[FM-IBX-0009]`; lease / visibility-timeout for
crash recovery applies; idempotency keys per the IBX worker-pool
contract permit safe re-execution.

Per-runner-identity concurrency caps **may** be applied at the
IAM layer; the DPG runner **shall not** exceed its IAM-declared
session concurrency cap.

Mid-action-safe termination per the worker-pool contract: a
runner session terminated while holding an in-flight claim
**shall** return the claim to the queue per the IBX
mid-action-safe termination semantics; in-flight executions emit
all events through termination per `[FM-ACT-0009]` ack contract
before claim release.

*Verification: Conformance-test* — the harness exercises
worker-pool dispatch against multiple concurrent runners and
asserts exactly-once claim; terminates a runner mid-execution and
asserts the claim returns to the queue with audit events
preserved.

#### `[FM-DPG-0008]` Substrate substitutability via Exit Test

DPG's substrate substitutability **shall** be defined as passing
the multi-profile conformance run against the Conformance Profile
seams per §5.6.1. The contract — the five ephemeral-isolation
properties per `[FM-DPG-0002]` — **shall** hold across substrate
change.

Isolation runtimes **shall** be tier-graded; deployments handling
sensitive data **shall** select a substrate appropriate to the
data tier (Tier-0 substrates provide separate-kernel-per-execution
isolation; Tier-2 substrates provide OS-level isolation suitable
for low-sensitivity validation only).

Out-of-set isolation runtimes **shall not** be claimed supported
— an unvetted isolation runtime is a security boundary, not a
convenience substrate. Extending the profile requires the
argued-case discipline per `[FM-INV-0003.2]` AND a conformance-
suite extension running the adversarial containment battery against
the new runtime before merging.

*Verification: Conformance-test* — the multi-profile harness runs
the same adversarial containment battery and the same sample
execution workload across every conformance-claimed substrate;
asserts identical containment outcomes and semantically identical
execution results (modulo declared determinism level per
`[FM-DPG-0010]`).

#### `[FM-DPG-0009]` Registry-bound executable validation

All Registry-bound executable artifacts (PCS-governed plugins, MCP
servers, skills, runbooks, workflows, hooks, agents — anything the
mesh runs) **shall** pass DPG validation as part of their
pre-promotion lifecycle. PCS-Daemon's pre-promotion state
**shall** invoke DPG for executable validation; the Daemon's
state transition reflects the DPG outcome.

The Daemon **shall not** bypass DPG for executable workloads.
Every plugin or MCP server that includes runtime tests **shall**
pass through DPG validation. The Registry contains only artifacts
that have been DPG-validated against the security framework and
the four mandatory validation gates.

This requirement is the dev-to-production trust boundary applied
to executable artifacts.

*Verification: Conformance-test* — the harness exercises a plugin
promotion through PCS-Daemon and asserts DPG is invoked during the
pre-promotion state; asserts a `validation_failed` DPG outcome
prevents promotion advancement; asserts a bypass-attempt (a
direct Registry write skipping DPG) is rejected by the Registry
contract.

#### `[FM-DPG-0010]` Deterministic execution with declared determinism level

DPG executions **shall** be deterministic where possible: same
inputs + same execution command + same validation specification
**shall** produce the same result, modulo externally-sourced
nondeterminism the substrate cannot replay (wall-clock time,
RNG, external network responses).

Where external nondeterminism is required, the execution request
**may** declare a deterministic seed; the runner **shall** provide
the seed to the execution environment.

CUDA workloads **may** carry numerical drift from
nondeterministic reduction orderings. The execution record
**shall** declare the determinism level achieved per a bounded
enumeration: `deterministic`, `numerical-drift-only`,
`nondeterministic`. Downstream consumers (PCS-Daemon promotion,
ACT, test-result interpretation) **shall** read the declared
level rather than assuming `deterministic`.

*Verification: Conformance-test* — the harness runs the same
sample execution twice under identical inputs and asserts
identical outputs for `deterministic`-declared workloads; runs a
CUDA workload twice and asserts the execution record's declared
determinism level matches the observed reduction-order behavior.

#### `[FM-DPG-0011]` Reconciliation sweep for lost completions

DPG **shall** run an idempotent reconciliation sweep that
detects executions whose `dpg.execution_complete` event emission
was lost (e.g., runner crashed after boundary destruction but
before the completion event reached ACT). The sweep **shall**:

1. **Find** executions in `running` state older than a bounded
   window (default: max execution time + grace period; operator-
   configurable per deployment SLO) with no `dpg.execution_complete`
   event in ACT AND no live boundary in the substrate.
2. **Confirm** substrate state by re-checking the boundary is
   actually gone before emitting any recovery event.
3. **Emit** a terminal `dpg.execution_complete` event with outcome
   `lost_completion_recovered` and a structured note indicating
   reconciliation as the emission source rather than normal
   completion. The recovery event **shall** itself emit via the
   `[FM-ACT-0009]` ack contract.
4. **Be safe to re-run** — idempotency keys on the recovery
   event **shall** prevent double-emission; a re-run that sees an
   existing recovery event is a no-op.

The reconciliation sweep recovers the *fact* of a lost completion
— the synthetic `lost_completion_recovered` event records that the
execution's completion path did not reach ACT normally. The sweep
does **not** recover the *content* of in-boundary telemetry that
died before flushing to ACT; that gap (the boundary-local-to-
ACT-ingest interval for in-execution telemetry) is acknowledged
and **shall** be addressed by a future requirement when its
design is settled. The fact-of-loss recovery is the audit floor.

*Verification: Conformance-test* — the harness simulates a runner
crash after boundary destruction and before completion-event
emission; runs the reconciliation sweep and asserts emission of
the recovery event with `lost_completion_recovered` outcome; runs
the sweep a second time and asserts no duplicate event.

#### `[FM-DPG-0012]` Audit emission via ACT

DPG **shall** emit the following `dpg.*` events to ACT via the
`[FM-ACT-0009]` ack contract, drawn from the `[FM-ACT-0004]`
event-type taxonomy:

- `dpg.code_emitted` — emitted by the upstream code-emitting
  agent (not DPG itself), recording that an agent submitted code
  to DPG. Provides Workforce-side attribution.
- `dpg.execution_complete` — emitted by the DPG runner on
  execution finish (success or any failure outcome). Payload
  includes `execution_id`, `outcome`, validation results summary,
  `resource_usage`, `boundary_audit_summary`.
- `dpg.execution_request_rejected` — emitted by the DPG runner
  when an execution request is refused at submission (e.g.,
  unauthorized principal-id, malformed request).
- `dpg.lost_completion_recovered` — emitted by the
  reconciliation sweep per `[FM-DPG-0011]`.

Per `[FM-ACT-0009]`, an execution **shall not** be considered
complete until ACT acknowledges the corresponding
`dpg.execution_complete` (or recovery) event; lack-of-ack or
negative-ack **shall** cause the operation to fail strict.

Every execution **shall** have exactly one terminal completion
event in ACT (either a normal `dpg.execution_complete` or a
`dpg.lost_completion_recovered`); an execution with neither is a
no-bypass violation per `[FM-INV-0001]`.

*Verification: Conformance-test* — the harness verifies each
event type is emitted on the corresponding event class; asserts
the ACT ack contract is honored; asserts every execution has
exactly one terminal completion event.

#### `[FM-DPG-0013]` Subagent-worktree precursor (transitional clause)

The mesh's current subagent-worktree pattern (`isolation:
"worktree"` per the operator's subagent-policy convention)
provides OS-level git-isolation for agent-spawned subagents
performing write-enabled work. The pattern is the operational
precedent for `[FM-DPG-0002]` properties 1 and 2 (single-use
creation/destruction + filesystem isolation) but does **not**
satisfy the full ephemeral-isolation contract or the four
mandatory validation gates per `[FM-DPG-0004]`.

**Transitional deviation — sunset on `[FM-DPG-0002]` operational
availability.** A deployment **may** continue to use the
subagent-worktree pattern for low-sensitivity research /
read-mostly workflows during the transition period, but **shall
not** be claimed conformant to `[FM-DPG-0002]` or
`[FM-DPG-0004]` on the basis of subagent-worktree usage. The
deviation **shall**:

1. Be registered in Appendix F with explicit sunset condition:
   "Generalized DPG operational per `[FM-DPG-0002]` and
   `[FM-DPG-0004]` across the deployment's executable-emission
   surface."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "subagent-worktree-precursor"` per
   `[FM-PGE-0011]` discriminator (canonical emitter: PGE, via
   the policy that classifies subagent-worktree usage as
   non-DPG-conformant execution) for every workload using the
   precursor pattern.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when generalized DPG is declared
   operational.

A deployment operating under the subagent-worktree precursor
deviation **shall not** be claimed conformant to `[FM-DPG-0002]`
on the basis of the precursor; it is conformant to the deviation
clause only.

*Verification (operational): Conformance-test* — the
adversarial containment battery per `[FM-DPG-0002]` Conformance-
test is satisfied by the generalized DPG implementation.
*Verification (deviation period): Inspection of deviation
registry* — deviation entry present in Appendix F with sunset
condition; divergence events emitted per item 2 above.

#### `[FM-DPG-0014]` DPG telemetry emission

DPG **shall** emit OTLP-format traces, metrics, and logs for its
own operational observability. Span names **shall** follow the
`mesh.dpg.*` namespace (e.g., `mesh.dpg.sandbox.create`,
`mesh.dpg.sandbox.execute`, `mesh.dpg.gate.evaluate`,
`mesh.dpg.sandbox.terminate`, `mesh.dpg.return.attest`,
`mesh.dpg.reconciliation.sweep`).

The required metric set **shall** include at minimum:
`executions_total` (counter, labeled by outcome),
`sandbox.lifecycle_ms` (histogram),
`gate.rejection_rate` (counter, labeled by gate),
`resource.limit_exceeded_total` (counter),
`escape.attempt_total` (counter — the load-bearing security
signal), `sandbox.in_flight` (gauge),
`reconciliation.swept_total` (counter).

The operational telemetry stream (`mesh.dpg.*`) is distinct from
the audit-event stream (`dpg.*` per `[FM-DPG-0012]`). The two
flow to different sinks: operational OTLP for `mesh.dpg.*`; ACT
event store for `dpg.*` audit.

*Verification: Conformance-test* — the harness invokes
representative DPG operations and asserts emission of the
required span / metric / log records to the operational OTLP
sink with the `mesh.dpg.*` namespace.

### §5.6.1 DPG Conformance Profile

The DPG pillar's substrate substitutability claim covers exactly
the rows in this Conformance Profile. The **isolation-runtime
seam's conformance is load-bearing**: the same adversarial
containment battery (fork-bomb, unauthorized-egress,
out-of-boundary-write, privilege-escalation, persistent-state)
**shall** produce identical containment outcomes across every
tested isolation runtime. A seam change that fails any tested
profile does not merge.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Isolation runtime | `[FM-DPG-0002]`, `[FM-DPG-0003]`, `[FM-DPG-0008]` | Podman 5+ rootless (Tier-1, fleet container runtime) | git worktrees + cgroups (Tier-2, lightweight floor + operational precedent), systemd-nspawn (Tier-1), gVisor (Tier-1, syscall interception), Firecracker microVM (Tier-0, separate kernel per execution), Kata Containers (Tier-0) | `dpg-isolation-runtime-v1` |
| Base image (for container / microVM runtimes) | `[FM-DPG-0002]` (substrate floor) | UBI9-minimal | Wolfi, distroless, scratch-equivalent. N/A for the worktree substrate | `dpg-base-image-v1` |
| Network egress control | `[FM-DPG-0002]` property 3, `[FM-DPG-0003]` | nftables-based egress proxy with default-deny + per-execution allowlist | Cilium, Calico, Envoy proxy — any substrate enforcing declarative per-execution egress allowlists | `dpg-network-egress-v1` |
| Telemetry sink | `[FM-DPG-0014]` | OTLP-on-the-wire (any OTLP-compatible backend) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `dpg-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported.
Extending the profile requires the argued-case discipline per
`[FM-INV-0003.2]` AND a conformance-suite extension running the
full adversarial containment battery against the new substrate
before merging. The discipline matters most on the isolation-
runtime seam: an unvetted runtime is a security boundary.

### §5.7 CRB — Compute Resource Broker

**Scope.** CRB is the mesh's hardware-aware workload-dispatch
pillar: every workload that requires specific compute resources
(GPU, large unified memory, low-latency substrate access) is
routed to a host capable of satisfying them. CRB owns *where to
run*; DPG owns *how to isolate*. The pillar exists because most
mesh work is **not** GPU-bound — agent reasoning, document
workflows, audit, and DB analytics dominate the workload mix — so
the bottleneck is *visibility into which workloads can run in
parallel on existing compute*, not "not enough compute." CRB
turns that visibility into a fleet-callable dispatch contract.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply — dispatch decisions **shall not** be circumvented and **shall** fail strict on substrate unavailability.
- CRB accepts dispatch requests as `action`-priority PCTs per the IBX message-shape contract; result PCTs return to the original requester via the standard IBX path. CRB is the **Reasoner archetype**, not the Worker archetype, and therefore **shall not** consume the IBX worker-pool claim queue.
- CRB broker daemons, when built, hold IAM-issued principal-ids per `[FM-IAM-0006]` and `[FM-IAM-0011]`. The broker's identity is the authorizing principal for dispatch decisions; the broker **shall not** use operator or requester credentials.
- CRB emits state-affecting events as `crb.*` records to ACT via the `[FM-ACT-0009]` ack contract and the `[FM-ACT-0004]` taxonomy.
- CRB and DPG own orthogonal concerns (*where to run* vs *how to isolate*) but couple at decision time: a DPG-side isolation-tier constraint **shall** feed CRB's eligibility filter as an input dimension when a workload requires both pillars. Neither pillar **shall** subsume the other.
- PGE applies content-level and resource-routing policy at the CRB dispatch chokepoint per `[FM-PGE-0005]` and `[FM-PGE-0007]`; CRB **shall not** carry its own policy corpus.

#### `[FM-CRB-0001]` Three architecturally distinct components

CRB **shall** be implemented as three architecturally distinct
components:

1. **Workload Classification Taxonomy** — the bounded enum of
   workload classes per `[FM-CRB-0002]`. Workload-side semantic;
   meaningful in itself before any dispatch.
2. **Dispatch Policy** — the mapping from classification to
   eligible target hosts per `[FM-CRB-0003]`. Fleet-side; per-
   deployment.
3. **Broker Daemon** — the service that applies classification +
   policy to select a target and tracks the dispatch outcome. The
   policy executor.

Classification evolves independently of any specific fleet's
policy; the policy adapts to new hardware without changing the
taxonomy; the broker implementation swaps under the Exit Test per
`[FM-CRB-0008]` without affecting either upstream concern. A
monolithic implementation that fuses any two of these into a
single component does not conform.

*Verification: Inspection* — the implementation's component
boundaries are reviewed against the classification / policy /
daemon separation; classification is exercised independently of
policy (a workload's class is a value, not a function of the
fleet's hosts).

#### `[FM-CRB-0002]` Workload classification taxonomy (bounded)

The mesh-level workload classification taxonomy **shall** be a
bounded enumeration. The Standard commits at minimum the
following five classes; extension **shall** require an explicit
curation event (same discipline as the `[FM-ACT-0004]` event-type
taxonomy):

- **`gpu_bound`** — workload requires GPU compute on a CUDA-class
  or equivalent accelerator runtime per the Conformance Profile.
- **`mps_bound`** — workload requires Apple MPS specifically (a
  sub-class of accelerator-bound where the accelerator family is
  Apple, not CUDA-class). Explicitly separated because the
  `gpu_bound` runtime is not interchangeable with the MPS runtime
  at the framework layer.
- **`db_bound`** — workload requires direct database substrate
  access with low-latency network path to the substrate.
- **`reasoning_bound`** — workload is primarily agent reasoning
  with minimal infrastructure dependency beyond a conforming
  language runtime.
- **`mixed`** — workload combines multiple classes; the
  eligibility filter applies the **strictest constraint** among
  the sub-class requirements.

Every dispatch request **shall** declare its class. A dispatch
request with an unknown class **shall** be rejected with
`crb.dispatch_request_rejected` per `[FM-CRB-0012]`. Workload
misclassification by the submitter is a content-level concern CRB
cannot prevent structurally; broker behavior on subsequent
re-dispatch is policy-side.

*Verification: Conformance-test* — the harness submits dispatch
requests of each enumerated class and asserts acceptance; submits
an unknown class and asserts rejection with the corresponding
audit event; attempts taxonomy extension without a curation event
and asserts rejection.

#### `[FM-CRB-0003]` Dispatch policy contract

The dispatch policy **shall** be a pure function:
`dispatch_policy(workload_class, workload_constraints) →
eligible_host_list`. The contract:

1. **Pure** — same class + same constraints **shall** produce
   the same eligible-host list; no hidden state.
2. **Bounded eligibility** — the eligibility check **shall** be
   decidable in bounded time. Recursive policy resolution and
   policy chains **shall not** be permitted.
3. **Substrate-aware** — the policy **may** consult substrate
   primitives (hardware inventory, network topology) but **shall
   not** depend on broker-daemon implementation details.
4. **Tiered fallback** — if no host satisfies the constraints,
   the policy **shall** emit a `crb.policy_no_match` event per
   `[FM-CRB-0012]` and the workload **shall** remain in queue
   until a host is added or constraints relax. Silent fallback to
   a non-matching host **shall not** be permitted.
5. **Capacity-aware** — eligibility evaluation **shall** include
   actual available capacity on the candidate host, not just type
   match. A host whose accelerator is already allocated **shall
   not** be returned as eligible.

The mapping of classes to eligible hosts is **deployment-
architecture**, not pillar contract; different fleets have
different policies because they have different inventories. What
the Standard binds is the function shape and the fallback
discipline.

*Verification: Conformance-test* — the harness exercises the
policy function with repeated identical inputs and asserts
identical outputs (purity); submits a workload with no eligible
host and asserts `crb.policy_no_match` emission; verifies no
dispatch to a non-matching host occurs; submits a workload to a
typed-eligible-but-capacity-exhausted host and asserts the policy
returns no match.

#### `[FM-CRB-0004]` Hardware topology model

CRB **shall** model the deployment's fleet as a typed inventory.
Each host record **shall** carry at minimum: `host_id`,
`host_class` (a bounded enum of `control`, `sage`, `forge`,
`judge`, `worker`), `os` + version, `cpu`, `memory_bytes`,
`accelerators` (list of `{type, model, memory_bytes, count}`
records where `type` is drawn from the accelerator-runtime
seam of the Conformance Profile), `network_interfaces` with
topology context, `storage_classes` accessible from the host,
`available_runtimes`, and per-host language-runtime paths.

Inventory updates as hardware is added or removed; the schema
does not. Inventory **shall** be a versioned, operator-reviewed
artifact — the broker **shall** read from the latest committed
inventory and **shall not** synthesize host records at runtime
without an inventory entry.

*Verification: Static-check + Conformance-test* — Static-check
verifies the inventory schema; Conformance-test exercises a
dispatch against an inventory missing a host the convention
expects and asserts `crb.policy_no_match` rather than synthesis.

#### `[FM-CRB-0005]` CRB broker identity

The CRB broker daemon **shall** hold its own IAM-issued
principal-id (job code: `crb-broker` or equivalent) per
`[FM-IAM-0006]`. Brokers **shall not** use the operator's
credentials, the requester's credentials, or any shared
service-account credential.

The broker's identity is what dispatch decisions are recorded as
at the audit layer. When the broker emits dispatch instructions
to remote hosts (e.g., via the substrate's job-submission
primitive), the broker's identity is the authorizing principal —
never the operator's.

Authorization to invoke CRB **shall** be checked against the
requester's principal-id at the chokepoint per `[FM-IAM-0011]`
identity-context contract. The broker's own authentication at
dispatch is governed by `[FM-INV-0001]` (every actor
authenticates, every time) — the broker holds and presents its
own principal-id on every dispatch decision; no implicit-trust
shortcut applies. Workloads requiring scarce or high-tier
resources **may** carry tighter job-code authorization
requirements than routine `reasoning_bound` workloads. Per
`[FM-IAM-0011]`, "not authorized" is terminal — the broker emits
`crb.dispatch_request_rejected` and halts.

*Verification: Conformance-test* — the harness verifies the
broker's principal-id is distinct from the requester's and the
operator's; submits a dispatch request from an unauthorized
principal-id and asserts `crb.dispatch_request_rejected`;
verifies dispatch-decision audit records carry the broker's
identity, not the requester's.

#### `[FM-CRB-0006]` Reasoner archetype — no worker-pool claim seam

CRB **shall** be deployed as the Reasoner archetype: one or a
small handful of broker sessions per deployment with broad
authority over the dispatch surface. CRB **shall not** consume
the IBX worker-pool claim-queue per `[FM-IBX-0007]` /
`[FM-IBX-0009]`; dispatch requests reach the broker via direct
addressing (`recipient=crb-broker`) under standard IBX
semantics, not via competitive worker-pool claim.

Per-broker-identity concurrency caps **may** be applied at the
IAM layer; brokers **shall not** exceed their IAM-declared
session concurrency cap.

Deployments requiring broker high-availability **may** run
leader-elected active/standby brokers; the leader holds the
broker principal-id for dispatch authority. Active/active broker
pools **shall not** be operated without explicit cross-broker
coordination — uncoordinated parallel brokers would re-introduce
the claim-queue contention that the Reasoner archetype
classification rejects.

*Verification: Inspection + Conformance-test* — Inspection
verifies the broker addressing pattern (direct, not worker-pool);
Conformance-test asserts that submitting a dispatch request to
the worker-pool claim queue is not the conformant path; verifies
broker sessions are bounded by the IAM concurrency cap.

#### `[FM-CRB-0007]` Clean seam — no isolation, no validation, no content policy

CRB **shall not** provision isolation boundaries, validate
workload outputs, or enforce content-level policy. Specifically:

- **Isolation** is DPG's concern per `[FM-DPG-0002]`. CRB
  dispatches to a host; the workload runs on that host in
  whatever environment DPG (if invoked) or the host itself
  provides. CRB **shall not** add an isolation surface.
- **Output validation** is DPG's concern per `[FM-DPG-0004]`
  (four mandatory gates) or PGE's concern per `[FM-PGE-0005]`
  (Gate-2 enforcement). CRB records dispatch outcomes; it
  **shall not** validate them.
- **Content-level policy** is PGE's concern per `[FM-PGE-0005]`.
  CRB applies *resource-routing* policy at dispatch time; PGE
  applies *content* policy at intent and execution. The two are
  distinct.

A future CRB implementation that adds isolation, validation, or
content-policy surfaces is non-conforming.

*Verification: Inspection* — code review on any CRB
implementation rejects additions to the isolation, validation, or
content-policy surface; the boundary is structural, not advisory.

#### `[FM-CRB-0008]` Substrate substitutability via Exit Test

CRB's substrate substitutability **shall** be defined as passing
the multi-profile conformance run against the Conformance Profile
seams per §5.7.1. The contract — classification taxonomy + policy
function shape per `[FM-CRB-0003]` + inventory schema per
`[FM-CRB-0004]` — **shall** hold across substrate change.

The accelerator-runtime seam's substitutability is load-bearing:
the taxonomy's `gpu_bound` is the **accelerator-compute
capability**, not a CUDA lock-in. A conforming `gpu_bound`
workload **shall** be satisfiable by any conforming accelerator
runtime on an eligible host (CUDA, ROCm, Vulkan compute, oneAPI,
Apple MPS for the `mps_bound` sub-class). Out-of-set runtimes
**shall not** be claimed supported; extension requires the
argued-case discipline per `[FM-INV-0003.2]` and a conformance-
suite extension.

The broker implementation **shall not** prematurely adopt
distributed-scheduler machinery (Nomad / Slurm / Kubernetes)
without substrate-substitutability validation against the test
set.

*Verification: Conformance-test* — the multi-profile harness
runs the same dispatch battery (classification → expected
eligible-host set, `policy_no_match` on no capacity) across every
conformance-claimed scheduling backend; a `gpu_bound` workload
**shall** dispatch and account correctly across ≥ 2 accelerator
families on hosts that carry them.

#### `[FM-CRB-0009]` DPG seam — isolation-tier as eligibility input

When a workload requires both CRB and DPG, the DPG-side
isolation-tier requirement **shall** feed CRB's eligibility
filter as an input dimension. The dependency direction is
DPG-isolation-requirement → CRB-eligibility-input — CRB never
provisions isolation; DPG never routes by host class.

Concretely: an execution requesting a Tier-0 isolation substrate
(e.g., GPU-passthrough microVM per `[FM-DPG-0002]` properties +
the Tier-0 substrate row of the DPG Conformance Profile) **shall
constrain** the CRB eligibility filter to hosts whose
`available_runtimes` and hardware properties satisfy the Tier-0
substrate's host requirements. Symmetrically, the CRB-selected
target host's available substrate set constrains the isolation
tiers DPG can provision; a host without `/dev/kvm` excludes
microVM-class isolation tiers.

CRB **shall** treat isolation-tier satisfaction as an explicit
validation step on the selected host, not as an implicit
consequence of the eligibility filter. Before emitting
`crb.dispatch_started`, the broker **shall** verify the selected
host satisfies the workload's declared isolation-tier
requirement; a host that passes the eligibility filter but fails
the validation step (e.g., because the host's substrate set
changed between policy evaluation and dispatch) **shall** cause
the broker to re-evaluate eligibility or emit
`crb.policy_no_match`. This makes the eligibility-filter
assumption a checked invariant at the dispatch boundary, not a
trust-the-filter shortcut.

The composition is **at decision time**, not at the *concern*
level: the two pillars compose per workload, neither subsumes
the other.

*Verification: Conformance-test* — the harness submits a
workload requiring a Tier-0 DPG isolation substrate; asserts CRB
filters to hosts that can run the substrate; asserts a host
unable to run the substrate is rejected at eligibility; mutates
the selected host's substrate set between eligibility evaluation
and dispatch and asserts the explicit-validation step catches
the divergence and emits `crb.policy_no_match` rather than
proceeding; asserts the composition is logged in the dispatch-
decision audit.

#### `[FM-CRB-0010]` Operational-state transitional clause

The CRB broker daemon is **design-stage at this Standard's
publication**. The operational role today is played by operator
and agent convention recorded in the deployment's standing
documentation; the daemon is the build target. A deployment
**may** operate under the convention pattern as a recognized
**transitional deviation** until the broker daemon is built and
declared operational.

The transitional deviation **shall**:

1. Be registered in Appendix F with explicit sunset condition:
   "CRB broker daemon operational per `[FM-CRB-0001]` /
   `[FM-CRB-0003]` / `[FM-CRB-0005]` — codified policy applied
   to dispatch requests via IBX PCT, broker identity authorizing
   decisions, `crb.*` audit emission to ACT."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "crb-codified-by-convention"` per
   `[FM-PGE-0011]` discriminator (canonical emitter: PGE, via the
   policy that classifies convention-period dispatch as non-CRB-
   daemon-conformant) for every dispatch decision made under the
   convention.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when the broker daemon is declared
   operational. Mirror of the `[FM-IBX-0010]` / `[FM-IAM-0014]` /
   `[FM-PGE-0005]` Gate-2 / `[FM-DPG-0013]` transitional pattern.

A deployment operating under the convention deviation **shall
not** be claimed conformant to `[FM-CRB-0001]` / `[FM-CRB-0003]`
/ `[FM-CRB-0005]` on the basis of convention — it is conformant
to the deviation clause only.

*Verification (operational): Conformance-test* — when the broker
daemon is built, the multi-profile harness exercises the full
dispatch lifecycle and asserts the `crb.*` event sequence is
emitted per `[FM-CRB-0012]`.
*Verification (deviation period): Inspection of deviation
registry* — deviation entry present in Appendix F with sunset
condition; divergence events emitted per item 2 above.

#### `[FM-CRB-0011]` Convention-codification fidelity

When the broker daemon is built, its initial dispatch policy
**shall** match the deployment's codified-by-convention dispatch
behavior at the moment of daemon activation. The deployment
operator **shall** verify the parity (for each workload class
the convention recognizes, the daemon's selected host **shall**
match operator/agent convention) before the
`[FM-CRB-0010]` transitional deviation is sunset.

Subsequent policy evolution (capacity additions, new workload
classes, host removals) follows the deployment-architecture
governance for inventory + policy changes; surprise dispatch
behavior on daemon activation is a non-conformance against this
requirement, not a feature.

*Verification: Conformance-test* — the harness exercises a
parity battery: for each workload class in the deployment's
convention, the daemon's selected host **shall** match the
convention; a mismatch blocks deviation sunset.

#### `[FM-CRB-0012]` Audit emission via ACT

CRB **shall** emit the following `crb.*` events to ACT via the
`[FM-ACT-0009]` ack contract, drawn from the `[FM-ACT-0004]`
event-type taxonomy:

- `crb.dispatch_requested` — emitted on dispatch request
  acceptance after submission validation, before policy
  evaluation.
- `crb.policy_evaluated` — emitted on policy completion;
  payload includes classification, constraint set, eligible-host
  set, selected target.
- `crb.dispatch_started` — emitted when the broker initiates
  workload execution on the target host.
- `crb.dispatch_completed` — emitted on workload completion;
  payload includes outcome, resource usage, execution duration.
- `crb.policy_no_match` — emitted when no host satisfies the
  constraints; the workload remains in queue.
- `crb.dispatch_request_rejected` — emitted on submission
  refusal (authorization failure, malformed request, unknown
  class).

Per `[FM-ACT-0009]`, a dispatch **shall not** be considered
complete until ACT acknowledges the corresponding
`crb.dispatch_completed` (or terminal) event; lack-of-ack or
negative-ack **shall** cause the operation to fail strict.

Every dispatch **shall** have exactly one terminal event in ACT
(`crb.dispatch_completed`, `crb.policy_no_match` upon queue
exit, or `crb.dispatch_request_rejected`); a dispatch with no
terminal event is a no-bypass violation per `[FM-INV-0001]`.

*Verification: Conformance-test* — the harness exercises each
event type on the corresponding event class; asserts the ACT ack
contract is honored; asserts every dispatch has exactly one
terminal event.

#### `[FM-CRB-0013]` CRB telemetry emission

CRB **shall** emit OTLP-format traces, metrics, and logs for its
own operational observability. Span names **shall** follow the
`mesh.crb.*` namespace (e.g., `mesh.crb.dispatch.request`,
`mesh.crb.policy.evaluate`, `mesh.crb.dispatch.start`,
`mesh.crb.dispatch.complete`).

The required metric set **shall** include at minimum:
`dispatch.latency_ms` (histogram),
`dispatch.rate` (counter, labeled by outcome),
`policy.no_match_total` (counter — capacity / inventory-gap
signal), `host.utilization` (gauge, per-host per-class — the
load-bearing fleet-balance signal),
`queue.depth` (gauge, per workload class).

The operational telemetry stream (`mesh.crb.*`) is distinct from
the audit-event stream (`crb.*` per `[FM-CRB-0012]`). The two
flow to different sinks: operational OTLP for `mesh.crb.*`; ACT
event store for `crb.*` audit.

*Verification: Conformance-test* — the harness invokes
representative CRB operations and asserts emission of the
required span / metric / log records to the operational OTLP
sink with the `mesh.crb.*` namespace.

### §5.7.1 CRB Conformance Profile

The CRB pillar's substrate substitutability claim covers exactly
the rows in this Conformance Profile. CRB is the Reasoner
archetype and therefore has **no claim-queue substrate seam**
(distinct from worker-pool pillars like IBX / DPG).

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Scheduling / dispatch backend | `[FM-CRB-0001]`, `[FM-CRB-0003]`, `[FM-CRB-0008]` | Custom mesh broker daemon over DAC routing + per-host runtime — design-stage; operational under the `[FM-CRB-0010]` deviation today | Nomad 1.7+, Slurm 23+, Kubernetes 1.29+ — broker becomes a job emitter / controller against the same CRB contract | `crb-dispatch-backend-v1` |
| Accelerator runtime (`gpu_bound` / `mps_bound` target) | `[FM-CRB-0002]`, `[FM-CRB-0008]` | NVIDIA CUDA 12.x (`gpu_bound`) + Apple MPS (`mps_bound` sub-class) | ROCm 6+ (AMD), Vulkan compute, oneAPI (Intel) — each satisfying the accelerator-compute capability on a host that carries it | `crb-accelerator-runtime-v1` |
| Telemetry sink | `[FM-CRB-0013]` | OTLP-on-the-wire (any OTLP-compatible backend) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `crb-telemetry-v1` |

Out-of-set substrates **shall not** be claimed supported.
Extending the profile requires the argued-case discipline per
`[FM-INV-0003.2]` AND a conformance-suite extension running the
full dispatch battery (classification → expected eligible-host
set, `policy_no_match` on no capacity, accelerator-runtime
accounting per family) against the new substrate before merging.

### §5.8 MCC — Mesh Control Center

**Scope.** MCC is the mesh's **pluggable host-frame** and human
operator surface. The fleet and human users point at *one*
endpoint — MCC — which authenticates every call, dispatches to the
right pillar plugin, and returns through one canonical response
path. MCC is the central locus for substrate handles (database
pool, secret-store client, identity-provider federation, telemetry
sink), the IAM auth hook (every request is authenticated against
the IAM plugin before reaching another plugin), and the operator
surface (web admin UI; not CLI for routine operations). The
eight pillars (IBX, IAM, PGE, ACT, AKB, DPG, CRB per §§5.1–5.7;
PCS per §6) are **loadable modules** that live inside MCC; MCC is
the structural host they run on. **Pillar count stays at eight**
per `[FM-MCC-0011]` — MCC is not a ninth pillar but the host the
eight pillar contracts live inside.

**Dependencies.**

- `[FM-INV-0001]` (No bypass) and `[FM-INV-0002]` (Fail strict) apply — every plugin call **shall** traverse the IAM auth hook and the frame's dispatch path; bypassing MCC to reach a plugin directly is non-conforming.
- MCC consumes IAM as plugin #1 per `[FM-IAM-0001]` / `[FM-IAM-0006]` / `[FM-IAM-0011]`; IAM **shall** load before any other plugin can serve requests per `[FM-MCC-0005]`.
- MCC emits state-affecting frame operations as `mcc.*` events to ACT via the `[FM-ACT-0009]` ack contract and the `[FM-ACT-0004]` taxonomy.
- MCC **shall not** carry business logic, policy enforcement, identity verification, or audit storage — those live in their respective plugin pillars (PGE / IAM / ACT). The frame hosts them; the frame does not subsume them.

#### `[FM-MCC-0001]` Pluggable host-frame model

MCC **shall** be implemented as a **kernel/frame** that hosts the
mesh pillar contracts as **loadable modules** (plugins). The frame
**shall** provide the following capabilities to every loaded
plugin:

1. **Transport** — one HTTP server and one MCP transport, both
   routing inbound calls to plugin handlers.
2. **Authenticated context** — every plugin call carries an
   authenticated principal-id + role + permissions, populated by
   the IAM auth hook per `[FM-MCC-0003]` before the plugin sees
   the call.
3. **Substrate handles** — the database pool, secret-store
   client, identity-provider federation handle, and telemetry
   sink are held by the frame per `[FM-MCC-0004]` and surfaced to
   plugins by dependency-injection or equivalent registry.
4. **Configuration** — per-plugin config sections exposed via
   the frame's config registry; plugins declare config schema at
   registration.
5. **Telemetry sink** — a single OTLP sink the frame collects
   spans / metrics / logs into per `[FM-MCC-0014]`.
6. **Plugin registry** — other loaded plugins are discoverable
   by name; cross-plugin calls go through the registry, not
   direct connections.
7. **Judge-gate hook** — a frame-level elevated-confirmation
   hook per `[FM-MCC-0010]`.
8. **Lifecycle** — frame loads plugins at startup, calls their
   initialization, holds them through runtime, and calls their
   shutdown at termination.

A microservice mesh (each pillar deployed as its own network
service) is **not** conformant to this requirement — substrate
credentials scattered across N services and an auth surface forked
across N services both violate the kernel/frame model's
centralization invariants.

A pillar implementation that does not plug into MCC **shall not**
be claimed a deployable Fiducial Mesh pillar; it is a spec-only
artifact until it satisfies the plugin contract per
`[FM-MCC-0006]`.

*Verification: Inspection + Conformance-test* — Inspection
verifies the frame holds the substrate handles + auth hook +
dispatch + telemetry sink + config registry as enumerated;
Conformance-test exercises a plugin call through the full stack
(transport → auth → dispatch → plugin handler → response).

#### `[FM-MCC-0002]` Single endpoint

The fleet (agents) and human users **shall** point at exactly one
network address — MCC. Per-pillar endpoints (one MCP server per
pillar, one HTTP server per pillar, etc.) **shall not** exist in
the deployed system; they **may** exist at the build/test level
as plugin entry points the frame composes.

Routing within MCC: every inbound call **shall** carry a target
identifier (the tool name in MCP semantics; the URL path in HTTP
semantics) that names the plugin and the operation. MCC's frame
**shall** dispatch to the loaded plugin matching the identifier.

The customer deployment is **one URL** the customer points their
fleet at. Per-customer substrate (their database, their identity
provider, their secret store) is configured at the MCC frame
level. Pillars **shall** be blind to which substrate they are
running against — they consume handles per `[FM-MCC-0004]`, not
connection strings.

*Verification: Conformance-test* — the harness verifies the
deployed system exposes exactly one externally-reachable address;
asserts a probe of any candidate per-pillar address fails to
connect; asserts both HTTP and MCP transports route to the same
plugin operation set.

#### `[FM-MCC-0003]` IAM auth hook on every call

Every inbound call **shall** traverse the IAM auth hook before
reaching any plugin handler. The frame **shall** extract the
call's credentials (session token in MCP, bearer token / cookie in
HTTP), pass them to the IAM plugin's `validate-session` operation
per the `[FM-IAM-0011]` identity-context contract, and proceed to
plugin dispatch only on a return of an authenticated principal.

Plugins **shall** receive the authenticated context as part of
the call and **shall not** perform AuthN themselves; per
`[FM-INV-0001]`, re-authentication at the plugin layer is a
duplicated chokepoint and a structural defect.

Auth failures (missing credentials, invalid session, denied
authorization) **shall** halt at the frame boundary; the plugin
handler **shall not** be invoked. The frame **shall** emit
`mcc.auth_denied` and the call **shall** fail with the
appropriate transport-level rejection (HTTP 401/403 or MCP
equivalent).

The IAM auth-hook implementation **shall** be backed by a
session-validation cache to bound per-call latency. The cache
entry **shall not** outlive the IAM-declared session lifetime.
The cache is a latency optimization, not an extension mechanism
for the IAM authorization decision.

**Identity-context-version revalidation (TOCTOU defense).** Each
cache entry **shall** carry the `Identity-context version` (field
6 of the identity context per `[FM-IAM-0011]`) of the
principal-id at the moment the entry was populated. On every
cache hit, the frame **shall** synchronously compare the cached
version against the current `Identity-context version` for the
principal-id as held by IAM; if the versions differ, the cache
entry **shall** be evicted and the call **shall** re-authenticate
through the full IAM auth hook before dispatch. `[FM-IAM-0005]`
revocation operations (suspend / resume / terminate) increment
the version for the affected principal-id per `[FM-IAM-0011]`
items 3 + 6; the per-call version revalidation makes the cache
entry's freshness a **synchronous check**, not an async guarantee
against an inherently async revocation propagation channel.

A previous wording of this requirement — "shall be invalidated by
IAM revocation events… shall evict the corresponding cache entry
before the next authenticated call lands" — described an
unachievable happens-before guarantee against the async
revocation channel; the per-call version check replaces that
async-evict pattern with a synchronous-revalidate pattern that
is implementable as written.

*Verification: Conformance-test* — the harness submits calls
with missing / invalid / denied credentials and asserts halt at
the frame boundary with the corresponding auth-denied event;
asserts a successful call reaches the plugin handler with a
populated authenticated context; verifies the cache layer does not
extend session lifetime past the IAM-declared bound; **races a
revocation against a cached-valid entry** — terminates a
principal-id at T0, submits a call from the same principal-id at
T0 + ε before any async propagation could complete, and asserts
the version-revalidation evicts the cache entry and the call is
denied at the frame boundary.

#### `[FM-MCC-0004]` Centralized substrate handles

Substrate handles (database pool, secret-store client, identity-
provider federation, telemetry sink, any other deployment-scoped
substrate connection) **shall** be held by the frame and surfaced
to plugins via dependency-injection or equivalent registry.
Plugins **shall not** open direct connections to substrate; they
**shall** request handles from the frame at registration.

The frame **shall** fail plugin load if a plugin declares a
substrate-handle requirement that the frame cannot satisfy
(missing configuration, unreachable substrate, missing credential).

Substrate credentials **shall** live in the frame's secret-store
integration (per the Conformance Profile secret-store seam) and
**shall not**:

1. Appear in configuration files committed to source control,
2. Persist in environment variables on disk,
3. Appear in logs at any level,
4. Be readable by plugin handlers — handles are opaque references,
   not credential strings.

*Verification: Inspection + Conformance-test* — Inspection
verifies plugin code paths do not establish substrate connections
outside the frame's registry; Conformance-test attempts to load a
plugin whose declared substrate handle is unavailable and asserts
load failure; static-check confirms substrate credentials do not
appear in committed configuration files.

#### `[FM-MCC-0005]` IAM-first load order

The frame **shall** load the IAM plugin before any other plugin
can serve requests. A frame startup that cannot load IAM **shall**
fail closed — no plugins serve requests until IAM is operational.

Per `[FM-MCC-0003]`, every plugin call authenticates through the
IAM auth hook; the IAM plugin's `validate-session` operation
**shall** be available before any other plugin's handler is
reachable. The frame **shall** enforce this load ordering by
construction; plugin authors **shall not** be able to declare a
dependency ordering that places IAM after a dependent plugin.

After IAM, the load order of remaining plugins **may** be governed
by declared dependencies; plugin-name registration collisions
**shall** fail loudly at frame startup, not silently at runtime.

*Verification: Conformance-test* — the harness simulates IAM
plugin load failure and asserts no other plugin serves requests;
restores IAM and asserts dependent plugins load in declared
order; submits a duplicate-name plugin registration and asserts
loud rejection at startup.

#### `[FM-MCC-0006]` Plugin contract (minimum-viable surface)

A pillar implementation that plugs into MCC **shall** provide:

1. **A read-only MCP tool surface** — agent-facing read
   operations on the pillar's contract. The plugin registers these
   as MCP tools with the frame at startup; the frame routes
   inbound MCP calls to them after authentication.
2. **Privileged service operations behind a non-agent boundary**
   — write and lifecycle operations that an agent **shall not**
   invoke directly. The frame **shall** route these to non-agent
   actors (the operator via the admin UI; service principals via
   the credentialed service path). The agent-out-of-secret-path
   invariant **shall** be enforced at the frame boundary per
   `[FM-MCC-0009]`.
3. **A substrate-handle dependency declaration** — the plugin
   names which substrate handles it requires; the frame fails
   plugin load if any required handle is unavailable per
   `[FM-MCC-0004]`.
4. **Telemetry emission** — the plugin emits OTLP spans, metrics,
   and JSON logs via the frame's telemetry handle; the plugin
   **shall not** configure its own exporter.
5. **A Judge-gate declaration** — operations requiring elevated
   confirmation **shall** be declared by the plugin at registration
   per `[FM-MCC-0010]`.

This contract is the **minimum-viable surface** for the plugin
contract. Extension (inter-plugin coordination semantics, plugin
hot-replacement, sandboxing, external plugin loading) is reserved
for future requirements as additional plugins exercise the contract
and surface coverage gaps.

*Verification: Conformance-test* — the harness verifies a
candidate plugin satisfies every item; a plugin missing any of
the five **shall** fail load.

#### `[FM-MCC-0007]` Operator surface — web admin UI

The operator interaction surface for MCC **shall** be a web admin
UI. A CLI **may** exist at the frame level for build, test, and
emergency debugging — it **shall not** be the operator's normal
interaction surface for routine operations.

The admin UI **shall** authenticate the human operator through
the IAM auth hook per `[FM-MCC-0003]`, federated to the
deployment's identity provider per the Conformance Profile
identity-provider seam. There **shall not** be a separate
human-auth surface parallel to the agent-auth surface; both flow
through IAM.

Admin UI surfaces **shall** be a strict subset of the operations
available via the underlying frame API per `[FM-MCC-0008]` — the
UI is a client of the API, not a parallel control surface.

*Verification: Inspection + Conformance-test* — Inspection
confirms a web admin UI is the documented operator surface;
Conformance-test verifies every UI action invokes a frame API
operation also reachable directly via HTTP/MCP.

#### `[FM-MCC-0008]` CLI-first / UI-second discipline

Every admin UI action **shall** invoke a frame API operation that
is also reachable directly via the HTTP or MCP transport per
`[FM-MCC-0002]`. The UI **shall** be a client of the API, never a
parallel or privileged control surface. The CLI (when present)
**shall** wrap the same API.

A condition where the UI performs an operation the API cannot
**shall** be classified as a structural defect requiring spec-level
correction, not a UI bug. The discipline ensures the admin UI is
documentation-by-example for the underlying contract, and that
every operator action is automation-replayable through the API.

*Verification: Conformance-test* — the harness asserts a
one-to-one mapping between documented UI actions and reachable
frame API operations; a UI action with no corresponding API
operation fails the test.

#### `[FM-MCC-0009]` Agent-out-of-secret-path enforcement at frame

Agent-out-of-secret-path enforcement (per the IAM increment-2
invariant) **shall** be applied at the frame boundary, not at the
plugin layer. Calls from agents targeting privileged operations
(write / lifecycle operations on identity, secret-rotation
operations, infrastructure-modification operations) **shall** be
denied at the frame *before* reaching the plugin handler.

The frame **shall** maintain the privileged-operation classifier
as a declared property of each plugin's operation set (per the
plugin contract per `[FM-MCC-0006]` item 2). Calls from agents to
privileged operations **shall** emit `mcc.agent_secret_path_denied`
to ACT and **shall** fail with the corresponding transport-level
rejection.

The frame **shall not** trust the plugin to enforce the
agent-out-of-secret-path invariant — duplicating the enforcement
inside the plugin is permitted as defense in depth but **shall
not** substitute for the frame-boundary enforcement.

*Verification: Conformance-test* — the harness submits agent-
authenticated calls to privileged operations across each loaded
plugin and asserts frame-boundary denial; verifies the denial
event lands in ACT with the agent's principal-id and the targeted
privileged-operation classifier.

#### `[FM-MCC-0010]` Judge-gate hook (frame-level)

Operations requiring elevated confirmation (the Judge gate
pattern: lifecycle terminations, irreversible deletions,
catastrophic-class operations per `[FM-INV-0004]`) **shall** be
enforced by the frame at the plugin-dispatch boundary. Plugins
**shall** declare which operations are Judge-gated at
registration; the frame **shall** enforce the elevated
confirmation flow before dispatching to the plugin handler.

The Judge-gate confirmation flow **shall**:

1. Require non-default confirmation (the operator types or
   re-attests a uniquely-identifying value for the target, not a
   yes/no click);
2. Be uniquely audit-attestable — the confirmation action emits
   `mcc.judge_gate_confirm` with the operator's principal-id, the
   target plugin / operation, and the confirmation token, to ACT
   per the `[FM-ACT-0009]` ack contract before the plugin handler
   is invoked;
3. Be uniformly applied — every Judge-gated operation uses the
   same UX pattern; plugin-specific confirmation surfaces are not
   permitted, to prevent "the easy one" UX drift.

A plugin operation declared Judge-gated that is dispatched without
a matching `mcc.judge_gate_confirm` event in ACT is a no-bypass
violation per `[FM-INV-0001]`.

*Verification: Conformance-test* — the harness submits a
Judge-gated operation without the confirmation flow and asserts
denial at the frame; submits with confirmation and asserts the
confirm event is emitted before plugin handler invocation;
verifies the plugin handler cannot be invoked by skipping the
frame's confirmation step.

#### `[FM-MCC-0011]` Eight pillars; MCC is the host

The mesh's pillar count **shall** remain eight: IBX (§5.1), IAM
(§5.2), PGE (§5.3), ACT (§5.4), AKB (§5.5), DPG (§5.6), CRB
(§5.7), and PCS (§6). MCC (§5.8) is the **host frame** and
**shall not** be claimed a ninth pillar.

MCC is the **host frame** the eight pillar contracts live inside,
parallel to the substrate seams the pillars depend on below the
pillar layer. The pillar layer is the contract surface customers
consume; MCC is the structural host that surface runs on;
substrates (`[FM-CONFORMANCE-*]` etc.) are the implementation
seams below the pillar contracts.

The Conformance Profile invariants — every pillar declares a
substrate matrix; every pillar passes a conformance test set;
every pillar emits audit and telemetry through the patterns
specified in this Standard — **shall** be unaffected by the MCC
host frame's existence; MCC adds a host layer, not a pillar.

*Verification: Inspection* — the mesh's pillar enumeration
across §§5.1–5.7 (seven pillars) + §6 (PCS, the eighth) is
verified to count eight; MCC (§5.8) is documented as host frame,
not as pillar #9; the Conformance Profile across all pillars is
unaffected by the MCC frame.

#### `[FM-MCC-0012]` Operational-state transitional clause

The pluggable host-frame model committed by `[FM-MCC-0001]` is
**partially operational** at this Standard's publication. The
current deployed surface satisfies the single-endpoint property
per `[FM-MCC-0002]`, the IAM auth hook per `[FM-MCC-0003]`, and
the centralized-substrate-handle property per `[FM-MCC-0004]` for
the operator-surface workload class. The full host-frame with all
eight pillars loaded as plugins per `[FM-MCC-0006]` is the build
target; the remaining pillars **shall** plug in as they reach
their operational-state declarations.

A deployment **may** operate under the partial-load pattern as a
recognized **transitional deviation** until all eight pillars are
loaded into MCC. The deviation **shall**:

1. Be registered in Appendix F with explicit sunset condition:
   "All eight pillars loaded into MCC per `[FM-MCC-0006]` plugin
   contract; the deployment's `mcc_plugin_loaded` gauge per
   `[FM-MCC-0014]` reports the full pillar set."
2. Emit a divergence event to ACT per `[FM-INV-0005.2]` with
   `divergence_type = "mcc-partial-load"` per `[FM-PGE-0011]`
   discriminator (canonical emitter: PGE) for every dispatch
   targeting a pillar that is not yet loaded as an MCC plugin.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when all eight pillars are loaded into
   MCC. Mirror of the `[FM-IBX-0010]` / `[FM-IAM-0014]` /
   `[FM-PGE-0005]` Gate-2 / `[FM-DPG-0013]` / `[FM-CRB-0010]`
   transitional pattern.

A deployment operating under the partial-load deviation **shall
not** be claimed conformant to `[FM-MCC-0006]` on the basis of
the loaded subset — it is conformant to the deviation clause only
for the unloaded pillars.

*Verification (operational): Conformance-test* — the harness
verifies all eight pillars are loaded per the plugin contract;
asserts every pillar's read-only MCP tool surface is reachable
through MCC's single endpoint.
*Verification (deviation period): Inspection of deviation
registry* — deviation entry present in Appendix F with sunset
condition; divergence events emitted per item 2 above.

#### `[FM-MCC-0013]` Audit emission via ACT

MCC **shall** emit the following `mcc.*` events to ACT via the
`[FM-ACT-0009]` ack contract, drawn from the `[FM-ACT-0004]`
event-type taxonomy:

- `mcc.call_received` — emitted on inbound call before
  authentication.
- `mcc.auth_denied` — emitted on auth-hook denial per
  `[FM-MCC-0003]`.
- `mcc.agent_secret_path_denied` — emitted on agent-out-of-secret-
  path denial per `[FM-MCC-0009]`.
- `mcc.dispatch_completed` — emitted on plugin dispatch completion
  (success or plugin-reported failure).
- `mcc.judge_gate_confirm` — emitted on Judge-gate confirmation
  per `[FM-MCC-0010]`.
- `mcc.plugin_loaded` / `mcc.plugin_load_failed` — emitted on
  plugin lifecycle events.

Per `[FM-ACT-0009]`, a call **shall not** be considered complete
until ACT acknowledges the corresponding terminal event;
lack-of-ack or negative-ack **shall** cause the operation to fail
strict.

Every inbound call **shall** have exactly one terminal event in
ACT (`dispatch_completed`, `auth_denied`, or
`agent_secret_path_denied`); a call with no terminal event is a
no-bypass violation per `[FM-INV-0001]`.

*Verification: Conformance-test* — the harness exercises each
event type on the corresponding event class; asserts the ACT ack
contract is honored; asserts every call has exactly one terminal
event.

#### `[FM-MCC-0014]` MCC telemetry emission

MCC **shall** emit OTLP-format traces, metrics, and logs for the
frame's own operational observability. Span names **shall** follow
the `mesh.mcc.*` namespace (e.g., `mesh.mcc.transport.handle`,
`mesh.mcc.auth.validate`, `mesh.mcc.dispatch.plugin`,
`mesh.mcc.plugin.load`, `mesh.mcc.judge_gate.confirm`).

The required metric set **shall** include at minimum:
`requests_total` (counter, labeled by transport, plugin,
operation, outcome), `request_duration_seconds` (histogram),
`auth_validations_total` (counter, labeled by auth outcome),
`plugin_loaded` (gauge, labeled by plugin — the load-bearing
host-frame-completeness signal that drives `[FM-MCC-0012]`'s
sunset condition), `judge_gate_pending` (gauge).

The operational telemetry stream (`mesh.mcc.*`) is distinct from
the audit-event stream (`mcc.*` per `[FM-MCC-0013]`). The two flow
to different sinks: operational OTLP for `mesh.mcc.*`; ACT event
store for `mcc.*` audit.

Per-plugin telemetry (each loaded plugin's own `mesh.<pillar>.*`
spans / metrics / logs) is governed by that pillar's telemetry
requirement (`[FM-IBX-…]`, `[FM-IAM-…]`, etc.) and flows through
the frame's telemetry handle; the frame **shall not** swallow,
relabel, or aggregate per-plugin telemetry into its own namespace.

*Verification: Conformance-test* — the harness invokes
representative MCC operations and asserts emission of the required
span / metric / log records with the `mesh.mcc.*` namespace;
verifies per-plugin telemetry passes through with the pillar's own
namespace intact.

### §5.8.1 MCC Conformance Profile

The MCC pillar's substrate substitutability claim covers exactly
the rows in this Conformance Profile. The substrate seams the
frame depends on are deployment-architecture choices, not pillar
implementation choices; per the `[FM-INV-0003.2]` argued-case
discipline and the §1 language-neutral principle, every seam
names the *capability*, not the product or implementation
language.

| Seam | Bound requirement(s) | Sovereign reference (version floor) | Supported alternatives | Test Set |
|------|---------------------|-------------------------------------|------------------------|----------|
| Transport (HTTP + MCP) | `[FM-MCC-0001]`, `[FM-MCC-0002]` | HTTPS-only HTTP server + MCP-over-TLS transport, both routing to the same plugin operation set | Any HTTPS-capable server + MCP-compatible transport satisfying the single-endpoint property | `mcc-transport-v1` |
| Relational database (transactional, JSONB-equivalent) | `[FM-MCC-0004]` | PostgreSQL 17+ | Oracle 19+, MySQL 8+ — any relational substrate satisfying the IBX claim-queue and the IAM identity-store contracts | `mcc-database-v1` |
| Secret store (HTTPS-accessible, audit-loggable, revocable) | `[FM-MCC-0004]`, `[FM-IAM-0006]` | HashiCorp Vault (Tier-0 with PKCS#11 HSM; Tier-2 soft-mode) per the IAM Conformance Profile | Azure Key Vault (HSM Tier-0), AWS KMS + Secrets Manager (CloudHSM Tier-0), OCI Vault (dedicated HSM), Thales CipherTrust Manager, standalone PKCS#11 HSM on-prem | `mcc-secret-store-v1` |
| Identity provider (federated; SAML/OIDC/LDAP-capable) | `[FM-MCC-0003]`, `[FM-MCC-0007]`, `[FM-IAM-0011]` | Samba AD / Microsoft AD (federation per the IAM identity-provider seam) | Microsoft Entra, OpenLDAP, Keycloak, FreeIPA, any SAML/OIDC/LDAP-capable identity provider | `mcc-identity-provider-v1` |
| Telemetry sink | `[FM-MCC-0014]` | OTLP-on-the-wire (any OTLP-compatible backend) | Grafana/Prometheus/Tempo, Azure Monitor, Datadog, OCI Monitoring | `mcc-telemetry-v1` |
| TLS terminator | `[FM-MCC-0001]` (transport) | Any TLS-capable HTTPS server (self-handled or front-proxy) | Caddy, nginx, native HTTPS in the host runtime, cloud load-balancer TLS termination | `mcc-tls-v1` |
| Process supervisor | `[FM-MCC-0001]` (lifecycle) | Any process supervisor with restart, log capture, resource limits | systemd, container orchestrator (Kubernetes / Nomad / Podman), supervisord, runit | `mcc-supervisor-v1` |

Out-of-set substrates **shall not** be claimed supported.
Extending the profile requires the argued-case discipline per
`[FM-INV-0003.2]` AND a multi-profile conformance run proving the
new substrate passes the MCC test suite for every affected seam.

---

## §6 Reserved — PCS plugin and workflow requirements

*This section is reserved for the normative requirements governing PCS
plugin structure, workflow lifecycle, validation harness tiers,
registry behavior, and marketplace projection. Will be landed in
subsequent PRs.*

---

## §7 Reserved — Operational requirements

*This section is reserved for the normative requirements governing
delivery and packaging substrate, security framework, FIPS-Day-1
discipline, and AIR/CLCA continuous-improvement discipline. Will be
landed in subsequent PRs.*

---

## Appendix A — PCT Schema (normative)

The Principal Control Token (PCT) is the message-from-Principal-to-
Singleton artifact every IBX message carries per `[FM-IBX-0001]`. The
nine-field PCT v1 schema is defined here and is referenced from
`[FM-IBX-0001]` (rejection-on-missing-field) and `[FM-IBX-0002]`
(field-name stability across v1.x).

### A.1 Field list — pct-v1

| # | Field | Group | Type | Purpose |
|---|-------|-------|------|---------|
| 1 | `principal-id` | Identity / work | identifier (IAM-issued; see `[FM-IBX-0010]`) | Who sent the message (the identity behind the message) |
| 2 | `task` | Identity / work | structured text | What the recipient is asked to do |
| 3 | `background` | Identity / work | structured text | Context the recipient needs to do it |
| 4 | `reach` | Boundary axes | scope set | What the recipient may touch (scope) |
| 5 | `completion-criterion` | Boundary axes | structured text | Success criteria for the work |
| 6 | `autonomy` | Boundary axes | authority specification | What the recipient may decide without further approval (authority bounds) |
| 7 | `pct-version` | Meta | semver string | Version of the PCT schema in use (e.g., `pct-v1.0`) |
| 8 | `provenance` | Meta | signed chain | Chain of identities and tooling that produced the PCT |
| 9 | `validity-window` | Meta | `{not-before, not-after}` timestamps | Earliest-effective and latest-effective times |

### A.2 Group semantics

- **Identity / work (fields 1–3)** — who sent it, what they want
  done, the background to do it
- **Boundary axes (fields 4–6)** — three orthogonal constraints on
  the work: `reach` (scope), `completion-criterion` (success criteria),
  `autonomy` (authority bounds). Scope and authority bounds are
  axially distinct: `reach` answers *what may I touch*; `autonomy`
  answers *what may I decide without asking*. These **shall not** be
  conflated in spec prose or tooling — `reach` ties to the IAM-scope
  authorization seam, `autonomy` ties to the Judge-gate approval seam.
- **Meta (fields 7–9)** — properties of the PCT itself, not its
  content. Machine-validated structure.

### A.3 Validation discipline

A complete PCT v1 message has all nine fields populated. Per
`[FM-IBX-0001]`, IBX rejects any message missing one or more fields
at the routing layer. Per `[FM-IBX-0002]`, the field names defined
here are immutable across `pct-v1.x` — field-value constraints,
validation rules, and deprecation-with-replacement semantics **may**
be added in v1.x but field identity **shall not** change.

A future `pct-v2` schema, if introduced, **shall** be a separate
appendix entry; consumers that build against `pct-v1` (e.g., the
PCS-Daemon `pct-v1` consumer per §6 when landed) **shall** continue
to receive `pct-v1` messages.

## Appendix B — Normative plugin manifest schema

*Reserved for the PCS plugin manifest JSON schema and the `policy:`
block schema. Will be landed alongside §6.*

## Appendix C — Normative namespace conventions

*Reserved for the namespace coordinate format, prefix-reservation
discipline, and tenant-onboarding requirements. Will be landed
alongside §6.*

## Appendix D — Normative cross-pillar binding matrix

*Reserved for the requirement-by-requirement mapping of how PCS workflow
execution touches each pillar. Will be landed alongside §5 and §6.*

## Appendix E — Non-normative regulatory crosswalk

*Reserved for the non-normative mapping of Fiducial Mesh requirement
identifiers to external regulatory frameworks (NIST SP 800-53, HIPAA,
FedRAMP, ICD 705, etc.). Will be landed alongside §7.*

## Appendix F — Argued cases and deviations (normative entry schema)

This Appendix is the normative registry of **argued cases** per
`[FM-INV-0003.2]` and **recognized deviations** per the transitional
clauses of `[FM-IBX-0010]`, `[FM-IAM-0014]`, `[FM-PGE-0005]` Gate-2,
`[FM-ACT-0008]`, `[FM-DPG-0013]`, `[FM-CRB-0010]`, and
`[FM-MCC-0012]` (and any future requirements that introduce
deviation clauses by the same pattern).

The registry itself is **per-deployment** — each conforming
deployment maintains its own Appendix F as part of its conformance
documentation. This section of the Standard defines the **entry
schema** that every registry entry **shall** satisfy. The Standard
does not enumerate specific deployments' entries; those are runtime
artifacts of each deployment's operational state.

### §F.1 Argued-case entry schema

An argued-case entry (per `[FM-INV-0003.2]`) **shall** carry:

| Field | Required content |
|-------|------------------|
| `entry_id` | Unique identifier within the deployment's registry; monotonically assigned |
| `entry_date` | UTC timestamp of entry creation |
| `type` | `argued-case` |
| `bound_requirements` | One or more `[FM-*-NNNN]` requirement IDs the case extends or argues against |
| `case_rationale` | Structured argument satisfying `[FM-INV-0003.2]` — what new capability is being requested, why the existing Standard requirement does not cover it, what mitigations apply |
| `quorum_attestation` | If the case is catastrophic-class per `[FM-INV-0004]`: the quorum signatures or references thereto; otherwise the field is `n/a` with explicit justification |
| `authoring_identity` | The `principal-id` of the case's author |
| `approval_chain` | Ordered list of `{approver_identity, approval_timestamp, approval_signature}` records |
| `status` | One of `proposed` / `approved` / `rejected` / `superseded` |

An argued case that adds a substrate to a pillar's Conformance
Profile **shall** also include the multi-profile conformance run
result for the new substrate as part of `case_rationale`.

### §F.2 Recognized-deviation entry schema

A recognized-deviation entry (per a Standard transitional clause)
**shall** carry:

| Field | Required content |
|-------|------------------|
| `entry_id` | Unique identifier within the deployment's registry; monotonically assigned |
| `entry_date` | UTC timestamp of entry creation |
| `type` | `deviation` |
| `bound_requirements` | The `[FM-*-NNNN]` requirement(s) the deployment is deviating from |
| `deviation_clause` | The transitional clause within the bound requirement that authorizes the deviation (e.g., "FM-MCC-0012 Operational-state transitional clause") |
| `deviation_scope` | Specific scope of the deviation — which pillars, which workloads, which surfaces are affected |
| `sunset_condition` | Verbatim text of the sunset condition declared by the transitional clause |
| `divergence_type` | The `divergence_type` value emitted per the requirement's `[FM-INV-0005.2]` divergence-event emission requirement (cross-references `[FM-PGE-0011]`'s discriminator table) |
| `authoring_identity` | The `principal-id` of the deviation's author |
| `approval_chain` | Ordered list of `{approver_identity, approval_timestamp, approval_signature}` records |
| `status` | One of `active` / `sunset` / `superseded` |
| `sunset_attestation` | When `status = sunset`: the `principal-id` + timestamp + attestation that the sunset condition has been met |

### §F.3 Registry integrity requirements

A conforming deployment's Appendix F registry **shall**:

1. Append entries monotonically (entry IDs increase; entries are not
   modified in place once `status` is set to a terminal value);
2. Be reviewable by audit at any time — every entry **shall** be
   queryable by `bound_requirements`, by `divergence_type`, and by
   `status`;
3. Cross-reference the corresponding ACT events emitted per
   `[FM-INV-0005.2]` — a deviation entry's `divergence_type`
   **shall** match the ACT-emitted `divergence_type` per the
   `[FM-PGE-0011]` discriminator table;
4. Be reviewed at each major Standard release per the transitional
   clauses' Standard-release-review condition; entries whose
   `bound_requirements` reference a requirement that has been
   superseded by a Standard revision **shall** have their `status`
   transitioned accordingly.

*Verification: Inspection of registry + Conformance-test of registry
queries* — Inspection verifies each entry conforms to the §F.1 or
§F.2 schema; Conformance-test exercises the three query axes
(`bound_requirements`, `divergence_type`, `status`) and asserts
matching ACT events exist for every deviation entry whose
`divergence_type` is non-empty.

---

*End of FIDUCIAL-MESH-STD-001 v0.1.*

This Standard is the source of truth for the normative requirements
Fiducial Mesh implementations satisfy. The companion handbook
[`FIDUCIAL-MESH-HDBK-001`](FIDUCIAL-MESH-HDBK-001.md) carries the
rationale, design history, worked examples, and dialectical narrative.
