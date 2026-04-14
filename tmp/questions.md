# Pressure-Test Open Questions

Questions surfaced during the 2026-04-13 pressure-test session. Each is a case where `reference.md` was silent or ambiguous AND the gap could not be resolved from reference content alone. Items are indexed for discussion.

## Q1 — Per-iteration REQ reporting inside a loop (RESOLVED 2026-04-13)

**Resolution:** `print_error` in `share/printer.func` now returns 1 instead of exit 1. Reference §Checks gained:
1. A third REQ in the example block showing the compact loop pattern (`cmd || print_error "…" || true`).
2. Updated `print_error` rule reflecting the new semantics (return 1; errexit propagates under set -e; `|| true` is the local escape hatch).
3. New rule: "Per-iteration reporting inside a loop" with two forms — **Compact** (Shape B, loop body: `cmd || print_error "…" || true`) for simple report-and-continue, and **Structured** (Shape A, loop body: `if/then/else` with room to grow) for failure branches that need multiple statements.

Verified live: set -e halts after print_error in plain context; `|| true` neutralizes per-iteration.

---

### Original write-up

**Surfaced in:** test-a (cert-expiry checker), `script.sh:139-160`

**Situation:** A REQ needs to report per-iteration pass/fail while iterating an input list (N hosts, N files, etc.). The reference's §Checks Shape A pattern calls `print_error "reason"` on failure — but `print_error` exits the script with status 1, terminating after the first failed iteration. The CA cannot report failures for subsequent iterations because the script is dead.

