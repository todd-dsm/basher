# basher

A helper for the agents so they create GNU Bash scripts like UNIX sys-admins. For more detailed info read [the docs](docs/readme.md).

## Why

AI coding assistants generate shell scripts that work but, without additional prompting they tend towards a very pythonic way of writing. They miss `set -euo pipefail`, use antipatterns like parsing `ls`, and produce brittle constructs that break in production. **basher** gives them a single-file reference of correct, idiomatic Bash so they produce better scripts from the start.

## What

Point your agent towards the `reference.md` file, one fetch, one source of truth. 
- 95% functional constructs (loops, conditionals, functions, error handling, I/O, variables) as concrete "do this, not that" pairs. 
- 5% educational via inline comments that double as context for the caller.

## License

[TBD]
