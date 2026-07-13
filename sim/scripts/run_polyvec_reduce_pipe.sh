#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/run_polyvec_elementwise.sh" tb_polyvec_reduce_pipe polyvec_reduce.mem 80s
