`timescale 1ns/1ps
// Parameter-sanity helper for the runner. The actual differential checks are
// the self-checking indexed KeyGen/Encaps/Decaps testbenches invoked by
// run_mlkem_internal_chain.sh; this helper does not duplicate their oracle.
module tb_mlkem_internal_chain;
 integer keygen_vectors,encaps_vectors,decaps_vectors,fallback_vectors;
 initial begin
  if(!$value$plusargs("KEYGEN_VECTORS=%d",keygen_vectors))keygen_vectors=2;
  if(!$value$plusargs("ENCAPS_VECTORS=%d",encaps_vectors))encaps_vectors=2;
  if(!$value$plusargs("DECAPS_VECTORS=%d",decaps_vectors))decaps_vectors=4;
  if(!$value$plusargs("FALLBACK_VECTORS=%d",fallback_vectors))fallback_vectors=4;
  if(keygen_vectors<1||encaps_vectors<1||decaps_vectors<1||fallback_vectors!=decaps_vectors)$fatal(1,"invalid reduced internal-chain vector counts");
  $display("PASS internal_chain_parameters keygen=%0d encaps=%0d decaps=%0d fallback=%0d",keygen_vectors,encaps_vectors,decaps_vectors,fallback_vectors);
  $finish;
 end
endmodule
