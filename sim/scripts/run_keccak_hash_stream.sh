#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_keccak_stream_test.sh" tb_keccak_hash_stream tb/block/tb_keccak_hash_stream.v
