// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_debug_signals_ones_count
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
   parameter DEBUG_SIGNAL_WIDTH = 64
)
(
   input  logic clock,
   input  logic reset_n,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_ones_count_mask,
   input  DebugsignalOnescountvalueMmr_s DebugsignalOnescountvalueMmr,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   output logic debug_signals_ones_count_match
);

  logic [$clog2(DEBUG_SIGNAL_WIDTH):0] debug_signals_ones_count;
  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals_filtered;
  logic debug_signals_ones_count_match_next;

  integer i;
  assign debug_signals_filtered = debug_signals & debug_signal_ones_count_mask;

  always @(*)
   begin
      debug_signals_ones_count = ($clog2(DEBUG_SIGNAL_WIDTH)+1)'(debug_signals_filtered[0]);
      for (i=1;i<DEBUG_SIGNAL_WIDTH;i=i+1)
        debug_signals_ones_count = ($clog2(DEBUG_SIGNAL_WIDTH)+1)'(debug_signals_ones_count + ($clog2(DEBUG_SIGNAL_WIDTH)+1)'(debug_signals_filtered[i]));
   end

  always @ (*)
   begin
    debug_signals_ones_count_match_next = (debug_signals_ones_count ==  ($clog2(DEBUG_SIGNAL_WIDTH)+1)'(DebugsignalOnescountvalueMmr.Value));
   end

  always @(posedge clock)
      if (!reset_n)
       debug_signals_ones_count_match <= 1'b0;
      else
       debug_signals_ones_count_match <= debug_signals_ones_count_match_next;

endmodule
