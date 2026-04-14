# Software Requirements — Four Sysadmin Scripts

**Document ID:** bash-test-reqs
**Version:** 2.0
**Date:** 2026-04-13
**Status:** Issued to PM

---

## 1. Introduction

### 1.1 Purpose

This document specifies four bash scripts to be produced by the engineering team. Each script is a sysadmin utility with a clearly scoped behavior, a fixed argument surface, and a defined set of inputs and outputs. All four must conform to the style reference staged under `refs/`.

### 1.2 Scope

- **In scope:** authoring, execution, and quality review of the four scripts defined in §3.1.
- **Out of scope:** deployment of the scripts to production systems.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| **OP** | The Operator — the caller who issued this document to the PM. |
| **PM** | The Project Manager — receives this document, deploys the engineering team, scores their output, reports back to the OP. |
| **CA** | Calling Agent — an engineering agent on the PM's team producing a single script. |
| **Happy path** | The code example given in each section of the style reference. Authoritative. |
| **Conformance** | The emitted script follows the style reference's rules without deviation. |
| **Defect** | Any deviation from the style reference or any runtime failure against the fixtures. |

### 1.4 References

| Artifact | Path |
|---|---|
| Style reference | `refs/reference.md` |

### 1.5 Overview

§2 defines the product and its user classes. §3 specifies each script and the deliverables. §4 defines acceptance. Appendices C, D, E provide the per-script task spec, the fixture setup commands, and the quality rubric respectively.

---

## 2. Overall Description

### 2.1 Product perspective

Four independent bash scripts, each produced by a separate CA invocation. The scripts target sysadmin workflows (TLS probing, log retention, config synchronization, live log aggregation). Each conforms to the style reference at `refs/reference.md`.

### 2.2 Product functions

1. **Author** — four bash scripts, each produced by an independent CA working from a spec + the style reference.
2. **Execute** — each script runs against its fixtures; output captured.
3. **Score** — each script is evaluated against the quality rubric in Appendix E.
4. **Remediate** (bounded) — if a defect in an emitted script is addressed by **unambiguous, cite-able** content in `refs/reference.md`, the PM produces a remediated script alongside the original as `script-remediated.sh`. Both are preserved. When the fix requires judgment, invention, or content not in the reference, **do not remediate** — record the defect in the results and leave the original unchanged. Test: *"Can I name a specific rule in `refs/reference.md` that says do X instead?"* If yes → remediate. If you're reasoning "well, what if we…" → stop, record, move on.
5. **Report** — per-script `score.md`, session-level `/tmp/bash-test-results.md`.

### 2.3 User classes

| Class | Role |
|---|---|
| **OP** | Issues this document. Reviews the PM's final report. |
| **PM** | Owns execution of this document. Orchestrates fixtures, deploys CAs, runs scripts, scores output, compiles the results report. Reports to OP. |
| **CA** (one per script) | Produces `script.sh` from the spec + reference. Returns script plus a short decisions note. |

### 2.4 Operating environment

- **Platform:** macOS with GNU coreutils installed (`gdate`, `gfind`, `gsed`, `ggrep`). Scripts assume GNU tool behavior.
- **Shell:** bash 5+.
- **Network:** script A requires outbound HTTPS to public hostnames (`github.com`, `cloudflare.com`, `expired.badssl.com`).
- **Filesystem:** scripts read from and write to `/tmp` or the test's fixture directory; no root privileges.
- **Working repo:** artifacts land under `tmp/qa/`.
- **Per-script layout:** each script operates in `tmp/qa/test-<id>/`, shaped as a minimal consumer repo.

Canonical layout:

```
tmp/qa/
├── README.md                 # PM's session notes
├── scoring-rubric.md         # Appendix E staged verbatim
└── test-<id>-<name>/
    ├── spec.md               # Appendix C staged verbatim
    ├── fixtures/             # built per Appendix D
    ├── script.sh             # CA output, preserved untouched
    ├── script-remediated.sh  # optional, PM-produced per §2.2.4
    ├── run.log               # execution transcript
    └── score.md              # PM's score per Appendix E
```

### 2.5 Constraints

- **C1. Blind authorship.** Each CA produces its script from its `spec.md` + the four `refs/` files + nothing else. No reading of other scripts, prior outputs, or ambient material.
- **C2. No improvisation.** CAs follow the happy path. When the happy path does not satisfy the spec, they follow the style reference's Further-research links. No improvisation beyond that.
- **C3. Script preservation.** The original `script.sh` is never modified. Remediation (if any) is a new file.
- **C4. Remediation bound.** Remediation uses only content from `refs/reference.md`. Any defect the reference does not address is recorded and left uncorrected.

