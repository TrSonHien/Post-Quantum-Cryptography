# Arithmetic And NTT Smoke Simulation Report

## Commands

```sh
./sim/scripts/run_mod_add.sh
./sim/scripts/run_mod_sub.sh
./sim/scripts/run_reduction.sh
./sim/scripts/run_mod_mul.sh
./sim/scripts/run_zetas_rom.sh
./sim/scripts/run_butterfly_unit.sh
```

## Current Result

```text
PASS tb_mod_add       pass_count=1009 fail_count=0
PASS tb_mod_sub       pass_count=1012 fail_count=0
PASS tb_reduction     pass_count=620  fail_count=0
PASS tb_mod_mul       pass_count=1010 fail_count=0
PASS tb_zetas_rom     pass_count=16   fail_count=0
FAIL tb_butterfly_unit compile/elaboration blocked
```

## Failure Detail

`rtl/ntt/butterfly_unit.v` does not elaborate:

```text
rtl/ntt/butterfly_unit.v:40: error: Unable to bind parameter `KYBER_Q_WIDTH'
rtl/ntt/butterfly_unit.v:40: error: Dimensions must be constant.
rtl/ntt/butterfly_unit.v:40: This MSB expression violates the rule: KYBER_Q_WIDTH
```

The failing line is:

```verilog
wire [KYBER_Q_WIDTH:0] t;
```

The macro name is missing the Verilog backtick. After that is fixed, review the width warnings around `mod_add` and `mod_sub`: those modules currently use `[`KYBER_Q_WIDTH-1:0]`, while `butterfly_unit` wires use `[`KYBER_Q_WIDTH:0]`.

## Notes

- `tb_zetas_rom` checks selected forward and inverse table entries against `kyber768/ntt.c`.
- `tb_butterfly_unit` was added, but it could not run because `butterfly_unit.v` did not elaborate.
