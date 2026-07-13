#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/sim/logs"
OUT_DIR="${ROOT_DIR}/sim/outputs"
SIM_OUT="${OUT_DIR}/tb_ntt_core_pipe.vvp"
LOG_FILE="${LOG_DIR}/ntt_core_pipe.log"
VECTOR_FILE="${OUT_DIR}/ntt_core_pipe_vectors.mem"

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

PYTHONPATH="${ROOT_DIR}${PYTHONPATH:+:${PYTHONPATH}}" \
python3 "${ROOT_DIR}/tb/tools/gen_ntt_core_pipe_vectors.py" \
    --output "${VECTOR_FILE}" \
    --random-count 20

iverilog -g2012 -Wall \
    -I "${ROOT_DIR}/rtl/common" \
    -o "${SIM_OUT}" \
    "${ROOT_DIR}/rtl/memory/ntt_bank_map.v" \
    "${ROOT_DIR}/rtl/memory/sync_1r1w_ram.v" \
    "${ROOT_DIR}/rtl/memory/ntt_pingpong_banks.v" \
    "${ROOT_DIR}/rtl/control/fixed_latency_delay.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_add_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_sub_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/montgomery_reduce_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_mul_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/zetas_rom.v" \
    "${ROOT_DIR}/rtl/ntt/butterfly_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/ntt_scheduler_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/ntt_core_pipe.v" \
    "${ROOT_DIR}/tb/block/tb_ntt_core_pipe.v"

timeout 20s vvp "${SIM_OUT}" +VECTOR_FILE="${VECTOR_FILE}" | tee "${LOG_FILE}"

grep -q "PASS tb_ntt_core_pipe" "${LOG_FILE}"
