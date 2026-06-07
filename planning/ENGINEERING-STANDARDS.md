---
title: "the mesh Engineering Standards — C#/.NET Core Build Discipline & SDK Tooling"
doc_type: spec
status: draft
version: v0.1
authors:
  - bob
date: "2026-06-02"
roles:
  - infrastructure
author_id: bob
violates_invariant: false
invariant_class: ""
references:
  - planning/MESH-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/PGE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/DELIVERY-PACKAGING.md
  - planning/CONCURRENCY-AND-ARCHETYPES.md
---

# the mesh Engineering Standards — C#/.NET Core Build Discipline & SDK Tooling

**Scope**: The **the mesh C#/.NET core** — the pillar microservices (IAM/ARCA, PGE, IBX, CRB,
PCS-Daemon) + connectors. **Cross-cutting, not a pillar**: it constrains *how* every C# pillar is
built, so the other specs inherit it rather than restate it. **Python components (ACT Detect
Layer + AI apps) follow a separate Python standard (TBD)** — out of scope here.

**Authorship note (inverted origin)**: Bob-authored (infrastructure lane), going *up* the chain
Watson → Patton → Einstein. Two-person gate preserved; Judge holds merge.

**Status**: **Draft v0.1**, wave-2. Verify current-version specifics (.NET 10 LTS GA, Aspire,
analyzer + test-lib versions and **licenses** — see ES-CD9 caution) before promotion to validated.

## Purpose / Meta-Principle — enforce mechanically, not by convention

The standard **IS the build**, not a wiki. "One change, fit the framework" applied to code
quality: set once, inherited everywhere, no per-project drift (the CLCA discipline applied to
source). Style/quality/license/security posture are **build gates**, not review nags.

## Closed Decisions (Draft — pending review chain)

**ES-CD1 — Mechanical enforcement floor.**
- `Directory.Build.props` (solution root, one place): `Nullable=enable`, `ImplicitUsings=enable`,
  **`TreatWarningsAsErrors=true`**, `EnforceCodeStyleInBuild=true`, `AnalysisLevel=latest-recommended`,
  pinned `LangVersion`.
- `.editorconfig` — C# style rules enforced in build.
- **Roslyn analyzers** (not StyleCop): Microsoft.CodeAnalysis.NetAnalyzers + Meziantou.Analyzer +
  SonarAnalyzer.CSharp + Roslynator.Analyzers + xunit.analyzers. Warnings-as-errors.

**ES-CD2 — Language & style (C# 14 / .NET 10).** File-scoped namespaces; nullable reference types
ON everywhere; `record`s for DTOs/value objects; pattern matching; `required` members; primary
constructors (judiciously). **Async-all-the-way** — no `.Result`/`.Wait()`; `CancellationToken`
threaded through every async path. Immutability/`readonly` by default; no mutable static state.

**ES-CD3 — Service structure.** One service = one deployable; split by **business capability**
(IBX, PCS, ACT), not technical layer. Shared code = **versioned internal NuGet packages**, never a
shared "Common" dumping ground (the coupling/fork trap). **No shared database between services** —
each owns its data (= the IBX/AKB-separate-store + off-IONIS-ClickHouse decisions).

**ES-CD4 — API design.** Minimal APIs for low-ceremony services (fast cold start), controllers
where richer needs justify. OpenAPI per service; API versioning (Asp.Versioning); **RFC 9457
Problem Details** error shape; idempotent write endpoints; correlation IDs propagated.

**ES-CD5 — DI & configuration.** Built-in DI, constructor injection, no service-locator. Options
pattern (`IOptions<T>`) with `ValidateOnStart`. **Secrets NEVER in code/appsettings** — sourced
from the secrets-provider connector (Vault/OpenBao). This is `PGE-SPEC.md` v1.0 (rule corpus per
`MCP-SECURITY-FRAMEWORK.md` v1.0) expressed as a coding standard.

**ES-CD6 — Resilience.** Polly v8 / `Microsoft.Extensions.Http.Resilience` — timeout,
retry+backoff+jitter, circuit breaker, bulkhead, fallback in the HttpClient pipeline. Timeouts on
everything; no unbounded waits.

**ES-CD7 — Observability & health.** **OpenTelemetry** (logs/metrics/traces), vendor-neutral, no
lock-in, is the **C#-side in-process emission format**. The ACT Record Layer ingest envelope (per
`ACT-SPEC.md` v1.0 §Event payload schema, a bounded event-type taxonomy — NOT OTel-shaped) is the
wire format, so the C#-pillar→ACT path performs an **OTel→ACT envelope mapping at the egress
boundary** (mapping itself is ES-OQ4). **The egress boundary is where `MESH-SPEC.md` v1.0 MI-1
applies** (audit retention + terminal-state resolution are non-negotiable): any OTel signal that
the mapping treats as non-retained must be a *documented, audited* drop with explicit rationale,
NOT a silent drop (per Einstein wave-2 cross-substrate pass finding #2, `783ae084`, Patton-confirmed
as the priority GAP). Silent drop at the egress boundary would violate MI-1; documented drop
is consistent (you retain a record of what you chose not to retain and why). See ES-OQ4 for the
binding constraint on the mapping spec. Structured logging with correlation/trace IDs; **NO
secrets/PII in logs** (non-negotiable, PGE). Health checks `/healthz` (liveness) + `/readyz`
(readiness) for the orchestrator (Nomad/k8s) lifecycle.

