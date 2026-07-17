#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";D="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m4-full.XXXXXX")";T="$D/repo";START="$(date +%s)";RUN=0;PASS=0;FAIL=0;CHECKS=0;trap 'rm -rf "$D"' EXIT INT TERM
summary(){ echo "M4_REGRESSION_STATUS=$1";echo "TESTS_RUN=$RUN";echo "TESTS_PASSED=$PASS";echo "TESTS_FAILED=$FAIL";echo "INTERNAL_CHECKS=$CHECKS";echo "ELAPSED_SECONDS=$(($(date +%s)-START))";}
test_one(){ local n="$1" lim="$2" c="$3" log status;shift 3;RUN=$((RUN+1));log="$D/$RUN.log";set +e;timeout "$lim" "$@">"$log" 2>&1;status=$?;set -e;if [[ $status == 0 ]];then PASS=$((PASS+1));CHECKS=$((CHECKS+c));echo "M4_TEST name=$n status=PASS checks=$c";else FAIL=$((FAIL+1));echo "M4_TEST name=$n status=FAIL exit=$status";tail -100 "$log";summary FAIL;exit "$status";fi;}
mkdir -p "$T";tar -C "$R" --exclude='./.git' --exclude='./sim/logs/*' --exclude='./sim/outputs/*' --exclude='./sim/waves/*' --exclude='*/__pycache__' -cf - .|tar -C "$T" -xf -;cd "$T";export PYTHONPATH="$T${PYTHONPATH:+:$PYTHONPATH}" DEBUG_WAVES="${DEBUG_WAVES:-0}"
echo "M4_REGRESSION_COMMIT=$(git -C "$R" rev-parse --short HEAD)";echo "DEBUG_WAVES=$DEBUG_WAVES"
test_one mod_mul_normal 60s 100000 ./sim/scripts/run_mod_mul_normal_pipe.sh
test_one basecase 60s 50000 ./sim/scripts/run_basecase_mul_pipe.sh
test_one poly_basemul 90s 8192 ./sim/scripts/run_poly_basemul_pipe.sh
test_one polyvec_workspace 40s 768 ./sim/scripts/run_polyvec_workspace.sh
test_one polyvec_add 150s 12288 ./sim/scripts/run_polyvec_add_pipe.sh
test_one polyvec_sub 150s 12288 ./sim/scripts/run_polyvec_sub_pipe.sh
test_one polyvec_reduce 150s 12288 ./sim/scripts/run_polyvec_reduce_pipe.sh
test_one polyvec_ntt 260s 12288 ./sim/scripts/run_polyvec_ntt_pipe.sh
test_one polyvec_intt 260s 12288 ./sim/scripts/run_polyvec_intt_pipe.sh
test_one polyvec_roundtrip 260s 24576 ./sim/scripts/run_polyvec_ntt_intt_roundtrip.sh
test_one polyvec_basemul_acc 180s 8192 ./sim/scripts/run_polyvec_basemul_acc_pipe.sh
test_one workspace 40s 524 ./sim/scripts/run_poly_workspace.sh
test_one poly_add 60s 8449 ./sim/scripts/run_poly_add_pipe.sh
test_one poly_sub 60s 8449 ./sim/scripts/run_poly_sub_pipe.sh
test_one poly_reduce 60s 8193 ./sim/scripts/run_poly_reduce_pipe.sh
test_one poly_ntt 90s 8451 ./sim/scripts/run_poly_ntt_pipe.sh
test_one poly_intt 90s 8451 ./sim/scripts/run_poly_intt_pipe.sh
test_one poly_roundtrip 120s 15360 ./sim/scripts/run_poly_ntt_intt_roundtrip.sh
if [[ "${RUN_LOWER_REGRESSIONS:-1}" != "0" ]]; then
test_one m3_unified 220s 361656 ./sim/scripts/run_m3_regression.sh
test_one m2_memory 80s 5417 ./sim/scripts/run_m2_1_primitives.sh
test_one m2_arithmetic 150s 312935 ./sim/scripts/run_m2_2_regression.sh
fi
test_one legacy_poly_add 60s 1024 ./sim/scripts/run_poly_add.sh
test_one legacy_poly_sub 60s 1024 ./sim/scripts/run_poly_sub.sh
test_one legacy_basemul 60s 514 ./sim/scripts/run_basemul_unit.sh
test_one legacy_basemul_addr 60s 256 ./sim/scripts/run_poly_basemul_addr_gen.sh
test_one legacy_poly_basemul 60s 768 ./sim/scripts/run_poly_basemul_montgomery.sh
test_one legacy_ntt 60s 512 ./sim/scripts/run_ntt_core.sh
test_one legacy_intt 60s 768 ./sim/scripts/run_intt_core.sh
test_one legacy_ntt_roundtrip 60s 1024 ./sim/scripts/run_ntt_intt_roundtrip.sh
if [[ "${RUN_LOWER_REGRESSIONS:-1}" != "0" ]]; then
test_one python_selftest 30s 1 python3 -m ref_model.python_model.selftest
test_one python_foundations 30s 13 python3 -m ref_model.python_model.test_foundations
test_one python_schema 30s 5 python3 -m ref_model.compare.test_compare_tools
test_one vector_repro 90s 3 bash -c 'for g in gen_m4_poly_vectors.py gen_m4_3_vectors.py gen_m4_4_vectors.py gen_m4_5_vectors.py;do mkdir -p "$1/$g/a" "$1/$g/b";python3 "tb/tools/$g" --output-dir "$1/$g/a";python3 "tb/tools/$g" --output-dir "$1/$g/b";diff -qr "$1/$g/a" "$1/$g/b";done' _ "$D/repro"
fi
summary PASS
