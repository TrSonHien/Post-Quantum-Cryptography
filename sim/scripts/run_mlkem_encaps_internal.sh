#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-encaps-internal.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM;N="${M8_VECTOR_COUNT:-${M8_SMOKE_VECTORS:-1}}"
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count "$N" >/dev/null
timeout 240s iverilog -g2012 -I "$R/rtl/common" -s tb_mlkem_encaps_internal -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/kpke_matrix_row_sampler.v "$R"/rtl/kpke/kpke_noise_vector_sampler.v "$R"/rtl/kpke/kpke_encrypt.v "$R"/rtl/mlkem/mlkem_encaps_internal.v "$R"/tb/block/tb_mlkem_encaps_internal.v
for((i=0;i<N;i++));do printf -v pfx 'v%04d' "$i";echo "M8_ENCAPS_INTERNAL_PROGRESS vector=$((i+1))/$N";timeout "${M8_VECTOR_TIMEOUT:-300s}" vvp "$T/t.vvp" +VEC_DIR="$T/v" +VEC_PREFIX="$pfx";done
echo "ENCAPS_INTERNAL_VECTORS=$N"
