#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-public-encaps.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count 1 >/dev/null
timeout 300s iverilog -g2012 -I "$R/rtl/common" -s tb_mlkem_encaps -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/kpke_matrix_row_sampler.v "$R"/rtl/kpke/kpke_noise_vector_sampler.v "$R"/rtl/kpke/kpke_encrypt.v "$R"/rtl/mlkem/mlkem_ek_check.v "$R"/rtl/mlkem/mlkem_encaps_internal.v "$R"/rtl/mlkem/mlkem_encaps.v "$R"/tb/block/tb_mlkem_encaps.v
timeout "${MLKEM_ENCAPS_TIMEOUT:-600s}" vvp "$T/t.vvp" +VEC_DIR="$T/v" ${MLKEM_ENCAPS_PLUSARGS:-}
