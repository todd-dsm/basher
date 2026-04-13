# Reference Review — Remaining Work

Formal-logic review of `reference.md` completed; 17 of 24 findings applied and committed at `v0.0.0-base` (`f8152c3`). Items below are the untouched remainder.

## Section 5 — Coverage Gaps

### 5.1 Exit codes beyond 0/1/2 (open)
The reference names:
- exit 0 — success
- exit 1 — `print_error`
- exit 2 — argument parsing error

Silent on other failure modes (precondition failure mid-run, partial success).

**Proposed fix:** one sentence in Exit or Error Mode: *"All application failures go through `print_error` (exit 1); reserve other codes for documented contracts."*

### 5.2 Multi-Goal REQ state-sharing (open)
MAIN rule says REQ numbering resets per Goal. Silent on:
- Can REQs in Goal 2 read state set by Goal 1?
- Can REQs within a Goal depend on earlier REQs in that Goal?

**Proposed fix:** one sentence in MAIN: *"Goals share script-global variables; REQs depend only on prior REQs in the same Goal."*

### 5.3 Temp files / trap (closed — declined)
Author declined earlier: the ca already knows `mktemp` + `trap … EXIT`; placement is the only basher-specific question, and a real script will surface it better than an abstract rule. Revisit when a real script makes placement unclear.

### 5.4 stdin handling (open — awaits decision)
Argument Parsing covers flags and positional args. Silent on:
- Scripts that read from stdin
- Scripts that accept `-` as a filename (stdin convention)

**Decision pending:** add one-sentence rule now, or defer to pressure-test phase where a real script will surface whether guidance is needed.

### 5.5 Logging reference in Line Width example (closed — no action)
The `logged: /tmp/script-purpose.log` line in the example is illustrative report content, not implying a logging rule. No action needed unless a real script makes logging conventions necessary.

## Section 6 — Rule Economy

### 6.1 + 6.2 Merge flag-order + debug-x rules (open)
Error Mode currently has two separate rules:
- L250: Keep all three flags together in order `-euo pipefail`
- L252: For debugging, add `x`: `set -euxo pipefail`

Plus a rationale at L253 that restates L244/L245's placement rationale.

**Proposed fix:** merge into one rule — *"Keep all three flags together, in the order `-euo pipefail`, on one `set` line. For debugging, add `x` → `set -euxo pipefail`; remove when done."* Rationale collapses into a single line about single-line editing.

### 6.3 Goal/MAIN sharing merge (done ✓)
Absorbed by finding 1.2 (MAIN two-shape rule).

### 6.4 Frame-is-title promotion (done ✓)
Already promoted to rule in the new Section Frame section.

### 6.5 "Nothing else uses that pattern" cut (done ✓)
Removed when Variables was rewritten to point at Section Frame.

### 6.6 REPORT rationale collapse (done ✓)
Absorbed by finding 2.5 (REPORT trigger removed entirely).

### 6.7 L566 "last lines" tautology cut (open)
Current text: *"The marker and `exit 0` are the last lines of the file. Nothing follows them."*

Given the preceding rule already says *"close every executable script with … `exit 0` immediately below,"* this adds nothing a ca would not infer.

**Proposed fix:** delete L566 and its rationale, or fold the uniqueness clause into the main closer rule as a trailing sentence.

## Order of Attack (least-dependencies-first)

1. **6.7** — cut tautology. Zero-cost deletion.
2. **6.1 + 6.2** — merge two Error Mode rules into one. Local.
3. **5.1** — exit-code contract. One sentence in Exit.
4. **5.2** — Goal/REQ state-sharing. One sentence in MAIN.
5. **5.4** — stdin handling. Decision point: add or defer.

## Related Deferred Work (not from this review)

- `scripts/template.sh` (or `share/template.sh`) — canonical template artifact promised by the Starter Kit rule. Deferred until reference is stable.
- Real-script pressure test — rebuild a non-trivial existing script against the reference; gaps that surface become the next rules worth writing.

## Tag

Current base: `v0.0.0-base` → `f8152c3`. Retag after this batch lands.
