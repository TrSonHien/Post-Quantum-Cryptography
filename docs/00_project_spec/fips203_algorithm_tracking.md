# FIPS 203 Algorithm Tracking

## Scope

This file is the canonical ML-KEM-768 algorithm tracking file.

Normative source: `references/standards/NIST.FIPS.203.pdf`.

Supporting dependency source: `references/standards/nist.fips.202.pdf`.

Current parameter set: ML-KEM-768.

ML-KEM-768 parameters from FIPS 203 Table 2 and Table 3, Section 8, PDF page 44:

| Parameter | Value |
|---|---:|
| `n` | 256 |
| `q` | 3329 |
| `k` | 3 |
| `eta1` | 2 |
| `eta2` | 2 |
| `du` | 10 |
| `dv` | 4 |
| claimed security strength | 192 bits |
| encapsulation key size | 1184 bytes |
| decapsulation key size | 2400 bytes |
| ciphertext size | 1088 bytes |
| shared secret size | 32 bytes |

## Initial tracking table

| Algorithm / dependency | Normative source | Input/output | ML-KEM-768 parameters | Legacy C candidate mapping | Future Python mapping | Planned RTL milestone | Verification-vector source | Current status | Unresolved differences |
|---|---|---|---|---|---|---|---|---|---|
| `ByteEncode_d` | FIPS 203 Algorithm 5, Section 4.2.1, PDF page 31 | Input: 256 integers modulo `m`; output: byte array of length `32*d` | `d` used as 1, 4, 10, 12 depending caller | `poly_tobytes`, `poly_compress`, `polyvec_compress` candidates in legacy Kyber C | `mlkem_codec.byte_encode(d, coeffs)` | M6 Codec | final CAVP/ACVP ML-KEM vectors; generated module vectors later | planned | Need exact FIPS mapping for each legacy encode/compress path; legacy packing may be equivalent but not assumed. |
| `ByteDecode_d` | FIPS 203 Algorithm 6, Section 4.2.1, PDF page 31 | Input: byte array of length `32*d`; output: 256 integers | `d` used as 1, 4, 10, 12 | `poly_frombytes`, `poly_decompress`, `polyvec_decompress` candidates | `mlkem_codec.byte_decode(d, data)` | M6 Codec | final CAVP/ACVP ML-KEM vectors; generated module vectors later | planned | Need input-check implications for `ByteDecode_12` in ML-KEM.Encaps. |
| `Compress_d` | FIPS 203 Section 4.2.1 equations 4.7-4.8, PDF page 30 | Input: integer modulo `q`; output: integer modulo `2^d` | `du=10`, `dv=4`, also `d=1` for messages | `poly_compress`, `polyvec_compress` candidates | `mlkem_codec.compress(d, x)` | M6 Codec | final CAVP/ACVP ML-KEM vectors; directed boundary vectors | planned | Need exact rounding rule and tie behavior checked against FIPS formula. |
| `Decompress_d` | FIPS 203 Section 4.2.1 equations 4.7-4.8, PDF page 30 | Input: integer modulo `2^d`; output: integer modulo `q` | `du=10`, `dv=4`, also `d=1` | `poly_decompress`, `polyvec_decompress` candidates | `mlkem_codec.decompress(d, y)` | M6 Codec | final CAVP/ACVP ML-KEM vectors; directed boundary vectors | planned | Need prove legacy Kyber decompression matches FIPS rounding. |
| `SampleNTT` | FIPS 203 Algorithm 7, Section 4.2.2, PDF page 32; Appendix B PDF page 52 | Input: byte string seed for XOF; output: NTT-domain polynomial coefficients | `n=256`, `q=3329`, XOF uses SHAKE128 wrapper | `rej_uniform`, `gen_matrix` / `poly_getnoise` candidates need review | `mlkem_sampling.sample_ntt(seed)` | M5 Sampler / M3 NTT support | final CAVP/ACVP ML-KEM vectors; deterministic seed vectors | planned | FIPS uses XOF wrapper; legacy matrix-index/domain ordering must be checked. |
| `SamplePolyCBD_eta` | FIPS 203 Algorithm 8, Section 4.2.2, PDF page 32 | Input: `64*eta` bytes; output: polynomial in `Z_q^256` | `eta1=2`, `eta2=2` for ML-KEM-768 | `cbd.c`, `poly_getnoise_eta1`, `poly_getnoise_eta2` candidates | `mlkem_sampling.sample_poly_cbd(eta, data)` | M5 Sampler | final CAVP/ACVP ML-KEM vectors; deterministic PRF seed vectors | planned | Legacy eta handling likely reusable for 768 but must be traced through FIPS PRF inputs. |
| `NTT` | FIPS 203 Algorithm 9, Section 4.3, PDF page 35 | Input: polynomial coefficients; output: NTT representation | `n=256`, `q=3329`, zeta table from Appendix A | `ntt.c: ntt` candidate | `mlkem_ntt.ntt(f)` | M3 Fmax-oriented NTT | final CAVP/ACVP vectors if available; Python independent vectors | inventory only | Existing RTL has tests, but M0 has not proven FIPS-vector equivalence. |
| `NTT^-1` | FIPS 203 Algorithm 10, Section 4.3, PDF page 35 | Input: NTT representation; output: polynomial coefficients | `n=256`, `q=3329` | `ntt.c: invntt` candidate | `mlkem_ntt.intt(fhat)` | M3 Fmax-oriented INTT | final CAVP/ACVP vectors if available; Python independent vectors | inventory only | Existing round-trip uses Montgomery-domain convention; FIPS mapping must be documented. |
| `MultiplyNTTs` | FIPS 203 Algorithm 11, Section 4.3.1, PDF page 36 | Input: two NTT representations; output: NTT-domain product | `n=256`, 128 base multiplications | `poly_basemul_montgomery`, `basemul` candidates | `mlkem_ntt.multiply_ntts(fhat, ghat)` | M4 Polynomial / Polyvec engines | final CAVP/ACVP vectors if available; Python independent vectors | inventory only | Need align FIPS `BaseCaseMultiply` zeta indexing with legacy `zetas[64+i]` pattern. |
| `K-PKE.KeyGen` | FIPS 203 Algorithm 13, Section 5.1, PDF page 38 | Input: 32-byte seed `d`; output: `ekPKE`, `dkPKE` | `k=3`, `eta1=2`, `q=3329` | `indcpa_keypair_derand` / `indcpa_keypair` candidates | `mlkem_kpke.keygen(d)` | M7 K-PKE KeyGen | final CAVP/ACVP ML-KEM vectors; internal deterministic vectors | planned | FIPS adds `G(d||k)` and domain separation; legacy mapping must be proven. |
| `K-PKE.Encrypt` | FIPS 203 Algorithm 14, Section 5.2, PDF page 39 | Input: `ekPKE`, 32-byte message, 32-byte randomness; output: ciphertext | `k=3`, `du=10`, `dv=4`, `eta1=eta2=2` | `indcpa_enc` candidate | `mlkem_kpke.encrypt(ek, m, r)` | M7 K-PKE Encrypt | final CAVP/ACVP ML-KEM vectors; internal deterministic vectors | planned | Matrix transpose/order, compression, and message encode path must be tracked. |
| `K-PKE.Decrypt` | FIPS 203 Algorithm 15, Section 5.3, PDF page 40 | Input: `dkPKE`, ciphertext; output: 32-byte message | `k=3`, `du=10`, `dv=4` | `indcpa_dec` candidate | `mlkem_kpke.decrypt(dk, c)` | M7 K-PKE Decrypt | final CAVP/ACVP ML-KEM vectors; internal deterministic vectors | planned | Need confirm ciphertext split and `ByteEncode_1(Compress_1(w))` exact behavior. |
| `ML-KEM.KeyGen_internal` | FIPS 203 Algorithm 16, Section 6.1, PDF page 41 | Input: seeds `d`, `z`; output: `ek`, `dk` | `ek=1184`, `dk=2400` bytes | `crypto_kem_keypair` internals candidate but not direct | `mlkem_kem.keygen_internal(d, z)` | M8 ML-KEM top-level | final CAVP/ACVP ML-KEM vectors | planned | Legacy secret-key layout and seed handling must be compared with FIPS. |
| `ML-KEM.Encaps_internal` | FIPS 203 Algorithm 17, Section 6.2, PDF page 42 | Input: `ek`, message `m`; output: shared secret `K`, ciphertext `c` | `K=32`, `c=1088` bytes | `crypto_kem_enc` internals candidate but not direct | `mlkem_kem.encaps_internal(ek, m)` | M8 ML-KEM top-level | final CAVP/ACVP ML-KEM vectors | planned | FIPS 203 Appendix C says ML-KEM changes shared-secret derivation versus Kyber Round 3. |
| `ML-KEM.Decaps_internal` | FIPS 203 Algorithm 18, Section 6.3, PDF page 43 | Input: `dk`, ciphertext; output: shared secret | `dk=2400`, `c=1088`, `K=32` bytes | `crypto_kem_dec` internals candidate but not direct | `mlkem_kem.decaps_internal(dk, c)` | M8 ML-KEM top-level | final CAVP/ACVP ML-KEM vectors | planned | FIPS 203 Appendix C says implicit rejection derivation differs from Kyber Round 3. |
| `H` | FIPS 203 Section 4.1 equation 4.4, PDF page 27; FIPS 202 Section 6.1 | Input: byte string; output: 32 bytes | SHA3-256 | `fips202.c: sha3_256` candidate | `mlkem_hash.h(data)` | M5 Keccak/SHA3/SHAKE | NIST hash vectors; final ML-KEM vectors | planned | Need validate local Keccak/SHA3 implementation or use trusted Python library for oracle. |
| `G` | FIPS 203 Section 4.1 equation 4.5, PDF page 28; FIPS 202 Section 6.1 | Input: byte string; output: two 32-byte strings | SHA3-512 | `fips202.c: sha3_512` candidate | `mlkem_hash.g(data)` | M5 Keccak/SHA3/SHAKE | NIST hash vectors; final ML-KEM vectors | planned | Must track `G(d||k)` and `G(m||H(ek))` callers separately. |
| `J` | FIPS 203 Section 4.1 equation 4.4, PDF page 27; FIPS 202 Section 6.2 | Input: byte string; output: 32 bytes | SHAKE256 output 32 bytes | `fips202.c: shake256` candidate | `mlkem_hash.j(data)` | M5 Keccak/SHA3/SHAKE | NIST SHAKE vectors; final ML-KEM vectors | planned | Used in decapsulation implicit rejection; Kyber difference must be tracked. |
| `PRF` | FIPS 203 Section 4.1 equations 4.2-4.3, PDF page 27; FIPS 202 Section 6.2 | Input: eta, 32-byte seed, one byte; output: `64*eta` bytes | `eta1=eta2=2` for ML-KEM-768 | `symmetric-shake.c: kyber_shake256_prf` candidate | `mlkem_hash.prf(eta, s, b)` | M5 Sampler / Keccak | deterministic PRF vectors; final ML-KEM vectors | planned | Confirm byte concatenation and output length for each caller. |
| `XOF` | FIPS 203 Section 4.1 XOF wrapper, PDF pages 28-29; FIPS 202 Section 6.2 | Incremental absorb/squeeze over SHAKE128 | used by `SampleNTT` matrix generation | `symmetric-shake.c: xof_absorb`, `xof_squeezeblocks` candidates | `mlkem_hash.xof_absorb_squeeze(...)` | M5 Sampler / Keccak | deterministic XOF vectors; final ML-KEM vectors | planned | Matrix-index ordering and wrapper byte-vs-bit length behavior must be checked. |

## M0.1 status

This is an initial tracking table. It records source anchors and candidate mappings only. No row is complete, differential-tested, KAT-verified, or FIPS-validated yet.
