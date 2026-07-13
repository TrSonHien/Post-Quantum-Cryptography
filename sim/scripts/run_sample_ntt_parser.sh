#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-parser.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_sample_ntt_vectors.py" --output-dir "$O";iverilog -g2012 -Wall -s tb_sample_ntt_parser -o "$O/t.vvp" "$R/rtl/sampler/sample_ntt_parser.v" "$R/tb/unit/tb_sample_ntt_parser.v";timeout 40s vvp "$O/t.vvp" +VECTOR_FILE="$O/parser.mem"|tee "$O/run.log";grep -q 'PASS tb_sample_ntt_parser' "$O/run.log"
