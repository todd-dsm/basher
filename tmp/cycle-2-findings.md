# Cycle 2 — Reference findings

Surfaced during the 2026-04-13 second execution of the four-script SRD (v2.0). Scored by the PM against unmodified `reference.md` (main HEAD, equivalent to `v0.2.0-contract` + post-tag commits). Analyzed by OP per the methodology.

All four scripts ACCEPTED. Zero footgun-class defects. Q1–Q7 regression targets all held.

Six reference-improvement candidates below. For discussion; no edits applied yet.

---

## HIGH — clear reference issues

### 1. §Checks vs §Examples: `print_pass` argument policy contradiction

**Surfaced in:** test-c (`score.md` Notes; also test-d's peer scripts use same form)

**Situation:** the reference contradicts itself.
- **§Checks rule:** *"`print_pass` takes no arguments."*
- **§Examples `#config-drift` block** (which test-c's spec explicitly directs the CA to follow): uses `print_pass "added: $line"` and `print_pass "already set: $line"` verbatim.

The CA followed §Examples verbatim per the spec's cue. `printer.func` silently discards extra args, so output is unaffected — but the reference is internally inconsistent, and the CA had to choose which rule to honor.

**Candidate fixes:**
- **(a)** Relax §Checks: *"print_pass takes no arguments by default; per-iteration contexts may pass a short identifier."*
- **(b)** Rewrite the §Examples `#config-drift` block to use bare `print_pass` with a separate context line above it.
- **(c)** Leave §Checks strict; note in §Examples block that `print_pass` takes no args and use a printf-above pattern.

**Recommendation pending.** (a) is the smallest change and codifies what the corpus actually does. (c) keeps §Checks strict but requires a small §Examples rewrite.

---

### 2. §External Tools vs §Loops: counter-preserving iteration over `find`

**Surfaced in:** test-b (conformance scored 2 on §External Tools and 2 on §Loops)

**Situation:** two happy paths collide when a script needs both.
- **§External Tools happy path:** `find … -exec cmd {} +` (batched exec).
- **§Loops happy path:** `while read … < <(cmd)` (process substitution preserves script-local state in the caller shell).

Test-b needs bulk action across matching files AND script-local counters (`compressed`, `deleted`). `-exec +` spawns a subshell that loses the counter updates. The CA chose `while read -d '' < <(gfind … -print0)` per §Loops. Correct under §Loops; non-canonical under §External Tools.

**Candidate fixes:**
- **(a)** Add a carve-out in §External Tools: *"when the action body needs to update script-local state (counters, arrays, flags), use the `< <(find … -print0)` form per §Loops — `-exec cmd {} +` spawns a subshell that loses those updates."*
- **(b)** Add a cross-reference in §Loops to §External Tools for the find-specific case, mirroring (a) from the other direction.
- **(c)** Both.

**Recommendation pending.** (a) alone is probably enough; the CA is already following §Loops correctly — we're just resolving which section's happy path wins when they intersect.

---

### 4. GNU-prefix tool preference (`gdate` / `gfind` / `gsed`)

**Surfaced in:** test-d (defect L2 — `date` used where `gdate` was the spec's intent). **Repeat finding from cycle 1 (G2).**

**Situation:** reference §External Tools has the Darwin `-exec +` caveat but no general rule for GNU-prefix variant preference on macOS. When a spec's platform note says "macOS with GNU coreutils," the CA has no cite-able rule to reach for `gdate`/`gfind`/`gsed`. Script A's CA used `gdate` because its spec pinned it; Script D's CA used `date` because its spec was silent. SRD v2.3 patched the spec platform notes, but the reference is still silent — any future spec that omits the instruction repeats the gap.

**Candidate fix:** add one sentence to §External Tools near the Darwin caveat:
> *"On macOS with GNU coreutils installed, reach for the `g`-prefix variants (`gdate`, `gfind`, `gsed`) where BSD semantics differ. The target is GNU semantics, not BSD portability."*

**Recommendation:** ship. Two cycles of signal; small, bounded, cite-able.

---

## MEDIUM — pattern worth naming

### 3. Per-iteration context line above bare `print_pass`

**Surfaced in:** test-a (`score.md` Notes)

**Situation:** the CA invented a clean pattern to give per-iteration detail while respecting the §Checks "no args" rule:

```bash
while IFS= read -r host; do
    check_cert "$host" || { print_error "..." || true; continue; }
    printf '    %s: %d days remaining\n' "$host" "$days"
    print_pass
done < "$hosts_file"
```

One-line printf context above bare `print_pass`. Operator gets the per-host detail; §Checks rule is honored.

**Candidate fix:** §Examples entry — `#loop-report-with-context` — showing this pattern. The reference §Checks Per-iteration rule currently teaches the failure side (`cmd || print_error "…" || true`); this entry would teach the success side.

**Recommendation pending.** Nice-to-have. Would convert an invented pattern into a canonical one.

---

## LOW — judgment territory

### 5. Summary-count semantics (at-entry vs at-exit)

**Surfaced in:** test-b defect L1 (and addressed in SRD v2.3 S1).

**Situation:** spec said "report `already compressed`" without disambiguating at-entry-snapshot vs at-exit-tally. CA chose at-exit; report double-counts on run 1. SRD v2.3 fixed this spec-side by pinning the semantics. Reference could also have an entry showing the pre-scan-snapshot pattern for summary counts.

**Candidate fix:** §Examples entry for pre-scan snapshot pattern. Optional; the SRD-side fix is enough for this specific test.

**Recommendation:** defer unless the pattern recurs.

---

### 6. Concurrent-writer tempfile pattern

**Surfaced in:** test-d (`score.md` Notes)

**Situation:** the script uses a shared `mktemp` tempfile with multiple concurrent background writers (one per tail). Relies on atomic-write size for correctness — works at fixture scale, risky at higher throughput where a FIFO + single writer would be safer.

**Candidate fix:** §Examples entry — `#concurrent-append-tempfile` — with the atomic-size caveat and a FIFO alternative for scale.

**Recommendation:** defer. Only worth it if concurrent I/O becomes a recurring theme.

---

## Cross-cycle observations

### Signal strength

- Cycle 1 (2026-04-13 first run): surfaced G1 (counter semantics), G2 (gdate preference).
- Cycle 2 (this run): reconfirmed G2 → finding 4. Surfaced findings 1, 2, 3 as new.
- Zero footgun-class defects both cycles. Q1–Q7 regression targets all continue to hold. This is the strongest longitudinal signal: the fixes from the 2026-04-13 design session are sticking.

### Convergence posture

- Reference has matured past silent-gap territory (Q1–Q7 are the old footguns; none recurring).
- Remaining gaps are narrower: internal contradictions (finding 1), cross-section tensions (finding 2), confirmed-pending additions (finding 4), pattern formalization (finding 3).
- Retag warranted if findings 1, 2, 4 land → `v0.2.1-contract` patch bump.

### What stayed quiet

Sections not stressed by these four scripts but worth considering for future specs:
- §Report (informational REQ shape; reporting counts)
- §Exit `fin~` idiom (all four produced correctly but no adversarial probe)
- §Variables ENV-asserted-early block (none of the four use `: "${VAR?…}"`)
- §Comments (no CA got close enough to comment discipline to stress it)

These could inform cycle 3's script selection.
