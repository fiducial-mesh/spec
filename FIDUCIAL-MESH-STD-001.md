---
title: "FIDUCIAL-MESH-STD-001 — Fiducial Mesh Platform Standard"
doc_type: standard
status: draft
version: v0.1
date: 2026-06-09
authors:
  - watson
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

### §0.5 Out of scope for this Standard

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
contracts (PCS plugin and workflow shape, validation harness tiers,
registry behavior, substrate-matrix conformance discipline), the
per-pillar requirements (IBX, AKB, ACT, IAM, PGE, CRB, DPG, MCC), and
the operational disciplines (security framework, delivery and
packaging substrate, AIR/CLCA continuous-improvement loop).

This Standard is **substrate-pluggable**: it defines what
implementations and deployments **shall** do, not what specific
backend products **shall** be used. Customer choice across the
substrate-matrix seams is a first-class property; conformance is
verified by passing the multi-profile conformance run against the
declared matrix rows.

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
| AIR | After-Incident Report |
| AKB | Agent Knowledge Base (pillar) |
| ARCA | Agentic Root Certificate Authority |
| BOM | Bill of Materials (versioned signed registry artifact pinning a coherent plugin set) |
| CLCA | Closed Loop Corrective Action (Ford 8D discipline) |
| CRB | Compute Resource Broker (pillar) |
| DPG | Deterministic Proving Ground (pillar) |
| FIPS | Federal Information Processing Standards |
| HDBK | Handbook (NASA document type) |
| IAM | Identity and Access Management (pillar) |
| IBX | Inbox Exchange (pillar) |
| MCC | Mesh Control Center (pillar) |
| MCP | Model Context Protocol |
| PCS | Platform Control System (pillar) |
| PCT | Principal Control Token |
| PGE | Policy Guardrail Engine (pillar) |
| SCIF | Sensitive Compartmented Information Facility |
| STD | Standard (NASA document type) |
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

#### `[FM-INV-0002]` Fail strict

Under error, ambiguity, unavailability, or unverifiable state, the
platform **shall** halt the affected operation and **shall not**
proceed.

A principal whose credential cannot be confirmed valid **shall** stop.
An action whose authorization cannot be resolved **shall** be denied.
An identity verification request that cannot be completed **shall not**
default to "allow." When in doubt, the platform **shall** halt.

### §4.2 Capability provisioning as primary defense

#### `[FM-INV-0003]` Capability provisioning is the primary defense

The mesh **shall** provision the minimum capability set consistent with
its declared purpose. Policy **shall** gate use of provisioned
capabilities; policy **shall not** be used to expand the capability
surface beyond what has been explicitly provisioned with an argued
case.

##### `[FM-INV-0003.1]` Extensions compose within the provisioned surface

PCS plugins, workflows, and components **shall** compose only within
the capability surface already provisioned by the pillar implementations
and their declared substrate matrices. A plugin **shall not** introduce
a capability that the underlying pillars do not already expose.

##### `[FM-INV-0003.2]` Net-new capability requires argued-case plus quorum

Provisioning a net-new platform-level capability — a new pillar, an
extended substrate matrix row, a new agent surface, or any other
expansion of what the platform allows — **shall** require an explicit
argued case documented in this Standard and **shall** be gated at apply
time by the quorum mechanism defined in `[FM-INV-0004]`.

##### `[FM-INV-0003.3]` Decision test for new capability proposals

When a new capability is proposed for the mesh, the proposal **shall**
answer the question: *"Do we want any principal — anywhere, ever — to
be able to perform this operation?"* If the answer is no, the
capability **shall not** be provisioned; policy cannot make a
non-existent capability safer than its non-existence. If the answer
is yes, the proposal **shall** specify the policy gates, identity
scopes, audit emissions, and (where applicable) quorum-class
classification per `[FM-INV-0004]` that govern its use.

### §4.3 Quorum authority for catastrophic-class capabilities

#### `[FM-INV-0004]` Quorum authority for catastrophic-class capabilities

For any capability classified as catastrophic-class, authority **shall**
be distributed across N independent identities via Shamir K-of-N
quorum. Single-identity wielding of a catastrophic-class capability
**shall** be structurally impossible — not merely policy-restricted.

Catastrophic-class capabilities include, non-exhaustively: applying or
revoking a policy overlay; revoking the ARCA root CA; minting a new
overlay-author identity; rotating the trust-root key chain; mass
identity action affecting the entire workforce; substrate decommission
or irreversible data destruction.

