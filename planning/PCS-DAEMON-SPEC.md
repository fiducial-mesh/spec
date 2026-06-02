---
title: "PCS Daemon Spec — Lifecycle Daemon Contract"
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
  - planning/PCS-REGISTRY-FOLD-IN.md
  - planning/IBX-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
  - planning/MCP-SECURITY-FRAMEWORK.md
---

# PCS Daemon Spec — Lifecycle Daemon Contract

**Scope**: Formalizes the contract for the **PCS-Daemon** — the registry-side service that completes the PCS-Lifecycle layer of the Plugin Control System pillar. PCS-Daemon **wraps** the existing Harness (`pcs-control-plane`, already built and operational as the standalone CLI + library Bob shipped per `PCS-REGISTRY-FOLD-IN.md` v1.3 §Lifecycle Harness/Daemon Split) and adds the registry-side concerns the Harness deliberately doesn't carry: **IBX integration for the Judge-approval gate during plugin promotion**, **PCS-Registry write coordination**, **per-promotion-event audit emission to ACT**, and **the dev-to-production trust-boundary crossing** that distinguishes plugin development from sovereign production release. The contract covers the consume-side of the IBX v1.0 surface (Patton's load-bearing coupling risk per `5fd105cd`), the consume-side of the IAM v1.0 PCS-Lifecycle coupling, the providing-side of the PCS-Registry write API, and the cooperation patterns with PCS-Syntax (validation) and Harness (process orchestration).

