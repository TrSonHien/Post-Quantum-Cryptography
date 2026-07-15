#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-byte-buffer.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
timeout 30s iverilog -g2012 -s tb_mlkem_byte_buffer -o "$T/test.vvp" \
  "$R/rtl/mlkem/mlkem_byte_buffer.v" "$R/tb/unit/tb_mlkem_byte_buffer.v"
timeout 30s vvp "$T/test.vvp"
