#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEBUG_WAVES="${DEBUG_WAVES:-0}"
START="$(date +%s)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m4-regression.XXXXXX")"
TEST_ROOT="$TMP_ROOT/repo"
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; INTERNAL_CHECKS=0

cleanup(){
  if [[ "$DEBUG_WAVES" == 1 ]];then
    mkdir -p "$ROOT_DIR/sim/waves/m4_regression_debug"
    find "$TEST_ROOT/sim/waves" -type f \( -name '*.vcd' -o -name '*.fst' \) -exec cp -f {} "$ROOT_DIR/sim/waves/m4_regression_debug/" \; 2>/dev/null||true
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT INT TERM
summary(){
  echo "M4_0_M4_2_REGRESSION_STATUS=$1"
  echo "TESTS_RUN=$TESTS_RUN"
  echo "TESTS_PASSED=$TESTS_PASSED"
  echo "TESTS_FAILED=$TESTS_FAILED"
  echo "INTERNAL_CHECKS=$INTERNAL_CHECKS"
  echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
}
run_test(){
  local name="$1" limit="$2" checks="$3" log status begun elapsed;shift 3
  TESTS_RUN=$((TESTS_RUN+1));log="$TMP_ROOT/test_${TESTS_RUN}.log";begun="$(date +%s)"
  set +e; timeout "$limit" "$@" >"$log" 2>&1;status=$?;set -e
  elapsed=$(($(date +%s)-begun))
  if [[ $status -eq 0 ]];then
    TESTS_PASSED=$((TESTS_PASSED+1));INTERNAL_CHECKS=$((INTERNAL_CHECKS+checks))
    printf 'M4_TEST name=%q status=PASS elapsed_s=%d checks=%d\n' "$name" "$elapsed" "$checks"
  else
    TESTS_FAILED=$((TESTS_FAILED+1));printf 'M4_TEST name=%q status=FAIL exit=%d elapsed_s=%d\n' "$name" "$status" "$elapsed";tail -100 "$log";summary FAIL;exit "$status"
  fi
}

mkdir -p "$TEST_ROOT"
tar -C "$ROOT_DIR" --exclude='./.git' --exclude='./sim/logs/*' --exclude='./sim/outputs/*' --exclude='./sim/waves/*' --exclude='./ref_model/c_ref/build' --exclude='*/__pycache__' -cf - . | tar -C "$TEST_ROOT" -xf -
cd "$TEST_ROOT";export PYTHONPATH="$TEST_ROOT${PYTHONPATH:+:$PYTHONPATH}" DEBUG_WAVES
echo "M4_REGRESSION_COMMIT=$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
echo "DEBUG_WAVES=$DEBUG_WAVES"
run_test workspace 30s 524 ./sim/scripts/run_poly_workspace.sh
run_test poly_add 45s 8449 ./sim/scripts/run_poly_add_pipe.sh
run_test poly_sub 45s 8449 ./sim/scripts/run_poly_sub_pipe.sh
run_test poly_reduce 45s 8193 ./sim/scripts/run_poly_reduce_pipe.sh
run_test poly_ntt 75s 8451 ./sim/scripts/run_poly_ntt_pipe.sh
run_test poly_intt 80s 8451 ./sim/scripts/run_poly_intt_pipe.sh
run_test poly_roundtrip 90s 15360 ./sim/scripts/run_poly_ntt_intt_roundtrip.sh
run_test vector_repro 45s 7 bash -c 'mkdir -p "$1/a" "$1/b";python3 tb/tools/gen_m4_poly_vectors.py --output-dir "$1/a";python3 tb/tools/gen_m4_poly_vectors.py --output-dir "$1/b";diff -qr "$1/a" "$1/b"' _ "$TMP_ROOT"
run_test m3_unified 200s 361656 ./sim/scripts/run_m3_regression.sh
run_test m2_memory 70s 5417 ./sim/scripts/run_m2_1_primitives.sh
run_test m2_arithmetic 130s 312935 ./sim/scripts/run_m2_2_regression.sh
run_test legacy_poly_add 60s 1024 ./sim/scripts/run_poly_add.sh
run_test legacy_poly_sub 60s 1024 ./sim/scripts/run_poly_sub.sh
run_test basemul 60s 514 ./sim/scripts/run_basemul_unit.sh
run_test basemul_address 60s 256 ./sim/scripts/run_poly_basemul_addr_gen.sh
run_test poly_basemul 60s 768 ./sim/scripts/run_poly_basemul_montgomery.sh
run_test python_selftest 30s 1 python3 -m ref_model.python_model.selftest
run_test python_foundations 30s 13 python3 -m ref_model.python_model.test_foundations
run_test python_schema 30s 5 python3 -m ref_model.compare.test_compare_tools
summary PASS
