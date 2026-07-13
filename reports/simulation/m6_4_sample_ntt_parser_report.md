# M6.4 SampleNTT Parser Report

Eight synthetic rejection streams pass 2,048 ordered coefficient comparisons.
They cover both/one/neither accepted, 3328, 3329, 4095, alternating rejection,
and the coefficient-255 suppression edge. The two-entry queue holds stable
under the ready/valid contract and outputs canonical NTT-domain coefficients.
Rejected values are never reduced modulo q.
