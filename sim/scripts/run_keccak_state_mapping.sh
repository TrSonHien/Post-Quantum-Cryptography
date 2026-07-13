#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)";TMP="$(mktemp -d "${TMPDIR:-/tmp}/m5-map.XXXXXX")";trap 'rm -rf "$TMP"' EXIT INT TERM
timeout 30s iverilog -g2012 -Wall -o "$TMP/test.vvp" "$ROOT/tb/unit/tb_keccak_state_mapping.v"
(cd "$TMP";timeout 30s vvp test.vvp)
