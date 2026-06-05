---
title: "Pillar-Spec Template — Required Sections + Acceptance Criteria"
doc_type: spec
status: validated
version: v1.0
authors:
  - watson
date: "2026-06-04"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - planning/SOM-DELIVERY-PACKAGING.md
---

# Pillar-Spec Template — Required Sections + Acceptance Criteria

**Scope**: Defines the canonical section structure and acceptance criteria every per-pillar SOM spec must satisfy. Per-pillar specs (IBX, IAM-CORE, ACT, PCS-DAEMON, DPG, CRB, PGE) are the **manifests** that instantiate the mesh-level **contracts** in `SOM-SPEC.md` (SOM-MI-8 Substrate Substitutability, SOM-MI-11 Telemetry Contract, § Tested Substrate Profiles, SOM-CD15 conformance enforcement). This template is the contract every pillar spec builds to.

**Status**: **Validated v1.0** — resolves issues #6 (Substrate Matrix + Telemetry Contract sections + three non-negotiables) and #24 (CLI-first/UI-second + audit emission extension). The template is the load-bearing artifact that the 7 v1.1 pillar refreshes (#10–#16) build to.

## Why this exists

Per-pillar specs need a **manifest** layer that names this-specific-pillar's substrate dependencies and telemetry surface. Mesh-level invariants (SOM-MI-8, SOM-MI-11, § Tested Substrate Profiles) define the contract; per-pillar manifests declare *how this pillar instantiates that contract*. Without a template, the 7 pillars drift into different section shapes and a downstream implementer (Bob, Newton, a customer integrator) cannot read a pillar spec end-to-end and know which spans to instrument, which metrics to emit, which substrate seams to honor.

The template is the discipline that keeps the 7 manifests structurally identical so a reader who knows one pillar spec can navigate any other.

## Required frontmatter

Per `.claude/skills/akb-doc` — every pillar spec is AKB-conformant. Required fields:

```yaml
---
title: "<Pillar> Spec — <one-line scope>"
doc_type: spec
status: draft | validated | deprecated | superseded
version: v<major>.<minor>
authors: [<agent ids>]
date: "YYYY-MM-DD"
roles: [design-intent, infrastructure]
author_id: <primary author>
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - <other related spec paths>
---
```

`doc_type: spec` is fixed for pillar specs. `roles` is `[design-intent, infrastructure]` for every pillar spec (cross-cutting → both lanes).

## Required sections (in order)

Every pillar spec must include these H2 sections, in this order:

1. **Purpose / Problem Restatement** — what contract this pillar holds, what load-bearing question it answers
2. **Approach / Architecture** — current state vs. specification target; the seam boundary surfaces
3. **Substrate Matrix** *(this template, § Substrate Matrix below)*
4. **Telemetry Contract** *(this template, § Telemetry Contract below)*
5. **Closed Decisions** — versioned CD-list (CD1, CD2, …) of commitments
6. **Open Questions** — versioned OQ-list of unresolved questions
7. **Failure Modes** — what could go wrong, mitigations
8. **Dependencies** — what other pillars / external substrates this pillar relies on
9. **Acceptance Criteria** *(this template, § Acceptance Criteria below — five non-negotiables)*
10. **References** — citation list

