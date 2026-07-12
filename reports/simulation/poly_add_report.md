# poly_add Simulation Report

## Module name

`poly_add`

## Purpose

Verify coefficient-wise Kyber polynomial addition:

```text
r[i] = (a[i] + b[i]) mod KYBER_Q
```

for all 256 coefficients.

## Files tested

- `rtl/poly/poly_add.v`

## Testbench files

- `tb/unit/tb_poly_add.v`
- `sim/scripts/run_poly_add.sh`

## Test strategy

- Load full 256-coefficient A and B polynomials through the DUT load ports.
- Pulse `start`.
- Wait for `done`.
- Read all 256 result coefficients.
- Compare each coefficient against a behavioral modular-add reference.
- Use four deterministic patterns:
  - all-zero operands
  - complementary operands summing to `KYBER_Q - 1`
  - maximum canonical operands, `KYBER_Q - 1`
  - nontrivial arithmetic sequences

## Simulation command

```sh
./sim/scripts/run_poly_add.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_poly_add.sh
```

Latest result:

```text
INFO tb_poly_add: pass_count=1024 fail_count=0
PASS tb_poly_add
```

## RTL warning to fix

Resolved by user before retest. The latest run reports no `poly_add` RTL
compile warning.
