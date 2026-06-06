---
title: "CRB Spec — Compute Resource Broker Pillar Contract"
doc_type: spec
status: validated
version: v1.1
authors:
  - watson
  - patton
  - bob
date: "2026-06-05"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/PILLAR-NAMES.md
  - planning/PRODUCTION-VALIDATION.md
  - planning/MANIFESTO.md
  - planning/TECHNICAL-OVERVIEW.md
  - planning/CONCURRENCY-AND-ARCHETYPES.md
  - planning/IBX-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/DPG-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/MESH-SPEC.md
---

# CRB Spec — Compute Resource Broker Pillar Contract

**Scope**: Formalizes the contract for **CRB** (Compute Resource Broker), the Control-Plane pillar that provides hardware-aware workload dispatch across the mesh compute fleet. Covers the **workload classification taxonomy** (per `MANIFESTO.md` v0.6 §6.2 — GPU-bound, DB-bound, reasoning-bound, mixed), the **dispatch policy contract** (how a workload's classification maps to a target host), the **hardware topology model** (the host inventory and DAC routing fabric the broker schedules against), the **substrate substitutability** (the DAC + per-host-venv reference substrate at v1.0 → Nomad/Slurm/Kubernetes-equivalent admissible per the Exit Test), and the **coupling boundaries** with IBX (dispatch requests as PCTs), IAM (broker daemon identity when built), ACT (dispatch event audit emission), DPG (clean seam — CRB dispatches to *where*; DPG isolates *how*; orthogonal concerns), and Workforce (the agents emitting workloads).

**Status**: **Validated v1.1** — seventh (final) instantiation of the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md`, merged 2026-06-05 at `9c67f57`); with this, all 7 pillar v1.1 refreshes are complete. v1.1 adds the per-pillar manifest layer (§ Substrate Matrix + § Telemetry Contract) instantiating the mesh-level contracts in `MESH-SPEC.md` (MI-8, MI-11, § Tested Substrate Profiles); CD13 + CD14 record the v1.1 commitments. The v1.0 contract surface (classification taxonomy, dispatch-policy contract, hardware topology model, substrate substitutability, coupling boundaries, CD1–CD12) is **unchanged** — v1.1 is **purely additive** (no substrate-of-record change). CRB is **design-stage** — the broker daemon is not built; CRB is codified-by-convention (per Patton's watch-out #1). The Substrate Matrix names *seams the broker build will have*, every row design-stage. Capability-framing applies throughout (Patton's PR #31 lesson), most sharply on the accelerator-runtime seam (the taxonomy's `gpu_bound` is the accelerator-compute capability, not a CUDA lock-in).

**v1.1 adds (additive manifest layer):**
1. **§ Substrate Matrix** — three CRB substrate seams (scheduling/dispatch backend, accelerator runtime, telemetry sink) as the substitutability boundary per MI-8 + CD15 (CD13). Complements the existing § Substrate Substitutability (Patton's watch-out #2) — that section is the dispatch-backend Exit-Test narrative; the matrix is the formal manifest.
2. **§ Telemetry Contract** — `mesh.crb.*` spans/metrics/log events per MI-11, with the MI-1 (`crb.*` audit to ACT) vs MI-11 (observability) distinction (CD14).
3. **§ Acceptance Criteria** (renamed from § Success Criteria) — prepends the 5 non-negotiables; the v1.0 CRB-specific success criteria are retained below.

**Prior status (v1.0, retained)**: Item 5b of the spec-campaign queue (per Patton's `87d77f55` + ruling `251c9511` that DPG and CRB are separate; CRB after DPG). The CRB pillar is **operationally codified-by-convention today, NOT yet automated by a broker daemon** — same design-vs-built framing the IAM spec used. Per `PRODUCTION-VALIDATION.md` v1.1 §CRB: *"CRB is operationally codified by convention, not yet automated by a broker daemon. Workload assignment lives in `CLAUDE.md` and the per-agent execution context, and is reliable in practice today; a future CRB spec will land daemon-process automation. Until that lands, the pillar's 'validation' claim is that the dispatch* discipline *is in production, not that a CRB-daemon is."* This spec is the formal contract for *what gets built* when the broker daemon implementation begins; the **ruling-dependent parts** (broker bootstrap credential, per-session credential format, in-flight dispatch handling on broker session termination, per-broker concurrency cap) stay marked **Deferred-Pending-Increment-2-Rulings** per the spec-campaign discipline.

**Patton's two watch-outs for this spec, addressed explicitly throughout the body** (per his `4759a355` forward note):

1. **Design-vs-built honesty**. CRB-as-pillar today is *convention*, not code. The spec body never reads CRB as "having a daemon" — every reference to the broker daemon is explicit about its build-target status. The same discipline IAM v1.0 used for the briefs-only IAM implementation applies here.
2. **Exit Test boundary clarity**. CRB's substrate-substitutability is its load-bearing architectural claim: the DAC + per-host-venv reference substrate at v1.0 must support migration to Nomad / Slurm / Kubernetes-class schedulers without contract revision. The contract is what CRB commits; the substrate is what the deployment satisfies. This watch-out gets its own dedicated section (§ Substrate Substitutability).

**Clean seam with DPG explicitly preserved (refined per Einstein finding #2 `dc6ca481`)**: CRB and DPG own **orthogonal concerns** but their **decisions couple at workload level**. CRB answers *where to run* (which host, by hardware classification). DPG answers *in what isolation boundary* (ephemeral, per § DPG-SPEC.md v1.0). The *concerns* are separate — CRB never provisions isolation; DPG never routes by host class. The *decisions* are coupled — when an isolation tier (DPG-side) is only satisfiable on a host class (e.g., GPU-passthrough microVM on hosts with PCIe-isolated GPUs), that constraint feeds CRB's eligibility filter as an input. A single workload may require both — CRB routes it to 9975WX because GPU-bound *and* because the requested isolation tier is satisfiable there; DPG isolates it on 9975WX in the ephemeral boundary. The two pillars compose at the workload level; they do NOT subsume each other. Per Patton's ruling `251c9511` (refined by Einstein cross-substrate pass), this seam is structural (different concerns, different failure modes, different Exit Test boundaries) and is preserved in this spec by never letting CRB take on DPG's isolation concerns or vice versa — but the decision-time eligibility-input direction is named explicitly so the orthogonality is not over-claimed.

## Purpose / Problem Restatement

Per `MANIFESTO.md` v0.6 §6.2 ("The Workload Classification driver — CRB scope"): **most the mesh work is not GPU-bound.** It's database analytics, agent reasoning, document workflows, and audit. The bottleneck isn't "not enough compute" — it's **lacking visibility into which workloads can run in parallel on existing compute**.

The lab's hardware fleet is heterogeneous on purpose:
- **9975WX (Threadripper, control node)** — 32C/64T, 128 GB DDR5, **RTX PRO 6000 96 GB**, ClickHouse, Newton (Llama 3.3 70B), all CUDA workloads
- **M3 Ultra (Mac Studio, sage node)** — 96 GB unified memory, MPS backend, IONIS training
- **EPYC 7302P (forge node, replica/backup)** — 16C/32T, 128 GB DDR4 ECC, Mellanox 25 GbE
- **DAC network** (10 Gbps point-to-point, MTU 9000) — Thunderbolt 4 (M3↔9975), x710 SFP+ (9975↔Proxmox, 9975↔TrueNAS)

Different workload classes have natural hosts: GPU-bound goes to 9975WX (only host with the RTX PRO 6000); MPS training goes to M3 (only host with the Mac unified memory); ClickHouse queries go to 9975WX (substrate is there); reasoning-bound work runs anywhere a Python venv exists. **Today the dispatch happens by operator/agent convention** — Watson knows training runs on M3; Bob knows CUDA work runs on 9975; both know ClickHouse lives on 9975 over DAC. The convention is reliable in practice but lives **in `CLAUDE.md` and the per-agent execution context**, not in code. CRB-as-pillar is the spec for turning that convention into a fleet-callable dispatch service when the broker daemon is built.

**Two architectural guarantees CRB commits**:

1. **Hardware-aware dispatch**: every workload that requires specific compute resources (GPU, large unified memory, ClickHouse substrate, etc.) is routed to a host that can satisfy them. The broker dispatches against a hardware inventory; the workload's classification determines target eligibility; the dispatch decision is auditable through ACT.
2. **Workload classification as first-class concept**: The mesh has at least three primary workload classes (GPU-bound, DB-bound, reasoning-bound) and a fourth catch-all (mixed). CRB-as-pillar commits the classification taxonomy as the substrate for dispatch decisions. The taxonomy is bounded (curation event to extend) and structural (every dispatch request declares its class).

**Current implementation gap, named explicitly**: today (2026-06-02) the lab has **no broker daemon**. Dispatch happens by operator/agent convention recorded in `CLAUDE.md` § Infrastructure and `CLAUDE.md` § AI Agents. The convention works at the lab's current scale (single-operator + N-agents, four hosts, three workload classes). The implementation gap closes when Bob builds the broker daemon per this spec's contract; until then, CRB exists as a discipline-of-record, not as a service. The spec body defends the design-vs-built line at every reference per Patton's watch-out #1.

## Architecture — Classification + Dispatch Policy + Broker Daemon

CRB-as-pillar has three architectural components that v1.0 commits, plus one substrate primitive the v1.0 reference deployment uses:

| Component | Role |
|---|---|
| **Workload Classification Taxonomy** | The bounded set of workload classes the broker recognizes. Per `MANIFESTO.md` v0.6 §6.2: at minimum GPU-bound, DB-bound, reasoning-bound + a catch-all `mixed` class. Each dispatch request declares its class. Adding a new class requires explicit curation event (mirrors the ACT event-type taxonomy discipline). |
| **Dispatch Policy** | The mapping from workload class to eligible target hosts. Substrate-agnostic — the policy says "GPU-bound → host with NVIDIA GPU + CUDA toolkit installed"; the deployment's hardware inventory determines which actual hosts match. |
| **Broker Daemon** (build target — not yet built) | The service that accepts dispatch requests, applies the classification + policy, selects a target host, dispatches the workload, and tracks the dispatch outcome. v1.0 commits the daemon's behavior contract; today the role is played by operator/agent convention. |
| **Substrate primitive (v1.0 reference)** | DAC routing (10.60.1.0/24 Thunderbolt 4, 10.60.2.0/24 SFP+, 10.60.3.0/24 SFP+) + per-host venv (`$WORKSPACE_ROOT/.venv/bin/python` on every host). |

### Classification / Policy / Daemon separation

v1.0 commits these as architecturally distinct:

- **Classification is workload-side semantic** — every workload has a class. Workloads emit dispatch requests carrying their classification. The classification is meaningful in itself even before any dispatch happens (it expresses what the workload needs).
- **Policy is fleet-side mapping** — for a given fleet's hardware inventory, the policy maps each classification to eligible target hosts. Different fleets (lab, customer A, customer B) have different policies because they have different hardware inventories; the classification taxonomy is the same.
- **Broker daemon is policy executor** — applies the policy to a dispatch request to select a target. Substrate-coupled (depends on the deployment's hardware + network topology) but contract-substitutable (per Exit Test, the broker can be Nomad, Slurm, custom daemon).

The split lets the workload classification evolve independently of any specific fleet's policy; lets the policy adapt to new hardware without changing the taxonomy; and lets the broker implementation swap (per Exit Test) without affecting either upstream concern.

## Workload Classification Taxonomy

v1.0 commits four workload classes. The set is bounded; adding a new class requires explicit curation event (same discipline as ACT event-type taxonomy per `ACT-SPEC.md` v1.0 CD4).

| Class | Definition | Target hardware properties |
|---|---|---|
| `gpu_bound` | Workload requires GPU compute for primary execution (CUDA kernels, neural network training/inference on accelerators). | Host with NVIDIA GPU + CUDA toolkit, GPU memory ≥ requested. Today: 9975WX (RTX PRO 6000). Mac MPS workloads are a sub-class — see `mps_bound` below. |
| `mps_bound` | Workload requires Apple MPS backend specifically (PyTorch MPS, Mac unified memory). | Host with Apple Silicon + MPS-compatible runtime. Today: M3 Ultra. Sub-class of GPU-class workloads where the accelerator family is Apple, not NVIDIA. |
| `db_bound` | Workload requires direct database substrate access (ClickHouse queries against `wspr.*`, `solar.*`, `pskr.*` etc.). | Host with low-latency network path to the database (DAC 10 Gbps preferred over LAN). Today: 9975WX (substrate-local) or any DAC-connected host (9975WX or M3 over DAC). |
| `reasoning_bound` | Workload is primarily agent reasoning + tool calls; minimal infrastructure dependency beyond a Python venv. | Any host with a the mesh-conformant Python venv. Today: 9975WX, M3, EPYC all qualify. |
| `mixed` | Workload combines multiple classes (e.g., training that pulls ClickHouse data and runs CUDA forward passes). | Host satisfying the strictest constraint among the workload's sub-class requirements. Today: 9975WX (only host with both RTX PRO 6000 AND DAC access to ClickHouse). |

### Why this taxonomy (not more, not less)

- **Three primary classes + mixed** is what the lab's current workloads actually surface. GPU-bound (CUDA + training), DB-bound (ClickHouse), reasoning-bound (agent work) — these are the structural shapes. Adding a `network_bound` class for fetch-heavy workloads is tempting but premature: today's fetch-heavy workloads are bounded by reasoning latency, not network throughput. Adding a `disk_bound` class is similarly premature: storage subsystems are fast enough that disk hasn't been the bottleneck.
- **MPS as a sub-class of GPU** matters because Apple's MPS backend is not interchangeable with NVIDIA CUDA. A workload that says `gpu_bound` and lands on M3 will fail at framework load if it expects CUDA; explicitly classifying `mps_bound` prevents that mispairing.
- **Mixed as a real class, not a fallback** — when a workload spans classes, it gets the union of constraints. Mixed is operationally common (training + DB) and deserves first-class taxonomy treatment.

### Adding a new class

Curation event required. Reasonable extension candidates if the lab grows: `quantum_bound` (if a quantum backend is added), `fpga_bound` (if FPGA accelerators are added), `network_bound` (if low-latency-network workloads become primary). v1.0 spec body explicitly does not include these — they are deferred to when they're justified by actual workloads.

## Dispatch Policy

The dispatch policy is the **fleet-specific mapping** from classification to eligible hosts. v1.0 commits the policy contract (what the policy must express); the actual mapping for any deployment is deployment-architecture, not pillar contract.

### Policy contract

The policy is a function: `dispatch_policy(workload_class, workload_constraints) → list[eligible_host]`. v1.0 commits:

- **Pure function**: same workload class + same constraints → same eligible-host list. Re-evaluable; no hidden state.
- **Bounded eligibility**: the eligibility check is decidable in bounded time (no recursive policy resolution; no policy chains).
- **Substrate-aware**: the policy may consult substrate primitives (the hardware inventory, the network topology) but does not depend on broker daemon implementation details.
- **Tiered fallback**: if no host fully satisfies the constraints, the policy emits a `policy_no_match` event (rather than silently falling back to a non-matching host). Workloads stay in queue until a host is added or constraints relax.

### Today's policy (the convention captured in CLAUDE.md, before daemon implementation)

This is the policy operators and agents apply by convention today. v1.0 captures it as the reference policy for the lab's current deployment — but it is **deployment-architecture**, not pillar contract.

| Workload class | Today's target |
|---|---|
| `gpu_bound` | 9975WX (only host with RTX PRO 6000) |
| `mps_bound` | M3 Ultra (only host with Apple Silicon + MPS) |
| `db_bound` | 9975WX (substrate-local) — for queries; over DAC for remote-read workloads from M3 |
| `reasoning_bound` | Per-agent assignment — Watson on M3, Bob on 9975WX, Patton on M3 via Claude Desktop, Newton on 9975WX, Einstein in browser |
| `mixed` | 9975WX (only host satisfying multi-constraint workloads today) |

When the broker daemon is built, this policy is what it codifies on day one. Future hardware additions (e.g., a second GPU host) extend the policy without changing the contract.

### Why the policy is deployment-architecture, not pillar contract

Hardware fleets differ across deployments. The lab has one GPU host today; a customer deployment may have a GPU cluster. The classification taxonomy is the same (workloads still split into GPU-bound, DB-bound, etc.); the *mapping* of classes to eligible hosts differs per fleet. v1.0 keeps the contract about *what the policy must express*, not *what the lab's policy is*. The lab's policy lives in the deployment-architecture doc and updates as hardware changes.

## Hardware Topology Model

CRB models the deployment's hardware fleet as a typed inventory. v1.0 commits the inventory schema; today's lab inventory is the reference.

### Inventory schema

Each host in the inventory has:

| Field | Purpose |
|---|---|
| `host_id` | Unique identifier (e.g., `9975wx`, `m3-ultra`, `epyc-7302p`) |
| `host_class` | Bounded enum: `control`, `sage`, `forge`, `judge`, `worker`. The host's primary role in the mesh control/compute/state planes (per `MANIFESTO.md` v0.6 §0). |
| `os` | Operating system + version (`rocky-9.7`, `macos-15`, `freebsd-13` for TrueNAS, etc.) |
| `cpu` | CPU model + core count |
| `memory_bytes` | Total RAM |
| `accelerators` | List of accelerator records: `{type: cuda \| mps \| fpga, model, memory_bytes, count}` |
| `network_interfaces` | List of NICs with topology context (DAC subnet membership, LAN membership) |
| `storage_classes` | List of storage substrates accessible from this host (`local_ssd`, `zfs_dataset`, `nfs_truenas`, `clickhouse_native`, `clickhouse_dac`) |
| `host_venv_path` | Per-host Python venv path (`$WORKSPACE_ROOT/.venv/bin/python` per `CLAUDE.md` Conventions) |
| `available_runtimes` | List of runtimes available on the host (`python-3.10`, `cuda-12.4`, `pytorch-mps`, `llama_cpp`, etc.) |

### Today's lab inventory (v1.0 reference)

| host_id | host_class | accelerators | DAC membership |
|---|---|---|---|
| `9975wx` | `control` | RTX PRO 6000 (96 GB) | `10.60.1.0/24` (.1), `10.60.2.0/24` (.1), `10.60.3.0/24` (.1) |
| `m3-ultra` | `sage` | Apple M3 Ultra unified memory (96 GB) | `10.60.1.0/24` (.2) |
| `epyc-7302p` | `forge` | none (Mellanox 25 GbE only) | — (LAN only) |
| `proxmox-vm` (future PCS Registry host) | `worker` | — | `10.60.2.0/24` (.2) |
| `truenas` (storage host) | `worker` | — | `10.60.3.0/24` (.2) |

The inventory updates as hardware is added/removed; the schema does not.

## Substrate Substitutability (Per Exit Test — Patton's Watch-Out #2)

The CRB substrate is the **dispatch + execution fabric** — DAC routing today, alternative schedulers tomorrow. Per Patton's watch-out: substrate-substitutability is CRB's load-bearing architectural claim, and getting this right is the difference between a real Exit-Test-conformant pillar and a lock-in defect.

### Substrate options (per Exit Test discipline)

| Substrate class | What it provides | Acceptable at v1.0? |
|---|---|---|
| **DAC routing + per-host venv** (today's lab) | Direct point-to-point network, per-host Python environments, manual dispatch convention | v1.0 reference; convention-based broker (no daemon yet) |
| **Nomad** | Distributed scheduler with workload constraints, host attributes, allocation lifecycle | Acceptable v1.x — would consume the same CRB contract, broker becomes a Nomad job emitter |
| **Slurm** | HPC-style scheduler with resource classes, fair-share queues | Acceptable v1.x — same contract consumption |
| **Kubernetes** | Container-style scheduler with node selectors, resource requests | Acceptable v1.x — broker becomes a k8s controller |
| **Custom daemon** | The mesh-specific broker implementing the v1.0 contract directly against the lab's hardware | Acceptable v1.x — Bob's likely first build target |

**The contract is what holds across substrate change.** Per `MANIFESTO.md` v0.6 §4 Exit Test: a pillar that doesn't survive substrate substitution is a lock-in defect. The CRB contract — classification taxonomy + policy function shape + inventory schema — must be expressible in every substrate above. v1.0 commits this property and adds the dedicated success criterion (per § Success Criteria below).

### Why DAC + per-host-venv is the right reference substrate at v1.0

- **Operationally validated**: the lab has been running on DAC + per-host venv for the entire IONIS Phase-4 and spec-campaign duration. Workloads dispatch correctly; substrate is reliable.
- **Honest scope**: the broker is convention, not code. Saying "DAC + venv" today instead of "Nomad cluster" tells the truth — the lab doesn't need a distributed scheduler yet.
- **Substitutable forward**: when a deployment exceeds the lab's scale (multi-GPU cluster, multi-tenant scheduling), Nomad or Slurm absorbs the dispatch concern without breaking the contract.

### Discipline against premature substrate complexity

v1.0 commits: **the broker daemon implementation, when built, does not prematurely adopt Nomad/Slurm/k8s machinery.** The first build is a the mesh-specific daemon consuming the v1.0 contract directly against the lab's DAC fabric. Later substrates absorb when actual scale demands them. This is the same discipline IBX v1.0 applied to its substrate (ClickHouse today, NATS/Kafka/Redis later); same Exit-Test posture.

## Coupling Boundary: IBX ↔ CRB (Dispatch Request + Result Return)

CRB is **both** a consumer of IBX (dispatch requests arrive as PCTs) and a provider of results (workload-completion notifications return as PCT-bearing messages). v1.0 commits the consume-side and provide-side surfaces against IBX v1.0.

### What CRB consumes from IBX (dispatch request side)

- **Dispatch requests arrive as `action`-priority PCTs** addressed to `recipient=crb-broker` (when the broker daemon exists) or via the existing convention path (operator/agent dispatches directly to the target host — today's reference).
- **Worker-pool dispatch** is NOT the canonical pattern for CRB — broker daemons are singleton-ish (per the Reasoner archetype, not the Worker archetype, per `CONCURRENCY-AND-ARCHETYPES.md` §2). CRB does not need many concurrent broker sessions; one or a small handful per deployment suffice.
- **The PCT carries the dispatch request payload** in field 3 (`context`) and field 5 (`success criteria`). Scope (field 4) declares the workload's classification + resource constraints; authority bounds (field 6) determine whether dispatch routing requires Judge approval (high-stakes workloads via Judge gate; routine dispatches do not).

### What CRB provides to IBX (result side)

- **Workload-completion notifications return as `info`-priority PCTs** addressed to the original requester. Payload includes dispatch decision (target host), execution outcome (success/failure), resource usage summary.
- **Status workflow applies normally**: result PCT is sent (`unread`), recipient picks it up (`read`), recipient acts on the result (`in_progress` or `done`).

### Field-by-field PCT shape for CRB dispatch result

The CRB broker emits the result PCT with:

| PCT field | CRB-emitted value |
|---|---|
| **1. principal-id** | The CRB broker's own ARCA-issued agent identity (job code: "compute resource broker") |
| **2. task** | `"dispatch result: <dispatch_id> → <target_host>"` |
| **3. context** | Structured dispatch decision + outcome: classification accepted, policy applied, target host selected, execution start/end timestamps, resource usage summary |
| **4. scope** | The original requester's scope (echoed; the result is bounded to what the dispatch was authorized to do) |
| **5. success criteria** | Echo of the original request's success criteria |
| **6. authority bounds** | None — result is informational; no further gate fires from CRB's result itself |
| **7. version** | `pct-v1` per IBX v1.0 |
| **8. audit** | Provenance chain: original dispatch-request `message_id`, broker's identity, target host id, eligibility-check audit trail |
| **9. validity** | Operationally relevant; default = original request's validity + execution duration; info-priority, so validity is advisory per IBX v1.0 CD5 |

## Coupling Boundary: IAM ↔ CRB (Broker Daemon Identity)

Per `IAM-CORE-SPEC.md` v1.0 (same pattern as PCS-Daemon and DPG): the CRB broker daemon, when built, has its **own** ARCA-issued agent identity (job code: "compute resource broker"). v1.0 commits:

- **The CRB broker daemon does NOT use the operator's credentials** or the requester's credentials. It has its own.
- **The broker's identity is what dispatch decisions are recorded as** at the audit layer. Even if the broker emits dispatch instructions to remote hosts (e.g., SSH to target with a workload script), the broker's identity is the authorizing principal — never the operator's.
- **Authorization to invoke CRB** is checked against the requester's job code at the chokepoint: the broker inspects the originating PCT's `principal-id` and confirms the requester is authorized to dispatch the requested workload class. Workloads requiring scarce/expensive resources may have tighter job-code requirements than routine reasoning-bound workloads.

## Coupling Boundary: ACT ↔ CRB (Dispatch Event Audit Emission)

v1.0 PCS-Daemon and DPG specs introduced the `pcs.*` and `dpg.*` event-type namespaces (with VP-PCS-1 and VP-DPG-1 tracking the cross-spec ACT v1.x curation event). CRB introduces a third namespace: `crb.*`. v1.0 proposes the following events:

- **`crb.dispatch_requested`** — emitted when CRB receives a dispatch request (after submission validation, before policy evaluation)
- **`crb.policy_evaluated`** — emitted when the policy completes evaluation; payload includes the classification, the constraint set, the eligible hosts, and the selected target
- **`crb.dispatch_started`** — emitted when the broker initiates workload execution on the target host
- **`crb.dispatch_completed`** — emitted on workload completion; payload includes outcome (success/failure), resource usage, execution duration
- **`crb.policy_no_match`** — emitted when no host satisfies the constraints; workload stays in queue until policy admits a match
- **`crb.dispatch_request_rejected`** — emitted when CRB refuses to accept a dispatch request (authorization failure, malformed request)

Per ACT v1.0 CD4, the `crb.*` namespace requires an explicit curation event. v1.0 CRB spec tracks the dependency in **VP-CRB-1** below. Following Patton's standing pattern (per his `4759a355`): the ACT v1.x curation event closing VP-CRB-1 should fold the **same single event** that closes VP-PCS-1 and VP-DPG-1, so the enum extension lands in one motion across all three pillars.

## Coupling Boundary: DPG ↔ CRB (Orthogonal Concerns, Coupled Decisions — Patton's Ruling 251c9511 + Einstein Refinement `dc6ca481`)

Per Patton's ruling: DPG and CRB own **separate concerns**. Per Einstein cross-substrate pass finding #2 (`dc6ca481`) and Patton adjudication: the *concerns* are orthogonal but the *decisions* couple at workload level. This section names the seam explicitly so the two pillars cannot drift toward overlap, AND names the decision-time coupling so the orthogonality is not over-claimed.

| Concern | Owned by | Not owned by |
|---|---|---|
| **Where to run** (hardware classification, target-host selection) | CRB | DPG |
| **How to isolate** (ephemeral boundary, validation gates) | DPG | CRB |
| **Workload submission** (the PCT that requests execution) | Either pillar may accept submissions per the request's classification | — |
| **Result return** (workload outcome back to requester) | The pillar that handled the dispatch returns the result | — |

### Orthogonal concerns, coupled decisions (per Einstein finding #2)

The earlier framing — "no arrow between CRB and DPG" — slightly overclaims. The accurate picture: **CRB never provisions isolation; DPG never routes by host class.** The *concerns* don't overlap. But when a workload's isolation tier (DPG-side) is only satisfiable on a host class (e.g., GPU-passthrough microVM only on hosts with PCIe-isolated GPUs; firecracker microVM only on hosts running compatible KVM), that constraint **feeds CRB's eligibility filter as an input**. The dependency runs DPG-isolation-requirement → CRB-eligibility-input, not as a CRB-internal decision. Symmetrically, CRB's target-host choice constrains what isolation primitives are available on that host (a host without `/dev/kvm` excludes microVM-class isolation tiers).

Neither pillar subsumes the other's *concern*; they compose at *decision time*. CRB's classification taxonomy (§ Workload Classification Taxonomy) already carries `gpu_bound`/`mps_bound` and the `mixed` class takes "the strictest constraint among sub-class requirements" — the machinery to express "this isolation tier needs this host class" exists; it's wired to the DPG seam by treating isolation-tier as an additional constraint dimension at policy evaluation. This preserves the ruling `251c9511` (clean separation of concerns) while closing the seam-table overclaim Einstein caught.

### When a workload requires both CRB and DPG

A workload that is *pre-promotion validation* (per PCS-Daemon promotion flow) typically requires both:

1. **CRB dispatches the workload to an eligible target host** (e.g., 9975WX because GPU-bound)
2. **DPG provisions an ephemeral boundary on that host** for the actual execution
3. **DPG runs the workload inside the boundary**, applies the four validation gates
4. **DPG returns the result through the attested channel**
5. **CRB's dispatch is recorded as `success` or `failure`** based on the DPG outcome

The two pillars compose at the workload level; they do NOT subsume each other. A workload that needs CRB but not DPG (a routine training run dispatched to M3 with no isolation gate) is a CRB-only workload. A workload that needs DPG but not CRB (an ad-hoc validation on the host where the broker already exists) is a DPG-only workload.

### What CRB does NOT do (lest the seam drift)

- **CRB does not provision isolation boundaries.** Even when CRB dispatches to a host, the workload runs in whatever environment the host provides. If isolation is required, DPG provides it; CRB does not duplicate.
- **CRB does not validate workload outputs.** Validation is DPG's domain (when isolation + validation is needed) or PGE's domain (when policy compliance is needed). CRB records dispatch outcomes; it does not validate them.
- **CRB does not enforce policy on workload contents.** PGE applies policy at the workload's content level; CRB applies dispatch policy at the resource-routing level. The two policies are distinct and do not overlap.

## Coupling Boundary: PGE ↔ CRB (Authorization at Dispatch Chokepoint)

PGE applies its rule corpus at the dispatch chokepoint:

- **Before dispatch routing**, PGE evaluates the dispatch request against policy: is the requester authorized to dispatch workloads of this class? Is the target host's accelerator allowance compatible with the workload's tier?
- **PGE's rules are the same** as those applied at IBX (per `IBX-SPEC.md` v1.0) and inside DPG (per `DPG-SPEC.md` v1.0 CD8). Single source of policy truth.
- **CRB does NOT carry its own policy corpus.** Routing-level policy decisions are PGE's; CRB consumes the decision.

## Coupling Boundary: Workforce ↔ CRB (Workloads Originate from Workforce)

Workforce agents (Watson, Bob, Patton, Einstein, Newton) are the principal sources of workloads CRB dispatches. v1.0 commits:

- **Workforce agents emit dispatch requests as PCTs** to CRB (when the broker daemon exists) or directly to target hosts per convention (today).
- **Subagent dispatch** (per `CLAUDE.md` § Subagent Policy) is dispatched by the parent agent and may exercise CRB routing if the subagent needs a specific host (e.g., GPU-bound subagent work). When the broker is built, Watson/Bob's subagent spawning APIs may consult CRB for routing decisions.

## Substrate Matrix

**Design-stage caveat first**: this section names the **substrate seams the CRB broker daemon will have when implementation begins**, not seams wired today — the broker daemon is not built (CRB is codified-by-convention per the Status + Patton's watch-out #1). The matrix is the substitutability boundary CRB commits to honor when built (per CD13), not running infrastructure. Wording is **role + version floor** per Patton's PR #31 capability-framing lesson — most sharply on the accelerator-runtime seam, where the alternatives diverge mechanically (CUDA ≠ MPS ≠ ROCm ≠ Vulkan compute).

CRB depends on three substrate seams. Its peer-pillar couplings (IBX, IAM, ACT, PGE, DPG) are governed by their § Coupling Boundary sections, not the matrix. CRB is the **Reasoner archetype** (singleton-ish broker), so it does **not** consume the IBX worker-pool claim queue (per § Coupling Boundary: IBX ↔ CRB) — there is no claim-queue seam.

| Seam | Contract (role + version floor) | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|---------------------------------|-------------------------------------|----------------------------------------|
| **Scheduling / dispatch backend** | Hardware-aware dispatch: classification → eligible-host selection via a pure-function policy (bounded eligibility, tiered fallback with `policy_no_match`); allocation-lifecycle tracking; an inventory-driven eligibility filter | **the mesh custom broker daemon** over DAC routing + per-host venv (v1.0 reference; see § Substrate Substitutability) | Nomad 1.7+, Slurm 23+, Kubernetes 1.29+ — the broker becomes a job emitter / controller against the same CRB contract (per § Substrate Substitutability) |
| **Accelerator runtime** (the compute substrate `gpu_bound` / `mps_bound` workloads target) | Accelerator compute addressable by job-spec; per-job resource accounting (device memory + compute time); multi-device coordination primitive for tensor-parallel workloads. **The taxonomy's `gpu_bound` is the *capability*, not a CUDA lock-in** — a `gpu_bound` workload is satisfiable by any conforming accelerator runtime on an eligible host | **CUDA 12.x** (NVIDIA; 9975WX RTX PRO 6000) + **Apple MPS** (M3 Ultra; the `mps_bound` sub-class) | ROCm 6+ (AMD), Vulkan compute, oneAPI (Intel) — each satisfying the accelerator-compute capability on a host that carries it. The substrate is the *target host's* accelerator; CRB matches workloads to it via the inventory's `accelerators` field, never hard-coding a vendor. |
| **Telemetry sink** (per MI-11; OTLP-on-the-wire) | OTLP traces + metrics; JSON logs to stderr; sink via `OTEL_EXPORTER_OTLP_ENDPOINT` | Grafana / Prometheus / Tempo stack | Azure Monitor / App Insights, Datadog, OCI Monitoring, any OTLP-compatible sink |

**Conformance**: when the broker daemon is built, CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set — for the scheduling backend, the same dispatch battery (classification → expected eligible-host set, `policy_no_match` on no capacity) must produce identical decisions across tested schedulers; for the accelerator runtime, a `gpu_bound` workload must dispatch + account correctly across ≥ 2 accelerator families on hosts that carry them. A seam change that fails any tested profile does not merge (CD15).

**Out-of-set substrates**: a deployment using a scheduler or accelerator runtime not listed is **not covered** by CRB's substitutability claim — new profile (CONF-CD11) + conformance-suite extension + the multi-profile run passing per CD15.

**Relation to § Substrate Substitutability**: that section (Patton's watch-out #2) is CRB's Exit-Test narrative for the dispatch-backend seam; this matrix is the formal manifest. The dispatch-backend row's alternatives are the substrate classes enumerated there.

## Telemetry Contract

Per MI-11, the CRB broker emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr when built; the sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; the mesh does not name the backend. Naming follows the template: `mesh.crb.<operation>` for spans, `mesh.crb.<metric>` for metrics. **Design-stage**: the contract is what the broker emits when built (CRB is codified-by-convention today; no daemon).

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| Accept + validate a dispatch request | `mesh.crb.dispatch.request` | `dispatch_id`, `workload_class`, `requester_identity` |
| Evaluate the dispatch policy | `mesh.crb.policy.evaluate` | `dispatch_id`, `workload_class`, `eligible_host_count`, `selected_host`, `match_outcome` (`matched` / `no_match`) |
| Initiate workload execution on the target host | `mesh.crb.dispatch.start` | `dispatch_id`, `target_host` |
| Workload completes (success / failure) | `mesh.crb.dispatch.complete` | `dispatch_id`, `target_host`, `outcome` |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `mesh.crb.dispatch.latency_ms` | histogram | milliseconds | Policy-evaluation + dispatch-initiation duration |
| `mesh.crb.dispatch.rate` | counter | dispatches | Cumulative dispatches by outcome (`success` / `failure` / `rejected`) |
| `mesh.crb.policy.no_match_total` | counter | count | Cumulative `policy_no_match` events — capacity / inventory-gap signal |
| `mesh.crb.host.utilization` | gauge | fraction | Per-host workload occupancy by class — fleet-balance signal |
| `mesh.crb.queue.depth` | gauge | count | Queued workloads per class awaiting an eligible host |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| `dispatch.decision` | `info` | `dispatch_id`, `workload_class`, `selected_host`, `eligible_host_count` |
| `policy.no_match` | `warn` | `dispatch_id`, `workload_class`, `constraint_summary` |
| `dispatch.request_rejected` | `warn` | `dispatch_id`, `requester_identity`, `reason` (`authz` / `malformed` / `unknown_class`) |
| `dispatch.completed` | `info` | `dispatch_id`, `target_host`, `outcome`, `duration_ms` |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name` = `crb-broker` (resource attribute)
- `service.version` — from `get_version_info` (resource attribute)
- `deployment.environment` — resource attribute (`lab-design-stage` today; `prod-<host>` when built)
- `identity` — the broker's ARCA-issued principal-id (event attribute)
- `session` — the broker's session-id (event attribute)
- `trace_id`, `span_id` — OpenTelemetry standard (event attributes)
- `cost-center` — applied when ACT chargeback is wired (post #22 resolution)

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT` (no specific backend named)
- **Logs**: JSON to stderr (stdout is reserved for the MCP protocol channel)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields

### Distinction: audit (MI-1) vs observability (MI-11)

CRB emits **both** signal classes, kept distinct:

- **MI-1 (audit)** — the **`crb.*` event stream to ACT** (`crb.dispatch_requested`, `crb.policy_evaluated`, `crb.dispatch_started`, `crb.dispatch_completed`, `crb.policy_no_match`, `crb.dispatch_request_rejected`) per § Coupling Boundary: ACT ↔ CRB. The durable accountability record — *what was dispatched where, under whose authority, with what outcome*. The `crb.*` enum extension to ACT is tracked in VP-CRB-1.
- **MI-11 (observability)** — the `mesh.crb.*` spans + metrics + log events above. Operational + fleet-balance + cost-attribution.

The two are separate streams: a dispatch's *accountability* (who dispatched what to which host) lives in the MI-1 `crb.*` stream; its *operational characteristics* (dispatch latency, queue depth, host utilization) live in the MI-11 `mesh.crb.*` stream. Per the template style rule, they are not collapsed.

## Closed Decisions (CDs — v1.0–v1.1 Commitments)

**CD1**: **Three architectural components (Workload Classification + Dispatch Policy + Broker Daemon) plus one substrate primitive** (DAC + per-host-venv reference at v1.0).

**CD2**: **The workload classification taxonomy is bounded** (`gpu_bound`, `mps_bound`, `db_bound`, `reasoning_bound`, `mixed`) and extension requires explicit curation event. Same discipline as ACT event-type taxonomy and DPG workload types.

**CD3**: **Dispatch policy is fleet-specific deployment-architecture, not pillar contract.** Contract commits the policy function shape (pure function, bounded eligibility, substrate-aware, tiered fallback with `policy_no_match` emission); actual mapping per fleet is deployment.

**CD4**: **Hardware topology model is structural** — every fleet has an inventory satisfying the v1.0 schema. Inventory updates as hardware adds/removes; schema does not.

**CD5**: **CRB has its own ARCA-issued agent identity** when broker daemon is built (job code: "compute resource broker"). Same pattern as PCS-Daemon and DPG. Broker never uses operator's or requester's credentials.

**CD6**: **CRB does NOT provision isolation boundaries, validate workload outputs, or enforce content-level policy.** Clean seam with DPG (CRB = where; DPG = how to isolate) and PGE (CRB = resource routing; PGE = content policy). Seam preserved structurally; CRB does not absorb adjacent pillar concerns.

**CD7**: **Substrate substitutability via Exit Test** — DAC + per-host-venv at v1.0; Nomad / Slurm / Kubernetes / custom daemon admissible at v1.x. Contract holds across substrate change. Patton's watch-out #2 addressed.

**CD8**: **Dispatch decision auditability via ACT** — broker emits `crb.*` event sequence per § Coupling Boundary: ACT ↔ CRB. New event-type namespace tracked in VP-CRB-1.

**CD9**: **Tiered fallback emits `crb.policy_no_match` rather than silently routing to a non-matching host.** No silent constraint relaxation; workload stays in queue or surfaces to operator.

**CD10**: **MPS is a sub-class of GPU classification, not a peer.** `gpu_bound` workloads landing on MPS-only hosts fail at framework load; explicit `mps_bound` prevents this mispairing.

**CD11**: **Broker daemon does not prematurely adopt distributed-scheduler machinery** (Nomad/Slurm/k8s). First build is a the mesh-specific daemon consuming the v1.0 contract directly. Later substrates absorb when actual scale demands them. Same discipline as IBX v0→v1.

**CD12**: **Honest design-vs-built framing throughout** (Patton's watch-out #1). CRB is convention today; daemon is build target. Spec body never reads CRB as "having a daemon" or "operational broker"; every reference to the daemon is explicit about its build-target status.

**CD13 (v1.1 — Substrate Matrix is design-stage, capability-framed, CRB substitutability boundary)**: Per MI-8 + § Tested Substrate Profiles + Patton's PR #31 capability-framing lesson. § Substrate Matrix names three CRB substrate seams (scheduling/dispatch backend, accelerator runtime, telemetry sink) as the broker daemon's substitutability boundary. Every row is **design-stage** (CRB is codified-by-convention; no daemon). Contract columns are **capability-framed** — most sharply the **accelerator-runtime seam: the taxonomy's `gpu_bound` is the accelerator-compute capability (CUDA sovereign-ref + Apple MPS for the `mps_bound` sub-class; ROCm / Vulkan / oneAPI alternatives), never a CUDA lock-in**. CRB is the Reasoner archetype (singleton-ish), so it has **no IBX worker-pool claim-queue seam**. The § Substrate Substitutability section (Patton's watch-out #2) is the dispatch-backend Exit-Test narrative; this matrix is the formal manifest. Substitutability under CD15 covers exactly the rows listed; out-of-set substrates require a new conformance run.

**CD14 (v1.1 — Telemetry Contract is design-stage MI-11 manifest; MI-1 `crb.*` audit vs MI-11 observability kept distinct)**: Per MI-11 + the pillar-spec template + Patton's audit-vs-observability stream distinction. § Telemetry Contract names CRB spans (`mesh.crb.dispatch.{request,start,complete}`, `mesh.crb.policy.evaluate`), metrics (`mesh.crb.dispatch.latency_ms`, `.dispatch.rate`, `.policy.no_match_total`, `.host.utilization`, `.queue.depth`), and log events. Every signal is **design-stage**. The two stream classes are distinct: the **MI-1 audit stream is the `crb.*` event sequence to ACT** (durable dispatch accountability, per § Coupling Boundary: ACT ↔ CRB, VP-CRB-1); the **MI-11 observability stream is `mesh.crb.*`** (operational + fleet-balance + cost-attribution). The AC5 audit-emission path (Path A vs Path B) follows `#22` at build time.

## Deferred-Pending-Increment-2-Rulings (DRs)

**DR-CRB-1 (couples to DR-IAM-2)**: **Broker daemon's bootstrap credential at process start.** Same recursive root problem as PCS-Daemon (per `PCS-DAEMON-SPEC.md` v1.0 DR-PCS-1) and DPG (per `DPG-SPEC.md` v1.0 DR-DPG-1). Until DR-IAM-2 resolves, deployment-architecture-configured bootstrap.

**DR-CRB-2 (couples to DR-IAM-5)**: **Per-session credential format for broker sessions.** Same shape as DR-PCS-2 and DR-DPG-2.

**DR-CRB-3 (couples to DR-IAM-4)**: **Session-termination impact on in-flight dispatch.** When a broker session terminates with workloads in-flight, audit invariant (per ACT v1.0 DR-ACT-3 pattern): all events emitted to that point are preserved. Runtime continuation (in-flight workloads remain executing on their target hosts vs are signaled to abort vs are re-dispatched on next broker session start) depends on DR-IAM-4 ruling.

**DR-CRB-4 (couples to DR-IAM-1)**: **Per-broker-identity concurrency cap values.** CRB broker is Reasoner archetype (few concurrent sessions of broad authority); the per-identity concurrency cap mechanism is committed in IAM v1.0 CD4 + IBX v1.0; the *values* depend on Judge's ruling on cap values per tier.

## Validation-Pending (VP)

**VP-CRB-1 (mirrors VP-PCS-1 and VP-DPG-1)**: **ACT extension to absorb `crb.*` event-type namespace.** v1.0 CRB spec proposes the new event-type prefix. Per ACT v1.0 CD4, adding requires explicit curation event. **Cross-spec dependency tracking**: PR #68 (this spec) is the originating reference for the required ACT v1.x curation event, **alongside** PR #66 (PCS-Daemon `pcs.*`) and PR #67 (DPG `dpg.execution_request_rejected`) — per Patton's standing direction (`4759a355` + `294ec70a`), all three should fold in **one shared curation event** to prevent the half-extended-enum failure mode. Pre-curation-event, the broker may emit `act.detection_signal` events with payload-encoded `signal_type=crb_*` (e.g., `crb_dispatch_requested`, `crb_policy_no_match`) per the bounded-fallback pattern shared with PCS-Daemon and DPG.

## Open Questions (genuinely open, v1.0)

**OQ-C1**: **Multi-broker coordination for high-availability deployments.** v1.0 commits the broker is singleton-ish per deployment (Reasoner archetype). For deployments requiring HA (e.g., a production deployment where broker downtime would block agent work), how do two or more brokers coordinate without becoming Worker-archetype-style claim queue contention? Recommendation: leader-election with one active broker + standby; specific mechanism deployment-architecture.

**OQ-C2**: **Cross-fleet routing for federated deployments.** A customer deployment with multiple geographic fleets (US lab + EU lab) may want workloads dispatched to the nearest eligible fleet. v1.0 commits single-fleet-per-broker; multi-fleet routing is post-v1.0.

**OQ-C3**: **Workload priority within class.** When multiple workloads of the same class queue against limited hosts, what priority semantics apply? v1.0 commits FIFO with potential operator-set priority overrides; ML-driven priority (e.g., shortest-job-first) is post-v1.0.

## Failure Modes To Watch

- **Silent mismatch dispatch.** Policy returns a host that nominally matches the constraints but isn't actually capable (e.g., GPU on the host is allocated to another workload). **Mitigation**: policy evaluation includes capacity check, not just type check; `crb.policy_no_match` fires if no host has actual available capacity, not just matching type.
- **Convention drift between operators and broker daemon.** Today's convention (operators dispatch by knowing which host runs what) may not exactly match the broker's policy when daemon is built; sudden change in dispatch behavior could surprise agents. **Mitigation**: when broker daemon is built, the initial policy is the codified-by-convention reference (per § Today's policy table); deviations from convention go through operator review.
- **Inventory drift.** Hardware changes (new GPU, host removal) not reflected in inventory cause dispatches to wrong hosts. **Mitigation**: inventory is a versioned artifact (deployment-architecture); changes require operator review; the broker reads from the latest committed inventory.
- **Policy infinite loop.** Recursive policy resolution (policy A → policy B → policy A) hangs the broker. **Mitigation**: CD3 commits bounded eligibility; no policy chains. Policy is a single function call; recursion is disallowed by structure.
- **Workload misclassification by submitter.** Submitter declares `reasoning_bound` for a workload that actually requires GPU; lands on M3 without CUDA; fails at framework load. **Mitigation**: this is a content-level mismatch CRB cannot prevent structurally. The mitigation is at the workload level (submitter discipline) and at the failure-recovery level (broker re-dispatches with `mixed` classification after first failure). Bounded retry per OQ-C3 priority semantics.
- **DPG seam drift — CRB starts isolation-boundary tasks.** Future CRB version adds workload-isolation features ("CRB provisions a sandboxed venv"). **Mitigation**: CD6 explicit non-commitment + the architectural separation in § Coupling Boundary: DPG ↔ CRB. Code review on any CRB version that adds isolation surface rejects the change.
- **PGE seam drift — CRB starts content-level policy enforcement.** Future CRB version adds content checks ("CRB rejects workloads that look suspicious"). **Mitigation**: CD6 explicit non-commitment + the architectural separation in § Coupling Boundary: PGE ↔ CRB.
- **Substrate-substitution breaks the contract.** A migration to Nomad/Slurm/k8s introduces semantics that break the policy contract (e.g., Nomad's allocation lifecycle doesn't map cleanly to CRB's dispatch lifecycle). **Mitigation**: CD7 substitutability discipline + Exit Test analysis required before substrate migration; CLCA cycle catches contract divergence.
- **`policy_no_match` storm.** A misconfigured policy causes systemic `policy_no_match` emissions, flooding ACT with no-match events. **Mitigation**: operator review of `crb.policy_no_match` rate as a deployment-health signal; rate-limit on no-match emission per workload (don't re-emit on every poll).
- **Convention-period dispatch ambiguity.** Until broker daemon exists, there is no canonical authority for dispatch decisions — agents apply convention but disagreements can surface. **Mitigation**: CLAUDE.md § AI Agents + § Infrastructure are the convention authority; operator (Judge) is the tiebreaker. When broker daemon lands, it codifies the convention and the ambiguity collapses.

## Dependencies

- **`PILLAR-NAMES.md`** v1.1 — CRB pillar entry of record
- **`PRODUCTION-VALIDATION.md`** v1.1 — CRB row records the codified-by-convention status; this spec advances the row to "specification complete (validated)" while preserving the "daemon not yet built" honesty
- **`MANIFESTO.md`** v0.6 — §6.2 The Workload Classification driver names the underlying design question; this spec resolves it into the taxonomy and dispatch contract
- **`TECHNICAL-OVERVIEW.md`** v0.2 — Control Plane framing for CRB
- **`CONCURRENCY-AND-ARCHETYPES.md`** — Reasoner-archetype framing for the broker daemon
- **`IBX-SPEC.md`** v1.0 — IBX provides the dispatch-request and result-return PCT transport
- **`IAM-CORE-SPEC.md`** v1.0 — broker daemon identity model (when built)
- **`ACT-SPEC.md`** v1.0 — `crb.*` events for audit emission; VP-CRB-1 tracks the cross-spec curation event dependency
- **`DPG-SPEC.md`** v1.0 — clean seam preserved per Patton ruling `251c9511`
- **`PCS-DAEMON-SPEC.md`** v1.0 — adjacent pillar in the spec campaign; not a coupling boundary but a parallel CD pattern reference
- **`CLAUDE.md`** § Infrastructure, § AI Agents — the convention authority CRB-as-pillar codifies

## Acceptance Criteria

A pillar spec is not validated until all five non-negotiables (per `planning/PILLAR-SPEC-TEMPLATE.md`) hold, equal weight to security. CRB is **design-stage**; each Measure names the design-stage gap and what becomes testable when the broker daemon build begins.

### 1. Secure

The broker conforms to the security framework (`planning/MCP-SECURITY-FRAMEWORK.md`): credentials in OS keyring / IAM-issued session credential only; no injection surface in the dispatch path; authorization checked at the dispatch chokepoint (per § Coupling Boundary: IAM ↔ CRB + PGE ↔ CRB). **Measure (design-stage)**: when built, `test_security.py` passes + manual audit confirms no credential leakage and that the broker never executes workloads under the operator's or requester's identity (only its own).

### 2. Instrumented-by-default

The broker emits the OTLP traces + metrics of § Telemetry Contract. **Measure (design-stage)**: when built, an OTel Collector observes the full `mesh.crb.*` span + metric sets across a sample dispatch; a missing named span/metric is a non-conformance.

### 3. JSON logs

The broker emits structured JSON logs to stderr with the required keys + trace correlation per MI-11. **Measure (design-stage)**: when built, every stderr line is valid JSON carrying `trace_id` + `span_id`.

### 4. CLI-first, UI-second

Every broker management function (submit dispatch, query dispatch state, list inventory, inspect policy) is runnable on a CLI/API surface before any MCC pane exists; the MCC pane is a thin client per CD14. **Measure (design-stage)**: when built, the full dispatch lifecycle is drivable headless via CLI/MCP; the MCC pane renders only existing CLI/API surfaces.

### 5. Audit emission

The broker emits an accountability event for every dispatch — the `crb.*` event stream per § Coupling Boundary: ACT ↔ CRB (`crb.dispatch_requested` … `crb.dispatch_completed`, plus `crb.policy_no_match` / `crb.dispatch_request_rejected`). Per **Path A** (emission-as-build-standard, default until `#22` resolves to Path B), these land on the MI-1 stream ACT consumes downstream; VP-CRB-1 tracks the `crb.*` enum extension. The author checks `KI7MT/specs#22` at build time. **Measure (design-stage)**: when built, every dispatch has a corresponding durable `crb.*` event sequence from request through completion; a dispatch with no audit trail is a no-bypass violation.

### v1.0 CRB-specific success criteria (retained)

- **Classification taxonomy is bounded and stable across v1.x.** Every dispatch request declares a class from the v1.0 enum; adding new classes follows the curation-event discipline. **Measure**: dispatch-request validation rejects unknown classes; curation-event log records every taxonomy extension.
- **Policy is a pure function.** Same input → same output; no hidden state. **Measure**: integration test in the broker implementation replays a known input set and verifies deterministic eligible-host lists.
- **Substrate substitutability holds.** CRB contract is expressible in DAC + per-host-venv (v1.0 reference), Nomad, Slurm, Kubernetes, and custom-daemon substrates. **Measure**: substrate-swap exercise during deployment migration verifies contract holds; no contract-revision required for substrate change.
- **DPG seam preserved.** CRB does not provision isolation, validate outputs, or enforce content policy. **Measure**: code review on any CRB version proposing isolation-surface additions rejects the change per CD6.
- **PGE seam preserved.** CRB does not carry its own policy corpus. **Measure**: same code-review discipline.
- **Convention codification fidelity.** When the broker daemon is built, its initial policy matches today's codified-by-convention dispatch behavior (per § Today's policy table). **Measure**: parity test — for each workload class, broker daemon's selected host matches operator/agent convention.
- **`policy_no_match` surfaces, doesn't silently fail.** No silent constraint relaxation. **Measure**: dispatch-failure audit shows `crb.policy_no_match` events for unmatched workloads; no dispatches to non-matching hosts.
- **Audit completeness.** Every dispatch has corresponding ACT events from request through completion. **Measure**: ACT query shows complete event coverage for sampled dispatches.
- **Patton dialectical sign-off at v1.0.** Single review gate per the simplified workflow; file-based review per the post-PR-#65 discipline. **Measure**: Patton's sign-off inbox message.

## References

- `planning/MESH-SPEC.md` — mesh-level invariants (MI-8, MI-11, § Tested Substrate Profiles) the v1.1 manifest instantiates
- `planning/PILLAR-SPEC-TEMPLATE.md` — the v1.1 manifest-section template + acceptance criteria
- `planning/PILLAR-NAMES.md` v1.1 — CRB pillar entry of record
- `planning/PRODUCTION-VALIDATION.md` v1.1 — CRB codified-by-convention status
- `planning/MANIFESTO.md` v0.6 — §6.2 The Workload Classification driver
- `planning/TECHNICAL-OVERVIEW.md` v0.2 — Control Plane framing
- `planning/CONCURRENCY-AND-ARCHETYPES.md` — Reasoner-archetype framing
- `planning/IBX-SPEC.md` v1.0 — PCT transport
- `planning/IAM-CORE-SPEC.md` v1.0 — broker daemon identity
- `planning/ACT-SPEC.md` v1.0 — crb.* events; VP-CRB-1 cross-spec dependency
- `planning/DPG-SPEC.md` v1.0 — clean seam
- `planning/PCS-DAEMON-SPEC.md` v1.0 — parallel CD pattern reference
- `CLAUDE.md` § Infrastructure, § AI Agents — convention authority
