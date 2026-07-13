#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";O="$(mktemp -d "${TMPDIR:-/tmp}/m7-noisevec.XXXXXX")";trap 'rm -rf "$O"' EXIT INT TERM
PYTHONPATH="$R" python3 "$R/tb/tools/gen_kpke_vectors.py" --output-dir "$O"
iverilog -g2012 -Wall -s tb_kpke_noise_vector_sampler -o "$O/t.vvp" "$R/rtl/keccak/keccak_round.v" "$R/rtl/keccak/keccak_f1600_core.v" "$R/rtl/keccak/keccak_sponge_ctx.v" "$R/rtl/keccak/keccak_hash_stream.v" "$R/rtl/keccak/mlkem_prf.v" "$R/rtl/sampler/sample_poly_cbd_pipe.v" "$R/rtl/sampler/mlkem_noise_sampler.v" "$R/rtl/kpke/kpke_noise_vector_sampler.v" "$R/tb/block/tb_kpke_noise_vector_sampler.v"
timeout 240s vvp "$O/t.vvp" +VECTOR_FILE="$O/noise_vectors.mem" | tee "$O/run.log"
grep -q 'PASS tb_kpke_noise_vector_sampler' "$O/run.log"
