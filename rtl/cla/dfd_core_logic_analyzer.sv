
// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************

module dfd_core_logic_analyzer 
import dfd_cla_csr_pkg::*;
import dfd_cla_pkg::*;
#(
  parameter CORE_INSTANCE = 1'b0
)
(
  input logic       clock,
  input logic       reset_n,
  input  logic      reset_n_warm_ovrride,
  input  logic   [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
  input  logic   [XTRIGGER_WIDTH-1:0]      xtrigger_in, 
  output logic   [XTRIGGER_WIDTH-1:0]      xtrigger_out,
  output logic                             external_action_halt_clock_local, 
  output logic                             external_action_halt_clock,
  output logic                             external_action_debug_interrupt,
  output logic                             external_action_toggle_gpio,
  output logic                             external_action_trace_start,
  output logic                             external_action_trace_stop,
  output logic                             external_action_trace_pulse,
  output logic  [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  external_action_custom,
  output logic  [DEBUG_SIGNALS_WIDTH-1:0]  debug_signals_aligned,

  input  logic                             time_match_event,
  //Register Interface
  // Register Bus
// Registers
  input CrCdbgclacounter0CfgCsr_s                    ClacounterCfg0Csr,
  input CrCdbgclacounter1CfgCsr_s                    ClacounterCfg1Csr,
  input CrCdbgclacounter2CfgCsr_s                    ClacounterCfg2Csr,
  input CrCdbgclacounter3CfgCsr_s                    ClacounterCfg3Csr,
  input CrCdbgnode0Eap0Csr_s                         Node0Eap0Csr,
  input CrCdbgnode0Eap1Csr_s                         Node0Eap1Csr,
  input CrCdbgnode0Eap2Csr_s                         Node0Eap2Csr,
  input CrCdbgnode0Eap3Csr_s                         Node0Eap3Csr,
  input CrCdbgnode1Eap0Csr_s                         Node1Eap0Csr,
  input CrCdbgnode1Eap1Csr_s                         Node1Eap1Csr,
  input CrCdbgnode1Eap2Csr_s                         Node1Eap2Csr,
  input CrCdbgnode1Eap3Csr_s                         Node1Eap3Csr,
  input CrCdbgnode2Eap0Csr_s                         Node2Eap0Csr,
  input CrCdbgnode2Eap1Csr_s                         Node2Eap1Csr,
  input CrCdbgnode2Eap2Csr_s                         Node2Eap2Csr,
  input CrCdbgnode2Eap3Csr_s                         Node2Eap3Csr,
  input CrCdbgnode3Eap0Csr_s                         Node3Eap0Csr,
  input CrCdbgnode3Eap1Csr_s                         Node3Eap1Csr,
  input CrCdbgnode3Eap2Csr_s                         Node3Eap2Csr,
  input CrCdbgnode3Eap3Csr_s                         Node3Eap3Csr,
  input CrCdbgsignalmask0Csr_s                       Debugsignalmask0Csr,
  input CrCdbgsignalmatch0Csr_s                      Debugsignalmatch0Csr,
  input CrCdbgsignalmask1Csr_s                       Debugsignalmask1Csr,
  input CrCdbgsignalmatch1Csr_s                      Debugsignalmatch1Csr,
  input CrCdbgsignalmask2Csr_s                       Debugsignalmask2Csr,
  input CrCdbgsignalmatch2Csr_s                      Debugsignalmatch2Csr,
  input CrCdbgsignalmask3Csr_s                       Debugsignalmask3Csr,
  input CrCdbgsignalmatch3Csr_s                      Debugsignalmatch3Csr,
  input CrCdbgsignaledgedetectcfgCsr_s               DebugsignaledgedetectcfgCsr,
  input CrCdbgeapstatusCsr_s                         EapstatusCsr,
  input CrCdbgclactrlstatusCsr_s                     ClactrlstatusCsr,
  input DebugsignalTransitionmaskCsr_s               DebugsignalTransitionmaskCsr,
  input DebugsignalTransitionfromCsr_s               DebugsignalTransitionfromCsr,
  input DebugsignalTransitiontoCsr_s                 DebugsignalTransitiontoCsr,
  input DebugsignalOnescountmaskCsr_s                DebugsignalOnescountmaskCsr,
  input DebugsignalOnescountvalueCsr_s               DebugsignalOnescountvalueCsr,
  input DebugsignalchangeCsr_s                       DebugsignalchangeCsr, 
  input CrCdbgsignaldelaymuxselCsr_s                 DebugsignaldelaymuxselCsr,
  input CrCdbgclaxtriggertimestretchCsr_s            XtriggertimestretchCsr,
// HW Write Ports
  output CrCdbgclacounter0CfgCsrWr_s                 Clacounter0CfgCsrWr,
  output CrCdbgclacounter1CfgCsrWr_s                 Clacounter1CfgCsrWr,
  output CrCdbgclacounter2CfgCsrWr_s                 Clacounter2CfgCsrWr,
  output CrCdbgclacounter3CfgCsrWr_s                 Clacounter3CfgCsrWr,
  output CrCdbgeapstatusCsrWr_s                      EapstatusWr, 
  output CrCdbgclactrlstatusCsrWr_s                  ClactrlstatusWr,
  output CrCdbgsignalsnapshotnode0Eap0CsrWr_s        DbgSignalSnapShotNode0Eap0CsrWr, 
  output CrCdbgsignalsnapshotnode0Eap1CsrWr_s        DbgSignalSnapShotNode0Eap1CsrWr,
  output CrCdbgsignalsnapshotnode0Eap2CsrWr_s        DbgSignalSnapShotNode0Eap2CsrWr, 
  output CrCdbgsignalsnapshotnode0Eap3CsrWr_s        DbgSignalSnapShotNode0Eap3CsrWr,
  output CrCdbgsignalsnapshotnode1Eap0CsrWr_s        DbgSignalSnapShotNode1Eap0CsrWr, 
  output CrCdbgsignalsnapshotnode1Eap1CsrWr_s        DbgSignalSnapShotNode1Eap1CsrWr,
  output CrCdbgsignalsnapshotnode1Eap2CsrWr_s        DbgSignalSnapShotNode1Eap2CsrWr, 
  output CrCdbgsignalsnapshotnode1Eap3CsrWr_s        DbgSignalSnapShotNode1Eap3CsrWr,
  output CrCdbgsignalsnapshotnode2Eap0CsrWr_s        DbgSignalSnapShotNode2Eap0CsrWr, 
  output CrCdbgsignalsnapshotnode2Eap1CsrWr_s        DbgSignalSnapShotNode2Eap1CsrWr,
  output CrCdbgsignalsnapshotnode2Eap2CsrWr_s        DbgSignalSnapShotNode2Eap2CsrWr, 
  output CrCdbgsignalsnapshotnode2Eap3CsrWr_s        DbgSignalSnapShotNode2Eap3CsrWr,
  output CrCdbgsignalsnapshotnode3Eap0CsrWr_s        DbgSignalSnapShotNode3Eap0CsrWr, 
  output CrCdbgsignalsnapshotnode3Eap1CsrWr_s        DbgSignalSnapShotNode3Eap1CsrWr,
  output CrCdbgsignalsnapshotnode3Eap2CsrWr_s        DbgSignalSnapShotNode3Eap2CsrWr, 
  output CrCdbgsignalsnapshotnode3Eap3CsrWr_s        DbgSignalSnapShotNode3Eap3CsrWr
  );

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

ClacounterCfgCsr_s    ClacounterCfgCsr[CLA_NUMBER_OF_COUNTERS];

logic   [DEBUG_SIGNALS_WIDTH-1:0] debug_signals_d1;

logic       gated_clock;
generic_ccg #(.HYST_EN(0)) ClaGatedClock
     (.out_clk (gated_clock), .clk (clock),
      .en (ClactrlstatusCsr.EnableCla), .rst_n (reset_n),
      .force_en ('0), .hyst ('0), .te('0));

// Mux to align all the lanes of debug signals to the same clock edge based on the individual delays
dfd_debug_signal_shift_mux #(
  .DEBUG_MUX_OUTPUT_WIDTH(DEBUG_SIGNALS_WIDTH)
) debug_signal_shift_mux_inst (
  .clock(clock),
  .reset_n(reset_n),
  .reset_n_warm_ovrride(reset_n_warm_ovrride),
  .debug_signals_in(debug_signals),
  .debug_signals_out(debug_signals_aligned),
  .DebugSignalDelayMuxsel(DebugsignaldelaymuxselCsr)
);

generate
  if(CORE_INSTANCE == 1'b1) begin
    always_comb begin
      event_bus_mod = event_bus;
      event_bus_mod[15] = time_match_event & ClactrlstatusCsr.EnableEap;
    end
  end
  else begin
    assign event_bus_mod = event_bus;
  end
endgenerate

//Doing all these as we cannot typecast on output ports!!! 
assign ClacounterCfgCsr[0] = (ClacounterCfgCsr_s'(ClacounterCfg0Csr));
assign ClacounterCfgCsr[1] = (ClacounterCfgCsr_s'(ClacounterCfg1Csr));
assign ClacounterCfgCsr[2] = (ClacounterCfgCsr_s'(ClacounterCfg2Csr));
assign ClacounterCfgCsr[3] = (ClacounterCfgCsr_s'(ClacounterCfg3Csr));

// Two set of EAPs: EAP0 Node, EAP1 Node
NodeEapCsr_s         NodeEap0Csr[CLA_NUMBER_OF_NODES];
NodeEapCsr_s         NodeEap1Csr[CLA_NUMBER_OF_NODES];
NodeEapCsr_s         NodeEap2Csr[CLA_NUMBER_OF_NODES];
NodeEapCsr_s         NodeEap3Csr[CLA_NUMBER_OF_NODES];
//Doing all these as we cannot typecast on output ports!!! 
assign NodeEap0Csr[0] = (NodeEapCsr_s'(Node0Eap0Csr));
assign NodeEap1Csr[0] = (NodeEapCsr_s'(Node0Eap1Csr));
assign NodeEap2Csr[0] = (NodeEapCsr_s'(Node0Eap2Csr));
assign NodeEap3Csr[0] = (NodeEapCsr_s'(Node0Eap3Csr));
assign NodeEap0Csr[1] = (NodeEapCsr_s'(Node1Eap0Csr));
assign NodeEap1Csr[1] = (NodeEapCsr_s'(Node1Eap1Csr));
assign NodeEap2Csr[1] = (NodeEapCsr_s'(Node1Eap2Csr));
assign NodeEap3Csr[1] = (NodeEapCsr_s'(Node1Eap3Csr));
assign NodeEap0Csr[2] = (NodeEapCsr_s'(Node2Eap0Csr));
assign NodeEap1Csr[2] = (NodeEapCsr_s'(Node2Eap1Csr));
assign NodeEap2Csr[2] = (NodeEapCsr_s'(Node2Eap2Csr));
assign NodeEap3Csr[2] = (NodeEapCsr_s'(Node2Eap3Csr));
assign NodeEap0Csr[3] = (NodeEapCsr_s'(Node3Eap0Csr));
assign NodeEap1Csr[3] = (NodeEapCsr_s'(Node3Eap1Csr));
assign NodeEap2Csr[3] = (NodeEapCsr_s'(Node3Eap2Csr));
assign NodeEap3Csr[3] = (NodeEapCsr_s'(Node3Eap3Csr));

DebugsignalmatchCsr_s DebugsignalmatchCsr[CLA_NUMBER_OF_MASK_MATCH_SET];
DebugsignalmaskCsr_s  DebugsignalmaskCsr[CLA_NUMBER_OF_MASK_MATCH_SET];
assign DebugsignalmatchCsr[0] = Debugsignalmatch0Csr;
assign DebugsignalmatchCsr[1] = Debugsignalmatch1Csr;
assign DebugsignalmatchCsr[2] = Debugsignalmatch2Csr;
assign DebugsignalmatchCsr[3] = Debugsignalmatch3Csr;
assign DebugsignalmaskCsr[0] = Debugsignalmask0Csr;
assign DebugsignalmaskCsr[1] = Debugsignalmask1Csr;
assign DebugsignalmaskCsr[2] = Debugsignalmask2Csr;
assign DebugsignalmaskCsr[3] = Debugsignalmask3Csr;

ClacounterCfgCsrWr_s  ClacounterCfgCsrWr[CLA_NUMBER_OF_COUNTERS];
assign Clacounter0CfgCsrWr = CrCdbgclacounter0CfgCsrWr_s'(ClacounterCfgCsrWr[0]);
assign Clacounter1CfgCsrWr = CrCdbgclacounter1CfgCsrWr_s'(ClacounterCfgCsrWr[1]);
assign Clacounter2CfgCsrWr = CrCdbgclacounter2CfgCsrWr_s'(ClacounterCfgCsrWr[2]);
assign Clacounter3CfgCsrWr = CrCdbgclacounter3CfgCsrWr_s'(ClacounterCfgCsrWr[3]);
always_comb begin 
       ClactrlstatusWr = '0;
       ClactrlstatusWr.CurrentNodeWrEn = 1'b1;
       ClactrlstatusWr.Data.CurrentNode = current_node_id;
end 
//Clear EAP Status if w2c value is same as current status.
assign node_eap_status_w2c[3][3] = EapstatusCsr.Node3Eap3W2C;
assign node_eap_status_w2c[2][3] = EapstatusCsr.Node2Eap3W2C;
assign node_eap_status_w2c[1][3] = EapstatusCsr.Node1Eap3W2C;
assign node_eap_status_w2c[0][3] = EapstatusCsr.Node0Eap3W2C;

assign node_eap_status_w2c[3][2] = EapstatusCsr.Node3Eap2W2C;
assign node_eap_status_w2c[2][2] = EapstatusCsr.Node2Eap2W2C;
assign node_eap_status_w2c[1][2] = EapstatusCsr.Node1Eap2W2C;
assign node_eap_status_w2c[0][2] = EapstatusCsr.Node0Eap2W2C;

assign node_eap_status_w2c[3][1] = EapstatusCsr.Node3Eap1W2C;
assign node_eap_status_w2c[2][1] = EapstatusCsr.Node2Eap1W2C;
assign node_eap_status_w2c[1][1] = EapstatusCsr.Node1Eap1W2C;
assign node_eap_status_w2c[0][1] = EapstatusCsr.Node0Eap1W2C;

assign node_eap_status_w2c[3][0] = EapstatusCsr.Node3Eap0W2C;
assign node_eap_status_w2c[2][0] = EapstatusCsr.Node2Eap0W2C;
assign node_eap_status_w2c[1][0] = EapstatusCsr.Node1Eap0W2C;
assign node_eap_status_w2c[0][0] = EapstatusCsr.Node0Eap0W2C;

//Record EAP Status.
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

assign DbgSignalSnapShotNode0Eap0CsrWr.ValueWrEn = (snapshot_capture_per_eap[0][0] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap1CsrWr.ValueWrEn = (snapshot_capture_per_eap[0][1] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap2CsrWr.ValueWrEn = (snapshot_capture_per_eap[0][2] == 1) && (current_node_id == 0);
assign DbgSignalSnapShotNode0Eap3CsrWr.ValueWrEn = (snapshot_capture_per_eap[0][3] == 1) && (current_node_id == 0);

assign DbgSignalSnapShotNode1Eap0CsrWr.ValueWrEn = (snapshot_capture_per_eap[1][0] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap1CsrWr.ValueWrEn = (snapshot_capture_per_eap[1][1] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap2CsrWr.ValueWrEn = (snapshot_capture_per_eap[1][2] == 1) && (current_node_id == 1);
assign DbgSignalSnapShotNode1Eap3CsrWr.ValueWrEn = (snapshot_capture_per_eap[1][3] == 1) && (current_node_id == 1);

assign DbgSignalSnapShotNode2Eap0CsrWr.ValueWrEn = (snapshot_capture_per_eap[2][0] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap1CsrWr.ValueWrEn = (snapshot_capture_per_eap[2][1] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap2CsrWr.ValueWrEn = (snapshot_capture_per_eap[2][0] == 1) && (current_node_id == 2);
assign DbgSignalSnapShotNode2Eap3CsrWr.ValueWrEn = (snapshot_capture_per_eap[2][1] == 1) && (current_node_id == 2);

assign DbgSignalSnapShotNode3Eap0CsrWr.ValueWrEn = (snapshot_capture_per_eap[3][0] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap1CsrWr.ValueWrEn = (snapshot_capture_per_eap[3][1] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap2CsrWr.ValueWrEn = (snapshot_capture_per_eap[3][2] == 1) && (current_node_id == 3);
assign DbgSignalSnapShotNode3Eap3CsrWr.ValueWrEn = (snapshot_capture_per_eap[3][3] == 1) && (current_node_id == 3);

//Delay debug signal by 1 clock. See bug RVDE  14490

always@(posedge gated_clock)
  if (reset_n == 0) 
     debug_signals_d1 <= '0;
  else 
     debug_signals_d1 <= debug_signals_aligned;

always@(posedge gated_clock) begin
  if (reset_n == 0) 
     external_action_debug_interrupt <= 1'b0;
  else if(debug_interrupt_pulse)
     external_action_debug_interrupt <= 1'b1;
  else if({reset_eap_status_w2c[3],reset_eap_status_w2c[2],reset_eap_status_w2c[1],reset_eap_status_w2c[0]} != 0)
     external_action_debug_interrupt <= 1'b0;
end

assign DbgSignalSnapShotNode0Eap0CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode0Eap1CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode0Eap2CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode0Eap3CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode1Eap0CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode1Eap1CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode1Eap2CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode1Eap3CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode2Eap0CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode2Eap1CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode2Eap2CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode2Eap3CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode3Eap0CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode3Eap1CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode3Eap2CsrWr.Data = debug_signals_d1;
assign DbgSignalSnapShotNode3Eap3CsrWr.Data = debug_signals_d1;

generic_dff #(.WIDTH($bits(xtrigger_in)))  xtrigger_in_ff  (.out(xtrigger_in_d1),         .in(xtrigger_in), .clk(gated_clock), .rst_n(reset_n), .en(1'b1));
generic_dff #(.WIDTH($bits(xtrigger_out))) xtrigger_out_ff (  .out(xtrigger_out), .in(xtrigger_out_pre_ff), .clk(gated_clock), .rst_n(reset_n), .en(1'b1));

dfd_xtrigger_stretch_circuit xtrigger_stretch_circuit_inst (
  .clock(gated_clock),
  .reset_n(reset_n),
  .reset_n_warm_ovrride(reset_n_warm_ovrride),
  .xtrigger_in(xtrigger_out_pre_ff),
  .xtrigger_out(xtrigger_out_stretch),

  .CrCsrCdbgclaxtriggertimestretch(XtriggertimestretchCsr)
);

dfd_cla_event_gen ClaEventGen (
.clock                        ( gated_clock ),
.reset_n                      ( reset_n ),
.debug_signals                ( debug_signals_aligned ),
.ClacounterCfgCsr             ( ClacounterCfgCsr ),
.ClacounterCfgCsrWr           ( ClacounterCfgCsrWr ),
.DebugsignalmatchCsr          ( DebugsignalmatchCsr ),
.DebugsignalmaskCsr           ( DebugsignalmaskCsr ),
.DebugsignaledgedetectcfgCsr  ( DebugsignaledgedetectcfgCsr ),
.DebugsignalTransitionmaskCsr ( DebugsignalTransitionmaskCsr ),
.DebugsignalTransitionfromCsr ( DebugsignalTransitionfromCsr ),
.DebugsignalTransitiontoCsr   ( DebugsignalTransitiontoCsr ), 
.DebugsignalOnescountmaskCsr  ( DebugsignalOnescountmaskCsr ),
.DebugsignalOnescountvalueCsr ( DebugsignalOnescountvalueCsr ),
.DebugsignalchangeCsr         ( DebugsignalchangeCsr ), 
.cla_counter_controls         ( counter_actions ),
.xtrigger_in                  ( xtrigger_in_d1 & (~self_filter)), // filter self xtrigger
.event_bus                    ( event_bus )
);

genvar i;
generate
for (i=0;i<CLA_NUMBER_OF_NODES;i=i+1)
  dfd_cla_node_eap_set #(.MY_NODE_ID(i)) cla_node_eap_set_inst
   (
   .clock                    ( gated_clock ),
   .reset_n                  ( reset_n ),
   .enable_eap               ( ClactrlstatusCsr.EnableEap  ),
   .event_bus                ( event_bus_mod ),
   .NodeEapCsr               ( {NodeEap0Csr[i], NodeEap1Csr[i], NodeEap2Csr[i], NodeEap3Csr[i]} ),
   .next_node_action_bus     ( next_node_action_bus[i] ),
   .next_node_custom_action_bus     ( next_node_custom_action_bus[i] ),
   .next_destination_node_id ( next_destination_node_id[i] ),
   .node_eap_status_w2c      ( node_eap_status_w2c[i] ),
   .current_node_id          ( current_node_id ),
   .reset_eap_status_w2c     ( reset_eap_status_w2c[i] ),
   .snapshot_capture_per_eap ( snapshot_capture_per_eap[i] ),
   .node_eap_status          ( node_eap_status[i] )
  );
endgenerate  


dfd_cla_action_gen ClaActionGen 
(
   .clock                    ( gated_clock ),
   .reset_n                  ( reset_n ),
   .reset_n_warm_ovrride     (reset_n_warm_ovrride),
   .enable_eap               ( ClactrlstatusCsr.EnableEap ),
   .cla_chain_loop_delay     ( ClactrlstatusCsr.ClaChainLoopDelay),
   .next_node_action_bus     ( next_node_action_bus ),
   .next_node_custom_action_bus     ( next_node_custom_action_bus ),
   .next_destination_node_id ( next_destination_node_id ), 
   .clock_halt_global_en     ( ~ClactrlstatusCsr.DisableGlobalClockHalt ),
   .clock_halt_local_en      ( ~ClactrlstatusCsr.DisableLocalClockHalt ),
   .clock_halt_global        ( external_action_halt_clock ),
   .clock_halt_local         ( external_action_halt_clock_local ),
   .debug_interrupt          ( debug_interrupt_pulse ),
   .toogle_gpio              ( external_action_toggle_gpio ),
   .start_trace              ( external_action_trace_start ),
   .stop_trace               ( external_action_trace_stop ),
   .trace_pluse              ( external_action_trace_pulse ),
   .xtrigger_out             ( xtrigger_out_pre_ff ),
   .self_filter              ( self_filter ),
   .custom_action_bus        ( external_action_custom ),
   // Internal Action Signals
   .counter_actions         (counter_actions),
   //Status
   .current_node_id         (current_node_id)
);

endmodule

