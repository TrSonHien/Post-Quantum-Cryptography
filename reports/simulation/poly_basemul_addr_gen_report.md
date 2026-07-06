# poly_basemul_addr_gen Simulation Report

## Module name

`poly_basemul_addr_gen`

## Purpose

Verify the address and zeta-control schedule for Kyber
`poly_basemul_montgomery`.

The DUT generates the 128 two-coefficient base-multiplication operations used by
the Kyber reference loop:

```text
for i = 0..63:
  basemul(r[4*i],   a[4*i],   b[4*i],   zetas[64+i])
  basemul(r[4*i+2], a[4*i+2], b[4*i+2], -zetas[64+i])
```

## Files tested

- `rtl/poly/poly_basemul_addr_gen.v`

## Testbench files

- `tb/unit/tb_poly_basemul_addr_gen.v`
- `sim/scripts/run_poly_basemul_addr_gen.sh`

## Test strategy

- Check reset idle behavior.
- Pulse `start` and verify every valid schedule cycle.
- Check all 128 operations:
  - `op_index`
  - `a_addr0/a_addr1`
  - `b_addr0/b_addr1`
  - `r_addr0/r_addr1`
  - `zeta_addr`
  - `zeta_neg`
- Verify `valid == busy` during active schedule.
- Verify `done` pulses exactly once after the final operation.
- Run the complete schedule twice.
- During the second run, pulse `start` while `busy` is already high and verify
  that the active schedule continues instead of restarting.

## Simulation command

```sh
./sim/scripts/run_poly_basemul_addr_gen.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_poly_basemul_addr_gen.sh
```

Latest result:

```text
INFO tb_poly_basemul_addr_gen: run=0 checked 128 operations
INFO tb_poly_basemul_addr_gen: run=1 checked 128 operations
INFO tb_poly_basemul_addr_gen: run_count=2 pass_count=256 fail_count=0
PASS tb_poly_basemul_addr_gen
```
