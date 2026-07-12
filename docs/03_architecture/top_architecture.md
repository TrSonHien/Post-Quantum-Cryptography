# Top Architecture

Use this file for the ML-KEM-768 top-level hardware architecture.

Planned topics:

- KeyGen datapath
- Encaps datapath
- Decaps datapath
- Shared control FSM
- Shared arithmetic, NTT, Keccak, sampler, codec, and memory resources

## M1 v0.1 integration rules

Major engines communicate through registered valid/ready request and response
channels. Canonical normal-domain coefficients are used at architectural
boundaries; NTT-domain objects carry explicit `*_hat` naming and metadata.
Montgomery values cannot cross an engine boundary.

Control is synchronously reset by active-low `rst_n`; payload storage and
memories are not reset. A controller owns each memory set while an operation is
active. Ownership and domain changes occur only on completed transfers. Engine
completion is visible only after the final architectural write commits.

M1 freezes contracts, not resource sharing between KeyGen, Encaps, and Decaps.
Keccak/sampler/codec topology and whole-accelerator scheduling remain future
milestone work.
