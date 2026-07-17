#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m8-smoke.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$T"' EXIT INT TERM
RUN=0;PASS=0;FAIL=0;CHECKS=0
summary(){ echo "M8_SMOKE_STATUS=$1";echo "TESTS_RUN=$RUN";echo "TESTS_PASSED=$PASS";echo "TESTS_FAILED=$FAIL";echo "INTERNAL_CHECKS=$CHECKS";echo "ELAPSED_SECONDS=$(($(date +%s)-START))";}
one(){ local n="$1" lim="$2" c="$3" log="$T/$1.log" rc;shift 3;RUN=$((RUN+1));set +e;timeout "$lim" "$@">"$log" 2>&1;rc=$?;set -e;if((rc));then FAIL=$((FAIL+1));echo "M8_SMOKE_TEST name=$n status=FAIL exit=$rc";tail -160 "$log";summary FAIL;exit "$rc";else PASS=$((PASS+1));CHECKS=$((CHECKS+c));echo "M8_SMOKE_TEST name=$n status=PASS checks=$c";fi;}
export M8_SMOKE_VECTORS="${M8_SMOKE_VECTORS:-1}"
one byte_buffer 60s 200 "$R/sim/scripts/run_mlkem_byte_buffer.sh"
one dk_layout 60s 9599 "$R/sim/scripts/run_mlkem_dk_layout.sh"
one ek_check 60s 4608 "$R/sim/scripts/run_mlkem_ek_check.sh"
one decaps_input_check 90s 160 "$R/sim/scripts/run_mlkem_decaps_input_check.sh"
one compare_select 90s 6720 "$R/sim/scripts/run_mlkem_ct_compare_select.sh"
one zeroization 60s 10 "$R/sim/scripts/run_mlkem_zeroization.sh"
one keygen_internal 240s 3584 "$R/sim/scripts/run_mlkem_keygen_internal.sh"
one encaps_internal 300s 1120 "$R/sim/scripts/run_mlkem_encaps_internal.sh"
one decaps_internal 420s 2240 "$R/sim/scripts/run_mlkem_decaps_internal.sh"
summary PASS
