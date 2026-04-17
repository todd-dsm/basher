# Software Requirements — Four Sysadmin Scripts

**Document ID:** bash-test-reqs
**Version:** 2.0
**Date:** 2026-04-13
**Status:** Issued to PM

---

## 1. Introduction

### 1.1 Purpose

This document specifies four bash scripts to be produced by the engineering team. Each script is a sysadmin utility with a clearly scoped behavior, a fixed argument surface, and a defined set of inputs and outputs. All four must conform to the style reference that `cascadian:bash` reads from its cache.

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

| Artifact | Source |
|---|---|
| Style reference | Cached by `cascadian:bash` at `~/.claude/cascadian/basher/reference.md` (upstream: `https://raw.githubusercontent.com/todd-dsm/basher/refs/heads/main/reference.md`). The skill owns freshness. |

### 1.5 Overview

§2 defines the product and its user classes. §3 specifies each script and the deliverables. §4 defines acceptance. Appendices C, D, E provide the per-script task spec, the fixture setup commands, and the quality rubric respectively.

---

## 2. Overall Description

### 2.1 Product perspective

Four independent bash scripts, each produced by a separate CA invocation. The scripts target sysadmin workflows (TLS probing, log retention, config synchronization, live log aggregation). Each conforms to the style reference the skill reads from its cache.

### 2.2 Product functions

1. **Author** — four bash scripts, each produced by an independent CA working from a spec + the style reference.
2. **Execute** — each script runs against its fixtures; output captured.
3. **Score** — each script is evaluated against the quality rubric in Appendix E.
4. **Remediate** (bounded) — if a defect in an emitted script is addressed by **unambiguous, cite-able** content in the cached `reference.md`, the PM produces a remediated script alongside the original as `script-remediated.sh`. Both are preserved. When the fix requires judgment, invention, or content not in the reference, **do not remediate** — record the defect in the results and leave the original unchanged. Test: *"Can I name a specific rule in `reference.md` that says do X instead?"* If yes → remediate. If you're reasoning "well, what if we…" → stop, record, move on.
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
- **Per-script layout:** each script operates in its own test directory under `tmp/` in the working repo — the PM's conventional home for ephemeral test artifacts. Directories and their fixtures are removed after the cycle closes. Exact layout under `tmp/` is the PM's choice. The *internal shape* — where the script is emitted, where the printer is sourced from, how the script tree is laid out — is determined by `cascadian:bash` per its skill conventions, not prescribed by this SRD. The PM creates the per-test directory, stages `spec.md` inside it, builds the test data files per Appendix D (from that directory as CWD), and invokes the skill from that directory; the skill reads `reference.md` from its own cache and places the script according to its own rules.

Per-test directory must contain, at PM's setup time:

- `spec.md` — Appendix C, staged verbatim
- Test data files — built per Appendix D; the PM runs the Appendix D block from the per-test CWD

And, after the cycle completes:

- `run.log` — execution transcript
- `score.md` — PM's score per Appendix E

The authored script and any remediated variant land wherever `cascadian:bash` places them; the PM discovers the path from the skill's output, not from this document.

Session-level (PM chooses the parent):

```
<session-dir>/
├── README.md                 # PM's session notes
└── scoring-rubric.md         # Appendix E staged verbatim
```

### 2.5 Constraints

- **C1. Blind authorship.** Each CA produces its script from its `spec.md` + the cached `reference.md` (read by the skill) + nothing else. No reading of other scripts, prior outputs, or ambient material.
- **C2. No improvisation.** CAs follow the happy path. When the happy path does not satisfy the spec, they follow the style reference's Further-research links. No improvisation beyond that.
- **C3. Script preservation.** The original `script.sh` is never modified. Remediation (if any) is a new file.
- **C4. Remediation bound.** Remediation uses only content from the cached `reference.md`. Any defect the reference does not address is recorded and left uncorrected.

### 2.6 Assumptions

- `cascadian:bash` is installed and its cache at `~/.claude/cascadian/basher/reference.md` is reachable (the skill refreshes it on invocation per its freshness rule).

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

- **IR.1 — CA contract.** Each CA is invoked with read-only access to its `spec.md`. Style knowledge comes from the cached `reference.md`, which the skill reads on its own — the caller does not stage it. The CA produces the script named in the spec via its own conventions; path placement is the CA's responsibility, not the caller's. It returns a short note listing any judgment calls. No other outputs.
- **IR.2 — Script invocation.** Scripts are invoked from the CWD in which they were produced (which the CA treats as a consumer repo root).

### 3.4 Deliverables

