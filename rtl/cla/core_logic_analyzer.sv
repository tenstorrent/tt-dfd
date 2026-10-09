// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module core_logic_analyzer
import cla_mmr_pkg::*;
import cla_pkg::*;
import dst_pkg::*;
#(
  parameter CORE_INSTANCE = 1'b0,
  parameter DEBUG_SIGNAL_WIDTH = 128,
  parameter bit TIMESTAMP_SYNC_SCHEME = 0,

  localparam TIMESTAMP_UPPER_WIDTH = 56,
  localparam TIMESTAMP_LOWER_WIDTH = 8
)
(
  input logic       clock,
  input logic       i_reset_n,
  input  logic      reset_n_warm_ovrride,
  input  logic   [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
  input  logic   [XTRIGGER_WIDTH-1:0]      xtrigger_in,
  input  logic                             i_ext_posedge,
  output logic   [XTRIGGER_WIDTH-1:0]      xtrigger_out,
  output logic                             external_action_halt_clock_local,
  output logic                             external_action_halt_clock,
  output logic                             external_action_debug_interrupt,
  output logic                             external_action_toggle_gpio,
  output logic                             external_action_trace_start,
  output logic                             external_action_trace_stop,
  output logic                             external_action_trace_pulse,
  output logic  [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  external_action_custom,
  output logic  [DEBUG_SIGNAL_WIDTH-1:0]  debug_signals_aligned,

  input ClaCdbgclacounter0CfgMmr_s                    ClacounterCfg0Mmr,
  input ClaCdbgclacounter1CfgMmr_s                    ClacounterCfg1Mmr,
  input ClaCdbgclacounter2CfgMmr_s                    ClacounterCfg2Mmr,
  input ClaCdbgclacounter3CfgMmr_s                    ClacounterCfg3Mmr,
  input ClaCdbgnode0Eap0Mmr_s                         Node0Eap0Mmr,
  input ClaCdbgnode0Eap1Mmr_s                         Node0Eap1Mmr,
  input ClaCdbgnode0Eap2Mmr_s                         Node0Eap2Mmr,
  input ClaCdbgnode0Eap3Mmr_s                         Node0Eap3Mmr,
  input ClaCdbgnode1Eap0Mmr_s                         Node1Eap0Mmr,
  input ClaCdbgnode1Eap1Mmr_s                         Node1Eap1Mmr,
  input ClaCdbgnode1Eap2Mmr_s                         Node1Eap2Mmr,
  input ClaCdbgnode1Eap3Mmr_s                         Node1Eap3Mmr,
  input ClaCdbgnode2Eap0Mmr_s                         Node2Eap0Mmr,
  input ClaCdbgnode2Eap1Mmr_s                         Node2Eap1Mmr,
  input ClaCdbgnode2Eap2Mmr_s                         Node2Eap2Mmr,
  input ClaCdbgnode2Eap3Mmr_s                         Node2Eap3Mmr,
  input ClaCdbgnode3Eap0Mmr_s                         Node3Eap0Mmr,
  input ClaCdbgnode3Eap1Mmr_s                         Node3Eap1Mmr,
  input ClaCdbgnode3Eap2Mmr_s                         Node3Eap2Mmr,
  input ClaCdbgnode3Eap3Mmr_s                         Node3Eap3Mmr,
  input ClaCdbgsignalmask0LoMmr_s                     DebugsignalMask0LoMmr,
  input ClaCdbgsignalmask0HiMmr_s                     DebugsignalMask0HiMmr,
  input ClaCdbgsignalmatch0LoMmr_s                    DebugsignalMatch0LoMmr,
  input ClaCdbgsignalmatch0HiMmr_s                    DebugsignalMatch0HiMmr,
  input ClaCdbgsignalmask1LoMmr_s                     DebugsignalMask1LoMmr,
  input ClaCdbgsignalmask1HiMmr_s                     DebugsignalMask1HiMmr,
  input ClaCdbgsignalmatch1LoMmr_s                    DebugsignalMatch1LoMmr,
  input ClaCdbgsignalmatch1HiMmr_s                    DebugsignalMatch1HiMmr,
  input ClaCdbgsignalmask2LoMmr_s                     DebugsignalMask2LoMmr,
  input ClaCdbgsignalmask2HiMmr_s                     DebugsignalMask2HiMmr,
  input ClaCdbgsignalmatch2LoMmr_s                    DebugsignalMatch2LoMmr,
  input ClaCdbgsignalmatch2HiMmr_s                    DebugsignalMatch2HiMmr,
  input ClaCdbgsignalmask3LoMmr_s                     DebugsignalMask3LoMmr,
  input ClaCdbgsignalmask3HiMmr_s                     DebugsignalMask3HiMmr,
  input ClaCdbgsignalmatch3LoMmr_s                    DebugsignalMatch3LoMmr,
  input ClaCdbgsignalmatch3HiMmr_s                    DebugsignalMatch3HiMmr,
  input ClaCdbgsignaledgedetectcfgMmr_s               DebugsignalEdgedetectcfgMmr,
  input ClaCdbgeapstatusMmr_s                         EapstatusMmr,
  input ClaCdbgclactrlstatusMmr_s                     ClactrlstatusMmr,
  input ClaCdbgtransitionmaskloMmr_s                 DebugsignalTransitionmaskLoMmr,
  input ClaCdbgtransitionmaskhiMmr_s                 DebugsignalTransitionmaskHiMmr,
  input ClaCdbgtransitionfromvalueloMmr_s            DebugsignalTransitionfromLoMmr,
  input ClaCdbgtransitionfromvaluehiMmr_s            DebugsignalTransitionfromHiMmr,
  input ClaCdbgtransitiontovalueloMmr_s              DebugsignalTransitiontoLoMmr,
  input ClaCdbgtransitiontovaluehiMmr_s              DebugsignalTransitiontoHiMmr,
  input ClaCdbgonescountmaskloMmr_s                  DebugsignalOnescountmaskLoMmr,
  input ClaCdbgonescountmaskhiMmr_s                  DebugsignalOnescountmaskHiMmr,
  input ClaCdbgonescountvalueMmr_s                    DebugsignalOnescountvalueMmr,
  input ClaCdbganychangeloMmr_s                      DebugsignalchangeLoMmr,
  input ClaCdbganychangehiMmr_s                      DebugsignalchangeHiMmr,
  input ClaCdbgsignaldelaymuxselMmr_s                 DebugsignaldelaymuxselMmr,
  input ClaCdbgclaxtriggertimestretchMmr_s            XtriggertimestretchMmr,
  input ClaCdbgclatimestampMmr_s                    ClatimestampMmr,
  input ClaCdbgclatimestampsyncMmr_s                ClatimestampsyncMmr,
  input ClaCdbgclatimestampoffsetMmr_s              ClatimestampoffsetMmr,
  input ClaCdbgclatimestampconfigMmr_s              ClatimestampconfigMmr,
  input ClaCdbgclatimematchMmr_s                    ClatimematchMmr,
  input ClaCdbglfsrMmr_s                            ClaMmrCdbglfsr,
  input ClaCdbglfsrmaskMmr_s                        ClaMmrCdbglfsrmask,
  input ClaCdbgcompare0LoMmr_s                   ClaMmrCdbgcompare0Lo,
  input ClaCdbgcompare0MaskloMmr_s               ClaMmrCdbgcompare0Masklo,
  input ClaCdbgcompare1LoMmr_s                   ClaMmrCdbgcompare1Lo,
  input ClaCdbgcompare1MaskloMmr_s               ClaMmrCdbgcompare1Masklo,
  input ClaCdbgcompare2LoMmr_s                   ClaMmrCdbgcompare2Lo,
  input ClaCdbgcompare2MaskloMmr_s               ClaMmrCdbgcompare2Masklo,
  input ClaCdbgcompare3LoMmr_s                   ClaMmrCdbgcompare3Lo,
  input ClaCdbgcompare3MaskloMmr_s               ClaMmrCdbgcompare3Masklo,
  input ClaCdbgcompare0HiMmr_s                   ClaMmrCdbgcompare0Hi,
  input ClaCdbgcompare0MaskhiMmr_s               ClaMmrCdbgcompare0Maskhi,
  input ClaCdbgcompare1HiMmr_s                   ClaMmrCdbgcompare1Hi,
  input ClaCdbgcompare1MaskhiMmr_s               ClaMmrCdbgcompare1Maskhi,
  input ClaCdbgcompare2HiMmr_s                   ClaMmrCdbgcompare2Hi,
  input ClaCdbgcompare2MaskhiMmr_s               ClaMmrCdbgcompare2Maskhi,
  input ClaCdbgcompare3HiMmr_s                   ClaMmrCdbgcompare3Hi,
  input ClaCdbgcompare3MaskhiMmr_s               ClaMmrCdbgcompare3Maskhi,

  input logic                                     i_Time_Tick,
  input logic [TIMESTAMP_UPPER_WIDTH-1:0]         i_ref_timestamp,
  input timestamp_s                               timestamp,

  output ClaCdbgclacounter0CfgMmrWr_s                 Clacounter0CfgMmrWr,
  output ClaCdbgclacounter1CfgMmrWr_s                 Clacounter1CfgMmrWr,
  output ClaCdbgclacounter2CfgMmrWr_s                 Clacounter2CfgMmrWr,
  output ClaCdbgclacounter3CfgMmrWr_s                 Clacounter3CfgMmrWr,
  output ClaCdbgeapstatusMmrWr_s                      EapstatusWr,
  output ClaCdbgclactrlstatusMmrWr_s                  ClactrlstatusWr,
  output ClaCdbgclatimestampMmrWr_s                   ClatimestampWr,
  output ClaCdbgclatimestampconfigMmrWr_s             ClatimestampconfigWr,
  output ClaCdbgsignalsnapshotnode0Eap0LoMmrWr_s      DbgSignalSnapShotNode0Eap0LoMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap0HiMmrWr_s      DbgSignalSnapShotNode0Eap0HiMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap1LoMmrWr_s      DbgSignalSnapShotNode0Eap1LoMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap1HiMmrWr_s      DbgSignalSnapShotNode0Eap1HiMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap2LoMmrWr_s      DbgSignalSnapShotNode0Eap2LoMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap2HiMmrWr_s      DbgSignalSnapShotNode0Eap2HiMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap3LoMmrWr_s      DbgSignalSnapShotNode0Eap3LoMmrWr,
  output ClaCdbgsignalsnapshotnode0Eap3HiMmrWr_s      DbgSignalSnapShotNode0Eap3HiMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap0LoMmrWr_s      DbgSignalSnapShotNode1Eap0LoMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap0HiMmrWr_s      DbgSignalSnapShotNode1Eap0HiMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap1LoMmrWr_s      DbgSignalSnapShotNode1Eap1LoMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap1HiMmrWr_s      DbgSignalSnapShotNode1Eap1HiMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap2LoMmrWr_s      DbgSignalSnapShotNode1Eap2LoMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap2HiMmrWr_s      DbgSignalSnapShotNode1Eap2HiMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap3LoMmrWr_s      DbgSignalSnapShotNode1Eap3LoMmrWr,
  output ClaCdbgsignalsnapshotnode1Eap3HiMmrWr_s      DbgSignalSnapShotNode1Eap3HiMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap0LoMmrWr_s      DbgSignalSnapShotNode2Eap0LoMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap0HiMmrWr_s      DbgSignalSnapShotNode2Eap0HiMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap1LoMmrWr_s      DbgSignalSnapShotNode2Eap1LoMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap1HiMmrWr_s      DbgSignalSnapShotNode2Eap1HiMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap2LoMmrWr_s      DbgSignalSnapShotNode2Eap2LoMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap2HiMmrWr_s      DbgSignalSnapShotNode2Eap2HiMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap3LoMmrWr_s      DbgSignalSnapShotNode2Eap3LoMmrWr,
  output ClaCdbgsignalsnapshotnode2Eap3HiMmrWr_s      DbgSignalSnapShotNode2Eap3HiMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap0LoMmrWr_s      DbgSignalSnapShotNode3Eap0LoMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap0HiMmrWr_s      DbgSignalSnapShotNode3Eap0HiMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap1LoMmrWr_s      DbgSignalSnapShotNode3Eap1LoMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap1HiMmrWr_s      DbgSignalSnapShotNode3Eap1HiMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap2LoMmrWr_s      DbgSignalSnapShotNode3Eap2LoMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap2HiMmrWr_s      DbgSignalSnapShotNode3Eap2HiMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap3LoMmrWr_s      DbgSignalSnapShotNode3Eap3LoMmrWr,
  output ClaCdbgsignalsnapshotnode3Eap3HiMmrWr_s      DbgSignalSnapShotNode3Eap3HiMmrWr,
  output ClaCdbglfsrMmrWr_s                           ClaMmrCdbglfsrWr,
  output ClaCdbgtimestampcaptureMmrWr_s               ClaMmrCdbgtimestampcaptureWr,

  output timestamp_s                              o_cla_timesync_timestamp,
  output logic [7:0]                               o_cla_debug_marker
  );

localparam DBG_SIGNAL_CONFIG = DEBUG_SIGNAL_WIDTH == 128 ? 1'b1 : 1'b0;

counter_controls                    counter_actions[CLA_NUMBER_OF_COUNTERS];
logic [CLA_NUMBER_OF_EVENTS-1:0]          event_bus, event_bus_mod;

logic [CLA_NUMBER_OF_ACTIONS-1:0]         next_node_action_bus[CLA_NUMBER_OF_NODES];
logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  next_node_custom_action_bus[CLA_NUMBER_OF_NODES];
logic [CLA_NODE_ID_MSB:0]                 next_destination_node_id [CLA_NUMBER_OF_NODES];
logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0]   node_eap_status[CLA_NUMBER_OF_NODES];
logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0]   node_eap_status_w2c[CLA_NUMBER_OF_NODES];
logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0]   reset_eap_status_w2c[CLA_NUMBER_OF_NODES];
logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0]   snapshot_capture_per_eap[CLA_NUMBER_OF_NODES];
logic [CLA_NODE_ID_MSB:0]                 current_node_id;
logic [XTRIGGER_WIDTH-1:0]                self_filter;
logic                                     debug_interrupt_pulse;
logic [XTRIGGER_WIDTH-1:0]                xtrigger_in_d1;
logic [XTRIGGER_WIDTH-1:0]                xtrigger_out_pre_ff, xtrigger_out_stretch;
logic                                     time_match_event;

