# M8.3 Encaps_internal Development Report

One deterministic Python vector passes 32 K and 1,088 ciphertext bytes.  Exact
`H(ek)`, `G(m||H(ek))`, K/r split, and K-PKE ciphertext are inherited from the
generated oracle.  The stalled run is 58,377 cycles.  Required 16+ vectors,
intermediate observability coverage, and reused-child scrub remain open.
