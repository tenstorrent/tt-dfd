// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_debug_signals_change
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
   parameter DEBUG_SIGNAL_WIDTH = 64
)
(
   input  logic clock,
   input  logic reset_n,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_change_mask,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   output logic debug_signals_change_match
);

  logic debug_signals_change_match_next;
  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals_with_change_mask_dly;
  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals_with_change_mask;

  assign debug_signals_with_change_mask = debug_signals & debug_signal_change_mask;

  always @(posedge clock)
      if (!reset_n)
       begin
        debug_signals_with_change_mask_dly <= {DEBUG_SIGNAL_WIDTH{1'b0}};
        debug_signals_change_match <= 1'b0;
       end
      else
       begin
        debug_signals_with_change_mask_dly <= debug_signals_with_change_mask;
        debug_signals_change_match <= (debug_signals_with_change_mask_dly != debug_signals_with_change_mask);
       end

endmodule
