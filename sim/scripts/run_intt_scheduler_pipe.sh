#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
mkdir -p "${ROOT_DIR}/sim/logs" "${ROOT_DIR}/sim/outputs"

iverilog -g2012 -Wall -o "${ROOT_DIR}/sim/outputs/tb_intt_scheduler_pipe.vvp" \
    "${ROOT_DIR}/rtl/memory/ntt_bank_map.v" \
    "${ROOT_DIR}/rtl/ntt/intt_scheduler_pipe.v" \
    "${ROOT_DIR}/tb/unit/tb_intt_scheduler_pipe.v"

timeout 20s vvp "${ROOT_DIR}/sim/outputs/tb_intt_scheduler_pipe.vvp" \
    | tee "${ROOT_DIR}/sim/logs/intt_scheduler_pipe.log"
grep -q "PASS tb_intt_scheduler_pipe" "${ROOT_DIR}/sim/logs/intt_scheduler_pipe.log"
