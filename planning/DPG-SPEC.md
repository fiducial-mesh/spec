---
title: "DPG Spec — Deterministic Proving Ground Pillar Contract"
doc_type: spec
status: validated
version: v1.0
authors:
  - watson
  - patton
date: "2026-06-02"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-TECHNICAL-OVERVIEW.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
  - planning/IBX-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/PCS-DAEMON-SPEC.md
  - planning/CUDA-PREFLIGHT.md
  - planning/MCP-SECURITY-FRAMEWORK.md
---

# DPG Spec — Deterministic Proving Ground Pillar Contract

**Scope**: Formalizes the contract for **DPG** (Deterministic Proving Ground), the Compute-Plane pillar that provides the ephemeral isolation boundary in which agent-emitted code is compiled, tested, and validated before it can touch production state. Covers the **ephemeral-isolation contract** (what the boundary guarantees and what it does not), the **code-execution contract** (Python/CUDA/Bash workloads under deterministic conditions), the **validation gates** any DPG execution must pass before its outputs return through the attested channel, the **return-channel contract** (single attested path from DPG to the rest of SOM, no side-channel exfiltration), the **substrate options** (git worktrees as the v1.0 reference substrate, with containerized DPG via nspawn/firecracker as Exit-Test-substitutable), and the **coupling boundaries** with IBX (execution requests), IAM (DPG runner identity), PGE (double-guardrail enforcement), PCS-Daemon (pre-promotion validation), ACT (audit emissions), and Workforce (the agents that emit code into DPG).

