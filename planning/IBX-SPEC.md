---
title: "IBX Spec — Inbox Exchange Message Routing Substrate"
doc_type: spec
status: draft
version: v0.2
authors:
  - watson
  - patton
date: "2026-06-01"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/PCS-REGISTRY-FOLD-IN.md
  - shared-context/agent-message-queue.sql
---

# IBX Spec — Inbox Exchange Message Routing Substrate

**Scope**: Formalizes the contract IBX (Inbox Exchange) satisfies as the Control-Plane message routing substrate of SOM. Covers the PCT (Principal Control Token) nine-field schema, message routing rules, status workflow, the Judge-approval gate, the storage substrate, and the coupling boundaries with PCS-Lifecycle and SOM's IAM pillar.

**Status**: Draft v0.2 — fold-in stream applied in two passes. Pass 1 (Patton dialectical review `31b322a3`): scope/authority-bounds sharpened to keep them axially separate (access-control vs decision-rights, not collapsed); a ninth PCT field `validity` added to close the no-expiry anti-pattern Patton flagged (the async equivalent of a credential with no expiry — the failure mode SOM's IAM pillar exists to prevent); the v0.3 body-encoded vs structured-columns deferral reframed as the underlying validate-at-send-fail-strict vs trust-the-recipient question (with the leaning explicit so v0.3 doesn't drift toward trust-the-recipient); the PCS-Daemon coupling deferred-side over-listed; two new Open Questions added (PCT integrity/tamper-evidence, one-task-per-PCT enforced-vs-convention). Pass 2 (Bob no-overclaim + coupling-boundary review `60856a8d` and `637b1519`): the Judge-approval gate enforcement layer corrected from "schema-enforced" / "storage-layer" to **MCP-server-layer (code, not prompt)** — ClickHouse GRANTs are table/column-level, not value-level, so the schema-layer claim was inaccurate; the actual enforcement is `agent-inbox-mcp` code refusing to write `approved`/`rejected` for any agent caller; added the explicit security-claim limit that a direct-DB caller with the `inbox` credential is not schema-blocked, which is exactly why the IAM hardening matters and is consistent with the bus being named "cooperative-trusted, not cryptographically-trusted" elsewhere. Bob's `message_id`-stable + status-queryable-per-`message_id` clause added to the PCS-Daemon "may rely on" list — his send/poll integration pattern depends on the correlatability commitment. Patton greenlit drafting in `5fd105cd` (2026-06-01) with the discipline directive *"keep the PCT message contract stable across review cycles, because PCS-Daemon ↔ IBX coupling means your churn becomes Bob's churn."* The nine-field PCT surface committed in this version is the surface PCS-Daemon may build against; v0.3+ may add validation detail but may not rename or remove fields. Patton's v0.2 fold-in acknowledged in `637b1519` as clean ("v0.2's Patton fold lands clean"); Bob's two flags now folded in this pass. Pending Einstein review (Patton flagged not currently required) and Judge merge.

## Purpose / Problem Restatement

IBX (Inbox Exchange) is the Control-Plane message routing substrate that carries every async hand-off between SOM agents and every Judge-approval gate. It is the hub that PCS, PGE, CRB, and Judge route *through* to reach Workforce — the structural reason PCT (Principal Control Token) lives in IBX rather than in PCS scope. Today IBX is **POC-in-production**: the runtime substrate (`agent-inbox-mcp` server + `inbox-ui` Wails desktop app + `messages.inbox` ClickHouse table on 9975WX) is operational and used daily for Watson/Bob/Patton/Einstein hand-offs and Judge approvals. The pillar has no formal spec — `SOM-PILLAR-NAMES.md` v1.1 records its Spec column as *"Pending dedicated spec; behaviors documented in CLAUDE.md 'Agent Message Queue' + agent-inbox-mcp README."* This document closes that gap.

The load-bearing question this spec answers: **what contract must IBX hold across substrate evolution** so that downstream consumers (PCS-Daemon, IAM-when-built, the Increment-2 active-security model) can build against a stable surface? The substrate may evolve (DAC ClickHouse today → EPYC/TrueNAS per the PCS-Registry deployment plan); the contract must not. The spec formalizes what is already true (the nine-field PCT, the priority semantics, the server-enforced Judge gate) so that "what IBX guarantees" stops being implicit and starts being citable.

