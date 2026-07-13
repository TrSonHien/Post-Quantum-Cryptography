#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; OUT="${ROOT_DIR}/sim/outputs"; mkdir -p "$OUT" "${ROOT_DIR}/sim/logs"
PYTHONPATH="$ROOT_DIR" python3 "${ROOT_DIR}/tb/tools/gen_m4_poly_vectors.py" --output-dir "$OUT"
iverilog -g2012 -Wall -I "$ROOT_DIR/rtl/common" -s tb_poly_sub_pipe -o "$OUT/tb_poly_sub_pipe.vvp" \
 "$ROOT_DIR/rtl/poly/poly_workspace.v" "$ROOT_DIR/rtl/arithmetic/mod_add_pipe.v" "$ROOT_DIR/rtl/arithmetic/mod_sub_pipe.v" \
 "$ROOT_DIR/rtl/poly/poly_binary_pipe.v" "$ROOT_DIR/rtl/poly/poly_add_pipe.v" "$ROOT_DIR/rtl/poly/poly_sub_pipe.v" \
 "$ROOT_DIR/tb/block/tb_poly_binary_pipe.v" "$ROOT_DIR/tb/block/tb_poly_sub_pipe.v"
timeout 30s vvp "$OUT/tb_poly_sub_pipe.vvp" +VECTOR_FILE="$OUT/poly_sub.mem" | tee "${ROOT_DIR}/sim/logs/poly_sub_pipe.log"
grep -q 'PASS tb_poly_binary_pipe' "${ROOT_DIR}/sim/logs/poly_sub_pipe.log"
