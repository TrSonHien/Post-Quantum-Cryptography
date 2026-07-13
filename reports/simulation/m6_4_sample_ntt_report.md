# M6.4 Integrated SampleNTT Report

Sixty-four independent SHAKE128/FIPS vectors pass all 16,384 coefficients.
The tested streams request 10,086 continuing three-byte groups. Per vector,
groups range from 148 to 169 with integer average 157; no-stall cycles range
from 1124 to 1256 with integer average 1172. With deterministic output stalls,
cycles range from 1155 to 1291 with average 1205. Output order and canonical NTT
domain match the independent Python Algorithm 7 model exactly.

The engine initializes M5 XOF once with `seed||index0||index1`, permits only
one outstanding squeeze request, and continues the same context for every
group. There is no functional iteration/rejection limit. The shell runner's
wall-clock timeout and TB cycle watchdog are verification guards only. Stalled
output is stable; a mid-XOF reset cancels the context and a fresh init replays
all 256 coefficients successfully.
