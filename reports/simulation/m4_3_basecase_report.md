# M4.3 BaseCaseMultiply Report

The pipeline uses four parallel exact products, one exact gamma product, and
two modular-add lanes. Product and metadata delays align transaction N at the
final add. Measured latency is 9 cycles and II=1. Public gamma is a canonical
mathematical residue, not a Montgomery constant.

`timeout 60s ./sim/scripts/run_basecase_mul_pipe.sh` PASS: 50,000 independent
Python BaseCaseMultiply tuples, including boundary gamma values and full-rate
traffic. All 100,000 output coefficients were canonical and bit-exact.
