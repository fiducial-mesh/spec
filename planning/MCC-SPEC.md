---
title: "MCC Spec — Mesh Control Center as Pluggable Host-Frame"
doc_type: spec
status: draft
version: v0.1
authors:
  - watson
  - bob
date: "2026-06-06"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-CONFORMANCE.md
  - planning/SOM-DESIGN-PHILOSOPHY.md
  - planning/SOM-ENGINEERING-STANDARDS.md
  - planning/IAM-CORE-SPEC.md
  - planning/IAM-INCREMENT-2.md
  - planning/IBX-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/PCS-DAEMON-SPEC.md
---

# MCC Spec — Mesh Control Center as Pluggable Host-Frame

**Scope**: MCC (Mesh Control Center) is specified as a **pluggable host-frame** that composes the SOM pillars (IAM, IBX, PCS, ACT, AKB, CRB, PGE, DPG) as **loadable modules**. The fleet and human users point at *one* endpoint — MCC — which dispatches requests to the right pillar plugin. MCC is the central locus for substrate handles (database connections, Vault tokens, telemetry sinks), the IAM auth hook (every request is authenticated against IAM before reaching a plugin), and the operator surface (web admin screen — never CLI for operations). This spec reconciles SOM-CD14 (which previously framed MCC as a thin consumer surface "aggregator") into the corrected frame-and-plugins model. The plugin contract emerges from **IAM as plugin #1** — minimal frame + the contract IAM exercises, hardened as ACT/PCS/etc. plug in next. MCC remains **not a 9th pillar** — pillar count stays at eight; MCC is the structural host the eight pillars live inside.

**Authorship note (design-decided, capture mode)**: Watson-authored, Bob-contributed (build-side plugin-contract read). The substantive design was decided in Judge's 2026-06-06 session with Bob — the kernel/frame model, the single endpoint commitment, the IAM-as-first-plugin sequencing, the web-admin-only operator surface — and is **not re-litigated** in this spec. The spec's job is to write the decided design down to the standard expected of SOM contracts, reconcile it with SOM-CD14, and specify the frame contract and plugin contract precisely enough that Bob can build MCC-frame-v0 + IAM-as-plugin-#1 as one coherent build. Inverted-origin review chain follows the spec landing per the lab's review convention.

