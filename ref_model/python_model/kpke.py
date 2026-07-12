"""FIPS 203 K-PKE algorithms for ML-KEM-768.

The implementation uses canonical unsigned coefficients in [0, q-1] and the
FIPS NTT representation from the M0.4a foundation layer. It does not use
Montgomery-domain or lazy-range conventions from the legacy Kyber C code.
"""

from __future__ import annotations

from .codec import byte_decode, byte_encode, compress, decompress
from .ntt import intt, multiply_ntts, ntt
from .params import (
    C1_BYTES,
    C2_BYTES,
    DU,
    DV,
    ETA1,
    ETA2,
    K,
    N,
    PKE_PUBLICKEY_BYTES,
    PKE_SECRETKEY_BYTES,
    POLY_BYTES,
    Q,
    SEED_BYTES,
)
from .sampling import sample_ntt, sample_poly_cbd
from .symmetric import G, prf

Poly = list[int]
PolyVec = list[Poly]
Matrix = list[PolyVec]


def _add_poly(a: Poly, b: Poly) -> Poly:
    return [(x + y) % Q for x, y in zip(a, b)]


def _sub_poly(a: Poly, b: Poly) -> Poly:
    return [(x - y) % Q for x, y in zip(a, b)]


def _zero_poly() -> Poly:
    return [0] * N


def _encode_polyvec_12(vec: PolyVec) -> bytes:
    if len(vec) != K:
        raise ValueError(f"polyvec must contain {K} polynomials")
    return b"".join(byte_encode(12, poly) for poly in vec)


def _decode_polyvec_12(data: bytes) -> PolyVec:
    if len(data) != POLY_BYTES * K:
        raise ValueError(f"encoded polyvec must be {POLY_BYTES * K} bytes")
    return [
        byte_decode(12, data[i * POLY_BYTES : (i + 1) * POLY_BYTES])
        for i in range(K)
    ]


def _compress_encode_polyvec(vec: PolyVec, d: int) -> bytes:
    return b"".join(byte_encode(d, [compress(d, x) for x in poly]) for poly in vec)


def _decode_decompress_polyvec(data: bytes, d: int) -> PolyVec:
    poly_bytes = 32 * d
    if len(data) != K * poly_bytes:
        raise ValueError(f"encoded compressed polyvec must be {K * poly_bytes} bytes")
    out: PolyVec = []
    for i in range(K):
        comp = byte_decode(d, data[i * poly_bytes : (i + 1) * poly_bytes])
        out.append([decompress(d, x) for x in comp])
    return out


def _compress_encode_poly(poly: Poly, d: int) -> bytes:
    return byte_encode(d, [compress(d, x) for x in poly])


def _decode_decompress_poly(data: bytes, d: int) -> Poly:
    if len(data) != 32 * d:
        raise ValueError(f"encoded compressed polynomial must be {32 * d} bytes")
    return [decompress(d, x) for x in byte_decode(d, data)]


def generate_matrix(rho: bytes) -> Matrix:
    """Generate Ahat with FIPS 203 ordering A[i,j] = SampleNTT(rho || j || i)."""

    if len(rho) != SEED_BYTES:
        raise ValueError("rho must be 32 bytes")
    return [
        [sample_ntt(rho + bytes([j, i])) for j in range(K)]
        for i in range(K)
    ]


def transpose_matrix(matrix: Matrix) -> Matrix:
    if len(matrix) != K or any(len(row) != K for row in matrix):
        raise ValueError("matrix must be K x K")
    return [[matrix[j][i] for j in range(K)] for i in range(K)]


def _matrix_vector_mul_ntt(matrix: Matrix, vec: PolyVec) -> PolyVec:
    out: PolyVec = []
    for i in range(K):
        acc = _zero_poly()
        for j in range(K):
            acc = _add_poly(acc, multiply_ntts(matrix[i][j], vec[j]))
        out.append(acc)
    return out


