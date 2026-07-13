# M5.1 Keccak Round Report

Command `timeout 120s ./sim/scripts/run_keccak_round.sh` passes 2,072 complete
1600-bit round comparisons, covering all 24 round indices, 1,600 walking-one
states, structured/all-zero/all-one states, and 400 deterministic random
states. A 24-vector debug subset additionally compares theta C/D, theta lanes,
rho/pi lanes, chi lanes, iota, offsets, coordinates, and constant anchors.

The vector tool is a pure-Python FIPS-equation implementation. Before emitting
vectors it cross-checks its complete sponge against `hashlib` SHA3-256,
SHA3-512, SHAKE128, and SHAKE256. Two-directory generation is byte-identical.
The public RTL is purely combinational and has no latency or handshake.
