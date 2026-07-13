# M4 to K-PKE Handoff

For a selected matrix row `A_hat[i][0..2]` and vector `s_hat[0..2]`, M7 may
load those two complete canonical NTT-domain polyvecs into
`polyvec_basemul_acc_pipe`. The result is

```text
sum(j=0..2, MultiplyNTTs(A_hat[i][j], s_hat[j])) mod q
```

as one complete canonical `POLY_DOMAIN_NTT` polynomial. Operand order is
mathematically symmetric, but callers retain matrix-row/vector naming.

M7 owns transposed versus non-transposed matrix selection and repeats the call
for rows 0, 1, and 2 to form a result polyvec. M4 receives an already selected
row. It does not generate matrix A, absorb SHAKE output, select KeyGen versus
Encrypt, perform codec/sampling, or orchestrate K-PKE.

Both operands require 768 indexed coefficient loads with all three domains
NTT. The engine owns memory while busy; callers must not load or read until
done. Result reads are synchronous by logical coefficient index. Sticky error
reports incomplete/mixed/wrong-domain input, invalid poly index, busy access,
premature read, or unread-result overwrite. Measured compute duration is 2757
cycles, excluding external operand load and final result readback.
