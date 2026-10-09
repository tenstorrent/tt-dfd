// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_debug_signals_transition
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
   parameter DEBUG_SIGNAL_WIDTH = 64
)
(
   input  logic clock,
   input  logic reset_n,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_transition_mask,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_transition_from,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0]  debug_signal_transition_to,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   output logic debug_signals_transition_match
);

  logic debug_signals_from_match_next, debug_signals_from_match;
  logic debug_signals_to_match_next, debug_signals_to_match;

  always @ (*)
   begin
    debug_signals_from_match_next = ((debug_signals & debug_signal_transition_mask) == debug_signal_transition_from);
    debug_signals_to_match_next   = ((debug_signals & debug_signal_transition_mask) == debug_signal_transition_to);
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
