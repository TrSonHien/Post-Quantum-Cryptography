"""Tests for deterministic vector export, strict loading, and comparison."""

from __future__ import annotations

import copy
import tempfile
import unittest
from pathlib import Path

from ref_model.compare.compare_vectors import first_mismatch
from ref_model.compare.generate_vectors import build_document
from ref_model.compare.vector_schema import VectorFormatError, load_document, validate_document, write_document


class TestVectorInfrastructure(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = build_document()

    def test_export_reload_is_exact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "vectors.json"
            write_document(self.document, path)
            self.assertEqual(load_document(path), self.document)

    def test_generation_is_reproducible(self) -> None:
        self.assertEqual(build_document(), build_document())

    def test_malformed_input_rejected(self) -> None:
        malformed = copy.deepcopy(self.document)
        del malformed["metadata"]["byte_order"]
        with self.assertRaisesRegex(VectorFormatError, "missing=.*byte_order"):
            validate_document(malformed)

    def test_unknown_case_field_rejected(self) -> None:
        malformed = copy.deepcopy(self.document)
        malformed["vectors"][0]["surprise"] = True
        with self.assertRaisesRegex(VectorFormatError, "extra=.*surprise"):
            validate_document(malformed)

    def test_first_mismatch_reports_path(self) -> None:
        actual = copy.deepcopy(self.document)
        actual["vectors"][2]["expected"]["ntt"][17] ^= 1
        self.assertEqual(
            first_mismatch(self.document, actual),
            "root.vectors[2].expected.ntt[17]: expected 3139, got 3138",
        )


if __name__ == "__main__":
    unittest.main()
