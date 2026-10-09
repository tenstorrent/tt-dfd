// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module vlt_packet_compression
import cla_mmr_pkg::*;
import dst_pkg::*;
import dst_mmr_pkg::*;
#(
  parameter DEBUG_SIGNAL_WIDTH = 64,
  localparam DEBUG_BUS_BYTE_ENABLE_WIDTH = DEBUG_SIGNAL_WIDTH/8,
  localparam VLT_HDR_WIDTH = 8 + DEBUG_BUS_BYTE_ENABLE_WIDTH,
  localparam WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD = $clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH)+1,
  localparam VLT_PACKET_WIDTH = VLT_HDR_WIDTH+DEBUG_SIGNAL_WIDTH,
  localparam VLT_PACKET_WIDTH_IN_BYTES = VLT_PACKET_WIDTH/8,

  parameter type vlt_data_header_s = logic

)
(
    input logic clock,
    input logic reset_n,

    input  DstTrdstcontrolMmr_s      Trdstcontrol,
    input  timestamp_s                timestamp,

    input logic [DEBUG_SIGNAL_WIDTH-1:0] xor_debug_bus_in,
    input logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  xor_debug_bus_byte_enable_in,
    input logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info,
    input logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] debug_source,
    input logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH],
    input logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH],

    output logic [VLT_PACKET_WIDTH-1:0] vlt_packet,
    output logic [VLT_PACKET_WIDTH/8-1:0] vlt_packet_byte_enable,
    input  logic flush_mode_enable,
    input  logic flush_mode_exit,
    output logic trace_info_xmt_pending,
    output logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes,

    input logic requested_packet_space_granted,
    output logic retain_original_input,

    input logic stream_full
);

function automatic logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] get_trace_info;
 input logic [VLT_PACKET_WIDTH-1:0] vlt_packet_in;
 begin
  if (vlt_packet_in[7] == 1'b0)
      get_trace_info = vlt_packet_in[1:0];
  else
      get_trace_info = (vlt_packet_in[1] == 1'b1) ? vlt_packet_in[9:8] : 2'b00;
 end
endfunction

localparam  MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD = DEBUG_SIGNAL_WIDTH/8 ;
localparam  VLT_PAYLOAD_WIDTH = DEBUG_SIGNAL_WIDTH;

logic [VLT_PACKET_WIDTH-1:0] next_vlt_packet;
logic [VLT_PACKET_WIDTH/8-1:0] next_vlt_packet_byte_enable;
logic [VLT_PAYLOAD_WIDTH-1:0] vlt_payload;
logic [VLT_PAYLOAD_WIDTH/8-1:0] vlt_payload_byte_enable;
logic [VLT_PACKET_WIDTH-1:0] retry_vlt_packet;
logic [VLT_PACKET_WIDTH/8-1:0] retry_vlt_packet_byte_enable;
logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0]   retry_vlt_packet_length_in_bytes;
logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0]   incoming_packet_length_in_bytes;
logic retry_data_packet_tx, retry_ts_packet_tx,retry_trace_info_tx;
vlt_data_header_s vlt_data_header;
vlt_support_pkt_header0_s vlt_flush_header;
vlt_support_pkt_header vlt_ts_header;
vlt_support_pkt_header vlt_tinfo_header;
logic trace_in_progress_flop, trace_in_progress;
logic packet_lost;
logic next_packet_lost;
logic trace_start_in_trace_info,trace_stop_in_trace_info;
logic trace_start_in_xmitted_vlt_packet,trace_stop_in_xmitted_vlt_packet;
logic trace_start_in_next_xmitted_vlt_packet,trace_stop_in_next_xmitted_vlt_packet;
logic trace_start_to_xmt,trace_stop_to_xmt;
logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info_to_xmt,next_vlt_packet_trace_info;
logic trace_start_xmt_pending,trace_stop_xmt_pending;
logic incoming_packet;
logic trace_flush;
logic ts_packet_enable;
logic stream_full_d1, stream_full_posedge, stream_full_till_next_input_packet, stream_full_till_next_input_packet_next;

logic [PERIODIC_SYNC_CTR_MAX_WIDTH - 1 : 0] periodic_sync_counter, next_periodic_sync_counter, periodic_sync_max_count;
logic periodic_sync_count_match, next_periodic_sync_count_match, periodic_sync_count_clr, periodic_sync_count_en;
logic dstStarted;

assign dstStarted = (Trdstcontrol.Trdstenable);

assign periodic_sync_max_count = PERIODIC_SYNC_CTR_MAX_WIDTH'({1 << (Trdstcontrol.Trdstsyncmax + 4)});

assign periodic_sync_count_en = (Trdstcontrol.Trdstsyncmode != COUNT_OFF_DST_MODE) & trace_in_progress;