The only path-pinned deliverable is the top-level results report at `/tmp/bash-test-results.md`. All other artifacts live at PM-chosen paths in the working repo, per §2.4 (internal shape determined by `cascadian:bash`).

**Per-script directory** — one per test, PM-chosen parent:

| File | Source | Required |
|---|---|---|
| `spec.md` | Appendix C, staged verbatim | yes |
| Test data files | Appendix D, built verbatim at the per-test CWD | yes |
| Authored script | CA output via `cascadian:bash`, preserved untouched; named per Appendix C | yes |
| Remediated script | PM output per §2.2.4 | optional |
| `run.log` | execution transcript (stdout + stderr) | yes |
| `score.md` | PM scoring per Appendix E | yes |

**Session-level** — PM-chosen parent:

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
| 1.0–1.5 | 2026-04-13 | OP | Initial drafts (superseded). |
| 2.0 | 2026-04-13 | OP | Full rewrite into stable shape. |
| 2.1 | 2026-04-13 | OP | Reduced reference set to what the team needs at author time. |
| 2.2 | 2026-04-13 | OP | Removed file-placement instructions; the consuming skill owns placement. |
| 2.3 | 2026-04-13 | OP | Five tightenings from execution feedback (S1–S4, S6): counter semantics in C.2; standardized platform notes; canonical scripts path; rubric severity tiers; build location unbound from any fixed parent. |
| 2.4 | 2026-04-13 | OP | Removed post-cycle disposition section (out of PM scope). Trimmed change-log entries to production-relevant summaries. |
| 2.5 | 2026-04-14 | OP | Per-test directories now explicitly live under `tmp/` — the working repo's ephemeral-artifacts convention. Fixtures removed after each cycle. Removes ambiguity about where the PM places per-test material. |

---

## Appendix C — Per-script `spec.md` (canonical, copy verbatim)

Each block below is the **complete contents** of the named spec file. The PM copies each verbatim to the per-test directory as `spec.md` at the start of the cycle.

### C.1 — `test-a-cert-expiry/spec.md`

```markdown
# Script A — TLS cert-expiry checker

## Task

Produce a bash script named `cert-expiry` via `cascadian:bash` that, given a file of hostnames, reports the TLS certificate expiry status of each. The skill places the script; do not prescribe its path here.

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

macOS with GNU coreutils installed; use the `g`-prefix variants (`gdate`, `gfind`, `gsed`) where BSD semantics differ. The target is GNU semantics.

## Fixtures

`hostnames.txt` — provided at the CWD.

## Reference

Follow the style reference exactly (the skill reads it from cache). Use only the shapes and rules it teaches. Source the printer library per the skill's convention (assume it is staged and reachable). When a case doesn't fit an example, consult the Further-research links in the relevant section.

Do NOT improvise beyond what the reference describes. Do NOT invent print helpers beyond `print_goal`, `print_req`, `print_pass`, `print_error`.
```

### C.2 — `test-b-log-archival/spec.md`

```markdown
# Script B — Log archival

## Task

Produce a bash script named `log-archival` via `cascadian:bash` that enforces a retention policy on a directory of log files. The skill places the script; do not prescribe its path here.

## Behavior

- Positional: log directory. Find regular files matching `*.log` and `*.log.gz` and process per policy:
  - `*.log` files older than `N` days (`--compress-days`): gzip in place.
  - `*.log` and `*.log.gz` files older than `M` days (`--delete-days`): delete.
- Idempotent: re-running on an already-compliant directory produces zero additional changes; all files report "kept" or "already compressed".
- Report counts:
  - **compressed** — files compressed during this run
  - **deleted** — files deleted during this run (originals or pre-existing `.gz` archives)
  - **already compressed** — files that were `.log.gz` *before this run began* (snapshot at entry). Files compressed during this run are counted only in `compressed`, not here.
  - **kept** — `.log` files present within the retention window; unchanged by this run
- Precondition: `M > N`; otherwise exit via `print_error`.

## Arguments

- **Positional:** `LOG_DIR` (required).
- **`-n, --compress-days DAYS`** — default `7`.
- **`-m, --delete-days DAYS`** — default `30`.
- **`-h, --help`** — usage.

## Platform

macOS with GNU coreutils installed; use the `g`-prefix variants (`gdate`, `gfind`, `gsed`) where BSD semantics differ. The target is GNU semantics. Retention rules apply to both `.log` and `.log.gz` forms.

## Fixtures

`logs/` — pre-populated with files at a range of ages, at the CWD. Expected post-run state in `EXPECTED.md`, also at the CWD.

## Reference

Follow the style reference (the skill reads it from cache). Source the printer library per the skill's convention.
```

### C.3 — `test-c-config-drift/spec.md`

