#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem768-top.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_mlkem_vectors.py" --output-dir "$T/v" --count 1 >/dev/null
timeout 600s iverilog -g2012 -I "$R/rtl/common" -s tb_mlkem768_top -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/*.v "$R"/rtl/mlkem/*.v "$R"/tb/system/tb_mlkem768_top.v
timeout "${MLKEM_TOP_TIMEOUT:-900s}" vvp "$T/t.vvp" +VEC_DIR="$T/v"
