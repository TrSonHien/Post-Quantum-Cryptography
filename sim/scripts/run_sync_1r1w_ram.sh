#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/outputs" "${ROOT_DIR}/sim/logs"
iverilog -g2012 -Wall -s tb_sync_1r1w_ram \
  -o "${ROOT_DIR}/sim/outputs/tb_sync_1r1w_ram.vvp" \
  "${ROOT_DIR}/rtl/memory/sync_1r1w_ram.v" \
  "${ROOT_DIR}/tb/unit/tb_sync_1r1w_ram.v"
vvp "${ROOT_DIR}/sim/outputs/tb_sync_1r1w_ram.vvp" | tee "${ROOT_DIR}/sim/logs/sync_1r1w_ram.log"
grep -q "PASS tb_sync_1r1w_ram" "${ROOT_DIR}/sim/logs/sync_1r1w_ram.log"
