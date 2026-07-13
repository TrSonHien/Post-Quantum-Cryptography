#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m4-basecase.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_m4_3_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_basecase_mul_pipe -o "$O/tb_basecase_mul_pipe.vvp" "$R/rtl/control/fixed_latency_delay.v" "$R/rtl/arithmetic/barrett_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_normal_pipe.v" "$R/rtl/arithmetic/mod_add_pipe.v" "$R/rtl/poly/basecase_mul_pipe.v" "$R/tb/unit/tb_basecase_mul_pipe.v"
timeout 40s vvp "$O/tb_basecase_mul_pipe.vvp" +VECTOR_FILE="$O/basecase.mem"|tee "$O/run.log";grep -q 'PASS tb_basecase_mul_pipe' "$O/run.log"