```markdown
# Script C — Config-drift remediation

## Task

Produce a bash script named `config-sync` via `cascadian:bash` that ensures every `key = value` line in a spec file is present in a target config file. The skill places the script; do not prescribe its path here.

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

macOS with GNU coreutils installed; use the `g`-prefix variants (`gdate`, `gfind`, `gsed`) where BSD semantics differ. The target is GNU semantics. In particular, use GNU `sed -i` (no empty-string argument).

## Fixtures

`target.conf`, `spec.conf` at the CWD. Anchor: `# === managed block below ===`.

## Reference

Follow the style reference (the skill reads it from cache). Source the printer library per the skill's convention.

**Note:** the reference's §Examples section contains an entry tagged `#idempotent · #config-drift · #declarative` that describes this exact shape. Find and follow it.
```

### C.4 — `test-d-log-tail-aggregator/spec.md`

```markdown
# Script D — Log-tail aggregator

## Task

Produce a bash script named `log-tail-aggregator` via `cascadian:bash` that tails multiple log files in parallel, aggregates lines matching a regex into a tempfile, and shuts down cleanly on SIGINT or timeout. The skill places the script; do not prescribe its path here.

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

macOS with GNU coreutils installed; use the `g`-prefix variants (`gdate`, `gfind`, `gsed`) where BSD semantics differ. The target is GNU semantics. `tail -F` is common to both macOS and Linux.

## Fixtures

`tail-logs/` — three log files at the CWD. `driver.sh` (at the CWD) appends lines on a timer while the aggregator runs. Use `--duration 5` for bounded testing.

## Reference

Follow the style reference (the skill reads it from cache); source the printer library per the skill's convention. Pay particular attention to §Temp Files, §Functions, §Exit, §Checks.
```

---

## Appendix D — Fixture setup (run verbatim)

Fixtures are generated, not authored — the PM runs these commands to stand up the test environment.

All commands below use paths relative to the per-test CWD. For each test, the PM first creates the per-test directory, `cd`s into it, then runs the corresponding block.

### D.1 — Script A hostnames

```bash
cat > hostnames.txt <<'EOF'
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
mkdir -p logs
cd logs

gtouch -d "1 day ago"    web-recent.log
gtouch -d "7 days ago"   web-boundary.log
gtouch -d "11 days ago"  web-2w.log
gtouch -d "14 days ago"  app-2w.log
echo "old archive" > web-old.log && gzip web-old.log
gtouch -d "33 days ago"  web-old.log.gz
gtouch -d "42 days ago"  web-ancient.log
gtouch -d "100 days ago" readme.txt  # non-log, must be ignored

cd -
cat > EXPECTED.md <<'EOF'
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
cat > target.conf <<'EOF'
# Sample application config
# Pre-existing entries below; do not touch lines outside the managed block.

listen_port = 8080
log_level = info
timeout = 30

# === managed block below ===
max_connections = 100
workers = 4
EOF

cat > spec.conf <<'EOF'
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
mkdir -p tail-logs
cd tail-logs

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
cat > driver.sh <<'EOF'
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
chmod +x driver.sh
```


---

## Appendix E — Quality rubric (canonical)

Copy to the session-level `scoring-rubric.md`.

```markdown
# Quality Rubric

For each script, the PM scores the **original** CA-emitted script (wherever `cascadian:bash` placed it) against this rubric. Remediation (if produced) is logged separately.

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

Sections to score are listed in the spec's §Exercises (where applicable) or inferred from what the script touches. Aggregation (min, avg, full list, etc.) is PM discretion.

### 3. Defects (category + severity)

Every defect is categorized and severity-tagged.

**Category** (what kind of defect):
- **violation** — reference explicitly prohibits what the script does.
- **shortfall** — reference prescribes a shape the script failed to meet.
- **correctness** — script behavior differs from the spec (wrong output, missed case).

**Severity** (how impactful):
- **HIGH** — runtime failure, footgun-class (crashes, data loss, silent wrongness), security issue, idempotency break.
- **MEDIUM** — conformance violation without runtime impact, or a correctness issue the operator would likely notice.
- **LOW** — cosmetic drift, spec-silence-induced ambiguity, or style deviations with no behavioral consequence.

List each defect with: short name, category, severity, file:line, one-line description.

## Score record format (`score.md`)

    # Script X — Score

    ## Runtime
    <pass/partial/fail + one-line reason>

    ## Conformance
    | Section | Score | Notes |
    |---|---|---|
    | ...

    ## Defects (N)
    1. **<name>** [violation|shortfall|correctness, HIGH|MEDIUM|LOW] — <file:line> — <description>
```
