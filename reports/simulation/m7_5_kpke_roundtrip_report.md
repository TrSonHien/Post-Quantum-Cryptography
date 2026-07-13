# M7.5 K-PKE Roundtrip Report

`timeout 1800s ./sim/scripts/run_kpke_roundtrip.sh` PASS for 20 complete chained
transactions.  Each case runs RTL KeyGen(d), feeds the actual RTL ekPKE to RTL
Encrypt(ekPKE,m,r), feeds the actual RTL dkPKE and ciphertext to RTL Decrypt,
and compares every intermediate final byte to the independent Python oracle.
The test performs 69,120 byte comparisons and also checks the recovered message
against the original.

The set includes zero, all-ff, sequential, alternating, and deterministic
random d/m/r values.  It includes nonsymmetric matrix-sensitive seeds and the
separate M7.1 proof checks all matrix entries/orientations.  Per-vector measured
cycles are 46,438--46,738 for KeyGen, 54,510--54,810 for Encrypt, and 17,755
for Decrypt under the roundtrip no-stall output convention.

The TB gates clocks only to inactive mode controllers to avoid simulator work;
the active controller always receives the project clock and actual produced
bytes are retained and passed to the next mode.  This is not an RTL clock-gating
architecture.  The standalone mode tests independently apply output stalls.

Project Python differential vectors are not final authoritative CAVP/ACVP
validation.  No synthesis, area, timing, or Fmax claim is made.
