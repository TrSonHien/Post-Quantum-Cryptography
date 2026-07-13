#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-ctx.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
python3 "$ROOT/tb/tools/gen_keccak_sponge_vectors.py" --output-dir "$TMP/vectors"
timeout 60s iverilog -g2012 -Wall -s tb_keccak_sponge_ctx -o "$TMP/test.vvp" "$ROOT/rtl/keccak/keccak_round.v" "$ROOT/rtl/keccak/keccak_f1600_core.v" "$ROOT/rtl/keccak/keccak_sponge_ctx.v" "$ROOT/tb/block/tb_keccak_sponge_ctx.v"
(cd "$TMP";timeout 300s vvp test.vvp +VECTORS="$TMP/vectors/keccak_hash.vec")
