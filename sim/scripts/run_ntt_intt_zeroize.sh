#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/ntt-intt-zeroize.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_ntt_intt_zeroize -o "$T/t.vvp" \
  "$R/rtl/memory/ntt_bank_map.v" "$R/rtl/memory/sync_1r1w_ram.v" \
  "$R/rtl/memory/ntt_pingpong_banks.v" "$R/rtl/control/fixed_latency_delay.v" \
  "$R/rtl/arithmetic/mod_add_pipe.v" "$R/rtl/arithmetic/mod_sub_pipe.v" \
  "$R/rtl/arithmetic/montgomery_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_pipe.v" \
  "$R/rtl/ntt/zetas_rom.v" "$R/rtl/ntt/butterfly_pipe.v" \
  "$R/rtl/ntt/intt_butterfly_pipe.v" "$R/rtl/ntt/intt_scaler_pipe.v" \
  "$R/rtl/ntt/ntt_scheduler_pipe.v" "$R/rtl/ntt/intt_scheduler_pipe.v" \
  "$R/rtl/ntt/ntt_core_pipe.v" "$R/rtl/ntt/intt_core_pipe.v" \
  "$R/tb/block/tb_ntt_intt_zeroize.v"
timeout 60s vvp "$T/t.vvp"
