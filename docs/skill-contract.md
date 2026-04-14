# basher ↔ bash skill — Contract

## Purpose

The **`cascadian:bash` skill is the calling agent ("CA")** defined by this contract. Throughout basher's documentation — including `reference.md` — "the CA" refers to this skill by name. No other agent is authorized to consume basher as a CA.

Two systems collaborate to produce sysadmin-quality shell scripts for a consumer's repo:

- **basher** — knowledge side. Authoritative style rules, shapes, patterns, examples. This repository.
- **`cascadian:bash` skill** — implementation side (CA). Reads basher, performs the operational steps (stage artifacts, emit scripts, run shellcheck, validate), respects the consumer's local configuration.

## Two-tier CA model

The `cascadian:bash` skill operates in **two distinct roles** with different underlying models:

1. **Design / assemble / test** — **powerful model** (Sonnet/Opus class). Consumes `reference.md` in full to design, author, and test the script. Collaborates with domain experts (e.g., the mathematician). This is the role that produces the artifact.
2. **Execute** — **less powerful model** (Haiku class). Runs a *tested, confirmed-good* script. Reads status, surfaces output, helps the operator. Does not author or modify scripts. The script does the work; this CA is a thin management layer.

**`reference.md`'s audience is the design-phase CA.** The execute-phase CA does not read the reference at runtime — it invokes scripts that have already been made conformant.

**Implications for condensation:**

- The reference must be complete enough that conformance comes from the document, not from the model's capability. A powerful design-phase CA could often infer an unstated rule; a less-capable CA running the same reference could not. The bar is the latter.
- Pressure-testing with Haiku as the authoring model (as in 2026-04-13) is intentional rigor — it reveals gaps the reference should close, even though the production writer is more capable.
- Safe cuts are **exact duplicates** and **pure rhetoric**. Cuts based on "the CA already knows" are unsafe because they assume capability that varies by model.
- Every retained rule should encode a **footgun, a WHEN-test, an enumerated operator boundary, or a specific failure mode**. If the italic only restates the rule as a slogan, it can go. If it names a mechanism or consequence, it stays.

Reviews of `reference.md` are conducted with this bar explicitly in mind.

This document states the dividing line between them, the shared conventions both must agree on, and the open items each side owes the other. basher authors this document; the skill team reads and executes against it. `skills/bash/SKILL.md` is read-only from basher's side; proposals flow here, implementation happens there.

---

## Dividing line

### basher holds (knowledge)

- The style reference: `reference.md` in full
- Canonical shipped artifacts under `share/` (currently: `share/printer.func`)
- Tagged patterns in `reference.md` §Examples
- Open questions from pressure testing (`tmp/questions.md`)
- This contract

basher is the single source of truth for "what a conformant script looks like." Every rule, shape, and example lives here.

### Skill holds (implementation)

- Operational workflow — when invoked, read basher; produce script; shellcheck; validate; report.
- Safety protocol — shellcheck zero warnings before commit; `bash -n` syntax check; ring-bell before destructive operations; approval gate for irreversible actions.
- Local environment assumptions — macOS with GNU coreutils, `gdate`/`gsed`/`gfind` available; assume basher's `reference.md` is reachable at a known path in the plugin cache.
- **Staging step** — copy `share/printer.func` → `scripts/lib/printer.func` in the consumer's repo before the first emitted script runs.
- **CA prompt conventions** — rules about *how the CA behaves when producing scripts* (see "Skill-side items" below: Q3/Q7). These are about agent behavior, not script style.

### The skill does NOT hold (going forward)

Style rules, patterns, examples, gotchas, printer semantics, script structure, idempotency patterns, error-checking idioms. All of these live in basher. If the skill's `SKILL.md` currently documents any of them, it should shrink to a pointer.

---

## Shared conventions

Named and numbered so each side can assert conformance.

