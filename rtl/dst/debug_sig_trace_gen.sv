// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module debug_sig_trace_gen
import cla_mmr_pkg::*;
import dst_pkg::*;
import dst_mmr_pkg::*;
#(
  parameter DEBUG_SIGNAL_WIDTH = 64,
  localparam DEBUG_BUS_BYTE_ENABLE_WIDTH = DEBUG_SIGNAL_WIDTH/8,
  localparam VLT_HDR_WIDTH = 8 + DEBUG_BUS_BYTE_ENABLE_WIDTH,
  localparam VLT_PACKET_WIDTH = VLT_HDR_WIDTH+DEBUG_SIGNAL_WIDTH

)
(
    input logic clock,
    input logic i_reset_n,
    input logic reset_n_warm_ovrride,
    input logic trace_start, trace_stop, trace_pulse,
    input DstTrdstinstfeaturesMmr_s Trdstinstfeatures,

    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_in,
    input logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable,

    input logic trace_hardware_flush,
    input logic trace_hardware_stop,

    input  DstTrdstcontrolMmr_s      Trdstcontrol,
    input  DstTrdstimplMmr_s         Trdstimpl,
    output DstTrdstcontrolMmrWr_s    TrdstcontrolWr,
    input  timestamp_s				        timestamp,
    input  timestamp_s				        cla_timesync_timestamp,

    output logic flush_mode_enable,
    input  logic flush_mode_exit,
    input  logic packetizer_empty,

    output logic [VLT_PACKET_WIDTH-1:0] vlt_packet,
    output logic [VLT_PACKET_WIDTH/8-1:0] vlt_packet_byte_enable,
    output logic [$clog2(VLT_PACKET_WIDTH/8):0] request_packet_space_in_bytes,

    input logic requested_packet_space_granted,

    input logic stream_full

);

  localparam WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD = $clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH)+1;
  localparam VLT_PACKET_WIDTH_IN_BYTES = VLT_PACKET_WIDTH/8;

  typedef struct packed {
    logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]   byte_enable;
    logic                                     pkt_type;
    logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] source_id;
    logic                                     packet_lost;
    logic [VLT_HDR_TRACE_INFO_WIDTH-1:0]      trace_info;
  } vlt_data_header_s;

    logic [DEBUG_SIGNAL_WIDTH-1:0] xor_debug_bus;
    logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  xor_debug_bus_byte_enable;
    logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] xor_trace_info;
    logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH];
    logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH];
    dst_format_mode_e dst_format_mode;

  assign dst_format_mode = dst_format_mode_e'(Trdstcontrol.Trdstformat);

  logic trace_start_effective;
  logic trdst_enable, trdst_enable_dly, next_flush_mode_enable;
  logic trace_disable_due_to_hw_flush;
  logic trace_stop_from_hw_flush, trace_stop_from_hw_flush_d1, trace_start_after_hw_flush;
  logic sw_tracing_in_progress, tracing_in_progress_flop;

  logic trace_hardware_stop_d1, trace_hardware_flush_d1;
  logic trace_stop_from_hw_overflow, trace_hardware_flush_pulse;

  logic trace_hw_flush_inprogress, trace_hw_flush_inprogress_d1;
  logic trace_stop_from_sw_when_hw_flush_inprogress;
  logic trace_info_xmt_pending;

  logic trace_stop_from_mmr;
  logic trdst_enable_mmr, trdst_enable_mmr_d1;

  timestamp_s vlt_timestamp;

  assign vlt_timestamp = Trdstimpl.Trdsttimestampconfig ? cla_timesync_timestamp : timestamp;

  assign trdst_enable_mmr = Trdstcontrol.Trdstenable;

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_disable_due_to_mmr_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trdst_enable_mmr),
      .out   (trdst_enable_mmr_d1)
  );
  assign trace_stop_from_mmr = ~trdst_enable_mmr & trdst_enable_mmr_d1;

  assign trdst_enable = Trdstcontrol.Trdstenable & ~trace_disable_due_to_hw_flush & ~(~sw_tracing_in_progress & trace_hardware_flush_pulse & ~trace_stop);
  always@ (posedge clock) begin
    if(i_reset_n == 0) begin
        flush_mode_enable <= 1'b0;
        trdst_enable_dly  <= 1'b0;
      end
    else begin
        flush_mode_enable <= next_flush_mode_enable;
        trdst_enable_dly  <= trdst_enable;
      end
  end

  always@(*)
    begin
     if (flush_mode_enable == 1'b0)
        next_flush_mode_enable = (trdst_enable_dly == 1'b1) && (trdst_enable == 1'b0);
     else
        next_flush_mode_enable = (flush_mode_exit == 1'b0) | trace_info_xmt_pending;
    end
  always_comb begin
       TrdstcontrolWr = '0;
       TrdstcontrolWr.TrdstinsttracingWrEn = trace_hardware_stop;
       TrdstcontrolWr.Data.Trdstinsttracing = 1'b0;
       TrdstcontrolWr.TrdstemptyWrEn=1'b1;
       TrdstcontrolWr.Data.Trdstempty = packetizer_empty;
  end

   logic retain_original_input;

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_stop_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_hardware_stop),
      .out   (trace_hardware_stop_d1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_flush_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_hardware_flush),
      .out   (trace_hardware_flush_d1)
  );

  assign trace_stop_from_hw_overflow = trace_hardware_stop & ~trace_hardware_stop_d1;
  assign trace_hardware_flush_pulse = trace_hardware_flush & ~trace_hardware_flush_d1;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_flush_inprogress_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (sw_tracing_in_progress & trace_hardware_flush_pulse),
      .clr   (flush_mode_enable & flush_mode_exit),
      .in    (1'b1),
      .out   (trace_hw_flush_inprogress)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_flush_inprogress_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_hw_flush_inprogress),
      .out   (trace_hw_flush_inprogress_d1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_stop_from_sw_when_flush_inprogress_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trace_hw_flush_inprogress & trace_stop),
      .clr   (trace_hw_flush_inprogress_d1 & ~trace_hw_flush_inprogress),
      .in    (1'b1),
      .out   (trace_stop_from_sw_when_hw_flush_inprogress)
  );

  assign trace_start_after_hw_flush = ~trace_hw_flush_inprogress & trace_hw_flush_inprogress_d1 & ~trace_stop_from_sw_when_hw_flush_inprogress & ~trace_stop;
  assign trace_stop_from_hw_flush = trace_hw_flush_inprogress & ~trace_hw_flush_inprogress_d1;

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_stop_from_hw_flush_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_stop_from_hw_flush),
      .out   (trace_stop_from_hw_flush_d1)
  );

  assign trace_disable_due_to_hw_flush = ~trace_stop_from_hw_flush & trace_stop_from_hw_flush_d1;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) tracing_in_progress_flop_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trace_start_effective),
      .clr   (trace_stop),
      .in    (1'b1),
      .out   (tracing_in_progress_flop)
  );
  assign sw_tracing_in_progress = (tracing_in_progress_flop | trace_start_effective) & ~trace_stop;

  assign trace_start_effective = trace_start & ~trace_hardware_stop;

   xor_compression  #(
    .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
   )xor_compression
    (

    .clock (clock),
    .reset_n (i_reset_n),
    .debug_bus_in (debug_bus_in),
    .trace_start (trace_start_effective | trace_start_after_hw_flush),
    .trace_stop  (trace_stop | trace_stop_from_hw_overflow | trace_stop_from_hw_flush | trace_stop_from_mmr),
    .trace_pulse (trace_pulse),
    .trace_enable(trdst_enable),
    .retain_original_input (retain_original_input),
    .dst_format_mode(dst_format_mode),

    .debug_bus_out (xor_debug_bus),
    .debug_bus_byte_enable (xor_debug_bus_byte_enable),
    .trace_info (xor_trace_info),
    .pyramid_of_byte_enable_sums (pyramid_of_byte_enable_sums),
    .pyramid_of_byte_enable_sums_next (pyramid_of_byte_enable_sums_next)
   );

    vlt_packet_compression #(
      .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH),
      .vlt_data_header_s(vlt_data_header_s)
    )vlt_packet_compression
    (

    .clock (clock),
    .reset_n (i_reset_n),
    .debug_source (Trdstinstfeatures.Trdstsrcid[DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0]),

    .timestamp(vlt_timestamp),
    .Trdstcontrol(Trdstcontrol),

    .xor_debug_bus_in (xor_debug_bus),
    .xor_debug_bus_byte_enable_in (xor_debug_bus_byte_enable),
    .trace_info (xor_trace_info),
    .pyramid_of_byte_enable_sums (pyramid_of_byte_enable_sums),
    .pyramid_of_byte_enable_sums_next (pyramid_of_byte_enable_sums_next),

    .flush_mode_enable(flush_mode_enable),
    .flush_mode_exit(flush_mode_exit),
    .trace_info_xmt_pending(trace_info_xmt_pending),

    .vlt_packet (vlt_packet),
    .vlt_packet_byte_enable (vlt_packet_byte_enable),
    .request_packet_space_in_bytes (request_packet_space_in_bytes),

    .requested_packet_space_granted (requested_packet_space_granted),
    .retain_original_input  (retain_original_input),
    .stream_full (stream_full)

);

endmodule
