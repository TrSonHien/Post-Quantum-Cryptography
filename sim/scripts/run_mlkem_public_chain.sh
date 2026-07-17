#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."&&pwd)";N="${M8_PUBLIC_CHAINS:-${M8_PUBLIC_CHAIN_VECTORS:-2}}"
timeout 1800s env M8_PUBLIC_CHAIN_VECTORS="$N" MLKEM_TOP_TB_MODULE=tb_mlkem_public_chain MLKEM_TOP_TB_SOURCE="$R/tb/system/tb_mlkem_public_chain.v" "$R/sim/scripts/run_mlkem768_top.sh"
echo "PUBLIC_CHAIN_STATUS=PASS";echo "PUBLIC_CHAIN_VECTORS=$N"
