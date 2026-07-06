#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/sim/outputs"
LOG_DIR="${ROOT_DIR}/sim/logs"
WAVE_DIR="${ROOT_DIR}/sim/waves"
SIM_OUT="${OUT_DIR}/tb_poly_basemul_addr_gen.vvp"
LOG_FILE="${LOG_DIR}/poly_basemul_addr_gen.log"

mkdir -p "${OUT_DIR}" "${LOG_DIR}" "${WAVE_DIR}"

cd "${ROOT_DIR}"

iverilog -g2012 -Wall \
    -I rtl/common \
    -o "${SIM_OUT}" \
    rtl/poly/poly_basemul_addr_gen.v \
    tb/unit/tb_poly_basemul_addr_gen.v 2>&1 | tee "${LOG_FILE}"

vvp "${SIM_OUT}" 2>&1 | tee -a "${LOG_FILE}"

grep -q "PASS tb_poly_basemul_addr_gen" "${LOG_FILE}"
