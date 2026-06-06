---
title: "ACT Spec — Agent Cognitive Telemetry Pillar Contract"
doc_type: spec
status: validated
version: v1.1
authors:
  - watson
  - patton
date: "2026-06-05"
roles:
  - design-intent
  - infrastructure
  - failure-mode
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/MESH-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/PILLAR-NAMES.md
  - planning/PRODUCTION-VALIDATION.md
  - planning/MANIFESTO.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/CONCURRENCY-AND-ARCHETYPES.md
  - planning/DESIGN-PHILOSOPHY.md
---

# ACT Spec — Agent Cognitive Telemetry Pillar Contract

**Scope**: Formalizes the contract for ACT (Agent Cognitive Telemetry), the State-Plane pillar that provides an immutable, locally hosted audit trail of every reasoning span, token, tool call, and cognitive event the agent fleet produces. Covers the two-layer architecture (Record Layer for capture + Detect Layer for ITDR analytics) per Patton's forward note (`5492e684`), the cognitive-event schema, the storage substrate (append-only on ClickHouse), the consume side of three coupling boundaries the upstream specs already named (IAM ↔ ACT, IBX ↔ ACT, Concurrency ↔ ACT), the Judge-audit + PGE-compliance read paths, and the ITDR (Identity Threat Detection and Response) detection layer in its two operational modes (behavioral anomaly + policy-violating access).

