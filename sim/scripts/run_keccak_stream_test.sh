#!/usr/bin/env bash
set -euo pipefail
TOP="${1:?top}";TB="${2:?tb}";ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-stream.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
python3 "$ROOT/tb/tools/gen_keccak_sponge_vectors.py" --output-dir "$TMP/vectors"
RTL=(keccak_round.v keccak_f1600_core.v keccak_sponge_ctx.v keccak_hash_stream.v sha3_256_stream.v sha3_512_stream.v shake128_stream.v shake256_stream.v)
FILES=();for f in "${RTL[@]}";do FILES+=("$ROOT/rtl/keccak/$f");done
timeout 60s iverilog -g2012 -Wall -s "$TOP" -o "$TMP/test.vvp" "${FILES[@]}" "$ROOT/tb/block/keccak_stream_test_driver.v" "$ROOT/$TB"
ARGS=(+VECTORS="$TMP/vectors/keccak_hash.vec");[[ "${DEBUG_WAVES:-0}" == 1 ]]&&ARGS+=(+DEBUG_WAVES)
(cd "$TMP";timeout 240s vvp test.vvp "${ARGS[@]}")
