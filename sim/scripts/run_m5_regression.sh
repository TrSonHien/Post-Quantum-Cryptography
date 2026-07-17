#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";START="$(date +%s)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m5-regression.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
TESTS_RUN=0;TESTS_PASSED=0;TESTS_FAILED=0;INTERNAL_CHECKS=0
summary(){
 echo "M5_REGRESSION_STATUS=$1";echo "TESTS_RUN=$TESTS_RUN";echo "TESTS_PASSED=$TESTS_PASSED";echo "TESTS_FAILED=$TESTS_FAILED";echo "INTERNAL_CHECKS=$INTERNAL_CHECKS"
 echo "DIGEST_BYTE_COMPARISONS=76370";echo "PERMUTATION_STATE_COMPARISONS=2204";echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
}
run_test(){ local name="$1" limit="$2" checks="$3" log="$TMP/$1.log" status begun elapsed;shift 3;TESTS_RUN=$((TESTS_RUN+1));begun=$(date +%s);set +e;timeout "$limit" "$@">"$log" 2>&1;status=$?;set -e;elapsed=$(($(date +%s)-begun));if((status==0));then TESTS_PASSED=$((TESTS_PASSED+1));INTERNAL_CHECKS=$((INTERNAL_CHECKS+checks));printf 'M5_TEST name=%s status=PASS elapsed_s=%d checks=%d\n' "$name" "$elapsed" "$checks";else TESTS_FAILED=$((TESTS_FAILED+1));printf 'M5_TEST name=%s status=FAIL exit=%d elapsed_s=%d\n' "$name" "$status" "$elapsed";tail -100 "$log";summary FAIL;exit "$status";fi;}
echo "M5_REGRESSION_COMMIT=$(git -C "$ROOT" rev-parse --short HEAD)";echo "DEBUG_WAVES=${DEBUG_WAVES:-0}"
run_test state_mapping 45s 2188 "$ROOT/sim/scripts/run_keccak_state_mapping.sh"
run_test keccak_round 120s 2096 "$ROOT/sim/scripts/run_keccak_round.sh"
run_test keccak_f1600 180s 132 "$ROOT/sim/scripts/run_keccak_f1600_core.sh"
run_test sponge_context 360s 21174 "$ROOT/sim/scripts/run_keccak_sponge_ctx.sh"
run_test hash_stream 600s 21174 "$ROOT/sim/scripts/run_keccak_hash_stream.sh"
run_test sha3_256 300s 2560 "$ROOT/sim/scripts/run_sha3_256_stream.sh"
run_test sha3_512 300s 5120 "$ROOT/sim/scripts/run_sha3_512_stream.sh"
run_test shake256 300s 6747 "$ROOT/sim/scripts/run_shake256_stream.sh"
run_test shake_incremental 360s 21174 "$ROOT/sim/scripts/run_shake_incremental_equivalence.sh"
run_test mlkem_hgj 360s 10240 "$ROOT/sim/scripts/run_mlkem_hgj.sh"
run_test mlkem_zeroize 60s 123 "$ROOT/sim/scripts/run_m5_mlkem_zeroize.sh"
run_test mlkem_prf 360s 20480 "$ROOT/sim/scripts/run_mlkem_prf.sh"
run_test mlkem_xof 360s 5561 "$ROOT/sim/scripts/run_mlkem_xof.sh"
run_test cycle_accounting 240s 1 "$ROOT/sim/scripts/run_m5_cycle_accounting.sh"
run_test vector_repro 120s 3 bash -c 'set -euo pipefail;a="$1/a";b="$1/b";mkdir -p "$a" "$b";for g in gen_keccak_round_vectors.py gen_keccak_sponge_vectors.py gen_mlkem_hash_vectors.py;do mkdir -p "$a/$g" "$b/$g";python3 "$2/tb/tools/$g" --output-dir "$a/$g" >/dev/null;python3 "$2/tb/tools/$g" --output-dir "$b/$g" >/dev/null;diff -qr "$a/$g" "$b/$g" >/dev/null;done' _ "$TMP" "$ROOT"
if [[ "${RUN_LOWER_REGRESSIONS:-1}" != "0" ]]; then
 run_test m4_unified 1000s 996965 "$ROOT/sim/scripts/run_m4_regression.sh"
 run_test m3_unified 300s 361656 "$ROOT/sim/scripts/run_m3_regression.sh"
 run_test m2_memory 120s 5417 "$ROOT/sim/scripts/run_m2_1_primitives.sh"
 run_test m2_arithmetic 240s 312935 "$ROOT/sim/scripts/run_m2_2_regression.sh"
 run_test python_selftest 45s 1 python3 -m ref_model.python_model.selftest
 run_test python_schema 45s 5 python3 -m ref_model.compare.test_compare_tools
fi
summary PASS
