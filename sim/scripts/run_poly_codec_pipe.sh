#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-polycodec.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
for d in 4 10;do iverilog -g2012 -Wall -s tb_poly_codec_pipe -Ptb_poly_codec_pipe.D="$d" -o "$O/t$d.vvp" "$R/rtl/codec/byte_encode_poly_pipe.v" "$R/rtl/codec/byte_decode_poly_pipe.v" "$R/rtl/codec/poly_compress_encode_pipe.v" "$R/rtl/codec/poly_decode_decompress_pipe.v" "$R/tb/block/tb_poly_codec_pipe.v";timeout 90s vvp "$O/t$d.vvp" +VECTOR_FILE="$O/poly_codec_d$d.mem";done|tee "$O/run.log";grep -c 'PASS tb_poly_codec_pipe' "$O/run.log"|grep -q '^2$'
