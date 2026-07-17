#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem768-top.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM;N="${M8_PUBLIC_CHAIN_VECTORS:-1}"
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count "$N" >/dev/null
TB_MODULE="${MLKEM_TOP_TB_MODULE:-tb_mlkem768_top}";TB_SOURCE="${MLKEM_TOP_TB_SOURCE:-$R/tb/system/tb_mlkem768_top.v}"
timeout 600s iverilog -g2012 -I "$R/rtl/common" -I "$R/tb/system" -s "$TB_MODULE" -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/*.v "$R"/rtl/mlkem/*.v "$TB_SOURCE"
for((i=0;i<N;i++));do printf -v pfx 'v%04d' "$i";echo "M8_PUBLIC_CHAIN_PROGRESS vector=$((i+1))/$N";timeout "${MLKEM_TOP_TIMEOUT:-900s}" vvp "$T/t.vvp" +VEC_DIR="$T/v" +VEC_PREFIX="$pfx";done
echo "PUBLIC_CHAIN_VECTORS=$N"
