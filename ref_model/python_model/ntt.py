"""FIPS 203 NTT, inverse NTT, and NTT-domain multiplication."""

from __future__ import annotations

from .mod_arith import bitrev7, zeta_power
from .params import INV_NTT_SCALE, N, Q


def _check_poly(poly: list[int], name: str) -> None:
    if len(poly) != N:
        raise ValueError(f"{name} must have {N} coefficients")


def ntt(poly: list[int]) -> list[int]:
    _check_poly(poly, "poly")
    out = [x % Q for x in poly]
    i = 1
    length = 128
    while length >= 2:
        for start in range(0, N, 2 * length):
            zeta = zeta_power(bitrev7(i))
            i += 1
            for j in range(start, start + length):
                t = (zeta * out[j + length]) % Q
                out[j + length] = (out[j] - t) % Q
                out[j] = (out[j] + t) % Q
        length //= 2
    return out


def intt(poly_ntt: list[int]) -> list[int]:
    _check_poly(poly_ntt, "poly_ntt")
    out = [x % Q for x in poly_ntt]
    i = 127
    length = 2
    while length <= 128:
        for start in range(0, N, 2 * length):
            zeta = zeta_power(bitrev7(i))
            i -= 1
            for j in range(start, start + length):
                t = out[j]
                out[j] = (t + out[j + length]) % Q
                out[j + length] = (zeta * (out[j + length] - t)) % Q
        length *= 2
    return [(x * INV_NTT_SCALE) % Q for x in out]


def base_case_multiply(a0: int, a1: int, b0: int, b1: int, gamma: int) -> tuple[int, int]:
    c0 = (a0 * b0 + a1 * b1 * gamma) % Q
    c1 = (a0 * b1 + a1 * b0) % Q
    return c0, c1


def multiply_ntts(f_hat: list[int], g_hat: list[int]) -> list[int]:
    _check_poly(f_hat, "f_hat")
    _check_poly(g_hat, "g_hat")
    out = [0] * N
    for i in range(128):
        gamma = zeta_power(2 * bitrev7(i) + 1)
        out[2 * i], out[2 * i + 1] = base_case_multiply(
            f_hat[2 * i] % Q,
            f_hat[2 * i + 1] % Q,
            g_hat[2 * i] % Q,
            g_hat[2 * i + 1] % Q,
            gamma,
        )
    return out


def naive_mul_mod_xn_plus_1(f: list[int], g: list[int]) -> list[int]:
    """Slow R_q multiplication for tests: Z_q[X]/(X^256 + 1)."""

    _check_poly(f, "f")
    _check_poly(g, "g")
    out = [0] * N
    for i, a in enumerate(f):
        for j, b in enumerate(g):
            idx = i + j
            term = a * b
            if idx >= N:
                idx -= N
                term = -term
            out[idx] = (out[idx] + term) % Q
    return out