ClacounterCfgMmr_s    ClacounterCfgMmr[CLA_NUMBER_OF_COUNTERS];

logic   [DEBUG_SIGNAL_WIDTH-1:0] debug_signals_d1;
logic   [63:0] cla_sync_timestamp;

debug_signal_shift_mux #(
  .DEBUG_MUX_OUTPUT_WIDTH(DEBUG_SIGNAL_WIDTH)
) debug_signal_shift_mux_inst (
  .clock(clock),
  .reset_n(i_reset_n),
  .reset_n_warm_ovrride(reset_n_warm_ovrride),
  .debug_signals_in(debug_signals),
  .debug_signals_out(debug_signals_aligned),
  .DebugSignalDelayMuxsel(DebugsignaldelaymuxselMmr)
);

assign time_match_event = (timestamp.time_val >= ClatimematchMmr.TimeMatchVal) && (|ClatimematchMmr.TimeMatchVal);

generate
  if(CORE_INSTANCE == 1'b1) begin : gen_event_bus_mod_core_instance
    always_comb begin
      event_bus_mod = event_bus;
      event_bus_mod[15] = time_match_event & ClactrlstatusMmr.EnableEap;
    end
  end
  else begin : gen_event_bus_mod_tieoff
    assign event_bus_mod = event_bus;
  end
endgenerate

logic i_xtrigger_ff, xtrigger_posedge;

generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) xtrigger_edge_det (
    .clk   (clock),
    .rst_n (i_reset_n),
    .en    ('1),
    .in    (xtrigger_in[0]),
    .out   (i_xtrigger_ff)
);
assign xtrigger_posedge = xtrigger_in[0] && ~i_xtrigger_ff;

  assign o_cla_debug_marker = ClatimestampconfigMmr.DebugMarker;

if (TIMESTAMP_SYNC_SCHEME == 0) begin : gen_timestamp_sync_scheme_0

  logic [63:0]              timestamp_nxt;
  logic timestamp_load;
  logic timestamp_resync;
  logic [63:0] timestamp_full;
  assign timestamp_full = {ClatimestampMmr.TimestampUpper, ClatimestampMmr.TimestampLower};
  assign timestamp_resync = ClatimestampconfigMmr.Resync;
  assign timestamp_load   = timestamp_resync && xtrigger_posedge;
  assign timestamp_nxt    = timestamp_full +1;

  always_comb begin
    ClatimestampWr = '0;
    ClatimestampconfigWr = '0;
    ClaMmrCdbgtimestampcaptureWr = '0;

    ClatimestampWr.Data.TimestampUpper = timestamp_load ? ClatimestampsyncMmr.TimestampSync[63:TIMESTAMP_LOWER_WIDTH] :
                                      i_Time_Tick  ? timestamp_nxt[63:TIMESTAMP_LOWER_WIDTH] :
                                                    timestamp_full[63:TIMESTAMP_LOWER_WIDTH];
    ClatimestampWr.Data.TimestampLower = timestamp_load ? ClatimestampsyncMmr.TimestampSync[TIMESTAMP_LOWER_WIDTH-1:0] :
                                      i_Time_Tick  ? timestamp_nxt[TIMESTAMP_LOWER_WIDTH-1:0] :
                                                    timestamp_full[TIMESTAMP_LOWER_WIDTH-1:0];

    ClatimestampconfigWr.Data.Resync =  timestamp_load ? 1'b0 :
                                                        ClatimestampconfigMmr.Resync;
    ClatimestampWr.TimestampUpperWrEn = 1'b1;
    ClatimestampWr.TimestampLowerWrEn = 1'b1;
    ClatimestampconfigWr.ResyncWrEn = 1'b1;
  end

  assign cla_sync_timestamp = timestamp_full;
end

else if (TIMESTAMP_SYNC_SCHEME == 1) begin : gen_timestamp_sync_scheme_1

  logic [TIMESTAMP_UPPER_WIDTH-1:0] timestamp_upper, timestamp_compare_upper;
  logic timestamp_upper_incr;

  logic [TIMESTAMP_LOWER_WIDTH-1:0] timestamp_lower;

  assign timestamp_upper = ClatimestampMmr.TimestampUpper;
  assign timestamp_lower = ClatimestampMmr.TimestampLower;
  assign timestamp_compare_upper = timestamp_upper - ClatimestampoffsetMmr.Offset;
  assign timestamp_upper_incr = (timestamp_compare_upper != i_ref_timestamp);

  always_comb begin
    ClatimestampWr = '0;
    ClatimestampconfigWr = '0;
    ClaMmrCdbgtimestampcaptureWr = '0;

    ClaMmrCdbgtimestampcaptureWr.TimestampWrEn = xtrigger_posedge && ClatimestampconfigMmr.TsCapture;
    ClaMmrCdbgtimestampcaptureWr.Data.Timestamp = {ClatimestampMmr.TimestampUpper, TIMESTAMP_LOWER_WIDTH'(0)};

    ClatimestampWr.Data.TimestampUpper = timestamp_upper_incr ? timestamp_upper + 1 : ClatimestampMmr.TimestampUpper;
    ClatimestampWr.Data.TimestampLower = timestamp_upper_incr ? TIMESTAMP_LOWER_WIDTH'(0) : timestamp_lower+1;

    ClatimestampWr.TimestampUpperWrEn = timestamp_upper_incr;
    ClatimestampWr.TimestampLowerWrEn = 1'b1;
  end

  assign cla_sync_timestamp = {timestamp_upper, timestamp_lower};
end

assign o_cla_timesync_timestamp = cla_sync_timestamp;

assign ClacounterCfgMmr[0] = (ClacounterCfgMmr_s'(ClacounterCfg0Mmr));
assign ClacounterCfgMmr[1] = (ClacounterCfgMmr_s'(ClacounterCfg1Mmr));
assign ClacounterCfgMmr[2] = (ClacounterCfgMmr_s'(ClacounterCfg2Mmr));
assign ClacounterCfgMmr[3] = (ClacounterCfgMmr_s'(ClacounterCfg3Mmr));

NodeEapMmr_s         NodeEap0Mmr[CLA_NUMBER_OF_NODES];
NodeEapMmr_s         NodeEap1Mmr[CLA_NUMBER_OF_NODES];
NodeEapMmr_s         NodeEap2Mmr[CLA_NUMBER_OF_NODES];
NodeEapMmr_s         NodeEap3Mmr[CLA_NUMBER_OF_NODES];

assign NodeEap0Mmr[0] = (NodeEapMmr_s'(Node0Eap0Mmr));
assign NodeEap1Mmr[0] = (NodeEapMmr_s'(Node0Eap1Mmr));
assign NodeEap2Mmr[0] = (NodeEapMmr_s'(Node0Eap2Mmr));
assign NodeEap3Mmr[0] = (NodeEapMmr_s'(Node0Eap3Mmr));
assign NodeEap0Mmr[1] = (NodeEapMmr_s'(Node1Eap0Mmr));
assign NodeEap1Mmr[1] = (NodeEapMmr_s'(Node1Eap1Mmr));
assign NodeEap2Mmr[1] = (NodeEapMmr_s'(Node1Eap2Mmr));
assign NodeEap3Mmr[1] = (NodeEapMmr_s'(Node1Eap3Mmr));
assign NodeEap0Mmr[2] = (NodeEapMmr_s'(Node2Eap0Mmr));
assign NodeEap1Mmr[2] = (NodeEapMmr_s'(Node2Eap1Mmr));
assign NodeEap2Mmr[2] = (NodeEapMmr_s'(Node2Eap2Mmr));
assign NodeEap3Mmr[2] = (NodeEapMmr_s'(Node2Eap3Mmr));
assign NodeEap0Mmr[3] = (NodeEapMmr_s'(Node3Eap0Mmr));
assign NodeEap1Mmr[3] = (NodeEapMmr_s'(Node3Eap1Mmr));
assign NodeEap2Mmr[3] = (NodeEapMmr_s'(Node3Eap2Mmr));
assign NodeEap3Mmr[3] = (NodeEapMmr_s'(Node3Eap3Mmr));

DebugsignalCompareLoMmr_s DebugsignalCompareLoMmr[CLA_NUMBER_OF_ARITHMETIC_COMPARE];
DebugsignalCompareMaskLoMmr_s DebugsignalCompareMaskLoMmr[CLA_NUMBER_OF_ARITHMETIC_COMPARE];
DebugsignalCompareHiMmr_s DebugsignalCompareHiMmr[CLA_NUMBER_OF_ARITHMETIC_COMPARE];
DebugsignalCompareMaskHiMmr_s DebugsignalCompareMaskHiMmr[CLA_NUMBER_OF_ARITHMETIC_COMPARE];

assign DebugsignalCompareLoMmr[0] = ClaMmrCdbgcompare0Lo;
assign DebugsignalCompareLoMmr[1] = ClaMmrCdbgcompare1Lo;
assign DebugsignalCompareLoMmr[2] = ClaMmrCdbgcompare2Lo;
assign DebugsignalCompareLoMmr[3] = ClaMmrCdbgcompare3Lo;
assign DebugsignalCompareMaskLoMmr[0] = ClaMmrCdbgcompare0Masklo;
assign DebugsignalCompareMaskLoMmr[1] = ClaMmrCdbgcompare1Masklo;
assign DebugsignalCompareMaskLoMmr[2] = ClaMmrCdbgcompare2Masklo;
assign DebugsignalCompareMaskLoMmr[3] = ClaMmrCdbgcompare3Masklo;

if (DBG_SIGNAL_CONFIG == 1'b1) begin: cla_signal_compare_mmr_blk
  assign DebugsignalCompareHiMmr[0] = ClaMmrCdbgcompare0Hi;
  assign DebugsignalCompareHiMmr[1] = ClaMmrCdbgcompare1Hi;
  assign DebugsignalCompareHiMmr[2] = ClaMmrCdbgcompare2Hi;
  assign DebugsignalCompareHiMmr[3] = ClaMmrCdbgcompare3Hi;
  assign DebugsignalCompareMaskHiMmr[0] = ClaMmrCdbgcompare0Maskhi;
  assign DebugsignalCompareMaskHiMmr[1] = ClaMmrCdbgcompare1Maskhi;
  assign DebugsignalCompareMaskHiMmr[2] = ClaMmrCdbgcompare2Maskhi;
  assign DebugsignalCompareMaskHiMmr[3] = ClaMmrCdbgcompare3Maskhi;
end
else begin: cla_signal_compare_mmr_tieoff_blk
  assign DebugsignalCompareHiMmr[0] = '0;
  assign DebugsignalCompareHiMmr[1] = '0;
  assign DebugsignalCompareHiMmr[2] = '0;
  assign DebugsignalCompareHiMmr[3] = '0;
  assign DebugsignalCompareMaskHiMmr[0] = '0;
  assign DebugsignalCompareMaskHiMmr[1] = '0;
  assign DebugsignalCompareMaskHiMmr[2] = '0;
  assign DebugsignalCompareMaskHiMmr[3] = '0;
end

DebugsignalMatchLoMmr_s DebugsignalMatchLoMmr[CLA_NUMBER_OF_MASK_MATCH_SET];
DebugsignalMaskLoMmr_s  DebugsignalMaskLoMmr[CLA_NUMBER_OF_MASK_MATCH_SET];

assign DebugsignalMatchLoMmr[0] = DebugsignalMatch0LoMmr;
assign DebugsignalMatchLoMmr[1] = DebugsignalMatch1LoMmr;
assign DebugsignalMatchLoMmr[2] = DebugsignalMatch2LoMmr;
assign DebugsignalMatchLoMmr[3] = DebugsignalMatch3LoMmr;
assign DebugsignalMaskLoMmr[0] = DebugsignalMask0LoMmr;
assign DebugsignalMaskLoMmr[1] = DebugsignalMask1LoMmr;
assign DebugsignalMaskLoMmr[2] = DebugsignalMask2LoMmr;
assign DebugsignalMaskLoMmr[3] = DebugsignalMask3LoMmr;

DebugsignalMatchHiMmr_s DebugsignalMatchHiMmr[CLA_NUMBER_OF_MASK_MATCH_SET];
DebugsignalMaskHiMmr_s  DebugsignalMaskHiMmr[CLA_NUMBER_OF_MASK_MATCH_SET];

if (DBG_SIGNAL_CONFIG == 1'b1) begin: cla_signal_mask_match_mmr_blk

  assign DebugsignalMatchHiMmr[0] = DebugsignalMatch0HiMmr;
  assign DebugsignalMatchHiMmr[1] = DebugsignalMatch1HiMmr;
  assign DebugsignalMatchHiMmr[2] = DebugsignalMatch2HiMmr;
  assign DebugsignalMatchHiMmr[3] = DebugsignalMatch3HiMmr;
  assign DebugsignalMaskHiMmr[0] = DebugsignalMask0HiMmr;
  assign DebugsignalMaskHiMmr[1] = DebugsignalMask1HiMmr;
  assign DebugsignalMaskHiMmr[2] = DebugsignalMask2HiMmr;
  assign DebugsignalMaskHiMmr[3] = DebugsignalMask3HiMmr;

end else begin: cla_signal_mask_match_mmr_tieoff_blk

  assign DebugsignalMatchHiMmr[0] = '0;
  assign DebugsignalMatchHiMmr[1] = '0;
  assign DebugsignalMatchHiMmr[2] = '0;
  assign DebugsignalMatchHiMmr[3] = '0;
  assign DebugsignalMaskHiMmr[0] = '0;
  assign DebugsignalMaskHiMmr[1] = '0;
  assign DebugsignalMaskHiMmr[2] = '0;
  assign DebugsignalMaskHiMmr[3] = '0;

end

ClacounterCfgMmrWr_s  ClacounterCfgMmrWr[CLA_NUMBER_OF_COUNTERS];
assign Clacounter0CfgMmrWr = ClaCdbgclacounter0CfgMmrWr_s'(ClacounterCfgMmrWr[0]);
assign Clacounter1CfgMmrWr = ClaCdbgclacounter1CfgMmrWr_s'(ClacounterCfgMmrWr[1]);
assign Clacounter2CfgMmrWr = ClaCdbgclacounter2CfgMmrWr_s'(ClacounterCfgMmrWr[2]);
assign Clacounter3CfgMmrWr = ClaCdbgclacounter3CfgMmrWr_s'(ClacounterCfgMmrWr[3]);
always_comb begin
       ClactrlstatusWr = '0;
       ClactrlstatusWr.CurrentNodeWrEn = 1'b1;
       ClactrlstatusWr.Data.CurrentNode = current_node_id;
end

assign node_eap_status_w2c[3][3] = EapstatusMmr.Node3Eap3W2C;
assign node_eap_status_w2c[2][3] = EapstatusMmr.Node2Eap3W2C;
assign node_eap_status_w2c[1][3] = EapstatusMmr.Node1Eap3W2C;
assign node_eap_status_w2c[0][3] = EapstatusMmr.Node0Eap3W2C;

assign node_eap_status_w2c[3][2] = EapstatusMmr.Node3Eap2W2C;
assign node_eap_status_w2c[2][2] = EapstatusMmr.Node2Eap2W2C;
assign node_eap_status_w2c[1][2] = EapstatusMmr.Node1Eap2W2C;
assign node_eap_status_w2c[0][2] = EapstatusMmr.Node0Eap2W2C;

assign node_eap_status_w2c[3][1] = EapstatusMmr.Node3Eap1W2C;
assign node_eap_status_w2c[2][1] = EapstatusMmr.Node2Eap1W2C;
assign node_eap_status_w2c[1][1] = EapstatusMmr.Node1Eap1W2C;
assign node_eap_status_w2c[0][1] = EapstatusMmr.Node0Eap1W2C;

assign node_eap_status_w2c[3][0] = EapstatusMmr.Node3Eap0W2C;
assign node_eap_status_w2c[2][0] = EapstatusMmr.Node2Eap0W2C;
assign node_eap_status_w2c[1][0] = EapstatusMmr.Node1Eap0W2C;
assign node_eap_status_w2c[0][0] = EapstatusMmr.Node0Eap0W2C;

always_comb begin
  EapstatusWr = '0;

  EapstatusWr.Data.Node3Eap3 = node_eap_status[3][3];
  EapstatusWr.Data.Node2Eap3 = node_eap_status[2][3];
  EapstatusWr.Data.Node1Eap3 = node_eap_status[1][3];
  EapstatusWr.Data.Node0Eap3 = node_eap_status[0][3];

  EapstatusWr.Data.Node3Eap2 = node_eap_status[3][2];
  EapstatusWr.Data.Node2Eap2 = node_eap_status[2][2];
  EapstatusWr.Data.Node1Eap2 = node_eap_status[1][2];
  EapstatusWr.Data.Node0Eap2 = node_eap_status[0][2];

  EapstatusWr.Data.Node3Eap1 = node_eap_status[3][1];
  EapstatusWr.Data.Node2Eap1 = node_eap_status[2][1];
  EapstatusWr.Data.Node1Eap1 = node_eap_status[1][1];
  EapstatusWr.Data.Node0Eap1 = node_eap_status[0][1];

  EapstatusWr.Data.Node3Eap0 = node_eap_status[3][0];
  EapstatusWr.Data.Node2Eap0 = node_eap_status[2][0];
  EapstatusWr.Data.Node1Eap0 = node_eap_status[1][0];
  EapstatusWr.Data.Node0Eap0 = node_eap_status[0][0];

  EapstatusWr.Node3Eap3WrEn  = 1'b1;
  EapstatusWr.Node2Eap3WrEn  = 1'b1;
  EapstatusWr.Node1Eap3WrEn  = 1'b1;
  EapstatusWr.Node0Eap3WrEn  = 1'b1;

  EapstatusWr.Node3Eap2WrEn  = 1'b1;
  EapstatusWr.Node2Eap2WrEn  = 1'b1;
  EapstatusWr.Node1Eap2WrEn  = 1'b1;
  EapstatusWr.Node0Eap2WrEn  = 1'b1;

  EapstatusWr.Node3Eap1WrEn  = 1'b1;
  EapstatusWr.Node2Eap1WrEn  = 1'b1;
  EapstatusWr.Node1Eap1WrEn  = 1'b1;
  EapstatusWr.Node0Eap1WrEn  = 1'b1;

  EapstatusWr.Node3Eap0WrEn  = 1'b1;
  EapstatusWr.Node2Eap0WrEn  = 1'b1;
  EapstatusWr.Node1Eap0WrEn  = 1'b1;
  EapstatusWr.Node0Eap0WrEn  = 1'b1;

  EapstatusWr.Node3Eap3W2CWrEn  = reset_eap_status_w2c[3][3];
  EapstatusWr.Node2Eap3W2CWrEn  = reset_eap_status_w2c[2][3];
  EapstatusWr.Node1Eap3W2CWrEn  = reset_eap_status_w2c[1][3];
  EapstatusWr.Node0Eap3W2CWrEn  = reset_eap_status_w2c[0][3];

  EapstatusWr.Node3Eap2W2CWrEn  = reset_eap_status_w2c[3][2];
  EapstatusWr.Node2Eap2W2CWrEn  = reset_eap_status_w2c[2][2];
  EapstatusWr.Node1Eap2W2CWrEn  = reset_eap_status_w2c[1][2];
  EapstatusWr.Node0Eap2W2CWrEn  = reset_eap_status_w2c[0][2];

  EapstatusWr.Node3Eap1W2CWrEn  = reset_eap_status_w2c[3][1];
  EapstatusWr.Node2Eap1W2CWrEn  = reset_eap_status_w2c[2][1];
  EapstatusWr.Node1Eap1W2CWrEn  = reset_eap_status_w2c[1][1];
  EapstatusWr.Node0Eap1W2CWrEn  = reset_eap_status_w2c[0][1];

  EapstatusWr.Node3Eap0W2CWrEn  = reset_eap_status_w2c[3][0];
  EapstatusWr.Node2Eap0W2CWrEn  = reset_eap_status_w2c[2][0];
  EapstatusWr.Node1Eap0W2CWrEn  = reset_eap_status_w2c[1][0];
  EapstatusWr.Node0Eap0W2CWrEn  = reset_eap_status_w2c[0][0];

  EapstatusWr.Data.Node3Eap3W2C = 1'b0;
  EapstatusWr.Data.Node2Eap3W2C = 1'b0;
  EapstatusWr.Data.Node1Eap3W2C = 1'b0;
  EapstatusWr.Data.Node0Eap3W2C = 1'b0;

  EapstatusWr.Data.Node3Eap2W2C = 1'b0;
  EapstatusWr.Data.Node2Eap2W2C = 1'b0;
  EapstatusWr.Data.Node1Eap2W2C = 1'b0;
  EapstatusWr.Data.Node0Eap2W2C = 1'b0;

  EapstatusWr.Data.Node3Eap1W2C = 1'b0;
  EapstatusWr.Data.Node2Eap1W2C = 1'b0;
  EapstatusWr.Data.Node1Eap1W2C = 1'b0;
  EapstatusWr.Data.Node0Eap1W2C = 1'b0;

  EapstatusWr.Data.Node3Eap0W2C = 1'b0;
  EapstatusWr.Data.Node2Eap0W2C = 1'b0;
  EapstatusWr.Data.Node1Eap0W2C = 1'b0;
  EapstatusWr.Data.Node0Eap0W2C = 1'b0;
end

assign DbgSignalSnapShotNode0Eap0LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][0] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap1LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][1] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap2LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][2] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap3LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][3] == 1) && (current_node_id == 0);

assign DbgSignalSnapShotNode1Eap0LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][0] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap1LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][1] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap2LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][2] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap3LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][3] == 1) && (current_node_id == 1);

assign DbgSignalSnapShotNode2Eap0LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][0] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap1LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][1] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap2LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][2] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap3LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][3] == 1) && (current_node_id == 2);

assign DbgSignalSnapShotNode3Eap0LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][0] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap1LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][1] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap2LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][2] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap3LoMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][3] == 1) && (current_node_id == 3);

assign DbgSignalSnapShotNode0Eap0LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode0Eap1LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode0Eap2LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode0Eap3LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode1Eap0LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode1Eap1LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode1Eap2LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode1Eap3LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode2Eap0LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode2Eap1LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode2Eap2LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode2Eap3LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode3Eap0LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode3Eap1LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode3Eap2LoMmrWr.Data.Value = debug_signals_d1[63:0];
assign DbgSignalSnapShotNode3Eap3LoMmrWr.Data.Value = debug_signals_d1[63:0];

if (DBG_SIGNAL_CONFIG == 1'b1) begin: cla_snapshot_mmr_hi_blk
  assign DbgSignalSnapShotNode0Eap0HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][0] == 1) && (current_node_id == 0);
  assign DbgSignalSnapShotNode0Eap1HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][1] == 1) && (current_node_id == 0);
  assign DbgSignalSnapShotNode0Eap2HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][2] == 1) && (current_node_id == 0);
  assign DbgSignalSnapShotNode0Eap3HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[0][3] == 1) && (current_node_id == 0);

  assign DbgSignalSnapShotNode1Eap0HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][0] == 1) && (current_node_id == 1);
  assign DbgSignalSnapShotNode1Eap1HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][1] == 1) && (current_node_id == 1);
  assign DbgSignalSnapShotNode1Eap2HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][2] == 1) && (current_node_id == 1);
  assign DbgSignalSnapShotNode1Eap3HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[1][3] == 1) && (current_node_id == 1);

  assign DbgSignalSnapShotNode2Eap0HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][0] == 1) && (current_node_id == 2);
  assign DbgSignalSnapShotNode2Eap1HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][1] == 1) && (current_node_id == 2);
  assign DbgSignalSnapShotNode2Eap2HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][2] == 1) && (current_node_id == 2);
  assign DbgSignalSnapShotNode2Eap3HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[2][3] == 1) && (current_node_id == 2);

  assign DbgSignalSnapShotNode3Eap0HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][0] == 1) && (current_node_id == 3);
  assign DbgSignalSnapShotNode3Eap1HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][1] == 1) && (current_node_id == 3);
  assign DbgSignalSnapShotNode3Eap2HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][2] == 1) && (current_node_id == 3);
  assign DbgSignalSnapShotNode3Eap3HiMmrWr.ValueWrEn = (snapshot_capture_per_eap[3][3] == 1) && (current_node_id == 3);

  assign DbgSignalSnapShotNode0Eap0HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode0Eap1HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode0Eap2HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode0Eap3HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode1Eap0HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode1Eap1HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode1Eap2HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode1Eap3HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode2Eap0HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode2Eap1HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode2Eap2HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode2Eap3HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode3Eap0HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode3Eap1HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode3Eap2HiMmrWr.Data.Value = debug_signals_d1[127:64];
  assign DbgSignalSnapShotNode3Eap3HiMmrWr.Data.Value = debug_signals_d1[127:64];

