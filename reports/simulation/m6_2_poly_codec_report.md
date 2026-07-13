# M6.2 Polynomial Codec Report

The d4 and d10 compress/encode then decode/decompress paths each pass 64
deterministic polynomials. Comparisons cover 8,192/20,480 encoded bytes and
16,384 coefficients per mode against the independent FIPS Python model.
Composition reuses the bounded ByteEncode/Decode reservoirs; NORMAL-domain
checks, canonical output, exact byte count, and final markers pass.
