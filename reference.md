# Bash Reference

A single-file reference of GNU Bash constructs for AI coding assistants.

<!-- Consumption: fetch this file raw from GitHub. One file, one source of truth. -->
<!-- Structure: each section is a self-contained construct with "do this, not that" pairs. -->

The code blocks in this file are the answer. Use them directly.

For edge cases or deeper understanding, each section links to [Wooledge](https://mywiki.wooledge.org/): the authoritative reference for all shell operations.

---

## Starter Kit

<!-- basher ships two paired artifacts at canonical paths. Every compliant script presumes both. -->

Rules:
- The starter kit is two files at fixed paths under `scripts/`:
	- `scripts/template.sh` — the complete, annotated script anatomy.
	- `scripts/lib/printer.func` — shared output helpers: `print_goal`, `print_req`, `print_pass`, `print_error`.
	- *Two files, one unit. The template sources the printer; the printer's helpers drive every script's visible output.*
- Every compliant script sources the printer: `source scripts/lib/printer.func`.
	- *The Main-program conventions (announcing goals, reporting pass/fail) presuppose these helpers. A script that doesn't source them exits the scope of this reference.*

---

## Invocation

<!-- A shared anchor for paths makes scripts simpler. If every script assumes a different working directory, relative paths become guesswork and scripts grow defensive prologues to compensate. One convention replaces all that ceremony. -->

Rules:
- Scripts are invoked from the repo root. The operator types `scripts/name.sh` and stays there — no `cd scripts && ./name.sh`, no absolute path gymnastics.
	- *One CWD for every script in the project. The operator stays put; scripts come to the operator. This is the convention that every other rule here depends on.*
- All relative paths inside a script — `source` targets, data file references, log output paths — are paths from the repo root.
	- *Bash resolves relative paths against the invoking shell's CWD, not the script's file location. With a single anchor (the repo root), `source scripts/lib/printer.func` reads the same from every script and every invocation.*
- Do not use `$(dirname "$0")`, `$BASH_SOURCE`-based CWD computation, or `cd` prologues to find or change the script's working directory.
	- *Each is a workaround for a convention that isn't being held. With the convention in place, they add ceremony and nothing else — and each has its own edge cases (symlinks, sourced scripts, `$0` lies) that the convention avoids entirely.*

Further research:
1. [BashFAQ/028: Script location](https://mywiki.wooledge.org/BashFAQ/028): why `$0` and `$(dirname "$0")` are unreliable, and why a CWD convention is the stable answer.

---

## Line Width

<!-- Old terminals wrap anything past 80 columns. Modern ones do the same when windows are split, panes are narrow, or output is piped through `less -S`. A script that only reads cleanly at full width is a script that only reads in ideal conditions. -->

Rules:
- Every line is exactly 79 characters or shorter — never 80, never longer. Code, comments, output, section rules, and `# ---` markers all obey the same hard limit.
	- *The constraint is the worst plausible terminal, not the author's. 79 is the number because section rules are 79 and every other line lives inside that frame. One wrap-imposed line break destroys alignment, indentation, and the reader's ability to scan.*
- When a single statement or message cannot fit, break it into a multi-line construct rather than letting the terminal wrap it.
	- *An author-controlled break is deliberate. A terminal-imposed wrap is noise.*
- When multi-line output is needed (reports, summaries, banners), a multi-line `printf` is the default form. Preserve the shape of the rendered output in the source.
	- *What you write is what the reader sees. Collapsing a shaped report into a single 200-char line trades readability in the source for readability nowhere.*
- Reach for a heredoc (`cat <<EOF` / `<<'EOF'`) when the block is large static text, embeds literal `$` or backticks, or feeds another command's stdin. Not every multi-line case is a heredoc case.
	- *Heredocs are purpose-built for "here is a chunk of text, pass it through." For a short report with a few variable substitutions, `printf` is lighter and reads more directly.*
- Heredocs pair especially well with `envsubst` for generating config files, templates, and manifests from a fixed template plus environment variables.
	- *`cat <<'EOF' | envsubst` keeps the template literal in the source — no shell expansion mid-heredoc — and does a single, predictable substitution pass at the end. It's the cleanest way to render a Kubernetes manifest, Terraform vars file, or service config from a script.*

Example — a post-run report written in the shape it will render:

```bash
printf '\n\n%s\n' "

Post-run report:

* removed thing:  success
* modified thing: success
* added thing:    success

logged: /tmp/script-purpose.log

"
```

Further research:
1. [BashFAQ/032: printf](https://mywiki.wooledge.org/BashFAQ/032): formatted output, the preferred tool over `echo` for anything non-trivial.
2. [HereDocument](https://mywiki.wooledge.org/HereDocument): `cat <<EOF` as the alternative multi-line construct.

---

## Indentation

<!-- Indentation is a preference in most places. It is not a preference in any place where whitespace changes execution — there it is part of the code's behavior. -->

Rules:
- basher scripts use 4-space indentation. Always. Every committed artifact — template, examples, produced scripts — indents with four spaces. No tabs, no two-space, no eight-space, no mixing.
	- *This is the rule, not a default. Agents producing new scripts emit 4 spaces and nothing else. "Default" implies an alternative; there is none inside basher.*
- When editing a script that already lives outside basher and uses a different convention, match what's there — do not retab as a side effect.
	- *The author of an external script has the right to their own convention. Changing it silently pollutes the diff. This exception applies only to foreign scripts; basher's own artifacts are 4-space, always.*
- Within any one script, one depth and one whitespace choice, applied consistently.
	- *Mixed indentation renders unpredictably across editors and breaks alignment of comments and continuations.*
- Never reformat whitespace in a way that alters execution. Heredoc body lines, line-continuation trailing whitespace, and string literals are code, not style.
	- *`<<EOF` emits body lines verbatim; `<<-EOF` strips leading tabs (not spaces); `\` continuations require the backslash as the last character on the line.*

---

## Shebang

<!-- Without a correct shebang, the script runs under the wrong interpreter, or not at all. -->

```bash
# DO
#!/usr/bin/env bash

# DON'T
#!/bin/bash        # hardcoded path: breaks on NixOS, FreeBSD, some containers
#!/bin/sh          # POSIX sh: no arrays, no [[ ]], no process substitution
```

Rules:
- Use `#!/usr/bin/env bash`. No other form.
	- *Bash lives at different paths across systems. `env` finds it in `$PATH`.*
- Line 1, byte 0. Nothing before it.
	- *The kernel expects `#!` at the start of the file. Anything before it and the shebang is ignored.*

Further research:
1. [BashProgramming: Shebang](https://mywiki.wooledge.org/BashProgramming#Shebang): the basics.
2. [Choosing your shell](https://mywiki.wooledge.org/BashGuide/Practices#Choose_Your_Shell): deeper treatment and portability edge cases.

---

## Script Header

<!-- A script without a header arrives bare. The next reader (human or agent) has no idea what it does, what it needs, or how to run it. -->

```bash
#  PURPOSE: One-line description of what this script does.
# -----------------------------------------------------------------------------
#  PREREQS: a) required tool or permission
#           b) required environment variable
#           c) required input format
# -----------------------------------------------------------------------------
#  EXECUTE: scripts/name-of-script.sh [args]
# -----------------------------------------------------------------------------
```

Rules:
- Header follows the shebang, before any code.
	- *The header is read first. Placing it anywhere else hides the context the next reader needs.*
- If (and only if) ShellCheck flags a rule you must suppress, add the directive directly below the shebang: one rule per line, each with an inline reason.

  ```bash
   # shellcheck disable=SC2317     # trap handler; looks unreachable to linter
  ```

  Do not invent rule numbers. Do not add disables pre-emptively. No disables = no line.
	- *A real `disable=none` is a parse error (SC1073). The only clean state is an empty slot. Running ShellCheck on the finished script is the trigger for adding a directive.*
- `PURPOSE` is one line. Name the action, not the implementation.
	- *Readers scan PURPOSE to decide if this is the script they want. Long prose defeats scanning.*
- `PREREQS` lists every external dependency: tools, environment variables, permissions, input formats. If none apply yet, write `none` — do not remove the block.
	- *A script that silently assumes `jq` is installed fails mysteriously. Keeping the PREREQS slot visible prompts the next author to fill it when one is added.*
- `EXECUTE` shows the exact invocation: `scripts/name-of-script.sh` followed by any arguments the script accepts. Nothing else — no inline comments, no commentary, no CWD reminders. The Invocation rule already fixes the CWD; repeating it here is noise.
	- *Copy-pasteable usage prevents misuse. "How do I run this?" should never be a question.*

Further research:
1. [ShellCheck directive reference](https://www.shellcheck.net/wiki/Directive): valid directives and placement.
2. [BashGuide: Practices](https://mywiki.wooledge.org/BashGuide/Practices): broader script hygiene.

---

## Error Mode

<!-- Bash's defaults are lenient: unset variables expand to empty strings, failed commands keep running, broken pipelines return success. A production script turns all three off on line one of its body. Placing the flag line immediately under the header — before anything else executes — makes it the earliest point where behavior could have diverged, and puts it one character away from the debugger's reach. -->

```bash
#!/usr/bin/env bash
#  PURPOSE: …
# -----------------------------------------------------------------------------
#  PREREQS: …
# -----------------------------------------------------------------------------
#  EXECUTE: scripts/name-of-script.sh
# -----------------------------------------------------------------------------
set -euo pipefail
```

Rules:
- The first executable line of every **executable script** is `set -euo pipefail`, directly under the header's closing `# ---` rule with no blank line between them.
	- *First executable line means the flags govern the entire script body. No blank above means the line rides with the header as a single opening unit — shebang, header, mode. The reader sees the script's operating posture in one uninterrupted block.*
- Sourced libraries (`*.func` files) **omit this line**. Shell options set inside a sourced file persist in the caller's shell — a library that runs `set -euo pipefail` silently changes the error-handling posture of every script that sources it. Libraries define functions and return; the caller picks its own error mode.
	- *Execution runs in a child shell and the flags die with it; sourcing runs in the caller's shell and the flags stay. Libraries must not leak behavior the caller didn't opt into.*
- Two blank lines separate `set -euo pipefail` from the VARIABLES section that follows — the same separator used before every top-level rule block.
	- *No carve-out for the error-mode stanza. One rule for vertical space between sections keeps the script's rhythm predictable: two blanks means "new section starts here," everywhere.*
- Keep all three flags together, in the order `-euo pipefail`. Do not split them across multiple `set` calls.
	- *One line is easier to read, easier to edit, and keeps the three behaviors visible as a set rather than scattered decisions.*
- For debugging, add `x`: `set -euxo pipefail`. Remove it when debugging is done.
	- *The flag line sits at the top of the body precisely so the `x` is a one-character edit at a glance-findable location. A `set -x` buried later traces only part of the run.*

What each flag does:
- `-e` — exit immediately if any command exits non-zero (outside of tested conditions like `if` and `&&/||`).
- `-u` — treat expansion of an unset variable as an error, not an empty string.
- `-o pipefail` — a pipeline's exit status is the rightmost non-zero status, not just the last command's. Without it, `false | true` returns 0.

Further research:
1. [BashFAQ/105: errexit pitfalls](https://mywiki.wooledge.org/BashFAQ/105): the edge cases and surprises of `set -e`.
2. [BashGuide: Practices](https://mywiki.wooledge.org/BashGuide/Practices): where these flags fit in broader script hygiene.

---

## Variables

<!-- Scattered assignments make scripts hard to tune and impossible to debug by inspection. One block, up top, lets you change behavior in one place and trace every expansion with `set -x`. -->

```bash
# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------
# ENV — required external inputs, assert early
: "${API_TOKEN?  API_TOKEN is missing!}"
: "${CONFIG_PATH?  CONFIG_PATH must point at a readable file}"

# Sourced — variables shared across scripts
source scripts/lib/common.env

# Assignments and flags
region='us-west-2'
dry_run=false
max_retries=3
threshold='1,000,000'

# Data — structured inputs the script reads
hosts_csv='etc/hosts.csv'
```

Rules:
- One block, near the top, after the header. No late `foo=bar` buried in the main program.
	- *A single block is the only place you look to change behavior or audit inputs. Debugging with `set -x` then traces every expansion against a known set.*
- Wrap the block in 79-char `# ---` rules (`# ` + 77 dashes) with a `VARIABLES` label. This is the **top-level section title pattern** — used by every top-level section (`VARIABLES`, `FUNCTIONS`, `MAIN`, `REPORT`) and by Goals inside MAIN. The rule block *is* the section title; there is no prose heading above it.
	- *The rule block is the script's hardest visual break: "new phase starts here." Nothing else in the script uses that pattern.*
- Two blank lines precede every top-level rule block; content follows the closing rule immediately, no gap.
	- *Top-of-hierarchy separator: two blank lines above, no gap below. Sub-blocks (functions, REQs in MAIN) use the same two-blank-lines pattern with a narrower `# ---` marker instead of the full rule.*
- Assert required inputs with `: "${VAR?  message}"`. The script exits immediately if unset.
	- *Failing at the top with a named variable beats failing 200 lines later with a cryptic unbound-variable error or — worse — silent wrong behavior on an empty expansion.*
- Group by origin: ENV (external), sourced (shared), local assignments, data pointers. Prune groups not used in this script — `template.sh` carries the full shape for reference.
	- *The shape of the groups tells the next reader what the script depends on at a glance. A pruned script shows only real dependencies; nothing to mistake for a forgotten slot.*
- Name local assignments lowercase. Reserve `UPPER_CASE` for exported/environment variables.
	- *Convention from POSIX forward. Mixing cases makes `set -x` output harder to scan.*
- Quote string values; leave bare booleans and bare integers unquoted. Numbers formatted for display (commas, units) are strings — quote them.
	- *Quoting tracks semantics: a string you'll pass around and print is quoted; a scalar you'll compute with is not. `region='us-west-2'` is a string; `port=8080` is an integer; `threshold='1,000,000'` is a formatted string that happens to look numeric. Single quotes suppress all expansion — use them unless interpolation is intended, then double quotes.*

Further research:
1. [BashGuide: Parameters](https://mywiki.wooledge.org/BashGuide/Parameters): assignment, scoping, and expansion basics.
2. [BashFAQ/073: Parameter expansion](https://mywiki.wooledge.org/BashFAQ/073): the `${var?}`, `${var:-default}`, `${var:=default}` family.
3. [Quotes](https://mywiki.wooledge.org/Quotes): when single vs. double quotes matter, and when they don't.

---

## Functions

<!-- Logic inlined in the main program turns a script into a transcript. Functions named for what they do let the main program read as a sequence of intentions, and let each piece be tested and reused. -->

```bash
# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
# Output helpers: print_goal, print_req, print_pass, print_error
source scripts/lib/printer.func

# Validate the input file exists and is readable.
check_input() {
	local path="$1"
	[[ -r "$path" ]] || { print_error "cannot read: $path"; return 1; }
}

# Render a summary line for one host record.
render_host() {
	local name="$1" ip="$2"
	printf '%-20s %s\n' "$name" "$ip"
}
```

Rules:
- One block, after Variables, before the main program. Every function defined before it is called.
	- *Bash resolves function names at call time, but a reader scans top-down. Defining up front means no "where is this defined?" hunts, and no ordering surprises when the main program is rearranged.*
- Wrap the block in the top-level section title pattern (see Variables) with a `FUNCTIONS` label.
	- *Consistent visual weight with VARIABLES and MAIN.*
- Source shared libraries here, not scattered through the script. Annotate what each provides.
	- *A single `source` site is the only place to look for external symbols. The annotation tells the reader which names entered the namespace without opening the library.*
- One purpose per function. Name `verb_noun`, lowercase, underscores.
	- *Functions that do one thing are testable in isolation. `verb_noun` reads as intent in the main program: `check_input "$file"` needs no further explanation.*
- Separate each function from the next with two empty lines followed by a comment block. The function's purpose comment is that comment block.
	- *One blank line separates logic inside a function. Two blank lines + a comment is the sibling-block separator used everywhere below the top-level rules — between functions here, between requirements in MAIN.*
- Declare locals with `local`. Return status with `return N`; return values via stdout.
	- *Without `local`, every assignment leaks into the caller's scope and silently clobbers state. Bash functions can only return an integer 0–255 as status — text must travel through stdout.*
- Comment above each function with its purpose. Compact — one line when possible, more only when needed.
	- *A name plus a short intent line is all the next reader needs. Prose longer than the function body is a smell.*

Further research:
1. [BashProgramming: Functions](https://mywiki.wooledge.org/BashProgramming#Functions): definition syntax, scope, `local`, and return conventions in one place.
2. [BashFAQ/084: Returning values](https://mywiki.wooledge.org/BashFAQ/084): why `return` is for status and `echo`/`printf` is for data.

---

## Main

<!-- MAIN is where the script does its work. It decomposes into Goals — sequential processing stages, each leaving state for the next — and each Goal decomposes into Requirements. Dividers address the source-reader (maintainer); `print_*` calls address the executor (operator). Two audiences, two strings — never combine them. -->

```bash
# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
# Normalize incoming HR records
#  * drops rows with missing phone numbers
#  * converts all phones to E.164
# ---------------------------------------------------------------------------
print_goal 'Normalizing HR records'


# ---
# REQ1
# ---
print_req 'Drop rows without a phone number'
# ... body: whatever legal bash the REQ needs ...


# ---
# REQ2
# ---
print_req 'Convert phone numbers to E.164'
# ... body ...


# ---------------------------------------------------------------------------
# Emit enriched CSV
#  * writes to /tmp/hr-out.csv
# ---------------------------------------------------------------------------
print_goal 'Writing enriched CSV'


# ---
# REQ1
# ---
print_req 'Write normalized records to disk'
# ... body ...
```

Rules:
- MAIN uses the top-level section title pattern with the `MAIN` label.
- MAIN contains one or more Goals. Each Goal is a sequential processing stage that leaves state for the next.
	- *Goals support the script's PURPOSE. A single-step script has one Goal; a three-stage pipeline has three.*
- Goal divider: top-level section title pattern wrapping a short `# Goal Purpose` line and optional `#  * detail` bullets. This block is written **for the maintainer reading the source** — describe what the Goal does, why, and any context the next author will need. Descriptive prose; can expand as context requires.
- Immediately after the closing 79-char rule, call `print_goal '…'`. This message is written **for the operator watching the script run** — the same Goal purpose rendered as a short verb-form announcement (typically `-ing`: "Normalizing HR records", "Writing enriched CSV").
	- *Two audiences, two strings. The comment block explains; the `print_goal` narrates. Do not collapse them — the maintainer wants context, the operator wants a progress line.*
- The first Goal's top rule is MAIN's closing rule — one shared line, no gap.
	- *MAIN's closer already provides the separator; doubling it is wasted weight.*
- Subsequent Goals have their own opening rule, preceded by two empty lines.
	- *Top-level-section separator applied between Goals that don't share a boundary with MAIN.*
- Each Goal contains one or more REQs — discrete steps the Goal depends on.
	- *REQs support Goals the way Goals support the PURPOSE.*
- REQ divider: short three-line form `# --- / # REQN / # ---`. The label is the bare sequential identifier — `REQ1`, `REQ2`, … — nothing else. Never concatenate with a purpose string.
- REQ numbering resets per Goal. Each Goal's first REQ is `REQ1`.
	- *REQs are scoped to their Goal. Per-Goal numbering lets Goals be reordered without renumbering the script.*
- Immediately after the closing `# ---`, call `print_req 'description'`.
- Two empty lines precede every REQ's opening `# ---`.
	- *Sibling-block separator within a Goal.*
- The REQ body follows `print_req`. Its content is outside the scope of these rules — a REQ may test a condition, run a command, transform data, loop, anything legal in bash.
	- *Constructs used inside a REQ (conditionals, loops, I/O) have their own sections in this reference.*

---

## Checks

<!-- Most REQs test a condition. The reference doesn't teach `[[ ]]` or `if` — the agent already has that. What needs saying is how the print helpers compose around the check: one announcement line, one test, one outcome call. Consistency here is what makes script output scannable across the whole codebase. -->

```bash
# ---
# REQ1
# ---
print_req 'Drop rows without a phone number'
if [[ -s "$hosts_csv" ]]; then
    print_pass
else
    print_error "input is empty or missing: $hosts_csv"
fi


# ---
# REQ2
# ---
print_req 'Apply migration 0042'
if ! migrate up 0042; then
    print_error 'migration 0042 did not apply cleanly'
fi
```

Rules:
- Every REQ that performs a check follows one shape: `print_req` announces, a conditional tests, one of `print_pass` or `print_error` reports the outcome. No variations.
	- *Three things on three lines, the same three lines every time. Reading a dozen REQs feels like reading the same REQ — the operator's eye locks onto the content, not the scaffolding.*
- `print_pass` takes no arguments. The `print_req` above it already named what was tested.
	- *Two strings saying the same thing is noise. The helper prints a short success marker; the reader's context is the REQ description one line up.*
- `print_error` takes a short reason — a fragment that completes the sentence "it failed because…". It prints a banner to stderr and exits the script with status 1.
	- *The reason is the one piece of information the operator doesn't already have. Keep it short; the banner does the visual work.*
- Do not write `exit 1` (or any exit) after `print_error`. It exits for you. Adding one is dead code and moves termination behavior out of a single place.
	- *Error handling lives in `print_error`. A call site that duplicates the exit splits that responsibility and rots the moment the helper's exit code changes.*
- Use the `if / then / else / fi` block form, not `&&/||` one-liners, for any check with both a pass and a fail branch.
	- *Block form reads top-to-bottom: test, pass path, fail path. `cmd && print_pass || print_error "…"` looks equivalent but isn't — if `print_pass` ever returns non-zero, the `||` fires. The block form has no such trap.*
- When the command *is* the check (no value to compare), use the negated single-branch form: `if ! command; then print_error '…'; fi`. No `print_pass`, no `else`.
	- *Successful execution under `set -euo pipefail` continues naturally — no success announcement needed beyond the `print_req` above. Forcing a `print_pass` here duplicates the REQ line and adds a branch that can never usefully differ from "kept running".*
- Do not redirect print helpers. `print_goal`, `print_req`, `print_pass` go to stdout; `print_error` goes to stderr. The helpers manage their own streams.
	- *Stream discipline is part of their contract. Piping `print_error` to stdout breaks the operator's ability to separate progress from failures with a single `2>errors.log`.*

Further research:
1. [BashFAQ/105: errexit pitfalls](https://mywiki.wooledge.org/BashFAQ/105): why the block form is safer than `&&/||` chains under `set -e`.

---

## Report

<!-- A script that alters state can summarize what it did. REPORT is the optional closing section that emits that summary, for the executor, after MAIN completes. -->

Rules:
- REPORT is optional. Include it when the operator would benefit from statistical pass/fail numbers after execution — counts of items processed, succeeded, failed, skipped. Omit it otherwise.
	- *The trigger is tallies the operator can act on, not merely the existence of outcomes. A script that writes one file produces an outcome but no statistic; a script that processes 400 records and skipped 12 has numbers worth surfacing.*
- When included, REPORT uses the top-level section title pattern with the bare label `REPORT` — no descriptive purpose line, no detail bullets. Placement: after MAIN, before exit.
	- *Goals carry a unique purpose; REPORT's is always the same — surface execution stats. The `(optional)` qualifier in `template.sh` is meta-info; drop it in actual scripts.*
- When the summary is multi-line, use the multi-line `printf` pattern covered in Line Width.
	- *Body format is a rendering concern, already specified. REPORT contributes the section framing only.*

---

## Exit

<!-- Every script ends the same way: a signature, then a graceful terminator. A script written properly closes with both. -->

```bash
# ---
# fin~
# ---
exit 0
```

Rules:
- Close every **executable script** with a three-line `# --- / # fin~ / # ---` marker, then `exit 0` immediately below — no blank line between them.
	- *`# fin~` is an artistic expression — the script's deliberate close, written by someone who cares how it reads. `exit 0` is the graceful terminator: explicit success, independent of whatever the last command returned.*
- Sourced libraries (`*.func` files) use `return 0` in place of `exit 0`. Everything else about the closer is the same.
	- *`exit` from sourced code terminates the caller, not the library. `return` leaves the sourced scope and hands control back to the script that sourced it — the correct terminator for a library.*
- Two empty lines precede the opening `# ---` of the marker.
	- *Same sibling-block separator used throughout. The marker is the script's final sibling.*
- The marker and `exit 0` are the last lines of the file. Nothing follows them.
	- *A trailing newline is fine; a trailing comment, unreachable code, or additional statement is not.*

---
