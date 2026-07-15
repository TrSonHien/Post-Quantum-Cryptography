#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-public-decaps.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count 1 >/dev/null
timeout 480s iverilog -g2012 -I "$R/rtl/common" -s tb_mlkem_decaps -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/kpke_matrix_row_sampler.v "$R"/rtl/kpke/kpke_noise_vector_sampler.v "$R"/rtl/kpke/kpke_decrypt.v "$R"/rtl/kpke/kpke_encrypt.v "$R"/rtl/mlkem/mlkem_decaps_input_check.v "$R"/rtl/mlkem/mlkem_decaps_internal.v "$R"/rtl/mlkem/mlkem_decaps.v "$R"/tb/block/tb_mlkem_decaps.v
timeout "${MLKEM_DECAPS_TIMEOUT:-900s}" vvp "$T/t.vvp" +VEC_DIR="$T/v" ${MLKEM_DECAPS_PLUSARGS:-}