This is also Patton's risk #2 from the two-week roadmap: PCS-Daemon ↔ IBX coupling. If the PCT contract churns mid-cycle, Bob's PCS-Daemon design churns with it. A stable v0.2 contract de-risks the PCS Daemon build that follows AKB Phase-1.

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

2. **IBX consumes from SOM's IAM pillar (when IAM is built).** Currently the `sender` field in `messages.inbox` is asserted by brief — identity-by-brief, not identity-by-credential. Once SOM's IAM pillar (per `SOM-IDENTITY-PILLAR-DESIGN.md`) is built, every IBX message becomes signed by the sender's agent-DNA (private key) and verifiable against the public-key fingerprint in the Roster. The PCT `principal-id` field (defined below) is the seam where that verification happens. v0.2 names the seam; the verification commit lands when IAM does.

### The PCT (Principal Control Token) — nine-field contract

PCT is the message-from-Principal-to-Singleton artifact that the Singleton/Instance Asymmetry (per `SOM-PROBLEM-STATEMENT.md` v0.5 §2) makes load-bearing. Every IBX message carries a PCT in its body, structured or implicit. v0.2 commits the nine-field surface; **field names and semantics are stable across review cycles** — v0.3+ may add validation detail but may not rename or remove fields.

The nine fields divide cleanly into three groups:

- **Identity / work (1-3)**: who sent it, what they want done, the background to do it.
- **Boundary axes (4-6)**: the three orthogonal axes that constrain the work — **reach** (scope), **completion criterion** (success criteria), **autonomy** (authority bounds). Scope and authority bounds are axially distinct (per Patton dialectical review `31b322a3`): scope answers *what may I touch*, authority bounds answers *what may I decide without asking*. The spec keeps them split because conflating them muddles the IAM-coupling seam (scope ties to job-code authz) with the Judge-gate seam (authority bounds ties to approval). Prose must not let one creep into the other's territory.
- **Meta (7-9)**: properties of the PCT itself, not its content. Version, provenance, validity window — the machine-validated fields a future structural-validation pass will live in.

| Field | Type | Purpose |
|---|---|---|
| **1. principal-id** | string (agent_id) | Sender identity. Today brief-asserted (the agent claims to be "Patton" because the briefing says so); IAM-future credential-verified (signed with agent-DNA private key, verified against Roster-published public-key fingerprint). Seam into SOM's IAM pillar — `principal-id` is *the* field IBX/IAM coupling lands on. |
| **2. task** | string | The atomic unit of work being requested. Imperative form ("review PR #56", "draft IBX-SPEC"). One task per PCT — **today this is convention, not enforced**; IBX does not reject multi-task PCTs at send. Open Question 7 names whether v0.3+ enforces. Chained work uses separate PCTs linked via field 8 `audit`. |
| **3. context** | markdown | Background the recipient needs to act. Includes prior decisions, current state, file paths, commit hashes. Bounded length — if context exceeds a screenful, link rather than embed. |
| **4. scope** | enum + string | **Access-control axis: what data, files, repos, or resources the recipient may ACT ON.** Answers "what may I touch." Today expressed in prose, bounded informally by the recipient's role brief; IAM-future ties directly to the recipient's job-code authorization policy and becomes machine-enforced. Do NOT use this field to express decision-rights — that is field 6. |
| **5. success criteria** | bulleted list | How the recipient (and the next reviewer) knows the task is done. Each criterion is measurable or verifiable. No "vibes-based" criteria. |
| **6. authority bounds** | enum + string | **Decision-rights axis: what the recipient may decide UNILATERALLY vs. must escalate to the Judge gate.** Answers "what may I decide without asking." A task may be entirely *in scope* (the recipient is authorized to touch the resources) yet require Judge approval to *act* (the decision exceeds unilateral autonomy). Criteria that exceed bounds route through the Judge-approval gate via priority `action` or `urgent`. Do NOT use this field to express access — that is field 4. |
| **7. version** | string (semver-like) | PCT contract version this message conforms to. v0.2 contracts are tagged `pct-v1` (PCT v1 surface is what this spec commits). v0.3+ may add fields but not break v1 readers. |
| **8. audit** | structured | Provenance — who originated the PCT, when, in response to what (prior message_id, prior commit hash, prior PR number). The chain that lets a reviewer reconstruct *why* the task was requested. PCT integrity in transit (tamper-evidence) is a future concern (Open Question 6); v0.2 does not commit signing. |
| **9. validity** | timestamp (`not-after`) | **Expiry window — when the PCT becomes stale and recipients must not act on it.** Patton flagged the no-expiry gap (`31b322a3`): a PCT outliving the authority that issued it is the async equivalent of a credential with no expiry — the exact anti-pattern SOM's IAM pillar exists to prevent. Today expressed as a deadline timestamp in the body for action-priority messages; v0.3+ will likely promote this to a structured column. **Default behavior** if `validity` is unset on send: PCTs do not auto-expire, but recipients *must* check the originating context for staleness signals (a task referencing PR #56 after PR #56 merged is implicitly stale). The expiry field exists so that *explicit* validity windows become first-class; v0.3 may move toward default-expiry-required for action-priority. |

