# M6.3 CBD Report

The pair primitive exhaustively passes all 256 eta2 groups and all 4096 eta3
groups (8,704 coefficient comparisons), at registered latency one and II one.
Complete-polynomial testing passes 128 vectors per eta and 32,768 coefficients
per eta. Zero, all-ones, deterministic random streams, LSB-first reservoir
crossings, exact input lengths, canonical unsigned negative encoding, NORMAL
domain, and exact 256-output completion pass. No signed coefficient escapes.

No-stall complete-polynomial simulations use approximately 291 cycles for
eta2 and 307 cycles for eta3 under the testbench edge convention; closure cycle
accounting remeasures these values centrally.
