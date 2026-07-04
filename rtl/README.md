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
