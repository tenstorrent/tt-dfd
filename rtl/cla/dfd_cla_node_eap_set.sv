module dfd_cla_node_eap_set
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
    input NodeEapCsr_s NodeEapCsr[CLA_NUMBER_OF_EAPS_PER_NODE],
    input logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0] node_eap_status_w2c,
    input logic [CLA_NODE_ID_MSB:0] current_node_id,
    output logic [CLA_NUMBER_OF_ACTIONS-1:0]  next_node_action_bus,
    output logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  next_node_custom_action_bus,
    output logic [CLA_NODE_ID_MSB:0]          next_destination_node_id, 
    output logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0] reset_eap_status_w2c,
    output logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0] snapshot_capture_per_eap, 
    output logic [CLA_NUMBER_OF_EAPS_PER_NODE-1:0] node_eap_status
);

    logic [CLA_NUMBER_OF_ACTIONS-1:0]  next_node_action_bus_per_eap[CLA_NUMBER_OF_EAPS_PER_NODE];
    logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  next_node_custom_action_bus_per_eap[CLA_NUMBER_OF_EAPS_PER_NODE];
    logic                              next_node_custom_action_bus_enable_per_eap[CLA_NUMBER_OF_EAPS_PER_NODE]; // Not being used currently
    logic [CLA_NODE_ID_MSB:0]          next_destination_node_id_per_eap[CLA_NUMBER_OF_EAPS_PER_NODE];
    logic                              eap_logic_operation_result[CLA_NUMBER_OF_EAPS_PER_NODE];
    genvar i;
    generate
    for(i=0;i<CLA_NUMBER_OF_EAPS_PER_NODE;i=i+1)    
       dfd_cla_node_eap #(.MY_NODE_ID(MY_NODE_ID)) cla_node_eap_inst 
       (
        .clock(clock),
        .reset_n(reset_n),
        .enable_eap(enable_eap),
        .event_bus(event_bus),
        .NodeEapCsr(NodeEapCsr[i]),
        .next_node_action_bus(next_node_action_bus_per_eap[i]),
        .next_node_custom_action_bus(next_node_custom_action_bus_per_eap[i]),
        .next_node_custom_action_bus_enable(next_node_custom_action_bus_enable_per_eap[i]),
        .next_destination_node_id(next_destination_node_id_per_eap[i]), 
        .eap_logic_operation_result(eap_logic_operation_result[i]),
        .eap_status_w2c(node_eap_status_w2c[i]),
        .current_node_id(current_node_id),
        .reset_eap_status_w2c(reset_eap_status_w2c[i]),
        .eap_status(node_eap_status[i])
    );
    for(i=0;i<CLA_NUMBER_OF_EAPS_PER_NODE;i=i+1)    
      assign snapshot_capture_per_eap[i] = eap_logic_operation_result[i];
    endgenerate

    //FIXME_MUSTFIX_BABYLON: Parameterize properly for scaling to higher number of nodes
    always@(*)
      begin
        next_node_action_bus = next_node_action_bus_per_eap[3] | next_node_action_bus_per_eap[2] | next_node_action_bus_per_eap[1] | next_node_action_bus_per_eap[0] ;
        next_node_custom_action_bus = next_node_custom_action_bus_per_eap[3] |next_node_custom_action_bus_per_eap[2] |next_node_custom_action_bus_per_eap[1] | next_node_custom_action_bus_per_eap[0] ;
        if (eap_logic_operation_result[0] == 1) // EAP0 destination node takes priority
          next_destination_node_id = next_destination_node_id_per_eap[0];
        else if (eap_logic_operation_result[1] == 1) 
          next_destination_node_id = next_destination_node_id_per_eap[1];
        else if (eap_logic_operation_result[2] == 1) 
          next_destination_node_id = next_destination_node_id_per_eap[2];
        else if (eap_logic_operation_result[3] == 1) 
          next_destination_node_id = next_destination_node_id_per_eap[3];
        else 
          next_destination_node_id = $clog2(CLA_NUMBER_OF_NODES)'(MY_NODE_ID);
      end


endmodule


