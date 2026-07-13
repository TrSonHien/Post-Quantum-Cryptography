# M4.1 Polynomial Workspace Report

`poly_workspace` stores 256 canonical 12-bit coefficients in fixed even/odd
128-entry banks. Logical mapping is `bank=index[0]`, `addr=index[7:1]`; pair
access reads or writes `(2p,2p+1)` at II=1 with one-cycle synchronous read
latency. Payload memory is unreset.

The interface provides external `load_begin/load_we`, synchronous indexed
result reads, internal indexed and pair reads/writes, and explicit acquire,
initialize, publish, and release controls. Ownership is external-load,
internal-operation, or external-result. A 256-bit bitmap and nine-bit count
track completeness independently from RAM contents. Duplicate pre-start loads
are legal overwrites and do not increment the count. Domain metadata is the
M4.0 two-bit encoding; sticky error clears only on synchronous reset.

`timeout 30s ./sim/scripts/run_poly_workspace.sh` PASS with 524 checks. The TB
loads all indices sequentially and in reverse order, reads all 256 values back
for both cases, checks duplicate overwrite, pair mapping, completeness/domain,
ownership blocking, one-cycle result valid, reset valid cancellation, payload
retention, and clean reuse. No asynchronous read or physical-bank interface is
exposed to callers.

No synthesis/Fmax claim is made. M2.3b remains pending.