##### `[FM-INV-0004.1]` Asymmetric apply-vs-revoke thresholds

The K threshold for applying (arming) a catastrophic-class operation
**shall** be greater than or equal to the K threshold for revoking
(firing) the same operation, where applicable. Emergency revocation
**shall not** be blocked by a quorum threshold equivalent to the apply
threshold.

##### `[FM-INV-0004.2]` Time-bounded attestation windows

Each attestation toward a K-of-N quorum **shall** carry an expiration
timestamp. If K-of-N attestations are not collected within the
configured window, all collected attestations **shall** expire and the
quorum process **shall** restart. Stale attestations **shall not** be
retained for later use beyond their declared window.

##### `[FM-INV-0004.3]` Role-typed quorum membership

A catastrophic-class operation **may** require specific roles within
the K-of-N quorum (e.g., HIPAA overlay apply may require the
HIPAA-compliance-officer identity within the K set). When role-typed
quorum is specified, the absence of a required role **shall** prevent
the operation regardless of total attestation count.

##### `[FM-INV-0004.4]` Bootstrap at mesh initialization

The initial K-of-N quorum membership **shall** be established at mesh
initialization, parallel to the `vault operator init` ceremony.
Subsequent modifications to quorum membership — including addition,
removal, replacement, or rotation of members — **shall** themselves
require existing K-of-N quorum.

### §4.4 Platform enforcement floor

#### `[FM-INV-0005]` Platform enforcement floor is authoritative

The platform's enforcement floor — including but not limited to
authentication (`[FM-INV-0001]`), fail-strict (`[FM-INV-0002]`),
capability provisioning (`[FM-INV-0003]`), and quorum authority
(`[FM-INV-0004]`) — **shall** be authoritative and independent of
plugin or workflow self-declaration. A plugin's PCS manifest policy
declaration **shall** constitute a declaration of intent, not an
enforcement contract.

##### `[FM-INV-0005.1]` Default-deny on declaration omission

Absence of a policy declaration field in a plugin's PCS manifest
**shall not** confer permission. A plugin that omits a `judge_gates`
or `quorum_required` declaration **shall not** thereby acquire
permission to perform those operations without the platform's gates.
Absent **shall not** mean permitted; absent **shall** mean unspecified,
and the platform **shall** apply its floor.

##### `[FM-INV-0005.2]` Divergence between declaration and enforcement is auditable

When a plugin's declared policy diverges from the platform's
enforcement (the plugin claims an operation requires no gate; the
platform enforces a gate anyway), the divergence **shall** be recorded
as a discrete audit event in the ACT pillar. Repeated divergence
involving the same plugin **shall** be available as a CLCA trigger
signal.

##### `[FM-INV-0005.3]` Enforcement granularity

The platform's enforcement floor **shall** cover the broader surface of
state-affecting operations classified by PGE policy as requiring
approval, not solely the headline catastrophic-class operations
enumerated in `[FM-INV-0004]`. Per-operation classification belongs to
PGE policy; the enforcement floor binds regardless of plugin
declaration.

---

## §5 Reserved — Pillar requirements

*This section is reserved for the per-pillar normative requirements
(IBX, AKB, ACT, IAM, PGE, CRB, DPG, MCC). Pillar requirements will be
landed in subsequent PRs that migrate the substrate-matrix conformance
profiles and pillar-specific contracts from the companion handbook.*

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

## Appendix A — Normative plugin manifest schema

*Reserved for the PCS plugin manifest JSON schema and the `policy:`
block schema. Will be landed alongside §6.*

## Appendix B — Normative namespace conventions

*Reserved for the namespace coordinate format, prefix-reservation
discipline, and tenant-onboarding requirements. Will be landed
alongside §6.*

## Appendix C — Normative cross-pillar binding matrix

*Reserved for the requirement-by-requirement mapping of how PCS workflow
execution touches each pillar. Will be landed alongside §5 and §6.*

## Appendix D — Non-normative regulatory crosswalk

*Reserved for the non-normative mapping of Fiducial Mesh requirement
identifiers to external regulatory frameworks (NIST SP 800-53, HIPAA,
FedRAMP, ICD 705, etc.). Will be landed alongside §7.*

---

*End of FIDUCIAL-MESH-STD-001 v0.1.*

This Standard is the source of truth for the normative requirements
Fiducial Mesh implementations satisfy. The companion handbook
[`FIDUCIAL-MESH-HDBK-001`](FIDUCIAL-MESH-HDBK-001.md) carries the
rationale, design history, worked examples, and dialectical narrative.
