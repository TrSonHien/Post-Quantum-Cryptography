#!/usr/bin/env bash
set -euo pipefail
TOP="${1:?top}";TB="${2:?tb}";VEC="${3:?vec}";ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-mlkem.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
python3 "$ROOT/tb/tools/gen_mlkem_hash_vectors.py" --output-dir "$TMP/vectors"
FILES=(keccak_round.v keccak_f1600_core.v keccak_sponge_ctx.v keccak_hash_stream.v sha3_256_stream.v sha3_512_stream.v shake256_stream.v mlkem_h.v mlkem_g.v mlkem_j.v mlkem_prf.v mlkem_xof.v);RTL=();for f in "${FILES[@]}";do RTL+=("$ROOT/rtl/keccak/$f");done
EXTRA=();[[ "$TOP" == tb_mlkem_hgj ]]&&EXTRA+=("$ROOT/tb/block/keccak_stream_test_driver.v")
timeout 60s iverilog -g2012 -Wall -s "$TOP" -o "$TMP/test.vvp" "${RTL[@]}" "${EXTRA[@]}" "$ROOT/$TB"
(cd "$TMP";timeout 300s vvp test.vvp +VECTORS="$TMP/vectors/$VEC")
