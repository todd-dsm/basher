# Cycle 2 — Reference findings

Surfaced during the 2026-04-13 second execution of the four-script SRD (v2.0). Scored by the PM against unmodified `reference.md` (main HEAD, equivalent to `v0.2.0-contract` + post-tag commits). Analyzed by OP per the methodology.

All four scripts ACCEPTED. Zero footgun-class defects. Q1–Q7 regression targets all held.

Six reference-improvement candidates below. For discussion; no edits applied yet.

---

## HIGH — clear reference issues

### 1. §Checks vs §Examples: `print_pass` argument policy contradiction (RESOLVED 2026-04-13 cycle 2)

**Resolution:** the §Examples `#config-drift` block was wrong; the §Checks rule is right. The canonical iteration shape is `print_req "process <item>"` inside the loop + bare `print_pass` on success. Variant information (added vs already set, days remaining, etc.) belongs in §Report counts, not in `print_pass` args. Rewrote both instances of the block (the §Examples canonical entry and the §Comments DO example) to match. `printer.func` unchanged; `print_pass` keeps its zero-arg contract.

**Closes Finding 3 jointly** — test-a's "printf above bare print_pass" pattern was also a misreading of the model. `print_req "check <host>"` per iteration + bare `print_pass` on success is the correct shape; per-host context on success is not emitted (the `print_req` above it names what was tested; operator gets pass-or-fail).

---

### Original write-up

**Surfaced in:** test-c (`score.md` Notes; also test-d's peer scripts use same form)

**Situation:** the reference contradicts itself.
- **§Checks rule:** *"`print_pass` takes no arguments."*
- **§Examples `#config-drift` block** (which test-c's spec explicitly directs the CA to follow): uses `print_pass "added: $line"` and `print_pass "already set: $line"` verbatim.

The CA followed §Examples verbatim per the spec's cue.

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

### 4. GNU-prefix tool preference (`gdate` / `gfind` / `gsed`) — CASCADIAN TERRITORY

**Surfaced in:** test-d (defect L2 — `date` used where `gdate` was the spec's intent). **Repeat from cycle 1 (G2).**

**Disposition:** **deferred to cascadian, not a basher change.** When cascadian properly configures the CA's environment (PATH ordering, shim wrappers, or equivalent), `date`/`find`/`sed` will resolve to GNU variants on macOS by default. The CA writes plain tool names; the platform layer handles tool selection. Under that model, the reference doesn't need a GNU-prefix rule at all — the CA can't write `date` and get BSD semantics, so there's nothing to guard against.

**Next step:** raise as a cascadian feature request. No basher action.

---

## MEDIUM — pattern worth naming

### 3. Per-iteration context line above bare `print_pass` (RESOLVED jointly with Finding 1)

**Resolution:** the CA's invented pattern was a misreading of the model. Under the correct shape, per-iteration context belongs in `print_req` (which names what's being tested), not in a `printf` above `print_pass`. No new §Examples entry needed. See Finding 1.

---

### Original write-up

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
