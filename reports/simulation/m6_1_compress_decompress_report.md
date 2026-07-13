# M6.1 Compression/Decompression Report

`run_compress_coeff_pipe.sh` exhaustively passes all 3329 canonical inputs for
each d=1,4,10 (9,987 comparisons). `run_decompress_coeff_pipe.sh` exhaustively
passes 2+16+1024 raw inputs (1,042 comparisons). The generator additionally
asserts `Compress_d(Decompress_d(y))=y` for every raw input.

Both registered pipelines have measured latency two and II one. Compression
uses reciprocal 5039 at shift 24 plus one exact remainder correction;
decompression multiplies by 3329, adds the rounding constant, and shifts.
There is no floating point, signed coefficient arithmetic, or RTL division.
