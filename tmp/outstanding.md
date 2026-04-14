# Outstanding items — basher project

Consolidated open-items list as of 2026-04-14 post-cycle-3. Pulls from the per-cycle findings docs, the salvage list, and OP-side operational items. Source-of-truth detail is in the named cross-references.

---

## Reference candidates (basher-side)

Changes to `reference.md`, `share/printer.func`, or `share/printer.sh` that would close a real gap or tighten an existing rule.

### From cycle 3 (fresh)

**C3-1. §Examples `#config-drift` — loose key probe.** (MEDIUM)
- The example uses `grep -qF -- "$key" "$target_config"` which is whole-line substring search. Real configs with overlapping key substrings get false positives ("already set" when it isn't).
- Candidate: tighten to `grep -qE "^[[:space:]]*${key}[[:space:]]*=" -- "$target_config"` or similar token-anchored form.
- Detail: `tmp/cycle-3-findings.md` Finding 1.

**C3-2. §Examples `#config-drift` — reverse-order insertions.** (LOW)
- Loop of `sed -i "/$anchor/a\\ $line"` produces the inserted lines in reverse spec order.
- Candidate: rewrite to accumulate-then-append, OR document reverse-order as a known property of the example.
- Detail: `tmp/cycle-3-findings.md` Finding 2.

### From cycle 2 (still deferred)

**C2-5. Summary-count semantics pattern.** (LOW, defer)
- Pre-scan snapshot vs post-scan tally for iteration summaries. SRD v2.3 S1 addressed the specific Script B case; no reference addition shipped. Defer unless the pattern recurs.
- Detail: `tmp/cycle-2-findings.md` Finding 5.

**C2-6. Concurrent-writer tempfile pattern.** (LOW, defer)
- Candidate `#concurrent-append-tempfile` §Examples entry covering atomic-short-write assumption + FIFO alternative for scale. Defer unless concurrent I/O becomes a recurring theme.
- Detail: `tmp/cycle-2-findings.md` Finding 6.

### Cross-cycle pattern to discuss

**§Examples blocks as the weak link.** Cycle 2 surfaced one defect in `#config-drift`; cycle 3 surfaces two more. Tagged §Examples blocks are canonical — CAs retrieve and copy verbatim — so every weakness reproduces. Future §Examples additions may deserve a tighter OP review gate than illustrative sketches.

---

## SRD-side clarifications (not basher)

Spec precision issues surfaced by cycle 3. Live in `/tmp/bash-test-reqs.md` (v2.5); OP-owned.

**S-1. Script B ordering (compress vs delete).** SRD Appendix C.2 doesn't pin order; different CA choices produce different tallies. Proposed v2.6 fix: mandate compress-then-delete (or the reverse) explicitly. Detail: `tmp/cycle-3-findings.md` Finding 3.

**S-2. Script B "already compressed" semantics.** SRD v2.3 S1 pinned "snapshot at entry"; cycle-3 CA read this as "snapshot-survivors at exit." Language ambiguity. Detail: `tmp/cycle-3-findings.md` Finding 4.

**S-3. Script D `tail -F` history window.** Spec silent on whether pre-existing lines count; default `tail -F` reads last 10 lines. Pin `-n 0` if only new appends should count. Detail: `tmp/cycle-3-findings.md` Finding 5.

---

## Shelf items (pending decisions)

### Salvage from cascadian:bash backup

Five items from `/Users/work/code/cascadian/tmp/bash.bak` (archived pre-contract `SKILL.md`), per `tmp/salvage-from-bash-skill.md`:

**V-1. Output patterns — three tagged §Examples entries.** (HIGH)
- `#validation` (succeed quietly, fail loudly), `#generation` (silent operations, show deliverable), `#creation` (verbose state-changing).

**V-2. Graceful-skip pattern — `#graceful-skip`.** (MEDIUM)
- Check-before-operate for external resources where some entries may legitimately not exist.

**V-3. Operator-summary pattern — `#operator-summary`.** (MEDIUM)
- Counts + warnings at end of iterative scripts.

**V-4. Pre-auth / pre-execution / failure-protocol safety sequences.** (HIGH — skill side)
- Concrete checklists (verify requirement, shellcheck, ring bell before destructive ops, etc.) for `docs/skill-contract.md`.

**V-5. "Build for the target, not the workbench" aphorism.** (LOW)
- Mnemonic for `etc/rules-project.md §Engineering Principles`.

### Cycle 2 Finding 4 — cascadian territory

**GNU-prefix tool preference (`gdate`, `gfind`, `gsed`).** Deferred — cascadian should PATH-route or shim so the CA writes plain `date`/`find`/`sed` and gets GNU semantics on macOS. Detail: `tmp/cycle-2-findings.md` Finding 4.

---

## OP-side operational items

### Post-cycle migrations

Per `tmp/post-cycle-actions.md` (OP-owned, not PM-visible):

1. **SRD migration.** `/tmp/bash-test-reqs.md` (currently v2.5) → `docs/qa/srd-pressure-test.md`. Prepend the lean PM seed prompt at the top so SRD and kickoff travel together. `rm -f /tmp/bash-test-reqs.md` after.
2. **OP methodology migration.** `/tmp/bash-test-op-methodology.md` → `docs/qa/pressure-test-methodology.md`. `rm -f /tmp/bash-test-op-methodology.md` after.
3. **Cycle results preservation.** This cycle's artifacts in `/tmp/bash-test-results.md` and `/tmp/bash-test-report.md` → `docs/qa/results/2026-04-14-bash-test-results.md`. `rm -f` the `/tmp` copies after.
4. **Dev record entry** for each of the above moves.

### Tag hygiene

**Retag if Findings C3-1 and/or C3-2 land.** Patch bump → `v0.2.2-contract`. Per project versioning rules in `etc/rules-project.md §Version Tags`.

### Physical leftovers

**Orphan `/Users/work/code/bashing/refs/` directory.** Left over from my pressure-test staging (2026-04-13). SRD no longer references it. Cascadian reads the reference from its own cache. Safe to `rm -rf`; pending OP direction.

---

## Status snapshot (as of 2026-04-14 02:00 PT)

| Area | Status |
|---|---|
| Q1–Q7 regression (three cycles) | All held, zero regressions |
| Cycle 3 scripts | All four ACCEPTED |
| Current SRD version | v2.5 at `/tmp/bash-test-reqs.md` |
| Current basher tag | `v0.2.1-contract` |
| Latest cycle results | `/tmp/bash-test-results.md` (2026-04-14 00:51 PT) |
| Printer contract | §Printer Library in reference.md + `share/printer.sh` harness |
| Cascadian:bash skill | v0.2.0, caching `reference.md` from upstream |
