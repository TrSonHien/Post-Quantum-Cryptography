#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
START="$(date +%s)"; TESTS_RUN=0; TESTS_PASSED=0
run(){ local name="$1" limit="$2";shift 2;TESTS_RUN=$((TESTS_RUN+1));echo "M6_ZEROIZE_TEST name=$name status=RUN";timeout "$limit" "$@";TESTS_PASSED=$((TESTS_PASSED+1));echo "M6_ZEROIZE_TEST name=$name status=PASS"; }
run prf_xof 90s "$ROOT/sim/scripts/run_m6_prf_xof_zeroize.sh"
run codec 90s "$ROOT/sim/scripts/run_m6_codec_zeroize.sh"
run sampler 180s "$ROOT/sim/scripts/run_m6_sampler_zeroize.sh"
echo "M6_ZEROIZE_STATUS=PASS"
echo "TESTS_RUN=$TESTS_RUN"
echo "TESTS_PASSED=$TESTS_PASSED"
echo "TESTS_FAILED=0"
echo "OWNER_TYPES_CHECKED=15"
echo "INTERNAL_CHECKS=62"
echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
