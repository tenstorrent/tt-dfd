//Module to instantiate all event generators.
module dfd_cla_event_gen
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input logic clock,
   input logic reset_n,
   input logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,

   input  ClacounterCfgCsr_s   ClacounterCfgCsr   [CLA_NUMBER_OF_COUNTERS],
   output ClacounterCfgCsrWr_s ClacounterCfgCsrWr [CLA_NUMBER_OF_COUNTERS],

   input DebugsignalmatchCsr_s DebugsignalmatchCsr[CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignalmaskCsr_s  DebugsignalmaskCsr [CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignaledgedetectcfgCsr_s   DebugsignaledgedetectcfgCsr,
   input DebugsignalTransitionmaskCsr_s  DebugsignalTransitionmaskCsr,
   input DebugsignalTransitionfromCsr_s  DebugsignalTransitionfromCsr,
   input DebugsignalTransitiontoCsr_s    DebugsignalTransitiontoCsr,
   input DebugsignalOnescountmaskCsr_s   DebugsignalOnescountmaskCsr,
   input DebugsignalOnescountvalueCsr_s  DebugsignalOnescountvalueCsr,
   input DebugsignalchangeCsr_s          DebugsignalchangeCsr, 
   input counter_controls        cla_counter_controls[CLA_NUMBER_OF_COUNTERS],

   input logic [XTRIGGER_WIDTH-1:0] xtrigger_in,
   output logic [CLA_NUMBER_OF_EVENTS-1:0] event_bus 
);

// Using event_bus[15] for core time match event generation
// It will be overridden in dfd_core_logic_analyzer.sv
assign event_bus[63:32]= 32'b0; //Disable (Event not active).  
assign event_bus[15:13]= 3'b0;  //Disable (Event not active).  
assign event_bus[0]= 1'b0; //Disable (Event not active). 
assign event_bus[1]= 1'b1; //Always On (The event is active all the time. Useful for default actions.) 

genvar i;
generate
 
  //Event Generator:
  //Match (positive filter) Match Debug Signals with a given mask and value. 
  //No Match1 (negative filter) 
  for (i=0;i<LOWER_CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1)
  begin
   dfd_cla_debug_signals_match lower_cla_debug_signals_match_inst (
                             .clock(clock),
                             .reset_n(reset_n),
                             .DebugsignalmaskCsr(DebugsignalmaskCsr[i]),
                             .DebugsignalmatchCsr(DebugsignalmatchCsr[i]),
                             .debug_signals(debug_signals),
                             .debug_signals_positive_match(event_bus[LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)]),
                             .debug_signals_negative_match(event_bus[LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)+1]));
  end

  for (i=0;i<UPPER_CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1)
  begin
   dfd_cla_debug_signals_match upper_cla_debug_signals_match_inst (
                             .clock(clock),
                             .reset_n(reset_n),
                             .DebugsignalmaskCsr(DebugsignalmaskCsr[i+LOWER_CLA_NUMBER_OF_MASK_MATCH_SET]),
                             .DebugsignalmatchCsr(DebugsignalmatchCsr[i+LOWER_CLA_NUMBER_OF_MASK_MATCH_SET]),
                             .debug_signals(debug_signals),
                             .debug_signals_positive_match(event_bus[UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)]),
                             .debug_signals_negative_match(event_bus[UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)+1]));
  end




  //Event Generator:
  //Pos-edge :Look for a transition of 0--> 1 on a given bit of Debug Signals.  
  //Neg-edge :Look for a transition of 1--> 0 on a given bit of Debug Signals 
  dfd_cla_edge_detect cla_edge_detect_inst(
                             .clock(clock),
                             .reset_n(reset_n),
                             .DebugsignaledgedetectcfgCsr(DebugsignaledgedetectcfgCsr),
                             .debug_signals(debug_signals),
                             .debug_signal_edge_detect({event_bus[DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS+1],event_bus[DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS]}));

  
  // Look for transition of Debug Signals from Value A (with Mask A) to Value B (with Mask B). Useful for tracking state machine transitions.  
  dfd_cla_debug_signals_transition dfd_cla_debug_signals_transition (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .DebugsignalTransitionmaskCsr(DebugsignalTransitionmaskCsr),
                             .DebugsignalTransitionfromCsr(DebugsignalTransitionfromCsr),
                             .DebugsignalTransitiontoCsr(DebugsignalTransitiontoCsr),
                             .debug_signals_transition_match(event_bus[DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS]));

  //Cross Trigger Input from CLA star network.
  //Cross Trigger In 1 
  //Cross Trigger In 2
  assign event_bus[XTRIGGER_EVTBUS_POS]  =xtrigger_in[0];
  assign event_bus[XTRIGGER_EVTBUS_POS+1]=xtrigger_in[1];

  // Count 1s (useful for one-hot. Why flexiblity in counting number of 1s? We can track more than 1 one-hot FSMs)
  dfd_cla_debug_signals_ones_count dfd_cla_debug_signals_ones_count (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .DebugsignalOnescountmaskCsr(DebugsignalOnescountmaskCsr),
                             .DebugsignalOnescountvalueCsr(DebugsignalOnescountvalueCsr),
                             .debug_signals_ones_count_match(event_bus[DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS])); 

  dfd_cla_debug_signals_change dfd_cla_debug_signals_change (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .DebugsignalchangeCsr(DebugsignalchangeCsr), 
                             .debug_signals_change_match(event_bus[DEBUG_SIGNALS_CHANGE_EVTBUS_POS])); 
 
  // CLA Counter# Target Match 
  // CLA Counter# Target Overflow 
  // CLA Counter# > Counter Target 
  for(i=0;i<CLA_NUMBER_OF_COUNTERS;i=i+1)
  begin
   dfd_cla_counter cla_counter_inst(
                             .clock(clock),
                             .reset_n(reset_n),
                             .cla_counter_controls(cla_counter_controls[i]),
                             .ClacounterCfgCsr(ClacounterCfgCsr[i]),
                             .target_match   (event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+0+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .target_overflow(event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+1+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .below_target   (event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+2+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .next_WrData(ClacounterCfgCsrWr[i])
   );
  end
 endgenerate


endmodule

