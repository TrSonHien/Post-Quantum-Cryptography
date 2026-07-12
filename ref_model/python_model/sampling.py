"""FIPS 203 sampling algorithms for ML-KEM foundations."""

from __future__ import annotations

from .codec import bytes_to_bits
from .params import N, Q
from .symmetric import XOF


def sample_ntt(seed_with_indices: bytes) -> list[int]:
    if len(seed_with_indices) != 34:
        raise ValueError("SampleNTT input must be 34 bytes")
    xof = XOF()
    xof.absorb(seed_with_indices)
    out: list[int] = []
    while len(out) < N:
        c = xof.squeeze(3)
        d1 = c[0] + 256 * (c[1] % 16)
        d2 = (c[1] // 16) + 16 * c[2]
        if d1 < Q:
            out.append(d1)
        if d2 < Q and len(out) < N:
            out.append(d2)
    return out


def sample_poly_cbd(eta: int, data: bytes) -> list[int]:
    if eta not in (2, 3):
        raise ValueError("eta must be 2 or 3")
    if len(data) != 64 * eta:
        raise ValueError(f"SamplePolyCBD_{eta} requires {64 * eta} bytes")
    bits = bytes_to_bits(data)
    out: list[int] = []
    for i in range(N):
        x = sum(bits[2 * i * eta + j] for j in range(eta))
        y = sum(bits[2 * i * eta + eta + j] for j in range(eta))
        out.append((x - y) % Q)
    return out

