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
	- `scripts/lib/printer.func` — shared output helpers: `print_goal`, `print_req`, `print_pass`, `print_info`, `print_error`.
	- *Two files, one unit. The template sources the printer; the printer's helpers drive every script's visible output.*
- Every compliant script sources the printer: `source scripts/lib/printer.func`.
	- *The Main-program conventions (announcing goals, reporting pass/fail) presuppose these helpers. A script that doesn't source them exits the scope of this reference.*
- Downstream projects mirror the layout — `scripts/template.sh` and `scripts/lib/printer.func` at the project root, every time.
	- *One convention across basher and its users. Every project has the same two files at the same two paths.*

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
- Keep every line — code, comments, output — under 80 characters. The 79-char section rules and `# ---` sub-block markers are instances of the same discipline.
	- *The constraint is the worst plausible terminal, not the author's. One wrap-imposed line break destroys alignment, indentation, and the reader's ability to scan.*
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
printf '\n\n%s\n' """

Post-run report:

* removed thing:  success
* modified thing: success
* added thing:    success

logged: /tmp/script-purpose.log

"""
```

Further research:
1. [BashFAQ/032: printf](https://mywiki.wooledge.org/BashFAQ/032): formatted output, the preferred tool over `echo` for anything non-trivial.
2. [HereDocument](https://mywiki.wooledge.org/HereDocument): `cat <<EOF` as the alternative multi-line construct.

---

## Indentation

<!-- Indentation is a preference in most places. It is not a preference in any place where whitespace changes execution — there it is part of the code's behavior. -->

Rules:
- basher scripts default to 4-space indentation in every committed artifact — template, examples, produced scripts.
	- *One choice across the kit. Agents producing new scripts emit 4 spaces without further ceremony.*
- When modifying an existing script, match its indentation. Do not retab as a side effect.
	- *The author of a script has the right to their own convention. Changing it silently pollutes the diff and disrespects the choice.*
- Within any one script, one depth and one whitespace choice (spaces or tabs), applied consistently.
	- *Mixed indentation renders unpredictably across editors and breaks alignment of comments and continuations.*
- Never reformat whitespace in a way that alters execution. Heredoc body lines, line-continuation trailing whitespace, and string literals are code, not style.
	- *`<<EOF` emits body lines verbatim, leading whitespace included. `<<-EOF` strips leading tabs only — not spaces. A `\` line continuation requires the backslash to be the last character on the line. Reformatting these silently changes output or breaks the parse.*

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
#  EXECUTE: ./script.sh [args]                              # how to invoke it
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
- `EXECUTE` shows the exact invocation.
	- *Copy-pasteable usage prevents misuse. "How do I run this?" should never be a question.*

Further research:
1. [ShellCheck directive reference](https://www.shellcheck.net/wiki/Directive): valid directives and placement.
2. [BashGuide: Practices](https://mywiki.wooledge.org/BashGuide/Practices): broader script hygiene.

---

## Variables

<!-- Scattered assignments make scripts hard to tune and impossible to debug by inspection. One block, up top, lets you change behavior in one place and trace every expansion with `set -x`. -->

```bash
# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------
# ENV — required external inputs, assert early
: "${API_TOKEN?  API_TOKEN is missing!}"
: "${1?  first argument required: path to input file}"

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
- Wrap the block in 79-char `# ---` rules (`# ` + 77 dashes) with a `VARIABLES` label. The same pattern names every top-level section: `HEADER`, `VARIABLES`, `FUNCTIONS`, `MAIN`. The rule block *is* the section title — there is no prose heading above it.
	- *The rule block is the script's hardest visual break: "new phase starts here." Nothing else in the script uses that pattern.*
- Separate top-level sections with two empty lines before the rule block.
	- *Two blank lines + full-width rule is the top-of-hierarchy separator. Sub-blocks (individual functions, individual requirements in MAIN) use two blank lines + a narrower comment block — never the full rule.*
- The first line of content follows the section title immediately — no blank line between the closing rule and the first comment or statement.
	- *The title and its body are one unit. A gap would suggest another separator level that doesn't exist.*
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
# Output helpers: print_goal, print_req, print_pass, print_info, print_error
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
- Wrap the block in 79-char `# ---` rules (`# ` + 77 dashes) with a `FUNCTIONS` label — the same full-width title pattern used by `HEADER`, `VARIABLES`, and `MAIN`. Two blank lines precede the rule block; the first line of content follows immediately with no blank line.
	- *Consistent top-level separator across every section. The script reads as HEADER → VARIABLES → FUNCTIONS → MAIN, always, with the same visual weight between them.*
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

