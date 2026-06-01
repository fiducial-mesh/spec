# SOM Instantiation & Identity Provider Integration

*Provisional. Companion to SOM-IDENTITY-PILLAR-DESIGN.md. Defines how agents are onboarded and how they authenticate and load their role at session start, and how the identity backend stays pluggable across lab and customer deployments. Names ("ARCA", "SOM", "Roster") provisional.*

---

## 0. The instantiation question

When a session opens "as Patton," how does the agent know who it is, and where does its identity come from? The durable answer: **the agent logs in.** Identity and role are not asserted by whoever starts the session — they are retrieved by the agent from services, by authenticating. This is identical to how any company onboards and logs in an employee. The employee logs in; now the agent logs in.

### Current state vs. design target — stated plainly

**What exists today: briefs only.** A briefing file is loaded into a session by hand; the agent is "Patton" because the briefing says so and cooperatively acts on it. There is no Vault, no Roster, no ARCA, no login, no credentials, no enforcement. Identity is asserted, not verified — and the agent follows its brief because it is a well-behaved model, not because anything *enforces* the role. This is a cooperative prototype.

**What this document describes: the build target.** Everything below — the four services, the onboarding flow, the login flow, the pluggable identity-provider interface — is *design for what is intended to be built.* None of it is currently running. The whole value of the target over the current state is the move from **identity-by-assertion** (the brief says who you are) to **identity-by-control** (you prove who you are with a credential, and your authority is enforced at the infrastructure layer, not merely described in a prompt).

Nothing in this document may be represented as operational. It is the design to build toward, from a starting point of briefs-only.

---

## 1. Components

Four services, kept deliberately separate because they have different security postures and lifecycles.

### ARCA — issuing authority (offline, above the dotted line)
The signing key. Its only job is to mint agent keypairs and sign their birth certificates/identities. It is not a runtime service: it issues, then steps out. Its one touch-point with the rest of the system is the **publish** step (see below). Otherwise it stays dark.

