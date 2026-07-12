# M1 v0.1 Architecture Verification Plan

## Python-vector to RTL-interface mapping

`mlkem-vector-v1` remains the source container. Future adapters translate cases
without changing values:

| Vector content | RTL transaction |
|---|---|
| metadata `parameters` | elaboration/configuration checks (`q,n,k,eta,du,dv`) |
| metadata `byte_order` | byte-stream lane/address ordering assertion |
| metadata `coefficient_representation` | boundary range/domain assertions |
| case `id` | `operation_id`/test diagnostic label |
| `inputs.coefficients` | normal-domain coefficient load stream |
| `inputs.f_hat`, `inputs.g_hat` | NTT-domain streams with domain=`hat` |
| `expected.ntt` | NTT `poly_hat` output stream |
| `expected.intt` | INTT normal-domain output stream |
| `expected.product_hat` | `MultiplyNTTs` NTT-domain output stream |
| `*_hex` | byte stream, two hex characters per increasing-address byte |

Coefficient arrays transfer in logical index order `0..255`; load/drain adapters
apply the documented physical bank/address map. Comparisons reconstruct logical
order and use the strict first-mismatch comparator. Internal Montgomery data is
never exported into this schema.

## Required protocol assertions

- valid payload and metadata remain stable while ready is low;
- transfer count increments only on `valid && ready`;
- no output without a corresponding accepted operation ID;
- no duplicate, dropped, or reordered operation IDs;
- valid-only lane output occurs exactly `L` cycles after input valid;
- invalid pipeline slots never write memory;
- reset clears all control/valid state on the sampling edge;
- reset does not require or assume memory/payload initialization;
- completion implies the final write committed in the same or an earlier edge;
- no command acceptance while a non-overlap engine is occupied.

## Required memory and NTT assertions

- address is within `0..127` for every bank request;
- exactly one source-bank read per bank for each valid butterfly;
- exactly one destination-bank write per bank for each valid result;
- no same-bank duplicate write;
- no same physical bank/address read-write collision;
- source and destination roles differ throughout a stage;
- role swap occurs only after the stage's final write commit;
- bank/address mapping equals the stage table;
- 128 butterflies issue per stage, seven stages per transform;
- zeta, stage, butterfly index, logical indices, domain, and `last` stay aligned;
- NTT accepts one butterfly per cycle after fill (`II=1`);
- NTT emits `poly_hat`; INTT consumes `poly_hat` and emits normal-domain data;
- every architectural coefficient is `<3329`.

## Verification gates

1. Unit-test bank/address formulas exhaustively for all 256 indices and every
   NTT/INTT transition.
2. Verify no collisions and exact read/write counts from schedule traces.
3. Compare reconstructed outputs against curated and generated
   `mlkem-vector-v1` NTT/INTT vectors.
4. Test request/response stalls at every engine boundary while proving fixed
   internal lane latency.
5. Test reset during idle and active operation; active work is discarded and no
   stale valid/write may escape.
6. Test first, middle, and final write timing and completion ordering.
7. Retain existing baseline regressions as legacy checks; they do not prove M1
   contract compliance.

Final NIST CAVP/ACVP vectors remain pending and are not implied by this plan.
