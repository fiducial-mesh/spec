---
title: "IBX Spec — Inbox Exchange Message Routing Substrate"
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
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
  - planning/PCS-REGISTRY-FOLD-IN.md
  - shared-context/agent-message-queue.sql
---

# IBX Spec — Inbox Exchange Message Routing Substrate

**Scope**: Formalizes the contract IBX (Inbox Exchange) satisfies as the Control-Plane message routing substrate of SOM. Covers the PCT (Principal Control Token) nine-field schema, **two distinct message-routing dispatch patterns** (point-to-point and worker-pool claim), status workflow, the server-enforced Judge-approval gate, the storage substrate (which may split by pattern), the identity-vs-session distinction folded from `SOM-CONCURRENCY-AND-ARCHETYPES.md`, and the coupling boundaries with PCS-Lifecycle and SOM's IAM pillar.

**Status**: **Validated v1.1** — first instantiation of the new pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md`, merged 2026-06-05). v1.1 adds the per-pillar manifest layer (§ Substrate Matrix + § Telemetry Contract) that instantiates the mesh-level contracts in `SOM-SPEC.md` (SOM-MI-8, SOM-MI-11, § Tested Substrate Profiles); renames § Success Criteria → § Acceptance Criteria with the 5 non-negotiables from the template prepended; records CD7 + CD8 for the v1.1 commitments. v1.0 contract surface is unchanged — PCS-Daemon's `pct-v1` consumer remains valid. v1.0 history retained below.

**Prior status (v1.0, retained for history)**: First item of the spec-campaign queue (per Patton's `87d77f55`). Extends v0.2 with the concurrency hooks from `SOM-CONCURRENCY-AND-ARCHETYPES.md` (Patton + Watson, 2026-06-02, landed at `c5b2426`) and resolves the non-IAM-coupled Open Questions to commitments. IAM-coupled Open Questions (DR1, DR2, DR3, DR5) remain **deferred-pending the seven Increment-2 Judge rulings**; DR6 is **narrowed** to defer only the v2 *content* (migration *discipline* committed in CD6). DR4 was **closed** at the v1.0 review gate by Patton ruling (`b2b6a4e1`) — see CD5. The stable parts are validated and PCS-Daemon may build against them.

v1.1 additions (this version):
1. **§ Substrate Matrix** (new section) — per-pillar manifest of IBX's substrate seams (routing audit storage, worker-pool claim queue, identity verification, telemetry sink, Judge-gate credential) per SOM-MI-8 + § Tested Substrate Profiles. CD7 commits PG-17 as primary worker-pool claim queue substrate per Bob's CD4-permissive reading (`6316686f`) + Judge's (B) Owed disposition. Substitutability claim is scoped to the matrix rows (per SOM-CD15).
2. **§ Telemetry Contract** (new section) — IBX-specific spans (`som.ibx.message.send`, `som.ibx.judge.gate.fire`, `som.ibx.workerpool.claim`, etc.), metrics (`som.ibx.message.depth`, `som.ibx.judge.gate.pending`, etc.), and log events per SOM-MI-11. CD8 commits this as the MI-11 manifest for IBX.
3. **§ Acceptance Criteria** (renamed from § Success Criteria) — prepends the 5 non-negotiables from `planning/PILLAR-SPEC-TEMPLATE.md`: Secure, Instrumented-by-default, JSON logs, CLI-first/UI-second, Audit emission. Existing v1.0 success criteria preserved as additional IBX-specific acceptance bars.
4. **CD7 + CD8** record the substrate matrix + telemetry contract commitments respectively.

The v1.0 contract surface (PCT nine-field schema, priority semantics, status workflow, server-enforced Judge gate, worker-pool claim/lease/retry contract) is **unchanged**. PCS-Daemon's `pct-v1` consumer built against v1.0 remains valid. v1.1 is additive: it adds the manifest layer that says *which* substrates and *which* spans/metrics — it does not modify any v1.0 commitment.

v1.0 additions (retained for history):
1. **Identity-vs-session distinction** folded into PCT field 1 (`principal-id`) — names *which identity*; the substrate names *which session of that identity*. Today IBX is single-session-per-identity in practice; the spec defines the contract for the concurrent-sessions case so the worker-pool pattern is unambiguous when Bob builds it.
2. **Worker-pool claim dispatch pattern** — new § Concurrency-Safe Worker-Pool Dispatch. Exactly-once claim semantics (SKIP-LOCKED-style), lease/visibility-timeout, retry + poison-queue, idempotency keys, mid-action-safe termination. Substrate implication: claim queue needs a transactional store (OLAP/ClickHouse is wrong for the claim queue).
3. **Resolved Open Questions** (non-IAM-coupled, now Closed Decisions): validate-at-send fail-strict on PCT meta fields (CD1, closes OQ1+OQ2), `all`-is-announcements broadcast semantics (CD2, closes OQ5), field-name convention snake_case (CD3, closes OQ10), substrate split by dispatch pattern (CD4 — v1.0 new). Patton review at v1.0 (`b2b6a4e1`) closed an additional question on the merits: validity stays advisory for `info` priority (CD5, closes DR4 v0.2 OQ8). Patton review also committed the PCT contract-version migration discipline (CD6) — coordinated migration with PCS-Daemon participation; no unilateral version changes; v2 *content* still deferred but the *migration posture* is locked in.
4. **Storage substrate splits by dispatch pattern**: point-to-point routing's audit-trail can stay OLAP (ClickHouse); worker-pool claim queue requires a transactional store. v1.0 names the split; the deployment-architecture doc picks the specific substrate.
5. **Failure modes**: added stale-claim-after-crash, lease-expiry race, double-claim from idempotency-key collision, mid-action-termination return-to-queue.

**Authors**: Watson (drafted v0.1 → v0.2 → v1.0); Patton (dialectical review at each gate; co-author on the concurrency design that this v1.0 folds in). v0.2 history preserved in commits `2fb9e09` (v0.1), `a92db3d` (Patton fold-in pass 1), `3cb0f6f` (Bob fold-in pass 2). v0.2 merge: `d755cd9` (PR #58).

**The nine-field PCT contract surface is unchanged from v0.2.** v1.0 adds *behavior* (worker-pool dispatch, identity-vs-session interpretation) without modifying any field name or semantics. Patton's stability directive holds: PCS-Daemon's `pct-v1` consumer built against v0.2 remains valid under v1.0.

**Don't front-run discipline**: per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §8 and Patton's `87d77f55`, the worker-pool dispatch design and the validity-default and PCT-integrity questions all couple to the seven Increment-2 rulings (concurrency cap values per tier, session vs identity revocation, ITDR-over-ACT scope, etc.). v1.0 specifies the **stable claim/lease/retry semantics** and explicitly marks the **ruling-dependent pieces** deferred. Bob may build the stable parts; the ruling-dependent parts wait for Judge.

## Purpose / Problem Restatement

IBX (Inbox Exchange) is the Control-Plane message routing substrate that carries every async hand-off between SOM agents and every Judge-approval gate. It is the hub that PCS, PGE, CRB, and Judge route *through* to reach Workforce — the structural reason PCT (Principal Control Token) lives in IBX rather than in PCS scope. Today IBX is **POC-in-production**: the runtime substrate (`agent-inbox-mcp` server + `inbox-ui` Wails desktop app + `messages.inbox` ClickHouse table on 9975WX) is operational and used daily for Watson/Bob/Patton/Einstein hand-offs and Judge approvals. The pillar has no formal spec — `SOM-PILLAR-NAMES.md` v1.1 records its Spec column as *"Pending dedicated spec; behaviors documented in CLAUDE.md 'Agent Message Queue' + agent-inbox-mcp README."* This document closes that gap.

The load-bearing question this spec answers: **what contract must IBX hold across substrate evolution** so that downstream consumers (PCS-Daemon, IAM-when-built, the Increment-2 active-security model) can build against a stable surface? The substrate may evolve (DAC ClickHouse today → EPYC/TrueNAS per the PCS-Registry deployment plan); the contract must not. The spec formalizes what is already true (the nine-field PCT, the priority semantics, the server-enforced Judge gate) so that "what IBX guarantees" stops being implicit and starts being citable.

This is also Patton's risk #2 from the two-week roadmap: PCS-Daemon ↔ IBX coupling. If the PCT contract churns mid-cycle, Bob's PCS-Daemon design churns with it. A stable v1.0 contract de-risks the PCS Daemon build that follows the AKB spec finish + concurrency design.

## Approach / Architecture

### Current state vs. specification target — stated plainly

**Current state**: IBX runs as a POC-in-production on 9975WX. The runtime is:

- **`messages.inbox`** — ClickHouse table on 9975WX (`/var/lib/clickhouse`, ZFS-backed). DDL lives in `shared-context/agent-message-queue.sql`. Append-mostly; status mutations land as new rows materialized into the latest-state view.
- **`agent-inbox-mcp`** — internal Python MCP server, six tools (`inbox_check`, `inbox_read`, `inbox_send`, `inbox_mark`, `inbox_search`, `get_version_info`). Runs on every agent host via local venv (`$WORKSPACE_ROOT/.venv/bin/agent-inbox-mcp`). M3 sets `CH_HOST=10.60.1.1` to reach ClickHouse over the DAC link; 9975 talks to localhost; EPYC reaches via DAC link `10.60.2.0/24`.
- **`inbox-ui`** — Wails/Go/Svelte desktop app on M3, the only path Judge uses to approve/reject `action`/`urgent` messages. Holds the server-enforced approval gate (see § Judge-Approval Gate).
- **Dedicated ClickHouse user `inbox`** — has grants limited to `messages.inbox` only. Cannot read `wspr.*`, `solar.*`, `training.*`, or any other dataset. Cannot set `approved` or `rejected` status (that capability lives only with the Judge-side credential used by `inbox-ui`).

**Specification target**: this document. The runtime above already satisfies the contract; this spec writes the contract down so it can be cited by PCS-Daemon, IAM (when built), and Increment-2. It does **not** require a re-build of IBX; it formalizes the surface and identifies what must hold across substrate evolution.

**Future home — preserved distinction**: per `PCS-REGISTRY-FOLD-IN.md` v1.3 and the deployment-architecture work, the SOM production substrate target is **EPYC/Proxmox VM + TrueNAS NFS** with internal-only DNS via PiHole. IBX migrates with that substrate transition; the contract this spec defines must hold across the migration. References to "where IBX runs" in this document always say "on 9975WX today / on EPYC/TrueNAS at production target" rather than collapsing the two — that distinction is load-bearing.

### Pillar placement and structural role

IBX sits on the **Control Plane** of SOM's three-plane decomposition (per `SOM-PROBLEM-STATEMENT.md` v0.5 §0). It is the **hub** that other Control-Plane pillars (PCS, PGE, CRB) and the Judge gate route *through* to reach the Compute Plane (Workforce + DPG). Two structural observations follow:

1. **IBX is the message system; PCS owns plugin schemas; MCP is the wire protocol.** These three layers are deliberately separate — confusing them is one of the failure modes the seven-pillar shape was designed to prevent. PCT (the Principal Control Token, defined below) is a *message*; it lives in IBX rather than in PCS because pillar-owns-its-own-schemas keeps the pillars orthogonal. Bob and Patton converged on this independently from different priors (`SOM-PROBLEM-STATEMENT.md` §2 and §6.3); the convergence is the kind of independent-reasoning evidence that makes the placement architecturally stable.

2. **IBX consumes from SOM's IAM pillar (when IAM is built).** Currently the `sender` field in `messages.inbox` is asserted by brief — identity-by-brief, not identity-by-credential. Once SOM's IAM pillar (per `SOM-IDENTITY-PILLAR-DESIGN.md`) is built, every IBX message becomes signed by the sender's agent-DNA (private key) and verifiable against the public-key fingerprint in the Roster. The PCT `principal-id` field (defined below) is the seam where that verification happens. v1.0 names the seam; the verification commit lands when IAM does (DR2 deferred-pending-IAM).

### The PCT (Principal Control Token) — nine-field contract

PCT is the message-from-Principal-to-Singleton artifact that the Singleton/Instance Asymmetry (per `SOM-PROBLEM-STATEMENT.md` v0.6 §2) makes load-bearing. Every IBX message carries a PCT in its body, structured or implicit. v1.0 commits the nine-field surface; **field names and semantics are stable across review cycles** — v1.x may add validation detail but may not rename or remove fields.

The nine fields divide cleanly into three groups:

- **Identity / work (1-3)**: who sent it, what they want done, the background to do it.
- **Boundary axes (4-6)**: the three orthogonal axes that constrain the work — **reach** (scope), **completion criterion** (success criteria), **autonomy** (authority bounds). Scope and authority bounds are axially distinct (per Patton dialectical review `31b322a3`): scope answers *what may I touch*, authority bounds answers *what may I decide without asking*. The spec keeps them split because conflating them muddles the IAM-coupling seam (scope ties to job-code authz) with the Judge-gate seam (authority bounds ties to approval). Prose must not let one creep into the other's territory.
- **Meta (7-9)**: properties of the PCT itself, not its content. Version, provenance, validity window — the machine-validated fields a future structural-validation pass will live in.

| Field | Type | Purpose |
|---|---|---|
| **1. principal-id** | string (agent_id) | Sender **identity** — who the principal is. Today brief-asserted (the agent claims to be "Patton" because the briefing says so); IAM-future credential-verified (signed with agent-DNA private key, verified against Roster-published public-key fingerprint). Seam into SOM's IAM pillar — `principal-id` is *the* field IBX/IAM coupling lands on. **Identity-vs-session distinction (v1.0, per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §1)**: `principal-id` identifies the *identity* (singular, who), not the *session* (which execution). A worker pool of N concurrent sessions for the same `document-processor` identity carries `principal-id=document-processor` on every PCT; the substrate distinguishes the specific session of that identity via session attribution (see § Identity-vs-Session at IBX). Today IBX runs single-session-per-identity in practice for Watson/Bob/Patton/Einstein/Newton; the spec defines the concurrent-sessions contract so the worker-pool pattern is unambiguous when Bob builds it. |
| **2. task** | string | The atomic unit of work being requested. Imperative form ("review PR #56", "draft IBX-SPEC"). One task per PCT — **today this is convention, not enforced**; IBX does not reject multi-task PCTs at send. DR3 names whether v1.x+ enforces (deferred-pending Increment-2 ruling on per-session-credential scoping). Chained work uses separate PCTs linked via field 8 `audit`. |
| **3. context** | markdown | Background the recipient needs to act. Includes prior decisions, current state, file paths, commit hashes. Bounded length — if context exceeds a screenful, link rather than embed. |
| **4. scope** | enum + string | **Access-control axis: what data, files, repos, or resources the recipient may ACT ON.** Answers "what may I touch." Today expressed in prose, bounded informally by the recipient's role brief; IAM-future ties directly to the recipient's job-code authorization policy and becomes machine-enforced. Do NOT use this field to express decision-rights — that is field 6. |
| **5. success criteria** | bulleted list | How the recipient (and the next reviewer) knows the task is done. Each criterion is measurable or verifiable. No "vibes-based" criteria. |
| **6. authority bounds** | enum + string | **Decision-rights axis: what the recipient may decide UNILATERALLY vs. must escalate to the Judge gate.** Answers "what may I decide without asking." A task may be entirely *in scope* (the recipient is authorized to touch the resources) yet require Judge approval to *act* (the decision exceeds unilateral autonomy). Criteria that exceed bounds route through the Judge-approval gate via priority `action` or `urgent`. Do NOT use this field to express access — that is field 4. |
| **7. version** | string (semver-like) | PCT contract version this message conforms to. v1.0 contracts are tagged `pct-v1` (PCT v1 surface is what this spec commits). Future versions may add fields but not break v1 readers. Validated at send per CD1 (required-field check, fail-strict). |
| **8. audit** | structured | Provenance — who originated the PCT, when, in response to what (prior message_id, prior commit hash, prior PR number). The chain that lets a reviewer reconstruct *why* the task was requested. Validated at send per CD1. PCT integrity in transit (tamper-evidence) is a future concern (DR2 deferred-pending-IAM); v1.0 does not commit signing. |
| **9. validity** | timestamp (`not-after`) | **Expiry window — when the PCT becomes stale and recipients must not act on it.** Patton flagged the no-expiry gap (`31b322a3`): a PCT outliving the authority that issued it is the async equivalent of a credential with no expiry — the exact anti-pattern SOM's IAM pillar exists to prevent. **v1.0 CD1 commits validity *required* at send for `action`/`urgent` priority** (missing = send rejected); **advisory for `info` priority** (may be unset). v1.x may promote validity to a structured column for substrate-level enforcement. **Default behavior** if `validity` is unset on `info` priority: PCTs do not auto-expire, but recipients *must* check the originating context for staleness signals (a task referencing PR #56 after PR #56 merged is implicitly stale). DR4 names whether v1.x extends required-validity to info priority (deferred-pending Increment-2 expiry ruling). |

**Stability commitment**: PCS-Daemon may build a `pct-v1` consumer against this nine-field surface. Future PCT contract changes (v2 onwards) must preserve v1-field compatibility — new fields may be added; existing fields may not be renamed, retyped, or have semantics altered without a coordinated v2-bump migration that PCS-Daemon participates in. The axial split of scope/authority bounds in particular is structural: collapsing them in any future version would muddle the IAM-coupling and Judge-gate seams.

**Today's encoding**: PCT structure is **implicit** in the inbox-message body (markdown). The `sender`, `recipient`, `priority`, `subject` columns of `messages.inbox` encode fields 1, 4 (partial), 6 (partial). Fields 2, 3, 5, 7, 8, 9 live in the body. v1.x may add explicit structured columns for fields 7, 8, and 9 (the machine-validated meta fields) as substrate evolves. v1.0 specifies the contract; the storage encoding is a substrate-implementation detail.

**Validation-at-send is committed (v1.0 CD1)**: IBX validates machine-critical PCT structure (fields 7, 8, 9) at `inbox_send` time and rejects malformed messages fail-strict. The architecture's spine (no-bypass + fail-strict at every chokepoint) is honored at the IBX layer specifically. Fields 2-6 remain body-encoded for human readability; the server does NOT enforce structural validation on them (recipient-side parsing is the validation layer for content fields, where context informs what counts as well-formed). This is the v1.0 commitment; drift toward trust-the-recipient on machine-critical fields would require a v2 spec change with explicit Patton review.

### Message routing contract

**Senders and recipients** (the bounded principal set):

- `watson`, `bob`, `patton`, `einstein`, `newton` — the five Workforce callsigns (per `SOM-PROBLEM-STATEMENT.md` v0.5 §0, "Workforce as first-class named container")
- `judge` — the human-authority gate, accessed via `inbox-ui` only
- `all` — broadcast recipient; sender `all` is reserved (broadcasts originate from a named principal)

Cross-cutting hand-offs (Watson → Bob, Bob → Patton, Patton → Watson, etc.) all route through `messages.inbox`. There is no out-of-band agent-to-agent channel — IBX is the **only** substrate for cognitive hand-off, by design (the audit trail and Judge-gate are non-bypassable as long as IBX is the only path).

**Priority semantics** — three levels with distinct contracts:

| Priority | Recipient may act without Judge approval? | Use when |
|---|---|---|
| `info` | Yes — agents act on info immediately. | FYI, status updates, reference material, completion confirmations. |
| `action` | **No** — must wait for Judge to mark `approved` via `inbox-ui` before acting. | A task requiring sustained work, a decision affecting other pillars or external state, a sign-off request. |
| `urgent` | **No** — same as `action`, but flagged for Judge's immediate attention. | Blocking issues, security flags, time-critical decisions. |

**Status workflow** — five live states plus two terminals:

```
unread → read → approved → in_progress → done
                                       ↘ rejected
