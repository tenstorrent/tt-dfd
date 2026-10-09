// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dfd_top_cla_dst_ntrace_apb_no_trace_top
  import cla_mmr_pkg::*;
  import ntr_sink_mmr_pkg::*;
  import dst_sink_mmr_pkg::*;
  import funnel_mmr_pkg::*;
  import ntr_mmr_pkg::*;
  import dst_mmr_pkg::*;
  import cla_pkg::*;
  import dst_pkg::*;
  import tt_dbm_pkg::*;
  import te_pkg::*;
  import packetizer_pkg::*;
  import tn_pkg::*;
 #(
    parameter int unsigned CONTEXT_WIDTH = te_pkg::TE_CONTEXT_WIDTH,
    parameter DEBUGMARKER_WIDTH = 8,
    parameter DEBUG_SIGNAL_WIDTH = 128,
    parameter int unsigned IRETIRE_WIDTH = 5,
    parameter LANE_WIDTH = 16,
    parameter MMR_ADDR_WIDTH = 17,
    parameter MMR_AXI_ID_WIDTH = 4,
    parameter MMR_AXI_USER_WIDTH = 8,
    parameter MMR_DATA_WIDTH = 32,
    parameter int unsigned NUM_CLA_INST = 8,
    parameter int unsigned NUM_DST_INST = 8,
    parameter NUM_INPUT_LANES = 8,
    parameter int unsigned NUM_NTRACE_INST = 8,
    parameter bit OCTS_TS_OUTPUT = 0,
    parameter int unsigned PC_WIDTH = te_pkg::TE_PC_WIDTH,
    parameter bit TIMESTAMP_SYNC_SCHEME = 1,
    parameter int unsigned TSTAMP_WIDTH = te_pkg::TE_TSTAMP_WIDTH,
    parameter int unsigned TVAL_WIDTH = te_pkg::TE_TVAL_WIDTH,
    parameter MMR_BASE_ADDRESS = (MMR_ADDR_WIDTH)'('h0),
    localparam DATA_WIDTH_TNIF_WRAPPER = 128,
    localparam ITYPE_WIDTH_NTR_WRAPPER = te_pkg::TE_ITYPE_WIDTH,
    localparam MAX_DST_NTR_INST_NTR_WRAPPER = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST,
    localparam MMR_PSTRB_WIDTH_MMRS = MMR_DATA_WIDTH / 8,
    localparam NUM_BLOCKS_NTR_WRAPPER = te_pkg::TE_NUM_BLOCKS,
    localparam NUM_CLA_INST_SAFE_MMRS = (NUM_CLA_INST    > 0) ? NUM_CLA_INST    : 32'd1,
    localparam NUM_DST_INST_SAFE_MMRS = (NUM_DST_INST    > 0) ? NUM_DST_INST    : 32'd1,
    localparam NUM_NTRACE_INST_SAFE_MMRS = (NUM_NTRACE_INST > 0) ? NUM_NTRACE_INST : 32'd1,
    localparam TIMESTAMP_UPPER_WIDTH_CLA_WRAPPER = 56,
    localparam TNIF_W_TNIF_WRAPPER = ((NUM_DST_INST == 0) && (NUM_NTRACE_INST == 0)) ? 32'd1
                                         : ((NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST)
) (
    input logic [NUM_CLA_INST-1:0] i_cla_ext_posedge,
    input logic [NUM_CLA_INST-1:0] i_cla_time_tick,
    input logic [NUM_CLA_INST-1:0] [XTRIGGER_WIDTH-1:0] i_cla_xtrigger,
    input logic i_clk,
    input logic i_critical_signal_hold,
    input logic [NUM_CLA_INST-1:0] [NUM_INPUT_LANES-1:0] [LANE_WIDTH-1:0] i_debug_bus_signals,
    input logic [MMR_ADDR_WIDTH-1:0] i_jtag_mmr_req_addr,
    input logic [MMR_DATA_WIDTH-1:0] i_jtag_mmr_req_data,
    input logic i_jtag_mmr_req_vld,
    input logic i_jtag_mmr_req_we,
    input logic [NUM_NTRACE_INST-1:0] [CONTEXT_WIDTH-1:0] i_ntr_hart_te_context,
    input logic [NUM_NTRACE_INST-1:0] i_ntr_hart_te_error,
    input logic [NUM_NTRACE_INST-1:0] [NUM_BLOCKS_NTR_WRAPPER-1:0] [PC_WIDTH-1:1] i_ntr_hart_te_iaddr,
    input logic [NUM_NTRACE_INST-1:0] [NUM_BLOCKS_NTR_WRAPPER-1:0] i_ntr_hart_te_ilastsize,
    input logic [NUM_NTRACE_INST-1:0] [NUM_BLOCKS_NTR_WRAPPER-1:0] [IRETIRE_WIDTH-1:0] i_ntr_hart_te_iretire,
    input logic [NUM_NTRACE_INST-1:0] [NUM_BLOCKS_NTR_WRAPPER-1:0] [ITYPE_WIDTH_NTR_WRAPPER-1:0] i_ntr_hart_te_itype,
    input logic [NUM_NTRACE_INST-1:0] [2:0] i_ntr_hart_te_priv,
    input logic [NUM_NTRACE_INST-1:0] [TSTAMP_WIDTH-1:0] i_ntr_hart_te_tstamp,
    input logic [NUM_NTRACE_INST-1:0] [TVAL_WIDTH-1:0] i_ntr_hart_te_tval,
    input logic [NUM_CLA_INST-1:0] [63:0] i_octs_timestamp,
    input logic [NUM_CLA_INST-1:0] [TIMESTAMP_UPPER_WIDTH_CLA_WRAPPER-1:0] i_ref_timestamp,
    input logic i_rst_n,
    input logic [MAX_DST_NTR_INST_NTR_WRAPPER-1:0] [1:0] i_sdtrig_control,
    input logic i_test_icg_en,
    input logic [NUM_CLA_INST-1:0] [63:0] i_timestamp,
    output logic [NUM_CLA_INST-1:0] [DEBUGMARKER_WIDTH-1:0] o_cla_debug_marker,
    output logic [NUM_CLA_INST-1:0] [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] o_cla_external_action_custom,
    output logic [NUM_CLA_INST-1:0] o_cla_external_action_debug_interrupt_out,
    output logic [NUM_CLA_INST-1:0] o_cla_external_action_halt_clock_local_out,
    output logic [NUM_CLA_INST-1:0] o_cla_external_action_halt_clock_out,
    output logic [NUM_CLA_INST-1:0] o_cla_external_action_toggle_gpio_out,
    output logic [NUM_CLA_INST-1:0] [XTRIGGER_WIDTH-1:0] o_cla_xtrigger,
    output DbgMuxSelMmr_s [NUM_CLA_INST-1:0] o_debug_mux_sel,
    output logic [MMR_DATA_WIDTH-1:0] o_jtag_mmr_rsp_data,
    output logic o_jtag_mmr_rsp_vld,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_active,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_stall_mode_en,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_start_backpressure,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_start_stop,
    input logic [MMR_ADDR_WIDTH-1:0] paddr,
    input logic penable,
    output logic [MMR_DATA_WIDTH-1:0] prdata,
    output logic pready,
    input logic psel,
    output logic pslverr,
    input logic [MMR_PSTRB_WIDTH_MMRS-1:0] pstrb,
    input logic [MMR_DATA_WIDTH-1:0] pwdata,
    input logic pwrite,
    output logic [TNIF_W_TNIF_WRAPPER-1:0] [DATA_WIDTH_TNIF_WRAPPER-1:0] tnif_tr_data,
    output logic [TNIF_W_TNIF_WRAPPER-1:0] tnif_tr_src,
    output logic [TNIF_W_TNIF_WRAPPER-1:0] tnif_tr_valid,
    input logic [TNIF_W_TNIF_WRAPPER-1:0] tr_tnif_dst_bp,
    input logic [TNIF_W_TNIF_WRAPPER-1:0] tr_tnif_dst_flush,
    input logic [TNIF_W_TNIF_WRAPPER-1:0] tr_tnif_gnt,
    input logic [TNIF_W_TNIF_WRAPPER-1:0] tr_tnif_ntr_bp,
    input logic [TNIF_W_TNIF_WRAPPER-1:0] tr_tnif_ntr_flush
);

  localparam CLA_W_CLK_RST_WRAPPER = (NUM_CLA_INST    == 0) ? 32'd1 : NUM_CLA_INST;
  localparam CLA_W_DST_WRAPPER = (NUM_CLA_INST == 0) ? 1 : NUM_CLA_INST;
  localparam CLA_W_NTR_WRAPPER = (NUM_CLA_INST == 0) ? 1 : NUM_CLA_INST;
  localparam DATA_WIDTH_DST_WRAPPER = 128;
  localparam DATA_WIDTH_NTR_WRAPPER = 128;
  localparam DST_W_CLK_RST_WRAPPER = (NUM_DST_INST    == 0) ? 32'd1 : NUM_DST_INST;
  localparam DST_W_TNIF_WRAPPER = (NUM_DST_INST     == 0) ? 32'd1 : NUM_DST_INST;
  localparam MAX_DST_NTR_INST_DST_WRAPPER = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST;
  localparam NTR_W_CLK_RST_WRAPPER = (NUM_NTRACE_INST == 0) ? 32'd1 : NUM_NTRACE_INST;
  localparam NTR_W_TNIF_WRAPPER = (NUM_NTRACE_INST  == 0) ? 32'd1 : NUM_NTRACE_INST;
  localparam TNIF_CONNECTIONS_TNIF_WRAPPER = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST;
  localparam TNIF_W_CLK_RST_WRAPPER = ((NUM_DST_INST == 0) && (NUM_NTRACE_INST == 0)) ? 32'd1
                                     : ((NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST);

  wire ClaMmrs_s [NUM_CLA_INST_SAFE_MMRS-1:0] ClaMmrs;

  wire ClaMmrsWrMinimal_s [NUM_CLA_INST-1:0] ClaMmrsWr;

  wire DstMmrs_s [NUM_DST_INST_SAFE_MMRS-1:0] DstMmrs;

  wire DstMmrsWr_s [NUM_DST_INST-1:0] DstMmrsWr;

  DstSinkMmrs_s DstSinkMmrs;

  FunnelMmrs_s FunnelMmrs;

  wire NtrMmrs_s [NUM_NTRACE_INST_SAFE_MMRS-1:0] NtrMmrs;

  wire NtrMmrsWr_s [NUM_NTRACE_INST-1:0] NtrMmrsWr;

  NtrSinkMmrs_s NtrSinkMmrs;

  logic [NUM_CLA_INST_SAFE_MMRS-1:0] cla_func_enable;

  logic [CLA_W_CLK_RST_WRAPPER-1:0] cla_gated_clock;

  logic [CLA_W_CLK_RST_WRAPPER-1:0] cla_gated_func_clamp;

  logic [CLA_W_CLK_RST_WRAPPER-1:0] cla_gated_reset_n;

  logic [CLA_W_CLK_RST_WRAPPER-1:0] cla_gated_reset_n_warm_ovrride;

  logic [NUM_CLA_INST-1:0] [DEBUG_SIGNAL_WIDTH-1:0] debug_bus;

  logic [NUM_DST_INST_SAFE_MMRS-1:0] dst_func_enable;

  logic [DST_W_CLK_RST_WRAPPER-1:0] dst_gated_clock;

  logic [DST_W_CLK_RST_WRAPPER-1:0] dst_gated_func_clamp;

  logic [DST_W_CLK_RST_WRAPPER-1:0] dst_gated_reset_n;

  logic [DST_W_CLK_RST_WRAPPER-1:0] dst_gated_reset_n_warm_ovrride;

  logic dst_sink_func_enable;

  logic dst_sink_gated_clock;

  logic dst_sink_gated_func_clamp;

  logic dst_sink_gated_reset_n;

  logic dst_sink_gated_reset_n_warm_ovrride;

  logic [NUM_DST_INST-1:0] [DATA_WIDTH_DST_WRAPPER-1:0] dst_tnif_data;

  logic [NUM_DST_INST-1:0] dst_tnif_req;

  logic funnel_func_enable;

  logic funnel_gated_clock;

  logic funnel_gated_func_clamp;

  logic funnel_gated_reset_n;

  logic funnel_gated_reset_n_warm_ovrride;

  logic [NUM_NTRACE_INST_SAFE_MMRS-1:0] ntr_func_enable;

  logic [NTR_W_CLK_RST_WRAPPER-1:0] ntr_gated_clock;

  logic [NTR_W_CLK_RST_WRAPPER-1:0] ntr_gated_func_clamp;

  logic [NTR_W_CLK_RST_WRAPPER-1:0] ntr_gated_reset_n;

  logic [NTR_W_CLK_RST_WRAPPER-1:0] ntr_gated_reset_n_warm_ovrride;

  logic ntr_sink_func_enable;

  logic ntr_sink_gated_clock;

  logic ntr_sink_gated_func_clamp;

  logic ntr_sink_gated_reset_n;

  logic ntr_sink_gated_reset_n_warm_ovrride;

  logic [NUM_NTRACE_INST-1:0] [DATA_WIDTH_NTR_WRAPPER-1:0] ntr_tnif_data;

  logic [NUM_NTRACE_INST-1:0] ntr_tnif_req;

  logic [NUM_CLA_INST-1:0] o_cla_external_action_trace_pulse;

  logic [NUM_CLA_INST-1:0] o_cla_external_action_trace_start;

  logic [NUM_CLA_INST-1:0] o_cla_external_action_trace_stop;

  logic s_mmr_axi_arready;

  logic s_mmr_axi_awready;

  logic [MMR_AXI_ID_WIDTH-1:0] s_mmr_axi_bid;

  logic [1:0] s_mmr_axi_bresp;

  logic [MMR_AXI_USER_WIDTH-1:0] s_mmr_axi_buser;

  logic s_mmr_axi_bvalid;

  logic [MMR_DATA_WIDTH-1:0] s_mmr_axi_rdata;

  logic [MMR_AXI_ID_WIDTH-1:0] s_mmr_axi_rid;

  logic s_mmr_axi_rlast;

  logic [1:0] s_mmr_axi_rresp;

  logic [MMR_AXI_USER_WIDTH-1:0] s_mmr_axi_ruser;

  logic s_mmr_axi_rvalid;

  logic s_mmr_axi_wready;

  wire dst_pkg::timestamp_s [NUM_CLA_INST-1:0] timesync_cla_timestamp;

  logic [DST_W_TNIF_WRAPPER-1:0] tnif_dst_bp;

  logic [DST_W_TNIF_WRAPPER-1:0] tnif_dst_flush;

  logic [DST_W_TNIF_WRAPPER-1:0] tnif_dst_pull;

  logic [TNIF_W_CLK_RST_WRAPPER-1:0] tnif_gated_clock;

  logic [TNIF_W_CLK_RST_WRAPPER-1:0] tnif_gated_func_clamp;

  logic [TNIF_W_CLK_RST_WRAPPER-1:0] tnif_gated_reset_n;

  logic [TNIF_W_CLK_RST_WRAPPER-1:0] tnif_gated_reset_n_warm_ovrride;

  logic [NTR_W_TNIF_WRAPPER-1:0] tnif_ntr_bp;

  logic [NTR_W_TNIF_WRAPPER-1:0] tnif_ntr_flush;

  logic [NTR_W_TNIF_WRAPPER-1:0] tnif_ntr_pull;

  logic trRamDataRdEn;

  logic trdstRamDataRdEn;

  cla_wrapper #(
    .DEBUGMARKER_WIDTH(DEBUGMARKER_WIDTH),
    .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH),
    .LANE_WIDTH(LANE_WIDTH),
    .NUM_CLA_INST(NUM_CLA_INST),
    .NUM_INPUT_LANES(NUM_INPUT_LANES),
    .OCTS_TS_OUTPUT(OCTS_TS_OUTPUT),
    .TIMESTAMP_SYNC_SCHEME(TIMESTAMP_SYNC_SCHEME)
  ) cla_wrapper (
    .i_cla_ext_posedge(i_cla_ext_posedge),
    .i_cla_time_tick(i_cla_time_tick),
    .i_cla_xtrigger(i_cla_xtrigger),
    .i_debug_bus_signals(i_debug_bus_signals),
    .i_octs_timestamp(i_octs_timestamp),
    .i_ref_timestamp(i_ref_timestamp),
    .i_test_icg_en(i_test_icg_en),
    .i_timestamp(i_timestamp),
    .o_cla_debug_marker(o_cla_debug_marker),
    .o_cla_external_action_custom(o_cla_external_action_custom),
    .o_cla_external_action_debug_interrupt_out(o_cla_external_action_debug_interrupt_out),
    .o_cla_external_action_halt_clock_local_out(o_cla_external_action_halt_clock_local_out),
    .o_cla_external_action_halt_clock_out(o_cla_external_action_halt_clock_out),
    .o_cla_external_action_toggle_gpio_out(o_cla_external_action_toggle_gpio_out),
    .o_cla_xtrigger(o_cla_xtrigger),
    .o_debug_mux_sel(o_debug_mux_sel),
    .cla_gated_reset_n(cla_gated_reset_n),
    .cla_gated_clock(cla_gated_clock),
    .ClaMmrs(ClaMmrs),
    .cla_gated_func_clamp(cla_gated_func_clamp),
    .cla_gated_reset_n_warm_ovrride(cla_gated_reset_n_warm_ovrride),
    .timesync_cla_timestamp(timesync_cla_timestamp),
    .debug_bus(debug_bus),
    .o_cla_external_action_trace_start(o_cla_external_action_trace_start),
    .o_cla_external_action_trace_stop(o_cla_external_action_trace_stop),
    .o_cla_external_action_trace_pulse(o_cla_external_action_trace_pulse),
    .ClaMmrsWr(ClaMmrsWr)
  );

  clk_rst_wrapper #(
    .NUM_CLA_INST(NUM_CLA_INST),
    .NUM_DST_INST(NUM_DST_INST),
    .NUM_NTRACE_INST(NUM_NTRACE_INST)
  ) clk_rst_wrapper (
    .ntr_sink_gated_reset_n_warm_ovrride(ntr_sink_gated_reset_n_warm_ovrride),
    .tnif_gated_reset_n_warm_ovrride(tnif_gated_reset_n_warm_ovrride),
    .ntr_sink_gated_reset_n(ntr_sink_gated_reset_n),
    .dst_sink_gated_reset_n(dst_sink_gated_reset_n),
    .funnel_gated_reset_n_warm_ovrride(funnel_gated_reset_n_warm_ovrride),
    .dst_gated_reset_n_warm_ovrride(dst_gated_reset_n_warm_ovrride),
    .ntr_gated_reset_n_warm_ovrride(ntr_gated_reset_n_warm_ovrride),
    .dst_sink_gated_func_clamp(dst_sink_gated_func_clamp),
    .ntr_sink_gated_func_clamp(ntr_sink_gated_func_clamp),
    .ntr_sink_gated_clock(ntr_sink_gated_clock),
    .funnel_gated_reset_n(funnel_gated_reset_n),
    .dst_sink_gated_reset_n_warm_ovrride(dst_sink_gated_reset_n_warm_ovrride),
    .dst_sink_gated_clock(dst_sink_gated_clock),
    .cla_gated_reset_n_warm_ovrride(cla_gated_reset_n_warm_ovrride),
    .funnel_gated_clock(funnel_gated_clock),
    .funnel_gated_func_clamp(funnel_gated_func_clamp),
    .cla_gated_reset_n(cla_gated_reset_n),
    .cla_gated_clock(cla_gated_clock),
    .cla_gated_func_clamp(cla_gated_func_clamp),
    .i_clk(i_clk),
    .i_critical_signal_hold(i_critical_signal_hold),
    .i_rst_n(i_rst_n),
    .i_test_icg_en(i_test_icg_en),
    .ntr_func_enable(ntr_func_enable),
    .cla_func_enable(cla_func_enable),
    .dst_func_enable(dst_func_enable),
    .dst_sink_func_enable('0),
    .ntr_sink_func_enable('0),
    .funnel_func_enable('0),
    .dst_gated_clock(dst_gated_clock),
    .dst_gated_reset_n(dst_gated_reset_n),
    .dst_gated_func_clamp(dst_gated_func_clamp),
    .ntr_gated_reset_n(ntr_gated_reset_n),
    .ntr_gated_clock(ntr_gated_clock),
    .ntr_gated_func_clamp(ntr_gated_func_clamp),
    .tnif_gated_reset_n(tnif_gated_reset_n),
    .tnif_gated_func_clamp(tnif_gated_func_clamp),
    .tnif_gated_clock(tnif_gated_clock)
  );

  dst_wrapper #(
    .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH),
    .NUM_CLA_INST(NUM_CLA_INST),
    .NUM_DST_INST(NUM_DST_INST),
    .NUM_NTRACE_INST(NUM_NTRACE_INST)
  ) dst_wrapper (
    .i_sdtrig_control(i_sdtrig_control),
    .i_timestamp(i_timestamp),
    .dst_gated_clock(dst_gated_clock),
    .DstMmrs(DstMmrs),
    .tnif_dst_flush(tnif_dst_flush),
    .timesync_cla_timestamp(timesync_cla_timestamp),
    .tnif_dst_pull(tnif_dst_pull),
    .tnif_dst_bp(tnif_dst_bp),
    .debug_bus(debug_bus),
    .dst_gated_reset_n_warm_ovrride(dst_gated_reset_n_warm_ovrride),
    .dst_gated_reset_n(dst_gated_reset_n),
    .dst_gated_func_clamp(dst_gated_func_clamp),
    .cla_trigger_trace_start(o_cla_external_action_trace_start),
    .cla_trigger_trace_stop(o_cla_external_action_trace_stop),
    .cla_trigger_trace_pulse(o_cla_external_action_trace_pulse),
    .DstMmrsWr(DstMmrsWr),
    .dst_tnif_data(dst_tnif_data),
    .dst_tnif_req(dst_tnif_req)
  );

  mmrs #(
    .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH),
    .MMR_ADDR_WIDTH(MMR_ADDR_WIDTH),
    .MMR_AXI_ID_WIDTH(MMR_AXI_ID_WIDTH),
    .MMR_AXI_USER_WIDTH(MMR_AXI_USER_WIDTH),
    .MMR_BASE_ADDRESS(MMR_BASE_ADDRESS),
    .MMR_DATA_WIDTH(MMR_DATA_WIDTH),
    .NUM_CLA_INST(NUM_CLA_INST),
    .NUM_DST_INST(NUM_DST_INST),
    .NUM_NTRACE_INST(NUM_NTRACE_INST),
    .USE_AXI_INTF(0),
    .TRC_SIZE_IN_KB(0),
    .TRACE_SINK_SUPPORT(0)
  ) mmrs (
    .s_mmr_axi_rresp(s_mmr_axi_rresp),
    .FunnelMmrs(FunnelMmrs),
    .trRamDataRdEn(trRamDataRdEn),
    .s_mmr_axi_bresp(s_mmr_axi_bresp),
    .DstSinkMmrs(DstSinkMmrs),
    .s_mmr_axi_rdata(s_mmr_axi_rdata),
    .ntr_sink_func_enable(ntr_sink_func_enable),
    .s_mmr_axi_buser(s_mmr_axi_buser),
    .s_mmr_axi_arready(s_mmr_axi_arready),
    .s_mmr_axi_awready(s_mmr_axi_awready),
    .funnel_func_enable(funnel_func_enable),
    .trdstRamDataRdEn(trdstRamDataRdEn),
    .s_mmr_axi_bid(s_mmr_axi_bid),
    .s_mmr_axi_ruser(s_mmr_axi_ruser),
    .NtrSinkMmrs(NtrSinkMmrs),
    .s_mmr_axi_rid(s_mmr_axi_rid),
    .dst_sink_func_enable(dst_sink_func_enable),
    .s_mmr_axi_wready(s_mmr_axi_wready),
    .s_mmr_axi_rvalid(s_mmr_axi_rvalid),
    .s_mmr_axi_bvalid(s_mmr_axi_bvalid),
    .s_mmr_axi_rlast(s_mmr_axi_rlast),
    .ClaMmrs(ClaMmrs),
    .ntr_func_enable(ntr_func_enable),
    .cla_func_enable(cla_func_enable),
    .dst_func_enable(dst_func_enable),
    .DstMmrs(DstMmrs),
    .i_clk(i_clk),
    .i_critical_signal_hold(i_critical_signal_hold),
    .i_jtag_mmr_req_addr(i_jtag_mmr_req_addr),
    .i_jtag_mmr_req_data(i_jtag_mmr_req_data),
    .i_jtag_mmr_req_vld(i_jtag_mmr_req_vld),
    .i_jtag_mmr_req_we(i_jtag_mmr_req_we),
    .i_rst_n(i_rst_n),
    .paddr(paddr),
    .penable(penable),
    .psel(psel),
    .pstrb(pstrb),
    .pwdata(pwdata),
    .pwrite(pwrite),
    .o_jtag_mmr_rsp_data(o_jtag_mmr_rsp_data),
    .o_jtag_mmr_rsp_vld(o_jtag_mmr_rsp_vld),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr),
    .NtrMmrsWr(NtrMmrsWr),
    .ClaMmrsWr(ClaMmrsWr),
    .DstMmrsWr(DstMmrsWr),
    .s_mmr_axi_awid('0),
    .s_mmr_axi_awaddr('0),
    .s_mmr_axi_awlen('0),
    .s_mmr_axi_awsize('0),
    .s_mmr_axi_awburst('0),
    .s_mmr_axi_awlock('0),
    .s_mmr_axi_awcache('0),
    .s_mmr_axi_awprot('0),
    .s_mmr_axi_awqos('0),
    .s_mmr_axi_awregion('0),
    .s_mmr_axi_awatop('0),
    .s_mmr_axi_awuser('0),
    .s_mmr_axi_awvalid('0),
    .s_mmr_axi_wdata('0),
    .s_mmr_axi_wstrb('0),
    .s_mmr_axi_wlast('0),
    .s_mmr_axi_wuser('0),
    .s_mmr_axi_wvalid('0),
    .s_mmr_axi_bready('0),
    .s_mmr_axi_arid('0),
    .s_mmr_axi_araddr('0),
    .s_mmr_axi_arlen('0),
    .s_mmr_axi_arsize('0),
    .s_mmr_axi_arburst('0),
    .s_mmr_axi_arlock('0),
    .s_mmr_axi_arcache('0),
    .s_mmr_axi_arprot('0),
    .s_mmr_axi_arqos('0),
    .s_mmr_axi_arregion('0),
    .s_mmr_axi_aruser('0),
    .s_mmr_axi_arvalid('0),
    .s_mmr_axi_rready('0),
    .TraceRamWrEn('0),
    .FunnelMmrsWr('0),
    .DstSinkMmrsWr('0),
    .NtrSinkMmrsWr('0),
    .NtrMmrs(NtrMmrs)
  );

  ntr_wrapper #(
    .CONTEXT_WIDTH(CONTEXT_WIDTH),
    .IRETIRE_WIDTH(IRETIRE_WIDTH),
    .NUM_CLA_INST(NUM_CLA_INST),
    .NUM_DST_INST(NUM_DST_INST),
    .NUM_NTRACE_INST(NUM_NTRACE_INST),
    .PC_WIDTH(PC_WIDTH),
    .TSTAMP_WIDTH(TSTAMP_WIDTH),
    .TVAL_WIDTH(TVAL_WIDTH)
  ) ntr_wrapper (
    .NtrMmrsWr(NtrMmrsWr),
    .i_ntr_hart_te_context(i_ntr_hart_te_context),
    .i_ntr_hart_te_error(i_ntr_hart_te_error),
    .i_ntr_hart_te_iaddr(i_ntr_hart_te_iaddr),
    .i_ntr_hart_te_ilastsize(i_ntr_hart_te_ilastsize),
    .i_ntr_hart_te_iretire(i_ntr_hart_te_iretire),
    .i_ntr_hart_te_itype(i_ntr_hart_te_itype),
    .i_ntr_hart_te_priv(i_ntr_hart_te_priv),
    .i_ntr_hart_te_tstamp(i_ntr_hart_te_tstamp),
    .i_ntr_hart_te_tval(i_ntr_hart_te_tval),
    .i_sdtrig_control(i_sdtrig_control),
    .o_ntr_tr_active(o_ntr_tr_active),
    .o_ntr_tr_stall_mode_en(o_ntr_tr_stall_mode_en),
    .o_ntr_tr_start_backpressure(o_ntr_tr_start_backpressure),
    .o_ntr_tr_start_stop(o_ntr_tr_start_stop),
    .ntr_gated_reset_n(ntr_gated_reset_n),
    .ntr_gated_clock(ntr_gated_clock),
    .NtrMmrs(NtrMmrs),
    .tnif_ntr_flush(tnif_ntr_flush),
    .tnif_ntr_pull(tnif_ntr_pull),
    .ntr_gated_reset_n_warm_ovrride(ntr_gated_reset_n_warm_ovrride),
    .tnif_ntr_bp(tnif_ntr_bp),
    .ntr_gated_func_clamp(ntr_gated_func_clamp),
    .cla_trigger_trace_start(o_cla_external_action_trace_start),
    .cla_trigger_trace_stop(o_cla_external_action_trace_stop),
    .cla_trigger_trace_pulse(o_cla_external_action_trace_pulse),
    .ntr_tnif_data(ntr_tnif_data),
    .ntr_tnif_req(ntr_tnif_req)
  );

  tnif_wrapper #(
    .NUM_DST_INST(NUM_DST_INST),
    .NUM_NTRACE_INST(NUM_NTRACE_INST)
  ) tnif_wrapper (
    .tnif_dst_flush(tnif_dst_flush),
    .tnif_dst_pull(tnif_dst_pull),
    .tnif_dst_bp(tnif_dst_bp),
    .tnif_ntr_flush(tnif_ntr_flush),
    .tnif_ntr_pull(tnif_ntr_pull),
    .tnif_ntr_bp(tnif_ntr_bp),
    .tr_tnif_dst_bp(tr_tnif_dst_bp),
    .tr_tnif_dst_flush(tr_tnif_dst_flush),
    .tr_tnif_gnt(tr_tnif_gnt),
    .tr_tnif_ntr_bp(tr_tnif_ntr_bp),
    .tr_tnif_ntr_flush(tr_tnif_ntr_flush),
    .tnif_tr_data(tnif_tr_data),
    .tnif_tr_src(tnif_tr_src),
    .tnif_tr_valid(tnif_tr_valid),
    .tnif_gated_reset_n(tnif_gated_reset_n),
    .tnif_gated_func_clamp(tnif_gated_func_clamp),
    .dst_tnif_data(dst_tnif_data),
    .tnif_gated_reset_n_warm_ovrride(tnif_gated_reset_n_warm_ovrride),
    .tnif_gated_clock(tnif_gated_clock),
    .ntr_tnif_data(ntr_tnif_data),
    .dst_tnif_req(dst_tnif_req),
    .ntr_tnif_req(ntr_tnif_req),
    .dst_gated_func_clamp(dst_gated_func_clamp),
    .ntr_gated_func_clamp(ntr_gated_func_clamp)
  );

endmodule
