# M8.5 Unified Top Development Report

`run_mlkem768_top.sh` passes one actual public KeyGen -> Encaps -> Decaps chain:
3,584 KeyGen bytes, 1,120 Encaps bytes, and 32 Decaps bytes match Python, with
the frozen typed record order.  ZEROIZE mode currently has no top-owned payload
to erase and does not reach residual M5--M7 state; it is therefore not closure
evidence.
