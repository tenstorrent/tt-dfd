// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_debug_signal_shift_mux 
import dfd_cla_csr_pkg::*;
import dfd_cla_pkg::*;
#(
  parameter DEBUG_MUX_OUTPUT_WIDTH = 64,
             LANE_WIDTH             = 8, 
             NUM_OUTPUT_LANES       = (DEBUG_MUX_OUTPUT_WIDTH/LANE_WIDTH)
)
(
  input  logic                              clock,
  input  logic                              reset_n,
  input  logic                              reset_n_warm_ovrride,
  input  logic [DEBUG_MUX_OUTPUT_WIDTH-1:0] debug_signals_in,

  output logic [DEBUG_MUX_OUTPUT_WIDTH-1:0] debug_signals_out,

  // Registers
  input CrCdbgsignaldelaymuxselCsr_s        DebugSignalDelayMuxsel
  );

localparam MUX_SEL_WIDTH = 2;

// Mux control signals
logic [NUM_OUTPUT_LANES-1:0][MUX_SEL_WIDTH-1:0] debug_signal_shift_mux_sel;

// Lane signals
logic [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_signals_per_lane, debug_signals_per_lane_d1, debug_signals_per_lane_d2, debug_signals_per_lane_d3;
logic [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_signals_per_lane_out;

// Mux control signals
assign debug_signal_shift_mux_sel[0] = DebugSignalDelayMuxsel.Muxselseg0;
assign debug_signal_shift_mux_sel[1] = DebugSignalDelayMuxsel.Muxselseg1;
assign debug_signal_shift_mux_sel[2] = DebugSignalDelayMuxsel.Muxselseg2;
assign debug_signal_shift_mux_sel[3] = DebugSignalDelayMuxsel.Muxselseg3;
assign debug_signal_shift_mux_sel[4] = DebugSignalDelayMuxsel.Muxselseg4;
assign debug_signal_shift_mux_sel[5] = DebugSignalDelayMuxsel.Muxselseg5;
assign debug_signal_shift_mux_sel[6] = DebugSignalDelayMuxsel.Muxselseg6;
assign debug_signal_shift_mux_sel[7] = DebugSignalDelayMuxsel.Muxselseg7;

// Shifted debug signals
for (genvar i=0; i<NUM_OUTPUT_LANES; i++) begin: lane_control_signals
  assign debug_signals_per_lane[i] = debug_signals_in[((i+1)*LANE_WIDTH-1):i*LANE_WIDTH];

  generic_dff #(.WIDTH(LANE_WIDTH)) debug_signals_per_lane_ff_d1 (.out(debug_signals_per_lane_d1[i]), .in(debug_signals_per_lane[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(LANE_WIDTH)) debug_signals_per_lane_ff_d2 (.out(debug_signals_per_lane_d2[i]), .in(debug_signals_per_lane_d1[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(LANE_WIDTH)) debug_signals_per_lane_ff_d3 (.out(debug_signals_per_lane_d3[i]), .in(debug_signals_per_lane_d2[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
end

// MUX logic at the output to select the correct debug signals with appropriate delay
always_comb begin
    for (int i=0; i<NUM_OUTPUT_LANES; i++) begin
        case (debug_signal_shift_mux_sel[i])
            2'h3: debug_signals_per_lane_out[i] = debug_signals_per_lane_d3[i];
            2'h2: debug_signals_per_lane_out[i] = debug_signals_per_lane_d2[i];
            2'h1: debug_signals_per_lane_out[i] = debug_signals_per_lane_d1[i];
            default: debug_signals_per_lane_out[i] = debug_signals_per_lane[i];
        endcase
    end
end

// Concatenate the shifted debug signals to form the final output
for (genvar i=0; i<NUM_OUTPUT_LANES; i++) begin: output_signals
  assign debug_signals_out[((i+1)*LANE_WIDTH-1):i*LANE_WIDTH] = debug_signals_per_lane_out[i];
end

endmodule

