#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/outputs" "${ROOT_DIR}/sim/logs"
iverilog -g2012 -Wall -s tb_sync_1r1w_ram_collision \
  -o "${ROOT_DIR}/sim/outputs/tb_sync_1r1w_ram_collision.vvp" \
  "${ROOT_DIR}/rtl/memory/sync_1r1w_ram.v" \
  "${ROOT_DIR}/tb/unit/tb_sync_1r1w_ram_collision.v"
set +e
vvp "${ROOT_DIR}/sim/outputs/tb_sync_1r1w_ram_collision.vvp" > "${ROOT_DIR}/sim/logs/sync_1r1w_ram_collision.log" 2>&1
status=$?
set -e
grep -q "SYNC_RAM_COLLISION" "${ROOT_DIR}/sim/logs/sync_1r1w_ram_collision.log"
if [[ ${status} -eq 0 ]]; then
  echo "FAIL: collision simulation unexpectedly succeeded"
  exit 1
fi
echo "PASS tb_sync_1r1w_ram_collision: expected assertion observed"
