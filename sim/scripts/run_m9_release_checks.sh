#!/usr/bin/env bash
# Academic M9 release gate.  It intentionally uses the reduced M8 depths.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m9-release.XXXXXX")"
START="$(date +%s)"
trap 'rm -rf "$TMP"' EXIT INT TERM

RUN=0; PASS=0; FAIL=0
ELAB=NOT_RUN; SMOKE=NOT_RUN; FUNCTIONAL=NOT_RUN; M7=NOT_RUN; VECTOR=NOT_RUN
M23=NOT_RUN; TOP_SYNTH=NOT_RUN

summary() {
  local overall="$1"
  echo "M9_RELEASE_STATUS=$overall"
  echo "ELABORATION_STATUS=$ELAB"
  echo "M8_SMOKE_STATUS=$SMOKE"
  echo "M8_FUNCTIONAL_STATUS=$FUNCTIONAL"
  echo "M7_SANITY_STATUS=$M7"
  echo "VECTOR_REPRO_STATUS=$VECTOR"
  echo "M2_3B_SYNTH_STATUS=$M23"
  echo "MLKEM_TOP_SYNTH_STATUS=$TOP_SYNTH"
  echo "TESTS_RUN=$RUN"
  echo "TESTS_PASSED=$PASS"
  echo "TESTS_FAILED=$FAIL"
  echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
}

required() {
  local name="$1" limit="$2" log="$TMP/$1.log" rc
  shift 2
  RUN=$((RUN+1)); echo "M9_RELEASE_PROGRESS test=$name index=$RUN"
  set +e
  timeout "$limit" "$@" >"$log" 2>&1
  rc=$?
  set -e
  if (( rc != 0 )); then
    FAIL=$((FAIL+1)); echo "M9_RELEASE_TEST name=$name status=FAIL exit=$rc"
    tail -160 "$log"; summary FAIL; exit "$rc"
  fi
  PASS=$((PASS+1)); echo "M9_RELEASE_TEST name=$name status=PASS"
  case "$name" in
    m8_smoke) rg '^(M8_SMOKE_STATUS|ELAPSED_SECONDS)=' "$log" || true ;;
    m8_functional) rg '^(M8_REGRESSION_STATUS|ELAPSED_SECONDS)=' "$log" || true ;;
  esac
}

required elaboration 900s "$ROOT/sim/scripts/run_m9_elaboration.sh"; ELAB=PASS
required m8_smoke 900s "$ROOT/sim/scripts/run_m8_smoke.sh"; SMOKE=PASS
required m8_functional 3600s "$ROOT/sim/scripts/run_m8_regression.sh"; FUNCTIONAL=PASS
required m7_roundtrip 2100s "$ROOT/sim/scripts/run_kpke_roundtrip.sh"; M7=PASS
required vector_repro 180s bash -c '
  mkdir -p "$1/a" "$1/b"
  PYTHONPATH="$2" python3 "$2/tb/tools/gen_mlkem_vectors.py" --output-dir "$1/a" --count 4 >/dev/null
  PYTHONPATH="$2" python3 "$2/tb/tools/gen_mlkem_vectors.py" --output-dir "$1/b" --count 4 >/dev/null
  diff -qr "$1/a" "$1/b"
' _ "$TMP/vector_repro" "$ROOT"; VECTOR=PASS

required m2_3b_synthesis 120s "$ROOT/synth/m2_3/run_synth_sweep.sh"
if rg -q 'BLOCKER:' "$TMP/m2_3b_synthesis.log"; then M23=ENVIRONMENT_BLOCKED; else M23=PASS; fi

required top_synthesis_scripts 120s bash -c '"$1/synth/m9/run_yosys.sh"; "$1/synth/m9/run_genus.sh"' _ "$ROOT"
if rg -q 'ENVIRONMENT_BLOCKED' "$TMP/top_synthesis_scripts.log"; then TOP_SYNTH=ENVIRONMENT_BLOCKED; else TOP_SYNTH=PASS; fi

if [[ "$M23" == ENVIRONMENT_BLOCKED || "$TOP_SYNTH" == ENVIRONMENT_BLOCKED ]]; then
  summary PARTIAL
else
  summary PASS
fi
