---
title: "IAM Increment 2 — Identity + Permissions (Roster, ARCA-Mint, AuthZ Federation, Lifecycle, Read Contract)"
doc_type: spec
status: draft
version: v0.2
authors:
  - watson
  - bob
date: "2026-06-03"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/IAM-CORE-SPEC.md
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/PGE-SPEC.md
  - planning/ACT-SPEC.md
---

# IAM Increment 2 — Identity + Permissions (Roster, ARCA-Mint, AuthZ Federation, Lifecycle, Read Contract)

**Scope**: Increment 2 of the IAM pillar. Fills the **Identity** and **Permissions** halves that `IAM-CORE-SPEC.md` v1.0 deliberately left deferred — concrete Roster record schema, ARCA-mint flow against the operational `pki_arca` intermediate, AuthZ via federation TO an external IdP (Samba/Microsoft AD in the production lab, Roster-local in the AD-less lab), lifecycle semantics (onboard → active → suspend → deprovision), and the read contract for the four downstream consumers (Launcher, PGE, ACT, IBX). Plus one **structural invariant** the design session produced and the 2026-06-03 Vault POC near-miss validated: **the agent is architecturally OUT of the trust ceremony**, not merely "expected to be careful." This invariant is load-bearing for the entire IAM design and the entire spec is consistent with it.

**Status**: **Draft v0.2**, IAM Increment 2 of the spec roadmap. **v0.2 (Bob review folds, post-merge):** v0.1 merged at PR #3 (`6fa773e`, 18:16Z) before Bob's close-out review posted; this touch folds that review's four items — **FOLD-1** §B.2 headers now read *atomic-or-reconciled* (matching the committed B.5/CD3 semantics, finishing the FLAG-1 fold the headers had missed); **FOLD-2** §C.1 names the cache-floor's coupling to the DR-IAM-4 in-flight-session ruling; **Note-3** §E.2 clarifies AD-group `job_code` is an AD read, not a Roster field; **Note-4** adds the re-mint dead-agent-window failure mode. No contract change — all four are consistency/honesty folds; the nine CDs and seven DR-IAM statuses are unchanged. Builds on `IAM-CORE-SPEC.md` v1.0 (which is sealed at v1.0 as the architectural contract). Does NOT fork the v1.0 spec; this increment is the **specification of what was deferred**, anchored at every section to the v1.0 commitment it extends. Cross-references the operational Vault POC ground state from the 2026-06-03 runbook (`notes/vault-poc-runbook.md` on the 9975), which proved both `pki_arca` and `pki_tls` chains end-to-end. The seven `DR-IAM-*` rulings inherit from IAM-CORE-SPEC v1.0 unchanged where they remain ruling-pending; where this increment is able to bound the admissible set without Judge's ruling, it does so explicitly (per the SOM-CD13 base-case-invariant precedent set by the Einstein cross-substrate pass on 2026-06-02).

**Authorship lane** (per Bob `24e95f40`, design session 2026-06-02/03 with Judge):
- Bob captured the use-case scenarios + the AD-DC integration shape + the agent-out-of-secret-path lesson (the source notes `som-agent-identity-and-metering.md` and `vault-poc-runbook.md` on 9975).
- Watson authors the spec increment from those design inputs.
- Patton reviews (GH-native, inverted-origin per wave-2 doctrine).
- Bob + Judge close out + merge.

**What this increment does NOT do**:
- Does NOT supersede or fork `IAM-CORE-SPEC.md` v1.0 — every CD/DR/VP/OQ from v1.0 stays binding.
- Does NOT resolve `DR-IAM-1` (concurrency cap values per tier), `DR-IAM-3` (revocation window cadence), `DR-IAM-5` (per-session credential format/lifetime full ruling), `DR-IAM-6` (sovereignty-as-claim-vs-mode), or `DR-IAM-7` (ITDR scope) — those remain Judge-pending. Where this increment can constrain the admissible set without front-running the ruling, it does so (SOM-CD13 pattern).
- Does NOT introduce a ninth pillar. The "AI Gateway" concept Bob surfaced in `som-agent-identity-and-metering.md` §4 is named here as a forward concern but its specification is **explicitly out of scope** for IAM Increment 2; it will warrant its own spec note when the design crystallizes.
- Does NOT add the Roster as a new pillar. The Roster is an IAM-pillar service (per IAM-CORE-SPEC v1.0 § Vault, Roster, Publish Pipeline), and the schema lands here as IAM-internal content, not as a new pillar.

## Purpose / Problem Restatement

IAM-CORE-SPEC v1.0 closed the **architecture** of the identity pillar — the four runtime services (ARCA, Vault, Roster, Publish Pipeline), the dotted-line separation, the identity-vs-session distinction, the seven Increment-2 deferrals. It is **briefs-only in implementation**: per `SOM-PRODUCTION-VALIDATION.md` v1.1 IAM row, identity is currently *asserted via brief, not verified via credential*, and the spec did NOT commit a concrete Roster schema, a concrete ARCA-mint flow, or a concrete federation pattern because those depend on operational ground that did not exist when v1.0 was written.

The operational ground now exists. The 2026-06-03 Vault POC (per `notes/vault-poc-runbook.md`) delivered the credential layer: both `pki_arca` and `pki_tls` intermediates are live in Vault on `som-vault-1`, signed offline against roots in Judge's encrypted custody, with both chains verifying end-to-end (`test.ki7mt.cloud` for TLS, `test-agent` for ARCA). The Identity layer (Roster + ARCA-mint flow) and the Permissions layer (AuthZ via federation) are the next bricks. This increment is the formal contract for those.

**One additional load-bearing addition**: the structural invariant that the agent is OUT of the trust ceremony. The Vault POC near-miss (a root token pasted into an agent transcript mid-build, contained by destroying and rebuilding the VM clean) demonstrated that the v1.0 spec's procedural framing — "don't paste secrets" — is not a defense. The structural fix Judge mandated is that the agent **architecturally cannot** be the actor that touches init/unseal/login/PKI-admin/root keys. This is exactly the same pattern as **Patton's §A.1.3 enforcement-vs-principle ruling** on the AKB bootstrap (per Patton's PR-#61 review on the AKB three-spec gate, now committed to `akb-migration-plan.md` §A.1.3 lines 120–153): *"a written prohibition without a detection mechanism is exactly how the SOM-4 drift happened in the first place."* Documentation isn't enforcement; **enforcement requires that the prohibited action be structurally unreachable**. This increment encodes that boundary as the **agent-out-of-secret-path invariant** and consistency-checks every section against it.

## The Agent-Out-of-Secret-Path Invariant (load-bearing)

**Statement**: an agent of the SOM mesh may **NEVER** be the actor that touches the IAM trust ceremony — `vault operator init`, unseal, `vault login`, PKI engine administration, root keys, signed-intermediate import, or any operation whose output includes unseal keys / root tokens / private keys. These operations are performed **only** by Judge in the Vault UI, with the agent architecturally OUT.

