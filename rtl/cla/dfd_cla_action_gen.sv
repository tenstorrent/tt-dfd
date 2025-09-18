module dfd_cla_action_gen 
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
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
   // External Action Signals
   output  logic [XTRIGGER_WIDTH-1:0] self_filter,
   output  logic clock_halt_global,
   output  logic clock_halt_local,
   output  logic debug_interrupt,
   output  logic toogle_gpio,
   output  logic start_trace,
   output  logic stop_trace,
   output  logic trace_pluse,
   output  logic [XTRIGGER_WIDTH-1:0] xtrigger_out,
   output  logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0]  custom_action_bus,
   // Internal Action Signals
   output  counter_controls counter_actions[CLA_NUMBER_OF_COUNTERS],
   //Status
   output logic [CLA_NODE_ID_MSB:0] current_node_id
);

localparam CLA_CHAIN_LOOP_DELAY_WIDTH   = $bits(cla_chain_loop_delay); // Chain loop delay can be a value upto 127 (7 bits) ->  CLA_CHAIN_LOOP_DELAY_WIDTH = 7
localparam CLA_CHAIN_XTRIGGER_0  = 0;
localparam CLA_CHAIN_XTRIGGER_1  = 1;
// localparam CLA_CHAIN_CLOCKHALT   = 2;
// localparam NUM_CLA_CHAIN_SIGNALS = 3;

logic [CLA_NODE_ID_MSB:0] next_current_node_id;
logic [CLA_NUMBER_OF_ACTIONS-1:0] action_bus, next_action_bus; 
logic [CLA_NUMBER_OF_CUSTOM_ACTIONS-1:0] next_custom_action_bus; 

logic [XTRIGGER_WIDTH-1:0][CLA_CHAIN_LOOP_DELAY_WIDTH-1:0] filter_cnt, next_filter_cnt;
logic [XTRIGGER_WIDTH-1:0]                                 cla_chain_action_bus_triggers; // used for coding simplicity. redirection

assign cla_chain_action_bus_triggers[CLA_CHAIN_XTRIGGER_0] = action_bus[ACTION_XTRIGGER0_OUT];
assign cla_chain_action_bus_triggers[CLA_CHAIN_XTRIGGER_1] = action_bus[ACTION_XTRIGGER1_OUT];

generic_dff #(.WIDTH(1), .RESET_VALUE('0)) u_dff_clk_hlt_det_global (.out(clock_halt_global), .in('1), .en(action_bus[ACTION_CLOCK_HALT] && clock_halt_global_en), .clk(clock), .rst_n(reset_n));
generic_dff #(.WIDTH(1), .RESET_VALUE('0)) u_dff_clk_hlt_det_local  (.out(clock_halt_local), .in('1), .en(action_bus[ACTION_CLOCK_HALT] && clock_halt_local_en), .clk(clock), .rst_n(reset_n));
generic_dff #(.WIDTH(CLA_NODE_ID_MSB+1), .RESET_VALUE('0)) u_dff_curr_node_id (.out(current_node_id), .in(next_current_node_id), .en(1'b1), .clk(clock), .rst_n(reset_n_warm_ovrride));
generic_dff #(.WIDTH(CLA_NUMBER_OF_ACTIONS), .RESET_VALUE('0)) u_dff_action_bus (.out(action_bus), .in(next_action_bus), .en(1'b1), .clk(clock), .rst_n(reset_n));
generic_dff #(.WIDTH(CLA_NUMBER_OF_CUSTOM_ACTIONS), .RESET_VALUE('0)) u_dff_custom_action_bus (.out(custom_action_bus), .in(next_custom_action_bus), .en(1'b1), .clk(clock), .rst_n(reset_n));

generic_dff #(.WIDTH(XTRIGGER_WIDTH*CLA_CHAIN_LOOP_DELAY_WIDTH), .RESET_VALUE('0)) u_dff_filter_cnt (.out(filter_cnt), .in(next_filter_cnt), .en(1'b1), .clk(clock), .rst_n(reset_n));

