# Development Record

## Purpose

Evidence of activities performed during basher development (ISO/IEC/IEEE 15289:2019 Record). Most recent first. Categorized by kind: Added, Changed, Fixed, Removed, Moved. Maintained by the scribe as part of session exit criteria.

---

## 2026-04-12

### Added
- `reference.md` sections: Quoting, Section Frame, Error Mode, Argument Parsing, Checks
- `share/printer.func` — canonical printer library (print_goal, print_req, print_pass, print_error); 79-char borders; `return 0` closer for sourced use
- `etc/rules-project.md` sections: Version Tags, Authoring Principles (happy-path-first, CA-perspective test)
- `tmp/review-remaining.md` — unfinished items from formal review
- Annotated tag `v0.0.0-base` at commit `f8152c3`

### Changed
- `reference.md` consistency/ambiguity/redundancy pass per sme-math review (14 findings applied): full-rule width normalized to 79 chars; MAIN stated as two explicit shapes (with/without `parse_args`); Checks stated as two named shapes (Shape A both-outcomes, Shape B check-is-command); "blank line" standardized and anchored to `^$`; PREREQS functional test ("if the script won't run properly without it, it's a prerequisite"); foreign-script carve-out concretely defined; quoting/assertion duplications removed; REPORT inclusion trigger removed as out-of-scope (maintainer judgment)
- Top of `reference.md` adds consumption rule for the calling agent: use the example; follow Further-research links if it doesn't fit; do not improvise

### Removed
- `print_info` from Starter Kit and Functions examples (deferred; not present in printer.func)
- REPORT inclusion-trigger rule (judgment call outside reference scope)

### Added (corpus recon)
- `/tmp/tally/` — pattern tally from 2,234 *.sh files across `/tmp/reference/` (~30 years of sysadmin scripts); supersededs pruned to reflect current project style
- `reference.md` §Quoting: command-substitution `"$(cmd)"` in DO/DON'T block; brace-adjacency rule (brace when adjacent to word chars, digits, or parameter operators)

### Changed (corpus recon)
- `reference.md` §Variables casing rule: tightened to `snake_case` for locals + `UPPER_CASE` for exports/constants; `camelCase` explicitly retired (snake_case is the UNIX convention; matches tool-surface consistency)
- `reference.md` §Functions: added function-form rule retiring the `function` keyword (POSIX `name() {` form only)
- `reference.md` §Starter Kit: removed `scripts/template.sh` from the promise (template is constructed per project from the reference; printer.func is the only shipped artifact)

### Added (corpus recon, continued)
- `reference.md` §Parameter Expansion — new section teaching the CA the concept and pointing at wooledge BashGuide/BashFAQ (default, prefix/suffix strip, arithmetic examples; "don't improvise beyond the shapes shown")
- `reference.md` §Redirection — new section covering silence (`>/dev/null 2>&1`, not `&>`), envsubst templating, heredocs (quoted vs unquoted delimiter), herestring, process substitution; cites unix.SE/a/119650 and BashGuide/InputAndOutput
- `reference.md` §Loops — new section; `while IFS= read -r` first (unknown-size streams), `< <(cmd)` process-substitution pairing to preserve loop-body scope, `for x in "${arr[@]}"` last (known bounded arrays); cites BashFAQ/001 and BashGuide/TestsAndConditionals
- `reference.md` §Redirection: added UUOC rule (`cmd <file` instead of `cat file | cmd`)
- `reference.md` §External Tools — new section (DO/DON'T format) covering `find -exec {} +` vs `\;`, `-print0 | xargs -0` null-safety, curl `-fsSL` flag set, download-and-extract pipe to tar; macOS Darwin `-exec +` early-exit caveat; cites wooledge UsingFind §7, BashFAQ/119, curl manpage
- `reference.md` §Pipelines — new section naming the distinctive idioms: leading-pipe continuation, `| tee` invocation convention, `yes | cmd` batch-confirm, `grep "[x]foo"` self-exclusion trick, `curl | bash` vendor-installer caveat; dry-run note for `xargs kill`; cites GNU Bash manual Pipelines, man tee/yes/pgrep
- `reference.md` §Temp Files — new section; `mktemp -d /tmp/name-XXXXXX` + paired `trap 'rm -rf "$tmp"' EXIT` as the security-aware ephemeral-artifact shape; bans hand-rolled `/tmp/$$.tmp`; cites man mktemp, BashFAQ/062

---

## 2026-04-11

### Added
- Project initialized with Cascadian framework (Archetype A — new project)
- CLAUDE.md, etc/rules-project.md, etc/manifest.md, docs/development-record.md
- share/plugin.md (software plugin), share/plugins/ (full catalog)
- share/agents/ (dormant agents for non-default plugins)
