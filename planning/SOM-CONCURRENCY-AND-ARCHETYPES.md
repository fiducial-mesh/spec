---
title: "SOM Concurrency Model and Agent Archetypes"
doc_type: spec
status: draft
version: v0.1
authors:
  - patton
  - watson
date: "2026-06-02"
roles:
  - design-intent
  - infrastructure
  - failure-mode
author_id: patton
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-IDENTITY-PILLAR-DESIGN.md
  - planning/SOM-INSTANTIATION-AND-IDP.md
  - planning/SOM-DESIGN-PHILOSOPHY.md
  - planning/IBX-SPEC.md
  - planning/SOM-PILLAR-NAMES.md
  - planning/SOM-PROBLEM-STATEMENT.md
---

# SOM Concurrency Model and Agent Archetypes

*Provisional design doc. Captures the concurrency model (identity-vs-session) and the agent archetypes (worker / reasoner / quorum-voter) that surfaced from real document-processing examples. DESIGN — none of this is built; current state is briefs-only (identity asserted not verified; no Vault/Roster/ARCA/login/credentials/broker exist yet). This document is INPUT to the Increment-2 Judge rulings, not a front-run of them — it surfaces the concurrency dimension the rulings need to account for, and explicitly defers the rulings themselves. Names provisional ("SOM"). Open items stay open.*

---

## 0. Why this exists

The identity pillar design treated "one agent = one ARCA-issued keypair = one Employee ID." It did not ask what happens when the SAME identity runs in MULTIPLE concurrent instances. That is a real gap: an agent identity, unlike a human employee, has no single body — N processes can hold one identity's credential simultaneously. This document resolves that gap and the archetypes it surfaces.

The gap was surfaced by concrete document-processing examples (see §5), not abstract reasoning — which is why it is grounded rather than speculative.

---

## 1. The core distinction: identity vs. session/instance

The model so far CONFLATED two things that concurrency forces apart:

- **Identity** = WHO the principal is (the ARCA-issued keypair, the Employee ID, the job code). Permanent, singular. "Patton."
- **Session / instance** = a specific running EXECUTION authenticated as that identity. Ephemeral, and there can be MANY concurrent ones. "Patton-instance-2."

**Resolution: one identity (singular, who), many concurrent sessions (plural, which execution).** Each session has its own session credential; all sessions are attributable to the identity but individually distinguishable. This mirrors how real systems handle it — one user account, many concurrent logins/sessions.

This is not optional sugar — concurrency is a FEATURE the workforce needs (parallel work is the point of an agentic workforce). Forbidding concurrency would throttle the workforce to serial execution.

### Consequences across the pillars

| Pillar | Concurrency consequence |
|---|---|
| **IAM / broker** | Per-session credentials (not one shared credential per identity), so one instance can be revoked/suspended without killing all instances. Validates the increment's per-session-credential leaning — it is what makes per-instance isolation possible, not just an expiry nicety. |
| **ACT (attribution)** | Records `identity=X, session=instance-N` — identity for WHO, session for WHICH execution. Without session granularity, a compromised instance is invisible among legitimate ones and you cannot suspend just the bad one. **Attribution and incident-response operate at SESSION level; identity is the grouping.** |
| **Incident response** | Must support BOTH session-level actions (suspend instance-2 for investigation while -1 and -3 keep working) AND identity-level actions (terminate all instances if the identity/key is compromised). The suspend/terminate/Halon design must distinguish these. |
| **Concurrency safety** | Concurrent instances acting on shared resources need INFRASTRUCTURE-enforced concurrency control (atomic claiming, locking) — you cannot trust autonomous agents to coordinate politely. Enforce-at-the-chokepoint applied to concurrency: safety enforced at the resource, not delegated to well-behaved agents. |
| **Authority** | Concurrent instances share the identity's job code / authority. Concurrency does NOT expand authority, but it does mean N instances each carry the FULL identity authority — N attack surfaces at full authority. Containment (narrow job code) limits all instances equally. |

### Discipline: concurrent instances share identity+authority, NOT mutable runtime state
If concurrent instances shared mutable runtime state (shared memory, shared working context), you get race conditions INSIDE the identity. Cleanest model: instances are independent executions that share identity-and-authority but coordinate (if needed) only through governed channels (IBX / shared resources with proper concurrency control), never through shared mutable agent-state. Stateless-per-instance-except-through-governed-channels.

