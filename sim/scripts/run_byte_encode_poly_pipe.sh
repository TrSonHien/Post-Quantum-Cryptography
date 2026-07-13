#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; O="$(mktemp -d "${TMPDIR:-/tmp}/m6-encode.XXXXXX")"; trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
for d in 1 4 10 12; do iverilog -g2012 -Wall -s tb_byte_encode_poly_pipe -Ptb_byte_encode_poly_pipe.D="$d" -o "$O/t$d.vvp" "$R/rtl/codec/byte_encode_poly_pipe.v" "$R/tb/block/tb_byte_encode_poly_pipe.v"; timeout 60s vvp "$O/t$d.vvp" +VECTOR_FILE="$O/encode_d$d.mem"; done | tee "$O/run.log"
grep -c 'PASS tb_byte_encode_poly_pipe' "$O/run.log" | grep -q '^4$'
