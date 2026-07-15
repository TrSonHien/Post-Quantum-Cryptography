# M8.1 Decaps Input-Check Development Report

`run_mlkem_decaps_input_check.sh` passes five Python-derived cases.  Valid DK/c,
embedded-EK mutation, stored-hash mutation, z mutation, and dkPKE mutation give
the required classifications.  Every case compares 32 hash bytes; 3,520
M8-owned bytes are scrubbed.  The reused Keccak hierarchy lacks physical scrub.
