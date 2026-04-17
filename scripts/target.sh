#!/usr/bin/env bash
#  PURPOSE: Fleet patch-readiness audit — verify hosts are reachable
#           and responsive on expected ports.
# -----------------------------------------------------------------------------
#  PREREQS: a) source scripts/vars.env
#           b) nc (netcat) and curl installed
#           c) hosts CSV: hostname,address,role (one per line)
# -----------------------------------------------------------------------------
#  EXECUTE: scripts/target.sh [-hv] [-t THRESHOLD] HOSTS_FILE
# -----------------------------------------------------------------------------
set -euo pipefail


# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------
# ENV — required external inputs, assert early
: "${SSH_KEY_PATH?  SSH_KEY_PATH must point at a readable key file}"

# Assignments and flags
verbose=false
timeout="${CONNECT_TIMEOUT:-3}"
pass_count=0
fail_count=0
total_count=0

# Arrays
ports=(443 80)
required_tools=(nc curl)

# Data — structured inputs the script reads (set by parse_args)
hosts_file=''


# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
# Output helpers: print_goal, print_req, print_pass, print_error
source scripts/lib/printer.func


# Print invocation help.
usage() {
    cat <<'EOF'
Usage: scripts/target.sh [-hv] HOSTS_FILE

  -h, --help             show this help
  -v, --verbose          verbose output
  HOSTS_FILE             path to hosts CSV
EOF
}


# Parse flags and positional args; populate script-wide vars.
parse_args() {
    while :; do
        case "${1:-}" in
            -h|--help)      usage; exit 0 ;;
            -v|--verbose)   verbose=true ;;
            --)             shift; break ;;
            -?*)            usage >&2; exit 2 ;;
            *)              break ;;
        esac
        shift
    done
    : "${1?missing HOSTS_FILE; see -h}"
    hosts_file="$1"
}


# Probe a single host:port with nc; return 0/1.
check_port() {
    local host="$1" port="$2"
    nc -z -w "$timeout" "$host" "$port" >/dev/null 2>&1
}


# Clean stale artifacts from a prior run's temp dir.
clean_artifacts() {
    local target_dir="$1"
    find "$target_dir" -type f -name '*.tmp' \
        -mtime +1 -exec rm {} +
}


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
parse_args "$@"


# -----------------------------------------------------------------------------
# Prepare workspace
# -----------------------------------------------------------------------------
print_goal 'Preparing the workspace...'


# ---
# Ensure the required tools are present on the system
# ---
print_req 'Verifying required tools...'
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        print_error "required tool not found: $tool"
    fi
done
print_pass


# ---
# create temp work space
# ---
print_req 'Creating temp working directory'
tmp_dir="$(mktemp -d /tmp/target-XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT
print_pass


# ---
# download patch manifest
# ---
print_req 'Downloading patch manifest...'
manifest_url="${MANIFEST_URL:-https://raw.githubusercontent.com/todd-dsm/basher/main/reference.md}"
manifest="${tmp_dir}/manifest.csv"
if curl -fsSL -o "$manifest" "$manifest_url"; then
    print_pass
else
    print_error "failed to fetch manifest: $manifest_url"
fi


# ---
# clean stale artifacts from prior runs
# ---
print_req 'Cleaning stale artifacts...'
clean_artifacts "$tmp_dir"
print_pass


# -----------------------------------------------------------------------------
# Audit hosts
#  * iterate hosts CSV line by line
#  * probe each host on ports 443 and 80
#  * per-host continue-on-error
# -----------------------------------------------------------------------------
print_goal 'Auditing hosts'


# ---
# REQ1
# ---
print_req 'Check host reachability on expected ports'
while IFS= read -r line; do
    [[ "$line" = \#* ]] && continue
    host="${line%%,*}"
    addr="${line#*,}"
    addr="${addr%%,*}"
    total_count=$((total_count + 1))
    host_ok=true
    for port in "${ports[@]}"; do
        print_req "$host ($addr) :$port"
        if check_port "$addr" "$port"; then
            print_pass
        else
            print_error "$host: port $port unreachable" || true
            host_ok=false
        fi
    done
    if [[ "$host_ok" = true ]]; then
        pass_count=$((pass_count + 1))
    else
        fail_count=$((fail_count + 1))
    fi
done < "$hosts_file"


# -----------------------------------------------------------------------------
# REPORT
# -----------------------------------------------------------------------------
printf '\n\n%s\n' "

Patch-readiness summary:

  hosts checked:  $total_count
  passed:         $pass_count
  failed:         $fail_count

"


# ---
# fin~
# ---
exit 0
