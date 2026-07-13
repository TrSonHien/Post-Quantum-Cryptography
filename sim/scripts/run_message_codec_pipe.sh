#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-msgcodec.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -s tb_message_codec_pipe -o "$O/t.vvp" "$R/rtl/codec/byte_encode_poly_pipe.v" "$R/rtl/codec/byte_decode_poly_pipe.v" "$R/rtl/codec/poly_compress_encode_pipe.v" "$R/rtl/codec/poly_decode_decompress_pipe.v" "$R/rtl/codec/message_to_poly_pipe.v" "$R/rtl/codec/poly_to_message_pipe.v" "$R/tb/block/tb_message_codec_pipe.v";timeout 120s vvp "$O/t.vvp" +VECTOR_FILE="$O/message_codec.mem"|tee "$O/run.log";grep -q 'PASS tb_message_codec_pipe' "$O/run.log"
