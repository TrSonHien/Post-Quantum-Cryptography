# M8 Completion Report -- Academic Functional Baseline

M8 implements FIPS 203 Algorithms 16--21 as deterministic internal
KeyGen/Encaps/Decaps controllers plus public external-RBG wrappers and the
unified ML-KEM-768 top. The implemented interfaces enforce the ML-KEM-768
lengths: EK 1184 bytes, DK 2400 bytes, ciphertext 1088 bytes, and shared secret
32 bytes. Decapsulation compares all 1088 ciphertext bytes and selects either
`K_prime` or the exact `J(z || c)` fallback without exposing a reject result.

The academic functional suite uses an independent Python model and reduced,
deterministic vector depths: 2 KeyGen_internal, 2 Encaps_internal, 4 valid
Decaps_internal, 4 modified-ciphertext fallback cases, and 2 public end-to-end
chains. Basic EK, DK/ciphertext, and RBG-failure checks are included. The
optional full-project regression was deliberately not run.

Latest evidence: smoke passed 9/9 in 61 seconds and the nonrecursive M8
functional regression passed 7/7 subtests in 556 seconds.

The current academic RTL baseline provides control-state invalidation and
selected explicit secret-state clearing. Exhaustive physical destruction of all
retained lower-level datapath state is deferred to a future security hardening
milestone. Production-grade physical zeroization, comprehensive side-channel
hardening, exhaustive regression, authoritative CAVP/ACVP validation, and
synthesis closure remain future work. M2.3b synthesis is pending.

There is no synthesis, area, timing-closure, Fmax, final authoritative KAT, or
CAVP/ACVP claim in this report.
