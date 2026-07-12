# RTL

Use this folder for synthesizable Verilog RTL.

Folder map:

- `top/` for ML-KEM top-level wrappers.
- `arithmetic/` for modular arithmetic blocks.
- `ntt/` for NTT, INTT, butterfly, and polynomial multiplication blocks.
- `keccak/` for SHAKE/Keccak hardware.
- `sampler/` for CBD and rejection sampling blocks.
- `codec/` for encode, decode, compress, decompress, pack, and unpack blocks.
- `memory/` for RAM wrappers, buffers, and memory scheduling.
- `control/` for KeyGen, Encaps, Decaps, and top-level controllers.

Current RTL is scaffold only and is not a verified ML-KEM implementation.

M2.1 contract primitives:

- `memory/sync_1r1w_ram.v`: synchronous 1R/1W RAM, one-cycle read;
- `memory/ntt_bank_map.v`: M1 conflict-free logical bank/address map;
- `memory/ntt_pingpong_banks.v`: four-bank out-of-place ping-pong wrapper;
- `control/fixed_latency_delay.v`: fixed-latency valid/metadata alignment;
- `control/rv_register_slice.v`: one-entry valid/ready register slice.

These modules do not implement NTT arithmetic or a controller and carry no
synthesis/Fmax claim.