```

- **unread** — message landed in recipient's queue; not yet inspected.
- **read** — recipient (or another agent on their behalf) has loaded the body. Agents may transition `unread → read` on receipt; today this is often implicit in tool-call patterns.
- **approved** — Judge has cleared the message via `inbox-ui` (action/urgent only). For `info` priority, this state is skipped (info messages flow `read → done`).
- **in_progress** — recipient is acting on the approved task. Multi-step work stays in this state across many commits.
- **done** — task complete; provenance preserved in the chain.
- **rejected** — Judge declined the action (action/urgent only). Terminal; replaces the would-have-been work with the rejection record.

Status mutations are append-mostly — each transition lands as a new row in `messages.inbox` with the new status; the latest-state view materializes the current status per message-id. This preserves the audit trail without requiring soft-delete or in-place mutation.

### Identity-vs-Session at IBX (v1.0, folded from concurrency design)

Per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §1, identity and session are distinct concepts that the original IBX (v0.x) conflated by running single-session-per-identity in practice. v1.0 names the distinction explicitly so the worker-pool dispatch pattern (next section) is unambiguous when Bob builds it.

- **Identity** = WHO the principal is (the `principal-id` field of PCT — agent_id, e.g., `document-processor`, `watson`, `patton`). Permanent, singular per principal. The substrate level on which authority and audit are grouped.
- **Session** = WHICH execution authenticated as that identity is doing the work. Ephemeral. Multiple concurrent sessions of the same identity are allowed for archetypes that support them (Worker, Reasoner per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §2); Quorum-voter archetype requires **distinct identities**, not multiple sessions of one.

**Substrate-level session attribution** (the implementation layer's job, not PCT's): the substrate row for an IBX message records both `principal-id` (the identity, copied from PCT field 1) and a `session-id` (a substrate-generated ULID/UUID per running session). Today (single-session-per-identity in practice for Watson/Bob/Patton/Einstein/Newton), every IBX hand-off implicitly has session = identity-singleton; the substrate may record a sentinel `session-id=identity` value. When Bob builds the worker-pool case, the substrate begins assigning a fresh `session-id` per claim-event (see § Concurrency-Safe Worker-Pool Dispatch); `principal-id` stays constant across the pool, `session-id` distinguishes the specific worker.

**Why the distinction matters at IBX layer**:
- **Attribution and incident response operate at SESSION level; identity is the grouping.** Without session granularity, a compromised worker-instance is invisible among legitimate ones and you cannot suspend just the bad one. This is the structural reason ACT will store `(identity, session)` tuples rather than just identity (ACT spec — item 3 of the spec campaign).
- **The Judge-approval gate operates on PCT, which carries `principal-id` (identity).** Authority is granted to the identity; sessions inherit it. A worker-pool action-priority message does not multiply Judge approvals across N sessions — the identity gets one approval and the pool's N workers can all claim under it.
- **Suspension/termination semantics distinguish**: session-level suspend (instance-2 stops, instance-1 and instance-3 keep working) vs identity-level terminate (all instances of the identity stop). Both are real operations; the Increment-2 ruling on terminator failure-mode determines specific semantics. Until that lands, the contract IBX commits to: substrate tracks `session-id`, supports per-session suspend, and supports per-identity terminate via PCT routed at IAM-future authority.

**Identity-vs-session in PCT itself**: PCT carries only `principal-id` (identity). It does NOT carry session-id — the session is a substrate property of the claim, not a contract field. This keeps PCT stable as a v1 surface; session granularity lives at the storage/runtime layer where it belongs.

### Concurrency-Safe Worker-Pool Dispatch (v1.0, new dispatch pattern)

Point-to-point routing (above) handles `Watson → Patton` and `Bob → Watson` hand-offs — the recipient is a specific principal. **Worker-pool dispatch** handles a different shape: the recipient is "any-instance-of-identity-X", and the first session of that identity to claim the work owns it. Worker-pool dispatch is the substrate for the Worker archetype per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §2.

**The dispatch contract** (v1.0 stable commitments — Bob may build against these):

1. **Exactly-once claim, lease-bounded.** A PCT addressed to a worker-pool recipient is claimed by exactly one session via an atomic `SKIP-LOCKED`-style operation (or substrate equivalent). The claim is recorded with the claiming `session-id`, a `claimed-at` timestamp, and a `lease-expires-at` timestamp derived from the configured lease duration.
2. **Lease / visibility-timeout for crash recovery.** If the claiming session does not transition the PCT to `done` (success) or `rejected` (failure) before `lease-expires-at`, the claim expires and the PCT becomes claimable again. This guarantees that a crashed worker's in-flight unit returns to the queue without manual intervention. **Lease duration default is an Open Question** (depends on workload — fast worker pools need short leases; slow human-review-loop tasks need long leases). Until the default is set, deployments specify per-pool.
3. **Mid-action-safe termination.** If a worker session is suspended or terminated while holding a claim, the substrate must return the claim to the queue (mark the claim as `released` rather than `done` or `rejected`). This is the operational consequence of the identity-vs-session distinction at IBX — session-level termination must release session-held claims back to the identity's pool.
4. **Idempotency keys for safe retry.** A worker that completes its PCT but crashes before recording `done` may re-claim the same PCT (after lease expiry) and re-execute. The contract IBX commits: the PCT carries a stable `idempotency-key` derived from the PCT id; recipient must use this key when writing downstream artifacts (bronze layer, side effects) so duplicate execution is detected at the destination, not at IBX.
5. **Poison/dead-letter queue.** A PCT that has been claimed and released (via crash, lease expiry, or explicit rejection) more than a configurable retry count gets moved to a dead-letter queue rather than re-claimed indefinitely. **Retry count default**: 3 attempts before dead-letter (commit). Operator may override per pool; the value goes in the dispatch configuration, not the PCT.
6. **Bronze writes must be concurrent-safe + idempotent.** This is a discipline on the *recipient*, not on IBX itself — but IBX commits to the idempotency-key contract above to make the recipient discipline implementable. Workers writing to `wspr.bronze`-style sinks must use `INSERT IF NOT EXISTS` semantics keyed on `idempotency-key`.

**Substrate implication: claim queue needs transactional store; ClickHouse is wrong** (per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §5):
- The point-to-point routing audit trail (today's IBX `messages.inbox` on ClickHouse) is fine on OLAP — appends are cheap, audit queries are columnar.
- The claim queue requires **row-level atomic claim** semantics that OLAP databases do not provide. ClickHouse SKIP-LOCKED equivalent doesn't exist; concurrent workers claiming the same PCT would race and double-execute.
- **v1.0 commits: the claim queue substrate is distinct from the routing audit trail substrate.** Specific choices (PostgreSQL with `FOR UPDATE SKIP LOCKED`, Redis Streams with consumer groups, RabbitMQ work queues, NATS JetStream consumer ack) are deployment decisions. The Exit Test discipline (per `SOM-PROBLEM-STATEMENT.md` v0.5 §4) applies — any substrate that supports atomic claim, lease, and per-session attribution may host the queue.
- **Today's IBX (v0.x) does NOT have a worker-pool case in production.** Every PCT is point-to-point; the claim queue substrate is unbuilt. The contract above describes what IBX-the-pillar commits to *when* the worker-pool case is built; the implementation phase (Bob's PCS-Daemon and any document-processing workers) brings up the claim queue substrate as needed.

**Routing recipient resolution for worker-pool**:
- Today's `recipient` field carries a specific principal-name (`watson`, `bob`, `patton`, etc.) or `all` (broadcast).
- v1.0 adds: **`recipient=pool:<identity>`** denotes a worker-pool recipient. The substrate enforces exactly-once claim semantics on PCTs with `pool:` prefix; PCTs without the prefix are point-to-point (current behavior, no claim semantics).
- The prefix syntax keeps point-to-point routing unchanged — no existing message format is broken; the worker-pool case is opt-in.

### Judge-approval gate (MCP-server-layer enforced, code-not-prompt, non-substitutable)

The Judge-approval gate is a first-class architectural element of SOM (per `SOM-TECHNICAL-OVERVIEW.md` v0.2 § Control Plane). IBX enforces it at the **MCP-server layer (code, not prompt)** — not at the schema layer. The precise mechanism (per Bob's `60856a8d` no-overclaim review):

- The `agent-inbox-mcp` server **refuses to write** the values `approved` or `rejected` for any agent caller — this is application-layer code, not a prompt-layer convention. Calls that attempt those status transitions are rejected at the server before reaching ClickHouse.
- The `inbox-ui` Wails app (Judge's desktop tool) is the **only** path that writes `approved` or `rejected`, and it does so under a separate Judge-side credential.
- The ClickHouse user `inbox` (the credential `agent-inbox-mcp` uses) holds grants on `messages.inbox` for `SELECT` and `INSERT`. ClickHouse GRANTs are **table/column-level, not value-level** — there is no schema-level way to grant "INSERT status ∈ {`read`, `in_progress`, `done`} but not {`approved`, `rejected`}" to a user. Code-level enforcement in the MCP server is the working substitute.

**Important security-claim limit, stated plainly**: a caller holding the `inbox` credential and talking to ClickHouse *directly* (bypassing the MCP server) is **not** schema-blocked from writing `approved` or `rejected`. The protection holds because (a) agents reach `messages.inbox` only through the `agent-inbox-mcp` chokepoint, (b) the chokepoint is application-layer code Watson/Bob review on every commit, and (c) audit captures any out-of-band writes. This is **stronger than prompt-layer convention but weaker than cryptographic enforcement** — which is exactly why the IAM-future hardening (signed messages + hardware-bound Judge credential) matters. The same gap is the reason the bus is named "cooperative-trusted, not cryptographically-trusted" elsewhere in this spec; the two framings are consistent.

The contract IBX commits to: **no action-priority work begins until the gate fires through the inbox-ui code path**, and the gate cannot be bypassed without compromising the Judge-side credential *or* the application-layer MCP server. Both are sensitive surfaces; the IAM build elevates both.

### Storage substrate (current and substitutable; v1.0 splits by dispatch pattern)

**v1.0 substrate framing**: IBX has **two distinct substrate concerns** that may share or split storage:
1. **Routing audit trail** — the point-to-point hand-off record (Watson → Patton with priority, status workflow, Judge-gate transitions). Append-mostly, columnar-friendly, OLAP-suitable. Today on ClickHouse `messages.inbox`.
2. **Worker-pool claim queue** — atomic claim, lease, retry, dead-letter (per § Concurrency-Safe Worker-Pool Dispatch). Requires row-level transactional semantics. ClickHouse is **wrong substrate** for this — see the §Worker-Pool section above. Today **not built**; brought up when the first worker-pool case lands.

Concerns may share a substrate (a transactional store supporting both append-audit and atomic-claim — PostgreSQL, NATS JetStream, etc.) or split (ClickHouse for audit, separate transactional store for claim queue). The Exit Test discipline applies to each concern independently — the contract is what IBX commits, not which database.

**Current substrate** (today, routing audit trail only): ClickHouse `messages.inbox` on 9975WX. Columns approximately:
- `id` (UUID), `timestamp`, `sender`, `recipient`, `priority`, `subject`, `body` (markdown), `status`, plus provenance columns (`originating_message_id`, `originating_commit_hash`).
- DDL canonical at `shared-context/agent-message-queue.sql`.
- Append-mostly; latest-state view materializes current status per `id`.
- LZ4 compression on disk; ZFS pool `data-pool/clickhouse`.

**Substitutable substrate** (Exit Test pass): Kafka, RabbitMQ, Redis Streams, or any message-queue substrate that supports:
1. Persistent message storage with content-addressable identifiers
2. Append-mostly status mutation (or equivalent state machine)
3. Schema-enforced authorization (which credential can write which status)
4. Tooling for the equivalent of the six MCP tool surface (`check`, `read`, `send`, `mark`, `search`, `get_version_info`)

The Exit Test discipline (per `SOM-PROBLEM-STATEMENT.md` v0.6 §4) requires the contract to hold across substrate swap. The PCT contract, the priority semantics, the status workflow, the Judge-gate enforcement, and the worker-pool claim/lease/retry contract are substrate-agnostic; ClickHouse is the v1.0 routing-audit-trail implementation, not the contract.

### Coupling boundary: PCS-Daemon ↔ IBX

PCS-Daemon (per `PCS-REGISTRY-FOLD-IN.md` v1.3 §Lifecycle) is the registry-side service that wraps the `pcs-control-plane` Harness and integrates with IBX for the Judge-approval gate during plugin promotion. The coupling boundary IBX commits to:

**What PCS-Daemon may rely on from IBX (v1.0 — `pct-v1` contract surface)**:
- The nine-field PCT contract is stable across review cycles (Patton's discipline directive in `5fd105cd`). Field names and semantics are not renamed or retyped without coordinated v2-bump migration.
- The axial split of scope (#4, access-control) and authority bounds (#6, decision-rights) holds — PCS-Daemon may rely on these being two distinct fields, not a collapsed one, because the IAM-coupling and Judge-gate seams depend on the distinction.
- The priority semantics (`info` / `action` / `urgent`) and the status workflow (`unread → read → approved → in_progress → done` or `rejected`) are stable.
- The server-enforced Judge-approval gate fires for any `action`-priority message regardless of sender; PCS-Daemon emits its promotion approval requests at `action` priority and trusts IBX to gate them.
- **`message_id` is stable, and status is queryable per `message_id`** (per Bob's `60856a8d` coupling-boundary addition). PCS-Daemon's promotion pattern is *send `action`-priority request → poll for the Judge's `approved`/`rejected` by `message_id`*; this commitment is what makes the send/poll loop correlatable. Implied by the per-message-id latest-state view materialized over `messages.inbox`, committed explicitly here so PCS-Daemon's build may depend on it.
- The substrate is reachable from PCS-Daemon's deployment host (EPYC/Proxmox VM today routes to IBX-on-9975 via DAC `10.60.2.0/24`; production target is co-located on EPYC/TrueNAS).

**What PCS-Daemon may NOT rely on from IBX (v1.0) — deferred/unstable side, per Patton's directive that the unstable side stay at least as detailed as the stable side (`31b322a3`)**:
- **Recipient-side semantic validation of fields 2-6** — v1.0 CD1 commits fail-strict validation at send for fields 7-9 *only*; fields 2-6 are body-encoded and not server-validated. PCS-Daemon must defensively validate the content fields of a received PCT before acting (e.g., parse field 2 task structure, parse field 4 scope assertions).
- **Schema-level PCT validation columns for content fields** — v1.0 may store fields 1, 4 (partial), 6 (partial) in columns; fields 2, 3, 5, 7, 8, 9 live in body today. v1.x may add structured columns for 7-9 (validation-already-committed). Fields 2-6 stay body-encoded as v1.0 commitment.
- **PCT integrity / tamper-evidence in transit** — v1.0 does not commit signing or tamper-detection (DR2 deferred-pending-IAM). PCS-Daemon should treat the bus as cooperative-trusted, not cryptographically-trusted, until the IAM coupling (agent-DNA signature model) lands.
- **`info`-priority validity enforcement** — v1.0 CD1 commits validity *required* at send for action/urgent; info priority may have unset validity. DR4 names whether v1.x extends required-validity to info (deferred-pending Increment-2 expiry ruling). PCS-Daemon must apply context-based staleness judgment for info-priority PCTs without explicit validity.
- **One-task-per-PCT enforcement** — v1.0 documents one-task-per-PCT as convention, not enforced at send (DR3 deferred-pending Increment-2 ruling on per-session-credential scoping). PCS-Daemon must not assume a received PCT contains a single task; defensive parsing of field 2 should handle the multi-task case gracefully even if the convention is followed in practice.
- **Future PCT v2 forward-compatibility guarantees** — v1.0 commits the `pct-v1` surface only (DR6 deferred — v2 is premature pending Increment-2 reshaping). When v2 is proposed, PCS-Daemon participates in the coordinated migration; until then, do not pre-build for hypothetical v2 fields.
- **Round-trip-time guarantees on the Judge gate** — v1.0 does not commit a latency contract. PCS-Daemon's design must tolerate that Judge approval may take seconds, minutes, or hours, depending on operator availability.
- **Worker-pool claim queue substrate** — v1.0 commits the claim/lease/retry/idempotency contract but does not commit a specific substrate (PostgreSQL, NATS, Redis Streams, etc.) — DR5 defers the substrate choice to the deployment-architecture doc. PCS-Daemon's worker-pool consumption pattern must be substrate-agnostic by adhering only to this spec's claim semantics.
- **Cross-substrate behavior under EPYC/TrueNAS migration** — v1.0 commits the contract holds across substrate change but does not commit the migration timing or the cutover semantics (DR5). PCS-Daemon's design should be substrate-agnostic by adhering only to this spec's contract, not to ClickHouse-specific behavior of the current implementation.

**The Watson↔Bob coordination discipline this implies**: any time IBX-SPEC version changes a clause in either table above, Bob is notified via inbox `info` before the PR opens — the may-rely-on table changing reduces what Bob can build against; the may-NOT-rely-on table changing means something Bob was holding off on may now be available. Patton dialectical review at each gate (Patton's directive). PCS-Daemon's design assumptions live in its own spec and are cross-checked against this section at every IBX-SPEC version bump.

### Coupling boundary: IAM (future) ↔ IBX

When SOM's IAM pillar is built (per `SOM-IDENTITY-PILLAR-DESIGN.md`), IBX integrates as follows:

- Every IBX message becomes **signed** by the sender's agent-DNA (private key) at `inbox_send` time.
- The PCT `principal-id` field is verified against the sender's signature and the Roster-published public-key fingerprint.
- The `sender` column of `messages.inbox` is no longer brief-asserted — it is the principal authenticated against ARCA-issued identity.
- The Judge-side credential used by `inbox-ui` becomes a real human credential (PIV/CAC, hardware-bound) rather than the current ClickHouse-user-grant model.
- The server-enforced gate persists; the credential model underneath gets stronger.

**v1.0 commits to naming this seam, not to building it.** The IAM pillar is design-stage, briefs-only — the current state per the v1.1 validation doc. Until IAM lands, IBX runs on identity-by-brief; this is honest, documented, and consistent with the rest of SOM's design-vs-implementation discipline.

## Substrate Matrix

Per SOM-MI-8 + `SOM-SPEC.md` § Tested Substrate Profiles, IBX's substrate substitutability is defined as **passing the multi-profile conformance run** against the matrix below. Wording is **role + version floor** — the matrix names *contracts*, not *products*. IBX's substitutability claim covers exactly the rows listed; out-of-set substrates require a new profile definition (per CONF-CD11), conformance suite extension, and the multi-profile run passing per SOM-CD15.

IBX exposes five substrate seams. The first two are storage (split per CD4 by dispatch pattern); the third is identity (design-stage gap closed by IAM); the fourth is telemetry (per SOM-MI-11); the fifth is the Judge-gate credential boundary (today ClickHouse-grant-based, hardware-bound per future IAM).

| Seam | Contract (role + version floor) | Sovereign reference (version floor) | Supported alternatives (version floor) |
|------|---------------------------------|-------------------------------------|----------------------------------------|
| **Routing audit storage** (point-to-point hand-off record) | Append-mostly storage with per-message-id latest-state view materialization; LZ4 or zstd compression; columnar-friendly OR row-oriented | ClickHouse 23.8+ (today on 9975WX `messages.inbox`) | PostgreSQL 17+ with logical-decoding history, NATS JetStream 2.10+ with stream retention, Kafka 3.6+ with compacted topics |
| **Worker-pool claim queue** (atomic claim / lease / retry / dead-letter; per § Concurrency-Safe Worker-Pool Dispatch) | Row-level transactional semantics with SKIP-LOCKED-style atomic claim; lease/visibility timeout; idempotency-key uniqueness constraint; per-attempt retry counter; dead-letter routing on attempt N+1 | **PostgreSQL 17+** with `FOR UPDATE SKIP LOCKED` (CD7) | NATS JetStream 2.10+ (consumer ack with redelivery), Redis Streams 7+ (consumer groups with XCLAIM), RabbitMQ 3.12+ (quorum queues with delivery-count) |
| **Identity verification source** (sender authentication for PCT principal-id field 1) | Sender identity attestation: today brief-asserted (cooperative trust); future ARCA-signed PCT verifiable against Roster-published public key | **IAM (design-stage, briefs-only)** | Cooperative-trust-by-convention (today). IAM is the only future binding per § Coupling boundary: IAM. Until IAM lands, this seam is design-only — see DR2. |
| **Telemetry sink** (per SOM-MI-11; OTLP-on-the-wire contract) | OpenTelemetry / OTLP for traces + metrics; JSON-structured logs to stderr; sink configurable via `OTEL_EXPORTER_OTLP_ENDPOINT` | Grafana/Prometheus/Tempo stack | Azure Monitor / App Insights, Datadog, OCI Monitoring, any OTLP-compatible sink — per SOM-MI-11 final paragraph |
| **Judge-gate credential store** (server-enforced status-mutation authorization; only Judge can transition unread → approved/rejected) | Authorization gate on status-mutation MCP tool calls; credential binding cannot be bypassed at the prompt layer | ClickHouse user grant (today, `inbox-ui` MCP/desktop app holds the credential) | IAM-issued hardware-bound credential (PIV/CAC) per § Coupling boundary: IAM. Currently the lab's most sensitive non-ClickHouse-admin credential. |

**Conformance**: CI runs the multi-profile conformance suite (CONF-CD1..11) against **≥ 2 products per seam** from the supported set when IBX is built out for SOM mesh. A seam change that fails any tested profile does not merge (SOM-CD15). For today's POC-in-production state, only the sovereign-reference column is exercised; the alternatives are spec'd as the substitutability boundary that future deployment + migration work (per DR5) preserves.

**Out-of-set substrates**: A deployment using a substrate not listed (e.g., MongoDB for routing audit, Cassandra for claim queue, Keycloak for identity verification) is **not covered by IBX's substitutability claim** — it requires a new profile definition (CONF-CD11), a conformance suite extension to test the seam against it, and the multi-profile run passing per SOM-CD15. This is the same boundary discipline as `SOM-DELIVERY-PACKAGING.md` DP-CD1 (tested-on-named-base-image-set-not-any-Linux).

**Cross-pillar substrate consequences**: per SOM-CD9, no IBX substrate choice may create lock-in for another pillar's substrate. The CD4 split (routing audit vs claim queue) is *itself* an instance of this discipline applied within the pillar — IBX could not have committed to ClickHouse-for-everything without locking PCS-Daemon's worker-pool consumer into a ClickHouse-shaped contract that no other transactional substrate could satisfy.

## Telemetry Contract

Per SOM-MI-11, `agent-inbox-mcp` (the IBX runtime substrate) emits OTLP traces, OTLP metrics, and JSON-structured logs to stderr. The sink is selected by the customer via `OTEL_EXPORTER_OTLP_ENDPOINT`; SOM does not name the backend. Naming convention follows the template: `som.ibx.<operation>` for spans, `som.ibx.<metric>` for metrics.

This section is the per-pillar **manifest** of MI-11's mesh-level **contract** — the spans, metrics, and log events IBX commits to emit. Pillars that consume this telemetry (ACT for chargeback + metering; Patton/Newton for behavioral analysis; future MCC for operator dashboards) build against the names and attributes below.

### Spans

| Operation | Span name | Required attributes (beyond identity, session, service.*) |
|-----------|-----------|-----------------------------------------------------------|
| PCT validation + send | `som.ibx.message.send` | `priority`, `recipient`, `pct_validation_outcome` (`ok` / `field_missing` / `validity_missing` / `policy_rejected`) |
| Query latest-state view by recipient + filter | `som.ibx.message.read` | `filter_status` (e.g., `unread`, `approved`), `result_count` |
| Append status mutation | `som.ibx.message.mark` | `from_status`, `to_status`, `message_id` |
| Search by sender / recipient / subject / date range | `som.ibx.message.search` | `filter_kind` (`sender` / `recipient` / `subject` / `date`), `result_count` |
| Judge-gate trigger on action/urgent send | `som.ibx.judge.gate.fire` | `priority`, `sender`, `recipient` |
| Judge-gate decision (approved or rejected) via `inbox-ui` | `som.ibx.judge.gate.transition` | `from_status` (`unread`), `to_status` (`approved` or `rejected`), `judge_decision`, `pending_duration_ms` |
| Atomic claim of worker-pool PCT | `som.ibx.workerpool.claim` | `pool_id`, `lease_duration_ms`, `worker_session_id` |
| Claim lease expired; PCT returns to queue | `som.ibx.workerpool.lease_expire` | `pool_id`, `worker_session_id`, `attempt_count` |
| Worker records done; idempotency-key written | `som.ibx.workerpool.complete` | `pool_id`, `idempotency_key`, `worker_session_id` |
| Dead-letter routing (attempt N+1 retries exhausted) | `som.ibx.workerpool.deadletter` | `pool_id`, `message_id`, `attempt_count`, `last_error_class` |

### Metrics

| Metric name | Type | Unit | Meaning |
|-------------|------|------|---------|
| `som.ibx.message.depth` | gauge | count | Current count of messages by status (`unread`, `read`, `in_progress`) per recipient — operational backlog signal |
| `som.ibx.message.lag_ms` | histogram | milliseconds | Time from send to first read, bucketed by priority — message-pickup latency |
| `som.ibx.message.action_lag_ms` | histogram | milliseconds | Time from send to `approved` for action/urgent priority — Judge response latency (the load-bearing operator metric) |
| `som.ibx.judge.gate.pending` | gauge | count | Current count of action/urgent messages awaiting Judge approval — Judge inbox backlog signal |
| `som.ibx.workerpool.claim_rate` | counter | claims/sec | Per-pool claim throughput |
| `som.ibx.workerpool.lease_expirations_total` | counter | count | Cumulative lease expiries per pool — crash-recovery signal (high rate = workers crashing mid-claim) |
| `som.ibx.workerpool.deadletter_total` | counter | count | Cumulative dead-letter routes per pool — poison-message signal |
| `som.ibx.workerpool.idempotency_collision_total` | counter | count | Cumulative idempotency-key collisions detected at recipient sinks (downstream-reported) — double-execution signal |

### Log events

| Event | Level | Structured fields (beyond required keys) |
|-------|-------|------------------------------------------|
| `pct.validation.failed` | `warn` | `missing_field`, `sender`, `priority`, `validation_rule` (one of CD1 fail-strict rules) |
| `judge.gate.transition` | `info` | `from_status`, `to_status`, `judge_decision`, `message_id`, `pending_duration_ms` |
| `judge.gate.timeout_warning` | `warn` | `pending_duration_ms`, `message_id`, `sender`, `priority`, `threshold_ms` |
| `workerpool.lease.expired` | `info` | `pool_id`, `worker_session_id`, `attempt_count`, `message_id` |
| `workerpool.deadletter.routed` | `error` | `pool_id`, `message_id`, `attempt_count`, `last_error_class` |
| `substrate.exit_test.violation` | `error` | `substrate_name`, `contract_field`, `expected`, `observed` — fired when a substrate-swap test detects contract drift |

### Required attributes / resource attributes (per MI-11, all events)

- `service.name` = `agent-inbox-mcp` (resource attribute)
- `service.version` — from `get_version_info` MCP tool (resource attribute)
- `deployment.environment` — resource attribute (e.g., `lab-9975`, `prod-epyc`)
- `identity` — PCT principal-id (event attribute; required on every span)
- `session` — PCT session-id when present (event attribute; required on worker-pool spans)
- `trace_id`, `span_id` — OpenTelemetry standard (event attributes)
- `cost-center` — applied when ACT chargeback is wired (post #22 resolution)

### Format

- **Traces + metrics**: OpenTelemetry / OTLP, exported via `OTEL_EXPORTER_OTLP_ENDPOINT` (no specific backend named)
- **Logs**: JSON to stderr (stdout is reserved for the MCP protocol channel)
- **Required log keys**: `timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session` + event-specific fields

### Distinction: audit (MI-1) vs observability (MI-11)

IBX emits **both** audit signals (durable accountability record per SOM-MI-1) and observability signals (operational + cost-attribution per SOM-MI-11). The two streams are distinct:

- **MI-1 (audit)**: every status mutation (`send`, `mark`, judge-gate `approved`/`rejected`) is durably recorded as an accountability event with `identity`, `session`, `operation`, `outcome`, `timestamp` + PCT-specific fields. ACT consumes from this stream. Today the audit record lives in `messages.inbox` itself (append-only append-mostly); the MI-1 contract is what makes that record reliable.
- **MI-11 (observability)**: the spans, metrics, and log events above. ACT consumes the token + cost metrics from this stream for chargeback.

Per the pillar-spec template's Telemetry Contract guidance, the two streams are named separately so consumers know which contract they're building against. Per `#22` resolution, MI-1 emission may be direct (Path A) or via ACT service-write (Path B); the per-pillar implementation honors whichever path is current.

