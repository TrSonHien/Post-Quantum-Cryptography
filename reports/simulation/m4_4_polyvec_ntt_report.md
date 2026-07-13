# M4.4 Polyvec NTT/INTT Report

The baseline reuses one polynomial NTT or INTT adapter and serializes K=3
elements. No M3 physical bank is exposed or duplicated.

| Operation | Vectors | Comparisons | Cycles | Result |
|---|---:|---:|---:|---|
| Polyvec NTT | 16 | 12288 | 5980 | PASS |
| Polyvec INTT | 16 | 12288 | 6385 | PASS |
| Roundtrip forward | 16 | 12288 | 5980 | PASS |
| Roundtrip final | 16 | 12288 | 6385 | PASS |

Each element was independently compared with the Python NTT/INTT model.
NORMAL maps to NTT and NTT maps to canonical NORMAL. Reset/restart and domain
control checks pass. No synthesis/Fmax claim is made; M2.3b remains pending.
