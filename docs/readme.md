# basher Documentation

## How to Use

### Claude Code (Cascadian users)

The Cascadian bash skill fetches `reference.md` automatically at invocation.

### Claude Code (standalone)

Copy the skill file from `support/claude/` into your project's `.claude/` directory:

```bash
cp support/claude/bash-style.md .claude/commands/bash-style.md
```

### Codex

See `support/codex/` for integration instructions.

### Other AI tools

Fetch the raw reference directly:

```
https://raw.githubusercontent.com/todd-dsm/basher/main/reference.md
```

### Humans

Read `reference.md` on GitHub. That's it.

## Quick Start (Contributors)

### Required Tools

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Git | >= 2.0 | `brew install git` or [git-scm.com](https://git-scm.com/downloads) |
| ShellCheck | >= 0.9 | `brew install shellcheck` or [shellcheck.net](https://www.shellcheck.net/) |

Admin/sudo permissions may be required if these tools are not already installed — arrange access before starting.

### Clone and verify

```bash
git clone git@github.com:todd-dsm/basher.git
cd basher
shellcheck --version   # verify >= 0.9
```
