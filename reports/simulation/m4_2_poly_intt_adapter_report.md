# M4.2 Polynomial Inverse NTT Adapter Report

`poly_intt_pipe` uses the same serialized workspace controller around the
unchanged `intt_core_pipe`. Input must be complete `POLY_DOMAIN_NTT`; output is
published as complete `POLY_DOMAIN_NORMAL` only after M3's seven inverse stages
and two-lane final scaler finish. The adapter performs no additional scaling
and never uses legacy operand 1441.

Measured start-to-done is 1608 cycles: 256 unique preload transfers, the frozen
1090-cycle scaled inverse, 256 unique logical result indices plus the final
synchronous response cycle, and five controller/acquire/publish cycles. Access
uses only public M3 logical indices; physical banks are not visible.

`timeout 80s ./sim/scripts/run_poly_intt_pipe.sh` PASS: 32 independent
NTT-domain polynomials, 8192 Python inverse comparisons, canonical output, and
constant cycle count. Tests also reject incomplete/wrong-domain and overwrite
starts, exercise illegal busy accesses, reset preload/compute/readback phases,
verify no premature NORMAL metadata, and restart successfully after reset.

M3 RTL was not modified. M4.3 pointwise/basemul remains pending. No
synthesis/Fmax claim is made; M2.3b remains pending.
