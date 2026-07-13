#!/usr/bin/env python3
"""Generate deterministic forward-NTT vectors for tb_ntt_core_pipe.

The arithmetic comes from ref_model.python_model.ntt and is not reimplemented
here. The output is a readmemh-compatible file: each vector stores 256 input
coefficients followed by 256 expected NTT-domain coefficients.
"""

from __future__ import annotations

import argparse
import random
from pathlib import Path

from ref_model.python_model.ntt import ntt
from ref_model.python_model.params import N, Q


def deterministic_pattern() -> list[int]:
    return [((i * 37) + (i * i * 7) + 123) % Q for i in range(N)]


def build_vectors(random_count: int) -> list[tuple[str, list[int]]]:
    vectors: list[tuple[str, list[int]]] = []
    vectors.append(("zero", [0] * N))
    for idx in (0, 1, 127, 128, 255):
        poly = [0] * N
        poly[idx] = 1
        vectors.append((f"impulse_{idx}", poly))
    vectors.append(("all_q_minus_1", [Q - 1] * N))
    vectors.append(("deterministic_pattern", deterministic_pattern()))

    rng = random.Random(0x4D334B32)
    for vec_idx in range(random_count):
        vectors.append((f"random_{vec_idx:02d}", [rng.randrange(Q) for _ in range(N)]))
    return vectors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--random-count", type=int, default=20)
    args = parser.parse_args()

    vectors = build_vectors(args.random_count)
    path = Path(args.output)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as handle:
        handle.write("// format: for each vector, 256 input words then 256 expected NTT words\n")
        handle.write(f"// vector_count {len(vectors)}\n")
        handle.write("// coefficient representation: canonical unsigned hex, q=3329\n")
        for name, poly in vectors:
            expected = ntt(poly)
            handle.write(f"// vector {name}\n")
            for value in poly:
                handle.write(f"{value:03x}\n")
            for value in expected:
                handle.write(f"{value:03x}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
