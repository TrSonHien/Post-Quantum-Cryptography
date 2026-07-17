#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd $(dirname $0)/../.. && pwd)
DIR=$ROOT/synth/m9
cd $ROOT
validate_filelist() {
  awk 'NF { if (seen[$0]++) { print "M9_FILELIST_STATUS=FAIL duplicate=" $0; exit 2 } if ($0 ~ /^tb\//) { print "M9_FILELIST_STATUS=FAIL testbench=" $0; exit 2 } }' $DIR/rtl.f
  while IFS= read -r f; do
    [[ -z "$f" || -f "$ROOT/$f" ]] || { echo "M9_FILELIST_STATUS=FAIL missing=$f"; exit 2; }
  done < $DIR/rtl.f
  echo "M9_FILELIST_STATUS=PASS files=$(grep -cve '^$' $DIR/rtl.f)"
}
validate_filelist
if ! command -v yosys >/dev/null 2>&1; then
  echo "M9_YOSYS_SYNTH_STATUS=ENVIRONMENT_BLOCKED tool=yosys"
  exit 0
fi
mkdir -p $DIR/reports
LOG=$(mktemp /tmp/m9-yosys.XXXXXX.log)
trap 'rm -f "$LOG"' EXIT INT TERM
if timeout 1800s yosys -ql $LOG -s $DIR/yosys_synth.tcl; then
  cat $LOG
  echo "M9_YOSYS_SYNTH_STATUS=PASS"
else
  rc=$?
  tail -200 $LOG
  echo "M9_YOSYS_SYNTH_STATUS=FAIL exit=$rc"
  exit $rc
fi