Pillars may add additional H2 sections for pillar-specific concerns (e.g., IBX's § Concurrency-Safe Worker-Pool Dispatch). The 10 sections above are the floor, not the ceiling.

## Substrate Matrix

**Purpose**: Names this pillar's substrate dependencies as a per-pillar instance of SOM-MI-8 substitutability, scoped to the profiles in `SOM-SPEC.md § Tested Substrate Profiles`. The pillar's substitutability claim covers exactly the rows in the matrix below — no further (per SOM-CD15).

**Section template**:

```markdown
## Substrate Matrix

Per SOM-MI-8 + § Tested Substrate Profiles, this pillar's substrate substitutability is defined as **passing the multi-profile conformance run** against the matrix below. Wording is **role + version floor** (never vendor-named) so the matrix names a *contract*, not a *product*.

| Seam | Contract | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|----------|-------------------------------------|----------------------------------------|
| <seam role> | <minimal contract, e.g. "ANSI SQL + ENUM + JSONB"> | <product family + version> | <product family + version>, … |
| <seam role> | <contract> | <ref> | <alt>, <alt> |

**Conformance**: CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set. A seam change that fails any tested profile does not merge (SOM-CD15).

**Out-of-set substrates**: A deployment using a substrate not listed in the matrix is **not covered by this pillar's substitutability claim** — it requires a new profile definition (CONF-CD11) + conformance suite extension + the multi-profile run passing before merging.
```

**Style rules**:

- **Role + version floor, never vendor-named.** Write *"OLTP RDBMS with ANSI SQL + ENUM"* not *"PostgreSQL 17"*. The sovereign reference column names the product; the contract column names the role.
- **List only seams this pillar depends on**, not the full mesh-wide matrix. The mesh-wide matrix lives in `SOM-SPEC.md § Tested Substrate Profiles`; this pillar's section is the subset that applies.
- **Telemetry sink is a seam if the pillar emits telemetry.** Per SOM-MI-11, every pillar emits OTLP → so every pillar's matrix includes a Telemetry-sink row (OTLP-on-the-wire contract).

## Telemetry Contract

**Purpose**: Names the telemetry surface this pillar exposes per SOM-MI-11. Mesh-level MI-11 defines the **mechanism** (OTLP traces + metrics + JSON-structured logs with the named attribute keys, exported via `OTEL_EXPORTER_OTLP_ENDPOINT`); this section is the per-pillar **manifest** — the specific spans, metrics, and log records this pillar emits.

**Section template**:

```markdown
## Telemetry Contract

Per SOM-MI-11, this pillar emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr. The sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; SOM does not name the backend.

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| <operation description> | `som.<pillar>.<operation>` | <attribute>, <attribute> |
| <operation description> | `som.<pillar>.<operation>` | <attribute>, <attribute> |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `som.<pillar>.<metric>` | counter / gauge / histogram | <unit> | <one-line meaning> |
| `som.<pillar>.<metric>` | counter / gauge / histogram | <unit> | <one-line meaning> |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| <event description> | info / warn / error | <field>: <type>, <field>: <type> |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name`, `service.version`, `deployment.environment` — resource attributes
- `identity`, `session`, `trace_id`, `span_id` — event attributes
- `cost-center` — when ACT chargeback applies (per CD on ACT integration)

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT` (no specific backend named)
- **Logs**: JSON to stderr (stdout is reserved for MCP protocol channel)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields

### Explicitly NOT in this spec

- Collector deployment topology
- Backend choice (App Insights, Datadog, Grafana/Tempo, Azure Monitor, etc.)
- Dashboards, alerts, retention policies
- Sampling strategy

These are **deployment-side concerns** governed by the Telemetry-sink seam (per SOM-MI-8 substrate-pluggability extending to MI-11 per SOM-MI-11 final paragraph).
```

**Style rules**:

- **Span/metric names are `som.<pillar-id>.<operation>` or `som.<pillar-id>.<metric>`.** Consistent prefix lets a customer's dashboard filter by pillar trivially.
- **Required attributes inherited from MI-11 are not repeated per-span.** List them once in the § Required attributes block; per-span tables only list *additional* pillar-specific attributes.
- **Distinction from SOM-MI-1 (audit) is explicit when applicable.** If the pillar emits both audit events (MI-1) and observability telemetry (MI-11), name which signals belong to which class. MI-1 is the durable accountability record; MI-11 is the operational + cost-attribution surface.

## Acceptance Criteria — five non-negotiables

A pillar spec is not validated until all five hold. Equal weight to security; a pillar lacking any is **not finished**.

### 1. Secure

The pillar conforms to the security framework: credential handling (OS keyring only, never config files), no injection surface (no `subprocess`, `shell=True`, `eval`, `exec` on untrusted input), HTTPS-only for external connections, parameterized queries for any SQL, input validation on user strings, rate limiting on external APIs. See `planning/MCP-SECURITY-FRAMEWORK.md`.

### 2. Instrumented-by-default

The pillar emits OTLP traces + OTLP metrics per its § Telemetry Contract. A pillar that isn't instrumented isn't finished — load-bearing because ACT (chargeback / metering) can only meter what pillars emit. *Wording shift from earlier drafts*: telemetry is **mandatory**, not "should be considered."

### 3. JSON logs

The pillar emits structured JSON logs to stderr with the required keys (`timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session`) per SOM-MI-11. Trace correlation via `trace_id` + `span_id` is mandatory.

### 4. CLI-first, UI-second

Every management function is runnable on a CLI or API surface **before** any UI exists. The UI (MCC pane) is a *thin client* of the CLI/API surface, never a privileged path that bypasses it.

**Build order**: function → CLI/API → validate headless → wire the MCC pane.

**Payoffs** (Bob's framing, 2026-06-04 architecture session):

- Agents / scripts / CI can do everything humans can — same command surface
- Headless tests against the CLI/API are the canonical test surface
- Production ops never depend on a UI being available
- Forces a clean API boundary; function design happens at the CLI level
- MCC stays thin (per SOM-CD14): MCC panes render existing CLI/API surfaces, not new ones

**MCC is a client of these commands, never privileged.**

### 5. Audit emission

The pillar emits accountability events for every operation that affects state.

**Path A (emission-as-build-standard, default until #22 resolves to Path B)**:

- Pillars emit audit events directly per SOM-MI-1 stream
- Required attributes per event: `identity`, `session`, `operation`, `outcome`, `timestamp` + pillar-specific fields
- Same OTel pipeline as the Telemetry Contract; audit events are a separate signal class or audit-flagged log records
- ACT consumes downstream from the MI-1 stream

**Path B (service-write, if #22 resolves that way)**:

- Pillars call ACT during the critical path of each state-affecting operation
- "Audit emission" becomes "ACT integration" as a build standard
- Pillar must handle ACT-service-unavailable cases per spec (block, fail, or buffer — pillar's CD names which)

Either path: **accountability events are a build standard**, not optional instrumentation. Author of the per-pillar spec checks the current state of `KI7MT/som-spec#22` at write time and uses whichever path is current.

## How to use this template

1. Copy the section structure (not the literal section bodies) into the new pillar spec.
2. Fill the Substrate Matrix table with this pillar's seams + supported substrates (role + version floor, never vendor-named).
3. Fill the Telemetry Contract tables with this pillar's spans, metrics, and log events (`som.<pillar-id>.<operation>` naming).
4. Confirm all five Acceptance Criteria are addressed in the spec body (each gets at minimum a CD or an explicit conformance statement).
5. Confirm AKB-conformant frontmatter (`doc_type: spec`, `roles: [design-intent, infrastructure]`, etc.).
6. Open a PR; Patton reviews GH-native; Judge merges.

## Dependencies

- Mesh-level invariants in `SOM-SPEC.md`: SOM-MI-8 (substrate substitutability), SOM-MI-11 (telemetry contract), SOM-MI-12 (Spec-Harness-Registry primitive), SOM-CD15 (conformance-enforced substrate-neutrality), § Tested Substrate Profiles (the named substrate set)
- AKB frontmatter conventions: `.claude/skills/akb-doc`
- Security framework: `planning/MCP-SECURITY-FRAMEWORK.md`

## Acceptance Criteria (for the template itself)

- [x] Substrate Matrix section template named with role + version floor wording (#6)
- [x] Telemetry Contract section template named with OTLP + JSON-stderr + required attribute keys (#6)
- [x] Three non-negotiables (Secure, Instrumented-by-default, JSON logs) given equal weight to security (#6)
- [x] CLI-first/UI-second non-negotiable added with build-order guidance and MCC-is-client framing (#24)
- [x] Audit emission non-negotiable added with both Path A and Path B branches naming #22 as the gate (#24)
- [x] AKB frontmatter convention captured for downstream pillar authors

## References

- `planning/SOM-SPEC.md` — mesh-level invariants the per-pillar manifests instantiate
- `planning/SOM-DELIVERY-PACKAGING.md` — DP-CD5 supply-chain integrity (informs the telemetry-pipeline build)
- `planning/MCP-SECURITY-FRAMEWORK.md` — security framework referenced by Acceptance Criterion 1
- `.claude/skills/akb-doc` — AKB frontmatter contract
- Issues `KI7MT/som-spec#6`, `KI7MT/som-spec#24` — origin issues for this template's sections + acceptance criteria
