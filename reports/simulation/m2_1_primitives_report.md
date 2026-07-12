# M2.1 Synchronous Memory and Pipeline-Control Primitives

## Implemented modules

- `sync_1r1w_ram`: one registered read and one synchronous write per cycle;
  latency 1, II=1, memory unreset, read-valid synchronously reset.
- `ntt_bank_map`: boundary and adjacent-stage XOR/remove-bit mappings.
- `ntt_pingpong_banks`: four physical 128x12 RAMs, logical pair routing,
  source/destination role swap, one pair read/write per cycle.
- `fixed_latency_delay`: parameterized latency, II=1, aligned payload/metadata.
- `rv_register_slice`: one-entry valid/ready elastic boundary, one-cycle
  no-stall latency and II=1.

## Verification

```text
PASS tb_sync_1r1w_ram           pass_count=515 fail_count=0
PASS tb_sync_1r1w_ram_collision expected SYNC_RAM_COLLISION fatal observed
PASS tb_ntt_pingpong_banks      pass_count=4866 fail_count=0
PASS tb_pipeline_control        pass_count=35 fail_count=0
PASS run_m2_1_primitives
```

Coverage includes sequential initialization/readback, deterministic random
updates, exact one-cycle read-valid behavior, reset with a read request,
memory persistence across reset, all 256 coefficients across every adjacent
forward/inverse NTT stage map, two role swaps, logical response ordering,
expected collision failure, fixed latency, metadata alignment, and register
slice backpressure stability/refill.

Adjacent regression results:

```text
PASS tb_ntt_core                  pass_count=512  fail_count=0
PASS tb_intt_core                 pass_count=768  fail_count=0
PASS tb_ntt_intt_roundtrip        pass_count=1024 fail_count=0
PASS tb_poly_add                  pass_count=1024 fail_count=0
PASS tb_poly_sub                  pass_count=1024 fail_count=0
PASS tb_poly_basemul_montgomery   pass_count=768  fail_count=0
```

The adjacent blocks continue using legacy `poly_buffer`; their PASS results are
regression evidence, not proof that they satisfy M1 synchronous-memory
contracts.

## Assertions and limits

The RAM terminates simulation on a same-address simultaneous read/write. The
ping-pong wrapper terminates on same-bank logical pairs or role swap with
active/pending traffic. Normal NTT traffic uses physically separate source and
destination sets and therefore does not rely on read-during-write behavior.

M2.1 adds no arithmetic or NTT controller. No synthesis, timing, area, power,
or Fmax claim is made. M2.2 has not started.
