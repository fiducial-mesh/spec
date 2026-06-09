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
policy block, per §6 and Appendix A) references a capability not
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
   referenced amendment document (default location: Appendix E,
   reserved for argued-case records, to be created in PR-B).
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

For any capability classified as catastrophic-class, authority **shall**
be distributed across N independent identities via Shamir K-of-N
quorum. Single-identity wielding of a catastrophic-class capability
**shall** be structurally impossible — not merely policy-restricted.

Catastrophic-class capabilities include, non-exhaustively: applying or
revoking a policy overlay; revoking the ARCA root CA; minting a new
overlay-author identity; rotating the trust-root key chain; mass
identity action affecting the entire workforce; substrate decommission
or irreversible data destruction.

*Verification: Conformance-test* — the harness submits a
catastrophic-class operation request signed by fewer than K independent
identities and asserts the operation is not applied.

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

*Verification: Conformance-test* — the harness submits an attestation,
advances clock past the window without reaching K-of-N, and asserts
all attestations have expired and the operation cannot apply with the
expired attestation set.

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
   are emitted to the ACT pillar as a single immutable record.
5. **From ceremony completion onward**, all subsequent modifications
   to quorum membership — including addition, removal, replacement,
   or rotation of members — **shall** themselves require existing
   K-of-N quorum.

*Verification: Inspection* — mesh-init record in ACT is reviewed for
all five ceremony elements; absence of any element invalidates the
bootstrap and requires re-ceremony.

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
