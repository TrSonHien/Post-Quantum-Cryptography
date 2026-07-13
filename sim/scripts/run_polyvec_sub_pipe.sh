#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/run_polyvec_elementwise.sh" tb_polyvec_sub_pipe polyvec_sub.mem 80s
