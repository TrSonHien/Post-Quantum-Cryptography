"""Modular arithmetic helpers for canonical Z_q coefficients."""

from __future__ import annotations

from .params import Q


def mod_q(x: int) -> int:
    """Return the canonical representative of x in [0, q-1]."""

    return x % Q


def add_q(a: int, b: int) -> int:
    return (a + b) % Q


def sub_q(a: int, b: int) -> int:
    return (a - b) % Q


def mul_q(a: int, b: int) -> int:
    return (a * b) % Q


def bitrev(value: int, width: int) -> int:
    if value < 0 or value >= (1 << width):
        raise ValueError(f"value {value} does not fit in {width} bits")
    out = 0
    for _ in range(width):
        out = (out << 1) | (value & 1)
        value >>= 1
    return out


def bitrev7(value: int) -> int:
    return bitrev(value, 7)


def zeta_power(exp: int) -> int:
    from .params import ZETA

    return pow(ZETA, exp, Q)

