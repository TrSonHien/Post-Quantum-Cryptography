#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/sim/logs"
OUT_DIR="${ROOT_DIR}/sim/outputs"
SIM_OUT="${OUT_DIR}/tb_mod_add.vvp"
LOG_FILE="${LOG_DIR}/mod_add.log"

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

iverilog -g2012 -Wall \
    -I "${ROOT_DIR}/rtl/common" \
    -o "${SIM_OUT}" \
    "${ROOT_DIR}/rtl/arithmetic/mod_add.v" \
    "${ROOT_DIR}/tb/unit/tb_mod_add.v"

vvp "${SIM_OUT}" | tee "${LOG_FILE}"

grep -q "PASS tb_mod_add" "${LOG_FILE}"
