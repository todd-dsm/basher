# Syllabus

Constructs to cover in `reference.md`. Move items from here into `reference.md` as each section is written. When this file is empty, the reference is complete.

## Preamble
- [x] Shebang
- [x] Strict mode (`set -euo pipefail`, IFS)
- [x] Script header

## Variables & Data
- [ ] Variable declaration (naming, `local`, `readonly`, `declare`)
- [x] Quoting (single vs double vs escaped)
- [ ] Parameter expansion (`${var:-default}`, `${var%pattern}`, etc.)
- [ ] Command substitution (`$(...)` vs backticks)
- [ ] Arithmetic (`$(( ))`, `(( ))`)

## Conditionals
- [ ] Test constructs (`[[ ]]` vs `[ ]` vs `test`)
- [ ] File tests (`-f`, `-d`, `-r`, etc.)
- [ ] String comparison
- [ ] Numeric comparison
- [ ] if / elif / else
- [ ] case

## Loops
- [ ] for (C-style, list iteration, range)
- [ ] while / until
- [ ] Read loops (`while IFS= read -r`)

## Collections
- [ ] Indexed arrays
- [ ] Associative arrays

## Functions
- [ ] Function declaration
- [ ] Arguments and `$@` vs `$*`
- [ ] Return values and exit status
- [ ] Local scope

## I/O
- [ ] Redirection (`>`, `>>`, `<`, `2>&1`)
- [ ] Pipes
- [ ] Heredocs & herestrings
- [ ] Process substitution (`<(...)`, `>(...)`)
- [ ] printf vs echo

## Expansion & Globbing
- [ ] Brace expansion
- [ ] Pathname expansion / globs
- [ ] Word splitting (and how to prevent it)

## Error Handling
- [ ] Exit codes (`$?`, meaningful exit codes)
- [ ] trap (EXIT, ERR, signals)
- [ ] Error propagation (pipefail nuances)

## Script Interface
- [ ] Argument parsing (`getopts`, positional params)
- [ ] Usage / help output
- [ ] Environment variables

## Advanced
- [ ] Subshells vs command grouping (`( )` vs `{ }`)
- [ ] Here-strings for safe input
- [ ] Signal handling
- [ ] ShellCheck-driven discipline
