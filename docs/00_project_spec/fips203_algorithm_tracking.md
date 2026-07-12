# FIPS 203 Algorithm Tracking

## Scope

This is the canonical ML-KEM-768 algorithm tracking file for M0.

Normative ML-KEM source: `references/standards/NIST.FIPS.203.pdf`.

Normative SHA3/SHAKE dependency source: `references/standards/nist.fips.202.pdf`.

Supporting SHAKE incremental-API reference: `references/standards/nist.sp.800-185.pdf`.

Kyber Round-3 material and the local `NIST-PQ-Submission-Kyber-20201001` package are legacy/supporting sources only. They are not final FIPS 203 validation authorities.

## ML-KEM-768 parameter profile

FIPS 203 Section 8, Table 2 and Table 3, PDF page 48:

| Parameter | ML-KEM-768 value | Notes |
|---|---:|---|
| `n` | 256 | Polynomial degree. |
| `q` | 3329 | Coefficient modulus. |
| `k` | 3 | Module dimension. |
| `eta1` | 2 | Noise for `s`, `e`, and `y`. |
| `eta2` | 2 | Noise for `e1` and `e2`. |
| `du` | 10 | Compression width for vector `u`. |
| `dv` | 4 | Compression width for polynomial `v`. |
| Required RBG strength | 192 bits | FIPS 203 Table 2. |
| Encapsulation key size | 1184 bytes | `384*k + 32`. |
| Decapsulation key size | 2400 bytes | `768*k + 96`. |
| Ciphertext size | 1088 bytes | `32*(du*k + dv)`. |
| Shared secret size | 32 bytes | FIPS 203 Table 3. |

## M0.2 algorithm tracking register

Status vocabulary:

- `tracked`: FIPS source, interface, parameters, dependency, and candidate mapping recorded.
- `legacy-candidate`: local Kyber 2020 code appears structurally related but is not yet proven FIPS-equivalent.
- `missing`: project-owned implementation, harness, parser, or vector source is not present yet.
- `blocked-on-vectors`: final NIST CAVP/ACVP ML-KEM vectors are not local yet.

