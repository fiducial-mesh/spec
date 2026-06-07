---
title: "AIR Spec — Design Notes & Severity-Model Research (pre-spec reference)"
doc_type: design-reference
status: draft-notes
version: v0.1
authors:
  - patton
date: "2026-06-05"
roles:
  - failure-analysis
  - design-intent
author_id: patton
references:
  - planning/AIR-001-closed-not-landed.md
  - planning/PILLAR-NAMES.md
  - planning/MESH-SPEC.md
---

# AIR Spec — Design Notes & Severity-Model Research

**What this is**: a durable design reference for when the **AIR pillar spec** is drafted.
NOT a spec, NOT an incident report, NOT a ratified pillar. AIR-as-a-pillar requires Judge
sign-off per CD1 (eight pillars) + PILLAR-NAMES discipline; this file is the
captured thinking + external research so that work doesn't start from a blank page or rely
on session memory (which is the chronic failure mode AIR is partly meant to address).
Captured 2026-06-05 from a design discussion with Judge.

**Attribution honesty (added 2026-06-05 after a Watson/Judge correction).** This file mixes
two things and they must not be conflated: (a) **cases and gaps Judge raised directly** in
the discussion — the per-incident principle, the bug-vs-incident line, the PCS-fires-AIR
case (§1.2), the substrate-failure case (§1.3), the security-need-to-know case + ACT/AKB
exclusion (§1.4), the SEC-pillar gap, the two-Atlassian-products distinction; and (b)
**Patton's synthesis built on those prompts** — the contract-vs-substrate framing (§1.1), the
"AIR is not a pillar, it's meta-layer" placement, the AKB+AIR+PCS "containment architecture"
framing, and the specific structural-fix shapes. The "(Judge, 2026-06-05)" tags on section
headers mark *the case/gap Judge raised*, NOT endorsement of my synthesis of it. Where a
framing is my reading, it is my reading until Judge ratifies it — nothing in this file is a
Judge-authorized architectural commitment. (This honesty note exists because an earlier
correction of mine over-attributed my own synthesis to Judge as "standing discipline"; that
is the closed-not-landed root cause in attribution form — an unverified attribution treated
as authorization — and it should not be repeated in a durable doc.)

---

## 1. Core concept — what AIR IS (and is not)

**AIR = Agentic Incident Reports = incident management, where an incident is anything
service- or customer-impacting, regardless of cause.** This is the SRE/ITIL sense of
"incident," NOT the bug-tracker sense.

- An **incident** is an *impact event* — something that affected (or nearly affected)
  service or customer, severe enough to warrant a formal capture → root-cause → tracked
  improvement loop.
- The **cause is an attribute of the incident, not its definition.** The cause may be
  agentic/process (AIR-001 was — closed-not-landed), OR service/operational (a pillar
  drops telemetry under load, a substrate migration corrupts the audit trail, an IAM mint
  strands an identity), OR security (a breach / near-miss like the Vault-token-in-transcript),
  OR data (corruption/loss), OR availability (outage).
- **Distinction from a bug report**: a bug is a defect in a thing; an incident is an
  *impact*. More severe than a bug precisely because it is service/customer-impacting. The
  entry threshold (§4) is what separates the two.

**Runtime self-instrumentation — the payoff (Judge, 2026-06-05).** With the mesh deployed at a
customer site, the mesh uses its OWN features to root-cause and report its own incidents *before
a human sees them*: a PCS workflow fails (§1.2) or its substrate dependency fails (§1.3) →
the workflow emits an AIR → RC machinery runs through PCS flows → the report lands
(internally for mesh-side CLCA, externally into the customer's JSM/ServiceNow via the §1.1
seam) automatically. The mesh becomes self-instrumenting for failure: it watches itself,
diagnoses itself, files the report; the human arrives to an already-captured,
already-triaged incident instead of a mystery. This is the AIR+AKB+PCS containment running
at customer-runtime, not just in the lab.

**Boundary — AIR is for INCIDENTS only; ABG (Agent Bug Reporting) is the sibling for
agent-defects (Judge, 2026-06-05; ABG design deferred — "more on that later").** Keep the
bug-vs-incident line: AIR = impact event (incident-response / JSM side, CLCA-to-closure,
runtime-emitted). **ABG = a defect in an agent or its output with no (or not-yet) impact** —
the agent reasoned poorly, produced a bad artifact, misbehaved, but nothing went sideways in
production. ABG belongs on the *development/delivery* side (the Jira-Software lane,
backlog-ordered — §1.1), NOT the incident side. The threshold (§4) is the escalation switch:
an agent bug that *causes* impact crosses into an AIR; one caught before impact stays an ABG.
This keeps AIR from diluting (every agent misstep becoming an "incident") and gives
agent-defects their own proper home. ABG is a candidate sibling pillar/spec on the dev side;
not designed here.

