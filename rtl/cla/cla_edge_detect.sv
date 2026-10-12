// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_edge_detect
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
   parameter DEBUG_SIGNAL_WIDTH = 128
)
(
   input  logic clock,
   input  logic reset_n,
   input  DebugsignalEdgedetectcfgMmr_s  DebugsignalEdgedetectcfgMmr,
   input  logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   output logic [1:0] debug_signal_edge_detect
);

   localparam MAX_DEBUG_SIGNAL_WIDTH = 128;

  logic  signal4edge_detect_0;
  logic  signal4edge_detect_0_dly1;
  logic  signal4edge_detect_1;
  logic  signal4edge_detect_1_dly1;
  logic [DEBUG_SIGNAL_WIDTH-1:0] signal0_select_qualified_debug_signals;
  logic [DEBUG_SIGNAL_WIDTH-1:0] signal1_select_qualified_debug_signals;

  genvar i;
  generate
     for(i=0;i<DEBUG_SIGNAL_WIDTH;i=i+1) begin : gen_signal_select
        assign signal0_select_qualified_debug_signals[i] = (DebugsignalEdgedetectcfgMmr.Signal0Select==$clog2(MAX_DEBUG_SIGNAL_WIDTH)'(i))? debug_signals[i]:1'b0;
        assign signal1_select_qualified_debug_signals[i] = (DebugsignalEdgedetectcfgMmr.Signal1Select==$clog2(MAX_DEBUG_SIGNAL_WIDTH)'(i))? debug_signals[i]:1'b0;
     end
  endgenerate
  assign signal4edge_detect_0 = |signal0_select_qualified_debug_signals;
  assign signal4edge_detect_1 = |signal1_select_qualified_debug_signals;

  always @(posedge clock)
      if (!reset_n)
        begin

         debug_signal_edge_detect[1:0] <= 2'b0;
         signal4edge_detect_0_dly1 <= 1'b0;
         signal4edge_detect_1_dly1 <= 1'b0;
        end
      else
        begin
         debug_signal_edge_detect[0] <= (DebugsignalEdgedetectcfgMmr.PosEdgeSignal0 == 1)?
                                     (signal4edge_detect_0_dly1==0 && signal4edge_detect_0==1 ):
                                     (signal4edge_detect_0_dly1==1 && signal4edge_detect_0==0 );
         debug_signal_edge_detect[1] <= (DebugsignalEdgedetectcfgMmr.PosEdgeSignal1 == 1)?
                                     (signal4edge_detect_1_dly1==0 && signal4edge_detect_1==1 ):
                                     (signal4edge_detect_1_dly1==1 && signal4edge_detect_1==0 );
         signal4edge_detect_0_dly1 <= signal4edge_detect_0;
         signal4edge_detect_1_dly1 <= signal4edge_detect_1;
        end

endmodule
