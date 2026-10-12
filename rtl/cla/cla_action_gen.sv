// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_action_gen
import cla_mmr_pkg::*;
import cla_pkg::*;
(
   input logic clock,
   input logic reset_n,
   input logic reset_n_warm_ovrride,
   input logic enable_eap,
   input logic [7-1:0] cla_chain_loop_delay,
   input logic clock_halt_global_en,
   input logic clock_halt_local_en,
   input logic [CLA_NUMBER_OF_ACTIONS-1:0] next_node_action_bus[CLA_NUMBER_OF_NODES],
   input logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] next_node_custom_action_bus[CLA_NUMBER_OF_NODES],
   input logic [CLA_NODE_ID_MSB:0] next_destination_node_id [CLA_NUMBER_OF_NODES],

   output  logic [XTRIGGER_WIDTH-1:0] self_filter,
   output  logic clock_halt_global,
   output  logic clock_halt_local,
   output  logic debug_interrupt,
   output  logic toggle_gpio,
   output  logic start_trace,
   output  logic stop_trace,
   output  logic trace_pulse,
   output  logic [XTRIGGER_WIDTH-1:0] xtrigger_out,
   output  logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  custom_action_bus,

   output  counter_controls counter_actions[CLA_NUMBER_OF_COUNTERS],

   output logic [CLA_NODE_ID_MSB:0] current_node_id
);

localparam CLA_CHAIN_LOOP_DELAY_WIDTH   = $bits(cla_chain_loop_delay);
localparam CLA_CHAIN_XTRIGGER_0  = 0;
localparam CLA_CHAIN_XTRIGGER_1  = 1;

logic [CLA_NODE_ID_MSB:0] next_current_node_id;
logic [CLA_NUMBER_OF_ACTIONS-1:0] action_bus, next_action_bus;
logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] next_custom_action_bus;

logic [XTRIGGER_WIDTH-1:0][CLA_CHAIN_LOOP_DELAY_WIDTH-1:0] filter_cnt, next_filter_cnt;
logic [XTRIGGER_WIDTH-1:0]                                 cla_chain_action_bus_triggers;

assign cla_chain_action_bus_triggers[CLA_CHAIN_XTRIGGER_0] = action_bus[ACTION_XTRIGGER0_OUT];
assign cla_chain_action_bus_triggers[CLA_CHAIN_XTRIGGER_1] = action_bus[ACTION_XTRIGGER1_OUT];

generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) u_dff_clk_hlt_det_global (
    .clk   (clock),
    .rst_n (reset_n),
    .en    (action_bus[ACTION_CLOCK_HALT] && clock_halt_global_en),
    .in    ('1),
    .out   (clock_halt_global)
);
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) u_dff_clk_hlt_det_local (
    .clk   (clock),
    .rst_n (reset_n),
    .en    (action_bus[ACTION_CLOCK_HALT] && clock_halt_local_en),
    .in    ('1),
    .out   (clock_halt_local)
);
generic_dff #(
    .WIDTH       ($bits(logic [CLA_NODE_ID_MSB+1-1:0])),
    .RESET_VALUE ('0)
) u_dff_curr_node_id (
    .clk   (clock),
    .rst_n (reset_n_warm_ovrride),
    .en    ('1),
    .in    (next_current_node_id),
    .out   (current_node_id)
);
generic_dff #(
    .WIDTH       ($bits(logic [CLA_NUMBER_OF_ACTIONS-1:0])),
    .RESET_VALUE ('0)
) u_dff_action_bus (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (next_action_bus),
    .out   (action_bus)
);
generic_dff #(
    .WIDTH       ($bits(logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0])),
    .RESET_VALUE ('0)
) u_dff_custom_action_bus (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (next_custom_action_bus),
    .out   (custom_action_bus)
);

generic_dff #(
    .WIDTH       ($bits(logic [XTRIGGER_WIDTH*CLA_CHAIN_LOOP_DELAY_WIDTH-1:0])),
    .RESET_VALUE ('0)
) u_dff_filter_cnt (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (next_filter_cnt),
    .out   (filter_cnt)
);

always_comb begin
   next_current_node_id = '0;

   if (enable_eap) begin
      for(int i=0;i<CLA_NUMBER_OF_NODES;i=i+1) begin
         next_current_node_id |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(i))?next_destination_node_id[i]:($clog2(CLA_NUMBER_OF_NODES)'(0));
      end
   end
end

always_comb begin
   next_action_bus = '0;
   next_custom_action_bus = '0;

   if (enable_eap) begin
      for(int k=0;k<CLA_NUMBER_OF_NODES;k=k+1) begin
         next_action_bus |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(k))?next_node_action_bus[k]:{CLA_NUMBER_OF_ACTIONS{1'b0}};
         next_custom_action_bus |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(k))?next_node_custom_action_bus[k]:{CLA_NUMBER_OF_CUSTOM_ACTIONS{1'b0}};
      end
   end
end

always_comb begin
   next_filter_cnt = filter_cnt;
   self_filter = '0;

   for (int ii = 0; ii < XTRIGGER_WIDTH; ii++) begin
      if (filter_cnt[ii] == 0) begin
         if (cla_chain_action_bus_triggers[ii] &&  (cla_chain_loop_delay == 7'b0)) begin
            self_filter[ii] = 1'b1;
         end else if (cla_chain_action_bus_triggers[ii]) begin
            next_filter_cnt[ii] = CLA_CHAIN_LOOP_DELAY_WIDTH'(1);
         end
      end else begin
         next_filter_cnt[ii] = filter_cnt[ii] + CLA_CHAIN_LOOP_DELAY_WIDTH'(1);

         if (filter_cnt[ii] >= cla_chain_loop_delay) begin
            next_filter_cnt[ii] = '0;
            self_filter[ii] = 1'b1;
         end
      end
   end
end

 always_comb
  begin

     debug_interrupt = action_bus[ACTION_DEBUG_INTERRUPT];
     toggle_gpio = action_bus[ACTION_TOGGLE_GPIO];
     start_trace = action_bus[ACTION_START_TRACE];
     stop_trace = action_bus[ACTION_STOP_TRACE];
     trace_pulse = action_bus[ACTION_TRACE_PULSE];

     xtrigger_out[0] = action_bus[ACTION_XTRIGGER0_OUT];
     xtrigger_out[1] = action_bus[ACTION_XTRIGGER1_OUT];
  end

genvar j;
generate
     for (j=0;j<CLA_NUMBER_OF_COUNTERS;j=j+1) begin : gen_counter_actions
     always@(*)
       begin
        counter_actions[j].increment_pulse      = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_INCREMENT_PULSE];
        counter_actions[j].clear_ctr            = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_CLEAR_CTR];
        counter_actions[j].auto_increment       = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_AUTO_INCREMENT];
        counter_actions[j].stop_auto_increment  = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_STOP_AUTO_INCREMENT];
      end
     end
endgenerate

endmodule
