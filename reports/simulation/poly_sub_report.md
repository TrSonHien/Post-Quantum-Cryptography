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

FAIL.

Command run:

```sh
./sim/scripts/run_poly_sub.sh
```

Latest result:

```text
rtl/poly/poly_sub.v:153: warning: implicit definition of wire 'add_result0'.
rtl/poly/poly_sub.v:159: warning: implicit definition of wire 'add_result1'.
rtl/poly/poly_sub.v:150: warning: Port 3 (c) of module mod_sub expects 12 bit(s), given 1.
rtl/poly/poly_sub.v:156: warning: Port 3 (c) of module mod_sub expects 12 bit(s), given 1.
FIRST_FAIL tb_poly_sub: pattern=0 index=0 expected=0 actual=z
INFO tb_poly_sub: pass_count=0 fail_count=1024
FAIL tb_poly_sub
```

## RTL issue to fix

`rtl/poly/poly_sub.v` declares the intended subtract result wires:

```verilog
wire [DATA_WIDTH-1:0] sub_result0;
wire [DATA_WIDTH-1:0] sub_result1;
```

but the two `mod_sub` instances drive undeclared `add_result0` and
`add_result1` instead:

```verilog
.c(add_result0)
.c(add_result1)
```

Because `sub_result0` and `sub_result1` are never driven, the R buffer writes
high-Z data and all coefficient checks fail.
