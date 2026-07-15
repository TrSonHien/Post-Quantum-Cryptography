#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m6-codec-zeroize.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT INT TERM
timeout 60s iverilog -g2012 -s tb_m6_codec_zeroize -o "$TMP/tb.vvp" \
  "$ROOT/rtl/codec/bits_to_bytes_pipe.v" \
  "$ROOT/rtl/codec/bytes_to_bits_pipe.v" \
  "$ROOT/rtl/codec/compress_coeff_pipe.v" \
  "$ROOT/rtl/codec/decompress_coeff_pipe.v" \
  "$ROOT/rtl/codec/byte_encode_poly_pipe.v" \
  "$ROOT/rtl/codec/byte_decode_poly_pipe.v" \
  "$ROOT/rtl/codec/poly_encode12_pipe.v" \
  "$ROOT/rtl/codec/poly_compress_encode_pipe.v" \
  "$ROOT/rtl/codec/poly_decode12_pipe.v" \
  "$ROOT/rtl/codec/poly_decode_decompress_pipe.v" \
  "$ROOT/rtl/codec/polyvec_codec_pipe.v" \
  "$ROOT/rtl/codec/kpke_format_pipe.v" \
  "$ROOT/tb/unit/tb_m6_codec_zeroize.v"
timeout 60s vvp "$TMP/tb.vvp"
