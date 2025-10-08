// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// *************************************************************************
// *
// * Open Source DFD (Data Flow Debugger) Top Module
// * __________________
// *
// * This file contains the main DFD top-level module with configurable
// * features for debugging and tracing.
// *
// *************************************************************************

module dfd_top_mmr
  import dfd_pkg::*;
  import dfd_cla_csr_pkg::*;
  import dfd_tr_csr_pkg::*;
  import dfd_mcr_csr_pkg::*;
  import dfd_dst_csr_pkg::*;
  import dfd_ntr_csr_pkg::*;
  import dfd_dst_pkg::*;
  import dfd_cla_pkg::*;
  import dfd_packetizer_pkg::*;
  import dfd_te_pkg::*;
  import dfd_tn_pkg::*;
  import dfd_CL_axi_pkg::*;
#(
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 1,
    localparam int unsigned TNIF_CONNECTIONS = (NUM_TRACE_AND_ANALYZER_INST <= 1) ? 2 : NUM_TRACE_AND_ANALYZER_INST,
	parameter NTRACE_SUPPORT = 0,
	parameter DST_SUPPORT = 0,
	parameter CLA_SUPPORT = 0,
    parameter bit INTERNAL_MMRS = 1,
    parameter int unsigned DEBUGMARKER_WIDTH = 8,  // CLA's Debug Marker Width
    parameter int unsigned TRC_SIZE_IN_KB = 16,
    parameter bit TSEL_CONFIGURABLE = 0,
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] BASE_ADDR = '0,
    parameter bit [DFD_APB_ADDR_WIDTH-1:0] TIMESYNC_ADDR_OFFSET = 'h200
) (
    //Globals
    input logic clk,
    input logic reset_n,
    input logic reset_n_warm_ovrride,
    input logic cold_reset_n,
    input logic [10:0] i_mem_tsel_settings,

    // EXTERNAL CLA
    // verilint W240 off
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_start,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_stop,
    input logic [NUM_TRACE_AND_ANALYZER_INST-1:0] external_cla_action_trace_pulse,
    // verilint W240 on

    // APB Interface
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

  // PARAMETERS
  localparam DATA_WIDTH_IN_BYTES = 16;  // Sets TNIF Data Width
  localparam TRC_RAM_INDEX = TRC_SIZE_IN_KB * 16;
  localparam TRC_SIZE_IN_B = TRC_SIZE_IN_KB * 1024;

  // Unused Signals - START
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][15:0] hw0,hw1,hw2,hw3,hw4,hw5,hw6,hw7;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][15:0] hw8,hw9,hw10,hw11,hw12,hw13,hw14,hw15;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]       Time_Tick;
  assign {hw0,hw1,hw2,hw3,hw4,hw5,hw6,hw7,hw8,hw9,hw10,hw11,hw12,hw13,hw14,hw15} = '0;
  assign Time_Tick = '0;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][XTRIGGER_WIDTH-1:0] xtrigger_in;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]                     time_match_event;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][DEBUGMARKER_WIDTH-1:0] cla_debug_marker;
  timestamp_s [NUM_TRACE_AND_ANALYZER_INST-1:0] timesync_cla_timestamp;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][XTRIGGER_WIDTH-1:0]  xtrigger_out;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_trace_start;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_trace_stop;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_trace_pulse;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_halt_clock_out;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_halt_clock_local_out;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_debug_interrupt_out;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0]  					  external_action_toggle_gpio_out;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] external_action_custom;
  assign xtrigger_in = '0;
  assign time_match_event = '0;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_BLOCKS-1:0][IRETIRE_WIDTH-1:0] IRetire;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_BLOCKS-1:0][  ITYPE_WIDTH-1:0] IType;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_BLOCKS-1:0][     PC_WIDTH-1:1] IAddr;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][NUM_BLOCKS-1:0]                    ILastSize;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][TSTAMP_WIDTH-1:0]                  Tstamp;
  PrivMode_e [NUM_TRACE_AND_ANALYZER_INST-1:0]                    Priv;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][CONTEXT_WIDTH-1:0] Context;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][TVAL_WIDTH-1:0]    Tval;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Error;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Active;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] StallModeEn;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] StartStop;
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0] Backpressure;
  TrigTraceControl_e    [NUM_TRACE_AND_ANALYZER_INST-1:0] TrigControl;
  assign {IRetire,IType,IAddr,ILastSize,Tstamp,Context,Tval,Error} = '0;
  assign Priv = {NUM_TRACE_AND_ANALYZER_INST{PRIVMODE_USER}};
  assign TrigControl = {NUM_TRACE_AND_ANALYZER_INST{TRIG_TRACE_NONE}};
  dfd_slv_axi_req_t	TR_EXT_SlvReq;
  dfd_slv_axi_rsp_t	EXT_TR_SlvResp;
  dfd_tr_slv_axi_rsp_t	TR_JT_SlvResp;
  dfd_tr_slv_axi_req_t	JT_TR_SlvReq;
  assign JT_TR_SlvReq = '0;
  assign EXT_TR_SlvResp = '0;
  DfdCsrs_s   		DfdCsrs_external;
  DfdCsrsWr_s 		DfdCsrsWr_external;
  assign DfdCsrs_external = '0;
  // Unused Signals - END

  //TNIF Connectivity
  logic [TNIF_CONNECTIONS-1:0] tnif_tr_gnt_in;
  logic [TNIF_CONNECTIONS-1:0] tnif_dst_bp_in, tnif_ntr_bp_in;
  logic [TNIF_CONNECTIONS-1:0] tnif_dst_flush_in, tnif_ntr_flush_in;

  logic [TNIF_CONNECTIONS-1:0] tnif_tr_vld_out;
  logic [TNIF_CONNECTIONS-1:0] tnif_tr_src_out;
  logic [TNIF_CONNECTIONS-1:0][DATA_WIDTH_IN_BYTES*8-1:0] tnif_tr_data_out;

  // Debug Bus
  logic [NUM_TRACE_AND_ANALYZER_INST-1:0][DEBUG_SIGNALS_WIDTH-1:0] debug_bus, debug_bus_aligned;

  // DFD TimeSync
  logic       [    NUM_TRACE_AND_ANALYZER_INST-1:0]                         timesync_pready;
  logic       [    NUM_TRACE_AND_ANALYZER_INST-1:0]                         timesync_pslverr;
  logic       [    NUM_TRACE_AND_ANALYZER_INST-1:0][DFD_APB_DATA_WIDTH-1:0] timesync_prdata;
  logic       [    NUM_TRACE_AND_ANALYZER_INST-1:0]                         timesync_reghit;

  // DFD MMRs
  DfdCsrs_s                                                    DfdCsrs;
  DfdCsrsWr_s                                                  DfdCsrsWr;
  logic                                                        dfdmmr_pready;
  logic                                                        dfdmmr_pslverr;
  logic       [DFD_APB_DATA_WIDTH-1:0]                         dfdmmr_prdata;

  dfd_mmrs #(
      .INTERNAL_MMRS(INTERNAL_MMRS),
      .NTRACE_SUPPORT(NTRACE_SUPPORT),
      .DST_SUPPORT(DST_SUPPORT),
      .CLA_SUPPORT(CLA_SUPPORT),
      .NUM_TRACE_AND_ANALYZER_INST(NUM_TRACE_AND_ANALYZER_INST),
      .TRC_SIZE_IN_B(TRC_SIZE_IN_B),
      .BASE_ADDR(BASE_ADDR[DFD_APB_ADDR_WIDTH-1:0])
  ) u_dfd_mmrs (
      .clk                 (clk),
      .reset_n             (reset_n),
      .reset_n_warm_ovrride(reset_n_warm_ovrride),
      .cold_reset_n        (cold_reset_n),
      .DfdCsrs             (DfdCsrs),
      .DfdCsrsWr           (DfdCsrsWr),
      .DfdCsrs_external    (DfdCsrs_external),
      .DfdCsrsWr_external  (DfdCsrsWr_external),
      .paddr               (paddr),
      .psel                (psel),
      .penable             (penable),
      .pstrb               (pstrb),
      .pwrite              (pwrite),
      .pwdata              (pwdata),
      .pready              (dfdmmr_pready),
      .prdata              (dfdmmr_prdata),
      .pslverr             (dfdmmr_pslverr)
  );

  if (CLA_SUPPORT == 1) begin : apb_cla_connection
    always_comb begin
      pready  = dfdmmr_pready;
      prdata  = dfdmmr_prdata;
      pslverr = dfdmmr_pslverr;
      for (int ii = 0; ii < NUM_TRACE_AND_ANALYZER_INST; ii++) begin
        if (timesync_reghit[ii]) begin
          pready  = timesync_pready[ii];
          prdata  = timesync_prdata[ii];
          pslverr = timesync_pslverr[ii];
        end
      end
    end
  end else begin : apb_no_cla_connection
    assign pready  = dfdmmr_pready;
    assign prdata  = dfdmmr_prdata;
    assign pslverr = dfdmmr_pslverr;
  end

  if ((CLA_SUPPORT == 1) || (DST_SUPPORT == 1)) begin : dbm_gen_blk
    for (genvar ii = 0; ii < NUM_TRACE_AND_ANALYZER_INST; ii++) begin : dbm_gen_inst_blk
      dfd_mux_sel #(
          .DEBUG_BUS_WIDTH(DEBUG_SIGNALS_WIDTH),
          .ID_INDEX(ii)
      ) u_dfd_mux_sel (
          .clk                 (clk),
          .reset_n             (reset_n),
          .reset_n_warm_ovrride(reset_n_warm_ovrride),
          .hw0                 (hw0[ii]),
          .hw1                 (hw1[ii]),
          .hw2                 (hw2[ii]),
          .hw3                 (hw3[ii]),
          .hw4                 (hw4[ii]),
          .hw5                 (hw5[ii]),
          .hw6                 (hw6[ii]),
          .hw7                 (hw7[ii]),
          .hw8                 (hw8[ii]),
          .hw9                 (hw9[ii]),
          .hw10                (hw10[ii]),
          .hw11                (hw11[ii]),
          .hw12                (hw12[ii]),
          .hw13                (hw13[ii]),
          .hw14                (hw14[ii]),
          .hw15                (hw15[ii]),
          .Time_Tick           (Time_Tick[ii]),
          .DbgMuxSelCsr        (DfdCsrs.McrCsrs.CrCsrCdbgmuxsel),
          .debug_bus           (debug_bus[ii])
      );
    end
  end else begin : dbm_no_gen_blk
    assign debug_bus = '0;
  end

  if (CLA_SUPPORT == 1) begin : cla_gen_blk
    for (genvar ii = 0; ii < MAX_NUM_TRACE_INST; ii++) begin : cla_gen_inst_blk
      if (ii < NUM_TRACE_AND_ANALYZER_INST) begin
        dfd_time_sync #(
            .DFD_APB_ADDR_WIDTH(DFD_APB_ADDR_WIDTH),
            .BASE_ADDR(BASE_ADDR[DFD_APB_ADDR_WIDTH-1:0] + 23'h9000 * ii ), // .BASE_ADDR(BASE_ADDR[DFD_APB_ADDR_WIDTH-1:0])
            .START_OFFSET(TIMESYNC_ADDR_OFFSET)
        ) time_sync_block (
            .i_clk         (clk),
            .i_reset_n     (reset_n),
            .i_reset_n_warm(reset_n_warm_ovrride),
            .i_paddr       (paddr),
            .i_psel        (psel),
            .i_penable     (penable),
            .i_pstrb       (pstrb),
            .i_pwrite      (pwrite),
            .i_pwdata      (pwdata),
            .o_pready      (timesync_pready[ii]),
            .o_prdata      (timesync_prdata[ii]),
            .o_pslverr     (timesync_pslverr[ii]),
            .o_reg_hit     (timesync_reghit[ii]),

            .i_xtrigger   (xtrigger_in[ii][0]), // xtrigger[0] for timesync
            .i_time_tick  (Time_Tick[ii]),
            .o_timestamp  (timesync_cla_timestamp[ii]),
            .o_debug_marker  (cla_debug_marker[ii])
        );

        dfd_core_logic_analyzer #(
            .CORE_INSTANCE(1'b1)
        ) cla0 (
            .clock                           (clk),
            .reset_n                         (reset_n),
            .reset_n_warm_ovrride            (reset_n_warm_ovrride),
            .debug_signals                   (debug_bus[ii]),
            .xtrigger_in                     (xtrigger_in[ii]),
            .xtrigger_out                    (xtrigger_out[ii]),
            .external_action_halt_clock_local(external_action_halt_clock_local_out[ii]),
            .external_action_halt_clock      (external_action_halt_clock_out[ii]),
            .external_action_debug_interrupt (external_action_debug_interrupt_out[ii]),
            .external_action_toggle_gpio     (external_action_toggle_gpio_out[ii]),
            .external_action_trace_start     (external_action_trace_start[ii]),
            .external_action_trace_stop      (external_action_trace_stop[ii]),
            .external_action_trace_pulse     (external_action_trace_pulse[ii]),
            .external_action_custom          (external_action_custom[ii]),
            .debug_signals_aligned           (debug_bus_aligned[ii]),
            .time_match_event                (time_match_event[ii]),

            // MMRs
            .ClacounterCfg0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter0Cfg),
            .ClacounterCfg1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter1Cfg),
            .ClacounterCfg2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter2Cfg),
            .ClacounterCfg3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter3Cfg),
            .Node0Eap0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap0),
            .Node0Eap1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap1),
            .Node0Eap2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap2),
            .Node0Eap3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap3),
            .Node1Eap0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap0),
            .Node1Eap1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap1),
            .Node1Eap2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap2),
            .Node1Eap3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap3),
            .Node2Eap0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap0),
            .Node2Eap1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap1),
            .Node2Eap2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap2),
            .Node2Eap3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap3),
            .Node3Eap0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap0),
            .Node3Eap1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap1),
            .Node3Eap2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap2),
            .Node3Eap3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap3),
            .Debugsignalmask0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask0),
            .Debugsignalmatch0Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch0),
            .Debugsignalmask1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask1),
            .Debugsignalmatch1Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch1),
            .Debugsignalmask2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask2),
            .Debugsignalmatch2Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch2),
            .Debugsignalmask3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask3),
            .Debugsignalmatch3Csr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch3),
            .DebugsignaledgedetectcfgCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignaledgedetectcfg),
            .EapstatusCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgeapstatus),
            .ClactrlstatusCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclactrlstatus),
            .Clacounter0CfgCsrWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter0CfgWr),
            .Clacounter1CfgCsrWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter1CfgWr),
            .Clacounter2CfgCsrWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter2CfgWr),
            .Clacounter3CfgCsrWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter3CfgWr),
            .DebugsignalTransitionmaskCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitionmask),
            .DebugsignalTransitionfromCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitionfromvalue),
            .DebugsignalTransitiontoCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitiontovalue),
            .DebugsignalOnescountmaskCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgonescountmask),
            .DebugsignalOnescountvalueCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgonescountvalue),
            .DebugsignalchangeCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbganychange),
            .DebugsignaldelaymuxselCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignaldelaymuxsel),
            .XtriggertimestretchCsr(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclaxtriggertimestretch),
            .EapstatusWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgeapstatusWr),
            .ClactrlstatusWr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclactrlstatusWr),
            .DbgSignalSnapShotNode0Eap0CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap0Wr),
            .DbgSignalSnapShotNode0Eap1CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap1Wr),
            .DbgSignalSnapShotNode0Eap2CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap2Wr),
            .DbgSignalSnapShotNode0Eap3CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap3Wr),
            .DbgSignalSnapShotNode1Eap0CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap0Wr),
            .DbgSignalSnapShotNode1Eap1CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap1Wr),
            .DbgSignalSnapShotNode1Eap2CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap2Wr),
            .DbgSignalSnapShotNode1Eap3CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap3Wr),
            .DbgSignalSnapShotNode2Eap0CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap0Wr),
            .DbgSignalSnapShotNode2Eap1CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap1Wr),
            .DbgSignalSnapShotNode2Eap2CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap2Wr),
            .DbgSignalSnapShotNode2Eap3CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap3Wr),
            .DbgSignalSnapShotNode3Eap0CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap0Wr),
            .DbgSignalSnapShotNode3Eap1CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap1Wr),
            .DbgSignalSnapShotNode3Eap2CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap2Wr),
            .DbgSignalSnapShotNode3Eap3CsrWr	(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap3Wr)
        );
      end else begin
        assign DfdCsrsWr.ClaCsrsWr[ii] = '0;
      end
    end
  end else begin
    assign xtrigger_out                         = '0;
    assign external_action_halt_clock_out       = '0;
    assign external_action_halt_clock_local_out = '0;
    assign external_action_debug_interrupt_out  = '0;
    assign external_action_toggle_gpio_out      = '0;
    assign cla_debug_marker                     = '0;
    assign timesync_cla_timestamp               = '0;
    assign external_action_trace_start          = external_cla_action_trace_start;
    assign external_action_trace_stop           = external_cla_action_trace_stop;
    assign external_action_trace_pulse          = external_cla_action_trace_pulse;
    assign external_action_custom               = '0;

    assign DfdCsrsWr.ClaCsrsWr                  = '0;
  end

  for (genvar ii = 0; ii < MAX_NUM_TRACE_INST; ii++) begin : dfd_unit_gen_blk
    if (ii < NUM_TRACE_AND_ANALYZER_INST) begin : dfd_unit_real
      dfd_unit #(
          .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
          .NTRACE_SUPPORT(NTRACE_SUPPORT),
          .DST_SUPPORT(DST_SUPPORT)
      ) u_dfd_unit (
          .clk                        (clk),
          .reset_n                    (reset_n),
          .reset_n_warm_ovrride       (reset_n_warm_ovrride),
          .external_action_trace_start(external_action_trace_start[ii]),
          .external_action_trace_stop (external_action_trace_stop[ii]),
          .external_action_trace_pulse(external_action_trace_pulse[ii]),
          .debug_bus                  (debug_bus_aligned[ii]),
          .CoreTime                   (timesync_cla_timestamp[ii]),
          .DstCsrs                    (DfdCsrs.DstCsrs[ii]),
          .NtrCsrs                    (DfdCsrs.NtrCsrs[ii]),
          .DstCsrsWr                  (DfdCsrsWr.DstCsrsWr[ii]),
          .NtrCsrsWr                  (DfdCsrsWr.NtrCsrsWr[ii]),
          .IRetire                    (IRetire[ii]),
          .IType                      (IType[ii]),
          .IAddr                      (IAddr[ii]),
          .ILastSize                  (ILastSize[ii]),
          .Tstamp                     (Tstamp[ii]),
          .Priv                       (Priv[ii]),
          .Context                    (Context[ii]),
          .Tval                       (Tval[ii]),
          .Error                      (Error[ii]),
          .Active                     (Active[ii]),
          .StallModeEn                (StallModeEn[ii]),
          .StartStop                  (StartStop[ii]),
          .Backpressure               (Backpressure[ii]),
          .TrigControl                (TrigControl[ii]),
          .tnif_tr_gnt_in             (tnif_tr_gnt_in[ii]),
          .tnif_dst_bp_in             (tnif_dst_bp_in[ii]),
          .tnif_ntr_bp_in             (tnif_ntr_bp_in[ii]),
          .tnif_dst_flush_in          (tnif_dst_flush_in[ii]),
          .tnif_ntr_flush_in          (tnif_ntr_flush_in[ii]),
          .tnif_tr_vld_out            (tnif_tr_vld_out[ii]),
          .tnif_tr_src_out            (tnif_tr_src_out[ii]),
          .tnif_tr_data_out           (tnif_tr_data_out[ii])
      );
    end else if (ii < TNIF_CONNECTIONS) begin : dfd_unit_virtual
      assign tnif_tr_vld_out[ii] = '0;
      assign tnif_tr_src_out[ii] = '0;
      assign tnif_tr_data_out[ii] = '0;
      assign DfdCsrsWr.DstCsrsWr[ii] = '0;
      assign DfdCsrsWr.NtrCsrsWr[ii] = '0;
    end else begin : dfd_unit_none
      assign DfdCsrsWr.DstCsrsWr[ii] = '0;
      assign DfdCsrsWr.NtrCsrsWr[ii] = '0;
    end
  end

  // Trace Top (Contains Trace Network -> Trace Funnel -> Trace Mem)
  if ((DST_SUPPORT == 1) || (NTRACE_SUPPORT == 1)) begin : trace_top_gen_blk
    dfd_trace_top #(
        .NUM_CORES(TNIF_CONNECTIONS),  // Minimum 2 TNIFs
        .NUM_ACTIVE_CORES(NUM_TRACE_AND_ANALYZER_INST),
        .BASE_ADDR(BASE_ADDR[DFD_APB_ADDR_WIDTH-1:0]),
        .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
        .TRC_RAM_INDEX(TRC_RAM_INDEX),
        .TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
        .SINK_CELL(SINK_CELL)
    ) u_trace_top (
        .clk                (clk),
        .reset_n            (reset_n),
        // .cold_reset_n		(cold_reset_n),
        .i_mem_tsel_settings(i_mem_tsel_settings),

        // Trace Network (TNIF Interface)
        .TN_MS_Gnt   (tnif_tr_gnt_in),
        .TN_MS_Dst_Bp  (tnif_dst_bp_in),
        .TN_MS_Ntrace_Bp (tnif_ntr_bp_in),
        .TN_MS_Dst_Flush (tnif_dst_flush_in),
        .TN_MS_Ntrace_Flush (tnif_ntr_flush_in),
        .MS_TN_Vld   (tnif_tr_vld_out),
        .MS_TN_Src   (tnif_tr_src_out),
        .MS_TN_Data   (tnif_tr_data_out),

        // Trace DFD MMRs
        .TrCsrs  (DfdCsrs.TrCsrs),
        .TrCsrsWr(DfdCsrsWr.TrCsrsWr),

        // Trace Funnel
        // AXI Interface the Memory
        .TR_AB_SlvReq_Rx (TR_EXT_SlvReq),
        .AB_TR_SlvResp_Tx(EXT_TR_SlvResp),

        // JTAG-AXI Control Interface
        .JT_TR_SlvReq (JT_TR_SlvReq),
        .TR_JT_SlvResp(TR_JT_SlvResp),

        // JTAG-MMR Control Interface
        .jt_tr_mmr_req_vld_o (psel & ~penable),
        .jt_tr_mmr_req_we_o  (pwrite),
        .jt_tr_mmr_req_addr_o(paddr),
        .jt_tr_mmr_req_data_o(pwdata[31:0]),
        .tr_jt_mmr_rsp_data_i(),
        .tr_jt_mmr_rsp_vld_i ()
    );
  end else begin
    assign tnif_tr_gnt_in = '0;
    assign tnif_dst_bp_in = '0;
    assign tnif_ntr_bp_in = '0;
    assign tnif_dst_flush_in = '0;
    assign tnif_ntr_flush_in = '0;
  end

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eus]$"
// End:

