# Codec and sampler

## codec

### Purpose
FIPS 203 byte encoding, decoding, compression, or format support

### Active modules

- `byte_decode_poly_pipe`
- `byte_encode_poly_pipe`
- `message_to_poly_pipe`
- `poly_compress_encode_pipe`
- `poly_decode12_pipe`
- `poly_decode_decompress_pipe`
- `poly_encode12_pipe`
- `poly_to_message_pipe`
- `polyvec_codec_pipe`
- `polyvec_compress_encode10_pipe`
- `polyvec_decode12_pipe`
- `polyvec_decode_decompress10_pipe`
- `polyvec_encode12_pipe`

### Adapter and historical note

- `kpke_format_pipe` is a retained active adapter.
- `poly_encode12_pipe` and `poly_decode12_pipe` are active through the K-PKE
  public-key polyvec codecs.
- Superseded codec micro-pipelines are available only in Git history before
  `pre-legacy-prune-b683bd7`.

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.

### Dependency graph, representations, and reading order

Read active byte codecs, coefficient codecs, poly/polyvec codecs, then CBD,
noise, and SampleNTT.  Encodings are LSB-first coefficient encodings and
low-byte-first stream words; sampler outputs are explicitly NORMAL or NTT as
named by each port.  Codec and sampler controllers own their local shift,
count, and output holding state until valid/ready completion.  Use M6
regression and the named block runners; SampleNTT is not
described here as constant-time.

## sampler

### Purpose
FIPS 203 Algorithms 7--8 sampling support

### Active modules

- `mlkem_noise_sampler`
- `mlkem_sample_ntt`
- `sample_ntt_parser`
- `sample_poly_cbd_pipe`

### Historical note

The current sampler path uses `sample_poly_cbd_pipe`; the earlier pairwise CBD
helper is available only in Git history before `pre-legacy-prune-b683bd7`.

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
