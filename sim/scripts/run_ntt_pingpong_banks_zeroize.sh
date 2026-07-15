#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/ntt-banks-zeroize.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -I "$R/rtl/include" -s tb_ntt_pingpong_banks_zeroize -o "$T/t.vvp" \
  "$R/rtl/memory/sync_1r1w_ram.v" "$R/rtl/memory/ntt_pingpong_banks.v" \
  "$R/rtl/memory/ntt_bank_map.v" "$R/tb/unit/tb_ntt_pingpong_banks_zeroize.v"
timeout 30s vvp "$T/t.vvp"
