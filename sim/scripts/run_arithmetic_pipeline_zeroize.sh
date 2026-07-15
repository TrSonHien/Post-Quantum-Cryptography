#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/arithmetic-zeroize.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_arithmetic_pipeline_zeroize -o "$T/t.vvp" \
  "$R/rtl/arithmetic/mod_add_pipe.v" "$R/rtl/arithmetic/mod_sub_pipe.v" \
  "$R/rtl/arithmetic/montgomery_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_pipe.v" \
  "$R/tb/unit/tb_arithmetic_pipeline_zeroize.v"
timeout 20s vvp "$T/t.vvp"
