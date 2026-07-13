#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m7-decrypt.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_kpke_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_kpke_decrypt -o "$O/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/kpke_decrypt.v "$R"/tb/block/tb_kpke_decrypt.v
timeout 900s vvp "$O/t.vvp" +VECTOR_FILE="$O/decrypt.mem" ${KPKE_VVP_ARGS:-} | tee "$O/run.log"
grep -q 'PASS tb_kpke_decrypt' "$O/run.log"
