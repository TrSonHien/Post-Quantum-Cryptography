#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m7-matrix.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_kpke_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -s tb_kpke_matrix_row_sampler -o "$O/t.vvp" "$R/rtl/keccak/keccak_round.v" "$R/rtl/keccak/keccak_f1600_core.v" "$R/rtl/keccak/keccak_sponge_ctx.v" "$R/rtl/keccak/mlkem_xof.v" "$R/rtl/sampler/sample_ntt_parser.v" "$R/rtl/sampler/mlkem_sample_ntt.v" "$R/rtl/kpke/kpke_matrix_row_sampler.v" "$R/tb/block/tb_kpke_matrix_row_sampler.v"
timeout 360s vvp "$O/t.vvp" +VECTOR_FILE="$O/matrix_rows.mem" | tee "$O/run.log"
grep -q 'PASS tb_kpke_matrix_row_sampler' "$O/run.log"
