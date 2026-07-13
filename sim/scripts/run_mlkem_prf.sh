#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_mlkem_hash_test.sh" tb_mlkem_prf tb/block/tb_mlkem_prf.v mlkem_prf.vec
