# Bash Reference

A single-file reference of GNU Bash constructs for AI coding assistants.

<!-- Consumption: fetch this file raw from GitHub. One file, one source of truth. -->
<!-- Structure: each section is a self-contained construct with "do this, not that" pairs. -->

## Shebang

<!-- Every script starts here. The shebang tells the kernel which interpreter to use. -->

```bash
# DO
#!/usr/bin/env bash

# DON'T
#!/bin/bash        # hardcoded path — breaks on NixOS, FreeBSD, some containers
#!/bin/sh          # POSIX sh, not Bash — no arrays, no [[ ]], no process substitution
```

RULES:
- Use `#!/usr/bin/env bash`. No other form.
	- *Bash lives at different paths across systems. `env` finds it in `$PATH`.*
- Line 1, byte 0. Nothing before it.
	- *The kernel expects `#!` at the start of the file. Anything before it and the shebang is ignored.*

---