**Status**: **Validated v1.0** — item 5a of the spec-campaign queue (per Patton's `87d77f55` + ruling `251c9511` that DPG and CRB are separate specs; DPG first). The DPG pillar **has an operational precedent** — the **CUDA-preflight flow** documented in `planning/CUDA-PREFLIGHT.md` and `SOM-PRODUCTION-VALIDATION.md` v1.1 §DPG, in which Bob's Phase-4 "High-Heat" CUDA kernels (Maidenhead-to-LatLon, Haversine, Solar Join) were securely compiled and tested within the DPG boundary before touching production `wspr.silver`. The **substrate primitive** is **git worktrees** (per `CLAUDE.md` § Subagent Policy and `SOM-PRODUCTION-VALIDATION.md` DPG verifier path — subagents needing write access use `isolation: "worktree"` for OS-level Git isolation). What does NOT yet exist is the **generalized reusable substrate** that turns the precedent into a fleet-callable service: the CUDA-preflight pattern works ad-hoc per kernel; the DPG-as-pillar contract turns it into a chokepoint any code-emitting agent must pass through. This spec is the formal contract for *what gets built* when the generalized DPG substrate is implemented; the **ruling-dependent parts** (DPG-runner bootstrap credential, per-session credential format, in-flight execution termination semantics) stay marked **Deferred-Pending-Increment-2-Rulings** per the spec-campaign discipline. **v1.0 fold-in (Patton `58db3413`)**: VP-DPG-1 extended with shared-ACT-v1.x-curation-event cross-reference (closes BOTH VP-DPG-1 and VP-PCS-1 in one curation event citing PR #66 + PR #67 — prevents half-extended-enum failure mode); new CD13 commits the runner reconciliation sweep formally (promoted from Failure-Modes prose; analog to PCS-Daemon CD5 rollback-path reconciliation; closes the audit-gap-during-boundary-destruction failure mode as a CD rather than a referenced mitigation).

## Purpose / Problem Restatement

As agents move from read-only reasoning to write-enabled code generation, **the risk of unvalidated execution rises**. Big Tech handles this probabilistically (vendor safety filters on the LLM input/output) or by obfuscating the execution layer in the cloud. SOM rejects both options — the first because vendor-mediated safety filters are not auditable from outside the vendor, the second because cloud-mediated execution gives up sovereignty. DPG is SOM's structural answer: **a local, ephemeral isolation boundary** at which code emitted by agents is compiled, tested, and validated before it can affect anything outside that boundary.

The pillar bridges what `SOM-TECHNICAL-OVERVIEW.md` v0.2 §3 names *the gap between stochastic reasoning and deterministic execution*: agents may reason probabilistically; the code they emit is validated under deterministic conditions in DPG before it touches production state.

**Two architectural guarantees DPG commits**:

1. **Ephemeral isolation**: every execution runs in a single-use boundary. The boundary is created for that execution, used, and destroyed. Nothing persists across executions in the substrate; nothing the execution wrote inside the boundary survives unless it returns through the attested channel. The "ephemeral" property is what makes the boundary safe — even a malicious or runaway execution cannot accumulate state across runs to escape.
2. **Single attested return channel**: DPG executions return their outputs through one canonical path. Side channels (network, filesystem-outside-boundary, IPC) do not exist within DPG, are not provisioned, and are not permitted by the substrate. The return channel is itself attestable — outputs come with a structured execution record that ACT captures, so the question "what did this code actually do" is answerable from the audit trail.

**Current implementation gap, named explicitly**: today (2026-06-02) the lab uses DPG-as-pattern in two places: the CUDA-preflight flow (Bob runs new CUDA kernels in an isolated build + test pass on 9975WX before they touch production), and the subagent `isolation: "worktree"` flag (Watson and Bob spawn subagents in OS-level Git-isolated worktrees per `CLAUDE.md` § Subagent Policy). **There is no DPG-as-service**: no daemon that other pillars call to "run this code in DPG and return the result"; no chokepoint that all code-emitting workflows must pass through; no Worker-pool of DPG runners (per the Worker archetype framing in `SOM-CONCURRENCY-AND-ARCHETYPES.md` §2) that scales with parallel validation demand. The implementation gap closes when Bob builds the generalized DPG runner substrate per this spec's contract; until then, the precedent works ad-hoc, and the spec body defends the design-vs-built line at every reference.

## Architecture — Three Components, One Substrate

DPG-as-pillar has three architectural components that v1.0 commits, plus one substrate primitive that the v1.0 reference deployment uses:

| Component | Role |
|---|---|
| **DPG Runner** | The service that accepts execution requests, provisions the ephemeral boundary, runs the requested code, validates the outputs, and returns the structured execution record. May run as a singleton (one runner) or a Worker pool (many concurrent runners) per the deployment's parallelism needs. |
| **Ephemeral Boundary** | The single-use isolation boundary in which the execution runs. v1.0's reference substrate is a git worktree (per `CLAUDE.md` § Subagent Policy `isolation: "worktree"`); v1.x substrates include nspawn containers, firecracker microVMs, or any substrate that satisfies the ephemeral-isolation contract per the Exit Test. |
| **Validation Gates** | The pass/fail checks applied to the execution's outputs before they return through the attested channel. Includes Syntax conformance (per `pcs-spec`), PGE compliance (per `MCP-SECURITY-FRAMEWORK.md`), test-suite execution (per the requested execution's test specification), and resource-limit attestation (CPU, memory, time, network). |
| **Substrate primitive (v1.0 reference)** | Git worktrees, per the existing precedent. |

### Runner / Boundary / Gates separation

v1.0 commits these three as **architecturally distinct**:

- **The Runner is substrate-coupled** — it depends on whichever substrate primitive (git worktrees, nspawn, etc.) is deployed. Runner code may differ across deployments; the runner's *behavior contract* (accept request, provision boundary, run, validate, return) does not.
- **The Boundary is substrate-specific** — git worktrees, nspawn containers, and firecracker microVMs have different internals. The boundary contract (ephemeral, single-use, isolated) holds across all of them; the implementation differs.
- **The Validation Gates are substrate-agnostic** — they consume the execution's outputs (artifacts, logs, return value) and apply rules that are the same regardless of substrate. Gates compose the same way whether the underlying substrate is a worktree or a microVM.

The split lets each component evolve at its own rate: substrate choice is a deployment decision; runner implementation tracks substrate; gates are reusable across substrate changes.

## Ephemeral-Isolation Contract

v1.0 commits five properties any DPG ephemeral boundary MUST satisfy. These are non-negotiable across substrate choices; a substrate that fails any of them is not DPG-conformant.

### 1. Single-use creation and destruction

- The boundary is **created** for one execution request.
- It is **destroyed** after the execution returns its result (or after a timeout fires).
- **Nothing persists** between executions in the boundary. Two consecutive executions in the same DPG runner see fresh boundaries; the second has no access to the first's filesystem state, memory, or process tree.

### 2. Filesystem isolation

- The boundary has its own filesystem view. Reads from outside the boundary are permitted only via **explicit input declarations** in the execution request (e.g., "this execution needs read access to the source-code repo at this commit").
- Writes from inside the boundary cannot reach outside the boundary except via the attested return channel.
- The substrate enforces the filesystem isolation; the agent code running inside does NOT have to honor the boundary (it cannot violate it even maliciously). Per the architecture's spine of *enforce at the chokepoint, don't trust the consumer*, this is mechanism, not convention.

### 3. Network isolation

- The boundary has **no network access by default**. An execution that needs network resources must declare them in the execution request (specific hostnames, ports), and the runner provisions a network egress proxy that allows only the declared resources.
- The "no network by default" property is what makes DPG a chokepoint against exfiltration: even a malicious execution cannot reach the network unless the request authorized it.
- Inbound network is **never** permitted to DPG boundaries (no listening sockets that anyone outside can reach). The boundary is push-only, not server-style.

### 4. Resource limits

- Every execution runs under explicit CPU, memory, and time limits declared in the request. Exceeding any limit terminates the execution with a `resource_limit_exceeded` result.
- The runner enforces the limits via the substrate's primitives (cgroups for nspawn, firecracker's VM resource configuration, or comparable for git-worktree-based runs with cgroup wrapping).
- Resource limits are themselves part of the execution audit — ACT records the limits in effect plus the actual consumption.

### 5. Process and identity isolation

- The execution runs as a dedicated execution user with no privilege on the host beyond what the boundary substrate provisions.
- The execution **cannot escalate** to the host's user identity; even root-level operations inside the boundary do not affect anything outside it (per the substrate's isolation guarantees).
- The execution's process tree is bounded — child processes spawned by the execution are themselves inside the boundary and terminate with it.

