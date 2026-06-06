---
title: "SOM Regulated-Workflow Overlay — Federal-Program-Grade Deployment Class"
doc_type: spec
status: draft
version: v0.1
authors:
  - watson
date: "2026-06-06"
roles:
  - design-intent
  - infrastructure
  - failure-mode
author_id: watson
violates_invariant: false
invariant_class: ""
references:
  - planning/SOM-SPEC.md
  - planning/SOM-PROBLEM-STATEMENT.md
  - planning/SOM-CONFORMANCE.md
  - planning/SOM-DESIGN-PHILOSOPHY.md
  - planning/IAM-CORE-SPEC.md
  - planning/IBX-SPEC.md
  - planning/ACT-SPEC.md
  - planning/PGE-SPEC.md
  - planning/DPG-SPEC.md
  - planning/CRB-SPEC.md
  - planning/PCS-DAEMON-SPEC.md
---

# SOM Regulated-Workflow Overlay — Federal-Program-Grade Deployment Class

**Scope**: A **composable overlay** on top of stable som-core that specifies the additions, extensions, and operational gates demanded by federal-program-grade procurement instruments. Anchored on a real procurement document (IHFA RFP, 2026-06-05) and structured to admit additional anchor sources. The overlay sits **on top of unchanged pillar contracts**: where som-core already covers a primitive, the overlay cites the pillar; where the regulated class demands more granularity than core stipulates, the overlay adds it as an overlay-tier requirement *without* changing the core contract; where the regulated class needs a pattern that does not exist in core, the overlay defines that pattern as overlay-only. som-core remains sector-neutral.

**Authorship note (overlay method)**: Watson-authored. The overlay model — keeping som-core sector-neutral and landing sector/vertical/regulatory shape as composable overlays — was committed early in SOM spec design and is the anchor mechanism in PGE-SPEC.md OQ-P1 ("Cross-deployment rule overlay model: per-deployment overlay file with explicit additions/removals against the core; rule resolution = core ∪ deployment-additions − deployment-removals"). This document is the first formal SOM **workflow overlay** (PGE OQ-P1 anticipated the rule-corpus overlay layer; this overlay extends the model to workflow primitives spanning multiple pillars). The IHFA RFP anchors v0.1. Subsequent revisions will fold in additional anchor RFPs (state Medicaid, HRSA, USDA Rural Development, DOT, state environmental, FERPA-bound education) to validate generality and identify primitives the IHFA anchor undersamples.

**Status**: **Draft v0.1**, anchor = IHFA RFP (2026-06-05). This overlay does **not** propose changes to any pillar contract. Where the regulated class demands granularity beyond core, the overlay specifies it as an overlay-tier addition that a deployment activates by enabling this overlay. Pillar implementations that satisfy core conformance remain conformant after this overlay lands; overlay activation is the customer-deployment-class concern.

## Purpose / Problem Restatement

If SOM is to be deployable into regulated arenas — federal grant administration, housing finance, healthcare grants, public education records, environmental compliance — the mesh must satisfy a workflow class that is **stringent, externally specified, audited, and procurement-disciplined**. Three structural requirements follow, all reconciled by the overlay model:

1. **som-core must stay sector-neutral.** SOM's deployability depends on the core being identical across all customers. A bank, a state HFA, a hospital system, and a research lab all install the same som-core. Per-sector shape lives outside the core. Modifying pillar contracts to satisfy regulated arenas would fork the core; the cost would compound across every subsequent sector engagement.

2. **Regulated arenas demand more granularity than sector-neutral core stipulates.** Field-level audit, time-bounded identity grants, configurable rule-engine with toggle semantics, disclosure-bound rendering — these are real requirements of the regulated class that a sector-neutral core would over-specify if absorbed and under-specify if ignored. The overlay is the resolution: core specifies the baseline; the overlay specifies the regulated-class extensions on top.

