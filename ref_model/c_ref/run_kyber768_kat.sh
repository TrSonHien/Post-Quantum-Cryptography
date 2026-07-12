#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

src_dir="$repo_root/ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/Reference_Implementation/crypto_kem/kyber768"
kat_dir="$repo_root/ref_model/c_ref/NIST-PQ-Submission-Kyber-20201001/KAT/kyber768"
build_root="$repo_root/ref_model/c_ref/build"
work_dir="$build_root/kyber768_ref"

local_req="$kat_dir/PQCkemKAT_2400.req"
local_rsp="$kat_dir/PQCkemKAT_2400.rsp"
gen_req="$work_dir/PQCkemKAT_2400.req"
gen_rsp="$work_dir/PQCkemKAT_2400.rsp"

mkdir -p "$build_root"
if [[ -e "$work_dir" ]]; then
  rm -rf "$work_dir"
fi
mkdir -p "$work_dir"

cp -a "$src_dir/." "$work_dir/"

make -C "$work_dir" PQCgenKAT_kem > "$build_root/kyber768_make.log" 2>&1

(
  cd "$work_dir"
  ./PQCgenKAT_kem
) > "$build_root/kyber768_pqcgenkat.log" 2>&1

cmp -s "$gen_req" "$local_req"
cmp -s "$gen_rsp" "$local_rsp"

python3 "$repo_root/ref_model/kat/parse_legacy_kyber_kat.py" \
  --expect kyber768-2020 \
  --req "$local_req" \
  --rsp "$local_rsp" \
  --compare-req "$gen_req" \
  --compare-rsp "$gen_rsp" \
  > "$build_root/kyber768_parser.log"

sha256sum "$local_req" "$local_rsp" "$gen_req" "$gen_rsp" \
  > "$build_root/kyber768_sha256sums.log"

echo "legacy_profile=kyber768-2020"
echo "classification=legacy Kyber 2020 regression vectors; not FIPS 203 ML-KEM validation"
echo "source_copy=$work_dir"
echo "generated_req=$gen_req"
echo "generated_rsp=$gen_rsp"
echo "exact_req_compare=PASS"
echo "exact_rsp_compare=PASS"
echo "parser_check=PASS"
