`timescale 1ns/1ps
// The direct-context test performs irregular absorb and repeated squeeze for
// both SHAKE modes. Keep this named top as the M5 incremental-equivalence gate.
module tb_shake_incremental_equivalence;
  tb_keccak_sponge_ctx test();
endmodule
