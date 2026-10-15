// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dfd_top_cla_dst_notrace_mmr
  import dfd_compat_pkg::*;
#(
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 1,
    parameter NTRACE_SUPPORT = 0,
    parameter bit DST_SUPPORT = 1,
    parameter bit CLA_SUPPORT = 1,
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

    input timestamp_s [NUM_TRACE_AND_ANALYZER_INST-1:0] CoreTime,

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

  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_INPUT_LANES-1:0][LANE_WIDTH-1:0] debug_bus_signals;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][63:0] timestamp;

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
      timestamp[ii]      = CoreTime[ii].time_val;
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
  assign external_action_trace_start     = '0;
  assign external_action_trace_stop      = '0;
  assign external_action_trace_pulse     = '0;

  dfd_top_cla_dst_apb_no_trace_top #(
      .DEBUGMARKER_WIDTH     (DEBUGMARKER_WIDTH),
      .DEBUG_SIGNAL_WIDTH    (DEBUG_SIGNALS_WIDTH),
      .LANE_WIDTH            (LANE_WIDTH),
      .MMR_ADDR_WIDTH        (MMR_ADDR_WIDTH),
      .MMR_DATA_WIDTH        (MMR_DATA_WIDTH),
      .NUM_CLA_INST          (NUM_TRACE_AND_ANALYZER_INST),
      .NUM_DST_INST          (NUM_TRACE_AND_ANALYZER_INST),
      .NUM_INPUT_LANES       (NUM_INPUT_LANES),
      .OCTS_TS_OUTPUT        (1'b0),
      .TIMESTAMP_SYNC_SCHEME (1'b1),
      .MMR_BASE_ADDRESS      (BASE_ADDR[MMR_ADDR_WIDTH-1:0])
  ) u_dfd_top (

      .i_clk                       (clk),
      .i_rst_n                     (reset_n),

      .i_critical_signal_hold      (1'b0),

      .i_test_icg_en               (1'b0),

      .i_debug_bus_signals         (debug_bus_signals),
      .i_cla_time_tick             (Time_Tick),
      .i_cla_ext_posedge           ('0),
      .i_cla_xtrigger              (xtrigger_in),
      .o_cla_xtrigger              (xtrigger_out),
      .o_cla_debug_marker          (cla_debug_marker),
      .o_cla_external_action_halt_clock_out(external_action_halt_clock_out),
      .o_cla_external_action_halt_clock_local_out(external_action_halt_clock_local_out),
      .o_cla_external_action_debug_interrupt_out(external_action_debug_interrupt_out),
      .o_cla_external_action_toggle_gpio_out(external_action_toggle_gpio_out),
      .o_cla_external_action_custom(external_action_custom),
      .o_debug_mux_sel             (),

      .i_timestamp                 (timestamp),
      .i_ref_timestamp             ('0),
      .i_octs_timestamp            ('0),

      .i_sdtrig_control            ('0),

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
                                  time_match_event};

endmodule
