# M8 Academic Functional Regression Report

The regression has three tiers: bounded M8 smoke, bounded nonrecursive M8
functional verification, and an optional manual full-project runner. The
functional tier uses the academic defaults of 2 KeyGen_internal vectors, 2
Encaps_internal vectors, 4 valid Decaps_internal vectors, 4 exact fallback
vectors, and 2 public chains. Each Decaps test checks the 1088-byte comparison
and 32-byte select counts. Public checks include EK validity/noncanonical data
and length, DK stored-hash and length, ciphertext length, and RBG failure.

The full-project runner is intentionally not part of this M8 claim. Its use is
reserved for a later manual overnight/M9 session.

Latest verified results: `run_m8_smoke.sh` passed 9/9 checks in 61 seconds.
`run_m8_regression.sh` passed 7/7 bounded subtests in 556 seconds.
