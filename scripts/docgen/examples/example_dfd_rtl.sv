/*
This module is for CLA demonstration, and has no function
*/

module my_module
  import example_dfd_pkg::*;
  import dbm_pkg::*;
(
  input   logic                   clk,
  input   logic                   reset_n,

  // L0 ID 0
  input logic [15:0] hw0,hw1,hw2,hw3,hw4,hw5,hw6,hw7,

  // L0 ID 1
  input logic [15:0] hw8,hw9,hw10,hw11,hw12,hw13,hw14,hw15,
);

//Debug mux outputs
logic [63:0]  dbm_out_l0_0;
logic [63:0]  dbm_out_l0_1;
logic [63:0]  dbm_out_l1;

//Debug mux select CSRs
DbgMuxSelCsr_s  CrCsrCdbgmuxsel;

// FineGrainTimeSignal
logic [7:0] FineGrainTime;

// Misc Int. Signal
logic [2:0] debug_clken;


//Instantiate Debug Bus Mux
debug_bus_mux_new #(
    .LANE_WIDTH(16),
    .NUM_INPUT_LANES(8),
    .DEBUG_MUX_ID(0)
) debug_bus_mux_l0_0 (
    .clk(clk),
    .clkte(1'b0),
    .reset_n(reset_n),
    .debug_signals_in({hw7, hw6, hw5, hw4, hw3, hw2, hw1, hw0}),
    .debug_bus_out(debug_bus_l0_0),
    .debug_clken(debug_clken[0]),
    .DbgMuxSelCsr(CrCsrCdbgmuxsel)
);

debug_bus_mux_new #(
    .LANE_WIDTH(16),
    .NUM_INPUT_LANES(8),
    .DEBUG_MUX_ID(1)
) debug_bus_mux_l0_1 (
    .clk(clk),
    .clkte(1'b0),
    .reset_n(reset_n),
    .debug_signals_in({hw15, hw14, hw13, hw12, hw11, hw10, hw9, hw08}),
    .debug_bus_out(debug_bus_l0_1),
    .debug_clken(debug_clken[1]),
    .DbgMuxSelCsr(CrCsrCdbgmuxsel)
);

debug_bus_mux_new #(
    .LANE_WIDTH(16),
    .NUM_INPUT_LANES(9),
    .DEBUG_MUX_ID(2)
) debug_bus_mux_l1 (
    .clk(clk),
    .clkte(1'b0),
    .reset_n(reset_n),
    .debug_signals_in({8'b0,FineGrainTime,debug_bus_l0_1, debug_bus_l0_0}),
    .debug_bus_out(dbm_out_l1),
    .debug_clken(debug_clken[2]),
    .DbgMuxSelCsr(CrCsrCdbgmuxsel)
);  

//Instantiate CLA
core_logic_analyzer cla(
  .clock                (clk),
  .reset_n              (reset_n),
  .debug_signals        (dbm_out_l1)
  //...
);

endmodule