### Explicitly NOT in this spec

- Collector deployment topology (OTel Collector vs direct OTLP push)
- Backend choice (App Insights, Datadog, Grafana/Tempo, etc.) — per Telemetry-sink seam in § Substrate Matrix
- Dashboards, alerts, retention policies — deployment-side concerns
- Sampling strategy — deployment-side concern

These are governed by the Telemetry-sink seam per SOM-MI-8 substrate-pluggability extending to MI-11 per the SOM-MI-11 final paragraph.

## Closed Decisions (v1.0–v1.1)

Four v0.2 Open Questions are resolved to commitments in v1.0 — the leanings carried in v0.2 had the right discipline and v1.0 commits them as the contract Bob may build against. These do not couple to Increment-2 rulings; they were ready to close.

**CD1 (closes v0.2 OQ1 + OQ2)**: **Validate-at-send is the discipline; fields 7-9 (version, audit, validity) are validated at `inbox_send` time, fail-strict on malformation.** The validation runs at the `agent-inbox-mcp` server layer (same chokepoint as the Judge-gate enforcement, per § Judge-approval gate). Specific rules:
- Required-field presence check for fields 7 and 8 (version, audit). Missing = send rejected; sender gets a structured error naming the missing field.
- Field 9 (validity) is *advisory* for `info` priority (may be unset), *required* for `action` / `urgent` priority (unset = send rejected). This is the operational form of "action/urgent without explicit validity is the async-credential-expiry anti-pattern" surfaced in Patton's `31b322a3` review.
- Fields 2-6 remain body-encoded for human readability; the server does NOT enforce structural validation on them (full semantic validation is delegated to the recipient).
- The validation contract is **substrate-independent**: the same fail-strict-at-send semantic holds whether IBX is on ClickHouse, PostgreSQL, or any future substrate. This is the v1.0 commitment that makes the architecture's no-bypass + fail-strict spine load-bearing at IBX.

