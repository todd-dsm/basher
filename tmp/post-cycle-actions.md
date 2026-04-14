# Post-cycle actions

Items to execute after the current pressure-test cycle closes. Distinct from `tmp/questions.md` (open reference-content questions) and `tmp/salvage-from-bash-skill.md` (deferred migrations from the skill backup).

## 1. Migrate the pressure-test SRD into the repo

**From:** `/tmp/bash-test-reqs.md` (volatile)
**To:** `docs/qa/srd-pressure-test.md`

**Additional step:** prepend the lean PM seed prompt at the top of the file so the SRD and its kickoff prompt travel together as one consumable artifact.

**Rationale:** the SRD has stabilized at v1.5+ and should no longer live in `/tmp`. Future pressure-test cycles invoke the same SRD; preserving it in `docs/qa/` keeps it discoverable alongside other QA material.

**Clean-up:** delete the `/tmp/bash-test-reqs.md` draft (`rm -f`) once the repo copy is confirmed.

**Record:** add entry to `docs/development-record.md`.

## 2. Retag if the cycle closes out substantive reference changes

Current tag: `v0.2.0-contract`. If the cycle surfaces reference.md revisions that land, retag (e.g., `v0.3.0-<theme>`).
