#!/usr/bin/env python3
"""Strict parser/checker for the legacy Kyber 2020 KAT .req/.rsp files.

This script intentionally labels the vectors as legacy Kyber material. Passing
this checker does not imply FIPS 203 ML-KEM validation.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


EXPECTED = {
    "kyber768-2020": {
        "records": 100,
        "header": "# Kyber768",
        "seed": 48,
        "pk": 1184,
        "sk": 2400,
        "ct": 1088,
        "ss": 32,
    }
}

FIELD_ORDER = ("count", "seed", "pk", "sk", "ct", "ss")
FIELD_RE = re.compile(r"^(count|seed|pk|sk|ct|ss) = ?([0-9A-F]*)$")


class KatError(ValueError):
    pass


def _hex_len(value: str, nbytes: int, field: str, path: Path, count: int) -> None:
    if len(value) != 2 * nbytes:
        raise KatError(
            f"{path}: count {count}: {field} length {len(value)} hex chars, "
            f"expected {2 * nbytes}"
        )
    if not re.fullmatch(r"[0-9A-F]*", value):
        raise KatError(f"{path}: count {count}: {field} is not uppercase hex")


def parse_kat(path: Path, kind: str, profile: dict[str, int | str]) -> list[dict[str, str | int]]:
    if kind not in {"req", "rsp"}:
        raise KatError(f"unsupported KAT kind: {kind}")

    records: list[dict[str, str | int]] = []
    pending: list[str] = []
    saw_header = False

    for lineno, raw in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        line = raw.rstrip("\n")
        if line == "":
            continue
        if line.startswith("#"):
            if kind != "rsp" or records or pending:
                raise KatError(f"{path}:{lineno}: unexpected comment line")
            expected_header = str(profile["header"])
            if line != expected_header:
                raise KatError(f"{path}:{lineno}: header {line!r}, expected {expected_header!r}")
            saw_header = True
            continue
        pending.append(line)
        if len(pending) == len(FIELD_ORDER):
            record = _parse_record(path, lineno - len(FIELD_ORDER) + 1, pending, kind, profile)
            records.append(record)
            pending = []

    if pending:
        raise KatError(f"{path}: trailing partial record with {len(pending)} fields")
    if kind == "rsp" and not saw_header:
        raise KatError(f"{path}: missing response header")

    expected_records = int(profile["records"])
    if len(records) != expected_records:
        raise KatError(f"{path}: parsed {len(records)} records, expected {expected_records}")
    for expected_count, record in enumerate(records):
        if record["count"] != expected_count:
            raise KatError(f"{path}: record index {expected_count} has count {record['count']}")
    return records


def _parse_record(
    path: Path,
    start_lineno: int,
    lines: list[str],
    kind: str,
    profile: dict[str, int | str],
) -> dict[str, str | int]:
    record: dict[str, str | int] = {}
    count = -1
    for offset, (expected_field, line) in enumerate(zip(FIELD_ORDER, lines)):
        lineno = start_lineno + offset
        match = FIELD_RE.fullmatch(line)
        if not match:
            raise KatError(f"{path}:{lineno}: malformed field line")
        field, value = match.groups()
        if field != expected_field:
            raise KatError(f"{path}:{lineno}: got field {field}, expected {expected_field}")
        if field == "count":
            if value == "":
                raise KatError(f"{path}:{lineno}: blank count")
            count = int(value, 10)
            record[field] = count
            continue

        if field == "seed":
            _hex_len(value, int(profile["seed"]), field, path, count)
        elif kind == "req":
            if value != "":
                _hex_len(value, int(profile[field]), field, path, count)
        else:
            _hex_len(value, int(profile[field]), field, path, count)
        record[field] = value
    return record


def compare_exact(reference: Path, generated: Path, label: str) -> None:
    ref = reference.read_bytes()
    gen = generated.read_bytes()
    if ref != gen:
        raise KatError(
            f"{label}: exact byte comparison failed: {generated} differs from {reference}"
        )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expect", choices=sorted(EXPECTED), default="kyber768-2020")
    parser.add_argument("--req", type=Path, required=True)
    parser.add_argument("--rsp", type=Path, required=True)
    parser.add_argument("--compare-req", type=Path)
    parser.add_argument("--compare-rsp", type=Path)
    args = parser.parse_args(argv)

    profile = EXPECTED[args.expect]
    req_records = parse_kat(args.req, "req", profile)
    rsp_records = parse_kat(args.rsp, "rsp", profile)

    for i, (req, rsp) in enumerate(zip(req_records, rsp_records)):
        if req["count"] != rsp["count"]:
            raise KatError(f"count mismatch at record {i}")
        if req["seed"] != rsp["seed"]:
            raise KatError(f"seed mismatch at count {i}")

    if args.compare_req:
        parse_kat(args.compare_req, "req", profile)
        compare_exact(args.req, args.compare_req, "REQ")
    if args.compare_rsp:
        parse_kat(args.compare_rsp, "rsp", profile)
        compare_exact(args.rsp, args.compare_rsp, "RSP")

    print("legacy_profile=kyber768-2020")
    print("classification=legacy Kyber 2020 regression vectors; not FIPS 203 ML-KEM validation")
    print(f"req_records={len(req_records)}")
    print(f"rsp_records={len(rsp_records)}")
    print("fields=count,seed,pk,sk,ct,ss")
    print("status=PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except KatError as exc:
        print(f"status=FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
