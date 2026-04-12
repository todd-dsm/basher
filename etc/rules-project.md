# Project-Specific Rules

## Aim

A public reference of GNU Bash constructs that makes AI coding assistants produce sysadmin-quality shell scripts. The product is `reference.md` — a single-file, fetch-once source of truth consumed by AI tools via raw.githubusercontent.com.

## Domain Constraints

- Single-file product (`reference.md`) — all constructs in one document, no splitting
- 95% functional constructs (loops, conditionals, functions, error handling, I/O, variables) — concrete "do this, not that" pairs
- 5% educational via inline comments that double as context for the AI caller
- Public repo, always — no private forks, no access gates
- No GitHub Pages, no submodules, no local copies
- Consumption model: raw fetch from GitHub (raw.githubusercontent.com)
- `support/` directory provides drop-in integrations for AI tools (Claude Code, Codex, etc.)

## Technical Decisions

- **Markdown as delivery format**: reference.md is Markdown with fenced Bash code blocks. Parseable by any AI tool, readable by humans on GitHub.
- **No build step**: the repo IS the product. No compilation, no generation, no CI artifacts.
- **Fetch, don't bundle**: consumers fetch reference.md at invocation time. No vendoring, no caching layers.
- **Section format**: every construct in reference.md follows the anatomy defined in [reference-format.md](reference-format.md).

## Environment Prerequisites

Git >= 2.0

```shell
brew install git
```

Or download from [git-scm.com](https://git-scm.com/downloads).

ShellCheck >= 0.9 (for validating example snippets)

```shell
brew install shellcheck
```

Or download from [ShellCheck](https://www.shellcheck.net/).

**One-time check**: After all tools pass, the agent writes `.prereqs` to the project root (gitignored — per-machine state) with a single line: `installed: git, shellcheck` listing what was verified. Future sessions compare `.prereqs` against this section — if it's a 1:1 match, skip straight to implementation.

## Non-Functional Testing

| Test Type | Enabled | Profiles |
|-----------|---------|----------|
| Security  | no | — |
| Performance | no | — |
| Reliability | no | — |
| Usability | no | — |
| Accessibility | no | — |

## Merge Criteria

- [ ] PE conformance assessment complete (tmp/conformance.md)
- [ ] PM final review approved
- [ ] All Bash examples pass ShellCheck
- [ ] reference.md is valid Markdown (no broken fenced blocks)

## Review Archive

- **disabled** (default): `rm -rf tmp/*` after summation in development-record.md.

## Active Context

- Project initialized. No features built yet.
- Backlog: design reference.md structure, create support/ integrations