### Vault — credentials and secrets (runtime, network service, inside the boundary)
Holds the **secret** material: agent private keys, scoped SSH keys, API keys, tokens. This is what an agent authenticates *to* at login. Highest-security service in the fleet; tightly access-controlled. **Integrate, do not build** (e.g. HashiCorp Vault, cloud KMS/HSM, PKCS#11).

### Company Roster / Profile service — identity and role (runtime, network service)
The "HR system." Holds the **non-secret** employee record: Employee ID / fingerprint, job code (authorization policy), status (active / suspended / terminated), **and the agent's brief / prompt / role definition.** Answers "who is this authenticated principal and what is their job." Can be widely readable (many things need role data); must not hold secrets (those are in the Vault).

### Publish pipeline — onboarding (privileged)
Takes ARCA's output and writes the new agent's identity into the Vault (secret material) and the Roster (identity + role + brief). It can create principals, so it is a high-authority actor with its own authenticated identity, audited and fail-strict. The HR onboarding clerk with write access to both systems. A compromised publish pipeline can mint rogue agents — it is guarded accordingly.

### Why secrets and role are split (Vault vs Roster)
Same separation every company has: your password lives in the auth system; your job title and reporting line live in HR. Splitting them lets the Roster be broadly readable while the Vault stays locked down. Collapsing them would force the sensitive secrets to inherit the looser access role-data needs. Keep them apart.

---

## 2. The onboarding flow (happens once, per agent)

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

Issuance happens ahead of time and offline (the county-clerk event). ARCA is uninvolved thereafter.

---

## 3. The login flow (happens every session, on any host or form factor)

```
Agent process starts  (M3 app, CLI, 9975 process, or browser)
        │
        ▼
1. Authenticate to the Vault         proves "I am Patton" (bootstrap credential / token)
        │
        ▼
2. Vault returns Patton's credentials  private key, scoped SSH/API keys
        │
        ▼
3. Fetch profile from Roster          Employee ID, job code, AND the brief/prompt
        │
        ▼
4. Agent loads its role, bound to its authenticated identity
        │
        ▼
   Operates — every action signed, attributed, authz'd against the job code
```

The session does not *create* identity; it *assumes* a pre-existing one by proving credential possession, then pulls role from the profile. **The brief lives in the profile, not in the operator's hands** — the agent retrieves who it is rather than being told. This makes briefs versioned, governed, and tied to identity: Patton cannot accidentally run with Watson's brief, because the brief comes from Patton's authenticated profile.

---

## 4. Heterogeneous agent form factors

The fleet is not uniform, and the OS-keyring is **not** the identity store — it is at most a place to cache a local bootstrap credential. Identity comes from the **network identity services (Vault + Roster) inside the sovereign boundary**, which every agent reaches regardless of host or form factor.

| Agent | Form factor | Keyring? | Credential mechanism |
|---|---|---|---|
| Patton | Desktop app (M3) | yes (M3) | host bootstrap token → Vault |
| Watson | CLI (local) | yes | host bootstrap token → Vault |
| Bob, Newton | processes on 9975 | yes (9975) | host bootstrap token → Vault |
| Einstein | browser | **no** | interactive / OAuth login → short-lived token |

Two consequences:
- **Per-machine keyrings are not fleet identity.** The M3 keyring and the 9975 keyring are separate stores; a browser has none. Fleet-coherent identity requires a network identity service, not per-host local stores. (This is why "air-gapped" means *no external network*, not *no internal network* — the mesh has an internal trust network, and the identity service lives on it inside the air-gap.)
- **A browser cannot hold a long-lived private key.** Einstein authenticates via an interactive/OAuth flow and holds a short-lived bearer token, not a key. **Form-factor securability must match authority:** a weaker-identity agent is acceptable only if its job code is correspondingly minimal. A browser advisor with read-only, no-infrastructure authority is a sound design; a browser agent with production access would be a hole. Match the privilege to the form factor.

---

## 5. Pluggable identity provider (lab today, customer IdP tomorrow)

**Requirement: build it real, but make the identity backend pluggable.** The build target is standalone Vault + Roster services as real, deployed lab infrastructure (not conceptual mockups) — noting that *today the lab runs briefs only and none of these services exist yet.* When built, the standalone Roster stands in for a corporate directory, with the honest limitation that it is a stand-in. The pillars **must** be able to support real enterprise identity providers — LDAP, Active Directory, Okta/OIDC, PIV/CAC — without the pillars changing.

The mechanism is the same neutral-core-plus-profile discipline applied to identity:

- **The pillars depend on an abstract identity-provider interface, never on a specific provider.** A pillar asks "authenticate this principal" and "what is this principal's role/authz" — it does not care whether the answer comes from the lab Roster or a customer's Active Directory.
- **Concrete providers implement the interface:** the lab Vault + Roster is one adapter; LDAP, AD, and OIDC adapters are others. Same socket, different plug.
- **Build the interface as if AD were already behind it, then implement the lab Roster to satisfy it** — never the reverse. Defining the interface around the lab Roster's shape would bake in lab-isms and make the later AD swap a rewrite. The test for every interface concept: *does LDAP/AD have an equivalent?* If yes, it belongs in the interface. If it is lab-Roster-specific, it lives in the adapter, and the pillars never see it.

### Human vs agent principals federate differently
A customer's directory knows their **employees**, not "Patton" or "Watson." So:
- **Human principals** federate to the customer's existing IdP — they are already there (this is also why human-side adoption is easy: no new identity store for the customer to trust).
- **Agent principals** are ARCA-minted and published into the runtime identity store (or registered as service accounts in the customer's directory, one valid integration path).
- The interface must resolve a principal that may be *either* a federated human or a minted agent, cleanly — both are principals, each authorized for their own part, through one interface. (This is the delegation seam: never "the agent borrows the human's permissions.")

---

## 6. Open design items (carried forward, not yet resolved)

1. **The bootstrap credential is a recursive root problem.** Step 1 of login — "authenticate to the Vault" — requires the agent to prove it is Patton *before* it holds Patton's credentials. That bootstrap secret (per form factor: host token for local processes, interactive/OAuth for the browser) is the soft underbelly and must be specified, not hand-waved.
2. **The brief-in-profile is an injection surface.** If the agent pulls operating instructions from the Roster, then write-access to the Roster's brief field is behavior-control-by-proxy. The Roster *write* path must be specified with the same rigor as credential issuance — high-privilege, audited, fail-strict.
3. **The publish pipeline is privileged.** It can create principals; it needs its own authenticated identity, audit, and fail-strict behavior. Not an unguarded script.
4. **POC scope must stay honest.** A POC that proves *the flow* (authenticate → pull credentials → pull role/brief → operate, all attributed) is achievable and valuable, and is what the lab will demonstrate. It is **not** the production-hardened system (HSM-backed ARCA key, full revocation, every form-factor bootstrap solved, air-gap-correct). The validation record must state which one was built. "Working POC of the identity/login flow" is a true, strong claim; "production identity system" would not be, yet.

---

*Status: provisional companion design. Current state: briefs only — no services exist yet. Build target: real Vault + Roster microservices + ARCA app/signing key + publish pipeline + agent-side login flow, run in the lab as if deployed, with a standalone Roster standing in for a corporate IdP and the identity-provider interface defined to be IdP-shaped from the start so LDAP/AD/OIDC adapters drop in without pillar changes.*