3. **The same overlay activates the same shape across many customers in the class.** State HFAs (~50 nationally), state Medicaid administrators, federal-grantee organizations — all of these are the same workflow class with different rule corpora. One overlay characterization, fifty-plus deployments. The overlay model is what makes the SOM mesh scale into the regulated arena without per-customer core forks.

This overlay captures the workflow class as a composable activation: enable the overlay, and the mesh deployment carries the regulated-class additions on top of unchanged core.

## Overlay model and core stability commitment

Per PGE-SPEC OQ-P1, the overlay mechanism is: **deployment-class shape = core ∪ overlay-additions − overlay-removals**, with the core remaining authoritative for sector-neutral concerns. This overlay applies that model to workflow primitives spanning multiple pillars (not just the PGE rule corpus PGE OQ-P1 originally anticipated).

The overlay categorizes each regulated-workflow primitive into one of three buckets:

- **(A) Already in core**: the primitive is satisfied by a current pillar contract. The overlay cites the pillar; no overlay-tier addition is required. The deployment gets this primitive by activating the relevant pillar; the overlay's role is documentation.

- **(B) Overlay extension on top of stable core**: the pillar contract is necessary but the regulated class requires more granularity, stricter discipline, or additional sub-patterns. The overlay specifies the extensions as overlay-tier requirements that activate when the overlay is enabled. The core pillar contract is unchanged; an implementation that satisfies core remains conformant. An implementation that wants to deploy under this overlay additionally satisfies the overlay-tier requirements.

- **(C) Overlay-only pattern**: the primitive is not in core at all (because it would over-specify a sector-neutral mesh). The overlay defines its own pattern. The core has no opinion; the overlay specifies the contract for this overlay's deployments.

**Hard discipline**: nothing in this overlay proposes a change to any pillar contract. If a regulated-class requirement appears so cross-cutting across sectors that it warrants core inclusion, the path is SOM-IP (Integration Principle) ratification with Judge sign-off — **not** an overlay change request to a pillar spec. This overlay specifies, it does not modify.

## The empirical anchor — IHFA RFP (2026-06-05)

**Issuer**: Idaho Housing and Finance Association (IHFA), administrator of LIHTC, Housing Bonds, HOME, HTF, HOME-ARP, ESG, CoC, with resources from HUD.

**Procurement vehicle**: Federal Programs Project Management Software, competitive proposal under 2 CFR 200.318-326, closed bid, fixed-price contract, sealed until deadline, with an 8-criterion evaluation scorecard, 4-hour onsite presentation + 30-minute Q&A for finalists.

**Hard gates** (filter out non-compliant bidders before evaluation):

1. **SOC 2 Type II audit (current)** — explicit: "IHFA will not accept proposals from Vendors who do not have a current SOC II audit"
2. **2 CFR 200.318-326** competitive-proposal procurement compliance
3. **SAM.gov debarment check** — not debarred / suspended by Federal Government
4. **Idaho bondability** if required
5. **Fixed-price contract** structure
6. **Idaho Public Records Act** posture with watermarking discipline for trade-secret claims

**Functional surface** (seven areas spanning A–G): Security/Support/Integrity, Funding/PM/Apps, Communications/Documents, Project Financials, Property Compliance, Reporting, Homelessness Grants Management.

**Evaluation criteria** (eight-factor scorecard): Vendor Capabilities, Implementation Plan (incl. Change Management approach), Product Functionality, Industry Experience, User Experience, Reporting and Analysis, Technical Infrastructure/Platform/Integration Options, Pricing.

**Operational SLA**: 8a-5p MST live support via phone or ticket system, Monday-Friday.

