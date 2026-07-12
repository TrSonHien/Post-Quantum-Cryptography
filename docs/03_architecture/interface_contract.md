# M1 v0.1 Interface Contract

## Engine transaction interface

Major engines use decoupled request and response channels:

```text
request:  req_valid, req_ready, req_payload, req_metadata
response: rsp_valid, rsp_ready, rsp_payload, rsp_metadata, rsp_error
```

A transfer occurs only on `valid && ready`. Producers hold valid, payload, and
metadata stable until transfer. Consumers may backpressure. No major-engine
boundary may create a long combinational ready path; register slices or skid
buffers are required where timing analysis demands them.

An accepted command is neither repeated nor discarded. A single-operation
engine may expose `busy` as status, but `busy` is not a transfer handshake.
Completion is a response transaction. If a compatibility wrapper exposes
`done`, it is a one-cycle pulse derived only after the final architectural write
has committed and must not replace `rsp_valid/rsp_ready` internally.

## Fixed-latency internal lanes

Valid-only is permitted inside a pipeline only when downstream acceptance is
guaranteed by construction. Such a lane has no backpressure and must document:

- latency `L` from accepted `in_valid` to `out_valid`;
- initiation interval `II`;
- payload and metadata fields delayed exactly `L` cycles;
- behavior of invalid cycles;
- reset flushing behavior.

The NTT butterfly lane baseline has `II=1`; exact arithmetic latency is selected
and verified in M3. Multi-lane variants are deferred to M3.

## Naming and widths

- active-low synchronous reset: `rst_n`;
- handshakes: `<channel>_valid`, `<channel>_ready`;
- memory requests: `<bank>_rd_en`, `<bank>_rd_addr`, `<bank>_wr_en`,
  `<bank>_wr_addr`, `<bank>_wr_data`;
- registered read response: `<bank>_rd_valid`, `<bank>_rd_data`;
- NTT-domain data: names ending in `_hat`;
- byte arrays: byte 0 is the lowest addressed byte;
- coefficient indices and polynomial/vector identifiers travel as metadata.

## Error behavior

Protocol errors, illegal commands, and memory collisions are assertions during
unit verification. Architecturally detectable input/type failures set
`rsp_error`; no partial successful result may be reported.

## M2.1 reusable boundary primitive

`rtl/control/rv_register_slice.v` implements the approved one-entry registered
valid/ready boundary. It may be instantiated between engines or used as the
building block for deeper buffering. It does not define an engine command.