assign next_periodic_sync_count_match = (next_periodic_sync_counter == (periodic_sync_max_count - PERIODIC_SYNC_CTR_MAX_WIDTH'(1)));
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) periodic_sync_count_match_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (next_periodic_sync_count_match),
    .out   (periodic_sync_count_match)
);

assign periodic_sync_count_clr = periodic_sync_count_match | !trace_in_progress;

assign next_periodic_sync_counter = periodic_sync_counter + 1'b1;
generic_dff_clr #(
    .WIDTH       ($bits(logic [PERIODIC_SYNC_CTR_MAX_WIDTH-1:0])),
    .RESET_VALUE ('0)
) periodic_sync_count_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    (periodic_sync_count_en),
    .clr   (periodic_sync_count_clr),
    .in    (next_periodic_sync_counter),
    .out   (periodic_sync_counter)
);

assign ts_packet_enable = (Trdstcontrol.Trdstsyncmode == CYCLE_COUNT_DST_MODE) && periodic_sync_count_match & trace_in_progress & Trdstcontrol.Trdstenable;

assign retain_original_input = (!requested_packet_space_granted | ts_packet_enable | retry_ts_packet_tx | stream_full_till_next_input_packet | trace_flush) & (xor_debug_bus_byte_enable_in != '0);

logic [7:0] xor_debug_bus_bytes [MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD];
always @(*) begin
  for (int i = 0; i < MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD; i++) begin
    xor_debug_bus_bytes[i] = xor_debug_bus_in[(i*8) +: 8];
  end
end

always @(*) begin
  if (xor_debug_bus_byte_enable_in != 0)
    incoming_packet = 1'b1;
  else
    incoming_packet = 1'b0;
end

generic_dff_clr #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) stream_full_till_next_input_packet_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    (trace_in_progress),
    .clr   (trace_info == 2'h2),
    .in    (stream_full_till_next_input_packet_next),
    .out   (stream_full_till_next_input_packet)
);
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) stream_full_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    ('1),
    .in    (stream_full),
    .out   (stream_full_d1)
);

