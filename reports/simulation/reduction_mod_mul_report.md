# Reduction And Modular Multiplication Simulation Report

## Units

- RTL under test:
  - `rtl/arithmetic/reduction.v`
  - `rtl/arithmetic/mod_mul.v`
- Testbenches:
  - `tb/unit/tb_reduction.v`
  - `tb/unit/tb_mod_mul.v`
- Run scripts:
  - `sim/scripts/run_reduction.sh`
  - `sim/scripts/run_mod_mul.sh`

## Commands

```sh
./sim/scripts/run_reduction.sh
./sim/scripts/run_mod_mul.sh
```

## Current Result

`reduction.v` result:

```text
INFO tb_reduction: KYBER_Q=3329
INFO tb_reduction: pass_count=620 fail_count=0
PASS tb_reduction
```

Status: PASS

`mod_mul.v` result:

```text
INFO tb_mod_mul: KYBER_Q=3329
INFO tb_mod_mul: pass_count=1010 fail_count=0
PASS tb_mod_mul
```

Status: PASS

## Notes

- `reduction.v` was tested with directed and random checks for `montgomery_reduce`, `barrett_reduce`, and `conditional_sub_q`.
- `mod_mul.v` wraps `montgomery_reduce(a * b)` and converts the signed Montgomery result back to the unsigned canonical coefficient range.
- Last refreshed during repository orientation on 2026-07-06.
