#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd $(dirname $0)/../.. && pwd)
FILELIST=$ROOT/synth/m9/rtl.f
TMP=$(mktemp -d /tmp/m9-elaboration.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM
cd $ROOT
awk 'NF { if (seen[$0]++) { print "M9_FILELIST_STATUS=FAIL duplicate=" $0; exit 2 } if ($0 ~ /^tb\//) { print "M9_FILELIST_STATUS=FAIL testbench=" $0; exit 2 } }' $FILELIST
while IFS= read -r f; do
  [[ -z "$f" || -f "$ROOT/$f" ]] || { echo "M9_FILELIST_STATUS=FAIL missing=$f"; exit 2; }
done < $FILELIST
echo "M9_FILELIST_STATUS=PASS files=$(grep -cve '^$' $FILELIST)"
if command -v verilator >/dev/null 2>&1; then
  timeout 600s verilator --lint-only --timing -Wall -Wno-fatal -DSYNTHESIS -I$ROOT/rtl/common --top-module mlkem768_top -f $FILELIST >$TMP/verilator.log 2>&1 || { tail -200 $TMP/verilator.log; echo "M9_VERILATOR_STATUS=FAIL"; exit 1; }
  echo "M9_VERILATOR_STATUS=PASS warnings=$(grep -c '%Warning' $TMP/verilator.log || true)"
else
  echo "M9_VERILATOR_STATUS=UNAVAILABLE"
fi
timeout 600s iverilog -g2012 -DSYNTHESIS -I $ROOT/rtl/common -s mlkem768_top -tnull -f $FILELIST >$TMP/iverilog.log 2>&1 || { tail -200 $TMP/iverilog.log; echo "M9_IVERILOG_STATUS=FAIL"; exit 1; }
echo "M9_IVERILOG_STATUS=PASS warnings=$(grep -ci 'warning:' $TMP/iverilog.log || true)"
echo "M9_ELABORATION_STATUS=PASS"