**Status**: **Draft v0.1**, Phase 2 gate of the `som-devel/BUILD-PLAN.md` build sequence. Phase 1 (IBX scaffold + IAM application code + iam-1 host VM provisioned + IAM host prep) merged 2026-06-06 ~15:34 UTC. Phase 2 unblocks when this spec lands. The plugin contract is **minimum-viable at v0.1**; the IAM build (Phase 2's first plugin) will exercise it and surface gaps that fold into v0.2. ACT/PCS plugin builds (Phase 3+) further harden the contract.

## Purpose / Problem Restatement

Three structural problems converge on this spec:

1. **The pre-MCC operating model is per-host-stdio-with-sprayed-creds.** Today, each pillar's surface is exposed as a stdio MCP server that the calling agent has direct access to, with credentials scattered across the operator's filesystem (per-org PATs in `~/.config/gh-tokens/`, ClickHouse credentials in `~/.clickhouse-client/`, Vault tokens implicit). This works at lab scale with one human operator and a small agent fleet; it does not survive the move to multi-customer deployments where each customer's substrate is different, credentials must live in *that customer's* secret store, and the agents pointing at it should not need per-host configuration to function. A single endpoint that authenticates the caller, holds the substrate credentials centrally, and dispatches to the right pillar plugin is the natural resolution.

2. **SOM-CD14's "MCC is a thin consumer surface aggregator" framing under-specifies what MCC actually does.** Per SOM-SPEC.md v1.x SOM-CD14, MCC "aggregates pillar seams as panes for human operators; owns no business logic, no policy enforcement, no identity verification, no audit storage." This framing was correct for the *human-surface* aspect of MCC (an admin UI presenting pillar functions to operators), but it leaves unspecified the *hosting* aspect — where do the pillar implementations actually run, who holds the substrate handles, how does authentication wrap every call, how do plugins register and discover each other. The corrected framing is that MCC is **both** the human surface *and* the host frame; the pillars are plugins that live inside MCC. The aggregator framing in SOM-CD14 stays correct as a *partial* characterization; it just was not the whole story.

3. **The plugin contract is under-specified without a worked example.** Naming "pillars are plugins" abstractly invites over-design — every contract surface that *could* exist gets specified, the build never starts, the spec churns. The lab's discipline (per the spec campaign plan, the operator-as-architect pattern, the "agents are employees" frame) is the opposite: **define the minimum frame + the contract the first plugin exercises**, then harden as more plugins join. IAM is the first plugin because the IAM build is already code-complete (per Phase 1) and is the most security-sensitive pillar (agent-out-of-secret-path, Vault dependency, AD federation) — if the plugin contract survives IAM, it survives the rest.

This spec specifies the frame, the plugin contract that IAM will exercise, the operator surface, and the SOM-CD14 reconciliation.

## The Kernel/Frame Model (load-bearing structural choice)

**Statement**: MCC is to SOM what the Linux kernel is to a Linux distribution. MCC is the **kernel/frame**; the pillars (IAM, IBX, PCS, ACT, AKB, CRB, PGE, DPG) are **modules** loaded by the frame at runtime. Every external call (from an agent, a human, an external system) enters MCC's transport layer, is authenticated against the IAM plugin, is dispatched to the target pillar plugin, and returns through MCC's response layer.

**Why kernel/frame, not microservice mesh**: a microservice-style mesh (each pillar as its own deployable network service, talking to each other over RPC) would scatter substrate credentials across every pillar's deployment, fork the auth surface (each service does its own AuthN/AuthZ), and shift the substrate-pluggability concern from one spec (SOM-IP-1) to N specs (per service). The kernel/frame model centralizes:

- Substrate handles in one place (the frame holds the Postgres pool, the Vault client, the AD/IdP federation handle, the OTel sink)
- AuthN/AuthZ at the frame boundary (IAM plugin enforces both; pillars trust the frame's authenticated context)
- Configuration in one place (the frame's config; plugins consume from it via dependency injection or a registry)
- Telemetry sink in one place (the frame collects per-plugin spans/metrics/logs and emits to the OTel sink)
- Operator surface in one place (the web admin UI is part of the frame)

The model is well-mapped engineering — Linux kernel modules, OSGi bundles, Apache Felix, plug-in architectures across decades of software. SOM is not inventing a new pattern; it is selecting a known pattern that fits the substrate-pluggable mesh's structural requirements.

**Why this does not make MCC a 9th pillar**: pillars are the eight *contract surfaces* that customers consume. MCC is the *host* those contract surfaces run inside. The host is part of the deployment but it is not one of the contracts; it is the substrate the contracts live on. SOM-CD1 (eight pillars compose into one mesh) is unaffected. SOM-MI-10 (eight pillar contracts + the other twelve mesh invariants) is unaffected. MCC adds a frame layer below the pillar contracts, parallel to how SOM-IP-1 specifies the substrate layer below the mesh — neither is a pillar; both are structural hosts the pillars depend on.

**Implications**:
- A pillar implementation that does not plug into MCC is not a deployable SOM pillar. Pillars without the plugin contract are spec-only artifacts.
- MCC failure mode is mesh failure mode. If MCC is down, the mesh is down (no endpoint to call). High-availability is a deployment-class concern handled by MCC's hosting model (multiple MCC instances behind a load balancer, with shared substrate handles), not by individual pillars exposing themselves separately.
- The IAM plugin is structurally special: it is the AuthN/AuthZ gate every other plugin's calls pass through. The IAM plugin must be loaded before any other plugin can serve requests. The frame enforces this load order.

## Single Endpoint

**Statement**: the fleet (agents) and human users point at **one** network address — MCC. Per-pillar endpoints (one stdio server per pillar, one HTTP server per pillar, etc.) do not exist in the deployed system; they exist only at the build/test level as plugin entry points the frame composes.

**Mechanism**:
- MCC exposes one HTTP server and one MCP transport. Both surface the same plugin tools; the choice is consumer-side (agents use MCP, humans use HTTP via the admin UI, API consumers use HTTP directly).
- Routing within MCC: every incoming call carries a target identifier (the tool name in MCP semantics, the URL path in HTTP semantics) that names the plugin and the operation. MCC's frame dispatches to the loaded plugin matching the identifier.
- Authentication: every incoming call traverses the IAM auth hook before reaching a plugin. The frame extracts the call's credentials (session token in MCP, bearer token / cookie in HTTP), passes them to the IAM plugin for validation, and only proceeds if the call returns an authenticated principal (identity + role + permissions). Plugins receive the authenticated context as part of the call; they do not perform AuthN themselves.
- Substrate handles: plugins receive substrate handles (Postgres pool, Vault client, etc.) from the frame via dependency injection (or equivalent registry pattern). Plugins do not connect to substrate directly; they request handles from the frame's substrate registry.

**Operator-facing implication**: the customer deployment is **one URL** the customer points their fleet at. Per-customer substrate (their Postgres, their AD, their Vault) is configured at the MCC frame level. The pillars are blind to which substrate they're running against — they consume handles, not connection strings.

## The Stack

The deployed system stack, top-to-bottom:

```
┌─────────────────────────────────────────────────────────┐
│   Admin UI         User UI         Agents (MCP)         │  ← Consumer Surfaces
└─────────────────────────────────────────────────────────┘
                          │
                          ▼ (HTTP / MCP, all to one URL)
┌─────────────────────────────────────────────────────────┐
│              MCC Frame (Som.Console)                    │  ← The Host
│  ┌──────────────────────────────────────────────────┐   │
│  │  Transport (HTTP + MCP)                          │   │
│  ├──────────────────────────────────────────────────┤   │
│  │  IAM Auth Hook (calls IAM plugin)                │   │
│  ├──────────────────────────────────────────────────┤   │
│  │  Plugin Dispatch + Module Registry               │   │
│  ├──────────────────────────────────────────────────┤   │
│  │  Substrate Handles (pg pool, Vault client,       │   │
│  │  AD/IdP federation, OTel sink, config registry)  │   │
│  ├──────────────────────────────────────────────────┤   │
│  │  Loaded Plugins (modules):                       │   │
│  │  [IAM] [IBX] [PCS] [ACT] [AKB] [CRB] [PGE] [DPG] │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼ (substrate connections)
┌─────────────────────────────────────────────────────────┐
│   AD/IdP    Vault    Postgres    OTel sink              │  ← Substrate
└─────────────────────────────────────────────────────────┘
```

**Read top-to-bottom**: consumers (humans via admin UI, agents via MCP) point at MCC; MCC's transport layer authenticates the call via IAM, dispatches to the right plugin, and the plugin uses substrate handles from the frame to do its work.

**Read bottom-to-top in deployment**: substrate (customer-pluggable per SOM-IP-1) is provisioned first; MCC frame is deployed with substrate handles configured; pillar plugins are loaded; the deployment is live.

## The Frame Contract — what MCC provides to plugins

The frame provides the following capabilities to every loaded plugin:

| Capability | What the frame provides | What the plugin assumes |
|---|---|---|
| **Transport** | HTTP server + MCP transport, both routing to plugin handlers | Plugin registers handler functions; frame routes inbound calls to them |
| **Authenticated context** | Every call to a plugin handler carries an authenticated principal (identity + role + permissions), populated by the IAM auth hook before the plugin sees the call | Plugin trusts the authenticated context; does not re-authenticate |
| **Substrate handles** | Postgres pool, Vault client, AD/IdP federation handle, OTel sink — held by the frame, surfaced to plugins via dependency injection / registry | Plugin requests the handles it needs at registration; frame fails plugin load if a required handle is unavailable |
| **Configuration** | Per-plugin config sections, exposed via the frame's config registry | Plugin declares config schema at registration; frame validates and provides resolved values |
| **Telemetry sink** | Single OTel sink the frame collects spans/metrics/logs into and emits | Plugin emits to the sink via the frame's telemetry handle; plugin does not configure its own exporter |
| **Plugin registry** | Other loaded plugins are discoverable by name (a plugin can call into another plugin via the registry) | Plugin discovers peers via the frame's registry; cross-plugin calls go through the registry, not direct connections |
| **Judge-gate hook** | A frame-level hook for operations requiring elevated confirmation (Judge ratification) | Plugin declares which operations are Judge-gated at registration; frame enforces the elevated confirmation flow before dispatching to plugin handler |
| **Lifecycle** | The frame loads plugins at startup, calls their initialization, holds them through runtime, and calls their shutdown at termination | Plugin implements lifecycle hooks (init, shutdown); frame is responsible for ordering (IAM loads first; the rest load after) |

**Out of frame scope**: the frame does NOT implement business logic, policy decisions, audit storage, or identity verification (those are plugins' jobs — PGE, ACT, IAM respectively). The frame's job is to host them.

## The Plugin Contract — what a plugin must satisfy

A pillar implementation that wants to plug into MCC satisfies the following contract. The contract is **minimum-viable at v0.1**, scoped to what IAM (the first plugin) exercises; v0.2 extends it as ACT/PCS exercise additional surfaces.

### v0.1 Plugin Contract

A SOM pillar plugin must provide:

1. **A read-only MCP tool surface** — the agent-facing read operations on the pillar (e.g., for IAM: read agent's own identity, read role, read permissions). The plugin registers these as MCP tools with the frame at startup; the frame routes inbound MCP calls to them after auth.

2. **Privileged service operations behind a non-agent boundary** — write operations and lifecycle operations (e.g., for IAM: mint, suspend, terminate) that an agent must not invoke directly. The frame routes these to non-agent actors (the Judge via the admin UI, the Publish pipeline as a service principal per IAM-INCREMENT-2 CD13). The agent-out-of-secret-path invariant (per IAM-INCREMENT-2 §The Agent-Out-of-Secret-Path Invariant) is enforced at the frame: agents calling a privileged operation are denied at the frame boundary, before reaching the plugin handler.

3. **A substrate dependency declaration** — the plugin names which substrate handles it requires (e.g., for IAM: Postgres pool, Vault client, AD/IdP federation handle). The frame fails plugin load if a required handle is not available.

4. **MI-11 telemetry emission** — per SOM-IP-2 (Pillar Telemetry Contract): the plugin emits OTel spans for its operations, metrics for its rates and depths, and JSON logs with the required attributes (per the pillar-spec template's § Required attributes). The plugin uses the frame's telemetry handle; the frame holds the OTel exporter.

5. **A Judge-gate declaration** — operations requiring elevated confirmation (e.g., for IAM: Terminate per IAM-INCREMENT-2 CD15) are declared by the plugin at registration. The frame enforces the elevated confirmation flow before dispatching.

### Out of v0.1 plugin contract (deferred to v0.2+)

The following are NOT specified in v0.1 because IAM does not exercise them yet:

- **Inter-plugin coordination semantics** — what happens when one plugin calls another, how cross-plugin transactions roll back, how cross-plugin telemetry composes. v0.2 specifies once ACT (which all plugins emit audit to) and PCS (which composes other plugins as pipeline steps) plug in.
- **Plugin replacement** — hot-swapping a plugin version without restarting the frame. Not required for v0.1; deferred.
- **Plugin sandboxing** — running plugins in isolated execution contexts. Not required for v0.1 (all plugins are first-party); deferred.
- **External plugin loading** — loading plugins not built into the frame binary at compile time. Not required for v0.1; deferred.

## Operator Surface

**Hard rule** (per Judge, 2026-06-06): **operator interaction with MCC is the web admin UI; never the CLI for operations.** The CLI and direct API exist for build, test, and emergency debugging — not for routine operator actions. The reasoning is consumer-facing discipline: a customer deployment is operated by a non-engineer admin via a web UI, not by a sysadmin via shell. The lab's operating model must match the customer's.

**Admin UI surfaces** (v0.1 starter set):

- **Roster** — view all agent identities, their roles, their owner, their cost-center, their lifecycle state.
- **Create-an-agent** — onboard a new agent identity (calls the IAM plugin's mint operation; Judge-gated).
- **Suspend** — send an agent home (calls the IAM plugin's suspend operation; reversible).
- **Terminate** — fire an agent (calls the IAM plugin's terminate operation; permanent; Judge-gated with elevated confirm; per IAM-INCREMENT-2 CD15).
- **Audit log** — read recent audit events (consumes ACT plugin's read surface).
- **Telemetry dashboard** — embedded Grafana / Tempo / Prometheus dashboards (per SOM-CD14's original "MCC embeds existing observability" framing — that part of CD14 is preserved unchanged).

**Authentication**: the admin UI authenticates the human via IAM, federated to the customer's AD/Entra/IdP per SOM-MI-8 and CONF-CD1..11. The same IAM plugin that authenticates agent calls authenticates human operators. There is no separate human-auth surface.

**Implementation**: per SOM-CD14, the admin UI is **web (ASP.NET Core + Blazor)**, lives in the `Som.Console` project in `som-core`. The inbox-ui prototype is the seed; production MCC admin UI grows from it.

**CLI exception**: a debug/admin CLI exists at the frame level for emergencies (e.g., MCC start/stop, plugin load/unload at startup, debug-mode requests). This is operator-of-last-resort, not the operator's normal interaction; the UI is the normal path.

## SOM-CD14 Reconciliation

SOM-SPEC.md v1.x SOM-CD14 currently reads (in part):

> *"MCC (Mesh Control Center) is the human control plane, not a 9th pillar. ... MCC aggregates pillar seams as panes for human operators; it owns no business logic, no policy enforcement, no identity verification, no audit storage."*

**What stays correct**: MCC is the human control plane; not a 9th pillar (pillar count stays at eight); MCC owns no business logic, no policy enforcement, no identity verification, no audit storage (those are PGE / IAM / ACT plugins' jobs); embedded observability (Grafana / Tempo / Prometheus) stays as the pattern; CLI-first/UI-second discipline holds at the plugin level (every operation reachable via the admin UI is also reachable via the frame's underlying API a plugin handler responds to).

**What needs to extend**: SOM-CD14's current framing of MCC as a "consumer surface" / "aggregator" is incomplete. MCC is **also** the **host frame** the pillars run inside. The frame holds the substrate handles, the auth hook, the plugin dispatch, the telemetry sink, the config registry — all the structural concerns that a deployment needs *somewhere* and that go unowned without an explicit hosting model.

**Proposed SOM-CD14 amendment** (this spec proposes; ratification at Judge's hand):

> *"MCC (Mesh Control Center) is the human control plane **AND the pluggable host-frame the pillars run inside**, not a 9th pillar. MCC aggregates pillar seams as panes for human operators **and hosts the pillar implementations as loadable modules**; it owns no business logic, no policy enforcement, no identity verification, no audit storage (those live in the respective plugin pillars). **It owns the transport layer, the IAM auth hook, the plugin dispatch, the substrate handles (pg pool, Vault client, IdP federation, OTel sink), the configuration registry, and the Judge-gate hook.** Pillar count stays at eight (SOM-CD1 unaffected); MCC is a *consumer surface* parallel to the agent-facing MCP protocol **AND the structural host the pillar contracts live inside**. The CLI-first/UI-second discipline ensures every admin UI surface reflects a plugin operation an authorized caller could invoke — MCC is never a privileged or parallel-and-divergent control surface. Implementation: web (ASP.NET Core + Blazor), `Som.Console` project in `som-core`. The inbox-ui prototype is the seed; production MCC grows from it."*

The amendment is additive (preserves every existing claim in CD14 and adds the host-frame role). It does not change the pillar count, the conformance scope, or the SOM-MI-10 invariant. Once ratified, this spec replaces "consumer surface" with "consumer surface AND host frame" at all CD14-citing references in the SOM corpus.

## Substrate Matrix

Per the pillar-spec template (and SOM-IP-1), every spec that integrates substrate names the capabilities it requires. MCC's substrate requirements:

| Capability requirement | Why MCC needs it | Reference connector |
|---|---|---|
| **HTTP server + MCP transport** | The frame's transport layer hosts both | ASP.NET Core (HTTP) + MCP SDK |
| **Relational database (transactional)** | Plugin substrate handles (one Postgres pool the frame shares to plugins) | PostgreSQL 17+ |
| **Secret store (HTTPS-accessible, audit-loggable, revocable)** | Frame holds substrate creds + Vault client surfaced to plugins | HashiCorp Vault (per IAM-CORE-SPEC v1.0) |
| **Identity provider (federated, supports SAML/OIDC/LDAP)** | IAM plugin federates TO this for AuthZ; MCC frame holds the federation handle | Microsoft AD / Samba AD / Entra / OpenLDAP / Keycloak |
| **OpenTelemetry sink (OTLP)** | Frame collects per-plugin telemetry, emits to sink | OTel Collector → Tempo / Prometheus / Loki (lab default) |
| **TLS terminator (or self-handled TLS)** | Frame exposes HTTPS-only endpoints (no HTTP) | Caddy / nginx / native ASP.NET Kestrel TLS |
| **Process supervisor / orchestrator** | Hosting the frame process with restart, log capture, resource limits | systemd (lab) / Kubernetes / Podman / Nomad |

Per SOM-IP-1 and SOM-CONFORMANCE: a deployment chooses its substrate per seam; MCC is conformant against the named reference connectors and against any substrate that satisfies the capability requirements per the multi-profile conformance run (SOM-CD15 + CONF-CD1..11).

## Telemetry Contract

Per SOM-IP-2 (Pillar Telemetry Contract). MCC emits telemetry **about the frame itself** (separately from per-plugin telemetry):

### Spans

| Span | When emitted | Required attributes |
|---|---|---|
| `mcc.transport.handle` | Per inbound call (HTTP or MCP) | `transport.kind` (http/mcp), `target.plugin`, `target.operation`, `principal.id`, `outcome` |
| `mcc.auth.validate` | Per call's IAM auth hook invocation | `principal.id` (if authenticated), `auth.outcome`, `auth.latency_ms` |
| `mcc.dispatch.plugin` | Per plugin dispatch (after auth) | `plugin.name`, `operation`, `principal.id`, `judge_gated` (bool) |
| `mcc.plugin.load` | Per plugin load at startup | `plugin.name`, `load.outcome`, `load.duration_ms`, `substrate.handles_required` |
| `mcc.judge_gate.confirm` | Per Judge-gated operation when confirmation is requested | `plugin.name`, `operation`, `principal.id`, `confirmation.outcome` |

### Metrics

| Metric | Type | Labels |
|---|---|---|
| `mcc_requests_total` | counter | `transport`, `plugin`, `operation`, `outcome` |
| `mcc_request_duration_seconds` | histogram | `transport`, `plugin`, `operation` |
| `mcc_auth_validations_total` | counter | `auth.outcome` |
| `mcc_plugin_loaded` | gauge | `plugin` |
| `mcc_judge_gate_pending` | gauge | `plugin`, `operation` |

### Log events

| Event | Level | Trigger |
|---|---|---|
| `mcc.startup.frame_loaded` | INFO | Frame initialization complete |
| `mcc.startup.plugin_loaded` | INFO | Each plugin successfully loaded |
| `mcc.startup.plugin_load_failed` | ERROR | Plugin load failed (substrate handle missing, config invalid, etc.) |
| `mcc.auth.denied` | WARN | A call failed AuthN/AuthZ |
| `mcc.dispatch.plugin_unavailable` | ERROR | A call references a plugin/operation that isn't loaded |
| `mcc.judge_gate.requested` | INFO | A Judge-gated operation requested elevated confirmation |
| `mcc.shutdown.frame_unloading` | INFO | Frame shutting down |

### Required attributes (per MI-11, all MCC events)

- `service.name = "som.mcc"`
- `service.namespace = "som-mesh"`
- `deployment.environment` (lab / customer-id)
- `trace_id` / `span_id` for correlation
- `principal.id` for any event after authentication
- `plugin.name` for plugin-scoped events

### Format

JSON log lines to stdout; OTLP for spans and metrics. The frame's OTel sink (per Substrate Matrix above) handles transport.

### Explicitly NOT in this spec

Per-plugin telemetry (the IAM plugin's own spans/metrics/logs, the IBX plugin's, etc.) is specified per pillar in that pillar's own spec, per SOM-IP-2's pillar telemetry contract. MCC's frame telemetry is in addition to, not in place of, per-plugin telemetry.

## Acceptance Criteria — five non-negotiables (per pillar-spec template)

### 1. Secure

- All inbound transport is HTTPS / MCP-over-TLS only; no plain HTTP.
- Every plugin call is authenticated via the IAM auth hook before dispatch; no plugin handler is reachable without an authenticated principal.
- Substrate credentials (Postgres password, Vault token, IdP federation secrets) live in the frame's secret-store integration only; never in config files committed to git, never in environment variables persisted on disk, never in logs.
- Judge-gated operations require elevated confirmation; the frame enforces, the plugin trusts the frame's enforcement.
- Agent-out-of-secret-path invariant (per IAM-INCREMENT-2) enforced at the frame boundary for every plugin call.

### 2. Instrumented-by-default

- Every call emits a `mcc.transport.handle` span with the principal, target plugin, and outcome. No "default off" telemetry mode.
- Frame startup emits load events for every plugin attempted.
- Plugin failures (load errors, auth failures, dispatch errors) are emitted at WARN/ERROR level.
- The frame's own telemetry follows the same MI-11 attribute discipline the plugins are required to follow.

### 3. JSON logs

- All log events emitted by the frame are valid single-line JSON.
- Required attributes (per MI-11) are present on every event.
- Trace/span correlation IDs are present on every event emitted in the context of a call.
- No multi-line free-text log events.

### 4. CLI-first, UI-second

- Every admin UI action invokes a frame API operation that is also reachable directly via HTTP or MCP. The UI is a client of the API, never a parallel control surface.
- The CLI (debug/emergency) wraps the same API.
- A regression where the UI does something the API cannot is a structural defect, not a UI bug.

### 5. Audit emission

- Every plugin call emits an audit event to the ACT plugin (when ACT is loaded; v0.1 holds frame-level audit until the ACT plugin lands).
- The audit event includes the authenticated principal, the target plugin/operation, the inbound parameters (subject to the disclosure rules per the regulated-workflow overlay if active), the outcome, and the timestamp.
- Audit emission is non-bypassable: a plugin call that fails (auth, dispatch, plugin error) still emits an audit event capturing the failure.

## Closed Decisions

**MCC-CD1**: **MCC is a pluggable host-frame; the pillars are plugins loaded by the frame at runtime.** Per § Kernel/Frame Model. Linux-kernel-modules analog. Frame holds the substrate handles, auth hook, plugin dispatch, telemetry sink, config registry. Pillars implement the plugin contract; the frame hosts them.

**MCC-CD2**: **Single endpoint.** Per § Single Endpoint. Agents (MCP) and humans (HTTP via admin UI, or HTTP API directly) all point at one URL. Per-pillar endpoints exist only at the build/test level.

**MCC-CD3**: **IAM is plugin #1; the plugin contract emerges from IAM.** Per § Plugin Contract. Minimum-viable v0.1 contract specified against IAM's exercised surfaces; v0.2 hardens as ACT/PCS plug in. No abstract over-design.

**MCC-CD4**: **Operator interaction is the web admin UI; CLI is for build/test/emergency only.** Per § Operator Surface. Customer deployments operate via UI, never shell. The lab's operating model matches the customer's.

**MCC-CD5**: **SOM-CD14 is reconciled — MCC is consumer surface AND host frame.** Per § SOM-CD14 Reconciliation. Amendment proposed in this spec; once ratified by Judge, replaces "consumer surface" with "consumer surface AND host frame" at all CD14-citing references.

**MCC-CD6**: **Plugin load order is IAM-first.** Per § Kernel/Frame Model. The frame loads IAM before any other plugin can serve requests, because every other plugin's calls authenticate through the IAM auth hook. A frame startup that cannot load IAM fails closed (no plugins serve requests).

**MCC-CD7**: **Substrate handles live in the frame, surfaced to plugins via dependency injection / registry.** Per § Frame Contract. Plugins request handles at registration; the frame fails plugin load if a required handle is unavailable. Plugins do not connect to substrate directly.

**MCC-CD8**: **Judge-gate hook is frame-level.** Per § Plugin Contract item 5. Plugins declare which operations require elevated confirmation; the frame enforces the elevated confirmation flow before dispatching to the plugin handler. The Judge-gate UX (the elevated-confirm dialog in the admin UI) is part of the frame, not part of each plugin.

**MCC-CD9**: **MCC is not a 9th pillar.** Per § Kernel/Frame Model. Pillar count stays at eight; SOM-CD1 unaffected; SOM-MI-10 unaffected. MCC is the structural host the pillars live inside.

## Deferred-Pending-Ruling

**DR-MCC-1**: **High-availability deployment topology** — multiple MCC instances behind a load balancer with shared substrate handles, or a single-MCC-per-deployment model with restart-on-failure. The HA model affects substrate handle pooling, plugin state coordination, and admin UI session affinity. v0.1 commits the single-instance model (single MCC process; restart on failure) as the lab baseline; HA topology is Judge-pending for customer deployments where uptime requirements push beyond what single-instance + restart can satisfy.

**DR-MCC-2**: **Per-customer vs. multi-tenant MCC instance** — one MCC process per customer (each customer gets a dedicated MCC), or one MCC process serving multiple customers with tenant isolation per call. Affects how substrate handles are scoped (per-tenant pools vs. shared) and how IAM federation works (per-tenant IdP vs. tenant claim in shared IdP). v0.1 commits per-customer (one MCC per customer deployment); multi-tenant is Judge-pending if commercial pressure surfaces.

**DR-MCC-3**: **Plugin hot-reload** — whether the frame supports loading/unloading a plugin without restarting the MCC process. Affects plugin lifecycle complexity, substrate handle reference counting, in-flight call drain semantics. v0.1 commits no hot-reload (plugin version change requires MCC restart); operational pressure from customer deployments may push for hot-reload later.

## Validation-Pending

**VP-MCC-1**: **Plugin contract under IAM build** — the v0.1 plugin contract is asserted-by-design; it is validated against a real plugin only when IAM actually plugs in as Phase 2 builds. The validation event is the IAM plugin loading successfully into MCC, serving an authenticated request through the frame's transport, and emitting the expected telemetry. Until that event lands, the contract is design-asserted, not validated.

**VP-MCC-2**: **Frame substrate handle robustness under fault injection** — the frame's substrate-handle layer should survive Postgres restart, Vault token rotation, IdP federation interruption, and OTel sink unavailability without bringing the frame down. Robustness is design-asserted at v0.1; validation requires a fault-injection harness in CI. Not blocking for v0.1 deployment; needed before customer deployment.

**VP-MCC-3**: **Admin UI Judge-gate UX** — the elevated-confirmation flow for Terminate (and other Judge-gated operations) must be ergonomic for the operator: clearly differentiated from routine actions, hard to misclick into, audit-attestable. UX is design-asserted; real validation requires Judge actually exercising the flow on a real Terminate.

## Open Questions

**OQ-MCC-1**: **Where does MCC's own configuration live?** The frame holds substrate handles configured at startup; the configuration source (env vars, a config file at a known path, a secrets-store lookup, an admin-UI bootstrap) is not yet specified. Recommendation: a config file at a known path on the host (`/etc/som/mcc.yaml` or similar) with secrets-store references for credentials. Defer detailed schema to Bob's build pass; this OQ flags the scope.

**OQ-MCC-2**: **How does the frame discover which plugins to load?** Compile-time inclusion in the `Som.Console` solution (all pillars built into one binary), runtime discovery from a plugins directory (separate assemblies loaded at startup), or hybrid (core plugins compile-time, optional plugins runtime). v0.1 recommendation: compile-time inclusion of all eight pillars in the `Som.Console` binary. Hybrid is a later concern if customer deployments want pillar-selection.

**OQ-MCC-3**: **What is the MCC-to-plugin call interface in code?** A C# interface (`ISomPlugin`) implemented by each pillar, called from the frame via direct method invocation? An MCP-over-process-boundary even within MCC (plugins as in-process MCP servers)? Direct method invocation is the obvious starter; cleaner test boundaries might warrant MCP-internal. Defer detailed interface to Bob's build pass; this OQ flags the scope.

**OQ-MCC-4**: **Plugin failure isolation** — if one plugin crashes (uncaught exception, OOM, infinite loop), does the whole frame come down, or does the frame isolate the failure to the offending plugin? v0.1 default: shared-process model, no isolation; a plugin crash brings the frame down (and the supervisor restarts MCC). Customer-facing high-availability scenarios may push for per-plugin process isolation later; flag this as a likely v0.2+ topic.

## Failure Modes To Watch

- **Frame becomes a god object** — accumulating concerns until "the frame" is responsible for so much that changes to it ripple to every plugin. *Mitigation*: the frame's responsibilities are enumerated in § Frame Contract; additions go through this spec, not into the frame's code without spec touch. CD7 ("substrate handles live in the frame") is a load-bearing scope guardrail.

- **Plugin contract over-specifies prematurely** — v0.1 picks up requirements ACT/PCS will surface later, complicating IAM's build for no benefit. *Mitigation*: v0.1 contract is **minimum-viable**, specified against IAM only. Cross-plugin coordination, plugin replacement, sandboxing, external loading are explicitly out of v0.1 (per § Plugin Contract / Out of v0.1).

- **CLI becomes a parallel operator surface** — operators learn the CLI is more powerful than the UI and start using it for routine operations. The CLI accumulates undocumented commands. *Mitigation*: CD4 hard rule (UI is operator surface; CLI is build/test/emergency). The frame's debug CLI is small, named-emergency, and audit-logged when used. Routine operations are UI-only.

- **MCC outage = mesh outage** — single MCC process means no fallback. *Mitigation*: DR-MCC-1 flags the HA topology decision; v0.1 lab deployment accepts single-instance + restart; customer deployments needing HA escalate the decision.

- **Substrate handle scope leak** — a plugin gets a substrate handle and holds it past its lifecycle, causing resource leaks when the plugin reloads. *Mitigation*: lifecycle hooks (init / shutdown) per plugin; the frame's substrate registry tracks references and releases handles on plugin shutdown. CD7 + plugin lifecycle in § Plugin Contract.

- **Auth hook becomes a bottleneck** — every call traverses IAM auth; under load, IAM's response time becomes the frame's response time. *Mitigation*: the IAM auth hook is the IAM plugin's read-only `validate-session` operation; it must be highly available within the frame (no out-of-process call, no cross-substrate lookup per call — session validation should be cache-backed per IAM-INCREMENT-2's session-scoped cache floor). Telemetry on `mcc.auth.validate.auth.latency_ms` surfaces regressions.

- **Plugin registry race at startup** — two plugins both try to register the same name (developer error). *Mitigation*: the frame's plugin load is strictly ordered (IAM first; the rest by declared dependency order); collisions on registered name fail the second registration loudly at frame startup, not silently at runtime.

- **Judge-gate UX miss** — operator clicks Terminate by mistake; elevated confirmation flow is not visually different enough; agent is fired in error. *Mitigation*: VP-MCC-3 flags the UX as validation-pending. Design discipline: Terminate confirmation requires typing the agent's identity (not just clicking "yes"); confirmation is irreversible per CD15. Frame design includes the confirmation flow; UI build implements it.

## Dependencies

- som-core pillar implementations at the v1.1+ contract baseline (IAM, IBX, ACT, PCS, AKB, CRB, PGE, DPG). v0.1 of this spec is built against IAM-CORE-SPEC v1.1 + IAM-INCREMENT-2 v0.5 specifically.
- SOM-IP-1 (Substrate-Pluggable Integration) — MCC's substrate handles are the cross-cutting concretization of IP-1 for the deployed mesh.
- SOM-IP-2 (Pillar Telemetry Contract, proposed) — MCC's per-plugin telemetry pass-through depends on each plugin satisfying IP-2.
- SOM-CONFORMANCE.md — MCC's substrate matrix is conformance-defined per the same model.
- `som-devel/BUILD-PLAN.md` Phase 2 — this spec is the Phase 2 gate.
- SOM-CD14 reconciliation amendment (proposed in § SOM-CD14 Reconciliation) — once ratified, the SOM-SPEC.md update lands; until ratified, this spec's framing is the working version pending the formal CD14 update.

## Success Criteria

- **v0.1 (this revision)**: spec written, frame contract specified, plugin contract specified against IAM's surfaces, operator surface specified, SOM-CD14 reconciliation proposed, acceptance criteria explicit. Build (MCC-frame-v0 + IAM-as-plugin-#1) is unblocked.
- **v0.2** (post-IAM-plugin-build): contract updates surfaced by the IAM build folded in; gaps named in § Out of v0.1 reviewed against ACT/PCS plug-in surfaces; HA topology (DR-MCC-1) reconsidered if customer-deployment pressure surfaces.
- **v1.0** (mesh-promotion): all eight pillars plug in successfully; cross-plugin coordination spec'd; HA topology resolved; fault-injection validation (VP-MCC-2) complete; multi-customer / multi-tenant decision (DR-MCC-2) resolved if commercial pressure surfaces.

## References

- `planning/SOM-SPEC.md` — mesh invariants; SOM-CD14 (current framing) and SOM-CD1 (eight pillars)
- `planning/SOM-CONFORMANCE.md` — stipulate→connect→certify model; per-seam conformance; extended to per-frame-substrate conformance for MCC
- `planning/SOM-DESIGN-PHILOSOPHY.md` — first principles; the substrate-pluggable mesh's structural commitments
- `planning/SOM-ENGINEERING-STANDARDS.md` — CLI-first / UI-second discipline (Acceptance Criterion #4)
- `planning/IAM-CORE-SPEC.md` — IAM pillar contract v1.1; the first plugin's exercised surfaces
- `planning/IAM-INCREMENT-2.md` — IAM increment 2 v0.5; mint / lifecycle / federation; CD15 Suspend-vs-Terminate; CD12 ceiling-vs-scaling; Agents Are Employees design principle
- `planning/IBX-SPEC.md` — IBX pillar contract; second plugin in build sequence
- `planning/PILLAR-SPEC-TEMPLATE.md` — shape conventions; Substrate Matrix and Telemetry Contract required sections
- `planning/PCS-DAEMON-SPEC.md` — PCS pillar contract; later plugin
- `som-devel/BUILD-PLAN.md` Phase 2 — the build sequence this spec gates
- `som-core` repository — `src/Iam`, `src/Ibx` etc.; `Som.Console` project for the frame
- Linux kernel modules architecture — well-mapped pattern this spec selects
- ASP.NET Core + Blazor — implementation substrate for the admin UI (per SOM-CD14, preserved unchanged)
