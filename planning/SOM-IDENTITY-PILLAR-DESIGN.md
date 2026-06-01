# SOM Identity Pillar — Foundational Design

*Provisional name: Sovereign Orchestration Mesh (SOM). Working draft — the foundational pillar specification. Companion to SOM-DESIGN-PHILOSOPHY.md. Pillar count, naming, and "SOM"/"ARCA" labels are provisional pending the full specification pass and name clearance.*

---

## 0. First principle

**Identity is the root of trust. Without it, nothing else binds.**

Identity is foundational, not one pillar among equals. Every other guarantee in the mesh — authorization, isolation, audit, segregation of duties, the human approval gates — is *downstream* of identity and inherits its strength. A flaw in identity is therefore not a local defect; it is a flaw in every guarantee above it. For that reason the identity pillar is specified to the highest rigor tier (Tier-0) and is designed adversarially: not "what features does it have," but "how does an attacker defeat the root, and what happens to everything above it when they do."

Two invariants follow and are non-negotiable at Tier-0:

- **No bypass.** No action, data access, or approval occurs without an authenticated principal. There is no "trusted because internal." Every actor — human, agent, plugin, service — authenticates, every time. No standing god-rights account, no caller trusted by location, no bootstrap path that runs before identity is up.
- **Fail strict.** Under error, ambiguity, unavailability, or unverifiable state, the system **halts** — it does not proceed. A principal that cannot confirm its credential is valid stops. An action whose authorization cannot be resolved is denied. When in doubt, stop.

---

## 1. The organizing metaphor: the Agentic Workforce is a workforce

The entire pillar maps one-to-one onto something every board, auditor, and security team already understands: **the employee lifecycle.** This is not a loose analogy; it is the structural template, and it is also the explanation that lets a non-technical approver understand and sign off on the system.

| Human organization | SOM / Agentic Workforce |
|---|---|
| HR / issuing authority | **ARCA** (Agentic Root CA) — issues, then steps out |
| Employee ID (immutable) | Agent **fingerprint** (public key) |
| The person themselves | Agent **DNA** (private key) |
| Employee profile / record | Agent identity record + birth certificate |
| Job code / job description | **AuthZ policy** — what this agent may do |
| Badge-in / authenticate | Sign action with private key |
| SSH keys, API keys, logins | Agent's **own** scoped credentials |
| Manager / approval chain | **Judge** gate (human authority, Tier-0) |
| Personnel file / audit | **ACT** telemetry (immutable attribution) |
| Onboarding | Agent **birth** (keypair + certificate) |
| Role change / promotion | Re-issued AuthZ policy, **same identity** |
| Termination / offboarding | **Revocation** (credentials invalidated) |

The plain-language statement of the whole pillar: *Each agent is an employee. It has a permanent Employee ID it cannot forge, a job description that bounds exactly what it may do, its own credentials issued to that identity and scoped to that job, it badges in for every action so everything is attributable, high-stakes actions route to a human manager for sign-off, and when it is decommissioned it is offboarded like any employee — credentials revoked, ID retired but retained in the record.*

A CISO can approve that. A board can fund it. A regulator already governs employees this way.

### The critical boundary the metaphor must not blur

An employee is one continuous entity that can be held **personally** accountable — fired, sued, prosecuted. An agent can be cloned, scaled to many parallel instances, and torn down at no personal cost. The HR mapping is exact for **structure** (identity, authorization, audit, offboarding) but must never be read to transfer **liability**: accountability for an agent's actions terminates in a **human** (the Judge, the operator, the organization), never in the agent. The Employee ID exists for *attribution and control*, not *legal personhood*. The mapping governs the mechanism; humans hold the liability. This is why the Judge pillar exists and why human authority and agent capability are each only half the solution.

---

## 2. ARCA — the issuing authority

**ARCA (Agentic Root CA)** is the per-organization root of trust for agent identity. The hospital / county clerk: it issues the birth certificate and then has no further role in the principal's life.

- **Per-organization and sovereign.** Each customer runs its own ARCA. This settles the mint-vs-federate question by default: identity is sovereign to the organization, with no dependency on the vendor or any external root — exactly what an air-gapped deployment requires. Every org *is* its own authority.
- **Issuance only — no operational function.** ARCA mints identities and steps out. It says "these agents exist; here are their identities," and is then silent. It is **not** a runtime participant: not reachable, not queried, not in the action path.

### The dotted line (issuance / runtime separation)

```
   ARCA  (issuing authority — offline, sovereign to the org)
   "We created N agents. Here are their identities."
   Issues birth certificates. Holds the root. Does nothing operational.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   ← the dotted line
   THE MESH  (runtime)
   Agents operate using ARCA-minted credentials.
   Verification is LOCAL — signature + trust chain, no callback to ARCA.
   PGE / AuthZ / AKB / ACT all consume already-issued identity.
   ARCA is not a participant here.
```

Separating the issuing authority from the runtime is a deliberate security property, not tidiness:

1. **It removes a catastrophic single point of failure from the runtime.** Because ARCA is never in the action path, it can be kept **offline** — and an offline authority cannot be attacked over the network during operation. The dotted line is what *permits* the offline root; they are the same decision.
2. **It makes the air-gap natural.** Runtime verification is local (signature + trust chain), never a callback. The mesh was never designed to phone home, so the air-gap is an assumption of the design rather than a constraint fighting it.
3. **It is a stronger audit story.** "The authority that *creates* principals is a separate, offline, tightly-controlled system; the running mesh cannot issue itself new authority" is segregation of duties applied to the identity infrastructure itself — a control auditors specifically look for.

### Where the line is crossed — and at what altitude

The dotted line is crossed only at **birth** (issuance) and, if short-lived credentials are used, at **re-attestation** (renewal). These two needs are in tension: a never-touched offline root argues for long-lived certificates; self-healing revocation argues for short-lived ones. The resolution sets the line at the right altitude:

- **Root ARCA** stays fully offline. It signs only **intermediate** CAs and handles succession. It is touched rarely and deliberately.
- **Intermediates** do day-to-day agent signing and renewal. They live just on the mesh side of operational reachability, rotate freely, and can be revoked without touching the root or re-birthing agents under other intermediates.

This preserves "the root is never reachable" while still allowing self-healing revocation at the intermediate level.

---

## 3. Agent identity lifecycle (the "birth," the DNA, and trust continuity)

This is a standard PKI applied to agents. The novelty is the *agentic application*, not the cryptography — which is deliberate: standing on primitives the world already trusts is what makes the design credible and auditable.

- **Birth.** At creation, an agent acquires a **keypair**. The **private key is the DNA** — never leaves the agent, never transmitted, used only to *sign* the agent's actions. The **public key is the fingerprint** — the immutable, shareable identifier. The pair is mathematically bound: only the holder of the private key can produce signatures the public key verifies. The agent cannot change its fingerprint without becoming a different agent. That is identity that cannot be forged or mutated.
- **Birth certificate.** An intermediate (under ARCA) signs a timestamped record binding public key → agent identity → initial attributes. Identity becomes not just unforgeable but **attested**, with a signed, immutable origin record.

This yields the three required properties for free:
- **Unforgeable identity** — cannot be spoofed without the private key.
- **Non-repudiation** — a signed action cannot later be denied; the agent provably did it. (This is the Tier-0/defense property that justifies the cost of signing.)
- **Immutability** — identity is fixed at birth; any mutation is cryptographically detectable.

### Identity is permanent; authority is mutable

When an employee is promoted, they keep their Employee ID and get a new job code. Likewise: **an agent's DNA never changes, but its AuthZ policy can be re-issued.** You are always you (identity); what you may do changes with your role (authorization). This separation is what makes contextual authorization and segregation of duties enforceable, and it has an HR-native explanation an auditor grasps instantly.

### Trust continuity when the authority changes

A root or authority change re-*attests* identity; it does not recreate it. The agent's keypair is unaffected — a root change is a change to *who vouches for the agent*, not to *who the agent is*.

- **Planned rotation** uses an offline root signing rotating intermediates, so the *signer* can change routinely while the *root* stays constant.
- **Root succession** uses cross-signing (old root signs new root), so there is always a continuous trust path and no agent is orphaned.
- **Compromise** is handled by revocation + short-lived, frequently re-attested certificates + fail-strict verification. A compromised agent simply stops being renewed and expires itself.

### The hard part, named honestly

**Revocation in an air-gap** is genuinely difficult and must not be hand-waved: agents cannot phone home to a revocation server. Distribution of signed revocation material into the enclave (on a cadence set by tier), and short-lived self-expiring certificates, are the tools. The fail-strict invariant governs the boundary: an agent that cannot confirm current revocation state **halts**.

---

## 4. Authorization, credentials, and containment

### Job code = authorization policy

The organization's existing job-code / role structure *is* the authorization model — already legally tested and auditor-accepted. SOM's AuthZ mirrors it: an agent's job code defines, precisely and machine-enforceably, what it may do. Segregation of duties is expressed exactly as it is for humans: "the approver job code and the executor job code cannot be held by the same identity on the same transaction."

Caveat carried into the spec: human job descriptions are prose full of judgment ("uses discretion," "as needed"). An agent's AuthZ policy must be **exact and fail-strict** — anything not explicitly permitted is denied. The job description is the *source*; it is compiled down to an enforceable policy with ambiguity driven out.

### Agents hold their own real credentials

An agent is a first-class principal **all the way down to the credential layer**. It is issued its **own** SSH keys, API keys, database logins, service tokens, and signing keys — scoped to its job code — exactly as a human employee would be. It does not borrow the operator's credentials and does not share a service account.

This grounds every higher-level property in real, commodity infrastructure:
- **Least privilege becomes physical** — the agent holds keys for exactly what its job code permits and nothing else. You cannot misuse access you were never issued.
- **Attribution is true at every layer** — the host log, API gateway, and DB audit each independently record *which agent* acted, because the action authenticated with the agent's own credential.
- **Offboarding is credential revocation** — the same motion ops already performs for a departed employee. Revoke the keys; the agent is gone from every system. No special machinery.

