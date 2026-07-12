#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/outputs" "${ROOT_DIR}/sim/logs"
iverilog -g2012 -Wall -s tb_pipeline_control \
  -o "${ROOT_DIR}/sim/outputs/tb_pipeline_control.vvp" \
  "${ROOT_DIR}/rtl/control/fixed_latency_delay.v" \
  "${ROOT_DIR}/rtl/control/rv_register_slice.v" \
  "${ROOT_DIR}/tb/unit/tb_pipeline_control.v"
vvp "${ROOT_DIR}/sim/outputs/tb_pipeline_control.vvp" | tee "${ROOT_DIR}/sim/logs/pipeline_control.log"
grep -q "PASS tb_pipeline_control" "${ROOT_DIR}/sim/logs/pipeline_control.log"