| Item | Normative source | Exact input | Exact output | ML-KEM-768 parameters and dependencies | Legacy C candidate mapping | Future Python mapping | Planned RTL milestone | Verification requirements | Current status | Unresolved FIPS/Kyber issue |
|---|---|---|---|---|---|---|---|---|---|---|
| `BitsToBytes` | FIPS 203 Algorithm 3, Section 4.2.1, PDF page 29 | Bit array length multiple of 8 | Byte array | Little-endian bit order inside each byte | implicit in packers | `codec.bits_to_bytes` | M6 Codec | Directed bit-order vectors plus caller-level KATs | tracked | Must verify every legacy packer uses the same bit order. |
| `BytesToBits` | FIPS 203 Algorithm 4, Section 4.2.1, PDF page 29 | Byte array | Bit array | Little-endian bit extraction | implicit in unpackers | `codec.bytes_to_bits` | M6 Codec | Directed bit-order vectors plus caller-level KATs | tracked | Must verify every legacy unpacker uses the same bit order. |
| `Compress_d` | FIPS 203 equations 4.7-4.8, Section 4.2.1, PDF page 30 | `x in Z_q` | `Compress_d(x) in Z_(2^d)` | `d=1,4,10`; rational rounding, no floating point | `poly_compress`, `polyvec_compress`, `poly_tomsg` | `codec.compress(d, x)` | M6 Codec | Boundary vectors for all `x`; final CAVP/ACVP and Python oracle | tracked, legacy-candidate | Need prove integer rounding/tie behavior matches FIPS exactly. |
| `Decompress_d` | FIPS 203 equations 4.7-4.8, Section 4.2.1, PDF page 30 | `y in Z_(2^d)` | `Decompress_d(y) in Z_q` | `d=1,4,10`; rational rounding, no floating point | `poly_decompress`, `polyvec_decompress`, `poly_frommsg` | `codec.decompress(d, y)` | M6 Codec | Exhaustive vectors for `2^d` inputs; final CAVP/ACVP and Python oracle | tracked, legacy-candidate | Need prove decompression arithmetic and canonical output range match FIPS. |
| `ByteEncode_d` | FIPS 203 Algorithm 5, Section 4.2.1, PDF page 31 | `F in Z_m^256`, `m=2^d` for `d<12`, `m=q` for `d=12` | `B in B^(32*d)` | Used with `d=1,4,10,12`; little-endian `d`-bit segments | `poly_tobytes`, `polyvec_tobytes`, `poly_compress`, `polyvec_compress`, `poly_tomsg` | `codec.byte_encode(d, F)` | M6 Codec | Round-trip tests, invalid `d=12` public-key checks, final vectors | tracked, legacy-candidate | `ByteEncode_12` is injective only for canonical `0..q-1`; legacy reductions must be proven. |
| `ByteDecode_d` | FIPS 203 Algorithm 6, Section 4.2.1, PDF page 31 | `B in B^(32*d)` | `F in Z_m^256`, `m=2^d` for `d<12`, `m=q` for `d=12` | Used with `d=1,4,10,12`; `d=12` reduces 12-bit chunks modulo `q` | `poly_frombytes`, `polyvec_frombytes`, `poly_decompress`, `polyvec_decompress`, `poly_frommsg` | `codec.byte_decode(d, B)` | M6 Codec | Directed invalid-encoding tests for encapsulation-key modulus check | tracked, legacy-candidate | Legacy decoders may accept non-canonical public-key encodings; FIPS input check must be separate. |
| `SampleNTT` | FIPS 203 Algorithm 7, Section 4.2.2, PDF page 32; Appendix B, PDF page 55 | `B in B^34` = 32-byte seed plus two indices | `ahat in Z_q^256`, NTT-domain polynomial | XOF = SHAKE128 wrapper; rejection accepts two 12-bit candidates per 3 bytes | `indcpa.c:gen_matrix`, `rej_uniform`, `xof_absorb`, `xof_squeezeblocks` | `sampling.sample_ntt(B)` | M5 Sampler | Deterministic seed/index vectors, matrix ordering tests, final vectors | tracked, legacy-candidate | Must prove `rho||j||i` ordering and transposed matrix calls match FIPS final. |
| `SamplePolyCBD_eta` | FIPS 203 Algorithm 8, Section 4.2.2, PDF page 32 | `B in B^(64*eta)` | `f in Z_q^256` | ML-KEM-768 uses `eta=2` for both `eta1` and `eta2`; coefficients represent `x-y mod q` | `cbd_eta1`, `cbd_eta2`, `poly_getnoise_eta1`, `poly_getnoise_eta2` | `sampling.sample_poly_cbd(eta, B)` | M5 Sampler | Exhaustive small-pattern vectors and PRF-driven deterministic vectors | tracked, legacy-candidate | Legacy `eta2` prototype uses Kyber constants; confirm no stale-size bug affects 768 path. |
| `NTT` | FIPS 203 Algorithm 9, Section 4.3, PDF page 35 | `f in Z_q^256` in normal coefficient order | `fhat in Z_q^256` in NTT representation | `zeta=17`, `BitRev7`, in-place Cooley-Tukey schedule | `ntt.c:ntt`, `poly_ntt`, `polyvec_ntt` | `ntt.ntt(f)` | M3 NTT | FIPS-aligned Python oracle, inverse/property tests, final vectors if exposed | tracked, legacy-candidate | Legacy C/RTL use Montgomery and lazy ranges; mathematical representation bridge must be documented. |
| `NTT^-1` | FIPS 203 Algorithm 10, Section 4.3, PDF page 35 | `fhat in Z_q^256` | `f in Z_q^256` | Gentleman-Sande schedule; final multiply by `3303 = 128^-1 mod q` | `ntt.c:invntt`, `poly_invntt_tomont`, `polyvec_invntt_tomont` | `ntt.intt(fhat)` | M3 INTT | Round-trip and convolution-property tests against independent oracle | tracked, legacy-candidate | Legacy inverse returns Montgomery-scaled/lazy values; exact normalization must be proven. |
| `BaseCaseMultiply` | FIPS 203 Algorithm 12, Section 4.3.1, PDF page 36 | `a0,a1,b0,b1,gamma in Z_q` | `(c0,c1) in Z_q^2` | `c0=a0*b0+a1*b1*gamma`; `c1=a0*b1+a1*b0` mod `q` | `ntt.c:basemul` | `ntt.base_case_multiply` | M4 Polynomial multiply | Exhaustive/random modular vectors, zeta-index vectors | tracked, legacy-candidate | Need align FIPS `gamma=zeta^(2*BitRev7(i)+1)` with legacy `zetas[64+i]`. |
| `MultiplyNTTs` | FIPS 203 Algorithm 11, Section 4.3.1, PDF page 36 | `fhat, ghat in Z_q^256` | `hhat in Z_q^256` | 128 `BaseCaseMultiply` calls; NTT-domain multiplication | `poly_basemul_montgomery`, `polyvec_pointwise_acc_montgomery` | `ntt.multiply_ntts(fhat, ghat)` | M4 Polynomial / polyvec engines | Polynomial product property against independent oracle | tracked, legacy-candidate | Montgomery-domain product and reduction schedule must be mapped before RTL reuse. |
| `K-PKE.KeyGen` | FIPS 203 Algorithm 13, Section 5.1, PDF page 38 | `d in B^32` | `ekPKE in B^(384*k+32)`, `dkPKE in B^(384*k)` | For 768: `ekPKE=1184`, `dkPKE=1152`; uses `G(d||k)`, `SampleNTT(rho||j||i)`, `PRF_eta1`, `NTT`, `MultiplyNTTs`, `ByteEncode_12` | `indcpa_keypair` is structural candidate only | `kpke.keygen(d)` | M7 K-PKE KeyGen | Deterministic internal vectors from final CAVP/ACVP plus Python/C comparison | tracked, legacy-candidate, blocked-on-vectors | FIPS adds explicit `k` byte domain separation; confirm local `indcpa_keypair` implements same input to `G`. |
| `K-PKE.Encrypt` | FIPS 203 Algorithm 14, Section 5.2, PDF page 39 | `ekPKE in B^(384*k+32)`, `m in B^32`, `r in B^32` | `c in B^(32*(du*k+dv))` | For 768: `c=1088`; uses matrix transpose sampling, `PRF_eta1`, `PRF_eta2`, `NTT`, `NTT^-1`, `Compress_du`, `Compress_dv`, byte encoding | `indcpa_enc` is structural candidate only | `kpke.encrypt(ek, m, r)` | M7 K-PKE Encrypt | Deterministic internal vectors; matrix-order and compression split tests | tracked, legacy-candidate, blocked-on-vectors | Need prove transpose flag/order and message polynomial path match final FIPS. |
| `K-PKE.Decrypt` | FIPS 203 Algorithm 15, Section 5.3, PDF page 40 | `dkPKE in B^(384*k)`, `c in B^(32*(du*k+dv))` | `m in B^32` | For 768: split `c1=960`, `c2=128`; `ByteDecode_du`, `ByteDecode_dv`, `Decompress`, `NTT`, `NTT^-1`, `ByteEncode_1(Compress_1(w))` | `indcpa_dec` is structural candidate only | `kpke.decrypt(dk, c)` | M7 K-PKE Decrypt | Deterministic decrypt vectors and ciphertext split tests | tracked, legacy-candidate, blocked-on-vectors | Need prove message recovery threshold/rounding exactly matches FIPS `Compress_1`. |
| `ML-KEM.KeyGen_internal` | FIPS 203 Algorithm 16, Section 6.1, PDF page 41 | `d,z in B^32` | `ek in B^(384*k+32)`, `dk in B^(768*k+96)` | For 768: `ek=1184`, `dk=2400`; `dk=dkPKE||ek||H(ek)||z`; deterministic CAVP interface | `crypto_kem_keypair` is not direct because it samples internally | `kem.keygen_internal(d, z)` | M8 KEM top | Final CAVP/ACVP internal keygen vectors | tracked, missing, blocked-on-vectors | Legacy keypair RNG path must not be treated as this deterministic interface without a new harness. |
| `ML-KEM.Encaps_internal` | FIPS 203 Algorithm 17, Section 6.2, PDF page 42 | `ek in B^(384*k+32)`, `m in B^32` | `K in B^32`, `c in B^(32*(du*k+dv))` | For 768: `K=32`, `c=1088`; `(K,r)=G(m||H(ek))`; calls K-PKE.Encrypt | `crypto_kem_enc` is not direct; legacy hashes `m` and derives final key differently | `kem.encaps_internal(ek, m)` | M8 KEM top | Final CAVP/ACVP internal encaps vectors | tracked, missing, blocked-on-vectors | Major Kyber/FIPS difference: FIPS does not hash ciphertext into shared-secret derivation. |
| `ML-KEM.Decaps_internal` | FIPS 203 Algorithm 18, Section 6.3, PDF page 43 | `dk in B^(768*k+96)`, `c in B^(32*(du*k+dv))` | `K in B^32` | Parses `dkPKE`, `ekPKE`, `h`, `z`; computes `(K',r')=G(m'||h)`, `Kbar=J(z||c)`, constant-time select on ciphertext compare | `crypto_kem_dec` is not direct; legacy implicit rejection and KDF path differ | `kem.decaps_internal(dk, c)` | M8 KEM top | Valid and invalid ciphertext vectors; constant-time compare/select review | tracked, missing, blocked-on-vectors | Major Kyber/FIPS difference: implicit rejection uses `J(z||c)` and no final ciphertext-hash KDF. |
| `ML-KEM.KeyGen` | FIPS 203 Algorithm 19, Section 7.1, PDF page 44 | No external input | `ek in B^(384*k+32)`, `dk in B^(768*k+96)` or error | Uses approved RBG for fresh `d,z in B^32`; calls internal keygen | `crypto_kem_keypair` structurally similar only | `kem.keygen(rbg)` | M8 KEM top | RBG failure tests plus internal deterministic vector replay | tracked, missing | Hardware/software boundary for approved RBG is unresolved; M0 only tracks algorithm. |
| `ML-KEM.Encaps` | FIPS 203 Algorithm 20, Section 7.2, PDF page 46 | Checked `ek in B^(384*k+32)` | `K in B^32`, `c in B^(32*(du*k+dv))` or error | Requires type check and modulus check `ByteEncode_12(ByteDecode_12(ek[0:384*k]))` before use; fresh `m in B^32` | `crypto_kem_enc` lacks explicit FIPS input-check interface | `kem.encaps(ek, rbg)` | M8 KEM top | Invalid public-key encodings, RBG failure, CAVP/ACVP vectors | tracked, missing | Legacy APIs likely do not enforce final FIPS public-key modulus check. |
| `ML-KEM.Decaps` | FIPS 203 Algorithm 21, Section 7.3, PDF page 47 | Checked `dk in B^(768*k+96)`, checked `c in B^(32*(du*k+dv))` | `K in B^32` | Requires ciphertext length check every call; decapsulation key length/hash checks before use | `crypto_kem_dec` lacks explicit FIPS input-check interface | `kem.decaps(dk, c)` | M8 KEM top | Invalid length/hash/ciphertext tests plus CAVP/ACVP vectors | tracked, missing | Legacy APIs likely do not expose final FIPS decapsulation input-check policy. |
| `PRF_eta` | FIPS 203 equations 4.2-4.3, Section 4.1, PDF page 27; FIPS 202 SHAKE256 | `eta in {2,3}`, `s in B^32`, `b in B` | `B^(64*eta)` | For 768: `eta=2`, output 128 bytes; `eta` controls length only, not domain separation | `kyber_shake256_prf`, macro `prf` in non-90s build | `hash.prf(eta, s, b)` | M5 Keccak/Sampler | SHAKE256 vectors and caller deterministic vectors | tracked, legacy-candidate | Confirm local non-90s path only; 90s AES/SHA2 variant is out of FIPS scope. |
| `H` | FIPS 203 equation 4.4, Section 4.1, PDF page 27; FIPS 202 SHA3-256 | Variable-length byte string | `B^32` | Used for `H(ek)` and decapsulation key hash check | `sha3_256`, macro `hash_h` in non-90s build | `hash.H(data)` | M5 Keccak | NIST SHA3-256 vectors and ML-KEM vectors | tracked, legacy-candidate | Need validate local Keccak implementation before using as oracle. |
| `J` | FIPS 203 equation 4.4, Section 4.1, PDF page 27; FIPS 202 SHAKE256 | Variable-length byte string | `B^32` | Used only for implicit rejection `J(z||c)` | No direct Kyber 2020 equivalent; `shake256` primitive only | `hash.J(data)` | M5 Keccak | SHAKE256 fixed-length vectors and invalid-ciphertext vectors | tracked, missing | Legacy Kyber uses KDF-based path; primitive availability is not algorithm equivalence. |
| `G` | FIPS 203 equation 4.5, Section 4.1, PDF page 28; FIPS 202 SHA3-512 | Variable-length byte string | Two 32-byte strings `(a,b)` | Used as `G(d||k)`, `G(m||H(ek))`, `G(m'||h)` | `sha3_512`, macro `hash_g` in non-90s build | `hash.G(data)` | M5 Keccak | NIST SHA3-512 vectors and caller-level vectors | tracked, legacy-candidate | Must track each caller separately because FIPS/Kyber changed KEM-level derivation. |
| `XOF` | FIPS 203 Section 4.1, PDF pages 28-29; FIPS 202 SHAKE128; SP 800-185 incremental API | Incremental absorb byte arrays; squeeze byte lengths | Byte stream | Wrapper uses byte lengths; only used by `SampleNTT` matrix generation | `kyber_shake128_absorb`, `xof_squeezeblocks`, `shake128_squeezeblocks` | `hash.xof` | M5 Keccak/Sampler | SHAKE128 vectors, absorb/squeeze equivalence tests, SampleNTT vectors | tracked, legacy-candidate | Need prove byte-order and index absorb sequence exactly match FIPS final. |

