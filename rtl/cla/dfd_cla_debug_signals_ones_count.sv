// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

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
     