| id | convention | authority |
|---|---|---|
| C1 | Script location: `scripts/<name>.sh` relative to the consumer's repo root | basher §Invocation, §Starter Kit |
| C2 | Printer library staging target: `scripts/lib/printer.func` | basher §Starter Kit |
| C3 | Printer source line in emitted scripts: `source scripts/lib/printer.func` | basher §Starter Kit |
| C4 | Invocation CWD: the consumer's repo root | basher §Invocation |
| C5 | Shebang: `#!/usr/bin/env bash` | basher §Shebang |
| C6 | Error mode: `set -euo pipefail` as the first executable line of every executable script | basher §Error Mode |
| C7 | Printer semantics: `print_goal` / `print_req` / `print_pass` / `print_error` only. `print_error` propagates failure (current: via `exit 1`; pending proposal Q1: via `return 1`). | basher §Starter Kit, §Checks |
| C8 | Comment framing: `# ` + 77 dashes (79 chars) for full rule, `# ---` for short rule | basher §Section Frame |
| C9 | Casing: `snake_case` for locals, `UPPER_CASE` for exports/constants | basher §Variables |
| C10 | Indentation: 4 spaces, no tabs | basher §Indentation |

If the skill's current defaults disagree with any row above, the row wins. Skill updates to match.

---

## Redistribution plan — skill → basher

The current `SKILL.md` duplicates large portions of `reference.md`. Each item below names what moves, what shrinks, and what stays.

### Move into basher (consolidate — skill should delete its copy and reference basher instead)

| Skill section | Destination in basher | Status |
|---|---|---|
| Variable Naming | §Variables | **already in basher** — skill deletes its copy |
| Script Structure template | §Script Header, §Section Frame, §Error Mode, §Main, §Exit | **already in basher** — skill deletes |
| Printer Library (hierarchy, print_error exits) | §Starter Kit, §Checks | **already in basher** — skill deletes |
| Modern Error Checking (`if ! cmd`) | §Checks Shape B | **already in basher** — skill deletes |
| Efficient Search and Replace (`find -exec sed`) | §External Tools | **already in basher** — skill deletes |
| Idempotency Pattern | §Examples `#idempotent` | **already in basher** — skill deletes |
| Gotcha: `((var++))` under `set -e` | §Error Mode (pending — Q5) | **pending** — add to basher, then skill deletes |
| Gotcha: graceful handling of missing resources | §Examples (new `#graceful-skip` entry) | **pending** — add to basher, then skill deletes |
| Gotcha: summary output for operators | §Report or §Checks informational-REQ | **pending** — add to basher, then skill deletes |
| Gotcha: print_pass must be inside conditionals | §Checks Shape A | **already implicit in basher** — skill deletes |
| Gotcha: don't compute SCRIPT_DIR | §Invocation | **already in basher** — skill deletes |
| Wooledge reference | basher already cites throughout | skill deletes |
| Output Patterns: Validation / Generation / Creation | §Examples (three new tagged entries) | **pending** — add to basher, then skill deletes |
| `# shellcheck source=...` directive before source | §Starter Kit or §Functions | **gap in basher** — add to basher |

### Stay in skill (keep, slim down)

- Workflow: "When invoked, read basher's `reference.md`; produce script; run shellcheck; test." Six lines max.
- Safety & Validation: shellcheck zero-warnings, `bash -n`, ring-bell, destructive-op gate. Operational.
- Failure Protocol: what the CA does on syntax errors / logical errors / unclear requirements / destructive operations.
- Local environment assumptions: macOS + GNU coreutils installed.
- Pointer to basher: "For every style question, consult `reference.md`. Do not improvise."

Target: skill shrinks from ~420 lines to ~60–80.

---

## Three conflicts to resolve

### Conflict 1 — path convention: `bin/` vs `scripts/`

- Skill says: template at `bin/lib/template.sh`; source `bin/lib/printer.func`; scripts land in `bin/`.
- basher says: `scripts/<name>.sh`; `scripts/lib/printer.func`; repo-root invocation.

**Resolution (proposed):** basher's `scripts/` convention wins. Rationale:
- `scripts/` is widely used in the ecosystem (github.com, makefiles, CI tooling).
- `bin/` conventionally holds compiled binaries; using it for shell scripts creates ambiguity.
- basher's §Invocation rule depends on this path.
- Skill updates: `bin/` → `scripts/` throughout.

