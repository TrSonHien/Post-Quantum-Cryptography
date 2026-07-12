"""Strict deterministic vector schema shared by Python, RTL TBs, and comparators."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

SCHEMA = "mlkem-vector-v1"
REQUIRED_METADATA = {
    "algorithm", "parameter_set", "parameters", "source", "seed",
    "generation_command", "byte_order", "coefficient_representation",
}
REQUIRED_CASE = {"id", "category", "operation", "inputs", "expected"}
ALLOWED_CATEGORIES = {
    "arithmetic", "codec", "ntt", "multiply_ntts", "sampling", "kpke", "mlkem"
}


class VectorFormatError(ValueError):
    """Raised when a vector document is not schema-conformant."""


def _require_exact_keys(value: dict[str, Any], required: set[str], where: str) -> None:
    missing = required - value.keys()
    extra = value.keys() - required
    if missing or extra:
        raise VectorFormatError(
            f"{where}: keys mismatch; missing={sorted(missing)}, extra={sorted(extra)}"
        )


def validate_document(document: Any) -> dict[str, Any]:
    if not isinstance(document, dict):
        raise VectorFormatError("root: expected object")
    _require_exact_keys(document, {"schema", "metadata", "vectors"}, "root")
    if document["schema"] != SCHEMA:
        raise VectorFormatError(f"root.schema: expected {SCHEMA!r}")
    metadata = document["metadata"]
    if not isinstance(metadata, dict):
        raise VectorFormatError("metadata: expected object")
    _require_exact_keys(metadata, REQUIRED_METADATA, "metadata")
    if metadata["parameter_set"] != "ML-KEM-768":
        raise VectorFormatError("metadata.parameter_set: expected ML-KEM-768")
    if not isinstance(metadata["parameters"], dict):
        raise VectorFormatError("metadata.parameters: expected object")
    if not isinstance(metadata["seed"], str) or len(metadata["seed"]) != 64:
        raise VectorFormatError("metadata.seed: expected 32-byte lowercase hex")
    try:
        bytes.fromhex(metadata["seed"])
    except ValueError as exc:
        raise VectorFormatError("metadata.seed: invalid hex") from exc
    vectors = document["vectors"]
    if not isinstance(vectors, list) or not vectors:
        raise VectorFormatError("vectors: expected non-empty array")
    seen: set[str] = set()
    for index, case in enumerate(vectors):
        where = f"vectors[{index}]"
        if not isinstance(case, dict):
            raise VectorFormatError(f"{where}: expected object")
        _require_exact_keys(case, REQUIRED_CASE, where)
        if not isinstance(case["id"], str) or not case["id"]:
            raise VectorFormatError(f"{where}.id: expected non-empty string")
        if case["id"] in seen:
            raise VectorFormatError(f"{where}.id: duplicate {case['id']!r}")
        seen.add(case["id"])
        if case["category"] not in ALLOWED_CATEGORIES:
            raise VectorFormatError(f"{where}.category: unsupported category")
        if not isinstance(case["operation"], str) or not case["operation"]:
            raise VectorFormatError(f"{where}.operation: expected non-empty string")
        if not isinstance(case["inputs"], dict) or not isinstance(case["expected"], dict):
            raise VectorFormatError(f"{where}: inputs and expected must be objects")
    return document


def load_document(path: str | Path) -> dict[str, Any]:
    try:
        with Path(path).open("r", encoding="utf-8") as stream:
            document = json.load(stream)
    except (OSError, json.JSONDecodeError) as exc:
        raise VectorFormatError(f"cannot load {path}: {exc}") from exc
    return validate_document(document)


def write_document(document: dict[str, Any], path: str | Path) -> None:
    validate_document(document)
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
