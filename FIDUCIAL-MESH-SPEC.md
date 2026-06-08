---
title: "Fiducial Mesh Specification"
status: draft
version: v0.1
date: 2026-06-08
authors:
  - watson
references:
  - planning/MANIFESTO.md
  - planning/MESH-SPEC.md
  - planning/IBX-SPEC.md
  - planning/PILLAR-NAMES.md
---

# Fiducial Mesh Specification

> Single-document specification for Fiducial Mesh. The mesh is described
> end-to-end in this file; pillar files and design notes are folded in.

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
per `planning/PILLAR-NAMES.md`): **IBX** (Inbox Exchange — message
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
plugins and execute), the **documentation model** (this spec + user
guide + workflow matrix), and the **dogfood story** (KI7MT lab as
tenant #1).

### 5. Appendices
Reference material: glossary, language map per pillar, conformance
criteria, the five mesh-internal namespaces (deployment / configuration /
operations / administration / diagnostics), the PCS plugin manifest
reference, cross-pillar binding matrix, and citation list back to the
working notes (which remain in `planning/` and `devel/spec-drafts/`
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
data sovereignty and deterministic process control. The architecture is
**air-gapped ready and exfiltration hostile** by construction, not by
configuration — sovereignty is not just *where* the workloads run, it is
whether the architecture can be operated without trust-bearing paths to
a counterparty.

## 1.2 The problem the mesh solves

Two failure modes drive every design choice in this spec:

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
durable, or easier to migrate. **A vendor cannot credibly build
vendor-neutral infrastructure** because doing so erodes their own moat.
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

The compliance regimes (SOX, HIPAA, FIPS, defense, finance) map cleanly
*because they were written for human-and-system organizations*. The mesh
satisfies them by reconstructing the accountability fabric they assume.
The framing is deliberately *not exotic*: a well-run regulated
organization already is an orchestration mesh of principals operating
under identity, authority, segregation of duties, audit, and escalation.
The mesh reconstructs that same fabric and makes agents first-class
principals within it. To an auditor: **the AI is held to the same
standard of identity, authorization, and auditability you already hold
your employees to.**

## 1.5 Language policy

Open-source first. Sovereign by construction. Pragmatism over preference.

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
later (crypto / PKI / Samba AD integration may push to a different
runtime) but the case has to be made explicitly and decided, not assumed.

**No C# anywhere in the canon.** The earlier C#-spine assumption is
retired: Fiducial Mesh is OSS, GPLv3, and C# does not fit that posture.
Source code in C# may be retained for reference where it exists in the
lab's history, but no canonical spec component is built in C#, and no
language map row binds a pillar to C#.

**The mesh-CLI / installer** is either a Go static binary OR is
"Claude Code + PCS plugins is the CLI" (per the Mesh-CLI delivery shape
in §2.13). The earlier .NET AOT mesh-CLI plan is retired with the
C#-spine.

The language map per pillar is enumerated in Appendix B.

## 1.6 The eight pillars + four planes

The mesh organizes eight pillars into four planes (see
`planning/diagrams/mesh_architecture_with_identity_and_arca.svg` for
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
agent identity. The dotted-line separation is a deliberate security
property, not tidiness: because ARCA is never in the action path, it
can be kept offline, and an offline authority cannot be attacked over
the network during operation. Runtime verification is local (signature
+ trust chain), never a callback.

**The Control Plane** is the authoritative governing body of the mesh.
Six elements:

| Element | Role |
|---------|------|
| **IAM (runtime half)** | identity verification + authorization. Beneath PGE — authorization consumes verified identity. |
| **PCS** | the action / management layer. Owns plugins, workflows, registry, validation. **Manages every other pillar via the plugin system**, including IAM. |
| **PGE** | deterministic policy enforcement. Double-guardrail — gates intent before IBX, gates execution inside DPG. |
| **CRB** | hardware-aware workload broker. Routes between unified-memory hosts and compute-host GPUs. |
| **IBX** | the message hub. Every Control-Plane pillar and the Judge gate route to Workforce *through* IBX. |
| **Judge (human)** | the human-in-the-loop approval gate for `action` / `urgent` priority messages. First-class architectural element. |

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

## 1.7 How to read the rest of this spec

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

**Working notes preserved for provenance** — design dialogue, AIR
reports, draft material that produced this spec — remain in
`planning/` and `devel/spec-drafts/` in the spec and devel repos
respectively. They are not part of the canon; this single spec is.

---

*Part 1 fill-in complete. Parts 2–5 land as subsequent commits.*
