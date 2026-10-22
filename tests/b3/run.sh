#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then
  printf 'usage: bash tests/run.sh <WORKSPACE>/chipyard\n' >&2
  exit 2
fi
root=$(realpath "$1")
tests=$(cd "$(dirname "$0")" && pwd)
config=${B3_CONFIG:-Hytron64SmallB3DualAddR1p1Config}
sim="$root/sims/verilator/simulator-chipyard.harness-$config"
test -x "$sim"
for case_id in 0 1 2 3; do
  log="$tests/build/case${case_id}.run.log"
  if [ -f "$log" ]; then
    cp -p "$log" "$log.before_testfix_r2.$(date +%Y%m%d_%H%M%S)"
  fi
  if (
    cd "$root/sims/verilator"
    "$sim" +permissive +verbose +max-cycles=1000000 +permissive-off \
      "$tests/build/case${case_id}.elf"
  ) >"$log" 2>&1; then
    # The assembly writes tohost=1 only AFTER both software RF checks.
    # A fail branch or unexpected trap writes tohost=3 (nonzero process exit).
    printf '\nB3_SOFTWARE_EXIT=0\n' >>"$log"
  else
    status=$?
    printf 'B3_CASE%s_SIMULATOR_EXIT=%s\n' "$case_id" "$status" >&2
    tail -n 40 "$log" >&2
    exit "$status"
  fi
  python3 "$tests/check_log.py" "$case_id" "$log"
done
