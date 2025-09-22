// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_cla_node_eap
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
 #(
   parameter MY_NODE_ID = $clog2(CLA_NUMBER_OF_NODES)'(0)
) 
(
    input logic clock,
    input logic reset_n,
    input logic enable_eap,
    input logic [CLA_NUMBER_OF_EVENTS-1:0] event_bus,
    input NodeEapCsr_s NodeEapCsr,
    input logic eap_status_w2c,
    input logic [CLA_NODE_ID_MSB:0] current_node_id,
    output logic [CLA_NUMBER_OF_ACTIONS-1:0]  next_node_action_bus,
    output logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  next_node_custom_action_bus,
    output logic                                     next_node_custom_action_bus_enable,
    output logic [CLA_NODE_ID_MSB:0]          next_destination_node_id, 
    output logic eap_logic_operation_result,                          // This bit will be result of logical op of event_type0 and event_type1
    output logic eap_status,
    output logic reset_eap_status_w2c
);
    //--------------------------------------------------------------
    //All actions are asserted of all the conditions below are met:
    //  a. Node is active
    //  b. Triggers are met
    // the action signals are de-asserted when the conditions are not met. 
    // the action signals are level triggered and not edge. Meaning,
    // action will be taken as long as the signal is asserted.

  logic event_type0_status_in_event_bus; // This bit will indicate if the selected event type0 is asserted on event bus
  logic event_type1_status_in_event_bus; // This bit will indicate if the selected event type1 is asserted on event bus
  logic event_type2_status_in_event_bus; // This bit will indicate if the selected event type2 is asserted on event bus
  logic [CLA_NUMBER_OF_ACTIONS-1:0]  action_bus_idle_value;
  logic debug_interrupt;
  logic eap_status_clr_rise_edge ;
  logic eap_status_w2c_dly;
  integer iter;

  //user defined function lookup result
  logic udf_result;
  // All event bus signals are assumed to be flopped at posedge from source...
  // Now to select the event from event bus using event_type
  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type0_qualified_event_bus; //Updated Event Bus only if the event bus is selected as per EAP.Event Type 0.
  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type1_qualified_event_bus; //Updated Event Bus only if the event bus is selected as per EAP.Event Type 1.
  logic [CLA_NUMBER_OF_EVENTS-1:0] event_type2_qualified_event_bus; //Updated Event Bus only if the event bus is selected as per EAP.Event Type 1.
  genvar i;
  generate
    for(i=0;i<CLA_NUMBER_OF_EVENTS;i=i+1) begin
      assign event_type0_qualified_event_bus[i] = (NodeEapCsr.EventType0== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0; 
      assign event_type1_qualified_event_bus[i] = (NodeEapCsr.EventType1== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0; 
      assign event_type2_qualified_event_bus[i] = (NodeEapCsr.EventType2== $clog2(CLA_NUMBER_OF_EVENTS)'(i))?event_bus[i]:1'b0; 
    end
  endgenerate
  assign event_type0_status_in_event_bus = |event_type0_qualified_event_bus;
  assign event_type1_status_in_event_bus = |event_type1_qualified_event_bus;
  assign event_type2_status_in_event_bus = |event_type2_qualified_event_bus;

  // Apply configured logical operation 
  always @ (*)
  begin
     case(NodeEapCsr.LogicalOp)
       2'b00:eap_logic_operation_result = event_type0_status_in_event_bus | event_type1_status_in_event_bus; // OR operation
       2'b01:eap_logic_operation_result = event_type0_status_in_event_bus & event_type1_status_in_event_bus; // AND operation
       2'b11:eap_logic_operation_result = !(event_type0_status_in_event_bus | event_type1_status_in_event_bus); // NOR operation
       default:eap_logic_operation_result = udf_result;//User Defind Function
     endcase
  end

  always @ (*)
  begin
     case ({event_type2_status_in_event_bus,event_type1_status_in_event_bus,event_type0_status_in_event_bus})
       3'b000:udf_result = NodeEapCsr.Udf[0];
       3'b001:udf_result = NodeEapCsr.Udf[1];
       3'b010:udf_result = NodeEapCsr.Udf[2];
       3'b011:udf_result = NodeEapCsr.Udf[3];
       3'b100:udf_result = NodeEapCsr.Udf[4];
       3'b101:udf_result = NodeEapCsr.Udf[5];
       3'b110:udf_result = NodeEapCsr.Udf[6];
       3'b111:udf_result = NodeEapCsr.Udf[7];
     endcase
  end

  //if the result of above logical operation is true and the node is enabled...
  // a. Drive Action & Custom Action Bus
  // Drive the action bus
  always @ (*)
   begin
    for(iter=0;iter<CLA_NUMBER_OF_ACTIONS;iter=iter+1)
      next_node_action_bus[iter] = (((NodeEapCsr.Action3 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapCsr.Action2 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapCsr.Action1 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                    ((NodeEapCsr.Action0 == $clog2(CLA_NUMBER_OF_ACTIONS)'(iter)) & eap_logic_operation_result)) ?
                                   enable_eap:
                                   action_bus_idle_value[iter];
   end

  always @ (*)
   begin
    action_bus_idle_value = '0;
    action_bus_idle_value[ACTION_DEBUG_INTERRUPT] = debug_interrupt; 
   end

 // Continue to drive interrupts till the eap status is cleared by SW.
  always_ff@(posedge clock)  
   begin
    if(!reset_n)
      debug_interrupt <= 1'b0;
    else  if ((next_node_action_bus[ACTION_DEBUG_INTERRUPT] == 1'b1) && (current_node_id == ($clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID)))  && (enable_eap == 1'b1))
      debug_interrupt <= 1'b1;
    else
      debug_interrupt <= 1'b0;
   end

  // Drive the custom action bus
  always @ (*)
   begin
    for(iter=0;iter<CLA_NUMBER_OF_CUSTOM_ACTIONS;iter=iter+1)
      next_node_custom_action_bus[iter] = ( (NodeEapCsr.CustomAction1Enable & (NodeEapCsr.CustomAction1 == $clog2(CLA_NUMBER_OF_CUSTOM_ACTIONS)'(iter)) & eap_logic_operation_result) ||
                                         (NodeEapCsr.CustomAction0Enable & (NodeEapCsr.CustomAction0 == $clog2(CLA_NUMBER_OF_CUSTOM_ACTIONS)'(iter)) & eap_logic_operation_result)) ?
                                         1'b1:
                                         1'b0; 
   end

  assign  next_node_custom_action_bus_enable = (NodeEapCsr.CustomAction1Enable ||  NodeEapCsr.CustomAction0Enable ); 

  // b. Select destinatin id
    assign next_destination_node_id = (eap_logic_operation_result)?NodeEapCsr.DestNode:($clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID));

  // c. Indicate the eap node was activated (recorded in eap status)
  //    The eap_status is set to 1, when logic operation result is true when current node equals NODE ID.
  //    Eap status is cleared on w2c irrespective of current node id.
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


