# Reference Review — Remaining Work

Formal-logic review of `reference.md` completed; 17 of 24 findings applied and committed at `v0.0.0-base` (`f8152c3`). Subsequent corpus-recon session (2026-04-12) added §Parameter Expansion, §Redirection, §Loops, §External Tools, §Pipelines, §Temp Files, §Examples; applied a 17-finding condensation pass; closed all remaining items from the original formal review.

## Section 5 — Coverage Gaps

### 5.1 Exit codes beyond 0/1/2 (done ✓ — 2026-04-12)
Added to §Exit: *"All application failures go through `print_error` (exit 1); reserve other non-zero codes for documented contracts."*

### 5.2 Multi-Goal REQ state-sharing (done ✓ — 2026-04-12)
Added to §Main with PM-corrected framing: *"Goals and REQs share script-global variables. A REQ may depend on state established by any earlier REQ — within its own Goal or in any prior Goal — since execution is top-to-bottom sequential."* Italic names the pipeline shape `A → B → C` as the norm.

### 5.3 Temp files / trap (done ✓ — 2026-04-12)
§Temp Files added during corpus-recon dissection. `mktemp -d /tmp/name-XXXXXX` + paired `trap 'rm -rf "$tmp"' EXIT` as the security-aware ephemeral-artifact shape. Cites `man mktemp` and BashFAQ/062.

### 5.4 stdin handling (done ✓ — 2026-04-12)
Added to §Argument Parsing: *"Scripts that read stdin accept `-` as a filename synonym for stdin and document the form in the header's EXECUTE line."*

### 5.5 Logging reference in Line Width example (closed — no action)
The `logged: /tmp/script-purpose.log` line in the example is illustrative report content, not implying a logging rule.

## Section 6 — Rule Economy

### 6.1 + 6.2 Merge flag-order + debug-x rules (done ✓ — 2026-04-12)
Merged into one §Error Mode rule: *"Keep all three flags together, in the order `-euo pipefail`, on one `set` line. For debugging, add `x` → `set -euxo pipefail`; remove it when done."*

### 6.3 Goal/MAIN sharing merge (done ✓)
Absorbed by finding 1.2 (MAIN two-shape rule).

### 6.4 Frame-is-title promotion (done ✓)
Already promoted to rule in the Section Frame section.

### 6.5 "Nothing else uses that pattern" cut (done ✓)
Removed when Variables was rewritten to point at Section Frame.

### 6.6 REPORT rationale collapse (done ✓)
Absorbed by finding 2.5 (REPORT trigger removed entirely).

### 6.7 "last lines" tautology cut (done ✓ — 2026-04-12)
Deleted. Preceding rule already states the closer is the last content.

## Related Deferred Work (not from this review)

- **`scripts/template.sh`** — Starter Kit promise was removed (template is constructed per project from the reference; only `printer.func` is shipped as a fixed artifact). No longer outstanding.
- **Real-script pressure test** — Rebuild a non-trivial existing script against the reference; gaps that surface become the next rules worth writing. Highest-value next step.
- **Section-order review** — `reference.md` now has ~21 sections added through tally-driven insertions; a top-to-bottom reread for flow is worthwhile but low priority (it reads coherently as-is).
- **§Examples expansion** — §Examples has one entry (config-file convergence). More patterns can be added as they surface in real scripts.

## Tag

Retag after this batch lands.
