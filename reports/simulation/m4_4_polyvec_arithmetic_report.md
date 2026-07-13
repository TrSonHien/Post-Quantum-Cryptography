# M4.4 Polyvec Arithmetic Report

One `polyvec_elementwise_pipe` serializes elements 0, 1, and 2 through one
shared M4.1 polynomial child. It transfers complete coefficients through
synchronous logical interfaces and retains vector busy through final publish.

| Operation | Vectors | Comparisons | Cycles | Result |
|---|---:|---:|---:|---|
| Add | 16 | 12288 | 2731 | PASS |
| Subtract | 16 | 12288 | 2731 | PASS |
| Reduce | 16 | 12288 | 1963 | PASS |

Matching NORMAL/NTT domains are preserved. Reset during operation, clean
restart, incomplete/result-overwrite rejection, one-cycle done, and canonical
result behavior pass. Commands are the corresponding bounded
`run_polyvec_{add,sub,reduce}_pipe.sh` runners.