### Open item: per-identity concurrency cap
"Can run multiple instances" must NOT mean "unlimited instances" — a runaway or compromised situation spinning up many instances is a resource-exhaustion / blast-radius (DoS) vector. There should be a per-identity concurrency cap (policy, tier-scaled), enforced at instantiation (the broker won't grant the N+1th session). Instantiation is already a chokepoint, so it can count and cap concurrent sessions. **Cap VALUES per tier are an open Judge item (ties to the Increment-2 expiry/tier rulings).**

---

## 2. Three agent archetypes

Concurrency is not one-size-fits-all. Three distinct archetypes surfaced, each with a different concurrency / identity / authority / governance profile. The model should recognize these as first-class.

### Archetype A — WORKER
- **Profile:** many concurrent instances, homogeneous task, narrow authority, fully automated, cheap-per-unit.
- **Identity model:** ONE role-identity (e.g. `document-processor`), run at a configured concurrency level (a worker pool). NOT N distinct identities — that would be meaningless identity sprawl (workers are interchangeable). Scale by running N concurrent SESSIONS of the one identity.
- **Concurrency cap is a SCALING KNOB**, not just a safety limit — "run 50 workers" is a throughput decision. (Both exist: a safety ceiling and a configured operating level under it.)
- **Optimizes:** throughput.
- **Governance intensity:** low — automated, no per-item human gate (that would defeat the automation). Justified by narrow authority: a compromised worker can only do worker-things.

### Archetype B — REASONER
- **Profile:** few concurrent instances, heterogeneous/broad tasks, broad authority, human-gated for high-stakes.
- **Identity model:** few concurrent sessions of a broad-authority identity (e.g. Patton).
- **Optimizes:** judgment.
- **Governance intensity:** high — broad authority means high-stakes actions are Judge-gated. Low concurrency, high governance.

### Archetype C — QUORUM VOTER
- **Profile:** N agents REDUNDANTLY process the SAME unit of work and a consensus mechanism decides the outcome.
- **Identity model:** N DISTINCT identities (not N sessions of one) — because the whole point is INDEPENDENCE (see §3). Coordinated by a governed quorum/consensus mechanism.
- **Optimizes:** accuracy / trustworthiness through redundancy.
- **Governance intensity:** the consensus coordinator is a governed, attributable decision point (structurally Judge-gate-like but automated for the consensus case). Disagreement escalates to humans.

### Governance intensity scales INVERSELY with authority-narrowness
Narrow-authority workers run automated at high concurrency; broad-authority reasoners run gated at low concurrency. A worker pool does not need a Judge gate per item; a reasoner's high-stakes action does. This is a useful design axis.

---

## 3. The quorum/consensus pattern (Archetype C, expanded)

This is N-version redundancy with consensus — the high-reliability-systems pattern (run multiple independent implementations, vote/aggregate) applied to agentic work. Used when being WRONG is expensive (regulated/high-stakes work). Spends Nx compute per unit to buy confidence in correctness, with human fallback for non-consensus.

### Independence is the whole ballgame (the critical requirement)
Quorum buys NOTHING unless the voters are INDEPENDENT. If N agents are identical instances of one identity running identical code, they produce identical results INCLUDING identical errors — "3 of 5 agree" is meaningless because they would agree even when all wrong the same way. **Redundancy only helps if the redundant versions fail DIFFERENTLY.** This pushes toward DIVERSE voters (different models, different engines, different approaches) so errors are uncorrelated and consensus actually signals correctness.

This is the same principle as cross-substrate independence (the ITDR/diverse-substrate idea, and Einstein being a different model than the Claude agents). 5 identical voters is NOT redundancy — it is 5x cost for zero accuracy benefit. **Cutting the independence corner silently destroys the entire value of the quorum.**

### The quorum coordinator is a governed component
Something dispatches the unit to N voters, collects results, applies the consensus rule, and routes the outcome. This coordinator:
- must NOT be one of the voters (conflict — a voter counting its own votes),
- needs its own identity/authority,
- makes an attributable decision (it decides what enters the trusted store).
It is a GOVERNANCE component, not just plumbing.

### Odd vs. even, and why confidence-aggregation dissolves the question
- **Pure majority voting:** use ODD (3/5/7) to avoid ties (even can deadlock 2-2). 5 is a common sweet spot (margin for 2 dissenters, not absurd cost). This is the same reason consensus systems (Raft, etc.) use odd.
- **Confidence-aggregation (the better model — see §4):** each agent produces a result WITH a confidence; you aggregate confidences against thresholds rather than counting discrete votes. There is no "tie" to break, so the odd-number constraint RELAXES — count becomes a cost/robustness choice, not a tie-avoidance one.

### The no-consensus path doubles as agent-health telemetry (a useful insight)
When voters DON'T reach consensus, the unit escalates to human/forensic review. But disagreement is also a SIGNAL ABOUT THE AGENTS: an agent that is PERSISTENTLY the dissenter (consistently outvoted) is a degrading/failing agent — exactly the behavioral anomaly ITDR-over-ACT detects. So the quorum mechanism GENERATES the telemetry ITDR consumes: persistent dissent = a failing agent, detectable. The disagreement isn't only a routing decision; it is a workforce-health signal. Elegant: the consensus mechanism doubles as agent-health monitoring.

---

## 4. Confidence-aggregation and graded outcomes (refinement of §3)

Better than binary voting: each agent produces a result WITH a confidence, aggregated into a graded add / review / reject decision:
- **High aggregate confidence** (agents agree AND are individually confident) -> **add** (auto).
- **Medium / mixed** -> **review** (human or higher-tier).
- **Low / strong disagreement** -> **reject / forensic queue.**

This uses more signal than binary voting (an agent 51%-sure and one 99%-sure are not equal votes) and matches reality (extraction quality is a spectrum, not pass/fail).

### Caveats (these separate "elegant idea" from "works at scale")
1. **Self-reported confidence is often MISCALIBRATED.** LLM/ML "confidence" is frequently confidently-wrong. Naive confidence-weighting AMPLIFIES a confidently-wrong agent (it gets more weight BECAUSE it overclaimed). Mitigations: (a) CALIBRATE confidence against known-correct data; (b) trust INTER-AGENT AGREEMENT (independent agents agreeing) MORE than INTRA-AGENT self-confidence; (c) treat self-confidence as one input, not THE input. **Independence matters DOUBLY here** — inter-agent agreement is a calibrated signal in a way self-confidence is not.
2. **Thresholds (add/review/reject boundaries) are the load-bearing tuning knobs** and must be set against a LABELED VALIDATION SET, not guessed. Too strict -> human queue floods; too loose -> bad data auto-added. Empirical, not a-priori; at scale, small threshold changes move large numbers.
3. **The aggregation function is a real design choice** (average / reliability-weighted / require-agreement-AND-confidence / lowest-confidence-wins). Start simple, refine against data. Do not over-engineer early.

### Agreement granularity: per-field, not whole-document
Metadata extraction produces STRUCTURED output (many fields). Whole-document quorum is crude. **Per-field quorum** (accept fields where N agree, flag fields where they don't) is more granular and likely better — accept a document where critical fields hit quorum and flag only the disputed field, rather than kicking the whole document to humans for one field. Real design decision: whole-document vs. field-level. Field-level likely better, more complex.

---

## 5. Grounding example: document processing (worker pool vs. quorum)

Two concrete examples surfaced the archetypes. They are a REFERENCE LENS, not a committed product spec.

### Example 1 — worker pool (Archetype A)
"A document-processing agent reads PDFs, extracts metadata, writes to a bronze layer; millions of documents." => one `document-processor` identity, N concurrent worker-sessions pulling from a concurrency-safe queue (exactly-once claiming via SKIP-LOCKED-style atomic claim — which is WHY a transactional store matters for IBX, and why ClickHouse/OLAP is wrong for the claim queue). Bronze writes must be concurrent-safe + idempotent. Requires lease/visibility-timeout (crashed worker's doc returns to queue), retry + poison/dead-letter queue, idempotency keys. A suspended/terminated worker's in-flight unit must return to the queue (ties to mid-action-safe termination).

### Example 2 — quorum (Archetype C)
"5 agents each process the same document; need a 3-agent quorum to accept; else kick to a queue for human/forensic analysis AND OCR-failure analysis against the processing agents." => the consensus pattern of §3-4, with the dual-path escalation (forensic on the DOCUMENT + failure-analysis on the AGENTS) and the agent-health-telemetry insight.

### Choosing the pattern by criticality tier
Do NOT quorum everything (Nx cost). Routine documents -> worker pool (cheap). High-stakes documents -> quorum (expensive, high-trust). The criticality tier decides which pattern a unit gets. Tier dial selects archetype.

---

## 6. The label-oracle / model-training extension (distinct from a feedback loop)

The multi-agent confidence ensemble is, in effect, a TRUSTWORTHY LABEL ORACLE — it produces labels WITH a confidence/agreement signal that says which labels to trust. This enables training a domain-expert model (ordinary supervised ML), NOT a closed feedback loop.

### The sound version (what is intended)
Use high-confidence-independent-consensus extractions as trustworthy training labels; human-label the disagreement cases (the informative hard examples); train a domain-expert model; VALIDATE against held-out human-verified ground truth; optionally use the cheaper trained model for routine volume, escalating hard cases to the ensemble + humans. This is weak-supervision / distillation — standard, sound. No loop.

### The hard rules (non-negotiable)
1. **NEVER a closed loop without ground-truth anchoring.** Training a model on agent outputs and feeding its outputs back into its own training -> model collapse / error amplification (systematic errors get baked in and entrenched). The loop MUST be broken by periodic human-verified ground truth. The confidence filter helps but does NOT save you, because SYSTEMATIC errors can be high-confidence (correlated agents confidently agreeing on the same wrong thing).
2. **Voter independence matters DOUBLY for training-data quality.** Independent agents agreeing = a trustworthy label. CORRELATED agents agreeing = a POISONED label that LOOKS high-quality (everyone agrees, high confidence) but encodes shared blind spots. Train on correlated-consensus and you teach the model those exact blind spots.
3. **Do NOT feed the distilled model back in as a voter.** It was trained on the other voters, so it is CORRELATED with them (an echo) — adding it to the ensemble reduces the independence the ensemble depends on.
4. **Held-out human-verified ground truth for evaluation is mandatory.** "The model agrees with the ensemble that trained it" is NOT "the model is correct" (it may have learned to mimic the ensemble's errors). Trained != good; good is measured against independent ground truth.

### Scoping honesty
This is a substantial Python/ML subsystem (per the tech-stack decision: ML => Python) with ONGOING collapse/drift monitoring — not a config, not train-once. Scope it as a real ML build with real failure modes.

---

## 7. Open items (stay open — Judge / design rulings)

- **Per-identity concurrency cap values, per tier** (ties to Increment-2 expiry/tier rulings).
- **Session-level vs. identity-level revocation/termination semantics** (the suspend/terminate/Halon design must distinguish; ties to Increment-2 terminator-failure-mode ruling).
- **Agreement granularity** for quorum: whole-document vs. per-field (per-field leaning).
- **Confidence aggregation function** choice (start simple; tune against labeled data).
- **add/review/reject thresholds** — empirical, set against a labeled validation set (does not exist yet; must be bootstrapped).
- **Quorum voter independence mechanism** — how diversity is achieved (different models/engines) and verified.
- **Accuracy definition** for any high-trust extraction use case: per-field weighted by criticality, measured against human-verified ground truth (which must be bootstrapped — it does not exist for an un-databased document backlog).

---

## 8. Relationship to other SOM work (no front-running)

- **Increment 2:** this document is INPUT to the seven Increment-2 rulings (concurrency cap values, revocation semantics, ITDR-over-ACT scope), not a replacement for them. It surfaces the concurrency dimension those rulings must account for. It commits no ruling.
- **IBX spec (Watson):** directly informs IBX's open questions — concurrency-safe claiming, lease/retry, the "one task per PCT" enforcement question. The worker-pool queue semantics are IBX (or work-queue) concerns.
- **IAM / identity pillar:** extends it with the identity-vs-session distinction the pillar did not make.
- **ACT / ITDR:** session-granular attribution; the quorum-dissent-as-health-signal insight feeds ITDR detection.
- **Tech stack:** the label-oracle/model-training extension is Python/ML; the worker queue needs the transactional persistence layer (not OLAP).
- **Finance overlay (loan-document accuracy):** the high-trust quorum + confidence + human-on-uncertain + per-field-accuracy + ground-truth-bootstrapping maps onto the real loan-document extraction problem. Held as a reference lens, not a committed spec. Problem statement incomplete (document count + heterogeneity pending).

---

*Status: provisional design capture. Current state is briefs-only (no concurrency control, no session model, no broker, no quorum mechanism built — all design). This document feeds Increment-2 and the IBX spec; it front-runs no Judge ruling. Names provisional. Open items remain open.*
