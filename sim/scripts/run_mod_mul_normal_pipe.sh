#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m4-mul.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_m4_3_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_mod_mul_normal_pipe -o "$O/tb_mod_mul_normal_pipe.vvp" "$R/rtl/arithmetic/barrett_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_normal_pipe.v" "$R/tb/unit/tb_mod_mul_normal_pipe.v"
timeout 30s vvp "$O/tb_mod_mul_normal_pipe.vvp" +VECTOR_FILE="$O/mod_mul_normal.mem"|tee "$O/run.log";grep -q 'PASS tb_mod_mul_normal_pipe' "$O/run.log"
