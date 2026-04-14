# Cycle 3 — Reference findings

Surfaced during the 2026-04-14 third execution of the four-script SRD (v2.5). Authored via `cascadian:bash` v0.2.0 (skill installed from `cascadian-local/cascadian/0.2.0`) consuming the cached `reference.md` at `~/.claude/cascadian/basher/reference.md` (upstream commit `2026-04-14T07:22:45Z`). Analyzed by OP per the methodology.

All four scripts ACCEPTED. Zero CRITICAL / HIGH / MEDIUM per PM. Six LOW defects (PM): five spec-silent or defensible CA judgment; one is a non-finding (the `|| true` loop idiom working as designed).

**Q1–Q7 regression targets all held** — three cycles running with no regression:
- Q1 (loop-REQ shape): A correctly uses `print_error … || true` per §Checks per-iteration rule.
- Q2 (printer path): all four sourced the canonical `scripts/lib/printer.func`.
- Q3/Q7 (comment discipline): no NOTE-flood; compliance audit confirms "no decision-log narration."
- Q4 (flag ordering): C correctly rejects flags-after-positionals per §Argument Parsing line 696.
- Q5 (`(( var++ ))`): B's four counters use the assignment form.
- Q6 (EXIT-trap `exit 0`): D scored 3/3 on trap discipline; no mask.

Two reference-improvement candidates (basher side). Three spec clarifications (SRD side, deferred to OP). One non-finding.

---

## MEDIUM — reference-example weakness

### 1. §Examples `#config-drift` block: `grep -qF` is substring-match on whole line

**Surfaced in:** test-c defect #1 (`scripts/config-sync.sh:115`)

**Situation:** the reference's §Examples `#idempotent · #config-drift · #declarative` block uses:

```bash
if ! grep -qF -- "$key" "$target_config"; then
```

`grep -qF -- "$key"` does a *substring* match against every line of the target file. For the Appendix D fixture, no keys collide, so no observable bug. In a real config where keys can share substrings (e.g., `log` vs `log_level` vs `access_log`), the probe gives false positives — "key already set" when it isn't.

CA reproduced this verbatim. Not the CA's fault; the example is the loose pattern.

**Candidate fix:** tighten the §Examples grep to anchor on key-token boundaries. Options:
- **(a)** `grep -qE "^[[:space:]]*${key}[[:space:]]*=" -- "$target_config"` — key at start of line, optional whitespace, then `=`.
- **(b)** `grep -qE "^${key} *= " -- "$target_config"` — matches the exact shape the loop extracts with `${line%% = *}`.
- **(c)** Accept substring match as "good enough for this example" and add a caveat comment.

**Recommendation pending.** (b) is simplest and symmetric with the extraction form. Same tagged entry also has Finding 2 — worth fixing together.

**Severity rationale:** PM scored LOW because the Appendix D fixture has no collisions. From the reference's perspective, this is a latent correctness risk in the tagged example — likely MEDIUM for a real consumer. Reporting as MEDIUM.

---

## LOW — reference-example polish

### 2. §Examples `#config-drift` block: `sed` chain produces reverse-order insertions

**Surfaced in:** test-c defect #2 (`scripts/config-sync.sh:118`)

**Situation:** the reference's §Examples block uses:

```bash
sed -i "/$anchor/a\\ $line" "$target_config"
```

in a loop. Each `sed -i …/a\…` appends the new line immediately after the anchor — which pushes the previous insertion down. Three spec entries added one-after-another appear in the target in *reverse* order of the spec.

CA reproduced verbatim. End state is idempotent and correct-by-key-membership; ordering is the only drift.

**Candidate fix:** change the §Examples block to preserve spec order. Options:
- **(a)** Accumulate a list of pending lines first, emit one multi-line `sed` append at the end.
- **(b)** Use an insertion marker that advances after each write (e.g., anchor on the last-inserted line for subsequent ones).
- **(c)** Accept reverse-order and document it as a known property of the example.

**Recommendation pending.** (a) is a clean rewrite but changes the example's character (collect-then-act vs stream-process). (c) is cheapest — one sentence in the §Examples block noting ordering.

---

## SRD-side clarifications (not basher) — for OP review

### 3. Script B — ordering (compress vs delete) unpinned

**Surfaced in:** test-b defect #1 — PM classified "shortfall, LOW."

**Situation:** SRD Appendix C.2 lists the two retention rules (compress, then delete) as bulleted behaviors, with no explicit ordering imposed on the implementation. CA ordered delete-before-compress; PM notes end-state is equivalent for the fixture but the `compressed` tally differs for files crossing both windows (e.g., web-ancient at 42d would be *compressed-then-counted-as-deleted* under one reading, or *skipped-because-will-delete* under another).

