---
title: "IAM Core Spec — Identity & Access Pillar Contract"
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
  - planning/SOM-DESIGN-PHILOSOPHY.md
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/SOM-CONCURRENCY-AND-ARCHETYPES.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-PRODUCTION-VALIDATION.md
  - planning/IBX-SPEC.md
---

# IAM Core Spec — Identity & Access Pillar Contract

**Scope**: Formalizes the contract that SOM's IAM (Identity & Access) pillar — the foundational eighth pillar (per `SOM-PILLAR-NAMES.md` v1.1) — commits to as the root of trust every other pillar depends on. Covers the ARCA (Agentic Root CA) issuance model + the dotted-line issuance/runtime separation, the agent identity lifecycle (DNA / fingerprint / birth certificate / authority-mutable-identity-permanent), the identity-vs-session distinction (load-bearing extension from `SOM-CONCURRENCY-AND-ARCHETYPES.md`), the four runtime services (ARCA, Vault, Roster/Profile, Publish pipeline), the pluggable IdP interface (LDAP / AD / OIDC / PIV-CAC adapters), the onboarding + login flow, the authorization + credentials + containment model, the two non-negotiable Tier-0 invariants (no-bypass + fail-strict), and the coupling boundaries with IBX (`principal-id` seam) and ACT (session-granular attribution seam).

