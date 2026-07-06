# basemul_unit Simulation Report

## Module name

`basemul_unit`

## Purpose

Verify the Kyber base multiplication operation for one two-coefficient pair.

## Files tested

- `rtl/ntt/basemul_unit.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/unit/tb_basemul_unit.v`
- `sim/scripts/run_basemul_unit.sh`

## Reference equation

```text
t0 = fqmul(a1, b1)
t1 = fqmul(t0, zeta)
t2 = fqmul(a0, b0)
r0 = t1 + t2 mod q

t3 = fqmul(a0, b1)
t4 = fqmul(a1, b0)
r1 = t3 + t4 mod q
```

This matches `kyber768/ntt.c: basemul()`.

## Simulation command

```sh
./sim/scripts/run_basemul_unit.sh
```

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_basemul_unit.sh
```

Latest result:

```text
INFO tb_basemul_unit: pass_count=507 fail_count=0
PASS tb_basemul_unit
```

Coverage includes seven directed cases and 500 random canonical coefficient
tuples.
