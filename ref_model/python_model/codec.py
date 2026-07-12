"""FIPS 203 conversion and compression algorithms."""

from __future__ import annotations

from .params import N, Q


def bits_to_bytes(bits: list[int]) -> bytes:
    if len(bits) % 8:
        raise ValueError("bit length must be a multiple of eight")
    out = bytearray(len(bits) // 8)
    for i, bit in enumerate(bits):
        if bit not in (0, 1):
            raise ValueError("bits must be 0 or 1")
        out[i // 8] += bit << (i % 8)
    return bytes(out)


def bytes_to_bits(data: bytes) -> list[int]:
    return [(byte >> j) & 1 for byte in data for j in range(8)]


def _round_div(numer: int, denom: int) -> int:
    """Integer nearest rounding for non-negative rational numer/denom.

    FIPS 203 forbids floating-point compression/decompression. For ML-KEM's
    positive domains this is equivalent to floor((numer + denom/2) / denom).
    """

    return (2 * numer + denom) // (2 * denom)


def compress(d: int, x: int) -> int:
    if not 1 <= d < 12:
        raise ValueError("Compress_d requires 1 <= d < 12")
    return _round_div((1 << d) * (x % Q), Q) % (1 << d)


def decompress(d: int, y: int) -> int:
    if not 1 <= d < 12:
        raise ValueError("Decompress_d requires 1 <= d < 12")
    return _round_div(Q * (y % (1 << d)), 1 << d) % Q


def byte_encode(d: int, coeffs: list[int]) -> bytes:
    if not 1 <= d <= 12:
        raise ValueError("ByteEncode_d requires 1 <= d <= 12")
    if len(coeffs) != N:
        raise ValueError("ByteEncode_d requires 256 coefficients")
    modulus = Q if d == 12 else 1 << d
    bits: list[int] = []
    for coeff in coeffs:
        if coeff < 0 or coeff >= modulus:
            raise ValueError(f"coefficient {coeff} outside Z_{modulus}")
        a = coeff
        for _ in range(d):
            bits.append(a % 2)
            a = (a - bits[-1]) // 2
    return bits_to_bytes(bits)


def byte_decode(d: int, data: bytes) -> list[int]:
    if not 1 <= d <= 12:
        raise ValueError("ByteDecode_d requires 1 <= d <= 12")
    if len(data) != 32 * d:
        raise ValueError(f"ByteDecode_{d} requires {32 * d} bytes")
    modulus = Q if d == 12 else 1 << d
    bits = bytes_to_bits(data)
    out: list[int] = []
    for i in range(N):
        value = 0
        for j in range(d):
            value += bits[i * d + j] << j
        out.append(value % modulus)
    return out

