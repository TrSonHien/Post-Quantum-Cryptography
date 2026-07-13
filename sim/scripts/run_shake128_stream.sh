#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_keccak_stream_test.sh" tb_shake128_stream tb/block/tb_shake128_stream.v