end else begin: cla_snapshot_mmr_hi_tieoff_blk
  assign DbgSignalSnapShotNode0Eap0HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode0Eap1HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode0Eap2HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode0Eap3HiMmrWr.ValueWrEn = '0;

  assign DbgSignalSnapShotNode1Eap0HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode1Eap1HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode1Eap2HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode1Eap3HiMmrWr.ValueWrEn = '0;

  assign DbgSignalSnapShotNode2Eap0HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode2Eap1HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode2Eap2HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode2Eap3HiMmrWr.ValueWrEn = '0;

  assign DbgSignalSnapShotNode3Eap0HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode3Eap1HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode3Eap2HiMmrWr.ValueWrEn = '0;
  assign DbgSignalSnapShotNode3Eap3HiMmrWr.ValueWrEn = '0;

  assign DbgSignalSnapShotNode0Eap0HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode0Eap1HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode0Eap2HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode0Eap3HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode1Eap0HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode1Eap1HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode1Eap2HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode1Eap3HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode2Eap0HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode2Eap1HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode2Eap2HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode2Eap3HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode3Eap0HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode3Eap1HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode3Eap2HiMmrWr.Data.Value = '0;
  assign DbgSignalSnapShotNode3Eap3HiMmrWr.Data.Value = '0;

