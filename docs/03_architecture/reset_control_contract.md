# M1 v0.1 Reset and Control Contract

## Reset

Internal `rst_n` is synchronous active-low and sampled on `posedge clk`:

```verilog
always @(posedge clk) begin
    if (!rst_n) ...
```

Reset clears control state, FSM state, counters, valid bits, pending-command
state, error/status state, and metadata-valid state. Reset does not clear SRAM,
coefficient memories, payload registers, arithmetic pipeline data, keys, or
ciphertext storage. Data is meaningful only when its associated valid/ownership
state is asserted.

Reset deassertion does not create a transaction. Internal valid pipelines must
be empty on the first active cycle. External asynchronous reset, if required by
integration, must terminate at a synchronizing wrapper outside these contracts.

## Control and completion

Commands are accepted through `req_valid && req_ready`. Operation latency and
memory traffic are deterministic for public parameters. Secret-dependent early
exit is prohibited. Controllers must not inspect invalid payload data.

`done` or response-valid may assert only after the final write clock edge has
committed the final coefficient and all metadata is aligned. A new command may
be accepted according to the documented engine overlap rule; the baseline
single-operation controller accepts no second command while occupied.
