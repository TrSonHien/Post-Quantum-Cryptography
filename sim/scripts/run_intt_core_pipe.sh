#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/sim/logs"
OUT_DIR="${ROOT_DIR}/sim/outputs"
VECTOR_FILE="${OUT_DIR}/intt_core_pipe_vectors.mem"
ROUNDTRIP_FILE="${OUT_DIR}/ntt_intt_pipe_roundtrip_vectors.mem"
mkdir -p "${LOG_DIR}" "${OUT_DIR}" "${ROOT_DIR}/sim/waves"
DEBUG_ARGS=()
[[ "${DEBUG_WAVES:-0}" == "1" ]] && DEBUG_ARGS=(+DEBUG_WAVES)

PYTHONPATH="${ROOT_DIR}${PYTHONPATH:+:${PYTHONPATH}}" \
python3 "${ROOT_DIR}/tb/tools/gen_intt_pipe_vectors.py" \
    --intt-output "${VECTOR_FILE}" --roundtrip-output "${ROUNDTRIP_FILE}"

iverilog -g2012 -Wall -I "${ROOT_DIR}/rtl/common" \
    -o "${OUT_DIR}/tb_intt_core_pipe.vvp" \
    "${ROOT_DIR}/rtl/memory/ntt_bank_map.v" \
    "${ROOT_DIR}/rtl/memory/sync_1r1w_ram.v" \
    "${ROOT_DIR}/rtl/memory/ntt_pingpong_banks.v" \
    "${ROOT_DIR}/rtl/control/fixed_latency_delay.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_add_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_sub_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/montgomery_reduce_pipe.v" \
    "${ROOT_DIR}/rtl/arithmetic/mod_mul_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/zetas_rom.v" \
    "${ROOT_DIR}/rtl/ntt/intt_butterfly_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/intt_scaler_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/intt_scheduler_pipe.v" \
    "${ROOT_DIR}/rtl/ntt/intt_core_pipe.v" \
    "${ROOT_DIR}/tb/block/tb_intt_core_pipe.v"

timeout 30s vvp "${OUT_DIR}/tb_intt_core_pipe.vvp" +VECTOR_FILE="${VECTOR_FILE}" "${DEBUG_ARGS[@]}" \
    | tee "${LOG_DIR}/intt_core_pipe.log"
grep -q "PASS tb_intt_core_pipe" "${LOG_DIR}/intt_core_pipe.log"
