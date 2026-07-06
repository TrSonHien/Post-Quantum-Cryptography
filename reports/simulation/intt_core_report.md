# intt_core Simulation Report

## Module name

`intt_core`

## Purpose

Verify the first inverse NTT core at polynomial level. The testbench loads a
full 256-coefficient polynomial, runs the DUT, reads back all coefficients, and
compares against a behavioral Kyber inverse NTT reference model including final
scaling by `zetas_inv[127]`.

## Files tested

- `rtl/ntt/intt_core.v`
- `rtl/ntt/ntt_addr_gen.v`
- `rtl/ntt/zetas_rom.v`
- `rtl/memory/poly_buffer.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_sub.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/unit/tb_intt_core.v`
- `sim/scripts/run_intt_core.sh`

## Test strategy

- Generate a 10 ns clock.
- Apply reset before each test pattern.
- Load all 256 input coefficients through the DUT load interface.
- Compute expected output using the Kyber inverse NTT nested loop:
  `len = 2, 4, 8, 16, 32, 64, 128`, with `k = 0`.
- Use `zetas_rom` inverse mode as the reference zeta source.
- Use a behavioral Montgomery multiply model matching the current RTL
  `mod_mul`/`montgomery_reduce` datapath.
- Apply final scaling with inverse zeta address `127`.
- Pulse `start` for one cycle.
- Check that `done` pulses once and that `busy` drops after completion.
- Read back all 256 coefficients and compare every output.
- Run three deterministic polynomial patterns.

## Simulation command

```sh
./sim/scripts/run_intt_core.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_intt_core.sh
```

Latest result:

```text
INFO tb_intt_core: pass_count=768 fail_count=0
PASS tb_intt_core
```

The current DUT elaborates and matches the behavioral inverse NTT reference for
the three deterministic full-polynomial patterns in `tb_intt_core`.