The symmetry is the architecture (capture now, design ABG later): **agents find and report
both bugs AND incidents orders of magnitude faster than humans** — at machine speed,
continuously, including the boring ones. Same contract-vs-substrate split (§1.1) on both
sides — the mesh owns the *discipline* (what a well-formed report is), the customer's existing
tool is the *seam*:
- **Incident** → AIR → incident-response seam (JSM / ServiceNow / PagerDuty).
- **Defect** → ABG/ABR → development seam (Jira Software / GitHub Issues / Linear / "whatever
  the bug system is"). An agent-emitted bug flows into the customer's bug tracker the same
  way a the mesh-emitted AIR flows into their incident tool — same emit-interface pattern (§1.2),
  same bring-your-own-tool seam.
ABG design questions deferred to "later" (Judge): what a well-formed agent-emitted bug report
is; dedup (so agents don't file N variants of one defect); and severity/priority on the
*backlog* model (the Jira-Software delivery-priority classifier — NOT the incident-response
model AIR uses; see §5's three-classifier distinction — ABG uses the FIRST one, the one AIR
never touches).

**AIR's place in the architecture — two work-management DOMAINS, but they are SUBSTRATE
SEAMS, not provided pillars (Judge, 2026-06-05).** The team has two distinct work-management
domains, as different as Atlassian's two products (§5):

1. **Development / delivery management** (the Jira-Software domain) — projects, epics,
   sprints, backlogs, the PR workflow, issue tracking. The lane that *generates* work and
   orders it ("what do we build next").
2. **Incident management** (the JSM domain) — detection, severity classification, response,
   capture, CLCA, corrective/preventive tracking. The lane that *responds to* impact events
   ("what failed and how do we stop it recurring").

BUT — and this is the load-bearing decision — **a customer already runs these.** They have
Jira, or ServiceNow, or GitHub Issues + PagerDuty, or Linear, or nothing. The mesh cannot say
"adopt my PM tool and my incident tool" — that is the exact lock-in MI-8 forbids. So
work-management is **not a thing the mesh provides; it is a substrate the mesh consumes.** The
resolution is the same contract-vs-product split the mesh uses for every substrate — see §1.1.
AIR is specifically the **reporting + corrective-action contract** of the incident domain
(the analogue of a JSM post-incident review — one component, not the whole tool). It does
NOT own detection, alerting, or response-routing, and it does NOT own the *storage/ticketing*
— the customer's existing tool is the substrate behind the seam. AIR is the narrow,
load-bearing core: the incident record *contract* + 5-whys + CLCA loop + track-to-closure
*discipline*. Needed *first* and *most* because the capture-and-correct loop bends the
failure curve.

## 1.1 The load-bearing decision — contract (the mesh need) vs substrate (customer seam)

The question "is work-management a the mesh need or a substrate seam?" is the **Exit Test / MI-8
question applied to work-management** — and the answer is the same as for every other
substrate: **split the contract from the product.**

- **The CONTRACT is the mesh's (a genuine the mesh need).** The mesh defines what an incident record *is*:
  the AIR schema, severity taxonomy, the blameless discipline, the capture→CLCA→verified-
  closure loop, the close-on-landed-not-described criterion, the recurrence metrics. This is
  genuinely the mesh's contribution because **no off-the-shelf tool enforces the discipline** —
  nothing in Jira or JSM says "the preventive must be a landed PCS gate, verified in place,
  or the incident does not close." That rigor (the AIR+AKB+PCS containment against agentic
  memory) is the novel part and it is the mesh's.
- **The STORAGE / TICKETING is a SEAM (bring-your-own-tool).** *Where* the incident record
  lives and how it is ticketed — Jira, JSM, ServiceNow, GitHub Issues, a Postgres table — is
  the customer's substrate. The mesh emits an AIR conforming to its contract; an adapter renders
  it into whatever the customer runs. JSM shop → AIRs as JSM incidents; GitHub shop → labeled
  issues; sovereign air-gapped shop with nothing → the built-in reference implementation (a
  markdown file in a repo — which is exactly what AIR-001 *is* today).

**The test for which-is-which (write this into the spec):** *does the mesh's value live in the
discipline or in the storage?* For incidents, the value is overwhelmingly the discipline
(blameless 5-whys, CLCA-with-verified-closure, recurrence tracking) — storage is commodity.
So the mesh owns the contract, seams the storage. Same pattern as IBX: the PCT contract is the mesh's;
ClickHouse-vs-Postgres is the seam. The incident *record* is the mesh's; Jira-vs-JSM-vs-GitHub is
the seam.

**The two domains are ASYMMETRIC — do not spec them as two equal pillars.**
- **Incident management** has a *meaty* contract (the AIR discipline is novel and the mesh-owned)
  over a thin seam (storage is commodity). → worth a real spec (AIR).
- **Development / delivery management** is *almost entirely a seam* over a thin contract —
  the discipline the mesh cares about (PR review, two-person control, Exit-Test gates,
  fold-tracking) is already encoded in CLAUDE.md + PCS workflows; the backlog/sprint tooling
  is pure commodity the customer already has. → mostly "conform to the customer's tool,
  enforce our gates via PCS," not a standalone pillar spec.

So the likely shape is **one incident-contract spec (AIR) + a set of work-management seams**
into the customer's existing PM/incident tools, with development-side discipline carried by
PCS-workflow enforcement over the customer's backlog tool — NOT two new equal pillars. And
because these govern *how the team operates on the mesh* rather than carrying agent runtime
traffic, they are **meta-pillars** — same category as MCC ("not a 9th pillar"), so they
almost certainly sit OUTSIDE the CD1 eight-pillar count. Final shape is Judge's call.

## 1.2 AIR is NON-OPTIONAL — pillars emit AIRs programmatically (the PCS case, Judge 2026-06-05)

The decisive argument that AIR is a hard the mesh need, not a nice-to-have: **a pillar's own
workflow must be able to raise an AIR when it fails.** Case-in-point (Judge): a PCS
production workflow deploys an app/config and it goes sideways — deployment fails, config
lands wrong, the app comes up broken. Something must happen beyond the workflow logging an
error and dying. The PCS deploy step itself **calls/creates an AIR** at the moment and point
of failure — not a human noticing later, not an agent remembering to write it up.

This adds a creation path the spec MUST cover and AIR-001 did not exercise:

- **Human-authored AIR** (investigation, after the fact) — what AIR-001 is: a person/agent
  writes the incident up.
- **Machine-emitted AIR** (runtime, at the failure) — a pillar's workflow detects its own
  failure and emits an AIR programmatically, born automatically at the failure point.

Same contract, two creation paths. **Consequence for the spec: the AIR contract needs a
programmatic EMIT INTERFACE, not just a document template** — a callable surface a pillar
workflow invokes on failure (pre-populating problem-description / timeline-start / severity /
incident_class from the failure context; the 5-whys + CLCA get filled in during
investigation). The auto-emitted AIR opens in a `detected` / `triage` state; a human/agent
completes the root-cause and CLCA.

**Why this makes AIR non-optional AND fits the seam model (it doesn't break §1.1):**
- The **trigger is the mesh's** — a workflow step that emits an AIR on failure is mesh-internal
  plumbing; it cannot be a customer's tool, because PCS is the mesh's and the failure happens
  inside the mesh's runtime. The mesh must be able to *raise* an incident from inside its own
  workflows. Non-negotiable, the mesh-owned.
- The **record contract is the mesh's** — the AIR schema the step emits.
- The **storage is still a seam** — *where* the auto-generated AIR lands (JSM incident,
  GitHub issue, markdown file) is the customer's substrate per §1.1.

**This generalizes across every pillar.** If PCS-deploy-failure emits an AIR, then every
pillar's *failure-mode section is a candidate AIR trigger*: DPG worker crash past dead-letter
→ AIR; IAM mint strands an identity → AIR; IBX Judge-gate compromise detected → AIR; an
ACT/MI-13 reconciliation sweep that can't reach a terminal state → AIR. The pillars already
enumerate their failure modes in-spec; **AIR is the common sink those failure modes drain
into.** This is what makes "monitor and measure these incidents" real — incidents stop
depending on a human writing them up and start being *emitted by the thing that failed.*

**New cross-pillar seam this creates: PCS ↔ AIR (and pillar ↔ AIR generally).** PCS needs to
know how to emit an AIR (the contract + the callable emit interface); AIR needs to be
reachable from inside a PCS workflow (a callable surface, not just a file format). Same shape
as the IBX↔PCS coupling boundary — each side names what it relies on from the other. **The
AIR spec needs a "Coupling boundary: PCS ↔ AIR" section** (and more broadly a
"pillar-failure-mode → AIR-emit" contract that any pillar can call). This is also where AIR
touches PCS the *other* direction already noted in §1/§6: the CLCA *preventive* often becomes
a new PCS-workflow gate — so PCS both *fires* AIRs (on failure) and *receives* AIR
preventives (as new enforced steps). Bidirectional, and worth naming both directions.

## 1.3 Second emit case — SUBSTRATE-side failure (Judge 2026-06-05): dual-disposition + MI-8's operational face

Second machine-emitted case, structurally DISTINCT from §1.2 and the distinction drives the
spec. Same setup — an agent running a PCS workflow — but the failure is on the **customer
substrate behind a seam**: the DB is offline, identity/AD authentication failed, the domain
controller is unreachable, a secrets store is down — some the mesh substrate *dependency* fails.

**Why this is different from §1.2:** in §1.2 the mesh's own logic failed (the workflow, the config
it generated) — one owner (the mesh), corrective lands inside the mesh. Here **the mesh did not fail; the mesh's
dependency did.** That creates three properties §1.2 doesn't have:

**(a) The blameless discipline is genuinely tested — and this is where it earns its keep.**
The naive 5-whys on "DB offline" walks toward "the customer's database fell over," which
sounds like fault *outside the mesh* — "not our problem." The AIR discipline (root cause is always
a missing *control*, never a fault) forces the right reframe: the customer's outage is the
**trigger**, not the root cause. The mesh-side root cause is **"did the mesh's seam degrade
gracefully, or did the mesh's response make it worse?"** — did the PCS workflow detect the dead
substrate and fail closed cleanly with a clear diagnostic, or did it hang / corrupt
half-state / retry-storm the failing substrate / leave the deploy indeterminate? The AIR
root-causes **the mesh's response to the substrate failure**, not the substrate failure itself.

**(b) Dual-disposition — two root causes, two owners, the AIR MUST split them.** A
substrate-failure AIR has two findings with different owners:
- **Customer-facing fact** (their disposition): "substrate X (your AD / your DB) was
  unavailable HH:MM–HH:MM; the mesh operations depending on it failed during that window." the mesh
  records it; the customer fixes their substrate.
- **the mesh-facing CLCA** (the mesh's disposition): "the seam's behavior under substrate-unavailable
  was wrong — e.g. it retry-stormed instead of backing off / didn't fail closed / left
  half-state. Preventive: circuit-breaker + clean fail-closed on the seam."
Conflating them is the failure mode: either the mesh blames the customer and fixes nothing on its
side, or the mesh takes blame for the customer's outage and over-engineers. The spec needs a
**dual-disposition structure** for `substrate`-class AIRs (customer-fact vs CLCA, owned
separately) — §1.2's single-owner structure is insufficient here.

**(c) This is MI-8's OPERATIONAL face — and it exposes a gap in the substrate contract as
currently specced.** All the substrate-matrix work (MI-8, the conformance profiles, the
IBX CD7 capability framing) specs what a substrate must *provide when it is WORKING*. This
failure class is about what the mesh does when the substrate is **NOT** working — and that is not
systematically specced. Pillar specs name seams + their working-contracts; most say "fail
closed" in a failure-mode bullet, but there is **no systematic substrate-unavailable
(degradation) contract per seam.** This AIR class is the thing that surfaces it: every
`substrate`-class AIR is evidence about whether a seam's degradation behavior was specced
and correct. **Feedback into MI-8: every substrate seam must spec its substrate-unavailable
behavior** (fail-closed semantics, retry/backoff policy, circuit-breaker, half-state
handling on dependency loss, the diagnostic it emits) — a *degradation contract* alongside
the working-contract. Substrate-failure AIRs are the measurement of whether that degradation
contract holds, the same way substrate-profile conformance runs measure the working
contract. (This is a candidate finding to route into the MI-8 / pillar-spec work
independently of AIR — the degradation contract is owed whether or not AIR exists; AIR is
just what makes its absence *visible* via recurring substrate AIRs.)

**Net additions to the spec from this case:** an `incident_class: substrate` (§3);
a dual-disposition record structure (customer-fact + CLCA, separately owned); and a
feedback requirement into MI-8 (per-seam degradation contract). The emit path is the same
programmatic interface as §1.2 — the PCS workflow detects the substrate failure and emits —
but the *triage* must classify it as substrate-side so the dual-disposition kicks in and the mesh
doesn't either self-blame for a customer outage or hand-wave its own bad degradation behavior.

## 1.4 Third emit case — SECURITY findings are NEED-TO-KNOW (Judge 2026-06-05): SEC classifies, AIR routes restricted

Third case, and it breaks an assumption the §1.1 seam model quietly made (that an AIR has
ONE destination). An agent doing work finds a security issue — exposed secrets, a vuln, a
misconfiguration leaking credentials, an agent that itself exposed a secret. That is an
incident (AIR) AND a security matter (SEC pillar — see pillar-gap note below). But its
**audience is need-to-know, not the default broadcast.**

**The principle: a security incident's report must not widen the blast radius.** Every other
AIR class wants *visibility* — broadcast it, more eyes is better. Security is the inverse:
broadcasting "here is the exposed secret / here is the hole" to the whole company is itself
a second security incident. The report routes to the **security team only**, on a restricted
channel, by default. This is the same lesson as the agent-out-of-secret-path invariant and
the Vault-token-in-transcript near-miss, now at the *reporting* layer: the report about a
leak must not itself become a leak — right information, wrong channel is still a breach.

**This breaks the single-destination assumption — AIR routing is by-class WITH an
access-control boundary.** The §1.1 seam was "which tool"; it must also be "which tool *and
at what visibility*." A `security`-class AIR routes to a restricted destination (the security
team's queue, a locked JSM project, a private channel) — NOT the general incident feed
everyone sees. The AIR schema needs an **audience / visibility field** (default: normal;
security: need-to-know-restricted), and every seam adapter must honor it — a seam that can't
enforce the restricted audience is not a valid destination for a security-class AIR.

**Security findings and telemetry NEVER land in ACT or AKB (Judge 2026-06-05) — the
exclusion is structural, and it is filtered-BEFORE, not redacted-after.** ACT and AKB are
categorically the wrong substrates for security content, for the §1.4 blast-radius reason one
layer deeper:
- **ACT** is the cognitive-telemetry audit trail — broadly readable, role-projected,
  consumed by Patton/Newton for behavioral analysis and by MCC dashboards. A security finding
  in ACT makes *the telemetry trail itself the leak*: anyone with ACT read access now holds
  the secret or the map to it. ACT is built for visibility; security findings are need-to-know
  — categorically incompatible.
- **AKB** is worse, because it is *durable + retrievable*: a finding in AKB is embedded,
  vector-indexed, and surfaced to future agents via retrieval. That turns a transient finding
  into a permanent, searchable artifact in shared memory — the Vault-token-in-transcript
  near-miss made *permanent and queryable*.

**The one exception, drawn precisely — classification METADATA vs finding PAYLOAD:**
- **Detection/classification metadata MAY exist** in the security plane (and, conservatively,
  *only* there): "a security event of class C occurred at time T, severity S" — the *shape*
  of the event, what SEC needs to detect patterns, measure recurrence, run ITDR. That thin
  metadata is what "detection, or classification maybe" means.
- **The finding PAYLOAD never lands in ACT/AKB, ever** — the actual exposed secret, the
  specific vulnerable path, the credential, the exploit detail. Not redacted-after (the
  secret already transited the wrong substrate by then, and scrubbing is lossy + error-prone
  — the Vault-token lesson: prevent the write, don't scrub it). **Filtered-before**:
  security-classified content takes a different path from the start and structurally never
  reaches the ACT emit or the AKB ingest.
- Conservatism note: for the highest-sensitivity classes, even the *existence* of a detection
  at a specific path can be a tell — so the metadata that reaches any broad plane must be
  shape-only, never location-or-target-identifying.

**Consequence for the pillar specs — an EXCLUSION INVARIANT (easy to violate by default).**
Every pillar's Telemetry Contract (the MI-11 manifest) and every AKB ingest path needs a
**security-content exclusion**: security-classified findings are filtered *before* they
reach the ACT emit or AKB ingest, not redacted after. This is structural, not a scrubbing
step. And it sharpens the SEC seam: **SEC must have its OWN restricted store for finding
payloads**, separate from ACT/AKB, because the general observability/memory substrates are
categorically disqualified from holding them — another argument SEC is a real pillar (it
needs a substrate the other observability pillars cannot be).

**Where AIR and SEC interlock (this is the "AIR and SEC" in Judge's framing):**
- **SEC owns the classification.** SEC is the pillar that knows a finding is security-
  sensitive, so SEC *marks* the incident need-to-know. AIR cannot make that call — it does
  not know what is sensitive; SEC does. SEC-classifies feeds an AIR attribute.
- **AIR owns the record + the visibility-aware routing.** Once SEC flags it
  `security`/restricted, AIR's emit interface routes to the restricted destination instead
  of the default. AIR carries the record and honors the audience field; SEC decides what the
  audience is.

**Customer-side security finding (the sharp sub-case in Judge's example).** An agent finds a
security issue on the *customer's* system while doing work. Like §1.3 this is dual-
disposition, but with a confidentiality twist: the finding is a customer-facing security
FACT that routes to *their* security team, restricted; the mesh's side is "the agent encountered
it and correctly *contained* it — did not broadcast, did not log it to a wide channel, did
not widen the blast radius." Here the routing + access boundary matter more than the CLCA:
an agent that found the issue but *reported it on the wrong channel* has itself caused a
security incident, so "contained correctly" is part of the mesh-side disposition.

**Pillar-gap this surfaces: SEC / ASEC (Security) is a missing pillar.** Security today is
SMEARED across pillars — PGE (enforcement: keyring, parameterized SQL, subprocess gating),
IAM (the no-bypass/fail-strict invariants, agent-out-of-secret-path), DPG (execution
isolation), the MCP-SECURITY-FRAMEWORK (PGE's de-facto spec). Each pillar carries a *piece*
of security as a property of itself, but **nothing owns security as a discipline**: threat
modeling, the mesh's security posture as a whole, ITDR (Identity Threat Detection & Response
— which IBX-SPEC DR1 defers to "when the ITDR layer is built" with no pillar owning it),
security-incident classification (this §1.4), and the cross-pillar security invariants no
single pillar can enforce because they span seams. **SEC is the LSM-policy-module to PGE's
LSM-hook-framework**: PGE is the enforcement *mechanism*; SEC is the discipline that decides
*what* to enforce, detects threats, and classifies security incidents. For a SOVEREIGN mesh
whose CLAUDE.md #1 line is "if we can't implement it safely, we don't implement it," a
platform with no pillar that owns security is a real structural gap. ITDR being homeless in
IBX-SPEC is the smoking gun. Candidate ninth runtime pillar (UNLIKE AIR/ABG/MCC, which are
meta-layer) — SEC plausibly IS a runtime pillar because it carries live detection/response
traffic. **This is a Judge-gated CD1 question** (does the count go to nine?); flagged
here because §1.4's security-incident classification needs an owner and SEC is it. Separate
design note warranted when Judge wants it.

**AIR is per-incident.** Each AIR is a faithful record of ONE event with ONE timeline. A
gap caught *before* it causes an incident is a **preventive action on discovery** — it does
NOT get appended to a prior incident's report. (This was learned the hard way on 2026-06-05:
the fold-tracking gap was briefly mis-filed as "AIR-001 D-6"; Judge corrected it — that gap
is a standalone preventive that *could prevent a future AIR-002*, and burying it inside
AIR-001 would both muddy AIR-001's boundary and hide the preventive where no one would find
it.) Per-incident discipline is what keeps each AIR citable instead of a kitchen-sink.

**The loop**: AIR is the **capture**; **CLCA** is the process; **implementation drives the
improvement**. Capture → analyze (5-whys) → CLCA (corrective + preventive per deficiency) →
implement → verify-in-place → close. AIR without the implementation step is just a diary;
the implementation landing as an *enforced control* (a PCS workflow, an AKB-retrievable
lesson) is what bends the failure curve.

**Why AIR + AKB + PCS together are the containment** (the architectural bet): the chronic
problem under all agent failures is **agentic memory** — disciplines held in a session's
head evaporate when the session ends. AIR captures what failed (per incident, clean). AKB
makes the lesson retrievable across sessions so it doesn't live in memory. PCS turns the
lesson into an enforced lifecycle gate. The lesson being *structurally present at the point
it is needed* (not *remembered*) is the containment against repeat failure. This is the same
failure-steered method that produced IONIS V22-gamma through eight dead ends, applied to the
process layer: each AIR is a measurement, each preventive is a steering correction, and the
system gets more failure-resistant the more it is run — *if* the lessons land in AKB + PCS
rather than in session memory.

## 2. Required structure of an AIR (the durable spine)

This generalizes cleanly across any cause. AIR-001 is the worked example the spec can point
to. Sections:

1. **Frontmatter** — `air_id`, `severity`, `incident_class` (the cause taxonomy, §3),
   `disposition` (open/resolved), `priority` (if adopting the impact×urgency model, §5).
2. **Blameless preamble** — names mechanisms and missing controls, never individuals;
   single purpose is preventing recurrence. (Severity describes *impact, not fault* — see
   §6; this is industry-standard SRE practice and it dovetails with the lab's existing
   blameless framing.)
3. **Problem description** — what was impacted, why it crosses the incident threshold, blast
   radius (the *control surface* affected, not just the immediate artifact).
4. **Timeline** — reconstructed from evidence (inbox, repo, telemetry), times to the record.
5. **Events leading to the incident** — the conditions that made it possible, stated as
   workflow/system properties.
6. **Five whys** — walk to the root; bottoms out at a *missing control*, never a person.
7. **Identified deficiencies + CLCA** — each deficiency gets corrective (fixes this
   instance) + preventive (removes the class) + owner.
8. **Resolution tracking** — table to closure; **closure criterion = preventive landed AND
   verified in place, not merely described** (a control described-but-not-landed is itself
   the AIR-001 root-cause class, so AIR refuses to close on a description).

## 3. Incident-class taxonomy (cause as ATTRIBUTE)

The class is a classification, NOT a scope limit — naming the set makes clear AIR covers the
whole impact surface, so a service outage gets an AIR (not a bug ticket) because *impact*,
not *cause*, crosses the threshold. Candidate set (refine at spec time):

- `workflow` — agentic / process failure (AIR-001: closed-not-landed)
- `service` — a pillar/substrate failing in operation (the "severe bug" case)
- `substrate` — a customer substrate DEPENDENCY fails (DB offline, identity/AD down, domain
  controller unreachable, secrets store down). DISTINCT from `service`: the failure is the
  customer's substrate, not the mesh's logic. Carries the **dual-disposition** structure (§1.3):
  customer-fact (their substrate, their fix) + CLCA (the mesh's degradation behavior, the mesh's
  fix). Root-causes the mesh's *response* to the substrate loss, never the customer's outage.
- `security` — breach or near-miss (e.g. credential exposure). **NEED-TO-KNOW audience
  (§1.4): routes restricted to the security team, never the default broadcast — the report
  must not widen the blast radius. SEC classifies; AIR routes restricted. Carries the
  visibility/audience field.**
- `data` — corruption / loss / integrity violation
- `availability` — outage / degradation

## 4. Entry threshold (what makes it an AIR vs an ordinary issue)

The threshold is the boundary that gives AIR its meaning. Without it AIR either dilutes
(everything's an incident) or gates too high (real incidents logged as bugs, skipping CLCA).
Candidate criterion, Judge to ratify: **customer-visible OR service-degrading OR
security-relevant OR a control-surface corrupted → AIR; everything else → ordinary issue.**
Note AIR-001 qualified under "control-surface corrupted" (the issue tracker reported nine
false completions) even though no customer was touched — the threshold must capture
internal-control-surface damage, not only customer-facing impact.

## 5. Severity / priority research — Atlassian (2026-06-05)

**Critical framing correction (Judge, 2026-06-05): the two Atlassian models below come from
two DIFFERENT PRODUCTS doing two DIFFERENT jobs. They are comparable but separate
classifiers — do not blend them.**

- **Jira Software** = *project / delivery management* (projects, epics, scrums, sprints,
  backlogs). Its **priority** field (Highest/High/Medium/Low/Lowest, ~P1–P5) is a
  **backlog-ordering** signal: "what does the team work next." Answers a *planning* question.
- **Jira Service Management (JSM)** = *incident-response / ITSM ticketing* (the Impact ×
  Urgency → Priority matrix, SLAs, on-call, the SEV scale for major incidents). Its priority
  is an **operational-response** signal: "how fast must we respond, who gets paged." Answers
  a *response* question.

The two end up with similar-looking P1–P5 labels, which is why they're easy to conflate —
but they measure different things (delivery-sequencing vs incident-response-urgency). The
label collides; the meaning does not.

**AIR maps to the JSM side, NOT the Jira-Software side.** An incident's severity/priority is
an operational-response classifier (how bad is the impact, how fast must we respond) — it is
NOT a backlog-ordering classifier (which sprint does this go in). Conflating the two would
be the bug-vs-incident category error again: an incident mis-handled as a backlog item skips
the CLCA loop. AIR uses the incident-response model; ordinary backlog work uses the
project-management priority field, and they stay separate.

### JSM model A — SEV scale (incident severity, objective impact)
Severity = **objective measure of impact**. Atlassian's own definitions:
- **SEV1** — critical incident, very high impact: customer data loss, security breach, or a
  client-facing service down for ALL customers.
- **SEV2** — major incident, significant impact: client-facing service down for a SUBSET of
  customers, or a critical function not working.
- **SEV3** — lower impact: minor / limited-scope problem.
- (Many orgs extend to SEV4/SEV5 for minor + cosmetic; some add SEV0 for "all-hands
  regardless of time/day," which should be rare — aim <4/year.)

### JSM model B — Impact × Urgency → Priority (ITIL response routing)
JSM also derives a response **priority** from a matrix (distinct from SEV; used for routing
/ SLAs):
- **Impact** = the effect on business processes / quality of service (how widespread / how
  bad).
- **Urgency** = time before the incident significantly impacts the business (a high-impact
  incident can be *low* urgency if the effect is deferred — e.g. won't bite until FY-end).
- **Priority** = matrix(Impact, Urgency), typically P1–P5 (P1 highest). JSM defaults unknown
  to P3. Priority drives SLA / response time / escalation routing.

### The load-bearing distinction WITHIN the incident model (consistent across all sources)
Even inside JSM, **Severity ≠ Priority.** Severity is the *objective technical state /
impact* of the incident. Priority is the *contextual response decision* (urgency + business
judgment). The same SEV2 at 3am Sunday affecting a small subset may be prioritized P2 and
wait for morning. Keeping them separate gives cleaner frameworks for both — and prevents the
common failure where two responders look at the same alert and disagree because the org
never defined the levels precisely enough to reach the same answer from the same data. (Note
this is a *third* distinct axis from the Jira-Software backlog-priority above — three
classifiers total: delivery-priority [Jira Software], incident-severity [JSM SEV], and
incident-response-priority [JSM Impact×Urgency]. AIR uses the latter two; never the first.)

### Recommendation for AIR (to decide at spec time, Judge ratifies)
- Adopt **SEV1–SEV3** (optionally +SEV4/SEV5) as the AIR `severity` field — objective impact,
  the JSM incident-severity model.
- Optionally adopt **Impact × Urgency → Priority** for response routing if AIR ever drives
  SLAs / on-call. For an internal agent-lab today this may be heavier than needed; the SEV
  scale alone likely suffices for v0.1, with the impact/urgency matrix as a documented
  growth path.
- **Do NOT reach for the Jira-Software backlog-priority model** for AIR — that's the wrong
  product's classifier. Backlog ordering of the *corrective/preventive work items* an AIR
  generates is fine to track in the project-management lane; the *incident itself* is
  classified by the incident-response model.
- **Severity definitions must be precise enough that two agents reach the same SEV from the
  same evidence** — the whole value of the scale is inter-rater consistency. Vague
  definitions inherit inconsistency into every downstream process (escalation, postmortem,
  recurrence metrics).
- **Severity describes impact, not fault** — keeps the SEV field consistent with AIR's
  blameless discipline. If severity ever ties to blame, agents will avoid accurate
  assessment.

## 6. Metrics AIR should enable (the "monitor and measure" goal)

The point of capturing incidents is to *measure* them over time. Worth specc'ing as
queryable fields / reports:
- **Severity distribution** — a healthy spread skews low (industry rule-of-thumb cited:
  ~5% SEV1 / 15% SEV2 / rest lower; if half your incidents are SEV1 you have severity
  inflation OR genuine reliability problems).
- **Recurrence by severity** — repeat incidents at the same severity = inadequate
  remediation (the preventive didn't take). This is the single most important AIR metric for
  the lab, because it directly measures whether the AIR+AKB+PCS containment is *working* —
  recurrence is the signal that a lesson stayed in memory instead of landing as a gate.
- **Time-to-closure** per deficiency / per AIR.
- **Open-preventives count** — how many CLCA preventives are landed-and-verified vs still
  owed (parity with the AIR-001 closure criterion).

## 7. Open design questions for spec time

- Exact `incident_class` set + whether near-misses get their own class or a `near_miss: true`
  flag (the Vault-token case was a near-miss — captured how?).
- SEV scale depth (3 vs 5 levels) for a lab of this size.
- Whether to adopt the Impact×Urgency priority matrix now or document it as a growth path.
- ~~AIR numbering / ID scheme (AIR-001, AIR-002, …) and where AIRs live (planning/ vs a
  dedicated AIR directory once there are several).~~ **RESOLVED 2026-06-07 (Judge directive) — see §7.1.**
- How AIR links to PCS (the preventive-as-enforced-workflow) and AKB (the lesson-as-
  retrievable-knowledge) — the cross-pillar seams that make the containment real. **Note the
  PCS↔AIR link is BIDIRECTIONAL (see §1.2): PCS *fires* AIRs (a deploy/config workflow that
  fails emits one programmatically) AND PCS *receives* AIR preventives (a CLCA preventive
  becomes a new enforced PCS-workflow gate). The spec needs both directions + a callable
  emit interface, not just a document template.**
- **Pillar shape — RESOLVED by Judge (2026-06-05): work-management is a SUBSTRATE SEAM, not a
  provided pillar (see §1.1).** Customers already run Jira/JSM/ServiceNow/GitHub/etc., so
  the mesh cannot provide PM/incident tooling — MI-8 forbids the lock-in. Split: the **contract**
  (AIR schema + CLCA discipline + verified-closure) is the mesh's; the **storage/ticketing** is a
  seam adapting to the customer's existing tool. The two domains are asymmetric — incident
  management has a meaty the mesh-owned contract (AIR) worth a real spec; development management is
  almost entirely a seam with PCS-workflow-enforced gates. Likely shape: **one AIR
  contract-spec + work-management seams**, NOT two equal pillars. Spec-time questions that
  remain: (a) these are meta-pillars *about* running the mesh, so almost certainly OUTSIDE
  the CD1 eight-pillar count (like MCC — "not a 9th pillar"); confirm; (b) names per
  PILLAR-NAMES; (c) does AIR ship first as the load-bearing core with seams + the
  development side deferred? All Judge's call.
- **The seam set to enumerate at spec time** (per the §1.1 split): the AIR contract must
  define the adapter surface so a customer's tool can consume a the mesh-conformant AIR — minimally
  JSM/ServiceNow (incident-native), GitHub Issues + label (the lab's current substrate), and
  the built-in markdown reference implementation (air-gapped default, = AIR-001 today). Same
  substrate-matrix discipline as the pillar specs: name the contract per seam, tested-profile
  boundary, role-not-vendor wording.
- Scope boundary between the two pillars: a *bug* (defect, no impact) routes to the
  development/delivery pillar's backlog; an *incident* (impact event) routes to the
  incident-management pillar and gets an AIR. The entry threshold (§4) is the switch between
  the two lanes — worth specc'ing as the explicit hand-off so nothing falls between them
  (an impact event mis-routed to the backlog skips CLCA; a mere bug mis-routed to AIR
  inflates the incident record).
- **Substrate degradation contract (per §1.3) — feeds back into MI-8 / pillar specs,
  independent of AIR.** Every substrate seam must spec its *substrate-unavailable* behavior
  (fail-closed semantics, retry/backoff, circuit-breaker, half-state handling on dependency
  loss, the diagnostic emitted) — a degradation contract alongside the working-contract the
  substrate matrix already specs. This is a candidate finding to route into the MI-8 /
  pillar-spec work on its own; AIR's `substrate` class is what makes its absence visible
  (recurring substrate AIRs = a seam with no degradation contract). Decide at spec time
  whether the AIR spec *requires* it or merely *surfaces* it for the pillar specs to own.
- **Security-incident routing + audience (per §1.4) — the AIR schema needs a
  visibility/audience field.** `security`-class AIRs route need-to-know-restricted (security
  team only), NOT the default broadcast — the report must not widen the blast radius. Routing
  is by-class WITH an access-control boundary; every seam adapter must be able to honor the
  restricted audience or it is not a valid destination for a security-class AIR. SEC
  classifies (marks need-to-know); AIR routes. Decide at spec time: the visibility field's
  value set (normal / restricted / customer-security-team), and the seam-adapter conformance
  requirement that a destination must enforce restricted audience.
- **SEC / ASEC (Security) pillar gap (per §1.4) — Judge-gated CD1 question.** Security is
  currently smeared across PGE/IAM/DPG with no pillar owning the *discipline* (threat model,
  posture, ITDR, security-incident classification, cross-pillar security invariants). SEC =
  the policy/decision layer to PGE's enforcement mechanism (LSM-module vs LSM-hooks). UNLIKE
  AIR/ABG/MCC (meta-layer), SEC is plausibly a true runtime pillar (carries live
  detection/response). Owns the §1.4 security-incident classification. Does CD1 go to
  nine? Judge's call; warrants its own design note.
- **Security-content exclusion invariant (per §1.4) — feeds back into MI-11 + AKB ingest,
  independent of AIR.** Security finding PAYLOADS never land in ACT or AKB — filtered BEFORE
  the emit/ingest, not redacted after (scrubbing is lossy; prevent the write). Detection/
  classification METADATA (shape-only: class, time, severity — never the secret, the path, or
  the target) MAY exist, conservatively, in the SEC plane only. SEC needs its OWN restricted
  store for payloads, separate from ACT/AKB (the general substrates are categorically
  disqualified). Spec-time: state the exclusion as an MI-11 Telemetry-Contract invariant +
  an AKB-ingest invariant; decide exactly what metadata is safe for which plane (shape-only;
  highest-sensitivity classes may suppress even existence-at-a-path).

## 7.1 Resolved operational decisions (2026-06-07, Judge directive)

The "where AIRs live" question in §7 was resolved 2026-06-07 after AIR-002 landed and demonstrated that AIRs are structurally cross-repo (today's AIR-002 cross-references mesh-spec failures, IONIS ML failures, workspace-tier infra failures, and the inbox cutover). Forcing AIRs to live in any one project repo creates an artificial home; the cross-class corpus the paper consolidates from requires a neutral seam. The resolution operationalizes the §1.1 contract-vs-storage split for the *internal* (the mesh-owned) side of the seam: the lab's reference AIR storage is a dedicated repository, and CLCA tracking uses that repository's native Issue tracker.

### 7.1.1 Dedicated repository — `github.com/fiducial-mesh/air`

AIRs are authored to **`fiducial-mesh/air`** (private at first, flips public per the per-module visibility-flip discipline). This is the **reference implementation of the §1.1 storage seam** — the markdown-in-a-repo destination that the AIR contract specifies as the air-gapped default for any mesh deployment. Customer deployments may seam the same AIR record contract into JSM / ServiceNow / GitHub Issues per §1.1; the lab uses its own reference implementation.

The dedicated repository was chosen over keeping AIRs in `fiducial-mesh/spec/planning/` for three reasons:

1. **AIRs are structurally cross-repo.** An incident's failure surface frequently spans multiple repos (AIR-002 spans mesh-spec, core, IONIS, workspace-tier, inbox infra). Forcing the record into any single project repo orphans it on repo migrations + creates a misleading "ownership" attachment.
2. **Storage seam separation.** Per §1.1, the AIR *contract* is the mesh's; the *storage* is a seam. Keeping the lab's reference storage in a dedicated repository makes that boundary structurally visible — `fiducial-mesh/spec/` holds the AIR *contract* (this file + future AIR-SPEC.md when it lands); `fiducial-mesh/air/` holds the *instances* + tracking. Two repositories with two different concerns is honest.
3. **Native CLCA tracking.** GitHub Issues in a dedicated repo become the natural CLCA tracker (§7.1.2). Living in `spec/planning/` would mean either issues mint against the spec repo (polluting its issue queue with CLCA-tracking issues) or no native issue-tracker at all (which is the AIR-001 root cause).

**Repository layout** (the reference shape — Bob's lane to create + maintain):

```
fiducial-mesh/air/
├── README.md                         # workflow, statuses, conventions
├── LICENSE                           # GPLv3 when public; private until visibility flip
├── reports/
│   ├── AIR-001-closed-not-landed.md  # migrated from fiducial-mesh/spec/planning/
│   ├── AIR-002-day-of-stale-state.md # migrated from fiducial-mesh/spec/planning/
│   └── ...
├── templates/
│   └── AIR-TEMPLATE.md               # extracted common structure from AIR-001/002
└── .github/
    ├── ISSUE_TEMPLATE/
    │   └── clca-action.yml           # form-style CLCA tracker
    └── labels.yml                    # bulk-mint label set (see §7.1.3)
```

`AIR-SPEC-DESIGN-NOTES.md` (this file) and the future `AIR-SPEC.md` stay in `fiducial-mesh/spec/planning/` — the contract is spec-class; the instances + tracking are not.

### 7.1.2 CLCA tracking via Issues — tracked to conclusion

Every CLCA action from an AIR's § 5 disposition table becomes an Issue in `fiducial-mesh/air`. The Issue is the unit of CLCA tracking; the AIR's `disposition` field closes only when every linked CLCA Issue closes.

**Issue conventions:**

- **Title**: `[AIR-NNN F-N] <short action description>` — both the AIR and the failure-within-AIR are encoded in the title for easy filtering
- **Body** (form-driven via `clca-action.yml`): AIR ID • Failure ID (F-N) • Sub-type (per the operating-environment meta-class taxonomy in AIR-002 §1) • Lane (fleet-ops / AKB / PCS / MCC / IAM / spec) • Pillar tag (when applicable) • Action description • Verification criteria (how do we know it landed) • Evidence (filled in as the work lands)
- **Labels**: one `air-NNN` label per AIR (for filtering by-incident), plus `clca`, `subtype:<value>`, `lane:<value>`, `pillar:<value>`, `status:queued|in-progress|done|reverted` (see §7.1.3 for the full set)

**Cross-repo closure** is the load-bearing mechanic. CLCA work happens in *other* repositories (a PR in `fiducial-mesh/core` lands a code change, a PR in `fiducial-mesh/spec` adds a CD, a PR in `ki7mt/fleet-ops` deploys a control). The fix-PR closes the AIR Issue via the standard GitHub cross-repo close-via-keyword pattern:

```
Closes fiducial-mesh/air#42
```

In the PR body. The Issue closes when the fix-PR merges. The AIR's § 5 row's Evidence column references the closed Issue and the merging PR by URL. Disposition closure is automated from the Issue-closure state: when every `air-NNN`-labeled Issue is closed, the AIR's `disposition` flips `open → resolved` (mechanism TBD — could be a workflow on the AIR repo that updates the AIR file's frontmatter, or a CI check that verifies the disposition field is consistent with the Issue closure state).

**Per-AIR Issue minting timing**: Issues are minted from the AIR's § 5 table **after** the AIR merges to `fiducial-mesh/air`, not before. This avoids orphaned Issues when an AIR draft is amended during review. Minting is mechanical — one Issue per row in § 5 that isn't `Done (repo-tracked)` at AIR-merge time. (Rows already `Done (repo-tracked)` close immediately at mint time; rows `Done (workspace-root file)` or `Done (user-local memory)` open with a state reflecting their non-repo-resolvable evidence and a tracking comment explaining the lab-repo SOT move dependency.)

### 7.1.3 Label set (initial — refine with operating data)

The `labels.yml` set on the AIR repo:

| Label class | Values | Purpose |
|---|---|---|
| **AIR ID** | `air-001`, `air-002`, `air-NNN` (one per AIR) | Filter Issues by which AIR they trace to |
| **Type** | `clca` | Identifies an Issue as a CLCA action (vs. a meta-discussion Issue) |
| **Sub-type** | `subtype:stale-state`, `subtype:missing-control`, `subtype:conformance-defect`, `subtype:coverage-gap`, `subtype:identity-architecture`, `subtype:false-completion`, `subtype:narrative-vs-substrate`, `subtype:substrate`, `subtype:security` (per §3 incident-class taxonomy + AIR-002 §1 sub-types; `subtype:security` per §1.4 need-to-know audience) | Filter by failure mode; supports recurrence-metrics queries (§6) |
| **Lane** | `lane:fleet-ops`, `lane:akb`, `lane:pcs`, `lane:mcc`, `lane:iam`, `lane:spec`, `lane:act`, `lane:crb`, `lane:dpg`, `lane:pge`, `lane:shared` (cross-cutting CLCA actions where multiple lanes share ownership — e.g., AIR-002 F-3+F-7 converge on a fleet-ops/IAM joint fix) | Who owns the corrective work |
| **Pillar** | `pillar:akb`, `pillar:ibx`, `pillar:iam`, `pillar:pcs`, `pillar:act`, `pillar:mcc`, `pillar:crb`, `pillar:dpg`, `pillar:pge` | Optional — when the CLCA is pillar-scoped (vs. cross-cutting) |
| **Status** | `status:queued`, `status:in-progress`, `status:done`, `status:reverted` | Beyond GitHub's open/closed — `reverted` captures CLCA actions that landed and were later rolled back (recurrence signal) |
| **Severity** | `sev:1`, `sev:2`, `sev:3` (extend if AIR adopts SEV4/SEV5 per §5) | Carries the AIR's severity onto its CLCA Issues for prioritization |

### 7.1.4 Migration of existing AIRs

AIR-001 and AIR-002 currently live in `fiducial-mesh/spec/planning/`. They migrate to `fiducial-mesh/air/reports/` as part of repo creation:

1. `fiducial-mesh/air` repo created (Bob's lane)
2. Migration PR in `fiducial-mesh/air`: add AIR-001 + AIR-002 under `reports/`
3. Migration PR in `fiducial-mesh/spec`: replace the two files in `planning/` with stub-redirects pointing at the new location (or delete with a clear commit message — Judge picks)
4. Cross-references updated: this file's frontmatter `references:` block; any other reference to `planning/AIR-NNN-*.md` in the spec corpus
5. CLCA Issues minted from AIR-002 § 5 in `fiducial-mesh/air`

The lab-repo SOT move for *briefs* (Judge-deferred) is a separate concern from the AIR repo creation — different artifact class, different storage seam.

### 7.1.5 What this resolves and what remains open

**Resolved by this section**: where AIRs live (the §7 open question), how CLCA actions are tracked (Issues with cross-repo close-via), how AIR disposition closes (when every linked Issue closes), the initial label taxonomy.

**Still open at AIR-SPEC time** (these were §7 open questions and stay open until the AIR spec proper drafts):
- Exact `incident_class` set + near-miss handling
- SEV scale depth
- Whether to adopt Impact × Urgency priority matrix now or as a growth path
- Whether AIR-SPEC enforces the AIR-002 §1 sub-type taxonomy as a required frontmatter field
- The AIR `disposition` field's automated close mechanism (workflow vs CI check vs manual)
- SEC pillar gap (§1.4) — Judge-gated CD1 question
- Substrate degradation contract (§1.3) — feeds back into MI-8 independent of AIR

## 8. Worked example

`fiducial-mesh/air/reports/AIR-001-closed-not-landed.md` (post-migration; originally at `fiducial-mesh/spec/planning/AIR-001-closed-not-landed.md`) is a faithful instance of the §2 structure (incident_class: workflow, severity: high) — the spec can reference it as the canonical example of the capture → 5-whys → CLCA → tracked-closure shape.

`fiducial-mesh/air/reports/AIR-002-day-of-stale-state.md` (post-migration; originally at `fiducial-mesh/spec/planning/AIR-002-day-of-stale-state.md`) is the cascade variant — a single operating day producing ten distinct failures across multiple sub-types, with explicit per-failure CLCA actions, cross-class corpus references, and paper-consolidation sections. AIR-002 is also the worked example for the §7.1 operational decisions (its § 5 CLCA table will mint the first batch of Issues against `fiducial-mesh/air` post-migration).
