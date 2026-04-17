# Bash Reference

A single-file reference of GNU Bash constructs for the `cascadian:bash` skill.

> **You are the `cascadian:bash` skill.** This reference defines the conformance target for every bash script you produce or modify. Compliance is the skill's sole purpose; deviation means the output is not compliant. Apply every rule. Use every example. Follow the "Further research" links only when the example does not fit.

The code block in each section is the answer. Use it directly.

If the example does not meet your requirements, consult the section's "Further research" links before reaching for an alternative pattern. Do not improvise — every link is vetted for that construct's edge and corner cases. Pick the happy path first; follow the links when it does not fit.

Further-research entries are tagged *practice* (implementation best practices, typically from mywiki.wooledge.org) or *reference* (authoritative syntax, from the GNU Bash Manual). Start with *practice*; reach for *reference* when the question is about exact syntax or undocumented corners.

---

## Starter Kit

<!-- basher ships one canonical artifact. Every compliant script presumes it. -->

Rules:
- The starter kit is one file at a fixed target path: `scripts/lib/printer.func` — shared output helpers: `print_goal`, `print_req`, `print_pass`, `print_error`.
	- *The printer's helpers drive every compliant script's visible output. The script anatomy itself is constructed per project by following this reference; the printer is passed whole.*
- Every compliant script sources the printer: `source scripts/lib/printer.func`.
	- *The Main-program conventions (announcing goals, reporting pass/fail) presuppose these helpers. A script that doesn't source them exits the scope of this reference.*

---

## Printer Library

<!-- The four helpers sourced from `scripts/lib/printer.func` have fixed behaviors scripts rely on. Rules here codify what each call guarantees — streams, return codes, rendering — so callers can reason about output routing and error propagation without reading the library's source. -->

### Contract

| Helper | Stream | Return | Behavior |
|---|---|---|---|
| `print_goal <msg>` | stdout | 0 | Centered banner framed with hyphens |
| `print_req <msg>` | stdout | 0 | Indented requirement line |
| `print_pass` | stdout | 0 | `    test passed` in green; takes no args, caller args discarded |
| `print_error <reason>` | stderr | 1 | Centered red banner framed with tildes; returns 1 so `set -e` halts the script |

### Rules

- Streams are fixed. `print_goal`, `print_req`, `print_pass` go to stdout; `print_error` goes to stderr. Route the whole script's output with `script.sh >out 2>err`; do not redirect individual helpers at call sites.
	- *Stream discipline is part of the contract. Redirecting `print_error` to stdout breaks the operator's ability to separate progress from failures with a single `2>errors.log`.*
- `print_error` returns 1. Under `set -euo pipefail` a bare call halts the script at the point of failure — no separate `exit` needed. For per-iteration continue-on-error inside a loop, append `|| true` (see §Checks per-iteration rule).
	- *The `return 1` semantics let the caller decide: default halt via `set -e`, opt-in continue via `|| true`. The library doesn't impose exit policy; the script does.*
- `print_pass` is bare — no arguments. Per-iteration or per-item context belongs in `print_req` above the call.
	- *Two strings saying the same thing is noise. `print_req` names what was tested; `print_pass` confirms it.*
- Helpers tolerate empty-string and shell-metachar arguments without aborting. Quoting at the call site is the caller's responsibility per §Quoting.
	- *The library passes its arguments through `printf '%s'` internally — no second round of expansion, no crash on empty input. The caller's job is to quote on the way in; the library's job is to render what arrives.*

---

## Invocation

<!-- A shared anchor for paths makes scripts simpler. If every script assumes a different working directory, relative paths become guesswork and scripts grow defensive prologues to compensate. One convention replaces all that ceremony. -->

Rules:
- Scripts are invoked from the repo root. The operator types `scripts/name.sh` and stays there — no `cd scripts && ./name.sh`, no absolute path gymnastics.
	- *One CWD for every script in the project. The operator stays put; scripts come to the operator. This is the convention that every other rule here depends on.*
- All relative paths inside a script — `source` targets, data file references, log output paths — are paths from the repo root.
	- *Bash resolves relative paths against the invoking shell's CWD, not the script's file location. With a single anchor (the repo root), `source scripts/lib/printer.func` reads the same from every script and every invocation.*
- Do not use `$(dirname "$0")`, `$BASH_SOURCE`-based CWD computation, or `cd` prologues to find or change the script's working directory.
	- *Unneeded when the CWD convention holds; each has its own edge cases (symlinks, sourced scripts, `$0` lies).*

