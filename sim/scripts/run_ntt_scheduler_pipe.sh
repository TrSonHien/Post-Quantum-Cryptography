#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/sim/logs"
OUT_DIR="${ROOT_DIR}/sim/outputs"
SIM_OUT="${OUT_DIR}/tb_ntt_scheduler_pipe.vvp"
LOG_FILE="${LOG_DIR}/ntt_scheduler_pipe.log"

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

iverilog -g2012 -Wall \
    -I "${ROOT_DIR}/rtl/common" \
    -o "${SIM_OUT}" \
    "${ROOT_DIR}/rtl/memory/ntt_bank_map.v" \
    "${ROOT_DIR}/rtl/ntt/ntt_scheduler_pipe.v" \
    "${ROOT_DIR}/tb/unit/tb_ntt_scheduler_pipe.v"

vvp "${SIM_OUT}" | tee "${LOG_FILE}"

grep -q "PASS tb_ntt_scheduler_pipe" "${LOG_FILE}"
