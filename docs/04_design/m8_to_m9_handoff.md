# M8 to M9 Handoff -- Academic Functional Baseline

M8 contains deterministic internal functions, entropy-fed public wrappers,
mandatory public checks, fixed-work implicit rejection, and a typed unified
top. The academic functional regression uses reduced independent-Python vector
depths and bounded runners.

M8 is functionally complete for the academic baseline. The optional
full-project regression was not run and is reserved for a manual overnight/M9
session.

M9 must import authoritative vectors when available; record
CAVP/ACVP provenance and hashes; expand KAT/differential, randomized, mutation,
and fault tests; freeze the final interface; perform lint/synthesis-readiness
review; obtain M2.3b server evidence; review latency/area candidates; and tag a
verified release.  M9 may not equate legacy Kyber KATs with final FIPS vectors,
roundtrip with independent proof, reset with erasure, constant-work comparison
with complete side-channel resistance, or pre-layout timing with post-route.

## Limitations carried into M9

The current academic RTL baseline provides control-state invalidation and
selected explicit secret-state clearing. Exhaustive physical destruction of all
retained lower-level datapath state is deferred to a future security hardening
milestone. Production-grade physical zeroization, comprehensive side-channel
hardening, exhaustive regression, authoritative CAVP/ACVP validation, and
synthesis closure remain future work. M2.3b synthesis is pending.
