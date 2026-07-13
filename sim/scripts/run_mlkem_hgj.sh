#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_mlkem_hash_test.sh" tb_mlkem_hgj tb/block/tb_mlkem_hgj.v mlkem_hgj.vec
