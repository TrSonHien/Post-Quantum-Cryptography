#!/usr/bin/env bash
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)/run_keccak_sponge_ctx.sh"