### Conflict 2 — `print_info`

- Skill documents `print_info` prominently as the 3rd-tier informational helper; example templates use it.
- basher's `development-record.md` (2026-04-12) explicitly removed `print_info` from §Starter Kit and §Functions examples: "deferred; not present in printer.func."

**Resolution (proposed):** settle one way. Two options:
- **(a)** Restore `print_info` to `printer.func` and document it in basher §Starter Kit. Matches skill's expectations; requires a printer.func change.
- **(b)** Remove all `print_info` references from skill; it doesn't exist. Matches basher's current state; skill updates.

**Recommendation:** (a) — `print_info` is genuinely useful for informational (not-pass-or-fail) messages and the skill's documentation shows it's a natural fit for "skipping" or "detected" messages. Add it.

### Conflict 3 — `bin/lib/template.sh` (or `scripts/lib/template.sh`)

- Skill says: "Always start from template `bin/lib/template.sh`."
- basher: removed the template.sh promise from §Starter Kit on 2026-04-12. The template is "constructed per project from the reference."

**Resolution (proposed):** basher's position stands. The skill doesn't start from a fixed template file — it constructs each script by following `reference.md`. The skill updates to reflect this:
- Remove all references to `bin/lib/template.sh` (which doesn't exist).
- Replace with: "Construct each script by following basher's `reference.md` section-by-section: Shebang → Script Header → Error Mode → Variables → (helpers in Functions) → Main → Checks → Report → Exit."

---

## Skill-side open items (from pressure test 2026-04-13)

These are behaviors of the CA (not script style), so they live on the skill side.

### S1 — Printer staging (Q2)

On first invocation in a consumer's repo, the skill must stage `share/printer.func` → `scripts/lib/printer.func` before any emitted script runs. This is the `cp` step. Without it, emitted scripts can't source the printer.

**Proposed behavior:** the skill checks for `scripts/lib/printer.func` at the start of every run; if absent, stages it from basher's `share/printer.func`. Idempotent — subsequent runs are no-ops.

### S2 — CA prompt conventions: comments serve the reader, not the author (Q3/Q7)

During the pressure test, a Haiku CA produced a 1536-line script that was ~90% `# NOTE:` decision-log narration. Root cause: the author's prompt said "mark each judgment call with a `# NOTE:` comment" — license to embed a decision log in the script.

**Proposed behavior:** the skill's prompt to the underlying model should say: *"Write comments that serve the next reader following the script's story (see §Comments in reference.md). Comments express intent as lightweight pseudocode that the code below implements — so a future maintainer can evaluate and refactor the implementation against the contract. Do not embed decision logs in the script; list judgment calls in your final message instead."*

This pairs with basher's §Comments rule. Reference teaches the positive principle (comments as contract / pseudocode that decouples intent from implementation); skill enforces the CA-specific negative case (no decision-log narration in the emitted file).

### S3 — CA prompt conventions: printer path is canonical (Q2, continued)

The Haiku CAs got confused about whether `scripts/lib/printer.func` was a consumer-side path or a basher-dev path. They invented inline fallbacks or sourced from `share/`.

**Proposed behavior:** the skill's prompt should include: *"Emit `source scripts/lib/printer.func` unconditionally. The file WILL be staged there before your script runs. Do not fall back, do not invent helpers, do not source from any other path."*

---

## Roadmap

1. **This document (`docs/skill-contract.md`)** — written; awaiting PM review.
2. **basher `reference.md` updates** — Q5 (counter-increment), Q6 (trap exit), Q7 (comments) added; Output Patterns and Gotchas consolidated from skill into §Examples.
3. **Skill updates** — slim down `SKILL.md` to ~60–80 lines; delete duplicated style content; replace path conventions (`bin/` → `scripts/`); add S1/S2/S3 operational rules.
4. **Second pressure-test cycle** — same four tests after updates; measure whether Q1–Q7 are resolved.
5. **Open question: `print_info`** — restore or retire. Requires a decision.
6. **Future (deferred): OpenSpec** — if more skills consume basher, consider formalizing the contract as an OpenSpec specification. For now, this document is the contract.
