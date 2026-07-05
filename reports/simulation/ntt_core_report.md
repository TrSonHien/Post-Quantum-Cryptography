# ntt_core Simulation Report

## Module name

`ntt_core`

## Purpose

Verify the first forward NTT core at polynomial level. The testbench loads a full
256-coefficient polynomial, runs the DUT, reads back all coefficients, and
compares against a behavioral Kyber forward NTT reference model.

## Files tested

- `rtl/ntt/ntt_core.v`
- `rtl/ntt/ntt_addr_gen.v`
- `rtl/ntt/zetas_rom.v`
- `rtl/ntt/butterfly_unit.v`
- `rtl/memory/poly_buffer.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_sub.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/unit/tb_ntt_core.v`
- `sim/scripts/run_ntt_core.sh`

## Test strategy

- Generate a 10 ns clock.
- Apply reset before each test pattern.
- Load all 256 input coefficients through the DUT load interface.
- Compute expected output using the Kyber forward NTT nested loop:
  `len = 128, 64, 32, 16, 8, 4, 2`, with `k = 1`.
- Use `zetas_rom` as the reference zeta source.
- Use a behavioral Montgomery multiply model matching the current RTL
  `mod_mul`/`montgomery_reduce` datapath.
- Pulse `start` for one cycle.
- Check that `done` pulses once and that `busy` drops after completion.
- Read back all 256 coefficients and compare every output.
- Run two deterministic polynomial patterns.

## Simulation command

```sh
./sim/scripts/run_ntt_core.sh
```

## Final result

PASS.

Command run:

```sh
./sim/scripts/run_ntt_core.sh
```

Latest result:

```text
INFO tb_ntt_core: pass_count=512 fail_count=0
PASS tb_ntt_core
```

Previously resolved blockers:

- Port-name typos in `ntt_core.v`.
- ROM instance name mismatch: `zeta_rom` vs `zetas_rom`.
- Zeta width truncation in `ntt_core.v`.
- Butterfly and arithmetic port-width mismatches.

The current DUT elaborates and matches the behavioral forward NTT reference for
the two deterministic full-polynomial patterns in `tb_ntt_core`.