### Agent-scoped authority is a containment boundary

The dangerous, common anti-pattern is the agent acting with the **operator's** (or a shared service account's) authority — which inherits the human's full permissions, makes the blast radius "everything the human can do," and corrupts attribution. SOM closes this structurally:

- The agent has **its own** authority, scoped to **its own** job code — almost always far narrower than the operator's.
- A compromised, injected, or misreasoning agent is contained to the union of *its own* minimal permissions. It cannot escalate by borrowing the operator's authority, because it never had it. Containment is structural, not behavioral.
- **"Not authorized" is terminal and correct.** Against the agent's identity, a denial means *stop* — it is not a puzzle for the agent to solve. The agent does not reason about routing around access controls (the exact creativity you do not want pointed at your boundaries); it halts and escalates, like a properly-behaved employee who respects the "no" and files a request. Every authorization boundary becomes a fail-strict halt rather than an evasion risk.

### The delegation seam (spec carefully)

When an agent must act *on behalf of* a human request, the clean model is **two principals each authorized for their own part** — the agent acts under *its own* (still minimal) authority, and the human's involvement is a *separate* authorization at a gate (the Judge). It is never "the agent borrows the human's permissions." If "on behalf of" ever collapses into "with the permissions of," the act-as-operator hole reopens. This seam is where such models typically leak; it is sealed by never letting one principal lend its authority to another.

---

## 5. Integration posture (build the novel, integrate the solved)

The identity pillar is novel only where it should be — the agentic identity and governance model. Everything commodity is integrated, not rebuilt:

- **Vault.** The ARCA root key and agent secrets live in an existing, mature, often FIPS-validated vault/HSM (e.g. HashiCorp Vault, cloud KMS/HSM, PKCS#11 hardware, OS keyring at the low end). SOM defines the *interface*, not the vault. **At Tier-0 the interface must require in-boundary signing** — signing happens *inside* the hardware boundary; the root key is never exported into mesh memory. "Pluggable" therefore means "pluggable into something that can actually protect the root"; the tier sets which vaults qualify. The vault abstraction presents one consistent sign/protect/rotate contract so swapping the backend never ripples into the pillar.
- **Crypto.** A **pluggable crypto provider** isolates export/FIPS variation into one swappable component. The agent-DNA model stays simple and universal; a deployment selects a standard provider (commercial/finance), a FIPS-validated provider (defense), or a region-appropriate provider (export). Signatures/authentication ("agent DNA") are treated more leniently under export rules than encryption-for-confidentiality, which keeps the common case clean — but FIPS-validated-provider and international-shipment classification remain deployment-time legal/export items, contained behind the interface and deferred to the moment a specific defense or international customer is live (with counsel).
- **Existing IAM.** Because each agent is a principal with its own identity and job-code authority, it plugs into the customer's existing AuthN/AuthZ (AD, Okta, PIV/CAC, database grants, service ACLs) the same way a human employee does. There is no parallel permission universe to integrate — the agent simply looks like an employee to the systems that already grant access.

---

## 6. Operational commitments the credential layer forces

- **Credential lifecycle must be automated and coupled to the identity lifecycle.** Agents are born, scaled to many instances, and torn down on far faster cycles than humans. Issuing, scoping, rotating, and revoking keys must be programmatic and driven by birth/death events — never manual, never shared across agents (sharing collapses attribution and containment).
- **Enumerate credential grants per job code; "etc." is never a blanket.** SSH, API, database, cloud IAM role, queue access, service token, signing key — each is a distinct grant that must appear explicitly in the job code. An agent holds only the credential types its role enumerates. Otherwise "agents get keys like humans" silently becomes "agents get all the keys," recreating the over-privileged service account the model exists to kill.
- **The provisioning capability is itself high-privilege.** Whatever issues an agent's credentials at birth can grant access, so it lives on the issuance side (ARCA-side, above the dotted line), behind the same identity/authz rigor, fail-strict and audited. It must not become an unguarded back door.

---

## 7. Three-plane placement

The identity pillar is **foundational and spans the issuance/runtime boundary**:

- **ARCA (issuance)** sits *above the dotted line* — offline, sovereign, issue-and-step-out. Conceptually its own plane (the issuance plane), deliberately outside the runtime planes.
- **Identity verification + authorization** sit on the **Control Plane**, *beneath* PGE — authorization consumes verified identity, so identity is the layer PGE and every guardrail decision calls into.
- **Consumption** is everywhere below: Workforce signs actions with its DNA; IBX routes messages from authenticated principals; AKB projects knowledge against verified roles; ACT attributes every event to a principal; the Judge authenticates as a human principal at the gates.

Identity is the layer the whole mesh stands on. Everything else inherits its rigor — which is exactly why it is specified, and defended, to Tier-0.

---

*Status: foundational design, provisional. Open decisions deliberately surfaced rather than settled: (a) certificate lifetime (long-lived vs. short-lived self-expiring) against the air-gap constraint; (b) the exact in-boundary-signing requirements per tier; (c) FIPS provider and export/international items, deferred to live customer + counsel. These are next-pass spec items, not gaps in the model.*
