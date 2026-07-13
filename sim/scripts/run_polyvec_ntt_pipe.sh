#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/run_polyvec_elementwise.sh" tb_polyvec_ntt_pipe polyvec_ntt.mem 180s
