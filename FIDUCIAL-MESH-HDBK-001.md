---
title: "FIDUCIAL-MESH-HDBK-001 — Fiducial Mesh Handbook"
doc_type: handbook
status: released
version: v1.1
date: 2026-06-28
license: CC-BY-4.0
copyright: "Copyright (c) 2026 Agentics Labs LLC"
authors:
  - "Fiducial Mesh Group"
companion_to: FIDUCIAL-MESH-STD-001.md
references:
  - FIDUCIAL-MESH-STD-001.md
  - https://github.com/fiducial-mesh/devel/blob/main/spec-drafts/MANIFESTO.md
  - https://github.com/fiducial-mesh/devel/blob/main/spec-drafts/PILLAR-NAMES.md
---

# FIDUCIAL-MESH-HDBK-001 — Fiducial Mesh Handbook

> Companion handbook to `FIDUCIAL-MESH-STD-001`. This document carries
> the rationale, philosophy, worked examples, and dialectical narrative
> behind the mesh's normative requirements. **The STD is what gets
> audited; this handbook is what gets read.**
>
> Per the STD/HDBK separation: **this handbook cites STD requirement IDs
> by number; it never restates them.** Where this handbook discusses
> `[FM-INV-0001]` (no-bypass), the normative statement lives in
> STD-001 §4.1; this handbook explains the reasoning, the precedent,
> the operational consequence — not the requirement itself. Two documents
> that cross-restate drift; one source of truth prevents that.
>
> **Migration note:** this document was renamed from `FIDUCIAL-MESH-SPEC.md`
> on 2026-06-09 as part of the STD/HDBK restructure. Existing chapter
> content remains operative for material not yet migrated into STD-001;
> chapters are being reorganized into proper handbook structure (intro,
> rationale per invariant, dogfood story, dialectical narrative, worked
> examples) in subsequent commits.

## Table of Contents

