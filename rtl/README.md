# RTL

Use this folder for synthesizable Verilog RTL.

Folder map:

- `mlkem/` for ML-KEM internal/public controllers and the unified top-level.
- `arithmetic/` for modular arithmetic blocks.
- `ntt/` for NTT, INTT, butterfly, and polynomial multiplication blocks.
- `keccak/` for SHAKE/Keccak hardware.
- `sampler/` for CBD and rejection sampling blocks.
- `codec/` for encode, decode, compress, decompress, pack, and unpack blocks.
- `memory/` for RAM wrappers, buffers, and memory scheduling.
- `control/` for KeyGen, Encaps, Decaps, and top-level controllers.

The current `test` release tree contains the academic functional ML-KEM-768
implementation rooted at `rtl/mlkem/mlkem768_top.v`.  The release hierarchy
and current module classification are documented in `docs/05_code_guide/`.

M2.1 contract primitives:

- `memory/sync_1r1w_ram.v`: synchronous 1R/1W RAM, one-cycle read;
- `memory/ntt_bank_map.v`: M1 conflict-free logical bank/address map;
- `memory/ntt_pingpong_banks.v`: four-bank out-of-place ping-pong wrapper;
- `control/fixed_latency_delay.v`: fixed-latency valid/metadata alignment;

These modules do not implement NTT arithmetic or a controller and carry no
synthesis/Fmax claim.

M4 polynomial/polyvec RTL:

- `poly/poly_workspace.v`: synchronous even/odd-bank workspace with ownership,
  completeness, and semantic domain metadata;
- `poly/poly_add_pipe.v`, `poly/poly_sub_pipe.v`:
  canonical two-lane polynomial controllers;
- `poly/poly_ntt_pipe.v`, `poly/poly_intt_pipe.v`: logical-interface adapters
  around the frozen M3 cores.
- `arithmetic/mod_mul_normal_pipe.v`, `poly/basecase_mul_pipe.v`, and
  `poly/poly_basemul_pipe.v`: exact FIPS MultiplyNTTs path;
- `poly/polyvec_workspace.v` and `poly/polyvec_*_pipe.v`: serialized K=3
  arithmetic, transforms, and exact MultiplyNTTs accumulation.

M5 Keccak/SHA3/SHAKE, M6 codec/sampler, and deterministic M7 K-PKE standalone
controllers are implemented and differentially verified. M8 internal/public
controllers and the typed top form an academic functional baseline with
reduced Python differential regressions. Selected M8-local secret state is
explicitly cleared; exhaustive lower-datapath physical destruction and
side-channel hardening are deferred.

Superseded RTL implementations are intentionally absent from this current
release tree and remain available in Git history before
`pre-legacy-prune-b683bd7`.
