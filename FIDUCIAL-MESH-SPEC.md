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

# Part 2 — PCS (Platform Control System)

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
│   └── plugin.pcs.json           ← provenance, signature, BOM refs
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

The workflow IS the propagation — "fixed it locally, didn't propagate"
is structurally impossible. Ford 8D / manufacturing CLCA applied to AI
operations. Every workflow version traces back to the AIR that
motivated it. Mesh customers get one mechanical loop instead of
incident-report-in-PagerDuty + post-mortem-in-Confluence +
action-items-in-Jira + runbook-update-in-GitHub-wiki +
prompt-tweak-from-whoever's-on-call.

## 2.11 Bootstrap — agent-as-installer

PCS workflows manage the mesh; PCS runs on the mesh. The
chicken-and-egg resolves because **the agent IS the substrate**.

A fresh agent (Claude Code, Codex) + the `fiducial-mesh-deployment`
plugin → run the install workflow → end-state is a running mesh. No
external installer. No custom binary. The agent IS the installer.

The only irreducibly human step is `vault operator init` on the host
that becomes Vault-of-record — the unseal keys and root token can't
route through an agent (agent-out-of-secret-path). After that,
everything is workflow execution: `vault-pki-bootstrap` →
`iam-bootstrap` → `pillar-deploy:ibx` → `pillar-deploy:akb` →
`pillar-deploy:pcs-registry` (now PCS-managed from here on).

Pattern matches `kubeadm init` or `pacstrap` — one privileged
bootstrap step gets you to normal-mode platform operations. Difference:
no separate join-cluster binary. The agent is the binary.

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

**The AI gets built ZERO times for MCC.** Everything intelligent
happens in the CLI surface where Claude Code or Codex is already
running. MCC is a control surface over already-existing capabilities,
not a new place to put intelligence. The existing Wails `inbox-ui`
(Judge approve/reject app) is the MCC-UI approval-gate pane in embryo.

Governance rides Claude Code PreToolUse hooks — the seam already used
by `subagent-guard.sh`. PGE/IAM enforcement at the hook layer. Tier-0
profile = dev / low-stakes; destructive ops route through the governed
MCC backend so the Judge gate intercepts before execution.

---

# Part 3 — The Pillars

Eight pillars. PCS reaches each via its published interface (skills,
MCP tools, hooks) — pillars stay zero-coupled, standalone-installable,
and substrate-pluggable. Each section names the substrate matrix (the
seam contract — customer chooses among supported substrates) and what
PCS workflows do with the pillar. Detail beyond what's here lives in
each pillar's individual spec (referenced).

## 3.1 IBX — Inbox Exchange

The control-plane message-routing substrate. Every async hand-off
between agents and every Judge-approval gate routes through IBX. PCS,
PGE, CRB, and the Judge gate route *through* IBX to reach Workforce.
The PCT (Principal Control Token, nine-field schema) is an IBX message;
that's why PCT lives in IBX rather than expanding PCS scope.

**Status**: POC-in-production today (`agent-inbox-mcp` server +
`inbox-ui` Wails desktop app + `messages.inbox` ClickHouse table).
Formal spec at `planning/IBX-SPEC.md`.

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

## 3.2 AKB — Agent Knowledge Base

Role-projected, tier-stratified knowledge retrieval. Agents query AKB
for ranked context relevant to their role and current task; agents also
propose curator-gated updates. Tier-0 content is bounded-prior loaded
at session start; Tier-1 content is gradient-gated mid-reasoning;
substrate-trap-aware retrieval prevents the vector substrate (physics-
blind) from surfacing dead-end content as candidate solutions.

**Status**: built at `KI7MT/akb`; DDL + ingest + akb-mcp server +
Tier-0 generator green. Formal spec at `planning/AKB-SPEC.md`.

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

## 3.3 ACT — Agent Cognitive Telemetry

The immutable, locally-hosted audit ledger. Every reasoning span,
token, tool call, signed action, IAM event, IBX message, quorum vote,
and Judge approval is emitted to ACT. Unidirectional — agents emit;
nothing flows back out except via curator review. ACT is what makes
non-repudiation, per-session forensics, regulatory compliance, and the
dialectical-engine evidence trail mechanically possible.

**Status**: spec validated at `planning/ACT-SPEC.md`; reference
implementation pending.

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
reconciliation, 20/20 tests green). ARCA not yet built. Formal spec
at `planning/IAM-CORE-SPEC.md`.

**Substrate matrix:**

| Seam | Contract | Sovereign reference | Alternatives |
|------|----------|---------------------|--------------|
| Credential store | Vault KV + Vault Database (dynamic creds) | HashiCorp Vault | (cloud KMS / HSM / PKCS#11 if argued) |
| Identity store (Roster) | ANSI SQL + JSONB | PostgreSQL 17+ | (Vault Identity as alternate at scale; operator call) |
| PKI / signing authority | x509 + Vault PKI engine | Vault `pki_arca` + `pki_tls` | (HSM-backed if FIPS) |
| IdP federation | OIDC / LDAP / SAML | pluggable | LDAP/AD (Samba AD DC in the lab), OIDC providers |

**How PCS reaches it.** Every PCS workflow execution runs under an
authenticated identity from IAM. PCS does not implement
authentication; it consumes the verified-principal context from IAM
via standard interfaces. Publishing rights to namespaces are
IAM-scoped — only the prefix-reservation signing identity can publish
under that namespace.

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

---

*Part 3 (The Pillars) fill-in complete. Parts 4 (Operations) and 5
(Appendices) land as subsequent commits.*
