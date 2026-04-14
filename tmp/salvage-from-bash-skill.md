# Salvage from cascadian:bash skill backup

**Status:** deferred — to be addressed in a later session.

**Source:** `/Users/work/code/cascadian/tmp/bash.bak` — archived copy of `skills/bash/SKILL.md` captured 2026-04-13, before the skill was slimmed per `docs/skill-contract.md`. The backup's first lines state: *"ARCHIVED COPY — NOT ACTIVE. Pre-basher-contract snapshot."*

**Context:** the skill was slimmed down (removing duplicated style content that `reference.md` already owns). Five distinct pieces of original content in the backup were **not** duplicates of basher's reference — they're net-new patterns or operational content worth migrating before discarding the backup.

## Candidate migrations

### 1. Output Patterns — three tagged §Examples entries (high value)

Backup lines 159-209. Three named script shapes with distinct noise levels:

- **`#validation`** — *Succeed Quietly, Fail Loudly*. For scripts run often with >95% success rate. Silent on success; only failures produce output.
- **`#generation`** — *Silent Operations, Show Deliverable*. For config-file generators using envsubst. All ops silent; final `cat` shows the produced artifact as the value.
- **`#creation`** — *Verbose*. For state-changing operations. Announce every step via `print_goal` / `print_req`.

**Destination:** `reference.md` §Examples, one tagged entry per pattern.

### 2. Graceful Handling of Missing Resources — `#graceful-skip` (medium value)

Backup lines 344-358. Pattern for iterating external resources (vault, k8s, cloud APIs) where some entries may legitimately not exist. Check-before-operate with `&>/dev/null`; skip gracefully on expected-absent, fail-fast on unexpected errors.

**Destination:** `reference.md` §Examples, tagged `#graceful-skip`.

### 3. Summary Output for Operators — `#operator-summary` (medium value)

Backup lines 360-378. Counts + warnings at end of a processing loop. "Counts + warnings = confidence." Specifically for iterative scripts — more concrete than §Report's general guidance.

**Destination:** `reference.md` §Examples, tagged `#operator-summary`.

### 4. Pre-authoring / pre-execution / failure protocol (high value — skill-side)

Backup lines 265-279 and 296-304. Concrete safety checklists:

**Before authoring:** understand the requirement, check for similar existing script, identify prereqs, plan for idempotency.

**Before executing:** `bash -n` syntax check, shellcheck zero warnings, test in safe environment, ring bell before destructive ops.

**Failure protocol:** syntax error → fix; logical error → ring bell + explain; unclear requirement → ring bell + ask; destructive op → ring bell + approval gate.

**Destination:** `docs/skill-contract.md`, new subsection under "Skill's responsibilities" (or adjacent). Currently `skill-contract.md` names safety protocol generically; these give the concrete sequence.

### 5. "Build for the target, not the workbench" (low value — principle)

Backup line 60. Rationale for preferring GNU tools: production runs on Linux; don't style around the developer's macOS workbench. Cited as "Universal Rule 6" in the backup.

**Destination:** `etc/rules-project.md` §Engineering Principles as a one-line mnemonic, OR inline note in `reference.md` §External Tools near the GNU tools rule.

## Priority summary

| # | item | destination | priority |
|---|---|---|---|
| 1 | Output Patterns (3 entries) | `reference.md` §Examples | high |
| 4 | Safety checklists + failure protocol | `docs/skill-contract.md` | high |
| 2 | Graceful-skip pattern | `reference.md` §Examples | medium |
| 3 | Operator-summary pattern | `reference.md` §Examples | medium |
| 5 | "Build for the target" aphorism | `etc/rules-project.md` | low |

## When to revisit

Good candidates for pickup in any session that:
- Is expanding §Examples (all three tagged §Examples entries come together naturally)
- Touches `skill-contract.md` for other reasons (adding the safety sequence is low-lift at that point)
- Has cleared the current backlog (questions.md Q4 retest, Q6 revisit)

## Notes

- Items 1-3 overlap with the pressure-test findings but weren't surfaced there — the backup had them before the pressure test ran. They're independent material worth its own migration.
- The backup's `print_info` references should be reconciled against the open question in `skill-contract.md` about whether to restore `print_info` to `printer.func`. Both items relate to the same unresolved decision.
