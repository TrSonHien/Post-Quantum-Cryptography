#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m4-polyvec-ws.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
iverilog -g2012 -Wall -s tb_polyvec_workspace -o "$O/t.vvp" "$R/rtl/poly/poly_workspace.v" "$R/rtl/poly/polyvec_workspace.v" "$R/tb/unit/tb_polyvec_workspace.v"
timeout 30s vvp "$O/t.vvp"|tee "$O/run.log";grep -q 'PASS tb_polyvec_workspace' "$O/run.log"
