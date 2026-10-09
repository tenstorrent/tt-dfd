
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

module xtrigger_stretch_circuit
import cla_mmr_pkg::*;
import cla_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset_n,
  input  logic                              reset_n_warm_ovrride,

  input  logic   [XTRIGGER_WIDTH-1:0]      xtrigger_in,
  output logic   [XTRIGGER_WIDTH-1:0]      xtrigger_out,

  // Registers
  input ClaCdbgclaxtriggertimestretchMmr_s   Cdbgclaxtriggertimestretch
  );

// Stretch width
localparam XTRIGGER_STRETCH_CNTR_WIDTH = 8;

// Stretch logic
logic [XTRIGGER_WIDTH-1:0][XTRIGGER_STRETCH_CNTR_WIDTH-1:0] xtrigger_stretch_cntr, xtrigger_stretch_cntr_nxt;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_cntr_en;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_cntr_clr;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_in_d1;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_out;
logic [XTRIGGER_WIDTH-1:0][XTRIGGER_STRETCH_CNTR_WIDTH-1:0] xtrigger_stretch;

// Stretch control signals
assign xtrigger_stretch[0] = Cdbgclaxtriggertimestretch.Xtrigger0Stretch;
assign xtrigger_stretch[1] = Cdbgclaxtriggertimestretch.Xtrigger1Stretch;

// Stretch circuit
for (genvar i=0; i<XTRIGGER_WIDTH; i++) begin: stretch_circuit
  // Posedge detection
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) xtrigger_in_d1_ff (
      .clk   (clock),
      .rst_n (reset_n),
      .en    ('1),
      .in    (xtrigger_in[i]),
      .out   (xtrigger_stretch_in_d1[i])
  );

  // Detect new pulse (posedge)
  logic xtrigger_posedge;
  assign xtrigger_posedge = xtrigger_in[i] & ~xtrigger_stretch_in_d1[i];

  // Stretch output control logic
  logic xtrigger_stretch_clear;
  logic xtrigger_stretch_d_next;
  assign xtrigger_stretch_clear = (xtrigger_stretch_cntr[i] == xtrigger_stretch[i]) && (xtrigger_stretch[i] != 0);
  assign xtrigger_stretch_d_next = xtrigger_posedge | (xtrigger_stretch_out[i] & ~xtrigger_stretch_clear);

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) xtrigger_stretch_out_ff (
      .clk   (clock),
      .rst_n (reset_n),
      .en    ('1),
      .in    (xtrigger_stretch_d_next),
      .out   (xtrigger_stretch_out[i])
  );

  // Enable counter when stretch is active
  assign xtrigger_stretch_cntr_en[i] = xtrigger_stretch_out[i] && (xtrigger_stretch[i] != 0);

  // Increment counter
  assign xtrigger_stretch_cntr_nxt[i] = XTRIGGER_STRETCH_CNTR_WIDTH'(xtrigger_stretch_cntr[i] + 1'b1);

  // Clear counter when:
  // 1. New pulse arrives (restart stretching)
  // 2. Counter has reached the stretch width (stretch complete)
  assign xtrigger_stretch_cntr_clr[i] = xtrigger_posedge || xtrigger_stretch_clear;

  // Counter
  generic_dff_clr #(
      .WIDTH       ($bits(logic [XTRIGGER_STRETCH_CNTR_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) xtrigger_stretch_cntr_ff (
      .clk   (clock),
      .rst_n (reset_n),
      .en    (xtrigger_stretch_cntr_en[i]),
      .clr   (xtrigger_stretch_cntr_clr[i]),
      .in    (xtrigger_stretch_cntr_nxt[i]),
      .out   (xtrigger_stretch_cntr[i])
  );

  // Stretch output
  assign xtrigger_out[i] = xtrigger_in[i] | xtrigger_stretch_out[i];

end

endmodule
