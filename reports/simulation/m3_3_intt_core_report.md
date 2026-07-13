# M3.3 Banked Pipelined Inverse NTT Core Report

## Architecture and contract

`intt_scheduler_pipe` issues seven Gentleman-Sande stages at II=1. Each stage
contains 128 requests and waits for committed-write drain plus external
`stage_advance`. `intt_core_pipe` connects the scheduler to synchronous
`ntt_pingpong_banks`, aligns the descending forward-ROM zeta and write metadata,
uses `intt_butterfly_pipe`, and swaps roles only with empty pending traffic.

The exact public interface is:

```text
clk, rst_n, start -> busy, done, error
preload_en, preload_idx[7:0], preload_coeff[11:0] -> preload_ready
result_rd_req, result_rd_idx[7:0] -> result_rd_valid, result_rd_data[11:0]
```

Preload and result access are idle-only. Preload accepts canonical NTT-domain
coefficients and pairs indices differing at bit 1; the bit-1-zero coefficient
must be presented before its partner. Result read is legal only after completed
scaling and returns canonical normal-domain coefficients with one-cycle RAM
latency. Reset is synchronous active-low, clears control and valids, cancels
work, and does not clear memory payload. `done` is one cycle and is delayed
until M3.4 scaling completes; `error` is sticky until reset.

## Proven layouts and zetas

The inverse layouts are the exact reverse of committed M3.2: `b=i1,rm1` to
`b=i2^i1,rm1`, then `b=i3^i2,rm2`, `b=i4^i3,rm3`, `b=i5^i4,rm4`,
`b=i6^i5,rm5`, `b=i7^i6,rm6`, and finally `b=i7,rm7`.
`tb/tools/check_ntt_layouts.py` proves all eight layouts bijective and all 896
inverse source/destination pairs conflict-free. Zeta addresses are 127 down to
1, constant within each GS group.

## Edge timing

For request edge M: RAM response and butterfly input are visible/sampled at
M+1; the five-stage butterfly output is visible after M+6; destination RAM
commits at M+7; drain is recognized next; role swap and `stage_advance` occur
at M+9. The measured issue-to-write-commit latency is 7 cycles. The measured
start through final inverse-stage swap is 954 cycles.

Metadata carries destination layout/banks/addresses, stage, group, offset,
butterfly number, zeta address, and both last markers through a six-cycle
delay. Pending read, butterfly, and write counters increment on acceptance and
decrement on response/output/commit; swap requires the last committed write
and all counters draining to zero.

## Verification

- Scheduler: 896 requests, seven waits, seven advances, all mappings and markers PASS.
- Core: 896 reads, responses, butterfly inputs, butterfly outputs, and writes; seven drains/swaps/advances PASS.
- Standalone Python differential: 31 polynomials and 7936 coefficients PASS.
- Control/reset: busy access errors and reset during issue, drain, pre-swap, final stage, scaler issue/drain/pre-swap, followed by restart PASS.

Changed implementation files are `rtl/ntt/intt_scheduler_pipe.v`,
`rtl/ntt/intt_core_pipe.v`, their bounded TBs/runners, and the layout/vector
tools. Limitations: no backpressure interface and no synthesis timing evidence.
