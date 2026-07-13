#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m4-poly-basemul.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_m4_3_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_poly_basemul_pipe -o "$O/tb_poly_basemul_pipe.vvp" "$R/rtl/control/fixed_latency_delay.v" "$R/rtl/arithmetic/reduction.v" "$R/rtl/arithmetic/mod_mul.v" "$R/rtl/arithmetic/barrett_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_normal_pipe.v" "$R/rtl/arithmetic/mod_add_pipe.v" "$R/rtl/ntt/zetas_rom.v" "$R/rtl/poly/poly_workspace.v" "$R/rtl/poly/basecase_mul_pipe.v" "$R/rtl/poly/poly_basemul_pipe.v" "$R/tb/block/tb_poly_basemul_pipe.v"
timeout 60s vvp "$O/tb_poly_basemul_pipe.vvp" +VECTOR_FILE="$O/poly_basemul.mem"|tee "$O/run.log";grep -q 'PASS tb_poly_basemul_pipe' "$O/run.log"
