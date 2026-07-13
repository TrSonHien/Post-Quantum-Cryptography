#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";OUT="$ROOT/sim/outputs";mkdir -p "$OUT" "$ROOT/sim/logs"
DEBUG_ARGS=(); [[ "${DEBUG_WAVES:-0}" == 1 ]] && DEBUG_ARGS=(+DEBUG_WAVES)
PYTHONPATH="$ROOT" python3 "$ROOT/tb/tools/gen_m4_poly_vectors.py" --output-dir "$OUT"
iverilog -g2012 -Wall -I "$ROOT/rtl/common" -s tb_poly_intt_pipe -o "$OUT/tb_poly_intt_pipe.vvp" \
 "$ROOT/rtl/memory/ntt_bank_map.v" "$ROOT/rtl/memory/sync_1r1w_ram.v" "$ROOT/rtl/memory/ntt_pingpong_banks.v" "$ROOT/rtl/control/fixed_latency_delay.v" \
 "$ROOT/rtl/arithmetic/mod_add_pipe.v" "$ROOT/rtl/arithmetic/mod_sub_pipe.v" "$ROOT/rtl/arithmetic/montgomery_reduce_pipe.v" "$ROOT/rtl/arithmetic/mod_mul_pipe.v" \
 "$ROOT/rtl/ntt/zetas_rom.v" "$ROOT/rtl/ntt/butterfly_pipe.v" "$ROOT/rtl/ntt/intt_butterfly_pipe.v" "$ROOT/rtl/ntt/intt_scaler_pipe.v" \
 "$ROOT/rtl/ntt/ntt_scheduler_pipe.v" "$ROOT/rtl/ntt/intt_scheduler_pipe.v" "$ROOT/rtl/ntt/ntt_core_pipe.v" "$ROOT/rtl/ntt/intt_core_pipe.v" \
 "$ROOT/rtl/poly/poly_workspace.v" "$ROOT/rtl/poly/poly_transform_pipe.v" "$ROOT/rtl/poly/poly_ntt_pipe.v" "$ROOT/rtl/poly/poly_intt_pipe.v" \
 "$ROOT/tb/block/tb_poly_transform_pipe.v" "$ROOT/tb/block/tb_poly_intt_pipe.v"
timeout 50s vvp "$OUT/tb_poly_intt_pipe.vvp" +VECTOR_FILE="$OUT/poly_intt.mem" "${DEBUG_ARGS[@]}"|tee "$ROOT/sim/logs/poly_intt_pipe.log"
grep -q 'PASS tb_poly_transform_pipe' "$ROOT/sim/logs/poly_intt_pipe.log"
