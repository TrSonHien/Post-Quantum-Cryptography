"""FIPS 203 deterministic internal ML-KEM-768 algorithms."""

from __future__ import annotations

import hmac

from .codec import byte_decode, byte_encode
from .kpke import decrypt as kpke_decrypt
from .kpke import encrypt as kpke_encrypt
from .kpke import keygen as kpke_keygen
from .params import (
    CIPHERTEXT_BYTES,
    DECAPSULATION_KEY_BYTES,
    ENCAPSULATION_KEY_BYTES,
    K,
    PKE_PUBLICKEY_BYTES,
    PKE_SECRETKEY_BYTES,
    POLY_BYTES,
    SEED_BYTES,
)
from .symmetric import G, H, J


def check_encapsulation_key(ek: bytes) -> bool:
    """FIPS 203 Section 7.2 encapsulation-key type and modulus checks."""

    if len(ek) != ENCAPSULATION_KEY_BYTES:
        return False
    body = ek[: POLY_BYTES * K]
    test = b"".join(
        byte_encode(12, byte_decode(12, body[i * POLY_BYTES : (i + 1) * POLY_BYTES]))
        for i in range(K)
    )
    return test == body


def check_decapsulation_key(dk: bytes) -> bool:
    """FIPS 203 Section 7.3 decapsulation-key type and hash checks."""

    if len(dk) != DECAPSULATION_KEY_BYTES:
        return False
    ek = dk[PKE_SECRETKEY_BYTES : PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES]
    h = dk[PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES : PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES + 32]
    return hmac.compare_digest(H(ek), h)


def check_ciphertext(ciphertext: bytes) -> bool:
    """FIPS 203 Section 7.3 ciphertext type check for ML-KEM-768."""

    return len(ciphertext) == CIPHERTEXT_BYTES


def keygen_internal(seed_d: bytes, seed_z: bytes) -> tuple[bytes, bytes]:
    """FIPS 203 Algorithm 16 ML-KEM.KeyGen_internal(d, z)."""

    if len(seed_d) != SEED_BYTES:
        raise ValueError("d must be 32 bytes")
    if len(seed_z) != SEED_BYTES:
        raise ValueError("z must be 32 bytes")
    ek_pke, dk_pke = kpke_keygen(seed_d)
    ek = ek_pke
    dk = dk_pke + ek + H(ek) + seed_z
    return ek, dk


def encaps_internal(ek: bytes, message: bytes, *, require_checked_ek: bool = True) -> tuple[bytes, bytes]:
    """FIPS 203 Algorithm 17 ML-KEM.Encaps_internal(ek, m)."""

    if len(message) != SEED_BYTES:
        raise ValueError("m must be 32 bytes")
    if require_checked_ek and not check_encapsulation_key(ek):
        raise ValueError("encapsulation key failed FIPS input checks")
    if not require_checked_ek and len(ek) != ENCAPSULATION_KEY_BYTES:
        raise ValueError("ek has invalid length")
    shared_secret, randomness = G(message + H(ek))
    ciphertext = kpke_encrypt(ek, message, randomness)
    return shared_secret, ciphertext


def decaps_internal(
    dk: bytes,
    ciphertext: bytes,
    *,
    require_checked_inputs: bool = True,
) -> bytes:
    """FIPS 203 Algorithm 18 ML-KEM.Decaps_internal(dk, c)."""

    if require_checked_inputs:
        if not check_decapsulation_key(dk):
            raise ValueError("decapsulation key failed FIPS input checks")
        if not check_ciphertext(ciphertext):
            raise ValueError("ciphertext failed FIPS input checks")
    elif len(dk) != DECAPSULATION_KEY_BYTES or len(ciphertext) != CIPHERTEXT_BYTES:
        raise ValueError("invalid dk or ciphertext length")

    dk_pke = dk[:PKE_SECRETKEY_BYTES]
    ek_pke = dk[PKE_SECRETKEY_BYTES : PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES]
    h = dk[PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES : PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES + 32]
    z = dk[PKE_SECRETKEY_BYTES + PKE_PUBLICKEY_BYTES + 32 :]

    message_prime = kpke_decrypt(dk_pke, ciphertext)
    shared_secret_prime, randomness_prime = G(message_prime + h)
    fallback = J(z + ciphertext)
    ciphertext_prime = kpke_encrypt(ek_pke, message_prime, randomness_prime)

    if hmac.compare_digest(ciphertext, ciphertext_prime):
        return shared_secret_prime
    return fallback
