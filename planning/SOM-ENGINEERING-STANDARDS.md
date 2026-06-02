---
title: "SOM Engineering Standards — C#/.NET Core Build Discipline & SDK Tooling"
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
  - planning/SOM-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/PGE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/SOM-DELIVERY-PACKAGING.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
---

# SOM Engineering Standards — C#/.NET Core Build Discipline & SDK Tooling

**Scope**: The **SOM C#/.NET core** — the pillar microservices (IAM/ARCA, PGE, IBX, CRB,
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
from the secrets-provider connector (Vault/OpenBao). This is `MCP-SECURITY-FRAMEWORK.md` / PGE
expressed as a coding standard.

**ES-CD6 — Resilience.** Polly v8 / `Microsoft.Extensions.Http.Resilience` — timeout,
retry+backoff+jitter, circuit breaker, bulkhead, fallback in the HttpClient pipeline. Timeouts on
everything; no unbounded waits.

**ES-CD7 — Observability & health.** **OpenTelemetry** (logs/metrics/traces), vendor-neutral, no
lock-in — and the emission path **ACT consumes** (cf. `ACT-SPEC.md`). Structured logging with
correlation/trace IDs; **NO secrets/PII in logs** (non-negotiable, PGE). Health checks `/healthz`
(liveness) + `/readyz` (readiness) for the orchestrator (Nomad/k8s) lifecycle.

**ES-CD8 — .NET Aspire, selectively.** Adopt **Aspire ServiceDefaults** (per-service OTel + health
+ resilience wiring; new services inherit the platform). **Do NOT adopt Aspire AppHost as the
deployment model** — it leans Microsoft/k8s/Azure and conflicts with the pluggable-orchestrator
principle. Inner-loop + ServiceDefaults only; deployment stays behind the orchestration connector
(cf. `SOM-DELIVERY-PACKAGING.md`).

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

**Run tiering** (keep the heavy tools off the inner loop):
- **Per-commit / PR (seconds–low-min):** unit + architecture + a thin integration slice.
- **Nightly / pre-RC (heavy, needs real cores — the 9975):** full mutation (Stryker — `--since` on
  PRs, full nightly), full property-based, full Testcontainers integration, benchmarks on a quiet
  box. Same slot as the ephemeral real-backend RC-conformance run.

## ES-CD11 — Licensing discipline (we ship/distribute the stack)

The .NET OSS→paid wave makes this load-bearing — **8+ major libs went commercial in ~2 years**
(FluentAssertions 8+, AutoMapper + MediatR + MassTransit [Apr 2025], Moq, Duende IdentityServer,
ImageSharp, QuestPDF). Old versions stay permissive but get no fixes.

- **Recommended SOM test stack (all permissive, MTP-compatible):** xUnit v3 (Apache-2.0) ·
  NSubstitute (BSD-3) · Shouldly (BSD-3) · Testcontainers (MIT) · WebApplicationFactory (MIT) ·
  Pact.NET (MIT lib) · NetArchTest (MIT) · FsCheck (BSD-3) / CsCheck (MIT) · Stryker.NET (Apache-2.0) ·
  BenchmarkDotNet (MIT) · Coverlet (MIT) · Verify (MIT).
- **Avoid-list + free replacements:** FluentAssertions 8+ → Shouldly/AwesomeAssertions ·
  Moq → NSubstitute · AutoMapper → Mapperly (or hand-mapping) · MediatR → inject handlers directly ·
  MassTransit → SOM's **IBX is the message layer** (Rebus only if a bus abstraction is ever needed) ·
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
FIPS-cleanliness becomes the build, not a finding. Couples to `SOM-DELIVERY-PACKAGING.md` DP-CD6.

**ES-CD14 — Security baseline.** AuthN/AuthZ via the IAM pillar + mTLS (service mesh); input
validation; **HTTPS/mTLS only** (no `http://`); no secrets in code (PGE non-negotiable); dependency
scanning (`dotnet list package --vulnerable` / NuGet audit). Aligns with `MCP-SECURITY-FRAMEWORK.md`.

**ES-CD15 — CI/CD gate composition.** analyzers-as-errors + `dotnet format --verify-no-changes` +
unit/integration + coverage floor + **Stryker mutation-score threshold** + **license-audit gate
(ES-CD12)** + **FIPS-hygiene gate (ES-CD13)**. Two-person PR review (Bob codes → Watson reviews;
inverted-origin for Bob-authored infra specs). SemVer on shared packages; reproducible pinned
container builds.

