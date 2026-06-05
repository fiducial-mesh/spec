---
title: "PGE Spec — Policy Guardrail Engine Pillar Capstone"
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
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - planning/PILLAR-SPEC-TEMPLATE.md
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-TECHNICAL-OVERVIEW.md
  - planning/MCP-SECURITY-FRAMEWORK.md
  - planning/IBX-SPEC.md
  - planning/IAM-CORE-SPEC.md
  - planning/ACT-SPEC.md
  - planning/PCS-DAEMON-SPEC.md
  - planning/DPG-SPEC.md
  - planning/CRB-SPEC.md
---

# PGE Spec — Policy Guardrail Engine Pillar Capstone

**Scope**: Formalizes the contract for **PGE** (Policy Guardrail Engine), the Control-Plane pillar that provides deterministic compliance enforcement across the SOM fleet — replacing vendor-mediated safety filters with explicit, auditable, code-resident rules. Covers the **rule corpus** (today's enforcement set sourced from `MCP-SECURITY-FRAMEWORK.md`), the **double-guardrail architecture** (agent-action enforcement at IBX submission + sandbox-execution enforcement inside DPG, per `SOM-PROBLEM-STATEMENT.md` v0.6 §6 note on PGE), the **enforcement surfaces** (CI release gates, `PreToolUse` hook, per-server `test_security.py` suites), the **rule lifecycle** (how a rule enters, how it is amended, how it is retired), and the **coupling boundaries** with IBX (action-policy enforcement at the chokepoint), DPG (sandbox-execution policy enforcement at the boundary), PCS-Daemon (rule application at promotion gate), CRB (rule application at dispatch chokepoint), IAM (authorization rules reference identity claims), ACT (rule decision audit emission), and the Workforce (subagent-guard hook).

**Status**: **Validated v1.1** — fourth pillar instantiation of the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md`, merged 2026-06-05 at `9c67f57`). v1.1 adds the per-pillar manifest layer (§ Substrate Matrix + § Telemetry Contract) that instantiates the mesh-level contracts in `SOM-SPEC.md` (SOM-MI-8, SOM-MI-11, § Tested Substrate Profiles). CD13 + CD14 record the v1.1 commitments. v1.0 contract surface is unchanged. **v1.1 maintains the pure-capstone discipline (CD1)**: no new rules added, no existing rules altered, no enforcement points added or removed. The new sections **formalize** PGE's pre-existing substrate substitutability (CD8) and ACT audit emission (CD9) into the per-pillar manifest format with capability-framing per Patton's PR #31 lesson — they do not change PGE's behavior.

**Prior status (v1.0, retained for history)**: Item 6 of the spec-campaign queue. Per Patton's `ea67f2ac` forward note on PGE: *"it's the one pillar already operational-by-de-facto-spec (`MCP-SECURITY-FRAMEWORK.md` + per-server test suites + PreToolUse hook). So item 6 is a different shape than the others — less 'spec a build target,' more 'promote the de facto spec to a formal capstone and resolve the forward-references that DPG/PCS-Daemon/CRB all point at it.' When you bring it, the key question I'll be testing: does the capstone change any behavior, or purely formalize what's already enforced? If it changes behavior, that's a re-validation; if it formalizes, it's a capstone. Name which up front."*

**Named up front — PGE v1.0 is a PURE CAPSTONE (formalization, NOT behavior change).** This spec promotes the de facto enforcement surface — `MCP-SECURITY-FRAMEWORK.md` v1.0 (2026-03-04) + `.claude/hooks/subagent-guard.sh` + per-server `test_security.py` suites + `publish.yml` CI release gate — into the pillar contract. **No new rule is added at v1.0. No existing rule is altered at v1.0. No enforcement point is added or removed at v1.0.** The pillar's behavior is unchanged from production-validated state.

**v1.1 additions (this version — also pure capstone, no behavior change)**:
1. **§ Substrate Matrix** (new section) — names 4 PGE substrate seams (Rule corpus storage, Policy evaluation engine, Enforcement surface, Telemetry sink) per SOM-MI-8 + § Tested Substrate Profiles. **Formalizes the existing § Substrate Substitutability (Per Exit Test) into the per-seam template format.** CD13 commits the matrix as the substitutability boundary per SOM-CD15. Capability-framed throughout: contract column names what the substrate must guarantee, not the sovereign-ref's specific primitive.
2. **§ Telemetry Contract** (new section) — PGE-specific spans (`som.pge.gate1.evaluate`, `som.pge.gate2.evaluate`, `som.pge.promotion_gate.evaluate`, `som.pge.rule.lifecycle`, etc.), metrics (`som.pge.gate1.decisions_total`, `som.pge.gate2.decisions_total`, `som.pge.rule_evaluation_latency_ms`, etc.), log events per SOM-MI-11. **Formalizes the pre-existing CD9 `pge.*` event commitment into per-pillar MI-11 manifest format.** CD14 commits this; the cross-spec curation event for `pge.*` already tracked in VP-PGE-1 still applies.
3. **§ Acceptance Criteria** (renamed from § Success Criteria) — prepends the 5 non-negotiables from the template. Existing v1.0 PGE-specific success criteria preserved below.
4. **CD13 + CD14** record the substrate matrix + telemetry contract commitments respectively.

The v1.0 contract surface (pure-capstone discipline, two-stratum rule corpus, double-guardrail architecture, distributed enforcement surfaces, single-source-of-policy-truth, ACT audit integration, all coupling boundaries) is **unchanged**. v1.1 is purely additive — it adds the manifest layer formalizing what CD8 + CD9 already commit. **No new rules added; no existing rules altered; no enforcement points added or removed.**

What this spec does add:
1. **Names the pillar contract**: what PGE structurally commits as a pillar (rule corpus + double-guardrail architecture + lifecycle + coupling boundaries) so that future versions of PGE — or substrate substitutions to OPA/Cedar/per-pillar policy engines per `SOM-PROBLEM-STATEMENT.md` v0.6 §6 — have a contract to satisfy rather than mining `MCP-SECURITY-FRAMEWORK.md` for implicit semantics.
2. **Resolves the forward-references** carried by DPG (CD8 + §Coupling Boundary: PGE ↔ DPG), PCS-Daemon (PGE chokepoint application), CRB (§Coupling Boundary: PGE ↔ CRB), and IAM (PGE consumes verified identity claims) — all of which currently point at `MCP-SECURITY-FRAMEWORK.md` as the de facto PGE spec. After this capstone merges, those forward-references update to point at PGE-SPEC.md as the formal contract.
3. **Articulates the load-bearing architectural properties** (deterministic enforcement, single source of policy truth, double-guardrail symmetry, no-vendor-mediation, auditability via ACT) that the de facto framework has been satisfying in production but never explicitly named at the pillar level.
4. **Tracks the cross-spec sweep** Patton flagged in his `ea67f2ac` close-out — once this capstone lands, DPG / PCS-Daemon / CRB references to "MCP-SECURITY-FRAMEWORK as PGE source" should be updated in their next touch. The sweep is **post-merge cosmetic**, not a blocking precondition.

**What this spec does NOT do**:
- Does NOT introduce a "PGE daemon" build target. PGE today is **fleet-resident rules + per-surface enforcement points**, not a centralized policy service. v1.0 commits this architecture. Future centralization (an OPA-style service) is allowed by the Exit Test (§ Substrate Substitutability) but is NOT v1.0 commitment.
- Does NOT touch IAM identity issuance (per Patton's `97e870f6` ACT-seam discipline applied here too — PGE consumes identity at the chokepoint via `principal-id` field, does NOT mint or alter identity).
- Does NOT add policy rules for content-domain workloads beyond the MCP server / agent-action perimeter the de facto framework already covers. New domain coverage (e.g., model-training policy, dataset-egress policy) is post-v1.0.

## Purpose / Problem Restatement

Per `SOM-PROBLEM-STATEMENT.md` v0.6 — the Anthropic-safety-filter → policy-enforcement driver: VMA-style stacks rely on vendor-mediated safety filters at the LLM input/output layer; SOM's autonomy posture requires the safety surface to be **owned**, **deterministic**, and **auditable** by the operator. Vendor filters are not a substitute for code-resident policy because:

- They are opaque (operator cannot inspect the rule set; cannot trace which rule fired)
- They are non-deterministic (same input may pass on one day and fail on another)
- They live at the wrong layer (LLM I/O, not execution surface)
- They do not absorb execution-side policy (a vendor filter cannot prevent a subprocess call inside a sandbox)
- They are subject to vendor policy drift outside the operator's control

PGE replaces this with **deterministic compliance enforcement** applied at **defined chokepoints** in the SOM execution surface. The rule corpus is human-readable, version-controlled, code-resident, and auditable; rule decisions are deterministic (same input → same decision) and trace-emit through ACT.

**Per `SOM-PROBLEM-STATEMENT.md` v0.6 §6 PGE-double-guardrail note**: PGE acts at **two distinct enforcement points**:

1. **Agent-action policy** — *before* messages reach IBX. Catches non-compliant intent at submission time, before downstream work is wasted. The PCT's authority claim, scope assertion, principal identity, and action declaration are evaluated against the rule corpus at the IBX chokepoint. Non-compliant submissions fail closed; nothing reaches downstream pillars.
2. **Sandbox-execution policy** — *inside* DPG (and at any sandbox/ephemeral-boundary substrate). Catches non-compliant code at runtime, before it touches production state. Examples (today): no `subprocess` or `shell=True`; no `eval`/`exec` on user input; no plaintext credentials in code; HTTPS-only egress; parameterized SQL only.

The two-point enforcement is **structurally important** because intent-side and execution-side compliance gaps are different failure classes — either gate alone misses one class. VMA models typically enforce at one point (vendor safety filter on LLM I/O) and miss the execution-side surface entirely. SOM's PGE makes both gates explicit, owned, and deterministic.

**Current implementation, named explicitly**: the rule corpus lives in `MCP-SECURITY-FRAMEWORK.md` v1.0 (10 non-negotiable guarantees + 13 MCP-tooling implementation patterns + audit checklists). Enforcement surfaces today are:

- **Per-server `test_security.py`** suites in every qso-graph MCP repo (compile-time / CI enforcement; PR cannot merge if security tests fail)
- **`.claude/hooks/subagent-guard.sh`** PreToolUse hook (runtime enforcement on Watson/Bob's Claude Code sessions; blocks force push, PyPI publish bypass, credential-file writes regardless of caller)
- **`publish.yml`** GitHub Action (release gate; PyPI publish only triggers on tag push, never manual)
- **Project-level CLAUDE.md security clauses** (process-level rule application at session start)

This is what v1.0 promotes to formal pillar contract.

## Architecture — Rule Corpus + Double-Guardrail + Enforcement Surfaces

PGE-as-pillar has three architectural components that v1.0 commits, plus the substrate primitive the v1.0 reference deployment uses:

| Component | Role |
|---|---|
| **Rule Corpus** | The fleet-canonical set of compliance rules. v1.0 = `MCP-SECURITY-FRAMEWORK.md` v1.0's 10 non-negotiable guarantees + 13 implementation patterns. Single source of policy truth — DPG, PCS-Daemon, CRB consume from here. |
| **Double-Guardrail Enforcement Architecture** | Rules are applied at **two distinct points** — agent-action policy at the IBX submission chokepoint + sandbox-execution policy inside DPG. Both gates are required; either gate alone is incomplete. |
| **Enforcement Surfaces** | The concrete code/process artifacts that apply the rule corpus at each gate. v1.0: CI release gate (`publish.yml` + `test_security.py`), runtime hook (`subagent-guard.sh`), process-level CLAUDE.md rules. |
| **Substrate primitive (v1.0 reference)** | Per-language test framework (`pytest` + `test_security.py`) + bash PreToolUse hook + GitHub Actions release gate. Substitutable per § Substrate Substitutability. |

### Rule-Corpus vs Enforcement-Surface separation

v1.0 commits these as architecturally distinct:

- **Rule Corpus is semantic** — every rule expresses a compliance commitment in a form that is human-readable, code-resident, and version-controlled. The corpus is meaningful in itself before any specific gate evaluates it.
- **Enforcement Surface is pragmatic** — for a given deployment, each surface applies the relevant subset of the corpus at the appropriate gate. The IBX submission chokepoint applies agent-action policy rules; the DPG sandbox boundary applies sandbox-execution policy rules; the CI release gate applies build-time-verifiable rules.
- **The same rule may apply at multiple surfaces** — e.g., "no plaintext credentials in code" is checked by `test_security.py` at CI, blocked by `subagent-guard.sh` at runtime if an agent attempts a credential-file write, and enforced by the DPG sandbox via filesystem and environment restrictions. The rule is one; the surfaces are many.

The split lets the rule corpus evolve independently of any specific enforcement substrate; lets new surfaces (e.g., an OPA-style central policy service) absorb existing rules without re-derivation; and lets the deployment substrate swap (per Exit Test) without affecting either the rule corpus or the architectural gate-points.

## Rule Corpus (v1.0)

v1.0 commits the rule corpus by reference to `MCP-SECURITY-FRAMEWORK.md` v1.0 (2026-03-04). The corpus has two strata:

### Stratum 1 — Non-Negotiable Guarantees (10)

Per `MCP-SECURITY-FRAMEWORK.md` § Non-Negotiable Security Guarantees:

| # | Rule | Today's verification |
|---|------|---------------------|
| 1 | Credentials never in logs | Static analysis + code review |
| 2 | Credentials never in tool results | Trace all return paths |
| 3 | Credentials never in error messages | Audit all raise/exception statements |
| 4 | Credentials never in config files | OS keyring only |
| 5 | No command injection surface | No subprocess, no shell=True, no os.system |
| 6 | No SQL injection surface | Parameterized queries or API-only |
| 7 | HTTPS only for external calls | Grep audit of all URLs |
| 8 | Rate limiting implemented | Prevents user account bans |
| 9 | Input validation on all user strings | Regex validation before use |
| 10 | Fail safely | Errors reveal no sensitive information |

These are **non-negotiable**. Amending or retiring any of these is a CLCA-cycle decision with Judge sign-off, not a routine rule change.

### Stratum 2 — Implementation Patterns (13)

Per `MCP-SECURITY-FRAMEWORK.md` § Credential Handling Architecture, § Input Validation Requirements, § Code Safety Patterns, et al. These articulate *how* to satisfy the Stratum 1 guarantees in practice (e.g., the persona-based credential lookup pattern, the regex validation patterns for callsign/grid/date/band, the FixedString null-byte stripping pattern, the rate-limit decorator pattern, etc.).

Implementation patterns may evolve (e.g., the regex set extends when new input domains arrive) without amending Stratum 1. Stratum 2 changes are routine; Stratum 1 changes are CLCA-gated.

### Rule extension

Adding a new rule requires explicit curation event (mirrors the ACT event-type and CRB classification-taxonomy disciplines). Three classes of extension are reasonable:

- **Stratum 1 (non-negotiable)**: triggered by new threat class with no Stratum 2 mitigation possible. CLCA cycle + Judge sign-off.
- **Stratum 2 (implementation pattern)**: triggered by new input domain or new code-safety surface. Watson/Bob/Patton review + Judge merge.
- **Domain coverage extension**: triggered by new workload class entering policy scope (e.g., model-training policy, dataset-egress policy). Spec-level addition with cross-pillar review; not a routine pattern change.

v1.0 explicitly does NOT extend the rule corpus. The v1.0 spec is **pure capstone** — promotes the existing corpus, does not amend it.

## Double-Guardrail Enforcement Architecture

The double-guardrail is PGE's structurally load-bearing architectural property. v1.0 commits both gates and the separation between them.

### Gate 1 — Agent-Action Policy at IBX Submission Chokepoint

**Where**: at the moment a PCT is submitted to IBX, before the message is routed to any downstream pillar.

**What is evaluated**: the PCT's authority claim, scope assertion, principal identity (consumed from IAM), action declaration, and any tool-invocation specifics declared in the `context` field.

**What is rejected**: submissions that violate any non-negotiable guarantee (e.g., a PCT requesting a tool invocation that would write credentials to a config file) or any implementation pattern applicable at submission time (e.g., a PCT requesting a SQL operation with string-interpolated user input rather than parameterized query).

**Failure mode**: rejected submissions emit `pge.action_policy_rejected` ACT events (proposed namespace per § Coupling Boundary: ACT ↔ PGE). The PCT is NOT routed to IBX downstream consumers; the sender receives a rejection notification with the failing rule cited.

**Today's surfaces at this gate**:
- `.claude/hooks/subagent-guard.sh` PreToolUse hook (runtime; blocks force push, PyPI publish bypass, credential-file writes — agent-action policy violations applied at the moment of attempt)
- Pre-PR security review checklist in `MCP-SECURITY-FRAMEWORK.md` § Release Gate (process-level; agent-action policy applied at PR time)
- The MCP server's own input validation per `MCP-SECURITY-FRAMEWORK.md` § Input Validation Requirements (per-tool runtime; agent-action policy applied at tool-invocation time)

### Gate 2 — Sandbox-Execution Policy at DPG Boundary

**Where**: inside the DPG ephemeral boundary (and at any equivalent sandbox substrate), at code-execution time before any production-state touch.

**What is evaluated**: the workload's code surface (filesystem operations, network egress, subprocess invocations, environment variable access, child process spawning) and runtime behavior (rate of external API calls, scope of database queries, etc.).

**What is rejected**: workloads that attempt operations forbidden by the rule corpus (e.g., a subprocess call from within a workload claimed to have no command-injection surface; an `http://` URL from a workload claimed to use HTTPS-only egress; a string-interpolated SQL statement from a workload claimed to use parameterized queries).

**Failure mode**: rejected workloads emit `pge.sandbox_policy_rejected` ACT events. The workload is terminated; nothing escapes the sandbox boundary.

**Today's surfaces at this gate**:
- `test_security.py` per-server suites (compile-time / CI-resident; sandbox-execution policy verified before workload reaches production)
- Subagent worktree isolation per `CLAUDE.md` § Subagent Policy (OS-level Git isolation as a sandbox surface for subagent-drafted code)
- `subagent-guard.sh` PreToolUse hook (runtime; blocks specific forbidden operations regardless of caller — applies both at intent-side and execution-side)

### Why both gates are required (and either alone fails)

- **Gate 1 alone** misses execution-side compliance gaps. A PCT may declare a compliant action at submission time but invoke non-compliant code at execution time (e.g., a workload that *says* it uses HTTPS-only egress but at runtime fetches over `http://`). Gate 1 cannot catch this; Gate 2 must.
- **Gate 2 alone** wastes downstream work and creates audit-trail gaps. A non-compliant PCT submitted today may pass Gate 1 → route to DPG → fail at Gate 2 → consume DPG resources for nothing. Worse, the submission itself escaped audit at the chokepoint; the audit trail starts at the failure rather than the intent.
- **Both gates together** catch both classes of failure and produce complete audit coverage. Submissions either fail at Gate 1 (cheap, deterministic, before downstream cost) or pass Gate 1 and execute under Gate 2 supervision (with full audit of intent AND execution).

The double-guardrail is the response to VMA stacks' single-point enforcement and is what v1.0 names as PGE's load-bearing architectural property.

## Enforcement Surfaces

v1.0 commits the enforcement surfaces today's deployment uses. These are the **concrete code/process artifacts** that apply the rule corpus at each gate.

| Surface | Gate | Trigger | Scope |
|---|---|---|---|
| `test_security.py` per-server suite | Gate 1 + Gate 2 | CI on every PR | Per-MCP-server compliance verification |
| `.claude/hooks/subagent-guard.sh` PreToolUse hook | Gate 1 | Runtime, every tool invocation by Watson/Bob | Cross-cutting forbidden-operation block |
| `publish.yml` GitHub Action | Gate 1 | Tag push | PyPI publish gate; never manual |
| CLAUDE.md § Security clauses | Gate 1 + Gate 2 | Session start | Process-level rule application |
| Subagent worktree isolation | Gate 2 | Subagent spawn with write access | OS-level Git isolation per Anthropic Agent SDK |
| MCP server input validation | Gate 1 | Per-tool invocation | Per-tool runtime validation |
| Pre-release security audit checklist | Gate 1 | Pre-PyPI-publish | Watson security audit PASS in `messages.inbox` |

These surfaces are the v1.0 reference enforcement substrate. § Substrate Substitutability documents what's allowed to swap.

## Rule Lifecycle

v1.0 commits the lifecycle for how rules enter, are amended, and are retired.

### Entry

- **Stratum 1 (non-negotiable)**: triggered by new threat class. Process: identify defect → CLCA cycle → propose rule → Watson + Bob + Patton + Einstein review → Judge sign-off → commit to `MCP-SECURITY-FRAMEWORK.md` + emit `pge.rule_added` ACT event with `tier=1`.
- **Stratum 2 (implementation pattern)**: triggered by new input domain or code-safety surface. Process: Watson/Bob draft → Patton review → Judge merge → emit `pge.rule_added` ACT event with `tier=2`.

### Amendment

Same process as entry, with explicit deprecation of the prior rule. The old rule's `pge.rule_retired` ACT event must precede the new rule's `pge.rule_added` event (audit invariant: rule transitions are ordered and unambiguous; no period of two contradictory rules in flight).

### Retirement

- **Stratum 1**: only retire if the threat class itself has been structurally eliminated (e.g., the substrate that introduced the threat is no longer used). CLCA + Judge sign-off.
- **Stratum 2**: retire when the rule's underlying pattern is superseded by a Stratum 1 guarantee or by a different Stratum 2 pattern. Routine review process.

### Migration

When a Stratum 2 rule promotes to Stratum 1 (because the pattern proves to be a non-negotiable guarantee class, not just a pattern), the migration emits both `pge.rule_retired` (Stratum 2) and `pge.rule_added` (Stratum 1) events. The migration is atomic at the audit level.

## Substrate Substitutability (Per Exit Test)

The PGE substrate is the **enforcement runtime** — test frameworks, runtime hooks, CI release gates today; centralized policy services tomorrow. Per `SOM-PROBLEM-STATEMENT.md` v0.6 §6 Exit Test mapping: PGE's de facto substrate today is "MCP-SECURITY-FRAMEWORK + per-server tests"; substitutable to "OPA / Cedar / per-pillar policy engine" without contract revision.

### Substrate options

| Substrate class | What it provides | Acceptable at v1.0? |
|---|---|---|
| **Per-server `test_security.py` + `subagent-guard.sh` + CI release gate** (today) | Distributed, per-surface enforcement; rules co-located with code; CI verification | v1.0 reference; pure capstone of existing production substrate |
| **OPA (Open Policy Agent)** | Centralized policy service with Rego rule language, runtime policy evaluation API | Acceptable v1.x — would consume same rule-corpus contract, surfaces become OPA query points |
| **Cedar** | AWS-developed policy language and runtime; declarative rules + evaluation engine | Acceptable v1.x — same contract consumption |
| **Per-pillar policy engine** | Pillar-specific embedded engines (e.g., IBX has its own action-policy module, DPG has its own sandbox-policy module) | Acceptable v1.x — distributed-with-shared-corpus; same contract |
| **Hybrid** | Some surfaces remain code-resident (subagent-guard); some migrate to a central engine (e.g., OPA for new domain coverage) | Acceptable v1.x — most likely real-world evolution path |

**The contract is what holds across substrate change.** Per `SOM-PROBLEM-STATEMENT.md` v0.6 §4 Exit Test discipline: a pillar that doesn't survive substrate substitution is a lock-in defect. The PGE contract — rule corpus + double-guardrail architecture + lifecycle — must be expressible in every substrate above. v1.0 commits this property.

### Why per-server-tests + hook is the right reference at v1.0

- **Operationally validated**: production-validated by per-server `test_security.py` running in CI on every PR + `subagent-guard.sh` enforcing at runtime + zero security incidents at the substrate over the spec-campaign timeline.
- **Distributed enforcement matches distributed surfaces**: SOM's fleet has many MCP servers (13 qso-graph + 1 internal + future additions); per-server tests scale with the surface; centralizing would require lifting rules out of the surfaces that own them.
- **Substitutable forward**: when a deployment justifies central policy service (e.g., a customer with many heterogeneous workloads where per-surface tests don't compose), OPA / Cedar / equivalent absorbs the rule corpus without breaking the contract.

### Discipline against premature substrate complexity

v1.0 commits: **PGE does NOT prematurely adopt a centralized policy engine.** The lab's current substrate (per-server tests + hook + CI gate) is the right shape for the current scale. Centralization is a v1.x decision pending real workloads that justify it. Same discipline as IBX v0→v1 and CRB v1.0 substrate-substitutability framing.

## Coupling Boundary: IBX ↔ PGE (Agent-Action Policy at Submission Chokepoint)

PGE's Gate 1 lives at the IBX submission chokepoint. v1.0 commits:

- **Every PCT submission to IBX is evaluated against the agent-action policy subset** of the rule corpus before the message routes to its recipient.
- **The evaluation is deterministic and trace-emitting**: same PCT inputs → same decision; the decision (accept/reject) and the matching rule (when reject) are emitted to ACT.
- **Rejected submissions fail closed**: no `action`/`urgent`-priority PCT bypasses the gate by mistake. `info`-priority PCTs are evaluated under a lighter rule subset (per `IBX-SPEC.md` v1.0 CD5 validity treatment for info messages), but the gate still applies — info messages cannot, e.g., contain credentials in their body.
- **PGE consumes verified identity** from IAM (the PCT's `principal-id` field is already verified by the time PGE evaluates the action policy). PGE does NOT mint or verify identity; that is IAM's domain. Authorization rules (e.g., "only `compute resource broker` job code may dispatch GPU-bound workloads") reference identity claims but do not produce them.

## Coupling Boundary: DPG ↔ PGE (Sandbox-Execution Policy at the Boundary)

PGE's Gate 2 lives inside the DPG ephemeral boundary. v1.0 commits:

- **Every workload execution inside DPG is governed by the sandbox-execution policy subset** of the rule corpus.
- **DPG enforces, PGE specifies**: DPG provides the ephemeral isolation primitive; PGE's rules tell DPG what is permitted within the isolation. This is the clean seam between the two pillars — DPG owns isolation mechanics, PGE owns policy semantics.
- **Per `DPG-SPEC.md` v1.0 CD8** (single source of policy truth): DPG does NOT carry its own policy corpus. The rules DPG enforces are sourced from PGE — specifically from this spec's Rule Corpus § Stratum 2 implementation patterns applicable to sandbox execution.
- **Failure mode**: a workload that violates a sandbox-execution rule is terminated by DPG; PGE emits the `pge.sandbox_policy_rejected` ACT event with the failing rule identifier; the workload's result PCT carries a failure outcome.

### Resolves DPG forward-reference

Per Patton's `ea67f2ac` close-out flag on PR #68 (CRB), the DPG / PCS-Daemon / CRB references to "MCP-SECURITY-FRAMEWORK as PGE source" now have a formal target. `DPG-SPEC.md` v1.0 CD8 and §Coupling Boundary: DPG ↔ PGE references can update from `MCP-SECURITY-FRAMEWORK.md` to `PGE-SPEC.md` on next touch. **Post-merge sweep — not a v1.0 blocking precondition.**

## Coupling Boundary: PCS-Daemon ↔ PGE (Promotion-Gate Application)

Per `PCS-DAEMON-SPEC.md` v1.0: PCS-Daemon applies PGE rules at the plugin promotion gate — a plugin cannot promote from staging to production Registry without passing PGE policy compliance (the `policy_compliance_pass` requirement). v1.0 commits:

- **PCS-Daemon consumes PGE rules at promotion time**: when a plugin reaches the promotion gate, PCS-Daemon evaluates the plugin's code against the rule corpus (specifically Stratum 2 implementation patterns applicable to MCP-server code). Failure → no promotion.
- **The evaluation surface today** is `test_security.py` per-server suite execution; the plugin must have a passing `test_security.py` for promotion to proceed.
- **Promotion-gate rule application is auditable**: ACT receives `pge.promotion_gate_evaluated` events on every promotion-gate evaluation; payload includes the plugin identifier, the rule subset applied, and the decision.

### Resolves PCS-Daemon forward-reference

`PCS-DAEMON-SPEC.md` v1.0 references to `MCP-SECURITY-FRAMEWORK.md` as PGE source update to `PGE-SPEC.md` on next touch. **Post-merge sweep.**

## Coupling Boundary: CRB ↔ PGE (Dispatch-Chokepoint Application)

Per `CRB-SPEC.md` v1.0: PGE evaluates dispatch requests at CRB's chokepoint before routing decisions are made. v1.0 commits:

- **CRB consumes PGE rules at dispatch time**: when a dispatch request arrives, PGE evaluates whether the requester is authorized to dispatch workloads of the requested class; whether the target host's accelerator allowance is compatible with the workload tier; whether the workload is within the requester's policy scope.
- **The evaluation surface today** is the agent-action policy rule subset applied at IBX (CRB's dispatch requests arrive as IBX PCTs, so Gate 1 evaluation already applies).
- **CRB does NOT carry its own policy corpus** (per `CRB-SPEC.md` v1.0 CD6). The rules CRB consumes are sourced from PGE.

### Resolves CRB forward-reference

`CRB-SPEC.md` v1.0 §Coupling Boundary: PGE ↔ CRB references to PGE-as-MCP-SECURITY-FRAMEWORK update to `PGE-SPEC.md` on next touch. **Post-merge sweep.**

## Coupling Boundary: IAM ↔ PGE (Authorization Consumes Identity)

Per `IAM-CORE-SPEC.md` v1.0 + `SOM-PROBLEM-STATEMENT.md` v0.6 §0 (Control Plane composition note): identity verification and authorization are distinct concerns; IAM provides verified identity; PGE consumes that identity in authorization decisions.

- **PGE does NOT verify identity** (IAM's domain).
- **PGE does NOT issue identity** (ARCA's domain, above the issuance/runtime line per IAM v1.0).
- **PGE consumes identity claims** (the PCT's `principal-id` field) in authorization rules — e.g., "only `pcs control plane` job code may write to the Registry"; "only `security auditor` role may approve a PyPI release"; "no `subagent` role may push to remote repositories."
- **PGE's authorization rules are part of the rule corpus** but specifically the subset that references identity claims. These rules evolve under the same lifecycle as other rules but are typically Stratum 1 (non-negotiable for the authorization surface).

## Coupling Boundary: ACT ↔ PGE (Rule Decision Audit Emission)

v1.0 PGE proposes the `pge.*` event-type namespace (parallel to `pcs.*`, `dpg.*`, `crb.*`). Proposed events:

- **`pge.action_policy_evaluated`** — emitted when Gate 1 evaluates a PCT submission; payload includes the PCT identifier, the rule subset applied, and the decision (accept/reject)
- **`pge.action_policy_rejected`** — emitted specifically on Gate 1 rejection; payload includes the failing rule identifier and the rejection reason
- **`pge.sandbox_policy_evaluated`** — emitted when Gate 2 evaluates a workload's runtime behavior; payload includes the workload identifier, the rule subset applied, and the decision
- **`pge.sandbox_policy_rejected`** — emitted specifically on Gate 2 rejection
- **`pge.promotion_gate_evaluated`** — emitted on PCS-Daemon promotion-gate evaluation
- **`pge.rule_added`** — emitted on rule corpus entry (Stratum 1 or 2)
- **`pge.rule_amended`** — emitted on rule amendment
- **`pge.rule_retired`** — emitted on rule retirement

Per ACT v1.0 CD4, the `pge.*` namespace requires an explicit curation event. v1.0 PGE spec tracks the dependency in **VP-PGE-1** below. **Per Patton's standing direction** (`4759a355` + `294ec70a` + `ea67f2ac`): the cross-spec ACT v1.x curation event closing VP-PCS-1 + VP-DPG-1 + VP-CRB-1 should now ALSO fold VP-PGE-1 — **four pillars in one shared motion**. Pre-curation, PGE may emit `act.detection_signal` events with payload-encoded `signal_type=pge_*` per the bounded-fallback pattern.

## Coupling Boundary: Workforce ↔ PGE (Subagent-Guard Hook)

Workforce agents (Watson, Bob, subagents spawned by them) are governed by PGE at the runtime tool-invocation layer.

- **PreToolUse hook (`subagent-guard.sh`)** is the runtime surface — every tool invocation by Watson, Bob, or any subagent passes through the hook; forbidden operations (force push, PyPI publish bypass, credential-file writes) are blocked regardless of caller. This is per-CLAUDE.md § Subagent Policy "Hard" enforcement.
- **Subagent policy soft-enforcement** (CLAUDE.md text) is the process surface — Watson and Bob read CLAUDE.md at session start and apply the subagent restrictions in their delegation decisions.
- **The two surfaces compose**: soft enforcement guides typical behavior; hard enforcement catches the residual case where soft enforcement is bypassed or unreliable.

## Substrate Matrix

Per SOM-MI-8 + `SOM-SPEC.md` § Tested Substrate Profiles + CD13 + the pre-existing § Substrate Substitutability (Per Exit Test) + CD8 (substrate substitutability via Exit Test). **This matrix formalizes the existing v1.0 substitutability claim into the per-seam template format** — making the claim mechanically checkable per SOM-CD15 rather than asserted-in-prose. Pure-capstone discipline holds: the matrix names the seams PGE already commits to under CD8; it does not change PGE's behavior.

**Capability-framed per Patton's PR #31 lesson**: the contract column names what the substrate must guarantee (deterministic policy evaluation, distributed enforcement composition, rule corpus version-controlled-and-citable), not the sovereign-ref's specific primitive (`test_security.py` per-server, OPA Rego, etc.). PGE's substitutability claim covers exactly the rows listed; out-of-set substrates require a new profile definition (per CONF-CD11), conformance suite extension, and the multi-profile run passing per SOM-CD15.

PGE exposes four substrate seams. The first three are the core policy-engine seams (where rules live, what evaluates them, where decisions get applied); the fourth is telemetry per SOM-MI-11.

| Seam | Contract (role + version floor, capability-framed) | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|----------------------------------------------------|-------------------------------------|----------------------------------------|
| **Rule corpus storage** (where the rule set lives + how it is versioned + how it is cited) | Version-controlled rule corpus with two-stratum tagging (CD2 — Stratum 1 non-negotiable / Stratum 2 implementation pattern); per-rule identifier stable across rule lifecycle (CD10); citable from audit events (`pge.*_evaluated` events carry the rule identifier per CD9 + CD11) | **Git-versioned Markdown** (`MCP-SECURITY-FRAMEWORK.md` v1.0 + per-server `test_security.py` files) — today's de facto reference per CD1 pure-capstone | OPA Rego policy bundle (per-package versioning), Cedar policy file (per-policy versioning), database-backed corpus with explicit version table, hybrid (Markdown for Stratum 1 + Rego for Stratum 2). **Per CD8 + CD5, admissible v1.x; not v1.0 commitments.** |
| **Policy evaluation engine** (what evaluates rules at runtime/gate time) | Deterministic policy evaluation: same inputs → same decision; evaluation emits trace events per CD11 (gate decision + matching rule on reject); supports distributed-per-surface OR centralized-service composition per CD3 double-guardrail | **Distributed per-surface enforcement** — per-server `test_security.py` runtime (Python 3.10+ pytest) + `subagent-guard.sh` (Bash 5+) + CI release gate (GitHub Actions) — today's reference per CD1 + CD5 | OPA (Open Policy Agent) 0.60+ with Rego eval, Cedar runtime with declarative policy engine, per-pillar embedded policy engines (IBX action-policy module + DPG sandbox-policy module + ...), hybrid centralized + per-surface. **Per CD8 + DR-PGE-1, admissible v1.x with substrate-migration trigger deferred.** |
| **Enforcement surface** (where evaluation decisions get applied) | Surface that intercepts the action and applies the gate decision (allow/reject); per CD3 + § Enforcement Surfaces — double-guardrail composition (Gate 1 at IBX submission, Gate 2 at DPG boundary) + supplemental surfaces (CI release gate, `PreToolUse` hook, subagent guard) | **Distributed multi-surface** — `subagent-guard.sh` PreToolUse hook + IBX submission chokepoint + DPG ephemeral boundary + CI release gate (per `publish.yml`) + per-server test suite — today's reference per CD1 | OPA-sidecar middleware at IBX/DPG, Cedar runtime sidecar, custom enforcement library per-pillar, hybrid. **Per CD8, admissible v1.x; CD3 double-guardrail composition is invariant across substrate change.** |
| **Telemetry sink** (per SOM-MI-11; OTLP-on-the-wire contract) | OpenTelemetry / OTLP for traces + metrics; JSON-structured logs to stderr; sink configurable via `OTEL_EXPORTER_OTLP_ENDPOINT`. **Distinct from ACT audit emission** (CD9, `pge.*` events) — the telemetry sink seam is PGE's own MI-11 observability, separate from the `pge.*` audit-event class that flows to ACT | Grafana/Prometheus/Tempo stack | Azure Monitor / App Insights, Datadog, OCI Monitoring, any OTLP-compatible sink — per SOM-MI-11 final paragraph |

**Conformance**: when PGE's substrate evolves (per DR-PGE-1 substrate migration trigger), CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set. A seam change that fails any tested profile does not merge (SOM-CD15). For today's distributed-per-surface state, the sovereign-ref column is operationally exercised in production; the alternatives are the substitutability boundary CD8 commits future migrations may use.

**Out-of-set substrates**: A deployment using a substrate not listed (e.g., a vendor-mediated content-filter as the enforcement surface) is **not covered by PGE's substitutability claim** — it requires a new profile definition (CONF-CD11), conformance suite extension, and the multi-profile run passing per SOM-CD15. Same boundary discipline as `SOM-DELIVERY-PACKAGING.md` DP-CD1.

**Architectural invariants that bind across substrate change** (per CD3 + CD8): the **double-guardrail composition** (Gate 1 + Gate 2) and the **single-source-of-policy-truth** (CD12) are invariants regardless of which substrate engine evaluates rules. A centralized OPA service still applies both gates; a per-pillar engine still consumes from one corpus. The matrix admits substrate variation; the architectural commitments do not.

**Cross-reference**: the existing § Substrate Substitutability (Per Exit Test) section above contains the prose substitutability argument (why per-server-tests + hook is the right v1.0 reference, why centralization is admissible-future-not-premature). § Substrate Matrix is the per-seam manifest version of the same claim, with capability-framing applied so the conformance run under SOM-CD15 is mechanically checkable.

## Telemetry Contract

Per SOM-MI-11, PGE's own runtime (evaluation engine + enforcement surfaces) emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr. The sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; SOM does not name the backend. Naming convention follows the template: `som.pge.<operation>` for spans, `som.pge.<metric>` for metrics.

**PGE's double role — critical distinction**: PGE plays two roles in the mesh audit/observability architecture:
- **PGE as MI-1 audit emitter via `pge.*` events**: per CD9 + CD11 + § Coupling Boundary: ACT ↔ PGE — PGE emits `pge.action_policy_evaluated`, `pge.sandbox_policy_evaluated`, `pge.promotion_gate_evaluated`, `pge.*_rejected`, `pge.rule_added`, `pge.rule_amended`, `pge.rule_retired` events to ACT as durable audit records. **VP-PGE-1** tracks the cross-spec curation event that extends ACT's CD4 enum.
- **PGE as MI-11 observability emitter via `som.pge.*` signals** (this section): per-pillar observability for PGE's own runtime — gate evaluation latency, decision rates, rule-engine throughput, enforcement-surface health. **Distinct from the `pge.*` audit class**: the audit events go to ACT for durable accountability; the `som.pge.*` MI-11 signals go to the customer-selected OTLP sink for operational observability.

The two streams do not collapse: a PGE deployment without `som.pge.*` MI-11 emission still satisfies CD9 (ACT audit emission); a PGE deployment without `pge.*` ACT emission violates CD9 regardless of MI-11 emission.

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| Gate 1 (agent-action policy) evaluation at IBX submission | `som.pge.gate1.evaluate` | `pct_message_id`, `principal_id`, `priority`, `decision` (`allow` / `reject`), `matching_rule_id` (when reject), `rule_corpus_version` |
| Gate 2 (sandbox-execution policy) evaluation at DPG boundary | `som.pge.gate2.evaluate` | `workload_id`, `principal_id`, `decision` (`allow` / `reject`), `matching_rule_id` (when reject), `rule_corpus_version` |
| Promotion-gate evaluation (PCS-Daemon application) | `som.pge.promotion_gate.evaluate` | `plugin_id`, `plugin_version`, `decision` (`allow` / `reject`), `failing_rule_id` (when reject), `rule_corpus_version` |
| Dispatch-chokepoint evaluation (CRB application) | `som.pge.dispatch.evaluate` | `dispatch_target`, `principal_id`, `decision`, `matching_rule_id` (when reject), `rule_corpus_version` |
| Subagent-guard hook evaluation (Workforce surface) | `som.pge.subagent_guard.evaluate` | `tool_name`, `caller_identity`, `decision` (`allow` / `block`), `blocked_operation_class` (when block) |
| Rule lifecycle event (entry / amend / retire) | `som.pge.rule.lifecycle` | `rule_id`, `lifecycle_event` (`added` / `amended` / `retired`), `stratum` (`stratum_1` / `stratum_2`), `corpus_version_before`, `corpus_version_after` |
| Rule evaluation engine query (centralized substrate path) | `som.pge.engine.query` | `query_class` (`gate_decision` / `corpus_lookup` / `lifecycle`), `query_latency_ms` |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `som.pge.gate1.decisions_total` | counter | count | Cumulative Gate 1 evaluations labeled by `decision` (`allow` / `reject`) — operational signal for action-policy traffic |
| `som.pge.gate2.decisions_total` | counter | count | Cumulative Gate 2 evaluations labeled by `decision` — operational signal for sandbox-execution traffic |
| `som.pge.promotion_gate.decisions_total` | counter | count | Cumulative promotion-gate evaluations labeled by `decision` — PCS-Daemon coupling signal |
| `som.pge.dispatch.decisions_total` | counter | count | Cumulative dispatch-chokepoint evaluations labeled by `decision` — CRB coupling signal |
| `som.pge.subagent_guard.blocks_total` | counter | count | Cumulative subagent-guard blocks labeled by `blocked_operation_class` — Workforce-surface enforcement signal |
| `som.pge.rule_evaluation_latency_ms` | histogram | milliseconds | Per-gate evaluation latency, bucketed by `gate` (`gate1` / `gate2` / `promotion_gate` / `dispatch` / `subagent_guard`) |
| `som.pge.rule_corpus.size` | gauge | count | Current rule count per stratum (`stratum_1` / `stratum_2`) — corpus-health signal |
| `som.pge.rule_lifecycle.events_total` | counter | count | Cumulative lifecycle events labeled by `lifecycle_event` — corpus-stability signal |
| `som.pge.rule_corpus.version` | gauge | string | Current corpus version identifier (label-only gauge; emits 1) — citable in audit query joins |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| `pge.gate1.rejected` | `warn` | `pct_message_id`, `principal_id`, `matching_rule_id`, `rule_corpus_version` — operator visibility into rejected agent actions |
| `pge.gate2.rejected` | `warn` | `workload_id`, `principal_id`, `matching_rule_id`, `rule_corpus_version` — operator visibility into rejected sandbox workloads |
| `pge.promotion_gate.rejected` | `warn` | `plugin_id`, `plugin_version`, `failing_rule_id`, `rule_corpus_version` — promotion-gate blocked plugin |
| `pge.subagent_guard.blocked` | `warn` | `tool_name`, `caller_identity`, `blocked_operation_class` — runtime block via PreToolUse hook |
| `pge.rule.lifecycle` | `info` | `rule_id`, `lifecycle_event`, `stratum`, `corpus_version_before`, `corpus_version_after` |
| `pge.corpus.drift.detected` | `error` | `expected_version`, `observed_version`, `enforcement_surface` — Failure Mode 1 (corpus-drift) detection signal |
| `pge.gate.bypass.attempted` | `error` | `gate` (`gate1` / `gate2`), `attempt_pattern`, `principal_id_at_attempt` — Failure Mode 2/3 (gate-bypass attempt) signal |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name` — `agent-pge-mcp` (or the equivalent per-surface emitter; today's distributed substrate has each surface emit with its own `service.name` — `test_security_runner`, `subagent_guard`, etc. — and the rule_corpus_version attribute correlates them)
- `service.version` — from `get_version_info` MCP tool (when the central PGE service exists per DR-PGE-1) or per-surface version
- `deployment.environment` — resource attribute
- `identity` — PCT principal-id of the actor whose action is being evaluated
- `session` — session-id when applicable
- `trace_id`, `span_id` — OpenTelemetry standard
- `cost-center` — when ACT chargeback applies
- `rule_corpus_version` — citable across all PGE telemetry for audit-replay support

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT` (no specific backend named)
- **Logs**: JSON to stderr (stdout is reserved for the MCP protocol channel + the enforcement-surface decision channels where applicable)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields + `rule_corpus_version` for evaluation events

### Distinction: ACT-bound `pge.*` audit events vs `som.pge.*` MI-11 observability

PGE emits two distinct telemetry streams:
- **`pge.*` events to ACT** (per CD9 + § Coupling Boundary: ACT ↔ PGE): durable accountability records — `pge.action_policy_evaluated`, `pge.sandbox_policy_evaluated`, `pge.promotion_gate_evaluated`, `pge.*_rejected`, `pge.rule_added`/`amended`/`retired`. ACT consumes these into the cognitive-event store; they are the **audit truth** for rule decisions. **VP-PGE-1 tracks the cross-spec curation event** (four-pillar shared curation per Patton's standing direction).
- **`som.pge.*` MI-11 signals to OTLP sink** (this section): operational observability — gate evaluation latency, decision rate, rule-engine throughput, corpus drift detection. The customer's OTLP sink consumes these for dashboards, alerts, and capacity planning.

The streams correlate via `rule_corpus_version` (citable in both) and `trace_id` (when a gate decision span and an ACT audit event share the same trace context), but they do not collapse: the `pge.*` audit events are PGE's durable-record contract; the `som.pge.*` MI-11 signals are PGE's operational-observability contract. CD14 commits the MI-11 manifest; CD9 + CD11 + VP-PGE-1 commit the ACT audit emission contract.

### Explicitly NOT in this spec

- Collector deployment topology for PGE's MI-11 signals
- Backend choice for the OTLP sink — per § Substrate Matrix Telemetry-sink seam
- Dashboards, alerts, retention policies — deployment-side
- Sampling strategy for PGE's MI-11 — deployment-side (the `pge.*` ACT audit stream has zero sampling per CD11 audit-completeness; the `som.pge.*` MI-11 stream may sample per deployment policy)

These are governed by the Telemetry-sink seam per SOM-MI-8 substrate-pluggability extending to MI-11 per the SOM-MI-11 final paragraph.

## Closed Decisions (CDs — v1.0–v1.1 Commitments)

**CD1**: **PGE v1.0 is a pure capstone, not a behavior change.** No new rules added; no existing rules amended; no enforcement points added or removed. The spec promotes the de facto enforcement surface (`MCP-SECURITY-FRAMEWORK.md` v1.0 + `subagent-guard.sh` + `test_security.py` + CI release gates) into formal pillar contract.

**CD2**: **Rule Corpus has two strata** — Stratum 1 non-negotiable guarantees (10 today, CLCA-gated changes) + Stratum 2 implementation patterns (13+ today, routine review process). Adding rules requires curation event with tier identification.

**CD3**: **Double-guardrail architecture is load-bearing**: Gate 1 (agent-action policy at IBX submission chokepoint) + Gate 2 (sandbox-execution policy at DPG boundary). Both gates required; either alone is incomplete. Architectural commitment per `SOM-PROBLEM-STATEMENT.md` v0.6 §6 PGE-double-guardrail note.

**CD4**: **Rule Corpus and Enforcement Surface are architecturally distinct.** Rule corpus is semantic, version-controlled, code-resident; enforcement surfaces are pragmatic, deployment-substrate-specific. The same rule may apply at multiple surfaces.

**CD5**: **PGE does NOT carry its own daemon at v1.0.** Today's substrate is distributed enforcement surfaces (per-server tests, hook, CI gate); centralized policy services (OPA/Cedar/per-pillar engines) are admissible substrates per Exit Test but NOT v1.0 commitments.

**CD6**: **PGE consumes verified identity from IAM; does NOT mint or verify identity.** Authorization rules reference identity claims; identity issuance and verification remain IAM's exclusive domain.

**CD7**: **PGE does NOT enforce content-level policy beyond the rule corpus.** Domain coverage extensions (model-training policy, dataset-egress policy) are post-v1.0 spec additions, not routine pattern changes.

**CD8**: **Substrate substitutability via Exit Test** — per-server tests + hook + CI release gate at v1.0; OPA / Cedar / per-pillar engine / hybrid admissible at v1.x. Contract holds across substrate change.

**CD9**: **Rule decisions are auditable via ACT** — broker emits `pge.*` event sequence per § Coupling Boundary: ACT ↔ PGE. New event-type namespace tracked in VP-PGE-1.

**CD10**: **Rule lifecycle is curation-event-tracked** — entry/amend/retire events emitted to ACT; transitions are ordered and unambiguous; no period of two contradictory rules in flight.

**CD11**: **The double-guardrail is symmetric in audit treatment**: both Gate 1 rejections and Gate 2 rejections emit `pge.*_rejected` events with the failing rule identifier; audit completeness applies to both gates equally.

**CD12**: **Single source of policy truth** — DPG (CD8), PCS-Daemon (promotion gate), CRB (dispatch chokepoint) consume rules from PGE, not from their own embedded corpora. PGE is the policy hub; downstream pillars are enforcement points.

**CD13 (v1.1 — Substrate Matrix formalizes CD8 substitutability + Exit Test discipline at the per-seam level; pure capstone)**: Per SOM-MI-8 + § Tested Substrate Profiles + Patton's PR #31 capability-framing lesson. § Substrate Matrix names four PGE substrate seams (Rule corpus storage, Policy evaluation engine, Enforcement surface, Telemetry sink) **as the per-seam decomposition of CD8's substrate substitutability commitment and the pre-existing § Substrate Substitutability prose section**. v1.0 CD8 + § Substrate Substitutability committed substitutability at the prose level; v1.1 CD13 makes it mechanically checkable via the per-seam contract columns. The contract column is **capability-framed** (deterministic policy evaluation, version-controlled rule corpus citable from audit, distributed-or-centralized enforcement composition supporting CD3 double-guardrail) — not constraint-primitive-framed (Python pytest, Markdown, Bash hooks specifically). Sovereign-ref column names the specific reference (per-server `test_security.py` + `subagent-guard.sh` + CI release gate); supported-alternatives name what else satisfies the capability (OPA, Cedar, per-pillar engines, hybrid). **Pure-capstone discipline holds (CD1)**: this CD formalizes pre-existing v1.0 commitments into manifest format; it does not change PGE's behavior.

**CD14 (v1.1 — Telemetry Contract for `som.pge.*` MI-11 observability; distinct from `pge.*` ACT audit emission; pure capstone)**: Per SOM-MI-11 + the pillar-spec template + Patton's lesson on the audit-vs-observability stream distinction. § Telemetry Contract names PGE-specific `som.pge.*` spans (`som.pge.gate1.evaluate`, `som.pge.gate2.evaluate`, `som.pge.promotion_gate.evaluate`, `som.pge.dispatch.evaluate`, `som.pge.subagent_guard.evaluate`, `som.pge.rule.lifecycle`, `som.pge.engine.query`), metrics (`som.pge.gate1.decisions_total`, `som.pge.gate2.decisions_total`, `som.pge.rule_evaluation_latency_ms`, etc.), and log events. **Critical distinction maintained**: PGE emits two telemetry streams — the existing `pge.*` ACT audit emission (CD9 + CD11 + VP-PGE-1) for durable accountability records, and the new `som.pge.*` MI-11 observability for operational signals. The two streams operate on distinct contracts and do not collapse. **Pure-capstone discipline holds (CD1)**: this CD formalizes the MI-11 observability surface that PGE's existing distributed enforcement is already capable of emitting (today via per-surface OTel SDK wiring); it does not change PGE's behavior or add new `pge.*` audit events. Per `#22` resolution, the `pge.*` audit events route via Path A (direct emission to ACT) or Path B (PGE calls ACT as service-write); the resolution does not affect the `som.pge.*` MI-11 stream.

## Deferred-Pending-Increment-2-Rulings (DRs)

**DR-PGE-1**: **Centralized policy-engine substrate adoption.** Whether/when SOM adopts OPA, Cedar, or an equivalent centralized policy service depends on (a) Judge's ruling on which deployments will use SOM and at what scale; (b) whether per-server tests + hook + CI gate remain sufficient at customer scale or require central evaluation. v1.0 commits substrate substitutability (CD8); the *trigger* for migration is deferred.

**DR-PGE-2**: **Stratum-3 (domain-coverage) extension trigger.** Whether to add a Stratum 3 (specifically: domain-coverage rules — model-training policy, dataset-egress policy, finance/compliance rules per deployment vertical) depends on (a) customer engagements; (b) whether deployment-specific overlays prove insufficient and call for an in-corpus tier. v1.0 commits the existing two-stratum split; Stratum 3 admissibility deferred to ruling.

**DR-PGE-3 (couples to DR-IAM-4)**: **Rule-evaluation continuation on identity-session termination.** If an IAM session terminates while a long-running rule evaluation is in flight (e.g., a sandbox-execution policy evaluation that spans minutes), what happens to the evaluation? Audit invariant (per same pattern as DR-ACT-3 / DR-PCS-3 / DR-DPG-3 / DR-CRB-3): all evaluation events emitted to that point are preserved. Runtime continuation (in-flight evaluation continues vs is signaled to abort vs is re-issued on next session) depends on DR-IAM-4 ruling.

## Validation-Pending (VP)

**VP-PGE-1 (mirrors VP-PCS-1, VP-DPG-1, VP-CRB-1)**: **ACT extension to absorb `pge.*` event-type namespace.** v1.0 PGE spec proposes the new event-type prefix. Per ACT v1.0 CD4, adding requires explicit curation event. **Cross-spec dependency tracking**: PR #69 (this spec) is the originating reference, **alongside** PR #66 (`pcs.*`), PR #67 (`dpg.*`), and PR #68 (`crb.*`) — **four pillars now**. Per Patton's standing direction (`4759a355` + `294ec70a` + `ea67f2ac`): **a single shared curation event closes VP-PCS-1 + VP-DPG-1 + VP-CRB-1 + VP-PGE-1 simultaneously**, preventing the half-extended-enum failure mode across all four pillars. Pre-curation-event, PGE may emit `act.detection_signal` events with payload-encoded `signal_type=pge_*` (e.g., `pge_action_policy_rejected`, `pge_sandbox_policy_rejected`, `pge_rule_added`).

## Open Questions (genuinely open, v1.0)

**OQ-P1**: **Cross-deployment rule overlay model.** When SOM supports multiple deployments (lab + customer A + customer B), how do deployment-specific rules overlay the core rule corpus? Recommendation: per-deployment overlay file with explicit additions/removals against the core; rule resolution = core ∪ deployment-additions − deployment-removals. v1.0 commits single-deployment corpus; multi-deployment overlay model is post-v1.0.

**OQ-P2**: **Rule-versioning granularity for migrations.** When a rule is amended, downstream consumers (DPG, PCS-Daemon, CRB) must re-evaluate any in-flight work against the new rule. What is the right granularity (per-rule version, per-corpus version, per-evaluation snapshot)? v1.0 commits corpus-level versioning; finer granularity post-v1.0.

**OQ-P3**: **Rule corpus inheritance for plugin-defined rules.** May a PCS plugin contribute its own rule entries to the PGE corpus (e.g., a finance plugin contributing finance-specific policy rules)? Recommendation: plugins may NOT mutate the core corpus; deployment-overlay model handles plugin-introduced rules at the overlay layer. v1.0 keeps this closed (plugins do not write to corpus); reopen if real workloads pressure-test.

**OQ-P4**: **Rule evaluation performance at scale.** Today's per-server `test_security.py` runs in seconds per CI cycle. At customer scale (10x or 100x current MCP server count), does the substrate need optimization (parallel evaluation, cached evaluation results, incremental evaluation)? v1.0 commits the current substrate; optimization is post-v1.0.

## Failure Modes To Watch

- **Rule-corpus drift between `MCP-SECURITY-FRAMEWORK.md` and runtime enforcement.** The framework doc and the actual enforcement surfaces (`test_security.py`, `subagent-guard.sh`) could diverge if rule changes update one but not the other. **Mitigation**: rule-lifecycle events emit to ACT; periodic audit query verifies corpus version matches enforcement-surface version; CI gate on `MCP-SECURITY-FRAMEWORK.md` changes triggers parity test.
- **Gate-1 bypass via PCT routing trick.** An agent crafts a PCT that nominally passes agent-action policy but contains a hidden directive that escapes Gate 1 evaluation. **Mitigation**: the rule corpus' Stratum 1 guarantees (especially #5 no command-injection surface, #9 input validation) close this surface; Gate 2 catches what Gate 1 missed.
- **Gate-2 bypass via sandbox escape.** A workload finds a sandbox-escape primitive (e.g., a kernel-level vulnerability that exfiltrates from the DPG boundary). **Mitigation**: this is a substrate vulnerability, not a PGE failure per se; DPG owns the sandbox primitive (per `DPG-SPEC.md` v1.0); PGE's rule corpus includes "no kernel-level system calls" as part of Stratum 2 sandbox-execution patterns.
- **Both-gates-bypass via process-level rule erosion.** Operator/agent process-level rules (CLAUDE.md § Subagent Policy) erode over time (text-only "soft" enforcement). **Mitigation**: hard enforcement (subagent-guard.sh) catches the residual case; CI gate on CLAUDE.md changes flags rule erosions for Judge review.
- **VMA-like single-point-of-failure regression.** Future PGE version centralizes enforcement at a single service (an OPA cluster); that service becomes a target. **Mitigation**: CD3 double-guardrail is architectural commitment, not implementation detail — central service must still apply both gates; CD8 substrate substitutability allows central services BUT the contract requires double-guardrail preservation.
- **Stratum-1 dilution.** Pressure to add many rules at Stratum 1 (because "everything is critical") dilutes the non-negotiable tier. **Mitigation**: CD2 commits the two-stratum architecture and the CLCA gate for Stratum 1 entries; Judge sign-off discipline restricts Stratum 1 expansion to genuine non-negotiable classes.
- **Cross-deployment rule confusion.** Customer A's deployment uses overlay rules; Customer B's does not; operator confuses which corpus applies in a cross-customer support session. **Mitigation**: OQ-P1 commits to explicit overlay model when multi-deployment lands; until then, single-deployment scope keeps this closed.
- **Audit incomplete on rule-amendment race.** A rule is amended at T0; a Gate 1 evaluation in flight at T0 races the amendment; which rule applies? **Mitigation**: CD10 commits ordered, unambiguous lifecycle transitions; in-flight evaluations use the rule corpus version snapshot taken at evaluation start; rule amendments do not retroactively affect in-flight evaluations.
- **Forward-reference rot.** DPG / PCS-Daemon / CRB / IAM references to `MCP-SECURITY-FRAMEWORK.md` as PGE source remain stale after this capstone merges. **Mitigation**: post-merge sweep tracked in this spec's status banner; Patton's `ea67f2ac` close-out flag captured the cross-spec sweep work item.
- **Sandbox-execution policy gap on novel substrates.** A future workload class (e.g., quantum compute) lands without sandbox-execution policy coverage; Gate 2 has nothing to enforce. **Mitigation**: rule-corpus extension lifecycle (CD2) applies; new workload classes trigger Stratum 2 pattern additions during onboarding.

## Dependencies

- **`SOM-PILLAR-NAMES.md`** v1.1 — PGE pillar entry of record (line 50)
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — PGE row at §3 "Replaces vendor safety filters with deterministic compliance"; this spec advances the row from "Operational (MCP-SECURITY-FRAMEWORK is its de facto spec)" to "Specification complete (validated)" while preserving the de facto framework as Stratum 1 + Stratum 2 source of corpus
- **`SOM-PROBLEM-STATEMENT.md`** v0.6 — §6 PGE double-guardrail note resolves into CD3
- **`SOM-TECHNICAL-OVERVIEW.md`** v0.2 — Control Plane framing for PGE
- **`MCP-SECURITY-FRAMEWORK.md`** v1.0 (2026-03-04) — the de facto PGE spec; v1.0 PGE-SPEC promotes this to formal pillar contract while preserving the framework doc as the canonical corpus reference
- **`IBX-SPEC.md`** v1.0 — IBX submission chokepoint is Gate 1 surface
- **`IAM-CORE-SPEC.md`** v1.0 — PGE consumes verified identity from IAM (CD6)
- **`ACT-SPEC.md`** v1.0 — `pge.*` events for audit emission; VP-PGE-1 tracks the cross-spec curation event dependency (now four-pillar)
- **`PCS-DAEMON-SPEC.md`** v1.0 — promotion-gate consumes PGE rules; post-merge sweep updates `MCP-SECURITY-FRAMEWORK.md` references to `PGE-SPEC.md`
- **`DPG-SPEC.md`** v1.0 — Gate 2 lives inside DPG boundary; CD8 single-source-of-policy-truth commitment; post-merge sweep
- **`CRB-SPEC.md`** v1.0 — dispatch chokepoint consumes PGE rules; CD6 single-source commitment; post-merge sweep
- **`CLAUDE.md`** § Security clauses, § Subagent Policy — process-level enforcement surface
- **`.claude/hooks/subagent-guard.sh`** — runtime enforcement surface

## Acceptance Criteria

Per the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md` — five non-negotiables given equal weight to security). PGE is the policy-enforcement pillar — the security framework applies *as PGE's own corpus*; PGE's acceptance criteria are recursively the framework PGE enforces on everyone else. PGE is not validated until all five hold; below them, the PGE-specific acceptance bars from v1.0 (renamed from § Success Criteria) are preserved as additional evidence.

**Pure-capstone caveat**: PGE is operational today. The 5 non-negotiables are formalizing what PGE already does in production — not specifying new build behavior. Measures cite existing production state where applicable.

### Five non-negotiables (template-mandated, equal weight to security)

1. **Secure.** PGE *is* the security framework — `MCP-SECURITY-FRAMEWORK.md` is PGE's de facto v1.0 rule corpus. The recursive case: PGE follows its own rule corpus across PGE's own runtime. Stratum 1 guarantees (10 today) bind PGE's own implementation: PGE evaluation code has no `subprocess`/`shell=True` on rule inputs, no `eval`/`exec` on rule expressions, HTTPS only, parameterized queries to ACT, input validation on every rule lookup. The rule-corpus drift failure mode (Failure Mode 1) is the PGE-specific application of this criterion. **Measure**: PGE's own implementation (today: `subagent-guard.sh` + per-server `test_security.py` runners + CI hooks) passes `test_security.py` against itself; rule-corpus-drift detection (CD11 audit-completeness symmetry) is operationally exercised in CI.

2. **Instrumented-by-default.** PGE emits the `som.pge.*` spans + metrics + log events in § Telemetry Contract via OTLP. Mandatory — PGE is the gate the rest of the mesh trusts to enforce policy; an uninstrumented PGE is a gate whose evaluation latency, decision rate, and corpus health are invisible. **PGE-specific double-emission**: PGE also emits `pge.*` events to ACT for durable audit (CD9 + CD11). Both streams are mandatory. **Measure**: an OTel Collector receiving from PGE's enforcement surfaces (today's distributed substrate: `subagent_guard`, `test_security_runner`, CI gate emitters) observes the full `som.pge.*` span set + metric set; ACT query confirms the `pge.*` audit event coverage per CD11. Both observed simultaneously confirms the dual-emission discipline.

3. **JSON logs.** PGE emits structured JSON logs to stderr with the required keys per SOM-MI-11. **PGE-specific**: every log event carries `rule_corpus_version` so a log line cross-references a citable corpus version — essential for audit replay against historical rule sets. stdout is reserved for the MCP protocol channel + the enforcement-surface decision channels. **Measure**: parsing PGE's distributed-substrate stderr in CI confirms every line is valid JSON with required keys plus `rule_corpus_version` on evaluation events; `trace_id` cross-references the OTLP traces emitted in the same evaluation.

4. **CLI-first / UI-second.** Every PGE management function — rule corpus inspection, lifecycle event execution (rule add/amend/retire), gate decision query, corpus-drift verification — is reachable via CLI/API before any UI exists. Future MCC panes for PGE (rule corpus browser, gate-decision dashboard, lifecycle action interface) render the CLI/API surface, never bypass. **PGE-specific note**: rule-lifecycle operations (CD10 curation events) are CLI-only operations carrying high authority — there is no UI shortcut for amending or retiring a rule; both operations require explicit CLI invocation with Judge-approved credential. **Measure**: every operation reachable from any PGE UI is reachable headless via an MCP/CLI tool with the same authorization gate; rule-lifecycle operations have no UI surface at all.

5. **Audit emission.** PGE emits `pge.*` events to ACT for every state-affecting operation (gate decisions, rule-lifecycle events). Per CD9 + CD11 + VP-PGE-1. Path A (until `#22` resolves to Path B): events emitted directly to ACT's MI-1 stream with the rule identifier, decision, principal, corpus version + PGE-specific fields. Path B: PGE calls ACT during the critical path of each evaluation. **PGE-specific Tier-0 constraint**: a Path-B failure path that loses a `pge.*` audit event is a policy-decision-without-audit-trail violation — Failure Mode 7 (audit incomplete on rule-amendment race) generalizes to all gate-decision audit emission, and the resolution must hold under Path B unavailability (buffer-and-halt-or-retry per fail-strict). **Measure**: audit query against the MI-1 stream after a representative operation set (one Gate 1 evaluation, one Gate 2 evaluation, one promotion-gate evaluation, one rule lifecycle event) confirms every state mutation has a corresponding `pge.*` event with all required fields including `rule_corpus_version`.

### Additional PGE-specific acceptance bars (preserved from v1.0)

- **Pure-capstone discipline holds.** No new rule added at v1.0; no existing rule altered; no enforcement point added/removed. **v1.1 maintains this**: § Substrate Matrix + § Telemetry Contract formalize pre-existing CD8 + CD9 commitments; they do not change PGE's behavior. **Measure**: `MCP-SECURITY-FRAMEWORK.md` diff from pre-PGE-spec to post-merge state is text-cosmetic only (no rule-set changes).
- **Forward-reference sweep completes within next-touch cycle.** DPG / PCS-Daemon / CRB / IAM references to `MCP-SECURITY-FRAMEWORK.md` as PGE source update to `PGE-SPEC.md` on their next touch. **Measure**: at each next-spec-version commit, the reference table reflects `PGE-SPEC.md` as PGE source.
- **Double-guardrail enforced at both gates.** Every PCT submission passes Gate 1; every workload execution passes Gate 2. **Measure**: ACT query shows `pge.action_policy_evaluated` events on every PCT submission and `pge.sandbox_policy_evaluated` events on every workload execution.
- **Single source of policy truth held.** DPG, PCS-Daemon, CRB do not embed their own rule corpora. **Measure**: code review on any consuming-pillar version rejects embedded policy rules per their CD's source-from-PGE commitment.
- **Substrate substitutability holds.** PGE contract is expressible in per-server-tests + hook + CI gate (v1.0 reference), OPA, Cedar, per-pillar engines, and hybrid substrates. **v1.1 makes this mechanically checkable per § Substrate Matrix + SOM-CD15.** **Measure**: substrate-swap exercise during deployment migration verifies contract holds via multi-profile conformance run; no contract revision required.
- **Audit completeness.** Every rule decision (Gate 1 + Gate 2 + promotion-gate + lifecycle) has corresponding ACT event coverage. **Measure**: ACT query shows complete event coverage for sampled rule decisions.
- **Patton dialectical sign-off at v1.1.** Single review gate per the simplified workflow; file-based review per the discipline established at PR #65 + continued through the v1.1 batch. **Measure**: Patton's sign-off comment on the v1.1 review gate (GH-native per the 2026-06-02 convention).

## References

- `planning/SOM-SPEC.md` — mesh-level invariants this pillar instantiates (SOM-MI-8 substrate substitutability, SOM-MI-11 telemetry contract, SOM-CD15 conformance-enforced substrate-neutrality, § Tested Substrate Profiles). **v1.1 source for the per-pillar manifest layer.**
- `planning/PILLAR-SPEC-TEMPLATE.md` — pillar-spec template that v1.1 instantiates (10 required sections, Substrate Matrix + Telemetry Contract section structures, 5 non-negotiables). PGE-SPEC v1.1 is the fourth instantiation after IBX-SPEC + IAM-CORE-SPEC + ACT-SPEC.
- `planning/IBX-SPEC.md` v1.1 — Gate 1 surface; first pillar instantiation (capability-framing discipline applied to PGE's matrix per CD13)
- `planning/IAM-CORE-SPEC.md` v1.1 — identity consumed by PGE; second pillar instantiation
- `planning/ACT-SPEC.md` v1.1 — `pge.*` audit events; VP-PGE-1 four-pillar curation event; third pillar instantiation
- `planning/SOM-PILLAR-NAMES.md` v1.1 — PGE pillar entry of record
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — PGE row (operational status; this spec capstones it)
- `planning/SOM-PROBLEM-STATEMENT.md` v0.6 — §6 PGE double-guardrail note
- `planning/SOM-TECHNICAL-OVERVIEW.md` v0.2 — Control Plane framing
- `planning/MCP-SECURITY-FRAMEWORK.md` v1.0 — de facto PGE spec; canonical corpus reference; security framework referenced by Acceptance Criterion 1
- `planning/PCS-DAEMON-SPEC.md` v1.0 — promotion-gate consumer
- `planning/DPG-SPEC.md` v1.0 — Gate 2 substrate
- `planning/CRB-SPEC.md` v1.0 — dispatch-chokepoint consumer
- `CLAUDE.md` § Security clauses, § Subagent Policy
- `.claude/hooks/subagent-guard.sh` — runtime enforcement surface
- Issues `KI7MT/som-spec#16` (this v1.1 refresh), `KI7MT/som-spec#6` + `#24` (template that this spec instantiates)
