---
title: "AMP — Agentic MultiPlexer (Candidate Pillar Brief)"
status: CANDIDATE — non-normative seed for the dialectical chain. NOT yet part of STD-001.
origin: Judge, 2026-06-20
authors: [watson]
sequencing: New pillar → v1.2 / increment scope, NOT a v1.1.1 correction. See §6.
---

# AMP — Agentic MultiPlexer (Candidate Pillar Brief)

> **Status: candidate / vision-stage.** This brief seeds the standard dialectical chain
> (Watson structural draft → Bob/panel structural pass → Patton adversarial → Einstein
> first-principles → Judge merge). It is **not normative** and adds nothing to STD-001 / HDBK-001
> until it clears that chain. Captured here so the design and its open questions are on the dated
> record (which is also how the novelty is credited under the open-source / defensive-publication
> posture — the spec + paper are the prior-art trail).

## 1. One line

**AMP is a spec-defined multiplexer for cognition** — it routes agent-LLM calls across many
backends and many hardware architectures through one contract. A crossbar switch: **N agent-LLMs ×
M backends/architectures** routed through one switching layer.

**"Multi-Multi" = Multi-Agent-LLM × Multi-ARCH.** Two axes:
- **Multi-Agent-LLM** — native agent calls (Claude Code, Codex, Grok) + local fleet (Daina, Melody).
- **Multi-ARCH** — inference architectures: Apple **MLX**, NVIDIA **CUDA**, **Intel (oneAPI/SYCL)**, cloud, extensible.

## 2. Motivation — sovereign *and* hybrid (the load-bearing value)

AMP is the primitive that makes the same agent workload deployable across the sovereignty spectrum
**under one contract**:
- **Sovereign** — route everything to local backends (all-OSS, air-gappable); no call leaves the tenancy.
- **Hybrid** — route *sensitive* work to local backends and *burst / non-sensitive* work to cloud,
  by policy, with the routing decision itself auditable.

The deployment changes; the agent code and the contract do not. This is substrate-pluggability
(IP-1) pushed down to the **model and the silicon** — not just "swap the database," but "swap the
LLM and the architecture under the same agent loop."

## 3. Structural fit — the Spec-Harness-Registry primitive, 3rd instance

AMP is the same **Contract + Conformance + Registry** shape already identified as a reusable
Mesh-Invariant (PCS for plugins; IP-1 for substrate):

| Element | AMP |
|---|---|
| **Contract** | **polymorphic by port type** (§3a): for *endpoint* backends, the LLM provider **API spec** (Anthropic Messages / OpenAI Chat-Completions); for *CLI* backends, the **subprocess invocation interface** |
| **Conformance** | "does this backend satisfy *its port-type* contract" (a `*-v1`-style test set per port type) |
| **Registry** | the available backends, each tagged with its **port type** (§3a) + **billing mode** (§5a) |

A backend plugs in by satisfying its contract — exactly how a plugin plugs into PCS or a substrate
component satisfies IP-1.

## 3a. Two port types — the crossbar has heterogeneous ports (Judge, 2026-06-20)

The backends are NOT all the same shape; the spec must model this explicitly so **AMP doesn't pretend
a TUI is an endpoint**:

| Port type | Backends | What the "port" is | Contract | Auth |
|---|---|---|---|---|
| **Endpoint** | Daina, Melody, Newton (local, OpenAI-compatible) | an HTTP endpoint | the **provider API spec** (HTTP) | scoped key / AppRole |
| **CLI / agentic** | Claude Code, Grok Build, Codex | a **subprocess** with its own session | the **invocation interface** (argv / stdin prompt / stdout+exit / env) — *not* an HTTP spec | the CLI's **own OAuth / subscription** |

AMP routes uniformly at the agent-call level, but the **adapter differs by port type** — an HTTP client
for endpoints, a subprocess driver for CLIs. Port type is **independent of the arch axis** (§5): an
endpoint backend runs on MLX/CUDA; a CLI backend is typically the cloud frontier agent. **A CLI is its
own port class with its own conformance profile — model it, don't HTTP-ify it.**

## 3b. The request contract — payload attributes select the topology (Judge, 2026-06-20)