**CD2 (closes v0.2 OQ5)**: **`all` is for announcements only; tasks address a specific recipient.** A PCT addressed `recipient=all` is an announcement (informational broadcast — completion notifications, status updates, reference material). Announcements:
- Have no `task` field semantic (the announcement *is* the message; nothing is being requested).
- Cannot carry `action` or `urgent` priority (no Judge gate fires for announcements).
- Are excluded from the worker-pool dispatch pattern — `pool:<identity>` is the worker-pool recipient form, not `all`.

**CD3 (closes v0.2 OQ10)**: **Field-name convention is `snake_case`** for forward compatibility with structured-column storage. v1.0 spec body retains `principal-id` etc. for hyphenated human-reading aesthetics in this document; the canonical storage column names use `snake_case` (`principal_id`, `task`, `context`, `scope`, `success_criteria`, `authority_bounds`, `version`, `audit`, `validity`). The two are equivalent labels for the same fields; the storage form is authoritative for any tooling that schema-validates.

**CD4 (v1.0 new)**: **Worker-pool claim queue substrate is distinct from routing audit-trail substrate.** The claim queue requires row-level transactional semantics (`SKIP-LOCKED`-style atomic claim) that OLAP (ClickHouse) does not provide. v1.0 commits that the two concerns may share or split substrate; the specific worker-pool substrate (PostgreSQL, NATS JetStream, Redis Streams, RabbitMQ, etc.) is a deployment decision that goes in the deployment-architecture doc, not this spec. The Exit Test applies to each concern independently.

