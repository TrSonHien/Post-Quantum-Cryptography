# M3.5 NTT/INTT Differential and Roundtrip Report

## Independent vectors

`tb/tools/gen_intt_pipe_vectors.py` calls the unchanged
`ref_model.python_model.ntt.ntt/intt` algorithms. Standalone inverse vectors
use seed `0x4d33494e`; roundtrip vectors use seed `0x4d335254`. Generated files
are canonical unsigned, 256 coefficients per polynomial, deterministic, and
ignored simulation outputs. Two independent generations compared byte-for-byte.

## Results

- Existing forward differential: 28 polynomials, 7168 coefficients PASS.
- Standalone inverse differential: 31 polynomials, 7936 coefficients PASS.
- Pipelined roundtrip: 30 polynomials; 7680 Python forward comparisons and 7680 Python/final roundtrip comparisons PASS.
- Scheduler, scaler, control/reset, M2.1/M2.2, M3.1/M3.2, legacy NTT/INTT/roundtrip/poly/basemul, Python selftests, 13 foundation tests, and 5 comparator tests PASS.

Commands used were the four new `run_intt_*`/`run_ntt_intt_pipe_roundtrip.sh`
scripts, existing `run_ntt_scheduler_pipe.sh`, `run_ntt_core_pipe.sh`,
`run_m2_2_regression.sh`, legacy NTT/INTT/poly/basemul runners, and Python
selftest/unittest commands, all under 30-90 second shell timeouts.

The full inverse core is constant-cycle at 1090 cycles from accepted start to
public done in the tested interface. M2.3b server synthesis remains pending.
No synthesis timing, Fmax, post-route performance, final ML-KEM KAT, or FIPS
compliance claim is made.