**Disposition:** SRD ambiguity. Proposed SRD v2.6 fix per PM §4 follow-up #1: "mandate an ordering (compress-then-delete or delete-then-compress) so the `compressed` / `deleted` tally is deterministic."

**Not a basher concern.** Reference §Loops and §External Tools don't cover multi-pass retention policy — application-level logic.

---

### 4. Script B — "already compressed" counter semantics

**Surfaced in:** test-b defect #2 — PM classified "correctness, LOW."

**Situation:** SRD v2.3 S1 pinned "already compressed" as *"files that were `.log.gz` before this run began (snapshot at entry). Files compressed during this run are counted only in `compressed`, not here."* CA's implementation reads this as: snapshot = set at entry, minus any deleted during the run. Result: run-1 shows `already compressed: 0` because the pre-existing `web-old.log.gz` was deleted before the tally.

PM judged CA's reading defensible ("makes idempotency clean"). But the SRD language "snapshot at entry" implies the count is fixed at entry, regardless of subsequent deletions.

**Disposition:** the SRD may need a second tightening. Either confirm the "snapshot-at-entry, decoupled-from-subsequent-deletion" reading explicitly, or align with the CA's "snapshot-survivors" reading. OP call.

**Not a basher concern** — spec precision is SRD-side.

---

### 5. Script D — `tail -F` default history window

**Surfaced in:** test-d defect — PM classified "correctness, LOW."

**Situation:** `tail -F` without `-n 0` reads the last 10 lines of each file before following. For log aggregation, this causes pre-existing matching lines in the fixtures to be counted alongside new appends from the driver. Spec is silent on whether pre-existing lines should count.

**Disposition:** SRD v2.6 Appendix C.4 should pin `-n 0` if only new appends should count (the likely intent). OP call.

**Not a basher concern.** Reference could mention `tail -F -n 0` as a pattern in §External Tools or §Pipelines, but it's narrow enough to leave out unless we want a "live log following" example.

---

## Non-finding

### 6. test-a `print_error "reason" || true` inside per-host loop

**Surfaced in:** test-a defect #6 in PM's results table — but the per-test `score.md` says *"Defensible … the reference does not prohibit this form. Noted for audit, not scored against."*

**Disposition:** not a defect. The CA correctly applied the §Checks per-iteration rule (the fix for Q1). The PM listed it for OP visibility, not as a basher issue.

**Action:** none. The reference rule is working.

---

## Cross-cycle observations

### Q1–Q7 regression posture

Three consecutive cycles with zero regressions on the seven original footguns. The rules are holding without drift. Strong signal that the 2026-04-13 pass addressed real, stable gaps.

### New surface area — the §Examples block as a weak link

Cycle 2 surfaced Finding 1 (§Examples `print_pass "..."` vs §Checks no-args) — resolved by rewriting the block. Cycle 3 now surfaces two MORE issues with the same block (Findings 1 and 2 above). Pattern: the `#config-drift` §Examples entry is powerful (CAs retrieve and follow it), which makes every weakness in the example a cross-cycle reproducer.

**Implication for process.** Tagged §Examples blocks should be held to a tighter correctness standard than illustrative sketches. Each is de facto a canonical implementation that CAs will copy verbatim. Future additions to §Examples should pass an OP review that explicitly checks: "would this produce a correct script under edge-case inputs?"

### Convergence

Cycle 3 is all LOW. Zero HIGH/MEDIUM per PM; OP reclassifies one as MEDIUM (Finding 1). Reference is converging. Patch retag warranted if Findings 1 and 2 land → `v0.2.2-contract`.

### What stayed quiet this cycle

- §Report — scripts B and D used it; no issues.
- §Exit `fin~` — all four closed correctly; no adversarial probe.
- §Variables ENV-asserted-early — none of the four use `: "${VAR?…}"`; deferred to specs that demand it.
- §Comments — no CA produced NOTE-floods. (Cross-cycle confirmation Q3/Q7 rules are holding.)

### Cross-reference to shelf items

- Cycle 2 Finding 5 (counter semantics ambiguity) — reconfirmed this cycle as Finding 4 above. Same family. If v2.6 lands, it should address both at once.
- Salvage-from-bash-skill output-patterns (#validation, #generation, #creation) — no connection to cycle 3 findings. Remains pending.
- Orphan `../bashing/refs/` directory — cycle 3 did not use it (cascadian reads from its own cache). Still safe to remove at OP direction.
- SRD migration (per `tmp/post-cycle-actions.md`) — still pending; SRD v2.5 + this cycle's results are now the canonical artifacts to preserve in `docs/qa/`.
