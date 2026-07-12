# Memory Architecture

## M1 v0.1 synchronous polynomial-memory contract

The NTT baseline uses out-of-place ping-pong storage. One side is the source
set and one side is the destination set; roles swap only after a stage's final
write commits. Each set contains two banks of 128 canonical 12-bit coefficients:

```text
source:      src_bank0[0:127], src_bank1[0:127]
destination: dst_bank0[0:127], dst_bank1[0:127]
```

Each bank provides one registered read and one synchronous write interface.
Read latency is exactly one cycle: a read accepted at edge `t` produces
`rd_valid` and `rd_data` after edge `t+1`. Writes commit on the accepting edge.
The NTT schedule performs one read from each source bank and one write to each
destination bank per cycle, giving two coefficient reads and two coefficient
writes per cycle.

## Semantics

- memories and payload arrays are not reset;
- control and read-valid state are synchronously reset with active-low `rst_n`;
- a bank receives at most one read and one write request per cycle;
- source and destination are distinct physical sets within a stage, so normal
  operation never reads and writes the same bank;
- same-bank/address read-write collision is illegal and must assert in
  simulation/formal checks rather than depend on macro behavior;
- same-bank duplicate writes and out-of-range addresses are illegal;
- bank/address metadata is registered with read-valid and arithmetic payload;
- stage-role swap is control state, not a data copy.

Read-during-write behavior is intentionally unspecified because legal schedules
do not invoke it. A concrete SRAM wrapper may select a macro mode, but
architecture and verification cannot depend on old-data, new-data, or no-change
behavior.

## Loading and draining

External loading writes canonical coefficients according to the first-stage
bank map. Final draining translates the final physical bank/address map back to
logical coefficient index. Load/drain channels use valid/ready and may run at a
different bandwidth from the two-coefficient NTT datapath.

Polynomial-vector, matrix, key, ciphertext, and shared-secret capacities remain
for later milestones. They must reuse this synchronous request/response
discipline and explicit ownership/domain metadata.

## M2.1 implementation

- `rtl/memory/sync_1r1w_ram.v` implements each 1R/1W bank with one-cycle
  registered read data/valid, synchronous writes, unreset memory contents, and
  a simulation-fatal same-address read/write check.
- `rtl/memory/ntt_bank_map.v` implements boundary and transition formulas.
- `rtl/memory/ntt_pingpong_banks.v` composes four 128x12 banks, maps logical
  coefficient pairs, routes responses back to logical order, and swaps roles
  only with no request or pending read.

The wrapper supports one logical two-coefficient read and one logical
two-coefficient write each cycle (`II=1`). It is a storage primitive only; stage
scheduling and NTT arithmetic are intentionally absent.
