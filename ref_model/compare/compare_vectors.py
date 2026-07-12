"""Strict vector comparison with deterministic first-mismatch diagnostics."""

from __future__ import annotations

import argparse
from typing import Any

from ref_model.compare.vector_schema import load_document


def first_mismatch(expected: Any, actual: Any, path: str = "root") -> str | None:
    if type(expected) is not type(actual):
        return f"{path}: type mismatch expected {type(expected).__name__}, got {type(actual).__name__}"
    if isinstance(expected, dict):
        expected_keys = list(expected)
        actual_keys = list(actual)
        if set(expected_keys) != set(actual_keys):
            missing = sorted(set(expected_keys) - set(actual_keys))
            extra = sorted(set(actual_keys) - set(expected_keys))
            return f"{path}: key mismatch missing={missing}, extra={extra}"
        for key in sorted(expected_keys):
            mismatch = first_mismatch(expected[key], actual[key], f"{path}.{key}")
            if mismatch:
                return mismatch
        return None
    if isinstance(expected, list):
        if len(expected) != len(actual):
            return f"{path}: length mismatch expected {len(expected)}, got {len(actual)}"
        for index, (left, right) in enumerate(zip(expected, actual)):
            mismatch = first_mismatch(left, right, f"{path}[{index}]")
            if mismatch:
                return mismatch
        return None
    if expected != actual:
        return f"{path}: expected {expected!r}, got {actual!r}"
    return None


def compare_files(expected_path: str, actual_path: str) -> str | None:
    return first_mismatch(load_document(expected_path), load_document(actual_path))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("expected")
    parser.add_argument("actual")
    args = parser.parse_args()
    mismatch = compare_files(args.expected, args.actual)
    if mismatch:
        print(f"FAIL: {mismatch}")
        return 1
    print("PASS: vector documents match exactly")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
