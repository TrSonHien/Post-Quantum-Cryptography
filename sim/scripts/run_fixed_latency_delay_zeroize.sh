#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/delay-zeroize.XXXXXX")"
trap 'rm -rf "$T"' EXIT INT TERM
iverilog -g2012 -Wall -s tb_fixed_latency_delay_zeroize -o "$T/t.vvp" \
  "$R/rtl/control/fixed_latency_delay.v" "$R/tb/unit/tb_fixed_latency_delay_zeroize.v"
timeout 20s vvp "$T/t.vvp"
