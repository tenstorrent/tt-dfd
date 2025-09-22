// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_cla_debug_signals_match
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input  logic clock,
   input  logic reset_n,
   input  DebugsignalmatchCsr_s  DebugsignalmatchCsr,
   input  DebugsignalmaskCsr_s   DebugsignalmaskCsr,
   input logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
   output logic debug_signals_positive_match,
   output logic debug_signals_negative_match 
);
   
  logic debug_signals_positive_match_next;
  //Mask & Match Logic
  always @ (*)
    debug_signals_positive_match_next = ((debug_signals & DebugsignalmaskCsr.Value) == DebugsignalmatchCsr.Value);

  always @(posedge clock)
      if (!reset_n)
        begin
          debug_signals_positive_match <= 1'b0;
          debug_signals_negative_match <= 1'b1;
        end
      else
        begin 
          debug_signals_positive_match <= debug_signals_positive_match_next;
          debug_signals_negative_match <= ~debug_signals_positive_match_next;
        end
endmodule
     

