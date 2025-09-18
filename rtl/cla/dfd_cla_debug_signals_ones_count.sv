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

module dfd_cla_debug_signals_ones_count
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input  logic clock,
   input  logic reset_n,
   input  DebugsignalOnescountmaskCsr_s DebugsignalOnescountmaskCsr,
   input  DebugsignalOnescountvalueCsr_s DebugsignalOnescountvalueCsr,
   input  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
   output logic debug_signals_ones_count_match 
);

 
  logic [$clog2(DEBUG_SIGNALS_WIDTH):0] debug_signals_ones_count;
  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals_filtered;
  logic debug_signals_ones_count_match_next;

  // Mask and Count...
  integer i;
  assign debug_signals_filtered = debug_signals & DebugsignalOnescountmaskCsr.Value;

  always @(*)
   begin
      debug_signals_ones_count = ($clog2(DEBUG_SIGNALS_WIDTH)+1)'(debug_signals_filtered[0]); 
      for (i=1;i<DEBUG_SIGNALS_WIDTH;i=i+1)
        debug_signals_ones_count = ($clog2(DEBUG_SIGNALS_WIDTH)+1)'(debug_signals_ones_count + ($clog2(DEBUG_SIGNALS_WIDTH)+1)'(debug_signals_filtered[i])); 
   end
  //.. and see if count matches expected value.
  always @ (*)
   begin
    debug_signals_ones_count_match_next = (debug_signals_ones_count ==  ($clog2(DEBUG_SIGNALS_WIDTH)+1)'(DebugsignalOnescountvalueCsr.Value));
   end

  always @(posedge clock)
      if (!reset_n)
       debug_signals_ones_count_match <= 1'b0;
      else
       debug_signals_ones_count_match <= debug_signals_ones_count_match_next;
        
endmodule
     

