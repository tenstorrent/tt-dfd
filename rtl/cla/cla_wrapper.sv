// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_wrapper
    import cla_mmr_pkg::*;
    import cla_pkg::*;
    import dst_pkg::*;
    import tt_dbm_pkg::*;
#(
    parameter int unsigned NUM_CLA_INST = 8,
    parameter DEBUG_SIGNAL_WIDTH = 64,
    parameter DEBUGMARKER_WIDTH = 8,
    parameter NUM_INPUT_LANES = 8,
    parameter bit TIMESTAMP_SYNC_SCHEME = 0,
    parameter bit OCTS_TS_OUTPUT = 0,
    parameter LANE_WIDTH = 8,
    localparam TIMESTAMP_UPPER_WIDTH = 56,
    localparam TIMESTAMP_LOWER_WIDTH = 8
)(

    input  logic [NUM_CLA_INST-1:0] cla_gated_clock,
    input  logic [NUM_CLA_INST-1:0] cla_gated_reset_n,
    input  logic [NUM_CLA_INST-1:0] cla_gated_reset_n_warm_ovrride,
    input  logic [NUM_CLA_INST-1:0] cla_gated_func_clamp,
    input  logic i_test_icg_en,

    input  logic [NUM_CLA_INST-1:0][NUM_INPUT_LANES-1:0][LANE_WIDTH-1:0] i_debug_bus_signals,

    output logic          [NUM_CLA_INST-1:0][DEBUG_SIGNAL_WIDTH-1:0] debug_bus,
    output DbgMuxSelMmr_s [NUM_CLA_INST-1:0]                         o_debug_mux_sel,

    input  logic [NUM_CLA_INST-1:0]                     i_cla_ext_posedge,
    input  logic [NUM_CLA_INST-1:0][XTRIGGER_WIDTH-1:0] i_cla_xtrigger,
    input  logic [NUM_CLA_INST-1:0][63:0]               i_timestamp,
    input  logic [NUM_CLA_INST-1:0]                     i_cla_time_tick,
    input  logic [NUM_CLA_INST-1:0][63:0]               i_octs_timestamp,
    input  logic [NUM_CLA_INST-1:0][TIMESTAMP_UPPER_WIDTH-1:0]        i_ref_timestamp,
    output logic [NUM_CLA_INST-1:0][XTRIGGER_WIDTH-1:0]             o_cla_xtrigger,

    output logic [NUM_CLA_INST-1:0][DEBUGMARKER_WIDTH-1:0]          o_cla_debug_marker,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_trace_start,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_trace_stop,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_trace_pulse,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_halt_clock_out,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_halt_clock_local_out,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_debug_interrupt_out,
    output logic [NUM_CLA_INST-1:0]                                 o_cla_external_action_toggle_gpio_out,
    output logic [NUM_CLA_INST-1:0][CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] o_cla_external_action_custom,
    output dst_pkg::timestamp_s [NUM_CLA_INST-1:0]                 timesync_cla_timestamp,

    input  ClaMmrs_s   [NUM_CLA_INST-1:0] ClaMmrs,
    output ClaMmrsWrMinimal_s [NUM_CLA_INST-1:0] ClaMmrsWr
);

    logic [NUM_CLA_INST-1:0][XTRIGGER_WIDTH-1:0]            xtrigger_out_int;
    logic [NUM_CLA_INST-1:0][DEBUGMARKER_WIDTH-1:0]         cla_debug_marker_int;
    logic [NUM_CLA_INST-1:0]                                external_action_trace_start_int;
    logic [NUM_CLA_INST-1:0]                                external_action_trace_stop_int;
    logic [NUM_CLA_INST-1:0]                                external_action_trace_pulse_int;
    logic [NUM_CLA_INST-1:0]                                external_action_halt_clock_out_int;
    logic [NUM_CLA_INST-1:0]                                external_action_halt_clock_local_out_int;
    logic [NUM_CLA_INST-1:0]                                external_action_debug_interrupt_out_int;
    logic [NUM_CLA_INST-1:0]                                external_action_toggle_gpio_out_int;
    logic [NUM_CLA_INST-1:0][CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] external_action_custom_int;
    dst_pkg::timestamp_s [NUM_CLA_INST-1:0]                timesync_cla_timestamp_int;
    logic [NUM_CLA_INST-1:0][DEBUG_SIGNAL_WIDTH-1:0]       debug_bus_int;
    logic [NUM_CLA_INST-1:0][DEBUG_SIGNAL_WIDTH-1:0]       debug_bus_aligned;
    DbgMuxSelMmr_s [NUM_CLA_INST-1:0]                      DebugMuxSelMmr;
    ClaMmrsWrMinimal_s    [NUM_CLA_INST-1:0]                      ClaMmrsWr_int;

    logic [NUM_CLA_INST-1:0][63:0] cla_timestamp_muxed;
    assign cla_timestamp_muxed = OCTS_TS_OUTPUT == 1'b1 ? i_octs_timestamp : timesync_cla_timestamp_int;

    for (genvar ii = 0; ii < NUM_CLA_INST; ii++) begin : cla_gen_inst_blk

        assign DebugMuxSelMmr[ii].DbmId      = ClaMmrs[ii].Cdbgmuxsello.Dbmid;
        assign DebugMuxSelMmr[ii].DbmMode    = ClaMmrs[ii].Cdbgmuxsello.Dbmmode;
        assign DebugMuxSelMmr[ii].FineGrainTime = ClaMmrs[ii].Cdbgmuxsello.Finegraintime;
        assign DebugMuxSelMmr[ii].Muxselseg0 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg0;
        assign DebugMuxSelMmr[ii].Muxselseg1 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg1;
        assign DebugMuxSelMmr[ii].Muxselseg2 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg2;
        assign DebugMuxSelMmr[ii].Muxselseg3 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg3;
        assign DebugMuxSelMmr[ii].Muxselseg4 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg4;
        assign DebugMuxSelMmr[ii].Muxselseg5 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg5;
        assign DebugMuxSelMmr[ii].Muxselseg6 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg6;
        assign DebugMuxSelMmr[ii].Muxselseg7 = ClaMmrs[ii].Cdbgmuxsello.Muxselseg7;
        assign DebugMuxSelMmr[ii].Muxselseg8 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg8;
        assign DebugMuxSelMmr[ii].Muxselseg9 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg9;
        assign DebugMuxSelMmr[ii].Muxselseg10 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg10;
        assign DebugMuxSelMmr[ii].Muxselseg11 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg11;
        assign DebugMuxSelMmr[ii].Muxselseg12 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg12;
        assign DebugMuxSelMmr[ii].Muxselseg13 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg13;
        assign DebugMuxSelMmr[ii].Muxselseg14 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg14;
        assign DebugMuxSelMmr[ii].Muxselseg15 = ClaMmrs[ii].Cdbgmuxselhi.Muxselseg15;
        assign DebugMuxSelMmr[ii].Valid = ClaMmrs[ii].Cdbgmuxsello.Valid;

        mux_sel #(
            .DEBUG_BUS_WIDTH(DEBUG_SIGNAL_WIDTH),
            .NUM_INPUT_LANES(NUM_INPUT_LANES),
            .ID_INDEX(ii),
            .LANE_WIDTH(LANE_WIDTH)
        ) u_mux_sel (
            .clk					(cla_gated_clock[ii]),
            .i_reset_n				(cla_gated_reset_n[ii]),
            .i_test_icg_en			(i_test_icg_en),
            .reset_n_warm_ovrride (cla_gated_reset_n_warm_ovrride[ii]),
            .debug_signals_in		(i_debug_bus_signals[ii]),
            .Time_Tick				(i_cla_time_tick[ii]),
            .DbgMuxSelMmr			(DebugMuxSelMmr[ii]),
            .debug_bus				(debug_bus_int[ii])
        );

        core_logic_analyzer #(
            .CORE_INSTANCE(1'b1),
            .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH),
            .TIMESTAMP_SYNC_SCHEME(TIMESTAMP_SYNC_SCHEME)
        ) cla_inst (
            .clock								(cla_gated_clock[ii]),
            .i_reset_n							(cla_gated_reset_n[ii]),
            .reset_n_warm_ovrride             (cla_gated_reset_n_warm_ovrride[ii]),
            .debug_signals						(debug_bus_int[ii]),
            .i_ext_posedge						(i_cla_ext_posedge[ii]),
            .xtrigger_in						(i_cla_xtrigger[ii]),
            .xtrigger_out						(xtrigger_out_int[ii]),
            .external_action_halt_clock_local	(external_action_halt_clock_local_out_int[ii]),
            .external_action_halt_clock			(external_action_halt_clock_out_int[ii]),
            .external_action_debug_interrupt	(external_action_debug_interrupt_out_int[ii]),
            .external_action_toggle_gpio		(external_action_toggle_gpio_out_int[ii]),
            .external_action_trace_start		(external_action_trace_start_int[ii]),
            .external_action_trace_stop			(external_action_trace_stop_int[ii]),
            .external_action_trace_pulse		(external_action_trace_pulse_int[ii]),
            .external_action_custom				(external_action_custom_int[ii]),
            .debug_signals_aligned				(debug_bus_aligned[ii]),
            .timestamp							(dst_pkg::timestamp_s'(i_timestamp[ii])),
            .i_ref_timestamp						(i_ref_timestamp[ii]),
            .o_cla_timesync_timestamp			(timesync_cla_timestamp_int[ii]),
            .o_cla_debug_marker					(cla_debug_marker_int[ii]),

            .ClacounterCfg0Mmr					(ClaMmrs[ii].Cdbgclacounter0Cfg),
            .ClacounterCfg1Mmr					(ClaMmrs[ii].Cdbgclacounter1Cfg),
            .ClacounterCfg2Mmr					(ClaMmrs[ii].Cdbgclacounter2Cfg),
            .ClacounterCfg3Mmr					(ClaMmrs[ii].Cdbgclacounter3Cfg),
            .Node0Eap0Mmr						(ClaMmrs[ii].Cdbgnode0Eap0),
            .Node0Eap1Mmr						(ClaMmrs[ii].Cdbgnode0Eap1),
            .Node0Eap2Mmr						(ClaMmrs[ii].Cdbgnode0Eap2),
            .Node0Eap3Mmr						(ClaMmrs[ii].Cdbgnode0Eap3),
            .Node1Eap0Mmr						(ClaMmrs[ii].Cdbgnode1Eap0),
            .Node1Eap1Mmr						(ClaMmrs[ii].Cdbgnode1Eap1),
            .Node1Eap2Mmr						(ClaMmrs[ii].Cdbgnode1Eap2),
            .Node1Eap3Mmr						(ClaMmrs[ii].Cdbgnode1Eap3),
            .Node2Eap0Mmr						(ClaMmrs[ii].Cdbgnode2Eap0),
            .Node2Eap1Mmr						(ClaMmrs[ii].Cdbgnode2Eap1),
            .Node2Eap2Mmr						(ClaMmrs[ii].Cdbgnode2Eap2),
            .Node2Eap3Mmr						(ClaMmrs[ii].Cdbgnode2Eap3),
            .Node3Eap0Mmr						(ClaMmrs[ii].Cdbgnode3Eap0),
            .Node3Eap1Mmr						(ClaMmrs[ii].Cdbgnode3Eap1),
            .Node3Eap2Mmr						(ClaMmrs[ii].Cdbgnode3Eap2),
            .Node3Eap3Mmr						(ClaMmrs[ii].Cdbgnode3Eap3),
            .DebugsignalMask0LoMmr				(ClaMmrs[ii].Cdbgsignalmask0Lo),
            .DebugsignalMask0HiMmr				(ClaMmrs[ii].Cdbgsignalmask0Hi),
            .DebugsignalMatch0LoMmr				(ClaMmrs[ii].Cdbgsignalmatch0Lo),
            .DebugsignalMatch0HiMmr				(ClaMmrs[ii].Cdbgsignalmatch0Hi),
            .DebugsignalMask1LoMmr				(ClaMmrs[ii].Cdbgsignalmask1Lo),
            .DebugsignalMask1HiMmr				(ClaMmrs[ii].Cdbgsignalmask1Hi),
            .DebugsignalMatch1LoMmr				(ClaMmrs[ii].Cdbgsignalmatch1Lo),
            .DebugsignalMatch1HiMmr				(ClaMmrs[ii].Cdbgsignalmatch1Hi),
            .DebugsignalMask2LoMmr				(ClaMmrs[ii].Cdbgsignalmask2Lo),
            .DebugsignalMask2HiMmr				(ClaMmrs[ii].Cdbgsignalmask2Hi),
            .DebugsignalMatch2LoMmr				(ClaMmrs[ii].Cdbgsignalmatch2Lo),
            .DebugsignalMatch2HiMmr				(ClaMmrs[ii].Cdbgsignalmatch2Hi),
            .DebugsignalMask3LoMmr				(ClaMmrs[ii].Cdbgsignalmask3Lo),
            .DebugsignalMask3HiMmr				(ClaMmrs[ii].Cdbgsignalmask3Hi),
            .DebugsignalMatch3LoMmr				(ClaMmrs[ii].Cdbgsignalmatch3Lo),
            .DebugsignalMatch3HiMmr				(ClaMmrs[ii].Cdbgsignalmatch3Hi),
            .DebugsignalEdgedetectcfgMmr		(ClaMmrs[ii].Cdbgsignaledgedetectcfg),
            .EapstatusMmr						(ClaMmrs[ii].Cdbgeapstatus),
            .ClactrlstatusMmr					(ClaMmrs[ii].Cdbgclactrlstatus),
            .Clacounter0CfgMmrWr				(ClaMmrsWr_int[ii].Cdbgclacounter0CfgWr),
            .Clacounter1CfgMmrWr				(ClaMmrsWr_int[ii].Cdbgclacounter1CfgWr),
            .Clacounter2CfgMmrWr				(ClaMmrsWr_int[ii].Cdbgclacounter2CfgWr),
            .Clacounter3CfgMmrWr				(ClaMmrsWr_int[ii].Cdbgclacounter3CfgWr),
            .ClaMmrCdbgcompare0Lo				(ClaMmrs[ii].Cdbgcompare0Lo),
            .ClaMmrCdbgcompare0Masklo			(ClaMmrs[ii].Cdbgcompare0Masklo),
            .ClaMmrCdbgcompare0Hi				(ClaMmrs[ii].Cdbgcompare0Hi),
            .ClaMmrCdbgcompare0Maskhi			(ClaMmrs[ii].Cdbgcompare0Maskhi),
            .ClaMmrCdbgcompare1Lo				(ClaMmrs[ii].Cdbgcompare1Lo),
            .ClaMmrCdbgcompare1Masklo			(ClaMmrs[ii].Cdbgcompare1Masklo),
            .ClaMmrCdbgcompare1Hi				(ClaMmrs[ii].Cdbgcompare1Hi),
            .ClaMmrCdbgcompare1Maskhi			(ClaMmrs[ii].Cdbgcompare1Maskhi),
            .ClaMmrCdbgcompare2Lo				(ClaMmrs[ii].Cdbgcompare2Lo),
            .ClaMmrCdbgcompare2Masklo			(ClaMmrs[ii].Cdbgcompare2Masklo),
            .ClaMmrCdbgcompare2Hi				(ClaMmrs[ii].Cdbgcompare2Hi),
            .ClaMmrCdbgcompare2Maskhi			(ClaMmrs[ii].Cdbgcompare2Maskhi),
            .ClaMmrCdbgcompare3Lo				(ClaMmrs[ii].Cdbgcompare3Lo),
            .ClaMmrCdbgcompare3Masklo			(ClaMmrs[ii].Cdbgcompare3Masklo),
            .ClaMmrCdbgcompare3Hi				(ClaMmrs[ii].Cdbgcompare3Hi),
            .ClaMmrCdbgcompare3Maskhi			(ClaMmrs[ii].Cdbgcompare3Maskhi),
            .ClaMmrCdbglfsr						(ClaMmrs[ii].Cdbglfsr),
            .ClaMmrCdbglfsrmask					(ClaMmrs[ii].Cdbglfsrmask),
            .DebugsignalTransitionmaskLoMmr		(ClaMmrs[ii].Cdbgtransitionmasklo),
            .DebugsignalTransitionmaskHiMmr		(ClaMmrs[ii].Cdbgtransitionmaskhi),
            .DebugsignalTransitionfromLoMmr		(ClaMmrs[ii].Cdbgtransitionfromvaluelo),
            .DebugsignalTransitionfromHiMmr		(ClaMmrs[ii].Cdbgtransitionfromvaluehi),
            .DebugsignalTransitiontoLoMmr		(ClaMmrs[ii].Cdbgtransitiontovaluelo),
            .DebugsignalTransitiontoHiMmr		(ClaMmrs[ii].Cdbgtransitiontovaluehi),
            .DebugsignalOnescountmaskLoMmr		(ClaMmrs[ii].Cdbgonescountmasklo),
            .DebugsignalOnescountmaskHiMmr		(ClaMmrs[ii].Cdbgonescountmaskhi),
            .DebugsignalOnescountvalueMmr		(ClaMmrs[ii].Cdbgonescountvalue),
            .DebugsignalchangeLoMmr				(ClaMmrs[ii].Cdbganychangelo),
            .DebugsignalchangeHiMmr				(ClaMmrs[ii].Cdbganychangehi),
            .DebugsignaldelaymuxselMmr			(ClaMmrs[ii].Cdbgsignaldelaymuxsel),
            .XtriggertimestretchMmr			    (ClaMmrs[ii].Cdbgclaxtriggertimestretch),
            .ClatimestampMmr					(ClaMmrs[ii].Cdbgclatimestamp),
            .ClatimestampsyncMmr				(ClaMmrs[ii].Cdbgclatimestampsync),
            .ClatimestampoffsetMmr				(ClaMmrs[ii].Cdbgclatimestampoffset),
            .ClatimestampconfigMmr				(ClaMmrs[ii].Cdbgclatimestampconfig),
            .ClatimematchMmr					(ClaMmrs[ii].Cdbgclatimematch),
            .i_Time_Tick						(i_cla_time_tick[ii]),
            .EapstatusWr						(ClaMmrsWr_int[ii].CdbgeapstatusWr),
            .ClactrlstatusWr					(ClaMmrsWr_int[ii].CdbgclactrlstatusWr),
            .ClatimestampWr						(ClaMmrsWr_int[ii].CdbgclatimestampWr),
            .ClatimestampconfigWr				(ClaMmrsWr_int[ii].CdbgclatimestampconfigWr),
            .ClaMmrCdbglfsrWr					(ClaMmrsWr_int[ii].CdbglfsrWr),
            .ClaMmrCdbgtimestampcaptureWr		(ClaMmrsWr_int[ii].CdbgtimestampcaptureWr),
            .DbgSignalSnapShotNode0Eap0LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap0LoWr),
            .DbgSignalSnapShotNode0Eap0HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap0HiWr),
            .DbgSignalSnapShotNode0Eap1LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap1LoWr),
            .DbgSignalSnapShotNode0Eap1HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap1HiWr),
            .DbgSignalSnapShotNode0Eap2LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap2LoWr),
            .DbgSignalSnapShotNode0Eap2HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap2HiWr),
            .DbgSignalSnapShotNode0Eap3LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap3LoWr),
            .DbgSignalSnapShotNode0Eap3HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode0Eap3HiWr),
            .DbgSignalSnapShotNode1Eap0LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap0LoWr),
            .DbgSignalSnapShotNode1Eap0HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap0HiWr),
            .DbgSignalSnapShotNode1Eap1LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap1LoWr),
            .DbgSignalSnapShotNode1Eap1HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap1HiWr),
            .DbgSignalSnapShotNode1Eap2LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap2LoWr),
            .DbgSignalSnapShotNode1Eap2HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap2HiWr),
            .DbgSignalSnapShotNode1Eap3LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap3LoWr),
            .DbgSignalSnapShotNode1Eap3HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode1Eap3HiWr),
            .DbgSignalSnapShotNode2Eap0LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap0LoWr),
            .DbgSignalSnapShotNode2Eap0HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap0HiWr),
            .DbgSignalSnapShotNode2Eap1LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap1LoWr),
            .DbgSignalSnapShotNode2Eap1HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap1HiWr),
            .DbgSignalSnapShotNode2Eap2LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap2LoWr),
            .DbgSignalSnapShotNode2Eap2HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap2HiWr),
            .DbgSignalSnapShotNode2Eap3LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap3LoWr),
            .DbgSignalSnapShotNode2Eap3HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode2Eap3HiWr),
            .DbgSignalSnapShotNode3Eap0LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap0LoWr),
            .DbgSignalSnapShotNode3Eap0HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap0HiWr),
            .DbgSignalSnapShotNode3Eap1LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap1LoWr),
            .DbgSignalSnapShotNode3Eap1HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap1HiWr),
            .DbgSignalSnapShotNode3Eap2LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap2LoWr),
            .DbgSignalSnapShotNode3Eap2HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap2HiWr),
            .DbgSignalSnapShotNode3Eap3LoMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap3LoWr),
            .DbgSignalSnapShotNode3Eap3HiMmrWr	(ClaMmrsWr_int[ii].Cdbgsignalsnapshotnode3Eap3HiWr)
        );

        assign debug_bus[ii]                            = cla_gated_func_clamp[ii] ? '0 : debug_bus_aligned[ii];
        assign o_cla_xtrigger[ii]                         = cla_gated_func_clamp[ii] ? '0 : xtrigger_out_int[ii];
        assign o_cla_debug_marker[ii]                     = cla_gated_func_clamp[ii] ? '0 : cla_debug_marker_int[ii];
        assign o_cla_external_action_trace_start[ii]          = cla_gated_func_clamp[ii] ? '0 : external_action_trace_start_int[ii];
        assign o_cla_external_action_trace_stop[ii]           = cla_gated_func_clamp[ii] ? '0 : external_action_trace_stop_int[ii];
        assign o_cla_external_action_trace_pulse[ii]          = cla_gated_func_clamp[ii] ? '0 : external_action_trace_pulse_int[ii];
        assign o_cla_external_action_halt_clock_out[ii]       = cla_gated_func_clamp[ii] ? '0 : external_action_halt_clock_out_int[ii];
        assign o_cla_external_action_halt_clock_local_out[ii] = cla_gated_func_clamp[ii] ? '0 : external_action_halt_clock_local_out_int[ii];
        assign o_cla_external_action_debug_interrupt_out[ii]  = cla_gated_func_clamp[ii] ? '0 : external_action_debug_interrupt_out_int[ii];
        assign o_cla_external_action_toggle_gpio_out[ii]      = cla_gated_func_clamp[ii] ? '0 : external_action_toggle_gpio_out_int[ii];
        assign o_cla_external_action_custom[ii]               = cla_gated_func_clamp[ii] ? '0 : external_action_custom_int[ii];
        assign timesync_cla_timestamp[ii]               = cla_gated_func_clamp[ii] ? '0 : cla_timestamp_muxed[ii];
        assign ClaMmrsWr[ii]                            = cla_gated_func_clamp[ii] ? '0 : ClaMmrsWr_int[ii];
        assign o_debug_mux_sel[ii]                          = cla_gated_func_clamp[ii] ? '0 : DebugMuxSelMmr[ii];
    end

endmodule