### 2.6 Assumptions

- The OP has staged `refs/reference.md` into the working repo before issuing this document.

---

## 3. Specific Requirements

### 3.1 Functional requirements — the four scripts

Each script's full spec is in Appendix C. Summary:

| id | name | behavior | arguments | primary exercises |
|---|---|---|---|---|
| A | cert-expiry | For each hostname in a file, probe TLS on :443, compute days to cert expiry, flag under threshold. | positional hosts-file; `-t/--threshold DAYS` | loops, pipelines, external tools, per-iteration reporting |
| B | log-archival | In a directory of logs, compress old, delete very old, report counts. Idempotent. | positional log-dir; `-n/--compress-days`; `-m/--delete-days` | find patterns, loops, idempotency, counter discipline |
| C | config-sync | For each `key = value` in a spec file, insert into target after a named anchor if missing; report. Idempotent. | positional target + spec; `-a/--anchor STRING` | parameter expansion, loops, redirection, cross-reference retrieval |
| D | log-tail-aggregator | Tail multiple log files in parallel, aggregate regex-matching lines, clean shutdown on SIGINT or timeout. | positional log files; `-p/--pattern`; `-d/--duration` | functions decomposition, trap discipline, temp files, signals |

See Appendix C for each script's complete spec.

### 3.2 Non-functional requirements

- **NFR.1 — Reproducibility.** Running the same spec against the same reference and fixtures yields consistent results across cycles, barring natural variation in CA output.
- **NFR.2 — Isolation.** Each script operates in its own directory; no shared state.
- **NFR.3 — Auditability.** Every artifact (spec, fixtures, original script, remediated script, run log, score) persists for review.
- **NFR.4 — Minimum fidelity.** Every emitted script parses (`bash -n` exit 0). A script that fails syntax is scored `runtime: fail` with `conformance: 0`.

### 3.3 Interface requirements

- **IR.1 — CA contract.** Each CA is invoked with read-only access to its `spec.md` and `refs/reference.md`. It emits `script.sh` at the path specified in the spec. It returns a short note listing any judgment calls. No other outputs.
- **IR.2 — Script invocation.** Scripts are invoked from the root of their test directory (which acts as a consumer repo root).

### 3.4 Deliverables

All artifacts land under `tmp/qa/` in the working repo, except the top-level results report which lands at `/tmp/bash-test-results.md` per this contract.

**Per-script directory** — `tmp/qa/test-<id>-<name>/`:

| File | Source | Required |
|---|---|---|
| `spec.md` | Appendix C, staged verbatim | yes |
| `fixtures/` | Appendix D, built verbatim | yes |
| `script.sh` | CA output, preserved untouched | yes |
| `script-remediated.sh` | PM output per §2.2.4 | optional |
| `run.log` | execution transcript (stdout + stderr) | yes |
| `score.md` | PM scoring per Appendix E | yes |

**Session-level** — `tmp/qa/`:

| File | Contents | Required |
|---|---|---|
| `README.md` | brief session context pointer | yes |
| `scoring-rubric.md` | Appendix E staged verbatim | yes |

**Top-level report** — absolute path:

- **`/tmp/bash-test-results.md`** — the PM's report to the OP. Required shape:
  1. **Metadata block** — cycle start/end timestamps, CA identity + version/SHA, invocation mechanism (one sentence), underlying model identifier.
  2. **Summary table** — one row per script: runtime (pass/partial/fail), conformance score, defect count.
  3. **Defects ranked by severity** — each cross-referencing the per-script `score.md` entry.
  4. **Recommended follow-ups** — one per high-severity defect.

---

## 4. Verification

### 4.1 Per-script acceptance

A script is ACCEPTED if:
- Parses under `bash -n`
- Executes against its fixtures with the documented exit behavior
- Output matches the spec's behavioral requirements
- Idempotency holds where the spec requires it
- Conformance score ≥ 2 per exercised reference section
- Zero footgun-class defects

Otherwise the script is REJECTED with defects enumerated in `score.md`.

### 4.2 Session-level acceptance

The session is COMPLETE when all four scripts have been authored, executed, scored, and the results report at `/tmp/bash-test-results.md` has been written.

COMPLETE does not imply all four scripts ACCEPTED. A REJECTED script with clear defect analysis is a valid session outcome; acceptance is the OP's judgment on the final report.

---

## 5. Change log

