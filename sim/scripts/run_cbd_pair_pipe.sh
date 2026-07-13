#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-cbdpair.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_cbd_vectors.py" --output-dir "$O";iverilog -g2012 -Wall -s tb_cbd_pair_pipe -o "$O/t.vvp" "$R/rtl/sampler/cbd_pair_pipe.v" "$R/tb/unit/tb_cbd_pair_pipe.v";timeout 40s vvp "$O/t.vvp" +VECTOR_FILE="$O/cbd_pair.mem"|tee "$O/run.log";grep -q 'PASS tb_cbd_pair_pipe' "$O/run.log"
