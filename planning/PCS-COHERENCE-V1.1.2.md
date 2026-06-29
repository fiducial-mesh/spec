# PCS §6 Coherence Increment (v1.1.2 / PCS-hardening) — deferred from v1.1.1

**Status:** deferred — NOT in the v1.1.1 publication sweep (which stays a tight
scaffolding/naming pass). These are §6 **coherence gaps** (normative content the
implementation depends on but the spec under-states), **not** publication
blockers — the spec is publishable with them, stronger without.

**Source:** Judge's two PCS additions (PCS Validator + Registry-as-sole-source)
→ Patton coherence review → Watson grep-verification (2026-06-29).

## Gap 1 — PCS Validator does not cite the security floor it enforces
**Verified:** the 10 security non-negotiables (no `subprocess`/`shell=True`, no
`eval`/`exec`, HTTPS-only, keyring-only credentials — the MCP-SECURITY-FRAMEWORK
floor) are authored at **L2093, inside PGE §5.3 as Stratum-1 policy rules**. The
PCS Validator `[FM-PCS-0008]` and the Registration gate `[FM-PCS-0009]` cite them
**0×**.

**The seam:** PCS owns the *acceptance gate* over plugins (spec-superset +
security checks); the manifest *format* is upstream's. The Validator is the
natural enforcement point for the Python security floor (you don't want a
`shell=True` plugin reaching registration). But the spec attributes that floor to
PGE and never wires "the PCS Validator enforces the §5.3 Stratum-1 security floor
at registration."

**Fix (v1.1.2):** add a normative clause to `[FM-PCS-0008]` / `[FM-PCS-0009]`
binding the Validator to enforce the §5.3 Stratum-1 security floor at the
Registration gate — so the spec states the enforcement the implementation performs.

## Gap 2 — Registry sole-source is enforced-by-construction, not stated as an invariant
**Verified:** `[FM-PCS-0013]` (registry contract — mesh-internal, BOM-pinned) +
the gate chain `[FM-PCS-0009/0010/0011]` make the registry the only signature-
verified install path *by construction*. But "sole source / no plugin … except /
side-load / no-bypass" appears **0×** — the property is never *asserted*.

**Why it matters:** "no plugin enters the Mesh except via the Registry" is a
no-bypass security boundary (the same shape as `[FM-INV-0001]`) — it's what gives
the Validator teeth and `[FM-PKG-0005]` quarantine its meaning. For a defensive-
publication artifact, the *citable* invariant beats the *implied* one: a prior-art
reader / conformance auditor shouldn't have to infer the boundary from BOM mechanics.

**Fix (v1.1.2):** add a flat no-bypass invariant (INV-level, or a `[FM-PCS-0013]`
clause): *"No plugin shall execute in the Mesh except via the Registry; loading
outside the BOM-pinned set is non-conformant."*

## Process
Separate increment through the publication/doc track (Watson → Patton → Einstein →
Judge). Author deliberately — these are normative additions, not sweeps.