<!-- MAIN is where the script does its work. It decomposes into Goals — sequential processing stages, each leaving state for the next — and each Goal decomposes into Requirements. The hierarchy is visible in the dividers. -->

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
- MAIN is a top-level section titled by a 79-char rule block — same visual weight as VARIABLES and FUNCTIONS.
	- *The script's structural sections all read as equals.*
- MAIN contains one or more Goals. Each Goal is a sequential processing stage that leaves state for the next.
	- *Goals support the script's PURPOSE. A single-step script has one Goal; a three-stage pipeline has three.*
- Goal divider: 79-char rules both sides, a short `# Goal Purpose` title, optional `#  * detail` bullets for the maintainer. Goals get the same visual weight as top-level sections.
	- *The divider is the source-reader's view — descriptive, can expand into bullets when context helps.*
- Immediately after the closing 79-char rule, call `print_goal 'verb-form announcement'` — for the executor.
	- *Two audiences, two strings. The divider describes; `print_goal` announces. Never combine them.*
- The first Goal's top rule is MAIN's closing rule — they share a single line, no blank space between MAIN's label and the first Goal's label.
	- *MAIN's closing rule already provides the separator; adding a second rule would be doubled weight for no reader benefit. The section title and its first Goal compress into one unit.*
- Subsequent Goals have their own opening rule, preceded by two empty lines.
	- *Top-level-section separator applied between Goals that don't share a boundary with MAIN.*
- Each Goal contains one or more REQs — discrete steps the Goal depends on.
	- *REQs support Goals the way Goals support the PURPOSE.*
- REQ divider: short three-line form `# --- / # REQN / # ---`. The label is the bare sequential identifier — `REQ1`, `REQ2`, … — and nothing else. Never concatenate it with a purpose string.
	- *The REQ's purpose lives in `print_req`, not in the divider. The divider identifies; `print_req` describes.*
- REQ numbering resets per Goal. Each Goal's first REQ is `REQ1`.
	- *REQs are scoped to their Goal. Per-Goal numbering lets Goals be reordered without renumbering the script.*
- Immediately after the closing `# ---`, call `print_req 'description'` — for the executor.
	- *Same two-audience rule as Goals. `REQ1` identifies to the source-reader; `print_req` describes to the operator.*
- Two empty lines precede every REQ's opening `# ---`.
	- *Sibling-block separator within a Goal.*
- The REQ body follows `print_req`. Its content is outside the scope of these rules — a REQ may test a condition, run a command, transform data, loop, anything legal in bash.
	- *Constructs used inside a REQ (conditionals, loops, I/O) have their own sections in this reference.*

---

## Report

<!-- A script that alters state can summarize what it did. REPORT is the optional closing section that emits that summary, for the executor, after MAIN completes. -->

Rules:
- REPORT is optional. Include it when the operator needs confirmation of execution stats (counts, outcomes, produced paths). Omit it otherwise.
	- *The trigger is the operator's need for confirmation, not merely the existence of outcomes. A script can do meaningful work and still not warrant a summary if no one is waiting on the numbers.*
- When included, REPORT is a top-level section titled by a 79-char rule block with the bare label `REPORT` — no descriptive purpose line, no detail bullets. It sits after MAIN and before the closing exit.
	- *Goals carry a unique purpose because each one does something different. REPORT's purpose is always the same — surface execution stats to the operator — so the label alone is enough. The `(optional)` qualifier in `template.sh` is meta-info for the template reader; drop it in actual scripts.*
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
- Close every script with a three-line `# --- / # fin~ / # ---` marker, then `exit 0` immediately below — no blank line between them.
	- *`# fin~` is an artistic expression — the script's deliberate close, written by someone who cares how it reads. `exit 0` is the graceful terminator: explicit success, independent of whatever the last command returned.*
- Two empty lines precede the opening `# ---` of the marker.
	- *Same sibling-block separator used throughout. The marker is the script's final sibling.*
- The marker and `exit 0` are the last lines of the file. Nothing follows them.
	- *A trailing newline is fine; a trailing comment, unreachable code, or additional statement is not.*

---