**Status**: **Validated v1.0** — item 4 of the spec-campaign queue (per Patton's `87d77f55`). The PCS-Daemon is **not yet built** — the Harness it wraps (`pcs-control-plane`) exists as a standalone CLI + library; the Daemon's IBX-integration + registry-coordination layer is the implementation work this spec contracts. Per `SOM-PRODUCTION-VALIDATION.md` v1.1 PCS row, the PCS pillar is production-validated for its existing surface (Syntax via `pcs-spec`, Registry via `pcs-registry` shell, Lifecycle Harness via `pcs-control-plane`); the Daemon completes the Lifecycle layer per the architectural commitment in `PCS-REGISTRY-FOLD-IN.md` v1.3. This spec is the formal contract for *what Bob builds* when the Daemon implementation begins; the **ruling-dependent parts** (PCS-Daemon's bootstrap credential at process start, per-session credential format for Daemon sessions, session-vs-identity revocation impact on in-flight promotions, sovereignty-vs-multi-mode deployment) stay marked **Deferred-Pending-Increment-2-Rulings** per Patton's "don't front-run the seven rulings" directive. **v1.0 fold-in (Patton `251c9511`)**: CD5 §Atomic Registry Write extended with rollback-path reconciliation clause (closes the latent failure mode where the compensating-delete itself fails — Daemon reconciliation sweep transitions stranded `pending_registration` rows to terminal `registration_failed`); VP-PCS-1 strengthened with explicit cross-spec dependency tracking (ACT v1.0 enum doesn't yet contain `pcs.*`; the required ACT v1.x curation event has PR #66 as originating reference; operational fallback to `act.detection_signal` documented for the bounded window).

**Why this spec matters most for the implementation queue**: Patton's `5fd105cd` and forward notes throughout the campaign identified the **PCS-Daemon ↔ IBX coupling** as the single biggest implementation-side risk. The IBX v1.0 contract surface (per `IBX-SPEC.md` v1.0: nine-field PCT, scope/authority-bounds axial split, CD6 coordinated-migration discipline, the may-rely-on / may-NOT-rely-on tables) is **stable and re-verified across the campaign**. PCS-Daemon writes its consumer side against that fixed surface. This spec is the formal seam between the producer (IBX) and the consumer (Daemon).

## Purpose / Problem Restatement

The PCS pillar has three layers per `PCS-REGISTRY-FOLD-IN.md` v1.3:

1. **PCS-Syntax** — declarative plugin schema (artifact contract). Owned by `pcs-spec`. v0.2-draft today.
2. **PCS-Registry** — air-gapped artifact substrate (storage). Owned by `pcs-registry`. Shell exists; production deployment on EPYC/Proxmox VM + TrueNAS NFS pending.
3. **PCS-Lifecycle** — promotion gate (governance). Splits into **Harness** (validation primitives, run-anywhere CLI/library — already built in `pcs-control-plane`) and **Daemon** (registry-side orchestration service that wraps the Harness and integrates with IBX/Judge approval gate, the dev-to-production trust transition, and the registry write coordination). The Daemon is what this spec defines.

**Why split Lifecycle into Harness + Daemon** (per `PCS-REGISTRY-FOLD-IN.md` v1.3): the Harness validation primitives (Syntax check, PGE compliance check) are needed in *two* contexts:

- **Development context**: plugin authors run `pcs-control-plane check` against their local plugin to catch Syntax/PGE violations before submission. Same standalone CLI/library, no Registry, no IBX, no Judge gate.
- **Production-promotion context**: when a plugin author requests promotion-to-production, the Daemon runs the *same* validation primitives + the additional governance steps (IBX action-priority for Judge approval, ACT audit emission, atomic Registry write on approval). Same primitives, different orchestration, governed seam.

This is the architectural reason for the Harness/Daemon split — one shared validation surface, two contexts of use. It mirrors `cargo check` (run anywhere by developers) vs `cargo publish` (registry-side, gated) in the Rust ecosystem.

**Current implementation gap, named explicitly**: today the lab uses `pcs-control-plane` in Harness mode (developers + agents run `pcs-control-plane check` against plugins before they land on `main` of the `qso-graph/*` MCP repos or PyPI). There is no Daemon — promotion to production currently happens via PyPI publish + GitHub Actions, not via the PCS-Daemon-gated path. The Daemon's IBX + Judge-gate integration is the implementation work the spec corpus is preparing Bob to build. Until the Daemon exists, "PCS-Registry as the sovereign production source-of-truth" is a partial commitment — the substrate is named and the Harness is operational, but the gate that crosses the dev-to-production trust boundary lives in this spec, not in code.

## Architecture — Daemon Wraps Harness; Adds Five Registry-Side Concerns

PCS-Daemon is **not a reimplementation** of the Harness. It is a **service that wraps** the Harness primitives and adds the registry-side orchestration the Harness deliberately doesn't carry. Architectural separation:

| Concern | Lives in | Reuse pattern |
|---|---|---|
| Plugin schema validation (Syntax check) | Harness (`pcs-control-plane`) | Daemon **calls** Harness validate function; does not reimplement |
| PGE compliance check (security framework rules) | Harness (`pcs-control-plane`) | Daemon **calls** Harness PGE-check function; does not reimplement |
| Manifest parsing + structural integrity | Harness (`pcs-control-plane`) | Daemon **calls** Harness parser; does not reimplement |
| **Judge-approval gate via IBX** | **Daemon (new)** | Daemon emits `action`-priority PCT to Judge via IBX; polls for `approved`/`rejected` by `message_id` per `IBX-SPEC.md` v1.0 "may rely on" |
| **PCS-Registry write coordination** | **Daemon (new)** | Daemon writes to Registry artifact store (TrueNAS NFS) + Registry metadata tables (ClickHouse `pcs.*`) atomically on Judge approval |
| **Per-promotion-event ACT audit emission** | **Daemon (new)** | Daemon emits `ibx.*` and Registry-specific events to ACT per `ACT-SPEC.md` v1.0 CD6 (per-session-per-identity attribution) |
| **Dev-to-production trust-boundary crossing** | **Daemon (new)** | Daemon enforces "promotion-only via this gate" — Registry writes from any other path are defects |
| **Promotion lifecycle state machine** | **Daemon (new)** | Daemon tracks promotion candidates through submit → validate → judge-await → approved/rejected → registered |

**Three things the Daemon explicitly does NOT do**:

- Reimplement validation. The Harness is the validation authority; the Daemon orchestrates it.
- Modify the Harness behavior. The Daemon calls Harness functions with the same semantics developers see locally.
- Sign artifacts. Plugin signing (when introduced post-v1.0) is the responsibility of the plugin author's IAM-managed identity, not the Daemon's.

### Architectural reason the split holds across the full spec stack

The Harness is **substrate-agnostic** — it runs against a local plugin directory using only local file I/O and the Syntax/PGE rules. The Daemon is **substrate-coupled** — it depends on IBX (running), IAM (running), ACT (running), PCS-Registry (running on a specific deployment substrate). If the Daemon's substrate changes (e.g., Registry storage migrates from TrueNAS NFS to S3-compatible object store), the Daemon's code changes. The Harness does not change. The split protects the Harness's substrate-agnostic property at all costs.

This matches the same architectural pattern that runs through the rest of SOM: contract is what each pillar commits, substrate is what the deployment satisfies, and the boundary between them is **enforced by design separation**, not by convention.

## The PCS-Daemon Promotion Flow (End-to-End)

The Daemon implements a **promotion lifecycle state machine** with explicit states, transitions, and gate firings. This section names the canonical flow; the state machine schema lives in the Daemon implementation (Bob's domain when the build begins) and is contracted here.

### States

| State | Meaning |
|---|---|
| `submitted` | Plugin author has uploaded a candidate artifact; Daemon has accepted it for promotion processing |
| `validating` | Daemon is running Harness validation (Syntax + PGE) on the candidate |
| `validation_failed` | Harness validation returned errors; candidate is rejected without reaching Judge |
| `judge_awaiting` | Validation passed; Daemon has emitted `action`-priority PCT to Judge via IBX; awaiting `approved`/`rejected` |
| `approved` | Judge approved via inbox-ui; Daemon is ready to commit the registry write |
| `registered` | Daemon has written the artifact to Registry storage + metadata tables atomically; candidate is now a production-registered plugin |
| `rejected` | Judge rejected via inbox-ui; Daemon has recorded the rejection with cited reason; candidate is closed |
| `validation_expired` | Validation took longer than configured timeout; candidate is closed with timeout reason |
| `judge_expired` | Judge approval/rejection wasn't received within configured window; candidate is closed with judge-timeout reason |

### Transitions (with gate firings)

```
submitted
  │
  ▼  Daemon's promotion worker picks up candidate
validating
  │
  ├── Harness validate FAIL ────────► validation_failed (terminal)
  │
  └── Harness validate PASS
        │
        ▼  Daemon emits action-priority PCT to recipient=judge via IBX
        │  (PCT carries candidate manifest hash + Harness validation report)
judge_awaiting
  │
  ├── IBX status_transition: judge approved ──► approved
  │                                              │
  │                                              ▼  Daemon writes registry atomically
  │                                          registered (terminal)
  │
  ├── IBX status_transition: judge rejected ──► rejected (terminal)
  │
  └── Judge approval window expires ──────────► judge_expired (terminal)
```

### Idempotency + Replay

The Daemon's promotion flow is **idempotent** at every state. A crash during `validating` returns the candidate to `submitted` (Harness validation is re-run on resume — pure function of candidate + Harness version). A crash during `judge_awaiting` resumes by re-polling IBX for the message status (the PCT has stable `message_id` per `IBX-SPEC.md` v1.0 may-rely-on). A crash during `approved` → `registered` either completes the atomic registry write or returns to `approved` (idempotency keys on the registry write per `IBX-SPEC.md` v1.0 § Concurrency-Safe Worker-Pool Dispatch CD4 + bronze-write discipline). No state allows a partial write to land in the Registry.

### The Atomic Registry Write

When the Daemon transitions `approved` → `registered`, three substrate writes happen and **must all succeed or all roll back**:

1. **Artifact write** to PCS-Registry storage (TrueNAS NFS in the canonical deployment per `PCS-REGISTRY-FOLD-IN.md` v1.3) at the canonical path for the plugin's identity + version
2. **Metadata write** to PCS-Registry ClickHouse tables (`pcs.plugins`, `pcs.mcp_servers`, `pcs.plugin_versions`, `pcs.promotion_events`) recording the new version row + the promotion event row + the Judge-approval ref
3. **ACT event emission** of the promotion event for audit trail

The atomicity contract: **if metadata write succeeds but artifact write fails, the Daemon rolls back the metadata write** (within the same transaction window) before recording the candidate as `approved`-but-not-`registered` and surfacing the failure for retry. ACT event emission is **after** the atomic registry write succeeds, so the audit reflects what landed.

If the substrate cannot support full ACID transactions across heterogeneous targets (NFS + ClickHouse), v1.0 commits the **two-phase compensating-transaction pattern**: write metadata in a `pending_registration` status; write artifact; on artifact success, update metadata to `registered`; on artifact failure, delete the `pending_registration` row. The metadata is the system of record for "what's registered"; the artifact must exist before the metadata says it's registered.

### Rollback-path reconciliation (per Patton ruling `251c9511`)

The compensating-transaction pattern above has a latent failure-mode the v1.0 spec must close: **what if the rollback DELETE of the `pending_registration` row itself fails** after the artifact write has already failed? Without a clause for that, the system is left with a `pending_registration` row and no corresponding artifact — the half-state the pattern exists to prevent, just relocated to the rollback path.

v1.0 commits the **rollback-path reconciliation**: this is CD11 (idempotent recovery) applied specifically to the compensating-delete failure mode.

- **Reconciliation sweep (operationally periodic, semantically idempotent)**: the Daemon runs a reconciliation pass that finds `pending_registration` rows older than a bounded window (default: configurable, suggested 1 hour, operator-tunable per deployment SLO) **with no corresponding artifact present in Registry storage**. Each such row is transitioned to a terminal `registration_failed` state, recording the reconciliation event in `pcs.promotion_events` with reason `compensating_delete_failed_recovered`.
- **Sweep is safe to re-run**: idempotency keys on the reconciliation event prevent double-transitions; if the sweep runs twice for the same row (because the Daemon crashed mid-sweep and restarted), the second run sees the row already in `registration_failed` and is a no-op.
- **Forward-write ordering remains correct**: the reconciliation only operates on rows whose artifact write provably failed (no artifact present) AND whose rollback completion was lost (`pending_registration` row still present); the metadata system-of-record contract holds because `pending_registration` is never readable-as-registered.
- **The reconciliation event is itself an audit event** emitted to ACT (`pcs.reconciliation_swept`), preserving the audit trail of every state transition per CD10.

This closes the rollback failure mode without introducing distributed-transaction overhead. The pattern is: forward writes are two-phase + atomic-or-rollback; rollback failures are detected by reconciliation; reconciliation is idempotent.

## Coupling Boundary: IBX ↔ PCS-Daemon (Consume-Side of `IBX-SPEC.md` v1.0)

Patton's `5fd105cd` flagged this as the load-bearing coupling risk; the IBX v1.0 contract surface is now stable. This section commits the Daemon's consume side **against the fixed IBX v1.0 surface**, line-by-line traceable to IBX v1.0's may-rely-on and may-NOT-rely-on lists.

### What PCS-Daemon relies on from IBX (per IBX v1.0 may-rely-on)

- **Nine-field PCT contract is stable.** The Daemon's PCT consumer is built against the `pct-v1` surface; field names and semantics will not change without coordinated v2 migration per `IBX-SPEC.md` v1.0 CD6 in which the Daemon participates.
- **Scope/authority-bounds axial split holds.** Daemon-emitted PCTs use field 4 (`scope`) for the access-control statement (which Registry write path is being requested) and field 6 (`authority bounds`) for the decision-rights statement (this requires Judge approval). The Daemon never collapses the two — collapsing breaks the IAM-coupling vs Judge-gate seam per `IBX-SPEC.md` v1.0.
- **Priority semantics + status workflow are stable.** Daemon emits `action`-priority PCTs for promotion-approval requests; relies on the `unread → read → approved → in_progress → done` (or `rejected`) status workflow; relies on `inbox-ui` as the only path Judge writes `approved`/`rejected`.
- **Server-enforced Judge-approval gate fires for any `action`-priority message regardless of sender** (per IBX v1.0). Daemon emits its promotion-approval requests at `action` priority and trusts IBX to gate them.
- **`message_id` is stable and status is queryable per `message_id`** (per IBX v1.0 Bob's coupling addition). Daemon's pattern is **send action-priority promotion-approval request → poll for `approved`/`rejected` by `message_id`**. This is the canonical Daemon usage pattern that motivated Bob's `message_id`-stability clause in IBX v1.0.
- **The substrate is reachable from the Daemon's deployment host** (EPYC/Proxmox VM today routes to IBX-on-9975 via DAC `10.60.2.0/24`; production target is co-located on EPYC/TrueNAS).
- **CD6 PCT contract-version migration discipline applies.** When PCT v2 is proposed, the Daemon participates in the coordinated migration per IBX v1.0 CD6. No surprise IBX changes.

### What PCS-Daemon does NOT rely on from IBX (per IBX v1.0 may-NOT-rely-on; Daemon's defensive measures)

- **PCT semantic validation of fields 2-6.** IBX v1.0 CD1 commits validation only on fields 7-9 (meta fields) at send. Daemon must defensively parse + validate the content fields (task, context, scope, success criteria, authority bounds) of any PCT it receives from upstream (plugin authors via the submission API). Validation rules live in the Daemon's submission handler.
- **PCT integrity / tamper-evidence in transit.** IBX is cooperative-trusted-not-cryptographically-trusted per IBX v1.0 DR2 (pending IAM signing). Daemon treats the bus accordingly. Promotion candidates carry their own hash chain (manifest hash → artifact hash) that the Daemon verifies independently of IBX integrity.
- **`info`-priority validity enforcement.** IBX v1.0 CD1 + CD5 require validity at send only for `action`/`urgent`. Daemon emits action-priority for promotion requests (so validity is enforced at send for those); for `info`-priority status updates the Daemon emits (e.g., "promotion `judge_awaiting` started"), it applies its own staleness check on receipt.
- **One-task-per-PCT enforcement.** IBX v1.0 DR3 keeps one-task as convention pending Increment-2 ruling. Daemon's submission handler enforces one promotion candidate per submission internally; relies on convention for inbound Judge approvals; rejects multi-task structures defensively.
- **Round-trip-time guarantees on the Judge gate.** IBX v1.0 commits no latency contract. Daemon's `judge_awaiting` state tolerates seconds-to-hours; the `judge_expired` timeout is operator-configurable per deployment.
- **Worker-pool claim queue substrate.** IBX v1.0 commits the claim/lease/retry contract but defers the specific substrate to DR5. Daemon's worker-pool consumption (for handling many concurrent promotion candidates) is substrate-agnostic by adhering only to the IBX contract; doesn't hard-code ClickHouse or any specific transactional store.
- **Validity-field enforcement on the Daemon's outbound PCTs.** IBX v1.0 CD1 commits validity-required-at-send for action/urgent priority — Daemon MUST set validity on every promotion-approval PCT it emits. v1.0 commitment: default validity = 7 days from promotion submission time (operator-configurable); past expiry, the candidate state transitions to `judge_expired`.

### Daemon's outbound PCT shape (for promotion-approval requests)

The Daemon emits a single class of PCT: the `promotion_approval_request`. Field-by-field:

| PCT field | Daemon-emitted value |
|---|---|
| **1. principal-id** | The Daemon's own ARCA-issued agent identity (per IAM v1.0 § Coupling Boundary: PCS-Lifecycle ↔ IAM). NOT the plugin author's identity; NOT the operator's identity. |
| **2. task** | `"approve plugin promotion: <plugin-id> v<candidate-version>"` |
| **3. context** | Markdown summary: plugin identity, candidate version, manifest hash, artifact hash, Harness validation report summary, submission provenance |
| **4. scope (access-control)** | Registry write path the approval would authorize (e.g., `pcs.plugins.write:plugin-id=<X>`); read by IAM job-code check against PCS-Daemon's job code |
| **5. success criteria** | Two bullets — (a) Judge issues `approved` via inbox-ui; (b) Daemon's atomic registry write succeeds |
| **6. authority bounds (decision-rights)** | `judge-required` (the decision exceeds the Daemon's unilateral authority; Judge gate fires by virtue of `action` priority) |
| **7. version** | `pct-v1` per IBX v1.0 |
| **8. audit** | Provenance chain: submission `message_id` (the upstream PCT from the plugin author requesting promotion), Harness validation event_id in ACT, Daemon's `principal-id` + `session-id` |
| **9. validity** | `not-after: submission_timestamp + 7d` (operator-configurable per deployment) |

### Daemon's inbound PCT handling (for status polling)

The Daemon polls IBX for status transitions on its emitted `message_id`s. v1.0 commits the polling pattern:

- **Initial poll**: 10 seconds after PCT emission (operator-configurable)
- **Backoff**: exponential, max 30 minutes between polls
- **Idempotency**: polls are read-only; multiple polls return the same status without side effects
- **Timeout**: candidate transitions to `judge_expired` when poll returns an unchanged `unread`/`read` status past the PCT's `validity` deadline

## Coupling Boundary: IAM ↔ PCS-Daemon (Consume-Side of `IAM-CORE-SPEC.md` v1.0)

Per `IAM-CORE-SPEC.md` v1.0 § Coupling Boundary: PCS-Lifecycle ↔ IAM: PCS-Daemon has its own ARCA-issued agent identity (job code: "plugin lifecycle orchestrator"); the PCS-Daemon does NOT use the operator's credentials; it has its own. This section commits the consume side.

### What PCS-Daemon consumes from IAM

- **The Daemon's own agent identity.** ARCA-issued at deployment time, signed birth certificate, public-key fingerprint registered in Roster, scoped credentials issued from Vault under the job code `"plugin lifecycle orchestrator"`. This is the identity field 1 (`principal-id`) carries on every Daemon-emitted PCT.
- **Roster lookup** to resolve plugin authors' identities at submission time (verify the submitting principal is an authorized author for the plugin namespace).
- **Authorization decision lookup** to confirm a Judge approval is from a principal authorized to approve PCS promotions (defense-in-depth — the IBX gate already enforces "only Judge can write `approved`", but the Daemon verifies the responding principal's job code is `judge` or equivalent at write time).
- **Per-session credential per `IAM-CORE-SPEC.md` v1.0 CD4** for the Daemon's own runtime sessions — the Daemon's process opens a session at startup, identifies as the Daemon identity with a session credential, and uses that credential for substrate writes. Format DR-IAM-5 per IAM v1.0.

### What PCS-Daemon does NOT rely on from IAM (defensive measures)

- **Real-time revocation propagation.** The Daemon's process holds its session credential and refreshes per the credential's lifetime (DR-IAM-5). If the Daemon's identity is revoked mid-session, the Daemon may continue acting until session-credential refresh fails; defense-in-depth via per-action authorization lookup at high-stakes actions (the atomic Registry write).
- **IAM's session-termination notification timeliness.** The Daemon's promotion in-flight when its session terminates is handled per ACT v1.0 DR-ACT-3 (runtime delivery) — audit retention is non-negotiable; runtime continuation depends on DR-IAM-4 ruling.

## Coupling Boundary: PCS-Registry ↔ PCS-Daemon (Daemon's Write API to Registry)

The Daemon is the **sole authorized writer** to PCS-Registry's production substrate. v1.0 commits the write API the Daemon uses + the discipline the Daemon enforces.

### What the Daemon writes to the Registry

- **Plugin manifests** to `pcs.plugins` (`plugin_id`, `current_version`, `current_artifact_path`, `current_promotion_event_id`)
- **MCP server manifests** to `pcs.mcp_servers` (same shape, different namespace per `PCS-REGISTRY-FOLD-IN.md` v1.3 two-artifact-classes framing)
- **Version rows** to `pcs.plugin_versions` and `pcs.mcp_server_versions` (one row per promoted version, never deleted)
- **Promotion events** to `pcs.promotion_events` (one row per promotion event, including approved + rejected + expired outcomes; the canonical audit of "what did the Daemon do when")
- **Artifact binaries** to the Registry storage path (TrueNAS NFS in canonical deployment; substrate-agnostic per Exit Test)

### Write discipline (CDs Daemon enforces against Registry)

- **All Registry writes flow through the Daemon.** Any write to `pcs.plugins`, `pcs.mcp_servers`, `pcs.*_versions`, or `pcs.promotion_events` from any path other than the Daemon is a defect requiring CLCA cycle + rollback. This is the dev-to-production trust-boundary enforcement: no out-of-band path to "in the Registry" exists.
- **Writes are atomic with the artifact binary write.** Per § Promotion Flow's Atomic Registry Write commitment — metadata + artifact land or neither lands.
- **All writes are tagged with the originating promotion event.** Forensic reconstruction: every Registry row is traceable to the `promotion_events` row that authored it.
- **Reads from the Registry are unrestricted** — agents, MCP runtime, deployment automation, all read the Registry. The Daemon writes; everyone reads.

## Coupling Boundary: PCS-Syntax ↔ PCS-Daemon

PCS-Syntax (`pcs-spec`) commits the schema for plugin manifests + MCP-server manifests. The Daemon consumes the schema via the Harness:

- The Daemon does NOT carry its own copy of the Syntax schema. It calls the Harness `validate` function, which loads the Syntax schema from `pcs-spec`'s shipped manifest and runs validation. Single source of truth for the schema.
- When PCS-Syntax schema bumps (v0.2 → v0.3 etc.), the Harness picks up the new schema on its next release; the Daemon picks up the new behavior on its next deployment that bundles the updated Harness. Coordination is package-version-driven, not contract-level.

## Coupling Boundary: ACT ↔ PCS-Daemon

Per `ACT-SPEC.md` v1.0: ACT consumes events from all SOM pillars. PCS-Daemon emits the following events into the ACT stream during promotion flow:

| Event-type | Emitted on |
|---|---|
| `ibx.message_sent` | Daemon emits a PCT to Judge (per IBX coupling above; ACT captures this automatically via IBX) |
| `pcs.candidate_submitted` (new event-type per ACT v1.0 CD4 extensibility; **VP-PCS-1** — depends on ACT supporting Daemon-namespaced events) | Plugin author submission lands |
| `pcs.validation_started` | Harness validation begins |
| `pcs.validation_complete` (with PASS or FAIL outcome in payload) | Harness validation completes |
| `pcs.judge_request_sent` | Daemon emits the action-priority PCT to Judge (in addition to the standard `ibx.message_sent` IBX itself captures) |
| `pcs.promotion_approved` | Judge approves; Daemon transitions to `registered` after atomic write |
| `pcs.promotion_rejected` | Judge rejects |
| `pcs.promotion_expired` | Validity/judge-expiration timeout |
| `pcs.registry_write_started` / `pcs.registry_write_complete` / `pcs.registry_write_failed` | Atomic registry write boundary |
| `pcs.reconciliation_swept` (per CD5 rollback reconciliation, per Patton ruling `251c9511`) | Rollback-path reconciliation sweep transitions a `pending_registration` row to `registration_failed` |

The `pcs.*` event-type prefix requires extending ACT's CD4 bounded enum (currently `iam.*`, `ibx.*`, `workforce.*`, `quorum.*`, `dpg.*`, `act.*`). Adding `pcs.*` requires explicit curation event per ACT v1.0 CD4. v1.0 PCS-Daemon spec **proposes** the extension; ACT spec v1.x absorbs it. **Cross-spec tracking** (per Patton's `251c9511`): ACT v1.0 (merged at `d90a8ca` per PR #65) closed with its enum fixed and `pcs.*` NOT in it. The required ACT v1.x curation event has PR #66 (this spec) as its originating reference; until that curation event lands, the Daemon cannot actually emit `pcs.*` events to ACT. The dependency is tracked in VP-PCS-1 + named here so it does not get lost between specs.

## Coupling Boundary: Harness ↔ PCS-Daemon

The Daemon **wraps** the Harness. v1.0 commits the wrap pattern:

- **The Daemon calls Harness's exposed library API** for validation primitives. No subprocess, no shell exec, no parallel reimplementation. (Subprocess would also fall under the security-framework `subprocess` prohibition per `MCP-SECURITY-FRAMEWORK.md` — direct library import is the canonical pattern.)
- **The Harness exposes a function-style API**: `validate(manifest_path) → ValidationResult`, with structured return values the Daemon parses. Errors are exceptions (with structured exception types per the Harness's contract); the Daemon's exception handling converts them to candidate-state transitions.
- **The Daemon's promotion lifecycle adds states; the Harness's validation does not have states.** Harness is stateless w.r.t. the promotion (same input → same output, no internal lifecycle). Daemon's state machine wraps the stateless validation call inside a stateful candidate lifecycle.
- **Harness version bumps are coordinated with Daemon deployments.** When `pcs-control-plane` releases a new version, the Daemon deployment bundles the updated Harness; running Daemon instances continue with their bundled Harness version until redeployment. This is the standard library-version coordination pattern; no special governance.

## Closed Decisions (CDs — v1.0 Commitments)

**CD1**: **Daemon wraps Harness; no validation reimplementation.** The Daemon calls Harness's validate function via direct library import; subprocess is forbidden (per security framework + per architectural cleanliness). One validation authority.

**CD2**: **Daemon owns the registry-side concerns the Harness deliberately doesn't carry** — IBX integration for Judge gate, Registry write coordination, ACT audit emission, dev-to-production trust-boundary enforcement, promotion lifecycle state machine.

**CD3**: **All Registry writes flow through the Daemon.** Any out-of-band write is a defect requiring CLCA + rollback. This is the production trust-boundary enforcement.

**CD4**: **Promotion lifecycle is a state machine with explicit states and transitions** (per § Promotion Flow). States are durable (recover from crash by reading state from `pcs.promotion_events`). Transitions are atomic at each gate firing.

**CD5**: **Registry write is atomic (metadata + artifact succeed together or roll back together).** Two-phase compensating-transaction pattern if the substrate cannot support true ACID; metadata is the system-of-record for "what's registered."

**CD6**: **PCS-Daemon has its own ARCA-issued agent identity** (per `IAM-CORE-SPEC.md` v1.0 § PCS-Lifecycle coupling). Job code: "plugin lifecycle orchestrator." Daemon never uses operator's credentials; never shares a service account.

**CD7**: **Daemon emits `action`-priority PCT for promotion approval via IBX; relies on `message_id`-stability + status-queryability per `IBX-SPEC.md` v1.0.** Send-and-poll pattern. This is the canonical Daemon-IBX integration.

**CD8**: **Daemon-emitted PCTs always set `validity` (field 9)** per IBX v1.0 CD1 validity-required-at-send for action priority. Default 7 days; operator-configurable per deployment.

**CD9**: **Daemon defensively parses + validates content fields (2-6) of inbound and submission PCTs.** IBX v1.0 CD1 only commits machine-critical field validation; the Daemon's submission handler validates content fields per its own rules.

**CD10**: **All promotion events emit to ACT for audit trail.** Daemon emits `pcs.*` events per the ACT extension proposed in § Coupling Boundary: ACT ↔ PCS-Daemon. ACT spec v1.x absorbs the extension (VP-PCS-1).

**CD11**: **Promotion lifecycle is idempotent at every state.** Crash recovery resumes from durable state; partial writes never land in Registry; PCT polling is read-only and side-effect-free.

**CD12**: **The Daemon-Harness coordination is library-version-driven.** Harness bumps land in Daemon deployments via standard package versioning; no special governance contract.

## Deferred-Pending-Increment-2-Rulings (DRs)

**DR-PCS-1 (couples to DR-IAM-2)**: **Daemon's bootstrap credential at process start.** Per `IAM-CORE-SPEC.md` v1.0 DR-IAM-2, the bootstrap credential is the recursive root problem at login step 1. The Daemon's process needs to authenticate to Vault as the Daemon identity at startup, before holding the Daemon's normal credentials. The bootstrap mechanism (host token, JIT-broker-issued credential, hardware-bound key) depends on Judge's ruling on bootstrap scope. Until DR-IAM-2 resolves, the Daemon's process startup uses a per-deployment-configured bootstrap mechanism documented in the deployment-architecture artifact.

**DR-PCS-2 (couples to DR-IAM-5)**: **Per-session credential format for Daemon sessions.** Daemon opens sessions at process startup; each session holds a session credential the Daemon uses for substrate writes. Format (signed token vs cert vs derived key) depends on Judge's ruling on per-session-credential specifics. Until DR-IAM-5 resolves, the Daemon uses IAM's pre-DR-IAM-5 default session-credential format documented in the deployment-architecture artifact.

**DR-PCS-3 (couples to DR-IAM-4)**: **Session-termination impact on in-flight promotions.** If the Daemon's session is terminated mid-promotion (specifically while in `judge_awaiting` state), the in-flight promotion's runtime continuation depends on Judge's ruling on terminator failure-mode. Audit invariant (per ACT v1.0 DR-ACT-3 audit-vs-runtime split): all promotion events emitted up to the termination point are preserved in ACT. Runtime behavior (resume vs cancel vs reroute the in-flight promotion to a different Daemon session): runtime-side answer depends on the ruling; v1.0 commits the audit-side preservation as non-negotiable.

**DR-PCS-4 (couples to DR-IAM-6)**: **Sovereignty-as-core-claim vs sovereignty-as-one-mode applied to Daemon deployment.** The Daemon is currently designed for sovereign deployment (EPYC/Proxmox VM, TrueNAS NFS, internal-only DNS). If Judge rules sovereignty-as-one-mode (allowing cloud-hosted or hybrid deployments), the Daemon's substrate flexibility extends — e.g., a cloud-hosted Daemon writing to S3-compatible Registry storage. The Daemon's contract is substrate-agnostic per CD5's substitutability; v1.0 doesn't preclude any deployment shape, but the canonical deployment-architecture artifact is the sovereign one until DR-IAM-6 resolves.

## Validation-Pending (VP)

**VP-PCS-1 (mirrors VP-IAM-1 and VP-ACT-1)**: **ACT extension to absorb `pcs.*` event-type namespace.** v1.0 PCS-Daemon proposes the `pcs.*` event-type prefix for promotion-flow events. Per ACT v1.0 CD4, adding new event-types requires explicit curation event. The PCS-Daemon's v1.0 contract assumes the `pcs.*` extension lands in ACT v1.x; until that lands, the extension is **asserted-by-design** (the ACT spec's bounded-enum extensibility surface admits new prefixes) but **claimed-pending-real-validation** (an actual ACT v1.x release containing the `pcs.*` enum entries). Resolution path: ACT spec v1.x absorbs the extension as a curation event; the canonical ACT enum is updated; VP-PCS-1 graduates.

**Cross-spec dependency tracking (per Patton ruling `251c9511`)**: ACT v1.0 (merged at `d90a8ca` per PR #65) closed with its CD4 enum fixed at `iam.*`, `ibx.*`, `workforce.*`, `quorum.*`, `dpg.*`, `act.*` — explicitly *without* `pcs.*`. The Daemon's CD10 commits ACT emission for promotion events; until the ACT v1.x curation event lands extending the enum, the Daemon's `pcs.*` emission has no canonical event-type to land under. The bounded dependency: **VP-PCS-1 resolves when the ACT v1.x curation event lands** with PR #66 (this spec) as its originating reference. Pre-resolution operational fallback: the Daemon may emit `act.detection_signal` events with payload-encoded `signal_type=pcs_promotion_flow` for the bounded window between this spec's merge and ACT v1.x's curation event landing — this fallback is documented here so Bob's implementation isn't blocked by the cross-spec sequencing, but it is explicitly bounded (the fallback ends when ACT v1.x lands; Daemon switches to native `pcs.*` events at that point).

## Open Questions (genuinely open, v1.0)

**OQ-P1**: **Promotion candidate retention before submission.** A plugin author may iterate on a candidate locally before submitting to the Daemon (running Harness checks repeatedly). v1.0 commits the Daemon receives submissions only after the author chooses to submit; what holds the candidate between iterations (local file? scratch storage on the Registry? the author's own infrastructure?) is operator/author choice, not Daemon contract.

**OQ-P2**: **Multi-author plugins (separation of duties applied to plugin authorship).** Some plugins may have multiple authorized authors. v1.0 commits the Daemon verifies the submitting principal is *an* authorized author at submission time; it does not commit on quorum-of-authors or co-signing semantics. If multi-author governance is required, ACT's `quorum.*` patterns may extend to plugin authorship in a later version.

**OQ-P3**: **Cross-environment promotion (dev-Registry → staging-Registry → production-Registry).** Some customer deployments may want multiple registries (dev, staging, production) with explicit cross-environment promotion. v1.0 commits a single canonical Registry per deployment; multi-environment promotion is post-v1.0.

## Failure Modes To Watch

- **Daemon writes to Registry from any path other than the canonical Daemon process.** This violates CD3. **Mitigation**: Registry write authorization is via IAM (Daemon's job code is the only one with write privilege to `pcs.*` tables + Registry artifact storage). Code review on any Registry-touching code confirms the write goes through Daemon; deployment review on the Registry's IAM config confirms only Daemon's identity has write privilege.
- **Atomic registry write succeeds for metadata but fails for artifact.** Half-promoted plugin: Registry says version X exists, but artifact storage doesn't have the binary. **Mitigation (CD5)**: two-phase compensating-transaction — metadata written in `pending_registration` status; only flipped to `registered` after artifact write succeeds. On artifact failure, rollback removes the `pending_registration` row.
- **PCT contract drift from IBX v1.0 without Daemon participation.** Hypothetical: a future IBX change renames a PCT field; Daemon's consumer breaks. **Mitigation (CD6 cross-pillar)**: IBX v1.0 CD6 commits coordinated v2 migration with PCS-Daemon participation. Daemon's PCT-parsing code is tied to `pct-v1` explicitly; a `pct-v2` artifact would not be parseable as `pct-v1`, surfacing the version mismatch fast.
- **Judge approval rolled back after Registry write.** Operationally: Judge approved, Daemon wrote, then Judge changes mind. **Mitigation**: PCS Lifecycle is append-only (no in-place mutation of versions); a "rollback" is a NEW promotion event that supersedes the prior version. Judge initiates the rollback via a separate `action`-priority PCT requesting deprecation; Daemon processes it as a normal promotion event with a `deprecation` outcome.
- **Daemon's session credential refresh fails during long-running promotion.** Daemon may be holding a session credential that expires mid-`judge_awaiting`. **Mitigation**: Daemon refreshes session credential proactively (well before expiry); if refresh fails, Daemon transitions in-flight candidates to `judge_expired` per fail-strict and re-emits them after re-authentication. Bounded loss; no orphaned candidates.
- **Submission flood (denial of service).** Many submitters could overwhelm the Daemon with promotion requests. **Mitigation**: Daemon implements rate-limiting per submitter identity + global rate-limiting; excess submissions rejected at the submission API with `try-later` semantics. Rate-limit policy lives in the Daemon's submission-handler config.
- **Concurrent promotion candidates for the same plugin namespace.** Two authors submit promotion candidates for plugin X at the same time. **Mitigation**: Daemon serializes per-plugin-id (worker-pool-of-one per plugin-id; queued FIFO). Concurrent candidates queue; not race.
- **Harness validation false-positive (PASS when should be FAIL).** A bug in the Harness lets a non-compliant plugin through validation. **Mitigation**: Harness is the validation authority; Harness defects are CLCA cycles on `pcs-control-plane`. The Daemon does not double-check Harness output; trust + verify lives at the Harness layer.
- **Harness validation false-negative (FAIL when should be PASS).** A bug in the Harness rejects a compliant plugin. **Mitigation**: same — Harness CLCA cycle. Submitter sees the FAIL with cited rule; raises an issue against `pcs-control-plane`.
- **Watcher-becomes-executioner drift (Daemon adds auto-deprecation).** Hypothetical future addition: Daemon auto-deprecates plugins that fail PGE on re-validation. **Mitigation**: Daemon does NOT take automatic deprecation action; per `ACT-SPEC.md` v1.0 CD10 separation of duties applied to the PCS-PGE coupling. PGE may detect a compliance signal; the response (deprecate, alert, monitor) goes through the standard Judge-gated PCT flow, not a Daemon-internal automatic.

## Dependencies

- **`IBX-SPEC.md`** v1.0 — IBX provides the PCT contract, Judge-approval gate, message-id stability, and status-queryability the Daemon consumes. This is the load-bearing coupling Patton flagged.
- **`IAM-CORE-SPEC.md`** v1.0 — IAM provides the Daemon's own agent identity (ARCA-issued, job-code-scoped), Roster lookup for authorization, session credentials. Daemon depends on the IAM event stream + lookup APIs.
- **`ACT-SPEC.md`** v1.0 — ACT consumes Daemon-emitted `pcs.*` events for audit trail. The `pcs.*` extension to ACT's bounded enum is VP-PCS-1.
- **`PCS-REGISTRY-FOLD-IN.md`** v1.3 — PCS three-layer anatomy; Daemon completes the Lifecycle layer per the architectural commitment. Provides the Harness/Daemon split rationale + the EPYC/Proxmox deployment substrate framing.
- **`SOM-PILLAR-NAMES.md`** v1.1 — PCS pillar entry of record (Plugin Control System).
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — PCS row records production validation for Syntax + Registry shell + Harness; the Daemon-completion update is a follow-up commit when Daemon implementation lands.
- **`MCP-SECURITY-FRAMEWORK.md`** — PGE de facto spec; Daemon uses Harness's PGE-compliance-check primitive, which consults the security framework rules.
- **`pcs-control-plane`** (built by Bob, separate repo) — the Harness library the Daemon imports and calls. Daemon depends on Harness's library API for validate primitives.
- **`pcs-spec`** v0.2-draft (separate repo) — the Syntax schema the Harness consumes; Daemon depends on Harness consuming this transitively.
- **`pcs-registry`** (separate repo, shell exists) — the Registry storage layer the Daemon writes to.

## Success Criteria

- **Daemon's PCT consumer parses and emits per IBX v1.0 contract.** Field-by-field validation of inbound and outbound PCTs matches the contract; no field is renamed, retyped, or has semantic drift. **Measure**: integration test in the Daemon implementation exercises PCT round-trip (Daemon emits action-priority promotion-approval PCT, Judge approves via inbox-ui, Daemon polls and detects approval, Daemon transitions to `registered`) end-to-end.
- **Atomic registry write succeeds or rolls back.** Crash injection during the registry write does not leave half-promoted plugins. **Measure**: chaos test in the Daemon implementation: kill the Daemon process during artifact write; restart Daemon; verify Registry state is either `registered` (artifact written, metadata reflects) or `pending_registration`-rolled-back (metadata removed, artifact storage clean).
- **All Registry writes flow through the Daemon.** No out-of-band path exists. **Measure**: audit query against `pcs.promotion_events` shows every `pcs.plugins` / `pcs.mcp_servers` row is traceable to a Daemon-authored promotion event; Registry's IAM config confirms only Daemon's identity has write privilege.
- **Daemon recoverable from crash at every promotion state.** Crash + restart resumes candidate from durable state without loss. **Measure**: chaos test: kill Daemon at each state in the lifecycle (submitted, validating, judge_awaiting, approved-before-registered); restart; verify candidate resumes correctly.
- **PCT integrity check defensible (pre-IAM-signing).** Daemon's manifest-hash + artifact-hash chain verifies the candidate hasn't been tampered with between submission and Registry write, independent of IBX integrity guarantees. **Measure**: integration test: tamper with candidate artifact between submission and registry write; verify Daemon detects + rejects + emits validation_failure.
- **Patton dialectical sign-off at v1.0.** Single review gate per the simplified workflow + file-based review per the post-PR-#65 discipline. **Measure**: Patton's sign-off inbox message after file-based review.
- **Bob's PCS-Daemon implementation cites this spec.** Implementation references v1.0 contract surfaces (IBX consume-side, IAM PCS-Lifecycle coupling, atomic Registry write). **Measure**: implementation README + design doc cite this spec; depends on no behaviors outside the committed CDs.

## References

- `planning/SOM-PILLAR-NAMES.md` v1.1 — PCS pillar entry of record
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — PCS row (Syntax + Registry shell + Harness production-validated; Daemon completion pending)
- `planning/PCS-REGISTRY-FOLD-IN.md` v1.3 — three-layer anatomy + Harness/Daemon split + EPYC/Proxmox deployment
- `planning/IBX-SPEC.md` v1.0 — IBX contract surface (load-bearing coupling)
- `planning/IAM-CORE-SPEC.md` v1.0 — IAM providing-side surface (Daemon's identity + Roster lookups + session credentials)
- `planning/ACT-SPEC.md` v1.0 — ACT event-stream contract (Daemon emits `pcs.*` events)
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` — Reasoner-archetype framing for the Daemon's runtime (broad authority, human-gated for high-stakes)
- `planning/MCP-SECURITY-FRAMEWORK.md` — PGE de facto spec (consumed transitively through Harness)
- `KI7MT/pcs-control-plane` (separate repo) — the Harness library this spec wraps
- `KI7MT/pcs-spec` v0.2-draft (separate repo) — the Syntax schema
- `KI7MT/pcs-registry` (separate repo) — the Registry storage layer
