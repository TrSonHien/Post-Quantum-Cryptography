#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

from ref_model.python_model.ntt import intt, ntt
from ref_model.python_model.params import N, Q

SEED = 0x4D34504F


def canonical_patterns(count: int) -> list[tuple[str, list[int]]]:
    vectors = [
        ("zero", [0] * N),
        ("q_minus_1", [Q - 1] * N),
        ("alternating", [0 if i % 2 == 0 else Q - 1 for i in range(N)]),
        ("incrementing", [i % Q for i in range(N)]),
    ]
    for index in (0, 1, 2, 63, 64, 127, 128, 255):
        poly = [0] * N
        poly[index] = 1
        vectors.append((f"impulse_{index}", poly))
    rng = random.Random(SEED)
    while len(vectors) < count:
        vectors.append((f"random_{len(vectors)}", [rng.randrange(Q) for _ in range(N)]))
    return vectors


def write_mem(path: Path, header: list[str], vectors: list[tuple[str, list[list[int]]]], widths: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii", newline="\n") as handle:
        for item in header:
            handle.write(f"// {item}\n")
        for vector_id, (name, blocks) in enumerate(vectors):
            handle.write(f"// vector_id: {vector_id}; name: {name}\n")
            for block, width in zip(blocks, widths, strict=True):
                for value in block:
                    if not isinstance(value, int) or value < 0 or value >= (1 << width):
                        raise ValueError(f"invalid value in {name}")
                    handle.write(f"{value:0{(width + 3) // 4}x}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    out = Path(args.output_dir)
    base = canonical_patterns(32)
    rng = random.Random(SEED ^ 0xA55A)

    add_vectors = []
    sub_vectors = []
    for name, a in base:
        b = [rng.randrange(Q) for _ in range(N)]
        add_vectors.append((name, [a, b, [(x + y) % Q for x, y in zip(a, b, strict=True)]]))
        sub_vectors.append((name, [a, b, [(x - y) % Q for x, y in zip(a, b, strict=True)]]))

    reduce_vectors = []
    special = [0, Q - 1, Q, Q + 1, 2 * Q - 1, 2 * Q, 0xFFFFFFFF]
    for vector_id in range(32):
        values = [special[(i + vector_id) % len(special)] if i < 32 else rng.randrange(1 << 32) for i in range(N)]
        reduce_vectors.append((f"reduce_{vector_id}", [values, [x % Q for x in values]]))

    inverse_inputs = canonical_patterns(32)
    roundtrip_inputs = canonical_patterns(30)
    forward_vectors = [(name, [poly, ntt(poly)]) for name, poly in base]
    inverse_vectors = [(name, [poly, intt(poly)]) for name, poly in inverse_inputs]
    roundtrip_vectors = [(name, [poly, ntt(poly), intt(ntt(poly))]) for name, poly in roundtrip_inputs]

    common = ["schema: m4-poly-vector-v1", f"seed: 0x{SEED:08x}", "q: 3329; N: 256", "ordering: stable"]
    write_mem(out / "poly_add.mem", common + ["operation: poly_add", "input_domain: normal_or_ntt", "output_domain: preserves_input"], add_vectors, [12, 12, 12])
    write_mem(out / "poly_sub.mem", common + ["operation: poly_sub", "input_domain: normal_or_ntt", "output_domain: preserves_input"], sub_vectors, [12, 12, 12])
    write_mem(out / "poly_reduce.mem", common + ["operation: poly_reduce", "input_range: unsigned_32", "output_domain: preserves_input"], reduce_vectors, [32, 12])
    write_mem(out / "poly_reduce_input.mem", common + ["operation: poly_reduce_inputs", "input_range: unsigned_32"], [(n, [b[0]]) for n, b in reduce_vectors], [32])
    write_mem(out / "poly_reduce_expected.mem", common + ["operation: poly_reduce_expected", "output_range: canonical_unsigned"], [(n, [b[1]]) for n, b in reduce_vectors], [12])
    write_mem(out / "poly_ntt.mem", common + ["operation: poly_ntt", "input_domain: normal", "output_domain: ntt"], forward_vectors, [12, 12])
    write_mem(out / "poly_intt.mem", common + ["operation: poly_intt", "input_domain: ntt", "output_domain: normal"], inverse_vectors, [12, 12])
    write_mem(out / "poly_roundtrip.mem", common + ["operation: poly_ntt_intt_roundtrip", "domains: normal,ntt,normal"], roundtrip_vectors, [12, 12, 12])

    manifest = {
        "schema": "m4-poly-vector-v1",
        "version": 1,
        "q": Q,
        "N": N,
        "coefficient_width_bits": 12,
        "canonical_range": [0, Q - 1],
        "reduce_input_width_bits": 32,
        "reduce_input_range": [0, (1 << 32) - 1],
        "coefficient_encoding": "canonical_unsigned_integer",
        "seed": SEED,
        "vectors": {
            "add": [{"id": i, "name": n, "input_domain": "normal_or_ntt", "output_domain": "preserved", "input_polynomials": b[:2], "expected_polynomial": b[2]} for i, (n, b) in enumerate(add_vectors)],
            "sub": [{"id": i, "name": n, "input_domain": "normal_or_ntt", "output_domain": "preserved", "input_polynomials": b[:2], "expected_polynomial": b[2]} for i, (n, b) in enumerate(sub_vectors)],
            "reduce": [{"id": i, "name": n, "input_domain": "normal_or_ntt", "output_domain": "preserved", "input_polynomial": b[0], "expected_polynomial": b[1]} for i, (n, b) in enumerate(reduce_vectors)],
            "forward_ntt": [{"id": i, "name": n, "input_domain": "normal", "output_domain": "ntt", "input_polynomial": b[0], "expected_polynomial": b[1]} for i, (n, b) in enumerate(forward_vectors)],
            "inverse_ntt": [{"id": i, "name": n, "input_domain": "ntt", "output_domain": "normal", "input_polynomial": b[0], "expected_polynomial": b[1]} for i, (n, b) in enumerate(inverse_vectors)],
            "roundtrip": [{"id": i, "name": n, "input_domain": "normal", "output_domain": "normal", "input_polynomial": b[0], "expected_ntt": b[1], "expected_polynomial": b[2]} for i, (n, b) in enumerate(roundtrip_vectors)],
        },
    }
    (out / "m4_poly_vectors.json").write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="ascii")
    print("PASS gen_m4_poly_vectors add=32 sub=32 reduce=32 forward=32 inverse=32 roundtrip=30")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
