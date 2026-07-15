# M8.4 Implicit-Rejection Development Report

The modified smoke ciphertext returns the exact 32 bytes of `J(z||c_modified)`;
the test does not merely check inequality.  No reject flag is a module port,
and accumulator/mask are cleared before output.  Broader 32-case mutation
coverage is still required for closure.
