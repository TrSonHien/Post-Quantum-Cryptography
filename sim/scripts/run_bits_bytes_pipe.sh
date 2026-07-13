#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; O="$(mktemp -d "${TMPDIR:-/tmp}/m6-bits.XXXXXX")"; trap 'rm -rf "$O"' EXIT INT TERM
iverilog -g2012 -Wall -s tb_bits_bytes_pipe -o "$O/t.vvp" "$R/rtl/codec/bits_to_bytes_pipe.v" "$R/rtl/codec/bytes_to_bits_pipe.v" "$R/tb/unit/tb_bits_bytes_pipe.v"
timeout 20s vvp "$O/t.vvp" | tee "$O/run.log"; grep -q 'PASS tb_bits_bytes_pipe' "$O/run.log"
