# M4.3 Polynomial MultiplyNTTs Report

`poly_basemul_pipe` uses three synchronous `poly_workspace` instances and one
II=1 BaseCaseMultiply pipeline. It issues 128 pair reads, converts ROM
`gamma*R` to mathematical gamma, aligns pair metadata for 9 datapath cycles,
and commits 128 pair writes. Measured start-to-done is 142 cycles.

`timeout 90s ./sim/scripts/run_poly_basemul_pipe.sh` PASS: 32 deterministic
independent Python `multiply_ntts` vectors and 8,192 coefficient comparisons.
Each transform issued 128 requests, wrote all 256 logical coefficients once,
published canonical `POLY_DOMAIN_NTT`, and asserted one-cycle done. No M2/M3
or legacy RTL was changed. No synthesis/Fmax claim is made; M2.3b is pending.
