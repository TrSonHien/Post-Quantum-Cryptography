#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd $(dirname $0)/../.. && pwd)
DIR=$ROOT/synth/m9
cd $DIR
if ! command -v genus >/dev/null 2>&1; then
  echo "M9_GENUS_SYNTH_STATUS=ENVIRONMENT_BLOCKED tool=genus"
  exit 0
fi
if [[ ! -v LIB_FILE || -z "$LIB_FILE" || ! -f "$LIB_FILE" ]]; then
  echo "M9_GENUS_SYNTH_STATUS=ENVIRONMENT_BLOCKED reason=LIB_FILE"
  exit 0
fi
mkdir -p $DIR/reports
timeout 3600s genus -files $DIR/genus_synth.tcl -log $DIR/reports/genus.log
echo "M9_GENUS_SYNTH_STATUS=PASS"
