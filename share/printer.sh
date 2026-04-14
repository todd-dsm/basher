#!/usr/bin/env bash
#  PURPOSE: Exercise share/printer.func against the basher rules — each
#           test case is one array entry processed by a single loop. One
#           entry is a DELIBERATE FAIL so the red failure banner renders
#           visibly on every run.
# -----------------------------------------------------------------------------
#  PREREQS: a) bash 4+ (`local`, process substitution)
#           b) share/printer.func present alongside this script
#           c) terminal supports ANSI color escapes
# -----------------------------------------------------------------------------
#  EXECUTE: share/printer.sh
# -----------------------------------------------------------------------------
set -euo pipefail


# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------
# Capture files for inspecting helper output per test.
tmp_out=''
tmp_err=''

# Parallel arrays: one entry per test. Index i pairs descriptions[i] with
# functions[i]. Kept separate to avoid delimiter collisions with `||` and
# other shell metacharacters that appear in description text.
descriptions=(
    'print_goal writes to stdout, not stderr'
    'print_req writes to stdout, not stderr'
    'bare print_pass emits green test-passed marker'
    'print_pass discards caller args (§Checks no-args)'
    'print_error output goes to stderr, not stdout'
    'print_error returns 1 for errexit propagation'
    'set -e halts the script on a bare print_error call'
    'print_error with || true continues per-iteration'
    'special characters render literally'
    'empty-string arguments do not crash the helpers'
    'DELIBERATE FAIL — red failure banner renders'
)

functions=(
    check_goal_stdout
    check_req_stdout
    check_pass_bare
    check_pass_discards
    check_error_stderr
    check_returns_one
    check_set_e_halts
    check_or_true
    check_special_chars
    check_empty_string
    check_deliberate_fail
)


# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
# Output helpers: print_goal, print_req, print_pass, print_error
source share/printer.func


# Stage two capture files; paths land in tmp_out / tmp_err.
stage_captures() {
    tmp_out="$(mktemp /tmp/printer-sh-out-XXXXXX)"
    tmp_err="$(mktemp /tmp/printer-sh-err-XXXXXX)"
}


# Remove the capture files. Fired by the EXIT trap on every exit path.
cleanup_captures() {
    rm -f "$tmp_out" "$tmp_err"
}


# print_goal writes only to stdout.
check_goal_stdout() {
    print_goal 'Hello basher' >"$tmp_out" 2>"$tmp_err"
    [[ -s "$tmp_out" && ! -s "$tmp_err" ]]
}


# print_req writes only to stdout.
check_req_stdout() {
    print_req 'sample requirement' >"$tmp_out" 2>"$tmp_err"
    [[ -s "$tmp_out" && ! -s "$tmp_err" ]]
}


# Bare print_pass emits the green "test passed" marker.
check_pass_bare() {
    print_pass >"$tmp_out" 2>"$tmp_err"
    grep -q 'test passed' "$tmp_out" && [[ ! -s "$tmp_err" ]]
}


# print_pass drops caller arguments per §Checks (no-args contract).
check_pass_discards() {
    print_pass 'this string must not appear' >"$tmp_out" 2>"$tmp_err"
    grep -q 'test passed' "$tmp_out" \
        && ! grep -q 'this string must not appear' "$tmp_out"
}


# print_error writes to stderr only; stdout stays empty.
check_error_stderr() {
    : >"$tmp_out"; : >"$tmp_err"
    print_error 'stderr stream test' >"$tmp_out" 2>"$tmp_err" || true
    [[ ! -s "$tmp_out" && -s "$tmp_err" ]]
}


# print_error returns 1 so set -e can propagate the failure.
check_returns_one() {
    local rc=0
    print_error 'return-code test' 2>/dev/null || rc=$?
    [[ "$rc" -eq 1 ]]
}


# Under set -e, a bare print_error halts the calling script. Tested via
# `bash -c` so the inner shell is fully independent; expect non-zero exit
# AND no UNREACHABLE line in captured stdout.
check_set_e_halts() {
    local sub_rc=0
    bash -c '
        set -euo pipefail
        source share/printer.func
        print_error "halt test" 2>/dev/null
        echo UNREACHABLE
    ' >"$tmp_out" 2>"$tmp_err" || sub_rc=$?
    if [[ "$sub_rc" -eq 0 ]]; then
        return 1
    fi
    if grep -q 'UNREACHABLE' "$tmp_out"; then
        return 1
    fi
    return 0
}


# print_error || true neutralizes errexit so a loop can continue.
check_or_true() {
    local count=0
    local item
    for item in alpha bravo charlie; do
        print_error "per-item fail: $item" 2>/dev/null || true
        count=$((count + 1))
    done
    [[ "$count" -eq 3 ]]
}


# Shell metacharacters in helper arguments render literally.
check_special_chars() {
    print_goal "literal 'single' and \$dollar" >"$tmp_out" 2>"$tmp_err"
    grep -q "literal 'single' and \$dollar" "$tmp_out"
}


# Helpers tolerate empty-string arguments without aborting.
check_empty_string() {
    : >"$tmp_out"; : >"$tmp_err"
    print_goal  '' >>"$tmp_out" 2>>"$tmp_err"
    print_req   '' >>"$tmp_out" 2>>"$tmp_err"
    print_error '' >>"$tmp_out" 2>>"$tmp_err" || true
    [[ -s "$tmp_out" || -s "$tmp_err" ]]
}


# Intentional failure so the red banner renders every run. Not a real
# defect — this entry exists to prove the failure path is alive.
check_deliberate_fail() {
    return 1
}


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
stage_captures
trap 'cleanup_captures' EXIT


# -----------------------------------------------------------------------------
# Exercise each test condition
# -----------------------------------------------------------------------------
print_goal 'Printer library — conformance sweep'

for i in "${!descriptions[@]}"; do
    desc="${descriptions[i]}"
    func="${functions[i]}"
    print_req "$desc"
    if "$func"; then
        print_pass
    else
        print_error "$desc" || true
    fi
done


# -----------------------------------------------------------------------------
# REPORT
# -----------------------------------------------------------------------------
printf '\n\n%s\n' '
Printer library exercised:
  - print_goal   (stdout, centered banner)
  - print_req    (stdout, indented requirement)
  - print_pass   (stdout, bare "test passed"; args discarded)
  - print_error  (stderr, red banner, return 1; errexit-safe)

Exactly one red banner is expected (the DELIBERATE FAIL entry). Any
additional red banner names a real conformance violation.
'


# ---
# fin~
# ---
exit 0
