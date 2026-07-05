#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/sim/logs"
OUT_DIR="${ROOT_DIR}/sim/outputs"
SIM_OUT="${OUT_DIR}/tb_mod_sub.vvp"
LOG_FILE="${LOG_DIR}/mod_sub.log"

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

iverilog -g2012 -Wall \
    -I "${ROOT_DIR}/rtl/common" \
    -o "${SIM_OUT}" \
    "${ROOT_DIR}/rtl/arithmetic/mod_sub.v" \
    "${ROOT_DIR}/tb/unit/tb_mod_sub.v" 2>&1 | tee "${LOG_FILE}"

vvp "${SIM_OUT}" 2>&1 | tee -a "${LOG_FILE}"

grep -q "PASS tb_mod_sub" "${LOG_FILE}"