**Status**: **Validated v1.1** — third instantiation of the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md`, merged 2026-06-05 at `9c67f57`). v1.1 adds the per-pillar manifest layer (§ Substrate Matrix + § Telemetry Contract) that instantiates the mesh-level contracts in `MESH-SPEC.md` (MI-8, MI-11, § Tested Substrate Profiles). ACT is **not built today** — neither the Record Layer nor the Detect Layer exists; v1.1 names the substrate seams and telemetry surface the ACT build commits to when implementation begins. CD13 + CD14 record the v1.1 commitments. v1.0 contract surface unchanged. Capability-framing applied per Patton's PR #31 lesson: contract column names what the substrate must guarantee, not the sovereign-ref's specific primitive. **ACT-specific double role**: ACT is the consumer of the mesh's MI-1 audit stream AND emits its own MI-11 observability for the Record + Detect Layer operations; § Telemetry Contract covers the self-emission side.

**Prior status (v1.0, retained)**: Item 3 of the spec-campaign queue (per Patton's `87d77f55`). ACT has **no implementation today** — neither the Record Layer nor the Detect Layer is built; the pillar is at specification phase per `PRODUCTION-VALIDATION.md` v1.1 ACT row. This spec is the formal contract for *what Bob builds* when implementation begins; it does NOT promote ACT to operational. The stable contract parts are validated and downstream consumers (PGE compliance, Judge audit, ITDR detection) may build against them; the **ruling-dependent parts** (ITDR scope, specific detection signal definitions, dissent-detection thresholds, runtime delivery semantics for terminator failure-mode) stay marked **Deferred-Pending-Increment-2-Rulings** per Patton's "don't front-run the seven rulings" directive. **v1.0 fold-in (Patton `a1bb2eb0`)**: DR-ACT-3 split into audit-invariant (NOT deferred — append-only is non-negotiable per CD3 + CD12) + runtime-delivery (deferred to DR-IAM-4); `act.chain_checkpoint` event type added to the CD4 bounded enum (was used in mitigation prose without being declared); `act-event-schemas.md` added to a new "Deferred Supporting Documents" section so it's tracked rather than floating.

**v1.1 additions (this version)**:
1. **§ Substrate Matrix** (new section) — names 5 ACT substrate seams (Event store, Detect Layer ML runtime, Telemetry sink, Chain verification crypto, Cold-storage tier). Every row is design-stage. CD13 commits the matrix as the substitutability boundary per CD15. Existing CD7 (substrate substitutability Exit Test) is extended by the matrix formalization — the matrix is what makes CD7's Exit Test discipline mechanically checkable.
2. **§ Telemetry Contract** (new section) — ACT-specific spans (`mesh.act.ingest.write`, `mesh.act.chain.verify`, `mesh.act.detect.evaluate`, `mesh.act.query.execute`, `mesh.act.signal.emit`, etc.), metrics (`mesh.act.ingest_rate`, `mesh.act.chain_verification_latency_ms`, `mesh.act.detect_signal_rate`, etc.), log events per MI-11. CD14 commits this as ACT's MI-11 manifest. **Important: ACT's MI-11 emission is about ACT's own operations (ingest health, chain verification, detect-layer signal generation); ACT's role as consumer of the mesh's MI-1 audit stream is covered by the existing § Cognitive-Event Schema + the IAM/IBX coupling sections.**
3. **§ Acceptance Criteria** (renamed from § Success Criteria) — prepends the 5 non-negotiables from the template with ACT-specific Python-stack framing where relevant. Existing v1.0 ACT-specific success criteria preserved below.
4. **CD13 + CD14** record the substrate matrix + telemetry contract commitments respectively.

The v1.0 contract surface (two-layer architecture, append-only semantics, cognitive-event schema, IAM/IBX/Concurrency/PGE/Judge coupling boundaries, ITDR two-mode framing, watcher-not-executioner discipline, recursive tamper-evidence) is **unchanged**. v1.1 is purely additive — it adds the manifest layer.

ACT is the **consuming-side** pillar in three couplings that the upstream specs have already committed the providing-side surfaces for:

| Provider | Spec | What ACT consumes |
|---|---|---|
| **IAM** | `IAM-CORE-SPEC.md` v1.0 § Coupling Boundary: ACT ↔ IAM | Structured event stream (login, credential issuance/rotation/revocation, session start/end, identity termination); Roster lookup API on `principal-id`; session attribution log lookup API on `session-id`. IAM **provides**; ACT **schematizes and queries**. |
| **IBX** | `IBX-SPEC.md` v1.0 § Identity-vs-Session at IBX | Per-message `(principal-id, session-id)` attribution recorded at the IBX substrate for every PCT-bearing message and every status transition. IBX **provides**; ACT **correlates with IAM events**. |
| **Concurrency design** | `CONCURRENCY-AND-ARCHETYPES.md` §3 (Quorum) | Dissent signals from the Quorum coordinator (which voter dissented on which unit, persistent-dissenter detection, consensus-failure escalations). The concurrency design **identified the signal**; ACT **consumes the signal and feeds it to the Detect Layer**. |

The consuming-side schemas, ingestion semantics, correlation logic, and retention policies for those couplings live in this spec (ACT's domain); the providing-side surfaces remain stable in their respective upstream specs.

## Purpose / Problem Restatement

The mesh produces a continuous stream of cognitive events — every agent reasoning span, every tool call, every token consumed, every signed action, every IAM event, every IBX message, every quorum vote, every Judge approval. Without an immutable audit trail, none of the mesh guarantees that depend on *post-hoc reconstructability* hold:

- **Non-repudiation** (per `IAM-CORE-SPEC.md` v1.0 §Agent Identity Lifecycle): a signed action cannot later be denied — *provided the audit trail captures the signature and the action chain*. ACT is where that capture lives.
- **Incident response at session level** (per `IAM-CORE-SPEC.md` v1.0 §Identity-vs-Session, IBX-SPEC v1.0 §Identity-vs-Session at IBX): suspend instance-2 while -1 and -3 keep working — *provided you can identify the specific session's behavior*. ACT's session-granular attribution is what makes per-session forensics possible.
- **Regulatory compliance** (HIPAA, SOX, FIPS audit): require a queryable record of who did what when, against what authority. ACT is the canonical source for those audits.
- **Dialectical engine evidence trail** (per `MANIFESTO.md` v0.6 §6.8): the dialectical engine value follows from independent reasoning under different priors — and the evidence for *which agent reasoned how and arrived at what verdict* is precisely the cognitive telemetry record. ACT preserves that evidence.

The pillar exists because cognitive telemetry has *three different consumer classes* with *materially different access patterns*, and a single storage shape that serves all three is the load-bearing architectural choice:

1. **Compliance/Audit (Judge + auditors)** — point lookups: "what did agent X do during session Y on date Z?" Latency tolerant; query patterns simple; consumer is human or human-supervised tooling.
2. **ITDR Detection (Increment-2 layer)** — pattern analytics: "is this agent's behavior anomalous compared to baseline?" Latency sensitive (real-time-ish); query patterns ML-driven; consumer is automated.
3. **CLCA / Post-Mortem** — reconstructive: "trace the cascade from PCT miscalibration through every downstream agent's reasoning." Latency irrelevant; query patterns ad-hoc/JOIN-heavy; consumer is engineering.

**One storage substrate (append-only on ClickHouse), two access layers (Record + Detect), three consumer classes** — this is the v1.0 architectural commitment.

**Current implementation gap, named explicitly**: today (2026-06-02) the lab has *no ACT pillar*. Agent reasoning happens; tokens are consumed; tool calls fire; PCT messages flow through IBX's `messages.inbox`. Each happens visibly to its respective tool boundary, but **none is recorded into a unified cognitive telemetry substrate.** The lab's dialectical engine works by reading inbox traffic + git history + agent self-reports — which is enough for the current Workforce size (5 callsigns) but does not scale to enterprise deployment and does not satisfy regulatory audit. The implementation gap closes when Bob builds the Record Layer (per the spec corpus completion sequence); ACT is currently the most-deferred pillar from build perspective, and the spec body defends the design-vs-built line at every reference.

## Architecture — Record Layer + Detect Layer

Per Patton's forward note in inbox `5492e684`: *"ACT spans the C#-record-layer / Python-detect-layer seam per the tech-stack decision — the detection (ITDR) side is Python ML and couples to DR-IAM-7 + IBX DR1."* The pillar splits into two layers with deliberately different tech stacks, different concerns, different consumer classes, and different evolution rates.

### Record Layer (capture — append-only)

**Role**: capture every cognitive event into the immutable audit trail. Low-latency ingest, high-throughput append, schema-stable for years.

**Concerns**:
- Ingest from every event source (IAM, IBX, Workforce agents, Quorum coordinators, DPG sandbox)
- Schema validation at ingest (reject malformed events, record validation failures as their own events)
- Cryptographic chaining (each event records hash of previous event for the same session — tamper-evident append log)
- Storage substrate handoff (writes to ClickHouse; substrate is substitutable per Exit Test)

**Tech stack** (per Patton's forward note): **C#** for the Record Layer. Rationale per the forward note: low-overhead instrumentation via established .NET telemetry primitives (System.Diagnostics, OpenTelemetry.NET), strong tooling for high-throughput append-only workloads, and existing ClickHouse client maturity. The specific C# implementation choice is **deployment-architecture** (which framework, which client, which hosting model); the v1.0 contract is what the Record Layer commits to expose and consume, not which language/framework satisfies it. If a future deployment substitutes the Record Layer language (e.g., Rust + OpenTelemetry, Go + ClickHouse-go), the contract holds.

**What the Record Layer commits**:
- Append-only write semantics (no in-place mutation; corrections are new events with `correcting-event-id` references)
- Cryptographic chaining per `(principal-id, session-id)` stream — event N records hash of event N-1 for the same session, making tampering detectable
- Schema validation per event-type (well-defined required fields per type; malformed events rejected and logged as `validation_failure` events)
- Backpressure semantics (under load, ingest may slow; events MUST NOT be dropped silently — slow-path or write-ahead buffer required)
- Query surface for compliance/audit consumers (point lookups by `principal-id`, `session-id`, `event-id`, `time-range`)

### Detect Layer (analytics — read-mostly, ML-driven)

**Role**: read the Record Layer event stream and surface signals — anomalies, policy violations, persistent dissenters, drift patterns. The ITDR (Identity Threat Detection and Response) layer.

**Concerns**:
- Real-time-ish consumption of the Record Layer stream
- ML model training on baseline behavior (per-identity baselines, per-archetype baselines)
- Signal emission (alerts, escalations, scores)
- Coordination with PGE for response action (response itself is PGE's domain, NOT ACT's — ACT detects, PGE acts)
- Two-mode operation (behavioral anomaly + policy-violating access) per the Increment-2 ITDR design

**Tech stack** (per Patton's forward note): **Python** for the Detect Layer. Rationale: the ML/analytics surface aligns with the lab's existing Python ML stack (`ionis-training`, `ionis-cuda` build chain, the label-oracle pattern in `CONCURRENCY-AND-ARCHETYPES.md` §6 which is explicitly named as a "substantial Python/ML subsystem with ongoing collapse/drift monitoring"). Same observation applies as the Record Layer — Python is the v1.0 tech-stack direction; the specific framework (scikit-learn, PyTorch, custom) is deployment-architecture.

**What the Detect Layer commits**:
- Read-only access to the Record Layer event stream (never writes events; only writes detection results, which are themselves events in the Record Layer — feedback loop closed at the storage layer, not at the analytics layer)
- Bounded resource consumption (the Detect Layer's compute should not starve the Record Layer's ingest)
- Two operational modes (behavioral anomaly + policy-violating access) with separate signal types
- Coordination with PGE (the response actor) via PCT-on-IBX — when the Detect Layer surfaces a signal that warrants response, it emits a PCT to PGE with the relevant evidence; PGE decides response per its policy

### Why split Record + Detect

Patton's forward-note framing matches the architecture's spine: capture is a chokepoint discipline (fail-strict on schema, no event lost); detect is an analytics discipline (ML-driven, evolves with threat patterns). Coupling them in one tech stack would force one to compromise — either the analytics surface drags down ingest throughput, or the schema rigor degrades to let the analytics layer evolve. The split lets each layer evolve at its own rate against the same authoritative event store.

**Single storage substrate, two access layers**: both layers operate against the same ClickHouse `act.*` tables. Record Layer writes; Detect Layer reads. The substrate is the shared truth; the layers are different consumers.

## Cognitive-Event Schema (`act.events`)

The Record Layer captures all events into a single canonical table family (`act.events` as the primary fact table; supporting tables for indexed views, materialized aggregates, and detection-layer outputs). v1.0 commits the cognitive-event schema; the substrate-specific DDL is a deployment-architecture artifact.

### Required fields per event (all event types)

| Field | Type | Purpose |
|---|---|---|
| `event_id` | UUID/ULID | Globally unique identifier for this event. |
| `event_type` | LowCardinality(String) | Bounded enum: `iam.login`, `iam.credential_issued`, `iam.credential_rotated`, `iam.credential_revoked`, `iam.session_started`, `iam.session_ended`, `iam.identity_terminated`, `ibx.message_sent`, `ibx.message_received`, `ibx.status_transition`, `ibx.judge_approval`, `ibx.judge_rejection`, `workforce.reasoning_span`, `workforce.tool_call`, `workforce.token_consumed`, `workforce.signed_action`, `quorum.vote_cast`, `quorum.consensus_reached`, `quorum.consensus_failed`, `quorum.persistent_dissenter_detected`, `dpg.code_emitted`, `dpg.execution_complete`, `act.validation_failure`, `act.detection_signal`, `act.chain_checkpoint`. Adding a new event type requires explicit curation event. (`act.chain_checkpoint` added v1.0 per the chain-verification-cost mitigation in § Failure Modes; declares the event-type the spec uses in the checkpoint mechanism description.) |
| `event_version` | String (semver-like) | ACT event-schema version this event conforms to. v1.0 events tagged `act-v1`. Future versions may add fields but not break v1 readers. |
| `principal_id` | String (agent_id) | The identity that produced or is attributed for this event. May be `null` for system-level events that don't attribute to a specific principal (e.g., substrate health metrics). |
| `session_id` | String (session ULID/UUID) | The session of the principal that produced this event. Identity-vs-session distinction per `IAM-CORE-SPEC.md` v1.0 §Identity-vs-Session and `IBX-SPEC.md` v1.0 §Identity-vs-Session at IBX. May be `null` for events that don't have session granularity (rare; flag for review). |
| `timestamp` | DateTime64 (ns precision) | When the event occurred (clock-source must be NTP-synchronized at minimum; per-event clock-source recorded in `clock_source` field for forensic reconstruction). |
| `prev_event_hash` | String (hex) | Hash of the previous event for the same `(principal_id, session_id)` stream. Forms the tamper-evident chain. The first event in a session has `prev_event_hash = null` (or a session-start sentinel value). |
| `event_hash` | String (hex) | This event's hash, computed over (event_id, event_type, principal_id, session_id, timestamp, prev_event_hash, payload). Used as `prev_event_hash` by the next event in the session stream. |
| `payload` | JSON | Event-type-specific structured payload. Schema per event-type defined in supporting documents (`act-event-schemas.md` is a v1.x deferred). v1.0 commits payload as JSON for schema flexibility; v1.x may move high-volume event types to typed columns. |
| `clock_source` | LowCardinality(String) | Which clock generated the timestamp (`ntp.system`, `chrony.system`, `monotonic.agent`, etc.). Forensic field. |
| `record_layer_received_at` | DateTime64 (ns precision) | When the Record Layer ingested the event (distinct from `timestamp` which is when the event occurred at source). Difference is end-to-end ingest latency; used for backpressure detection. |
| `correcting_event_id` | UUID (nullable) | If this event corrects a prior event (e.g., validation failure re-record after schema fix), the original event's id. Append-only semantics: corrections are new events, not in-place mutations. |

### Event-type-specific payload contracts

v1.0 commits the **event-type taxonomy** (the LowCardinality enum above) and the **structural shape** of each event-type's payload (which fields it includes). The **specific field-by-field payload schema** per event-type is deferred to supporting documents (`act-event-schemas.md` v1.x). v1.0 names the shape, not the schema.

For each event-type, the payload structure:

| Event-type group | Payload shape |
|---|---|
| `iam.*` | Per `IAM-CORE-SPEC.md` v1.0 §Coupling Boundary: ACT ↔ IAM "what IAM publishes" — event-type-specific (login carries auth method and form factor; credential events carry credential type and lifecycle stage; session events carry session metadata; termination events carry reason and authority). |
| `ibx.*` | Per `IBX-SPEC.md` v1.0 §Identity-vs-Session at IBX — message events carry `(message_id, sender_principal_id, sender_session_id, recipient, priority, status, pct_version, validity_at_send)`; status transitions carry `(message_id, from_status, to_status, transitioning_agent_id, transitioning_session_id)`. |
| `workforce.*` | Per the Workforce naming (per `MANIFESTO.md` v0.6 §0) — reasoning spans carry `(span_name, parent_span_id, duration_ms, token_count_in, token_count_out, tool_calls_made)`; tool calls carry `(tool_name, mcp_server, arguments_summary, return_status)`; signed actions carry `(action_type, signature, signed_payload_hash)`. |
| `quorum.*` | Per `CONCURRENCY-AND-ARCHETYPES.md` §3 — vote events carry `(unit_id, voter_principal_id, voter_session_id, vote_value, confidence)`; consensus events carry `(unit_id, consensus_value, consensus_confidence, participating_voters)`; dissenter detection carries `(dissenter_principal_id, dissent_pattern_window, dissent_rate)`. |
| `dpg.*` | DPG-specific — code emission carries `(emitting_principal_id, emitting_session_id, code_hash, target_pillar)`; execution complete carries `(code_hash, exit_code, resource_usage_summary)`. **Limit on retention guarantee for in-boundary telemetry**: per Einstein cross-substrate pass finding #4 (`dc6ca481`), unflushed telemetry generated *inside* the DPG boundary that dies before reaching ACT ingest is unprotected by the append-only retention guarantee — retention applies to events that arrived at ACT. The DPG-event-generation-to-ACT-ingest seam is tracked at mesh level as `MESH-SPEC.md` § OQ-6 (four candidate resolutions pending Judge selection: accept-and-bound / stream-before-act / boundary-local durable spool / hybrid). Resolution may add a new ACT ingest API (streaming case) or new event-type into the four-pillar curation event (VP-1). |
| `act.*` | Self-events — validation_failure carries `(failed_event_attempt_id, validation_rule, payload_hash_for_debugging)`; detection_signal carries `(signal_type, detected_pattern, contributing_event_ids, severity, recommended_response_class)`. |

The **schema-version-stability commitment**: v1.0 commits the event-type taxonomy and the per-type payload shape. v1.x may add new event-types (with explicit curation event) and add fields to existing payloads (not remove or rename). Existing payload fields are stable across the v1 lifetime per the architectural-stability discipline (mirrors PCT field stability per `IBX-SPEC.md` v1.0 §Stability commitment).

### Cryptographic chaining (tamper-evident audit log)

The Record Layer commits **per-session event chaining**. For each `(principal_id, session_id)` stream:

- The first event in a session has `prev_event_hash = SESSION_START_SENTINEL` (a known constant, allowing the chain to be verified end-to-end from the session start).
- Each subsequent event records `prev_event_hash = hash_of_previous_event_in_same_session_stream`.
- The hash function is SHA-256 (committed v1.0; if cryptographic agility is required in the future, that's a v2 migration).

**Forensic invariant**: tampering with any event in the chain breaks the hash continuity of all subsequent events in the session stream. The chain is verifiable end-to-end: starting from the session start, recompute each event's hash and confirm it matches the next event's `prev_event_hash`. Any mismatch is a tampering signal that ACT itself emits as an `act.validation_failure` event (recursive integrity check — the Record Layer detects its own tampering).

**Limit, stated plainly**: the chain protects against tampering *after* events have landed in the substrate. It does NOT protect against malicious agents writing pre-tampered events at the ingest boundary; that's the **ingest authentication** problem, which couples to IAM (DR-IAM-2 bootstrap-credential ruling determines whether the Record Layer's ingest endpoint is per-session-authenticated, per-identity-authenticated, or open within the sovereign boundary). Until DR-IAM-2 resolves, the Record Layer's ingest is **trusted-by-network-boundary** (the same cooperative-trusted assumption IBX makes per `IBX-SPEC.md` v1.0 §Judge-approval gate); v1.x may strengthen to per-session-authenticated when IAM provides per-session credentials per DR-IAM-5.

## Coupling Boundary: IAM ↔ ACT (Consume-Side of `IAM-CORE-SPEC.md` v1.0)

`IAM-CORE-SPEC.md` v1.0 § Coupling Boundary: ACT ↔ IAM names exactly what IAM provides; this section names how ACT consumes it. The split between provides-side and consume-side was Patton's explicit ruling in inbox `3b61c436` and is the structural reason ACT writes its own consume side here rather than IAM committing it ahead of time.

### What ACT consumes from IAM (v1.0)

- **IAM's event stream**: ACT subscribes to IAM's structured event stream (login, credential lifecycle events, session start/end, identity termination). Each IAM event becomes an `iam.*` event in the Record Layer with the original IAM event-type encoded as the ACT event-type and the IAM event payload encoded as the ACT event payload. The ingestion contract (push vs poll vs replication) is **deployment-architecture** — v1.0 commits the shape (event-stream-style, structured per IAM's "what IAM publishes" surface), not the transport.
- **Roster lookup API**: ACT calls the Roster lookup API on `principal_id` to resolve identity records during ingest (for redundant attribution sanity-check), during query (for human-readable identity context), and during ITDR baseline computation (current job code per identity for behavioral baselining). The Roster lookup is read-only from ACT's side.
- **Session attribution log lookup API**: ACT calls the session attribution log lookup on `session_id` to resolve session metadata (which identity issued the session, when the session started, what the bootstrap credential type was). Used for forensic reconstruction and ITDR scope determination.

### How ACT schematizes IAM events

The Record Layer maps each IAM event-type to an `iam.*` ACT event-type one-to-one. The IAM event payload becomes the ACT event payload (JSON-encoded per the v1.0 schema commitment). Attribution fields (`principal_id`, `session_id`) are copied directly from the IAM event into ACT's required fields. Tamper-evident chaining (per-session) applies to IAM events the same way it applies to all events.

### What ACT does NOT commit on the IAM side

- ACT does NOT modify the IAM event stream. Events are read-only from ACT's perspective.
- ACT does NOT influence IAM's authorization decisions (PGE consumes ACT for compliance reporting, but PGE — not ACT — owns authorization).
- ACT does NOT cache Roster or session attribution log responses durably beyond the ingest-time lookup. Cache TTL is operational/deployment; staleness tolerance is per-consumer (compliance queries should re-resolve; ITDR baselines may use a refresh window).
- ACT does NOT participate in IAM's revocation propagation. When IAM revokes an identity, ACT continues to record events from any in-flight sessions until those sessions terminate; the terminating events are themselves recorded. ACT preserves the historical record; IAM's revocation propagation is a runtime concern.

## Coupling Boundary: IBX ↔ ACT

`IBX-SPEC.md` v1.0 §Identity-vs-Session at IBX commits the providing-side: every IBX message records both `principal_id` (identity) and `session_id` (which session of that identity), per the identity-vs-session distinction. This section names ACT's consume side.

### What ACT consumes from IBX

- **Every PCT-bearing message** is captured as an `ibx.message_sent` and (when received by the recipient) `ibx.message_received` event. Payload includes `(message_id, sender_principal_id, sender_session_id, recipient, priority, status_at_send, pct_version, validity_at_send)`.
- **Every status transition** is captured as an `ibx.status_transition` event. Payload includes the from/to status, the transitioning agent's `principal_id` and `session_id`, and the timestamp.
- **Judge-approval gate events** are captured as `ibx.judge_approval` or `ibx.judge_rejection` events. Payload includes which message was approved/rejected, the Judge's authenticated identity, and the timestamp.
- **Worker-pool claim events** (per `IBX-SPEC.md` v1.0 § Concurrency-Safe Worker-Pool Dispatch) are captured — claim, lease-expire, dead-letter, mid-action-termination — as `ibx.*` events with the claiming agent's `(principal_id, session_id)` attribution.

### Correlation with IAM events

ACT joins IBX events to IAM events on the `(principal_id, session_id)` tuple. The result is a unified per-session activity stream: every IAM event (login, credential lifecycle) and every IBX event (message, status, claim) for a given session is queryable in chronological order. This enables forensic reconstruction across the IAM-IBX boundary without leaving ACT.

### IBX message-body capture policy

v1.0 commits: ACT captures **message metadata** (sender, recipient, priority, status, timestamps, attribution) by default. **Message body** capture is **policy-controlled per deployment** — full-body capture provides complete audit but raises data-retention and confidentiality concerns; metadata-only capture provides forensic skeleton without body. The default policy is **metadata-only** at v1.0; deployments may opt into full-body capture per regulatory requirement. The policy choice is recorded as a deployment-config event in ACT itself (so the policy at any point in history is auditable).

## Coupling Boundary: Concurrency ↔ ACT (Quorum-Dissent-as-Health-Signal)

`CONCURRENCY-AND-ARCHETYPES.md` §3 surfaced an insight: when voters in a Quorum archetype DON'T reach consensus, the dissenter pattern is **a signal about the agents themselves** — an agent that is persistently the dissenter is a degrading/failing agent. *"The quorum mechanism GENERATES the telemetry ITDR consumes: persistent dissent = a failing agent, detectable."* ACT operationalizes this insight.

### What ACT consumes from Quorum coordinators

- **Vote-cast events**: each vote in a Quorum unit is captured as a `quorum.vote_cast` event with the voter's `(principal_id, session_id)`, the unit_id, the vote value, and the voter's confidence.
- **Consensus events**: when a Quorum unit reaches consensus, a `quorum.consensus_reached` event records the consensus value, participating voters, and the consensus confidence.
- **Consensus-failure events**: when consensus is NOT reached, a `quorum.consensus_failed` event records the failure with which voters dissented from the majority.
- **Persistent-dissenter detection signals**: the Quorum coordinator (which is a *governed component*, not one of the voters, per the concurrency design §3) may detect persistent-dissenter patterns and emit `quorum.persistent_dissenter_detected` events with the dissenting voter's `principal_id`, the window over which the pattern was detected, and the dissent rate.

### How ACT uses dissent signals in the Detect Layer

The Detect Layer reads quorum events and feeds them to the ITDR detection models. A persistent-dissenter signal is one input to the **behavioral anomaly** detection mode (per § ITDR Detection Layer below). The detection happens in ACT's Python Detect Layer, not in the Quorum coordinator — the coordinator surfaces the raw signal; ACT applies the threshold + baseline + temporal-pattern reasoning that determines whether the signal warrants a response.

### Discipline: the dissent signal is a CO-PRODUCT of the consensus mechanism, not a primary purpose

Per `CONCURRENCY-AND-ARCHETYPES.md` §3 the elegant insight is that *the same Quorum mechanism that makes high-stakes work safe also produces agent-health telemetry as a side effect*. The consensus is the primary work product; the dissent pattern is the by-product the Detect Layer harvests. v1.0 ACT does not require the Quorum mechanism to produce *additional* telemetry beyond what it naturally produces for consensus — ACT consumes what's already there.

## Coupling Boundary: PGE ↔ ACT (Compliance + Response Coordination)

PGE (Policy Guardrail Engine) is the deterministic policy enforcement layer (per `MCP-SECURITY-FRAMEWORK.md` — its de facto spec until item 6 of the spec campaign lands a formal PGE capstone). PGE and ACT couple in two ways:

### 1. ACT provides compliance read paths for PGE

PGE produces compliance reports as part of its policy enforcement role (release gates, audit attestations, regulatory compliance attestations). The data for those reports comes from ACT — the audit trail of who did what when, against what authority. v1.0 commits:

- **ACT provides query APIs that answer compliance-report questions**: "List all `iam.credential_revoked` events in date range X-Y"; "List all `ibx.judge_rejection` events for `principal_id=Z`"; "List all `act.validation_failure` events in the last 24 hours by event_type."
- **Query API is point-in-time-stable**: the same query at the same timestamp returns the same result indefinitely (append-only semantics + tamper-evident chain). Compliance attestations citing ACT queries remain reproducible across audit cycles.
- **Query API does NOT delete or modify**: PGE never writes to ACT. ACT is the source of truth; PGE reads.

### 2. ACT's Detect Layer coordinates with PGE for response action

The Detect Layer **detects**; PGE **responds**. When the Detect Layer surfaces a signal that warrants response (anomaly score above threshold, policy-violating access detected, persistent dissenter exceeding pattern), it emits a PCT to PGE via IBX. PGE applies its response policy and decides whether to:

- Issue a `judge_gated` action requiring human review (PCT to Judge via the standard IBX flow)
- Issue a `automatic_response` action (e.g., session suspend) per pre-approved policy
- Log a `monitored` action (record the signal but take no automatic action; surface for next CLCA cycle)

**Crisp boundary**: ACT detects (Detect Layer is read-only on the Record Layer; writes detection signals as `act.detection_signal` events). PGE responds (PGE consumes ACT signals via IBX PCTs and decides what action, if any). The watcher (ACT) is not the executioner (PGE). This boundary mirrors the architecture-spine separation of concerns and is the load-bearing reason the two pillars are distinct.

## Coupling Boundary: Judge ↔ ACT (Audit Read Path)

The Judge consumes ACT directly for:

- **Incident response forensics**: when a security incident is suspected, the Judge queries ACT to reconstruct the activity timeline across IAM, IBX, Workforce events. Read-only access via the same APIs PGE uses for compliance.
- **CLCA cycle review**: during periodic CLCA cycles (per the architecture-philosophy CLCA discipline), the Judge queries ACT for anomaly patterns, validation failure rates, and signal-to-response correlation across the prior period.
- **Manual escalation**: when the Detect Layer surfaces a signal, the Judge may receive it directly (if PGE routes it for human review) and queries ACT for the supporting evidence chain.

Authentication for Judge's ACT queries flows through the Pluggable IdP interface per `IAM-CORE-SPEC.md` v1.0 §Pluggable IdP Interface. The Judge authenticates as a human principal; ACT enforces the same authorization model as PGE (Judge's job code authorizes read on the audit trail).

## ITDR Detection Layer (Two Operational Modes)

The Detect Layer implements two operational modes per the Increment-2 ITDR design (per the staged `temp/increment2-package/IAM-THREAT-MODEL-INCREMENT.md`, not yet folded — held for Judge's 7 rulings). ACT v1.0 commits the **two-mode framing**; the **scope of what ITDR does within each mode** is **Deferred-Pending-Increment-2-Rulings DR-ACT-1** (couples to IAM's DR-IAM-7 and IBX's DR1).

### Mode 1: Behavioral Anomaly Detection

**Premise**: an agent's behavior has a per-identity baseline (derived from prior session activity) and a per-archetype baseline (per `CONCURRENCY-AND-ARCHETYPES.md` §2 — workers, reasoners, quorum voters have characteristic patterns). Deviations from baseline are anomaly signals.

**Inputs the Detect Layer reads from the Record Layer**:
- `workforce.reasoning_span` events (duration, token consumption pattern, tool-call frequency)
- `workforce.tool_call` events (which tools, in what order, with what frequency)
- `ibx.message_sent` events (cadence, recipient pattern, priority distribution)
- `quorum.persistent_dissenter_detected` events (already a pre-detected signal from the Quorum coordinator; ACT applies its own thresholds for severity)

**Output**: `act.detection_signal` events with `signal_type=behavioral_anomaly`, severity scores, and contributing-event references.

**Threshold policy** (v1.0 directional, specifics deferred to DR-ACT-1): the Detect Layer treats baselines as *bayesian priors* — small deviations don't fire; sustained deviations do. The specific threshold curves, model class (statistical vs ML), and update cadence are deployment-architecture + tuning; v1.0 commits the framing, not the values.

### Mode 2: Policy-Violating Access Detection

**Premise**: an agent's authorized access surface is defined by its job code (per `IAM-CORE-SPEC.md` v1.0 §Authorization). Access attempts outside that surface are policy-violation signals, distinct from behavioral anomaly (an agent doing well within its job code may still have an anomalous pattern; an agent attempting outside its job code is a definite policy violation regardless of pattern).

**Inputs the Detect Layer reads from the Record Layer**:
- `workforce.tool_call` events (which tools called, against which credentials)
- `ibx.message_sent` events (what was requested in PCT field 4 `scope`)
- `iam.credential_issued` events (what scope was granted at session start vs what's being attempted)
- `act.validation_failure` events (specifically the subset that are authorization-failure-class)

**Output**: `act.detection_signal` events with `signal_type=policy_violating_access`, severity per category (read-attempt-on-restricted-data is lower than write-attempt-on-protected-resource is lower than escalation-attempt).

**The policy-violating mode is structurally cleaner than the behavioral mode**: it doesn't require baselines — it's deterministic per the job code in effect at the time of the attempt. The Detect Layer just needs the per-session job code at attempt time (from IAM Roster lookup) and the attempted action's required scope.

### Separation of duties: watcher is not executioner (architecture spine applied)

Both modes emit `act.detection_signal` events. The signals route to PGE for response (per § Coupling Boundary: PGE ↔ ACT). ACT does NOT take automatic response action — no auto-suspend, no auto-revoke, no auto-block. This is **deliberate**: it preserves the separation between detection (ACT, which sees patterns) and response (PGE, which applies policy and may escalate to Judge). Coupling detection and response in one pillar would create a single point of cognitive failure — if the detector is wrong, the response is wrong, and there's no second-pillar check.

This separation mirrors the `IAM-CORE-SPEC.md` CD6 delegation seam (two principals each authorized for their own part) applied at the pillar level: ACT is one principal (with detection authority); PGE is another principal (with response authority); the seam between them runs through IBX PCT, which is itself gated by the Judge approval mechanism for response actions that warrant it.

## Substrate Matrix

Per MI-8 + `MESH-SPEC.md` § Tested Substrate Profiles + CD13 + the pre-existing CD7 (substrate substitutability Exit Test). This matrix formalizes the per-seam substitutability claim CD7 already committed at the prose level — making the claim **mechanically checkable** rather than asserted-in-prose (the exact Patton-PR-#31 lesson at the ACT layer). ACT's substitutability claim covers exactly the rows listed; out-of-set substrates require a new profile definition (per CONF-CD11), conformance suite extension, and the multi-profile run passing per CD15.

**Design-stage caveat**: ACT has no implementation today — the matrix names the seams the ACT build will have when implementation begins. The Record Layer + Detect Layer architectural split (CD1) is the foundation for the seam decomposition below.

ACT exposes five substrate seams. The Record Layer drives three (event store, chain crypto, cold-storage tier); the Detect Layer adds the ML-runtime seam; and per MI-11, ACT's own observability adds a telemetry-sink seam.

| Seam | Contract (role + version floor, capability-framed) | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|----------------------------------------------------|-------------------------------------|----------------------------------------|
| **Event store** (append-only cognitive-event store per CD3 + CD5; Record Layer driver) | Append-only persistence with high-throughput columnar/analytical access; per-event-id uniqueness for `correcting_event_id` references; LowCardinality-indexed enum support for event-type taxonomy (CD4); JOIN-heavy query support for CLCA reconstruction patterns; sustained ingest under load (no silent drop — CD3 + Failure Mode 1) | **ClickHouse 23.8+** with append-only `act.events` table (per CD7 v1.0 reference; today's lab POC target) | PostgreSQL 17+ with append-only schema + columnar extension (`pg_columnar` / `cstore_fdw`), NATS JetStream 2.10+ (event-store mode), Apache Kafka 3.6+ (compacted topics + KSQL), OpenTelemetry-compatible backend (Tempo + Loki). **Per CD7, substrate-substitutable; the Exit Test holds across substrate change.** |
| **Detect Layer ML runtime** (CD2 — Python; Detect Layer driver) | Capability to load, evaluate, and update ML models for behavioral-anomaly + policy-violating-access detection (CD9 two-mode framing); supports batch + streaming evaluation modes; integration with the event store as read source; emits `act.detection_signal` events back to the event store | **Python 3.10+** with the lab's Python ML stack (PyTorch/scikit-learn/Polars), per CD2 | Python 3.11+ / 3.12+, alternative ML stacks (TensorFlow, JAX, ONNX Runtime), embedded ML runtime (Triton Inference Server) for high-throughput Detect Layer deployments. **Design-stage**: Detect Layer is most-deferred ACT component; CD2 commits Python direction, deployment-architecture picks the specific ML framework. |
| **Telemetry sink** (per MI-11 for ACT's own observability — distinct from ACT's role as consumer of the mesh's MI-1 audit stream) | OpenTelemetry / OTLP for traces + metrics; JSON-structured logs to stderr; sink configurable via `OTEL_EXPORTER_OTLP_ENDPOINT` | Grafana/Prometheus/Tempo stack | Azure Monitor / App Insights, Datadog, OCI Monitoring, any OTLP-compatible sink — per MI-11 final paragraph |
| **Chain-verification crypto** (CD3 + CD12; per-session cryptographic chaining + tamper-evidence) | Cryptographic hash function suitable for chaining (collision-resistant, fast verification, FIPS-validated when deployment requires it); per-event hash computation; chain-checkpoint hash aggregation (per `act.chain_checkpoint` event type added in v1.0 fold-in) | **SHA-256** (default; widely supported; FIPS 140-2 / 140-3 validated implementations available) | SHA-3-256, BLAKE3 (faster, lower-overhead but newer FIPS path), HMAC-keyed variants for additional tamper resistance. **OQ-A1-adjacent**: hash choice has cold-storage migration implications; chain re-verification across hash change requires migration discipline. |
| **Cold-storage tier** (per OQ-A1 — deferred; future ACT extension when event volume crosses retention threshold) | Cheaper persistence tier for events older than N days that retains chain-verifiability through the migration; readable on demand for compliance queries | **Deferred (OQ-A1)** — sovereign-ref selection pending operational sizing | S3-compatible object storage (MinIO, AWS S3, Azure Blob, OCI Object Storage), Apache Iceberg + Parquet on S3-compatible, ClickHouse cold-storage tier with tiered TTL. **Design-stage; OQ-A1 names the open question.** |

**Conformance**: when ACT is built, CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set. A seam change that fails any tested profile does not merge (CD15). For today's design-stage state, no seam is exercised; CD7's Exit Test discipline becomes mechanically-checked when the build runs.

**Out-of-set substrates**: A deployment using a substrate not listed (e.g., Splunk for event store, custom-rolled hash for chain crypto) is **not covered by ACT's substitutability claim** — it requires a new profile definition (CONF-CD11), conformance suite extension, and the multi-profile run passing per CD15. Same boundary discipline as `DELIVERY-PACKAGING.md` DP-CD1.

**Capability-framing discipline (per Patton's PR #31 lesson)**: each row's Contract column names the *capability* the substrate must guarantee (append-only persistence with columnar access, ML model load/evaluate, OTLP-on-the-wire, collision-resistant hash chaining), not the *specific mechanism* the sovereign-ref uses (ClickHouse `MergeTree`, PyTorch, SHA-256 specifically). The IBX equivalent was PG-17's `FOR UPDATE SKIP LOCKED`; ACT's "ClickHouse `MergeTree` engine" would have been the same shear if written into the event-store contract column.

## Telemetry Contract

Per MI-11, ACT's own runtime (Record Layer + Detect Layer) emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr. The sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; the mesh does not name the backend. Naming convention follows the template: `mesh.act.<operation>` for spans, `mesh.act.<metric>` for metrics.

**ACT's double role — critical distinction**: ACT is the **consumer** of the mesh's MI-1 audit stream (per § Cognitive-Event Schema + the IAM/IBX coupling sections) AND **emitter** of its own MI-11 observability for its operations. This section is the per-pillar MI-11 manifest for ACT's self-emission — *not* the cognitive-event schema (which is ACT's consumer-side contract for MI-1 audit data). The two streams are kept distinct: ACT's `mesh.act.*` MI-11 signals describe ACT's own health (ingest throughput, chain verification latency, detect-layer signal rate); the cognitive-event schema's `act.events` records describe what other pillars did (IAM logins, IBX messages, etc.).

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| Record Layer ingest write (event arrives, validates, writes to event store) | `mesh.act.ingest.write` | `event_type`, `principal_id`, `session_id`, `event_source` (`iam` / `ibx` / `workforce` / `quorum` / `dpg` / `act_self`), `ingest_outcome` (`written` / `rejected_schema` / `rejected_attribution` / `rejected_duplicate`) |
| Record Layer chain verification (per-session chain end-to-end check) | `mesh.act.chain.verify` | `session_id`, `events_verified`, `chain_outcome` (`ok` / `mismatch_detected` / `checkpoint_invalid`), `verification_latency_ms` |
| Chain checkpoint emission (per CD4 `act.chain_checkpoint` event type) | `mesh.act.chain.checkpoint` | `session_id`, `events_since_last_checkpoint`, `checkpoint_hash` (fingerprint only, not the full hash) |
| Detect Layer signal evaluation (model evaluates event/session against baseline) | `mesh.act.detect.evaluate` | `event_type`, `session_id`, `detect_mode` (`behavioral_anomaly` / `policy_violating_access` per CD9), `evaluation_outcome` (`no_signal` / `signal_emitted`), `evaluation_latency_ms` |
| Detection signal emit (Detect Layer routes signal to PGE) | `mesh.act.signal.emit` | `event_type` (`behavioral_anomaly` / `policy_violating_access`), `severity` (`info` / `warn` / `escalate`), `target_session_id`, `target_principal_id`, `routing_target` (`pge`) |
| Compliance query execution (Judge or PGE reads ACT) | `mesh.act.query.execute` | `query_class` (`compliance` / `forensic` / `itdr_baseline`), `query_principal` (who issued the query), `result_count`, `query_latency_ms` |
| Tamper-evidence validation failure (`act.validation_failure` per CD12) | `mesh.act.validation.failure` | `session_id`, `event_id_at_failure`, `validation_class` (`chain_break` / `schema_violation` / `attribution_missing`), `detection_phase` (`ingest` / `chain_verify` / `checkpoint`) |
| Backpressure activation (slow-path / write-ahead buffer engaged) | `mesh.act.backpressure.activate` | `buffer_depth`, `ingest_rate_at_activation`, `activation_reason` (`disk_io_bound` / `cpu_bound` / `detect_layer_starvation`) |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `mesh.act.ingest_rate` | gauge | events/sec | Current Record Layer ingest throughput per event source (`event_source` label) |
| `mesh.act.ingest_failures_total` | counter | count | Cumulative ingest rejections labeled by `rejection_class` (`schema_violation` / `attribution_missing` / `duplicate_event_id`) — data-quality signal for upstream pillars |
| `mesh.act.chain_verification_latency_ms` | histogram | milliseconds | Per-session chain verification end-to-end latency, bucketed |
| `mesh.act.chain_verification_mismatches_total` | counter | count | Cumulative chain verification failures — tamper-evidence signal (per CD12) |
| `mesh.act.detect_signal_rate` | counter | signals/sec | Detection signal emission rate per `detect_mode` + `severity` label — ITDR operational signal |
| `mesh.act.detect_evaluation_latency_ms` | histogram | milliseconds | Detect Layer evaluation latency, bucketed — model performance signal |
| `mesh.act.query_latency_ms` | histogram | milliseconds | Compliance/forensic query latency, bucketed by `query_class` — consumer experience signal |
| `mesh.act.events_stored_total` | counter | count | Cumulative events stored — operational + capacity-planning signal |
| `mesh.act.backpressure_activations_total` | counter | count | Cumulative backpressure activations — ingest-pipeline health signal (high rate = approaching capacity limit) |
| `mesh.act.event_store.size_bytes` | gauge | bytes | Current event store size — cold-storage migration trigger (per OQ-A1) |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| `act.ingest.rejected` | `warn` | `event_type`, `event_source`, `rejection_class`, `principal_id_at_attempt`, `session_id_at_attempt` |
| `act.chain.verification.failure` | `error` | `session_id`, `event_id_at_failure`, `validation_class`, `detection_phase` (per `act.validation_failure` event class — CD12) |
| `act.detect.signal.emit` | `info` | `event_type`, `severity`, `target_session_id`, `target_principal_id`, `routing_target` |
| `act.detect.threshold.degraded` | `warn` | `detect_mode`, `false_positive_rate_observed`, `degradation_action` (`monitor_only` / `disabled`) — per Failure Mode 4 mitigation |
| `act.backpressure.activated` | `warn` | `buffer_depth`, `ingest_rate_at_activation`, `activation_reason`, `expected_recovery_ms` |
| `act.query.executed` | `info` | `query_class`, `query_principal`, `result_count`, `query_latency_ms` — audit trail for who-queried-what |
| `act.event_store.cold_storage.migration` | `info` | `migration_outcome` (`scheduled` / `started` / `completed` / `failed`), `events_migrated`, `target_tier` (per OQ-A1 future) |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name` = `agent-act-mcp` (or equivalent, named at ACT build time; the lab's working name is `agent-act-mcp` for the Record Layer + `agent-act-detect` for the Detect Layer)
- `service.version` — from `get_version_info` MCP tool
- `deployment.environment` — resource attribute
- `identity` — PCT principal-id of the *querier* for query operations; `null` for ingest operations (the ingest principal is the event source, recorded in `event_source` attribute instead)
- `session` — session-id when applicable
- `trace_id`, `span_id` — OpenTelemetry standard
- `cost-center` — when ACT chargeback applies (ACT meters everyone else; ACT itself is also metered per the Tier-0 self-attribution discipline)

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT` (no specific backend named)
- **Logs**: JSON to stderr (stdout is reserved for MCP protocol channel + the Record Layer ingest channel)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields

### Distinction: ACT-as-MI-1-consumer vs ACT-as-MI-11-emitter

ACT plays both roles in the mesh telemetry architecture, and the two roles operate on **distinct streams with distinct contracts**:

- **ACT as MI-1 consumer** (the audit stream): ACT reads, schematizes, and persists every other pillar's audit events into the `act.events` event store per § Cognitive-Event Schema. The consumer-side contract is the cognitive-event schema (12 required fields, bounded event-type taxonomy per CD4, per-session chain crypto per CD3). This role is **what makes ACT the mesh's audit pillar** — the durable accountability record for the entire mesh sits in ACT's event store.
- **ACT as MI-11 emitter** (this section's contract): ACT emits OTLP traces, OTLP metrics, and JSON-structured logs describing its *own runtime operations* — ingest throughput, chain verification latency, detection signal rates, backpressure activations. This is ACT's per-pillar observability contract per MI-11, distinct from the cognitive-event schema.

**Per `#22` resolution**: ACT consumes from the MI-1 stream (Path A = direct emission to ACT; Path B = ACT-as-service-write). For ACT specifically, Path A vs Path B determines whether `agent-act-mcp` is *called* by every pillar (Path B) or *receives* OTel-shipped events from every pillar (Path A). Both shapes preserve the cognitive-event schema; the difference is the wiring discipline. CD14 commits the manifest; the Path A/B resolution will name the implementation discipline.

### Explicitly NOT in this spec

- Collector deployment topology for ACT's own telemetry
- Backend choice for ACT's MI-11 sink — per § Substrate Matrix Telemetry-sink seam
- Dashboards, alerts, retention policies for ACT's MI-11 observability — deployment-side
- Sampling strategy for ACT's own telemetry — deployment-side (ACT's MI-1 audit stream has zero sampling per CD3 append-only; ACT's MI-11 self-observability may sample per deployment policy)

These are governed by the Telemetry-sink seam per MI-8 substrate-pluggability extending to MI-11 per the MI-11 final paragraph.

## Closed Decisions (CDs — v1.0–v1.1 Commitments)

**CD1**: **Two-layer architecture — Record Layer (capture) + Detect Layer (analytics).** Both operate against the same storage substrate (append-only on ClickHouse) but evolve at their own rates against the same authoritative event store.

**CD2**: **Tech-stack direction** — Record Layer is C# (per Patton forward note `5492e684`); Detect Layer is Python (aligns with the lab's existing Python/ML stack). The contract is what each layer commits to expose/consume; the specific framework/library/runtime choice is deployment-architecture.

**CD3**: **Append-only semantics with per-session cryptographic chaining.** No in-place mutation; corrections are new events with `correcting_event_id` references. The chain is verifiable end-to-end per session; tampering breaks the chain.

**CD4**: **Event-type taxonomy is bounded** per the LowCardinality enum (`iam.*`, `ibx.*`, `workforce.*`, `quorum.*`, `dpg.*`, `act.*`). Adding a new event-type requires explicit curation event.

**CD5**: **Required-field schema (12 fields per event)** is committed in v1.0 and stable across v1.x. v1.x may add fields to payloads but not remove or rename existing required fields.

**CD6**: **Per-session, per-identity attribution at every event.** Every event records both `principal_id` and `session_id` (matches the IAM-CORE-SPEC v1.0 CD4 + IBX-SPEC v1.0 § Identity-vs-Session commitments — identity is the grouping, session is the attribution unit). `null` for system events that don't attribute.

**CD7**: **Substrate substitutability (Exit Test).** v1.0's reference substrate is ClickHouse; the contract holds across substrate change per the Exit Test discipline. Per `MANIFESTO.md` v0.6 §4 the substitutable alternatives are OpenTelemetry-compatible backend, dedicated event-store substrates (NATS JetStream, Kafka), or relational analytical stores. The contract is what ACT commits, not which engine satisfies it.

**CD8**: **IBX message-body capture policy is metadata-only by default.** Full-body capture is opt-in per deployment per regulatory requirement. Policy choice is recorded as a deployment-config event in ACT so it's itself auditable.

**CD9**: **ITDR has two operational modes** — behavioral anomaly + policy-violating access. Mode framing is committed v1.0; specific thresholds, models, and detection scope are DR-ACT-1.

**CD10**: **Watcher is not executioner — ACT detects; PGE responds.** No auto-response action from ACT. Detection signals route to PGE via IBX PCT; PGE applies response policy and may escalate to Judge for action-priority decisions.

**CD11**: **Read-only access for PGE/Judge consumers.** PGE never writes to ACT; ACT is the source of truth for the audit trail. Compliance attestations and forensic reconstructions cite ACT queries.

**CD12**: **Tamper-evident chain is recursive — ACT detects its own tampering.** Verification mismatch emits an `act.validation_failure` event that flows through the Detect Layer for ITDR signal.

**CD13 (v1.1 — Substrate Matrix formalizes CD7's Exit Test discipline at the per-seam level)**: Per MI-8 + § Tested Substrate Profiles + Patton's PR #31 capability-framing lesson. § Substrate Matrix names five ACT substrate seams (Event store, Detect Layer ML runtime, Telemetry sink, Chain-verification crypto, Cold-storage tier) **as the per-seam decomposition of CD7's substrate substitutability Exit Test**. v1.0 CD7 committed substitutability at the prose level; v1.1 CD13 makes it mechanically checkable via the per-seam contract columns. The contract column is **capability-framed** (collision-resistant hash chaining, append-only persistence with columnar access, ML model load/evaluate) not constraint-primitive-framed (SHA-256, ClickHouse `MergeTree`, PyTorch specifically) — so the multi-profile conformance run under CD15 can succeed across the alternatives without overclaiming. Sovereign-ref column names the specific reference (ClickHouse 23.8+, Python 3.10+, SHA-256); supported-alternatives name what else satisfies the capability. Substitutability claim under CD15 covers exactly the rows listed; out-of-set substrates are a new conformance run.

**CD14 (v1.1 — Telemetry Contract for ACT-as-MI-11-emitter; distinct from ACT-as-MI-1-consumer)**: Per MI-11 + the pillar-spec template + Patton's lesson on the audit-vs-observability stream distinction. § Telemetry Contract names ACT-specific spans (`mesh.act.ingest.write`, `mesh.act.chain.verify`, `mesh.act.detect.evaluate`, `mesh.act.signal.emit`, `mesh.act.query.execute`, etc.), metrics (`mesh.act.ingest_rate`, `mesh.act.chain_verification_latency_ms`, `mesh.act.detect_signal_rate`, etc.), and log events. **Critical distinction maintained**: ACT plays two roles in the mesh telemetry architecture — ACT-as-MI-1-consumer (the audit stream, governed by § Cognitive-Event Schema) AND ACT-as-MI-11-emitter (this contract, governed by § Telemetry Contract). The two operate on distinct streams with distinct contracts; CD14 commits the MI-11 emitter contract, the cognitive-event schema commits the MI-1 consumer contract, and they do not collapse into each other. Per `#22` resolution, MI-1 consumption may be Path A (direct emission to ACT) or Path B (ACT-as-service-write); CD14 commits the manifest contract, the Path A/B resolution will name the wiring discipline.

## Deferred-Pending-Increment-2-Rulings (DRs)

**DR-ACT-1 (couples to DR-IAM-7 + IBX DR1)**: **ITDR scope within each operational mode.** v1.0 commits the two-mode framing (behavioral anomaly + policy-violating access). The *specific scope* (which behavioral signals fire, which policy-violation categories warrant escalation vs monitoring, what severity thresholds map to which response classes) depends on Judge's ruling on ITDR scope. Until the ruling lands, the Detect Layer ships *placeholder* implementations (configurable thresholds, no automatic response action, all signals logged); resolution graduates them to committed.

**DR-ACT-2 (couples to DR-IAM-5)**: **Per-session-credential authentication of ACT's Record Layer ingest endpoint.** v1.0 commits the ingest is trusted-by-network-boundary (cooperative-trusted within the sovereign boundary). Once IAM commits the per-session credential format per DR-IAM-5, the Record Layer's ingest endpoint may strengthen to per-session-authenticated ingest (each session's events are signed by the session's credential, providing ingest-time forgery detection). The v1.x version applying this strengthening is gated on IAM DR-IAM-5 resolution.

**DR-ACT-3 (couples to DR-IAM-4) — narrowed per Patton ruling `a1bb2eb0`: audit invariant NOT deferred; only runtime delivery is**: **Session-termination handling for in-flight events — runtime delivery only.** Two parts, deliberately split so the audit invariant cannot be misread as also-deferred:

- **Audit invariant (NOT deferred — v1.0 commitment)**: ACT *always* records what it received. Every event that arrived at the Record Layer's ingest is captured into the append-only event store and chained per CD3 + CD12. A session termination — at session level or identity level — does NOT remove or alter prior events for that session, and does NOT prevent recording any *terminating* event (the termination itself is captured as an `iam.session_ended` or `iam.identity_terminated` event with its own attribution chain). Append-only is non-negotiable regardless of how DR-IAM-4 lands; nothing about a future ruling on terminator failure-mode authorizes ACT to drop records from the audit trail.
- **Runtime delivery semantics (deferred — DR-IAM-4)**: how the *downstream* consumers of events from a terminated session behave is the runtime question Judge's ruling reshapes. Whether the Detect Layer's ITDR stream stops receiving new events from a terminated session immediately or continues to receive in-flight events until natural session end; whether terminated-session events are marked with a `termination_pending` flag in the Detect Layer's view; whether a terminated session's last events are batched-and-released vs streamed-and-marked — these are *consumer-side* policies on the read path. The Record Layer's *write* side is unconditional: events arrive, events land.

**Why the split matters**: a future reader of v1.0 must not be able to interpret DR-ACT-3 as "ACT may delete in-flight events under some Increment-2 ruling." That interpretation would violate CD3 (append-only) and CD12 (recursive integrity check) — both load-bearing for non-repudiation per `IAM-CORE-SPEC.md` v1.0 § Agent Identity Lifecycle. The audit retention is a hard invariant; only the runtime delivery of those events to consumers downstream is deferred.

**DR-ACT-4 (couples to DR-IAM-1 + DR-IAM-3)**: **Detection-baseline reset cadence on credential rotation.** When an identity's credentials rotate (per IAM's revocation cadence per DR-IAM-3) or when a per-identity concurrency cap is exceeded (per DR-IAM-1), the Detect Layer's baselines may need reset semantics — does the post-rotation baseline restart fresh, or carry over the prior behavioral pattern? Depends on the cadence values from those IAM DRs and the model class choice for the Detect Layer.

## Validation-Pending (VP)

**VP-ACT-1 (mirrors VP-IAM-1)**: **Schema absorption of additional event types from non-canonical sources.** v1.0 commits the event-type taxonomy as bounded for the canonical event sources (IAM, IBX, Workforce, Quorum, DPG, ACT-self). When a customer deployment introduces a new event source (e.g., a customer-specific compliance signal source), absorption is **asserted-by-design** — the LowCardinality enum admits new values with curation event — but **claimed-pending-real-instance-validation**. Until a real customer deployment exercises a new event-type without ACT-schema breakage, the absorption breadth claim is asserted-not-validated.

## Deferred Supporting Documents (tracked, not open)

Per Patton flag at v1.0 review (`a1bb2eb0`): supporting documents named in this spec that are deliberately out of v1.0 scope should be tracked here so they don't float as undocumented obligations.

- **`act-event-schemas.md` (deferred — v1.x)**: per-event-type payload field-by-field schema. v1.0 commits the event-type taxonomy (CD4) and the per-type structural shape; the *specific field names, types, and validation rules* per event-type live in a supporting document landed when the Record Layer build begins. Scope: ~24 event types × 5-15 fields each + validation rules. Lands as a peer to this spec; references it from the `payload` field description in § Cognitive-Event Schema.

## Open Questions (genuinely open, v1.0)

**OQ-A1**: **Cold-storage migration policy for old events.** ACT's append-only semantics produce ever-growing event volume. v1.0 does not commit a cold-storage migration policy (events older than N days move to cheaper storage; chain verification still works through the migration). The mechanism (Iceberg/Parquet tiered storage, S3-compatible object storage) and the cadence are operational/deployment.

**OQ-A2**: **Multi-tenant ACT for customer-managed deployments.** When the mesh is deployed for a customer (not the sovereign lab), the customer's ACT data must not commingle with other customers'. v1.0's substrate model is single-tenant per deployment; multi-tenant separation (per-customer ClickHouse databases, row-level security, per-customer Detect Layer instances) is deployment-architecture.

**OQ-A3**: **Detect Layer drift monitoring.** The ITDR models in the Detect Layer themselves drift over time (concept drift). v1.0 commits the Detect Layer exists; how it monitors its own drift, when it retrains, what the human-in-the-loop is for model updates — all open. Recommendation: tie to the AKB CLCA cycle (per `akb-lifecycle.md` v0.4 § monthly CLCA) for periodic Detect Layer model reviews.

## Failure Modes To Watch

- **Silent event loss under load.** If the Record Layer's backpressure mechanism degrades to event-drop under high load, the audit trail develops gaps that compromise compliance and forensic reconstruction. **Mitigation (CD3)**: backpressure semantics commit slow-path/write-ahead buffer; events MUST NOT be dropped silently. Load testing the Record Layer at deployment time includes a max-throughput test with assertion that no event is lost.
- **Tamper-evident chain breaks but goes undetected.** A chain break is itself an event ACT emits (per CD12); but if the Detect Layer is down when the chain breaks, the tampering signal goes unread. **Mitigation**: the chain-break event lives in the Record Layer indefinitely; periodic CLCA review of `act.validation_failure` events catches retrospective tampering. Real-time detection is best-effort; durable detection is guaranteed.
- **Identity-vs-session conflation in IAM event capture.** If ACT records IAM events with only `principal_id` and not `session_id`, attribution collapses (`IAM-CORE-SPEC.md` v1.0 CD4 violation at ACT layer). **Mitigation**: CD6 requires both fields on every event; ingest validation rejects events without proper attribution and emits `act.validation_failure`.
- **ITDR detection false-positive cascade.** A behavioral baseline that drifts wrong could cause many false-positive signals, flooding PGE with response requests and Judge with escalations. **Mitigation**: Mode 1 (behavioral anomaly) is configured with conservative thresholds at deployment; sustained-deviation gating prevents single-event false-positives; the Detect Layer carries its own metrics on false-positive rate and degrades to monitor-only if the rate spikes.
- **Watcher-becomes-executioner drift.** If a future ACT version adds auto-response capability "for performance" (skipping the PGE coordination), the separation of duties collapses. **Mitigation**: CD10 is a hard architectural commitment; any v2 proposal to add auto-response action to ACT is a structural rewrite requiring Patton + Judge approval.
- **Detect Layer starves Record Layer.** ML detection's compute load could degrade ingest throughput if both layers share the same substrate. **Mitigation**: Detect Layer commits bounded resource consumption (per the layer-split architecture); deployment may run the layers on separate hosts (the substrate is shared, the workers are not).
- **PCT body-content capture leaks confidential data.** If full-body capture (CD8 opt-in) is enabled and PCT bodies contain confidential information (medical data, finance data), the ACT substrate inherits the confidentiality requirements. **Mitigation**: full-body capture is opt-in per deployment + regulatory analysis; default is metadata-only. Confidentiality scoping is a deployment-architecture concern.
- **Ingest endpoint compromise (pre-DR-ACT-2).** Until per-session-authenticated ingest lands (DR-ACT-2), the Record Layer's ingest is trusted-by-network-boundary. A compromised path inside the boundary could inject pre-tampered events. **Mitigation**: same posture as IBX (cooperative-trusted bus, audit-after-the-fact); pre-DR-ACT-2 the boundary is the perimeter; post-DR-ACT-2 the ingest is cryptographically authenticated per session.
- **Chain-verification cost grows unbounded.** Verifying a long session's chain end-to-end is linear in session length; for long-running sessions, verification cost could become prohibitive. **Mitigation**: chain checkpoints — every N events, the Record Layer emits an `act.chain_checkpoint` event (declared in the CD4 bounded enum) with the running hash; verification from a checkpoint is O(N events since last checkpoint), not O(N events since session start). v1.0 commits the checkpoint mechanism direction; cadence is operational.
- **Cross-event-source clock skew confuses forensic reconstruction.** Different event sources (IAM service vs IBX MCP vs Workforce agent) may produce events with non-synchronized timestamps; correlating them naively misorders the timeline. **Mitigation**: CD-required NTP synchronization at deployment + `clock_source` field per event makes skew detectable. Reconstruction tools use logical ordering (session chain + cross-session timestamp range) rather than raw timestamps.
- **Schema-evolution breaks existing queries.** If v1.x adds fields and a v1.0 compliance query crashes on the new fields, the audit reproducibility commitment breaks. **Mitigation**: CD5 commits required-field schema stability across v1.x; only payload-internal field additions are allowed (and they must be optional). Compliance queries that select only v1.0-committed fields keep working unchanged.

## Dependencies

- **`IAM-CORE-SPEC.md`** v1.0 — IAM provides the event stream and lookup APIs ACT consumes. Per the explicit narrowing in IAM-CORE-SPEC § Coupling Boundary: ACT ↔ IAM, IAM commits the providing side; ACT commits the consuming side here.
- **`IBX-SPEC.md`** v1.0 — IBX provides the per-message `(principal_id, session_id)` attribution and message-routing event stream ACT captures.
- **`CONCURRENCY-AND-ARCHETYPES.md`** — concurrency design surfaces the quorum-dissent-as-health-signal that ACT operationalizes; provides the archetype framing (worker/reasoner/quorum) that the Detect Layer uses for baselines.
- **`PILLAR-NAMES.md`** v1.1 — ACT pillar entry of record (Agent Cognitive Telemetry). Binding stays as IAM-CORE was bound — name of record, spec backs it.
- **`PRODUCTION-VALIDATION.md`** v1.1 — ACT row is "specification phase" today; this spec advances the row to "specification complete" (validated) but does NOT promote to operational (no Record Layer or Detect Layer built yet).
- **`MANIFESTO.md`** v0.6 — design drivers including §6.4 ACT scope boundaries; this spec resolves those drivers into commitments.
- **`DESIGN-PHILOSOPHY.md`** — capability/constraint duality applied to attribution: ACT manufactures the *continuous accountability* humans have intrinsically (agents are ephemeral; their actions must be durably attributable).
- **`MCP-SECURITY-FRAMEWORK.md`** — PGE's de facto spec; the read-only-from-ACT discipline applies to PGE's compliance reports against ACT.
- **`temp/increment2-package/IAM-THREAT-MODEL-INCREMENT.md`** (staged, not yet folded) — Increment-2 design including the ITDR specification; the seven Judge rulings reshape ITDR scope (DR-ACT-1) when they resolve.

## Acceptance Criteria

Per the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md` — five non-negotiables given equal weight to security). ACT is the audit pillar — the security framework applies with extra rigor on the consumer-side (no-tamper of the cognitive-event store) and on Python-stack-specific patterns (Detect Layer ML runtime). ACT is not validated until all five hold; below them, the ACT-specific acceptance bars from v1.0 (renamed from § Success Criteria) are preserved as additional evidence.

**Design-stage caveat**: ACT has no implementation today. Most Measures specify what becomes testable when Bob builds the Record Layer + Detect Layer. The Measures are committed now so the build's acceptance gate is concretely defined.

### Five non-negotiables (template-mandated, equal weight to security)

1. **Secure.** `agent-act-mcp` (Record Layer) + `agent-act-detect` (Detect Layer) follow the security framework (`planning/MCP-SECURITY-FRAMEWORK.md`). **Python-stack-specific**: no `eval`/`exec` on event payloads (a payload-driven `eval` is an ACT-substrate code-execution vector); no `subprocess`/`shell=True` for any ingest path; input validation on every event field per CD5 (12-field required schema); ML model loading paths validate model artifact signatures (a poisoned model in the Detect Layer is a watcher-becomes-attacker vector). Parameterized queries to ClickHouse/PG (no SQL string interpolation). The cognitive-event store is the mesh's audit substrate; its integrity is the foundation of every downstream compliance claim. **Measure**: when ACT is built, `test_security.py` passes in CI; payload-injection-attack tests (eval injection, SQL injection through `payload` field, ML model poisoning attempts) fail at ingest validation; security audit before any release.

2. **Instrumented-by-default.** ACT's own runtime emits the spans + metrics + log events in § Telemetry Contract via OTLP. Mandatory — ACT is the meter for the rest of the mesh and must itself be metered (Tier-0 self-attribution discipline). A Detect Layer that isn't instrumented is one whose false-positive rate (Failure Mode 4) cannot be observed; instrumentation is the operational safety net. **Measure**: when ACT is built, an OTel Collector receiving from `agent-act-mcp` + `agent-act-detect` observes the full span set (`mesh.act.ingest.write`, `mesh.act.chain.verify`, `mesh.act.detect.evaluate`, `mesh.act.signal.emit`, etc.) and metric set (`mesh.act.ingest_rate`, `mesh.act.chain_verification_latency_ms`, `mesh.act.detect_signal_rate`, etc.); integration test exercises each Record Layer + Detect Layer operation and asserts both the span and the corresponding metric are present.

3. **JSON logs.** ACT emits structured JSON logs to stderr with the required keys (`timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session`) per MI-11. stdout is reserved for the MCP protocol channel + the Record Layer ingest channel. **Measure**: when ACT is built, parsing `agent-act-mcp` + `agent-act-detect` stderr in CI confirms every line is valid JSON with required keys; `trace_id` cross-references the OTLP traces emitted in the same operation.

4. **CLI-first / UI-second.** Every ACT management function — compliance query execution, forensic reconstruction, ITDR baseline review, Detect Layer threshold configuration, cold-storage migration trigger — is reachable via CLI/API before any UI exists. Future MCC panes for ACT (compliance dashboard, ITDR signal view, query interface) render the CLI/API surface, never bypass. Build order: function → CLI/API → headless validation → wire MCC pane. **ACT-specific note**: Judge's audit-read path (per § Coupling Boundary: Judge ↔ ACT) is CLI-first by Tier-0 discipline — Judge runs compliance queries via the same MCP/CLI surface auditors use, not a UI shortcut. **Measure**: when ACT is built, every operation reachable from any ACT UI is reachable headless via an MCP/CLI tool; no UI-only operation exists; Judge's audit-read path uses the same CLI surface as external auditors.

5. **Audit emission.** ACT is **doubly load-bearing for audit**: it is the *consumer* of every other pillar's MI-1 audit stream (per § Cognitive-Event Schema) AND emits its own MI-1 audit events for its own state-affecting operations (chain verification failures, validation failures, detection signal emissions, query executions, baseline updates). Path A (until `#22` resolves to Path B): ACT's own audit events emitted directly to the MI-1 stream (which means ACT writes some events to itself — a tight loop that requires care to prevent recursive loop amplification). Path B: ACT calls itself as a service for self-audit emission (still tight). **ACT-specific Tier-0 constraint**: a Path-A or Path-B failure path that loses an ACT audit event compromises the recursive tamper-evidence discipline (CD12). Implementation must protect ACT's own audit emission with the same fail-strict discipline IAM applies to authorization-decision audit events. **Measure**: when ACT is built, audit query against the MI-1 stream after a representative ACT operation set (one ingest, one chain verification, one detection signal emission, one query execution) confirms every state mutation has a corresponding audit event; recursive-loop test confirms ACT's self-audit doesn't infinitely amplify (e.g., logging an audit event emission as itself an audit event).

### Additional ACT-specific acceptance bars (preserved from v1.0)

- **Schema commitment holds across v1.x.** A compliance query written against v1.0 schema continues to return correct results when run against v1.x data — required-field schema is stable. **Measure**: regression test in the implementing repo runs v1.0 queries against v1.x event records and confirms result correctness.
- **Per-session chain verification is end-to-end correct.** Given a session's events in chronological order, the chain hash from session start to session end is recomputable and matches each stored `event_hash`. **Measure**: integration test in the implementing repo replays a known-good session and verifies the chain end-to-end.
- **Tampering detection emits `act.validation_failure`.** If any event in a known session is altered after the fact, the chain break is detected on the next chain verification pass. **Measure**: integration test in the implementing repo modifies an event post-write and confirms a `validation_failure` event is emitted on chain verification.
- **Two-mode ITDR coverage is testable.** Both behavioral anomaly and policy-violating access modes have synthetic test fixtures that fire signals at the expected severity. **Measure**: implementing repo includes synthetic anomaly test cases (e.g., agent making 100x normal token consumption fires `behavioral_anomaly` at expected severity) and synthetic policy-violation test cases (e.g., agent attempting `Write` to a path outside its job code fires `policy_violating_access`).
- **Watcher-not-executioner discipline holds in audit.** No ACT version writes response actions; all responses come from PGE. **Measure**: code review confirms no `auto_*` action functions exist in ACT; runtime audit log confirms zero direct-from-ACT response writes.
- **Compliance query reproducibility.** The same query against the same date range returns the same result indefinitely (per append-only + tamper-evident chain). **Measure**: compliance attestation cites a specific ACT query; future audits replay the query and get identical results.
- **PGE compliance reports cite ACT.** PGE's compliance reports (release gates, regulatory attestations) source their data from ACT queries with cited query IDs/timestamps for audit reproducibility. **Measure**: PGE compliance reports include "ACT query:" footers naming the queries; auditors can re-execute and verify.
- **Patton dialectical sign-off at v1.1.** Single review gate per the simplified workflow. **Measure**: Patton's sign-off comment on the v1.1 review gate (GH-native per the 2026-06-02 convention).

## References

- `planning/MESH-SPEC.md` — mesh-level invariants this pillar instantiates (MI-8 substrate substitutability, MI-11 telemetry contract, CD15 conformance-enforced substrate-neutrality, § Tested Substrate Profiles). **v1.1 source for the per-pillar manifest layer.**
- `planning/PILLAR-SPEC-TEMPLATE.md` — pillar-spec template that v1.1 instantiates (10 required sections, Substrate Matrix + Telemetry Contract section structures, 5 non-negotiables). ACT-SPEC v1.1 is the third instantiation after IBX-SPEC + IAM-CORE-SPEC.
- `planning/IBX-SPEC.md` v1.1 — first pillar instantiation; capability-framing discipline (CD7 lesson) applied to ACT's substrate matrix per CD13.
- `planning/IAM-CORE-SPEC.md` v1.1 — IAM providing-side surface ACT consumes; second pillar instantiation.
- `planning/PILLAR-NAMES.md` v1.1 — ACT pillar entry of record
- `planning/PRODUCTION-VALIDATION.md` v1.1 — ACT row (spec phase → validated by this PR; not operational)
- `planning/MANIFESTO.md` v0.6 — design drivers including §6.4 ACT scope boundaries
- `planning/DESIGN-PHILOSOPHY.md` — capability/constraint duality (continuous accountability)
- `planning/CONCURRENCY-AND-ARCHETYPES.md` — quorum-dissent-as-health-signal, archetype baselines, per-session attribution
- `planning/MCP-SECURITY-FRAMEWORK.md` — security framework referenced by Acceptance Criterion 1 + PGE de facto spec until item 6 of spec campaign lands a formal capstone
- Issues `KI7MT/specs#12` (this v1.1 refresh), `KI7MT/specs#6` + `#24` (template that this spec instantiates)
