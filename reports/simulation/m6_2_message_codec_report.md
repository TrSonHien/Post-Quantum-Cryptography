# M6.2 Message Codec Report

The message conversion regression passes 388 messages, including zero,
all-ones, sequential, all 256 walking bits, and deterministic random cases.
It compares 99,328 decoded coefficients and 12,416 roundtrip bytes. Bit zero
maps to coefficient zero and every output is canonical NORMAL domain.
