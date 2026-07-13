#!/usr/bin/env python3
"""Generate deterministic independent INTT and pipelined roundtrip vectors."""

from __future__ import annotations

import argparse
import random
from pathlib import Path

from ref_model.python_model.ntt import intt, ntt
from ref_model.python_model.params import N, Q


def write_words(path: Path, header: list[str], vectors: list[list[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as handle:
        for line in header:
            handle.write(f"// {line}\n")
        for vector in vectors:
            for value in vector:
                handle.write(f"{value:03x}\n")


def standalone_vectors() -> list[tuple[str, list[int]]]:
    vectors: list[tuple[str, list[int]]] = [
        ("zero", [0] * N),
        ("all_q_minus_1", [Q - 1] * N),
    ]
    for index in (0, 1, 2, 63, 64, 127, 128, 255):
        poly = [0] * N
        poly[index] = 1
        vectors.append((f"impulse_{index}", poly))
    vectors.append(("pattern", [((i * 41) + (i * i * 9) + 77) % Q for i in range(N)]))
    rng = random.Random(0x4D33494E)
    for index in range(20):
        vectors.append((f"random_{index:02d}", [rng.randrange(Q) for _ in range(N)]))
    return vectors


def roundtrip_vectors() -> list[tuple[str, list[int]]]:
    vectors: list[tuple[str, list[int]]] = [
        ("zero", [0] * N),
        ("one", [1] * N),
        ("all_q_minus_1", [Q - 1] * N),
    ]
    for index in (0, 1, 127, 128, 255):
        poly = [0] * N
        poly[index] = 1
        vectors.append((f"impulse_{index}", poly))
    vectors.extend((
        ("alternating", [0 if i % 2 == 0 else Q - 1 for i in range(N)]),
        ("increasing", [i % Q for i in range(N)]),
    ))
    rng = random.Random(0x4D335254)
    for index in range(20):
        vectors.append((f"random_{index:02d}", [rng.randrange(Q) for _ in range(N)]))
    return vectors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--intt-output", required=True)
    parser.add_argument("--roundtrip-output", required=True)
    args = parser.parse_args()

    inverse = standalone_vectors()
    inverse_words: list[list[int]] = []
    for _, poly in inverse:
        inverse_words.extend((poly, intt(poly)))
    write_words(Path(args.intt_output), [
        "format: each vector has 256 canonical NTT-domain inputs then 256 canonical normal outputs",
        f"vector_count {len(inverse)} seed 0x4d33494e coefficient_count 256",
        "source: ref_model.python_model.ntt.intt",
    ], inverse_words)

    roundtrip = roundtrip_vectors()
    roundtrip_words: list[list[int]] = []
    for _, poly in roundtrip:
        transformed = ntt(poly)
        roundtrip_words.extend((poly, transformed, intt(transformed)))
    write_words(Path(args.roundtrip_output), [
        "format: each vector has 256 normal inputs, 256 expected NTT, 256 expected INTT",
        f"vector_count {len(roundtrip)} seed 0x4d335254 coefficient_count 256",
        "source: ref_model.python_model.ntt.ntt and intt",
    ], roundtrip_words)
    print(f"PASS gen_intt_pipe_vectors intt_vectors={len(inverse)} roundtrip_vectors={len(roundtrip)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