**What the Haiku CA did:** invented a fallback — on failure, `printf '    test failed: <reason>\n'` without calling `print_error`, accumulate a failure counter, exit 1 at the end if any failed. Marked the deviation with a `# NOTE:` comment (explicitly flagging that the reference shape didn't fit the loop context).

**Why this matters:** looped per-item reporting is a first-class sysadmin pattern (health checks, host probes, file audits, batch remediation). The reference teaches single-REQ Shape A and Shape B but is silent on the multi-item case.

**Candidate fixes:**
- **(a)** Add a new Shape C in §Checks for "looped REQ": `print_req` once for the loop, each iteration writes a per-item sub-line (`printf '  %s %s\n' "$status" "$item"`), aggregate count at end, exit through `print_error` only if the final aggregate is a failure.
- **(b)** Add a rule to §Checks: "inside a loop, suppress `print_error`'s exit behavior by deferring aggregation; use a dedicated per-item indicator and a final summary check." Name the pattern; give an example.
- **(c)** Introduce a `print_fail` helper (no exit) distinct from `print_error` (exits). Update `printer.func` and §Starter Kit.

**Recommendation pending.** Option (c) is architecturally cleanest but touches printer.func. Option (a) is a pure reference addition.

---

## Q2 — Printer path: reference vs. actual file location (RESOLVED 2026-04-13)

**Resolution:** Printer-file placement is an implementation detail, therefore CA territory. `docs/skill-contract.md` names it as C2 (target path), C3 (source line), and S1 (the CA's copy operation). reference.md needs no changes — it states what a compliant script sources; the CA handles getting the file there. Clean dividing line held.

---

### Original write-up

**Surfaced in:** test-c (`script.sh:12-20`), test-d (`script.sh:40`)

**Situation:** §Starter Kit says: *"The starter kit is one file at a fixed target path: `scripts/lib/printer.func`"* and scripts source it via `source scripts/lib/printer.func`. But the actual file in the basher dev repo is at `share/printer.func`. The CA noticed the mismatch and responded in two different wrong ways:

- **test-c:** wrapped the source in an `if [[ -f scripts/lib/printer.func ]]` guard with inline fallback definitions of `print_goal`, `print_req`, `print_pass`, `print_error`. This is a §Starter Kit rule violation ("Do not invent print helpers").
- **test-d:** `source share/printer.func` — the dev-repo path, not the consumer path.

**Why this matters:** the reference is written for a CA producing scripts *into a consumer's repo* where they'd place `scripts/lib/printer.func`. In the dev repo itself, the source path doesn't yet resolve. The CA doesn't know which side it's on. The reference silently assumes consumer-side.

**Candidate fixes:**
- **(a)** Explicit rule in §Starter Kit: *"When producing a script, always emit `source scripts/lib/printer.func`. Staging the file into that path is a setup step outside the script's concern."* One sentence makes the CA stop second-guessing.
- **(b)** Ship `scripts/lib/printer.func` in the basher dev repo itself as the canonical path (symlink or move `share/printer.func` → `scripts/lib/printer.func`). The reference and reality then agree.
- **(c)** Both (a) and (b).

**Recommendation pending.**

---

## Q3 — Comment discipline: no general rule (RESOLVED 2026-04-13)

**Resolution:** §Comments section added to reference.md (between §Indentation and §Quoting). Principle: comments express intent as lightweight pseudocode that the code implements — "WHAT is preserved; HOW is free to evolve." Positive rule (write comments generously where they orient the reader) paired with prohibitions (don't restate code, don't narrate decisions, don't restate the reference). skill-contract.md S2 updated to cite the new section and mirror the principle in the CA prompt.

Closes Q7 jointly — the comment-flood pathology is addressed by (a) reference.md §Comments giving the CA a positive principle to follow, and (b) skill-contract.md S2 prompting the CA away from decision-log narration.

---

### Original write-up

**Surfaced in:** test-d (`script.sh:12-300`+ — ~250 lines of NOTE-comment decision narration before any real code)

**Situation:** The CA interpreted "mark each judgment call with a `# NOTE:` comment" as a license to narrate every decision as a comment block in the script. reference.md has no general rule against this. §Functions says *"Compact — one line when possible, more only when needed"* but scoped to function purpose comments.

**Why this matters:** a sysadmin-quality script reads as code plus short intention comments. Decision-log narrative belongs in commit messages or PR descriptions, not inline. A 600-line script that is 40% meta-commentary is the opposite of readable.

**What the Haiku CA produced:** examples of the NOTE comment flood:
```
# NOTE: §Section Frame: full 77-dash rules for top-level blocks.
# Applied consistently.
# NOTE: Indentation: 4 spaces per §Indentation rule. Applied throughout.
# NOTE: §Quoting applied throughout: "${var}", "$@"…
```
These are restatements of reference rules, not explanations of code.

**Candidate fixes:**
- **(a)** Add a §Comments section (or a rule inside §Indentation or near it): *"Comments explain what a reader cannot infer from the code. Do not narrate the rules the code already follows. Do not write decision logs in the script — those belong in the commit message."*
- **(b)** Tighten my prompting to CAs: "mark each judgment call with a `# NOTE:` comment" was license to over-narrate. This is prompt-level, not reference-level. May be both fixes needed.

**Recommendation pending.** Probably both — a reference rule plus clearer CA prompting conventions.

---

## Q4 — Argument parsing fails when flags follow positionals (RESOLVED 2026-04-13 — mark for retest)

**Resolution:** Three rules added to §Argument Parsing — Terms (flag vs positional vocabulary), Flags-precede-positionals (matches wooledge BashFAQ/035's explicit recommendation), and Validate flag-value presence (adopts wooledge's guard pattern, adapted to basher style with `print_error`). Example block updated to show the guarded flag-value form. BashFAQ/035's `"options appear before non-option arguments"` cited as the authoritative source.

**Mark for retest.** The next pressure-test cycle should verify that a CA following these rules produces a script where:
- Flags-after-positionals would be caught either by the operator following EXECUTE, or surfaced loudly rather than silently ignored.
- A flag with missing value fails loudly with a named error before the script reaches the affected command.

---

### Original write-up

**Surfaced in:** test-c (run 1 with `script.sh target spec -a ANCHOR` exited with `sed: no previous regular expression`), test-d (same — `--pattern` after positionals ignored)

**Situation:** The reference's §Argument Parsing happy path — `while :; do / case "$1" in … *) break` — exits the parse loop on the first non-option argument. Consequence: flags that appear *after* positional arguments are never seen. `script.sh TARGET SPEC -a ANCHOR` silently sets anchor="".

The CAs accept this as compliant behavior — they produced the standard loop. Users who naturally write `script.sh input.txt --flag` (GNU-convention intermixed) hit a silent failure: flags are unset, `: "${anchor?…}"` may or may not catch it depending on how the default is initialized, and a downstream command (sed, in test-c's case) fails obscurely.

**Candidate fixes:**
- **(a)** Add a rule to §Argument Parsing: *"Flags must precede positionals. If a flag appears after a positional, parse_args silently ignores it — the happy-path loop breaks on the first non-option token. Document this in the header's EXECUTE line."* Explicit is clearer than silent.
- **(b)** Change the reference pattern to loop over all args (accumulate positionals into an array as it goes, never break early). Matches GNU convention but is more complex.
- **(c)** Add a validation call after `parse_args` that asserts no leftover tokens look like flags — `[[ "$1" == -* ]] && { usage >&2; exit 2; }`.

**Recommendation pending.** (a) is cheapest and most consistent with the reference's "one happy path, documented" ethos.



---

## Q5 — `(( var++ ))` is a silent killer under `set -e` (RESOLVED 2026-04-13)

**Resolution:** Rule added to §Error Mode naming `count=$((count + 1))` as the canonical form; alternatives (`: $((count++))`, `(( count++ )) || true`) referenced via Further-research. Top-of-file note now tags research links as *practice* (wooledge) or *reference* (GNU Bash Manual). Validated by test-b remediation (`script-remediated.sh` in `/tmp/pressure/test-b-log-archival/` — exit 0, correct counts).

---

### Original write-up

**Surfaced in:** test-b — script crashed after compressing the first file (`((count_compressed++))` at `script.sh:109`)

**Situation:** `(( var++ ))` returns the *old* value of `var` as the exit status of the arithmetic command. When `var=0`, the expression returns exit status 1, and `set -e` aborts the script. Common idiom; silent killer.

The CA produced the textbook counter-increment form. There's nothing wrong with `(( ))` per se. But the reference says "use `set -euo pipefail`" without warning about this interaction.

Safe forms the reference already shows:
- `count=$((count + 1))` — assignment form, always exit-0
- `: $((count++))` — the `:` consumes the arithmetic exit code
- `(( count++ )) || true` — explicit neutralizer

**Candidate fixes:**
- **(a)** Add a rule to §Error Mode: *"`(( var++ ))` and `(( var-- ))` return the *old* value as exit status; under `set -e`, the post-increment from 0 aborts the script. Use the assignment form `count=$((count + 1))` for counters, or prepend `: ` to consume the exit code."*
- **(b)** Update §Parameter Expansion example to show a counter increment explicitly, using `$((x + 1))` form.

**Recommendation pending.** This is a real-world footgun that shipped to production in test-b and crashed the run.

---

## Q6 — Cleanup traps can swallow failure exit codes (RESOLVED 2026-04-13 — revisit after basher matures)

**Resolution:** Rule added to §Temp Files: EXIT trap bodies must not include `exit`; signal-specific normalization (e.g., SIGINT → 0) uses a dedicated `trap 'handler' INT` instead. Q1's `return 1` change narrowed the surface area but did not eliminate it — set -e aborts, `-u`/pipefail failures, and explicit exits can all still be masked.

**Marked for later review.** Revisit once basher has matured in real use: does the rule hold, is the signal-specific-trap carve-out used enough to warrant its own §Examples entry, does any pattern surface that the rule didn't anticipate?

---

### Original write-up

**Surfaced in:** test-d (`script.sh:1068` — `cleanup() { … exit 0; }` inside the EXIT trap)

**Situation:** The CA wrote a cleanup function called from `trap 'cleanup' EXIT`. The function ends with `exit 0` (the CA's stated intent: "ensure clean shutdown regardless of signal"). Side effect: when the script exits via `print_error` (which exits 1), the trap runs cleanup, which ends with `exit 0` — overriding the failure and reporting success to the operator.

test-d's actual run shows `print_error "invalid regex pattern: ERROR"` firing, then the script exiting with status 0. A failed script that looks successful is the worst possible outcome of a sysadmin tool.

Reference's §Temp Files says: *"Pair every `mktemp` with `trap 'rm -rf "$path"' EXIT`. Set the trap immediately after the mktemp line, before any work."* — nothing about the trap body's exit semantics.

**Candidate fixes:**
- **(a)** Add to §Temp Files: *"An EXIT trap body must not include an explicit `exit`. The trap runs as part of the script's exit sequence; adding `exit 0` inside it overrides every failure path. Do cleanup, then return."*
- **(b)** Add to §Exit: *"`trap` handlers on EXIT inherit the script's exit status. Do not `exit` from a trap body unless you are intentionally masking a failure (which is almost always a mistake)."*

**Recommendation pending.** Both angles worth capturing.

---

## Q7 — Script bloat: CA narrates every decision as a comment (RESOLVED 2026-04-13, jointly with Q3)

**Resolution:** See Q3. Addressed by the new reference.md §Comments section (positive principle: comments as pseudocode/contract serving the next reader) and skill-contract.md S2 (CA prompt convention: write story-serving comments, list decisions in final message not in script).

---

### Original write-up

**Surfaced in:** test-d (1536-line script, ~90% NOTE-comment narrative; actual code is ~100 lines)

**Situation:** My prompt to each Haiku CA said: *"mark each judgment call with a `# NOTE:` comment one line above the decision."* The test-a, test-b, test-c CAs produced 1-3 NOTE comments each — judicious. The test-d CA produced a decision log: ~250 lines of `# NOTE: …` narration before the first code line, plus multiple abandoned attempts left in the file.

This reveals two things:
1. **My prompt was ambiguous** — "mark each judgment call" is license to document everything.
2. **Reference has no comment-discipline rule** — §Functions says comments should be "Compact — one line when possible" but scoped to function purpose. No general rule against meta-narration, no guidance on "comment what the reader cannot infer."

**Candidate fixes:**
- **(a)** Add a §Comments section (near §Indentation / §Quoting) with one rule: *"Comments explain what the code cannot. Do not restate rules the code already follows. Do not narrate design decisions in the script — those belong in the commit message or PR description."*
- **(b)** Tighten CA prompting conventions (not a reference change): change "mark each call with a # NOTE" to "list your judgment calls in your final message only; do not embed them in the script."
- **(c)** Both.

**Recommendation pending.** Tightening CA prompting is the prompt-engineering fix; a reference rule protects against CAs that don't see my prompt.

---

_(end of pressure-test questions)_
