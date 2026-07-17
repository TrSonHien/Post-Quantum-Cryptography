# M9 Academic RTL Release Completion Report

## Final status: PARTIAL (external synthesis environment blocked)

The release gate completed 7/7 checks in 948 seconds: full hierarchy
elaboration, M8 smoke (9/9 in 62 seconds), M8 functional regression (7/7 in
555 seconds), focused M7 K-PKE roundtrip, and deterministic vector
reproducibility all pass.  The dedicated synthesis file list and runner shell
checks pass.  Local generic and technology-mapped synthesis are
environment-blocked by missing Yosys, Genus, and a standard-cell Liberty
library.

## Claims and non-claims

The release claim is limited to: **the ML-KEM-768 academic RTL release is
functionally verified and elaboration-ready. Technology-mapped synthesis
remains environment-blocked.**  It makes no authoritative CAVP/ACVP,
production-security, exhaustive-zeroization, ASIC-area, achieved-Fmax,
post-layout timing, or power claim.
