#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-round.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
python3 "$ROOT/tb/tools/gen_keccak_round_vectors.py" --output-dir "$TMP/vectors"
timeout 60s iverilog -g2012 -Wall -o "$TMP/test.vvp" "$ROOT/rtl/keccak/keccak_round.v" "$ROOT/tb/unit/tb_keccak_round.v"
ARGS=(+VECTORS="$TMP/vectors/keccak_round.vec" +TRACES="$TMP/vectors/keccak_trace.vec");[[ "${DEBUG_WAVES:-0}" == 1 ]]&&ARGS+=(+DEBUG_WAVES)
(cd "$TMP";timeout 60s vvp test.vvp "${ARGS[@]}")