end

always@(posedge clock)
  if (i_reset_n == 0)
     debug_signals_d1 <= '0;
  else
     debug_signals_d1 <= debug_signals_aligned;

always@(posedge clock) begin
  if (i_reset_n == 0)
     external_action_debug_interrupt <= 1'b0;
  else if(debug_interrupt_pulse)
     external_action_debug_interrupt <= 1'b1;
  else if({reset_eap_status_w2c[3],reset_eap_status_w2c[2],reset_eap_status_w2c[1],reset_eap_status_w2c[0]} != 0)
     external_action_debug_interrupt <= 1'b0;
end

generic_dff #(
    .WIDTH       ($bits(logic [$bits(xtrigger_in)-1:0])),
    .RESET_VALUE ('0)
) xtrigger_in_ff (
    .clk   (clock),
    .rst_n (i_reset_n),
    .en    ('1),
    .in    (xtrigger_in),
    .out   (xtrigger_in_d1)
);
generic_dff #(
    .WIDTH       ($bits(logic [$bits(xtrigger_out)-1:0])),
    .RESET_VALUE ('0)
) xtrigger_out_ff (
    .clk   (clock),
    .rst_n (i_reset_n),
    .en    ('1),
    .in    (xtrigger_out_stretch),
    .out   (xtrigger_out)
);

xtrigger_stretch_circuit xtrigger_stretch_circuit_inst (
  .clock(clock),
  .reset_n(i_reset_n),
  .reset_n_warm_ovrride(reset_n_warm_ovrride),
  .xtrigger_in(xtrigger_out_pre_ff),
  .xtrigger_out(xtrigger_out_stretch),

  .Cdbgclaxtriggertimestretch(XtriggertimestretchMmr)
);

cla_event_gen #(
  .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
)ClaEventGen (
.clock                        ( clock ),
.reset_n                      ( i_reset_n ),
.debug_signals                ( debug_signals_aligned ),
.i_ext_posedge                ( i_ext_posedge ),
.ClacounterCfgMmr             ( ClacounterCfgMmr ),
.ClacounterCfgMmrWr           ( ClacounterCfgMmrWr ),
.DebugsignalMatchLoMmr        ( DebugsignalMatchLoMmr ),
.DebugsignalMatchHiMmr        ( DebugsignalMatchHiMmr ),
.DebugsignalMaskLoMmr         ( DebugsignalMaskLoMmr ),
.DebugsignalMaskHiMmr         ( DebugsignalMaskHiMmr ),
.DebugsignalEdgedetectcfgMmr  ( DebugsignalEdgedetectcfgMmr ),
.DebugsignalTransitionmaskLoMmr ( DebugsignalTransitionmaskLoMmr ),
.DebugsignalTransitionmaskHiMmr ( DebugsignalTransitionmaskHiMmr ),
.DebugsignalTransitionfromLoMmr ( DebugsignalTransitionfromLoMmr ),
.DebugsignalTransitionfromHiMmr ( DebugsignalTransitionfromHiMmr ),
.DebugsignalTransitiontoLoMmr ( DebugsignalTransitiontoLoMmr ),
.DebugsignalTransitiontoHiMmr ( DebugsignalTransitiontoHiMmr ),
.DebugsignalOnescountmaskLoMmr  ( DebugsignalOnescountmaskLoMmr ),
.DebugsignalOnescountmaskHiMmr  ( DebugsignalOnescountmaskHiMmr ),
.DebugsignalOnescountvalueMmr ( DebugsignalOnescountvalueMmr ),
.DebugsignalChangeLoMmr        ( DebugsignalchangeLoMmr ),
.DebugsignalChangeHiMmr        ( DebugsignalchangeHiMmr ),
.ClaCdbglfsrMmr                ( ClaMmrCdbglfsr ),
.ClaCdbglfsrmaskMmr            ( ClaMmrCdbglfsrmask ),
.ClaCdbglfsrMmrWr              ( ClaMmrCdbglfsrWr ),
.DebugsignalCompareLoMmr       ( DebugsignalCompareLoMmr ),
.DebugsignalCompareHiMmr       ( DebugsignalCompareHiMmr ),
.DebugsignalCompareMaskLoMmr   ( DebugsignalCompareMaskLoMmr ),
.DebugsignalCompareMaskHiMmr   ( DebugsignalCompareMaskHiMmr ),
.cla_counter_controls         ( counter_actions ),
.xtrigger_in                  ( xtrigger_in_d1 & (~self_filter)),
.cla_en                       ( ClactrlstatusMmr.EnableEap ),
.event_bus                    ( event_bus )
);

genvar i;
generate
for (i=0;i<CLA_NUMBER_OF_NODES;i=i+1) begin : gen_cla_node_eap_set_inst
  cla_node_eap_set #(.MY_NODE_ID(i)) cla_node_eap_set_inst
   (
   .clock                    ( clock ),
   .reset_n                  ( i_reset_n ),
   .enable_eap               ( ClactrlstatusMmr.EnableEap  ),
   .event_bus                ( event_bus_mod ),
   .NodeEapMmr               ( {NodeEap0Mmr[i], NodeEap1Mmr[i], NodeEap2Mmr[i], NodeEap3Mmr[i]} ),
   .next_node_action_bus     ( next_node_action_bus[i] ),
   .next_node_custom_action_bus     ( next_node_custom_action_bus[i] ),
   .next_destination_node_id ( next_destination_node_id[i] ),
   .node_eap_status_w2c      ( node_eap_status_w2c[i] ),
   .current_node_id          ( current_node_id ),
   .reset_eap_status_w2c     ( reset_eap_status_w2c[i] ),
   .snapshot_capture_per_eap ( snapshot_capture_per_eap[i] ),
   .node_eap_status          ( node_eap_status[i] )
  );
end
endgenerate

cla_action_gen ClaActionGen
(
   .clock                    ( clock ),
   .reset_n                  ( i_reset_n ),
   .reset_n_warm_ovrride     (reset_n_warm_ovrride),
   .enable_eap               ( ClactrlstatusMmr.EnableEap ),
   .cla_chain_loop_delay     ( ClactrlstatusMmr.ClaChainLoopDelay),
   .next_node_action_bus     ( next_node_action_bus ),
   .next_node_custom_action_bus     ( next_node_custom_action_bus ),
   .next_destination_node_id ( next_destination_node_id ),
   .clock_halt_global_en     ( ~ClactrlstatusMmr.DisableGlobalClockHalt ),
   .clock_halt_local_en      ( ~ClactrlstatusMmr.DisableLocalClockHalt ),
   .clock_halt_global        ( external_action_halt_clock ),
   .clock_halt_local         ( external_action_halt_clock_local ),
   .debug_interrupt          ( debug_interrupt_pulse ),
   .toggle_gpio              ( external_action_toggle_gpio ),
   .start_trace              ( external_action_trace_start ),
   .stop_trace               ( external_action_trace_stop ),
   .trace_pulse              ( external_action_trace_pulse ),
   .xtrigger_out             ( xtrigger_out_pre_ff ),
   .self_filter              ( self_filter ),
   .custom_action_bus        ( external_action_custom ),

   .counter_actions         (counter_actions),

   .current_node_id         (current_node_id)
);

endmodule
