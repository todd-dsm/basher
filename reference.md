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
