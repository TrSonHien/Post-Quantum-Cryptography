#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/outputs" "${ROOT_DIR}/sim/logs"
iverilog -g2012 -Wall -s tb_ntt_pingpong_banks \
  -o "${ROOT_DIR}/sim/outputs/tb_ntt_pingpong_banks.vvp" \
  "${ROOT_DIR}/rtl/memory/sync_1r1w_ram.v" \
  "${ROOT_DIR}/rtl/memory/ntt_bank_map.v" \
  "${ROOT_DIR}/rtl/memory/ntt_pingpong_banks.v" \
  "${ROOT_DIR}/tb/unit/tb_ntt_pingpong_banks.v"
vvp "${ROOT_DIR}/sim/outputs/tb_ntt_pingpong_banks.vvp" | tee "${ROOT_DIR}/sim/logs/ntt_pingpong_banks.log"
grep -q "PASS tb_ntt_pingpong_banks" "${ROOT_DIR}/sim/logs/ntt_pingpong_banks.log"
