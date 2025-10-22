// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Trace Network - Connects all the trace hops as per the Cluster Organization

/*
  Even Channel: Previously known as North Channel (Even cores/dfd units)
  Odd Channel: Previously known as South Channel (Odd cores/dfd units)
*/

module dfd_trace_network
  import dfd_tn_pkg::*;
#(
  parameter NUM_CORES = 8,
  localparam NUM_CORES_IN_PATH = NUM_CORES >> 1,
  parameter DATA_WIDTH_IN_BYTES = 16,
  parameter DATA_WIDTH = DATA_WIDTH_IN_BYTES*8
) (
  input  logic                                            clk,
  input  logic                                            reset_n,

  // TNIF interfaces from the core
  output logic [NUM_CORES-1:0]                            TN_MS_Gnt,
  output logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Bp,
  output logic [NUM_CORES-1:0]                            TN_MS_Dst_Bp,
  output logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Flush,
  output logic [NUM_CORES-1:0]                            TN_MS_Dst_Flush,
  input  logic [NUM_CORES-1:0]                            MS_TN_Vld,
  input  logic [NUM_CORES-1:0]                            MS_TN_Src,
  input  logic [NUM_CORES-1:0] [DATA_WIDTH-1:0]           MS_TN_Data,

  // Even branch data interface
  output logic [NUM_CORES_IN_PATH-1:0]                    TN_TR_Even_Vld,
  output logic                                            TN_TR_Even_Src,
  output logic [DATA_WIDTH-1:0]                           TN_TR_Even_Data,

  // Odd branch data interface
  output logic [NUM_CORES_IN_PATH-1:0]                    TN_TR_Odd_Vld,
  output logic                                            TN_TR_Odd_Src,
  output logic [DATA_WIDTH-1:0]                           TN_TR_Odd_Data,
  
  // Funnel interface for the Backpressure and one-core mode control signals
  input  logic                                            TN_TR_Ntrace_Bp,
  input  logic                                            TN_TR_Dst_Bp,
  input  logic                                            TN_TR_Ntrace_Flush,
  input  logic                                            TN_TR_Dst_Flush,
  input  logic [NUM_CORES-1:0]                            TN_TR_Enabled_Srcs

);
  
  // Default values for the number of repeater stages, upstream repeaters, and hops to tail (max 8 cores)
  localparam logic [8-1:0][31:0] NUM_REPEATER_STAGES = '{32'h1,32'h2,32'h1,32'h3,32'h1,32'h2,32'h1,32'h3};
  localparam logic [8-1:0][31:0] NUM_UPSTREAM_REPEATERS = '{32'h0,32'h0,32'h1,32'h1,32'h0,32'h0,32'h1,32'h1};
  localparam logic [8-1:0][31:0] NUM_HOPS_TO_TAIL = '{32'h0,32'h1,32'h3,32'h4,32'h0,32'h1,32'h3,32'h4};

  // Even Branch Signals
  logic [NUM_CORES_IN_PATH:0] [NUM_CORES_IN_PATH-1:0] rep_core_tr_vld_north;
  logic [NUM_CORES_IN_PATH:0]                         rep_core_tr_src_north;
  logic [NUM_CORES_IN_PATH:0] [DATA_WIDTH-1:0]        rep_core_tr_data_north;

  logic [NUM_CORES_IN_PATH:0] core_rep_tr_ntrace_bp_north, core_rep_tr_dst_bp_north;
  logic [NUM_CORES_IN_PATH:0] core_rep_tr_ntrace_flush_north, core_rep_tr_dst_flush_north;
  logic [NUM_CORES_IN_PATH:0] [NUM_CORES_IN_PATH-1:0]  core_rep_tr_enabled_srcs_north;

  logic [NUM_CORES_IN_PATH-1:0] [NUM_CORES_IN_PATH-1:0] core_rep_tr_vld_north;
  logic [NUM_CORES_IN_PATH-1:0]                         core_rep_tr_src_north;
  logic [NUM_CORES_IN_PATH-1:0] [DATA_WIDTH-1:0]        core_rep_tr_data_north;

  // Odd Branch Signals
  logic [NUM_CORES_IN_PATH:0] [NUM_CORES_IN_PATH-1:0] rep_core_tr_vld_south;
  logic [NUM_CORES_IN_PATH:0]                         rep_core_tr_src_south;
  logic [NUM_CORES_IN_PATH:0] [DATA_WIDTH-1:0]        rep_core_tr_data_south;

  logic [NUM_CORES_IN_PATH:0] core_rep_tr_ntrace_bp_south, core_rep_tr_dst_bp_south;
  logic [NUM_CORES_IN_PATH:0] core_rep_tr_ntrace_flush_south, core_rep_tr_dst_flush_south;
  logic [NUM_CORES_IN_PATH:0] [NUM_CORES_IN_PATH-1:0]  core_rep_tr_enabled_srcs_south;

  logic [NUM_CORES_IN_PATH-1:0] rep_core_tr_ntrace_bp_south, rep_core_tr_dst_bp_south;
  logic [NUM_CORES_IN_PATH-1:0] rep_core_tr_ntrace_flush_south, rep_core_tr_dst_flush_south;
  logic [NUM_CORES_IN_PATH-1:0] [NUM_CORES_IN_PATH-1:0]  rep_core_tr_enabled_srcs_south;
  // -----------------------------------------------
  // Tail ports connections 
  // ----------------------------------------------- 
  assign rep_core_tr_vld_north[NUM_CORES_IN_PATH] = '0;
  assign rep_core_tr_src_north[NUM_CORES_IN_PATH] = '0;
  assign rep_core_tr_data_north[NUM_CORES_IN_PATH] = '0;

  assign rep_core_tr_vld_south[NUM_CORES_IN_PATH] = '0;
  assign rep_core_tr_src_south[NUM_CORES_IN_PATH] = '0;
  assign rep_core_tr_data_south[NUM_CORES_IN_PATH] = '0;

  // -----------------------------------------------
  // Funnel ports connections 
  // ----------------------------------------------- 
  assign TN_TR_Even_Vld = rep_core_tr_vld_north[0];
  assign TN_TR_Even_Src = rep_core_tr_src_north[0];
  assign TN_TR_Even_Data = rep_core_tr_data_north[0];

  assign TN_TR_Odd_Vld = rep_core_tr_vld_south[0];
  assign TN_TR_Odd_Src = rep_core_tr_src_south[0];
  assign TN_TR_Odd_Data = rep_core_tr_data_south[0];

  assign core_rep_tr_ntrace_bp_north[0] = TN_TR_Ntrace_Bp;
  assign core_rep_tr_dst_bp_north[0] = TN_TR_Dst_Bp;
  assign core_rep_tr_ntrace_flush_north[0] = TN_TR_Ntrace_Flush;
  assign core_rep_tr_dst_flush_north[0] = TN_TR_Dst_Flush;

  assign core_rep_tr_ntrace_bp_south[0] = TN_TR_Ntrace_Bp;
  assign core_rep_tr_dst_bp_south[0] = TN_TR_Dst_Bp;
  assign core_rep_tr_ntrace_flush_south[0] = TN_TR_Ntrace_Flush;
  assign core_rep_tr_dst_flush_south[0] = TN_TR_Dst_Flush;
  
  for (genvar i=0; i<NUM_CORES_IN_PATH; i++) begin
    assign core_rep_tr_enabled_srcs_north[0][i] = TN_TR_Enabled_Srcs[i << 1];
    assign core_rep_tr_enabled_srcs_south[0][i] = TN_TR_Enabled_Srcs[(i << 1) + 1]; 
  end


  // ----------------
  // Even Channel
  // ----------------
  for (genvar i=(NUM_CORES_IN_PATH-1); i>=0; i--) begin
    dfd_trace_hop #(
      .IS_REPEATER(0),
      .NUM_REPEATER_STAGES(NUM_REPEATER_STAGES[i]),
      .NUM_CORES_IN_PATH(NUM_CORES_IN_PATH),
      .RELATIVE_CORE_IDX(i),
      .NUM_UPSTREAM_REPEATERS(NUM_UPSTREAM_REPEATERS[i]),
      .NUM_HOPS_TO_TAIL(NUM_HOPS_TO_TAIL[i])
    ) trace_hop_even_core_inst (
      .clk(clk),
      .reset_n(reset_n),

      // Current Node connections
      .fblk_tr_gnt(TN_MS_Gnt[i << 1]),
      .fblk_tr_src(MS_TN_Src[i << 1]),
      .fblk_tr_vld(MS_TN_Vld[i << 1]),
      .fblk_tr_data(MS_TN_Data[i << 1]),
      .fblk_tr_ntrace_bp(TN_MS_Ntrace_Bp[i << 1]),
      .fblk_tr_dst_bp(TN_MS_Dst_Bp[i << 1]),
      .fblk_tr_ntrace_flush(TN_MS_Ntrace_Flush[i << 1]),
      .fblk_tr_dst_flush(TN_MS_Dst_Flush[i << 1]),

      // Upstream connections
      .upstrm_tr_vld(rep_core_tr_vld_north[i+1]),
      .upstrm_tr_src(rep_core_tr_src_north[i+1]),
      .upstrm_tr_data(rep_core_tr_data_north[i+1]),
      .upstrm_tr_ntrace_bp(core_rep_tr_ntrace_bp_north[i+1]),
      .upstrm_tr_dst_bp(core_rep_tr_dst_bp_north[i+1]),
      .upstrm_tr_ntrace_flush(core_rep_tr_ntrace_flush_north[i+1]),
      .upstrm_tr_dst_flush(core_rep_tr_dst_flush_north[i+1]),
      .upstrm_tr_enabled_srcs(core_rep_tr_enabled_srcs_north[i+1]),

      // Downstream connections
      .dnstrm_tr_vld(rep_core_tr_vld_north[i]),
      .dnstrm_tr_src(rep_core_tr_src_north[i]),
      .dnstrm_tr_data(rep_core_tr_data_north[i]),
      .dnstrm_tr_ntrace_bp(core_rep_tr_ntrace_bp_north[i]),
      .dnstrm_tr_dst_bp(core_rep_tr_dst_bp_north[i]),
      .dnstrm_tr_ntrace_flush(core_rep_tr_ntrace_flush_north[i]),
      .dnstrm_tr_dst_flush(core_rep_tr_dst_flush_north[i]),
      .dnstrm_tr_enabled_srcs(core_rep_tr_enabled_srcs_north[i])  
    );

  end

  // ----------------
  // Odd Channel
  // ----------------
  for (genvar i=(NUM_CORES_IN_PATH-1); i>=0; i--) begin
    dfd_trace_hop #(
      .IS_REPEATER(0),
      .NUM_REPEATER_STAGES(NUM_REPEATER_STAGES[i+4]),
      .NUM_CORES_IN_PATH(NUM_CORES_IN_PATH),
      .RELATIVE_CORE_IDX(i),
      .NUM_UPSTREAM_REPEATERS(NUM_UPSTREAM_REPEATERS[i+4]),
      .NUM_HOPS_TO_TAIL(NUM_HOPS_TO_TAIL[i+4])
    ) trace_hop_odd_core_inst (
      .clk(clk),
      .reset_n(reset_n),

      // Current Node connections
      .fblk_tr_gnt(TN_MS_Gnt[(i << 1) + 1]),
      .fblk_tr_src(MS_TN_Src[(i << 1) + 1]),
      .fblk_tr_vld(MS_TN_Vld[(i << 1) + 1]),
      .fblk_tr_data(MS_TN_Data[(i << 1) + 1]),
      .fblk_tr_ntrace_bp(TN_MS_Ntrace_Bp[(i << 1) + 1]),
      .fblk_tr_dst_bp(TN_MS_Dst_Bp[(i << 1) + 1]),
      .fblk_tr_ntrace_flush(TN_MS_Ntrace_Flush[(i << 1) + 1]),
      .fblk_tr_dst_flush(TN_MS_Dst_Flush[(i << 1) + 1]),

      // Upstream connections
      .upstrm_tr_vld(rep_core_tr_vld_south[i+1]),
      .upstrm_tr_src(rep_core_tr_src_south[i+1]),
      .upstrm_tr_data(rep_core_tr_data_south[i+1]),
      .upstrm_tr_ntrace_bp(core_rep_tr_ntrace_bp_south[i+1]),
      .upstrm_tr_dst_bp(core_rep_tr_dst_bp_south[i+1]),
      .upstrm_tr_ntrace_flush(core_rep_tr_ntrace_flush_south[i+1]),
      .upstrm_tr_dst_flush(core_rep_tr_dst_flush_south[i+1]),
      .upstrm_tr_enabled_srcs(core_rep_tr_enabled_srcs_south[i+1]),

      // Downstream connections
      .dnstrm_tr_vld(rep_core_tr_vld_south[i]),
      .dnstrm_tr_src(rep_core_tr_src_south[i]),
      .dnstrm_tr_data(rep_core_tr_data_south[i]),
      .dnstrm_tr_ntrace_bp(core_rep_tr_ntrace_bp_south[i]),
      .dnstrm_tr_dst_bp(core_rep_tr_dst_bp_south[i]),
      .dnstrm_tr_ntrace_flush(core_rep_tr_ntrace_flush_south[i]),
      .dnstrm_tr_dst_flush(core_rep_tr_dst_flush_south[i]),
      .dnstrm_tr_enabled_srcs(core_rep_tr_enabled_srcs_south[i])  
    );

  end
endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eust]$"
// End:

