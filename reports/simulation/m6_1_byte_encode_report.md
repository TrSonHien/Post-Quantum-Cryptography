# M6.1 ByteEncode Report

`run_byte_encode_poly_pipe.sh` passes 68 independently generated arrays for
each d=1,4,10,12. Exact comparisons cover 2,176, 8,704, 21,760, and 26,112
bytes respectively (58,752 total). The 64-bit bounded LSB-first reservoir
accepts 256 indexed values and emits exactly 8d full 32-bit words. Directed
zero, maximum, index, and alternating vectors precede deterministic random
arrays. Output stability and ordering pass deterministic stalls.
