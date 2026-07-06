#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/sim/outputs"
LOG_DIR="${ROOT_DIR}/sim/logs"
SIM_OUT="${OUT_DIR}/tb_basemul_unit.vvp"
LOG_FILE="${LOG_DIR}/basemul_unit.log"

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

iverilog -g2012 -Wall \
    -I "${ROOT_DIR}/rtl/common" \
    -o "${SIM_OUT}" \
    "${ROOT_DIR}/rtl/arithmetic/mod_add.v" \
    "${ROOT_DIR}/rtl/arithmetic/reduction.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_mul.v" \
    "${ROOT_DIR}/rtl/ntt/basemul_unit.v" \
    "${ROOT_DIR}/tb/unit/tb_basemul_unit.v" 2>&1 | tee "${LOG_FILE}"

vvp "${SIM_OUT}" 2>&1 | tee -a "${LOG_FILE}"

grep -q "PASS tb_basemul_unit" "${LOG_FILE}"
