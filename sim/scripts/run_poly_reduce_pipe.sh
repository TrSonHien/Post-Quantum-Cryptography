#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; OUT="${ROOT_DIR}/sim/outputs"; mkdir -p "$OUT" "${ROOT_DIR}/sim/logs"
PYTHONPATH="$ROOT_DIR" python3 "${ROOT_DIR}/tb/tools/gen_m4_poly_vectors.py" --output-dir "$OUT"
iverilog -g2012 -Wall -I "$ROOT_DIR/rtl/common" -s tb_poly_reduce_pipe -o "$OUT/tb_poly_reduce_pipe.vvp" \
 "$ROOT_DIR/rtl/poly/poly_workspace.v" "$ROOT_DIR/rtl/arithmetic/barrett_reduce_pipe.v" \
 "$ROOT_DIR/rtl/poly/poly_reduce_pipe.v" "$ROOT_DIR/tb/block/tb_poly_reduce_pipe.v"
timeout 30s vvp "$OUT/tb_poly_reduce_pipe.vvp" +INPUT_FILE="$OUT/poly_reduce_input.mem" +EXPECTED_FILE="$OUT/poly_reduce_expected.mem" | tee "${ROOT_DIR}/sim/logs/poly_reduce_pipe.log"
grep -q 'PASS tb_poly_reduce_pipe' "${ROOT_DIR}/sim/logs/poly_reduce_pipe.log"
