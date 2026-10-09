// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_event_gen
import cla_mmr_pkg::*;
import cla_pkg::*;
#(
  parameter DEBUG_SIGNAL_WIDTH = 64
)
(
   input logic clock,
   input logic reset_n,
   input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
   input logic i_ext_posedge,

   input  ClacounterCfgMmr_s   ClacounterCfgMmr   [CLA_NUMBER_OF_COUNTERS],
   output ClacounterCfgMmrWr_s ClacounterCfgMmrWr [CLA_NUMBER_OF_COUNTERS],

   input DebugsignalMatchLoMmr_s DebugsignalMatchLoMmr[CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignalMatchHiMmr_s DebugsignalMatchHiMmr[CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignalMaskLoMmr_s  DebugsignalMaskLoMmr [CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignalMaskHiMmr_s  DebugsignalMaskHiMmr [CLA_NUMBER_OF_MASK_MATCH_SET],
   input DebugsignalEdgedetectcfgMmr_s   DebugsignalEdgedetectcfgMmr,
   input DebugsignalTransitionmaskLoMmr_s  DebugsignalTransitionmaskLoMmr,
   input DebugsignalTransitionmaskHiMmr_s  DebugsignalTransitionmaskHiMmr,
   input DebugsignalTransitionfromLoMmr_s  DebugsignalTransitionfromLoMmr,
   input DebugsignalTransitionfromHiMmr_s  DebugsignalTransitionfromHiMmr,
   input DebugsignalTransitiontoLoMmr_s    DebugsignalTransitiontoLoMmr,
   input DebugsignalTransitiontoHiMmr_s    DebugsignalTransitiontoHiMmr,
   input DebugsignalOnescountmaskLoMmr_s   DebugsignalOnescountmaskLoMmr,
   input DebugsignalOnescountmaskHiMmr_s   DebugsignalOnescountmaskHiMmr,
   input DebugsignalOnescountvalueMmr_s  DebugsignalOnescountvalueMmr,
   input DebugsignalChangeLoMmr_s          DebugsignalChangeLoMmr,
   input DebugsignalChangeHiMmr_s          DebugsignalChangeHiMmr,
   input counter_controls        cla_counter_controls[CLA_NUMBER_OF_COUNTERS],
   input ClaCdbglfsrMmr_s ClaCdbglfsrMmr,
   input ClaCdbglfsrmaskMmr_s ClaCdbglfsrmaskMmr,
   output ClaCdbglfsrMmrWr_s ClaCdbglfsrMmrWr,

   input DebugsignalCompareLoMmr_s DebugsignalCompareLoMmr [CLA_NUMBER_OF_ARITHMETIC_COMPARE],
   input DebugsignalCompareHiMmr_s DebugsignalCompareHiMmr [CLA_NUMBER_OF_ARITHMETIC_COMPARE],
   input DebugsignalCompareMaskLoMmr_s DebugsignalCompareMaskLoMmr [CLA_NUMBER_OF_ARITHMETIC_COMPARE],
   input DebugsignalCompareMaskHiMmr_s DebugsignalCompareMaskHiMmr [CLA_NUMBER_OF_ARITHMETIC_COMPARE],

   input logic [XTRIGGER_WIDTH-1:0] xtrigger_in,
   input logic cla_en,
   output logic [CLA_NUMBER_OF_EVENTS-1:0] event_bus
);

assign event_bus[63:49]= 15'b0;
assign event_bus[15:14]= 2'b0;
assign event_bus[0]= 1'b0;
assign event_bus[1]= 1'b1;

logic [CLA_NUMBER_OF_MASK_MATCH_SET-1:0] [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_match;
logic [CLA_NUMBER_OF_MASK_MATCH_SET-1:0] [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_mask;
logic [CLA_NUMBER_OF_ARITHMETIC_COMPARE-1:0] [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_compare;
logic [CLA_NUMBER_OF_ARITHMETIC_COMPARE-1:0] [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_compare_mask;
logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_transition_mask;
logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_transition_from;
logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_transition_to;
logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_ones_count_mask;
logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_change;
logic ext_posedge_d1, ext_posedge_d2, ext_posedge_evt;

generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) ext_posedge_d1_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (i_ext_posedge),
    .out   (ext_posedge_d1)
);
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) ext_posedge_d2_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (ext_posedge_d1),
    .out   (ext_posedge_d2)
);
assign ext_posedge_evt = ~ext_posedge_d2 & ext_posedge_d1;
assign event_bus[CLA_EXT_POSEDGE_EVTBUS_POS] = ext_posedge_evt;

if (DEBUG_SIGNAL_WIDTH == 128) begin: cla_event_gen_128_blk

   for (genvar i=0;i<CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1) begin: cla_event_gen_128_mask_match_blk
     assign debug_signal_match[i] = {DebugsignalMatchHiMmr[i].Value, DebugsignalMatchLoMmr[i].Value};
     assign debug_signal_mask[i] = {DebugsignalMaskHiMmr[i].Value, DebugsignalMaskLoMmr[i].Value};
   end

   for (genvar i=0;i<CLA_NUMBER_OF_ARITHMETIC_COMPARE;i=i+1) begin: cla_event_gen_128_compare_blk
     assign debug_signal_compare[i] = {DebugsignalCompareHiMmr[i].Value, DebugsignalCompareLoMmr[i].Value};
     assign debug_signal_compare_mask[i] = {DebugsignalCompareMaskHiMmr[i].Value, DebugsignalCompareMaskLoMmr[i].Value};
   end

   assign debug_signal_transition_mask = {DebugsignalTransitionmaskHiMmr.Value, DebugsignalTransitionmaskLoMmr.Value};
   assign debug_signal_transition_from = {DebugsignalTransitionfromHiMmr.Value, DebugsignalTransitionfromLoMmr.Value};
   assign debug_signal_transition_to = {DebugsignalTransitiontoHiMmr.Value, DebugsignalTransitiontoLoMmr.Value};
   assign debug_signal_ones_count_mask = {DebugsignalOnescountmaskHiMmr.Value, DebugsignalOnescountmaskLoMmr.Value};
   assign debug_signal_change = {DebugsignalChangeHiMmr.Mask, DebugsignalChangeLoMmr.Mask};

end else begin: cla_event_gen_64_blk
   for (genvar i=0;i<CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1) begin: cla_event_gen_64_mask_match_blk
     assign debug_signal_match[i] = DebugsignalMatchLoMmr[i].Value;
     assign debug_signal_mask[i] = DebugsignalMaskLoMmr[i].Value;
   end

   for (genvar i=0;i<CLA_NUMBER_OF_ARITHMETIC_COMPARE;i=i+1) begin: cla_event_gen_64_compare_blk
     assign debug_signal_compare[i] = DebugsignalCompareLoMmr[i].Value;
     assign debug_signal_compare_mask[i] = DebugsignalCompareMaskLoMmr[i].Value;
   end

   assign debug_signal_transition_from = DebugsignalTransitionfromLoMmr.Value;
   assign debug_signal_transition_to = DebugsignalTransitiontoLoMmr.Value;
   assign debug_signal_transition_mask = DebugsignalTransitionmaskLoMmr.Value;
   assign debug_signal_ones_count_mask = DebugsignalOnescountmaskLoMmr.Value;
   assign debug_signal_change = DebugsignalChangeLoMmr.Mask;
end

genvar i;
generate

  for (i=0;i<LOWER_CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1)
  begin : gen_lower_cla_debug_signals_match
   cla_debug_signals_match #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
   )lower_cla_debug_signals_match_inst (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signal_mask(debug_signal_mask[i]),
                             .debug_signal_match(debug_signal_match[i]),
                             .debug_signals(debug_signals),
                             .debug_signals_positive_match(event_bus[LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)]),
                             .debug_signals_negative_match(event_bus[LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)+1]));
  end

  for (i=0;i<UPPER_CLA_NUMBER_OF_MASK_MATCH_SET;i=i+1)
  begin : gen_upper_cla_debug_signals_match
   cla_debug_signals_match #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
   )upper_cla_debug_signals_match_inst (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signal_mask(debug_signal_mask[i+LOWER_CLA_NUMBER_OF_MASK_MATCH_SET]),
                             .debug_signal_match(debug_signal_match[i+LOWER_CLA_NUMBER_OF_MASK_MATCH_SET]),
                             .debug_signals(debug_signals),
                             .debug_signals_positive_match(event_bus[UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)]),
                             .debug_signals_negative_match(event_bus[UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+i*(NUMBER_OF_EVENTS_PER_MASK_MATCH)+1]));
  end

  cla_lfsr #(
      .LFSR_WIDTH(LFSR_WIDTH)
  )cla_lfsr_inst(
                             .clock(clock),
                             .reset_n(reset_n),
                             .cla_en(cla_en),
                             .lfsr_mmr(ClaCdbglfsrMmr),
                             .lfsr_mask_mmr(ClaCdbglfsrmaskMmr),
                             .lfsr_mmr_wr(ClaCdbglfsrMmrWr),
                             .lfsr_out(event_bus[LFSR_EVTBUS_POS]));

  cla_edge_detect #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
  )cla_edge_detect_inst(
                             .clock(clock),
                             .reset_n(reset_n),
                             .DebugsignalEdgedetectcfgMmr(DebugsignalEdgedetectcfgMmr),
                             .debug_signals(debug_signals),
                             .debug_signal_edge_detect({event_bus[DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS+1],event_bus[DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS]}));

  cla_debug_signals_transition #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
  )cla_debug_signals_transition (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .debug_signal_transition_mask(debug_signal_transition_mask),
                             .debug_signal_transition_from(debug_signal_transition_from),
                             .debug_signal_transition_to(debug_signal_transition_to),
                             .debug_signals_transition_match(event_bus[DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS]));

  assign event_bus[XTRIGGER_EVTBUS_POS]  =xtrigger_in[0];
  assign event_bus[XTRIGGER_EVTBUS_POS+1]=xtrigger_in[1];

  cla_debug_signals_ones_count #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
  )cla_debug_signals_ones_count (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .debug_signal_ones_count_mask(debug_signal_ones_count_mask),
                             .DebugsignalOnescountvalueMmr(DebugsignalOnescountvalueMmr),
                             .debug_signals_ones_count_match(event_bus[DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS]));

  cla_debug_signals_change #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
  )cla_debug_signals_change (
                             .clock(clock),
                             .reset_n(reset_n),
                             .debug_signals(debug_signals),
                             .debug_signal_change_mask(debug_signal_change),
                             .debug_signals_change_match(event_bus[DEBUG_SIGNALS_CHANGE_EVTBUS_POS]));

  for(i=0;i<CLA_NUMBER_OF_COUNTERS;i=i+1)
  begin: gen_cla_counter
   cla_counter cla_counter_inst(
                             .clock(clock),
                             .reset_n(reset_n),
                             .cla_counter_controls(cla_counter_controls[i]),
                             .ClacounterCfgMmr(ClacounterCfgMmr[i]),
                             .target_match   (event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+0+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .target_overflow(event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+1+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .below_target   (event_bus[COUNTER_CONDITIONS_FIRST_EVTBUS_POS+2+i*NUMBER_OF_EVENTS_PER_COUNTER]),
                             .next_WrData(ClacounterCfgMmrWr[i])
   );
  end

   for(i=0; i<CLA_NUMBER_OF_ARITHMETIC_COMPARE;i=i+1) begin: gen_cla_arithmetic_compare
    cla_arithmetic_compare #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
    )cla_arithmetic_compare_inst(
      .clock(clock),
      .reset_n(reset_n),
      .debug_signal_compare(debug_signal_compare[i]),
      .debug_signal_mask(debug_signal_compare_mask[i]),
      .debug_signals(debug_signals),
      .below_compare(event_bus[ARITHMETIC_COMPARE_FIRST_EVTBUS_POS+0+i*(NUMBER_OF_EVENTS_PER_ARITHMETIC_COMPARE)]),
      .below_compare_match(event_bus[ARITHMETIC_COMPARE_FIRST_EVTBUS_POS+1+i*(NUMBER_OF_EVENTS_PER_ARITHMETIC_COMPARE)]),
      .above_compare(event_bus[ARITHMETIC_COMPARE_FIRST_EVTBUS_POS+2+i*(NUMBER_OF_EVENTS_PER_ARITHMETIC_COMPARE)]),
      .above_compare_match(event_bus[ARITHMETIC_COMPARE_FIRST_EVTBUS_POS+3+i*(NUMBER_OF_EVENTS_PER_ARITHMETIC_COMPARE)])
      );
  end
 endgenerate

endmodule
