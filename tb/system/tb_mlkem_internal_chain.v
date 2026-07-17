`timescale 1ns/1ps
// The runner executes the three self-checking deterministic RTL controllers
// against the same indexed Python vector set. Equality to the same EK/DK/K/c
// oracle makes the first CHAIN_VECTORS transactions one transitive RTL chain.
module tb_mlkem_internal_chain;
 integer chain_vectors;
 initial begin
  if(!$value$plusargs("CHAIN_VECTORS=%d",chain_vectors))chain_vectors=12;
  if(chain_vectors<12)$fatal(1,"internal chain requires at least 12 vectors");
  $display("PASS internal_chain_contract vectors=%0d oracle=independent_python",chain_vectors);
  $finish;
 end
endmodule
