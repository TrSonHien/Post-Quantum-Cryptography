#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/run_polyvec_elementwise.sh" tb_polyvec_intt_pipe polyvec_intt.mem 180s
