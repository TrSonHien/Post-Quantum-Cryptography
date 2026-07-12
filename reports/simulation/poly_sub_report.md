# poly_sub Simulation Report

## Module name

`poly_sub`

## Purpose

Verify coefficient-wise Kyber polynomial subtraction:

```text
r[i] = (a[i] - b[i]) mod KYBER_Q
```

for all 256 coefficients.

## Files tested

- `rtl/poly/poly_sub.v`

## Testbench files

- `tb/unit/tb_poly_sub.v`
- `sim/scripts/run_poly_sub.sh`

## Test strategy

- Load full 256-coefficient A and B polynomials through the DUT load ports.
- Pulse `start`.
- Wait for `done`.
- Read all 256 result coefficients.
- Compare each coefficient against a behavioral modular-subtract reference.
- Use four deterministic patterns:
  - all-zero operands
  - equal operands
  - full wraparound case, `0 - (KYBER_Q - 1)`
  - nontrivial arithmetic sequences

## Simulation command

```sh
./sim/scripts/run_poly_sub.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_poly_sub.sh
```

Latest result (2026-07-13):

```text
INFO tb_poly_sub: running pattern=0
INFO tb_poly_sub: running pattern=1
INFO tb_poly_sub: running pattern=2
INFO tb_poly_sub: running pattern=3
INFO tb_poly_sub: pass_count=1024 fail_count=0
PASS tb_poly_sub
```

## Resolved report discrepancy

The previous FAIL text described stale undeclared `add_result*` wiring. Current
RTL connects the two `mod_sub` outputs to declared `sub_result0` and
`sub_result1`; the live rerun resolves the conflict with the aggregate smoke
report. No RTL or testbench change was made during M1.
