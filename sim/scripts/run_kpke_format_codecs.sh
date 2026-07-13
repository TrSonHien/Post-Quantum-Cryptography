#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m6-format.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM;PYTHONPATH="$R" python3 "$R/tb/tools/gen_codec_vectors.py" --output-dir "$O"
for spec in 'ek 296 288' 'dk 288 288' 'ct 272 240';do set -- $spec;n=$1;w=$2;s=$3;iverilog -g2012 -Wall -s tb_kpke_format_codecs -Ptb_kpke_format_codecs.WORDS="$w" -Ptb_kpke_format_codecs.SPLIT="$s" -o "$O/$n.vvp" "$R/rtl/codec/kpke_format_pipe.v" "$R/tb/block/tb_kpke_format_codecs.v";timeout 60s vvp "$O/$n.vvp" +VECTOR_FILE="$O/kpke_$n.mem";done|tee "$O/run.log";grep -c 'PASS tb_kpke_format_codecs' "$O/run.log"|grep -q '^3$'
