#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/m5-zeroize.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -s tb_m5_mlkem_zeroize -o "$T/t.vvp" "$R"/rtl/keccak/*.v "$R/tb/block/tb_m5_mlkem_zeroize.v"
timeout 30s vvp "$T/t.vvp"