**CD5 (closes v0.2 OQ8 / v1.0 fold-in DR4 — Patton ruling `b2b6a4e1`)**: **Validity stays advisory for `info` priority; the required-at-send rule does NOT extend to info.** Patton's ruling at the v1.0 review gate: *"Validity/expiry exists to prevent stale HIGH-STAKES tasks being actioned late. Info has no task semantic — a stale info message read late is harmless. Requiring validity on info = ceremony with zero risk-reduction."* The required-validity discipline binds where staleness causes ACTION (action/urgent priorities — committed by CD1); info messages may have unset validity indefinitely. This closes the question of whether v1.x extends required-validity to info; the answer is no, on the merits, independent of the Increment-2 session-expiry rulings (per-message PCT validity ≠ session expiry semantics — those are different concerns).

**CD6 (v1.0 — PCT contract-version migration discipline, Patton ruling `b2b6a4e1`)**: **A PCT contract-version change (v1 → v2) is a COORDINATED MIGRATION in which PCS-Daemon participates — not a unilateral IBX change.** Contract-version changes are never made unilaterally. The v2 *content* (which fields, what semantics) is deferred pending Increment-2 rulings that may reshape the v1 surface (DR6 below — narrowed to *content* only). The v2 *migration discipline* (how a version change happens) is committed now: PCS-Daemon's consumer must be updated in coordination with the IBX-side change, both parties review the v2 candidate spec, the bump is gated by Patton review + Judge merge, and no IBX deployment writes `version=2` PCTs until PCS-Daemon's consumer reads them. This is the v1.0 commitment that protects against the exact coupling-churn risk Patton's stability directive targets — it locks in the coordination posture before any v2 content is on the table.

