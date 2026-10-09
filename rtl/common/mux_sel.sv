// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module mux_sel
import dst_pkg::*;
import tt_dbm_pkg::*;
import cla_pkg::*;
#(
	parameter DEBUG_BUS_WIDTH = 64,
	parameter NUM_INPUT_LANES = 8,
	parameter LANE_WIDTH = 8,
	parameter ID_INDEX = 0
)
(
    input logic clk,
    input logic i_reset_n,
	input logic i_test_icg_en,
    input logic reset_n_warm_ovrride,

    input logic [NUM_INPUT_LANES-1:0][LANE_WIDTH-1:0] debug_signals_in,

    input  logic                      Time_Tick,

    input  DbgMuxSelMmr_s 		 DbgMuxSelMmr,

    output [DEBUG_BUS_WIDTH-1:0] debug_bus

);

		logic [DEBUG_BUS_WIDTH-1:0] debug_bus_l0_0, debug_bus_l0_1, debug_bus_d1;

		localparam FINE_GRAIN_TSTAMP_COUNTER_WIDTH = 8;
		localparam NUM_OUTPUT_LANES = (DEBUG_BUS_WIDTH/LANE_WIDTH);
		logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0] FineGrainTime, FineGrainTime_d1;
		logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0] FineGrainTStampCounter, FineGrainTStampCounterNext;
		logic debug_signals_diff, Time_Tick_d1;
		logic debug_clken;

		generic_dff #(
		    .WIDTH       ($bits(logic [DEBUG_BUS_WIDTH-1:0])),
		    .RESET_VALUE ('0)
		) debug_bus_ff (
		    .clk   (clk),
		    .rst_n (i_reset_n),
		    .en    (debug_clken),
		    .in    (debug_bus),
		    .out   (debug_bus_d1)
		);
		assign debug_signals_diff = ((debug_bus[DEBUG_BUS_WIDTH-1:FINE_GRAIN_TSTAMP_COUNTER_WIDTH] ^ debug_bus_d1[DEBUG_BUS_WIDTH-1:FINE_GRAIN_TSTAMP_COUNTER_WIDTH]) != '0);

		assign FineGrainTStampCounterNext = Time_Tick ? '0 : FINE_GRAIN_TSTAMP_COUNTER_WIDTH'(FineGrainTStampCounter + 1'b1);

		generic_dff #(
		    .WIDTH       ($bits(logic)),
		    .RESET_VALUE ('0)
		) Time_Tick_ff (
		    .clk   (clk),
		    .rst_n (i_reset_n),
		    .en    ('1),
		    .in    (Time_Tick),
		    .out   (Time_Tick_d1)
		);

		generic_dff #(
		    .WIDTH       ($bits(logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0])),
		    .RESET_VALUE ('0)
		) FineGrainTStampCounter_ff (
		    .clk   (clk),
		    .rst_n (i_reset_n),
		    .en    (debug_clken | Time_Tick_d1),
		    .in    (FineGrainTStampCounterNext),
		    .out   (FineGrainTStampCounter)
		);

		assign FineGrainTime = debug_signals_diff ? FineGrainTStampCounterNext : FineGrainTime_d1;
		generic_dff #(
		    .WIDTH       ($bits(logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0])),
		    .RESET_VALUE ('0)
		) FineGrainTimeNext_ff (
		    .clk   (clk),
		    .rst_n (i_reset_n),
		    .en    (debug_signals_diff & debug_clken),
		    .in    (FineGrainTime),
		    .out   (FineGrainTime_d1)
		);

		logic [NUM_INPUT_LANES-1:0][LANE_WIDTH-1:0]  debug_signals_in_d1;
		generic_dff #(
		    .WIDTH       ($bits(logic [NUM_INPUT_LANES*LANE_WIDTH-1:0])),
		    .RESET_VALUE ('0)
		) debug_signals_in1_ff (
		    .clk   (clk),
		    .rst_n (i_reset_n),
		    .en    (debug_clken),
		    .in    (debug_signals_in),
		    .out   (debug_signals_in_d1)
		);

		logic [NUM_INPUT_LANES:0][LANE_WIDTH-1:0] debug_signals_in_mux;

		assign debug_signals_in_mux = DbgMuxSelMmr.FineGrainTime ? {debug_signals_in_d1, LANE_WIDTH'(FineGrainTime)} :
																{LANE_WIDTH'(0), debug_signals_in_d1};

		tt_debug_bus_mux #(
			.NUM_INPUT_LANES(NUM_INPUT_LANES + 1),
			.LANE_WIDTH(LANE_WIDTH),
			.DEBUG_MUX_OUTPUT_WIDTH(DEBUG_BUS_WIDTH),
			.DEBUG_MUX_ID(ID_INDEX)
		) debug_bus_mux (
			.clk(clk),
			.reset_n(reset_n_warm_ovrride),
			.test_icg_en(i_test_icg_en),
			.debug_signals_in(debug_signals_in_mux),
			.debug_bus_out(debug_bus),
			.debug_clken(debug_clken),
			.DbgMuxSelMmr(DbgMuxSelMmr)
		);
endmodule
