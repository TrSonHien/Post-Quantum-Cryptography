#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m7-protocol.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_kpke_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_kpke_protocol -o "$O/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/kpke_matrix_row_sampler.v "$R"/rtl/kpke/kpke_noise_vector_sampler.v "$R"/rtl/kpke/kpke_keygen.v "$R"/rtl/kpke/kpke_encrypt.v "$R"/rtl/kpke/kpke_decrypt.v "$R"/tb/block/tb_kpke_protocol.v
timeout 1800s vvp "$O/t.vvp" +VECTOR_FILE="$O/roundtrip.mem" | tee "$O/run.log"
grep -q 'PASS tb_kpke_protocol' "$O/run.log"
