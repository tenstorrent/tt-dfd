module dfd_cla_debug_signals_transition
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input  logic clock,
   input  logic reset_n,
   input  DebugsignalTransitionmaskCsr_s  DebugsignalTransitionmaskCsr,
   input  DebugsignalTransitionfromCsr_s  DebugsignalTransitionfromCsr,
   input  DebugsignalTransitiontoCsr_s    DebugsignalTransitiontoCsr,
   input  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
   output logic debug_signals_transition_match 
);

 
  logic debug_signals_from_match_next, debug_signals_from_match;
  logic debug_signals_to_match_next, debug_signals_to_match;
  //Mask & Match Logic
  always @ (*)
   begin
    debug_signals_from_match_next = ((debug_signals & DebugsignalTransitionmaskCsr.Value) == DebugsignalTransitionfromCsr.Value);
    debug_signals_to_match_next   = ((debug_signals & DebugsignalTransitionmaskCsr.Value) == DebugsignalTransitiontoCsr.Value);
   end

  always @(posedge clock)
      if (!reset_n)
        begin
          debug_signals_from_match <= 1'b0;
          debug_signals_to_match <= 1'b0;
          debug_signals_transition_match <= 1'b0;
        end
      else
        begin 
          debug_signals_from_match <= debug_signals_from_match_next ;
          debug_signals_to_match <= debug_signals_to_match_next ;
          debug_signals_transition_match <= debug_signals_from_match && debug_signals_to_match_next;
        end
endmodule
     

