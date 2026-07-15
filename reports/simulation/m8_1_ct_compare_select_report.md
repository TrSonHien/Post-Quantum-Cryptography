# M8.1 Constant-Work Compare/Select Development Report

`run_mlkem_ct_compare_select.sh` passes six cases and 192 exact K bytes.  Equal,
first/middle/final, all-byte mismatch, and reset/restart execute exactly 1,088
compare and 32 full-mask select iterations.  Mismatch and mask are zero before
output; all module-owned inputs and output staging are overwritten.
