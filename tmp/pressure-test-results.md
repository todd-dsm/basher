# Pressure-Test Results — 2026-04-13

Reference under test: `/Users/work/code/basher/reference.md` at tag `v0.1.0-advanced`.
Method: each Haiku-model CA produced its script blind from the reference alone. Original preserved. Remediation (where reference.md content alone fixes the bug) placed alongside. Unresolvable ambiguities logged to `tmp/questions.md`.

## Headline

| id | name | runtime | gaps | ambig. | footguns | reference-fixable? |
|---|---|---|---|---|---|---|
| a | cert-expiry | **pass** | 1 | 1 | 0 | Q1 needs new rule |
| b | log-archival | **fail** → **pass remediated** | 1 | 2 | 1 | Q5 fix applied (`$((x+1))`) |
| c | config-drift | **pass** (flag-order caveat) | 1 | 1 | 1 | Q2, Q4 need rules |
| d | log-tail agg. | **fail, silent** | 3 | 1 | 3 | Q2, Q6, Q7 need rules |

**Ran four; two pass cleanly, one passes after remediation, one is fundamentally broken by three distinct reference gaps interacting.**

## Seven open questions (full detail in `tmp/questions.md`)

| id | one-liner | severity |
|---|---|---|
| Q1 | §Checks Shape A exits on first loop failure — no shape for per-iteration reporting | high |
| Q2 | Printer path mismatch: reference says `scripts/lib/printer.func`, basher repo has `share/printer.func` | high |
| Q3 | No §Comments section; CA over-narrates decisions as comments | medium |
| Q4 | Arg-parsing happy path silently ignores flags after positionals | high |
| Q5 | `(( var++ ))` under `set -e` aborts when counter starts at 0 | high (shipped bug) |
| Q6 | `trap … EXIT` bodies with explicit `exit 0` swallow failure codes | high (silent failure) |
| Q7 | Decomposition + comment discipline — no "comment what the code cannot" rule | medium |

## Proposed reference.md changes (for PM review)

### Highest-leverage (fix real shipped bugs)
1. **Q5 — counter footgun.** Add one rule to §Error Mode or §Parameter Expansion: *"For counters under `set -e`, use `count=$((count + 1))` — the assignment form. `(( var++ ))` returns the pre-increment value as exit status; a post-increment from 0 aborts under `-e`."* Validated by test-b remediation.
2. **Q6 — trap exit discipline.** Add to §Temp Files (or §Exit): *"An `EXIT` trap body must not include an explicit `exit`. The trap runs as part of the script's exit sequence; `exit` inside it overrides the real exit status and silently masks failures."* Validated by test-d failure mode.
3. **Q2 — printer path.** Add to §Starter Kit: *"A conforming script emits `source scripts/lib/printer.func` unconditionally. Staging `printer.func` to that path is a setup step outside the script's concern."* Also: consider shipping `scripts/lib/printer.func` in the dev repo itself so the path resolves everywhere.

### Structural (new rules / sections)
4. **Q1 — loop-REQ shape.** Add a **Shape C** to §Checks for per-iteration reporting inside a loop. Proposed:
   - Before the loop: `print_req "Iterate <things>"` (announce the loop, not each item).
   - Per iteration on success: short line, no `print_pass`.
   - Per iteration on failure: short line, do NOT call `print_error` (which exits).
   - After the loop: `print_req "Final status"` + if any failures, `print_error "<N> failed"` (real exit).
5. **Q7 — comment discipline.** Add a §Comments section or a rule near §Indentation: *"Comments explain what the code cannot. Do not restate rules the code follows. Do not narrate design decisions — those belong in the commit message."*
6. **Q4 — flag ordering.** Add to §Argument Parsing: *"Flags precede positionals. The `while :; do / case` loop breaks on the first non-option, so flags after positionals are silently ignored. Document this in the header's EXECUTE line."*

### Enhancements (clarify existing rules)
7. Add flag-with-value example to §Argument Parsing (shown in all three test CAs that invented `shift` inside a branch — minor drift).
8. Annotate §Section Frame with literal character counts — all four CAs produced frames at 74–77 chars instead of 79.
9. Add an "informational REQ" shape to §Checks for REQs that report an observation rather than test a condition (test-b's `REQ3 Count kept files`).

## §Examples additions surfaced

- **`#looped-check`** — per-iteration reporting pattern (the Q1 fix), once Shape C is defined.
- **`#counter-safe`** — canonical counter-increment under `set -e` (the Q5 fix).

## Notable wins (what the reference got right)

- **§Examples tagging worked.** test-c's CA located the `#config-drift` entry by tag and followed its shape — validates the §Examples cross-reference system.
- **§Loops + §External Tools macOS caveat together.** test-b's CA correctly chose `while read … done < <(find ...)` instead of `find -exec +` — the Darwin early-exit caveat in §External Tools combined with §Loops's process-substitution rule produced the right call without prompting.
- **§Main two-shape rule.** All four CAs picked the "with parse_args" shape correctly.
- **§Starter Kit printer contract.** Three of four sourced `scripts/lib/printer.func`. The one that didn't (test-d) failed loudly enough to surface Q2.

## Proposed next steps

1. **PM review of Q1–Q7** (tomorrow morning). Each needs a decision: reference rule, §Examples entry, prompt convention, or multiple.
2. **Apply Q5, Q6, Q2 first** — these caused real bugs in this session. Q5 is a two-sentence addition; Q6 is one rule; Q2 is a clarification + one shipped-file decision.
3. **Design Shape C for Q1** — non-trivial; draft once PM weighs in.
4. **Decide on §Comments (Q7)** — include, or treat as CA-prompting convention only.
5. **Second pressure-test cycle** once the high-severity items land. Same four tests plus `--exec +` or similar tweak on test-b to surface new edges.

## Artifacts

- `/tmp/pressure/` — full test tree (specs, fixtures, original scripts, score.md per test, test-b remediated)
- `/Users/work/code/basher/tmp/questions.md` — Q1-Q7 with candidate fixes
- This file.
