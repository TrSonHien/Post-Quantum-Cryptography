#!/usr/bin/env python3
"""Generate deterministic independent INTT and pipelined roundtrip vectors."""

from __future__ import annotations

import argparse
import random
from pathlib import Path

from ref_model.python_model.ntt import intt, ntt
from ref_model.python_model.params import N, Q


def write_words(
    path: Path,
    header: list[str],
    vectors: list[tuple[str, list[list[int]]]],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as handle:
        for line in header:
            handle.write(f"// {line}\n")
        for vector_id, (name, blocks) in enumerate(vectors):
            handle.write(f"// vector_id: {vector_id}; name: {name}\n")
            for block in blocks:
                for value in block:
                    if not isinstance(value, int) or not 0 <= value < Q:
                        raise ValueError(f"non-canonical coefficient in {name}")
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
    inverse_words = [(name, [poly, intt(poly)]) for name, poly in inverse]
    write_words(Path(args.intt_output), [
        "schema: m3-ntt-vector-v1",
        "operation: inverse_ntt_with_canonical_scale",
        "format: 256 input words then 256 expected output words per vector",
        f"vector_count: {len(inverse)}",
        "coefficient_representation: canonical_unsigned_integer",
        "input_domain: ntt_poly_hat",
        "output_domain: normal_poly",
        "q: 3329; N: 256; input_count: 256; output_count: 256",
        "seed: 0x4d33494e; source: ref_model.python_model.ntt.intt",
    ], inverse_words)

    roundtrip = roundtrip_vectors()
    roundtrip_words: list[tuple[str, list[list[int]]]] = []
    for name, poly in roundtrip:
        transformed = ntt(poly)
        roundtrip_words.append((name, [poly, transformed, intt(transformed)]))
    write_words(Path(args.roundtrip_output), [
        "schema: m3-ntt-vector-v1",
        "operation: forward_inverse_roundtrip",
        "format: 256 normal inputs, 256 expected NTT outputs, 256 expected INTT outputs",
        f"vector_count: {len(roundtrip)}",
        "coefficient_representation: canonical_unsigned_integer",
        "input_domain: normal_poly; intermediate_domain: ntt_poly_hat; output_domain: normal_poly",
        "q: 3329; N: 256; input_count: 256; intermediate_count: 256; output_count: 256",
        "seed: 0x4d335254; source: ref_model.python_model.ntt.ntt,intt",
    ], roundtrip_words)
    print(f"PASS gen_intt_pipe_vectors intt_vectors={len(inverse)} roundtrip_vectors={len(roundtrip)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
