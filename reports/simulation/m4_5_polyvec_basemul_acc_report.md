# M4.5 Polyvec MultiplyNTTs Accumulation Report

One shared `poly_basemul_pipe` processes vector elements 0, 1, and 2. Product
0 initializes a canonical NTT accumulator; products 1 and 2 are synchronously
read with the accumulator and added through one verified `mod_add_pipe` lane.
Every accumulation write is canonical, so no wider lazy range escapes.

Measured start-to-done is 2757 cycles. Per result the controller performs
three polynomial MultiplyNTTs operations, 384 BaseCaseMultiply requests, 384
product pair writes, two 256-coefficient accumulation passes (512 writes), and
publishes 256 canonical NTT coefficients.

`timeout 180s ./sim/scripts/run_polyvec_basemul_acc_pipe.sh` PASS: 32
deterministic independent Python polyvec dot products, 8192 final coefficient
comparisons, exact structural counts, reset cancellation, restart, domain and
overwrite/error checks. No synthesis/Fmax or K-PKE completion claim is made;
M2.3b remains pending.
