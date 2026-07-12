"""Deterministic M0.4a self-tests for ML-KEM-768 foundations."""

from __future__ import annotations

import hashlib
import random

from .codec import byte_decode, byte_encode, compress, decompress
from .kpke import decrypt as kpke_decrypt
from .kpke import encrypt as kpke_encrypt
from .kpke import keygen as kpke_keygen
from .mlkem import (
    check_ciphertext,
    check_decapsulation_key,
    check_encapsulation_key,
    decaps_internal,
    encaps_internal,
    keygen_internal,
)
from .ntt import intt, multiply_ntts, naive_mul_mod_xn_plus_1, ntt
from .params import N, Q
from .sampling import sample_ntt, sample_poly_cbd
from .symmetric import G, H, J, prf, sha3_256, sha3_512, shake128, shake256


def _det_poly(seed: int) -> list[int]:
    rng = random.Random(seed)
    return [rng.randrange(Q) for _ in range(N)]


def run_selftests() -> None:
    assert sha3_256(b"abc") == hashlib.sha3_256(b"abc").digest()
    assert sha3_512(b"abc") == hashlib.sha3_512(b"abc").digest()
    assert shake128(b"abc", 64) == hashlib.shake_128(b"abc").digest(64)
    assert shake256(b"abc", 64) == hashlib.shake_256(b"abc").digest(64)
    assert H(b"abc") == hashlib.sha3_256(b"abc").digest()
    g0, g1 = G(b"abc")
    assert g0 + g1 == hashlib.sha3_512(b"abc").digest()
    assert J(b"abc") == hashlib.shake_256(b"abc").digest(32)
    assert prf(2, bytes(range(32)), 7) == hashlib.shake_256(bytes(range(32)) + b"\x07").digest(128)

    for d in (1, 4, 10):
        for y in range(1 << d):
            assert compress(d, decompress(d, y)) == y

    for d in (1, 4, 10, 12):
        modulus = Q if d == 12 else 1 << d
        coeffs = [(i * 37 + d) % modulus for i in range(N)]
        assert byte_decode(d, byte_encode(d, coeffs)) == coeffs

    for seed in range(5):
        poly = _det_poly(seed)
        assert intt(ntt(poly)) == poly

    for seed in range(3):
        f = _det_poly(100 + seed)
        g = _det_poly(200 + seed)
        product = intt(multiply_ntts(ntt(f), ntt(g)))
        assert product == naive_mul_mod_xn_plus_1(f, g)

    sntt = sample_ntt(bytes(range(32)) + b"\x01\x02")
    assert len(sntt) == N
    assert all(0 <= x < Q for x in sntt)

    cbd = sample_poly_cbd(2, bytes(range(128)))
    assert len(cbd) == N
    assert all((0 <= x <= 2) or (Q - 2 <= x < Q) for x in cbd)

    d = bytes(range(32))
    z = bytes(range(32, 64))
    m = bytes(range(64, 96))
    r = bytes(range(96, 128))

    ek_pke, dk_pke = kpke_keygen(d)
    c_pke = kpke_encrypt(ek_pke, m, r)
    assert kpke_decrypt(dk_pke, c_pke) == m

    ek, dk = keygen_internal(d, z)
    assert check_encapsulation_key(ek)
    assert check_decapsulation_key(dk)
    shared_secret, ciphertext = encaps_internal(ek, m)
    assert check_ciphertext(ciphertext)
    assert decaps_internal(dk, ciphertext) == shared_secret

    modified = bytearray(ciphertext)
    modified[0] ^= 1
    modified_ct = bytes(modified)
    assert decaps_internal(dk, modified_ct) == J(z + modified_ct)


if __name__ == "__main__":
    run_selftests()
    print("M0.4 Python golden model selftests: PASS")
