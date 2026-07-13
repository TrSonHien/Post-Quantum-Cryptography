# M5.2 One-Shot Hash Stream Report

`run_keccak_hash_stream.sh` passes 320 commands and 21,174 output-byte
comparisons. It covers exact length/keep/last handling, empty automatic
finalization, all four modes, multi-block input/output, deterministic input
gaps and output backpressure. Invalid fixed output length, zero SHAKE output,
early/missing last, invalid keep, command while busy, extra input, and reset
cancellation are rejected without stale output.
