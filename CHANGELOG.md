# Changelog

## 2026-07-04

- Reorganized repository for a long-term ML-KEM-768 RTL-to-GDSII project.
- Moved standards PDFs into `references/standards/`.
- Moved Kyber reference package into `ref_model/c_ref/`.
- Moved math material into `docs/02_math/`.
- Moved architecture papers into `docs/03_architecture/`.
- Moved RTL top scaffold into `rtl/top/mlkem768_top.v`.
- Moved system testbench scaffold into `tb/system/tb_mlkem768_top.v`.
- Moved simulation Makefile and filelists into `sim/scripts/`.
- Archived original `thoughts.txt` as `archive/thoughts.txt`.
- Added project documentation scaffold and folder-level README files.

## 2026-07-04 PD Placeholder Adjustment

- Replaced the active `pnr/` scaffold with an empty `pd/` placeholder for future server-controlled physical design structure.
- Updated README and project spec references to avoid prescribing a local PD folder structure.
