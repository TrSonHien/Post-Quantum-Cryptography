#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m8-functional.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$T"' EXIT INT TERM
RUN=0;PASS=0;FAIL=0
summary(){ echo "M8_REGRESSION_STATUS=$1";echo "TESTS_RUN=$RUN";echo "TESTS_PASSED=$PASS";echo "TESTS_FAILED=$FAIL";echo "KEYGEN_INTERNAL_VECTORS=${M8_KEYGEN_VECTORS:-2}";echo "ENCAPS_INTERNAL_VECTORS=${M8_ENCAPS_VECTORS:-2}";echo "VALID_DECAPS_VECTORS=${M8_DECAPS_VECTORS:-4}";echo "IMPLICIT_REJECTION_VECTORS=${M8_FALLBACK_VECTORS:-4}";echo "PUBLIC_CHAINS=${M8_PUBLIC_CHAINS:-2}";echo "ELAPSED_SECONDS=$(($(date +%s)-START))";}
one(){ local n="$1" lim="$2" log="$T/$1.log" rc;shift 2;RUN=$((RUN+1));echo "M8_REGRESSION_PROGRESS test=$n index=$RUN";set +e;timeout "$lim" "$@">"$log" 2>&1;rc=$?;set -e;if((rc));then FAIL=$((FAIL+1));echo "M8_TEST name=$n status=FAIL exit=$rc";tail -180 "$log";summary FAIL;exit "$rc";fi;PASS=$((PASS+1));echo "M8_TEST name=$n status=PASS";}
one smoke 900s "$R/sim/scripts/run_m8_smoke.sh"
one internal_chain 3600s "$R/sim/scripts/run_mlkem_internal_chain.sh"
one public_chain 3600s "$R/sim/scripts/run_mlkem_public_chain.sh"
one public_encaps_input_check 300s env MLKEM_ENCAPS_TIMEOUT=180s MLKEM_ENCAPS_PLUSARGS=+INVALID_ONLY "$R/sim/scripts/run_mlkem_encaps.sh"
one public_decaps_input_check 300s env MLKEM_DECAPS_TIMEOUT=180s MLKEM_DECAPS_PLUSARGS=+HASH_ONLY "$R/sim/scripts/run_mlkem_decaps.sh"
one m7_decrypt_sanity 1500s "$R/sim/scripts/run_kpke_decrypt.sh"
one vector_repro 120s bash -c 'mkdir -p "$1/a" "$1/b";PYTHONPATH="$2" python3 "$2/tb/tools/gen_mlkem_vectors.py" --output-dir "$1/a" --count "$3" >/dev/null;PYTHONPATH="$2" python3 "$2/tb/tools/gen_mlkem_vectors.py" --output-dir "$1/b" --count "$3" >/dev/null;diff -qr "$1/a" "$1/b"' _ "$T" "$R" "${M8_DECAPS_VECTORS:-4}"
summary PASS