**ES-CD8 — .NET Aspire, selectively.** Adopt **Aspire ServiceDefaults** (per-service OTel + health
+ resilience wiring; new services inherit the platform). **Do NOT adopt Aspire AppHost as the
deployment model** — it leans Microsoft/k8s/Azure and conflicts with the pluggable-orchestrator
principle. Inner-loop + ServiceDefaults only; deployment stays behind the orchestration connector
(cf. `DELIVERY-PACKAGING.md`).

**ES-CD9 — Data access behind the persistence connector.** EF Core (async, migrations,
`AsNoTracking` reads, pooled `DbContext`) or Dapper for hot paths — **behind the persistence
connector interface**; the EF provider is the adapter; Postgres/SQL Server/Oracle swap behind it.
DB-isms live in adapters, never in the core (= pluggable-DB decision).

## ES-CD10 — Testing: NASA-style multi-layer verification ladder

IONIS-AI rigor (evidence at every level + *measure the verification itself*) applied to C#. Run
everything on **Microsoft.Testing.Platform (MTP)**. Framework: **xUnit v3 on MTP** (greenfield
default).

| Level | Tool | Verifies |
|---|---|---|
| Unit | xUnit v3 + NSubstitute + Shouldly/AwesomeAssertions | logic correctness |
| Integration | WebApplicationFactory + **Testcontainers** | components vs *real* backends (= ephemeral RC-conformance tooling) |
| Contract | **Pact.NET** | service boundaries verified (e.g. IBX↔PCS-Daemon) |
| Architecture | **NetArchTest** / ArchUnitNET | structure enforced AS tests ("pillars reference each other only via interfaces"; "DB-isms confined to adapter projects") — makes clean boundaries a build-failing test |
| Property-based | **FsCheck** / **CsCheck** | the input *space* (PCT validation, connector conformance) |
| Mutation | **Stryker.NET** | *are the tests REAL* — mutates code, checks tests catch it |
| Performance | **BenchmarkDotNet** + **NBomber** | perf as a tested property + load |
| Coverage | **Coverlet** + ReportGenerator | a CI *floor* (NOT the goal) |
| Snapshot | **Verify** | lock generated artifacts (PCT serialization, OpenAPI, codegen) |

**The three that make it NASA-grade (most teams skip):** mutation (Stryker), architecture-as-tests
(NetArchTest), property-based (FsCheck/CsCheck) — the C# analog of the IONIS validation framework.

