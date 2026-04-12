# Bash Reference

A single-file reference of GNU Bash constructs for AI coding assistants.

<!-- Consumption: fetch this file raw from GitHub. One file, one source of truth. -->
<!-- Structure: each section is a self-contained construct with "do this, not that" pairs. -->

The code blocks in this file are the answer. Use them directly.

For edge cases or deeper understanding, each section links to [Wooledge](https://mywiki.wooledge.org/): the authoritative reference for all shell operations.

---

## Shebang

<!-- Without a correct shebang, the script runs under the wrong interpreter, or not at all. -->

```bash
# DO
#!/usr/bin/env bash

# DON'T
#!/bin/bash        # hardcoded path: breaks on NixOS, FreeBSD, some containers
#!/bin/sh          # POSIX sh, not Bash: no arrays, no [[ ]], no process substitution
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
  # shellcheck disable=SC2317     # functions invoked via trap look unreachable to the linter
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

# Data — structured inputs the script reads
hosts_csv='etc/hosts.csv'
```

Rules:
- One block, near the top, after the header. No late `foo=bar` buried in the main program.
	- *A single block is the only place you look to change behavior or audit inputs. Debugging with `set -x` then traces every expansion against a known set.*
- Wrap the block in 78-char `# ---` rules with a `VARIABLES` label. Same for every top-level section.
	- *The rules break a long script into scannable regions. Without them, a 300-line script reads as one wall of code.*
- Assert required inputs with `: "${VAR?  message}"`. The script exits immediately if unset.
	- *Failing at the top with a named variable beats failing 200 lines later with a cryptic unbound-variable error or — worse — silent wrong behavior on an empty expansion.*
- Group by origin: ENV (external), sourced (shared), local assignments, data pointers. Keep the grouping even if a group is empty.
	- *The shape of the block tells the next reader what the script depends on at a glance. An empty group is a truthful "none," not clutter.*
- Quote assignments with lowercase names. Reserve `UPPER_CASE` for exported/environment variables.
	- *Convention from POSIX forward. Mixing cases makes `set -x` output harder to scan.*

Further research:
1. [BashGuide: Parameters](https://mywiki.wooledge.org/BashGuide/Parameters): assignment, scoping, and expansion basics.
2. [BashFAQ/073: Parameter expansion](https://mywiki.wooledge.org/BashFAQ/073): the `${var?}`, `${var:-default}`, `${var:=default}` family.

---