Further research:
1. [BashFAQ/028: Script location](https://mywiki.wooledge.org/BashFAQ/028): why `$0` and `$(dirname "$0")` are unreliable, and why a CWD convention is the stable answer.

---

## Line Width

<!-- Old terminals wrap anything past 80 columns. Modern ones do the same when windows are split, panes are narrow, or output is piped through `less -S`. A script that only reads cleanly at full width is a script that only reads in ideal conditions. -->

Rules:
- Every line is exactly 79 characters or shorter — never 80, never longer. Code, comments, output, section rules, and `# ---` markers all obey the same hard limit.
	- *The constraint is the worst plausible terminal, not the author's. 79 is the number because section rules are 79 and every other line lives inside that frame. One wrap-imposed line break destroys alignment, indentation, and the reader's ability to scan.*
- When a single statement or message cannot fit, break it into a multi-line construct rather than letting the terminal wrap it.
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
- When editing a **foreign script** that uses a different convention, match what's there — do not retab as a side effect. A script is foreign iff it was neither produced from a basher template nor lives inside a repository that declares basher as its standard. Anything else is a basher artifact and takes 4 spaces.
	- *The author of a foreign script has the right to their own convention. Changing it silently pollutes the diff. The concrete definition of "foreign" closes the loophole of claiming any inherited script is exempt.*
- Within any one script, one depth and one whitespace choice, applied consistently.
	- *Mixed indentation renders unpredictably across editors and breaks alignment of comments and continuations.*
- Never reformat whitespace in a way that alters execution. Heredoc body lines, line-continuation trailing whitespace, and string literals are code, not style.
	- *`<<EOF` emits body lines verbatim; `<<-EOF` strips leading tabs (not spaces); `\` continuations require the backslash as the last character on the line.*

---

## Comments

<!-- A maintained script is a story the next reader inherits. The comment is the contract (WHAT); the code is one implementation (HOW). When the two agree, the next maintainer refactors freely without rebuilding intent. -->

```bash
# DO — the comment is the contract; the code is one implementation
# diff-first dispatch: cheap check, expensive remediation only when needed
if ! diff "$target_config" "$spec_file" >/dev/null; then
    while IFS= read -r line; do
        # ignore commented lines in the spec
        [[ "$line" = \#* ]] && continue
        key="${line%% = *}"
        print_req "process $key"
        if ! grep -qF -- "$key" "$target_config"; then
            sed -i "/$anchor/a\\ $line" "$target_config"
        fi
        print_pass
    done < "$spec_file"
fi

# DON'T — restate what the code already says
# read spec_file one line at a time
while IFS= read -r line; do …

# DON'T — narrate design decisions
# NOTE: Considered getopts, chose while-case for long-flag support

# DON'T — restate rules the reference already teaches
# §Quoting applied — all expansions quoted
```

Rules:
- Comments express intent; code expresses one implementation. When the comment names the strategy, invariant, or domain-level goal of the block below, the next reader evaluates the code against the comment and refactors freely — 50 chars to 30, one idiom to another — without rebuilding the purpose.
- Write comments generously where they orient the reader. Block-level strategy, domain-language intent for idioms, non-obvious invariants, edge cases the author has already thought through.
	- *Err toward comments that serve the next reader. The concern isn't "too many comments"; the concern is "comments that add no signal."*
- Do not restate what the code already says. `# read spec_file one line at a time` above `while IFS= read -r line` doubles the reading load without adding signal.
	- *Restating translates bash into English — work the reader does not need. Good variable names already say what happens.*
- Do not narrate design decisions. Those belong in the documentation, PR description, or commit message; one place is enough.
	- *`# NOTE: chose while-case over getopts` is a process note. Six months later it's a dead leaf; pick one channel (docs, PR, commit) and let it live there.*
- Do not restate the reference. `# §Quoting applied` patronizes the informed reader and misleads the uninformed one.
	- *The code follows the rule whether or not a comment says so. If the reader wants the rule, they read the reference.*

---

## Quoting

<!-- Unquoted expansion runs two passes most authors didn't ask for: word-splitting on IFS, then pathname expansion on any token that looks like a glob. A filename with a space or a `*` silently becomes multiple arguments or a list of matches. The rule isn't "quote when it matters" — it's "quote always; the only time you don't is when word-splitting is exactly what you mean." -->

```bash
# DO
cp "$src" "$dst"
for f in "${files[@]}"; do process "$f"; done
if [[ "$status" = 'ready' ]]; then ...
stamp="$(date '+%Y%m%d')"

# DON'T
cp $src $dst                    # src with a space becomes two args
for f in ${files[@]}; do        # elements re-split on IFS
if [[ $status = ready ]]; then  # RHS parsed as a glob, not a literal
stamp=$(date '+%Y%m%d')         # works today; breaks when output has whitespace
```

Rules:
- Quote every expansion. `"$var"`, `"$@"`, `"$(cmd)"`, `"${arr[@]}"`. In command position, in test brackets, in assignments, in strings — everywhere an expansion appears. This is the rule 99% of the time.
	- *Quotes suppress word-splitting and pathname expansion. You almost always want neither. Treat unquoted expansion as a deliberate, documented choice — not a default.*
- The only exception: when word-splitting or globbing is the explicit purpose of the expansion. An unquoted `for f in *.log` invokes pathname expansion on purpose. An unquoted `cmd $pre_built_args` splits a pre-built argument string on purpose — but when emitting new code, prefer an array: `cmd "${args[@]}"`. The pre-built-string form is a pattern you may encounter in legacy code; it is not one to produce.
	- *The carve-out is narrow: if the expansion would do exactly the right thing quoted, quote it. Reach for the unquoted form only when the splitting or globbing is the point — and for argument lists, an array is always the right shape in new code.*
- Prefer single quotes for literal strings. Use double quotes only when expansion is intended.
	- *Single quotes suppress `$`, backticks, and `\`. Upgrade to double only when expansion is actually needed.*
- Brace the name when the expansion is adjacent to word characters, a digit, or a parameter operator (`"${file}_backup"`, `"${arch##*-}"`). Use `"$var"` when the reference stands alone.
	- *The brace is what ends the name. Without it, `$file_backup` reads as a different variable. The cost of always-brace on adjacency is two characters; the cost of forgetting is a silent bug.*
- Arrays expand as `"${arr[@]}"`. Never `${arr[@]}`, `${arr[*]}`, or `"${arr[*]}"` — each is subtly different and almost never what you want.
	- *`"${arr[@]}"` is the one form that yields one shell word per element, preserving boundaries. The other three collapse or re-split in ways that corrupt data with whitespace or glob metacharacters in it.*
- Inside `[[ ]]`, quote the right-hand side of `=`/`!=` for literal comparison. Unquoted, the RHS is a glob pattern.
	- *`[[ "$f" = "*.log" ]]` compares against the literal string `*.log`. `[[ "$f" = *.log ]]` matches any filename ending in `.log`. Both are legal; 95% of the time the quoted, literal form is the one intended.*

Further research:
1. [Quotes](https://mywiki.wooledge.org/Quotes): the authoritative treatment — when each quote form matters and when it doesn't.
2. [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls): the first dozen entries are almost all unquoted-expansion bugs.

---

## Section Frame

<!-- Every labeled block in a basher script is framed by two comment rules, never by a Markdown heading. Two widths, one shape, explicit hierarchy. Every later section that refers to "wrapping the block", "the divider", or "the frame" means this. -->

```bash
# -----------------------------------------------------------------------------
# LABEL                            ← single-word label OR...
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Goal Purpose                     ← ...short prose + optional detail bullets
#  * optional detail
# -----------------------------------------------------------------------------

# ---
# REQ1                             ← short-rule variant, sub-blocks only
# ---
```

Rules:
- **Full rule** — `# ` + 77 dashes (79 chars total). Frames every top-level section (`VARIABLES`, `FUNCTIONS`, `MAIN`, `REPORT`) and every Goal inside MAIN.
- **Short rule** — `# ---` (5 chars). Frames sub-blocks *inside* a Goal: each `REQ` divider and the `# fin~` closer.
- The frame's body is either a single-word label OR a Goal Purpose line with optional `#  * detail` bullets. Nothing else sits between the rules.
	- *The label is for scanning; the prose form gives the maintainer context about a Goal. The corresponding `print_goal` call addresses the operator — two audiences, two strings; see MAIN.*
- Two **blank lines** precede every frame, regardless of width. Content follows the closing rule immediately — no blank line between. A blank line is `^$` — a line with no characters, not a whitespace-only line.
- A frame *is* the title. Never add a Markdown heading (`##`, `###`) or prose line above it.

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
#           b) source scripts/vars.env
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
- `PREREQS` lists every resource the script needs to run properly. The test is functional: if the script won't run properly without it, it's a prerequisite. Common categories include installed tools, environment variables, credentials and tokens (e.g., a HashiCorp Vault token, AWS/GCP credentials, SSH keys), permissions (sudo, group membership, file mode), network access to specific hosts or services, required input files and their formats, and existing filesystem state — but the test is the rule, not the list. Write `none` only when the script truly requires nothing beyond a working bash shell. Do not remove the block.
	- *A script that silently assumes `jq` is installed or a Vault token is present fails mysteriously. The functional test captures every such dependency, whether or not it fits a named category.*
- When a script depends on environment variables sourced from a setup file, list the `source` command as a prereq — e.g., `source scripts/vars.env`. The file can be named anything that describes its contents; there may be more than one, though typically one suffices. The operator runs the `source` command before execution; the script asserts the variables exist (see §Variables).
	- *The prereq tells the operator what to do; the `${VAR?}` assertion catches what they forgot. Together they close the gap between "the script needs this" and "the script fails clearly when it's missing."*
- `EXECUTE` shows the exact invocation: `scripts/name-of-script.sh` followed by any arguments the script accepts. Nothing else — no inline comments, no commentary, no CWD reminders. The Invocation rule already fixes the CWD; repeating it here is noise.
	- *Copy-pasteable usage prevents misuse. "How do I run this?" should never be a question.*

Further research:
1. [ShellCheck directive reference](https://www.shellcheck.net/wiki/Directive): valid directives and placement.
2. [BashGuide: Practices](https://mywiki.wooledge.org/BashGuide/Practices): broader script hygiene.

---

## Error Mode

<!-- Bash's defaults are lenient: unset variables expand to empty, failed commands keep running, broken pipelines return success. Turn all three off on line one. -->

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
- Keep all three flags together, in the order `-euo pipefail`, on one `set` line. For debugging, add `x` → `set -euxo pipefail`; remove it when done.
	- *One line is easier to read and edit; the top-of-body placement puts the `x` one character away when tracing is needed.*
- For counters, use `count=$((count + 1))`. Do not write `(( count++ ))` under `set -e`.
	- *`(( count++ ))` returns the pre-increment value as its exit status. When the counter is 0, that's exit 1, and `set -e` aborts. The assignment form yields a value and the `=` completes with exit 0 regardless. Other safe forms (`: $((count++))`, `(( count++ )) || true`) exist; consult the Further research links when the assignment form does not fit.*

What each flag does:
- `-e` — exit immediately if any command exits non-zero (outside of tested conditions like `if` and `&&/||`).
- `-u` — treat expansion of an unset variable as an error, not an empty string.
- `-o pipefail` — a pipeline's exit status is the rightmost non-zero status, not just the last command's. Without it, `false | true` returns 0.

Further research:
1. [BashFAQ/105: errexit pitfalls](https://mywiki.wooledge.org/BashFAQ/105) — *practice.* The edge cases and surprises of `set -e`, including the counter-increment interaction above.
2. [BashGuide: Practices](https://mywiki.wooledge.org/BashGuide/Practices) — *practice.* Where these flags fit in broader script hygiene.
3. [GNU Bash Manual: Shell Arithmetic](https://www.gnu.org/software/bash/manual/html_node/Shell-Arithmetic.html) — *reference.* Authoritative definitions of arithmetic expansion (`$(( … ))`), the `(( … ))` compound command, and their exit-status semantics.

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

# Assignments and flags
region='us-west-2'
dry_run=false
max_retries=3
threshold='1,000,000'

# Arrays
ports=(443 80)
required_tools=(nc curl)

# Data — structured inputs the script reads
hosts_csv='etc/hosts.csv'
```

Rules:
- One block, near the top, after the header. No late `foo=bar` buried in the main program.
	- *A single block is the only place you look to change behavior or audit inputs. Debugging with `set -x` then traces every expansion against a known set.*
- Frame the block (see Section Frame) with a `VARIABLES` label.
	- *The frame is the script's hardest visual break: "new phase starts here."*
- Assert required inputs with `: "${VAR?  message}"`. The script exits immediately if unset.
	- *Failing at the top with a named variable beats failing 200 lines later with a cryptic unbound-variable error or — worse — silent wrong behavior on an empty expansion.*
- Group by origin: ENV (external), assignments and flags (local scalars), arrays (local lists), data (file pointers). Add only the groups the script requires.
	- *The shape of the groups tells the next reader what the script depends on at a glance. A group that isn't there is a dependency that doesn't exist.*
- Name local assignments `snake_case`. Reserve `UPPER_CASE` for exports and script-level constants. No `camelCase`.
	- *`snake_case` matches UNIX convention and keeps `set -x` output scannable.*
- Quote string values; leave bare booleans and bare integers unquoted. Numbers formatted for display (commas, units) are strings — quote them.
	- *Quoting tracks semantics: a string you'll pass around and print is quoted; a scalar you'll compute with is not. `region='us-west-2'` is a string; `port=8080` is an integer; `threshold='1,000,000'` is a formatted string that happens to look numeric. Single vs. double quote choice is covered in the Quoting section.*

Further research:
1. [BashGuide: Parameters](https://mywiki.wooledge.org/BashGuide/Parameters): assignment, scoping, and expansion basics.
2. [BashFAQ/073: Parameter expansion](https://mywiki.wooledge.org/BashFAQ/073): the `${var?}`, `${var:-default}`, `${var:=default}` family.
3. [Quotes](https://mywiki.wooledge.org/Quotes): when single vs. double quotes matter, and when they don't.

---

## Parameter Expansion

<!-- Parameter expansion is bash's in-shell value surgery: default values, prefix/suffix strip, length, replace. Knowing it exists saves a fork to `basename`, `dirname`, `expr`, or `sed`, and produces correct-by-construction code for missing-value handling. -->

```bash
# Default when unset (fallback without branching)
vault_addr="${VAULT_ADDR:-https://localhost:8200}"

# Basename / dirname without forking
script_name="${0##*/}"            # strip longest prefix ending in /
script_dir="${0%/*}"               # strip shortest suffix starting with /

# Integer arithmetic
count=$((retries + 1))
```

Rules:
- Reach for parameter expansion before forking an external tool. `${path##*/}` replaces `$(basename "$path")` with no process spawn.
	- *Every `$(cmd)` is a subshell; shell-internal expansion is free. On a loop of 10,000 paths that's real time. On a one-shot it's still the clearer form once you know it.*
- Use `${var:-default}` for fallback, `${var:?message}` for required. Do not write `if [[ -z "$var" ]]; then var=default; fi`.
	- *The expansion form is atomic — no chance to branch wrong, no extra lines. `${var:?message}` exits the script with the named message; the canonical placement is the top of the script (see Variables).*
- Do not improvise expansions beyond the shapes shown. The operator set is large and subtle — `#` vs `##`, `%` vs `%%`, `:-` vs `-`, `/` vs `//` all differ in non-obvious ways; consult the references rather than guess.

Further research:
1. [BashGuide: Parameters — Parameter Expansion](https://mywiki.wooledge.org/BashGuide/Parameters#Parameter_Expansion): the complete operator set with examples.
2. [BashFAQ/073](https://mywiki.wooledge.org/BashFAQ/073): parameter-expansion cheat sheet.

---

## Redirection

<!-- Bash's redirection operators are expressive and easy to misread. Favor the explicit form over the shorter one — a reader who can pronounce the operators can debug them. -->

```bash
# Silence a command's output and errors
cmd >/dev/null 2>&1

# Expand template variables into a file
envsubst <"$template" >"$output"

# Write a config; body interpolates variables
cat <<EOF >/etc/app.conf
port=$port
log_dir=$log_dir
EOF

# Embed a literal block; no expansion
cat <<'EOF' >scripts/install.sh
#!/usr/bin/env bash
printf 'hello from $USER\n'
EOF

# Feed one string to stdin (split a line)
read -r first _ <<< "$line"

# Treat a command's output as a file argument
diff <(sort a.txt) <(sort b.txt)
```

Rules:
- Silence a command with `>/dev/null 2>&1`. Do not use `&>/dev/null`.
	- *`>/dev/null` redirects stdout; `2>&1` points stderr at the same place. Reach for this only to quiet a misbehaving tool that writes to the wrong stream — real errors are handled, not hidden.*
- Expand template variables into a file with `envsubst <template >output`. Do not pipe through `cat`.
	- *envsubst substitutes exported `$VAR` references in the input, leaving other text literal — a compact templating idiom. The `cat <tmpl | envsubst >out` form spawns a useless process.*
- Redirect a file into a command with `cmd <file`. Do not `cat file | cmd`.
	- *The `cat` form spawns an extra process, and breaks for commands that need seekable input (random-access, not a byte stream).*
- Heredocs: unquoted delimiter (`<<EOF`) interpolates the body; quoted delimiter (`<<'EOF'`) treats it as literal. Quote whenever the body contains `$`, backticks, or `\` that should pass through unchanged.
	- *The unquoted form is a reader-trap: `$PATH` in the body becomes the caller's `PATH`, not the literal string. When writing a script-into-a-script or embedding config with shell-looking syntax, quote the delimiter.*
- Herestring `<<<` feeds a single string to a command's stdin — most often paired with `read` to split a line into fields. See the reference for the full shape.
	- *A compact alternative to `echo "$line" | read …` — and unlike the pipe form, it does not spawn a subshell, so variables set by `read` stay in scope.*
- Process substitution `<(cmd)` lets a tool that expects a filename argument read a command's output instead. Bash materializes a `/dev/fd/N` handle; the consumer reads it as a file.
	- *The canonical use is diffing two streams — `diff <(sort a) <(sort b)` — without creating tempfiles. Useful anywhere a tool refuses pipes but accepts files.*

Further research:
1. [unix.SE: redirecting to /dev/null](https://unix.stackexchange.com/a/119650): walks through each operator explicitly; recommends writing it out over shortened forms.
2. [BashGuide: InputAndOutput](https://mywiki.wooledge.org/BashGuide/InputAndOutput): full redirection operator set, heredocs, herestrings, process substitution.
3. [GNU gettext: envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html): envsubst invocation, including the `'$VAR1 $VAR2'` explicit-list form.

---

## Loops

<!-- Bash has four loop forms; two of them carry nearly all real work. `while read` for unknown-size streams; array iteration for known, bounded inputs. The rest is niche. -->

```bash
# Stream-process a file line by line for an unknown number of elements
while IFS= read -r line; do
    process "$line"
done < "$input_file"

# Stream-process a command's output (state set inside survives)
while IFS= read -r cluster; do
    clusters+=("$cluster")
done < <(aws eks list-clusters --output text)

# Iterate an array of known number of elements
for server in "${key_servers[@]}"; do
    attempt_connect "$server"
done
```

Rules:
- Use `while IFS= read -r line; do …; done < input` when the count is open-ended — a file, a command's output, any stream. This is the first construct to reach for on a big processing job where the number of items is unknown.
	- *`while read` pulls one record at a time; memory usage is one line regardless of input size. For a command that returns a million rows, this is the only loop form that scales.*
- Feed a `while read` loop with process substitution (`done < <(cmd)`), not a pipeline (`cmd | while read`). Process substitution keeps the loop in the current shell; the pipeline runs it in a subshell and drops every variable set inside.
	- *Counters, accumulated arrays, and flags set inside a piped `while read` vanish when the loop exits — the subshell dies and takes its scope with it. The `< <(cmd)` form sidesteps that entirely. See Redirection for the mechanics of `<(cmd)`.*
- Always `IFS= read -r`. `IFS=` prevents leading/trailing whitespace being stripped; `-r` prevents backslash interpretation.
	- *`read` defaults to splitting on IFS and processing backslashes — both turn off when feeding records through the loop verbatim. `IFS= read -r` is the shape that preserves the record you were given.*
- Use `for x in "${arr[@]}"` when the items are a known array that fits in memory.
	- *`for` reads the whole list into the loop header before iteration starts — fine for a ten-item array, wrong shape for a stream of unknown size.*

Further research:
1. [BashFAQ/001: How can I read a file line-by-line?](https://mywiki.wooledge.org/BashFAQ/001): exact rationale for `IFS= read -r` and the `< <(cmd)` pattern, with edge cases (final newline, field splitting).
2. [BashGuide: TestsAndConditionals](https://mywiki.wooledge.org/BashGuide/TestsAndConditionals#Loops): the complete loop family (`for`, `while`, `until`, C-style).

---

## External Tools

<!-- Two tools dominate real sysadmin scripts: `find` and `curl`. Learn the safe shape once; don't improvise the flags. -->

```bash
# find — DO: batched exec, or null-safe pipeline
find /var/log -type f -name '*.log' -mtime -1 -exec rm {} +
find "$HOME/vms" -name '.DS_Store' -print0 | xargs -0 rm

# find — DON'T
find /var/log -name '*.log' -exec rm {} \;      # one fork per match
find /var/log -name '*.log' | xargs rm          # breaks on spaces/quotes in names

# curl — DO
curl -fsSL -o "$output" "$url"
curl -fsSL "$url" | sudo tar -xzC /usr/local

# curl — DON'T
curl "$url" -o "$output"                         # no fail-fast, no redirects, progress noise
```

Rules:
- `find … -exec cmd {} +` for bulk actions. `-print0 | xargs -0` when a pipeline is required.
	- *The `+` form batches matches into one `cmd` invocation; `\;` forks once per file. The `-print0 | xargs -0` form is null-delimited so filenames with spaces, newlines, or quotes survive — plain `| xargs` splits on whitespace and corrupts the input.*
- The `-fsSL` flag set for curl is invariant. `-f` fails on HTTP errors, `-sS` is silent-but-shows-real-errors, `-L` follows redirects.
	- *Each flag fixes a real footgun: without `-f`, a 404's HTML body lands in the output file; without `-sS`, either progress bars pollute stdout or hard errors are swallowed; without `-L`, a 301 silently returns nothing. Memorize the four letters as one token.*
- On macOS, `-exec cmd {} +` stops iterating on the first nonzero exit from `cmd` (Darwin bug). When partial results would be silent data loss, fall back to `-print0 | xargs -0`.
- When the action body needs to update script-local state (counters, arrays, flags), do not reach for `find … -exec cmd {} +` — its child shell drops every assignment made inside `cmd`. Use the process-substitution loop instead: `while IFS= read -r -d '' var; do …; done < <(find … -print0)`. find emits NUL-terminated paths, the loop reads each one in the current shell, and assignments made inside the loop persist after it exits.
	- *Two alternatives, one per case. `-exec +` is the default when the action is self-contained (the command itself is the whole job — `rm`, `chmod`, no tally back). The process-substitution loop is the default when the script needs the action's tally afterward. See §Loops for the `while read` mechanics.*

Further research:
1. [wooledge: UsingFind](https://mywiki.wooledge.org/UsingFind) — §7 "Actions in bulk" has the full xargs / `-print0` / `-exec +` treatment.
2. [BashFAQ/119](https://mywiki.wooledge.org/BashFAQ/119) — UUOC rationale.
3. [curl manpage](https://curl.se/docs/manpage.html) — every flag.

---

## Pipelines

<!-- Recognize the patterns; the man pages teach them. -->

```bash
# Long pipelines: break with \, continue with leading |
curl -s "$url" \
    | jq -r '.items[].metadata.name' \
    | grep -v '^kube-' \
    | xargs -I{} kubectl delete pod {}

# Watch output live and capture to disk
scripts/my_script.sh 2>&1 | tee /tmp/my_script.log

# Batch-confirm destructive commands
yes | gcloud container clusters delete "$cluster_name" --region "$region"

# Self-exclude grep from its own ps output (dry-run without `kill` first)
ps aux | grep "[v]ault server" | awk '{print $2}' | xargs kill
```

Rules:
- Leading-pipe continuation for multi-line pipelines — each stage reads as a distinct step.
- `| tee /tmp/$script.log` in the script's EXECUTE header tells the operator how to capture output live.
- `yes | cmd` feeds unlimited `y\n` for non-interactive flows with known-safe prompts.
- `grep "[x]foo"` matches `xfoo` but not the literal `[x]foo` — so grep excludes itself from its own `ps` output. Use `pgrep` when available.
- Dry-run `xargs kill` before automating. Run the pipeline with `kill` removed, confirm the PID list, then wire it in — an over-broad pattern kills the wrong processes.
- `curl | bash`: vendor-installer pattern. Security tradeoffs are on the operator; not endorsed here.

Further research:
1. [GNU Bash Manual: Pipelines](https://www.gnu.org/software/bash/manual/html_node/Pipelines.html) — authoritative pipeline semantics, including `|&`, exit status, and PIPESTATUS.
2. [`man pgrep`](https://man7.org/linux/man-pages/man1/pgrep.1.html) — modern replacement for the `ps … | grep "[x]foo"` self-exclusion trick.

---

## Temp Files

<!-- Scripts that create temp artifacts are promises to the operator: /tmp stays clean, even when the script aborts. `mktemp` names the file safely; `trap … EXIT` removes it on every exit path. The pair is also a first-class security construct — when secret or sensitive material needs to exist for a moment, serve its purpose, and disappear, this is the shape. -->

```bash
# Create a named temp dir; trap it for cleanup
tmp_dir="$(mktemp -d /tmp/my_script-XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

work_on "$tmp_dir/input.csv"
```

Rules:
- Use `mktemp -d /tmp/name-XXXXXX` for temp dirs, `mktemp /tmp/name-XXXXXX` for tempfiles. Include a project-identifiable prefix.
	- *The `XXXXXX` is not literal — mktemp replaces it with random characters and returns a guaranteed-unique path. A project prefix (`my_script-`, `deploy-`) makes tempfiles traceable when `/tmp` fills.*
- Pair every `mktemp` with `trap 'rm -rf "$path"' EXIT`. Set the trap immediately after the mktemp line, before any work.
	- *The EXIT trap fires on success, failure, error, and ctrl-C alike. Setting it at the top (not at the end of main) means every abort path cleans up — including the error the script doesn't know about yet. For sensitive material, that discipline is the difference between "exists for a moment" and "leaks on crash."*
- An `EXIT` trap body must not include `exit`. Let the script's real exit status flow through — `exit 0` (or any explicit code) in a trap body masks failures from `set -e`, `print_error`'s `return 1`, signals, and explicit error paths alike. For signal-specific behavior (e.g., normalize SIGINT's 130 to 0), use a dedicated `trap 'handler' INT` instead of overriding EXIT.
- Do not hand-roll temp paths. `/tmp/$$.tmp`, `/tmp/script.log`, or any literal fixed name is a race condition waiting to happen.
	- *A literal name collides between concurrent invocations; `$$` collides when PIDs wrap. mktemp is the one right answer.*

Further research:
1. [`man mktemp`](https://man7.org/linux/man-pages/man1/mktemp.1.html) — template syntax, `-d`, `-u`, `-q` flags, TMPDIR.
2. [BashFAQ/062](https://mywiki.wooledge.org/BashFAQ/062) — safe temp-file creation, security pitfalls, fallbacks when mktemp isn't available.

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
- Frame the block (see Section Frame) with a `FUNCTIONS` label.
	- *Consistent visual weight with VARIABLES and MAIN.*
- Source shared libraries here, not scattered through the script. Annotate each with a one-line comment directly above the `source` call: a short role label followed by a comma-separated list of the names it provides (e.g., `# Output helpers: print_goal, print_req, print_pass, print_error`).
	- *A single `source` site is the only place to look for external symbols. The one-line shape keeps the annotation scannable; the listed names tell the reader what entered the namespace without opening the library.*
- One purpose per function. Name `verb_noun`, lowercase, underscores.
	- *Functions that do one thing are testable in isolation. `verb_noun` reads as intent in the main program: `check_input "$file"` needs no further explanation.*
- Define with `name() {`. Never `function name {` or `function name() {`.
- Separate each function from the next with two blank lines followed by a comment block. The function's purpose comment is that comment block.
	- *Two blank lines + a comment is the standard sibling-block separator.*
- Declare locals with `local`. Return status with `return N`; return values via stdout.
	- *Without `local`, every assignment leaks into the caller's scope and silently clobbers state. Bash functions can only return an integer 0–255 as status — text must travel through stdout.*
- Comment above each function with its purpose. Compact — one line when possible, more only when needed.
	- *A name plus a short intent line is all the next reader needs. Prose longer than the function body is a smell.*

Further research:
1. [BashProgramming: Functions](https://mywiki.wooledge.org/BashProgramming#Functions): definition syntax, scope, `local`, and return conventions in one place.
2. [BashFAQ/084: Returning values](https://mywiki.wooledge.org/BashFAQ/084): why `return` is for status and `echo`/`printf` is for data.

---

## Argument Parsing

<!-- Parsing mechanics are well-documented elsewhere. What basher pins is the happy path — one way to parse short flags, one place it lives in the anatomy, one pattern the operator sees every time. For anything outside the happy path, follow the link. -->

```bash
# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
# Print invocation help.
usage() {
    cat <<'EOF'
Usage: scripts/name-of-script.sh [-hv] [-o OUT] INPUT

  -h, --help         show this help
  -v, --verbose      verbose output
  -o, --output OUT   output directory (default: /tmp)
  INPUT              path to input file
EOF
}

# Parse flags and positional args; populate script-wide vars.
parse_args() {
    while :; do
        case "${1:-}" in
            -h|--help)    usage; exit 0 ;;
            -v|--verbose) verbose=true ;;
            -o|--output)
                [[ "${2:-}" ]] || print_error '--output requires a value'
                output_dir="$2"; shift
                ;;
            --)           shift; break ;;
            -?*)          usage >&2; exit 2 ;;
            *)            break ;;
        esac
        shift
    done
    : "${1?missing input file; see -h}"
    input_file="$1"
}


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
parse_args "$@"


# -----------------------------------------------------------------------------
# …first Goal…
```

Rules:
- **Terms.** A **flag** (option) is a token starting with `-` or `--` — `-v`, `--verbose`, `-o OUT`. A **positional** is a token that does not start with `-`, read by its order in `$@` (first is `$1`, second `$2`, …). The delimiter `--` ends option parsing; any token after it is positional even if it begins with `-`. A bare `-` is the conventional stdin filename (see the stdin rule below).
- **Flags precede positionals.** The parse loop breaks on the first non-option token, so flags that appear *after* a positional are silently ignored. Reflect this in the EXECUTE header line: write the invocation as `scripts/name.sh [-hv] [-o OUT] INPUT` — flags first, positionals last.
	- *The loop is linear by design: no backtracking, no state, no ambiguity. Intermixed flags-and-positionals is a feature of richer parsers (getopts with reordering, argbash); the reference's happy path trades that flexibility for predictability. "Flags first" is the operator contract, and it matches wooledge's recommended pattern.*
- **Validate flag-value presence.** A flag that consumes a value must guard that the value exists before assigning. Use `[[ "${2:-}" ]] || print_error '<flag> requires a value'` as the first line of the case branch.
	- *Without the guard, `--output` followed by nothing silently sets the variable to empty, and the script fails obscurely when it's used. The guard fails loudly at the parse stage with a named flag in the message. `print_error` + `return 1` propagates through `set -e`; no extra exit needed.*
- The happy path for scripts that accept flags is a `while :; do / case "$1" in … esac; shift; done` loop. Wrap it in a `parse_args()` function defined in FUNCTIONS, alongside a `usage()` helper. Call `parse_args "$@"` as the first executable line of MAIN.
	- *`while :; do` with `case` handles short flags, long flags, `--key value`, and `--` terminators in a single shape. It reads top-to-bottom, adds cases trivially, and requires no knowledge of `getopts` quirks.*
- Inside the loop, match `"${1:-}"` (not bare `"$1"`) in the `case` head. With `set -u` active, a bare `$1` fails the moment arguments run out.
	- *The loop terminates on `*) break` when `$1` is empty or a non-option; the `:-` default lets that match fire cleanly instead of aborting the script.*
- `parse_args "$@"` is the first executable line after MAIN's closing rule. Placement follows MAIN's two-shape rule: with `parse_args`, MAIN takes its own full three-line frame and two blank lines separate the call from Goal 1.
	- *Parsing is setup, not work. It doesn't belong inside a Goal. Giving MAIN its own frame here keeps the invocation visually separated from the narrative that follows.*
- `usage()` prints help to stdout on `-h` and to stderr on a parse error. Exit 0 from `-h`, exit 2 from any parse error.
	- *Help to stdout can be piped to `less`; errors to stderr stay visible under output redirection. Exit 2 is the POSIX convention for misuse, distinct from `print_error`'s exit 1 for application failure.*
- Required positional arguments consumed after the loop use the same assertion pattern as Variables (`: "${VAR?message}"`).
	- *One assertion style across the whole script. The operator sees the same shape of error whether the missing input was a flag, an env var, or a positional arg.*
- Scripts that read stdin accept `-` as a filename synonym for stdin and document the form in the header's EXECUTE line.
	- *`-` is the POSIX/GNU convention; `./script.sh -` and `cmd | ./script.sh -` behave the same. Document it in EXECUTE so the operator sees the invocation shape alongside the flag list.*

Further research:
1. [BashFAQ/035: Handling command-line arguments](https://mywiki.wooledge.org/BashFAQ/035): the authoritative reference — when `getopts` is enough, when to parse manually, and the trade-offs of each approach. Consult before deviating from the happy path above.
2. [ComplexOptionParsing](https://mywiki.wooledge.org/ComplexOptionParsing): extended patterns for when the happy path runs out — bundled short flags (`-xvf`), `--key=value` forms, option-argument tight-coupling, and other edge cases.
3. [argbash](https://argbash.io/): the Wooledge authors' recommended generator for non-trivial parsers. Writes the `while :; do / case` loop, usage text, and validation for you from a concise spec. Reach for it when the hand-written loop would be longer than the rest of the script.

---

## Main

<!-- MAIN is where the script does its work. It decomposes into Goals — sequential processing stages, each leaving state for the next — and each Goal decomposes into Requirements. Dividers address the source-reader (maintainer); `print_*` calls address the executor (operator). Two audiences, two strings — never combine them. -->

```bash
# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
# Normalize incoming HR records
# -----------------------------------------------------------------------------
print_goal 'Normalizing incoming HR records...'


# ---
# drop rows with missing phone numbers
# ---
print_req 'Dropping rows without a phone number...'
# ... body: whatever legal bash the REQ needs ...


# ---
# convert all phones to E.164
# ---
print_req 'Converting phone numbers to E.164...'
# ... body ...


# -----------------------------------------------------------------------------
# Emit enriched CSV
# -----------------------------------------------------------------------------
print_goal 'Writing enriched CSV...'


# ---
# write normalized records to disk
# ---
print_req 'Writing normalized records to disk...'
# ... body ...
```

Rules:
- MAIN is framed (see Section Frame) with the `MAIN` label.
- A script is a pipeline: input → process → output, chained. The operator provides a spark (arguments, env vars); Goal 1 transforms that input into state; each subsequent Goal consumes the prior Goal's output and produces the next input. The chain continues until the PURPOSE is met, then `fin~`.
	- *This is the Unix process model applied to script structure. Each Goal is a process box with input and output. Nothing is decorative — every operation is load-bearing in the chain.*
- MAIN contains one or more Goals. Each Goal is a sequential processing stage that leaves state for the next.
	- *Goals support the script's PURPOSE. A single-step script has one Goal; a three-stage pipeline has three.*
- Everything that serves one PURPOSE belongs in one script. When the PURPOSE changes, it's a new script. The test: if a Goal's purpose can be stated without mentioning the prior Goal, and the operator might reasonably invoke it separately, it belongs in a separate script.
	- *Combine: a backup script reads a file list, builds an archive, and emails it — three Goals, one PURPOSE ("back up and deliver these files"), each Goal consuming the prior Goal's output. Separate: a Vault deployment uses `one-time-setup.sh` (enable APIs), `cluster-build.sh` (create cluster), `gen-tls-certs.sh` (generate certificates), `deploy-vault.sh` (deploy pods) — four scripts, four PURPOSEs, each independently invocable and retryable. The PURPOSE is the dividing line — not size, not complexity, not taste.*
- Each Goal is framed (see Section Frame) in the prose-body form — a short `# Goal Purpose` line with optional `#  * detail` bullets. This block is written **for the maintainer reading the source** — describe what the Goal does, why, and any context the next author will need. Descriptive prose; can expand as context requires.
- Immediately after the closing 79-char rule, call `print_goal '…'`. The message is an active verb with trailing `...` — what's happening now (e.g., `'Normalizing HR records...'`). It addresses the operator watching the script run.
	- *Two audiences, two strings. The comment block explains; the `print_goal` narrates. Do not collapse them — the maintainer wants context, the operator wants a progress line.*
- After completing a Goal's REQs, re-read the Goal frame and `print_goal` message. If the work changed what the Goal actually does, update both to match the result.
	- *Implementation reveals what design assumed. The Goal message serves the result, not the plan — when the data says the description drifted, update the description.*
- MAIN's opener takes one of two shapes, determined by whether the script parses arguments:
	- **No `parse_args` call:** MAIN's closing rule is also Goal 1's top rule — one shared line, no gap. The MAIN label block and the first Goal's divider merge into a single five-line frame.
	- **With a `parse_args` call:** MAIN takes its own full three-line frame. `parse_args "$@"` follows MAIN's closing rule immediately (no blank line). Two blank lines then separate it from Goal 1's own three-line divider.
- Goals after the first always have their own full three-line divider, preceded by two blank lines — regardless of which opener shape MAIN used.
	- *Between any two Goals, the top-level-section separator applies. The opener-sharing is a one-time economy at MAIN's boundary; it never recurs between Goals.*
- Each Goal contains one or more REQs — discrete steps the Goal depends on.
	- *REQs support Goals the way Goals support the PURPOSE.*
- Goals and REQs share script-global variables. A REQ may depend on state established by any earlier REQ — within its own Goal or in any prior Goal — since execution is top-to-bottom sequential.
	- *A pipeline shape `A → B → C` is the norm: each REQ consumes what the previous one produced. Local-only state is the exception, achieved with `local` inside a function, not at REQ scope.*
- REQ divider: short three-line form `# --- / # label / # ---`. The label is a normative statement — what should be true when the REQ completes (e.g., `# download patch manifest`). It addresses the maintainer reading source.
	- *The label is a contract: "after this block, this thing is done." A bare identifier (`REQ1`) tells the reader nothing; a normative statement tells them what to verify.*
- Immediately after the closing `# ---`, call `print_req 'description...'`. The message is an active verb with trailing `...` — what's happening now (e.g., `'Downloading patch manifest...'`). It addresses the operator watching output.
	- *Two audiences, two forms. The divider comment is a contract for the maintainer; the `print_req` message is a progress signal for the operator. Same pattern as Goal frames and `print_goal`.*
- The REQ body follows `print_req`. Its content is outside the scope of these rules — a REQ may test a condition, run a command, transform data, loop, anything legal in bash.
	- *Constructs used inside a REQ (conditionals, loops, I/O) have their own sections in this reference.*

---

## Checks

<!-- Most REQs test a condition. The reference doesn't teach `[[ ]]` or `if` — the agent already has that. What needs saying is how the print helpers compose around the check: one announcement line, one test, one outcome call. Consistency here is what makes script output scannable across the whole codebase. -->

```bash
# ---
# create temp work space
# ---
print_req 'Creating temp working directory...'
tmp_dir="$(mktemp -d /tmp/target-XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT
if [[ -d "$tmp_dir" ]]; then
    print_pass
else
    print_error "temp directory was not created: $tmp_dir"
fi


# ---
# ensure required tools are present
# ---
print_req 'Verifying required tools...'
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        print_error "required tool not found: $tool"
    fi
done


# ---
# check host reachability on expected ports
# ---
print_req 'Checking host reachability on expected ports...'
while IFS= read -r line; do
    check_port "$addr" "$port" \
        || print_error "$host: port $port unreachable" || true
done < "$hosts_file"
```

Rules:
- Test whenever possible. Every operation that can fail should be tested. The operator needs to see what passed, what failed, and why. A `print_pass` that wasn't tested is a lie; a silent success is invisible.
- Fail first, earn success. Test for the negative (`if !`) and include an `else` for the success path. Give the script every opportunity to fail before reporting success. Code that survives a gauntlet of failure tests deserves to be in production; code that only checked the happy path doesn't.
	- *The two rules above govern all checks. The shapes below are the implementation.*
- Every REQ that performs a check uses one of exactly two shapes. No others.
	- **Shape A — Both outcomes.** `print_req` announces, an `if` tests a value, `print_pass` on success, `print_error "reason"` on failure. Use when the conditional can succeed or fail and both branches need reporting.
	- **Shape B — Check-is-command.** `print_req` announces, the command itself is the test, only failure is announced: `if ! command; then print_error 'reason'; fi`. Use when the command's success has no value to verify — continued execution under `set -euo pipefail` is the success signal.
- `print_pass` takes no arguments. The `print_req` above it already named what was tested.
	- *Two strings saying the same thing is noise. The helper prints a short success marker; the reader's context is the REQ description one line up.*
- `print_error` takes a short reason — one line, a fragment that completes the sentence "it failed because…", fitting within the 79-char limit after the banner's centering padding. It prints a banner to stderr and returns 1; under `set -euo pipefail`, the non-zero return propagates and halts the script. Do not add `exit` after it — `print_error` is the single termination mechanism for application failures (see §Printer Library for the contract). This holds inside `if`/`then` bodies: the `if` condition is protected from errexit, but statements within the branches are not.
	- *The reason is the one piece of information the operator doesn't already have. Keep it short; the banner does the visual work. `return 1` rather than `exit 1` lets a caller that wants to continue past a reported error suppress errexit locally with `|| true` (see the per-iteration loop rule below).*
- **Per-iteration reporting inside a loop.** When the script should continue through per-iteration failures (report all bad items, not halt on the first), suppress `print_error`'s errexit propagation with a trailing `|| true`. Two forms match Shape A and Shape B:
	- **Compact (Shape B, loop body):** `cmd || print_error "<reason>" || true` — test, report, continue. Use when "report and keep going" is the entire failure action.
	- **Structured (Shape A, loop body):** `if cmd; then …; else print_error "<reason>" || true; …; fi` — the `else` branch has room for multiple statements (accumulate into an array, retry, log detail).
	- *Each loop iteration is a check; the loop wraps them. `|| true` neutralizes `print_error`'s `return 1` per-iteration so `set -e` doesn't halt the script. Without the loop wrapper, `print_error` still halts — which is the correct behavior for fail-fast REQs outside a loop. Compact when simple; Structured when the failure branch needs room to grow.*
- Use the `if / then / else / fi` block form in Shape A. Never `cmd && print_pass || print_error "…"`.
	- *Block form reads top-to-bottom: test, pass path, fail path. The `&&/||` one-liner looks equivalent but isn't — if `print_pass` ever returns non-zero, the `||` fires. The block form has no such trap.*
- Do not redirect print helpers. `print_goal`, `print_req`, `print_pass` go to stdout; `print_error` goes to stderr. The helpers manage their own streams.
	- *Stream discipline is part of their contract. Piping `print_error` to stdout breaks the operator's ability to separate progress from failures with a single `2>errors.log`.*

Further research:
1. [BashFAQ/105: errexit pitfalls](https://mywiki.wooledge.org/BashFAQ/105): why the block form is safer than `&&/||` chains under `set -e`.

---

## Report

<!-- A script that alters state can summarize what it did. REPORT is the optional closing section that emits that summary, for the executor, after MAIN completes. -->

Rules:
- REPORT is optional. The decision to include it belongs to the maintainer, who runs the script and judges whether the summary adds value. This reference does not prescribe when; only how, if present.
	- *Inclusion is operator-context-specific. The maintainer has that context; basher does not.*
- When included, REPORT is framed (see Section Frame) with the bare label `REPORT` — the label form only; no purpose line, no detail bullets. Placement: after MAIN, before exit.
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
	- *`exit 0` is explicit success, independent of whatever the last command returned.*
- Sourced libraries (`*.func` files) use `return 0` in place of `exit 0`. Everything else about the closer is the same.
	- *`exit` from sourced code terminates the caller, not the library. `return` leaves the sourced scope and hands control back to the script that sourced it — the correct terminator for a library.*
- All application failures go through `print_error` (exit 1); reserve other non-zero codes for documented contracts.
	- *Exit 2 is argument-parsing error (§Argument Parsing). Anything beyond 0, 1, 2 is a contract with a specific caller and needs to be named — undocumented codes look like bugs.*

---

## Examples

<!-- Concrete patterns, tagged. The body of the reference teaches primitives; this appendix shows primitives composed into real sysadmin idioms. Scan the tags for the pattern that matches the task at hand. -->

### Config-file convergence

**Tags:** #idempotent · #config-drift · #declarative

Check the target state; act only on what's missing; report both outcomes. Re-runnable to convergence without side effects — the script is its own convergence check.

```bash
# diff-first dispatch: cheap check, expensive remediation only when needed
if ! diff "$target_config" "$spec_file" >/dev/null; then
    while IFS= read -r line; do
        [[ "$line" = \#* ]] && continue
        key="${line%% = *}"
        print_req "process $key"
        if ! grep -qF -- "$key" "$target_config"; then
            sed -i "/$anchor/a\\ $line" "$target_config"
        fi
        print_pass
    done < "$spec_file"
fi
```

**Primitives used:** §Checks (`print_req` per iteration, bare `print_pass` on success), §Parameter Expansion (`${line%% = *}` extracts the key from a `key = value` line without forking), §Loops (`while read` over a spec file of unknown length), §Redirection (`diff … >/dev/null` as a pure comparison oracle), §External Tools (`grep -qF` for literal, quiet existence check).

**See also:** [Ansible `lineinfile` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html) — the formal version of this pattern with `insertafter` anchors and idempotent state management.

---
