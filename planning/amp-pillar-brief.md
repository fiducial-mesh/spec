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
- **Multi-ARCH** — inference architectures: Apple **MLX**, NVIDIA **CUDA**, cloud, extensible.

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
| **Contract** | the LLM provider **API spec** (Anthropic Messages / OpenAI Chat-Completions) |
| **Conformance** | "does this backend *speak* the contract" (a `*-v1`-style test set) |
| **Registry** | the set of available backends (Daina@llama.cpp, Melody@MLX, cloud Claude/Codex/Grok) |

A backend plugs in by speaking the contract — exactly how a plugin plugs into PCS or a substrate
component satisfies IP-1.

## 4. Doctrine — adopt the plugin system, don't invent it

> *"We didn't invent the plugin system; we're merely USING the plugin system in the Mesh."* — Judge

AMP **adopts proven OSS** as its mechanism (Claude Code Router / `claude-code-router`, MCP, the
provider SDKs) and routes through each agent's **native interface**, transforming at the seam
(Anthropic API → OpenAI-compatible, as CCR does) — never forcing a new format on any agent. This is
the cardinal-rule (speak agents' native vocabulary) + adopt-proven-OSS doctrine applied to routing.
It is also the **systematic form of vendor-diverse cognition** (Anthropic / OpenAI / xAI / local) —
routing diversity becomes a pillar instead of a manual habit.

## 5. Architecture substrate matrix (the Multi-ARCH axis)

| Capability | MLX (Apple) | NVIDIA (CUDA) | Cloud |
|---|---|---|---|
| Local coder | — | Daina (Qwen3-Coder, llama.cpp) | — |
| Local reasoner | Melody (Qwen2.5-72B, mlx_lm) | (Newton, llama.cpp, dormant) | — |
| Frontier agent | — | — | Claude Code / Codex / Grok |

The spec makes **MLX and NVIDIA first-class** so a deployment picks its architecture column the way
the Requirements×Houses matrix picks a vendor column — the conformance test is the invariant, the
architecture is the swappable axis. (This is AMP's paper figure: the pluggability thesis one layer
deeper than usual — across **model × silicon**.)

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

## 7. Process path

Standard chain (the one that produced v1.0): this brief → Bob/panel structural pass → Patton
adversarial → Einstein first-principles → Judge merge. Settle §6.1 (CRB boundary) and §6.2
(sequencing) **before** any normative `§5.x` text is drafted into STD-001.
