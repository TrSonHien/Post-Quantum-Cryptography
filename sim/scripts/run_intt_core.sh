#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/sim/outputs"
LOG_DIR="${ROOT_DIR}/sim/logs"
WAVE_DIR="${ROOT_DIR}/sim/waves"
SIM_OUT="${OUT_DIR}/tb_intt_core.out"
LOG_FILE="${LOG_DIR}/intt_core_sim.log"

mkdir -p "${OUT_DIR}" "${LOG_DIR}" "${WAVE_DIR}"

cd "${ROOT_DIR}"

iverilog -g2012 -Wall \
    -I rtl/common \
    -o "${SIM_OUT}" \
    rtl/arithmetic/mod_add.v \
    rtl/arithmetic/mod_sub.v \
    rtl/arithmetic/reduction.v \
    rtl/arithmetic/mod_mul.v \
    rtl/memory/poly_buffer.v \
    rtl/ntt/ntt_addr_gen.v \
    rtl/ntt/zetas_rom.v \
    rtl/ntt/intt_core.v \
    tb/unit/tb_intt_core.v 2>&1 | tee "${LOG_FILE}"

vvp "${SIM_OUT}" 2>&1 | tee -a "${LOG_FILE}"

grep -q "PASS tb_intt_core" "${LOG_FILE}"
