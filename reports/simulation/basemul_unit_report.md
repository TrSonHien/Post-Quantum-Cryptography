# basemul_unit Simulation Report

## Module name

`basemul_unit`

## Purpose

Verify the main high-throughput pipelined Kyber base multiplication operation
for one two-coefficient pair.

`basemul_unit` is now the main high-throughput pipelined implementation. The
older sequential/resource-shared implementation was replaced in place rather
than kept as a separate RTL variant.

## Files tested

- `rtl/ntt/basemul_unit.v`
- `rtl/arithmetic/mod_add.v`
- `rtl/arithmetic/mod_mul.v`
- `rtl/arithmetic/reduction.v`

## Testbench files

- `tb/unit/tb_basemul_unit.v`
- `sim/scripts/run_basemul_unit.sh`

## Architecture

- Interface: valid-only pipeline, `in_valid -> out_valid`
- Latency: 3 cycles from `in_valid` input to `out_valid` output
- Throughput: 1 result per cycle after pipeline fill
- Resources: 5 `mod_mul` + 2 `mod_add`
- Backpressure: none

The downstream block must accept `r0/r1` whenever `out_valid` is high.

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

## Test strategy

- Reset behavior check
- Single valid transaction
- Back-to-back valid transactions
- Valid bubble pattern: `1, 1, 0, 1, 0, 0, 1, 1`
- 14 deterministic directed transactions total
- 500 random canonical coefficient tuples
- `out_valid` checked as the 3-stage delayed version of `in_valid`
- `r0/r1` checked only when `out_valid` is high

## Current result

PASS.

Command run:

```sh
./sim/scripts/run_basemul_unit.sh
```

Latest result:

```text
INFO tb_basemul_unit: tx_count=514 valid_check_count=533
INFO tb_basemul_unit: pass_count=514 fail_count=0
PASS tb_basemul_unit
```
