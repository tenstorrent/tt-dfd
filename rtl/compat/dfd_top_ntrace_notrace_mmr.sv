// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dfd_top_ntrace_notrace_mmr
  import dfd_compat_pkg::*;
#(
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 1,
    parameter bit NTRACE_SUPPORT = 1,
    parameter DST_SUPPORT = 0,
    parameter CLA_SUPPORT = 0,
    parameter TRACE_SUPPORT = 0,
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

    // verilint W240 off
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_gnt_i,
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_dst_bp_i,
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_ntr_bp_i,
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_dst_flush_i,
    input  logic       [TNIF_CONNECTIONS-1:0]                          tnif_ntr_flush_i,
    // verilint W240 on
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_vld_o,
    output logic       [TNIF_CONNECTIONS-1:0]                          tnif_tr_src_o,
    output logic       [TNIF_CONNECTIONS-1:0][TR_TNIF_DATA_WIDTH-1:0]  tnif_tr_data_o,

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

  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][ 1:0] sdtrig_control;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][ 2:0] hart_te_priv;

  always_comb begin
    for (int unsigned ii = 0; ii < NUM_TRACE_AND_ANALYZER_INST; ii++) begin
      sdtrig_control[ii] = 2'(TrigControl[ii]);
      hart_te_priv[ii]   = 3'(Priv[ii]);
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

  dfd_top_ntrace_apb_no_trace_top #(
      .DEBUG_SIGNAL_WIDTH (DEBUG_SIGNALS_WIDTH),
      .MMR_ADDR_WIDTH     (MMR_ADDR_WIDTH),
      .MMR_DATA_WIDTH     (MMR_DATA_WIDTH),
      .NUM_NTRACE_INST    (NUM_TRACE_AND_ANALYZER_INST),
      .MMR_BASE_ADDRESS   (BASE_ADDR[MMR_ADDR_WIDTH-1:0])
  ) u_dfd_top (

      .i_clk                       (clk),
      .i_rst_n                     (reset_n),

      .i_critical_signal_hold      (1'b0),

      .i_test_icg_en               (1'b0),

      .i_ntr_hart_te_iretire       (IRetire),
      .i_ntr_hart_te_itype         (IType),
      .i_ntr_hart_te_iaddr         (IAddr),
      .i_ntr_hart_te_ilastsize     (ILastSize),
      .i_ntr_hart_te_tstamp        (Tstamp),
      .i_ntr_hart_te_priv          (hart_te_priv),
      .i_ntr_hart_te_context       (Context),
      .i_ntr_hart_te_tval          (Tval),
      .i_ntr_hart_te_error         (Error),
      .o_ntr_tr_active             (Active),
      .o_ntr_tr_stall_mode_en      (StallModeEn),
      .o_ntr_tr_start_stop         (StartStop),
      .o_ntr_tr_start_backpressure (Backpressure),
      .i_sdtrig_control            (sdtrig_control),

      .tnif_tr_valid               (tnif_tr_vld_o),
      .tnif_tr_src                 (tnif_tr_src_o),
      .tnif_tr_data                (tnif_tr_data_o),
      .tr_tnif_gnt                 (tnif_tr_gnt_i),
      .tr_tnif_dst_bp              (tnif_dst_bp_i),
      .tr_tnif_ntr_bp              (tnif_ntr_bp_i),
      .tr_tnif_dst_flush           (tnif_dst_flush_i),
      .tr_tnif_ntr_flush           (tnif_ntr_flush_i),

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
                                  external_cla_action_trace_pulse};

endmodule
