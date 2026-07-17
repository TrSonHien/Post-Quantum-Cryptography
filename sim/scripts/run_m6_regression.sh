#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m6-regression.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$TMP"' EXIT INT TERM
TESTS_RUN=0;TESTS_PASSED=0;TESTS_FAILED=0;INTERNAL_CHECKS=0;BYTE_COMPARISONS=276992;COEFFICIENT_COMPARISONS=376576
summary(){ echo "M6_REGRESSION_STATUS=$1";echo "TESTS_RUN=$TESTS_RUN";echo "TESTS_PASSED=$TESTS_PASSED";echo "TESTS_FAILED=$TESTS_FAILED";echo "INTERNAL_CHECKS=$INTERNAL_CHECKS";echo "BYTE_COMPARISONS=$BYTE_COMPARISONS";echo "COEFFICIENT_COMPARISONS=$COEFFICIENT_COMPARISONS";echo "SAMPLENTT_VECTORS=64";echo "ELAPSED_SECONDS=$(($(date +%s)-START))";}
run(){ local n="$1" lim="$2" checks="$3" log rc;log="$TMP/$n.log";shift 3;TESTS_RUN=$((TESTS_RUN+1));set +e;timeout "$lim" "$@">"$log" 2>&1;rc=$?;set -e;if((rc==0));then TESTS_PASSED=$((TESTS_PASSED+1));INTERNAL_CHECKS=$((INTERNAL_CHECKS+checks));echo "M6_TEST name=$n status=PASS checks=$checks";else TESTS_FAILED=$((TESTS_FAILED+1));echo "M6_TEST name=$n status=FAIL exit=$rc";tail -120 "$log";summary FAIL;exit "$rc";fi;}
echo "M6_REGRESSION_COMMIT=$(git -C "$ROOT" rev-parse --short HEAD)";echo "DEBUG_WAVES=${DEBUG_WAVES:-0}"
run byte_encode 120s 58752 "$ROOT/sim/scripts/run_byte_encode_poly_pipe.sh"
run byte_decode 120s 69888 "$ROOT/sim/scripts/run_byte_decode_poly_pipe.sh"
run poly_codec 180s 61440 "$ROOT/sim/scripts/run_poly_codec_pipe.sh"
run message_codec 180s 111744 "$ROOT/sim/scripts/run_message_codec_pipe.sh"
run polyvec_codec 180s 116736 "$ROOT/sim/scripts/run_polyvec_codec_pipe.sh"
run kpke_formats 120s 109568 "$ROOT/sim/scripts/run_kpke_format_codecs.sh"
run sample_cbd 120s 65536 "$ROOT/sim/scripts/run_sample_poly_cbd_pipe.sh"
run noise_sampler 180s 32768 "$ROOT/sim/scripts/run_mlkem_noise_sampler.sh"
run sample_ntt_parser 90s 2048 "$ROOT/sim/scripts/run_sample_ntt_parser.sh"
run sample_ntt 240s 16384 "$ROOT/sim/scripts/run_mlkem_sample_ntt.sh"
run vector_repro 180s 3 bash -c 'set -euo pipefail;for g in gen_codec_vectors.py gen_cbd_vectors.py gen_sample_ntt_vectors.py;do mkdir -p "$1/a/$g" "$1/b/$g";PYTHONPATH="$2" python3 "$2/tb/tools/$g" --output-dir "$1/a/$g" >/dev/null;PYTHONPATH="$2" python3 "$2/tb/tools/$g" --output-dir "$1/b/$g" >/dev/null;diff -qr "$1/a/$g" "$1/b/$g" >/dev/null;done' _ "$TMP" "$ROOT"
if [[ "${RUN_LOWER_REGRESSIONS:-1}" != "0" ]]; then
 run m5_unified 2400s 1802376 "$ROOT/sim/scripts/run_m5_regression.sh"
fi
summary PASS
