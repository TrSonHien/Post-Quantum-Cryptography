# M6.2 Polyvec Codec Report

One child serializes elements 0,1,2. D12 and compressed d10 each pass 32 K=3
vectors: 36,864/30,720 encoded bytes and 24,576 decoded coefficients per mode.
Element and coefficient indices, semantic domains, polynomial boundaries, and
one final vector marker compare exactly; no boundary bit leakage is observed.
