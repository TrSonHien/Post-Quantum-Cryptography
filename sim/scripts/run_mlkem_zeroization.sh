#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-zeroize.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
timeout 30s iverilog -g2012 -s tb_mlkem_zeroize_controller -o "$T/t.vvp" "$R/rtl/mlkem/mlkem_zeroize_controller.v" "$R/tb/unit/tb_mlkem_zeroize_controller.v"
timeout 30s vvp "$T/t.vvp"
