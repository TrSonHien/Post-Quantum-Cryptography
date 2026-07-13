#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-polyveccodec.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
SRC=("$R/rtl/codec/byte_encode_poly_pipe.v" "$R/rtl/codec/byte_decode_poly_pipe.v" "$R/rtl/codec/poly_encode12_pipe.v" "$R/rtl/codec/poly_decode12_pipe.v" "$R/rtl/codec/poly_compress_encode_pipe.v" "$R/rtl/codec/poly_decode_decompress_pipe.v" "$R/rtl/codec/polyvec_codec_pipe.v" "$R/tb/block/tb_polyvec_codec_pipe.v")
iverilog -g2012 -Wall -s tb_polyvec_codec_pipe -Ptb_polyvec_codec_pipe.D=12 -Ptb_polyvec_codec_pipe.COMPRESS=0 -o "$O/t12.vvp" "${SRC[@]}";timeout 120s vvp "$O/t12.vvp" +VECTOR_FILE="$O/polyvec_d12.mem"|tee "$O/run.log"
iverilog -g2012 -Wall -s tb_polyvec_codec_pipe -Ptb_polyvec_codec_pipe.D=10 -Ptb_polyvec_codec_pipe.COMPRESS=1 -o "$O/t10.vvp" "${SRC[@]}";timeout 120s vvp "$O/t10.vvp" +VECTOR_FILE="$O/polyvec_d10.mem"|tee -a "$O/run.log"
grep -c 'PASS tb_polyvec_codec_pipe' "$O/run.log"|grep -q '^2$'
