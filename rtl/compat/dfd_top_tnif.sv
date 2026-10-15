// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dfd_top_tnif
  import dfd_compat_pkg::*;
#(
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 1,
	parameter NTRACE_SUPPORT = 0,
	parameter DST_SUPPORT = 0,
	parameter CLA_SUPPORT = 0,
    parameter bit TRACE_SUPPORT = 1,
    parameter bit INTERNAL_MMRS = 1,
    parameter int unsigned DEBUGMARKER_WIDTH = 8,
    parameter int unsigned TRC_SIZE_IN_KB = 16,
    parameter bit TSEL_CONFIGURABLE = 0,
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] BASE_ADDR = '0,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] TIMESYNC_ADDR_OFFSET = 'h200
    ,localparam int unsigned TNIF_CONNECTIONS = TRACE_SUPPORT ? (NUM_TRACE_AND_ANALYZER_INST <= 1) ? 2 : ((NUM_TRACE_AND_ANALYZER_INST + 1) & ~1) : NUM_TRACE_AND_ANALYZER_INST
    ,localparam int unsigned TR_TNIF_DATA_WIDTH = 16 * 8
) (

    input logic clk,
    input logic reset_n,
    input logic reset_n_warm_ovrride,
    input logic cold_reset_n,
    input logic [10:0] i_mem_tsel_settings,

    // verilint W240 off
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_start,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_stop,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_pulse,
    // verilint W240 on

    output dfd_slv_axi_req_t TR_EXT_SlvReq,
    input  dfd_slv_axi_rsp_t EXT_TR_SlvResp,

    input  dfd_tr_slv_axi_req_t JT_TR_SlvReq,
    output dfd_tr_slv_axi_rsp_t TR_JT_SlvResp,

    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_gnt_o,
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_dst_bp_o,
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_ntr_bp_o,
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_dst_flush_o,
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_ntr_flush_o,
    // verilint W240 off
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_vld_i,
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_src_i,
    input  logic       [TNIF_CONNECTIONS-1:0][TR_TNIF_DATA_WIDTH-1:0]  tnif_tr_data_i,
    // verilint W240 on

    input  logic [ DFD_APB_ADDR_WIDTH-1:0] paddr,
    input  logic                           psel,
    input  logic                           penable,
    input  logic [DFD_APB_PSTRB_WIDTH-1:0] pstrb,
    input  logic                           pwrite,
    input  logic [ DFD_APB_DATA_WIDTH-1:0] pwdata,
    output logic                           pready,
    output logic [ DFD_APB_DATA_WIDTH-1:0] prdata,
    output logic                           pslverr
);

  localparam int unsigned MMR_ADDR_WIDTH  = 17;
  localparam int unsigned MMR_DATA_WIDTH  = DFD_APB_DATA_WIDTH;
  localparam int unsigned MMR_PSTRB_WIDTH = MMR_DATA_WIDTH / 8;
  localparam int unsigned TRC_RAM_INDEX   = TRC_SIZE_IN_KB * 16;

  localparam int unsigned NUM_CORES_WIDTH =
      (TNIF_CONNECTIONS == 1) ? 1 : int'($clog2(TNIF_CONNECTIONS));

  logic [TNIF_CONNECTIONS-1:0][NUM_CORES_WIDTH-1:0] vid_map;

  always_comb begin
    for (int unsigned ii = 0; ii < TNIF_CONNECTIONS; ii++) begin
      vid_map[ii] = NUM_CORES_WIDTH'(ii);
    end
  end

  logic apb_in_range;
  logic apb_psel;
  logic dut_pready;
  logic dut_pslverr;
  logic [MMR_DATA_WIDTH-1:0] dut_prdata;

  assign apb_in_range = (paddr[DFD_APB_ADDR_WIDTH-1:MMR_ADDR_WIDTH] == '0);
  assign apb_psel     = psel & apb_in_range;

  assign pready  = apb_in_range ? dut_pready  : (psel & penable);
  assign pslverr = apb_in_range ? dut_pslverr : (psel & penable);
  assign prdata  = apb_in_range ? dut_prdata  : '0;

  assign TR_JT_SlvResp = '0;

  dfd_top_dstx_ntracex_apb #(
      .MMR_ADDR_WIDTH      (MMR_ADDR_WIDTH),
      .MMR_DATA_WIDTH      (MMR_DATA_WIDTH),
      .NUM_DST_INST        (TNIF_CONNECTIONS),
      .NUM_NTRACE_INST     (TNIF_CONNECTIONS),

      .TRC_AXI_ADDR_WIDTH  (TRC_AXI_ADDR_WIDTH),
      .TRC_AXI_DATA_WIDTH  (TRC_AXI_DATA_WIDTH),
      .TRC_AXI_ID_WIDTH    (TRC_AXI_ID_WIDTH),
      .TRC_AXI_USER_WIDTH  (TRC_AXI_USER_WIDTH),
      .TRC_BASE_ADDR       (0),
      .TRC_RAM_INDEX       (TRC_RAM_INDEX),
      .TRC_SIZE_IN_KB      (TRC_SIZE_IN_KB),
      .TSEL_CONFIGURABLE   (TSEL_CONFIGURABLE),
      .MMR_BASE_ADDRESS    (BASE_ADDR[MMR_ADDR_WIDTH-1:0])
  ) u_dfd_top (

      .i_clk                 (clk),
      .i_rst_n               (reset_n),
      .i_mem_tsel_settings   (i_mem_tsel_settings),
      .i_critical_signal_hold(1'b0),

      .i_test_icg_en   (1'b0),

      .i_dst_disabled_srcs ('0),
      .i_ntr_disabled_srcs ('0),
      .i_vid_map           (vid_map),

      .tnif_tr_valid     (tnif_tr_vld_i),
      .tnif_tr_src       (tnif_tr_src_i),
      .tnif_tr_data      (tnif_tr_data_i),
      .tr_tnif_gnt       (tnif_tr_gnt_o),
      .tr_tnif_dst_bp    (tnif_dst_bp_o),
      .tr_tnif_ntr_bp    (tnif_ntr_bp_o),
      .tr_tnif_dst_flush (tnif_dst_flush_o),
      .tr_tnif_ntr_flush (tnif_ntr_flush_o),

      .m_trc_axi_awid    (TR_EXT_SlvReq.aw.id),
      .m_trc_axi_awaddr  (TR_EXT_SlvReq.aw.addr),
      .m_trc_axi_awlen   (TR_EXT_SlvReq.aw.len),
      .m_trc_axi_awsize  (TR_EXT_SlvReq.aw.size),
      .m_trc_axi_awburst (TR_EXT_SlvReq.aw.burst),
      .m_trc_axi_awlock  (TR_EXT_SlvReq.aw.lock),
      .m_trc_axi_awcache (TR_EXT_SlvReq.aw.cache),
      .m_trc_axi_awprot  (TR_EXT_SlvReq.aw.prot),
      .m_trc_axi_awqos   (TR_EXT_SlvReq.aw.qos),
      .m_trc_axi_awregion(TR_EXT_SlvReq.aw.region),
      .m_trc_axi_awatop  (TR_EXT_SlvReq.aw.atop),
      .m_trc_axi_awuser  (TR_EXT_SlvReq.aw.user),
      .m_trc_axi_awvalid (TR_EXT_SlvReq.aw_valid),
      .m_trc_axi_wdata   (TR_EXT_SlvReq.w.data),
      .m_trc_axi_wstrb   (TR_EXT_SlvReq.w.strb),
      .m_trc_axi_wlast   (TR_EXT_SlvReq.w.last),
      .m_trc_axi_wuser   (TR_EXT_SlvReq.w.user),
      .m_trc_axi_wvalid  (TR_EXT_SlvReq.w_valid),
      .m_trc_axi_bready  (TR_EXT_SlvReq.b_ready),
      .m_trc_axi_arid    (TR_EXT_SlvReq.ar.id),
      .m_trc_axi_araddr  (TR_EXT_SlvReq.ar.addr),
      .m_trc_axi_arlen   (TR_EXT_SlvReq.ar.len),
      .m_trc_axi_arsize  (TR_EXT_SlvReq.ar.size),
      .m_trc_axi_arburst (TR_EXT_SlvReq.ar.burst),
      .m_trc_axi_arlock  (TR_EXT_SlvReq.ar.lock),
      .m_trc_axi_arcache (TR_EXT_SlvReq.ar.cache),
      .m_trc_axi_arprot  (TR_EXT_SlvReq.ar.prot),
      .m_trc_axi_arqos   (TR_EXT_SlvReq.ar.qos),
      .m_trc_axi_arregion(TR_EXT_SlvReq.ar.region),
      .m_trc_axi_aruser  (TR_EXT_SlvReq.ar.user),
      .m_trc_axi_arvalid (TR_EXT_SlvReq.ar_valid),
      .m_trc_axi_rready  (TR_EXT_SlvReq.r_ready),
      .m_trc_axi_awready (EXT_TR_SlvResp.aw_ready),
      .m_trc_axi_wready  (EXT_TR_SlvResp.w_ready),
      .m_trc_axi_bid     (EXT_TR_SlvResp.b.id),
      .m_trc_axi_bresp   (EXT_TR_SlvResp.b.resp),
      .m_trc_axi_buser   (EXT_TR_SlvResp.b.user),
      .m_trc_axi_bvalid  (EXT_TR_SlvResp.b_valid),
      .m_trc_axi_arready (EXT_TR_SlvResp.ar_ready),
      .m_trc_axi_rid     (EXT_TR_SlvResp.r.id),
      .m_trc_axi_rdata   (EXT_TR_SlvResp.r.data),
      .m_trc_axi_rresp   (EXT_TR_SlvResp.r.resp),
      .m_trc_axi_rlast   (EXT_TR_SlvResp.r.last),
      .m_trc_axi_ruser   (EXT_TR_SlvResp.r.user),
      .m_trc_axi_rvalid  (EXT_TR_SlvResp.r_valid),

      .i_jtag_mmr_req_vld  (1'b0),
      .i_jtag_mmr_req_we   (1'b0),
      .i_jtag_mmr_req_addr ('0),
      .i_jtag_mmr_req_data ('0),
      .o_jtag_mmr_rsp_data (),
      .o_jtag_mmr_rsp_vld  (),

      .paddr   (paddr[MMR_ADDR_WIDTH-1:0]),
      .psel    (apb_psel),
      .penable (penable),
      .pstrb   (pstrb[MMR_PSTRB_WIDTH-1:0]),
      .pwrite  (pwrite),
      .pwdata  (pwdata),
      .pready  (dut_pready),
      .prdata  (dut_prdata),
      .pslverr (dut_pslverr)
  );

  logic unused_legacy_inputs;
  assign unused_legacy_inputs = ^{cold_reset_n,
                                  reset_n_warm_ovrride,
                                  external_cla_action_trace_start,
                                  external_cla_action_trace_stop,
                                  external_cla_action_trace_pulse,
                                  JT_TR_SlvReq};

endmodule
