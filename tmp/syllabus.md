# Syllabus

Constructs to cover in `reference.md`. Move items from here into `reference.md` as each section is written. When this file is empty, the reference is complete.

`NA:` prefix = the calling agent already knows the mechanics and basher has no style guidance to add. Left in place as a ledger of what was considered and consciously skipped.

## Preamble
- [x] Shebang
- [x] Strict mode (`set -euo pipefail`, IFS)
- [x] Script header

## Variables & Data
- [ ] NA: Variable declaration (naming, `local`, `readonly`, `declare`) — covered in Variables + Functions
- [x] Quoting (single vs double vs escaped)
- [ ] NA: Parameter expansion (`${var:-default}`, `${var%pattern}`, etc.)
- [ ] NA: Command substitution (`$(...)` vs backticks)
- [ ] NA: Arithmetic (`$(( ))`, `(( ))`)

## Conditionals
- [ ] NA: Test constructs (`[[ ]]` vs `[ ]` vs `test`)
- [ ] NA: File tests (`-f`, `-d`, `-r`, etc.)
- [ ] NA: String comparison
- [ ] NA: Numeric comparison
- [ ] NA: if / elif / else — style covered in Checks
- [ ] NA: case

## Loops
- [ ] NA: for (C-style, list iteration, range)
- [ ] NA: while / until
- [ ] NA: Read loops (`while IFS= read -r`)

## Collections
- [ ] NA: Indexed arrays — quoting already covered `"${arr[@]}"`
- [ ] NA: Associative arrays

## Functions
- [ ] NA: Function declaration — covered in Functions
- [ ] NA: Arguments and `$@` vs `$*`
- [ ] NA: Return values and exit status — covered in Functions
- [ ] NA: Local scope — covered in Functions

## I/O
- [ ] NA: Redirection (`>`, `>>`, `<`, `2>&1`)
- [ ] NA: Pipes — pipefail covered in Error Mode
- [ ] NA: Heredocs & herestrings — heredoc covered in Line Width
- [ ] NA: Process substitution (`<(...)`, `>(...)`)
- [ ] NA: printf vs echo — reference consistently uses printf

## Expansion & Globbing
- [ ] NA: Brace expansion
- [ ] NA: Pathname expansion / globs — covered by Quoting
- [ ] NA: Word splitting (and how to prevent it) — covered by Quoting

## Error Handling
- [ ] NA: Exit codes (`$?`, meaningful exit codes)
- [ ] NA: trap (EXIT, ERR, signals) — revisit if a real script makes placement unclear
- [ ] NA: Error propagation (pipefail nuances)

## Script Interface
- [x] Argument parsing (`getopts`, positional params)
- [x] Usage / help output
- [ ] NA: Environment variables — covered in Variables (ENV group)

## Advanced
- [ ] NA: Subshells vs command grouping (`( )` vs `{ }`)
- [ ] NA: Here-strings for safe input
- [ ] NA: Signal handling — see trap
- [ ] NA: ShellCheck-driven discipline — covered in Script Header + docs/readme
