#!/usr/bin/env bash
#  PURPOSE: Fleet patch-readiness audit — verify hosts are reachable
#           and responsive on expected ports.
# -----------------------------------------------------------------------------
#  PREREQS: a) source scripts/vars.env
#           b) nc (netcat) and curl installed
#           c) hosts CSV: address,role (one per line)
# -----------------------------------------------------------------------------
#  EXECUTE: scripts/target.sh [-hv] [HOSTS_FILE]
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
manifest_url='https://raw.githubusercontent.com/todd-dsm/basher/main/scripts/hosts.csv'

# Arrays
ports=(443 80)
required_tools=(nc curl)

# Data — structured inputs the script reads
hosts_file="${1:-}"


# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
# Output helpers: print_goal, print_req, print_pass, print_info, print_error
source scripts/lib/printer.func


# Print invocation help.
usage() {
    cat <<'EOF'
Usage: scripts/target.sh [-hv] [HOSTS_FILE]

  -h, --help             show this help
  -v, --verbose          verbose output
  HOSTS_FILE             path to hosts CSV (default: downloaded from remote)
EOF
}


# Parse flags; populate script-wide vars.
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
}


# Probe a single host:port with nc; return 0/1.
check_port() {
    local host="$1" port="$2"
    nc -z -w "$timeout" "$host" "$port" >/dev/null 2>&1
}


# Capitalize the first letter of a named variable.
capitalize() {
    local -n ref="$1"
    ref="${ref^}"
}


# Clean stale artifacts from a prior run's temp dir.
clean_artifacts() {
    local target_dir="$1"
    if ! find "$target_dir" -type f -name '*.tmp' \
        -mtime +1 -exec rm {} +; then
        print_error "failed to clean stale artifacts in $target_dir"
    else
        print_pass
    fi
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
# ensure required tools are present
# ---
print_req 'Verifying required tools...'
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        print_error "required tool not found: $tool"
    fi
done


# ---
# create temp work space
# ---
print_req 'Creating temp working directory...'
tmp_dir="$(mktemp -d /tmp/target-XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT
if [[ ! -d "$tmp_dir" ]]; then
    print_error "temp directory was not created: $tmp_dir"
else
    print_pass
fi


# ---
# prepare data file
# ---
print_req 'Preparing data file...'
if [[ -z "$hosts_file" ]]; then
    print_info "no data file provided; downloading from manifest_url"
    hosts_file="$manifest_url"
    manifest="${tmp_dir}/hosts.csv"
    if ! curl -fsSL -o "$manifest" "$hosts_file"; then
        print_error "failed to fetch data file"
    else
        hosts_file="$manifest"
        print_pass
    fi
fi

if [[ -z "${manifest:-}" ]]; then
    manifest="$hosts_file"
fi


# -----------------------------------------------------------------------------
# Audit hosts
# -----------------------------------------------------------------------------
print_goal 'Auditing hosts...'


# ---
# check host reachability on expected ports
# ---
print_req 'Checking host reachability on expected ports...'
while IFS=, read -r addr _; do
    [[ "$addr" = \#* ]] && continue
    host="${addr%%.*}"
    capitalize host
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
done < "$manifest"


# ---
# clean stale artifacts
# ---
print_req 'Cleaning stale artifacts...'
clean_artifacts "$tmp_dir"


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