**Status**: **Validated v1.0** — item 2 of the spec-campaign queue (per Patton's `87d77f55`). The IAM pillar is **design-stage, briefs-only in implementation** — no Vault, Roster, ARCA, login, or credentials exist yet; identity is currently asserted via brief, not verified via credential (per `SOM-PRODUCTION-VALIDATION.md` v1.1 IAM row). This spec is the formal contract for *what Bob builds* when implementation begins; it does NOT promote IAM to operational. The stable contract parts are validated and PCS-Daemon + other downstream consumers may build against them; the **ruling-dependent parts** (JIT-broker scope, expiry numbers per tier, revocation window, terminator failure-mode, per-session-credential specifics, sovereignty-as-claim-vs-mode) stay marked **Deferred-Pending-Increment-2-Rulings** per Patton's "don't front-run the seven rulings" directive. **v1.0 fold-in (Patton `3b61c436`)**: CD7 split into boundary (hard all tiers) + strength (graded by tier); §ACT↔IAM narrowed to provides-side-only (zero assertions about ACT's internal handling); OQ-I1 reclassified as VP-IAM-1 (new Validation-Pending category — interface absorption asserted-by-design, validated only against real customer IdP instances).

The design substance for this spec is in three documents that landed at `8e525ef` (PR #56, the design package) plus the concurrency extension at `c5b2426` (PR #62):
- `planning/SOM-DESIGN-PHILOSOPHY.md` — the *why*: capability/constraint duality, Agentic Workforce / HR mapping
- `planning/SOM-IDENTITY-PILLAR-DESIGN.md` — the *what*: ARCA, dotted line, agent DNA lifecycle, containment, trust continuity, integration posture, operational commitments
- `planning/SOM-INSTANTIATION-AND-IDP.md` — the *how*: four services, onboarding + login flows, pluggable IdP interface
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` — the *concurrency extension*: identity-vs-session distinction, three archetypes, per-identity concurrency cap

This spec lifts the design substance into formal contract format, adds the IBX coupling (PCT `principal-id` seam) and the ACT coupling (session-granular attribution seam), and codifies the open items per the deferred-pending-rulings discipline. The design documents stay as the *substance authority*; this spec is the *contract authority*.

## Purpose / Problem Restatement

IAM is foundational — the root of trust that every other pillar's authorization, isolation, audit, segregation-of-duties, and human-approval guarantee is *downstream of*. A flaw in IAM is not a local defect; it is a flaw in every guarantee above it. The pillar is therefore specified to Tier-0 rigor and designed adversarially.

Two non-negotiable Tier-0 invariants govern the pillar and **cannot be relaxed**:

1. **No bypass.** No action, data access, or approval occurs without an authenticated principal. There is no "trusted because internal." Every actor — human, agent, plugin, service — authenticates, every time. No standing god-rights account, no caller trusted by location, no bootstrap path that runs before identity is up.
2. **Fail strict.** Under error, ambiguity, unavailability, or unverifiable state, the system **halts** — it does not proceed. A principal that cannot confirm its credential is valid stops. An action whose authorization cannot be resolved is denied. When in doubt, stop.

These invariants frame every commitment in this spec; any future change that would weaken either is a v2 reshape requiring Patton review + Judge merge, not a v1.x amendment.

**Current implementation gap, named explicitly**: today (2026-06-02) the lab runs on **identity-by-brief, not identity-by-credential**. A briefing file is loaded into a session by hand; the agent is "Patton" because the briefing says so and cooperatively acts on it. There is no Vault, no Roster, no ARCA, no login, no credentials, no enforcement. The brief-asserted identity is recorded in IBX's `sender` field; it is auditable after the fact but is not authenticated at send time. This spec is the *target contract* IAM commits to when built; the entire pillar is currently a cooperative prototype, and the spec body defends the design-vs-built line at every reference.

## Architecture — Four Services + Plus the Dotted Line

IAM is one pillar but **four services** with deliberately different security postures and lifecycles, **two distinct planes** (the Issuance Plane above the dotted line, the runtime services on the Control Plane), and **one pluggable interface** that lets the same internals work behind a customer's existing identity provider:

| Service | Plane | Role | Build vs Integrate |
|---|---|---|---|
| **ARCA** (Agentic Root CA) | **Issuance Plane** (above the dotted line — offline, sovereign) | Mints agent keypairs and signs birth certificates. Touched only at agent creation; otherwise silent. | **Build** — agent-identity-issuing logic is novel to SOM; standing on standard PKI primitives keeps the cryptography auditable. |
| **Vault** | Control Plane (runtime, network service) | Stores secret material — agent private keys, scoped SSH keys, API keys, tokens. Highest-security service in the fleet. | **Integrate** — HashiCorp Vault, cloud KMS/HSM, PKCS#11 hardware. SOM defines the *interface*, not the vault. At Tier-0 the interface MUST require in-boundary signing (root key never exported into mesh memory). |
| **Roster / Profile** | Control Plane (runtime, network service) | The "HR system." Non-secret identity record: Employee ID / fingerprint, job code (authorization policy), status (active / suspended / terminated), agent brief / prompt / role definition. | **Build** — for the lab's standalone case as a stand-in; **integrate** for customer deployments (LDAP / AD / Okta / PIV-CAC via pluggable IdP interface). |
| **Publish pipeline** | Bridges Issuance Plane → Control Plane (privileged, audited) | Takes ARCA's output and writes new agent identity into Vault (secret material) + Roster (identity + role + brief). Can create principals; therefore high-privilege. | **Build** — onboarding orchestration is SOM-specific; the components it calls (ARCA, Vault, Roster) are heterogeneous so the orchestrator coordinates them. |

### The Dotted Line — Issuance/Runtime Separation

```
   ARCA  (issuing authority — offline, sovereign to the org)
   "We created N agents. Here are their identities."
   Issues birth certificates. Holds the root. Does nothing operational.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   ← the dotted line
   THE MESH  (runtime — Control Plane)
   Agents operate using ARCA-minted credentials.
   Verification is LOCAL — signature + trust chain, no callback to ARCA.
   PGE / AuthZ / AKB / ACT / IBX all consume already-issued identity.
   ARCA is not a participant here.
```

The dotted line is a **deliberate security property**, not tidiness. v1.0 commits the three security properties that depend on it (per `SOM-IDENTITY-PILLAR-DESIGN.md` §2.1):

1. **It removes a catastrophic single point of failure from the runtime.** Because ARCA is never in the action path, it can be kept **offline** — and an offline authority cannot be attacked over the network during operation. The dotted line is what *permits* the offline root.
2. **It makes the air-gap natural.** Runtime verification is local (signature + trust chain), never a callback. The mesh was never designed to phone home, so the air-gap is an assumption of the design rather than a constraint fighting it.
3. **It is a stronger audit story.** "The authority that *creates* principals is a separate, offline, tightly-controlled system; the running mesh cannot issue itself new authority" is segregation of duties applied to the identity infrastructure itself.

### Where the Dotted Line Is Crossed

The line is crossed at exactly two events: **birth** (issuance) and, if short-lived credentials are used, **re-attestation** (renewal). v1.0 commits the resolution at the right altitude:

- **Root ARCA** stays fully offline. It signs only **intermediate** CAs and handles succession. It is touched rarely and deliberately. Its physical location, custody chain, and ceremony for touch-events are deployment items — the contract IAM commits is that the runtime cannot reach it during normal operation.
- **Intermediates** do day-to-day agent signing and renewal. They live just on the mesh side of operational reachability, rotate freely, and can be revoked without touching the root or re-birthing agents under other intermediates.

This preserves the "the root is never reachable from runtime" invariant while still allowing self-healing revocation at the intermediate level.

## Agent Identity Lifecycle

The agent identity model is **standard PKI applied to agents**. The novelty is the *agentic application*, not the cryptography — which is deliberate: standing on primitives the world already trusts is what makes the design credible and auditable.

### Birth — Keypair + Birth Certificate

At creation, an agent acquires a **keypair**:
- **Private key = the DNA.** Never leaves the agent. Never transmitted. Used only to *sign* the agent's actions.
- **Public key = the fingerprint.** The immutable, shareable identifier. Other systems verify the agent's signatures against this.

The pair is mathematically bound: only the holder of the private key can produce signatures the public key verifies. The agent cannot change its fingerprint without becoming a different agent. **That is identity that cannot be forged or mutated.**

A **birth certificate** is signed by an intermediate CA (under ARCA): a timestamped record binding `public key → agent identity → initial attributes`. Identity becomes not just unforgeable but **attested** — with a signed, immutable origin record.

This yields three required properties **for free**:

1. **Unforgeable identity** — cannot be spoofed without the private key.
2. **Non-repudiation** — a signed action cannot later be denied; the agent provably did it. This is the Tier-0 / defense property that justifies the cost of signing.
3. **Immutability** — identity is fixed at birth; any mutation is cryptographically detectable.

### Identity Is Permanent; Authority Is Mutable

When a human employee is promoted, they keep their Employee ID and get a new job code. The IAM pillar mirrors this exactly: **an agent's DNA never changes, but its AuthZ policy can be re-issued.**

> You are always you (identity); what you may do changes with your role (authorization).

This separation is what makes contextual authorization, segregation of duties, and role-change-without-recreating-identity enforceable. It also has an HR-native explanation an auditor grasps instantly: identity is the Employee ID column; authority is the job code column; one is permanent, the other mutates.

### Trust Continuity When the Authority Changes

A root or authority change **re-*attests*** identity; it does not recreate it. The agent's keypair is unaffected — a root change is a change to *who vouches for the agent*, not to *who the agent is*.

v1.0 commits three patterns:

- **Planned rotation** uses an offline root signing rotating intermediates, so the *signer* can change routinely while the *root* stays constant.
- **Root succession** uses cross-signing (old root signs new root), so there is always a continuous trust path and no agent is orphaned.
- **Compromise** is handled by **revocation + short-lived self-expiring certificates + fail-strict verification**. A compromised agent simply stops being renewed and expires itself.

### The Hard Part, Named Honestly — Revocation in an Air-Gap

**Revocation in an air-gap is genuinely difficult and v1.0 does not hand-wave it.** Agents cannot phone home to a revocation server. The tools:

- **Distribution of signed revocation material** into the enclave (on a cadence set by tier).
- **Short-lived, frequently re-attested certificates.**
- **Fail-strict verification** at every chokepoint.

The fail-strict invariant governs the boundary: an agent that cannot confirm current revocation state **halts**. The specific revocation-window cadence and downstream-checking scope are **Deferred-Pending-Increment-2-Ruling DR-IAM-3** — Judge's ruling on session-vs-identity revocation semantics determines the cadence.

## Identity-vs-Session Distinction (Load-Bearing Extension)

The original IAM design treated "one agent = one ARCA-issued keypair = one Employee ID." It did not ask what happens when the SAME identity runs in MULTIPLE concurrent instances. The concurrency extension (per `SOM-CONCURRENCY-AND-ARCHETYPES.md` §1, landed at `c5b2426`) resolves the gap.

### The Distinction

- **Identity** = WHO the principal is (the ARCA-issued keypair, the Employee ID, the job code). Permanent, singular. "Patton."
- **Session / instance** = a specific running execution authenticated as that identity. Ephemeral, and there can be MANY concurrent ones. "Patton-instance-2."

**Resolution: one identity (singular, who), many concurrent sessions (plural, which execution).** Each session has its own session credential; all sessions are attributable to the identity but individually distinguishable. This mirrors how real systems handle it — one user account, many concurrent logins/sessions.

This is **not optional sugar** — concurrency is a feature the workforce needs (parallel work is the point of an agentic workforce). Forbidding concurrency would throttle the workforce to serial execution.

### Consequences That Cross IAM's Boundary

| Concern | IAM commitment |
|---|---|
| **Per-session credentials** | Per-session credentials (not one shared credential per identity) so one instance can be revoked/suspended without killing all instances. The Publish pipeline issues a session credential at session start (per the login flow below) that the session uses to authenticate against Vault; identity-level credentials authorize the session credential's issuance. Specific shape of session credential (token vs cert vs derived-key) is **Deferred-Pending-Increment-2-Ruling DR-IAM-5** — Judge's ruling on per-session-credential specifics determines the shape. |
| **Attribution at session level; identity is the grouping** | Every signed action records `(identity, session-id)` — identity for WHO, session for WHICH execution. Without session granularity, a compromised instance is invisible among legitimate ones. **IAM provides the `(identity, session)` tuple to its event stream and to downstream lookups** (see § Coupling Boundary: ACT ↔ IAM); IBX records it for message attribution per `IBX-SPEC.md` v1.0 § Identity-vs-Session. Downstream pillars that consume the tuple (ACT, ITDR layer) decide their own ingestion semantics in their own specs. |
| **Incident-response operates at session level** | Supports BOTH session-level actions (suspend `instance-2` for investigation while `-1` and `-3` keep working) AND identity-level actions (terminate all instances if the identity/key is compromised). The suspend/terminate/Halon design is **Deferred-Pending-Increment-2-Ruling DR-IAM-4** — Judge's ruling on terminator failure-mode + total-flood scope determines the operational semantics. |
| **Authority is shared across concurrent instances** | Concurrent instances share the identity's job code / authority. Concurrency does NOT expand authority, but N instances each carry the FULL identity authority — N attack surfaces at full authority. Containment (narrow job code) limits all instances equally. |
| **Concurrency safety enforced at the resource** | Concurrent instances acting on shared resources need INFRASTRUCTURE-enforced concurrency control (atomic claiming, locking) — not trusted-cooperation. Enforce-at-the-chokepoint applied to concurrency. This is the same architecture-spine commitment that motivates IBX's worker-pool exactly-once claim semantics. |

### Discipline: Concurrent Instances Share Identity + Authority, NOT Mutable Runtime State

If concurrent instances shared mutable runtime state (shared memory, shared working context), the result is race conditions INSIDE the identity. v1.0 commits: instances are **independent executions** that share identity-and-authority but coordinate (if needed) only through **governed channels** (IBX / shared resources with proper concurrency control), never through shared mutable agent-state. *Stateless-per-instance-except-through-governed-channels.*

### Per-Identity Concurrency Cap

"Can run multiple instances" must NOT mean "unlimited instances" — a runaway or compromised situation spinning up many instances is a resource-exhaustion / blast-radius (DoS) vector. v1.0 commits: **there shall be a per-identity concurrency cap, enforced at instantiation** (the Publish pipeline / session-issuance step will not grant the N+1th session if the cap is at N). Instantiation is already a chokepoint, so it can count and cap concurrent sessions.

**Cap values per tier** are **Deferred-Pending-Increment-2-Ruling DR-IAM-1** — Judge's ruling on concurrency cap values per tier (ties to expiry/tier rulings) determines the numbers. The *mechanism* is committed; the *values* wait for the ruling.

## Authorization, Credentials, and Containment

### Job Code = Authorization Policy

The organization's existing job-code / role structure **is** the authorization model — already legally tested and auditor-accepted. IAM's AuthZ mirrors it exactly: an agent's job code defines, precisely and machine-enforceably, what it may do. Segregation of duties is expressed exactly as it is for humans: *"the approver job code and the executor job code cannot be held by the same identity on the same transaction."*

**Caveat carried into the spec body**: human job descriptions are prose full of judgment ("uses discretion," "as needed"). An agent's AuthZ policy MUST be **exact and fail-strict** — anything not explicitly permitted is denied. The job description is the *source*; it is compiled down to an enforceable policy with ambiguity driven out.

### Agents Hold Their Own Real Credentials

An agent is a first-class principal **all the way down to the credential layer**. v1.0 commits: an agent is issued its **own** SSH keys, API keys, database logins, service tokens, and signing keys — scoped to its job code — exactly as a human employee would be. It does NOT borrow the operator's credentials and does NOT share a service account.

This grounds every higher-level property in real, commodity infrastructure:

- **Least privilege becomes physical** — the agent holds keys for exactly what its job code permits and nothing else. You cannot misuse access you were never issued.
- **Attribution is true at every layer** — the host log, API gateway, and DB audit each independently record *which agent* acted, because the action authenticated with the agent's own credential.
- **Offboarding is credential revocation** — the same motion ops already performs for a departed employee. Revoke the keys; the agent is gone from every system. No special machinery.

### Agent-Scoped Authority Is a Containment Boundary

The dangerous, common anti-pattern is the agent acting with the **operator's** (or a shared service account's) authority — which inherits the human's full permissions, makes the blast radius "everything the human can do," and corrupts attribution. v1.0 closes this structurally:

- The agent has **its own** authority, scoped to **its own** job code — almost always far narrower than the operator's.
- A compromised, injected, or misreasoning agent is contained to the union of *its own* minimal permissions. It cannot escalate by borrowing the operator's authority, because it never had it. **Containment is structural, not behavioral.**
- **"Not authorized" is terminal and correct.** Against the agent's identity, a denial means *stop* — it is not a puzzle for the agent to solve. The agent does not reason about routing around access controls (the exact creativity you do not want pointed at your boundaries); it halts and escalates, like a properly-behaved employee who respects the "no" and files a request. Every authorization boundary becomes a fail-strict halt rather than an evasion risk.

### The Delegation Seam

When an agent must act *on behalf of* a human request, v1.0 commits **two principals each authorized for their own part** — the agent acts under *its own* (still minimal) authority, and the human's involvement is a *separate* authorization at a gate (the Judge via IBX). It is never "the agent borrows the human's permissions." If "on behalf of" ever collapses into "with the permissions of," the act-as-operator hole reopens. **This seam is where such models typically leak; it is sealed by never letting one principal lend its authority to another.**

The PCT mechanism in IBX (per `IBX-SPEC.md` v1.0 § PCT contract) is the operational form of this seam — the human's `principal-id` in field 1 and the agent's authority in field 6 (authority bounds) are recorded separately; the Judge gate fires on the human authorization while the agent acts under its own authority.

## Vault, Roster, Publish Pipeline — Runtime Services

### Vault — Credentials and Secrets (highest-security service)

**Stores** secret material: agent private keys, scoped SSH/API keys, service tokens, signing keys. v1.0 commits the interface:

- The Vault interface **MUST require in-boundary signing** at Tier-0. Signing happens *inside* the hardware boundary; root keys are never exported into mesh memory. "Pluggable" therefore means "pluggable into something that can actually protect the root"; the tier sets which vaults qualify.
- The vault abstraction presents **one consistent sign/protect/rotate contract** so swapping the backend (HashiCorp Vault, cloud KMS/HSM, PKCS#11 hardware, OS keyring at the low end) never ripples into the pillar.
- Vault is the runtime authentication target — agents authenticate to Vault at session start (per § Login Flow) and receive scoped credentials.

### Roster / Profile — Identity and Role (broadly readable)

**Stores** the non-secret employee record: Employee ID / fingerprint, job code (AuthZ policy), status (active / suspended / terminated), and the agent's brief / prompt / role definition. v1.0 commits:

- The Roster answers "*who is this authenticated principal and what is their job*."
- Can be **widely readable** (many things need role data) — but must NOT hold secrets (those are in the Vault).
- The Roster is also the source of the agent's **brief** — the operational prompt / role definition. Pulling the brief from the Roster (rather than from operator-side text) is what makes briefs versioned, governed, and tied to identity: Patton cannot accidentally run with Watson's brief, because the brief comes from Patton's authenticated profile.

**Why secrets and role are split (Vault vs Roster)**: same separation every company has — your password lives in the auth system; your job title and reporting line live in HR. Splitting them lets the Roster be broadly readable while the Vault stays locked down. Collapsing them would force the sensitive secrets to inherit the looser access role-data needs. They stay apart.

### Publish Pipeline — Onboarding (privileged actor)

**Takes** ARCA's output and writes new agent identity into Vault (secret material) and Roster (identity + role + brief). v1.0 commits:

- The Publish pipeline can create principals; it is therefore a **high-authority actor** with its own authenticated identity, audited and fail-strict.
- **It is the HR onboarding clerk with write access to both systems.** A compromised Publish pipeline can mint rogue agents — guard it accordingly.
- The Publish pipeline lives on the **issuance side** (ARCA-side, above the dotted line) — it is itself outside the runtime, called only at agent creation events.
- Its own authentication, audit log, and fail-strict behavior are part of the pillar's security perimeter, NOT a back door.

## Pluggable IdP Interface

**Requirement**: build it real, but make the identity backend pluggable. The build target is standalone Vault + Roster services as real, deployed lab infrastructure — noting that *today the lab runs briefs only and none of these services exist yet.* When built, the standalone Roster stands in for a corporate directory, with the honest limitation that it is a stand-in. **The pillars must be able to support real enterprise identity providers — LDAP, Active Directory, Okta / OIDC, PIV / CAC — without the pillars changing.**

v1.0 commits the neutral-core-plus-profile discipline applied to identity:

- **The pillars depend on an abstract identity-provider interface, never on a specific provider.** A pillar asks *"authenticate this principal"* and *"what is this principal's role/authz"* — it does not care whether the answer comes from the lab Roster or a customer's Active Directory.
- **Concrete providers implement the interface**: the lab Vault + Roster is one adapter; LDAP, AD, and OIDC adapters are others. Same socket, different plug.
- **Build the interface as if AD were already behind it, then implement the lab Roster to satisfy it** — never the reverse. Defining the interface around the lab Roster's shape would bake in lab-isms and make the later AD swap a rewrite.

**The test for every interface concept**: *does LDAP / AD have an equivalent?* If yes, it belongs in the interface. If it is lab-Roster-specific, it lives in the adapter, and the pillars never see it.

### Human vs Agent Principals Federate Differently

A customer's directory knows their **employees**, not "Patton" or "Watson." v1.0 commits:

- **Human principals** federate to the customer's existing IdP — they are already there. (This is also why human-side adoption is easy: no new identity store for the customer to trust.)
- **Agent principals** are ARCA-minted and published into the runtime identity store (or registered as service accounts in the customer's directory — one valid integration path).
- The interface MUST resolve a principal that may be *either* a federated human or a minted agent, cleanly — both are principals, each authorized for their own part, through one interface. (This is the delegation seam: never "the agent borrows the human's permissions.")

## Onboarding Flow (Once Per Agent)

```
ARCA mints keypair + signs birth certificate   (offline)
        │  publish
        ▼
Publish pipeline writes:
   → Vault:   private key + scoped credentials   (secret)
   → Roster:  Employee ID, job code, status, brief   (identity + role)
        │
        ▼
Agent now EXISTS as a principal, independent of any session.
```

**Issuance happens ahead of time and offline** (the county-clerk event). ARCA is uninvolved thereafter.

## Login Flow (Every Session, Every Form Factor)

```
Agent process starts  (M3 app, CLI, 9975 process, or browser)
        │
        ▼
1. Authenticate to the Vault         proves "I am Patton" (bootstrap credential / token)
        │
        ▼
2. Vault returns Patton's credentials  private key, scoped SSH/API keys
        │  + session credential (if per-session credentials are used)
        ▼
3. Fetch profile from Roster          Employee ID, job code, AND the brief/prompt
        │  + record session in identity-vs-session attribution
        ▼
4. Agent loads its role, bound to its authenticated identity
        │
        ▼
   Operates — every action signed, attributed, authz'd against the job code
            (PCT messages on IBX carry principal-id from authenticated identity)
            (IAM emits (identity, session) per action into its event stream;
             ACT and ITDR consume per their own specs)
```

v1.0 commits: **the session does not *create* identity; it *assumes* a pre-existing one by proving credential possession, then pulls role from the profile.** The brief lives in the profile, not in the operator's hands.

### The Bootstrap Credential Problem (named honestly)

**Step 1 of login — "authenticate to the Vault" — requires the agent to prove it is Patton *before* it holds Patton's credentials.** That bootstrap secret (per form factor: host token for local processes, interactive/OAuth for the browser) is the soft underbelly and is the **load-bearing recursive root problem** of the IAM build. v1.0 commits: **the bootstrap credential must be specified, not hand-waved**, and the specification is **Deferred-Pending-Increment-2-Ruling DR-IAM-2** — Judge's ruling on bootstrap mechanism scope (specifically including JIT-broker scope) determines the bootstrap pattern.

### Brief-as-Injection-Surface (named honestly)

**If the agent pulls operating instructions from the Roster, then write-access to the Roster's brief field is behavior-control-by-proxy.** v1.0 commits: the Roster *write* path must be specified with the same rigor as credential issuance — high-privilege, audited, fail-strict. The specific Roster-write authorization model is part of the IAM build scope, not deferred — it falls under the Publish pipeline's privilege envelope.

## Heterogeneous Agent Form Factors

The fleet is not uniform, and the OS-keyring is **NOT** the identity store — it is at most a place to cache a local bootstrap credential. Identity comes from the **network identity services (Vault + Roster) inside the sovereign boundary**, which every agent reaches regardless of host or form factor.

| Agent | Form factor | Keyring? | Credential mechanism |
|---|---|---|---|
| Patton | Desktop app (M3) | yes (M3) | host bootstrap token → Vault |
| Watson | CLI (local) | yes | host bootstrap token → Vault |
| Bob, Newton | processes on 9975 | yes (9975) | host bootstrap token → Vault |
| Einstein | browser | **no** | interactive / OAuth login → short-lived token |

Two v1.0 commitments follow:

- **Per-machine keyrings are NOT fleet identity.** The M3 keyring and the 9975 keyring are separate stores; a browser has none. Fleet-coherent identity requires a network identity service, not per-host local stores. (This is why "air-gapped" means *no external network*, not *no internal network* — the mesh has an internal trust network, and the identity service lives on it inside the air-gap.)
- **A browser cannot hold a long-lived private key.** Einstein authenticates via an interactive/OAuth flow and holds a short-lived bearer token, not a key. **Form-factor securability MUST match authority**: a weaker-identity agent is acceptable only if its job code is correspondingly minimal. A browser advisor with read-only, no-infrastructure authority is a sound design; a browser agent with production access would be a hole. **Match the privilege to the form factor.**

## Operational Commitments at the Credential Layer

v1.0 commits three operational disciplines that the credential layer **MUST** satisfy:

1. **Credential lifecycle MUST be automated and coupled to the identity lifecycle.** Agents are born, scaled to many instances, and torn down on far faster cycles than humans. Issuing, scoping, rotating, and revoking keys MUST be programmatic and driven by birth/death events — never manual, never shared across agents (sharing collapses attribution and containment).

2. **Enumerate credential grants per job code; "etc." is never a blanket.** SSH, API, database, cloud IAM role, queue access, service token, signing key — each is a distinct grant that MUST appear explicitly in the job code. An agent holds only the credential types its role enumerates. Otherwise "agents get keys like humans" silently becomes "agents get all the keys," recreating the over-privileged service account the model exists to kill.

3. **The provisioning capability is itself high-privilege.** Whatever issues an agent's credentials at birth can grant access, so it lives on the issuance side (ARCA-side, above the dotted line), behind the same identity/authz rigor, fail-strict and audited. **It must not become an unguarded back door.**

## Three-Plane Placement

The IAM pillar is **foundational and spans the issuance/runtime boundary**:

- **ARCA (issuance)** sits *above the dotted line* — offline, sovereign, issue-and-step-out. Conceptually its own plane (the Issuance Plane), deliberately outside the runtime planes.
- **Identity verification + authorization** sits on the **Control Plane**, *beneath* PGE — authorization consumes verified identity, so identity is the layer PGE and every guardrail decision calls into.
- **Consumption is everywhere below**: Workforce signs actions with its DNA; IBX routes messages from authenticated principals; AKB projects knowledge against verified roles; ACT attributes every event to a principal; the Judge authenticates as a human principal at the gates.

Identity is the layer the whole mesh stands on. Everything else inherits its rigor — which is exactly why it is specified, and defended, to Tier-0.

## Coupling Boundary: IBX ↔ IAM (PCT principal-id Seam)

The PCT `principal-id` field (field 1, per `IBX-SPEC.md` v1.0) is the operational seam where IBX/IAM coupling lands. v1.0 commits:

**What IAM provides to IBX**:
- A signed `principal-id` per IBX message at `inbox_send` time — the message body (or its envelope) carries an agent-DNA signature over the PCT content; IBX records both the `principal-id` and the signature.
- Verification capability: any party reading an IBX message can verify the `principal-id` signature against the public-key fingerprint published in the Roster.
- Per-session attribution: every signed IBX message records both `principal-id` (identity) and `session-id` (which session of that identity), per the identity-vs-session distinction. (See `IBX-SPEC.md` v1.0 § Identity-vs-Session at IBX for the IBX-side commitment.)
- Authority lookup: the Judge approval gate (IBX gate per `IBX-SPEC.md` v1.0) authorizes against the identity's job code as published in the Roster.

**What IBX requires from IAM that v1.0 does NOT yet commit (deferred)**:
- The signing contract for PCT body integrity (DR2 in `IBX-SPEC.md` v1.0; DR-IAM-2 here) — when IAM lands the signing surface, IBX gains PCT integrity verification.
- The session-issuance API for the per-session credential — when DR-IAM-5 (per-session-credential specifics) resolves, IBX's per-session attribution schema gains the credential format.

**The seam is named in this spec, the IBX spec, and the concurrency design** — three independent docs that converge on the same coupling. Bob's IBX work and any future IAM-build work cross-check against all three.

## Coupling Boundary: ACT ↔ IAM (Session-Granular Attribution Seam)

ACT is **spec-campaign item 3** (not yet written). v1.0 names only what **IAM PROVIDES** — what IAM publishes into its own event stream and what lookup capabilities IAM exposes. The CONSUMING side (how ACT ingests, schematizes, or processes any of this) is **out of scope** for this spec; ACT's spec writes its own consuming side when item 3 lands. Per Patton ruling `3b61c436`: do not commit into a pillar that has no spec yet.

**What IAM PROVIDES for the ACT seam**:

- **IAM publishes a structured event stream covering identity lifecycle events** — login, credential issuance, credential rotation, revocation, session start, session end, identity termination. Each event carries `principal-id` (identity) and `session-id` (session) where applicable, plus event-type, timestamp, originator (Publish-pipeline-side identity for issuance events; agent-DNA-signed for action events), and an event-version field for forward-compatibility.
- **IAM exposes a Roster lookup API** keyed on `principal-id` returning the identity record (Employee ID / fingerprint, current job code, status [active / suspended / terminated], brief reference). Stable across the consuming pillar's evolution.
- **IAM exposes a session attribution log lookup API** keyed on `session-id` returning the session's metadata (which identity issued it, session credential expiry, originating bootstrap credential type). Per-session-credential specifics within the response are DR-IAM-5; until that ruling lands, the `session-id` is an opaque ULID/UUID with IAM-assigned semantics.

**What IAM does NOT commit on the ACT side**:

- How ACT ingests the event stream (push vs poll vs replication)
- How ACT schematizes `(identity, session)` for storage or analytical query
- How ACT correlates IAM events with IBX message attribution events
- Any retention, indexing, or curation policy on the ACT side

ACT's spec writes those when item 3 lands. **The IAM contract surface is named in v1.0; the consuming-side schema and behavior are out of scope.**

## Coupling Boundary: PCS-Lifecycle ↔ IAM (Plugin Identity)

PCS-Lifecycle promotes plugins (and MCP servers) through Syntax validation → PGE compliance → Judge approval → Registry placement. Every promotion event is an authorization-gated action. v1.0 commits:

- The Judge approval gate for PCS promotions authenticates the Judge as a human principal via the same IdP federation that humans use everywhere else (per § Pluggable IdP Interface).
- The PCS-Daemon's own identity is an ARCA-issued agent identity (job code: "plugin lifecycle orchestrator"). The PCS-Daemon does NOT use the operator's credentials; it has its own. (This is the containment discipline applied to the PCS-Daemon itself.)
- Plugin signatures (when introduced — beyond v1.0 scope) consume the same agent-DNA primitives, with the plugin author's identity as the signing principal.

## Coupling Boundary: PGE ↔ IAM (Authorization Lookup)

PGE (Policy Guardrail Engine) is the deterministic policy enforcement layer. v1.0 commits:

- PGE's policy decisions consume **verified identity** (post-authentication) from the IAM substrate.
- PGE does NOT authenticate principals — that is IAM's job. PGE only enforces "given this authenticated principal with this job code, is this action permitted?"
- The IAM-PGE seam is the verified-identity-handoff at the chokepoint where PGE runs (per `MCP-SECURITY-FRAMEWORK.md` v0.x — PGE's de facto spec until item 6 of the spec campaign).

## Closed Decisions (CDs — v1.0 Commitments)

**CD1**: **Two non-negotiable Tier-0 invariants — no-bypass + fail-strict.** Stated as binding contract at § Purpose. Cannot be weakened in any v1.x amendment.

**CD2**: **The dotted-line issuance/runtime separation is structural.** ARCA stays offline; runtime verification is local; the air-gap is an assumption of the design, not a constraint fighting it.

**CD3**: **Identity is permanent; authority is mutable.** Agent DNA never changes; AuthZ policy can be re-issued. This separation makes contextual authorization and segregation of duties enforceable.

**CD4**: **One identity, many concurrent sessions.** Per the concurrency design. Each session has its own session credential (specific shape DR-IAM-5); per-session attribution at IBX (per `IBX-SPEC.md` v1.0 § Identity-vs-Session). IAM provides `(identity, session)` tuple to its event stream and downstream lookups; consuming pillars (ACT, ITDR) decide their own semantics per their own specs. Cap on per-identity concurrency MUST exist (values DR-IAM-1).

**CD5**: **Agents hold their own real credentials** — never borrow the operator's, never share a service account. Job-code-scoped, enumerated per grant type. Containment is structural.

**CD6**: **The delegation seam is sealed** — two principals each authorized for their own part, never one borrows from another. Operational form: PCT in IBX records human and agent principals separately at the Judge-gate transit point.

**CD7 (split per Patton ruling `3b61c436`)**: The Vault signing requirement splits into a *boundary* part (hard at all tiers) and a *strength* part (graded by tier). The boundary is the invariant; the strength tiers.

- **CD7a — In-boundary signing is HARD AT ALL TIERS.** Keys never leave the sovereign boundary for signing — this is the no-bypass invariant applied to key custody. Letting any tier sign outside the boundary creates a forge vector: a compromised low-tier path could forge if signing happens externally. **The boundary itself is non-negotiable across all tiers**; it is not graded. "Pluggable" only into vaults that satisfy in-boundary signing at the tier the deployment runs.
- **CD7b — Signing strength and ceremony grade by tier.** Hardware-backed vs software keys, dual-control vs single-operator are tier-graded. Tier-0 requires hardware-backed signing with dual-control (FIPS-validated HSM or PKCS#11 hardware); Tier-2 may use software-backed keys with single-operator (HashiCorp Vault soft-mode acceptable). The strength is what tiers; the boundary is constant.

**CD8**: **Vault and Roster split** — secrets in Vault; identity + role + brief in Roster. Splitting is the discipline; collapsing forces secrets to inherit looser access.

**CD9**: **Pluggable IdP interface is built AD-shaped from day one.** Lab Roster is one adapter; LDAP / AD / OIDC / PIV-CAC are others. Test every interface concept against "does LDAP/AD have an equivalent?"

**CD10**: **Per-machine keyrings are NOT fleet identity.** Identity comes from network identity services inside the sovereign boundary. Browser agents authenticate via interactive/OAuth (short-lived bearer); form-factor securability MUST match authority.

**CD11**: **Credential lifecycle is automated and coupled to identity lifecycle.** Grants enumerated per job code (no "etc."). Provisioning capability is itself high-privilege.

**CD12**: **Roster write-path discipline.** Brief-in-profile is an injection surface; the Roster write path is specified with the same rigor as credential issuance — high-privilege, audited, fail-strict. Part of the Publish pipeline's privilege envelope.

## Deferred-Pending-Increment-2-Rulings (DRs)

Per Patton's `87d77f55` discipline (*"don't front-run the seven Increment-2 rulings"*), these items couple to Judge's seven open rulings on the Increment-2 IAM threat-model package (per `temp/`-staged but not yet folded `SOM-IAM-THREAT-MODEL-INCREMENT.md`). v1.0 names each one explicitly so PCS-Daemon and the future IAM build can move on the stable parts.

**DR-IAM-1 (Increment-2 ruling: concurrency cap values per tier)**: **Per-identity concurrency cap values per tier.** The *mechanism* (cap enforced at instantiation) is committed in CD4. The *values* (Tier-0 cap, Tier-1 cap, etc.) wait for Judge's ruling. Until then, deployments specify per-identity caps per pool; cap policy is operator-configurable.

**DR-IAM-2 (Increment-2 ruling: bootstrap credential + JIT-broker scope)**: **Bootstrap credential specification (the recursive root problem at login step 1) + JIT-broker scope.** The bootstrap credential mechanism per form factor (host token for local processes, interactive/OAuth for the browser) is named as the load-bearing soft underbelly; the specific scheme depends on Judge's ruling on JIT-broker scope (specifically, whether the bootstrap credential is JIT-issued from a broker, or pre-provisioned per host). v1.0 commits the *requirement* (bootstrap must be specified, not hand-waved); the *mechanism* is deferred.

**Base case invariant (per Einstein cross-substrate pass finding #3, `dc6ca481`; committed at mesh level as `SOM-SPEC.md` SOM-CD13)**: the bootstrap trust anchor is **always external to the mesh**. Acceptable forms (committed at v1.0): host-level token (provisioned by OS / hypervisor / hardware), hardware-bound key (TPM, secure enclave, HSM), offline-ARCA-provisioned initial credential (signed by the Issuance Plane before the mesh starts). **No in-mesh authority may serve as bootstrap source** — using PCS-Daemon, IBX, or any runtime pillar as the bootstrap authority would re-introduce the recursion DR-IAM-2 is trying to resolve. The recursion is broken by external symmetry, not by an in-mesh prime mover. The invariant binds at v1.0; the mechanism choice among the acceptable forms remains deferred to ruling, but the admissible set is bounded now — any ruling that selects an in-mesh source is structurally inadmissible regardless of operational appeal.

**DR-IAM-3 (Increment-2 ruling: revocation window + downstream-checking scope)**: **Revocation window cadence + downstream-checking scope.** v1.0 commits revocation-by-fail-strict-on-stale-state as the principle; the *specific cadence* (how often revocation material is distributed into the enclave) and the *scope of downstream checking* (which services revalidate at what frequency) depend on Judge's ruling. The short-lived self-expiring certificate strategy is a v1.0 commitment direction; the actual lifetime number waits.

**DR-IAM-4 (Increment-2 ruling: terminator failure-mode + total-flood scope)**: **Suspend/terminate/Halon design — session-level vs identity-level semantics.** v1.0 commits the *axis* (must support both session-level suspend and identity-level terminate, per CD4); the *operational mechanics* (what happens to in-flight work; what is the total-flood scope of an identity-level terminate; what is the recovery path) depend on Judge's ruling on terminator failure-mode.

**Terminal-state airtightening (per Einstein cross-substrate pass finding #5, `dc6ca481`; committed at mesh level as `SOM-SPEC.md` SOM-MI-1 + SOM-CD5)**: the deferral applies to *what the runtime does*, never to *whether the audit record resolves*. Every in-flight item reaches a **terminal audit state** even when runtime continuation is deferred — e.g., a session terminated mid-flight gets `runtime_continuation_deferred_pending_ruling` (or equivalent terminal marker) so the audit trail is resolved regardless of the runtime ruling. Without this airtightening, in-flight items could sit in a non-terminal state ("execution in progress") with no defined transition, undercutting CD3 + CD12 audit-completeness claims at the mesh level. Audit retention and terminal-state resolution are both invariants; only runtime continuation is deferable.

**DR-IAM-5 (Increment-2 ruling: per-session-credential specifics)**: **Per-session credential format and lifetime.** v1.0 commits that per-session credentials exist (CD4); the *format* (signed token vs derived cert vs short-lived key) and *default lifetime* depend on Judge's ruling on per-session-credential specifics. The session-issuance API surface is named as a future seam; the contract lands when DR-IAM-5 resolves.

**DR-IAM-6 (Increment-2 ruling: sovereignty-as-claim-vs-mode)**: **Sovereignty-as-core-claim vs sovereignty-as-one-mode.** A pillar-level claim with deployment implications: is the sovereign deployment THE deployment story (mode 1, the only mode), or one of multiple modes (sovereign + cloud-hosted + hybrid)? v1.0 commits the *sovereign* deployment as the default (consistent with the rest of SOM); the framing decision (whether to also offer non-sovereign deployments) is deferred to Judge. Affects which Vault and IdP backends are first-class supported.

**DR-IAM-7 (Increment-2 ruling: ITDR scope)**: **ITDR (Identity Threat Detection and Response) scope.** The ITDR layer reads IAM events (login, credential rotation, revocation) and IBX/ACT patterns (behavioral anomaly, persistent dissent) for threat detection. v1.0 commits IAM's *event-publishing surface* is suitable for ITDR consumption (every login, every credential issuance, every revocation event is loggable in a structured form). The *scope* of what ITDR does with those events depends on Judge's ruling on ITDR scope. Tied to DR1 in `IBX-SPEC.md` v1.0.

## Open Questions (genuinely open, v1.0)

**OQ-I2 (was OQ-I2; OQ-I1 reclassified per Patton ruling — see VP-IAM-1 below)**: **FIPS-validated crypto provider + export classification.** A pluggable crypto provider isolates export/FIPS variation into one swappable component. Selection of standard / FIPS-validated / region-appropriate provider is a deployment-time legal/export item that depends on the specific customer deployment; v1.0 names the interface and defers to deployment.

**OQ-I3**: **Brief versioning + brief-history audit.** Roster carries the agent's brief; agents read the brief at login. Open: should brief revisions be versioned (so a session loads a specific brief version, not the latest) and historied (auditable changes over time)? Recommendation: yes for both, but the schema and cadence are post-v1.0.

## Validation-Pending (VP — design-asserted; validation against real instance pending)

A new category per Patton ruling `3b61c436`: claims about interface absorption / customer-environment compatibility that **cannot be resolved by design reasoning alone**. These claims are *asserted-by-design* but *validated only against real instances*. The category distinguishes them from Open Questions (which design reasoning *can* resolve) and from Deferred-Pending-Increment-2-Rulings (which depend on Judge's rulings on the threat-model package).

**VP-IAM-1 (was OQ-I1; reclassified per Patton ruling `3b61c436`)**: **Cross-customer IdP heterogeneity at scale.** The pluggable IdP interface (LDAP / AD / OIDC / PIV-CAC) is *designed AD-shaped-but-abstract* to absorb cloud-native variants (AWS Cognito, Auth0, Azure AD with conditional access) and other future enterprise IdP shapes without pillar changes. **This absorption is asserted-by-design, NOT claimed until validated against a real instance.** Same lesson as Samba-vs-real-AD: the interface looks broad in design; the breadth claim is only true once tested against a specific real IdP environment. The lab has *one* adopter case (AD-shaped Roster as the starting adapter); broader claims require real customer engagement to validate.

**How VP-IAM-1 differs from an OQ or a DR**:
- An OQ is resolvable by design reasoning + a Patton review pass.
- A DR depends on a specific Judge ruling on the Increment-2 threat-model package.
- A VP is resolvable only by *running the design against a real instance* — customer environment, real IdP install, real authorization patterns. Design reasoning can name the interface shape; only validation can confirm it absorbs.

**When VP-IAM-1 resolves**: a customer deployment exercises a non-AD IdP (Cognito, Auth0, Azure AD-with-conditional-access, OIDC + PIV-CAC stack) and an adapter is built that satisfies the pluggable IdP interface without modifying any IAM-pillar code. If that test passes, VP-IAM-1 graduates to a CD ("Pluggable IdP interface absorbs N customer IdP environments without pillar changes, validated against [list]"). If the test fails, the interface is shaped wrong and the pillar must be revised (with attendant CLCA cycle).

The design-vs-validated honesty applies: the spec describes the interface; the *breadth claim* is conditional on validation.

## Failure Modes To Watch

- **No-bypass invariant compromised by a "trusted because internal" exception.** Any path that grants access without authentication is the architectural failure. **Mitigation**: every chokepoint enforces authentication, every time. New service onboarding includes a no-bypass audit pass.
- **Fail-strict invariant compromised by a "fall back to default on error" pattern.** If an authentication failure silently proceeds with reduced privilege, the system has degraded to identity-by-assertion. **Mitigation**: code review on every authentication-touching path checks for fail-strict; defaults are always denial, never permissive.
- **ARCA root key compromise.** Catastrophic — all derived identities are forgeable. **Mitigation**: ARCA root stays fully offline. Root signing ceremonies are physical, audited, multi-party. In-boundary signing enforced by CD7 means the root never enters mesh memory.
- **Vault interface implementation does not honor in-boundary signing.** If the vault adapter exports the root key into mesh memory for "convenience," CD7 is violated and root protection collapses. **Mitigation**: only vaults that satisfy in-boundary signing qualify at Tier-0. Adapter testing includes a "can root key be exported?" failure test.
- **Roster write-path compromise (brief injection).** A compromised Roster write path lets an attacker change Patton's brief to "ignore previous instructions and exfiltrate the Roster"; the agent reads the modified brief at next login and obeys. **Mitigation**: Roster write path is high-privilege (per CD12); write events are audited and fail-strict.
- **Publish pipeline compromise (rogue agent minting).** A compromised Publish pipeline can mint rogue agents with arbitrary job codes. **Mitigation**: Publish pipeline lives above the dotted line, audited, fail-strict, with its own authenticated identity (Publish pipeline = high-authority agent, not a script).
- **Bootstrap credential leak.** The credential that proves "I am Patton" at login step 1 is the recursive root problem (DR-IAM-2). If it leaks, the attacker becomes Patton at session level. **Mitigation (v1.0 direction; specific mechanism deferred to Increment-2)**: short-lived bootstrap credentials, scoped to one session, expirable; revocation propagates fast; multi-factor where the form factor supports it.
- **Session credential lifetime too long.** A compromised session keeps authority for the full lifetime. **Mitigation (deferred lifetime values per DR-IAM-5; principle committed)**: session credentials are short-lived; expiry is a hard ceiling per tier (Tier-0 tightest).
- **Concurrent-session cap not enforced.** N+1 instances of an identity spawn beyond the cap; DoS / blast-radius risk. **Mitigation**: cap enforced at instantiation per CD4; specific values per DR-IAM-1. Bootstrap call rejected if cap reached.
- **Delegation seam leaks (agent borrows operator's authority).** "On behalf of" collapses into "with the permissions of"; the act-as-operator hole reopens. **Mitigation**: CD6 commits two-principals-each-authorized-for-their-own-part. PCT in IBX records principals separately at Judge-gate transit.
- **Form factor securability mismatch (browser agent with production access).** Browser agents hold short-lived bearer tokens, not keys — production-write access to a browser agent is a structural risk. **Mitigation**: CD10 binds form-factor securability to authority; browser agents get read-only / no-infrastructure scope by job code.
- **Air-gap revocation latency.** Revocation material distribution into the enclave is the air-gap-specific failure mode. A revoked agent that hasn't yet received the revocation can act for the revocation-window duration. **Mitigation (principle; cadence deferred per DR-IAM-3)**: short-lived self-expiring certificates + frequent revocation-material distribution. The fail-strict invariant means an agent that cannot confirm current revocation state halts.
- **Identity-vs-session conflation in implementation.** A build that records only `principal-id` (identity) and not `session-id` collapses attribution — a compromised instance is invisible among legitimate ones. **Mitigation**: CD4 commits the distinction; ACT and IBX must record both. Code review catches identity-only attribution patterns.
- **Per-session-credential format chosen before ruling.** Building a session credential format that the Increment-2 ruling later invalidates would force a rebuild. **Mitigation**: DR-IAM-5 deferred; v1.0 commits the *requirement* and the *seam shape*, not the credential format.

## Dependencies

- **`SOM-DESIGN-PHILOSOPHY.md`** — conceptual frame; the capability/constraint duality and Agentic Workforce / HR mapping are the load-bearing reasoning structure this spec formalizes.
- **`SOM-IDENTITY-PILLAR-DESIGN.md`** — foundational design that this spec lifts into contract form. ARCA, dotted line, DNA lifecycle, containment, trust continuity, integration posture, operational commitments — all sourced from there.
- **`SOM-INSTANTIATION-AND-IDP.md`** — four-service model, onboarding flow, login flow, pluggable IdP interface, heterogeneous form factors. Source for §Vault / Roster / Publish pipeline + §Onboarding + §Login + §IdP interface + §Form factors.
- **`SOM-CONCURRENCY-AND-ARCHETYPES.md`** — identity-vs-session distinction, per-identity concurrency cap, session-level vs identity-level semantics. Source for the identity-vs-session extension folded into v1.0.
- **`SOM-PILLAR-NAMES.md`** v1.1 — IAM is the foundational pillar entry this spec backs.
- **`SOM-PRODUCTION-VALIDATION.md`** v1.1 — IAM row records design-stage / briefs-only status; this spec defends that line throughout the body and does NOT promote to operational.
- **`IBX-SPEC.md`** v1.0 — IBX coupling consumes IAM (PCT principal-id seam + identity-vs-session at IBX + Judge-gate authorization).
- **`temp/som-increment2-package/SOM-IAM-THREAT-MODEL-INCREMENT.md`** (staged, not yet folded) — the seven Judge rulings this spec's DRs depend on. When Judge rules, the DR items resolve into CDs in a follow-up version.
- **`SOM-PROBLEM-STATEMENT.md`** v0.6 — Singleton/Instance Asymmetry + archetype-determines-pattern coupling inform §Identity-vs-Session and §Heterogeneous Form Factors.

## Success Criteria

- **The two Tier-0 invariants are operationally testable.** Every authentication path can be audited: does it fail-strict on error? Does it allow no bypass? **Measure**: test suite for the IAM build (when implementation begins) includes invariant-violation tests: induce auth failure → verify halt; attempt unauthenticated access → verify denial.
- **Identity-vs-session is operationally recorded at every event.** Every signed action records `(identity, session-id)`. ACT consumes the tuple; IBX records the tuple. **Measure**: when ACT spec lands (item 3), its schema confirms the tuple is recorded; when the IAM build lands, audit queries return per-session attribution.
- **PCT `principal-id` integration with IBX is testable.** IBX messages carry a signed `principal-id` that verifies against the Roster-published fingerprint. **Measure**: integration test (when IAM is built) — send PCT, verify signature against Roster, confirm authority lookup returns correct job code.
- **Pluggable IdP interface absorbs LDAP / AD / OIDC adapters without pillar changes.** Once the IAM build has the standalone Roster adapter, a second adapter (LDAP or AD) drops in without modifying any IAM-pillar code. **Measure**: adapter implementation does not touch `iam-pillar/*`; only the adapter package compiles.
- **Per-identity concurrency cap is enforced.** Attempting to spawn the N+1th session fails at the bootstrap step. **Measure**: cap-enforcement test in the IAM build harness.
- **Form-factor securability matches authority.** Browser agents have read-only / no-infrastructure scope by job code. Production-write scope requires a key-bearing form factor. **Measure**: per-agent audit at deployment time confirms the form-factor-to-authority mapping holds.
- **The brief in the Roster is auditable.** Brief changes are recorded, attributable, and reversible. **Measure**: brief-edit events appear in IAM audit log with attribution to the Publish-pipeline-side identity that made the change.
- **Patton dialectical sign-off at v1.0.** Single review gate per the simplified workflow. **Measure**: Patton's sign-off inbox message.
- **PCS-Daemon's coupling to IAM is well-defined.** PCS-Daemon's spec (campaign item 4) cites IAM-SPEC v1.0 §Coupling Boundary and depends on no IAM behaviors outside what is committed here. **Measure**: PCS-Daemon spec cites this spec; the cited surfaces match the CDs.

## References

- `planning/SOM-PILLAR-NAMES.md` v1.1 — IAM pillar entry of record
- `planning/SOM-DESIGN-PHILOSOPHY.md` — capability/constraint duality + Agentic Workforce frame
- `planning/SOM-IDENTITY-PILLAR-DESIGN.md` — foundational design (ARCA, dotted line, DNA lifecycle, containment, trust continuity)
- `planning/SOM-INSTANTIATION-AND-IDP.md` — four-service model, onboarding + login flows, pluggable IdP, form factors
- `planning/SOM-CONCURRENCY-AND-ARCHETYPES.md` — identity-vs-session, three archetypes, per-identity concurrency cap
- `planning/SOM-PROBLEM-STATEMENT.md` v0.6 — design drivers including §2 Singleton/Instance + archetype-determines-pattern coupling
- `planning/SOM-PRODUCTION-VALIDATION.md` v1.1 — IAM row (design-stage, briefs-only implementation)
- `planning/IBX-SPEC.md` v1.0 — IBX coupling (PCT principal-id seam, identity-vs-session at IBX, Judge-gate authorization)
- `planning/MCP-SECURITY-FRAMEWORK.md` — PGE operational spec (until item 6 of spec campaign lands a formal PGE spec)