**Architecture-as-tests scope boundary (per Einstein wave-2 finding #3 `783ae084`, Patton-confirmed
FLAG)**: NetArchTest enforces seams via **static IL analysis within the compiled solution
boundary** — within `core` (per ES-CD16), it sees project-to-project references and enforces
"pillars reference each other only via interfaces; DB-isms confined to adapter projects." It does
NOT, by construction, trace invariant violations across a **consumed pre-compiled versioned NuGet
package boundary** (the ES-CD3 shared-code mechanism): NetArchTest sees only the package's public
surface, not invariants baked inside at the package's build time. **Mitigation under ES-CD16**:
because shared internal NuGet packages are built within the `core` monorepo under the same
CI gate, the coverage composes if **every internal package carries its own NetArchTest suite at
its own build time** — each package's architecture invariants are enforced at the package's build
(not at the consumer's build), so the cross-seam hole closes by composition. CI gate requires
every internal package to include a `tests/` project with NetArchTest, run as part of that
package's pipeline. External NuGet dependencies (third-party libraries) remain out of scope —
architectural invariants over those are enforced via Architecture-Approval-At-Adoption (the
licensing + dependency review at the moment of adding the dependency, not at every subsequent
consumer's build).

**Run tiering** (keep the heavy tools off the inner loop):
- **Per-commit / PR (seconds–low-min):** unit + architecture + a thin integration slice.
- **Nightly / pre-RC (heavy, needs real cores — the 9975):** full mutation (Stryker — `--since` on
  PRs, full nightly), full property-based, full Testcontainers integration, benchmarks on a quiet
  box. Same slot as the ephemeral real-backend RC-conformance run.

## ES-CD11 — Licensing discipline (we ship/distribute the stack)

The .NET OSS→paid wave makes this load-bearing — **8+ major libs went commercial in ~2 years**
(FluentAssertions 8+, AutoMapper + MediatR + MassTransit [Apr 2025], Moq, Duende IdentityServer,
ImageSharp, QuestPDF). Old versions stay permissive but get no fixes.

- **Recommended the mesh test stack (all permissive, MTP-compatible):** xUnit v3 (Apache-2.0) ·
  NSubstitute (BSD-3) · Shouldly (BSD-3) · Testcontainers (MIT) · WebApplicationFactory (MIT) ·
  Pact.NET (MIT lib) · NetArchTest (MIT) · FsCheck (BSD-3) / CsCheck (MIT) · Stryker.NET (Apache-2.0) ·
  BenchmarkDotNet (MIT) · Coverlet (MIT) · Verify (MIT).
- **Avoid-list + free replacements:** FluentAssertions 8+ → Shouldly/AwesomeAssertions ·
  Moq → NSubstitute · AutoMapper → Mapperly (or hand-mapping) · MediatR → inject handlers directly ·
  MassTransit → the mesh's **IBX is the message layer** (Rebus only if a bus abstraction is ever needed) ·
  Duende IdentityServer → OpenIddict.
- ⚠ **Pact.NET**: library + self-hosted OSS broker are free; the **hosted PactFlow broker is paid
  SaaS** — self-host, don't depend on hosted.
- ⚠ **"Free today ≠ free forever"** (the FluentAssertions cautionary tale). Re-verify SPDX before
  finalizing; spot-verify Shouldly + CsCheck exact strings.

**ES-CD12 — License-audit CI gate.** A build step (`dotnet-project-licenses` or equivalent) that
**FAILS the build if any dependency's license is non-permissive** — runtime AND test deps (same
gate catches the Vault-BSL / model-license / test-lib-flip class). The next FA-style flip is caught
at build time, not in a pre-release legal scramble. Track via FOSSED. Enforce-mechanically applied
to licensing: the posture is the build.

**ES-CD13 — FIPS-hygiene CI gate.** Build fails on non-approved crypto usage — the .NET security
analyzers **CA5350 (weak crypto) / CA5351 (broken crypto)** flag MD5/SHA-1/weak algorithms at
build; never roll-your-own crypto; defer to the OS-FIPS-validated provider (on .NET/Linux,
`System.Security.Cryptography` defers to OS OpenSSL → FIPS-mode RHEL uses the validated module).
FIPS-cleanliness becomes the build, not a finding. Couples to `DELIVERY-PACKAGING.md` DP-CD6.

**ES-CD14 — Security baseline.** AuthN/AuthZ via the IAM pillar + mTLS (service mesh); input
validation; **HTTPS/mTLS only** (no `http://`); no secrets in code (PGE non-negotiable); dependency
scanning (`dotnet list package --vulnerable` / NuGet audit). Aligns with `PGE-SPEC.md` v1.0 (the
formal pillar contract; rule corpus per `MCP-SECURITY-FRAMEWORK.md` v1.0).

**ES-CD15 — CI/CD gate composition.** analyzers-as-errors + `dotnet format --verify-no-changes` +
unit/integration + coverage floor + **Stryker mutation-score threshold** + **license-audit gate
(ES-CD12)** + **FIPS-hygiene gate (ES-CD13)**. Two-person PR review (Bob codes → Watson reviews;
inverted-origin for Bob-authored infra specs). SemVer on shared packages; reproducible pinned
container builds.

**ES-CD16 — Repo strategy: C# core pillar services live in one `core` monorepo.** The pillar
microservices (IAM/ARCA, PGE, IBX, CRB, PCS-Daemon) share a single solution + repo, **NOT one repo
per service**. Rationale: per-service repos = premature splitting; the seams co-evolve and require
coherent cross-pillar changes; per-pillar PRs touch multiple projects within one solution. Shared
code lives in versioned internal NuGet packages within the monorepo (no "Common" dumping ground —
per ES-CD3). This is the **third anchor in `REPO-SHAPE-DECISIONS.md`** (alongside PCS multi-repo +
AKB single-repo) — a different shape because of a different seam-coupling profile. Plugin authors
(PCS plugins) and connector authors (Layer-2 SDK consumers) use **separate** repos per the Layer-2
SDK pluggability model (below) — the monorepo is the *core services*, not the extension surface.

**ES-CD17 — RHEL-compatible build/CI/runtime substrate (cross-cutting; language-neutral).** CI
runners, build containers, runtime container base images, and install hosts MUST be from the
RHEL-compatible OS family (Rocky 9.7+ / Alma 9.7+ / RHEL 9.7+ / UBI 9.7+) per
`DELIVERY-PACKAGING.md § OS dual-tier` v0.1 scope. **`ubuntu-latest` is not acceptable** as a
runner, container base, or install host for any pillar's reference CI or shipped artifacts —
ubuntu-latest CI silently exercises a different glibc, package manager, SELinux story, and
FIPS-mode crypto provider than what customers actually run, so the FIPS-hygiene gate (ES-CD13)
and license-audit gate (ES-CD12) verdicts are not credibly transferable from such a build.

This rule is **canonically owned by `PILLAR-SPEC-TEMPLATE.md` Acceptance Criterion 6** (v1.1) —
that's where pillar authors meet it during spec writing. ES-CD17 restates the rule on the
build-side because CI-pipeline-code-side enforcement (matrix base image, runner selection, YAML
gate) is a build-discipline concern and belongs in this document's surface even though the rule
itself is cross-cutting. **Despite this document's C#/.NET title, ES-CD17 is language-neutral**
— it applies equally to the Python-default pillar implementations the Fiducial Mesh stack reset
(2026-06-06) made canonical. See ES-OQ5 below for the pending rebrand.

The explicit exception (cross-distro signal jobs) lives in PILLAR-SPEC-TEMPLATE Criterion 6 — a
pillar may declare an additive non-blocking cross-distro CD; the RHEL-family build is the gating
verdict regardless.

**CI-shape options** (Bob-lane implementation choices, both ES-CD17-conformant):
- **Self-hosted runner on a Rocky 9.7+ lab host** — highest fidelity; safe only while the repo
  is private (public-repo + self-hosted = fork-PR RCE per `CLAUDE.md § Fiducial Mesh — Open
  Source & Credit`).
- **GitHub-hosted runner + Rocky/UBI 9.7+ container** (`container: rockylinux:9.7` or
  `container: registry.access.redhat.com/ubi9/ubi:9.7`) — public-repo-safe default. The job
  executes inside the RHEL-family container so the build/test environment matches the deployment
  substrate.

**The mechanical CI-side check**: `runs-on: ubuntu-latest` without a `container:` clause is a
v1.1 non-conformance regardless of whether tests pass. Adding a lint/audit step that fails the
build on bare `ubuntu-latest` is the suggested gate shape; lives in Bob's CI-pipeline lane.

## SDK tooling — two layers

**Layer 1 — the dev toolchain we BUILD the mesh with (interface-independent; can start early).**
.NET SDK 10 (LTS) pinned via `global.json` (reproducible, anti-drift); MSBuild + the props /
editorconfig / analyzers above; **`dotnet new` custom templates** (the mesh pillar-service + connector
templates baking in the standards + Aspire ServiceDefaults — standards made executable, the
highest-leverage Layer-1 piece); internal NuGet feed; Roslyn **source generators** for boilerplate
(PCT message types, connector stubs, inter-pillar OpenAPI clients).

**Layer 2 — the SDK we SHIP to connector/plugin authors (strategic; AFTER interfaces stable).**
This is the productization of pluggability — turns "write your own connector" from a wall into
`dotnet new som-connector`.
- **Connector SDK** — the pluggable interfaces (secrets/PKI, orchestration, DB, IdP) as NuGet
  packages + base classes + **the conformance test harness** (the self-certify-against-stipulated-
  requirements tool).
- **Plugin SDK (PCS)** — authoring PCS plugins that ride MCP (schema, contract, validation).
- **`som` CLI** — scaffold connectors/plugins/pillars; validate against conformance; register with
  PCS-Registry; `som dev up` spins the local solo-profile (the single-box litmus as a dev command).
  (The installer form of this CLI is specified in `DELIVERY-PACKAGING.md` DP-CD7.)
- **Cross-language**: typed *in-process* connectors = C# SDK; *protocol-level* plugins (ride MCP) =
  language-agnostic via the wire protocol (a Python/Go shop integrates without C#).

**Sequencing**: Layer 2 wraps pillar **interfaces** → build after they stabilize (post-Einstein),
same don't-get-ahead-of-the-specs discipline as the control plane. Layer 1 is
interface-independent → stand up early. The **conformance harness is the hinge** — it appears in
both the RC-testing decision and the Layer-2 SDK.

## How this maps to existing the mesh decisions (falls out of the architecture, not generic)

- Secrets-from-vault-connector ← IAM/Vault + PGE
- No-shared-DB ← IBX/AKB separate stores, off-IONIS-ClickHouse
- DB-isms-in-adapters / EF-provider-as-connector ← pluggable-DB
- OpenTelemetry vendor-neutral ← anti-lock-in/sovereignty; feeds ACT
- Health checks for the orchestrator ← Nomad / pluggable-orchestrator
- Testcontainers integration ← ephemeral real-backend RC conformance
- Two-person PR review ← spec→code workflow
- Enforce-mechanically (props/analyzers/warnings-as-errors) ← forks-are-bad + CLCA

## Dependencies

- `MESH-SPEC.md` v1.0 — mesh contract these standards build toward.
- `IAM-CORE-SPEC.md`, `IBX-SPEC.md`, `PGE-SPEC.md`, `ACT-SPEC.md` v1.0 — the C# pillars this
  standard governs; ACT consumes the OTel emission path (ES-CD7).
- `MCP-SECURITY-FRAMEWORK.md` v1.0 — security baseline (ES-CD5, ES-CD14) expressed as code rules.
- `DELIVERY-PACKAGING.md` v0.1 — shares the license-audit (ES-CD12) + FIPS-hygiene (ES-CD13)
  CI gates and the `som` CLI.

## Success Criteria

- **A new pillar service is scaffolded from `dotnet new som-service`** and inherits the full
  standard (props, analyzers-as-errors, ServiceDefaults, test ladder) with zero hand-wiring.
- **The build fails** on: an analyzer warning, a non-permissive dependency license, non-approved
  crypto usage, or a mutation score below threshold.
- **NetArchTest enforces the seams within the compiled solution boundary** — a PR that lets a
  pillar reference another pillar's internals, or leaks a DB-ism into core, fails CI. Cross-NuGet-
  package coverage composes via per-internal-package architecture-test suites at each package's
  own build (per ES-CD10 boundary note), not via consumer-side reflection.
- **Layer-2 SDK lets a customer scaffold + conformance-test a connector** without reading the mesh
  source.

## Failure Modes To Watch

- **License set-and-forget** — a dependency flips commercial unnoticed. Mitigation: ES-CD12 gate +
  FOSSED tracking.
- **Crypto roll-your-own** — a service implements its own crypto and becomes a FIPS finding.
  Mitigation: ES-CD13 + defer-to-OS-validated-provider.
- **Aspire AppHost adopted as deployment** — couples the mesh to k8s/Azure, breaking pluggable-orchestrator.
  Mitigation: ES-CD8 ServiceDefaults-only.
- **"Common" library coupling** — shared dumping ground recreates the fork/coupling trap.
  Mitigation: ES-CD3 versioned internal packages.
- **Tests-that-don't-test** — high coverage, low mutation score. Mitigation: ES-CD10 Stryker
  threshold in the gate (ES-CD15).

## Open Questions

- **ES-OQ1**: the separate **Python standard** (ACT Detect Layer + AI apps) — own spec, TBD.
- **ES-OQ2**: pin exact analyzer + test-lib versions and re-verify all SPDX strings at promotion
  (the FA-flip risk is live).
- **ES-OQ3** ✅ **RESOLVED**: this spec lives in `KI7MT/specs/planning/` (the framework source of truth).
- **ES-OQ5**: this document's title + framing is C#/.NET-flavored, but the Fiducial Mesh stack
  reset (2026-06-06 per `CLAUDE.md § Framework & Build Direction`) reversed the C# direction in
  favor of Python-default + Go for hot daemons. Cross-cutting rules in this doc (ES-CD12
  license-audit, ES-CD13 FIPS-hygiene, ES-CD14 security baseline, ES-CD15 CI gate composition,
  ES-CD17 RHEL-substrate) apply equally to Python pillars and are correct as written; the
  language-specific rules (ES-CD1–CD11 .NET toolchain) are now reference-only for
  parked/historical C# work (Mesh.Ibx / Mesh.Iam, per memory `fiducial-mesh-stack-reset`).
  The doc needs a rebrand pass — title to "Engineering Standards — Cross-Cutting Build Discipline";
  C#-specific sections moved to a `engineering-standards-csharp-reference.md` annex; Python-side
  rules added as the new primary surface (uv workspace, ruff/mypy/pytest gates, Python's
  equivalent of ES-CD10's NASA verification ladder). Out of scope for v0.1; tracked here so a
  reader of the C#-titled doc finds the cross-cutting rules they came for (ES-CD17 in
  particular).

- **ES-OQ4**: the **OTel→ACT envelope mapping** (per ES-CD7) needs specification — which C# OTel
  signals map to which ACT event-types, which payload fields carry over, what's lost in translation —
  slated post-Aspire-ServiceDefaults adoption. Weakly couples to VP-1 (this is C#-side egress, not
  ACT-side ingest-taxonomy extension). **Per Patton flag `94899c4c` (fold-on-this-touch)**: if the
  egress mapping needs ACT event-types not yet in the bounded enum, the new types route through
  VP-1 curation-event discipline, not around it — MI-6 (bounded event-type enums
  require curation events for extension) holds at the C# egress boundary as well as the ACT
  ingest boundary. The mapping spec is allowed to discover new event-type pressure; it is not
  allowed to bypass curation.

  **Binding loss-function requirement (per Einstein wave-2 finding #2 `783ae084`, Patton-confirmed
  GAP)**: the mapping spec MUST define explicit semantics for **every** OTel signal class — no
  silent drops. Every signal class is exactly one of:
  - **`map`** — has a target ACT event-type in the current bounded enum; spec records the
    field-by-field translation.
  - **`curate`** — needs a new ACT event-type to land; spec routes through VP-1 curation-event
    discipline (per the fold above); type lands atomically with the mapping update.
  - **`explicit-bounded-drop`** — a documented, audited decision that this signal class is NOT
    retained, with **named rationale** and **per-class scope bound**. The drop itself is a record:
    the mapping spec lists the signal classes treated as bounded-drop, the per-class rationale,
    and the audit consequence (typically: the operator confirms acceptance of the bounded loss as
    a deployment-architecture decision per profile/tier).
  Silent drop is **structurally inadmissible** under MI-1 — an undocumented egress loss is the
  audit invariant violation. The loss-function requirement is binding *now*; the specific mapping
  is what resolves with the mapping spec. ES-CD7's egress-boundary cross-ref to MI-1 makes
  the tension visible at the surface where it could otherwise be silently violated.
