// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_xtrigger_stretch_circuit
import dfd_cla_csr_pkg::*;
import dfd_cla_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset_n,
  input  logic                              reset_n_warm_ovrride,

  input  logic   [XTRIGGER_WIDTH-1:0]      xtrigger_in, 
  output logic   [XTRIGGER_WIDTH-1:0]      xtrigger_out,

  // Registers
  input CrCdbgclaxtriggertimestretchCsr_s   CrCsrCdbgclaxtriggertimestretch
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
assign xtrigger_stretch[0] = CrCsrCdbgclaxtriggertimestretch.Xtrigger0Stretch;
assign xtrigger_stretch[1] = CrCsrCdbgclaxtriggertimestretch.Xtrigger1Stretch;

// Stretch circuit
for (genvar i=0; i<XTRIGGER_WIDTH; i++) begin: stretch_circuit
  // Posedge detection
  generic_dff #(.WIDTH(1)) xtrigger_in_d1_ff (.out(xtrigger_stretch_in_d1[i]), .in(xtrigger_in[i]), .clk(clock), .rst_n(reset_n), .en(1'b1));

  // Detect new pulse (posedge)
  logic xtrigger_posedge;
  assign xtrigger_posedge = xtrigger_in[i] & ~xtrigger_stretch_in_d1[i];

  // Stretch output control logic
  logic xtrigger_stretch_clear;
  logic xtrigger_stretch_d_next;
  assign xtrigger_stretch_clear = (xtrigger_stretch_cntr[i] == xtrigger_stretch[i]) && (xtrigger_stretch[i] != 0);
  assign xtrigger_stretch_d_next = xtrigger_posedge | (xtrigger_stretch_out[i] & ~xtrigger_stretch_clear);
  
  generic_dff_clr #(.WIDTH(1)) xtrigger_stretch_out_ff (
    .out(xtrigger_stretch_out[i]), 
    .in(xtrigger_stretch_d_next), 
    .clr(1'b0), 
    .en(1'b1), 
    .clk(clock), 
    .rst_n(reset_n)
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
  generic_dff_clr #(.WIDTH(XTRIGGER_STRETCH_CNTR_WIDTH)) xtrigger_stretch_cntr_ff (
    .out(xtrigger_stretch_cntr[i]), 
    .in(xtrigger_stretch_cntr_nxt[i]), 
    .clr(xtrigger_stretch_cntr_clr[i]), 
    .en(xtrigger_stretch_cntr_en[i]), 
    .clk(clock), 
    .rst_n(reset_n)
  );  

  // Stretch output
  assign xtrigger_out[i] = xtrigger_in[i] | xtrigger_stretch_out[i];

end

endmodule
