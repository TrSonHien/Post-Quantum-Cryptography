#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/outputs" "${ROOT_DIR}/sim/logs" "${ROOT_DIR}/sim/waves"
DEBUG_ARGS=(); [[ "${DEBUG_WAVES:-0}" == 1 ]] && DEBUG_ARGS=(+DEBUG_WAVES)
iverilog -g2012 -Wall -o "${ROOT_DIR}/sim/outputs/tb_poly_workspace.vvp" \
  "${ROOT_DIR}/rtl/poly/poly_workspace.v" "${ROOT_DIR}/tb/unit/tb_poly_workspace.v"
timeout 20s vvp "${ROOT_DIR}/sim/outputs/tb_poly_workspace.vvp" "${DEBUG_ARGS[@]}" | tee "${ROOT_DIR}/sim/logs/poly_workspace.log"
grep -q 'PASS tb_poly_workspace' "${ROOT_DIR}/sim/logs/poly_workspace.log"
