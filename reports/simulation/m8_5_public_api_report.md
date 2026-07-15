# M8.5 Public API Development Report

Public KeyGen passes one 64-byte mock-RBG transaction and pre-data RBG failure.
Public Encaps accepts a valid EK, rejects raw12=q before RNG, requests exactly
32 bytes, and matches 1,120 output bytes.  Public Decaps passes valid and
modified ciphertexts, returns exact fallback K without error, and rejects a
stored-hash mutation with no output.  Full protocol/reset/RBG matrices remain.
