#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_mlkem_hash_test.sh" tb_mlkem_xof tb/block/tb_mlkem_xof.v mlkem_xof.vec
