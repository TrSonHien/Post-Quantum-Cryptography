#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m6-sampler-zeroize.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT INT TERM
timeout 60s iverilog -g2012 -s tb_m6_sampler_zeroize -o "$TMP/tb.vvp" \
  "$ROOT/rtl/keccak/keccak_round.v" "$ROOT/rtl/keccak/keccak_f1600_core.v" \
  "$ROOT/rtl/keccak/keccak_sponge_ctx.v" "$ROOT/rtl/keccak/keccak_hash_stream.v" \
  "$ROOT/rtl/keccak/mlkem_prf.v" "$ROOT/rtl/keccak/mlkem_xof.v" \
  "$ROOT/rtl/sampler/cbd_pair_pipe.v" "$ROOT/rtl/sampler/sample_poly_cbd_pipe.v" \
  "$ROOT/rtl/sampler/sample_ntt_parser.v" "$ROOT/rtl/sampler/mlkem_noise_sampler.v" \
  "$ROOT/rtl/sampler/mlkem_sample_ntt.v" "$ROOT/tb/block/tb_m6_sampler_zeroize.v"
timeout 120s vvp "$TMP/tb.vvp"
