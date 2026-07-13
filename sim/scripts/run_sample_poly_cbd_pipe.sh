#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-cbd.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_cbd_vectors.py" --output-dir "$O";for e in 2 3;do iverilog -g2012 -Wall -s tb_sample_poly_cbd_pipe -Ptb_sample_poly_cbd_pipe.ETA="$e" -o "$O/t$e.vvp" "$R/rtl/sampler/sample_poly_cbd_pipe.v" "$R/tb/block/tb_sample_poly_cbd_pipe.v";timeout 60s vvp "$O/t$e.vvp" +VECTOR_FILE="$O/cbd_eta$e.mem";done|tee "$O/run.log";grep -c 'PASS tb_sample_poly_cbd_pipe' "$O/run.log"|grep -q '^2$'
