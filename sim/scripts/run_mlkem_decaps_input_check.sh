#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-decaps-check.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count 1 >/dev/null
timeout 60s iverilog -g2012 -s tb_mlkem_decaps_input_check -o "$T/t.vvp" \
 "$R/rtl/keccak/keccak_round.v" "$R/rtl/keccak/keccak_f1600_core.v" "$R/rtl/keccak/keccak_sponge_ctx.v" "$R/rtl/keccak/keccak_hash_stream.v" "$R/rtl/keccak/sha3_256_stream.v" "$R/rtl/keccak/mlkem_h.v" \
 "$R/rtl/mlkem/mlkem_decaps_input_check.v" "$R/tb/unit/tb_mlkem_decaps_input_check.v"
timeout 60s vvp "$T/t.vvp" +VEC_DIR="$T/v"
