#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/m7-zeroize.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_m7_kpke_zeroize -o "$T/t.vvp" "$R"/rtl/arithmetic/*.v "$R"/rtl/control/*.v "$R"/rtl/memory/*.v "$R"/rtl/ntt/*.v "$R"/rtl/poly/*.v "$R"/rtl/keccak/*.v "$R"/rtl/sampler/*.v "$R"/rtl/codec/*.v "$R"/rtl/kpke/*.v "$R/tb/block/tb_m7_kpke_zeroize.v"
timeout 60s vvp "$T/t.vvp"