The full IHFA RFP is held in `case-studies/regulated-workflow-anchors/` (to be created in a follow-up commit; for now the RFP is filed in the operator's local Downloads and is publicly distributed by IHFA). Citation: IHFA "Request for Proposal — Federal Programs Project Management Software," issued by Paula Grow, May 5, 2026, proposal deadline 2026-06-05 5pm MST.

The RFP is **typical of the federal-program-grade procurement class**, not exceptional. State HFAs (~50 nationally), state Medicaid administrators, state environmental program offices, USDA Rural Development field offices, and HRSA-funded grant administrators run substantially similar procurement processes with substantially similar functional requirements layered over their respective rule corpora. Designing one overlay against the IHFA anchor is designing for a workflow class that admits 50+ adjacent procurement instances.

## Workflow primitives extracted from the anchor RFP

The primitives below are the **workflow contract** the regulated arena imposes on any deployed system. Each is tagged with its overlay category (A/B/C per the model above).

### 1. Multi-jurisdictional regulatory layering — **(C) overlay-only pattern**

**Primitive**: Same record carries rules from three or more independent regulatory authorities (federal HUD, federal IRS, federal SAM.gov, state IHFA-level, state Idaho-public-records). Each rule set has its own audit cycle, change cadence, and consequence chain. The record's *rendering* depends on the requesting party's jurisdictional status.

**Overlay specification**: the regulated overlay defines a *jurisdictional context* attached to every read operation. A field that is internal-only under HUD reporting is public-record under Idaho IPRA *unless* trade-secret carved out, with per-page watermark discipline as the carve-out mechanism. som-core has no opinion on jurisdiction; the overlay provides the pattern.

### 2. Multi-fund layered allocation on shared project records — **(B) overlay extension of PCS**

**Primitive**: A single project carries N federal funding sources (LIHTC + HOME + HTF + ESG), each with its own rules, compliance windows, allocation amounts, and reporting cycles. The project record must reconcile against each authority independently while presenting a unified view.

**Overlay specification**: regulated-class deployments add a stacked-allocation pattern on top of PCS-Daemon's registry model. PCS-Daemon spec is unchanged; the overlay specifies that a regulated deployment activates the stacked-allocation extension. Worked example sits in this overlay, not in PCS-Daemon spec.

### 3. Federated identity across role tiers with time-bounded grants — **(B) overlay extension of IAM**

**Primitive**: Six identity tiers minimum — external applicant, external property manager (scoped to their properties), internal staff verifier (scoped by program/role), internal admin (risk scorer), internal inspector (mobile-offline-with-sync, scoped to assigned properties for a defined window), external auditor (read-only over defined scope). Time-bounded grants are first-class.

**Overlay specification**: the regulated overlay adds the role-tier richness, federated-identity integration with customer IdP, and time-bounded grant semantics on top of IAM-CORE-SPEC's identity contract. IAM-CORE-SPEC is unchanged; the overlay specifies which IAM extensions activate under the regulated class.

### 4. Field-level audit log with attestation chain — **(B) overlay extension of ACT**

**Primitive**: Every field-level change records old value, new value, timestamp, user ID, and ties back to the identity attestation chain. SOC 2 Type II and IRS audit both depend on field-level granularity. Replay must be possible from the audit log alone. The attestation chain survives substrate transitions.

**Overlay specification**: ACT-SPEC's audit contract is the baseline; the regulated overlay tightens granularity to field-level and pins attestation-chain survival across substrate transitions. ACT-SPEC's sector-neutral granularity stays whatever core requires (record-level may be sufficient for a research lab); the overlay activates field-level under regulated-class deployments. ACT-SPEC is unchanged.

### 5. Configurable rule-engine with toggle semantics + version tracking — **(B) overlay extension of PGE**

**Primitive**: The IRS/HUD/IHFA tenant-test engine is configurable: which tests are active, which set-asides are toggled on, can be adjusted per property or per program. Rule sets are versioned, with attribution of who-approved-which-rule-version. Historical evaluations must be reproducible against the rule set active at evaluation time, not the current rule set.

**Overlay specification**: PGE-SPEC's rule-corpus model is the baseline; the overlay adds toggle semantics, per-evaluation snapshot versioning, and rule-history retention. PGE-SPEC OQ-P1's overlay mechanism already anticipated this layer; this overlay instantiates it for the regulated class. PGE-SPEC is unchanged.

### 6. Closed-bid / deferred-disclosure / sealed-until-event — **(C) overlay-only pattern**

**Primitive**: Procurement runs as a closed bid — proposals are sealed until the deadline, after which they are unsealed for evaluation. Pre-deadline access by any party (including system administrators) constitutes a procurement violation. The seal mechanism is attestable from the audit log.

**Overlay specification**: the regulated overlay defines a cryptographically-attestable seal-until-event pattern that uses ACT's attestation infrastructure as the substrate. som-core has no procurement opinion; the overlay specifies the pattern.

### 7. Occasionally-connected client substrate tier — **(B) overlay extension of SOM-IP-1**

**Primitive**: Mobile inspection app, offline-capable, checklist + photo capture + GPS, sync when connectivity returns. Multi-inspector conflict resolution required.

**Overlay specification**: SOM-IP-1's Substrate Matrix presumes connected substrates as core. The regulated overlay extends the matrix with an "occasionally-connected client" tier carrying its own conformance requirements (storage limits per device class, idempotent sync API contract, conflict resolution policy, attestable evidence chain across the disconnected window). SOM-IP-1 itself is unchanged at core; the overlay specifies the extension that activates under regulated-class deployments.

### 8. External authority feed with periodic ingestion — **(C) overlay-only pattern, with PGE + CRB anchors**

**Primitive**: Periodic ingestion from external regulatory sources — HUD field/form updates, IRS rule changes, SAM.gov debarment list — with attribution of source, fetch date, and applied-to records. Updates may invalidate in-flight applications or recompute rule-engine outcomes. Ingestion is a governance event requiring CRB approval before applied to production rule sets.

**Overlay specification**: the overlay defines the external-authority-feed pattern, composed of PGE (rule-corpus consumer) + CRB (governance gate) + ACT (audit trail). som-core has no opinion on external authority feeds; the overlay specifies the composition.

### 9. Document depository with retention policies + legal hold — **(C) overlay-only pattern**

**Primitive**: Documents have lifecycle policies (retain N years for document type X, archive after N years, destroy after N years), with legal-hold overrides that suspend the lifecycle. Federal records retention rules apply on top of state-level rules. Legal-hold overrides are auditable.

**Overlay specification**: the overlay defines the document-lifecycle pattern composed over DPG (lifecycle enforcement) + PGE (retention policy specification) + ACT (audit of legal-hold actions). som-core does not specify retention policies; the overlay specifies them as overlay-tier patterns activated under the regulated class.

### 10. Customer-tier support with SLA — **(C) overlay-only pattern**

**Primitive**: 8a-5p MST live support via phone or ticket system, Monday-Friday. Tier-2+ compliance questions are personally-accountable for the customer's federal program manager; AI-mediated tier-2+ attestation is not customer-acceptable.

**Overlay specification**: the overlay defines a customer-facing support-shell composed over IBX (ticket substrate) + MCC (control plane surface) + IAM (identity scoping) + ACT (audit trail). Tier-1 AI-mediation boundary is explicit; tier-2+ human-attestation requirement is encoded. som-core does not specify customer support; the overlay specifies the pattern.

### 11. SOC 2 Type II posture with continuous controls — **cross-overlay; out of scope for v0.1**

**Primitive**: SOC 2 Type II audit operating-effectively over a 6-12 month observation window, with controls evidence continuously collected and auditor-attestable.

**Overlay specification**: a separate `SOM-SOC2-OVERLAY.md` is proposed as a sibling overlay using the same anchor-document method (sourced from SOC 2 Trust Services Criteria). Out of scope for this overlay's v0.1; a regulated-class deployment activates both overlays together.

### 12. Substrate-pluggable per-customer deployment — **(A) already in core**

**Primitive**: Customer chooses substrate per seam (their Postgres, their IdP, their hosting). SOM stipulates per-seam requirements; customer-side conformance attests fitness.

**Overlay specification**: none required. SOM-IP-1 (substrate-pluggability) and SOM-CONFORMANCE.md (stipulate→connect→certify) cover this in core. The overlay cites; nothing to extend.

## Overlay coverage table

| # | Primitive | Category | Owning pillar(s) | Overlay action |
|---|---|---|---|---|
| 1 | Multi-jurisdictional regulatory layering + disclosure-bound rendering | C | Overlay-only | Define jurisdictional-context + per-field disclosure classification pattern |
| 2 | Multi-fund layered allocation | B | PCS-Daemon | Add stacked-allocation worked example as overlay-tier addition |
| 3 | Federated identity + time-bounded grants + role-tier richness | B | IAM-CORE | Add federated-tier extensions + grant-window semantics as overlay-tier addition |
| 4 | Field-level audit log + attestation-chain survival | B | ACT | Tighten granularity to field-level + pin attestation-chain survival as overlay-tier addition |
| 5 | Configurable rule-engine + toggle semantics + version tracking | B | PGE | Add toggle + per-evaluation snapshot versioning as overlay-tier addition (instantiates PGE OQ-P1) |
| 6 | Closed-bid / sealed-until-event semantics | C | Overlay-only (uses ACT substrate) | Define seal-until-event attestable pattern |
| 7 | Occasionally-connected client substrate tier | B | SOM-IP-1 + SOM-CONFORMANCE | Extend Substrate Matrix with new tier + conformance requirements as overlay-tier addition |
| 8 | External authority feed with attribution + CRB governance | C | Overlay-only (uses PGE + CRB + ACT) | Define external-authority-feed pattern composition |
| 9 | Document depository with retention + legal hold | C | Overlay-only (uses DPG + PGE + ACT) | Define document-lifecycle + legal-hold pattern composition |
| 10 | Customer-tier support with SLA + AI-mediation boundary | C | Overlay-only (uses IBX + MCC + IAM + ACT) | Define customer-support-shell pattern composition |
| 11 | SOC 2 Type II posture with continuous controls | — | Cross-overlay | Out of scope for v0.1; sibling `SOM-SOC2-OVERLAY.md` proposed |
| 12 | Substrate-pluggable per-customer deployment | A | SOM-IP-1 + SOM-CONFORMANCE | Cite — already in core |

## Overlay activation and conformance

A deployment activates this overlay by including a manifest reference in its deployment configuration (per the eventual SOM deployment-config schema — out of scope for this doc). Activation has three consequences:

1. **Overlay-tier requirements activate on top of core pillar contracts.** An implementation that satisfies pillar-core conformance must additionally satisfy the overlay-tier requirements for each pillar the overlay extends. Per-pillar overlay-tier conformance is attested via the same stipulate→connect→certify model (SOM-CONFORMANCE.md), but against the overlay-tier contracts rather than the core contracts.

2. **Overlay-only patterns become required.** The five overlay-only patterns (jurisdictional rendering, sealed-until-event, external-authority-feed, document-lifecycle, customer-support-shell) become required components of the deployment.

3. **Core pillar conformance remains unchanged.** A deployment that does not activate this overlay (e.g., the research lab, a non-regulated customer) is unaffected. The same pillar implementations are conformant against core regardless of overlay activation.

This is the operational consequence of the overlay model: regulated-class deployments are *composed* from unchanged pillar core + overlay activation, not built from a forked core.

## Anchor extension methodology

This overlay commits to anchor extension as a recurring process:

1. **v0.2** — fold in a second anchor RFP from an adjacent federal-program-grade arena (target: HRSA grantee RFP, USDA Rural Development RFP, or state Medicaid administrator RFP). Identify primitives that the IHFA anchor undersamples or differently emphasizes. New primitives extend the overlay; existing primitives may have their overlay-tier requirements refined.

2. **v0.3** — fold in a third anchor from a different vertical (target: a state environmental remediation RFP, a state DOT corridor program RFP, or a FERPA-bound education record system RFP).

3. **v1.0 (overlay-promotion)** — by v1.0, the overlay should be validated against ≥4 anchor RFPs across ≥3 distinct verticals. v1.0 status promotion is contingent on no anchor RFP surfacing a workflow primitive uncovered by the overlay and no overlay-tier requirement remaining ambiguous.

## Open questions

1. **Where do anchor RFPs live in the repo?** Proposal: `case-studies/regulated-workflow-anchors/<year>-<issuer>-<short-title>.md` for the digested form (paraphrased + cited; not the raw PDF). Raw PDFs are not committed (license/distribution discipline). Each digest cites the public source.

2. **Should disclosure-bound rendering be promoted from overlay-only to a SOM-IP (cross-cutting integration principle)?** It is overlay-only in v0.1. If a second anchor RFP (v0.2) demonstrates the same primitive in a different vertical, that is empirical pressure to promote. Recommendation: hold as overlay-only until v0.2 evidence; if generalized, propose SOM-IP-3 ratification with Judge sign-off.

3. **Is the SOC 2 overlay a sibling or a sub-overlay of this one?** Recommendation: sibling. SOC 2 is its own anchor-document class (SOC 2 Trust Services Criteria), and regulated-class deployments will frequently activate both. Composing two siblings is cleaner than nesting.

4. **What is the activation manifest format?** Out of scope for this overlay's v0.1; the SOM deployment-config schema is a separate workstream. This overlay declares its activation requirement abstractly until that schema lands.

5. **Are pillar-spec writers expected to know about overlay activation?** Recommendation: no. Pillar specs remain sector-neutral; overlays are the home for sector/regulatory shape. The pillar spec writer does not need to know which overlays will activate against the pillar in deployment. The overlay author is the one tracking which pillar contract the overlay extends and ensuring the overlay-tier additions are consistent with the unchanged core contract.

6. **Industry Experience as evaluation factor (#4 in IHFA's scorecard) is structurally adversarial to newcomers.** Should this overlay document a teaming or reference-customer pattern? Recommendation: out of overlay scope; flag in the spec campaign plan as a strategic concern.

## Failure modes to watch

- **Overlay drift back into core**: pressure to "just add this to the pillar spec" because the regulated arena requires it. *Mitigation*: this overlay is the canonical place for regulated-class shape; pillar spec PRs that propose absorbing overlay-tier shape get flagged for re-routing into the overlay. The hard discipline (this overlay does not modify pillar contracts) goes both directions.

- **Anchor over-fitting**: designing the overlay around IHFA-specific quirks rather than the workflow class. *Mitigation*: anchor extension methodology — v0.2+ requires additional anchors; primitives that don't generalize get demoted to anchor-specific notes within the overlay, not folded into the cross-anchor overlay-tier contract.

- **Overlay activation skipped in deployment config**: a regulated-class customer deploys without activating the overlay; field-level audit, sealed-until-event, disclosure-bound rendering are missing in production. *Mitigation*: deployment config schema (separate workstream) commits to overlay-activation discipline; activation is part of the deployment record and is itself audit-loggable.

- **Disclosure-bound rendering omitted at pillar boundaries during overlay activation**: an overlay-activated deployment uses a pillar implementation that does not consult disclosure context, leaking jurisdictionally-restricted fields. *Mitigation*: overlay-tier conformance harness (analogous to per-seam core conformance per SOM-CONFORMANCE) tests disclosure-rule consultation at every rendering boundary; deployment fails activation conformance if a pillar implementation does not consult disclosure context.

- **Occasionally-connected substrate trusted with insufficient discipline**: a mobile-tier substrate accepts compliance-affecting actions without proper attestation infrastructure, breaking the audit chain. *Mitigation*: the overlay's Substrate Matrix extension defines conformance requirements for the tier; no occasionally-connected client may carry compliance-affecting actions without satisfying the matrix.

- **Customer-facing AI-mediation boundary leaks into tier-2**: an AI-mediated support shell answers a compliance question on its own authority; customer's federal program manager attests to it; audit finds the answer was wrong. *Mitigation*: the support-shell pattern documents the tier-1/tier-2 boundary as a structural seam, not a guideline. Tier-2 responses require human attestation per ACT's identity-attestation contract.

- **SOC 2 audit clock surprises**: SOC 2 controls operating-effectively over 6-12 months; overlay-tier requirements that affect SOC 2 controls re-start the clock. *Mitigation*: tracked in proposed sibling `SOM-SOC2-OVERLAY.md`; overlay revisions that affect SOC 2 controls must be flagged explicitly.

## Dependencies

- som-core pillar specs at v1.1+ remain the baseline; this overlay activates on top of them unchanged.
- PGE-SPEC OQ-P1 is the mechanism anchor; this overlay extends the rule-corpus overlay model to multi-pillar workflow primitives.
- SOM-CONFORMANCE.md (stipulate→connect→certify) extends to per-overlay-tier conformance attestation; no change to its model, just per-overlay invocation.
- Sibling `SOM-SOC2-OVERLAY.md` (proposed, out of scope for this overlay) for SOC 2 Type II posture.
- Deployment-config schema (separate workstream) for overlay activation discipline.
- Anchor-extension cycle (Watson, anchor-document method, recurring at v0.2 / v0.3 / v1.0 cadence).

## Success criteria

- **v0.1 (this revision)**: overlay published; coverage table maps every IHFA RFP requirement into one of three overlay categories (A/B/C) with the overlay's action specified; overlay-only patterns are scoped enough to ratify or reject in v0.2.
- **v0.2**: additional anchor RFP folded; any primitives uncovered by IHFA but present in the second anchor are added to the overlay; primitives that don't generalize are demoted to anchor-specific notes.
- **v1.0**: ≥4 anchor RFPs across ≥3 distinct verticals; coverage table fully closed (or remaining open items explicitly deferred with justification); a SOM mesh deployment with this overlay activated can satisfy a federal-program-grade RFP without ad-hoc deployment-class concessions.

## References

- IHFA RFP: "Request for Proposal — Federal Programs Project Management Software," Idaho Housing and Finance Association, issued by Paula Grow, May 5, 2026. Proposal deadline 2026-06-05 5pm MST. Public-domain procurement document.
- `planning/SOM-SPEC.md` — mesh invariants (SOM-MI-N), integration principles (SOM-IP-N)
- `planning/SOM-CONFORMANCE.md` — stipulate→connect→certify model; per-seam conformance; extensible to per-overlay-tier conformance
- `planning/SOM-PROBLEM-STATEMENT.md` — design drivers from operational practice
- `planning/SOM-DESIGN-PHILOSOPHY.md` — first principles; core stability commitment
- `planning/PGE-SPEC.md` OQ-P1 — cross-deployment rule overlay model: rule resolution = core ∪ deployment-additions − deployment-removals. **Architectural anchor for the overlay mechanism this doc extends.**
- `planning/PGE-SPEC.md` DR-PGE-2 — Stratum-3 (domain-coverage) extension trigger; held on overlay-sufficiency
- `planning/PGE-SPEC.md` OQ-P3 — plugins may NOT mutate core corpus; deployment-overlay handles plugin-introduced rules
- `planning/IAM-CORE-SPEC.md` — identity pillar (overlay extends with federated tiers + time-bounded grants)
- `planning/IBX-SPEC.md` — inbox / claim queue (overlay uses as ticket substrate for customer-support-shell)
- `planning/ACT-SPEC.md` — audit / conformance / telemetry (overlay tightens to field-level granularity)
- `planning/PGE-SPEC.md` — policy / governance (overlay adds rule-engine toggle + version tracking)
- `planning/DPG-SPEC.md` — deployment governance (overlay uses for document-lifecycle enforcement)
- `planning/CRB-SPEC.md` — change review board (overlay uses for external-authority-feed governance)
- `planning/PCS-DAEMON-SPEC.md` — PCS-Daemon (overlay adds stacked-allocation worked example)
- `papers/OPERATING-ACROSS-THE-GAP.md` (research-papers repo) — the failure-mode framework that this overlay's stringency requirements protect against. Field-level audit and disclosure-bound rendering are *structural countermeasures* against the silent-confidence-preserving volatility documented in the paper.