**Stability commitment**: PCS-Daemon may build a `pct-v1` consumer against this nine-field surface. Future PCT contract changes (v2 onwards) must preserve v1-field compatibility — new fields may be added; existing fields may not be renamed, retyped, or have semantics altered without a coordinated v2-bump migration that PCS-Daemon participates in. The axial split of scope/authority bounds in particular is structural: collapsing them in any future version would muddle the IAM-coupling and Judge-gate seams.

**Today's encoding**: PCT structure is **implicit** in the inbox-message body (markdown). The `sender`, `recipient`, `priority`, `subject` columns of `messages.inbox` encode fields 1, 4 (partial), 6 (partial). Fields 2, 3, 5, 7, 8, 9 live in the body. v0.3 will likely add explicit structured columns for fields 7, 8, and 9 (the machine-validated meta fields) to enable schema-level validation at send time. v0.2 specifies the contract; the storage encoding evolves under it.

**Validation-at-send vs trust-the-recipient — the underlying decision the v0.3 encoding choice rests on**: the real question for v0.3 is not "where does PCT structure live in storage" but "does IBX validate machine-critical PCT structure at send time (fail-strict on malformation) or trust recipients to parse and decide?" Per the architecture's spine (no-bypass + fail-strict at every chokepoint), the v0.2 leaning is **validate machine-critical fields at send, fail-strict on malformation, especially fields 7, 8, 9 (the meta fields)**. Fields 2-6 remain body-encoded for human readability; fields 7-9 are candidates for structured columns + validation at send in v0.3. Flagging this leaning explicitly so v0.3 does not drift toward trust-the-recipient — that drift would contradict the spine.

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

### Judge-approval gate (MCP-server-layer enforced, code-not-prompt, non-substitutable)

