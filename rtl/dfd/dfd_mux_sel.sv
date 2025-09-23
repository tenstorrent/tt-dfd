// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_mux_sel
import dfd_dst_pkg::*;
import dfd_tt_dbm_pkg::*;
import dfd_cla_pkg::*;
#(
	parameter DEBUG_BUS_WIDTH = 64,
	parameter ID_INDEX = 0
)
(
    input logic clk,
    input logic reset_n,
    input logic reset_n_warm_ovrride,

    //Input to debug Bus Mux
    input logic [15:0] hw0,hw1,hw2,hw3,hw4,hw5,hw6,hw7,
    input logic [15:0] hw8,hw9,hw10,hw11,hw12,hw13,hw14,hw15,

    // Cluster clock reference time tick
    input  logic                      Time_Tick,

    // Debug Mux MMR
    input  DbgMuxSelCsr_s 		 DbgMuxSelCsr,

    // Debug Bus
    output [DEBUG_BUS_WIDTH-1:0] debug_bus

);

        // Debug Bus & Debug Bus Mux Signals
		logic [DEBUG_BUS_WIDTH-1:0] debug_bus_l0_0, debug_bus_l0_1, debug_bus_d1;

		// Fine grain timestamping mechanism for core:
		localparam FINE_GRAIN_TSTAMP_COUNTER_WIDTH = 8;
		logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0] FineGrainTime, FineGrainTime_d1;
		logic [FINE_GRAIN_TSTAMP_COUNTER_WIDTH-1:0] FineGrainTStampCounter, FineGrainTStampCounterNext;
		logic debug_signals_diff, Time_Tick_d1;
		logic [2:0] debug_clken;

		// Detecting change in debug bus signal
		generic_dff #(.WIDTH(DEBUG_BUS_WIDTH)) debug_bus_ff (.out(debug_bus_d1), .in(debug_bus), .en(debug_clken[2]), .clk(clk), .rst_n(reset_n));
		assign debug_signals_diff = ((debug_bus[DEBUG_BUS_WIDTH-1:FINE_GRAIN_TSTAMP_COUNTER_WIDTH] ^ debug_bus_d1[DEBUG_BUS_WIDTH-1:FINE_GRAIN_TSTAMP_COUNTER_WIDTH]) != '0);

		// Recording internal fine grain time stamp counter
		assign FineGrainTStampCounterNext = Time_Tick ? '0 : FINE_GRAIN_TSTAMP_COUNTER_WIDTH'(FineGrainTStampCounter + 1'b1);
		// Ensures that the internal counter is reset when the time tick arrived
		generic_dff #(.WIDTH(1)) Time_Tick_ff (.out(Time_Tick_d1), .in(Time_Tick), .en(1'b1), .clk(clk), .rst_n(reset_n));
		// The internal counter will be incremented when the debug clock enable is high, AND its reset will be in sync with the time tick
		generic_dff #(.WIDTH(FINE_GRAIN_TSTAMP_COUNTER_WIDTH)) FineGrainTStampCounter_ff (.out(FineGrainTStampCounter), .in(FineGrainTStampCounterNext), .en(debug_clken[2] | Time_Tick_d1), .clk(clk), .rst_n(reset_n));

		// Updating fine grain time only when the debug bus signals between two clock cycles are different, otherwise retain the same value
		assign FineGrainTime = debug_signals_diff ? FineGrainTStampCounterNext : FineGrainTime_d1;
		generic_dff #(.WIDTH(FINE_GRAIN_TSTAMP_COUNTER_WIDTH)) FineGrainTimeNext_ff (.out(FineGrainTime_d1), .in(FineGrainTime), .en(debug_signals_diff & debug_clken[2]), .clk(clk), .rst_n(reset_n));


		// CLA during warm reset:
		// 1. The action bus will be set to zeroes as the event bus is connected to warm reset instead of the warm reset override signal
		// 2. Need to retain DBM programming, so the DBM will have the override reset
		// 3. Need to retain current node id internal to the Action gen module, so it will use the override reset
		// 4. CR DFD will be receiving the control info from CR MMRs that are hooked to the override reset signal -> saving the context during and after warm reset

		logic [3:0][DEBUG_BUS_WIDTH-1:0]  debug_signals_in;
		generic_dff #(.WIDTH(DEBUG_BUS_WIDTH)) debug_signals_in0_ff (.out(debug_signals_in[0]), .in({hw3, hw2, hw1, hw0}),     .en(debug_clken[0]), .clk(clk), .rst_n(reset_n));
		generic_dff #(.WIDTH(DEBUG_BUS_WIDTH)) debug_signals_in1_ff (.out(debug_signals_in[1]), .in({hw7, hw6, hw5, hw4}),     .en(debug_clken[0]), .clk(clk), .rst_n(reset_n));
		generic_dff #(.WIDTH(DEBUG_BUS_WIDTH)) debug_signals_in2_ff (.out(debug_signals_in[2]), .in({hw11, hw10, hw9, hw8}),   .en(debug_clken[1]), .clk(clk), .rst_n(reset_n));
		generic_dff #(.WIDTH(DEBUG_BUS_WIDTH)) debug_signals_in3_ff (.out(debug_signals_in[3]), .in({hw15, hw14, hw13, hw12}), .en(debug_clken[1]), .clk(clk), .rst_n(reset_n));

		//Instantiate Debug Bus Mux
		dfd_tt_debug_bus_mux #(
			.LANE_WIDTH(16),
			.NUM_INPUT_LANES(8),
			.DEBUG_MUX_ID(ID_INDEX * 3)
		) debug_bus_mux_l0_0 (
			.clk(clk),
			.reset_n(reset_n_warm_ovrride),
			.debug_signals_in({debug_signals_in[1], debug_signals_in[0]}),
			.debug_bus_out(debug_bus_l0_0),
			.debug_clken(debug_clken[0]),
			.DbgMuxSelCsr(DbgMuxSelCsr)
		);

		dfd_tt_debug_bus_mux #(
			.LANE_WIDTH(16),
			.NUM_INPUT_LANES(8),
			.DEBUG_MUX_ID(ID_INDEX * 3 + 1)
		) debug_bus_mux_l0_1 (
			.clk(clk),
			.reset_n(reset_n_warm_ovrride),
			.debug_signals_in({debug_signals_in[3], debug_signals_in[2]}),
			.debug_bus_out(debug_bus_l0_1),
			.debug_clken(debug_clken[1]),
			.DbgMuxSelCsr(DbgMuxSelCsr)
		);

		dfd_tt_debug_bus_mux #(
			.LANE_WIDTH(16),
			.NUM_INPUT_LANES(9),
			.DEBUG_MUX_ID(ID_INDEX * 3 + 2)
		) debug_bus_mux_l1 (
			.clk(clk),
			.reset_n(reset_n_warm_ovrride),
			.debug_signals_in({8'b0,FineGrainTime,debug_bus_l0_1, debug_bus_l0_0}),
			.debug_bus_out(debug_bus),
			.debug_clken(debug_clken[2]),
			.DbgMuxSelCsr(DbgMuxSelCsr)
		);
endmodule

