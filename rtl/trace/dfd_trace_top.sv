// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Trace Top: Top Trace File - Holds dfd_trace_network, trace_funnel, and trace_mem

module dfd_trace_top
  import dfd_tn_pkg::*;
  import dfd_tr_csr_pkg::*;
  import dfd_CL_axi_pkg::*;
#(
    parameter NUM_CORES = 8,
    localparam NUM_CORES_IN_PATH = NUM_CORES >> 1,
    parameter NUM_ACTIVE_CORES = 1,
    parameter BASE_ADDR = 0,
    parameter DATA_WIDTH_IN_BYTES = 16,
    parameter DATA_WIDTH = DATA_WIDTH_IN_BYTES * 8,
    parameter TRC_RAM_INDEX = 512,
    parameter TSEL_CONFIGURABLE = 0,
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined

) (

    input logic        clk,
    input logic        reset_n,
    // input  logic                                            cold_reset_n,
    input logic [10:0] i_mem_tsel_settings,

    // Trace Network
    // TNIF interfaces from the core
    output logic [NUM_CORES-1:0]                 TN_MS_Gnt,
    output logic [NUM_CORES-1:0]                 TN_MS_Ntrace_Bp,
    output logic [NUM_CORES-1:0]                 TN_MS_Dst_Bp,
    output logic [NUM_CORES-1:0]                 TN_MS_Ntrace_Flush,
    output logic [NUM_CORES-1:0]                 TN_MS_Dst_Flush,
    input  logic [NUM_CORES-1:0]                 MS_TN_Vld,
    input  logic [NUM_CORES-1:0]                 MS_TN_Src,
    input  logic [NUM_CORES-1:0][DATA_WIDTH-1:0] MS_TN_Data,

    // Trace MMRs
    input  TrCsrs_s   TrCsrs,
    output TrCsrsWr_s TrCsrsWr,

    // Trace Funnel
    // AXI Interface the Memory
    output dfd_slv_axi_req_t TR_AB_SlvReq_Rx,
    input  dfd_slv_axi_rsp_t AB_TR_SlvResp_Tx,

    // JTAG-AXI Control Interface
    input  dfd_tr_slv_axi_req_t JT_TR_SlvReq,
    output dfd_tr_slv_axi_rsp_t TR_JT_SlvResp,

	// JTAG-MMR Control Interface
	input  logic                                            jt_tr_mmr_req_vld_o,
	input  logic                                            jt_tr_mmr_req_we_o,
	input  logic [DfdAxiAddrWidth-1:0]                       jt_tr_mmr_req_addr_o,
	input  logic [31:0]                                     jt_tr_mmr_req_data_o,
	output logic [DfdAxiDataWidth-1:0]                       tr_jt_mmr_rsp_data_i,
	output logic                                            tr_jt_mmr_rsp_vld_i

);

  // Struct Definition
  localparam TRC_RAM_INDEX_WIDTH = $clog2(TRC_RAM_INDEX);

  typedef struct packed {
    logic mem_chip_en;
    logic mem_wr_en;
    logic [TRC_RAM_INDEX_WIDTH-1:0] mem_wr_addr;
    logic mem_wr_mask_en;
    logic [TRC_RAM_DATA_WIDTH-1:0] mem_wr_data;
  } SinkMemPktIn_s;

  typedef struct packed {logic [TRC_RAM_DATA_WIDTH-1:0] mem_rd_data;} SinkMemPktOut_s;

  // Signal Declaration

  // North branch data interface
  logic            [NUM_CORES_IN_PATH-1:0]                 TN_TR_North_Vld;
  logic                                                    TN_TR_North_Src;
  logic            [       DATA_WIDTH-1:0]                 TN_TR_North_Data;

  // South branch data interface
  logic            [NUM_CORES_IN_PATH-1:0]                 TN_TR_South_Vld;
  logic                                                    TN_TR_South_Src;
  logic            [       DATA_WIDTH-1:0]                 TN_TR_South_Data;

  // Funnel interface for the Backpressure
  logic                                                    TN_TR_Ntrace_Bp;
  logic                                                    TN_TR_Dst_Bp;
  logic                                                    TN_TR_Ntrace_Flush;
  logic                                                    TN_TR_Dst_Flush;
  logic            [        NUM_CORES-1:0]                 TN_TR_Enabled_Srcs;

  dfd_tr_slv_axi_req_t                                         TS_TR_SlvReq;
  dfd_tr_slv_axi_rsp_t                                         TR_TS_SlvResp;

  // JTAG internal AXI req packet
  dfd_tr_slv_axi_req_t                                         JT_TR_SlvReq_int;

  // Trace Sink Memory Macro Signals
  SinkMemPktIn_s   [TRC_RAM_INSTANCES-1:0]                 funnel_mem_SinkMemPktIn_ANY;
  SinkMemPktOut_s  [TRC_RAM_INSTANCES-1:0]                 mem_funnel_SinkMemPktOut_ANY;

  // Clock gating
  logic                                                    trfunnelactive;
  logic                                                    trfunnelfuse;
  logic                                                    trfunnelfuselock;

  logic                                                    Ccg_clk_tr;

  logic            [        NUM_CORES-1:0]                 MS_TN_Vld_Internal_Active_Cores;
  logic            [        NUM_CORES-1:0]                 MS_TN_Src_Internal_Active_Cores;
  logic            [        NUM_CORES-1:0][DATA_WIDTH-1:0] MS_TN_Data_Internal_Active_Cores;

  generic_ccg #(
      .HYST_EN (0),
      .HYST_CYC(0)
  ) u_Ccg_clk_tr (
      .out_clk(Ccg_clk_tr),
      .en(trfunnelactive),
      .te(1'b0),
      .force_en('0),
      .hyst(1'b0),
      .clk(clk),
      .rst_n(reset_n)
  );

  always_comb begin
    MS_TN_Vld_Internal_Active_Cores  = '0;
    MS_TN_Src_Internal_Active_Cores  = '0;
    MS_TN_Data_Internal_Active_Cores = '0;

    for (int i = 0; i < NUM_ACTIVE_CORES; i++) begin
      MS_TN_Vld_Internal_Active_Cores[i]  = MS_TN_Vld[i];
      MS_TN_Src_Internal_Active_Cores[i]  = MS_TN_Src[i];
      MS_TN_Data_Internal_Active_Cores[i] = MS_TN_Data[i];
    end
  end

  dfd_trace_network #(
      .NUM_CORES(NUM_CORES),
      .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
      .DATA_WIDTH(DATA_WIDTH)
  ) trace_network_inst (
      .clk(clk),
      .reset_n(reset_n),
      .TN_MS_Gnt(TN_MS_Gnt),
      .TN_MS_Ntrace_Bp(TN_MS_Ntrace_Bp),
      .TN_MS_Dst_Bp(TN_MS_Dst_Bp),
      .TN_MS_Ntrace_Flush(TN_MS_Ntrace_Flush),
      .TN_MS_Dst_Flush(TN_MS_Dst_Flush),
      .MS_TN_Vld(MS_TN_Vld_Internal_Active_Cores),
      .MS_TN_Src(MS_TN_Src_Internal_Active_Cores),
      .MS_TN_Data(MS_TN_Data_Internal_Active_Cores),
      .TN_TR_North_Vld(TN_TR_North_Vld),
      .TN_TR_North_Src(TN_TR_North_Src),
      .TN_TR_North_Data(TN_TR_North_Data),
      .TN_TR_South_Vld(TN_TR_South_Vld),
      .TN_TR_South_Src(TN_TR_South_Src),
      .TN_TR_South_Data(TN_TR_South_Data),
      .TN_TR_Ntrace_Bp(TN_TR_Ntrace_Bp),
      .TN_TR_Dst_Bp(TN_TR_Dst_Bp),
      .TN_TR_Ntrace_Flush(TN_TR_Ntrace_Flush),
      .TN_TR_Dst_Flush(TN_TR_Dst_Flush),
      .TN_TR_Enabled_Srcs(TN_TR_Enabled_Srcs)
  );

  dfd_trace_funnel #(
      .NUM_CORES(NUM_CORES),
      .TRC_RAM_INDEX(TRC_RAM_INDEX),
      .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
      .SinkMemPktIn_s(SinkMemPktIn_s),
      .SinkMemPktOut_s(SinkMemPktOut_s),
      .DATA_WIDTH(DATA_WIDTH),
      .BASE_ADDR(BASE_ADDR)
  ) trace_funnel_inst (
      .clk(Ccg_clk_tr),
      .clk_mmr(clk),
      .reset_n(reset_n),
      // .cold_reset_n(cold_reset_n),
      .TrCsrs(TrCsrs),
      .TrCsrsWr(TrCsrsWr),
      .trfunnelactive(trfunnelactive),
      .trfunnelfuse(trfunnelfuse),
      .trfunnelfuselock(trfunnelfuselock),
      .TN_TR_North_Vld(TN_TR_North_Vld),
      .TN_TR_North_Src(TN_TR_North_Src),
      .TN_TR_North_Data(TN_TR_North_Data),
      .TN_TR_South_Vld(TN_TR_South_Vld),
      .TN_TR_South_Src(TN_TR_South_Src),
      .TN_TR_South_Data(TN_TR_South_Data),
      .TN_TR_Ntrace_Bp(TN_TR_Ntrace_Bp),
      .TN_TR_Dst_Bp(TN_TR_Dst_Bp),
      .TN_TR_Ntrace_Flush(TN_TR_Ntrace_Flush),
      .TN_TR_Dst_Flush(TN_TR_Dst_Flush),
      .TN_TR_Enabled_Srcs(TN_TR_Enabled_Srcs),
      .TS_TR_SlvReq(TS_TR_SlvReq),
      .TR_TS_SlvResp(TR_TS_SlvResp),
      .jt_tr_mmr_req_vld_o(jt_tr_mmr_req_vld_o),
      .jt_tr_mmr_req_we_o(jt_tr_mmr_req_we_o),
      .jt_tr_mmr_req_addr_o(jt_tr_mmr_req_addr_o),
      .jt_tr_mmr_req_data_o(jt_tr_mmr_req_data_o),
      .tr_jt_mmr_rsp_data_i(tr_jt_mmr_rsp_data_i),
      .tr_jt_mmr_rsp_vld_i(tr_jt_mmr_rsp_vld_i),
      .funnel_mem_SinkMemPktIn_ANY(funnel_mem_SinkMemPktIn_ANY),
      .mem_funnel_SinkMemPktOut_ANY(mem_funnel_SinkMemPktOut_ANY)
  );

  dfd_trace_mem #(
      .SINK_CELL(SINK_CELL),
      .TRC_RAM_INDEX_WIDTH(TRC_RAM_INDEX_WIDTH),
      .TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
      .SinkMemPktIn_s(SinkMemPktIn_s),
      .SinkMemPktOut_s(SinkMemPktOut_s)
  ) trace_mem_inst (
      .clk(clk),
      .reset_n(reset_n),
      .i_mem_tsel_settings(i_mem_tsel_settings),
      .funnel_mem_SinkMemPktIn_ANY(funnel_mem_SinkMemPktIn_ANY),
      .mem_funnel_SinkMemPktOut_ANY(mem_funnel_SinkMemPktOut_ANY)
  );

	// Tie off the JTAG AXI request to have user bits as 8'h3
	always_comb begin
		JT_TR_SlvReq_int = JT_TR_SlvReq;
		JT_TR_SlvReq_int.aw.user = $bits(JT_TR_SlvReq_int.aw.user)'(Dfd_SRCID);
		JT_TR_SlvReq_int.ar.user = $bits(JT_TR_SlvReq_int.aw.user)'(Dfd_SRCID);
	end

  axi_mux #(
      .SlvAxiIDWidth(TrAxiIdWidthSlvPorts),  // ID width of the slave ports
      .slv_aw_chan_t(dfd_tr_slv_aw_chan_t),      // AW Channel Type, slave ports
      .mst_aw_chan_t(dfd_slv_aw_chan_t),      // AW Channel Type, master port
      .w_chan_t     (dfd_slv_w_chan_t),       //  W Channel Type, all ports
      .slv_b_chan_t (dfd_tr_slv_b_chan_t),       //  B Channel Type, save ports
      .mst_b_chan_t (dfd_slv_b_chan_t),       //  B Channel Type, master port
      .slv_ar_chan_t(dfd_tr_slv_ar_chan_t),      // AR Channel Type, slave ports
      .mst_ar_chan_t(dfd_slv_ar_chan_t),      // AR Channel Type, master port
      .slv_r_chan_t (dfd_tr_slv_r_chan_t),       //  R Channel Type, slave ports
      .mst_r_chan_t (dfd_slv_r_chan_t),       //  R Channel Type, master port
      .slv_req_t    (dfd_tr_slv_axi_req_t),
      .slv_resp_t   (dfd_tr_slv_axi_rsp_t),
      .mst_req_t    (dfd_slv_axi_req_t),
      .mst_resp_t   (dfd_slv_axi_rsp_t),
      .NoSlvPorts   (2),                     // Number of Masters for the module
      .MaxWTrans    (1),
      .FallThrough  (0),
      .SpillAw      (1),
      .SpillW       (1),
      .SpillB       (1),
      .SpillAr      (1),
      .SpillR       (1)
  ) axi_mux_inst (
      .clk_i(clk),
      .rst_ni(reset_n),
      .test_i(1'b0),  // Test Mode enable
      .slv_reqs_i  ( {JT_TR_SlvReq_int, TS_TR_SlvReq}),
      .slv_resps_o ( {TR_JT_SlvResp, TR_TS_SlvResp}),
      .mst_req_o   ( TR_AB_SlvReq_Rx ),
      .mst_resp_i  ( AB_TR_SlvResp_Tx )

  );

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eust]$"
// End:

