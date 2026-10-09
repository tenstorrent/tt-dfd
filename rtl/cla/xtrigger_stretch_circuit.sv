// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module xtrigger_stretch_circuit
import cla_mmr_pkg::*;
import cla_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset_n,
  input  logic                              reset_n_warm_ovrride,

  input  logic   [XTRIGGER_WIDTH-1:0]      xtrigger_in,
  output logic   [XTRIGGER_WIDTH-1:0]      xtrigger_out,

  input ClaCdbgclaxtriggertimestretchMmr_s   Cdbgclaxtriggertimestretch
  );

localparam XTRIGGER_STRETCH_CNTR_WIDTH = 8;

logic [XTRIGGER_WIDTH-1:0][XTRIGGER_STRETCH_CNTR_WIDTH-1:0] xtrigger_stretch_cntr, xtrigger_stretch_cntr_nxt;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_cntr_en;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_cntr_clr;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_in_d1;
logic [XTRIGGER_WIDTH-1:0] xtrigger_stretch_out;
logic [XTRIGGER_WIDTH-1:0][XTRIGGER_STRETCH_CNTR_WIDTH-1:0] xtrigger_stretch;

assign xtrigger_stretch[0] = Cdbgclaxtriggertimestretch.Xtrigger0Stretch;
assign xtrigger_stretch[1] = Cdbgclaxtriggertimestretch.Xtrigger1Stretch;

for (genvar i=0; i<XTRIGGER_WIDTH; i++) begin: stretch_circuit

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

  logic xtrigger_posedge;
  assign xtrigger_posedge = xtrigger_in[i] & ~xtrigger_stretch_in_d1[i];

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

  assign xtrigger_stretch_cntr_en[i] = xtrigger_stretch_out[i] && (xtrigger_stretch[i] != 0);

  assign xtrigger_stretch_cntr_nxt[i] = XTRIGGER_STRETCH_CNTR_WIDTH'(xtrigger_stretch_cntr[i] + 1'b1);

  assign xtrigger_stretch_cntr_clr[i] = xtrigger_posedge || xtrigger_stretch_clear;

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

  assign xtrigger_out[i] = xtrigger_in[i] | xtrigger_stretch_out[i];

end

endmodule
