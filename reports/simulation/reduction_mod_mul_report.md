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
rtl/arithmetic/mod_mul.v:9: error: Superfluous comma in port declaration list.
```

Status: BLOCKED by RTL compile error.

## Notes

- `reduction.v` was tested with directed and random checks for `montgomery_reduce`, `barrett_reduce`, and `conditional_sub_q`.
- `mod_mul.v` could not be simulated because compilation stops before elaboration.
- The likely fix is to remove the trailing comma after output port `c` in `mod_mul.v`.