**CD7 (v1.1 — Substrate Matrix commits PG-17 as primary worker-pool claim queue substrate)**: Per Bob's CD4-permissive reading (inbox `6316686f`) + Judge's (B) Owed disposition (2026-06-04): IBX-as-SOM-pillar belongs on the SOM substrate (`pg-1`), not the IONIS-lab ClickHouse where today's `messages.inbox` POC sits. The worker-pool claim queue requires PostgreSQL 17+ with `FOR UPDATE SKIP LOCKED` semantics (the row-level transactional contract that ClickHouse's OLAP model cannot satisfy per CD4). § Substrate Matrix names the per-seam contracts as the substitutability boundary per SOM-CD15: alternatives (NATS JetStream, Redis Streams, RabbitMQ) are part of the substitutability claim; out-of-set substrates are a new conformance run. Routing audit storage remains permissive (ClickHouse OK today; PG-17 OK; migration timing per DR5). This CD does not commit a deployment-side migration plan for the routing audit (that's DR5); it commits the substrate matrix as the substitutability boundary.

**CD8 (v1.1 — Telemetry Contract commits the per-pillar MI-11 manifest)**: Per SOM-MI-11 + the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md`): § Telemetry Contract names IBX's specific spans (`som.ibx.message.send`, `som.ibx.judge.gate.fire`, `som.ibx.workerpool.claim`, etc.), metrics (`som.ibx.message.depth`, `som.ibx.judge.gate.pending`, `som.ibx.message.action_lag_ms`, etc.), and log events. `agent-inbox-mcp`'s implementation wires these surfaces to the OTel SDK and emits OTLP to the customer-selected `OTEL_EXPORTER_OTLP_ENDPOINT`. The contract is mandatory per § Acceptance Criteria #2 (Instrumented-by-default). ACT consumes the metrics + spans for chargeback per the MI-11 → MI-1 distinction documented in § Telemetry Contract.

## Deferred-Pending-Increment-2-Rulings (v1.0)

Per Patton's `87d77f55` discipline (*"don't front-run the seven Increment-2 rulings"*), these items couple to Judge's pending rulings and stay deferred. v1.0 names each one explicitly so Bob can build against the stable v1.0 contract without assuming the deferred items will land in any particular direction.

**DR1 (deferred — was v0.2 OQ4)**: **ITDR-over-ACT integration.** An ITDR (Identity Threat Detection and Response) layer reads IBX message patterns from ACT telemetry for behavioral anomaly detection. Depends on (a) Increment-2 settling the ITDR scope ruling (JIT-broker scope + ITDR scope are linked decisions per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §8), (b) ACT pillar spec landing (spec-campaign item 3). IBX will commit a hook contract when both ship; the hook surface is named here as a future seam, not a current capability.

**DR2 (deferred — was v0.2 OQ6)**: **PCT integrity / tamper-evidence in transit.** When IAM lands, PCTs become signed by sender agent-DNA and verifiable against Roster-published public keys (per `SOM-IDENTITY-PILLAR-DESIGN.md`). v1.0 deliberately does not commit a signing contract — a future reader must not infer the bus is cryptographically trusted today (it is *cooperative-trusted*). Open: the signing contract lands at the same gate IAM moves from briefs-only to operational. Increment-2 ruling on session-vs-identity signing semantics also feeds in.

**DR3 (deferred — was v0.2 OQ7)**: **One-task-per-PCT — enforced vs convention.** Today (v1.0) one-task-per-PCT is *convention*; IBX does not reject multi-task PCTs at send. The Increment-2 ruling on per-session-credential scoping affects whether enforcement is feasible (session-scoped credentials make per-task auth tractable; identity-scoped credentials don't). Stays convention until the ruling lands.

**DR4 (CLOSED by Patton ruling at v1.0 review gate — see CD5 above)**: Resolved. The question "should v1.x extend required-validity to info priority?" is answered NO on the merits (Patton `b2b6a4e1`: *"Info has no task semantic — a stale info message read late is harmless. Requiring validity on info = ceremony with zero risk-reduction."*). Validity stays advisory for info; required for action/urgent (CD1 + CD5). This closure is independent of any Increment-2 session-expiry ruling — per-message PCT validity ≠ session-expiry semantics; those are different concerns.

**DR5 (deferred — was v0.2 OQ9 + v1.0 new substrate concern)**: **EPYC/TrueNAS migration plan + worker-pool substrate choice.** Two related deferrals: when IBX migrates from 9975WX-ClickHouse to the EPYC/TrueNAS production substrate, the contract must hold (zero-downtime cutover vs scheduled outage is a deployment decision). When the worker-pool case lands, the claim queue substrate (PostgreSQL with `FOR UPDATE SKIP LOCKED`, Redis Streams consumer groups, NATS JetStream consumer ack, etc.) needs a specific choice. Both live in the deployment-architecture doc, not this spec — but flagged here so the coupling is on the record. The Increment-2 ruling on session-vs-identity revocation semantics affects what the substrate must support (e.g., per-session-credential rotation has substrate consequences).

**DR6 (NARROWED by Patton ruling at v1.0 review gate — content deferred, migration discipline committed in CD6)**: **PCT v1 → v2 *content* deferred.** The *what fields, what semantics* of a v2 surface stays open pending Increment-2 rulings that may reshape the v1 surface (validity defaults, integrity contract, one-task enforcement). The *how a v2 migration is conducted* is committed now in CD6 above — coordinated migration, PCS-Daemon participates, no unilateral changes. Per Patton `b2b6a4e1`: this split protects against the exact coupling-churn risk Watson's stability concern targets, without front-running the v2 content design.

## Open Questions (genuinely open; not v0.2 carryovers)

**OQ-W1 (v1.0 new)**: **Lease duration default for worker-pool dispatch.** v1.0 commits the lease/visibility-timeout *mechanism* (§ Concurrency-Safe Worker-Pool Dispatch); it does not commit a default duration. Workload-specific (fast pools want short leases for crash-recovery throughput; slow pools want long leases to avoid duplicate execution). Suggestion: pool configuration carries the lease duration; substrate enforces. Open whether v1.x commits a per-archetype lease floor (e.g., Worker archetype minimum lease = 30 seconds; below that, crash-recovery becomes worse than letting the worker complete).

**OQ-W2 (v1.0 new)**: **Identity-vs-session storage encoding details.** v1.0 commits that the substrate tracks `(principal-id, session-id)` for claim attribution and per-session suspend; the specific column shape (separate columns vs composite key vs ULID with embedded principal) is a substrate-implementation detail. Open when Bob builds the worker-pool case and picks the substrate.

**OQ-W3 (v1.0 new)**: **Dead-letter queue retention.** v1.0 commits 3-attempt retry-then-dead-letter; doesn't commit how long dead-letter entries are retained. Operator policy; flagged here for the audit trail.

## Failure Modes To Watch

- **PCT contract churn.** The single biggest risk per Patton's directive. If field names or semantics change between v1.0 and v2, PCS-Daemon's design (in flight by Bob) churns with it. **Mitigation**: hold the v1.0 nine-field surface across review cycles; v1.x may add validation detail but may not rename or remove fields. Any name change to fields 1-9 triggers a coordinated v2-bump migration with PCS-Daemon participation. The axial split of fields 4 (scope) and 6 (authority bounds) is structurally load-bearing and must not collapse.
- **Stale PCT actioned after the authority that issued it has been revoked.** The async-credential-expiry anti-pattern (per Patton's `31b322a3` dialectical surfacing). A PCT with no `validity` (field 9) sitting in the queue can be actioned long after it's relevant — the same shape as a credential with no expiry. **Mitigation (v1.0 CD1)**: validity required at send for `action`/`urgent` priority; missing = send rejected. For `info` priority, recipients apply context-based staleness judgment until DR4 ruling lands. The mitigation is now structural at the send chokepoint, not advisory.
- **Judge-gate compromise.** If the Judge-side credential is leaked or weakened, the server-enforced approval gate collapses to a prompt-layer convention. **Mitigation**: today the gate is the ClickHouse user grant model; IAM-future is hardware-bound PIV/CAC. Until IAM lands, treat the `inbox-ui` credential as the lab's most sensitive non-ClickHouse-admin credential.
- **Identity-by-assertion drift.** Today the `sender` field is brief-asserted, not credential-verified. A compromised or misconfigured agent could send messages claiming to be another agent. **Mitigation**: this is the gap SOM's IAM pillar closes. Until IAM lands, the lab operates on cooperative trust + audit-after-the-fact; the design package and `SOM-PRODUCTION-VALIDATION.md` v1.1 IAM row name this gap explicitly.
- **PCT tampered in transit, recipient acts on modified instruction.** Today (cooperative bus, no signing) a PCT could in principle be modified between send and pickup — the bus is trusted-by-convention. **Mitigation**: v1.0 deliberately does not bake in an assumption of cryptographic trust (DR2 deferred-pending-IAM). PCS-Daemon and other consumers must treat the bus as cooperative-trusted, not cryptographically-trusted, until the IAM coupling (agent-DNA signature model) lands.
- **Drift toward trust-the-recipient on PCT validation.** The architecture's spine is no-bypass + fail-strict at every chokepoint. **Mitigation (v1.0 CD1)**: validate-at-send is committed. Drift toward trust-the-recipient now requires a v2 spec change with explicit Patton review; the spec body is no longer ambiguous about which side the chokepoint is on.
- **Substrate evolution breaking the contract.** Future migration from ClickHouse to PostgreSQL / NATS / RabbitMQ / Redis Streams (or to the EPYC/TrueNAS production substrate) must preserve the nine-field PCT, the priority semantics, the status workflow, the Judge-gate enforcement, and the worker-pool claim/lease/retry contract. **Mitigation**: the Exit Test (per `SOM-PROBLEM-STATEMENT.md` v0.5 §4) is the CLCA gate for substrate changes. Any substrate proposed for either IBX concern (routing audit vs claim queue) must be evaluated against this spec's contract before adoption.
- **Body-encoded PCT misparsing.** Because fields 2-6 live in markdown body, agents that don't follow conventional structure can produce messages PCS-Daemon's parser rejects or misinterprets. **Mitigation (v1.0 partial)**: v1.0 introduces structured columns for fields 7, 8, 9 (validation-critical meta fields) with fail-strict validation at send (CD1); fields 2-6 remain body-encoded but with a recommended structure template that IBX agents follow as convention. PCS-Daemon's defensive parsing handles non-conformant messages without crashing.
- **`info` priority abuse.** An agent could mark a Judge-decision-requiring message as `info` to bypass the approval gate. **Mitigation**: this is a behavioral failure, not a structural one — the server-enforced gate only fires on `action`/`urgent`. The lab's discipline (per CLAUDE.md "Agent Message Queue") is that `info` is for FYI/completion; misuse is caught at audit. The Increment-2 ITDR layer (when built — DR1) detects this pattern as behavioral anomaly.
- **Multi-task PCT collapsing recipient attribution.** A sender could pack multiple tasks into field 2, making audit attribution ambiguous (which sub-task did the recipient act on; which was rejected; which is still in-progress). **Mitigation**: v1.0 documents one-task-per-PCT as convention (DR3 deferred-pending-Increment-2-ruling on per-session-credential scoping). Today the discipline is enforced socially through review rather than at send.

**Concurrency-related failure modes (v1.0 new — from worker-pool dispatch)**:

- **Stale claim from crashed worker (lease expiry).** A worker session crashes mid-execution while holding a claim; its `lease-expires-at` eventually fires and the PCT becomes re-claimable. **Mitigation (v1.0 commitment)**: the lease/visibility-timeout mechanism (§ Concurrency-Safe Worker-Pool Dispatch #2) guarantees crash recovery without manual intervention. Lease duration default is OQ-W1; deployments specify per-pool until a default lands.
- **Double-execution from idempotency-key collision.** A worker completes its PCT but crashes before recording `done`; lease expires; another worker re-claims and re-executes. **Mitigation (v1.0 commitment)**: the `idempotency-key` field on PCT (§ Worker-Pool Dispatch #4) is carried through to downstream writes; recipients use it for `INSERT IF NOT EXISTS` semantics at destination sinks. Double execution at the IBX layer is detected as duplicate-state at the destination, not as duplicate-claim at the queue.
- **Lease-expiry race between in-flight worker and re-claiming worker.** A worker is finishing its action exactly as the lease expires; a second worker claims; both may attempt to record `done`. **Mitigation**: the `done` transition is gated on the worker's `session-id` matching the substrate's current claim holder; mismatched session loses (its `done` write is rejected at the substrate). The first-to-update-with-matching-session wins; the other worker's writes are routed to a conflict log for audit. Exact mechanism depends on substrate choice (DR5).
- **Mid-action termination leaves orphan side effects.** A worker is suspended/terminated mid-action while holding a claim. The PCT returns to queue per § Worker-Pool Dispatch #3, but the worker may have already written partial state to downstream sinks. **Mitigation**: the `idempotency-key` discipline applies — re-execution by another worker writes the same key, so partial state is detected and reconciled at the destination. This is a *recipient discipline*, not an IBX guarantee; v1.0 commits the contract that enables it (stable idempotency-key on PCT) but cannot enforce destination-side reconciliation.
- **Worker-pool starvation under pool of one identity, broad cap.** If a worker pool runs with N=1 and the single worker is suspended for investigation, the entire identity's work backlog stalls. **Mitigation**: this is an operational concern (pool sizing), not an IBX contract issue. Flagged for the operator setting up the pool. The Increment-2 ruling on per-identity concurrency cap (per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §1, §7) informs operational defaults.
- **Quorum-archetype mis-paired with worker-pool dispatch.** A future operator could attempt to route quorum work through the worker-pool dispatch pattern — `recipient=pool:quorum-voter` would produce N sessions of one identity claiming exactly-once, which is *not* the quorum semantic (quorum requires N distinct identities reasoning over the same unit, per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §3). **Mitigation**: worker-pool dispatch is for the **Worker archetype** only. Quorum dispatch is a separate pattern that v1.0 does not define (no current implementation need); when it lands, it is N distinct point-to-point sends with consensus aggregation at the coordinator, not exactly-once claim. The PROBLEM-STATEMENT §2 archetype determines pattern (no orthogonality) framing prevents this mis-pairing structurally.

## Dependencies

- **`shared-context/agent-message-queue.sql`** — the ClickHouse DDL that defines the v0.2 storage substrate. Source of truth for column schema, grant model, latest-state view definition.
- **`agent-inbox-mcp`** (private repo, not on PyPI) — the MCP server implementing the six-tool surface (`inbox_check`, `inbox_read`, `inbox_send`, `inbox_mark`, `inbox_search`, `get_version_info`). Behavior contract documented in its README + CLAUDE.md "Agent Message Queue" section.
- **`inbox-ui`** (private repo, Wails/Go/Svelte desktop app) — the Judge-only path for `approved`/`rejected` status transitions. Holds the server-enforced gate credential.
- **`SOM-PILLAR-NAMES.md`** v1.1 — pillar bindings of record; IBX is the names-of-record entry this spec backs.
- **`SOM-PROBLEM-STATEMENT.md`** v0.5 — design drivers, including §2 Singleton/Instance Asymmetry, §6.3 PCT-as-message-schema (locked decision to live in IBX), §0 Control Plane placement.
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — IBX row records production status (Pillar #2, fully validated); this spec is the formal contract that production verification rests on.
- **`SOM-IDENTITY-PILLAR-DESIGN.md`** + **`SOM-INSTANTIATION-AND-IDP.md`** — the IAM pillar design IBX integrates with when IAM is built. The `principal-id` field (PCT #1) is the integration seam.
- **`PCS-REGISTRY-FOLD-IN.md`** v1.3 — the PCS-Lifecycle Harness + Daemon split; PCS-Daemon is the primary downstream consumer of this spec's contract.
- **`CLAUDE.md`** "Agent Message Queue" section — operational reference; what this spec formalizes was previously documented only there.

## Acceptance Criteria

Per the pillar-spec template (`planning/PILLAR-SPEC-TEMPLATE.md` — five non-negotiables given equal weight to security). IBX is not validated until all five hold; below them, the IBX-specific acceptance bars from v1.0 (renamed from § Success Criteria) are preserved as additional pillar-specific evidence.

### Five non-negotiables (template-mandated, equal weight to security)

1. **Secure.** `agent-inbox-mcp` follows the security framework (`planning/MCP-SECURITY-FRAMEWORK.md`): credentials in OS keyring only, no `subprocess`/`shell=True`/`eval`/`exec` on user input, HTTPS to any external surface, parameterized queries to ClickHouse/PG (no SQL string interpolation), input validation on PCT body fields, rate limiting on `inbox_send`. The Judge-gate credential held by `inbox-ui` is the lab's most sensitive non-ClickHouse-admin credential and is handled accordingly. **Measure**: `test_security.py` passes in CI; manual audit before any release confirms no credential leakage in tool results, logs, or error messages.

2. **Instrumented-by-default.** `agent-inbox-mcp` emits the spans + metrics + log events in § Telemetry Contract via OTLP to the customer-selected `OTEL_EXPORTER_OTLP_ENDPOINT`. Mandatory, not "should be considered" — a pillar without OTLP traces + metrics is not finished, because ACT (chargeback) can only meter what pillars emit. **Measure**: an OTel Collector receiving from `agent-inbox-mcp` observes traces with the named span set (`som.ibx.message.send`, `som.ibx.judge.gate.fire`, etc.) and the metric set (`som.ibx.message.depth`, `som.ibx.judge.gate.pending`, etc.); integration test exercises each tool and asserts the corresponding span appears.

3. **JSON logs.** `agent-inbox-mcp` emits structured JSON logs to stderr with the required keys (`timestamp`, `level`, `message`, `service.name`, `service.version`, `trace_id`, `span_id`, `identity`, `session`) per SOM-MI-11. Trace correlation via `trace_id` + `span_id` is mandatory. stdout is reserved for the MCP protocol channel. **Measure**: parsing `agent-inbox-mcp` stderr in CI confirms every line is valid JSON with all required keys; `trace_id` from a log line cross-references a span in the OTLP traces emitted in the same operation.

4. **CLI-first / UI-second.** The six MCP tools (`inbox_check`, `inbox_read`, `inbox_send`, `inbox_mark`, `inbox_search`, `get_version_info`) are the canonical surface for every management function — they are the CLI/API equivalent and exist before any UI. `inbox-ui` (Wails/Go/Svelte desktop app) is a *thin client* of the same authorization-enforced surface, never a privileged path that bypasses the MCP tool layer. Future MCC panes render the MCP/CLI surface; they do not introduce new privileged operations. Build order: function → MCP tool → headless validation → wire `inbox-ui` or MCC pane. **Measure**: any management operation accessible from `inbox-ui` is reachable headless via an MCP tool call with the same authorization gate firing; no `inbox-ui`-only operation exists.

5. **Audit emission.** Every state-affecting operation (`send`, `mark`, judge-gate `approved`/`rejected`, worker-pool `claim`/`complete`/`deadletter`) emits an accountability event per SOM-MI-1. Path A (until `#22` resolves to Path B): events are emitted directly to the MI-1 stream with `identity`, `session`, `operation`, `outcome`, `timestamp` + PCT-specific fields. Path B: `agent-inbox-mcp` calls ACT during the critical path of each state-affecting operation; ACT-unavailable handling per the per-pillar CD (block, fail, or buffer). The author of the implementing build checks `#22` state and uses whichever path is current. **Measure**: audit query against the MI-1 stream after a representative operation set (one send, one mark, one Judge approve, one worker-pool claim+complete cycle) confirms every state mutation has a corresponding audit event with the required fields.

### Additional IBX-specific acceptance bars (preserved from v1.0)

- **PCT nine-field contract is citable and stable.** PCS-Daemon's design references this section without needing to invoke a future fold-in for clarification. **Measure**: PCS-Daemon's design spec (Bob's draft, spec-campaign item 4) cites IBX-SPEC v1.0 § PCT and depends on no fields outside the nine, and does not depend on the scope/authority bounds being collapsed.
- **Patton dialectical review pass at v1.1.** Single review gate per the simplified workflow (per `feedback_spec_workflow_simplified`). **Measure**: Patton's sign-off comment on the v1.1 review gate (GH-native per the 2026-06-02 PR-review convention).
- **Substrate-swap survives the contract.** When IBX migrates from 9975WX-ClickHouse to EPYC/TrueNAS production substrate (DR5), the nine-field PCT, priority semantics, status workflow, server-enforced Judge gate, and worker-pool claim/lease/retry contract all hold without spec revision. v1.1 adds the substrate matrix as the substitutability boundary; the migration evidence is the multi-profile conformance run passing across the matrix rows per SOM-CD15. **Measure**: the migration deployment doc references this spec's contract as the invariant the substrate transition must preserve, and the conformance run passes against the new sovereign-reference column.
- **`info` vs `action`/`urgent` discipline holds in audit.** No agent self-acts on `action` or `urgent` work without an `approved` status transition recorded in `messages.inbox`. **Measure**: spot-check audit query against `messages.inbox` shows zero `action`/`urgent` messages with downstream commits before `approved` timestamp.
- **Validity-enforcement holds at send (v1.0 CD1).** Action/urgent PCTs without explicit `validity` are rejected at `inbox_send` time. **Measure**: audit query against `messages.inbox` shows zero action/urgent rows with NULL validity after v1.0 substrate change lands; for the pre-v1.0 audit-trail-only-substrate state, recipients have applied context-based staleness judgment without incident.
- **Worker-pool claim contract testable.** When the worker-pool case lands (Bob's PCS-Daemon work or future document-processing workers), the exactly-once claim, lease/retry, idempotency-key, and mid-action-safe-termination contract is testable end-to-end. **Measure**: integration test in the implementing repo exercises crash recovery (kill worker mid-claim, verify PCT returns to queue after lease expiry) and retry exhaustion (claim N+1 times, verify dead-letter on attempt N+1).
- **No mis-pairing of archetype with dispatch pattern.** Worker archetype routes through `pool:<identity>`; Quorum archetype does NOT use `pool:` (would destroy independence). **Measure**: code review on any new dispatch usage cites the archetype + pattern correctly, with explicit reference to `SOM-CONCURRENCY-AND-ARCHETYPES.md` §2 archetype-determines-pattern coupling.

## References

- `planning/SOM-SPEC.md` — mesh-level invariants this pillar instantiates (SOM-MI-8 substrate substitutability, SOM-MI-11 telemetry contract, SOM-CD9 cross-pillar substrate substitutability, SOM-CD15 conformance-enforced substrate-neutrality, § Tested Substrate Profiles named substrate set). **v1.1 source for the per-pillar manifest layer.**
- `planning/PILLAR-SPEC-TEMPLATE.md` — pillar-spec template that v1.1 instantiates (10 required sections, Substrate Matrix + Telemetry Contract section structures, 5 non-negotiables). IBX-SPEC v1.1 is the first instantiation.
- `planning/MCP-SECURITY-FRAMEWORK.md` — security framework referenced by Acceptance Criterion 1 (Secure)
- `planning/SOM-PILLAR-NAMES.md` v1.1 — pillar bindings of record
- `planning/SOM-PROBLEM-STATEMENT.md` v0.6 — design drivers (§0, §2 with concurrency archetype-determines-pattern coupling, §6.3, §4 Exit Test)
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — production validation record
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` v0.1 — concurrency model (identity-vs-session), three archetypes (worker/reasoner/quorum), confidence-aggregation, label-oracle four hard rules. **v1.0 source for the identity-vs-session distinction and worker-pool dispatch contract.**
- `planning/SOM-IDENTITY-PILLAR-DESIGN.md` — IAM pillar design (provisional, briefs-only implementation)
- `planning/SOM-INSTANTIATION-AND-IDP.md` — IAM onboarding + login flow (provisional)
- `planning/PCS-REGISTRY-FOLD-IN.md` v1.3 — PCS three-layer anatomy + Lifecycle Daemon scope
- `shared-context/agent-message-queue.sql` — ClickHouse DDL for `messages.inbox` (v1.0 routing-audit-trail substrate)
- `CLAUDE.md` "Agent Message Queue" — operational reference predating this spec
- Issues `KI7MT/som-spec#10` (this v1.1 refresh), `KI7MT/som-spec#6` + `#24` (template that this spec instantiates)
