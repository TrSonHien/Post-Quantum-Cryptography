# NTT -> INTT Round-Trip Simulation Report

## Flow

```text
poly -> ntt_core -> intt_core -> poly
```

## Purpose

Verify that the current forward NTT and inverse NTT cores compose correctly at
the block level. The testbench loads an input polynomial into `ntt_core`, runs
the forward transform, transfers all 256 NTT-domain coefficients into
`intt_core`, runs the inverse transform, and compares the final output against
the original polynomial multiplied by the Montgomery factor.

Important representation note:

```text
ntt_core -> intt_core returns coeff * R mod q
R = 2^16 mod 3329 = 2285
```

This matches the Kyber reference `invntt_tomont` convention. The current flow is
therefore:

```text
poly -> NTT -> INTT -> Montgomery-domain poly
```

## Files tested

- `rtl/ntt/ntt_core.v`
- `rtl/ntt/intt_core.v`
- `rtl/ntt/ntt_addr_gen.v`
- `rtl/ntt/zetas_rom.v`
- `rtl/ntt/butterfly_unit.v`
- `rtl/memory/poly_buffer.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_sub.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/block/tb_ntt_intt_roundtrip.v`
- `sim/scripts/run_ntt_intt_roundtrip.sh`

## Test strategy

- Generate a 10 ns shared clock and reset both cores.
- Load each deterministic input polynomial into `ntt_core`.
- Run `ntt_core` to completion and check the `done`/`busy` handshake.
- Transfer all 256 forward NTT output coefficients to `intt_core`.
- Run `intt_core` to completion and check the `done`/`busy` handshake.
- Compare all 256 final coefficients against `input_coeff * 2285 mod 3329`.
- Run four deterministic polynomial patterns.

## Simulation command

```sh
./sim/scripts/run_ntt_intt_roundtrip.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_ntt_intt_roundtrip.sh
```

Latest result:

```text
INFO tb_ntt_intt_roundtrip: pass_count=1024 fail_count=0
PASS tb_ntt_intt_roundtrip
```

The first exact raw-poly comparison intentionally exposed the representation:
pattern 0 returned `1 -> 2285`, `2 -> 1241`, etc., which is `coeff * R mod q`.
After updating the expected result to the Kyber Montgomery-domain convention,
the composed flow passes.
