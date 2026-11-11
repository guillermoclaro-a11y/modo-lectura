#!/bin/bash
# Tests the user-facing CLI argument handling (no root, nothing is blocked).
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CLI="$ROOT/package/contents/code/modo-lectura"
export XDG_STATE_HOME=$(mktemp -d) XDG_CONFIG_HOME=$(mktemp -d) LANG=C
trap 'rm -rf "$XDG_STATE_HOME" "$XDG_CONFIG_HOME"' EXIT
fails=0
expect() {  # expect <description> <grep pattern> <args...>
    local d=$1 p=$2; shift 2
    local out; out=$("$CLI" "$@" 2>&1)   # the CLI exits 1 on errors; check its output
    if grep -q -- "$p" <<< "$out"; then echo "  ok   $d"; else echo "  FAIL $d"; fails=$((fails+1)); fi
}
expect "status is valid JSON"      '"active":false'     status
expect "rejects 0 minutes"         'Duration must be'   start 0
expect "rejects 999 minutes"       'Duration must be'   start 999
expect "rejects text minutes"      'Duration must be'   start abc
expect "rejects unknown option"    'Unknown option'     start 25 --nope
python3 -c 'import json,subprocess,sys; json.loads(subprocess.run([sys.argv[1],"status"],capture_output=True,text=True).stdout)' "$CLI" \
    && echo "  ok   status parses as JSON" || { echo "  FAIL status parses as JSON"; fails=$((fails+1)); }
grep -q 'La duración' <<< "$(LANG=es_AR.UTF-8 "$CLI" start 0)" \
    && echo "  ok   Spanish messages" || { echo "  FAIL Spanish messages"; fails=$((fails+1)); }
echo; (( fails == 0 )) && echo "cli: all tests passed" || { echo "cli: $fails failed"; exit 1; }
