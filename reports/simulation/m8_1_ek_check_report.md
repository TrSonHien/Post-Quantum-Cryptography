# M8.1 Encapsulation-Key Check Development Report

`run_mlkem_ek_check.sh` passes six cases.  Each scans all 768 d12 coefficients
in exactly 768 scan cycles.  Valid, raw12 q/q+1/4095 at first/middle/final,
multiple invalid values, rho mutation, malformed keep, and 1,184-byte scrub
are covered.  Broader vector counts and reused-child zeroization remain open.