### What the boundary does NOT guarantee (v1.0)

- **Side-channel-attack resistance** (timing attacks, cache-based attacks, Spectre/Meltdown-class) is **not** in scope. v1.0 commits process and substrate-level isolation; cryptographic-grade side-channel hardening is a deployment-architecture concern that scales with substrate choice (firecracker microVMs provide stronger side-channel isolation than git worktrees).
- **Persistent storage** of execution results between executions. DPG is for one-shot validation; if the result needs to persist, it returns through the attested channel and downstream consumers (PCS-Daemon, ACT, PGE) store it durably.
- **Real-time SLA on execution latency**. DPG executions run with declared time limits but do not guarantee a max-latency-to-first-result for the caller; the caller's polling pattern (per IBX `message_id`-stability) absorbs latency.

## Code-Execution Contract

DPG accepts **Python, CUDA, and Bash** code workloads at v1.0 (matching the lab's current code-emission stack — `ionis-training` Python/PyTorch, `ionis-cuda` C++/CUDA, all agent Bash for build/test orchestration). Future workload types (Go, Rust, .NET) are admitted via the same execution-request schema with substrate-appropriate runners; the contract is workload-language-agnostic at the request level.

### Execution request shape

Each DPG execution arrives as an IBX PCT (per § Coupling Boundary: IBX ↔ DPG below) with a payload conforming to the execution-request schema. v1.0 commits the schema:

| Field | Purpose |
|---|---|
| `execution_id` | Unique ID for this execution. Returns with the result for correlation. |
| `workload_type` | `python`, `cuda`, `bash`, or future-type per substrate support. |
| `source_inputs` | List of explicit source-code or data inputs to mount into the boundary. Each input declares its source (e.g., a git commit + path, or an artifact ID from PCS-Registry) and its mount point inside the boundary. |
| `execution_command` | The command to run inside the boundary (interpreted per `workload_type`). |
| `network_requirements` | List of allowed network egress targets (hostnames + ports). Empty list = fully air-gapped boundary. |
| `resource_limits` | CPU cores, memory bytes, wall-clock-time seconds, max-disk-write bytes. |
| `validation_specification` | List of validation gates to apply to the execution's outputs (Syntax, PGE, test-suite, custom). |
| `return_artifact_specification` | List of paths inside the boundary whose contents return to the caller. Anything not listed is destroyed with the boundary. |

### Execution result shape

The result returned through the attested channel:

| Field | Purpose |
|---|---|
| `execution_id` | Echoed from the request. |
| `outcome` | `success`, `validation_failed`, `resource_limit_exceeded`, `crashed`, `timeout`. |
| `validation_results` | Per-gate result records — which gates ran, which passed, which failed, with cited reasons. |
| `resource_usage` | Actual CPU/memory/time/disk consumed. |
| `return_artifacts` | The artifacts from `return_artifact_specification`, packaged into the return channel. |
| `attestation` | Cryptographic signature over the result (per DR-DPG-1 — pending IAM signing). |
| `boundary_audit_summary` | Summary of what the substrate observed (process tree, network calls attempted vs allowed, filesystem reads outside declared inputs). |

### Deterministic execution

DPG commits **deterministic execution semantics where possible**:

- Same inputs + same execution command + same validation specification → same result, modulo external nondeterminism (clock, RNG, network responses that DPG cannot replay).
- Where external nondeterminism is required (e.g., a test that uses random data), the execution request may declare a deterministic seed; the runner provides that seed to the execution environment.
- For CUDA workloads, deterministic execution is **best-effort** — CUDA kernels can have nondeterministic reduction orderings that produce numerical drift. The execution result records the determinism level achieved (`deterministic`, `numerical-drift-only`, `nondeterministic`).

### Validation gates within DPG

v1.0 commits four standard validation gates that the runner applies to every execution. Additional gates are declared per-request in `validation_specification`.

- **Syntax conformance** (`pcs-spec` schemas, applied when the workload type has a corresponding Syntax). For example, an MCP server's metadata is validated against the MCP-server Syntax.
- **PGE compliance** (per `MCP-SECURITY-FRAMEWORK.md`). The runner applies the same security framework rules the Harness applies — keyring credentials only, no subprocess injection surface, HTTPS only, etc. This is the **double-guardrail** PGE applies inside DPG per `SOM-PROBLEM-STATEMENT.md` v0.6 §3 (PGE acts at two enforcement points: agent-action policy before IBX, sandbox-execution policy inside DPG).
- **Test-suite execution** (per the request's `validation_specification`). Standard unit-test/integration-test patterns; pass/fail per test.
- **Resource-limit attestation** — the runner reports actual resource consumption against the declared limits.

A DPG execution **passes** when all four standard gates plus any request-specific gates report success. Any gate failure marks the execution `validation_failed` and prevents the result from advancing to downstream consumers (PCS-Daemon, production state, etc.).

## Substrate Options (Per Exit Test)

v1.0 commits the **Exit Test substitutability** for the substrate primitive. Three substrate classes are admissible:

- **Git worktrees** (v1.0 reference substrate). Lightweight, fast provisioning, OS-level filesystem isolation via git worktree primitives, process isolation via OS user separation. Acceptable at Tier-2; insufficient side-channel isolation for Tier-0 workloads handling sensitive data.
- **nspawn containers**. Linux container-style isolation, stronger filesystem and network isolation than worktrees, intermediate ceremony. Acceptable at Tier-1; arguable Tier-0.
- **Firecracker microVMs**. VM-level isolation, strongest substrate-level guarantees (separate kernel per execution), highest ceremony. Acceptable at Tier-0.

Per `SOM-PROBLEM-STATEMENT.md` v0.6 §4 Exit Test discipline: the substrate change does not change the DPG contract. Whichever substrate the deployment chooses, the five ephemeral-isolation contract properties (single-use, filesystem, network, resource, process+identity) must hold; the runner's behavior contract holds; the validation gates' interface holds. Substrate is a deployment-architecture choice; contract is what this spec commits.

## Coupling Boundary: IBX ↔ DPG (DPG as Consumer + Provider)

DPG is **both** a consumer of IBX (execution requests arrive as PCTs) and a provider of results (execution results return as PCT-bearing messages). v1.0 commits the consume-side and provide-side surfaces against IBX v1.0.

### What DPG consumes from IBX (execution request side)

- **Execution requests arrive as `action`-priority PCTs** addressed to `recipient=dpg:<runner-id>` for routing to a specific DPG runner, or `recipient=pool:dpg-runners` for worker-pool dispatch (per `IBX-SPEC.md` v1.0 § Concurrency-Safe Worker-Pool Dispatch).
- **Worker-pool dispatch** is the canonical pattern for parallel DPG execution. Multiple DPG runners claim from the pool via exactly-once SKIP-LOCKED-style atomic claim per IBX v1.0; lease/visibility-timeout for crash recovery; idempotency keys for safe re-execution; mid-action-safe termination returns claimed-but-not-completed executions to the queue.
- **The PCT carries the execution request payload** in field 3 (`context`) and field 5 (`success criteria`). Scope (field 4) declares what the requester is authorized to ask DPG to do; authority bounds (field 6) name the gate (DPG validation; no Judge gate for routine validations; Judge gate routes to PGE per § Coupling Boundary: PGE ↔ DPG below).

### What DPG provides to IBX (result side)

- **Execution results return as `info`-priority PCTs** addressed to the original requester. Result-PCT payload contains the execution result shape committed in § Code-Execution Contract.
- **Status workflow applies normally**: result PCT is sent (`unread`), recipient picks it up (`read`), recipient acts on the result (`in_progress` or `done`).
- **Worker-pool claim semantics**: when DPG completes an execution claimed from a pool, the runner transitions the original PCT to `done` (success path) or `rejected` (validation_failed path), per IBX v1.0 worker-pool dispatch CD.

### Field-by-field PCT shape for DPG result

The DPG runner emits the result PCT with:

| PCT field | DPG-emitted value |
|---|---|
| **1. principal-id** | The DPG runner's own ARCA-issued agent identity (job code: "DPG runner") |
| **2. task** | `"execution result: <execution_id>"` |
| **3. context** | The structured execution result (per § Code-Execution Contract) |
| **4. scope** | The original requester's scope (echoed; the result is bounded to what the original execution was authorized to do) |
| **5. success criteria** | Echo of the original request's success criteria; useful for the requester to verify |
| **6. authority bounds** | None — the result is informational; no further gate fires from DPG's result itself |
| **7. version** | `pct-v1` per IBX v1.0 |
| **8. audit** | Provenance chain: original execution-request `message_id`, DPG runner's identity, boundary substrate type, validation gate audit trail |
| **9. validity** | Operationally relevant; default = original request's validity + execution duration; info-priority, so validity is advisory per IBX v1.0 CD5 |

## Coupling Boundary: IAM ↔ DPG (Runner Identity)

Per `IAM-CORE-SPEC.md` v1.0 (the same pattern applied to PCS-Daemon): DPG runners have their **own** ARCA-issued agent identity (job code: "DPG runner"). v1.0 commits:

- **DPG runners do NOT use the operator's credentials** or the requester's credentials. They have their own.
- **The DPG runner's identity is what executions run AS** at the substrate level (e.g., the worktree is owned by the runner's identity-derived user account). Even malicious execution code cannot escape to the operator's identity because the runner never held it.
- **Per-session credentials** apply (per IAM v1.0 CD4): each DPG runner session has its own session credential, distinguishing concurrent runners' executions for ACT attribution.
- **Authorization to invoke DPG** is checked against the requester's job code at the chokepoint: the runner inspects the originating PCT's `principal-id` and confirms the requester is authorized to execute the requested workload class. Per `IAM-CORE-SPEC.md` v1.0 § Authorization, "*not authorized" is terminal and correct — the runner halts and emits `execution_request_rejected` rather than reasoning about routing around access controls.

## Coupling Boundary: PGE ↔ DPG (Double-Guardrail Enforcement)

Per `SOM-PROBLEM-STATEMENT.md` v0.6 §3: **PGE acts as a double guardrail** — agent-action policy before messages reach IBX, and sandbox-execution policy inside DPG. v1.0 commits the inside-DPG enforcement:

- **The runner applies PGE rules** (from `MCP-SECURITY-FRAMEWORK.md`) as the second validation gate. The rules executed inside DPG are the same rules PGE applies at the agent-action policy point — single source of policy truth.
- **PGE rules executed inside DPG catch the failure class that intent-side enforcement misses**: code that *looks* compliant at submission but *behaves* non-compliant when executed (e.g., a test that triggers a subprocess injection only at runtime).
- **DPG is the substrate; PGE provides the rules; the runner is the policy executor.** The rule corpus is owned by PGE (item 6 of the spec campaign); DPG's contract is that any rule the PGE corpus contains will be evaluated against every DPG execution.

## Coupling Boundary: PCS-Daemon ↔ DPG (Pre-Promotion Validation)

The PCS-Daemon (per `PCS-DAEMON-SPEC.md` v1.0 § Promotion Flow) calls Harness validation as part of the promotion lifecycle. For workloads that are themselves *executable* (plugins that need to run during validation, MCP servers that need server-side smoke tests), the Harness invocation may itself trigger a **DPG execution** to run the executable validation inside the ephemeral boundary.

v1.0 commits:

- **PCS-Daemon invokes DPG for executable validation steps** by emitting a DPG execution request PCT during the `validating` state of the promotion lifecycle. The DPG execution runs the plugin's test suite, validates outputs, and returns the result.
- **DPG result feeds back to the Daemon** via the result PCT pattern in § Coupling Boundary: IBX ↔ DPG. The Daemon's promotion state transitions reflect the DPG outcome — `validation_failed` from DPG → Daemon transitions candidate to `validation_failed`.
- **The Daemon does NOT bypass DPG for executable workloads** — every plugin or MCP server that includes runtime tests passes through DPG validation. This is the **dev-to-production trust boundary** applied to executable artifacts: the Registry contains only artifacts that have been DPG-validated against the security framework.

## Coupling Boundary: ACT ↔ DPG (Audit Emission)

Per `ACT-SPEC.md` v1.0 CD4, the bounded event-type enum already includes `dpg.code_emitted` and `dpg.execution_complete`. DPG-as-pillar consumes these placeholders and commits emission semantics:

- **`dpg.code_emitted`** is emitted by the **agent that emits code into DPG** (not by DPG itself). This is the upstream signal: agent X submitted code to DPG. ACT records it for attribution at the Workforce layer.
- **`dpg.execution_complete`** is emitted by the **DPG runner** when an execution finishes (success or failure). ACT records it for DPG-side attribution. Payload includes the execution_id, outcome, validation_results summary, and resource_usage (per § Code-Execution Contract).
- **v1.0 proposes one additional event-type for ACT**: `dpg.execution_request_rejected` (when DPG refuses to run an execution at all, e.g., because the requester lacks authorization). Per ACT v1.0 CD4 extensibility, this is a curation-event addition; v1.0 DPG spec tracks the dependency in **VP-DPG-1** below.

## Coupling Boundary: Workforce ↔ DPG (Code Emission)

Workforce agents (Watson, Bob, Patton, Einstein, Newton) are the principal sources of code that enters DPG. v1.0 commits:

- **Workforce agents do NOT execute code in production directly.** Code emitted by Workforce intended to affect production state passes through DPG. This is enforced by PGE at the agent-action policy point (intent-side enforcement) and by IBX/Judge gate (action-priority for promotion).
- **Subagent worktree isolation** (per `CLAUDE.md` § Subagent Policy, `isolation: "worktree"` flag on Anthropic Agent SDK) is a **lightweight DPG** — agent-spawned subagents writing code use OS-level git worktree isolation as a Tier-2-equivalent DPG boundary. Subagent worktrees do NOT yet run the four standard validation gates (Syntax/PGE/test/resource), so they are precursor-to-DPG-as-pillar, not equivalent. v1.0 commits that subagent worktrees graduate to full DPG conformance when the implementation lands.

## Closed Decisions (CDs — v1.0 Commitments)

**CD1**: **DPG is three architecturally distinct components** — Runner (service), Boundary (substrate-specific), Gates (substrate-agnostic) — operating against one substrate primitive (v1.0 reference: git worktrees; Exit-Test-substitutable).

**CD2**: **The five ephemeral-isolation properties are non-negotiable** — single-use creation/destruction, filesystem isolation, network isolation (default no-network), resource limits, process and identity isolation.

**CD3**: **DPG executions accept Python, CUDA, Bash workloads at v1.0**; the execution-request schema is workload-language-agnostic, so future workload types extend via substrate support without contract changes.

**CD4**: **Four standard validation gates apply to every execution** — Syntax conformance, PGE compliance, test-suite execution, resource-limit attestation. Additional gates declared per-request.

**CD5**: **Single attested return channel.** No side channels exist within DPG; outputs come with structured execution records that ACT captures for forensic reconstruction.

**CD6**: **DPG runners have their own ARCA-issued agent identity** (job code: "DPG runner") per `IAM-CORE-SPEC.md` v1.0. Runners never use operator's or requester's credentials; the execution runs as the runner's identity at the substrate level.

**CD7**: **Worker-pool dispatch is the canonical pattern for parallel DPG execution** per `IBX-SPEC.md` v1.0 § Concurrency-Safe Worker-Pool Dispatch. DPG runners are the Worker archetype: many concurrent sessions of one identity, narrow authority, automated. Cap on per-runner-identity concurrency exists (mechanism per IAM v1.0 CD4; values per DR-IAM-1).

**CD8**: **PGE rules are evaluated inside DPG as the second guardrail.** Same rule corpus as agent-action policy at IBX; runner is the policy executor. Single source of policy truth (PGE owns the rules; DPG is the substrate).

**CD9**: **All Registry-touching artifacts pass through DPG validation** for executable workloads. PCS-Daemon's `validating` state invokes DPG for plugins/MCP-servers with runtime test suites. Dev-to-production trust boundary applied to executables.

**CD10**: **Deterministic execution where possible**; same inputs + command + validation spec → same result. Where external nondeterminism is required, declared seeds permit deterministic replay. CUDA workloads admit best-effort determinism (numerical drift allowed; recorded).

**CD11**: **Substrate substitutability via Exit Test.** Git worktrees → nspawn → firecracker microVMs are all admissible substrates; the contract is what holds across substrate change.

**CD12**: **DPG result emits `dpg.execution_complete` to ACT** per ACT v1.0 CD4. `dpg.code_emitted` is emitted by the upstream code-emitting agent, not by DPG. New event-type `dpg.execution_request_rejected` proposed for ACT v1.x curation event (tracked in VP-DPG-1).

**CD13 (per Patton ruling `58db3413` — promoted from Failure Modes prose to a formal commitment by parity with `PCS-DAEMON-SPEC.md` v1.0 CD5)**: **Runner reconciliation sweep for lost completion events.** Analogous to PCS-Daemon's rollback-path reconciliation (per `PCS-DAEMON-SPEC.md` v1.0 CD5), the DPG runner runs an idempotent reconciliation sweep that detects executions whose `dpg.execution_complete` event emission was lost (e.g., the runner process crashed after the boundary destruction completed but before the completion event reached ACT). The sweep:

- **Finds executions in `running` state older than a bounded window** (default: max execution time + grace period; operator-configurable per deployment SLO) **with no corresponding `dpg.execution_complete` event in ACT** AND no live boundary in the substrate.
- **Transitions each such execution to a terminal `dpg.execution_complete` event** with outcome `lost_completion_recovered` and a structured note indicating the reconciliation source rather than a normal completion. The substrate is checked one more time before emission to confirm the boundary is actually gone.
- **Sweep is safe to re-run** — idempotency keys on the recovery event prevent double-emission; a second run sees the recovery event already present and is a no-op.
- **The recovery event is itself emitted to ACT** so the audit trail records that a lost-completion recovery occurred. This satisfies the audit-completeness success criterion (which requires every DPG execution to have a corresponding ACT completion event).

CD13 closes the audit-gap-during-boundary-destruction failure mode (per § Failure Modes below) as a formal commitment rather than a mitigation that's only referenced in prose. Forward-completion ordering remains correct; lost-completion failures are caught by reconciliation; reconciliation is idempotent. Same pattern shape as PCS-Daemon CD5; the relocated half-state failure mode is shut.

## Deferred-Pending-Increment-2-Rulings (DRs)

**DR-DPG-1 (couples to DR-IAM-2)**: **DPG runner's bootstrap credential at process start.** Same recursive root problem as PCS-Daemon (per `PCS-DAEMON-SPEC.md` v1.0 DR-PCS-1) and the other agent identities. The DPG runner's process needs to authenticate to Vault as the runner identity at startup. Until DR-IAM-2 resolves, deployment-architecture-configured bootstrap.

**DR-DPG-2 (couples to DR-IAM-5)**: **Per-session credential format for DPG runner sessions.** Same shape as DR-PCS-2 — sessions hold session credentials for substrate-level operations; format depends on Judge's ruling on per-session credential specifics.

**DR-DPG-3 (couples to DR-IAM-4)**: **Session-termination impact on in-flight DPG executions.** When a runner session terminates, an in-flight execution must either return-and-release or terminate-and-rollback. Audit invariant (per ACT v1.0 DR-ACT-3 pattern): all events emitted to that point are preserved in ACT. Runtime continuation depends on the ruling. The execution's worker-pool claim is returned to the queue per `IBX-SPEC.md` v1.0 mid-action-safe termination.

**DR-DPG-4 (couples to DR-IAM-1)**: **Per-DPG-runner-identity concurrency cap values.** DPG is Worker archetype (per CD7); the per-identity concurrency cap mechanism is committed in IAM v1.0 CD4 + IBX v1.0; the *values* (how many concurrent DPG runner sessions per `dpg-runner` identity) depend on Judge's ruling on cap values per tier (DR-IAM-1).

## Validation-Pending (VP)

**VP-DPG-1 (mirrors VP-PCS-1)**: **ACT extension to absorb `dpg.execution_request_rejected` event type.** v1.0 DPG spec proposes the new event-type; per ACT v1.0 CD4, adding requires explicit curation event. Resolution path: ACT spec v1.x absorbs the extension; canonical ACT enum is updated. **Cross-spec dependency tracking**: PR #67 (this spec) is the originating reference for the required ACT v1.x curation event. The two existing dpg.* event types (`dpg.code_emitted`, `dpg.execution_complete`) are already in ACT v1.0 CD4 — no fallback needed for those. The new `dpg.execution_request_rejected` event-type is the bounded gap; pre-curation-event, the DPG runner may emit `act.detection_signal` events with payload-encoded `signal_type=dpg_request_rejected` for the same bounded window pattern PCS-Daemon uses (per `PCS-DAEMON-SPEC.md` v1.0 VP-PCS-1).

**Shared ACT v1.x curation event (per Patton ruling `58db3413`)**: the ACT v1.x curation event that resolves VP-DPG-1 should ALSO fold the `pcs.*` enum entries from VP-PCS-1 (per `PCS-DAEMON-SPEC.md` v1.0) in **a single motion**. Two originating references queued against one curation event: PR #66 (PCS-Daemon) for the `pcs.*` namespace + PR #67 (this spec) for `dpg.execution_request_rejected`. Patton left the matching standing note on the `pcs.*` side at his `294ec70a` close-out. Folding both in one curation event prevents the half-extended-enum failure mode where one VP graduates without the other; folding separately would risk one landing first and leaving the other unresolved for an unbounded window. The future agent (Watson, Bob, or whoever lands the ACT v1.x update) is expected to close BOTH VPs in the same curation event citing both PRs.

## Open Questions (genuinely open, v1.0)

**OQ-D1**: **DPG runner pool sizing and autoscaling.** v1.0 commits Worker-pool dispatch but does not commit pool-sizing logic. Static (fixed pool size) vs autoscaling (pool grows with queue depth, shrinks with idleness) is operational/deployment.

**OQ-D2**: **Substrate selection per execution (mixed-substrate DPG).** A single deployment may want some executions in worktrees (cheap, fast) and others in firecracker microVMs (strong, slow). v1.0 commits single-substrate-per-deployment; mixed-substrate routing (per workload type or per requester) is post-v1.0.

**OQ-D3**: **Cross-DPG-result correlation for distributed validation.** When PCS-Daemon validates a plugin that has multiple test runs (unit + integration + smoke), should they be one DPG execution or several? v1.0 commits one-DPG-execution-per-request; multi-step validation requests is a deferred design discussion.

## Failure Modes To Watch

- **Boundary escape via substrate vulnerability.** A bug in the substrate (worktree, nspawn, firecracker) lets execution code break out of the boundary. **Mitigation**: substrate selection per tier (Tier-0 workloads run on stronger substrate per CD11); periodic substrate-vulnerability review; the boundary's enforcement does NOT depend on the execution code's good behavior — it depends on substrate primitives.
- **Side-channel leak.** Timing attacks, cache-based attacks, Spectre/Meltdown-class exploitation could allow execution to extract information from outside the boundary. **Mitigation**: explicitly out of scope at v1.0; Tier-0 workloads on firecracker microVMs (which provide stronger side-channel isolation than worktrees) is the deployment-side mitigation.
- **Network egress proxy compromised.** A misconfigured or compromised network proxy could allow execution to reach unauthorized network destinations. **Mitigation**: proxy is a substrate-side component owned by the deployment; default-deny rule; allowlist per request; egress events captured in `boundary_audit_summary`.
- **Resource-limit bypass.** Execution code finds a way to exceed declared limits (e.g., fork-bomb-style process spawning that the substrate doesn't immediately catch). **Mitigation**: substrate-enforced cgroups/VM limits; runner monitors actual consumption; execution forcibly terminated when limit exceeded.
- **Validation gate misconfiguration.** A request specifies validation gates that don't catch a real defect; the execution passes DPG but is non-compliant in production. **Mitigation**: PGE compliance is mandatory and unmodifiable per CD4 + CD8 (not request-configurable); Syntax conformance is mandatory; per-request gates are additive, not subtractive — they add more checks, never remove the mandatory four.
- **Audit gap during boundary destruction.** A bug in the runner could destroy the boundary before fully capturing audit events. **Mitigation**: events emitted to ACT before boundary destruction; chain-checkpoint events (per `ACT-SPEC.md` v1.0 CD4 `act.chain_checkpoint`) preserve durable evidence; **CD13 formal reconciliation-sweep commitment** (promoted from this mitigation by Patton ruling `58db3413`) provides the durable recovery mechanism: runner reconciliation sweep detects executions whose `dpg.execution_complete` was lost and emits the recovery event with outcome `lost_completion_recovered`.
- **Worker-pool starvation.** A flood of execution requests overwhelms the DPG runner pool. **Mitigation**: dead-letter queue per IBX v1.0 worker-pool CD; rate-limiting at the request layer; OQ-D1 names autoscaling as the operational question.
- **Resource-limit-too-low rejection cascade.** A misconfigured tier defaults sets resource limits too low for routine workloads, causing systemic `resource_limit_exceeded` outcomes. **Mitigation**: per-deployment-tier resource-limit defaults documented in deployment-architecture; operator review of `resource_limit_exceeded` rate as a deployment-health signal.
- **CUDA nondeterminism masquerades as failure.** A test expects deterministic results; CUDA's numerical drift produces a "failure" that isn't really one. **Mitigation**: CUDA workloads explicitly declare their determinism expectation per CD10; tests for CUDA workloads use bounded-tolerance comparisons.
- **Watcher-becomes-executioner drift inside DPG.** A future DPG version adds "auto-remediate" capability: when an execution fails, automatically retry with adjusted parameters. **Mitigation**: explicit non-commit per the architecture-wide separation discipline (per `ACT-SPEC.md` v1.0 CD10) — DPG validates; PGE/PCS-Daemon/Judge decide response. Auto-remediation would route through PGE's response policy, not Daemon-internal logic.

## Dependencies

- **`SOM-PILLAR-NAMES.md`** v1.1 — DPG pillar entry of record
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — DPG row records the CUDA-preflight operational precedent; this spec is the formal contract for the generalized pillar
- **`SOM-TECHNICAL-OVERVIEW.md`** v0.2 §3 The Compute Plane — DPG as the bridge between stochastic reasoning and deterministic execution
- **`SOM-CONCURRENCY-AND-ARCHETYPES.md`** — Worker-archetype framing for the DPG runner pool
- **`IBX-SPEC.md`** v1.0 — IBX provides execution-request and result-return PCT transport; worker-pool dispatch for parallel runner pool
- **`IAM-CORE-SPEC.md`** v1.0 — DPG runner identity model
- **`ACT-SPEC.md`** v1.0 — DPG events feed ACT for audit trail; `dpg.code_emitted` + `dpg.execution_complete` already in CD4 enum
- **`PCS-DAEMON-SPEC.md`** v1.0 — PCS-Daemon invokes DPG for executable validation pre-promotion
- **`planning/CUDA-PREFLIGHT.md`** — the operational SOP for the CUDA-preflight precedent that DPG generalizes
- **`MCP-SECURITY-FRAMEWORK.md`** — PGE rule corpus that DPG applies as the second guardrail
- **`CLAUDE.md`** § Subagent Policy — the subagent `isolation: "worktree"` precedent for the substrate primitive

## Success Criteria

- **DPG runner emits all four standard validation gates on every execution.** No execution returns to the caller without all four gate results in the validation_results record. **Measure**: integration test in the implementation runs a sample execution and verifies all four gates fired.
- **Ephemeral isolation provably holds.** A malicious execution cannot write outside the boundary, cannot access network outside declared egress, cannot exceed declared resource limits. **Measure**: chaos test in the implementation runs adversarial executions (attempting fork-bomb, attempting unauthorized network egress, attempting filesystem write outside boundary) and verifies all are contained.
- **Single-substrate Exit Test conformance.** The same DPG contract holds when the substrate swaps from git worktrees to nspawn to firecracker. **Measure**: contract test in the implementation runs the same execution workload on multiple substrates and verifies semantically identical results (modulo CUDA numerical drift per CD10).
- **PCS-Daemon → DPG → result flow works end-to-end.** A plugin promotion invokes DPG for executable validation; DPG runs the plugin's test suite; result feeds back to Daemon; Daemon's state transitions per the result. **Measure**: end-to-end test runs a plugin promotion that exercises a DPG validation step; verifies the full flow.
- **Audit completeness.** Every DPG execution has corresponding ACT events covering submission (`dpg.code_emitted`) and completion (`dpg.execution_complete`); failed requests have `dpg.execution_request_rejected` (post-VP-DPG-1 resolution) or the fallback `act.detection_signal`. **Measure**: audit query against ACT shows complete event coverage for sampled DPG executions.
- **Patton dialectical sign-off at v1.0.** Single review gate per the simplified workflow; file-based review per the post-PR-#65 discipline. **Measure**: Patton's sign-off inbox message.

## References

- `planning/SOM-PILLAR-NAMES.md` v1.1 — DPG pillar entry of record
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — DPG row (CUDA-preflight operational precedent)
- `planning/SOM-TECHNICAL-OVERVIEW.md` v0.2 — Compute Plane framing
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` — Worker-archetype framing
- `planning/SOM-PROBLEM-STATEMENT.md` v0.6 — PGE double-guardrail framing (§3)
- `planning/IBX-SPEC.md` v1.0 — execution-request and result-return transport
- `planning/IAM-CORE-SPEC.md` v1.0 — DPG runner identity model
- `planning/ACT-SPEC.md` v1.0 — DPG events in CD4 enum; VP-DPG-1 for the new event type
- `planning/PCS-DAEMON-SPEC.md` v1.0 — pre-promotion executable validation
- `planning/CUDA-PREFLIGHT.md` — operational SOP for the precedent
- `planning/MCP-SECURITY-FRAMEWORK.md` — PGE rule corpus
- `CLAUDE.md` § Subagent Policy — `isolation: "worktree"` precedent
