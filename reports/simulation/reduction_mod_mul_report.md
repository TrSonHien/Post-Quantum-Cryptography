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
INFO tb_reduction: pass_count=618 fail_count=0
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

- `reduction.v` was retested with directed and random checks for the rewritten
  unsigned/canonical contract of `montgomery_reduce`, `barrett_reduce`, and
  `conditional_sub_q`.
- `tb_reduction.v` was updated to match the new unsigned reducer contract.
- `mod_mul.v` now uses an unsigned 24-bit coefficient product, explicitly
  zero-extends it to the reducer input, and consumes the reducer's canonical
  unsigned result directly.
- `mod_mul.v` and `tb_mod_mul.v` contain no signed declarations, `$signed`
  casts, or arithmetic right shifts.
- Direct dependent regressions also pass: `basemul_unit`,
  `poly_basemul_montgomery`, `ntt_core`, `intt_core`, and the NTT/INTT
  roundtrip.
- The current `reduction.v` still contains two internal `wire signed`
  declarations (`a_qdash_full` and `m`). They were not changed as part of this
  focused `mod_mul.v` task.
