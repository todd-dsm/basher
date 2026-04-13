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

---

## 2026-04-11

### Added
- Project initialized with Cascadian framework (Archetype A — new project)
- CLAUDE.md, etc/rules-project.md, etc/manifest.md, docs/development-record.md
- share/plugin.md (software plugin), share/plugins/ (full catalog)
- share/agents/ (dormant agents for non-default plugins)
