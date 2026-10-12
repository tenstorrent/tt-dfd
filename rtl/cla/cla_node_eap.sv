// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_node_eap
import cla_mmr_pkg::*;
import cla_pkg::*;
 #(
   parameter MY_NODE_ID = $clog2(CLA_NUMBER_OF_NODES)'(0)
)
(
    input logic clock,
    input logic reset_n,
    input logic enable_eap,
    input logic [CLA_NUMBER_OF_EVENTS-1:0] event_bus,
    input NodeEapMmr_s NodeEapMmr,
    input logic eap_status_w2c,
    input logic [CLA_NODE_ID_MSB:0] current_node_id,
    output logic [CLA_NUMBER_OF_ACTIONS-1:0]  next_node_action_bus,
    output logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  next_node_custom_action_bus,
    output logic                                     next_node_custom_action_bus_enable,
    output logic [CLA_NODE_ID_MSB:0]          next_destination_node_id,
    output logic eap_logic_operation_result,
    output logic eap_status,
    output logic reset_eap_status_w2c
);

  logic event_type0_status_in_event_bus;
  logic event_type1_status_in_event_bus;
  logic event_type2_status_in_event_bus;
  logic [CLA_NUMBER_OF_ACTIONS-1:0]  action_bus_idle_value;
  logic debug_interrupt;
  logic eap_status_clr_rise_edge ;
  logic eap_status_w2c_dly;
  integer iter;

  logic udf_result;

  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type0_qualified_event_bus;
  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type1_qualified_event_bus;
  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type2_qualified_event_bus;
  genvar i;
  generate
    for(i=0;i<CLA_NUMBER_OF_EVENTS;i=i+1) begin : gen_event_select
      assign event_type0_qualified_event_bus[i] = (NodeEapMmr.EventType0== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0;
      assign event_type1_qualified_event_bus[i] = (NodeEapMmr.EventType1== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0;
      assign event_type2_qualified_event_bus[i] = (NodeEapMmr.EventType2== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0;
    end
  endgenerate
  assign event_type0_status_in_event_bus = |event_type0_qualified_event_bus;
  assign event_type1_status_in_event_bus = |event_type1_qualified_event_bus;
  assign event_type2_status_in_event_bus = |event_type2_qualified_event_bus;

  always @ (*)
  begin
     case(NodeEapMmr.LogicalOp)
       2'b00:eap_logic_operation_result = event_type0_status_in_event_bus | event_type1_status_in_event_bus;
       2'b01:eap_logic_operation_result = event_type0_status_in_event_bus & event_type1_status_in_event_bus;
       2'b11:eap_logic_operation_result = !(event_type0_status_in_event_bus | event_type1_status_in_event_bus);
       default:eap_logic_operation_result = udf_result;
     endcase
  end

  always @ (*)
  begin
     case ({event_type2_status_in_event_bus,event_type1_status_in_event_bus,event_type0_status_in_event_bus})
       3'b000:udf_result = NodeEapMmr.Udf[0];
       3'b001:udf_result = NodeEapMmr.Udf[1];
       3'b010:udf_result = NodeEapMmr.Udf[2];
       3'b011:udf_result = NodeEapMmr.Udf[3];
       3'b100:udf_result = NodeEapMmr.Udf[4];
       3'b101:udf_result = NodeEapMmr.Udf[5];
       3'b110:udf_result = NodeEapMmr.Udf[6];
       3'b111:udf_result = NodeEapMmr.Udf[7];
     endcase
  end

  always @ (*)
   begin
    for(iter=0;iter<CLA_NUMBER_OF_ACTIONS;iter=iter+1)
      next_node_action_bus[iter] = (((NodeEapMmr.Action3 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapMmr.Action2 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapMmr.Action1 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapMmr.Action0 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result)) ?
                                   enable_eap:
                                   action_bus_idle_value[iter];
   end

  always @ (*)
   begin
    action_bus_idle_value = '0;
    action_bus_idle_value[ACTION_DEBUG_INTERRUPT] = debug_interrupt;
   end

  always_ff@(posedge clock)
   begin
    if(!reset_n)
      debug_interrupt <= 1'b0;
    else  if ((next_node_action_bus[ACTION_DEBUG_INTERRUPT] == 1'b1) && (current_node_id == ($clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID)))  && (enable_eap == 1'b1))
      debug_interrupt <= 1'b1;
    else
      debug_interrupt <= 1'b0;
   end

  always @ (*)
   begin
    for(iter=0;iter<CLA_NUMBER_OF_CUSTOM_ACTIONS;iter=iter+1)
      next_node_custom_action_bus[iter] = ( (NodeEapMmr.CustomAction1Enable & (NodeEapMmr.CustomAction1 == $clog2(CLA_NUMBER_OF_CUSTOM_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                         (NodeEapMmr.CustomAction0Enable & (NodeEapMmr.CustomAction0 == $clog2(CLA_NUMBER_OF_CUSTOM_ACTIONS)'(iter)) & eap_logic_operation_result)) ?
                                         1'b1:
                                         1'b0;
   end

  assign  next_node_custom_action_bus_enable = (NodeEapMmr.CustomAction1Enable ||  NodeEapMmr.CustomAction0Enable );

    assign next_destination_node_id = (eap_logic_operation_result)?NodeEapMmr.DestNode:($clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID));

  always_ff@(posedge clock)  begin
    if(!reset_n)
        eap_status <= '0;
    else if ((eap_logic_operation_result == 1'b1) && (current_node_id == ($clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID))) && (enable_eap == 1'b1))
        eap_status <=  1'b1;
    else if (eap_status_clr_rise_edge == 1'b1)
        eap_status <=  1'b0;
  end

  always_ff@(posedge clock)  begin
    if(!reset_n)
      eap_status_w2c_dly <= 1'b0;
    else
      eap_status_w2c_dly <= eap_status_w2c;
  end
  assign eap_status_clr_rise_edge = (eap_status_w2c == 1'b1) &&  (eap_status_w2c_dly == 1'b0);
  assign reset_eap_status_w2c = eap_status_clr_rise_edge;

endmodule
