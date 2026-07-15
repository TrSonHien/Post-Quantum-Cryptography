#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-dk-layout.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
timeout 30s iverilog -g2012 -s tb_mlkem_dk_layout -o "$T/t.vvp" "$R/rtl/mlkem/mlkem_dk_assemble.v" "$R/rtl/mlkem/mlkem_dk_parse.v" "$R/tb/unit/tb_mlkem_dk_layout.v"
timeout 30s vvp "$T/t.vvp"
