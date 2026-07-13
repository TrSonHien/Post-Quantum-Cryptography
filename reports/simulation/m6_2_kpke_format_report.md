# M6.2 K-PKE Format Report

Registered encoded-stream format adapters reuse the polynomial/polyvec codecs
at their boundaries and only enforce concatenation. Thirty-two independent
vectors pass for each format: ekPKE 37,888 bytes with rho at byte 1152; dkPKE
36,864 bytes; ciphertext 34,816 bytes with c2 at byte 960. Total length,
segment order, byte identity, and final marker are exact. K-PKE arithmetic and
operation scheduling are not implemented.
