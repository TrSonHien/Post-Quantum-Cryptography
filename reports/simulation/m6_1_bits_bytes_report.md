# M6.1 Bits/Bytes Report

`run_bits_bytes_pipe.sh` passes all 256 byte values through Algorithm 3 then
Algorithm 4 with deterministic output stalls. Each register slice has latency
one and II one. All 256 roundtrip bytes compare exactly; synchronous reset
cancels pending validity and restart is clean.
