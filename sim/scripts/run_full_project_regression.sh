#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-full-project.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$T"' EXIT INT TERM
run(){ local n="$1" lim="$2" log="$T/$1.log" rc;shift 2;set +e;timeout "$lim" "$@">"$log" 2>&1;rc=$?;set -e;if((rc));then echo "FULL_PROJECT_TEST name=$n status=FAIL exit=$rc";tail -200 "$log";exit "$rc";else echo "FULL_PROJECT_TEST name=$n status=PASS";fi;}
export M8_FULL_VECTORS="${M8_FULL_VECTORS:-12}"
run m8_focused 7200s env M8_FOCUSED_VECTORS="$M8_FULL_VECTORS" "$R/sim/scripts/run_m8_regression.sh"
run m7_once 7200s env RUN_LOWER_REGRESSIONS=0 "$R/sim/scripts/run_m7_regression.sh"
run m6_once 4200s env RUN_LOWER_REGRESSIONS=0 "$R/sim/scripts/run_m6_regression.sh"
run m5_once 3600s env RUN_LOWER_REGRESSIONS=0 "$R/sim/scripts/run_m5_regression.sh"
run m4_once 2400s env RUN_LOWER_REGRESSIONS=0 "$R/sim/scripts/run_m4_regression.sh"
run m3_once 900s "$R/sim/scripts/run_m3_regression.sh"
echo "FULL_PROJECT_REGRESSION_STATUS=PASS";echo "M8_FOCUSED_RUNS=1";echo "M7_UNIFIED_RUNS=1";echo "M6_UNIFIED_RUNS=1";echo "M5_UNIFIED_RUNS=1";echo "M4_UNIFIED_RUNS=1";echo "M3_UNIFIED_RUNS=1";echo "M2_ADJACENCY_RUNS=1";echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
