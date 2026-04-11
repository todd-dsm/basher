# Plugin: software

## Purpose

Software development — building, testing, and shipping production code. This plugin adds implementation and security agents, test profiles for common software archetypes, and process gates for safe merging and deployment.

## Agents

- agents/full-stack.md
- agents/security.md

## Test Profiles

- etc/test-profiles/global.md
- etc/test-profiles/binary.md
- etc/test-profiles/infra.md
- etc/test-profiles/library.md
- etc/test-profiles/web-app.md

## Process Modifications

- Phase 4 (Verification): Security agent runs test profiles in parallel with QA. CRITICAL/HIGH findings halt the line.
- Phase 6 (Commit): Security smoke test — no secrets in staged files, no debug flags in production config.
- Phase 7 (Merge): Requires /merge-to-main skill (decision 0014). Direct `git merge main` is blocked by hook.
