#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/logs" "${ROOT_DIR}/sim/outputs"

iverilog -g2012 -Wall -I "${ROOT_DIR}/rtl/common" \
    -o "${ROOT_DIR}/sim/outputs/tb_intt_scaler_pipe.vvp" \
    "${ROOT_DIR}/rtl/control/fixed_latency_delay.v" \
    "${ROOT_DIR}/rtl/arithmetic/montgomery_reduce_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_mul_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/intt_scaler_pipe.v" \
    "${ROOT_DIR}/tb/unit/tb_intt_scaler_pipe.v"

timeout 20s vvp "${ROOT_DIR}/sim/outputs/tb_intt_scaler_pipe.vvp" \
    | tee "${ROOT_DIR}/sim/logs/intt_scaler_pipe.log"
grep -q "PASS tb_intt_scaler_pipe" "${ROOT_DIR}/sim/logs/intt_scaler_pipe.log"
