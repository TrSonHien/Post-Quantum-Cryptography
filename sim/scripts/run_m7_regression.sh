#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m7-regression.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$TMP"' EXIT INT TERM
TESTS_RUN=0;TESTS_PASSED=0;TESTS_FAILED=0;INTERNAL_CHECKS=0;BYTE_COMPARISONS=151716;COEFFICIENT_COMPARISONS=324096
summary(){ echo "M7_REGRESSION_STATUS=$1";echo "TESTS_RUN=$TESTS_RUN";echo "TESTS_PASSED=$TESTS_PASSED";echo "TESTS_FAILED=$TESTS_FAILED";echo "INTERNAL_CHECKS=$INTERNAL_CHECKS";echo "BYTE_COMPARISONS=$BYTE_COMPARISONS";echo "COEFFICIENT_COMPARISONS=$COEFFICIENT_COMPARISONS";echo "ELAPSED_SECONDS=$(($(date +%s)-START))";}
run(){ local n="$1" lim="$2" checks="$3" log rc;log="$TMP/$n.log";shift 3;TESTS_RUN=$((TESTS_RUN+1));set +e;timeout "$lim" "$@">"$log" 2>&1;rc=$?;set -e;if((rc==0));then TESTS_PASSED=$((TESTS_PASSED+1));INTERNAL_CHECKS=$((INTERNAL_CHECKS+checks));echo "M7_TEST name=$n status=PASS checks=$checks";else TESTS_FAILED=$((TESTS_FAILED+1));echo "M7_TEST name=$n status=FAIL exit=$rc";tail -160 "$log";summary FAIL;exit "$rc";fi;}
echo "M7_REGRESSION_COMMIT=$(git -C "$ROOT" rev-parse --short HEAD)";echo "DEBUG_WAVES=${DEBUG_WAVES:-0}"
run matrix_row 420s 87972 "$ROOT/sim/scripts/run_kpke_matrix_row_sampler.sh"
run noise_vector 300s 16194 "$ROOT/sim/scripts/run_kpke_noise_vector_sampler.sh"
run keygen 1000s 124800 "$ROOT/sim/scripts/run_kpke_keygen.sh"
run encrypt 1300s 114560 "$ROOT/sim/scripts/run_kpke_encrypt.sh"
run decrypt 1000s 62080 "$ROOT/sim/scripts/run_kpke_decrypt.sh"
run roundtrip 1900s 69120 "$ROOT/sim/scripts/run_kpke_roundtrip.sh"
run protocol_reset 1900s 35 "$ROOT/sim/scripts/run_kpke_protocol.sh"
run primitive_boundary 420s 1152 "$ROOT/sim/scripts/run_kpke_boundary.sh"
run zeroize 90s 21462 "$ROOT/sim/scripts/run_m7_kpke_zeroize.sh"
run secure_payload_reset 60s 393 "$ROOT/sim/scripts/run_secure_payload_reset.sh"
run vector_repro 300s 7 bash -c 'set -euo pipefail;mkdir -p "$1/a" "$1/b";PYTHONPATH="$2" python3 "$2/tb/tools/gen_kpke_vectors.py" --output-dir "$1/a" >/dev/null;PYTHONPATH="$2" python3 "$2/tb/tools/gen_kpke_vectors.py" --output-dir "$1/b" >/dev/null;diff -qr "$1/a" "$1/b" >/dev/null' _ "$TMP" "$ROOT"
if [[ "${RUN_LOWER_REGRESSIONS:-1}" != "0" ]]; then
 run m6_unified 3000s 2467232 "$ROOT/sim/scripts/run_m6_regression.sh"
 run m5_unified 2600s 1802376 "$ROOT/sim/scripts/run_m5_regression.sh"
 run m4_unified 1200s 996965 "$ROOT/sim/scripts/run_m4_regression.sh"
 run m3_unified 300s 361656 "$ROOT/sim/scripts/run_m3_regression.sh"
 run python_model 180s 1 bash -c 'cd "$1";python3 -m unittest discover -s ref_model -p "test*.py"' _ "$ROOT"
fi
summary PASS
