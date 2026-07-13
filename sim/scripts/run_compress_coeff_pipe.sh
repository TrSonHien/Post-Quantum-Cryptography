#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; O="$(mktemp -d "${TMPDIR:-/tmp}/m6-compress.XXXXXX")"; trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
for d in 1 4 10; do iverilog -g2012 -Wall -s tb_compress_coeff_pipe -Ptb_compress_coeff_pipe.D="$d" -o "$O/t$d.vvp" "$R/rtl/codec/compress_coeff_pipe.v" "$R/tb/unit/tb_compress_coeff_pipe.v"; timeout 30s vvp "$O/t$d.vvp" +VECTOR_FILE="$O/compress.mem"; done | tee "$O/run.log"
grep -c 'PASS tb_compress_coeff_pipe' "$O/run.log" | grep -q '^3$'