## SDK tooling — two layers

**Layer 1 — the dev toolchain we BUILD SOM with (interface-independent; can start early).**
.NET SDK 10 (LTS) pinned via `global.json` (reproducible, anti-drift); MSBuild + the props /
editorconfig / analyzers above; **`dotnet new` custom templates** (SOM pillar-service + connector
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
  (The installer form of this CLI is specified in `SOM-DELIVERY-PACKAGING.md` DP-CD7.)
- **Cross-language**: typed *in-process* connectors = C# SDK; *protocol-level* plugins (ride MCP) =
  language-agnostic via the wire protocol (a Python/Go shop integrates without C#).

**Sequencing**: Layer 2 wraps pillar **interfaces** → build after they stabilize (post-Einstein),
same don't-get-ahead-of-the-specs discipline as the control plane. Layer 1 is
interface-independent → stand up early. The **conformance harness is the hinge** — it appears in
both the RC-testing decision and the Layer-2 SDK.

## How this maps to existing SOM decisions (falls out of the architecture, not generic)

- Secrets-from-vault-connector ← IAM/Vault + PGE
- No-shared-DB ← IBX/AKB separate stores, off-IONIS-ClickHouse
- DB-isms-in-adapters / EF-provider-as-connector ← pluggable-DB
- OpenTelemetry vendor-neutral ← anti-lock-in/sovereignty; feeds ACT
- Health checks for the orchestrator ← Nomad / pluggable-orchestrator
- Testcontainers integration ← ephemeral real-backend RC conformance
- Two-person PR review ← spec→code workflow
- Enforce-mechanically (props/analyzers/warnings-as-errors) ← forks-are-bad + CLCA

## Dependencies

- `SOM-SPEC.md` v1.0 — mesh contract these standards build toward.
- `IAM-CORE-SPEC.md`, `IBX-SPEC.md`, `PGE-SPEC.md`, `ACT-SPEC.md` v1.0 — the C# pillars this
  standard governs; ACT consumes the OTel emission path (ES-CD7).
- `MCP-SECURITY-FRAMEWORK.md` v1.0 — security baseline (ES-CD5, ES-CD14) expressed as code rules.
- `SOM-DELIVERY-PACKAGING.md` v0.1 — shares the license-audit (ES-CD12) + FIPS-hygiene (ES-CD13)
  CI gates and the `som` CLI.

## Success Criteria

- **A new pillar service is scaffolded from `dotnet new som-service`** and inherits the full
  standard (props, analyzers-as-errors, ServiceDefaults, test ladder) with zero hand-wiring.
- **The build fails** on: an analyzer warning, a non-permissive dependency license, non-approved
  crypto usage, or a mutation score below threshold.
- **NetArchTest enforces the seams** — a PR that lets a pillar reference another pillar's
  internals, or leaks a DB-ism into core, fails CI.
- **Layer-2 SDK lets a customer scaffold + conformance-test a connector** without reading SOM
  source.

## Failure Modes To Watch

- **License set-and-forget** — a dependency flips commercial unnoticed. Mitigation: ES-CD12 gate +
  FOSSED tracking.
- **Crypto roll-your-own** — a service implements its own crypto and becomes a FIPS finding.
  Mitigation: ES-CD13 + defer-to-OS-validated-provider.
- **Aspire AppHost adopted as deployment** — couples SOM to k8s/Azure, breaking pluggable-orchestrator.
  Mitigation: ES-CD8 ServiceDefaults-only.
- **"Common" library coupling** — shared dumping ground recreates the fork/coupling trap.
  Mitigation: ES-CD3 versioned internal packages.
- **Tests-that-don't-test** — high coverage, low mutation score. Mitigation: ES-CD10 Stryker
  threshold in the gate (ES-CD15).

## Open Questions

- **ES-OQ1**: the separate **Python standard** (ACT Detect Layer + AI apps) — own spec, TBD.
- **ES-OQ2**: pin exact analyzer + test-lib versions and re-verify all SPDX strings at promotion
  (the FA-flip risk is live).
- **ES-OQ3**: where this spec sits after the `som-spec` migration (likely moves with the SOM corpus).
