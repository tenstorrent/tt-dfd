// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************

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
     

