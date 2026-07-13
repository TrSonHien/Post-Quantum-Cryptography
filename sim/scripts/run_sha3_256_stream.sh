#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_keccak_stream_test.sh" tb_sha3_256_stream tb/block/tb_sha3_256_stream.v
