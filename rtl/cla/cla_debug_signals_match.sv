// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_debug_signals_match
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
   parameter DEBUG_SIGNAL_WIDTH = 128
)
(
   input  logic clock,
   input  logic reset_n,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_match,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_mask,
   input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   output logic debug_signals_positive_match,
   output logic debug_signals_negative_match
);

  logic debug_signals_positive_match_next;

  always @ (*)
    debug_signals_positive_match_next = ((debug_signals & debug_signal_mask) == debug_signal_match);

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