**The routing topology is not a mode of the AMP instance — it's a property of the request.** The caller
submits a payload; the payload's attributes declare what it wants — a single backend, or a panel + arbiter
(§5d). Same endpoint, same contract; **the payload picks the route.** This is exactly the "based on the
provider's own API spec" doctrine (§4): AMP takes the provider-API payload and **extends it with a
routing-control attribute namespace**, e.g.:

| Attribute | Effect |
|---|---|
| *(none)* | policy-driven 1:1 route — AMP/PGE picks the backend |
| `amp.backend` / `amp.backends` | target a specific backend or **backend set** (set ⇒ fan-out) |
| `amp.mode: single \| panel` | 1:1 routing vs `1:N → N:1` (§5d) |
| `amp.arbiter` | which port reconciles the panel (LLM / reducer / human) |
| `amp.data_class` | declares sensitivity → feeds PGE's routing decision |

For the **CLI port type** (§3a) the same intent rides invocation flags/args rather than a JSON body —
"request attributes," generalized across both port types.

**Critical guardrail — payload is *intent*, PGE is *decision*.** A caller asking for a cloud backend on
sensitive data does **not** get it by putting it in the payload — **policy still governs and may override
or reject.** The payload is a *request*, not a *grant*. This preserves the §5b dependency direction (AMP
consumes PGE; the payload can't escalate past it) and is what keeps payload-driven routing safe.

## 3c. The route IS the access surface — chokepoint + consolidation (Judge, 2026-06-20)

**Whatever can reach the AMP route can drive everything behind it** — every backend, the arbiter, the
meter. So the API route is *the* access-control surface; the security of the whole crossbar reduces to
controlling access to that one route. Two faces:

- **The payoff — access consolidates.** Today each backend is secured independently (and Daina was found
  wide open, §5c). Under AMP the backends go **private** — localhost-bound, reachable *only via AMP* — and
  the single AMP route carries auth + identity + policy + metering. **N doors to defend → one governed
  door.** Strictly better, *provided the route is locked with the same doctrine applied per-endpoint
  today:* **authenticated + source-bound.**
- **The risk — the route is the key.** "Anything with access can use it" means route access = capability.
  So the route must **not** be a single shared key, or it is a skeleton key to the whole fleet. Mitigation:
  the route is **identity-scoped** (each caller authenticates as *itself* via IAM, not a shared secret)
  and **PGE-bounded** (policy decides what that identity may route to — which backends, which data class).
  So "anything with access" is precisely **"any authenticated identity, limited to what policy grants
  it."** That is what stops the consolidation from becoming a single point of total compromise.

Composes with §3b: to use AMP you (a) **authenticate to the route** as a known identity (IAM), (b) your
**payload requests** a topology/backend (§3b), (c) **PGE decides** what you actually get. Three layers,
and the payload can never escalate past (a) or (c). This is today's endpoint-hardening finding completed
one layer up: secure each endpoint → then let endpoints go private behind **one** authenticated,
source-bound, identity-scoped, policy-gated route. **The AMP route is the highest-value door in the fleet;
it inherits the access doctrine in full.**

## 4. Doctrine — adopt the plugin system, don't invent it

> *"We didn't invent the plugin system; we're merely USING the plugin system in the Mesh."* — Judge

AMP **adopts proven OSS** as its mechanism (Claude Code Router / `claude-code-router`, MCP, the
provider SDKs) and routes through each agent's **native interface**, transforming at the seam
(Anthropic API → OpenAI-compatible, as CCR does) — never forcing a new format on any agent. This is
the cardinal-rule (speak agents' native vocabulary) + adopt-proven-OSS doctrine applied to routing.
It is also the **systematic form of vendor-diverse cognition** (Anthropic / OpenAI / xAI / local) —
routing diversity becomes a pillar instead of a manual habit.

## 5. Architecture substrate matrix (the Multi-ARCH axis)

| Capability | MLX (Apple) | NVIDIA (CUDA) | Intel (oneAPI/SYCL) | Cloud |
|---|---|---|---|---|
| Local coder | — | Daina (Qwen3-Coder, llama.cpp) | — | — |
| Local reasoner | Melody (Qwen2.5-72B, mlx_lm) | (Newton, llama.cpp, dormant) | — | — |
| Light / scribe | — | Jacob (EPYC RTX-5080) | (Iris Xe — OpenVINO/SYCL, small models) | — |
| Frontier agent | — | — | — | Claude Code / Grok / Codex |

The spec makes **MLX, NVIDIA, and Intel first-class** so a deployment picks its architecture column the
way the Requirements×Houses matrix picks a vendor column — the conformance test is the invariant, the
architecture is the swappable axis. (This is AMP's paper figure: the pluggability thesis one layer deeper
than usual — across **model × silicon**.) **Intel added 2026-06-21:** the substrate walk found a real
Intel GPU in the fleet (§5.1), so the local arch axis is **three vendors, not two** — the cheapest
possible proof that "Multi-ARCH" is more than MLX-vs-CUDA.

**Frontier-agent accounts the lab holds (2026-06-21): Claude (Max), Grok (SuperGrok), and Codex/OpenAI
(ChatGPT Plus — CLI + Desktop).** The frontier column is the **Multi-Agent-LLM axis** — but with a
**capability asymmetry verified 2026-06-21**, and the two frontier *roles* are NOT symmetric:
- **Evaluation (§5e)** is **vendor-neutral** — adjudicating is just an agent call; Claude, Grok, *or*
  Codex all qualify.
- **Trigger/origination (§6.6)** is **capability-gated** — it needs a *scheduled/autonomous runner*. **Two
  held vendors have one — Claude Desktop and Codex Desktop** (Judge-verified equivalents); **Grok has none**
  (Grok Build CLI + SuperGrok TUI, no scheduler).

So the trigger is **multi-vendor but not universal** — AMP must model it as a **capability some vendors
lack** (Grok), not assume vendor-neutrality. And because *two* held runners have it, the swap is actually
**testable** (§8), not hypothetical. AMP must no more hardcode Claude *for evaluation* than it hardcodes CUDA.

### 5.1 Concrete fleet — the real substrate the arch axis must describe (walked 2026-06-21)

**Five accelerators, three local architectures, four boxes — and two host OSes that gate roles.** This
inventory is itself a substrate-first artifact — it is *what the spec's arch axis has to be able to model*:

| Box | OS | Accelerator | Arch | Mem | Tier | Persona |
|---|---|---|---|---|---|---|
| M3 Ultra | macOS | unified | Apple MLX | 96 GB | heavyweight reasoner | Melody |
| 9975 | Rocky 9 | RTX PRO 6000 · Blackwell | CUDA | 96 GB | heavyweight coder | Daina |
| EPYC | Rocky 9 | RTX 5080 · Blackwell | CUDA | 16 GB | fast light / scribe | Jacob |
| ASUS SCAR 17 | Windows | RTX 3080 Ti · Ampere | CUDA | 16 GB | can-wait batch | — |
| ASUS SCAR 17 | Windows | Iris Xe iGPU | Intel oneAPI/SYCL | shared | small-model / heterogeneity proof | — |

**Consolidated matrix (Judge, 2026-06-21):** frontier = **Claude + Codex** (each CLI **and** Desktop App;
Grok being retired — no Desktop App) **×** these four compute boxes. Three routing/placement dimensions
fall straight out of it — all **worked substance for the §6.1 CRB seam** (kept open there, recorded here,
*not* resolved):
- **Capacity-fit** — a 70B job routes to a 96 GB card, never a 16 GB one. *Will it fit* is a hard
  constraint, not a preference.
- **Generation/speed-tier** — both 16 GB cards fit the same model, but **Blackwell (5080) ≫ Ampere
  (3080 Ti)** in throughput: latency-sensitive → Blackwell, can-wait nightly batch → Ampere. *How fast it
  must finish* is a second axis above raw fit.
- **Trigger-host eligibility (OS-gated, §6.6)** — a Desktop-app trigger runner needs a **GUI OS**
  (macOS/Windows) *and* always-on. So the **M3 (macOS, always-on + UPS) is the prime trigger host**; the
  Windows laptop is GUI-capable but sleeps (secondary); the **Rocky 9 servers (9975, EPYC) cannot host a
  Desktop app at all** — headless, they run CLI + the local-LLM inference endpoints. The OS splits the
  fleet into **trigger-hosts** (GUI desktops) and **compute / endpoint-hosts** (headless servers).

## 5a. Billing-aware + the metering chokepoint (Judge, 2026-06-20) — "crossbar AND meter"

Two functions fall out of AMP being the single point every agent-LLM call traverses:

1. **Billing-path correctness (a routing constraint).** Each backend has a **billing mode** —
   *subscription/OAuth* (Claude Code = Max, Grok Build = SuperGrok), *metered API* (api.anthropic.com,
   api.x.ai), or *local/free* (Daina/Melody/Newton). AMP **must route to the subscription/local path and
   NEVER silently to a metered-API path** without an explicit billing decision. This makes the *"no
   provider-API billing stacked on subscriptions"* doctrine — the exact trap flagged on the Grok path —
   an **enforced routing rule**, not a manual habit/audit.
2. **Metering chokepoint.** Every call emits a metering record — **(agent identity, backend, port type,
   billing mode, token counts / cost)** — straight into **ACT**. Per-(agent, backend, tokens) accounting
   falls out *for free* because every call already flows through the crossbar. It's also the natural data
   source for the deferred **ABS** (Agentic Billing System): AMP meters, ABS attributes/bills.
   The **telemetry sink is pluggable** (Judge, 2026-06-20): **ACT is the warehouse when Mesh-integrated**,
   or AMP writes to a **standalone store when running alone**. The meter is *intrinsic* to AMP; *where it
   lands* is the swappable part — so standalone metering does not require ACT (preserving §"dual-mode").

**Crossbar and meter.**

## 5b. Pillar relationships (Judge wants this explicit in the spec)

AMP is a **policy consumer + meter producer**, not an island:

| Pillar | Relationship |
|---|---|
| **PGE** | AMP **consumes** PGE policy: *"may agent X use backend Y for data-class Z?"* (e.g. sensitive → local-only). PGE decides, AMP **enforces** the routing. Routing policy is PGE's domain. |
| **ACT** | AMP **produces** to ACT: every routing decision + per-call metering → ACT's audit ledger + telemetry. AMP is the **meter**; ACT consumes. |
| **IAM** | AMP **consumes** identity from IAM — needed for per-agent routing policy and per-agent metering. |
| **ABS** (deferred) | AMP's metering feeds ABS for contract attribution / usage rollups. |

Same dependency-direction shape as everywhere: AMP's **routing core is self-sufficient**; PGE/ACT/IAM
are **additive** governance layered on top — consumed by AMP for decisions, fed by AMP for audit, never
reaching into the core. (This is *also* why standalone mode works: strip PGE/ACT/IAM and the core still
routes.)

## 5d. Fan-out + arbiter — the dialectical topology (Judge, 2026-06-20)

The Multi-Multi crossbar's higher-value mode isn't 1:1 (route a call to the right backend) — it's
**`1:N → N:1`**: fan one logical question out to a *set* of backends, then route the compared responses
to an **arbiter** that reconciles them. AMP makes this **dynamic** — the panel members and the arbiter are
selected at runtime by policy, not hardcoded.

- **The arbiter is just another AMP port — nothing special in the core.** It can be an LLM
  (LLM-as-judge), a deterministic reducer (vote / merge), or a **human** (Judge = the tiebreaker). Same
  port model as any other backend.
- **This is the lab's own dialectical method, automated.** Watson/Bob/Patton/Einstein/Grok answer; Judge
  arbitrates. AMP does that for the *LLM* layer dynamically — so the lab is again the reference
  implementation (the dialectical engine — see `papers/THE-DIALECTICAL-ENGINE.md` — as a *routing
  primitive*, not a hand-run ceremony).
- **It sharpens "Multi-Multi":** beyond routing *different* questions to different backends, fan-out asks
  the *same* question of several for **comparison / reconciliation**. Grok's existing
  synthesis/cross-agent reconciliation lens is exactly an arbiter role.
- **Meter consequence (ties §5a):** a panel call costs **N+1** inferences — AMP must attribute all of
  them. Panel calls are the expensive ones; the meter is what stops "ask everyone, arbitrate" from being a
  silent cost blowout, and **PGE decides *when* a question is worth a panel vs a single backend.**

Keeps the core minimal (IP-1 / adopt-don't-invent): fan-out is a **routing topology over the existing
port set**, not a new subsystem.

## 5c. Precursor & migration anchor — `qsp-mcp` is the proto-AMP (Judge, 2026-06-20)

The lab already runs a **hand-rolled, single-purpose AMP**: `qsp-mcp` bridges an agent to one local LLM
endpoint (`:8000`, Daina/Newton). It is what AMP generalizes — and it shows the failure modes AMP exists
to fix:

| `qsp-mcp` (proto) | AMP (the pillar) |
|---|---|
| one hardcoded backend / endpoint | multi-backend crossbar (Multi-Multi: agent-LLM × ARCH) |
| **theater auth** — config carries an `api_key` the backend ignores (confirmed 2026-06-20: open `0.0.0.0` endpoint, no auth) | every backend **authenticated + source-bound** is a precondition of safe routing |
| no metering, no policy, no audit | meter producer (→ ACT), policy consumer (← PGE), identity-scoped (← IAM) |
| a bespoke MCP per bridge | backends are **port adapters** behind one AMP contract |

So **AMP subsumes QSP**: the bridge becomes one backend adapter behind AMP's port model and the custom MCP
retires. Two consequences:
- **Don't over-invest in hardening `qsp-mcp` itself** — it's destined for replacement. The work that
  carries forward is **securing the backend endpoint** (auth + source-bind on Daina/Melody/Jacob), which
  AMP will route to unchanged. The `qsp-mcp` config key is throwaway twice over (theater now; MCP gone later).
- This is the **concrete "what does AMP replace?" story** for the spec — a real running precursor, not a
  greenfield claim. The local-LLM endpoint-hardening sweep (Melody = reference pattern; Daina/Jacob being
  brought to it) is **AMP's perms layer being proven in miniature before the pillar exists.**

## 5e. Role/judgment-tier routing — labor vs evaluation (Watson, 2026-06-21)

A routing topology distinct from fan-out+arbiter (§5d): not *one question to N peers reconciled*, but a
**two-stage pipeline** — local fleet **does the work** (compute, draft, triage), a **frontier agent
evaluates the result** (meaningful? drift or noise? action-worthy?). It routes by **required judgment
tier** — the systematic form of the lab's binding-vs-advisory rule:

- **Labor → local, advisory.** Daina/Melody/the 16 GB tier produce bulk output; confident-FP prone,
  never authoritative alone.
- **Evaluation → frontier, binding.** A frontier agent (Opus 4.8 today; **equally Grok** — vendor-neutral
  per §5, a *routable* Multi-Agent-LLM choice) adjudicates the labor's output — the same binding seat the
  cloud-Opus seat holds in the 3-panel. The evaluation can itself be a **panel** (§5d: Opus *and* Grok
  evaluate, arbiter reconciles) when one binding voice isn't enough.

Payload-selectable (§3b, e.g. `amp.tier: labor | evaluation`) and a PGE policy surface (§5b: which tier a
task class is entitled to). Meter consequence (§5a): the evaluation inference is the expensive,
low-volume one and the labor is high-volume/cheap — the meter shows the split.

## 6. OPEN questions for the chain (do NOT resolve ad-hoc)

1. **Relationship to CRB.** CRB is already "hardware-aware dispatch." AMP is "LLM-API-spec routing."
   Likely *layered* (AMP picks the backend → CRB places the inference on silicon), but **new-pillar
   vs CRB-expansion is a pillar-responsibility-split decision for the spec process**, not a memo.
   This is the first thing the chain must settle.
2. **Sequencing / version.** A new pillar is **v1.2 / increment scope**, not a v1.1.1 correction
   (v1.1.1 is Patton's MUST-FIX corrections). Is AMP the v1.2 headline, or seeded now and developed
   in parallel? Judge's call.
3. **Conformance test definition** — what exactly does "speaks the provider API spec" certify
   (streaming, tool-calling, system prompts, token accounting)?
4. **Routing-policy contract** — how is "route sensitive→local, burst→cloud" expressed and audited?
   (Touches PGE for the policy and ACT for the audit of routing decisions.)
5. **The routing-control payload schema (§3b).** Judge settled the *framing*: topology is
   **payload-selected**, not a static AMP mode — so fan-out+arbiter is one contract parameterized per
   request, not a separate subsystem. What's left for the chain: (a) the **normative attribute set**
   (`amp.backends` / `amp.mode` / `amp.arbiter` / `amp.data_class` …) and how it composes with each
   provider's own payload; (b) what conformance certifies about honoring it (§6.3); (c) ratifying the
   **payload-is-intent / PGE-is-decision** guardrail (§3b) so payload routing can't escalate past policy.
   Bears on the CRB boundary (§6.1) — settle alongside it, not ad-hoc.
6. **The trigger / origination layer — in-scope or explicitly out?** AMP **routes** calls; it does not
   **originate** them. The substrate walk (2026-06-21) surfaced origination as load-bearing: scheduled or
   autonomous work is *triggered* by a **frontier-agent runner that ships a scheduled/autonomous
   capability** — **Claude Desktop scheduled tasks**
   ([code.claude.com/docs/en/desktop-scheduled-tasks](https://code.claude.com/docs/en/desktop-scheduled-tasks))
   and **Codex Desktop** — **both held** (Claude via Max, Codex via ChatGPT Plus) and Judge-verified
   equivalents; **Grok has NO equivalent** (verified 2026-06-21 — Grok Build CLI + SuperGrok TUI, no
   scheduler/autonomous runner; the documented capability-gap example regardless of whether the
   subscription is retained) — plus Cloud
   routines (fire when machines are off / on GitHub events) and in-session `/loop`. **So the trigger is
   NOT uniformly vendor-available:** unlike evaluation (§5e, vendor-neutral), it is **capability-gated** —
   only vendors that ship a scheduler/autonomous runner can hold it. That asymmetry is itself
   spec-relevant. Is the layer (a) **out of AMP's contract** — origination is a separate concern, AMP
   routes whatever arrives — or (b) a **referenced-but-external** seam the spec must name so
   meter/policy/identity attach at origination too? The chain settles it; do **not** absorb the scheduler
   into the routing core ad-hoc (keep the core minimal, IP-1), and model the trigger as a **capability**
   (which vendors offer it), not an assumed vendor-neutral given.

## 7. Process path

Standard chain (the one that produced v1.0): this brief → Bob/panel structural pass → Patton
adversarial → Einstein first-principles → Judge merge. Settle §6.1 (CRB boundary) and §6.2
(sequencing) **before** any normative `§5.x` text is drafted into STD-001.

## 8. Substrate-first proving ground — build to falsify the brief (Judge, 2026-06-21)

**We are not building the Mesh pillar yet.** Per substrate-as-proving-ground (the IBX/PCS pattern): build
the AMP-exercising **substrate capability first**, on the real fleet (§5.1), and let the build
**falsify this brief** before any normative `§5.x` text is drafted. The pillar later adds only the
agent-meaning on top of a capability already proven on the substrate.

**First capability — the nightly cross-arch VOACAP/IONIS validation run** — ideal because it exercises
*every* AMP axis at once:
- **Multi-ARCH (§5):** the same IONIS inference on CUDA *and* MLX *and* Intel, compared — proves the arch
  axis is real, not a table.
- **Capacity/generation routing (§5.1):** heavy inference → a 96 GB card; can-wait batch → Ampere 16 GB;
  fast checks → Blackwell.
- **Role/judgment-tier (§5e):** local labor computes IONIS vs VOACAP vs the day's observations; a
  **frontier agent evaluates** (held / drifted / needs a look) — Claude or Codex (Grok-capable while held).
- **Trigger layer (§6.6):** originated by a **frontier-agent scheduled task** on the always-on M3 — Claude
  Desktop *or* Codex Desktop (both held; Grok has none) — the concrete test of whether origination is in-
  or out-of-contract, now swap-testable across two real vendors.
- **Meter (§5a):** every call — labor + evaluation — metered; proves per-(agent, backend, tier)
  accounting falls out of the crossbar.

**Falsification checklist — each is a spec question the build answers, not the brief:**
1. Does role-tier routing (§5e) hold as a real topology, or collapse into §5d's arbiter?
2. Does the CLI/agentic port type (§3a) cover *scheduled*, non-interactive invocation, or need extending?
3. Is Intel actually first-class (§5), or does it degrade to a footnote in practice?
4. Does the meter (§5a) capture a two-stage labor→evaluation pipeline cleanly?
5. Where do identity/policy/meter attach when a call is *originated by a scheduler*, not a live agent (§6.6)?
6. **Evaluation** vendor-neutrality (§5e): swap the evaluator across held frontier vendors (Claude,
   Codex, + Grok while retained) — does anything below the route change? (If yes, that's a leak.)
   **Trigger** (§6.6) is now a *two-sided* test: swap the runner **Claude Desktop ↔ Codex Desktop** (both
   held) — does the route below change? — *and* confirm the design models origination as a **capability
   Grok lacks**, not a universal given.

What the build finds — gaps, port-type stretches, missing attributes — feeds the chain (§7) as
**evidence**: the substrate proves or breaks the spec before the spec goes normative.
