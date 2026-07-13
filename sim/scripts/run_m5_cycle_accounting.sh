#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-cycle.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
FILES=(keccak_round.v keccak_f1600_core.v keccak_sponge_ctx.v keccak_hash_stream.v sha3_256_stream.v sha3_512_stream.v shake128_stream.v shake256_stream.v mlkem_prf.v mlkem_xof.v);RTL=();for f in "${FILES[@]}";do RTL+=("$ROOT/rtl/keccak/$f");done
timeout 60s iverilog -g2012 -Wall -s tb_m5_cycle_accounting -o "$TMP/test.vvp" "${RTL[@]}" "$ROOT/tb/block/tb_m5_cycle_accounting.v"
(cd "$TMP";timeout 180s vvp test.vvp)
