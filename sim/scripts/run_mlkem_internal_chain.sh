#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";T="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-internal-chain.XXXXXX")";START="$(date +%s)";trap 'rm -rf "$T"' EXIT INT TERM
KEYGEN="${M8_KEYGEN_VECTORS:-2}";ENCAPS="${M8_ENCAPS_VECTORS:-2}";DECAPS="${M8_DECAPS_VECTORS:-4}";FALLBACK="${M8_FALLBACK_VECTORS:-4}"
if [[ "$FALLBACK" != "$DECAPS" ]]; then echo "M8_INTERNAL_CHAIN_STATUS=FAIL reason=decaps_tb_runs_one_valid_and_one_fallback_per_vector" >&2; exit 2; fi
echo "M8_INTERNAL_CHAIN_PROGRESS phase=keygen vectors=$KEYGEN"
timeout 900s env M8_VECTOR_COUNT="$KEYGEN" "$R/sim/scripts/run_mlkem_keygen_internal.sh"
echo "M8_INTERNAL_CHAIN_PROGRESS phase=encaps vectors=$ENCAPS"
timeout 900s env M8_VECTOR_COUNT="$ENCAPS" "$R/sim/scripts/run_mlkem_encaps_internal.sh"
echo "M8_INTERNAL_CHAIN_PROGRESS phase=decaps vectors=$DECAPS fallback_vectors=$FALLBACK"
timeout 1800s env M8_VECTOR_COUNT="$DECAPS" "$R/sim/scripts/run_mlkem_decaps_internal.sh"
echo "INTERNAL_CHAIN_STATUS=PASS";echo "KEYGEN_INTERNAL_VECTORS=$KEYGEN";echo "ENCAPS_INTERNAL_VECTORS=$ENCAPS";echo "VALID_DECAPS_VECTORS=$DECAPS";echo "IMPLICIT_REJECTION_VECTORS=$FALLBACK";echo "ELAPSED_SECONDS=$(($(date +%s)-START))"