## FIPS 203 versus Kyber 2020 difference register

Source anchor: FIPS 203 Appendix C, PDF page 56, plus local C inspection of `crypto_kem/kyber768`.

| Difference | FIPS 203 requirement | Local Kyber 2020 observation | M0.2 disposition |
|---|---|---|---|
| Authoritative validation vectors | Final NIST CAVP/ACVP ML-KEM vectors are the external authority. | Local `.rsp` KATs are Kyber 2020 package vectors. | Keep local KATs labeled legacy regression vectors only. |
| Shared-secret derivation | `ML-KEM.Encaps_internal`: `(K,r)=G(m||H(ek))`; output `K` directly. | `kem.c:crypto_kem_enc` hashes random `m`, computes `G`, encrypts, hashes ciphertext into `kr+32`, then calls `kdf`. | Legacy KEM top is not FIPS-equivalent. Reuse only lower-level candidates after proof. |
| Initial encapsulation randomness | Algorithm 20 samples fresh `m`; Algorithm 17 uses that `m` directly. | `crypto_kem_enc` samples `buf` then calls `hash_h(buf, buf, 32)` before `G`. | Do not reuse as FIPS internal encaps without a new harness. |
| Implicit rejection | `Kbar=J(z||c)` and select `Kbar` if recomputed ciphertext mismatches. | `crypto_kem_dec` follows legacy `kr`/ciphertext hash/KDF path. | Legacy KEM decapsulation is not a direct FIPS oracle. |
| K-PKE keygen domain separation | `G(d||k)`; byte 33 is module dimension `k`. | `indcpa_keypair` has `buf[KYBER_SYMBYTES] = KYBER_K` before `hash_g`. | Candidate likely maps, but M0.3 must prove through a deterministic harness. |
| Matrix indices | Final FIPS uses `SampleNTT(rho||j||i)` in KeyGen and matching transpose usage in Encrypt. | `gen_matrix` uses `xof_absorb(seed, i, j)` or `xof_absorb(seed, j, i)` depending transpose flag. | Must test exact generated matrix entries before accepting. |
| Input checks | FIPS requires public-key type/modulus checks, decapsulation key length/hash checks, and ciphertext length check every decapsulation. | Kyber C API functions do not expose final FIPS input-check policy. | New FIPS wrapper/check layer required later; not M0.2 implementation. |
| Hash/XOF family | FIPS ML-KEM uses SHA3-256, SHA3-512, SHAKE128, SHAKE256. | Non-90s Kyber path maps to SHA3/SHAKE; 90s path maps to SHA2/AES. | 90s variant excluded from FIPS mapping. |
| NTT representation | FIPS algorithms are algebraic modulo `q`. | Kyber C and existing RTL use Montgomery/lazy intermediate representations. | Representation bridge must be documented before RTL architecture work. |
| Compression/encoding | FIPS specifies rational rounding and canonical byte encodings. | Kyber C uses optimized integer formulas. | Prove exact equivalence with exhaustive/directed vectors before claiming reuse. |

## M0.2 verification requirements

M0.2 is a documentation milestone only. No model or vector is valid merely because it is listed here.

Required later before any FIPS-equivalence claim:

1. Final NIST CAVP/ACVP ML-KEM vectors imported and provenance-recorded.
2. Project-owned deterministic C harness that writes generated artifacts outside the imported Kyber tree.
3. Independent Python ML-KEM-768 oracle using the FIPS interfaces above.
4. Exhaustive codec/compression boundary tests where feasible.
5. Deterministic module-level vectors for sampling, NTT, base multiply, K-PKE, and KEM internals.
6. Explicit proof or rejection of each legacy C candidate mapping.
7. Separate invalid-input tests for FIPS encapsulation and decapsulation checks.

## M0.2 result

The detailed FIPS 203 algorithm tracking register is complete for M0.2 when:

- every required algorithm/dependency has a FIPS source, interface, ML-KEM-768 parameter mapping, verification requirement, and candidate legacy mapping or explicit non-mapping;
- all known FIPS-vs-Kyber differences are recorded as unresolved until M0.3/M0.4 evidence exists;
- no RTL, testbench, simulation script, imported C source, Python model, KAT, or comparison tool is modified;
- `git diff --check` passes.