generic_dff_clr #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) trace_in_progress_ff (
    .clk   (clock),
    .rst_n (reset_n),
    .en    (trace_info == 2'h1),
    .clr   (trace_info == 2'h2),
    .in    (1'b1),
    .out   (trace_in_progress_flop)
);

assign trace_in_progress = ((trace_info == 2'h1) | trace_in_progress_flop) & ~(trace_info == 2'h2);

assign stream_full_posedge = stream_full & !stream_full_d1;

always_comb
begin
  stream_full_till_next_input_packet_next = stream_full_till_next_input_packet;
  if(stream_full_till_next_input_packet && (xor_debug_bus_byte_enable_in != '0))
  begin
    stream_full_till_next_input_packet_next = 1'b0;
  end
  else if(stream_full_posedge)
  begin
    stream_full_till_next_input_packet_next = 1'b1;
  end
end

logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0] mux_select_for_vlt_payload_calculation [0:MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-1];
always @(*) begin
  mux_select_for_vlt_payload_calculation[0] = xor_debug_bus_byte_enable_in;
  for (int i = 1; i < MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD ; i=i+1) begin
    mux_select_for_vlt_payload_calculation[i] = {DEBUG_BUS_BYTE_ENABLE_WIDTH{1'b0}};
    for (int j = i; j < DEBUG_BUS_BYTE_ENABLE_WIDTH ; j=j+1)begin
     mux_select_for_vlt_payload_calculation[i][j-i] = ((pyramid_of_byte_enable_sums[j-1] &
                                                     {WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD{xor_debug_bus_byte_enable_in[j]}})
                                                     == (($clog2(MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD)+1))'(i)) ;
    end
  end
end

generate
    for(genvar i=0;i<MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD;i=i+1) begin : gen_vlt_payload
       dst_priority_mux
       #(.LEVELS(MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-i)) vlt_instance (
         .inputs(xor_debug_bus_bytes[i:MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-1]),
         .select(mux_select_for_vlt_payload_calculation[i][DEBUG_BUS_BYTE_ENABLE_WIDTH-1-i:0]),
         .mux_out(vlt_payload[(i*8) +: 8]));
    end
endgenerate

always@(*) begin
   vlt_payload_byte_enable ={VLT_PAYLOAD_WIDTH/8{1'b0}};
   for(int i=0;i<VLT_PAYLOAD_WIDTH/8+1;i=i+1) begin
      if(pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH-1] == (WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD)'(i)) begin
        vlt_payload_byte_enable = (VLT_PAYLOAD_WIDTH/8)'(2**i-1);
      end
   end
end

assign vlt_data_header.pkt_type = 1'b0;
assign vlt_data_header.source_id = debug_source;
assign vlt_data_header.packet_lost = packet_lost | (retry_ts_packet_tx & (trace_info == 2'h2));
assign vlt_data_header.trace_info = trace_info_to_xmt;
assign vlt_data_header.byte_enable = xor_debug_bus_byte_enable_in;

assign vlt_flush_header.pkt_type = 1'b1;
assign vlt_flush_header.source_id = debug_source;
assign vlt_flush_header.packet_lost = packet_lost;
assign vlt_flush_header.hdr_extended = 1'b0;
assign vlt_flush_header.null_packet  = 1'b1;

assign vlt_ts_header.header0.pkt_type = 1'b1;
assign vlt_ts_header.header0.source_id = debug_source;
assign vlt_ts_header.header0.packet_lost = packet_lost;
assign vlt_ts_header.header0.hdr_extended = 1'b1;
assign vlt_ts_header.header0.null_packet  = 1'b0;
assign vlt_ts_header.header1.support_form = 4'b0;
assign vlt_ts_header.header1.support_info = {2'b00, trace_info_to_xmt};

assign vlt_tinfo_header.header0.pkt_type = 1'b1;
assign vlt_tinfo_header.header0.source_id = debug_source;
assign vlt_tinfo_header.header0.packet_lost = packet_lost;
assign vlt_tinfo_header.header0.hdr_extended = 1'b1;
assign vlt_tinfo_header.header0.null_packet  = 1'b0;
assign vlt_tinfo_header.header1.support_form = 4'b1;
assign vlt_tinfo_header.header1.support_info = {2'b00, trace_info_to_xmt};

assign trace_start_in_trace_info = trace_info[TRACE_INFO_TRACE_START_POS];
assign trace_stop_in_trace_info  = trace_info[TRACE_INFO_TRACE_STOP_POS];
assign next_vlt_packet_trace_info = get_trace_info(next_vlt_packet);
assign trace_start_in_next_xmitted_vlt_packet = next_vlt_packet_trace_info[TRACE_INFO_TRACE_START_POS] && requested_packet_space_granted;
assign trace_stop_in_next_xmitted_vlt_packet  = next_vlt_packet_trace_info[TRACE_INFO_TRACE_STOP_POS]  && requested_packet_space_granted;

always@(posedge clock)
  if (!reset_n)
    trace_start_xmt_pending <= 1'b0;
  else if ( trace_stop_to_xmt & ~trace_start_to_xmt)
    trace_start_xmt_pending <= 1'b0;
  else if (trace_start_to_xmt & ~trace_start_in_next_xmitted_vlt_packet)
    trace_start_xmt_pending <= 1'b1;
  else if (trace_start_xmt_pending ==  trace_start_in_next_xmitted_vlt_packet)
    trace_start_xmt_pending <= 1'b0;

always@(posedge clock)
  if (!reset_n)
    trace_stop_xmt_pending <= 1'b0;
  else if ( trace_start_to_xmt & ~trace_stop_to_xmt )
    trace_stop_xmt_pending <= 1'b0;
  else if (trace_stop_to_xmt & ~trace_stop_in_next_xmitted_vlt_packet)
    trace_stop_xmt_pending <= 1'b1;
  else if (trace_stop_xmt_pending == trace_stop_in_next_xmitted_vlt_packet)
    trace_stop_xmt_pending <= 1'b0;

assign trace_start_to_xmt = trace_start_in_trace_info | trace_start_xmt_pending;
assign trace_stop_to_xmt  = trace_stop_in_trace_info  | trace_stop_xmt_pending;
assign trace_info_to_xmt  = {trace_stop_to_xmt,trace_start_to_xmt} ;
assign trace_info_xmt_pending = (trace_start_xmt_pending | trace_stop_xmt_pending);

assign trace_flush =  flush_mode_enable && (flush_mode_exit == 1'b0) && ~trace_info_xmt_pending;

always@(posedge clock)
  if (!reset_n)
  begin
    retry_vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    retry_vlt_packet_length_in_bytes <= {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};
  end
  else if (ts_packet_enable)
  begin
    retry_vlt_packet                 <= VLT_PACKET_WIDTH'({timestamp,vlt_ts_header});
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b1}};
    retry_vlt_packet_length_in_bytes <= ($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1)'(NUMBER_OF_BYTES_IN_TS_PACKET);
  end
  else if (retry_ts_packet_tx && (trace_info == 2'h2))
  begin
    retry_vlt_packet                 <= VLT_PACKET_WIDTH'({timestamp,vlt_ts_header});
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b1}};
    retry_vlt_packet_length_in_bytes <= ($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1)'(NUMBER_OF_BYTES_IN_TS_PACKET);
  end
  else if (incoming_packet && !retry_ts_packet_tx)
  begin
    retry_vlt_packet                 <= {vlt_payload,vlt_data_header};
    retry_vlt_packet_byte_enable     <= {vlt_payload_byte_enable,{VLT_HDR_WIDTH/8{1'b1}} };
    retry_vlt_packet_length_in_bytes <= request_packet_space_in_bytes;
  end

  else if (!retry_data_packet_tx && !retry_ts_packet_tx)
  begin
    retry_vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    retry_vlt_packet_length_in_bytes <= {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};
  end

always@(posedge clock)
  if (!reset_n)
  begin
     retry_data_packet_tx  <= 1'b0;
     retry_ts_packet_tx    <= 1'b0;
  end
  else if (flush_mode_enable)
  begin
     retry_data_packet_tx  <= 1'b0;
     retry_ts_packet_tx    <= 1'b0;
  end

  else if ((ts_packet_enable || retry_ts_packet_tx) && (!requested_packet_space_granted))
  begin
    retry_data_packet_tx  <= 1'b0;
    retry_ts_packet_tx    <= 1'b1;
  end

  else if ((ts_packet_enable || retry_ts_packet_tx) && requested_packet_space_granted)
  begin

      retry_data_packet_tx  <= 1'b0;
      retry_ts_packet_tx    <= 1'b0;
  end

  else if (incoming_packet && (!requested_packet_space_granted))
  begin
      retry_data_packet_tx  <= 1'b1;
      retry_ts_packet_tx    <= 1'b0;
  end
  else if (retry_data_packet_tx && requested_packet_space_granted)
  begin
      retry_data_packet_tx  <= 1'b0;
      retry_ts_packet_tx    <= 1'b0;
  end

always@(posedge clock)
  if (!reset_n)
   begin
    vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    packet_lost                <= 1'b0;
   end
  else
   begin
    vlt_packet                 <= next_vlt_packet              ;
    vlt_packet_byte_enable     <= next_vlt_packet_byte_enable  ;
    packet_lost                <= next_packet_lost             ;
   end

always@(*)

  if (trace_flush)
  begin
    next_vlt_packet                 =  {VLT_PACKET_WIDTH_IN_BYTES{vlt_flush_header}};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {VLT_PACKET_WIDTH_IN_BYTES{1'b1}} : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted | ts_packet_enable | incoming_packet;
  end

  else if (ts_packet_enable)
  begin
    next_vlt_packet                 = VLT_PACKET_WIDTH'({timestamp,vlt_ts_header});
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {VLT_PACKET_WIDTH_IN_BYTES{1'b1}}: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = (incoming_packet | retry_data_packet_tx);
  end

  else if (retry_ts_packet_tx)
  begin
    next_vlt_packet                 = retry_vlt_packet;
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? retry_vlt_packet_byte_enable: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = (incoming_packet | retry_data_packet_tx | retry_ts_packet_tx);
  end

  else if (incoming_packet)
  begin
    next_vlt_packet                 = {vlt_payload,vlt_data_header};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {vlt_payload_byte_enable,{VLT_HDR_WIDTH/8{1'b1}} }: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted;
  end

  else if (retry_data_packet_tx)
  begin
    next_vlt_packet                 = retry_vlt_packet;
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? retry_vlt_packet_byte_enable : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted;
  end

  else if (trace_info_xmt_pending)
  begin
    next_vlt_packet                 = (VLT_PACKET_WIDTH)'({{DEBUG_SIGNAL_WIDTH{1'b0}},vlt_tinfo_header});
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {{VLT_PACKET_WIDTH_IN_BYTES-NUMBER_OF_BYTES_IN_TINFO_PACKET{1'b0}},{NUMBER_OF_BYTES_IN_TINFO_PACKET{1'b1}}} : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = packet_lost;
  end
  else
  begin
    next_vlt_packet                 = {VLT_PACKET_WIDTH{1'b0}};
    next_vlt_packet_byte_enable     = {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = packet_lost;
  end

always@(posedge clock)
  if (!reset_n)
    incoming_packet_length_in_bytes <= '0;
  else
    incoming_packet_length_in_bytes <= pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH-1] + WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD'(VLT_HDR_WIDTH/8);

always@(*)
   if (trace_flush)
      request_packet_space_in_bytes = ($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1)'(VLT_PACKET_WIDTH_IN_BYTES);
   else if (ts_packet_enable)
      request_packet_space_in_bytes = NUMBER_OF_BYTES_IN_TS_PACKET;
   else if (retry_ts_packet_tx)
      request_packet_space_in_bytes = retry_vlt_packet_length_in_bytes;
   else if (vlt_payload_byte_enable != 0)
      request_packet_space_in_bytes = incoming_packet_length_in_bytes;
   else if (retry_data_packet_tx)
      request_packet_space_in_bytes = retry_vlt_packet_length_in_bytes;
   else if (trace_info_xmt_pending)
      request_packet_space_in_bytes = NUMBER_OF_BYTES_IN_TINFO_PACKET;
   else
      request_packet_space_in_bytes = {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};

endmodule
