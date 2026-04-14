# Post-cycle actions

Items to execute after the current pressure-test cycle closes. Distinct from `tmp/questions.md` (open reference-content questions) and `tmp/salvage-from-bash-skill.md` (deferred migrations from the skill backup).

## 1. Migrate the SRD into the repo

**From:** `/tmp/bash-test-reqs.md` (volatile; PM-facing software requirements for four scripts)
**To:** `docs/qa/srd-pressure-test.md`

**Additional step:** prepend the lean PM seed prompt at the top of the file so the SRD and its kickoff prompt travel together as one consumable artifact.

**Rationale:** the SRD has stabilized at v2.0 (production-only framing; diagnostic content split into the OP methodology doc). Future cycles invoke the same SRD; preserving it in `docs/qa/` keeps it discoverable.

**Clean-up:** `rm -f /tmp/bash-test-reqs.md` once the repo copy is confirmed.

## 2. Migrate the OP methodology doc into the repo

**From:** `/tmp/bash-test-op-methodology.md` (volatile; OP-only diagnostic framework)
**To:** `docs/qa/pressure-test-methodology.md`

**Rationale:** captures the diagnostic layer (regression targets, PM-report interpretation, metadata tracking) that was extracted from the SRD. Private to OP — not issued to PMs in future cycles.

**Clean-up:** `rm -f /tmp/bash-test-op-methodology.md` once the repo copy is confirmed.

## 3. Preserve the results file from this cycle

**From:** `/tmp/bash-test-results.md` (PM-produced summary for this cycle)
**To:** `docs/qa/results/<YYYY-MM-DD>-bash-test-results.md` (or a cycle-specific subdirectory)

**Rationale:** the results file is per-cycle evidence. Preserving it enables longitudinal tracking (per OP methodology §5).

**Clean-up:** `rm -f /tmp/bash-test-results.md` once archived.

## 4. Record both moves

Add an entry to `docs/development-record.md` noting the migration of both documents and the preservation of the cycle's results.

## 5. Retag if substantive reference changes land

Current tag: `v0.2.0-contract`. If the cycle surfaces reference.md revisions that land, retag per OP methodology §6 (patch / minor / major rules).
