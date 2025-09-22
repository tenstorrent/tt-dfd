// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_cla_debug_signals_change
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input  logic clock,
   input  logic reset_n,
   input DebugsignalchangeCsr_s  DebugsignalchangeCsr, 
   input  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
   output logic debug_signals_change_match 
);

 
  logic debug_signals_change_match_next;
  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals_with_change_mask_dly;
  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals_with_change_mask;
 
  // Mask and Look for change...
  assign debug_signals_with_change_mask = debug_signals & DebugsignalchangeCsr.Mask;

  always @(posedge clock)
      if (!reset_n)
       begin 
        debug_signals_with_change_mask_dly <= {DEBUG_SIGNALS_WIDTH{1'b0}};
        debug_signals_change_match <= 1'b0;
       end
      else
       begin 
        debug_signals_with_change_mask_dly <= debug_signals_with_change_mask;
        debug_signals_change_match <= (debug_signals_with_change_mask_dly != debug_signals_with_change_mask);
       end
        
endmodule
     