def _dot_ntt(a: PolyVec, b: PolyVec) -> Poly:
    acc = _zero_poly()
    for i in range(K):
        acc = _add_poly(acc, multiply_ntts(a[i], b[i]))
    return acc


def keygen(seed_d: bytes) -> tuple[bytes, bytes]:
    """FIPS 203 Algorithm 13 K-PKE.KeyGen(d)."""

    if len(seed_d) != SEED_BYTES:
        raise ValueError("K-PKE.KeyGen seed d must be 32 bytes")
    rho, sigma = G(seed_d + bytes([K]))
    a_hat = generate_matrix(rho)

    nonce = 0
    s: PolyVec = []
    for _ in range(K):
        s.append(sample_poly_cbd(ETA1, prf(ETA1, sigma, nonce)))
        nonce += 1
    e: PolyVec = []
    for _ in range(K):
        e.append(sample_poly_cbd(ETA1, prf(ETA1, sigma, nonce)))
        nonce += 1

    s_hat = [ntt(poly) for poly in s]
    e_hat = [ntt(poly) for poly in e]
    t_hat = [_add_poly(prod, err) for prod, err in zip(_matrix_vector_mul_ntt(a_hat, s_hat), e_hat)]

    ek_pke = _encode_polyvec_12(t_hat) + rho
    dk_pke = _encode_polyvec_12(s_hat)
    return ek_pke, dk_pke


def encrypt(ek_pke: bytes, message: bytes, randomness: bytes) -> bytes:
    """FIPS 203 Algorithm 14 K-PKE.Encrypt(ekPKE, m, r)."""

    if len(ek_pke) != PKE_PUBLICKEY_BYTES:
        raise ValueError("ekPKE has invalid length")
    if len(message) != SEED_BYTES:
        raise ValueError("message must be 32 bytes")
    if len(randomness) != SEED_BYTES:
        raise ValueError("randomness r must be 32 bytes")

    t_hat = _decode_polyvec_12(ek_pke[: POLY_BYTES * K])
    rho = ek_pke[POLY_BYTES * K :]
    a_hat_t = transpose_matrix(generate_matrix(rho))

    nonce = 0
    y: PolyVec = []
    for _ in range(K):
        y.append(sample_poly_cbd(ETA1, prf(ETA1, randomness, nonce)))
        nonce += 1
    e1: PolyVec = []
    for _ in range(K):
        e1.append(sample_poly_cbd(ETA2, prf(ETA2, randomness, nonce)))
        nonce += 1
    e2 = sample_poly_cbd(ETA2, prf(ETA2, randomness, nonce))

    y_hat = [ntt(poly) for poly in y]
    u = [
        _add_poly(intt(prod), err)
        for prod, err in zip(_matrix_vector_mul_ntt(a_hat_t, y_hat), e1)
    ]
    mu = [decompress(1, x) for x in byte_decode(1, message)]
    v = _add_poly(_add_poly(intt(_dot_ntt(t_hat, y_hat)), e2), mu)

    c1 = _compress_encode_polyvec(u, DU)
    c2 = _compress_encode_poly(v, DV)
    return c1 + c2


def decrypt(dk_pke: bytes, ciphertext: bytes) -> bytes:
    """FIPS 203 Algorithm 15 K-PKE.Decrypt(dkPKE, c)."""

    if len(dk_pke) != PKE_SECRETKEY_BYTES:
        raise ValueError("dkPKE has invalid length")
    if len(ciphertext) != C1_BYTES + C2_BYTES:
        raise ValueError("ciphertext has invalid length")

    c1 = ciphertext[:C1_BYTES]
    c2 = ciphertext[C1_BYTES:]
    u = _decode_decompress_polyvec(c1, DU)
    v = _decode_decompress_poly(c2, DV)
    s_hat = _decode_polyvec_12(dk_pke)

    u_hat = [ntt(poly) for poly in u]
    w = _sub_poly(v, intt(_dot_ntt(s_hat, u_hat)))
    return byte_encode(1, [compress(1, x) for x in w])

