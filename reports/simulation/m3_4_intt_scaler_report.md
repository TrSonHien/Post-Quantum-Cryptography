# M3.4 Two-Lane Final INTT Scaler Report

## Architecture

`intt_scaler_pipe` contains two parallel `mod_mul_pipe` lanes and accepts one
coefficient pair per cycle. Each lane multiplies by 512. Since
`512 = 3303 * R mod 3329`, Montgomery multiplication computes
`x * 512 * R^-1 = x * 3303 mod 3329`, the required normal-domain inverse
scale. Legacy 1441 equals `3303 * R^2 mod q` and is not used here.

The scaler reads the inverse final layout `b=i7,rm7`, writes the same logical
layout into the alternate role, and swaps once after committed-write drain.
Logical result readback is therefore canonical standard order.

## Timing and counts

The multiplier output/metadata latency is 4 cycles. Including one-cycle RAM
read and the destination write edge, scaler issue-to-write commit is 6 cycles.
Measured full-core event cycles are: first issue 955, final issue 1082, final
write commit 1088, final role swap 1089, and public done 1090.

Per transform: 128 pair requests, 256 coefficient inputs, 256 multiplier
outputs, 128 pair writes, one scaler role swap, and one completion event.

## Verification

The standalone TB checks directed values 0, 1, q-1, 512, 1441 and every
canonical coefficient value across both lanes. It passed 3336 coefficient
checks, exact latency/metadata alignment, canonical range, II=1, final marker,
lane independence, and reset-valid flush. Integrated counts and final layout
also pass all 31 standalone inverse vectors. No synthesis or Fmax claim is made.