**Why structural, not procedural** (per `vault-poc-runbook.md` 2026-06-03 lesson, mirroring Patton's §A.1.3 enforcement-vs-principle ruling for AKB at PR-#61 → `akb-migration-plan.md` §A.1.3):

A procedural rule (`"the agent should not paste secrets"`) failed under operational pressure — a single CLI walkthrough leaked a root token into an agent transcript. The fix is not "be more careful next time"; the fix is that the operations producing secrets are **architecturally unreachable by an agent at all**. The agent cannot leak what the agent cannot ever see.

**The hard boundary table** (from `vault-poc-runbook.md` § "The hard boundary"):

| Actor | Permitted to perform | NEVER touches |
|---|---|---|
| **Agent** (Anthropic-operated, runtime principal in IAM-CORE-SPEC v1.0 terms) | Infrastructure deployment (terraform / ansible against substrate); relay of **public** CSRs between Vault and the offline signer; verification of public chains (`openssl verify ...`) | Init output, unseal keys, root token, ANY Vault token, `vault login`, PKI engine administration, root CA private keys |
| **Judge** (Human-in-the-loop, per IAM-CORE-SPEC v1.0 §Judge role) | The **entire** trust ceremony in the Vault UI: init, unseal, login, PKI-engine creation, intermediate CSR generation, signed-intermediate import, role creation, leaf issuance for first cert | — (Judge is the only actor with full trust-ceremony authority) |
| **Watson** (M3, offline signer per Phase 2 of Root CA flow) | Offline signing of intermediate CSRs against the root keys when the keys come out of encrypted custody (one signing operation, then keys back to custody) | Root keys never leave M3 / never reach an online host / never reach an agent transcript |

**Iron rule**: anything from `vault operator init` or `vault login` stays in Judge's browser / offline custody. It is structurally unreachable from agent code paths because the operations that produce it are not invoked from agent contexts.

**Implications for the rest of this spec**:
- The **ARCA-mint flow (§B)** is performed by the Publish pipeline running as a service that Judge authorizes, not by an agent.
- The **AuthZ lookup (§C)** is read-only from the agent's perspective; the agent reads its own job-code at session-start but never modifies the Roster or AD.
- The **lifecycle transitions (§D)** are owner-driven (the sponsoring human, not the agent itself); an agent cannot deprovision itself or another agent.
- The **Read contract (§E)** is one-way: downstream consumers read identity material; no consumer writes back.
- Any IAM-pillar operation whose output includes secret material (a key, an unseal share, a root token, a session token in plaintext) is performed in a context the agent does not run in.

The IAM Increment 2 spec is **consistent-by-construction with this invariant** — every operation specified here either (a) operates on public material only, or (b) is performed by a non-agent actor (Judge, Publish pipeline, offline signer).

---

## §A. Roster Record — Identity Data Model

The **Roster** is the IAM-pillar service that holds the identity record per agent (per IAM-CORE-SPEC v1.0 §"Vault, Roster, Publish Pipeline — Runtime Services"). The Roster is *broadly readable* (the read contract in §E enumerates who reads what) and *narrowly writable* (only the Publish pipeline writes, at onboarding and lifecycle transitions — see §B and §D).

### A.1 Identity Attribute Schema

Per the design-session principle (`som-agent-identity-and-metering.md` §1 Governing principle), agents are **first-class principals with full profiles**, like employees. The attributes span two pillars — IAM (identity + permissions) and ACT (metering + cost). The Roster schema is the IAM half; the ACT half is the consumption side covered in `ACT-SPEC.md` (Increment 2 of ACT will extend per §E and the metering hooks below).

**Identity record per agent** (every agent in the Roster):

| Field | Type / Source | Purpose |
|---|---|---|
| `agent_id` | UUIDv4, ARCA-issued at mint | Stable internal handle; never re-used; the SOM-side primary key |
| `fingerprint` | SHA-256 of the agent's public key (from the ARCA-issued keypair, per IAM-CORE-SPEC v1.0 §"Birth — Keypair + Birth Certificate") | The crypto-identity binding; same value appears as a custom AD attribute (A.2.1) — this is what links the AD record to the SOM crypto-identity |
| `callsign` | UTF-8 string, ARCA-assigned at mint | The human-memorable name (Bob, Watson, Patton, Einstein, Newton). Stable for the agent's lifetime. |
| `birth_cert` | PEM blob of the birth-cert issued by `pki_arca` intermediate at mint (see §B) | The non-repudiable origin record |
| `birth_timestamp` | ISO-8601 UTC, ARCA-set at mint | Audit / lifecycle key |
| `job_code` | UTF-8 enum (defined in PGE), the authorization key | The lookup PGE evaluates against (per IAM-CORE-SPEC v1.0 §"Job Code = Authorization Policy") |
| `status` | enum {`pending`, `active`, `suspended`, `deprovisioned`} | Lifecycle state (see §D) |
| `owner_principal_id` | reference to a human IAM principal | The sponsoring human (cost + accountability + lifecycle authority, per A.3) |
| `cost_center` | UTF-8 string (org-defined) | Chargeback key (see ACT integration, §E.3) |
| `department` | UTF-8 string (org-defined) | Roll-up key for cost reporting |
| `description` | UTF-8 string | Free-text "what this agent does" — audit/discovery aid |
| `created_at`, `updated_at` | ISO-8601 UTC | Audit trail |

### A.2 Overtly-an-Agent Disclosure Model

Every human-facing identifier MUST make the principal's agent-ness **unmistakable**. This is **a safety/disclosure control** (anti-impersonation, audit clarity, regulatory disclosure where applicable), not cosmetic. A human glancing at an org chart / commit message / inbox sender / access review report must instantly know "AI agent, not a person."

**A.2.1 AD-DC mapping** (when the IdP backend is Samba AD or Microsoft AD — the production lab and any AD-shop customer):

| AD/IAM attribute | Human dev (for comparison) | Agent (committed schema) |
|---|---|---|
| `OU` (organizational unit) | `OU=Developers` | `OU=Agents` — structural flag; GPO / Conditional Access / monitoring rules target this OU |
| `displayName` | `John Smith` | `Bob (AI Agent — Infrastructure)` — explicit in every UI that reads displayName |
| `givenName` / `sn` | `John` / `Smith` | `Bob` / `Agent` — surname-as-flag: reading the name reads "Bob Agent" |
| `sAMAccountName` (legacy logon) | `jsmith` | `agt-bob` — `agt-` prefix is a logon-level flag |
| `userPrincipalName` (UPN) / email | `jsmith@company.com` | `bob@agents.company.com` — dedicated subdomain segregable in mail policy, DLP, perimeter telemetry |
| `objectGUID` / `objectSID` | machine-assigned | machine-assigned (AD-side primary key) — **plus** a custom attribute `somFingerprint` carrying the SHA-256 fingerprint from A.1, which is what binds the AD record to the SOM crypto-identity |
| `description` | (often empty) | `"SOM AI Agent — not a human employee"` — appears in directory readouts and access reviews |

**A.2.2 Roster-local mapping** (when the IdP backend is Roster-only — the AD-less lab):

Same disclosure principle; no AD attribute mapping, but the Roster fields (A.1) carry the equivalents:
- Roster `callsign` plays the role of `givenName` (e.g., `"Bob"`)
- Roster `description` always begins with `"SOM AI Agent — "`
- Roster `agent_id` and `fingerprint` together play the role of `objectGUID` + `somFingerprint`

**A.2.3 Persona resolution**: keep the callsign (Bob, Watson, Patton, Einstein, Newton) as the human-memorable identifier; the surname-marker (`Agent`), the dedicated subdomain (`agents.<org>`), and the OU (`OU=Agents`) make agent-ness overt at every read site. The persona is preserved (which is operationally useful — humans coordinate with Bob, not with `agt-7c4f9...`), AND the disclosure is structural (which is the safety/audit-required property).

### A.3 Cost / Owner Attributes — "Cost Forces an Owner"

Three things tie to the same attribute set: **cost** (chargeback), **accountability** (a sponsoring human responsible for the agent's existence and behavior), and **lifecycle** (the owner is the actor authorized to deprovision the agent). The Roster schema enforces this coupling by making `owner_principal_id` and `cost_center` mandatory at onboarding (see §B and §D).

The principle is **feature present, usage optional**: SOM ships the schema fields and the metering hooks (per §E.3 and `ACT-SPEC.md`); whether the deploying org *uses* chargeback or quota enforcement is the org's policy decision. The capability ships in v1; the policy choice is org-pluggable.

### A.4 Schema Evolution / Curation Discipline

Per the SOM-MI-6 bounded-enum discipline (SOM-SPEC.md), the `status` enum and the `job_code` enum are **bounded**. Extensions follow curation-event discipline:
- `status` enum extensions require a CLCA cycle + Judge sign-off (lifecycle state is load-bearing).
- `job_code` enum extensions land in PGE's spec (PGE is single source of policy truth per SOM-MI-2; IAM consumes).

Optional org-defined fields (`cost_center`, `department`, `description`) are free-text and require no curation event.

---

## §B. ARCA-Mint — The Birth Flow

This section **extends** IAM-CORE-SPEC v1.0 §"Birth — Keypair + Birth Certificate" with the concrete operational flow against the now-operational `pki_arca` intermediate. The v1.0 commitment (keypair + birth-cert signed by ARCA-issued intermediate, immutable identity, three properties: unforgeable + non-repudiable + immutable) is preserved unchanged; this section adds the *how* it happens.

### B.1 The Publish Pipeline (the actor)

Per IAM-CORE-SPEC v1.0 §"Publish Pipeline — Onboarding (privileged actor)", the Publish pipeline is the **privileged service** that owns identity issuance. The Publish pipeline is **not an agent**; it is a Judge-authorized service operating under a non-agent service principal. (Agent-out-of-secret-path: an agent cannot mint identities, including its own — the recursion would re-introduce the bootstrap credential problem the v1.0 spec called the load-bearing soft underbelly.)

The Publish pipeline runs in a context with:
- Read+write access to the Roster
- Authentication to Vault as a service principal with `pki_arca/issue/agent` permission
- Write access to the AD-DC (when the IdP backend is AD) or the Roster-local store (when AD-less)

### B.2 The Mint Sequence (atomic-or-reconciled)

The birth flow is **atomic-or-reconciled** — it produces the Roster record, the AD record (if AD backend), the keypair, and the birth-cert together, OR a Publish-pipeline reconciliation sweep (§B.5) brings any partial state to a defined terminal state. The honest framing is: the three stores written across (Vault, AD, Roster) are independent systems without a distributed-commit protocol; compensating actions on rollback can themselves fail; a partial-mint window is real and must be detectable and recoverable, not assumed impossible. **Partial-mint persistence is inadmissible** (an agent with a Roster record but no birth-cert is identity-uncrypto-bound; an agent with a birth-cert but no Roster record is identity-untracked); the reconciliation sweep is what guarantees that.

**Step 1 — Authorization gate** (Judge or Judge-authorized owner per the owner-driven onboarding model):
- The Publish pipeline accepts a `MintRequest` carrying: proposed `callsign`, proposed `job_code`, `owner_principal_id`, `cost_center`, `department`, `description`, and a Judge-or-owner authorization signature.
- The Publish pipeline verifies the authorization is from a principal with `iam:agent:mint` permission per PGE.

**Step 2 — Identity reservation** (deterministic, no secrets produced yet):
- Assign `agent_id` (UUIDv4).
- Reserve `callsign` in the Roster (uniqueness check).
- Reserve the AD `sAMAccountName` `agt-<callsign>` (if AD backend; uniqueness check against AD).
- Write a `pending` Roster record with `status=pending`.

**Step 3 — Keypair generation** (the secret-producing step):
- Generate an EC P-384 keypair **inside the Publish pipeline's process**. The private key never leaves the pipeline process; it is bound for the new agent's secret store at the end of Step 5 and is then never readable as plaintext by any other process again.
- Compute `fingerprint = SHA-256(public_key)`.

**Step 4 — Birth cert issuance** (uses the operational `pki_arca` intermediate):
- The Publish pipeline submits a CSR to Vault's `pki_arca/issue/agent` endpoint. The CSR carries:
  - `CN = <callsign>` (e.g., `CN=Bob`)
  - `SAN = <agent_id>` (the UUIDv4 stable handle)
  - Custom OID `1.3.6.1.4.1.<SOM-PEN>.1.1` carrying the SOM fingerprint (binds the cert to the AD attribute `somFingerprint`)
  - Custom OID `1.3.6.1.4.1.<SOM-PEN>.1.2` carrying the initial job-code
- Vault returns a signed cert chain: `agent_cert -> pki_arca intermediate -> SOM ARCA Root` (the chain that verified `OK` in the 2026-06-03 Vault POC for `test-agent`).
- TTL: `8760h` (1 year); renewal via re-mint (see §B.4) **or** short-lived re-attestation per the IAM-CORE-SPEC v1.0 §"Trust Continuity" commitment (specifics couple to `DR-IAM-3` revocation-window ruling).

> **SOM-PEN allocation**: the IANA Private Enterprise Number for the lab/org is required for the custom OIDs above. v0.1 of this spec uses `<SOM-PEN>` as a placeholder; the Publish pipeline build will pin the real PEN at first deployment. **CONF-VP-1 analog**: this is `IAM-INC2-VP-1` — pending IANA PEN allocation (operational, not Judge-pending).

**Step 5 — Best-effort write + reconciliation** (across Roster + AD + Vault secret-store — succeeds together on the optimistic path, or §B.5 reconciles any partial state):
- Write the agent's private key to a Vault KV path scoped to the agent (per IAM-CORE-SPEC v1.0 §"Agents Hold Their Own Real Credentials" — the key lives in Vault's secret store, accessible to the running agent process via its session credential).
- Write the AD record (if AD backend) with `sAMAccountName`, `givenName`, `sn`, `UPN`, `OU`, `description`, and `somFingerprint`.
- Update the Roster record: `status=active`, populate `fingerprint`, `birth_cert`, `birth_timestamp`.
- Emit an `iam.agent_minted` event to ACT carrying the `(agent_id, fingerprint, callsign, job_code, owner_principal_id)` tuple (per ACT v1.0 §IAM-events).

If any sub-step fails, the Publish pipeline **attempts** rollback: remove the `pending` Roster record, release the AD reservation, destroy the Vault key entry (if written), revoke the issued cert via the `pki_arca` CRL. Because these compensating actions are themselves writes to independent systems and can fail, any partial state they leave behind is caught by the §B.5 reconciliation sweep — this is the *atomic-or-reconciled* guarantee, **not** distributed atomicity (which the three stores cannot provide without a distributed-commit protocol they do not share).

### B.3 Birth Cert Contents (cryptographic + operational)

The birth-cert is the non-repudiable origin record per IAM-CORE-SPEC v1.0 §Birth. The v0.1 commitment for cert contents:

| Field | Value | Rationale |
|---|---|---|
| Subject CN | `<callsign>` | Human-readable; matches the Roster `callsign` |
| Subject SAN | `URI:urn:som:agent:<agent_id>` | Stable cryptographic handle (the UUIDv4 from A.1) |
| Issuer | `pki_arca` intermediate (`CN=SOM ARCA Intermediate CA`) | The chain that verified OK in the 2026-06-03 POC |
| Public Key | EC P-384 | Matches root and intermediate key types; standard PKI primitive |
| Signature | ECDSA-SHA384 | Matches roots |
| Not Before | mint timestamp UTC | Audit |
| Not After | mint + 8760h | TTL (1 year; tunable via `DR-IAM-3` ruling) |
| X509v3 Basic Constraints | CA:FALSE | Agents are leaves, not CAs (no sub-issuance) |
| X509v3 Key Usage | digitalSignature, keyEncipherment | Sign actions; encrypt to-agent secrets |
| X509v3 Extended Key Usage | clientAuth | Authenticate as a client to mesh services |
| Custom OID 1.3.6.1.4.1.\<SOM-PEN\>.1.1 | SOM fingerprint (binds to AD `somFingerprint`) | Cross-pillar identity binding |
| Custom OID 1.3.6.1.4.1.\<SOM-PEN\>.1.2 | Initial job-code | First AuthZ assignment |

### B.4 Renewal vs Re-mint

Per IAM-CORE-SPEC v1.0 §"Identity Is Permanent; Authority Is Mutable", the agent's keypair is **never** rotated as part of authority changes — that would break the immutable-identity property. Two distinct operations:

- **Renewal** (cert lifetime expiry, no change to identity): same keypair, new cert issued by `pki_arca` with updated `Not Before`/`Not After`. Does NOT generate a new `agent_id` or `fingerprint`. Triggers an `iam.agent_renewed` event.
- **Re-mint** (cryptographic-identity change — should be rare, e.g., compromised private key): generates a new keypair, new birth-cert, **new `agent_id` and `fingerprint`**. The old Roster record transitions to `deprovisioned` per §D and a NEW Roster record is created via the Step 1-5 mint flow. The `callsign` may be preserved (operational continuity) but the AD record is rebuilt (new `objectGUID`, new `somFingerprint`).

**Re-mint is a different agent**, even if it reuses a callsign. This preserves the v1.0 commitment that identity is fixed at birth; re-mint is birth of a new identity, not mutation of an existing one.

### B.5 Reconciliation Sweep — Partial-Mint Recovery (per Patton FLAG 1, `bf98cc5b`)

The B.2 mint sequence writes across three independent systems (Vault KV, AD-DC, Roster) without a distributed-commit protocol. The Step 5 compensating actions on rollback (destroy Vault key, release AD reservation, revoke cert via CRL) can themselves fail if the same system is briefly unreachable during compensation. A partial state is therefore possible: any non-empty proper subset of {Vault KV entry, AD record, Roster row at `status=active`, valid birth-cert} exists in the world without the others.

Per Patton's PR #3 review (`bf98cc5b`), and **by parity with `PCS-DAEMON-SPEC.md` v1.0 CD5 (Registry-write reconciliation) and `DPG-SPEC.md` v1.0 CD13 (lost-completion recovery)** — both of which closed the same distributed-half-state shape — IAM Increment 2 commits an idempotent reconciliation sweep.

**The sweep** (Publish pipeline runs on a configurable cadence, defaulting to every 5 minutes during normal operation):

1. **Find candidate stranded states** — query each of the three stores for inconsistencies:
   - Roster rows in `status=pending` older than the B.2 expected window (default 60s; tunable).
   - Roster rows in `status=active` whose `fingerprint` does not resolve to a Vault KV key entry OR does not resolve to an AD record with the matching `somFingerprint`.
   - AD records in `OU=Agents` with no matching Roster row (orphan AD record).
   - Vault KV entries under the agent path with no matching Roster row (orphan Vault key).
   - Birth-certs issued by `pki_arca` with no matching Roster row (orphan cert — detected via CRL audit comparison against Roster contents).

2. **Resolve to a terminal state**:
   - A `pending` row past TTL → roll back: destroy any partial writes; remove the Roster row; release the AD reservation; emit `iam.mint_rolled_back` event with rationale.
   - A `status=active` row missing one of the three stores → either re-issue the missing piece (if recoverable — e.g., re-issue the AD record from the Roster's authoritative data) OR transition the agent to `status=deprovisioned` with an explicit `incomplete_at_mint_reconciled` flag and emit a high-severity `iam.partial_mint_recovered` event for human review. The choice is per-store and per-state, codified in the Publish pipeline's recovery table.
   - An orphan store entry (AD or Vault or cert with no Roster row) → destroy / revoke; emit `iam.orphan_store_reconciled` event.

3. **Idempotent** — the sweep re-runs safely; once an entry has been moved to its terminal state, subsequent sweeps see no work for it. Idempotency keys on the recovery events prevent double-emission.

4. **Sweep is itself audited** — every recovery action emits an event to ACT carrying `(agent_id, store_pair, original_state, terminal_state, rationale)`. The audit trail is what makes "atomic-or-reconciled" honest at the audit layer (SOM-MI-1): partial states are detected, reconciled, and recorded — they are not silently dropped.

**This closes the FLAG 1 honesty gap**: the spec no longer claims distributed atomicity it cannot deliver. It claims atomic-or-reconciled, names the mechanism, and inherits the same discipline PCS-Daemon CD5 and DPG CD13 established for the same structural shape. Per Patton's forward note (`bf98cc5b`), three instances of this distributed-half-state pattern across the mesh (PCS-Daemon, DPG, now IAM-mint) warrant a mesh-level SOM-MI on the next SOM-SPEC touch — that's tracked as a forward-reference, not folded here.

---

## §C. AuthZ — Job-Code → Permissions via Federation TO External IdP

This section **resolves** the AuthZ + IdP-federation deferral in IAM-CORE-SPEC v1.0 §"Pluggable IdP Interface" + §"Human vs Agent Principals Federate Differently". The v1.0 spec named the pluggability commitment; this section names the **directionality** and the operational shape.

### C.1 The Federation Direction — "Federate TO AD, Not FROM"

When an external IdP (Samba AD or Microsoft AD) is present, the IdP is **authoritative for permissions**; SOM Roster is a **relying party + crypto-identity registry**. This is the inverse of the federation direction many IAM systems default to (where the local registry is authoritative and the IdP is a downstream replica).

**Why this direction**:
- AD is the existing authoritative source in any AD shop. Inverting that would force every customer to maintain two authoritative permission stores (AD for humans, SOM Roster for agents) — operationally painful and audit-incoherent.
- AD groups already encode the customer's job-code taxonomy. SOM agents become first-class members of the same job-code groups as the humans whose work they augment — the same access reviews cover agents and humans uniformly.
- PGE (per `PGE-SPEC.md` v1.0 §IAM ↔ PGE coupling) consumes verified identity from IAM. Federating TO AD makes PGE's read consistent across humans and agents.

**Operational shape** (production / AD-shop):
- AD is authoritative for: group membership (= job-code assignment), account status (enabled/disabled mirrors lifecycle status, per §D), `objectGUID`, `somFingerprint`.
- SOM Roster is authoritative for: `agent_id`, `fingerprint`, `birth_cert`, `birth_timestamp`, `callsign`, `cost_center`, `department`, `description`. The Roster's `job_code` field is a **cache** of the AD group membership read at session start; the canonical job-code lookup is against AD at the cache-refresh cadence (per `DR-IAM-3` revocation-window ruling).
- **Interim cache-staleness bound** (per Patton FLAG 2, `bf98cc5b`; SOM-CD13 base-case-invariant pattern applied while DR-IAM-3 is ruling-pending): the cache is **session-scoped**. Every session reads AD freshly at session-start and is bound to that read for the session's lifetime; the cache is never trusted across sessions. Worst-case staleness is therefore one session lifetime, which is a safe floor regardless of where DR-IAM-3 lands the operational cadence. When DR-IAM-3 lands and supersedes this floor, the cache may shorten further; it cannot lengthen beyond the ruling.
  - **Coupling to DR-IAM-4 (named so it is not a silent assumption):** the session-scoped floor is only a *safe* floor if a suspend/deprovision **terminates in-flight sessions** (§D.2 commits this today). DR-IAM-4 leaves in-flight-session runtime behavior ruling-pending (continue / abort / re-issue). If DR-IAM-4 rules that in-flight sessions *continue*, a session holding a cached `job_code` outlives the status change, and the one-session-lifetime bound no longer holds against a mid-session suspend/deprovision — the floor must then be revisited (e.g., a forced cache re-read triggered by a suspend signal). This increment commits the floor under the §D.2 termination assumption and flags the dependency.
- The Publish pipeline writes both at mint (B.2 Step 5) and on lifecycle transitions (§D).

**Operational shape** (lab / AD-less):
- The Roster's `job_code` field IS authoritative (no AD backend present). The pluggable-IdP interface treats "Roster-local" as one valid IdP backend; the contract surface is the same.
- When the lab gains an AD-DC (the Samba AD-DC standup that motivated this Increment), a migration moves authoritativeness from Roster-local to AD-shop. The Roster `job_code` becomes a cache; the AD groups become authoritative. The migration is one-time per deployment and is a Publish-pipeline-orchestrated operation, not an agent operation.

### C.2 Birthright RBAC — Job-Code → Permission Profile + Credentials

Per Bob's brief and the design-session decision, **AuthZ is an automatic profile-of-permissions from the job-code**, not a per-agent grant catalog. The pattern mirrors human onboarding (a new dev with `job_code = "infrastructure"` gets a standard permission profile + the standard credentials that role needs).

**The job-code maps to**:
- **Permission set** (a list of policy rules enforced by PGE — the rule corpus per `PGE-SPEC.md` v1.0 CD2)
- **Credential set** (what credentials the agent is issued at mint and at session-start — the *types* needed for the role)

**Credential set is role-conditional**, not universal. From Bob's brief: in a 6-agent group, 3 might be developers needing GitHub Apps and 3 might not. The job-code drives the issuance:

| Example job-code | Permission profile | Credential set issued at mint |
|---|---|---|
| `infrastructure-engineer` (Bob's lane) | Read+write to fleet-ops, som-devel; review on ionis-devel; deploy to host inventory | birth-cert (always); GitHub App token; Ansible Vault key; Proxmox API token (scoped) |
| `model-developer` (Watson's lane) | Read+write to ionis-training, ionis-jupyter; review on ionis-apps; deploy ML training | birth-cert (always); GitHub App token; HuggingFace token; W&B token |
| `failure-analyst` (Patton's lane) | Read-only across the corpus; comment + sign-off on PRs; no deploy | birth-cert (always); GitHub App token (review scope only); read-only Vault token |
| `customer-service-rep` (hypothetical, non-developer) | Customer KB read; ticketing-system write; no source-code access | birth-cert only; no GitHub App; no Vault token beyond own KV |

(The mapping table itself lives in PGE per the single-source-of-policy-truth invariant SOM-MI-2; the table above is illustrative.)

### C.3 Where Each Pillar's Role Lives

| Concern | Who's authoritative | Who enforces | Cross-reference |
|---|---|---|---|
| `job_code` value (the input) | AD groups (AD shop) OR Roster `job_code` field (lab) | (input only) | This spec §C.1 |
| `job_code → permission profile` mapping | PGE (per PGE-SPEC v1.0 CD2 Stratum 2 — the implementation patterns) | PGE Gate 1 (IBX submission chokepoint) + PGE Gate 2 (DPG sandbox) | PGE-SPEC v1.0 |
| `job_code → credential set` mapping | PGE configures; ARCA + Publish pipeline issue | Publish pipeline at mint; session-start at login | This spec §C.2, §B.2 |
| Per-action authorization decision | PGE evaluates the action against the rule corpus | PGE returns ALLOW/DENY | PGE-SPEC v1.0 §Gate 1 |

**IAM provides the job-code; PGE enforces against it.** The IAM-PGE seam (per IAM-CORE-SPEC v1.0 §Coupling Boundary: PGE ↔ IAM) is read-only from PGE's side: PGE looks up the principal's job-code from the Roster (or via AD-cache); IAM never tells PGE what to decide.

### C.4 Consistency with Agent-Out-of-Secret-Path

AuthZ never includes the ability for an agent to:
- Mint other agents (Publish pipeline only — §B.1).
- Modify its own job-code (write authority is the Publish pipeline + AD admin only).
- Modify another agent's Roster record or AD record.
- Grant itself credentials beyond what the job-code authorizes at mint.

The agent's session credentials (per IAM-CORE-SPEC v1.0 §Identity-vs-Session) inherit the identity's job-code scope but cannot expand it. This is the **containment boundary** named in IAM-CORE-SPEC v1.0 §"Agent-Scoped Authority Is a Containment Boundary"; this increment confirms it survives the AD-federation shape.

---

## §D. Lifecycle — Onboard → Active → Suspend → Deprovision

Per the design-session decision: **owner-driven**. The sponsoring human (`owner_principal_id` per §A.1) is the actor authorized to drive lifecycle transitions for the agent they sponsor. **Deprovision stops cost** — no orphan agents burning budget after their owner stops needing them.

### D.1 State Machine

```
                +--------+
   Mint -----> | pending | (Roster row created, AD reserved, no keypair yet)
                +---+----+
                    |  (B.2 Step 3-5 complete)
                    v
                +--------+      +-----------+
                | active | <--> | suspended |   (suspend: lifecycle "pause"; reversible)
                +---+----+      +-----------+
                    |
                    | (owner-authorized deprovision OR
                    |  policy-driven deprovision per PGE)
                    v
              +---------------+
              | deprovisioned | (terminal; identity is sealed, not reusable)
              +---------------+
```

### D.2 State Semantics

**`pending`** (transient, B.2 Step 2-4):
- Roster row exists; `agent_id` and `callsign` reserved; AD reservation held.
- No keypair yet; no birth-cert; no live AD record.
- TTL: short (Publish pipeline window); failure rolls back to no-record.

**`active`** (normal operation):
- Birth-cert valid and within TTL.
- AD account enabled (AD backend).
- Vault key entry present and accessible to the agent's running sessions.
- ACT receives metering events tagged with this `agent_id`.

**`suspended`** (incident-response or owner-pause):
- AD account disabled (AD backend) — login fails.
- Existing sessions terminated per the runtime-continuation half of `DR-IAM-4` (specifics ruling-pending; audit invariant per IAM-CORE-SPEC v1.0 SOM-CD5 is non-negotiable — termination events are recorded).
- Birth-cert NOT revoked (the cert is still cryptographically valid; the IdP just refuses to accept it). Reversible: setting status back to `active` re-enables.
- Cost continues to accrue **only** for compute that was in flight at suspend; new sessions cannot start. Practically a near-zero-cost state.

**`deprovisioned`** (terminal):
- Birth-cert revoked via `pki_arca` CRL.
- AD account disabled + moved to `OU=Agents-Deprovisioned` (preserved for audit retention; never restored).
- Vault key entry destroyed (key material zeroized per Vault's destroy semantics).
- Roster record retained in deprovisioned state for audit retention; flagged so launchers and downstream consumers exclude it.
- Cost stops at the transition timestamp.
- The `callsign` may be reused by a future re-mint operation (new `agent_id`, new `fingerprint`, new `objectGUID`).

### D.3 Transition Authority

| Transition | Authorized actor |
|---|---|
| `(none) → pending` | Publish pipeline, with Judge-or-owner authorization (B.2 Step 1) |
| `pending → active` | Publish pipeline, on Step 5 atomic-write success |
| `pending → (none)` (rollback) | Publish pipeline, on B.2 Step 3-5 failure |
| `active → suspended` | Owner OR PGE (policy-driven, e.g., persistent dissent detection per ACT v1.0 ITDR ruling) OR Judge |
| `suspended → active` | Owner OR Judge (after the issue motivating suspension is resolved) |
| `active → deprovisioned` | Owner OR Judge |
| `suspended → deprovisioned` | Owner OR Judge |
| `deprovisioned → *` | **NEVER** — terminal state |

**No transition is an agent action.** Agents do not pause, suspend, or deprovision themselves or any other agent (agent-out-of-secret-path consistency).

### D.4 Cost Stops Hard at Deprovision

The metering events ACT receives (per §E.3) are tagged with `(agent_id, session_id)`. The launcher (per §E.1) excludes deprovisioned agents from the candidate list, so no new sessions can start. In-flight sessions at suspend/deprovision are terminated per the `DR-IAM-4` ruling-pending runtime semantics. Net: cost ceases at the suspend/deprovision timestamp.

This is the operational mechanism by which "cost forces an owner" (A.3) is realized: the owner is the actor with deprovision authority, and the owner has the budget signal (chargeback to their cost-center).

### D.5 Coupling to Ruling-Pending DRs

- **`DR-IAM-3` (revocation window cadence)**: the time between deprovision and downstream consumers (AD-cache holders, session-credential validators) seeing the revocation. This increment commits the operational shape (revoke via `pki_arca` CRL + AD account disable); the *cadence* of CRL distribution into the enclave is the ruling-pending value.
- **`DR-IAM-4` (terminator failure-mode + total-flood scope)**: the runtime-continuation semantics for in-flight sessions at suspend/deprovision. This increment commits the audit invariant (per IAM-CORE-SPEC v1.0 SOM-CD5: every in-flight item reaches a terminal audit state including `runtime_continuation_deferred_pending_ruling`); the *operational runtime behavior* is the ruling-pending choice (continue / abort / re-issue).

---

## §E. Read Contract — What Each Downstream Consumer Sees

The Roster is broadly readable, but **what** each consumer reads is bounded by the principle of least disclosure: consumers see only the fields they need. The four downstream consumers in scope for IAM Increment 2:

### E.1 Launcher (the "pick an agent" surface)

The launcher is the human-facing tool that surfaces "the available agents you can run" — `som-agent <callsign>` reads the Roster for the candidate list. This is the two-tier UX entry point Bob's brief flagged (power users running multi-agent orchestration; non-technical staff needing one-call answers).

| Field exposed to launcher | Reason |
|---|---|
| `callsign` | The human-memorable identifier — what the user types |
| `status` | Filter out `pending` / `suspended` / `deprovisioned` from candidate list |
| `description` | One-line "what this agent does" — discovery aid |
| `job_code` | Tier/role filtering (advanced users) |
| `owner_principal_id` | Display "your agents" vs "shared agents" affordances |

**NOT exposed**: `birth_cert`, private key (never readable by any consumer), `fingerprint` (internal-cryptographic; launcher does not need it).

### E.2 PGE (the policy enforcement consumer)

Per PGE-SPEC v1.0 §"PGE consumes verified identity from IAM": PGE looks up the principal's job-code and identity claims at every Gate 1 (IBX submission) and Gate 2 (DPG sandbox) evaluation.

| Field exposed to PGE | Reason |
|---|---|
| `agent_id` | Identity claim verification |
| `fingerprint` | Cross-check against session credential's certificate chain |
| `job_code` | The lookup key for the rule corpus |
| `status` | DENY all actions for non-`active` status (already covered by session-credential validation; defense-in-depth) |
| AD group memberships (when AD backend) | Authoritative job-code source per §C.1 |

**NOT exposed**: free-text description, cost_center, owner (PGE evaluates policy; cost attribution is ACT's domain).

> **Read-source note**: the table lists what PGE *consumes*, not that all of it originates in the Roster. `agent_id` / `fingerprint` / `status` are Roster reads; the **authoritative `job_code` is read from AD groups directly** (§C.1), not from the Roster — the Roster `job_code` is only the session-scoped cache. In the AD-less lab, the Roster `job_code` is the authoritative source under the same contract surface.

### E.3 ACT (the metering + audit consumer)

Per `ACT-SPEC.md` v1.0 and the design-session decision that ACT is the metering layer (not just audit), every consumption event is tagged with `(identity, session)` and rolls up to cost-center for chargeback.

| Field exposed to ACT | Reason |
|---|---|
| `agent_id` | Identity tag for every event |
| `callsign` | Human-readable identity in audit views |
| `cost_center` | Roll-up key for chargeback (per §A.3) |
| `department` | Higher-level roll-up |
| `owner_principal_id` | Accountability key for cost reports |
| `job_code` | Tier-level roll-up |

**NOT exposed**: `birth_cert`, `fingerprint` (ACT receives the session attribution from the session credential's chain; doesn't need the IAM-side fingerprint independently).

**The metering events themselves** are ACT-side concerns (the `(identity, session)` tagging at every span, token consumption, tool call); IAM provides the *attribute set* to roll up against. The ACT spec increment will commit the event schema and the metering hooks; this IAM increment commits what's available to be rolled up.

### E.4 IBX (the messaging consumer)

Per IBX-SPEC.md v1.0 §"Identity-vs-Session at IBX", every message carries `(sender_principal_id, sender_session_id)`. The principal_id is the SOM-side `agent_id` from the Roster.

| Field exposed to IBX | Reason |
|---|---|
| `agent_id` | The PCT `principal_id` field |
| `callsign` | Inbox UI display |
| `status` | Reject messages from non-`active` principals |

**NOT exposed**: anything else. IBX is a transport; identity claims travel in the PCT, but the Roster fields IBX needs are minimal.

### E.5 Read-Only Guarantee

All four consumers (Launcher, PGE, ACT, IBX) have **read-only** access to the Roster. The Roster's only writers are:
- The Publish pipeline (B.2 mint, §D lifecycle transitions, §B.4 renewal/re-mint).
- Per `DR-IAM-4` ruling-pending: an emergency override actor (Judge) for incident-response transitions outside the normal owner-driven flow.

No agent ever writes to the Roster. No PGE / ACT / IBX / Launcher write either.

---

## Closed Decisions (CDs — v0.1 Commitments)

**IAM-INC2-CD1**: **Agent-out-of-secret-path is a load-bearing structural invariant.** Agents never touch init/unseal/login/PKI-admin/root keys. Procedural rules are not enforcement; only structural unreachability is. Every section of this spec is consistent-by-construction with this invariant.

**IAM-INC2-CD2**: **Roster record schema is committed** per §A.1, with the overtly-an-agent disclosure model per §A.2 binding the AD-DC backend and the Roster-local backend equivalently. The `cost_center` + `owner_principal_id` couplings (A.3) make "cost forces an owner" structural.

**IAM-INC2-CD3**: **ARCA-mint is atomic-or-reconciled** per §B.2 + §B.5 (per Patton FLAG 1, `bf98cc5b`). The three-system distributed write (Vault + AD + Roster) succeeds together OR an idempotent Publish-pipeline reconciliation sweep brings any partial state to a defined terminal state. Partial-mint **persistence** is inadmissible; partial states are detected, reconciled, and recorded. The Publish pipeline is the privileged actor; agents never participate. Parity with PCS-Daemon CD5 (Registry-write reconciliation) and DPG CD13 (lost-completion recovery) — same distributed-half-state structural shape, same reconciliation discipline.

**IAM-INC2-CD4**: **Birth-cert contents are committed** per §B.3 — EC P-384, ECDSA-SHA384, 1-year TTL, custom OIDs for SOM fingerprint + initial job-code. Renewal preserves identity; re-mint creates a new identity (§B.4).

**IAM-INC2-CD5**: **Federation direction is TO an external IdP (Samba/Microsoft AD), not FROM** per §C.1. AD groups are authoritative for job-code in AD-shop deployments; Roster `job_code` is the cache. AD-less deployments use Roster-local as authoritative under the same contract surface.

**IAM-INC2-CD6**: **Birthright RBAC: job-code maps automatically to permission profile + role-conditional credential set** per §C.2. Not every agent needs every credential; the mapping table lives in PGE.

**IAM-INC2-CD7**: **PGE enforces, IAM provides the job-code** per §C.3 and IAM-CORE-SPEC v1.0 SOM-MI-2. The IAM-PGE seam is read-only from PGE's side; IAM never tells PGE what to decide.

**IAM-INC2-CD8**: **Lifecycle state machine is committed** per §D.1-D.4 with the four states `pending → active → suspended → deprovisioned` and the transition authority table at D.3. Owner-driven; deprovision is terminal and stops cost.

**IAM-INC2-CD9**: **Read contract is bounded by least disclosure** per §E. Each downstream consumer sees only the fields it needs. All four are read-only; only the Publish pipeline writes the Roster.

**IAM-INC2-CD10**: **The IAM-CORE-SPEC v1.0 contract is preserved unchanged.** This increment extends it; nothing in this spec contradicts a CD/DR/VP/OQ from v1.0. Specifically: the four-services architecture, the dotted-line separation, the identity-vs-session distinction, the per-session credentials commitment, the immutable-identity / mutable-authority separation, and the trust-continuity commitments all carry through unchanged.

## Deferred-Pending-Increment-2-Rulings (DRs) — Status Inherited from IAM-CORE-SPEC v1.0

This increment **resolves** several deferral surfaces (the Roster schema, the ARCA-mint flow, the federation direction, the lifecycle state machine, the read contract). The seven `DR-IAM-*` rulings from IAM-CORE-SPEC v1.0 remain Judge-pending; this increment notes where it constrains the admissible set without front-running the ruling.

| Ruling | Status after this increment |
|---|---|
| **DR-IAM-1** (concurrency cap values per tier) | Unchanged — values still Judge-pending. The Roster `status=active` + the cost-center attribute provide the substrate the cap policy will be evaluated against. |
| **DR-IAM-2** (bootstrap credential + JIT-broker scope) | **Bounded by SOM-CD13** (external-anchor invariant, landed in PR #71) — bootstrap is always external. This increment adds that the Publish pipeline's authentication to Vault is a **non-agent service principal** authorized by Judge; agents themselves do not have a bootstrap credential to Vault (they have session credentials issued at session-start). |
| **DR-IAM-3** (revocation window cadence) | Unchanged — cadence still Judge-pending. This increment commits the operational *mechanism* (revoke via `pki_arca` CRL + AD account disable per §D.2); the cadence at which CRL is distributed remains the ruling-pending value. |
| **DR-IAM-4** (terminator failure-mode + total-flood scope) | Unchanged for runtime; **audit invariant** committed (per IAM-CORE-SPEC v1.0 SOM-CD5: every in-flight item reaches a terminal audit state). This increment commits §D.3 transition authority (owner-or-Judge) and §D.4 cost-stop semantics; the in-flight-session runtime behavior is the ruling-pending choice. |
| **DR-IAM-5** (per-session credential format and lifetime) | Unchanged — format/lifetime still Judge-pending. The session credential's chain is verifiable against the agent's birth-cert (this increment commits the cross-binding via the custom OID in §B.3); the credential's *shape* is the ruling-pending part. |
| **DR-IAM-6** (sovereignty-as-claim-vs-mode) | Unchanged. This increment is sovereign-by-default (the Roster is on-prem; the AD-DC is on-prem). Non-sovereign federation patterns (Entra ID, AWS IAM, etc.) are admissible under the pluggable-IdP commitment but would require a follow-on increment when the ruling resolves. |
| **DR-IAM-7** (ITDR scope) | Unchanged. This increment provides the substrate (per-session attribution, lifecycle state machine, read contract for ACT) that ITDR will evaluate against; what ITDR does with that substrate is the ruling-pending scope. |

## Validation-Pending (VP — design-asserted; validation against real instance pending)

**IAM-INC2-VP-1**: **IANA Private Enterprise Number (SOM-PEN) allocation.** §B.3 commits the use of two custom OIDs under `1.3.6.1.4.1.<SOM-PEN>.1.*` to carry SOM fingerprint and initial job-code in the birth-cert. The actual PEN must be allocated from IANA before any production deployment. This is operational (not Judge-pending) and is tracked as a deployment-prerequisite, not as a deferred ruling.

**IAM-INC2-VP-2**: **AD schema extension.** §A.2.1 commits the use of a custom AD attribute `somFingerprint` on the agent's AD object. AD shops require schema-extension authority (typically Domain Admin); a deployment-prerequisite check confirms the extension is in place before the first mint. Same VP shape as IAM-CORE-SPEC v1.0 VP-IAM-1 (interface absorption pending real-instance validation).

**IAM-INC2-VP-3**: **Cost-attribution end-to-end accuracy under concurrency.** §A.3 + §E.3 commit the cost-attribution model (per-session metering rolling up to cost-center). Validation against a real concurrent multi-agent run with chargeback enabled is required to confirm the per-session granularity holds across span boundaries and vendor-API boundaries. This is a real-instance validation, not a design defect.

## Open Questions (genuinely open, v0.1)

**IAM-INC2-OQ1**: **AI Gateway / broker pillar question.** The design note (`som-agent-identity-and-metering.md` §4) surfaces a unified AI gateway concept where all AI requests (human + agent, any vendor + local LLM) flow through one authenticate-and-meter chokepoint. This may warrant its own pillar/spec note. **Out of scope for IAM Increment 2** — flagged here for visibility because the chokepoint sits at the IAM↔ACT↔CRB seam and an eventual gateway spec will need to consume from this Roster schema.

**IAM-INC2-OQ2**: **AD group naming convention for SOM job-codes.** §C.1 commits federation TO AD with AD groups encoding job-codes, but does not commit the naming convention (e.g., `SOM-job-infrastructure-engineer` vs `SOM_Agents_InfraEngineer` vs a UUID-named group). Likely deployment-architecture choice; would benefit from a recommended-default if a customer-deployment template ever ships.

**IAM-INC2-OQ3**: **Renewal automation vs human-in-the-loop.** §B.4 commits renewal at TTL expiry (no identity change). Whether renewal is fully automated (Publish pipeline service handles it) or requires owner re-confirmation is a policy choice. Defaulting to automated is operationally easier; defaulting to owner-confirmation is auditor-stronger. Worth a future ruling.

**IAM-INC2-OQ4**: **Re-mint authority — same owner, different owner, or Judge-only?** §B.4 commits re-mint as a new-identity operation; §D commits owner-driven lifecycle. Re-mint after a key compromise: is the *same* owner authorized, or does that require Judge approval (since the compromise itself may indicate the owner was a vector)?

## Failure Modes To Watch

- **Agent-out-of-secret-path drift.** A future implementation adds a CLI tool that, "for convenience," lets an agent perform a Vault operation via a wrapped service-account credential. **Mitigation**: IAM-INC2-CD1 is structural; any code path that lets an agent reach a trust-ceremony surface is a spec violation reviewable at PR time.
- **Roster + AD divergence.** The Roster cache of AD group membership goes stale; PGE evaluates against the stale cache and over-authorizes a deprovisioned agent. **Mitigation**: §D.5 names DR-IAM-3 as the ruling-pending cadence; the operational shape committed (CRL + AD-disable) closes the gap once the ruling lands.
- **Partial mint.** B.2 Step 3-5 atomicity fails (e.g., AD is unreachable mid-mint); the Roster shows `pending` indefinitely. **Mitigation**: §D.2 commits `pending` as transient with a short TTL; the Publish pipeline rolls back on Step 3-5 failure.
- **Re-mint reuse without deprovision.** A new keypair is generated but the old Roster record is not deprovisioned; two records with the same callsign exist concurrently. **Mitigation**: §B.4 commits "re-mint is a different agent" — the old record transitions to deprovisioned BEFORE the new record is created.
- **Re-mint dead-agent window.** The inverse of the above: §B.4 deprovisions the old record (cert revoked, key destroyed, AD disabled) *before* the new mint runs §B.2 Step 1–5. If the new mint hits a §B.5 partial-state, the identity is fully gone with no working replacement — a dead-agent window. **Mitigation (v0.2 — names the gap; resolution deferred to the §B.4 implementation / next spec touch):** either the §B.5 reconciliation sweep must explicitly cover a stranded re-mint (detect *old-deprovisioned + no-new-active for the same callsign* → re-drive the new mint or raise a high-severity alert), **or** re-mint holds the old record in `suspended` (reversible) rather than `deprovisioned` until the new record reaches `active`. The trade-off (clean-break vs. reversible-overlap) is a §B.4 design decision flagged here, not resolved unilaterally in this fold.
- **Cost attribution to a deprovisioned owner.** The sponsoring human leaves the org; their agent continues running and accruing cost against a stale cost-center. **Mitigation**: §A.3 makes `owner_principal_id` mandatory; the human-IdP side (out of scope here, but coupled via the IdP interface) is expected to surface owner-leave events that trigger §D lifecycle transitions on owned agents.
- **AD group sprawl encoding tier-skipping permission profiles.** An AD admin adds an agent to a group its job-code shouldn't carry, bypassing the birthright RBAC discipline. **Mitigation**: §C.3 commits PGE as the enforcement layer evaluating the *current* AD group set; auditing the group memberships against the job-code → permission-profile table is an ITDR / governance concern (couples to DR-IAM-7).
- **Custom OID collision.** The PEN-encoded custom OIDs in §B.3 collide with another organization's PEN usage if the PEN is misallocated. **Mitigation**: IAM-INC2-VP-1 — PEN allocation is a deployment prerequisite, not optional.

## Dependencies

- `IAM-CORE-SPEC.md` v1.0 — the architectural contract this increment extends. Every CD/DR/VP/OQ from v1.0 stays binding.
- `SOM-IDENTITY-PILLAR-DESIGN.md` — design package for the IAM pillar; this increment is consistent with its framings.
- `SOM-INSTANTIATION-AND-IDP.md` — pluggable IdP interface; §C.1 commits the federation direction within that interface.
- `PGE-SPEC.md` v1.0 — the policy enforcement consumer; §C and §E.2 commit the IAM↔PGE seam shape.
- `ACT-SPEC.md` v1.0 — the metering + audit consumer; §E.3 commits the IAM↔ACT seam.
- `SOM-PRODUCTION-VALIDATION.md` v1.1 — the IAM row currently shows "design-stage, briefs-only"; this increment is the bridge to "operational" once Bob's build lands against this contract.
- `notes/som-agent-identity-and-metering.md` (9975) — design input (§1 Roster schema, §2 cost attributes, §3 ACT metering, §4 AI Gateway flagged as out-of-scope).
- `notes/vault-poc-runbook.md` (9975) — operational ground state; the agent-out-of-secret-path lesson; the pki_arca operational status this increment depends on.

## Success Criteria

- **First mint succeeds end-to-end.** The Publish pipeline executes the B.2 sequence, the Roster shows a `status=active` row with a valid birth-cert that verifies up to the SOM ARCA Root, the AD record (or Roster-local equivalent) shows the agent in `OU=Agents` with the matching `somFingerprint`. The agent can authenticate to Vault as itself using its private key.
- **Agent-out-of-secret-path holds in code review.** A reviewer searching for any code path where an agent process could reach init/unseal/login/PKI-admin returns zero hits.
- **AD federation works in production-shape.** PGE looks up an agent's job-code from AD groups (not from the Roster cache) and the lookup returns the expected value within the DR-IAM-3 cadence.
- **Lifecycle transitions are operator-clean.** The owner can suspend their agent through whatever the operator-facing interface is; cost reporting shows the cost stop at the suspend timestamp.
- **Read contract bounded.** A Launcher / PGE / ACT / IBX consumer querying for a field outside its allowed set (§E) returns nothing or a contract-violation error.
- **Patton dialectical sign-off.** File-based GH-native review per the doctrine landed in PR #76/#77.

## References

- `planning/IAM-CORE-SPEC.md` v1.0 — the architectural contract this increment extends
- `planning/SOM-IDENTITY-PILLAR-DESIGN.md` — design package
- `planning/SOM-INSTANTIATION-AND-IDP.md` — pluggable IdP interface
- `planning/SOM-PILLAR-NAMES.md` — canonical pillar codes
- `planning/SOM-PROBLEM-STATEMENT.md` — design drivers
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — pillar status framing
- `planning/PGE-SPEC.md` v1.0 — policy enforcement consumer
- `planning/ACT-SPEC.md` v1.0 — metering + audit consumer
- `notes/som-agent-identity-and-metering.md` (Bob, 9975) — design input for §A schema + ACT metering
- `notes/vault-poc-runbook.md` (Bob, 9975) — operational ground + the agent-out-of-secret-path lesson
- `akb-migration-plan.md` §A.1.3 lines 120–153 (ionis-devel `planning/`) — **the §A.1.3 enforcement-vs-principle ruling** Patton committed per his PR-#61 review on the AKB three-spec gate, which IAM-INC2-CD1 mirrors structurally. The principle: *"a written prohibition without a detection mechanism is exactly how the SOM-4 drift happened in the first place."*
- Patton inbox `bf98cc5b` (2026-06-03) — IAM Increment 2 v0.1 PR #3 review; source of FLAG 1 (partial-mint reconciliation), FLAG 2 (cache-staleness interim bound), and the citation-correction (required fix that moved this provenance row from `dc6ca481` — wave-2 Einstein scoping reference — to the actual §A.1.3 AKB ruling above)
- Bob PR #3 close-out review (GitHub, 2026-06-03) — source of the v0.2 consistency folds: FOLD-1 (atomic-headers consistency), FOLD-2 (cache ↔ DR-IAM-4 coupling), Note-3 (§E.2 read-source), Note-4 (re-mint dead-agent window). Posted after the v0.1 merge; folded here as the v0.2 follow-up touch.
