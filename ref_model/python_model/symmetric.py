"""FIPS 203 hash/XOF wrappers backed by Python hashlib."""

from __future__ import annotations

import hashlib


def sha3_256(data: bytes) -> bytes:
    return hashlib.sha3_256(data).digest()


def sha3_512(data: bytes) -> bytes:
    return hashlib.sha3_512(data).digest()


def shake128(data: bytes, out_len: int) -> bytes:
    if out_len < 0:
        raise ValueError("out_len must be non-negative")
    return hashlib.shake_128(data).digest(out_len)


def shake256(data: bytes, out_len: int) -> bytes:
    if out_len < 0:
        raise ValueError("out_len must be non-negative")
    return hashlib.shake_256(data).digest(out_len)


def H(data: bytes) -> bytes:
    """FIPS 203 H: SHA3-256(data), 32 bytes."""

    return sha3_256(data)


def G(data: bytes) -> tuple[bytes, bytes]:
    """FIPS 203 G: SHA3-512(data), split into two 32-byte strings."""

    out = sha3_512(data)
    return out[:32], out[32:]


def J(data: bytes) -> bytes:
    """FIPS 203 J: SHAKE256(data, 32 bytes)."""

    return shake256(data, 32)


def prf(eta: int, seed: bytes, nonce: int) -> bytes:
    """FIPS 203 PRF_eta(seed, nonce). eta sets output length only."""

    if eta not in (2, 3):
        raise ValueError("eta must be 2 or 3")
    if len(seed) != 32:
        raise ValueError("seed must be 32 bytes")
    if nonce < 0 or nonce > 255:
        raise ValueError("nonce must fit in one byte")
    return shake256(seed + bytes([nonce]), 64 * eta)


class XOF:
    """Byte-oriented SHAKE128 wrapper for FIPS 203 SampleNTT.

    Python hashlib's SHAKE object does not expose an advancing squeeze API.
    This wrapper preserves FIPS byte-squeeze semantics by caching a growing
    SHAKE128 output prefix and consuming it with an explicit offset.
    """

    def __init__(self) -> None:
        self._absorbed = bytearray()
        self._offset = 0
        self._cache = b""

    def absorb(self, data: bytes) -> None:
        if self._offset != 0:
            raise ValueError("cannot absorb after squeezing")
        self._absorbed.extend(data)

    def squeeze(self, nbytes: int) -> bytes:
        if nbytes < 0:
            raise ValueError("nbytes must be non-negative")
        needed = self._offset + nbytes
        if needed > len(self._cache):
            size = max(needed, 2 * max(1, len(self._cache)))
            self._cache = shake128(bytes(self._absorbed), size)
        out = self._cache[self._offset : self._offset + nbytes]
        self._offset += nbytes
        return out

