#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/secure-leaf.XXXXXX")";trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -I "$R/rtl/common" -s tb_secure_payload_reset -o "$T/t.vvp" "$R/rtl/memory/sync_1r1w_ram.v" "$R/rtl/control/fixed_latency_delay.v" "$R/rtl/poly/poly_workspace.v" "$R/tb/unit/tb_secure_payload_reset.v"
timeout 30s vvp "$T/t.vvp"
