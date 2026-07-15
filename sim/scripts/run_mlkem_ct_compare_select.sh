#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-ct-select.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
timeout 60s iverilog -g2012 -s tb_mlkem_ct_compare_select -o "$T/t.vvp" "$R/rtl/mlkem/mlkem_ct_compare_select.v" "$R/tb/unit/tb_mlkem_ct_compare_select.v"
timeout 60s vvp "$T/t.vvp"
