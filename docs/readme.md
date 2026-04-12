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

### Recommended ShellCheck config

basher scripts are invoked from the repo root, so sourced paths like `source scripts/lib/printer.func` resolve against the caller's CWD — not the script's file location. ShellCheck's SC1091 check doesn't recognize this convention and reports a false positive on every compliant basher script.

Silence it globally by creating `~/.shellcheckrc`:

```bash
echo 'disable=SC1091' >> ~/.shellcheckrc
```

A per-project `.shellcheckrc` at the repo root works just as well if you'd rather not change home-dir config.

### Clone and verify

```bash
git clone git@github.com:todd-dsm/basher.git
cd basher
shellcheck --version   # verify >= 0.9
```