// Determine current node id:
always_comb begin
   next_current_node_id = '0;
   
   if (enable_eap) begin
      for(int i=0;i<CLA_NUMBER_OF_NODES;i=i+1) begin
         next_current_node_id |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(i))?next_destination_node_id[i]:($clog2(CLA_NUMBER_OF_NODES)'(0));
      end
   end
end 

//Select the node_action_bus
always_comb begin
   next_action_bus = '0;
   next_custom_action_bus = '0;

   for(int k=0;k<CLA_NUMBER_OF_NODES;k=k+1) begin
      next_action_bus |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(k))?next_node_action_bus[k]:{CLA_NUMBER_OF_ACTIONS{1'b0}};
      next_custom_action_bus |= (current_node_id == ($clog2(CLA_NUMBER_OF_NODES))'(k))?next_node_custom_action_bus[k]:{CLA_NUMBER_OF_CUSTOM_ACTIONS{1'b0}};
   end
end

 // CLA SELF FILTER MASK 
 /*
   The CLA should be able to filter it's own signal out from the network. As such, the filter will prevent an xtrigger in from itself. The CLA will use an
   MMR to indicate the number of cycles before the xtrigger-in signal is masked. 

   Notice that if another xtrigger occurs before the self-filter expiration, the 
 */

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


 //Parse the action bus
 always_comb
  begin
      // as per Dfd_Core_Logic_Analyzer_Specification --> List of Actions Chapter.
     debug_interrupt = action_bus[ACTION_DEBUG_INTERRUPT];
     toogle_gpio = action_bus[ACTION_TOOGLE_GPIO];
     start_trace = action_bus[ACTION_START_TRACE];
     stop_trace = action_bus[ACTION_STOP_TRACE];
     trace_pluse= action_bus[ACTION_TRACE_PLUSE];

     xtrigger_out[0] = action_bus[ACTION_XTRIGGER0_OUT];
     xtrigger_out[1] = action_bus[ACTION_XTRIGGER1_OUT];
  end

genvar j;
generate
     for (j=0;j<CLA_NUMBER_OF_COUNTERS;j=j+1) begin
     always@(*)
       begin
        counter_actions[j].increment_pulse      = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_INCREMENT_PULSE];  
        counter_actions[j].clear_ctr            = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_CLEAR_CTR];  
        counter_actions[j].auto_increment       = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_AUTO_INCREMENT];   
        counter_actions[j].stop_auto_increment  = action_bus[j*CLA_NUMBER_OF_ACTIONS_PER_COUNTER+ ACTION_BASE_COUNTER_STOP_AUTO_INCREMENT];
      end
     end
endgenerate


 // CLA CHAIN DATA MASKING LOGIC - // DEPRECATED: CLA CHAIN DATA MASKING NO LONGER USED FROM STAR Network
//  logic [NUM_CLA_CHAIN_SIGNALS-1:0][CLA_CHAIN_LOOP_DELAY_WIDTH:0]          cla_chain_wnd_counter;
//  logic [NUM_CLA_CHAIN_SIGNALS-1:0]                                      cla_chain_wnd;
//  logic [NUM_CLA_CHAIN_SIGNALS-1:0]                                      cla_chain_wnd_expired;
//  logic [NUM_CLA_CHAIN_SIGNALS-1:0]                                      cla_chain_wnd_start;
//  logic [NUM_CLA_CHAIN_SIGNALS-1:0]                                      cla_chain_mask;

 

//  for(genvar i = 0; i < 3; i=i+1) begin

//    always_comb begin
//       cla_chain_wnd_expired[i] = (cla_chain_wnd_counter[i] >= {1'b0, cla_chain_loop_delay}); // timeout
//       cla_chain_wnd_start[i]   = (cla_chain_action_bus_triggers[i]) && (cla_chain_wnd_counter[i] == '0); // New signal sent
//       cla_chain_mask[i] = ~cla_chain_wnd[i]; // mask based on window enable
//    end

//    always_ff@(posedge clock) 
//    if(!reset_n)
//       cla_chain_wnd[i] <= '0;
//    else begin
//       if      (cla_chain_wnd_start[i])    cla_chain_wnd[i] <= '1;
//       else if (cla_chain_wnd_expired[i])  cla_chain_wnd[i] <= '0;
//    end

//    always_ff@(posedge clock)
//    if(!reset_n)
//       cla_chain_wnd_counter[i] <= '0;
//    else begin
//       if       (cla_chain_wnd_expired[i])                 cla_chain_wnd_counter[i] <= '0;
//       else if  ((cla_chain_wnd[i] | cla_chain_wnd_start[i])) cla_chain_wnd_counter[i] <= cla_chain_wnd_counter[i] + (CLA_CHAIN_LOOP_DELAY_WIDTH+1)'(1'b1);
   
//    end
//  end

endmodule 