The Judge-approval gate is a first-class architectural element of SOM (per `SOM-TECHNICAL-OVERVIEW.md` v0.2 § Control Plane). IBX enforces it at the **MCP-server layer (code, not prompt)** — not at the schema layer. The precise mechanism (per Bob's `60856a8d` no-overclaim review):

- The `agent-inbox-mcp` server **refuses to write** the values `approved` or `rejected` for any agent caller — this is application-layer code, not a prompt-layer convention. Calls that attempt those status transitions are rejected at the server before reaching ClickHouse.
- The `inbox-ui` Wails app (Judge's desktop tool) is the **only** path that writes `approved` or `rejected`, and it does so under a separate Judge-side credential.
- The ClickHouse user `inbox` (the credential `agent-inbox-mcp` uses) holds grants on `messages.inbox` for `SELECT` and `INSERT`. ClickHouse GRANTs are **table/column-level, not value-level** — there is no schema-level way to grant "INSERT status ∈ {`read`, `in_progress`, `done`} but not {`approved`, `rejected`}" to a user. Code-level enforcement in the MCP server is the working substitute.

**Important security-claim limit, stated plainly**: a caller holding the `inbox` credential and talking to ClickHouse *directly* (bypassing the MCP server) is **not** schema-blocked from writing `approved` or `rejected`. The protection holds because (a) agents reach `messages.inbox` only through the `agent-inbox-mcp` chokepoint, (b) the chokepoint is application-layer code Watson/Bob review on every commit, and (c) audit captures any out-of-band writes. This is **stronger than prompt-layer convention but weaker than cryptographic enforcement** — which is exactly why the IAM-future hardening (signed messages + hardware-bound Judge credential) matters. The same gap is the reason the bus is named "cooperative-trusted, not cryptographically-trusted" elsewhere in this spec; the two framings are consistent.

The contract IBX commits to: **no action-priority work begins until the gate fires through the inbox-ui code path**, and the gate cannot be bypassed without compromising the Judge-side credential *or* the application-layer MCP server. Both are sensitive surfaces; the IAM build elevates both.

### Storage substrate (current and substitutable)

**Current substrate**: ClickHouse `messages.inbox` on 9975WX. Columns approximately:
- `id` (UUID), `timestamp`, `sender`, `recipient`, `priority`, `subject`, `body` (markdown), `status`, plus provenance columns (`originating_message_id`, `originating_commit_hash`).
- DDL canonical at `shared-context/agent-message-queue.sql`.
- Append-mostly; latest-state view materializes current status per `id`.
- LZ4 compression on disk; ZFS pool `data-pool/clickhouse`.

**Substitutable substrate** (Exit Test pass): Kafka, RabbitMQ, Redis Streams, or any message-queue substrate that supports:
1. Persistent message storage with content-addressable identifiers
2. Append-mostly status mutation (or equivalent state machine)
3. Schema-enforced authorization (which credential can write which status)
4. Tooling for the equivalent of the six MCP tool surface (`check`, `read`, `send`, `mark`, `search`, `get_version_info`)

The Exit Test discipline (per `SOM-PROBLEM-STATEMENT.md` v0.5 §4) requires the contract to hold across substrate swap. The PCT contract, the priority semantics, the status workflow, and the Judge-gate enforcement are substrate-agnostic; ClickHouse is the v0.2 implementation, not the contract.

### Coupling boundary: PCS-Daemon ↔ IBX

PCS-Daemon (per `PCS-REGISTRY-FOLD-IN.md` v1.3 §Lifecycle) is the registry-side service that wraps the `pcs-control-plane` Harness and integrates with IBX for the Judge-approval gate during plugin promotion. The coupling boundary IBX commits to:

**What PCS-Daemon may rely on from IBX (v0.2 — `pct-v1` contract surface)**:
- The nine-field PCT contract is stable across review cycles (Patton's discipline directive in `5fd105cd`). Field names and semantics are not renamed or retyped without coordinated v2-bump migration.
- The axial split of scope (#4, access-control) and authority bounds (#6, decision-rights) holds — PCS-Daemon may rely on these being two distinct fields, not a collapsed one, because the IAM-coupling and Judge-gate seams depend on the distinction.
- The priority semantics (`info` / `action` / `urgent`) and the status workflow (`unread → read → approved → in_progress → done` or `rejected`) are stable.
- The server-enforced Judge-approval gate fires for any `action`-priority message regardless of sender; PCS-Daemon emits its promotion approval requests at `action` priority and trusts IBX to gate them.
- **`message_id` is stable, and status is queryable per `message_id`** (per Bob's `60856a8d` coupling-boundary addition). PCS-Daemon's promotion pattern is *send `action`-priority request → poll for the Judge's `approved`/`rejected` by `message_id`*; this commitment is what makes the send/poll loop correlatable. Implied by the per-message-id latest-state view materialized over `messages.inbox`, committed explicitly here so PCS-Daemon's build may depend on it.
- The substrate is reachable from PCS-Daemon's deployment host (EPYC/Proxmox VM today routes to IBX-on-9975 via DAC `10.60.2.0/24`; production target is co-located on EPYC/TrueNAS).

**What PCS-Daemon may NOT rely on from IBX (v0.2) — over-listed deliberately so the unstable side is at least as detailed as the stable side, per Patton's dialectical review (`31b322a3`)**:
- **PCT malformation detection at send time** — v0.2 does not commit a normalization or rejection contract; PCS-Daemon must defensively validate PCT structure before acting on a received message. The v0.3 leaning is fail-strict at send for fields 7-9, but until v0.3 commits this, do not assume IBX has rejected anything malformed.
- **Schema-level PCT validation columns** — v0.2 PCT structure is body-encoded for fields 2, 3, 5, 7, 8, 9 (fields 1, 4 partial, 6 partial are encoded in storage columns). PCS-Daemon must parse the message body for the meta fields; do not assume structured columns.
- **PCT integrity / tamper-evidence in transit** — v0.2 does not commit signing or tamper-detection (Open Question 6). PCS-Daemon should treat the bus as cooperative-trusted, not cryptographically-trusted, until the IAM coupling (agent-DNA signature model) lands.
- **Validity-field enforcement** — v0.2 adds field 9 (`validity`) to the contract surface but does not enforce its presence or its semantics at send. PCS-Daemon should treat the field as advisory in v0.2; if a PCT has no `validity`, recipients including PCS-Daemon must apply context-based staleness judgment (Open Question 8). v0.3+ may move toward default-expiry-required for action-priority messages.
- **One-task-per-PCT enforcement** — v0.2 documents one-task-per-PCT as convention, not enforced at send (Open Question 7). PCS-Daemon must not assume a received PCT contains a single task; defensive parsing of field 2 should handle the multi-task case gracefully even if the convention is followed in practice.
- **Future PCT v2 forward-compatibility guarantees** — v0.2 commits the `pct-v1` surface only. When v2 is proposed, PCS-Daemon participates in the coordinated migration; until then, do not pre-build for hypothetical v2 fields.
- **Round-trip-time guarantees on the Judge gate** — v0.2 does not commit a latency contract. PCS-Daemon's design must tolerate that Judge approval may take seconds, minutes, or hours, depending on operator availability.
- **Cross-substrate behavior under EPYC/TrueNAS migration** — v0.2 commits the contract holds across substrate change but does not commit the migration timing or the cutover semantics. PCS-Daemon's design should be substrate-agnostic by adhering only to this spec's contract, not to ClickHouse-specific behavior of the current implementation.

**The Watson↔Bob coordination discipline this implies**: any time IBX-SPEC version changes a clause in either table above, Bob is notified via inbox `info` before the PR opens — the may-rely-on table changing reduces what Bob can build against; the may-NOT-rely-on table changing means something Bob was holding off on may now be available. Patton dialectical review at each gate (Patton's directive). PCS-Daemon's design assumptions live in its own spec and are cross-checked against this section at every IBX-SPEC version bump.

### Coupling boundary: IAM (future) ↔ IBX

When SOM's IAM pillar is built (per `SOM-IDENTITY-PILLAR-DESIGN.md`), IBX integrates as follows:

- Every IBX message becomes **signed** by the sender's agent-DNA (private key) at `inbox_send` time.
- The PCT `principal-id` field is verified against the sender's signature and the Roster-published public-key fingerprint.
- The `sender` column of `messages.inbox` is no longer brief-asserted — it is the principal authenticated against ARCA-issued identity.
- The Judge-side credential used by `inbox-ui` becomes a real human credential (PIV/CAC, hardware-bound) rather than the current ClickHouse-user-grant model.
- The server-enforced gate persists; the credential model underneath gets stronger.

**v0.2 commits to naming this seam, not to building it.** The IAM pillar is design-stage, briefs-only — the current state per the v1.1 validation doc. Until IAM lands, IBX runs on identity-by-brief; this is honest, documented, and consistent with the rest of SOM's design-vs-implementation discipline.

## Open Questions

These are deferred to v0.3+ deliberately — naming them keeps the spec disciplined without committing to answers before the dialectical engine has surfaced them. v0.2 expanded the list from seven to ten per Patton's dialectical review (`31b322a3`), which surfaced the three the original draft missed (integrity/tamper-evidence, one-task-enforcement, validity-default-policy).

1. **Validate-at-send-fail-strict vs trust-the-recipient — the underlying decision the v0.3 encoding choice rests on.** v0.2 named this as the *real* question underneath the body-encoded vs structured-columns deferral (per Patton's reframing). The leaning is explicit: **validate machine-critical fields (7, 8, 9) at send, fail-strict on malformation; body-encode fields 2-6 for human readability.** v0.3 should commit this — drift toward trust-the-recipient would contradict the architecture's no-bypass + fail-strict spine. Open: what specific structural rules does IBX run at send for fields 7-9? (Required-field presence is the floor; full schema validation is the ceiling.)
2. **PCT malformation detection rules — specific surface.** v0.2 names the surface (PCS-Daemon must defensively validate); v0.3 should commit the specific rules IBX runs at `inbox_send` time. Recommendation: **lightweight required-field check at send (fail-strict), full semantic validation delegated to recipient.** Tied to Open Question 1.
3. **PCT v1 → v2 migration policy.** Premature in v0.2; we don't have a v2 yet. Open when v2 is proposed.
4. **ITDR-over-ACT integration.** Per Patton's Increment-2 (`52d336a9` + `0d6e48fa`), an ITDR (Identity Threat Detection and Response) layer reads IBX message patterns from ACT telemetry for behavioral anomaly detection. v0.2 does not commit this integration; it depends on (a) Increment-2 settling the seven Judge rulings, (b) ACT pillar spec landing. Open when both ship.
5. **Broadcast semantics — multi-recipient PCT vs broadcast announcement.** v0.2 supports `all` as a broadcast recipient. Open: should broadcasts carry PCT structure (and if so, what does `task` mean when no specific recipient is committed?) or should `all` be reserved for announcements that explicitly do not carry actionable task structure? Recommendation: **`all` is for announcements, not PCT-bearing tasks.** Tasks address a specific recipient.
6. **PCT integrity / tamper-evidence in transit.** Per Patton's flag in `31b322a3`: today (brief-asserted, cooperative) PCT integrity does not matter; the bus is trusted-by-convention. When SOM's IAM pillar lands and PCTs are signed by sender agent-DNA, integrity becomes verifiable in transit. **v0.2 deliberately does not bake in an assumption that PCTs are trustworthy-as-received** — a future reader must not infer that the bus is cryptographically-trusted today. Open: when does IBX commit a signing contract? Recommendation: **at the same gate IAM moves from briefs-only to operational** — the two seams land together.
7. **One-task-per-PCT — enforced vs convention.** Per Patton's flag in `31b322a3`: v0.2 documents one-task-per-PCT as convention (recipients are trusted to honor); IBX does not reject multi-task PCTs at send. Open: does v0.3+ enforce one-task fail-strict, or does it stay convention? Recommendation: **stay convention for v0.3; promote to fail-strict only if audit surfaces multi-task abuse**. Forcing the rule before evidence justifies it would burden routine hand-offs without clear benefit.
8. **Default behavior when `validity` (field 9) is unset.** v0.2 commits the field but does not enforce its presence; the default is "no auto-expiry, recipients apply context-based staleness." Open: does v0.3+ move toward default-expiry-required for `action`/`urgent` priority? Recommendation: **yes — action/urgent without explicit `validity` should be a v0.3 fail-strict at send.** The async-credential-expiry analogy Patton drew makes this the right discipline; `info` priority can remain default-no-expiry.
9. **EPYC/TrueNAS migration plan.** When IBX migrates from 9975WX-ClickHouse to the EPYC/TrueNAS production substrate, the contract must hold. Open: zero-downtime cutover or scheduled outage with audit-trail preservation? Lives in the deployment-architecture doc, not this spec — but flagged here so the coupling is on the record.
10. **Field-name convention — `principal-id` vs `principal_id` vs `from`.** v0.2 uses `principal-id` (hyphenated, matches "Principal Control Token"). Open for v0.3 if the canonical field-name convention should be snake_case (for storage-column compatibility) or camelCase. Tied to Open Question 1 — when fields move to columns, naming matters.

## Failure Modes To Watch

- **PCT contract churn.** The single biggest risk per Patton's directive. If field names or semantics change between v0.2 and v0.3, PCS-Daemon's design (in flight by Bob) churns with it. **Mitigation**: hold the v0.2 nine-field surface across review cycles; only add validation detail in v0.3+. Any name change to fields 1-9 triggers a coordinated v2-bump migration with PCS-Daemon participation. The axial split of fields 4 (scope) and 6 (authority bounds) is structurally load-bearing and must not collapse.
- **Stale PCT actioned after the authority that issued it has been revoked.** The async-credential-expiry anti-pattern (per Patton's `31b322a3` dialectical surfacing). A PCT with no `validity` (field 9) sitting in the queue can be actioned long after it's relevant — the same shape as a credential with no expiry. **Mitigation**: v0.2 introduces field 9; v0.3 leans toward default-expiry-required for `action`/`urgent` priority (Open Question 8). Until then, recipients including PCS-Daemon must apply context-based staleness judgment — a task referencing a PR that has merged or a session that has terminated is implicitly stale.
- **Judge-gate compromise.** If the Judge-side credential is leaked or weakened, the server-enforced approval gate collapses to a prompt-layer convention. **Mitigation**: today the gate is the ClickHouse user grant model; IAM-future is hardware-bound PIV/CAC. Until IAM lands, treat the `inbox-ui` credential as the lab's most sensitive non-ClickHouse-admin credential.
- **Identity-by-assertion drift.** Today the `sender` field is brief-asserted, not credential-verified. A compromised or misconfigured agent could send messages claiming to be another agent. **Mitigation**: this is the gap SOM's IAM pillar closes. Until IAM lands, the lab operates on cooperative trust + audit-after-the-fact; the design package and `SOM-PRODUCTION-VALIDATION.md` v1.1 IAM row name this gap explicitly.
- **PCT tampered in transit, recipient acts on modified instruction.** Today (cooperative bus, no signing) a PCT could in principle be modified between send and pickup — the bus is trusted-by-convention. **Mitigation**: v0.2 deliberately does not bake in an assumption of cryptographic trust (Open Question 6). PCS-Daemon and other consumers must treat the bus as cooperative-trusted, not cryptographically-trusted, until the IAM coupling (agent-DNA signature model) lands. When IAM signing arrives, PCT integrity becomes verifiable; the seam is named at field 1 (`principal-id`).
- **Drift toward trust-the-recipient on PCT validation.** The architecture's spine is no-bypass + fail-strict at every chokepoint. If v0.3 drifts toward "IBX trusts senders, recipients validate downstream," that contradicts the spine and reproduces the failure mode SOM's PGE double-guardrail pattern exists to prevent. **Mitigation**: the v0.2 leaning is flagged explicitly (validate machine-critical fields 7-9 at send, fail-strict on malformation). Open Question 1 names this; v0.3 commit must hold the line.
- **Substrate evolution breaking the contract.** Future migration from ClickHouse to Kafka/RabbitMQ/Redis Streams (or to the EPYC/TrueNAS production substrate) must preserve the nine-field PCT, the priority semantics, the status workflow, and the Judge-gate enforcement. **Mitigation**: the Exit Test (per `SOM-PROBLEM-STATEMENT.md` v0.5 §4) is the CLCA gate for substrate changes. Any substrate proposed for IBX must be evaluated against this spec's contract before adoption.
- **Body-encoded PCT misparsing.** Because fields 2-6 live in markdown body (v0.2), agents that don't follow conventional structure can produce messages PCS-Daemon's parser rejects or misinterprets. **Mitigation**: v0.3 will introduce structured columns for fields 7, 8, 9 (validation-critical meta fields) with fail-strict validation at send; fields 2-6 remain body-encoded but with a recommended structure template that IBX agents follow as convention. PCS-Daemon's defensive parsing handles non-conformant messages without crashing.
- **`info` priority abuse.** An agent could mark a Judge-decision-requiring message as `info` to bypass the approval gate. **Mitigation**: this is a behavioral failure, not a structural one — the schema-layer gate only fires on `action`/`urgent`. The lab's discipline (per CLAUDE.md "Agent Message Queue") is that `info` is for FYI/completion; misuse is caught at audit. The Increment-2 ITDR layer (when built) detects this pattern as behavioral anomaly.
- **Multi-task PCT collapsing recipient attribution.** A sender could pack multiple tasks into field 2, making audit attribution ambiguous (which sub-task did the recipient act on; which was rejected; which is still in-progress). **Mitigation**: v0.2 documents one-task-per-PCT as convention (Open Question 7); v0.3+ may promote to fail-strict if audit surfaces abuse. Today the discipline is enforced socially through review rather than at send.

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

## Success Criteria

- **PCT nine-field contract is citable and stable.** PCS-Daemon's design references this section without needing to invoke a future v0.3 fold-in for clarification. **Measure**: PCS-Daemon's design spec (Bob's draft) cites IBX-SPEC v0.2 § PCT and depends on no fields outside the nine, and does not depend on the scope/authority bounds being collapsed.
- **Patton dialectical review pass.** Independent reasoning gate. v0.1 → v0.2 fold-in (this version) applied Patton's `31b322a3` review; the v0.2 → v0.3 candidate gate needs a fresh pass. **Measure**: Patton's sign-off inbox message at the v0.2 review gate.
- **Einstein independent reasoning pass.** Cross-substrate independence check; Patton has noted v0.2 does not currently require Einstein cross-substrate review (`31b322a3`: "design-judgment calls, not structural-correctness questions"). **Measure**: deferred unless v0.3 introduces structural-correctness questions Patton flags as needing Einstein.
- **Bob no-overclaim + coupling-boundary sanity pass.** Per the package-one IAM discipline that worked (Bob's `25371867`). **Measure**: Bob's review confirms (a) no IBX claim reads as "specified" when it is "POC-in-production," (b) no future-state claim reads as "built" when it is "designed," and (c) the v0.2 may-rely-on / may-NOT-rely-on coupling boundary is drawn where PCS-Daemon's design wants it.
- **Substrate-swap survives the contract.** When IBX migrates from 9975WX-ClickHouse to EPYC/TrueNAS production substrate, the nine-field PCT, priority semantics, status workflow, and Judge-gate enforcement all hold without spec revision. **Measure**: the migration deployment doc references this spec's contract as the invariant the substrate transition must preserve.
- **`info` vs `action`/`urgent` discipline holds in audit.** No agent self-acts on `action` or `urgent` work without an `approved` status transition recorded in `messages.inbox`. **Measure**: spot-check audit query against `messages.inbox` shows zero `action`/`urgent` messages with downstream commits before `approved` timestamp.
- **Validity-aware staleness handling holds across recipients.** Recipients (including PCS-Daemon when built) apply context-based staleness judgment for PCTs without explicit `validity`, and respect explicit `validity` deadlines when present. **Measure**: no recorded incident of a recipient acting on a PCT whose context (referenced PR, session, commit) has been terminated or merged-and-superseded.

## References

- `planning/SOM-PILLAR-NAMES.md` v1.1 — pillar bindings of record
- `planning/SOM-PROBLEM-STATEMENT.md` v0.5 — design drivers (§0, §2, §6.3, §4 Exit Test)
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — production validation record
- `planning/SOM-IDENTITY-PILLAR-DESIGN.md` — IAM pillar design (provisional, briefs-only implementation)
- `planning/SOM-INSTANTIATION-AND-IDP.md` — IAM onboarding + login flow (provisional)
- `planning/PCS-REGISTRY-FOLD-IN.md` v1.3 — PCS three-layer anatomy + Lifecycle Daemon scope
- `shared-context/agent-message-queue.sql` — ClickHouse DDL for `messages.inbox` (v0.2 storage substrate)
- `CLAUDE.md` "Agent Message Queue" — operational reference predating this spec
