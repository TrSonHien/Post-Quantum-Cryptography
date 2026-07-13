#!/usr/bin/env bash
set -euo pipefail
TOP="$1";VEC="$2";LIMIT="$3";R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m4-polyvec-op.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_m4_4_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s "$TOP" -o "$O/t.vvp" \
 "$R/rtl/memory/ntt_bank_map.v" "$R/rtl/memory/sync_1r1w_ram.v" "$R/rtl/memory/ntt_pingpong_banks.v" "$R/rtl/control/fixed_latency_delay.v" \
 "$R/rtl/arithmetic/mod_add_pipe.v" "$R/rtl/arithmetic/mod_sub_pipe.v" "$R/rtl/arithmetic/barrett_reduce_pipe.v" "$R/rtl/arithmetic/montgomery_reduce_pipe.v" "$R/rtl/arithmetic/mod_mul_pipe.v" \
 "$R/rtl/ntt/zetas_rom.v" "$R/rtl/ntt/butterfly_pipe.v" "$R/rtl/ntt/intt_butterfly_pipe.v" "$R/rtl/ntt/intt_scaler_pipe.v" "$R/rtl/ntt/ntt_scheduler_pipe.v" "$R/rtl/ntt/intt_scheduler_pipe.v" "$R/rtl/ntt/ntt_core_pipe.v" "$R/rtl/ntt/intt_core_pipe.v" \
 "$R/rtl/poly/poly_workspace.v" "$R/rtl/poly/poly_binary_pipe.v" "$R/rtl/poly/poly_add_pipe.v" "$R/rtl/poly/poly_sub_pipe.v" "$R/rtl/poly/poly_reduce_pipe.v" "$R/rtl/poly/poly_transform_pipe.v" "$R/rtl/poly/poly_ntt_pipe.v" "$R/rtl/poly/poly_intt_pipe.v" \
 "$R/rtl/poly/polyvec_workspace.v" "$R/rtl/poly/polyvec_elementwise_pipe.v" "$R/rtl/poly/polyvec_add_pipe.v" "$R/rtl/poly/polyvec_sub_pipe.v" "$R/rtl/poly/polyvec_reduce_pipe.v" "$R/rtl/poly/polyvec_ntt_pipe.v" "$R/rtl/poly/polyvec_intt_pipe.v" \
 "$R/tb/block/tb_polyvec_elementwise_pipe.v" "$R/tb/block/${TOP}.v"
timeout "$LIMIT" vvp "$O/t.vvp" +VECTOR_FILE="$O/$VEC"|tee "$O/run.log";grep -q 'PASS tb_polyvec_elementwise_pipe' "$O/run.log"