| Version | Date | Author | Notes |
|---|---|---|---|
| 1.0–1.5 | 2026-04-13 | OP + AI assistant | Initial drafts (superseded). |
| 2.0 | 2026-04-13 | OP + AI assistant | Full rewrite: PM-facing only; production language; no diagnostic framing; reference paths neutralized to `refs/`; results file at `/tmp/bash-test-results.md`; `tmp/qa/` as working dir; CA prompt shape removed (PM's concern); regression check removed (OP-side methodology). |
| 2.1 | 2026-04-13 | OP + AI assistant | Pruned `refs/` to only what the CA needs: `reference.md` + `printer.func`. Removed `skill-contract.md` and `rules-project.md` (basher-internal meta-docs; not needed for authoring bash scripts). |
| 2.2 | 2026-04-13 | OP + AI assistant | Removed all mention of `printer.func` staging from the SRD. Printer placement is the consuming skill's operational concern (handled per skill-contract S1); not a basher software requirement. `refs/` now contains only `reference.md`. Appendix D.5 (printer staging step) deleted. |

---

## Post-cycle disposition

When the session closes:

1. Migrate this document to `/Users/work/code/basher/docs/qa/srd-pressure-test.md`.
2. Prepend the PM seed prompt (tracked separately) at the top of the migrated file so the SRD and its kickoff prompt travel together.
3. Delete `/tmp/bash-test-reqs.md` and `/tmp/bash-test-results.md` (volatile drafts) with `rm -f`.
4. Record the move in basher's `docs/development-record.md`.

---

## Appendix C — Per-script `spec.md` (canonical, copy verbatim)

Each block below is the **complete contents** of the named spec file. The PM copies each verbatim to `tmp/qa/test-<id>-<name>/spec.md` at the start of the cycle.

### C.1 — `test-a-cert-expiry/spec.md`

```markdown
# Script A — TLS cert-expiry checker

## Task

Write a bash script at `scripts/cert-expiry.sh` that, given a file of hostnames, reports the TLS certificate expiry status of each.

## Behavior

- Read hostnames from a positional-argument file path, one hostname per line. Skip blank lines and lines starting with `#`.
- For each hostname, open a TLS connection on port 443 and retrieve the peer certificate's `notAfter` date via `openssl s_client` piped to `openssl x509 -noout -enddate`.
- Parse the `notAfter` date into a days-from-today count (positive = days remaining, 0 or negative = expired).
- For each host, emit a report line:
  - **Pass** when days remaining is strictly greater than the threshold.
  - **Fail** when days remaining is at or below the threshold, or the host was unreachable / handshake-failed.
- Script exits non-zero if any host failed.

## Arguments

- **Positional:** `HOSTS_FILE` (required).
- **`-t, --threshold DAYS`** — days below which a cert is flagged. Default: `30`.
- **`-h, --help`** — usage.

## Platform

macOS with GNU coreutils. Use `gdate` for date parsing.

## Fixtures

`fixtures/hostnames.txt` — provided.

## Reference

Follow `refs/reference.md` exactly. Use only the shapes and rules it teaches. Source `scripts/lib/printer.func` for output (assume it exists). When a case doesn't fit an example, consult the Further-research links in the relevant section.

Do NOT improvise beyond what the reference describes. Do NOT invent print helpers beyond `print_goal`, `print_req`, `print_pass`, `print_error`.
```

### C.2 — `test-b-log-archival/spec.md`

```markdown
# Script B — Log archival

## Task

Write a bash script at `scripts/log-archival.sh` that enforces a retention policy on a directory of log files.

## Behavior

- Positional: log directory. Find regular files matching `*.log` and `*.log.gz` and process per policy:
  - `*.log` files older than `N` days (`--compress-days`): gzip in place.
  - `*.log` and `*.log.gz` files older than `M` days (`--delete-days`): delete.
- Idempotent: re-running on an already-compliant directory produces zero additional changes; all files report "kept" or "already compressed".
- Report counts: **compressed**, **deleted**, **already compressed**, **kept**.
- Precondition: `M > N`; otherwise exit via `print_error`.

## Arguments

- **Positional:** `LOG_DIR` (required).
- **`-n, --compress-days DAYS`** — default `7`.
- **`-m, --delete-days DAYS`** — default `30`.
- **`-h, --help`** — usage.

## Platform

macOS with GNU coreutils. Retention rules apply to both `.log` and `.log.gz` forms.

## Fixtures

`fixtures/logs/` — pre-populated with files at a range of ages. Expected post-run state in `fixtures/EXPECTED.md`.

## Reference

Follow `refs/reference.md`. Source `scripts/lib/printer.func`.
```

### C.3 — `test-c-config-drift/spec.md`

```markdown
# Script C — Config-drift remediation

## Task

Write a bash script at `scripts/config-sync.sh` that ensures every `key = value` line in a spec file is present in a target config file.

## Behavior

- Positional 1: target config file.
- Positional 2: spec file of `key = value` lines.
- `--anchor` flag (required): literal line after which missing entries are inserted.
- For each non-comment, non-blank line in the spec file:
  - Extract the key via parameter expansion (everything before ` = `).
  - Check whether that key already appears in the target (literal match).
  - If **present:** report "already set"; leave target alone.
  - If **absent:** insert the spec line after the anchor line via `sed -i`; report "added".
- Idempotent.

## Arguments

- **Positional 1:** target config file.
- **Positional 2:** spec file.
- **`-a, --anchor STRING`** — required.
- **`-h, --help`** — usage.

## Platform

macOS with GNU coreutils. Use GNU `sed -i` (no suffix).

## Fixtures

`fixtures/target.conf`, `fixtures/spec.conf`. Anchor: `# === managed block below ===`.

## Reference

Follow `refs/reference.md`. Source `scripts/lib/printer.func`.

**Note:** the reference's §Examples section contains an entry tagged `#idempotent · #config-drift · #declarative` that describes this exact shape. Find and follow it.
```

### C.4 — `test-d-log-tail-aggregator/spec.md`

```markdown
# Script D — Log-tail aggregator

## Task

Write a bash script at `scripts/log-tail-aggregator.sh` that tails multiple log files in parallel, aggregates lines matching a regex into a tempfile, and shuts down cleanly on SIGINT or timeout.

## Behavior

- Positional arguments: one or more log file paths. Each is tailed with `tail -F --follow=name`.
- `--pattern REGEX` (required): extended regex applied to tailed lines; matches are aggregated.
- `--duration SECONDS` (optional): exit cleanly after this many seconds; default is to run until SIGINT.
- Matching lines are written to a tempfile (via `mktemp`) prefixed with timestamp + source filename.
- On shutdown (SIGINT or timeout):
  1. Stop all background tail processes.
  2. Read the tempfile; produce a per-file match count summary.
  3. Remove the tempfile.
- Use `trap` on EXIT to guarantee cleanup.
- Decompose into functions: at minimum `start_tails`, `aggregate`, `summarize`, `cleanup`.

## Arguments

- **Positional:** one or more log file paths.
- **`-p, --pattern REGEX`** — required.
- **`-d, --duration SECONDS`** — optional.
- **`-h, --help`** — usage.

## Platform

macOS with GNU coreutils. `tail -F` exists on both macOS and Linux.

## Fixtures

`fixtures/tail-logs/` — three log files. `fixtures/driver.sh` appends lines on a timer while the aggregator runs. Use `--duration 5` for bounded testing.

## Reference

Follow `refs/reference.md`. Source `scripts/lib/printer.func`. Pay particular attention to §Temp Files, §Functions, §Exit, §Checks.
```

---

## Appendix D — Fixture setup (run verbatim)

Fixtures are generated, not authored — the PM runs these commands to stand up the test environment.

### D.1 — Script A hostnames

```bash
mkdir -p tmp/qa/test-a-cert-expiry/fixtures
cat > tmp/qa/test-a-cert-expiry/fixtures/hostnames.txt <<'EOF'
# TLS cert-expiry test hostnames
# Blank lines and comment lines are skipped.

github.com
cloudflare.com
www.google.com

# Intentionally expired cert (public test endpoint)
expired.badssl.com

# Intentionally unreachable (nonexistent DNS)
this-host-does-not-exist-anywhere.example
EOF
```

### D.2 — Script B log fixtures (timestamp-sensitive)

```bash
mkdir -p tmp/qa/test-b-log-archival/fixtures/logs
cd tmp/qa/test-b-log-archival/fixtures/logs

gtouch -d "1 day ago"    web-recent.log
gtouch -d "7 days ago"   web-boundary.log
gtouch -d "11 days ago"  web-2w.log
gtouch -d "14 days ago"  app-2w.log
echo "old archive" > web-old.log && gzip web-old.log
gtouch -d "33 days ago"  web-old.log.gz
gtouch -d "42 days ago"  web-ancient.log
gtouch -d "100 days ago" readme.txt  # non-log, must be ignored

cd -
cat > tmp/qa/test-b-log-archival/fixtures/EXPECTED.md <<'EOF'
# Expected post-run state (defaults: --compress-days 7, --delete-days 30)

- web-recent.log     — unchanged (1 day old)
- web-boundary.log   — CA's interpretation of "older than N" determines whether this is compressed; either is acceptable
- web-2w.log         — compressed to web-2w.log.gz
- app-2w.log         — compressed to app-2w.log.gz
- web-old.log.gz     — deleted (33 days > 30)
- web-ancient.log    — compressed, then the resulting .gz deleted (42 days > 30)
- readme.txt         — unchanged (not *.log)

Idempotency: re-run produces no additional changes.
EOF
```

### D.3 — Script C config fixtures

```bash
mkdir -p tmp/qa/test-c-config-drift/fixtures
cat > tmp/qa/test-c-config-drift/fixtures/target.conf <<'EOF'
# Sample application config
# Pre-existing entries below; do not touch lines outside the managed block.

listen_port = 8080
log_level = info
timeout = 30

# === managed block below ===
max_connections = 100
workers = 4
EOF

cat > tmp/qa/test-c-config-drift/fixtures/spec.conf <<'EOF'
# Required parameters.

max_connections = 100
workers = 4
enable_tls = true
tls_min_version = 1.2
access_log = /var/log/app/access.log
EOF
```

### D.4 — Script D tail-log fixtures + driver

```bash
mkdir -p tmp/qa/test-d-log-tail-aggregator/fixtures/tail-logs
cd tmp/qa/test-d-log-tail-aggregator/fixtures/tail-logs

cat > app.log <<'EOF'
2026-04-13T08:00:01 INFO  app started
2026-04-13T08:00:05 INFO  accepting connections
2026-04-13T08:01:02 ERROR db handshake failed
EOF

cat > web.log <<'EOF'
2026-04-13T08:00:02 INFO  web listening on :443
2026-04-13T08:00:30 WARN  slow response 1800ms /api/search
EOF

cat > db.log <<'EOF'
2026-04-13T08:00:03 INFO  db ready
2026-04-13T08:01:02 ERROR connection reset
EOF

cd -
cat > tmp/qa/test-d-log-tail-aggregator/fixtures/driver.sh <<'EOF'
#!/usr/bin/env bash
# Driver: append lines to the three tail-logs every ~300ms while the
# aggregator runs. Start in background before invoking the aggregator.
set -euo pipefail
tail_dir="$(dirname "$0")/tail-logs"
lines=(
    "INFO  heartbeat"
    "INFO  healthcheck ok"
    "WARN  slow query 1200ms"
    "ERROR disk pressure at 95%"
    "INFO  request processed 200"
    "ERROR client timeout"
)
for i in $(seq 1 15); do
    ts="$(gdate -Is)"
    idx=$(( i % ${#lines[@]} ))
    target=$(( i % 3 ))
    case "$target" in
        0) file="$tail_dir/app.log" ;;
        1) file="$tail_dir/web.log" ;;
        2) file="$tail_dir/db.log" ;;
    esac
    printf '%s %s\n' "$ts" "${lines[idx]}" >> "$file"
    sleep 0.3
done
EOF
chmod +x tmp/qa/test-d-log-tail-aggregator/fixtures/driver.sh
```


---

## Appendix E — Quality rubric (canonical)

Copy to `tmp/qa/scoring-rubric.md`.

```markdown
# Quality Rubric

For each script, the PM scores the **original** `script.sh` against this rubric. Remediation (if produced) is logged separately.

## Dimensions

### 1. Runtime

- **pass** — script runs on the fixtures and produces the specified output.
- **partial** — runs but output is wrong, incomplete, or warns.
- **fail** — does not run (syntax error, missing tool, crash).

### 2. Conformance (per exercised reference section, 0–3)

- **3** — rule applied correctly, matches the reference example/shape.
- **2** — rule applied with minor deviation (style, ordering, naming).
- **1** — rule applied partially or mixed with a competing pattern.
- **0** — rule violated or ignored.

Sections to score are listed in the spec's §Exercises (where applicable) or inferred from what the script touches.

### 3. Defects (count + list)

Any deviation from the reference or any correctness issue. Categorized briefly:

- **violation** — reference explicitly prohibits what the script does.
- **shortfall** — reference prescribes a shape the script failed to meet.
- **correctness** — script behavior differs from the spec (wrong output, missed case).

List each defect with: short name, file:line, one-line description.

## Score record format (`score.md`)

    # Script X — Score

    ## Runtime
    <pass/partial/fail + one-line reason>

    ## Conformance
    | Section | Score | Notes |
    |---|---|---|
    | ...

    ## Defects (N)
    1. **<name>** [violation|shortfall|correctness] — <file:line> — <description>
```
