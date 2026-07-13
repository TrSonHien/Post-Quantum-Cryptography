# M6.6 Unified Regression Report

Command `./sim/scripts/run_m6_regression.sh` passed 16/16 programs in 164
seconds with 2,467,232 declared internal checks, 276,992 byte comparisons,
376,576 coefficient comparisons, and 64 integrated SampleNTT vectors. The 15
new programs cover bits/bytes, compression, decompression, ByteEncode,
ByteDecode, polynomial/message/polyvec/format codecs, CBD pair, complete CBD,
noise sampler, SampleNTT parser, integrated SampleNTT, and two-directory vector
reproducibility.

The sixteenth program is the complete M5 regression: 21/21 and 1,802,376
checks. It recursively passed M4 33/33 and 996,965 checks, M3 22/22 and 361,656
checks, M2 adjacency, and Python/schema checks. The regression is fail-fast,
uses per-program timeouts and temporary directories, cleans on all exits, and
prints a machine-readable summary. Status: `M6_REGRESSION_STATUS=PASS`.
