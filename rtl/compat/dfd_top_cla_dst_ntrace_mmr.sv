// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dfd_top_cla_dst_ntrace_mmr
  import dfd_compat_pkg::*;
#(
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 1,
    parameter bit NTRACE_SUPPORT = 1,
    parameter bit DST_SUPPORT = 1,
    parameter bit CLA_SUPPORT = 1,
    parameter bit TRACE_SUPPORT = 1,
    parameter bit INTERNAL_MMRS = 1,
    parameter int unsigned DEBUGMARKER_WIDTH = 8,
    parameter int unsigned TRC_SIZE_IN_KB = 16,
    parameter bit TSEL_CONFIGURABLE = 0,
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] BASE_ADDR = '0,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] TIMESYNC_ADDR_OFFSET = 'h200
    ,localparam int unsigned TNIF_CONNECTIONS = TRACE_SUPPORT ? (NUM_TRACE_AND_ANALYZER_INST <= 1) ? 2 : ((NUM_TRACE_AND_ANALYZER_INST + 1) & ~1) : NUM_TRACE_AND_ANALYZER_INST
) (

    input logic clk,
    input logic reset_n,
    input logic reset_n_warm_ovrride,
    input logic cold_reset_n,
    input logic [10:0] i_mem_tsel_settings,

    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][15:0] hw0,
    hw1,
    hw2,
    hw3,
    hw4,
    hw5,
    hw6,
    hw7,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][15:0] hw8,
    hw9,
    hw10,
    hw11,
    hw12,
    hw13,
    hw14,
    hw15,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0]       Time_Tick,

    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][XTRIGGER_WIDTH-1:0] xtrigger_in,
    input  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]                     time_match_event,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0][XTRIGGER_WIDTH-1:0] xtrigger_out,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0][DEBUGMARKER_WIDTH-1:0] cla_debug_marker,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0]                     external_action_trace_start,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0]                     external_action_trace_stop,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0]                     external_action_trace_pulse,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_action_halt_clock_out,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_action_halt_clock_local_out,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_action_debug_interrupt_out,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_action_toggle_gpio_out,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0][CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] external_action_custom,
    output timestamp_s [NUM_TRACE_AND_ANALYZER_INST-1:0] timesync_cla_timestamp,

    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][  NUM_BLOCKS-1:0][IRETIRE_WIDTH-1:0] IRetire,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][  NUM_BLOCKS-1:0][  ITYPE_WIDTH-1:0] IType,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][  NUM_BLOCKS-1:0][     PC_WIDTH-1:1] IAddr,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][  NUM_BLOCKS-1:0]                    ILastSize,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0][TSTAMP_WIDTH-1:0]                    Tstamp,

    input PrivMode_e [NUM_TRACE_AND_ANALYZER_INST-1:0]                    Priv,
    input logic      [NUM_TRACE_AND_ANALYZER_INST-1:0][CONTEXT_WIDTH-1:0] Context,
    input logic      [NUM_TRACE_AND_ANALYZER_INST-1:0][   TVAL_WIDTH-1:0] Tval,

    input  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Error,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Active,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] StallModeEn,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] StartStop,
    output logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Backpressure,

    input TrigTraceControl_e [NUM_TRACE_AND_ANALYZER_INST-1:0] TrigControl,

    input timestamp_s [NUM_TRACE_AND_ANALYZER_INST-1:0] CoreTime,

    output dfd_slv_axi_req_t TR_EXT_SlvReq,
    input  dfd_slv_axi_rsp_t EXT_TR_SlvResp,

    input  dfd_tr_slv_axi_req_t JT_TR_SlvReq,
    output dfd_tr_slv_axi_rsp_t TR_JT_SlvResp,

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

  localparam int unsigned LANE_WIDTH      = LEGACY_HW_BUS_WIDTH;
  localparam int unsigned NUM_INPUT_LANES = LEGACY_NUM_HW_BUSES;
  localparam int unsigned MMR_ADDR_WIDTH  = 17;
  localparam int unsigned MMR_DATA_WIDTH  = DFD_APB_DATA_WIDTH;
  localparam int unsigned MMR_PSTRB_WIDTH = MMR_DATA_WIDTH / 8;
  localparam int unsigned TRC_RAM_INDEX   = TRC_SIZE_IN_KB * 16;
  localparam int unsigned NUM_CORES       = NUM_TRACE_AND_ANALYZER_INST;
  localparam int unsigned NUM_CORES_WIDTH = (NUM_CORES == 1) ? 1 : int'($clog2(NUM_CORES));

  if (!CLA_SUPPORT || !DST_SUPPORT || !NTRACE_SUPPORT)
    $error("dfd_top_cla_dst_ntrace_mmr compat wrapper requires CLA/DST/NTRACE_SUPPORT = 1");
  if (!INTERNAL_MMRS)
    $error("dfd_top_cla_dst_ntrace_mmr compat wrapper only supports INTERNAL_MMRS = 1");
  if (!TRACE_SUPPORT)
    $error("dfd_top_cla_dst_ntrace_mmr compat wrapper wraps a top with an internal trace sink; TRACE_SUPPORT = 0 needs a no-trace flavour");
  if (NUM_TRACE_AND_ANALYZER_INST > MAX_NUM_TRACE_INST)
    $error("NUM_TRACE_AND_ANALYZER_INST exceeds MAX_NUM_TRACE_INST");
  if (BASE_ADDR[DFD_APB_ADDR_WIDTH-1:MMR_ADDR_WIDTH] != '0)
    $error("BASE_ADDR does not fit in the new %0d-bit MMR address space", MMR_ADDR_WIDTH);

  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_INPUT_LANES-1:0][LANE_WIDTH-1:0] debug_bus_signals;

  always_comb begin
    for (int unsigned ii = 0; ii < NUM_TRACE_AND_ANALYZER_INST; ii++) begin
      debug_bus_signals[ii][0] = hw0[ii];
      debug_bus_signals[ii][1] = hw1[ii];
      debug_bus_signals[ii][2] = hw2[ii];
      debug_bus_signals[ii][3] = hw3[ii];
      debug_bus_signals[ii][4] = hw4[ii];
      debug_bus_signals[ii][5] = hw5[ii];
      debug_bus_signals[ii][6] = hw6[ii];
      debug_bus_signals[ii][7] = hw7[ii];
      debug_bus_signals[ii][8] = hw8[ii];
      debug_bus_signals[ii][9] = hw9[ii];
      debug_bus_signals[ii][10] = hw10[ii];
      debug_bus_signals[ii][11] = hw11[ii];
      debug_bus_signals[ii][12] = hw12[ii];
      debug_bus_signals[ii][13] = hw13[ii];
      debug_bus_signals[ii][14] = hw14[ii];
      debug_bus_signals[ii][15] = hw15[ii];
    end
  end

  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][63:0] timestamp;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][ 1:0] sdtrig_control;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][ 2:0] hart_te_priv;

  logic [NUM_CORES-1:0][NUM_CORES_WIDTH-1:0] vid_map;

  always_comb begin
    for (int unsigned ii = 0; ii < NUM_TRACE_AND_ANALYZER_INST; ii++) begin
      timestamp[ii]      = CoreTime[ii].time_val;
      sdtrig_control[ii] = 2'(TrigControl[ii]);
      hart_te_priv[ii]   = 3'(Priv[ii]);
    end
    for (int unsigned ii = 0; ii < NUM_CORES; ii++) begin
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

  assign timesync_cla_timestamp      = '0;
  assign external_action_trace_start = '0;
  assign external_action_trace_stop  = '0;
  assign external_action_trace_pulse = '0;
  assign TR_JT_SlvResp               = '0;

  dfd_top_cla_dst_ntrace_apb #(
      .DEBUGMARKER_WIDTH   (DEBUGMARKER_WIDTH),
      .DEBUG_SIGNAL_WIDTH  (DEBUG_SIGNALS_WIDTH),
      .LANE_WIDTH          (LANE_WIDTH),
      .MMR_ADDR_WIDTH      (MMR_ADDR_WIDTH),
      .MMR_DATA_WIDTH      (MMR_DATA_WIDTH),
      .NUM_CLA_INST        (NUM_TRACE_AND_ANALYZER_INST),
      .NUM_DST_INST        (NUM_TRACE_AND_ANALYZER_INST),
      .NUM_INPUT_LANES     (NUM_INPUT_LANES),
      .NUM_NTRACE_INST     (NUM_TRACE_AND_ANALYZER_INST),
      .OCTS_TS_OUTPUT      (1'b0),

      .TIMESTAMP_SYNC_SCHEME(1'b1),
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

      .i_debug_bus_signals (debug_bus_signals),
      .i_cla_time_tick     (Time_Tick),
      .i_cla_ext_posedge   ('0),
      .i_cla_xtrigger      (xtrigger_in),
      .o_cla_xtrigger      (xtrigger_out),
      .o_cla_debug_marker  (cla_debug_marker),
      .o_cla_external_action_halt_clock_out      (external_action_halt_clock_out),
      .o_cla_external_action_halt_clock_local_out(external_action_halt_clock_local_out),
      .o_cla_external_action_debug_interrupt_out (external_action_debug_interrupt_out),
      .o_cla_external_action_toggle_gpio_out     (external_action_toggle_gpio_out),
      .o_cla_external_action_custom              (external_action_custom),
      .o_debug_mux_sel                           (),

      .i_timestamp       (timestamp),
      .i_ref_timestamp   ('0),
      .i_octs_timestamp  ('0),
      .i_vid_map         (vid_map),

      .i_ntr_hart_te_iretire  (IRetire),
      .i_ntr_hart_te_itype    (IType),
      .i_ntr_hart_te_iaddr    (IAddr),
      .i_ntr_hart_te_ilastsize(ILastSize),
      .i_ntr_hart_te_tstamp   (Tstamp),
      .i_ntr_hart_te_priv     (hart_te_priv),
      .i_ntr_hart_te_context  (Context),
      .i_ntr_hart_te_tval     (Tval),
      .i_ntr_hart_te_error    (Error),
      .o_ntr_tr_active            (Active),
      .o_ntr_tr_stall_mode_en     (StallModeEn),
      .o_ntr_tr_start_stop        (StartStop),
      .o_ntr_tr_start_backpressure(Backpressure),
      .i_sdtrig_control           (sdtrig_control),

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
                                  time_match_event,
                                  JT_TR_SlvReq};

endmodule
