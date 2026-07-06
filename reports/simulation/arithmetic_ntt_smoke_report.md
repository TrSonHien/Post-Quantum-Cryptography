# Arithmetic And NTT Smoke Simulation Report

## Commands

```sh
./sim/scripts/run_mod_add.sh
./sim/scripts/run_mod_sub.sh
./sim/scripts/run_reduction.sh
./sim/scripts/run_mod_mul.sh
./sim/scripts/run_zetas_rom.sh
./sim/scripts/run_butterfly_unit.sh
./sim/scripts/run_basemul_unit.sh
./sim/scripts/run_ntt_addr_gen.sh
./sim/scripts/run_ntt_core.sh
./sim/scripts/run_intt_core.sh
./sim/scripts/run_ntt_intt_roundtrip.sh
```

## Current Result

```text
PASS tb_mod_add       pass_count=1009 fail_count=0
PASS tb_mod_sub       pass_count=1012 fail_count=0
PASS tb_reduction     pass_count=620  fail_count=0
PASS tb_mod_mul       pass_count=1010 fail_count=0
PASS tb_zetas_rom     pass_count=16   fail_count=0
PASS tb_butterfly_unit pass_count=206  fail_count=0
PASS tb_basemul_unit  pass_count=507  fail_count=0
PASS tb_ntt_addr_gen   pass_count=1792 fail_count=0
PASS tb_ntt_core       pass_count=512  fail_count=0
PASS tb_intt_core      pass_count=768  fail_count=0
PASS tb_ntt_intt_roundtrip pass_count=1024 fail_count=0
```

## Notes

- `tb_zetas_rom` checks selected forward and inverse table entries against `kyber768/ntt.c`.
- `tb_butterfly_unit` verifies the forward butterfly arithmetic path.
- `tb_basemul_unit` verifies the Kyber `basemul()` equation with directed and random coefficient tuples.
- `tb_ntt_addr_gen` checks every forward and inverse schedule cycle.
- `tb_ntt_core` loads two full 256-coefficient polynomial patterns and compares readback against a behavioral forward NTT model.
- `tb_intt_core` loads three full 256-coefficient polynomial patterns and compares readback against a behavioral inverse NTT model with final scaling.
- `tb_ntt_intt_roundtrip` verifies `poly -> NTT -> INTT -> Montgomery-domain poly`, where each final coefficient equals `input * 2285 mod 3329`.

Last refreshed during repository orientation on 2026-07-06.
