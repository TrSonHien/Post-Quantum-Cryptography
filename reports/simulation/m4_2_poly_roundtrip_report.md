# M4.2 Polynomial NTT/INTT Roundtrip Report

`tb_poly_ntt_intt_roundtrip` transfers data only through the documented logical
polynomial result/load interfaces. For each of 30 canonical normal-domain
polynomials it runs the forward adapter, compares all 256 NTT coefficients to
the independent Python model, loads those values into the inverse adapter, and
compares all 256 final coefficients to Python and the original polynomial.

Result: PASS with 7680 intermediate forward comparisons and 7680 final inverse
comparisons. Measured adapter durations remain 1473 forward and 1608 inverse
cycles. The vector seed is `0x4d34504f`; exact regeneration is byte-identical.
A matching RTL-to-RTL result is therefore not the sole oracle.

Command: `timeout 90s ./sim/scripts/run_poly_ntt_intt_roundtrip.sh`.
No M4.3 or synthesis/Fmax claim is made.
