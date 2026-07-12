#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/run_sync_1r1w_ram.sh"
bash "${SCRIPT_DIR}/run_sync_1r1w_ram_collision.sh"
bash "${SCRIPT_DIR}/run_ntt_pingpong_banks.sh"
bash "${SCRIPT_DIR}/run_pipeline_control.sh"
echo "PASS run_m2_1_primitives"
