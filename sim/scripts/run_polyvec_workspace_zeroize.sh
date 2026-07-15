#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/polyvec-ws-zeroize.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -s tb_polyvec_workspace_zeroize -o "$T/t.vvp" \
  "$R/rtl/poly/poly_workspace.v" "$R/rtl/poly/polyvec_workspace.v" \
  "$R/tb/unit/tb_polyvec_workspace_zeroize.v"
timeout 30s vvp "$T/t.vvp"
