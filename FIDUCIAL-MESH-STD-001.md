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

*Reserved for future PR. Foundational pillar; per
`[FM-INV-0001]`/`[FM-INV-0002]` Tier-0 invariants. Required by `[FM-IBX-0010]`.*

### §5.3 PGE — Policy Guardrail Engine

*Reserved for future PR. Required by `[FM-INV-0005]` enforcement floor.*

### §5.4 ACT — Agent Cognitive Telemetry

*Reserved for future PR. Required by `[FM-IBX-0012]` and the audit-emission requirements every other pillar inherits.*

### §5.5 AKB — Agent Knowledge Base

*Reserved for future PR.*

### §5.6 DPG — Deterministic Proving Ground

*Reserved for future PR.*

### §5.7 CRB — Compute Resource Broker

*Reserved for future PR.*

### §5.8 MCC — Mesh Control Center

*Reserved for future PR.*

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

## Appendix F — Argued cases and deviations (reserved)

*Reserved for the registry of argued cases per `[FM-INV-0003.2]` and
recognized deviations per `[FM-IBX-0010]` and analogous deviation
clauses in future pillar sections. Each entry will record: requirement
ID, deviation or argued-case rationale, scope and sunset condition
(for deviations), authoring identity, approval chain. Will be landed
alongside §5 as deviation entries accumulate or per the first formal
argued case.*

---

*End of FIDUCIAL-MESH-STD-001 v0.1.*

This Standard is the source of truth for the normative requirements
Fiducial Mesh implementations satisfy. The companion handbook
[`FIDUCIAL-MESH-HDBK-001`](FIDUCIAL-MESH-HDBK-001.md) carries the
rationale, design history, worked examples, and dialectical narrative.
