# Modular Addition Simulation Report

## Unit

- RTL: `rtl/arithmetic/mod_add.v`
- Testbench: `tb/unit/tb_mod_add.v`
- Run script: `sim/scripts/run_mod_add.sh`

## Function

Computes:

```text
c = (a + b) mod KYBER_Q
```

Assumptions:

- `0 <= a < KYBER_Q`
- `0 <= b < KYBER_Q`
- `KYBER_Q = 3329`

## Implementation Note

The RTL forms a 13-bit internal sum, then subtracts `KYBER_Q` once when the sum is greater than or equal to `KYBER_Q`. One conditional subtract is sufficient because the maximum input sum is `3328 + 3328 = 6656`, which is less than `2 * 3329 = 6658`.

## Test Coverage

- Directed corner cases:
  - `0 + 0`
  - `0 + (KYBER_Q - 1)`
  - `(KYBER_Q - 1) + 0`
  - `(KYBER_Q - 1) + 1`
  - `1 + (KYBER_Q - 1)`
  - `(KYBER_Q - 1) + (KYBER_Q - 1)`
  - representative no-wrap and wrap cases
- 1000 random in-range operand pairs

## Command

```sh
./sim/scripts/run_mod_add.sh
```

Questa compile check from `sim/scripts/`:

```sh
make build
make run
```

## Result

```text
INFO tb_mod_add: KYBER_Q=3329
INFO tb_mod_add: running directed tests
INFO tb_mod_add: running random tests
INFO tb_mod_add: pass_count=1009 fail_count=0
PASS tb_mod_add
```

Status: PASS

Questa `make build` result after adding `+incdir+../../rtl/common` to `sim/scripts/compile.f`:

```text
-- Compiling module mod_add
-- Compiling module tb_mod_add
Errors: 0, Warnings: 0
```

The default Makefile run target now uses:

```text
TESTNAME ?= mod_add
TB_NAME  ?= tb_mod_add
```
