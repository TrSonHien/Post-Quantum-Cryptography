#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Running M2.2 Unified Arithmetic Pipeline Regression ==="

# 1. M2.1 Primitives
"${SCRIPT_DIR}/run_m2_1_primitives.sh"

# 2. Pipelined Modular Add
"${SCRIPT_DIR}/run_mod_add_pipe.sh"

# 3. Pipelined Modular Subtract
"${SCRIPT_DIR}/run_mod_sub_pipe.sh"

# 4. Pipelined Montgomery Reduction
"${SCRIPT_DIR}/run_montgomery_reduce_pipe.sh"

# 5. Pipelined Modular Multiplication
"${SCRIPT_DIR}/run_mod_mul_pipe.sh"

# 6. Pipelined Barrett Reduction
"${SCRIPT_DIR}/run_barrett_reduce_pipe.sh"

# 7. Pipelined Forward Butterfly
"${SCRIPT_DIR}/run_butterfly_pipe.sh"

# 8. Pipelined Inverse Butterfly
"${SCRIPT_DIR}/run_intt_butterfly_pipe.sh"

echo "=========================================================="
echo "PASS: All M2.2 pipelined arithmetic blocks verified!"
echo "=========================================================="
