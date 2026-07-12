# M1 v0.1 Pipeline Metadata and Latency Contract

## Required metadata

Every pipelined polynomial operation carries, as applicable:

```text
valid, operation_id, polynomial_id, vector_index, coefficient_index,
bank, address, stage, butterfly_index, zeta_index, domain, last, error
```

Metadata and payload are one transaction. Each registered stage delays both by
one cycle. Derived write address, write enable, bank select, domain, and `last`
must be generated before or beside the payload and pass through the same number
of registers.

## Latency rules

- Each module publishes latency `L` and initiation interval `II` in its contract.
- Fixed latency is measured from input transfer to output-valid presentation.
- A one-cycle synchronous memory read contributes one explicit pipeline cycle.
- Backpressured engine channels may extend wall-clock latency, but never reorder
  operation IDs or alter internal fixed-lane latency.
- Invalid pipeline slots must not write memory or advance completion state.
- Reset clears all valid/last/error metadata; payload values are don't-care.
- `last` identifies the final architectural output, not merely the final issued
  arithmetic operation.
- Completion occurs only after `last && write_commit`.

## Baseline NTT transaction timeline

For each issued butterfly: cycle `t` registers two source-bank read requests;
cycle `t+1` presents operands and valid metadata; arithmetic then advances
through its documented `L_bf` stages; the destination write commits at
`t+1+L_bf`. Consecutive butterflies issue every cycle (`II=1`). Stage swapping
waits until the final write of that stage commits.
