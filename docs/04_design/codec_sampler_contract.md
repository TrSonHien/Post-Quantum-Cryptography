# Codec and Sampler Contract v0.1

## Authority, parameters, and scope

FIPS 203 Algorithms 3--8 define M6. For ML-KEM-768, `n=256`, `q=3329`,
`k=3`, `eta1=eta2=2`, `du=10`, and `dv=4`. M6 implements conversion,
compression, formats, CBD, PRF noise sampling, and SampleNTT. It does not
implement K-PKE or ML-KEM control.

## Bit, byte, and stream representation

Byte arrays increase in address order and bits within a byte are least
significant first. Value `i` occupies packed bits `i*D +: D`; its bit zero is
earliest. A stream beat carries the earliest byte in `data[7:0]`, followed by
`[15:8]`, `[23:16]`, and `[31:24]`. Legal partial keeps are `0001`, `0011`,
`0111`, and `1111`; holes and zero keep are illegal. Required encoded
polynomial sizes (32D bytes) are word-aligned, so normal outputs are full beats.

## Domains and coefficient representation

Architectural coefficients are unsigned canonical residues in `[0,3328]`.
Semantic domains are `POLY_DOMAIN_INVALID=00`, `POLY_DOMAIN_NORMAL=01`, and
`POLY_DOMAIN_NTT=10`. Raw-code domains are distinct:
`CODEC_DOMAIN_RAW_D1`, `RAW_D4`, `RAW_D10`, and `RAW_D12`. Encoded bytes do not
carry normal/NTT meaning; callers retain metadata.

Compression produces a raw d-bit value for d=1,4,10:

```text
Compress_d(x) = floor((2^d*x + 1664)/3329) mod 2^d
Decompress_d(y) = floor((3329*y + 2^(d-1))/2^d)
```

These are exact nonnegative integer forms of nearest rational rounding. The
compress pipeline uses constant reciprocal/correction arithmetic selected at
elaboration; decompression uses multiplication followed by a constant shift.
No floating point, signed coefficient interpretation, or variable divisor is
permitted.

For d<12, ByteDecode returns the raw segment. For d=12 it returns
`raw12 mod 3329` and sets informational `noncanonical_seen` for any raw segment
at least 3329. Decoding never rejects such a segment. ByteEncode12 accepts only
canonical inputs.

## Controller and backpressure contract

Reset is synchronous active-low. Accepted start occurs only idle; busy spans
the complete operation; done is one cycle after the final result is accepted
or committed; error is explicit and sticky until reset/new transaction as
documented. Reset clears FSMs, counters, valid pipelines, domain metadata, and
noncanonical evidence, cancels the operation, and permits a clean restart.

Inputs count only `valid && ready`. Outputs keep data, keep/index/last, and
metadata stable while stalled. Malformed length, illegal keep/parameter/range,
early/missing last, excess input, or start while busy errors. Bounded LSB-first
reservoirs preserve bits across word boundaries without monolithic packing.

## Codec composition and formats

ByteEncode lengths are d1=32, d4=128, d10=320, and d12=384 bytes. Polynomial
adapters reuse the generic packer/unpacker. Compression adapters accept NORMAL
and return NORMAL after decode/decompress. Encode/decode12 preserve caller
NORMAL or NTT metadata; bytes never imply the domain.

K=3 adapters serialize polynomial elements 0,1,2 through one engine. D12 and
d10 polyvec lengths are 1152 and 960 bytes. `ekPKE` formatting is three d12
NTT polynomials then rho (1184 bytes); `dkPKE` is three d12 NTT polynomials
(1152 bytes). Ciphertext is three d10 compressed NORMAL polynomials followed
by one d4 compressed NORMAL polynomial (1088 bytes). M6 only formats data.

Message conversion is `ByteDecode1 -> Decompress1` and the inverse is
`Compress1 -> ByteEncode1`; message bit zero maps to coefficient zero.

## Samplers

CBD consumes exactly `64*eta` bytes. Each coefficient uses eta x-bits followed
by eta y-bits and emits `x-y mod 3329` canonically in NORMAL domain. Eta2 uses
one byte per coefficient pair; eta3 uses a bounded reservoir for 12-bit pairs.
The integrated noise sampler streams verified M5 `PRF_eta(seed,nonce)` into CBD;
eta is output length only and is not absorbed.

SampleNTT consumes continuing three-byte SHAKE128 groups. It forms
`d1=C0|((C1&0x0f)<<8)` then `d2=(C1>>4)|(C2<<4)`, accepts each only below 3329,
preserves order, and suppresses d2 when d1 fills coefficient 255. A two-entry
queue prevents loss under backpressure. Output is canonical NTT domain.
There is no functional iteration or rejection bound. M5 XOF is initialized
once with exactly `seed||index0||index1`; every later squeeze continues it.

## Architecture and timing freeze

The baseline uses registered single-lane coefficient arithmetic, bounded
encode/decode/CBD reservoirs, one serialized polynomial codec per polyvec, and
the existing M5 PRF/XOF engines. Latency and II are measured by focused M6
tests and recorded at closure. The expected critical paths are constant
compression correction and reservoir shift/merge. Synthesis remains required;
this contract makes no area, timing-closure, or Fmax claim. M2.3b is pending.
