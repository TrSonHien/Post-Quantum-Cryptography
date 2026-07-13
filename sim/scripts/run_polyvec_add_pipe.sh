#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/run_polyvec_elementwise.sh" tb_polyvec_add_pipe polyvec_add.mem 80s
