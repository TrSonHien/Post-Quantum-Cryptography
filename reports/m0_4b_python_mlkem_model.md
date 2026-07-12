# M0.4b Complete Python ML-KEM-768 Golden Model Report

## Scope

M0.4b completes the independent Python ML-KEM-768 golden model at the
deterministic internal-algorithm level.

Implemented from FIPS 203:

- matrix generation with `Ahat[i,j] = SampleNTT(rho || j || i)`;
- explicit matrix transposition for encryption;
- PRF/XOF/CBD orchestration for K-PKE;
- `K-PKE.KeyGen`, `K-PKE.Encrypt`, and `K-PKE.Decrypt`;
- `ML-KEM.KeyGen_internal`;
- `ML-KEM.Encaps_internal`;
- `ML-KEM.Decaps_internal`;
- implicit rejection using `J(z || c)`;
- ciphertext re-encryption comparison using Python `hmac.compare_digest`;
- encapsulation key, decapsulation key, and ciphertext input-check helpers.

M0.4b does not implement randomized public `ML-KEM.KeyGen`, `ML-KEM.Encaps`,
or `ML-KEM.Decaps` APIs. It does not implement M0.5 comparison tooling.

## Representation and layout decisions

The M0.4a representation decisions remain locked:

- coefficients are canonical unsigned integers in `[0, 3328]`;
- no Montgomery-domain representation is used;
- no lazy or centered intermediate representation is exposed;
- NTT arrays use the FIPS 203 `T_q` convention;
- byte layouts follow FIPS 203:
  - `ek = ekPKE`, length 1184 bytes;
  - `dk = dkPKE || ek || H(ek) || z`, length 2400 bytes;
  - `c = c1 || c2`, length 1088 bytes;
  - `c1` is 960 bytes for the compressed `u` vector;
  - `c2` is 128 bytes for the compressed `v` polynomial.

## FIPS/Kyber differences still unresolved

- Legacy Kyber 2020 top-level KEM behavior remains different from FIPS 203:
  FIPS 203 uses `(K, r) = G(m || H(ek))` and does not hash the ciphertext into
  the shared-secret derivation.
- FIPS 203 implicit rejection uses `J(z || c)`; legacy Kyber C uses its legacy
  `kr`/ciphertext-hash/KDF path.
- FIPS 203 requires encapsulation-key modulus checks and decapsulation
  key/ciphertext checks; legacy Kyber C APIs do not provide the same public
  input-check contract.
- Legacy C uses Montgomery/lazy internal representations; this Python model
  does not.
- Final NIST CAVP/ACVP ML-KEM vectors are not present locally, so no final KAT
  verification is claimed.

## Validation

Commands:

```sh
python3 -m py_compile ref_model/python_model/*.py
python3 -m ref_model.python_model.selftest
python3 -m unittest discover -s ref_model/python_model -p 'test*.py'
git diff --check
```

Result:

- Python compile check: PASS.
- Deterministic selftest: PASS.
- Unit tests: PASS, 13 tests.
- Successful encapsulation/decapsulation agreement: tested.
- Modified ciphertext fallback selection: tested.
- KAT verification: not claimed; final CAVP/ACVP vectors are missing.

## Remaining work

- M0.5 comparison tooling has not started.
- Final NIST CAVP/ACVP ML-KEM vectors still need to be imported/provenanced.
- Legacy C equivalence remains unresolved for lower-level functions until
  explicit C/Python comparison tooling exists.