### 1. The Mesh
The thesis (what Fiducial Mesh is, what problem it solves, why it exists),
the design philosophy (human authority + agent capability), the language
policy (Python default, Go for CRB and DPG, no C# anywhere), the pillar
topology (substrate / action / governance), and how to read the rest of
the spec.

### 2. PCS — Platform Control System
What controls the platform. **PCS manages the other pillars via the
plugin system** (control flows PCS → pillars; pillars stay zero-coupled).
Opens with the **plugin-loadout = agent role** framing: the 5
mesh-internal namespaces (deployment / configuration / operations /
administration / diagnostics) ARE five composable role-loadouts;
agents-are-employees; role = toolset granted; capability lives in the
plugin, authority lives in the identity. Covers the cardinal rule (PCS
plugins are a strict superset of Anthropic Claude Code AND OpenAI Codex
plugins, so they install on any agent surface — falls out as a free
target for Copilot CLI / Coding Agent via the open Agent Skills
standard), the artifact hierarchy (Namespace → Plugin → Workflow), the
validation harness, the mesh-internal registry with vendor-marketplace
projections, the default manifest + tested variations model (BOMs), the
AIR/CLCA continuous improvement loop, the bootstrap (agent + bootstrap
plugin IS pcs-init; no custom binary required), and the Mesh-CLI / MCC
delivery shape (Mesh-CLI is a configuration not a product; MCC backend
is conventional Python — the AI is built ZERO times for MCC).

### 3. The Pillars
The substrate pillars PCS orchestrates. Each pillar gets a section
explaining what it does, its substrate matrix (the seam contract —
customer chooses among supported substrates), its telemetry contract,
and how PCS reaches into it via plugins. Order (canonical short codes
per `https://github.com/fiducial-mesh/devel/blob/main/spec-drafts/PILLAR-NAMES.md`): **IBX** (Inbox Exchange — message
routing), **AKB** (Agent Knowledge Base — memory), **ACT** (Agent
Cognitive Telemetry — observation), **IAM** (Identity & Access —
foundational), **PGE** (Policy Guardrail Engine — deterministic
compliance enforcement), **CRB** (Compute Resource Broker — Go;
hardware-aware workload dispatch), **DPG** (Deterministic Proving
Ground — Go driver + adopted microVM; ephemeral isolation for code
execution), **MCC** (Mesh Control Center — operator UI binding the
whole thing).

### 4. Operations
How a Mesh runs in practice. Covers the **four flexibility axes** the
mesh is designed for (HA, scale, performance, OSS ‖ commercial) and
the **"run what you brung"** posture — deployment spectrum runs from
one-box hobbyist to 3 minis + 9975 to datacenter; the mesh adapts to
the substrate the customer has, not the other way around. Then:
**security framework**, **delivery and packaging** (Python default,
Go for CRB + DPG, no C# anywhere), the **AIR/CLCA discipline**
(incidents produce versioned workflow improvements, mechanically),
**how a customer extends the mesh without forking** (substrate matrix
× workflow composition — pillar code stays generic OSS, customer's
workflow encodes their substrate choice), the **agents-own-deployment
posture** (no human-following install procedures; agents read the
plugins and execute), the **documentation model** (Standard +
Handbook + user guide + workflow matrix per §4.7), and the
**dogfood story** (KI7MT lab as tenant #1).

### 5. Appendices
Reference material: glossary, language map per pillar, conformance
criteria, the five mesh-internal namespaces (deployment / configuration /
operations / administration / diagnostics), the PCS plugin manifest
reference, cross-pillar binding matrix, and citation list back to the
working notes (which remain in `https://github.com/fiducial-mesh/devel/blob/main/spec-drafts/` and `devel/spec-drafts/`
for provenance).

---

# Part 1 — The Mesh

## 1.1 What Fiducial Mesh is

A fiducial marker is a physical object used as an absolute, unyielding
point of reference. Fiducial Mesh provides exactly that for autonomous
AI workforces: **an absolute, deterministic architecture of trust**.

In one sentence: **the mesh composes human authority and agent capability
into a single governed, identity-rooted, auditable mesh** — because each
half alone solves only half the problem, and regulated sectors need the
whole.

It is built for deployment on highly secure, on-premises customer
infrastructure. Its purpose is to orchestrate, secure, and govern complex
collaborations among multi-agent AI workforces while ensuring absolute
data sovereignty and deterministic process control. **The mesh's own
pillars** are **air-gapped ready and exfiltration hostile** by
construction, not by configuration — pillar runtimes open no outbound
paths the operator did not provision. Sovereignty is not just *where*
the workloads run; it is whether the architecture can be operated
without trust-bearing paths to a counterparty.

The **agent-runtime / reasoning-model substrate** is a separate seam
(§1.5.1) — vendor-hosted reasoning (Claude Code, Codex) is the
operator's declared exception today, governed as a recognized
deviation with the data-flow consequence stated explicitly. A
genuinely air-gapped deployment runs sovereign local inference for
the reasoning runtime; the lab already runs the doer-tier local fleet
(Newton on 9975, Daina on the GPU host, Melody on M3). The "no
outbound path" claim above is **about the mesh's pillars**, not about
the agent-runtime substrate; conflating the two is the first thing a
hostile auditor reads for, and the HDBK names the gap explicitly
rather than glossing it.

## 1.2 The problem the mesh solves

Two failure modes drive every design choice in the mesh:

**A pure-agent mesh fails in regulated environments.** Accountability
must ultimately terminate in a person the law can hold responsible. You
cannot put an agent in front of a regulator, and "the model decided" is
not a defense a bank, a hospital, or a defense contractor can offer.
Autonomous capability without a human locus of accountability is
undeployable where the stakes are real.

**A pure-human process is the problem regulated organizations already
have.** It is too slow, too expensive, cannot scale to modern data
volumes, and cannot maintain perfect continuous audit. Human judgment is
irreplaceable at the decisions that matter — and ruinously inefficient
applied to everything else.

The mesh is the composition: agents supply superhuman capability and
tireless execution; humans supply irreplaceable judgment, legal
accountability, and final authority at the gates that matter. **The
invention is the governed seam between them.**

The alternative — Vendor-Mediated Architecture (VMA) — solves the
capability half by handing the trust-bearing layer to a counterparty
whose incentives are misaligned: cloud IdPs, vendor plugin stores,
managed vector databases, vendor safety filters. None of those vendors
has any structural reason to make sovereign deployment cheaper, more
durable, or easier to migrate. **A vendor whose product depends on
vendor lock-in is structurally misaligned to build vendor-neutral
infrastructure** — doing so erodes the moat that justifies their
valuation. (The general claim is incentive-misalignment, not
impossibility: Kubernetes is the standing counterexample of a
vendor commoditizing a rival's moat for strategic reasons. The
mesh's wager is that the AI-agent-platform space, today, looks
more like the IdP / vector-DB / safety-filter shape than the
Kubernetes-vs-AWS shape.)
The mesh is the sovereign alternative — owned hardware, owned identity,
owned audit, owned policy enforcement, no callbacks.

## 1.3 Design philosophy — the capability/constraint duality

The naive framing is "build for agents the governance a human
organization already has." That is the right north star but the wrong
precision. The sharper statement:

> **Give agents the superhuman capabilities humans lack, while
> engineering back in the safety constraints that human limitation
> provided for free — and manufacturing the identity and accountability
> that humans get from biology.**

This duality is the reason every pillar exists. Each pillar does one of
two things: it *grants a capability humans lack*, or it *re-imposes a
constraint that human limitation used to provide accidentally*.

**Where agents are weaker than humans — the mesh must manufacture what
humans have intrinsically:**

- **Identity.** A human carries intrinsic, hard-to-forge identity (face,
  body, DNA, continuous legal personhood). An agent has none by default —
  two instances are indistinguishable, and an agent can be cloned,
  spoofed, or impersonated trivially. The mesh must *issue* a
  cryptographic, verifiable, non-transferable identity per agent.
- **Continuity of accountability.** A human is one continuous accountable
  entity over time. An agent is ephemeral — spun up, torn down, stateless
  between calls. The mesh must pin durable accountability onto something
  that does not persist, via identity bound to immutable audit.

**Where agents are stronger than humans — the mesh must re-impose
constraints human limits provided for free:**

- **Memory, cognition, domain knowledge.** A human's bounded memory and
  knowledge are partly limitations — but they are also accidental safety
  features. A human loan officer cannot instantly read 200,000 borrower
  files; that friction is an unplanned privacy control. An agent can.
  Granting agents the memory and knowledge humans lack therefore *removes
  the accidental safety rails human cognitive limits provided.* The mesh
  must artificially re-impose what biology imposed naturally: need-to-know,
  role-bounded access, segregation of duties.
- **Enforced forgetting.** Human forgetting is sometimes a feature — data
  minimization and retention limits are *required* by several regimes.
  An agent's perfect persistent memory can violate retention rules by
  remembering too well. Memory must be designed to *forget on purpose* —
  retention limits, erasure, expiring context — not merely to remember
  well.

**The one-line consequence:** the mesh lets an organization have
superhuman capability *without* superhuman blast radius. The hard part
is not replicating human governance — it is governing entities that are
*more* capable than humans in exactly the dimensions where human limits
were quietly doing safety work.

### 1.3.1 Operating principle — *build to a spec, not spec to a build*

The duality describes *what* the mesh constructs. The operating
discipline that produces it is one sentence:

> **Build to a spec, not spec to a build.**

The naive failure mode in platform engineering is the inverse:
implementation ships first, documentation is reverse-engineered from
it, and that "spec" exists only to describe what the build already
does. The resulting document is description, not contract — it has no
authority to constrain a different implementation, no falsifiable
claims a third party can verify, and no defense against drift because
every change to the build is allowed to mutate the spec to match.

The mesh inverts this. The Standard (`FIDUCIAL-MESH-STD-001`) is
authored as authority: requirements precede implementation,
implementations conform to requirements, and divergence between an
implementation and the Standard is either fixed in the implementation
or registered as a recognized deviation in Appendix F per §F.2 — never
absorbed silently into a revised spec.

The discipline has three operational consequences:

- **The Verification line on every numbered requirement is the
  blueprint for the conformance harness.** A build that passes the
  per-requirement Verification tests is spec-conformant; a build that
  doesn't is spec-divergent and produces either a rebuild target or an
  argued-case / deviation entry. The harness is what makes the motto
  more than aspiration.
- **The Standard moves first.** When a new pattern is needed (a new
  pillar, a new deviation class, a substrate matrix extension), the
  spec changes first — through the argued-case discipline per
  `[FM-INV-0003.2]` for capability extensions, or through the
  catastrophic-class quorum path per `[FM-INV-0004]` for changes to
  the floor. Then implementations catch up.
- **Deviation machinery is honest, not absorptive.** When a
  deployment cannot meet a requirement (yet), the transitional clauses
  (`[FM-IBX-0010]`, `[FM-IAM-0014]`, `[FM-PGE-0005]` Gate-2,
  `[FM-ACT-0008]`, `[FM-DPG-0013]`, `[FM-CRB-0010]`,
  `[FM-MCC-0012]`) document the gap with a sunset condition and
  divergence-event emission. The deviation does not redefine the
  requirement; it acknowledges the gap until the gap closes.

**Honest bootstrap acknowledgment.** The motto is the steady-state
contract; it does not describe the project's current state cleanly.
A hostile reading is fair: several pillars were under construction
before their normative codification landed (IBX POC-in-production
predates `[FM-IBX-*]` numbered requirements; IAM code-complete
predates `[FM-IAM-0014]` operational-state declaration; MCC backend
BUILT precedes `[FM-MCC-0006]` plugin contract maturity). The PCS
whole-section debt that earlier tracked here — §6 absent as a
whole section — has since closed: **§6 PCS is authored** as the
eighth pillar with full Conformance Profile (`[FM-PCS-0001..0018]`),
so what remains is requirement-level / implementation gaps the
deviation machinery already covers cleanly. The
in-flight built pillars migrate under their declared transitional
deviations until each operational-state condition is met. The motto
does not yet describe today; it describes the steady state the
project is migrating toward, and the deviation discipline + §6
debt registration are how the gap is named without dissolving the
contract.

This is the discipline that turns the capability/constraint duality
into a contract a customer can hold the project to.

## 1.4 The agentic workforce — identity as the foundation

The duality above is realized through one organizing principle: **the
agentic workforce is a workforce.** Each agent is modeled as an
employee, and the employee lifecycle is the structural template:

- **Issuing authority** (ARCA — the "county clerk")
- **Employee ID** (the agent's public-key fingerprint, immutable)
- **The person themselves** (the private-key "DNA", never leaves the
  agent)
- **Job description** (the authorization policy)
- **Scoped credentials** (the agent's own SSH/API keys)
- **Manager** (the Judge gate)
- **Personnel file** (the audit ledger)
- **Offboarding** (credential revocation)

The HR mapping is exact for **structure** (identity, authorization,
audit, offboarding) — but never for **liability**: accountability
terminates in a human, never in the agent. Identity exists for
attribution and control, not legal personhood.

Identity is foundational because **without it, nothing else binds.** It
is the root of trust every other pillar is downstream of. Two
non-negotiable invariants govern it: **no bypass** (no action without an
authenticated principal — no "trusted because internal") and **fail
strict** (under error, ambiguity, unavailability, or unverifiable state,
the system halts).

The compliance regimes (SOX, HIPAA, FIPS, defense, finance) are
**designed to map cleanly** — they were written for
human-and-system organizations, and the mesh reconstructs the
accountability fabric they assume. The framing is deliberately
*not exotic*: a well-run regulated organization already is an
orchestration mesh of principals operating under identity,
authority, segregation of duties, audit, and escalation. The mesh
reconstructs that same fabric and makes agents first-class
principals within it. To an auditor, the design thesis is: **the
AI is held to the same standard of identity, authorization, and
auditability you already hold your employees to.**

**Honest open question — formal acceptance.** Whether a regulator
or audit firm actually accepts agent identities as principals
satisfying SoD / SOX-class controls is a **validation goal, not a
fact yet established**. No regulator has yet certified the
mapping; no audit firm has issued a SOC report against a
Fiducial-Mesh-managed agent fleet acting as a regulated principal.
The dogfood deployment (§4.8) is unregulated and therefore cannot
evidence the mapping by itself. The design is *intended to present
to an auditor in the vocabulary the regimes already use*; **formal
acceptance is one of the project's open hard parts** and a serious
regulated-industry CIO will treat it as such. The HDBK names the
gap rather than implying it's closed.

**Bound STD requirements.** The HR mapping is realized through the
IAM pillar's numbered contract: ARCA as offline issuance authority
per `[FM-IAM-0001]`; per-agent identity birth + lifecycle per
`[FM-IAM-0003]` and `[FM-IAM-0003.1]` (identity-permanent /
authority-mutable separation); Vault in-boundary signing per
`[FM-IAM-0006]` (the private-key "DNA" that never leaves the
boundary); the Roster as personnel file per `[FM-IAM-0007]`;
suspend / resume / terminate as offboarding per `[FM-IAM-0004]` and
`[FM-IAM-0005]`; the principal-type stamp per `[FM-IAM-0010]`; and
the identity-context contract per `[FM-IAM-0011]` (IAM provides
verified context; PGE makes the decision). The two non-negotiable
invariants — *no bypass* and *fail strict* — are `[FM-INV-0001]`
and `[FM-INV-0002]`; the fail-strict deadline anchored to every
external-ack point is `[FM-INV-0002.1]`. IAM operational-state
declaration (when the deployment exits the identity-by-brief
transitional deviation) is `[FM-IAM-0014]`.

## 1.5 Language policy

Open-source first. Sovereign by construction. Pragmatism over preference.

> **STD/HDBK boundary.** The Standard is **language-neutral at the
> contract layer** per `[FM-STD §1]` — pillar requirements shall not
> mandate the implementation language or framework of any pillar; the
> conformance test sets are language-blind, and a conforming
> implementation may be written in any language. **This Handbook
> section is the project's reference-implementation choice**, not a
> conformance requirement. A customer who insists on a different
> language stack implements the same numbered Standard requirements
> in their stack and is conformant on the same terms. The text below
> documents what *we* build to, not what *every* conforming
> implementation must build to.

**Python is the default.** Every pillar, every MCP server, every plugin
that doesn't have an argued reason to deviate is built in Python. The
default-Python rule keeps the substrate single-runtime, the dependency
surface manageable, and the agent-readable code uniform.

**Sanctioned deviations:**

- **CRB** is written in **Go** — hot concurrent broker; Go's concurrency
  primitives + GC characteristics fit the workload class Python doesn't.
- **DPG** is written in **Go driver + adopted microVM** — the driver
  layer needs the Go ecosystem for OCI / containerd integration; the
  microVM itself is adopted (gVisor / Kata floor), not built.
- **MCC-UI** is **JS/TS SPA** — browser context is the argued reason
  (the only language the browser runs natively). **MCC backend** is
  Python like everything else.

**The IAM pillar** is Python by default; an argued deviation may surface
later (crypto / PKI / FreeIPA integration may push to a different
runtime) but the case has to be made explicitly and decided, not assumed.

**No C# anywhere in the canon.** The earlier C#-spine assumption is
retired. The real rationale (the previously stated "doesn't fit
GPLv3 OSS posture" was wrong — .NET is MIT-licensed OSS): the
mesh's reference implementation chose **runtime uniformity** (one
language stack across the substrate keeps the dependency surface
manageable), **single agent-readable codebase** (the agents that
build and operate the mesh read one stack), and the **framework
reset** that landed during the 2026-06-08 PCS redesign moved
canonical components off C# as a deliberate simplification. C# is
not provisioned as a target language in the project's reference
implementation; the Standard remains language-neutral per §1, so a
customer who insists on C# implements the same numbered
requirements in their stack and is conformant on the same terms.
Source code in C# may be retained for reference where it exists in
the lab's history.

**The mesh-CLI / installer** is either a Go static binary OR is
"Claude Code + PCS plugins is the CLI" (per the Mesh-CLI delivery shape
in §2.13). The earlier .NET AOT mesh-CLI plan is retired with the
C#-spine.

The language map per pillar is enumerated in Appendix B.

## 1.5.1 Model / reasoning-runtime substrate

Language policy (§1.5) covers the substrate the *pillars* are written
in. There is a separate, equally load-bearing substrate seam: the
**reasoning-runtime** — the inference engine the agents themselves
run on. This seam is parallel to the pillar's persistent-store seam
or secret-store seam, and customers choose it the same way.

**The honest current state.** The lab and most operational mesh
sessions today route reasoning through **vendor-hosted models**
(Claude Code, Codex). For those sessions, **prompts and working
context — by definition the most sensitive content the mesh handles
at session time — leave the sovereign boundary and reach the
vendor**. The §1.1 air-gap claim covers the *mesh's pillars*; it
does **not** cover the reasoning-runtime substrate. Saying so plainly
is the honest baseline a regulated deployment evaluates against.

**The sovereign reference.** The intended sovereign substrate for
the reasoning runtime is **local inference** — a model that runs
inside the customer's trust boundary, with no callback. The lab
already operates the **doer-tier local fleet** (Newton on 9975, Daina
on the GPU host, Melody on M3) as the sovereign reference for the
doer agents; the escalation-tier (the cloud Opus / Codex agents that
do this design work) remains vendor-hosted under a recognized
deviation. A fully air-gapped deployment runs sovereign local
inference across both tiers; the lab's split is itself the
worked example of the transitional state.

**The vendor-hosted reasoning-runtime is a recognized deviation,
not the contract.** A deployment that operates with any vendor-
hosted reasoning is **operating under a deviation** that **shall**:

1. Be registered in Appendix F per §F.2 of the Standard with an
   explicit sunset condition naming the operational point at which
   the deployment migrates to local inference for that workload
   class.
2. Document the **data-flow consequence** — what content reaches the
   vendor, under whose identity, with what retention, and what the
   vendor's stated data-handling commitments are.
3. Be reviewed at each major Standard release; deviation expiry
   **shall** be enforced when the local-inference substrate is
   declared operational for the affected workload class.

A Standard-side requirement formalizing the **model substrate seam**
+ the divergence_type for vendor-hosted reasoning is queued as a
companion STD change (it is not yet in the STD; this Handbook
section is the rationale that the STD requirement will codify when
landed). Until it lands, the deviation discipline above is the
HDBK-level honest baseline; readers should not infer that the absence
of a numbered requirement means the seam isn't real.

**Why this matters more than language policy.** Language policy is
implementation choice — the conformance test set is language-blind.
The reasoning-runtime substrate is a *data-flow* choice; vendor-
hosted reasoning IS data egress, regardless of how careful the
prompt-engineering is. Hostile auditor day-one: *"You said
air-gapped. Where does the model run?"* — and the honest answer is
the one above.

## 1.5.2 Reference operating system

Open-source first. RHEL-compliant by gate. The same discipline as the
language policy: the Standard stays substrate-neutral at the contract
layer; this Handbook section documents what the project's reference
implementation runs on and the test it gates against.

> **STD/HDBK boundary.** The Standard does **not** mandate an
> operating system. The substrate-pluggability invariant per
> `[FM-STD §1]` and `[FM-INV-0005]` means the conformance test set is
> OS-blind; a conforming implementation may run on any operating system
> whose substrate seams satisfy the named test gates. **This Handbook
> section is the project's reference-implementation choice**, not a
> conformance requirement. A customer who runs the mesh on a different
> operating system implements the same numbered Standard requirements
> on their OS and is conformant on the same terms.

**The reference operating system is a RHEL-compliant distribution.**
"RHEL-compliant" is the contract: the distribution shall be binary-and-
ABI compatible with the corresponding Red Hat Enterprise Linux release,
shall track the same package set in the same versions, and shall pass
the standard RHEL-compliance test suite (the public Red Hat compatibility
test plan) for the release the deployment targets.

**Examples (open-source first):** Rocky Linux and AlmaLinux are the
free-and-open-source examples of the RHEL-compliant class; Red Hat
Enterprise Linux is the commercial example for shops that prefer the
vendor-supported path. Any RHEL-compliant distribution that passes the
gate is a valid reference choice; the test is on compatibility, not on
vendor.

**Why a RHEL-compliant gate, not a specific distribution name?** The
platform's substrate stack — Podman / DPG isolation runtime, FreeIPA
identity tier, the SELinux baseline the security profile assumes,
Vault / OpenBao + PKCS#11 HSM integration, the systemd lifecycle
contract — is engineered against the RHEL package set and security
model. Distributions outside the RHEL-compliant class can be made to
satisfy the same requirements, but the reference implementation does
not undertake the per-distribution work to verify each; it gates on
RHEL-compliance and treats anything passing the gate as substitutable.

**Why this lives in the Handbook, not the Standard.** A normative OS
mandate would couple the platform to a specific OS family forever and
break substrate-pluggability for adopters whose procurement does not
support the RHEL-compliant class. The Standard stays OS-neutral by
design; the Handbook documents the discipline the project's reference
implementation uses, which adopters may follow or replace per their own
substrate. This mirrors the language-policy split in §1.5.

**Platform appliances are scoped separately.** Reference-implementation
appliances that are not directory members and never will be (Proxmox
hypervisor, TrueNAS SCALE storage) carry their own embedded operating
systems and are placed beneath the mesh trust fabric as owned-hardware
substrate per `[FM-INV-0005]` (`hardware_custody = owned`). The
RHEL-compliant gate applies to the mesh hosts, not to the platform
appliances the mesh runs on.

## 1.6 The eight pillars + four planes

The mesh organizes eight pillars into four planes (see
`https://github.com/fiducial-mesh/devel/blob/main/spec-drafts/diagrams/mesh_architecture_with_identity_and_arca.svg` for
the visual contract):

```
                  ┌──────────────────────────────────────────┐
                  │         Issuance Plane (offline)         │
                  │              ARCA (IAM, root)            │
                  └──────────────────────────────────────────┘
                  ----- the dotted line — never in action path -----
                  ┌──────────────────────────────────────────┐
                  │              Control Plane                │
                  │  IAM (runtime) · PCS · PGE · CRB · IBX    │
                  │              + Judge (human)              │
                  └─────────────────────┬────────────────────┘
                                        │
                  ┌─────────────────────┴────────────────────┐
                  │              Compute Plane                │
                  │           Workforce + DPG                 │
                  └──────────────────────────────────────────┘
                  ┌──────────────────────────────────────────┐
                  │              State Plane                  │
                  │            AKB    ·    ACT                │
                  └──────────────────────────────────────────┘
```

**The Issuance Plane** sits above the dotted line. It is offline,
sovereign to the deploying organization, and never in the action path.
Its only role is to mint identities and step out. **ARCA** (Agentic
Root CA) is its only component — the per-organization root of trust for
agent identity per `[FM-IAM-0002]` (per-organization ARCA sovereignty).
The dotted-line separation is a deliberate security property, not
tidiness: because ARCA is never in the action path, it can be kept
offline, and an offline authority cannot be attacked over the network
during operation. Runtime verification is local (signature + trust
chain), never a callback.

**The Control Plane** is the authoritative governing body of the mesh.
Six elements:

| Element | Role |
|---------|------|
| **IAM (runtime half)** | identity verification + authorization. Beneath PGE — authorization consumes verified identity. |
| **PCS** | the action / management layer. Owns plugins, workflows, registry, validation. **Manages every other pillar via the plugin system**, including IAM. |
| **PGE** | deterministic policy enforcement. Double-guardrail — gates intent before IBX, gates execution inside DPG. |
| **CRB** | hardware-aware workload broker. Routes between unified-memory hosts and compute-host GPUs. |
| **IBX** | the message hub. Every Control-Plane pillar and the Judge gate route to Workforce *through* IBX. |
| **Judge (human)** | the human-in-the-loop approval gate for `action` / `urgent` priority messages — server-enforced at the IBX submission chokepoint per `[FM-IBX-0003]` (the gate cannot be opted out of by the message sender). First-class architectural element. |

**The Compute Plane** is where agent work executes:

| Element | Role |
|---------|------|
| **Workforce** | the bounded, named cluster of specialized agents (instances + singletons). |
| **DPG** | secure, ephemeral, isolated sandbox for code execution. Bridges stochastic reasoning and deterministic execution — agents may reason probabilistically; the code they emit is validated under deterministic conditions before it touches production state. |

**The State Plane** is the memory of the mesh — append-mostly substrates
that other planes write into and read from:

| Element | Role |
|---------|------|
| **AKB** | role-projected, tier-stratified knowledge retrieval. Bidirectional — agents query AKB; agents also propose curator-gated updates. |
| **ACT** | immutable, locally-hosted audit ledger. Unidirectional — Workforce and DPG emit telemetry; nothing flows back out except via curator review. |

**The whole stack rests on Customer Infrastructure** (sovereign,
air-gapped). Owned hardware, no cloud dependencies, no managed-service
substrate. Customer hardware shape varies (one-box hobbyist → 3 minis +
9975 → datacenter), but the architecture is the same in every case:
every pillar runs locally, every credential lives in OS-resident
stores, every byte of state stays inside the customer's trust boundary.

**Direction of control across the planes** flows outward from PCS. PCS
is the action layer that manages everything else; pillars stay
zero-coupled to PCS and remain standalone-installable. A pillar like
IBX or AKB runs correctly on its own — PCS reaches into each pillar via
its published interface (skills, MCP, hooks) and orchestrates from
outside. `pip install <pillar>` works with no PCS present.

**Bound STD requirements.** The pillar enumeration is the
8-pillar invariant per `[FM-MCC-0011]`: IBX (§5.1), IAM (§5.2),
PGE (§5.3), ACT (§5.4), AKB (§5.5), DPG (§5.6), CRB (§5.7), PCS
(§6). MCC (§5.8) is the **host frame**, not a ninth pillar. The
Issuance Plane's offline-ARCA / runtime-IAM separation is
`[FM-IAM-0001]`. PCS-as-action-layer-managing-every-pillar is the
MCC kernel/frame model per `[FM-MCC-0001]` (frame hosts pillars as
loadable modules) + `[FM-MCC-0004]` (centralized substrate handles)
+ `[FM-MCC-0005]` (IAM-first load order) — and the
zero-coupled-to-PCS / standalone-installable property is preserved
because pillars remain conformant against their own §5.x
requirements independent of MCC composition.

## 1.7 Foundational invariants

Three invariants govern every pillar and every workflow in the mesh.
They are not policy — they are architecture. Policy is the operational
ratchet within the bounds they define; it never widens them.

### 1.7.1 No bypass + fail strict (IAM Tier-0)

**No action, data access, or approval occurs without an authenticated
principal.** There is no "trusted because internal." Every actor —
human, agent, plugin, service — authenticates, every time. No standing
god-rights account, no caller trusted by location, no bootstrap path
that runs before identity is up.

**Under error, ambiguity, unavailability, or unverifiable state, the
system halts.** A principal that cannot confirm its credential is
valid stops. An action whose authorization cannot be resolved is
denied. When in doubt, stop.

These two clauses cannot be relaxed by policy. They are the load-bearing
floor every other guarantee in the mesh stands on.

**The "no bootstrap path that runs before identity is up" line has a
deliberate, bounded exception**: the **genesis event class** per
`[FM-INV-0004.5]` permits exactly three subtypes
(`mesh-init-quorum-bootstrap`, `iam-init-arca-root`,
`iam-init-roster-seed`) to land in ACT without IAM-`principal-id`
attribution, using holder-fingerprint attestation instead. The
carve-out exists because the identity system cannot bootstrap itself
under the unmodified rule — the founding ceremony has to create the
attribution chain it would otherwise need to reference. The carve-out
is closed (no other class qualifies), one-shot per subtype per
deployment lifetime, and re-issuance is catastrophic-class.

**Bound STD requirements.** No-bypass is `[FM-INV-0001]`; fail-strict
is `[FM-INV-0002]`; the fail-strict *deadline* anchored to every
external-ack point is `[FM-INV-0002.1]` (operator-configurable; shall
be strictly shorter than the minimum worker-pool lease window per
`[FM-IBX-0009]` so a lagging ack cannot race the lease and produce
duplicate execution). The genesis-event carve-out is
`[FM-INV-0004.5]`. ACT honors the carve-out per `[FM-ACT-0003]`'s
Genesis-event carve-out section + `[FM-ACT-0005]`'s Genesis-event
chain seeding section; every other event-emission path requires
full attribution.

### 1.7.2 Capability provisioning as primary defense

**Policy is a breach waiting to happen. If you don't want something
done, don't enable / provision the feature. Capability provisioning is
the primary defense; policy is the operational ratchet within the
already-bounded capability set.**

The natural enterprise-platform instinct is to provision a feature
broadly, then layer policy on top to restrict its use, then layer audit
on top to detect misuse. This produces platforms with broad capability
surfaces and rich policy languages — and a long tail of "honest
residuals" where policy defenses thin out: insider threats, key
compromise, supply-chain attacks on the policy authoring pipeline
itself. **Those residuals are not gaps to mitigate with more policy.
They are provisioning mistakes.** The right move on each is to engineer
the capability out, not the policy in.

The mesh already follows this principle implicitly at every pillar:

- **Air-gap by construction** (§1.1) — the mesh's own pillars open
  no outbound paths the operator did not provision; the policy
  "agent can't make outbound calls" isn't needed because the path
  isn't there to take. The reasoning-runtime substrate (§1.5.1) is
  a separate seam handled by its own deviation discipline, not by
  the pillar-side air-gap.
- **C# purged from the canon** (§1.5) — we don't policy "no C# in
  production"; C# isn't provisioned as a target language.
- **DPG ephemeral isolation** (§3.7) — we don't policy "execution
  state shouldn't persist between runs"; the sandbox is destroyed.
- **Mesh-internal registry, not public** (§2.10 / §2.8) — we don't
  policy "no anonymous publishers"; anonymous publish has no capability path.
- **Cardinal rule** (§2.3) — we don't policy "stick to vendor plugin
  formats"; PCS plugins ARE vendor plugins. There's no separate "Mesh
  plugin format" surface to subvert.
- **No-callbacks runtime verification** (§1.2) — we don't policy
  "don't phone home"; there is no phone-home substrate.

**The test for new architectural decisions** per `[FM-INV-0003.3]`.
When a new capability is proposed, the first question is: *"Do we
want anyone — anywhere, ever — to be able to do this?"*

- If no: don't provision it. Policy can't make it safer than not existing.
- If yes: policy gates who can do it, under what conditions, with what audit.

**Resolution against the open-extension model.** The mesh ships an open
extension surface (PCS plugins, the cardinal rule, marketplaces) which
could appear to contradict capability minimization. It does not.
**Extension composes within the provisioned capability surface; net-new
capability requires the argued-case + quorum path.** Concretely:

- Pillar implementations and their substrate matrices define the
  capability surface; the maintainer provisions each with an argued case
- Plugins compose within that surface — they invoke skills / hooks /
  MCP servers / agents the pillars already expose
- An MCP server in a plugin is **targeted** to be bounded by PGE
  policy (allowed tools), DPG sandbox (execution boundary), and IAM
  scope (calling agent's authority) — when DPG-hosted MCP execution
  is operational, the MCP server runs inside the boundary and the
  containment claim holds. **Present gap, explicit:** today MCP
  servers run as host-resident processes with host capability (the
  lab's 14-server fleet is the precedent), and DPG itself operates
  under the `subagent-worktree-precursor` transitional deviation per
  `[FM-DPG-0013]`. Until DPG-hosted MCP execution lands, the
  containment is provided by the plugin manifest's `policy:`
  declaration (per §2.4) + the validation harness review + PGE
  intent-side enforcement at IBX submission per `[FM-PGE-0005]`
  Gate 1 — execution-side Gate 2 sunsets when `[FM-DPG-0005]` is
  operational
- Workflows compose plugins — same containment, no net-new capability
- Net-new capability at the platform level (new pillar, extended
  substrate matrix, new agent surface) requires an argued case at the
  maintainer level and quorum at the apply step (per §1.7.3)

This invariant inverts the "feature-then-policy" default that produces
most enterprise breaches. Mesh's first line of defense at every pillar
is the absence of the capability, not the presence of the policy.

**Bound STD requirements.** Capability-provisioning-as-primary-defense
is `[FM-INV-0003]`. The extensions-compose-within-the-provisioned-
surface rule is `[FM-INV-0003.1]`. Net-new capability requires the
argued-case + quorum path per `[FM-INV-0003.2]`; the argued-case
entry schema is §F.1 of the Standard's normative Appendix F.

### 1.7.3 Quorum authority for catastrophic-class capabilities

**For any capability whose mis-use would be catastrophic, the mesh
distributes the authority across independent identities — by
architecture, not by policy.** Single-identity wielding of such
capabilities is **non-conformant by construction**: a single
identity attempting the operation produces only one attestation,
the verifier counts attestations, and the operation does not apply
without K-of-N.

The pattern is **K-of-N signed attestations enforced by an
independent verifier** — multi-signature authorization, structurally
parallel to the Vault unseal model. K-of-N independent identities
must independently sign attestations before the verifier applies the
operation; each attester holds their own signing key (their own
keyring or HSM; never shared storage), and each is a different
human role (CISO / CCO / GC / CTO / Security Officer / etc.). A
compromise of any single identity yields at most one attestation;
the verifier still requires the remaining K-1.

The mesh-init quorum-bootstrap ceremony per `[FM-INV-0004.4]`
**does** use Shamir's Secret Sharing for the quorum-authority
master at initialization — that's where the literal shard splitting
lives. Runtime operations (apply / revoke an overlay, mass identity
action, ARCA revocation) use the multi-signature attestation pattern,
not shard reconstruction. The HDBK does not conflate the two; the
init-time ceremony is shard-based, the runtime gate is
attestation-counting. A compromised verifier proceeding without
sufficient attestations is a runtime-side defect classified per
`[FM-INV-0005]` (platform enforcement floor is authoritative) — not
something the multi-signature pattern itself defends against;
verifier integrity is the load-bearing assumption stated explicitly.

**Capabilities in this class** (non-exhaustive):

- Applying or revoking a PGE policy overlay
- Revoking the ARCA root CA
- Minting a new overlay-author identity
- Rotating the trust-root key chain
- Mass identity action (e.g., revoking the entire workforce)
- Substrate decommission or irreversible data destruction

**Mechanism**: implementation rides existing mesh primitives — the
Quorum-Voter agent archetype (independent identities, not sessions of
one), PCT (Principal Control Token in IBX carries signing identity per
attestation), ACT (each attestation is an independent immutable audit
record), and IAM identity lifecycle (mint / suspend / resume /
terminate handles quorum member rotation). PGE Judge-gate is the
consumer: it refuses to apply the operation until K-of-N attestations
are present.

**Asymmetric thresholds.** Apply (arming) is harder than revoke
(firing). Apply requires a higher K (e.g., 4-of-5); emergency revoke
allows lower (e.g., 2-of-5) so rollback isn't blocked by
quorum-coordination overhead. Hard to ARM the system; lower
threshold to fire it (revoke is 2-of-5 by default, not literally a
single trigger — fewer attestations than apply, but still K-of-N
multi-signature, not unilateral).

**Time-bounded attestation windows.** An attestation expires if K-of-N
isn't reached within an operator-configured window. Prevents stale
approvals being held in reserve.

**Role-typed quorum.** Some operations require *specific* roles in the
quorum, not just any K-of-N. HIPAA overlay apply may require the
HIPAA-compliance-officer identity *in* the K set, not "any 4 quorum
members."

**Bootstrap at mesh init.** Initial quorum is minted at mesh
initialization (parallel to `vault operator init`). From that point on,
quorum-gated operations — including modifications to quorum
membership itself — require existing quorum.

**Platform enforcement floor is authoritative and independent of plugin
self-declaration.** A plugin's `.pcs/plugin.pcs.json` policy block
(§2.4) may *declare* the operations it considers `judge_gated` or
`quorum_required`, but the **platform's enforcement is not bounded by
the declaration.** PGE's judge-gate and §1.7.3's quorum-class apply to
every operation the platform classifies as catastrophic-class,
regardless of whether the plugin declares it. **Absence of declaration
is not absence of constraint.** Three corollaries follow:

- **Default-deny on declaration omission** per `[FM-INV-0005.1]`.
  A plugin that does not declare a `judge_gates` or `quorum_required`
  field does not thereby acquire permission to perform those operations
  without the platform's gates. Absent ≠ safe; absent = unspecified,
  and the platform applies its floor.
- **Divergence is a signal.** When a plugin's declared policy diverges
  from the platform's enforcement (plugin claims an op needs no judge
  gate; platform enforces one anyway), the divergence is logged to ACT
  as a discrete audit event. The plugin author and the operator both
  receive the signal; over time, repeated divergence is a CLCA
  trigger.
- **Granularity covers all dangerous operations** per
  `[FM-INV-0005.3]`. Catastrophic-class is the headline list (§1.7.3);
  judge-gating and quorum-enforcement cover the broader surface of
  state-affecting operations PGE policy classifies as requiring
  approval — not just the named catastrophic set.

This is capability-minimization (§1.7.2) applied recursively to the
policy substrate itself: the plugin's declaration is a *hint to
authors and consumers*, not an *enforcement contract*. The platform
floor cannot be opted out of by omission, weakening, or silence.

**Bound STD requirements.** Catastrophic-class quorum authority is
`[FM-INV-0004]`, decomposed as: asymmetric apply-vs-revoke thresholds
per `[FM-INV-0004.1]`; time-bounded attestation windows with the
clock-skew tolerance discipline (authenticated time source, verifier-
side expiry evaluation, asymmetric larger tolerance on the revoke
path) per `[FM-INV-0004.2]`; role-typed quorum membership per
`[FM-INV-0004.3]`; bootstrap at mesh init per `[FM-INV-0004.4]`; and
the genesis event class that makes mesh-init emittable to ACT
without a circular dependency on the identity system it brings into
existence per `[FM-INV-0004.5]`. The platform-enforcement-floor
discipline (the "declaration is a hint, not a contract" paragraph)
is `[FM-INV-0005]` (the floor is authoritative), `[FM-INV-0005.2]`
(divergence between declaration and enforcement is auditable),
`[FM-PGE-0005]` (the double-guardrail — IBX intent gate + DPG
execution gate), `[FM-PGE-0010]` (PGE applies the floor regardless
of plugin self-declaration), and `[FM-PGE-0011]` (`divergence_type`
discriminator + the 8 active subtypes registered in its
canonical-emitter table, including `policy-block-mismatch` which
covers the divergence-as-signal pattern).

---

## 1.8 How to read the rest of this Handbook

The spec is one document, organized top-down with PCS as the central
theme:

- **Part 2 (PCS)** is the longest part. PCS is the operational core —
  the action layer that turns the substrate pillars into a platform.
  Read this first if you want to understand what makes Fiducial Mesh
  different from a collection of independent services.
- **Part 3 (The Pillars)** is the substrate pillars PCS manages. Each
  pillar gets a chapter — what it does, what substrates it supports
  (the seam contract — customer chooses), what telemetry it emits,
  how PCS reaches into it.
- **Part 4 (Operations)** is how a mesh runs in practice — the
  flexibility axes, security framework, delivery, the AIR/CLCA
  improvement engine, customer customization without forking, the
  dogfood story.
- **Part 5 (Appendices)** is reference material — glossary, language
  map, conformance criteria, namespace inventory, plugin manifest
  reference, cross-pillar binding matrix.

The three foundational invariants in §1.7 govern every pillar and
every workflow in the parts that follow — and are codified
normatively in STD-001 §4 (`[FM-INV-0001]` through
`[FM-INV-0005]`). Where the rest of this Handbook describes specific
mechanisms, the invariants are the floor those mechanisms cannot go
below; the STD requirements are the contract that gates conformance.

**Working notes preserved for provenance** — design dialogue, AIR
reports, draft material that produced the Standard + this Handbook
— remain in
[`devel/spec-drafts/`](https://github.com/fiducial-mesh/devel/tree/main/spec-drafts).
They are not part of the canon; the canon is STD-001 + this Handbook.

---

# Part 2 — PCS (Platform Control System)

> **STD status of this Part.** PCS is the **eighth pillar** per
> `[FM-MCC-0011]` and lives in Standard **§6**, which is **written**:
> the numbered PCS requirements (`[FM-PCS-0001..0018]`) are normative.
> This Handbook Part is the rationale and design intent behind what §6
> normatively specifies. Cross-references
> in this Part point at the *cross-pillar contracts PCS already binds
> to* (FM-MCC, FM-PGE, FM-DPG, FM-AKB, FM-INV) — those bindings are
> in force today, and §6 — now written — normatively codifies the
> action-layer mechanisms this Part describes (`[FM-PCS-0001..0018]`).
> What remains is the PCS *implementation* built to that spec.

## 2.1 What PCS is

**PCS is the action layer of the mesh.** Other pillars supply *what
the mesh can do*; PCS supplies *how it does it*. Without PCS, the
pillars are independent services; with PCS, they compose into a
platform a customer can run.

**Control flows outward: PCS → pillars.** PCS reaches into each pillar
via its published interface (skills, MCP, hooks) and orchestrates from
outside, like Terraform/Ansible. Pillars do NOT plug into PCS; they
stay zero-coupled and standalone-installable. `pip install <pillar>`
works correctly with no PCS present. The mesh is one OSS baseline plus
N customer workflows, not N customer forks.

## 2.2 Plugin-loadout = agent role

> **The loaded plugin set is what makes a session agent-as-{installer,
> administrator, operator, diagnostician}.** Same harness, same LLM,
> different loadout → different role.

Five mesh-internal namespaces map to five composable role-loadouts:

| Namespace | Loadout makes the agent a … |
|-----------|----------------------------|
| `fiducial-mesh-deployment` | installer |
| `fiducial-mesh-configuration` | configurator |
| `fiducial-mesh-operations` | operator |
| `fiducial-mesh-administration` | administrator |
| `fiducial-mesh-diagnostics` | diagnostician |

Loadouts compose. Tenant namespaces (`qso-graph`, `ionis-ai`,
`<customer-X>`) work the same way — a tenant loadout makes the agent
capable of operating that tenant's tooling.

**Agents are employees; the role is the toolset granted.** Capability
lives in the plugin; authority lives in the identity. The plugin says
what can be done; IAM says who can do it. Loading the deployment plugin
doesn't grant deployment authority — it equips an authorized agent with
the deployment toolset.

## 2.3 The cardinal rule

> **A PCS plugin is a strict superset of an Anthropic Claude Code
> plugin AND an OpenAI Codex plugin. Every PCS plugin MUST validate as
> a valid plugin under both vendor specs before any PCS-specific
> governance is applied.**

Every downstream value-prop (portability, vendor-marketplace
projection, "operator picks their IDE", "manager on Desktop") chains
back to this gate. Without it, those claims are empty.

This works because agents have a grain. Their native vocabulary is MCP
and the plugin frameworks. Speak to them in that vocabulary, no
translation layer, everything downstream follows.

**Free targets:** Copilot CLI (GA'd Feb 2026) and Copilot Coding Agent
both consume the same `skills/`, `hooks/`, `.mcp.json` shape via the
open Agent Skills standard (`agentskills.io/specification`); Copilot
CLI even reads `.claude/skills/` directly. A PCS plugin targeting
Claude Code + Codex gets these for free.

**Out of scope:** VS Code Chat participants (separate extension
manifest) and the Copilot Extensions API (remote HTTP-service +
GitHub App backend). Different artifact models, deliberately not
targeted.

**Vendor-spec divergence — the honest hard part of the cardinal
rule.** The cardinal rule depends on two evolving proprietary
specs (Claude Code, Codex) staying compatible enough that
"strict superset of both" remains satisfiable. Three real risks
the HDBK names rather than assumes away:

1. **The two vendor specs can conflict** — same configuration
   path, different semantics; a feature in one not in the other;
   incompatible MCP transport changes. When that happens, the
   "validates under both" gate becomes unsatisfiable for the
   affected artifact class.
2. **Vendor spec drift is an external forcing function** on a
   platform whose §1.2 thesis is that those exact counterparties
   have misaligned incentives. The cardinal rule rides their R&D
   for free *and* inherits their roadmap changes for free —
   including changes that work against the mesh's portability
   claim.
3. **Tier-0 (the harness's hard gate per §2.7) executes
   third-party vendor tooling** that changes without mesh review.
   That's a supply-chain seam *inside the validator* — every Tier-0
   pass implicitly trusts the vendor's current validator state.

**The arbitration discipline.**

- **Vendor tooling versions are pinned in the BOM** (per §2.8) —
  the BOM declares which vendor-CLI version Tier-0 delegates to,
  so the mesh validator behavior is reproducible at the BOM
  version. An untested vendor-CLI version is not a Tier-0 input.
- **Conflict-arbitration rule when the strict-superset becomes
  unsatisfiable**: the affected artifact class falls back to a
  declared **per-vendor variant** for that class only (e.g., the
  agent definition emits separately to `.claude/agents/*.md` and
  `.codex/agents/*.toml` with the divergent semantic encoded per
  vendor). The rule of thumb: when conflict appears, **the cardinal
  rule yields first**, the project ships the divergent class as
  per-vendor variants, and the conflict is registered in Appendix
  F of the affected pillar's deployment as a deviation against the
  cardinal rule until upstream reconciliation lands.
- **Vendor-spec-drift surveillance** is operator-side: each new
  vendor-CLI release goes through a BOM-bump review before becoming
  the Tier-0 default; the validator behavior delta is documented
  and reviewed.

This is not the project's preferred state — the cardinal rule's
value depends on the superset being satisfiable. But pretending the
divergence cannot happen is exactly the over-claim a hostile
auditor exploits; naming the arbitration up-front is what makes the
discipline survive contact with vendor reality.

## 2.4 Plugin shape and addressing

Containment runs top-down: **Namespace ⊃ Plugin ⊃ Workflow**. Plugin
is the unit of distribution; workflow is the unit of operation;
components (skills, hooks, MCPs, agents, runbooks) are units of
capability that workflows compose.

**On-disk layout** — PCS extends the vendor common core without
modifying it:

```
fiducial-mesh-deployment-vault-management/
├── .claude-plugin/plugin.json    ← Anthropic-owned, verbatim
├── .codex-plugin/plugin.json     ← OpenAI-owned, verbatim
├── .pcs/                         ← PCS extension territory
│   └── plugin.pcs.json           ← provenance, signature, BOMs, policy block
├── workflows/                    ← PCS extension (not vendor-claimed)
├── skills/<name>/SKILL.md        ← open Agent Skills standard
├── hooks/hooks.json              ← vendor-defined
├── .mcp.json                     ← vendor-defined
├── agents/<name>.{md,toml}       ← dual-emit Claude+Codex
└── README.md
```

Plugin validates as a Claude Code AND Codex plugin out of the box.
Vendor tooling sees a normal plugin; PCS tooling sees plugin + PCS
metadata.

**Coordinate format** — Maven-style hierarchical:

```
<namespace>:<artifact>:<version>
fiducial-mesh-deployment:vault-bootstrap:1.4.2
qso-graph:spotter:2.1.0
```

Forward-domain kebab-case, NuGet-style prefix reservation enforced by
the registry, DNS-backed at tenant onboarding. Vendor marketplace
projection flattens to fit vendor flat-namespace constraints
(`fiducial-mesh-deployment-vault-bootstrap`).

**Granularity:** many small focused workflows per plugin, not
mega-workflows. A vault-management plugin ships `vault-install`,
`vault-unseal`, `vault-rotate-cert`, `vault-pki-bootstrap` — pick the
one you need.

**Declared capability surface — the `policy:` block.** The plugin's
PCS manifest (`.pcs/plugin.pcs.json`) carries a top-level `policy:`
block that declares the plugin's entire capability surface in one
auditable place: tools exposed, sandbox mode required, network access
needed, hooks fired, identity scopes accepted. This serves the
capability-minimization invariant (§1.7.2) directly — the validation
harness reads this single declaration and gates entry; one place to
audit; one place to deny. The pattern is borrowed from OpenAI Codex's
`requirements.toml` consolidation; the mesh adopts it because it
serves capability minimization better than a surface split across PGE
policy + DPG sandbox config + plugin manifest. Concrete schema lives
in Appendix E.

**The `policy:` block is a declaration, not an enforcement contract.**
Per §1.7.3, the platform enforcement floor is authoritative and
independent of plugin self-declaration. A plugin cannot opt out of
judge-gates or quorum-class controls by omitting the corresponding
field — absent ≠ safe. PGE applies its floor regardless; divergence
between plugin declaration and platform enforcement is logged to ACT
as a CLCA signal.

**Bound STD requirements.** The cardinal rule (PCS plugin as
strict superset of vendor plugins) is the design intent §6 now
codifies as `[FM-PCS-0001]` (cardinal rule — strict superset of
vendor plugins); the analogous already-numbered surface is the MCC
plugin contract per `[FM-MCC-0006]`. The platform-enforcement-floor paragraph above
binds to `[FM-INV-0005]` (the floor is authoritative),
`[FM-PGE-0010]` (PGE applies the floor regardless of declaration),
`[FM-INV-0005.2]` (divergence between declaration and enforcement
is auditable), and `[FM-PGE-0011]` (the `divergence_type`
discriminator with `policy-block-mismatch` as the canonical subtype
for this case — emitted by PGE per the discriminator table).

## 2.5 Plugin portability across surfaces

The plugin author writes once; the PCS toolchain projects per-surface:

| Surface | Install behavior | Scope |
|---------|------------------|-------|
| Claude Code (CLI) | Full plugin install | Primary |
| Codex (CLI) | Dual-emit Codex manifest, full install | Primary |
| Claude Desktop | Extract MCP servers, write `claude_desktop_config.json` | Projected (MCP slice) |
| Claude Web (claude.ai) | Register MCPs via Anthropic MCP integration | Projected (MCP slice) |
| Copilot CLI | Same plugin files consumed directly | Free via Agent Skills |
| Copilot Coding Agent | `.github/skills/` + `.mcp.json` | Free via Agent Skills |
| VS Code Chat participants | Separate `package.json` codegen | Out of scope |
| Copilot Extensions API | Remote HTTP service + GitHub App | Out of scope |

Non-dev users (managers on Desktop, analysts on Web) get the same
workflows as CLI users — they consume the MCP slice. Enterprises can't
mandate one IDE; PCS spans all of them with one source artifact.

## 2.6 Workflows — anatomy, lifecycle, pinning

A workflow is a composed, parameterized, version-controlled operation
— the unit a customer or user asks for.

Workflow declares parameters (env, identity, version pins), lifecycle
phases (pre-check → execute → post-validate), component pins (exact
versions of skills/hooks/MCPs/agents), dependencies, and provenance
(AIR/CLCA references when applicable).

**Authoring:** user says "for project X, I need a workflow for managing
nginx"; agent composes the workflow manifest, declares parameters,
pins components; validation harness gates entry to the registry;
registry catalogs and signs; workflow is available.

**Pinning is mandatory.** Every workflow version is immutable.
Reproducibility is non-negotiable.

**Lifecycle states.** A workflow version moves through explicit
states, each transition a signed event in the audit log:

```
Draft → Validating → Validated → Published → Deprecated → Withdrawn → Archived → Purged
              ↓ (fail)                                ↑ (emergency from any active state)
            Failed → back to Draft
```

| State | Resolvable by consumers? |
|-------|--------------------------|
| Draft / Validating / Failed / Validated | No |
| Published | Yes |
| Deprecated | Yes (with warning) |
| Superseded *(relation, not state)* | Yes (with migration hint) |
| Withdrawn | Yes (legacy resolution only) |
| Archived | Yes (explicit pinning only) |
| Purged | No (bytes deleted; audit-log entry remains) |

**RHEL cadence.** A workflow Deprecated within a BOM release lifetime
is Withdrawn at the next major BOM version. Same pattern as RHEL 9 →
RHEL 10: "deprecated in 9 is gone or replaced in 10." Customers pinned
to the older BOM keep resolving the workflow; the new BOM doesn't
include it. BOM versions are the cleanup boundary.

**Audit trail is permanent.** Even Purged workflows leave a signed
footprint — who created, validated, published, deprecated, withdrew,
purged, and when. Bytes can go; history stays.

## 2.7 Validation harness — tiered

Tier 0 is the hard gate; everything above is value-add.

| Tier | Checks | Gate or badge? |
|------|--------|----------------|
| 0 — Vendor base | Validates as Claude Code AND Codex plugin (delegated to vendor tooling) | **HARD GATE** |
| 1 — PCS Core | `.pcs/` valid, signature chain, declared workflows + BOM refs | **HARD GATE** |
| 2 — Cross-vendor portability | Both manifests emit cleanly; component variants present | Badge |
| 3 — Workflow conformance | Parameter contracts, lifecycle valid, refs resolve | Badge |
| 4 — Operational | Security scan, signature freshness, runtime smoke | Badge |

Delegating Tier 0 to vendor tooling means PCS gets vendor spec updates
for free; no reimplementation. The harness earns the trust once;
every conforming artifact inherits it.

**Bound STD requirements.** The validation harness's Tier-1
"PCS Core" hard gate is the surface §6 now normatively specifies
(`[FM-PCS-0008]` tiered validation harness). The harness's mandatory **execution-side validation
gates** for executable artifacts are already numbered in the DPG
pillar: `[FM-DPG-0004]` (four mandatory validation gates —
Syntax + PGE + test-suite + resource-limit attestation) and
`[FM-DPG-0005]` (PGE Gate-2 — PGE rule corpus executed inside
the DPG ephemeral boundary as the second guardrail). The
"validation harness earns trust once" framing maps to
`[FM-DPG-0008]` substrate substitutability via Exit Test —
identical containment outcomes across every conformance-claimed
substrate.

### 2.7.1 Where the formal proof ends — the Thompson trust-boundary axiom

The tiered harness is the strongest trust posture *software can
provide* given closed-source vendor tooling in the validation
chain. Tier-0 delegates parsing to the BOM-pinned vendor CLIs
(Claude Code, Codex) inside a DPG-grade ephemeral boundary; the
pre-isolation lexical gate kills the work-factor-amplification
DoS upstream of that boundary; the empirical N≥2 +
environment-indistinguishability defense in DPG raises the bar
on supply-chain payloads that try to behave-switch when they
detect testing. Stack the layers and the formal contract this
Standard provides is *closed* — up to one irreducible boundary.

That boundary is Ken Thompson's, named in *Reflections on
Trusting Trust* (1984): a malicious compiler can recognize a
validation environment and emit benign telemetry while
compiling malicious runtime behavior into the binaries it
produces. No purely-software analysis of those binaries can
detect the deception, because the analysis tooling was itself
compiled by the same chain. The supply chain terminates at
silicon and the compiler that built the tools — *not* at the
last gate the harness can run.

`[FM-PCS-0008]` names this explicitly as the **trust-boundary
axiom** of the mesh. The architecture has pushed the boundary
as far out as software can reach:

- **BOM-pinning** (`[FM-PCS-0013]`) bounds the attack surface
  to a specific, named, deployment-reviewable set of binaries —
  not "whatever the vendor ships at evaluation time." A
  compromised vendor release does not automatically infect a
  Mesh on a pinned older version.
- **Tier-0/1 ephemeral isolation** (`[FM-DPG-0002]`) bounds the
  *blast radius* of any compromised tooling to the per-
  evaluation ephemeral boundary. The boundary is single-use
  and destroyed after every evaluation; a compromised vendor
  CLI cannot persist past the boundary's destruction and
  cannot reach the harness host or production state.
- **Empirical N≥2 + environment-indistinguishability**
  (`[FM-DPG-0010]`) is the Volkswagen-emissions-class defense
  codified — a supply-chain payload that tries to defect only
  in production has to defect without being able to
  distinguish test-run-K from production-run, since the
  substrate makes the runs bit-identical from inside the
  boundary.

What this Standard cannot do is *replace* trust in the
underlying compiler chain with a formal proof. Deployments
requiring guarantees beyond the axiom must procure the
relevant binaries from reproducible-build pipelines
bootstrapped on trusted hardware and audited source —
disciplines outside the scope of this Standard. The Standard
names the boundary so the operator knows where the formal
proof ends and physical-axiom trust begins; it does not
pretend the boundary is closable in software.

This is the chain-close on the multi-pass review of v1.0: the
mesh contract is closed against the architectural failure
modes a first-principles read can produce — Confused Deputy,
CAP/FLP, Halting, Observer Effect, Amdahl, Capability
Revocation, Charron-Bost — and explicitly named against the
one bedrock limit that physics-of-computation says cannot be
closed in software.

## 2.8 The registry, marketplaces, BOMs

**Mesh-internal, not public.** Each Mesh runs its own PCS registry.
PCS does not operate a Maven-Central-for-the-world. Trust model is
bounded per-instance — every publisher is a known onboarded identity.
Cross-mesh namespace collisions don't exist (registries don't
federate).

**Catalog model — Maven Central pattern.** Single hierarchical
catalog (namespace : artifact : version) backing multiple flat
marketplace projections.

**Prefix reservation — NuGet pattern, DNS-backed.** Mesh maintainers
reserve `fiducial-mesh-*`; tenants reserve their prefix at
onboarding. Anyone publishing under a reserved prefix without the
matching key → validation rejects. Identity proves DNS control via
ACME / Sigstore patterns over the mesh's Vault PKI.

**Provenance.** Every artifact carries a signed attestation chain
anchored to Vault PKI. Verification is local; never a callback. A
per-mesh signed append-only log gives tamper-evidence within the mesh
(Go `sum.golang.org` pattern, scoped to one mesh).

**Marketplace projections.** One registry projects multiple endpoints:

| Projection | Serves |
|------------|--------|
| `fiducial-mesh-deployment@marketplace` | just the deployment namespace |
| `fiducial-mesh@marketplace` | umbrella over all five `fiducial-mesh-*` |
| `<tenant>@marketplace` | tenant slice only |

Operator runs `claude plugin marketplace add fiducial-mesh@marketplace`
and gets the full operator loadout.

**Default manifest + tested variations — BOMs.** The OSS deliverable
is a known-good baseline catalog, not a free-for-all. Three concentric
levels:

| Level | Tested by | Stability |
|-------|-----------|-----------|
| Default manifest | Mesh maintainers, exhaustively | Rock-solid |
| Tested variations (e.g. Mesh-with-Oracle) | Mesh maintainers, with test plans | Supported |
| Customer-specific workflows | Customer | On the customer |

BOMs are versioned signed artifacts that pin a coherent plugin set:

```
fiducial-mesh:default-mesh-bom:2026.06
fiducial-mesh:default-mesh-bom-oracle:2026.06   # variation
```

A customer installs from a BOM; upgrades happen by bumping the BOM
version, pulling every constituent plugin atomically. Linux distro /
`kubeadm` / Helm chart pattern.

**Upstream-distribution trust bootstrap (the supply-chain hard
part).** The local-verifier / no-callback property covers the
*customer's own* mesh registry — within a deployment, every artifact
is signed against that deployment's Vault PKI and verifiable
locally. **It does not cover how the customer comes to trust the
public reference plugins (`fiducial-mesh-*` namespaces) in the
first place.** That trust has to be bootstrapped, and the
bootstrap is a real supply-chain seam the hostile auditor reads
for first:

- **Project signing root.** Public reference plugins are signed by
  a **project-level signing root** maintained by the Fiducial Mesh
  Group; the public key is published with the project's release
  artifacts and pinned in the customer's mesh registry at
  onboarding. The customer's verifier then validates downstream
  plugin signatures against the pinned project root, locally, no
  callback.
- **Pinning ceremony.** The pinning step itself is a one-time
  trust-on-first-pin ceremony — the operator confirms the project
  root fingerprint against an out-of-band channel (the project's
  GitHub release page, the published key fingerprint in the project
  README, a printed fingerprint in the release announcement). After
  pinning, the trust is local; before pinning, the trust is on the
  operator verifying the fingerprint correctly. This is the
  irreducible bootstrap step; the HDBK names it explicitly rather
  than glossing it.
- **Key rotation.** A project-root key rotation is itself a
  signed-by-old-key announcement plus a new key fingerprint; the
  customer's registry pins the rotation event and trusts forward
  from the new key. Rotation cadence is operator-configurable; the
  project's recommended cadence is annual.
- **Key compromise.** If the project signing root is compromised
  (worst case), every customer's registry pins are invalidated and
  the project publishes a new root through every available
  out-of-band channel. Customers re-pin from the new root. There
  is no automatic recovery — a project-root compromise is a
  catastrophic-class event that puts every downstream customer
  into a re-pinning ceremony. The HDBK names this honestly rather
  than implying the local-verifier model eliminates supply-chain
  risk.

**Bound STD requirements.** Every artifact entering the registry
passes through DPG validation for executable artifacts per
`[FM-DPG-0009]` (Registry-bound executable validation) — the
PCS-Daemon pre-promotion state invokes DPG; the Daemon shall not
bypass DPG for executable workloads. This is the dev-to-production
trust boundary applied to executables. The upstream-distribution
trust bootstrap above sits *above* the per-deployment registry —
it's the seam between the project's public artifacts and the
customer's pinned local trust state. STD §6 codifies the
per-deployment registry contract (`[FM-PCS-0013]`); the project-signing-root
discipline lives in this Handbook for now and will land in the
Standard's release-engineering requirements when those are
authored.

## 2.9 Substrate matrix × workflow — customization without forking

Every large customer has bespoke substrate preferences (Oracle vs
Postgres, Cedar vs OPA, Datadog vs whatever). Without an absorption
layer, a platform either ships N customer forks or refuses customer
preferences. Neither is workable.

The mesh's answer:

1. **Each pillar's spec declares a substrate matrix** — the supported
   backends, the seam contract. IBX lists Postgres / Oracle / MySQL +
   KV stores; PGE lists Cedar / OPA; ACT lists OTLP-compatible
   backends.
2. **PCS workflows bind a specific substrate from that matrix** for a
   specific deployment.
3. **The OSS baseline pillar code stays the same** across every
   deployment.

**Worked example — Customer X requires Oracle:** they write a
`customer-x-deployment:ibx-bootstrap-oracle` workflow that binds the
existing IBX pillar to Oracle via the existing substrate matrix. No
pillar fork. No mesh release. Future upgrades flow because the pillar
interface is unchanged.

**Seams are what they are. Customer chooses. Agents own deployment,
installation, config, maintenance** via PCS workflows.

## 2.10 AIR/CLCA continuous improvement

Incidents drive workflow evolution:

```
incident → ACT telemetry → AIR drafted in AKB → CLCA action
                                                    ↓
                          new workflow OR modify existing workflow
                                                    ↓
                          validation → registry → versioned → signed
                                                    ↓
                          every agent picks up improved workflow next exec
```

The workflow IS the propagation — "fixed it locally, didn't
propagate" is **structurally surfaced as non-conformance**, not
literally impossible: an operator with root on the customer's own
hardware can patch a host directly outside the workflow loop, and
the mesh cannot remove shell access on hardware it does not own.
What the loop guarantees is that the local fix is **detectable
(divergence shows up in ACT) and non-conformant (the deployment is
operating outside its declared workflow)** — the propagation
discipline is enforceable by audit and CLCA, not by physically
preventing the local fix. Ford 8D / manufacturing CLCA applied to
AI operations. Every workflow version traces back to the AIR that
motivated it. Mesh customers get one mechanical loop instead of
incident-report-in-PagerDuty + post-mortem-in-Confluence +
action-items-in-Jira + runbook-update-in-GitHub-wiki +
prompt-tweak-from-whoever's-on-call.

**Bound STD requirements.** AIRs are first-class AKB Tier-1 corpus
per `[FM-AKB-0012]` — surfaced via the `[FM-AKB-0010]` infra-
decision-side hooks at exactly the moments operational lessons
should land. Security-class AIRs are categorically excluded from
AKB ingest per `[FM-AKB-0012]` and route to the restricted-
audience store out of AKB scope. The "incident → AIR → workflow
change" loop's audit trail is the `pcs.policy.divergence` event
class per `[FM-INV-0005.2]`; the CLCA-trigger derivation that
escalates a divergence pattern to action is `[FM-PGE-0011]` (PGE
emits `pcs.policy.divergence.clca-trigger` once a `divergence_type`
count exceeds the operator-configured threshold for the deviation's
canonical emitter).

## 2.11 Bootstrap — agent-as-installer

PCS workflows manage the mesh; PCS runs on the mesh. The
chicken-and-egg resolves because **the agent IS the substrate**.

A fresh agent (Claude Code, Codex) + the `fiducial-mesh-deployment`
plugin → run the install workflow → end-state is a running mesh. No
external installer. No custom binary. The agent IS the installer.

The irreducibly human steps are **the trust-root mint and the
mesh-init quorum ceremony** — both require multiple humans, neither
routes through an agent. `vault operator init` on the host that
becomes Vault-of-record produces the unseal keys + root token
(agent-out-of-secret-path), AND the parallel
`[FM-INV-0004.4]` mesh-init quorum-bootstrap ceremony requires N
independent identity holders physically present (or
attested-presence equivalent), each receiving a single Shamir shard
of the quorum-authority master, signing the initial role
assignments, and emitting the founding genesis-class event to ACT
per `[FM-INV-0004.5]`. After these ceremonies complete, everything
else is workflow execution: `vault-pki-bootstrap` →
`iam-bootstrap` → `pillar-deploy:ibx` → `pillar-deploy:akb` →
`pillar-deploy:pcs-registry` (now PCS-managed from here on).

Pattern matches `kubeadm init` or `pacstrap` — one privileged
bootstrap step gets you to normal-mode platform operations. Difference:
no separate join-cluster binary. The agent is the binary.

**Bound STD requirements.** The bootstrap ceremony itself is
`[FM-INV-0004.4]` (mesh-init quorum-bootstrap — `N` independent
identity holders, K-of-N Shamir shards, signed initial role
assignments, ceremony attestation emitted to ACT). The ceremony
event is emitted under the **genesis event class** per
`[FM-INV-0004.5]`, which carves out the otherwise-circular
attribution requirement so the founding event can land in ACT
before IAM is operational. Subsequent `pillar-deploy:*` workflows
fire under the standard `[FM-INV-0001]` / `[FM-INV-0002]` /
`[FM-INV-0002.1]` discipline (every actor authenticates, every
time; halt on unverifiable; bounded deadline at every external-
ack point). The IAM-first load order for MCC plugin composition
is `[FM-MCC-0005]`. The agent-out-of-secret-path principle is
the invariant that gates the one human step (`vault operator
init`); the corresponding frame-boundary enforcement on MCC
plugin calls is `[FM-MCC-0009]`.

## 2.12 Mesh-CLI + MCC delivery shape

**Mesh-CLI is a configuration, not a product.** Claude Code and Codex
already have plugin systems. The mesh adds OUR PCS plugins to THEIR
system. We ride the vendor's harness + R&D. Net-new is the plugin
*content*, not a parallel framework. Operator runs
`claude plugin marketplace add github.com/<their-mesh>/marketplace`
— no separate "Mesh CLI" to learn.

**MCC — three surfaces, no AI loops:**

| Surface | What it is |
|---------|-----------|
| MCC-TUI | Claude Code + PCS plugins (the doer surface) |
| MCC-UI | JS/TS SPA dashboard — observe, trigger known-good, approve gated ops (Judge surface), read AIR + telemetry. **No LLM loop in the browser.** |
| MCC backend | Conventional Python web/orchestration backend. **NOT an AI system.** |

**The AI gets built ZERO times for MCC.** Reasoning happens in the
CLI surface where Claude Code or Codex is already running — which
means today, for most operational sessions, that reasoning runs on
the **vendor-hosted reasoning-runtime substrate** per the §1.5.1
deviation discipline. MCC is a control surface over already-existing
capabilities, not a new place to put intelligence. The existing
Wails `inbox-ui` (Judge approve/reject app) is the MCC-UI
approval-gate pane in embryo. *Migration to sovereign local
inference for the doer tier is in progress per §1.5.1; the
escalation tier remains vendor-hosted under the recognized
deviation.*

Governance rides Claude Code PreToolUse hooks — the seam already used
by `subagent-guard.sh`. PGE/IAM enforcement at the hook layer. Tier-0
profile = dev / low-stakes; destructive ops route through the governed
MCC backend so the Judge gate intercepts before execution.

**Bound STD requirements.** MCC's kernel/frame model is
`[FM-MCC-0001]`; the single-endpoint property is `[FM-MCC-0002]`;
the IAM auth hook on every call (including the human admin-UI
authentication path through the same hook) is `[FM-MCC-0003]`
with the synchronous Identity-context-version revalidation that
closes the cache TOCTOU. The web-admin-UI operator surface
discipline is `[FM-MCC-0007]`; the CLI-first / UI-second
constraint is `[FM-MCC-0008]` (every admin UI action invokes a
frame API operation also reachable directly via HTTP or MCP — the
UI is documentation-by-example for the contract, never a
parallel control surface). The Judge-gate hook (frame-level
elevated confirmation with uniform UX, typed re-attestation,
audit-attestable via the `mcc.judge_gate_confirm` event) is
`[FM-MCC-0010]`.

---

# Part 3 — The Pillars

**Seven substrate pillars + the MCC host frame.** This Part
documents the seven substrate pillars (IBX, AKB, ACT, IAM, PGE,
CRB, DPG, in §§3.1–3.7) and MCC (§3.8) as the host frame that
hosts them. The eighth and final pillar — **PCS** — is the action
layer covered in Part 2 and lives normatively in STD-001 **§6**
(written). Pillar count is **8** per `[FM-MCC-0011]`;
MCC is host, not pillar #9. PCS reaches each pillar via its
published interface (skills, MCP tools, hooks) — pillars stay
zero-coupled, standalone-installable, and substrate-pluggable.
Each section names the substrate matrix (the seam contract —
customer chooses among supported substrates) and what PCS workflows
do with the pillar. The **normative spec** for each pillar lives
in STD-001 §5.x (per-pillar numbered requirements + Conformance
Profile). The substrate matrices in this Part are
**illustrative**; the authoritative substitutability claim per
pillar is the STD's **§5.x.1 Conformance Profile** with its Test
Set column. Where this Handbook substrate matrix and the STD
Conformance Profile differ, the STD is authoritative.

## 3.1 IBX — Inbox Exchange

The control-plane message-routing substrate. Every async hand-off
between agents and every Judge-approval gate routes through IBX. PCS,
PGE, CRB, and the Judge gate route *through* IBX to reach Workforce.
The PCT (Principal Control Token, nine-field schema) is an IBX message;
that's why PCT lives in IBX rather than expanding PCS scope.

**Status**: in-production on the PG-backed deployment
(`agent-inbox-mcp` server + `inbox-ui` Wails desktop app +
event-sourced PostgreSQL on `infra-pg-1`). The earlier
`messages.inbox` ClickHouse-table POC is superseded as pre-matrix
history — its ClickHouse substrate fell outside the
substrate-matrix's claim-queue contract (transactional SKIP-LOCKED;
OLAP unsuitable), which is why the in-production deployment is on
PG. **Normative spec**: STD-001 §5.1 (12 requirements + Conformance
Profile). Authoring drafts retained in `devel/spec-drafts/IBX-SPEC.md`
as historical reference.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Routing-audit storage | ANSI SQL + JSONB | PostgreSQL 17+ | Oracle 19+, MySQL 8+ |
| Worker-pool claim queue | Transactional SKIP-LOCKED | PostgreSQL 17+ | (claim semantics need real transactions; OLAP unsuitable) |
| Identity verification | Per IAM pillar | Vault PKI | (whatever IAM provides) |
| Telemetry sink | OTLP-on-the-wire | OTLP-compatible backend | (operator-selected; see ACT) |

**How PCS reaches it.** PCS workflows author / dispatch / mark messages
via the `agent-inbox-mcp` MCP server. Worker-pool dispatch and Judge
approval gates are first-class PCS workflow primitives — a `judge-gate`
hook can be declared on any workflow step that needs explicit approval
before proceeding.

**Bound STD requirements.** PCT nine-field contract =
`[FM-IBX-0001]`; PCT field-name stability =
`[FM-IBX-0002]`; server-enforced Judge gate for action-priority
messages = `[FM-IBX-0003]`; message status workflow =
`[FM-IBX-0004]`; append-mostly substrate = `[FM-IBX-0005]`;
identity-vs-session distinction in PCT = `[FM-IBX-0006]`;
worker-pool dispatch semantics = `[FM-IBX-0007]`; routing-audit
storage seam = `[FM-IBX-0008]`; claim-queue substrate seam
(transactional SKIP-LOCKED) = `[FM-IBX-0009]`; status-transition
audit emission via the `[FM-ACT-0009]` ack contract =
`[FM-IBX-0012]`; mesh.ibx.* telemetry emission =
`[FM-IBX-0011]`. The identity-by-brief transitional deviation
(the recognized gap until IAM operational) = `[FM-IBX-0010]` —
sunsets via `[FM-IAM-0014]`.

## 3.2 AKB — Agent Knowledge Base

Role-projected, tier-stratified knowledge retrieval. Agents query AKB
for ranked context relevant to their role and current task; agents also
propose curator-gated updates. Tier-0 content is bounded-prior loaded
at session start; Tier-1 content is gradient-gated mid-reasoning;
substrate-trap-aware retrieval prevents the vector substrate (physics-
blind) from surfacing dead-end content as candidate solutions.

**Status**: built at `KI7MT/akb`; DDL + ingest + akb-mcp server +
Tier-0 generator green. **Normative spec**: STD-001 §5.5
(14 requirements + Conformance Profile). Authoring draft retained
in `devel/spec-drafts/AKB-SPEC.md` as historical reference.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Vector store | k-NN + filter predicates | ClickHouse + ANN index | pgvector, Weaviate (operator-tested) |
| Embedding service | Sentence-embedding API | local model (sovereign) | sovereign-local alternatives only — no vendor APIs |
| Telemetry sink | OTLP | OTLP-compatible backend | (per ACT) |

**How PCS reaches it.** PCS workflows query AKB via the `akb-mcp` MCP
server for retrieval-augmented context; CLCA workflows write AIR
documents and lessons-learned back into AKB through curator-gated
ingestion plugins.

**Bound STD requirements.** Two-tier delivery (Tier 0 bounded prior
+ Tier 1 gradient-gated injection) = `[FM-AKB-0001]`; the 1024-byte
Tier-0 hard cap = `[FM-AKB-0002]`; Tier-0 source provenance
(deployable snapshot only from merged-`main`; Bar-B-gated source
edits) = `[FM-AKB-0003]`; substrate-trap deterministic pre-filter
before vector similarity = `[FM-AKB-0004]`; role projection at
retrieval = `[FM-AKB-0005]`; self-review exemption =
`[FM-AKB-0006]`; cross-role per-document cap = `[FM-AKB-0007]`;
stratified promotion gates (Bar A/B/C/Physics-C) = `[FM-AKB-0008]`;
bootstrap pre-write gate ≥20 chunks = `[FM-AKB-0009]`; hook trigger
domains (code-author + infra-decision) = `[FM-AKB-0010]`; fail-open
on retrieval with infra-decision-side escalation (the new
`akb-fail-open-on-irreversible-hook` divergence_type) =
`[FM-AKB-0011]`; AIRs as Tier-1 corpus with security-class
exclusion = `[FM-AKB-0012]`; ACT audit emission via the
`[FM-ACT-0009]` ack contract = `[FM-AKB-0013]`; mesh.akb.*
operational telemetry = `[FM-AKB-0014]`.

## 3.3 ACT — Agent Cognitive Telemetry

The immutable, locally-hosted audit ledger. Every **observable**
reasoning span, tool call, signed action, IAM event, IBX message,
quorum vote, and Judge approval is emitted to ACT.
(Vendor-hosted reasoning runtimes per §1.5.1 do not expose all
internal reasoning tokens to the calling process — ACT captures
what the runtime surfaces, not what it internalizes; this is one
of the costs of the vendor-hosted-reasoning deviation.)
Unidirectional — agents emit; nothing flows back out except via
curator review. ACT is what makes non-repudiation, per-session
forensics, regulatory compliance, and the dialectical-engine
evidence trail mechanically possible.

**Status**: **Normative spec**: STD-001 §5.4 (12 requirements +
Conformance Profile). Reference implementation pending. Authoring
draft retained in `devel/spec-drafts/ACT-SPEC.md` as historical
reference.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Telemetry backend | OTLP traces + metrics + logs | SigNoz (sovereign, OSS) | ClickStack, any OTLP-compatible backend (operator-selected) |
| Append-mostly OLAP store | Columnar, queryable | ClickHouse | (operator's existing OLAP, if OTLP-fronted) |
| Retention engine | Policy-driven retention + erasure | substrate-native | (per ACT spec) |

**How PCS reaches it.** Every PCS workflow execution emits telemetry
to ACT via the standard OTLP exporter — this is how the AIR/CLCA loop
in §2.10 sources its incident-detection signal. ACT is a passive
emitter from PCS's perspective; PCS workflows don't read from ACT
directly (that's MCC-UI and human operators).

**Bound STD requirements.** Append-only event store with carve-out
for retention-expiration ceremony only = `[FM-ACT-0001]`;
unidirectional cognitive-event emission = `[FM-ACT-0002]`;
session-granular attribution with genesis-event carve-out =
`[FM-ACT-0003]`; the event-type taxonomy = `[FM-ACT-0004]`;
per-session cryptographic chaining with genesis chain seeding and
retention-boundary re-anchoring = `[FM-ACT-0005]`; hash algorithm
policy (SHA-256 sovereign reference, FIPS-validated when §4.2
FIPS-Day-1 applies) = `[FM-ACT-0006]`; three-consumer-class
access pattern (Compliance / Detection / CLCA) = `[FM-ACT-0007]`;
Detect Layer transitional clause (with the new
`detect-layer-not-operational` divergence_type emission) =
`[FM-ACT-0008]`; the load-bearing **emission-confirmation
contract** every state-affecting pillar depends on (emit →
durable commit → ack → proceed; idempotent on `emission_id`) =
`[FM-ACT-0009]`; cold-storage tier deferred = `[FM-ACT-0010]`;
retention controls per regulatory regime = `[FM-ACT-0011]`;
mesh.act.* operational telemetry = `[FM-ACT-0012]`.

## 3.4 IAM — Identity & Access Management

Foundational. The root of trust every other pillar's authorization,
isolation, audit, segregation-of-duties, and human-approval guarantee
is downstream of. **Two non-negotiable Tier-0 invariants**: no bypass
(no action without an authenticated principal) and fail strict (under
error / ambiguity / unavailability, the system halts).

ARCA (Agentic Root CA) is the offline issuance authority — issues
agent identities, then steps out; never in the action path. Runtime
identity verification is local (signature + trust chain), never a
callback. The mesh's IAM pillar implements identity-by-control;
identity-by-assertion (what the lab runs today) is the prior state
the mesh moves agents away from.

**Status**: code-complete at lab `iam-1` (Phase 1 done — Roster,
lifecycle audit, MCP surface, principal-type stamp, mint, suspend /
resume / terminate, authz-context read contract for PGE, partial-mint
reconciliation, 20/20 tests green). ARCA not yet built. Deployment
operates under the `identity-by-brief` transitional deviation
per `[FM-IAM-0014]` + `[FM-IBX-0010]` until ARCA + Vault signing
are operational across the deployment. **Normative spec**: STD-001
§5.2 (14 requirements + Conformance Profile). Authoring drafts
retained in `devel/spec-drafts/IAM-CORE-SPEC.md` /
`IAM-INCREMENT-2.md` as historical reference.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Credential store | Vault KV + Vault Database (dynamic creds) | HashiCorp Vault | (cloud KMS / HSM / PKCS#11 if argued) |
| Identity store (Roster) | ANSI SQL + JSONB | PostgreSQL 17+ | (Vault Identity as alternate at scale; operator call) |
| PKI / signing authority | x509 + Vault PKI engine | Vault `pki_arca` + `pki_tls` | (HSM-backed if FIPS) |
| IdP federation | OIDC / LDAP / SAML | FreeIPA (HA) | OIDC providers (Keycloak, Authentik), OpenLDAP, Samba AD, Entra ID, Okta |

**How PCS reaches it.** Every PCS workflow execution runs under an
authenticated identity from IAM. PCS does not implement
authentication; it consumes the verified-principal context from IAM
via standard interfaces. Publishing rights to namespaces are
IAM-scoped — only the prefix-reservation signing identity can publish
under that namespace.

**FIPS-Day-1 discipline.** For deployments targeting FIPS-regulated
regimes, the IAM substrate (Vault PKI, TLS endpoints, signing engines,
credential authority) must run FIPS-validated mode from initial
provisioning. **Canonical statement of the requirement and its
rationale lives at §4.2.** This is a substrate-implementation
discipline, not a policy overlay — the validated crypto path must be
the substrate's default from `vault operator init` onward.

**Bound STD requirements.** Offline-ARCA separation =
`[FM-IAM-0001]`; identity issuance + lifecycle =
`[FM-IAM-0003]` + `[FM-IAM-0003.1]`; suspend / resume (with
worker-pool claim-draining semantics) = `[FM-IAM-0004]`;
revocation / termination = `[FM-IAM-0005]`; Vault in-boundary
signing = `[FM-IAM-0006]`; Roster = `[FM-IAM-0007]`; Publish
pipeline = `[FM-IAM-0008]`; IdP federation = `[FM-IAM-0009]`;
principal-type stamp = `[FM-IAM-0010]`; identity-context contract
for PGE consumers (six-element context including the monotonic
Identity-context version field that powers MCC-0003 cache
revalidation) = `[FM-IAM-0011]`; mesh.iam.* telemetry =
`[FM-IAM-0012]`; state-affecting-operation audit emission via the
`[FM-ACT-0009]` ack contract = `[FM-IAM-0013]`; operational-state
declaration = `[FM-IAM-0014]` (the four-condition gate that
sunsets the identity-by-brief deviation).

## 3.5 PGE — Policy Guardrail Engine

Deterministic, owned, auditable policy enforcement. PGE is the mesh's
sovereign alternative to vendor-mediated safety filters (which are
opaque, non-deterministic, at the wrong layer, and subject to vendor
policy drift). Double-guardrail: enforces policy on agent *intent*
before messages reach IBX, and on *execution* inside DPG. Either gate
alone misses a class.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Policy engine | Decision protocol (allow / deny + reason) | Cedar | OPA, Rego |
| Audit sink | OTLP audit-class log records | (per ACT pillar) | — |
| Hook integration | PreToolUse / PostToolUse / PermissionRequest | Claude Code + Codex hooks | (vendor-native hook surface) |

**How PCS reaches it.** PCS workflows declare policy guards as hooks
in the plugin manifest. PGE evaluation runs at hook fire time; deny
verdicts halt the workflow step before execution. The
`subagent-guard.sh` PreToolUse hook in the lab today is the precedent
implementation pattern.

**Status**: **Normative spec**: STD-001 §5.3 (14 requirements +
Conformance Profile). Authoring drafts retained in
`devel/spec-drafts/PGE-SPEC.md` as historical reference.

**Bound STD requirements.** Deterministic evaluation = `[FM-PGE-0001]`
+ `[FM-PGE-0002]`; rule corpus storage with the two-stratum split =
`[FM-PGE-0003]` (Stratum 1 non-negotiable) + `[FM-PGE-0004]`
(Stratum 2 patterns); the **double-guardrail enforcement** (Gate 1
intent at IBX submission + Gate 2 execution at DPG ephemeral
boundary) = `[FM-PGE-0005]` (sunsets when `[FM-DPG-0005]` is
operational); no-vendor-mediated-bypass = `[FM-PGE-0006]`;
PreToolUse hook surface = `[FM-PGE-0007]`; per-decision audit
emission via the `[FM-ACT-0009]` ack contract = `[FM-PGE-0008]`;
catastrophic-class quorum gating = `[FM-PGE-0009]`; platform
enforcement floor independent of plugin self-declaration =
`[FM-PGE-0010]`; the **`divergence_type` discriminator system**
with 8 active subtypes + canonical-emitter assignment rule +
fallback-emitter rule for unloaded emitters = `[FM-PGE-0011]`;
policy overlay consumption = `[FM-PGE-0012]`; per-surface
enforcement = `[FM-PGE-0013]`; mesh.pge.* telemetry =
`[FM-PGE-0014]`.

## 3.6 CRB — Compute Resource Broker

Hardware-aware workload dispatch. The mesh's hardware fleet is
heterogeneous on purpose: unified-memory hosts (M3 Ultra for inference),
GPU-bound hosts (RTX PRO 6000 on 9975 for CUDA), CPU-bound replicas
(EPYC), DAC network for low-latency inter-host traffic. CRB routes
each workload to the host that fits it.

**Language**: Go (sanctioned deviation — hot concurrent broker;
Go's concurrency + GC fit the workload class Python doesn't).

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Host inventory | Static config OR live discovery | YAML / TOML inventory | (cloud-provider inventory if argued) |
| Workload dispatch transport | gRPC / mTLS | local mTLS via Vault PKI | — |
| Telemetry sink | OTLP | (per ACT) | — |

**How PCS reaches it.** PCS workflows that need workload placement
declare resource requirements (GPU, memory, CPU) as workflow
parameters; CRB resolves placement at dispatch time. PCS does not
build a parallel scheduler — CRB owns the placement decision.

**Status**: **Normative spec**: STD-001 §5.7 (13 requirements +
Conformance Profile). Broker daemon design-stage — deployment
operates under the `crb-codified-by-convention` transitional
deviation per `[FM-CRB-0010]` until the broker is built. Authoring
draft retained in `devel/spec-drafts/CRB-SPEC.md` as historical
reference.

**Bound STD requirements.** Three architecturally distinct
components (Classification + Dispatch Policy + Broker Daemon) =
`[FM-CRB-0001]`; bounded classification taxonomy (`gpu_bound`,
`mps_bound`, `db_bound`, `reasoning_bound`, `mixed`) =
`[FM-CRB-0002]`; dispatch policy as pure function with bounded
eligibility / tiered fallback / capacity-aware = `[FM-CRB-0003]`;
hardware topology model = `[FM-CRB-0004]`; broker identity =
`[FM-CRB-0005]` (with FM-INV-0001 cross-ref for authentication-
at-dispatch); Reasoner archetype — no worker-pool claim seam =
`[FM-CRB-0006]`; clean seam — no isolation / no validation / no
content policy = `[FM-CRB-0007]`; substrate substitutability via
Exit Test with accelerator-runtime as a *capability* not a
CUDA-lock-in = `[FM-CRB-0008]`; DPG seam — isolation-tier as
eligibility input with **explicit pre-dispatch revalidation**
closing the eligibility-vs-dispatch TOCTOU = `[FM-CRB-0009]`;
operational-state transitional clause = `[FM-CRB-0010]`;
convention-codification fidelity (parity battery gating sunset) =
`[FM-CRB-0011]`; crb.* audit emission via the `[FM-ACT-0009]`
ack contract = `[FM-CRB-0012]`; mesh.crb.* telemetry =
`[FM-CRB-0013]`.

## 3.7 DPG — Deterministic Proving Ground

Local, ephemeral isolation boundary for agent-emitted code. Every
execution runs in a single-use boundary that is created, used, and
destroyed; nothing persists across runs in the substrate; nothing the
execution wrote inside the boundary survives unless it returns
through the attested channel. DPG is where stochastic agent reasoning
meets deterministic execution — agents may reason probabilistically;
the code they emit is validated here under deterministic conditions
before it touches production state.

**Language**: Go driver + adopted microVM (sanctioned — driver layer
needs Go for OCI / containerd integration; the microVM itself is
adopted, not built).

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Sandbox runtime | OCI-compatible ephemeral isolation | Podman (floor) → gVisor → **Kata** (ceiling) | (any OCI runtime with attested isolation) |
| Container registry | OCI distribution-spec | local OCI registry | (operator-selected) |
| Telemetry sink | OTLP | (per ACT) | — |

**How PCS reaches it.** PCS workflows requiring code execution
(test-run, build-validate, sandbox-execute) dispatch the code to DPG
via the DPG driver MCP; results return through the attested channel
to the calling workflow. PGE execution-side gates run inside DPG
before the code touches anything.

**Status**: **Normative spec**: STD-001 §5.6 (14 requirements +
Conformance Profile). Design-stage — deployments operate under the
`subagent-worktree-precursor` transitional deviation per
`[FM-DPG-0013]` until the generalized DPG runner is built. The
`subagent-guard.sh` PreToolUse hook and the `isolation: "worktree"`
subagent pattern are the operational precedent.

**Bound STD requirements.** Three architecturally distinct
components (Runner + Boundary + Gates) = `[FM-DPG-0001]`; the
five non-negotiable ephemeral-isolation properties (single-use,
filesystem isolation, network default-deny, resource limits,
process+identity isolation) **with explicit accelerator-VRAM
scrub at teardown** = `[FM-DPG-0002]`; single attested return
channel with `boundary_audit_summary` = `[FM-DPG-0003]`; four
mandatory validation gates (Syntax + PGE + test-suite + resource-
limit attestation) = `[FM-DPG-0004]`; PGE Gate-2 enforcement (the
sunset for the `[FM-PGE-0005]` Gate-2 transitional clause) =
`[FM-DPG-0005]`; DPG runner identity = `[FM-DPG-0006]`; worker-
pool dispatch via `[FM-IBX-0007]` / `[FM-IBX-0009]` =
`[FM-DPG-0007]`; substrate substitutability via Exit Test with
tier-graded isolation runtimes = `[FM-DPG-0008]`; Registry-bound
executable validation (dev-to-production trust boundary) =
`[FM-DPG-0009]`; deterministic execution with declared determinism
level = `[FM-DPG-0010]`; reconciliation sweep for lost completions
(fact-of-loss recovery via `lost_completion_recovered`) =
`[FM-DPG-0011]`; dpg.* audit emission via the `[FM-ACT-0009]`
ack contract = `[FM-DPG-0012]`; subagent-worktree precursor
transitional clause = `[FM-DPG-0013]`; mesh.dpg.* telemetry =
`[FM-DPG-0014]`.

## 3.8 MCC — Mesh Control Center

The operator UI binding the whole mesh together. **Three surfaces, no
AI loops in any of them** (the AI is in the CLI — Claude Code / Codex
— where the agents already run). Status: backend BUILT on `iam-1`
(Python FastAPI + web UI, https://192.168.1.31:8443/, Vault TLS); the
existing Wails `inbox-ui` is the MCC-UI approval-gate pane in embryo.

| Surface | What it is | Language |
|---------|-----------|----------|
| MCC-TUI | Claude Code + PCS plugins (the doer surface) | (Claude Code / Codex; not built by mesh) |
| MCC-UI | JS/TS SPA dashboard — observe, trigger known-good workflows, approve gated ops (Judge surface), read AIR + telemetry. **No LLM loop in the browser.** | JS / TS |
| MCC backend | Conventional Python web + orchestration. **NOT an AI system.** | Python |

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Web backend | HTTP + WebSocket + standard auth | FastAPI (Python) | (any Python WSGI/ASGI) |
| Frontend SPA hosting | Static asset serving | nginx / Caddy / FastAPI static | — |
| Session store | Server-side session | Redis OR PostgreSQL | — |
| Identity backend | Per IAM pillar | Vault + Roster | — |

**How PCS reaches it.** MCC-TUI *is* Claude Code + PCS plugins —
PCS doesn't "reach" MCC-TUI; PCS plugins ARE what makes a Claude Code
session into MCC-TUI. MCC-UI consumes PCS workflow definitions to
build trigger panes, reads execution state from the registry, and
gates approval-required workflow steps through the Judge surface.

**Status**: **Normative spec**: STD-001 §5.8 (14 requirements +
Conformance Profile — note MCC is the **host frame**, not a
ninth pillar, per `[FM-MCC-0011]`). Backend BUILT on iam-1
(Python FastAPI + web UI, Vault TLS); deployment operates under
the `mcc-partial-load` transitional deviation per `[FM-MCC-0012]`
until all eight pillars are loaded as plugins.

**Bound STD requirements.** Pluggable host-frame model =
`[FM-MCC-0001]`; single endpoint = `[FM-MCC-0002]`; IAM auth hook
on every call with synchronous Identity-context-version
revalidation (the TOCTOU defense) = `[FM-MCC-0003]`; centralized
substrate handles via dependency injection = `[FM-MCC-0004]`;
IAM-first load order (frame fails closed if IAM cannot load) =
`[FM-MCC-0005]`; minimum-viable plugin contract = `[FM-MCC-0006]`;
operator surface as web admin UI = `[FM-MCC-0007]`; CLI-first /
UI-second discipline = `[FM-MCC-0008]`; agent-out-of-secret-path
enforcement at the frame boundary = `[FM-MCC-0009]`; Judge-gate
hook with uniform typed re-attestation = `[FM-MCC-0010]`;
eight-pillars-MCC-is-host invariant = `[FM-MCC-0011]`;
operational-state transitional clause = `[FM-MCC-0012]`; mcc.*
audit emission via the `[FM-ACT-0009]` ack contract =
`[FM-MCC-0013]`; mesh.mcc.* operational telemetry (frame's own,
distinct from per-plugin pass-through) = `[FM-MCC-0014]`.

---

# Part 4 — Operations

How a Mesh actually runs. This part covers operational concerns
across deployment shapes; the per-pillar substrate decisions live in
Part 3, the workflow / registry / customization mechanics in Part 2.

## 4.1 Four flexibility axes — "run what you brung"

A Mesh deployment is parameterized along four orthogonal axes. The
customer's hardware and operating posture pick a point in this space;
the architecture adapts to the substrate, not the other way around.

| Axis | What it varies | Customer picks |
|------|---------------|----------------|
| **HA** | Single-instance ↔ HA cluster (Raft / leader-election) | Their availability requirement |
| **Scale** | Single host ↔ multi-host fleet | Their workload size |
| **Performance** | Commodity hardware ↔ specialized accelerators (GPU, fast NVMe, low-latency interconnect) | Their workload profile |
| **OSS ‖ commercial substrates** | Pure-OSS substrate matrix vs commercial alternatives where allowed | Their procurement posture |

**Deployment spectrum** spans:

- **One-box hobbyist** — single Linux box; every pillar runs locally; one Claude Code or Codex session is the entire operator surface
- **Lab / small team** — a handful of hosts (e.g. KI7MT's "3 minis + 9975" — three small unified-memory hosts plus a workstation-class GPU/CPU node); per-host venv + DAC interconnect; the lab fleet is this point
- **Datacenter** — Proxmox / VMware / bare-metal cluster; HA Vault, replicated PG, container-orchestrated pillars; per-customer PKI rooted at their ARCA

The same pillars run at every point in the spectrum. The PCS workflow
that deploys IBX on a one-box deployment is the same workflow that
deploys IBX on a datacenter cluster — different parameters, same
plugin. **The mesh runs what the customer brung.**

## 4.2 Security framework

Sovereignty is **not** a configuration option. It is the architecture.
Every pillar inherits these non-negotiables:

- **Credentials** live in Vault (KV or dynamic-secrets) or OS keyring,
  never in config files or environment variables that touch disk in
  plaintext
- **No injection surfaces** — no `subprocess` with `shell=True`, no
  `eval`/`exec` on untrusted input, parameterized SQL only
- **HTTPS / TLS only** for any cross-host traffic; mTLS against Vault
  PKI where pillars talk to each other
- **Audit emission is a build standard** (per `PILLAR-SPEC-TEMPLATE.md`
  Acceptance Criterion 5) — every state-affecting operation produces
  an accountability event via ACT
- **No bypass + fail strict** (IAM Tier-0 invariants — §3.4) — no
  trusted-because-internal account; the system halts under ambiguity
- **PreToolUse hooks gate destructive operations** before they execute;
  PGE evaluates intent before IBX; DPG isolates code before it touches
  production state

The framework detail lives in `MCP-SECURITY-FRAMEWORK.md` in the
`qso-graph-devel` repo and is referenced by every pillar's Acceptance
Criterion 1.

**Release gate.** No mesh-shipped component (pillar, PCS plugin, MCP
server) reaches production without (1) `test_security.py` passing,
(2) two-person GH-native review, (3) multi-platform validation. Tag
push triggers automated publish; manual publish is forbidden.

**FIPS-Day-1 substrate discipline.** For deployments targeting regulated
regimes that require FIPS-validated cryptography (FedRAMP-High,
IL5/IL6, HIPAA-hardened, DoD/SCIF), the substrate must run FIPS-mode
crypto from initial provisioning — Vault PKI, TLS endpoints, signing
engines, all on FIPS 140-3 (or 140-2 transitional) validated modules.
**FIPS-mode retrofitting onto a substrate that grew up non-FIPS is
ruinously expensive** — possible in principle (re-provision the
substrate, re-bootstrap PKI, migrate every key under the validated
modules), but in practice the cost is high enough that FIPS-Day-1
is the only realistic path for a deployment that anticipates the
regulated workload. The validated crypto path is a property of the
implementation pillars (per §3.4), not a policy overlay. Per
capability-minimization (§1.7.2), if a deployment targets FIPS-
regulated work, non-FIPS crypto modules must not be provisioned at
all — the overlay encodes the NIST controls, the substrate
provides the validated primitives.

**Bound STD requirements.** The security framework's bullet list
maps directly to numbered STD requirements: credentials in Vault =
`[FM-IAM-0006]` (in-boundary signing) + the IAM Conformance
Profile's secret-store seam; no-injection-surfaces is a §0.5
Static-check discipline applied across every pillar; HTTPS/TLS
only is the substrate-pluggable contract every pillar's
Conformance Profile names; audit-emission-as-build-standard is the
per-pillar audit requirement bound to the `[FM-ACT-0009]`
emission-confirmation contract (FM-IBX-0012, FM-IAM-0013,
FM-PGE-0008, FM-AKB-0013, FM-DPG-0012, FM-CRB-0012, FM-MCC-0013);
no-bypass + fail-strict = `[FM-INV-0001]` + `[FM-INV-0002]` +
`[FM-INV-0002.1]` deadline; PreToolUse hooks gating destructive
ops = `[FM-PGE-0007]` (PreToolUse hook surface) + `[FM-PGE-0005]`
double-guardrail with Gate-2 via `[FM-DPG-0005]`. Two-person
GH-native review and tag-push-triggers-publish are PCS / §6
release-gate concerns. FIPS-Day-1 substrate
discipline binds to the Tier-0 substrate selection in the IAM
Conformance Profile per `[FM-IAM-0006]` and to the FIPS-validated
hash algorithm per `[FM-ACT-0006]`; capability-minimization-applied-
to-FIPS-mode is the `[FM-INV-0003]` discipline applied at substrate
provisioning.

## 4.3 Delivery and packaging

> **STD/HDBK boundary reminder (per §1.5).** The Standard is
> language-neutral at the contract layer per `[FM-STD §1]`. The
> language map below is the project's **reference-implementation
> choice**, not a conformance requirement. A customer choosing
> a different stack for any pillar remains conformant on the same
> terms (passing the per-pillar Conformance Profile test set).

Language map (canonical reference in Appendix B):

| Layer | Language |
|-------|----------|
| Pillars (IBX, AKB, ACT, PGE, IAM) | **Python** |
| CRB | **Go** (sanctioned) |
| DPG (driver + adopted microVM) | **Go** + adopted microVM |
| MCC backend | **Python** |
| MCC-UI | **JS/TS SPA** (browser-context argued deviation) |
| Mesh-CLI / installer | **Go** static binary OR "Claude Code + PCS plugins is the CLI" |
| All MCP servers | **Python** |

**C# is purged from the canon.** Any C# in lab history is retained as
reference source code but does not bind a canonical mesh component.

**Build / runtime substrate** per `DELIVERY-PACKAGING.md` § OS
dual-tier: RHEL-compatible family only in v1.0–v1.1 (Rocky 9.7+ / Alma
9.7+ / RHEL 9.7+ / UBI 9.7+). `ubuntu-latest` is **not acceptable**
as the runner / container base / install host for any pillar's
reference CI or shipped artifacts. The constraint exists because
**the project validates the FIPS-clean and audit-substrate claims
on one family — the RHEL family — through v1.1**; cross-distro builds
(Ubuntu Pro ships FIPS-validated modules, for instance) can produce
conforming substrates on the same Standard requirements, but the
project's reference validation isn't run there. Cross-distro test
jobs are allowed as **additive signal**, never substitutive for
the validated family. A customer who insists on a different family
implements the same numbered Standard requirements on their
substrate and is conformant on the same terms; the conformance
profile is contract-pluggable per the Standard's substrate-
substitutability discipline.

**Distribution shape.** Each pillar publishes as a `pip install`able
Python package (or `go install`able binary for the Go pillars). The
default manifest BOM (per §2.8) pins coherent versions across the
whole stack. Customer installs from the BOM; upgrades happen by
bumping the BOM version.

## 4.4 The AIR / CLCA discipline (operations side)

The AIR / CLCA loop is described mechanically in §2.10. The
**operational** side:

- **Every incident produces an AIR.** Blameless post-mortem;
  documented in AKB; CLCA actions explicit
- **Every CLCA action becomes a workflow change.** New workflow OR
  modify existing workflow; versioned; signed; through the validation
  harness
- **No fix that isn't a workflow change is "done."** Local fixes that
  don't propagate via workflow versioning are operational debt — they
  will recur

The discipline comes from Ford 8D / manufacturing CLCA, applied to
AI operations. The mesh makes it mechanical because the workflow IS
the propagation — there is no separate "rollout" step that can be
skipped.

## 4.4.1 Judge-gate failure modes

The Judge gate is the single most load-bearing element of the human
side of the mesh — it shows up in §1.6 (first-class architectural
element), §2.12 (Judge surface in MCC), §3.1 (server-enforced at
IBX submission per `[FM-IBX-0003]`). An architecture whose thesis is
"humans supply judgment at the gates that matter" has to take the
failure modes of that judgment seriously. The Judge is human; the
attack surface is operator attention and cognitive load.

**Approval fatigue.** A Judge faced with N approvals per day past
some threshold will start approving by pattern-match rather than
review. The risk is not laziness; it's that human attention is a
finite resource and a flood of low-stakes approvals erodes the
attention available for the high-stakes ones. **Mitigation**: rate
ceilings on approval-event emission per principal-id per window
(operator-configurable; default rate flagged as a
`pcs.policy.divergence` event when exceeded); per-priority sorting
in MCC so high-stakes batches are visually distinct from routine
ones.

**Approval-spam attack.** An adversary (or a malfunctioning agent)
floods the Judge surface with low-stakes approval requests to mask
a single high-stakes one in the noise. **Mitigation**: ACT
analytics on approval-request velocity per requesting identity;
the divergence-event class for anomalous approval-spam patterns
fires before the high-stakes request reaches the Judge surface;
the operator gets the signal, not the per-request spam.

**Injection-shaped message content.** An agent crafts a PCT body
designed to read as routine to a human reviewer while triggering
a non-routine action when applied. The Judge sees plausible text;
the system enforces a different effect. **Mitigation**: the MCC
approval pane **shall** display the structured effect of the
operation (target identity, scope, what-changes-where), not just
the natural-language `task` field. The Judge approves the effect,
not the prose. The structured display is bound to `[FM-MCC-0010]`
Judge-gate hook's uniform UX with typed re-attestation of the
target value (not yes/no click).

**Second-Judge thresholds for anomalous batches.** When an
approval batch exceeds operator-configured thresholds (rate;
single-requester concentration; same-target-class concentration),
the Judge gate **shall** escalate to a second-Judge requirement
before any of the batch applies. This converts a single-Judge
fatigue compromise into a multi-Judge attack surface that costs
proportionally more for the adversary.

**ACT analytics on approval patterns.** ACT's three-consumer-class
access pattern per `[FM-ACT-0007]` includes Detection — the Judge-
gate's approval stream is exactly the kind of behavioral-anomaly
detection workload the Detect Layer is for. When the Detect Layer
is operational per `[FM-ACT-0008]`, approval-pattern anomalies
(rate spikes, requester-concentration, target-concentration,
time-of-day shifts) emit `act.detection_signal` events that route
to the operator surface. The operator sees the pattern, not just
the events.

**Bound STD requirements.** Server-enforced Judge gate =
`[FM-IBX-0003]`; Judge-gate hook with uniform typed re-attestation
= `[FM-MCC-0010]`; ACT three-consumer-class support including
Detection = `[FM-ACT-0007]`; Detect Layer transitional clause
governing the analytics maturity =
`[FM-ACT-0008]`. **The mitigations above** are intended to land as
operational deployment guidance and as future numbered
requirements on MCC's Judge-gate UX (rate ceilings, structured
effect display, second-Judge thresholds) when the §6 PCS
workflow gate-management requirements are written.

## 4.5 Customer extends without forking

The substrate-matrix × workflow composition is described mechanically
in §2.9. The **operational** side:

- The customer **does not fork the pillar**. The pillar's substrate
  matrix declares the seam contract; the customer's workflow binds
  their specific substrate from within that contract.
- The customer's workflow lives in **their tenant namespace** in
  their mesh registry — `<customer-x>:<workflow>:<version>`
- The OSS baseline pillar code is untouched across every customer.
  Mesh upgrades flow because the pillar interface is unchanged.

If the customer needs a substrate the pillar's matrix doesn't list,
the path is: argue the case → pillar maintainers add it to the matrix
→ ship in the next mesh release → customer's workflow now has a
supported binding to point at. The argued-deviation discipline (§1.5)
is the same shape applied to substrate choices.

**Bound STD requirements.** The argued-case path for adding a new
substrate to a pillar's Conformance Profile is `[FM-INV-0003.2]`
(net-new capability requires argued-case + the multi-profile
conformance run proving the new substrate passes the pillar's
test set). The Appendix F entry schema for the argued-case
submission is §F.1 of STD-001. The customer-tenant-namespace
discipline (`<customer-x>:<workflow>:<version>`) belongs to the
§6 PCS namespace + registry contract (`[FM-PCS-0014]` / `[FM-PCS-0013]`).

## 4.6 Agents own deployment, installation, config, maintenance

There are no human-following install procedures in the canonical
distribution. The mesh ships with PCS plugins that execute the work:

- **Install**: `fiducial-mesh-deployment` namespace workflows
- **Configure**: `fiducial-mesh-configuration` namespace workflows
- **Operate**: `fiducial-mesh-operations` namespace workflows
- **Administer**: `fiducial-mesh-administration` namespace workflows
- **Diagnose**: `fiducial-mesh-diagnostics` namespace workflows

The operator's interaction is to load the right plugin loadout
(per §2.2 — the loadout makes the agent the role) and tell their
agent what they want. The agent reads the plugin and executes the
workflow. The operator approves what needs Judge-gating; everything
else is mechanical.

The irreducibly-human steps are **the bootstrap trust-root mint
(`vault operator init` — agent-out-of-secret-path) and the
mesh-init quorum ceremony** (multi-human; `[FM-INV-0004.4]`); both
sit outside the workflow-execution model by design and are detailed
in §2.11. After those ceremonies, everything else is workflow
execution.

## 4.7 Documentation model

The mesh ships **four documentation artifacts, total:**

| Artifact | What it answers | Audience |
|----------|----------------|----------|
| **The Standard** (`FIDUCIAL-MESH-STD-001`) | "What IS the system?" — formal contract; numbered requirements with Verification lines | Implementers, auditors, alternative-implementations, future agent sessions |
| **The Handbook** (`FIDUCIAL-MESH-HDBK-001`, *this document*) | "Why is the system shaped this way?" — non-normative rationale, worked examples, design history | Architects, evaluating customers, operators reading STD against context |
| **The user guide** | "What DOES the system do?" — conceptual operations narrative | Operators, evaluating customers |
| **The workflow matrix** | "How do I DO things?" — registry-derived executable index | Anyone running a Mesh |

**No traditional admin guide. No step-by-step install procedure. No
operations runbook PDF.** The workflows ARE the procedures.

| What that displaces | Replaced by |
|---------------------|-------------|
| Installation guide | `fiducial-mesh-deployment-*` workflows + the bootstrap step |
| Configuration reference | Workflow parameter declarations (auto-discoverable) |
| Operations runbook | `fiducial-mesh-operations-*` workflows |
| Administration manual | `fiducial-mesh-administration-*` workflows |
| Troubleshooting guide | `fiducial-mesh-diagnostics-*` workflows |
| API reference | Auto-generated from MCP schemas |

The workflow matrix is registry-derived — not hand-maintained. When
a workflow is added or changed, the matrix updates automatically.
This is the model self-describing platforms (Kubernetes / Arch /
Terraform) use; it rejects the OpenStack-style "10,000 pages of stale
admin docs."

## 4.8 The dogfood story — KI7MT lab as tenant #1

The KI7MT AI Lab is structurally **becoming** one specific Mesh
deployment — the one where Fiducial Mesh itself is built. The
target shape is: same PCS registry, same validation harness, same
governance gates as any customer deployment. **Today's honest
state**: the lab dogfoods the pillars that exist (IBX, IAM scaffold,
MCC backend, AKB partial — each under its own declared transitional
deviation per the §3.x status lines), and the PCS layer that
mechanically anchors the dogfood claim is **specified in §6
(written) but not yet built** — implementation stage. The "tenant
#1 by construction" framing is true *as the PCS layer is
implemented*; today it holds for the pillars already operational
under their deviations, and is aspirational for the PCS layer that
will realize it fully once PCS is built to §6.

Lab projects are tenants in the Lab Mesh: `ki7mt-lab-fm-dev` (mesh
development), `ki7mt-lab-ionis` (IONIS-AI), `ki7mt-lab-qsograph`
(QSO-Graph MCP fleet), `ki7mt-lab-substrate` (substrate operations),
`ki7mt-lab-research` (paper drafts).

Lab workflows reference specific lab hardware (`9975WX`, `M3`, `EPYC`),
specific IPs (`10.60.1.1`, DAC subnets), specific paths
(`/mnt/ai-stack`, `/Users/gbeam/workspace`), and the lab's own Vault
and PKI. They would not run on anyone else's setup — that's not a
portability bug, that's the whole point. **Lab workflows stay internal;
the OSS plugins they compose stay public.**

This is the **plugin-vs-workflow open-vs-private boundary** in
practice:

| Layer | Generic? | Portable? | OSS? | Lives where? |
|-------|----------|-----------|------|--------------|
| Plugins | Yes | Yes (cross-vendor common core) | Yes (GPLv3, public) | Public OSS reference plugins in `fiducial-mesh-*` namespaces |
| Workflows | No (deployment-specific) | No (hostnames, paths, IPs baked in) | Operator-owned (private by default) | Stays in the operator's mesh registry |

KI7MT Lab dogfoods the same artifacts every customer gets — for the
pillars that exist, under their declared deviations. The workflows
the lab uses daily become the proof for those pillars. "The lab IS
the reference implementation" — **mechanically true at the PCS
layer once PCS is built to §6** (the spec is written; the
implementation is the remaining step); mechanically true today only for the
pillars that have landed normatively (IBX §5.1, IAM §5.2 under the
identity-by-brief deviation, MCC §5.8 host frame under the
partial-load deviation, AKB §5.5 under partial-load) and the
deviations they operate under. Naming the present-tense gap is the
honesty the dogfood claim earns.

---

# Part 5 — Appendices

Reference material. Tables and lookup, not narrative.

## Appendix A — Glossary

> **STD cross-reference.** Acronyms with a numbered-pillar binding
> (ACT, AIR, AKB, ARCA, BOM, CLCA, CRB, DPG, IAM, IBX, MCC, MCP,
> PCS, PCT, PGE, etc.) are also defined in STD-001 §3.1 — the
> Standard's definitions are authoritative. This Handbook glossary
> adds **narrative-only terms** not in the Standard (Cardinal rule,
> DAC, Default manifest, Dogfood, Free target, Plugin-loadout,
> Role-loadout, Tenant namespace, Tested variation, Workflow as
> rationale-shape).

| Term | Meaning |
|------|---------|
| **AIR** | After-Incident Report — blameless post-mortem stored in AKB |
| **ARCA** | Agentic Root CA — offline issuance authority for agent identity (IAM pillar component) |
| **BOM** | Bill of Materials — a versioned signed registry artifact pinning a coherent plugin set (Maven term) |
| **CLCA** | Closed Loop Corrective Action — Ford 8D discipline; identify defect → action plan → fix → verify |
| **Cardinal rule** | A PCS plugin is a strict superset of an Anthropic Claude Code AND OpenAI Codex plugin |
| **DAC** | Direct Attached Connection — point-to-point 10 Gbps interconnect used in the KI7MT lab |
| **Default manifest** | The known-good baseline catalog every fresh Mesh starts with; a BOM |
| **Dogfood** | The KI7MT lab being tenant #1 in its own Mesh; we use what we ship |
| **Free target** | A surface (Copilot CLI / Coding Agent) that consumes the PCS common core without additional codegen |
| **Mesh-internal namespace** | One of the five `fiducial-mesh-*` namespaces (deployment / configuration / operations / administration / diagnostics) |
| **PCT** | Principal Control Token — the nine-field IBX message-from-Principal-to-Singleton artifact |
| **Plugin** | The portable bundle (cross-vendor common core + PCS extensions); unit of distribution |
| **Plugin-loadout** | The set of plugins loaded into an agent session; determines the agent's role |
| **Role-loadout** | Synonym for plugin-loadout (the role-as-toolset framing) |
| **Tenant namespace** | A namespace owned by a tenant (e.g. `qso-graph`, `ionis-ai`, `<customer-X>`) |
| **Tested variation** | A non-default BOM the mesh maintainers have validated (e.g. `default-mesh-bom-oracle`) |
| **VMA** | Vendor-Mediated Architecture — the cloud-agent-platform shape Fiducial Mesh exists to replace |
| **Workflow** | A composed, parameterized, version-controlled operation; unit of operation |

## Appendix B — Language map

> **STD/HDBK boundary.** The Standard is **language-neutral at
> the contract layer** per STD-001 §1; pillar requirements shall
> not mandate an implementation language. This Appendix documents
> the **project's reference-implementation choice** — what *we*
> build to. A customer using a different language for any pillar
> remains conformant on the same terms (passing the per-pillar
> Conformance Profile test set per STD §0.4 + §5.x.1). The C#
> exclusion below is a project-level reference-implementation
> choice, not a Standard requirement.

Canonical per-pillar language assignment. Python is the default;
non-Python deviations are argued explicitly. C# is purged from the
canon.

| Layer / pillar | Language | Notes |
|----------------|----------|-------|
| IBX | Python | Default |
| AKB | Python | Default |
| ACT — Detect Layer | Python | Default; transitional deviation per `[FM-ACT-0008]` until operational |
| ACT — Record Layer | Python | Default |
| IAM | Python | Default; watch for argued deviation in PKI / AD area |
| PGE | Python | Default |
| CRB | **Go** | Sanctioned — hot concurrent broker |
| DPG (driver) | **Go** | Sanctioned — driver layer for OCI / containerd integration |
| DPG (sandbox runtime) | adopted microVM (Podman floor → gVisor → Kata ceiling) | Adopted, not built |
| MCC-TUI | (Claude Code / Codex) | Not built by mesh; mesh ships PCS plugins for it |
| MCC-UI | **JS/TS SPA** | Browser context is the argued deviation |
| MCC backend | Python | Default |
| Mesh-CLI / installer | **Go** static binary OR Claude Code + PCS plugins | "Mesh-CLI is a configuration, not a product" |
| All MCP servers | Python | `<service>-mcp` PyPI suffix |
| Workflows + plugins | Python (skills are `SKILL.md`; agents are markdown+YAML or TOML) | Cross-vendor common core |

## Appendix C — Conformance criteria

> **STD anchor.** The **authoritative** conformance criteria for
> each pillar are the per-pillar **Conformance Profile** in STD-001
> §5.x.1, exercised against the §0.4 verification methods and the
> per-requirement Verification lines (`Conformance-test` /
> `Inspection` / `Static-check`). The six non-negotiables below are
> a **narrative summary** of the cross-cutting acceptance criteria
> every pillar inherits — they map directly to numbered STD
> requirements. PCS plugins inherit the analogous discipline
> through the tiered validation harness (§2.7); the §6 PCS plugin
> requirements codify that harness as numbered requirements
> (`[FM-PCS-0001..0018]`).

**Pillar-spec acceptance criteria (six non-negotiables) with STD bindings:**

1. **Secure** — credential handling per `[FM-IAM-0006]` Vault
   in-boundary signing; no injection surface (§0.5 Static-check);
   HTTPS-only per each pillar's Conformance Profile transport seam;
   parameterized SQL; input validation; rate limiting.
2. **Instrumented-by-default** — OTLP traces + metrics per the
   per-pillar telemetry requirement (`[FM-IBX-*]`, `[FM-IAM-0012]`,
   `[FM-PGE-0014]`, `[FM-ACT-0012]`, `[FM-AKB-0014]`,
   `[FM-DPG-0014]`, `[FM-CRB-0013]`, `[FM-MCC-0014]`); each pillar
   names its `mesh.<pillar>.*` namespace.
3. **JSON logs** — structured JSON to stderr with required keys
   (`timestamp`, `level`, `message`, `service.name`, `service.version`,
   `trace_id`, `span_id`, `identity`, `session`); part of each
   pillar's telemetry requirement.
4. **CLI-first, UI-second** — every management function runnable on
   CLI/API before any UI exists per `[FM-MCC-0008]` (UI is a strict
   subset of frame API; the UI is documentation-by-example for the
   contract, never a parallel control surface).
5. **Audit emission** — accountability events for every state-
   affecting operation, bound to the `[FM-ACT-0009]` emission-
   confirmation contract (`[FM-IBX-0012]`, `[FM-IAM-0013]`,
   `[FM-PGE-0008]`, `[FM-AKB-0013]`, `[FM-DPG-0012]`,
   `[FM-CRB-0012]`, `[FM-MCC-0013]`); the operation shall not be
   considered complete until ACT acknowledges the emission per the
   ack sequence; lack-of-ack or negative-ack causes fail-strict per
   `[FM-INV-0002]` / `[FM-INV-0002.1]`.
6. **RHEL-compatible build / runtime substrate** — Rocky 9.7+ /
   Alma 9.7+ / RHEL 9.7+ / UBI 9.7+ only in v1.0–v1.1; no
   `ubuntu-latest`. This is a project-level reference-implementation
   choice per the STD/HDBK boundary (§1.5); the Standard is
   substrate-pluggable per STD §1 — a customer's regulated build
   substrate stays substrate-pluggable on the same terms.

**PCS plugin validation harness (tiered, per §2.7):**

| Tier | Check | Gate or badge |
|------|-------|---------------|
| 0 | Validates as Claude Code AND Codex plugin (vendor-delegated) | HARD GATE |
| 1 | PCS Core (`.pcs/` valid, signature chain, BOM refs) | HARD GATE |
| 2 | Cross-vendor portability | Badge |
| 3 | Workflow conformance | Badge |
| 4 | Operational (security scan, signature freshness, smoke test) | Badge |

## Appendix D — Namespace inventory

**Mesh-internal namespaces** (five — function-split, lifecycle stage):

| Namespace | Role-loadout |
|-----------|--------------|
| `fiducial-mesh-deployment` | installer |
| `fiducial-mesh-configuration` | configurator |
| `fiducial-mesh-operations` | operator |
| `fiducial-mesh-administration` | administrator |
| `fiducial-mesh-diagnostics` | diagnostician |

**Lab tenant namespaces** (KI7MT dogfood):

| Namespace | Scope |
|-----------|-------|
| `ki7mt-lab-fm-dev` | Fiducial Mesh development workflows |
| `ki7mt-lab-ionis` | IONIS-AI workflows |
| `ki7mt-lab-qsograph` | QSO-Graph MCP fleet workflows |
| `ki7mt-lab-substrate` | Lab substrate operations |
| `ki7mt-lab-research` | Research / paper workflows |

**Public tenant namespaces** (us-as-tenant; OSS):

| Namespace | Scope |
|-----------|-------|
| `ionis-ai` | IONIS-AI tooling |
| `qso-graph` | QSO-Graph MCP fleet (13 servers today) |

**Customer tenant namespaces**: `<customer-X>` per onboarded
deployment. Prefix reservation enforced by the customer's mesh
registry, DNS-backed at onboarding.

## Appendix E — PCS plugin manifest reference

The cardinal-rule extension shape (per §2.4):

```
<namespace>-<plugin-name>/
├── .claude-plugin/plugin.json    ← Anthropic-owned, verbatim
├── .codex-plugin/plugin.json     ← OpenAI-owned, verbatim
├── .pcs/
│   ├── plugin.pcs.json           ← PCS extension manifest
│   ├── signatures/
│   └── conformance/
├── workflows/
│   └── <name>.workflow.yaml
├── skills/<name>/SKILL.md        ← open Agent Skills standard
├── hooks/hooks.json
├── .mcp.json
├── agents/<name>.md              ← Claude Code variant
├── agents/<name>.toml            ← Codex variant
├── runbooks/
└── README.md
```

**Cross-vendor common core** (works on both vendors without extra
codegen): vendor manifest(s), `skills/`, `hooks/hooks.json`,
`.mcp.json`, `agents/` (with both `.md` and `.toml`).

**Vendor-only components** (flagged with capability metadata; omitted
gracefully when projecting to the other vendor):
- Claude Code: LSP, monitors, themes, output-styles, `bin/`,
  `settings.json` schema, semver dependency resolution
- Codex: `.app.json` (ChatGPT app / connector)

**Free targets** (consume the common core via the open Agent Skills
standard, no additional codegen):
- Copilot CLI — reads `.claude/skills/` for interop
- Copilot Coding Agent — reads `.github/skills/` + `.mcp.json`

### The `policy:` block in `.pcs/plugin.pcs.json`

The plugin's PCS manifest carries a top-level `policy:` block that
declares the plugin's entire capability surface in one auditable
place. The validation harness reads this once and gates entry; this
is the surface that capability-minimization (§1.7.2) operates against.

```jsonc
{
  "name": "fiducial-mesh-deployment-vault-management",
  "version": "1.4.2",
  "signature": "...",
  "boms": ["fiducial-mesh:default-mesh-bom:2026.06"],
  "provenance": { /* signing identity, harness version, hash chain */ },

  "policy": {
    "tools": [                           // tools the plugin exposes
      "vault.read", "vault.write", "vault.sign"
    ],
    "sandbox": "ephemeral-network-restricted",  // DPG sandbox mode required
    "network": {                         // declared external touchpoints
      "outbound": [],                    // empty = no internet egress required
      "intra-mesh": ["pillar:iam", "pillar:act"]
    },
    "hooks": [                           // lifecycle events the plugin fires
      "PreToolUse", "PostToolUse", "SessionStart"
    ],
    "identity_scopes": [                 // IAM scopes a calling identity must hold
      "vault.admin", "pillar.iam.read"
    ],
    "judge_gates": [                     // operations requiring Judge approval
      "vault.rotate-root", "vault.purge"
    ],
    "quorum_required": [                 // operations requiring K-of-N quorum (§1.7.3)
      "vault.rotate-root"
    ]
  },

  "components": {
    "skills":   "./skills/",
    "hooks":    "./hooks/hooks.json",
    "mcp":      "./.mcp.json",
    "agents":   ["./agents/"],
    "workflows": "./workflows/"
  }
}
```

**Validation gates run against the `policy:` block:**

- Tier 0 (vendor base): vendor manifests must declare components
  consistent with the `policy:` tool surface
- Tier 1 (PCS Core): `policy:` block must be present, signed, internally consistent
- Tier 2+: `policy.sandbox` must match a supported DPG sandbox mode;
  `policy.network` cannot declare egress the deployment's PGE overlay
  forbids; `policy.identity_scopes` must map to IAM-defined scopes;
  `policy.quorum_required` operations must be enforceable

One declaration, machine-readable, auditable, gateable at the
validation harness. Operators and compliance auditors read the
`policy:` block to know what a plugin can do without reading code.

## Appendix F — Cross-pillar binding matrix

> **STD anchor.** This Handbook appendix is the **narrative
> companion** to STD-001 **Appendix D — Normative cross-pillar
> binding matrix** (currently Reserved; will be filled alongside the
> §5 / §6 requirement-by-requirement mapping). Where STD Appendix D becomes
> the requirement-by-requirement mapping, this Handbook table is
> the workflow-moment view of the same composition. The STD
> Appendix D, when filled, is authoritative.

How PCS workflow execution touches each pillar:

| Workflow moment | Pillars engaged + STD bindings |
|-----------------|--------------------------------|
| Operator triggers a workflow via agent | IBX (request lands) per `[FM-IBX-0007]` worker-pool dispatch; IAM (who's asking, what's authorized) per `[FM-IAM-0011]` identity-context |
| Workflow execution begins | DPG (sandbox provisioned) per `[FM-DPG-0002]` five ephemeral-isolation properties; IAM (run-as identity bound) per `[FM-DPG-0006]` runner identity |
| Workflow consults a runbook / skill | AKB (read context, lessons learned) per `[FM-AKB-0001]` two-tier delivery + `[FM-AKB-0004]` substrate-trap pre-filter; PGE (allowed?) per `[FM-PGE-0005]` double-guardrail |
| Workflow emits events | ACT (telemetry captured) per `[FM-ACT-0009]` ack contract; IBX (cross-agent coordination msgs) per the §5.1 message-shape |
| Workflow completes | ACT (final state) per `[FM-ACT-0009]`; AKB (outcomes stored) per `[FM-AKB-0008]` promotion gates; IBX (notify dependent agents) |
| Incident occurs during execution | ACT → AIR drafted → AKB per `[FM-AKB-0012]` AIRs as Tier-1 corpus → CLCA per `[FM-PGE-0011]` divergence-derivation → new workflow version → registry per `[FM-DPG-0009]` Registry-bound validation |
| Workflow version evolves | IAM (publish auth) per `[FM-IAM-0008]` Publish pipeline; PGE (policy gates) per `[FM-PGE-0005]` + `[FM-PGE-0010]`; registry update |
| Operator reviews the whole story | MCC (UI surfaces all of it) per `[FM-MCC-0007]` web admin UI + `[FM-MCC-0008]` UI-strict-subset-of-API |
| Workload placement | CRB (hardware-aware dispatch) per `[FM-CRB-0003]` policy contract + `[FM-CRB-0009]` isolation-tier eligibility-input with explicit pre-dispatch validation |

## Appendix G — Working notes (provenance)

Design dialogue, AIR reports, draft material that produced this
Handbook and the companion STD-001 remain in `fiducial-mesh/devel/
spec-drafts/` (kept for provenance; not part of the canon — the
canon is STD-001 + this HDBK).

**The per-pillar spec drafts** (`IBX-SPEC.md`, `IAM-CORE-SPEC.md`,
`ACT-SPEC.md`, `PGE-SPEC.md`, `CRB-SPEC.md`, `DPG-SPEC.md`,
`AKB-SPEC.md`, `MCC-SPEC.md`) **are superseded** by the
corresponding STD-001 §5.x sections; they are retained as
historical reference for the trajectory but are no longer the
authoritative pillar specs. The current canonical pillar spec for
each is its STD-001 §5.x section + §5.x.1 Conformance Profile.

Notable design-trajectory documents (all in `devel/spec-drafts/`;
all superseded by the current canon but retained for provenance):

| Document | What it captured |
|----------|------------------|
| `MANIFESTO.md` | Design drivers from operational practice |
| `DESIGN-PHILOSOPHY.md` | The capability/constraint duality |
| `TECHNICAL-OVERVIEW.md` | External-facing architecture summary |
| `IDENTITY-PILLAR-DESIGN.md` | IAM foundational design |
| `CONCURRENCY-AND-ARCHETYPES.md` | Worker / Reasoner / Quorum-Voter archetypes (now bound to per-pillar §5.x) |
| `PCS-PLATFORM-REDESIGN-NOTES.md` | The 2026-06-08 PCS redesign conclusions doc (input to §6 PCS) |
| `LANGUAGE-POLICY-AND-CANON-CLEANUP-2026-06-08.md` | The consolidated language-policy + C#-purge + categorization plan (now reflected in STD §1 language-neutral clause + HDBK §1.5 / Appendix B) |
| Per-pillar drafts (8 files above) | Full pillar detail; superseded by STD-001 §5.x sections (12–14 numbered requirements + Conformance Profile per pillar) |

---

*End of Fiducial Mesh Handbook v1.1.*

The Handbook is the rationale / worked-example / narrative
companion to the normative Standard (`FIDUCIAL-MESH-STD-001`).
The Standard is authoritative; this Handbook is read-against-it.
Working notes preserved in `devel/spec-drafts/` for provenance.
