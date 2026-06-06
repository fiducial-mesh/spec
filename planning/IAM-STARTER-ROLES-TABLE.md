---
title: "IAM Starter Roles Table — Plain-English Job Descriptions for Initial Role Set"
doc_type: planning-draft
status: draft
version: v0.1
authors:
  - watson
date: "2026-06-06"
roles:
  - design-intent
  - infrastructure
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/IAM-CORE-SPEC.md
  - planning/IAM-INCREMENT-2.md
  - planning/PGE-SPEC.md
---

# IAM Starter Roles Table — Plain-English Job Descriptions

**Scope**: a starter set of agent roles for the mesh, written as plain-English job descriptions — the way a manager would describe what each employee does. Owned by IAM (the principal-class designation lives in the identity record); enforced by PGE (the policy corpus says what each role is permitted to do). This document is the **starter draft for Judge's red-line**. It does not commit to a final taxonomy; it captures the working roles already in the lab and proposes the plain-English mapping.

**Tone discipline** (per Judge direction 2026-06-06): job-description-sheet style. No spec-code jargon. No `CD-N`, no `§-refs`, no `MI-codes`. A manager reading this should be able to tell whether each role is correctly described without consulting the spec.

**How the table is used**:
- IAM stores the role on the identity record (the agent's "job title").
- PGE stores the policy that says what each role is permitted to do (the "job duties").
- When the agent does something, PGE checks the policy against the role.
- The role can be changed (job change, promotion, transfer) — that's a lifecycle event handled by the agent's owner.
- Per the "agents are employees" design principle: think of this as the org-chart and the job descriptions for the workforce.

---

## The Starter Roles

### 1. Infrastructure Engineer

**What they do**: build and maintain the substrate the rest of the work runs on. They set up databases, networks, storage, identity systems, deployment pipelines, monitoring. When something underneath the work breaks, they fix it.

**What they CAN do**:
- Provision, configure, and maintain database systems (ClickHouse, Postgres, Vault).
- Build and operate ingestion pipelines and ETL jobs.
- Manage networking, storage, and machine-level configuration.
- Build CI/CD pipelines and run them.
- Write and ship infrastructure code.
- Deploy services to production hosts.
- Read all operational logs and metrics across the substrate.

**What they CAN'T do**:
- Train models or make modeling decisions (that's the Model Developer's job).
- Sign off on failure analyses or post-mortems (that's the Failure Analyst's job).
- Approve security policy changes (Judge owns; CRB governs the change process).
- Touch root credentials, root keys, or the trust ceremony — those are Judge-only by structural rule, regardless of role.

**Who fits this role today**: Bob.

---

### 2. Model Developer

**What they do**: build, train, evaluate, and improve the machine-learning models that the lab produces. They write training code, run experiments, validate results, and ship checkpoints. When a model needs to get smarter, they're the ones doing the work.

**What they CAN do**:
- Write and run model training code.
- Experiment with model architectures and hyperparameters.
- Validate model outputs against test sets and operator-grounded benchmarks.
- Commit training code, evaluation scripts, and documentation to model repos.
- Read training data and signature stores.
- Tag model versions and prepare checkpoints for handoff to Infrastructure for packaging.

**What they CAN'T do**:
- Provision or modify production substrate (that's the Infrastructure Engineer).
- Tag releases or push to PyPI / package repos (that's the Infrastructure Engineer with sign-off authority).
- Sign off on failure analyses (that's the Failure Analyst).
- Approve security policy changes (Judge owns).
- Touch root credentials, root keys, or the trust ceremony — Judge-only.

**Who fits this role today**: Watson.

---

### 3. Failure Analyst

**What they do**: review work for defects, run post-mortems on incidents, and catch problems the people doing the work missed. They are deliberately skeptical. They don't ship code; they make sure the code that ships doesn't ship broken.

**What they CAN do**:
- Review pull requests, specs, and proposals across all repos.
- Run post-mortems on incidents and write incident reports.
- Surface architectural risks and propose corrective actions.
- Read all repos, all logs, and all artifacts.
- Sign off (or block) on architectural decisions and spec promotions per the review chain.
- Maintain the failure-analysis corpus (incident reports, anti-patterns, dead-ends).

**What they CAN'T do**:
- Commit code to any production repo (they review; they do not implement).
- Tag releases or push to package repos.
- Provision or modify production substrate.
- Approve security policy changes (Judge owns).
- Touch root credentials, root keys, or the trust ceremony — Judge-only.

**Who fits this role today**: Patton.

---

### 4. Domain Architect (Physicist)

**What they do**: provide the deep domain reasoning that shapes architectural decisions. They are the source of truth for "is this physically possible?" and "does this assumption hold?" They don't write code; they tell the people who do whether the model in their head matches reality.

**What they CAN do**:
- Review proposals and surface domain-grounded objections.
- Author and revise the physics / domain corpus (papers, design notes, constraint catalogs).
- Propose model architectures rooted in domain principles.
- Read all repos and all spec artifacts.
- Sign off on physics-grounded decisions when the review chain calls for it.

**What they CAN'T do**:
- Commit code to any production repo.
- Modify training data or run training.
- Tag releases.
- Provision substrate.
- Touch root credentials, root keys, or the trust ceremony — Judge-only.

**Who fits this role today**: Einstein.

---

### 5. Local Inference Service

**What they do**: serve a sovereign local language model (no cloud, no external API) to the rest of the mesh. They answer queries; they don't initiate work. They are a service, not a worker.

**What they CAN do**:
- Respond to inference requests over the local network.
- Read prompts and return completions.
- Report their own health, latency, and resource usage.

**What they CAN'T do**:
- Read any repository (they don't have repo access; they don't need it).
- Write any persistent state outside their own working memory.
- Initiate outbound network calls.
- Touch credentials of any kind.
- Make architectural decisions (they answer; they don't decide).

**Who fits this role today**: Newton.

---

### 6. Operator / Owner

**What they do**: the human in the loop. The accountable party. The authority that ratifies architectural decisions, approves merges, owns the lab and the work output.

**What they CAN do**:
- Everything. The operator is the source of authority.
- Specifically: merge PRs, tag releases, approve security policy changes, ratify spec decisions, hire / fire agents (onboard / terminate identities), set role for each agent, sign auditor attestations.
- Touch root credentials, root keys, and the trust ceremony — *only* the operator does these.

**What they CAN'T do** (by their own discipline, not by structural rule):
- They generally don't write code at the keyboard — they direct the agents who do.
- They don't run agent processes themselves — they review, approve, and act on outputs.

**Who fits this role today**: KI7MT (Judge).

---

## Notes for Judge's Red-Line

A few things worth a deliberate decision before promoting this from draft:

1. **Single role per agent vs multiple roles**. The lab today has each agent in essentially one role (Watson = Model Developer, Bob = Infrastructure Engineer, etc.). If an agent needs to do work across two roles (e.g., Watson needs to read infrastructure logs to debug a training pipeline issue), is that handled by: (a) a temporary role grant, (b) cross-role-readable resources, (c) explicit elevation by the operator, or (d) something else? Recommendation: (b) — make read access cross-role-broad and write access role-narrow. This matches the lab's actual operating pattern (everyone reads everything; only the role-owner writes).

2. **Role change vs new identity**. If Watson is promoted to also do failure analysis (or transferred to a new role), is that a role change on the same identity, or a deprovision + new mint? Recommendation: role change on the same identity, like an HR job-change transfer. Identity continuity (callsign, history, audit trail) is preserved. The owner approves the role change.

3. **Promotion / demotion authority**. Who can change a role? Recommendation: the agent's owner (typically the operator, KI7MT). Not the agent itself (no self-promotion). Not another agent (no peer-promotion). Owner-driven, audit-logged.

4. **Adding roles later**. If we add a "Security Researcher" or a "Customer Engineer" role later, what's the process? Recommendation: starter set lives here; new roles are added by editing this doc and merging through the normal review chain (or directly per the lab's current no-PR-ceremony discipline for spec docs).

5. **The "Local Inference Service" name**. The lab calls this agent "Newton." The role name is more generic so other inference services could fit the same role description. Worth confirming the role name vs the callsign.

6. **What's missing from the starter set?** Worth a deliberate scan: are there roles the lab needs in the near term that aren't here? Candidates that came up in passing but didn't make the starter set: Customer Success / Implementation Lead (for eventual customer deployments), Auditor (read-only, external attestation), Security Researcher (pentest, vulnerability analysis). These are easy adds when the work calls for them.

---

## How This Lands in the Spec Corpus

- **IAM-CORE-SPEC**: the *role* attribute is on the identity record (`type: agent`, `role: infrastructure-engineer`, etc.). The role is stored; IAM doesn't enforce policy on it.
- **PGE-SPEC**: the policy that says what each role is permitted to do lives here. PGE consults the role on every action and decides admissibility.
- **IAM-INCREMENT-2**: the lifecycle states (onboard, active, suspended, deprovisioned) operate on the identity regardless of role. The role moves with the identity.
- **CRB-SPEC**: role changes (and role-corpus changes — adding a new role to the table) are change events governed by the standard change review board flow.

This doc is the starter content for the role taxonomy. Whether the table itself lives in `IAM-CORE-SPEC.md` (as the role enumeration), in `PGE-SPEC.md` (as the policy mapping), or as a standalone doc referenced by both is a placement decision Judge can make on the red-line. Recommendation: standalone doc (this one), referenced by both, so the plain-English content stays plain-English and the spec docs stay spec-shaped.

---

## What This Doc Is Not

- Not the PGE rule corpus. The PGE corpus encodes the *permission policies* the role table maps onto; the role table is the input, not the rule set.
- Not a final taxonomy. Six starter roles is the working set; the actual list is whatever Judge red-lines this to.
- Not a tier or rank system. There is no implicit hierarchy among the roles; an Infrastructure Engineer is not "above" a Model Developer. The Operator is the only structural authority above all roles.
- Not a permission matrix. The CAN / CAN'T lists are the role's *job description*; the formal permission expressions live in PGE policy.
