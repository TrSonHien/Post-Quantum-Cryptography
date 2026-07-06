# poly_basemul_montgomery Simulation Report

## Module name

`poly_basemul_montgomery`

## Purpose

Verify the poly-level Kyber `poly_basemul_montgomery()` datapath. The intended
test loads full A and B polynomials, runs the DUT, reads back all 256 R
coefficients, and compares each coefficient against a behavioral Kyber
`basemul()` reference model.

## Files tested

- `rtl/poly/poly_basemul_montgomery.v`
- `rtl/poly/poly_basemul_addr_gen.v`
- `rtl/ntt/basemul_unit.v`
- `rtl/ntt/zetas_rom.v`
- `rtl/memory/poly_buffer.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/unit/tb_poly_basemul_montgomery.v`
- `sim/scripts/run_poly_basemul_montgomery.sh`

## Test strategy

- Reset and check idle control state.
- Load three deterministic full-polynomial A/B patterns.
- Compute expected R with the Kyber loop:

```text
for i = 0..63:
  basemul(r[4*i],   a[4*i],   b[4*i],   zetas[64+i])
  basemul(r[4*i+2], a[4*i+2], b[4*i+2], -zetas[64+i])
```

- Use the same behavioral Montgomery multiply model as the existing
  `tb_basemul_unit`.
- Wait for `done`, check one-cycle done behavior, read all 256 output
  coefficients, and compare against expected values.

## Simulation command

```sh
./sim/scripts/run_poly_basemul_montgomery.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_poly_basemul_montgomery.sh
```

Latest result:

```text
INFO tb_poly_basemul_montgomery: running pattern=0
INFO tb_poly_basemul_montgomery: running pattern=1
INFO tb_poly_basemul_montgomery: running pattern=2
INFO tb_poly_basemul_montgomery: pass_count=768 fail_count=0
PASS tb_poly_basemul_montgomery
```

The DUT now compiles and matches the behavioral Kyber poly-basemul reference for
three deterministic full-polynomial patterns.
