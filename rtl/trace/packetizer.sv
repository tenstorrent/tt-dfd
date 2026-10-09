// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module packetizer
import cla_mmr_pkg::*;
import packetizer_pkg::*;
#(
    parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64,
              PACKET_WIDTH_IN_BYTES = 10,
              FIFO_WIDTH_IN_BYTES = 16,
              FIFO_ENTRIES = 8,
              BANK_DATA_WIDTH_IN_BYTES = 32

) (
    input  logic clock,
    input  logic i_reset_n,
    input  logic reset_n_warm_ovrride,

    input logic [PACKET_WIDTH_IN_BYTES*8-1:0] data_in,
    input logic [PACKET_WIDTH_IN_BYTES-1  :0] data_byte_be_in,
    input  logic [$clog2(PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes,
    output logic requested_packet_space_granted,

    output logic tnif_req_out,
    input  logic tnif_data_pull_data_in,
    output logic [FIFO_WIDTH_IN_BYTES*8-1:0] tnif_data_out,

    input  logic flush_mode_enable,
    output logic flush_mode_exit,
    output logic packetizer_empty,

    input frame_info_s    frame_info,

    output logic stream_full
);

    logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] write_byte_boundary;
    logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8      -1:0] accumulator_data;
    logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES        -1:0] accumulator_byte_enables;
    logic requested_packet_space_granted_from_accumulator;

    logic [$clog2(FIFO_ENTRIES):0] fifo_entry_count;
    logic fifo_space_available,fifo_threshold;
    logic fifo_empty,accumulator_empty;
    logic fifo_pop, fifo_push;
    logic frame_fill;
    logic [FIFO_WIDTH_IN_BYTES*8-1:0] fifo_write_data [1:0];
    logic [FIFO_WIDTH_IN_BYTES*8-1:0] fifo_read_data;

    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] frame_fill_packet_be;

    logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)  :0]   request_packet_space_in_bytes_with_frame_support;
    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] bytes_in_current_frame;

    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] data_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] data_byte_be_expanded;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] cross_connect_data_in;
    logic [BANK_DATA_WIDTH_IN_BYTES-1  :0] cross_connect_data_byte_be_in;

    logic frame_overflow_with_new_request;

    logic stream_full_next;
    logic [$clog2(MAX_STREAM_DEPTH):0] frames_in_stream, frames_in_stream_next;
    logic [$clog2(MAX_STREAM_DEPTH):0] stream_depth;

assign stream_depth = frame_info.stream_depth;

assign requested_packet_space_granted = (frame_overflow_with_new_request == 1'b0) && requested_packet_space_granted_from_accumulator;

frame_filler #(
    .ACCUMULATOR_DATA_WIDTH_IN_BYTES (ACCUMULATOR_DATA_WIDTH_IN_BYTES),
    .PACKET_WIDTH_IN_BYTES (PACKET_WIDTH_IN_BYTES),
    .BANK_DATA_WIDTH_IN_BYTES (BANK_DATA_WIDTH_IN_BYTES)
) frame_filler_instance (
    .clock (clock),
    .reset_n (i_reset_n),

    .request_packet_space_in_bytes(request_packet_space_in_bytes),
    .requested_packet_space_granted_from_accumulator (requested_packet_space_granted_from_accumulator),

    .frame_overflow_with_new_request (frame_overflow_with_new_request),

    .flush_mode_enable (flush_mode_enable),
    .flush_mode_exit  (),

    .frame_info (frame_info),

    .frame_fill_packet(frame_fill_packet),
    .frame_fill_packet_bit_enable(frame_fill_packet_bit_enable),
    .frame_fill_packet_be(frame_fill_packet_be),
    .frame_fill(frame_fill),
    .request_packet_space_in_bytes_with_frame_support(request_packet_space_in_bytes_with_frame_support),
    .bytes_in_current_frame(bytes_in_current_frame)

);

generic_dff #(
    .WIDTH       ($bits(logic [$clog2(MAX_STREAM_DEPTH)+1-1:0])),
    .RESET_VALUE ('0)
) frames_in_stream_ff (
    .clk   (clock),
    .rst_n (i_reset_n),
    .en    (frame_info.stream_count_enable),
    .in    (frames_in_stream_next),
    .out   (frames_in_stream)
);
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) stream_full_ff (
    .clk   (clock),
    .rst_n (i_reset_n),
    .en    ('1),
    .in    (stream_full_next),
    .out   (stream_full)
);

always_comb
begin
  frames_in_stream_next = frames_in_stream;
  stream_full_next = stream_full;
  if(frame_fill)
  begin
    if(frames_in_stream < (stream_depth - ($clog2(MAX_STREAM_DEPTH)+1)'(1'b1)))
    begin
      frames_in_stream_next = frames_in_stream + 1'b1;
      stream_full_next = (frames_in_stream == (stream_depth - ($clog2(MAX_STREAM_DEPTH)+1)'(2'b10)));
    end
    else if(frames_in_stream == (stream_depth - ($clog2(MAX_STREAM_DEPTH)+1)'(1'b1)))
    begin
      frames_in_stream_next = '0;
      stream_full_next = 1'b0;
    end
  end
end

logic requested_packet_space_granted_dly;
always @(posedge clock)
 if (!i_reset_n)
   requested_packet_space_granted_dly <= 1'b0;
 else
   requested_packet_space_granted_dly <= requested_packet_space_granted;
assign  data_byte_be_expanded = ({{(BANK_DATA_WIDTH_IN_BYTES-PACKET_WIDTH_IN_BYTES){1'b0}},data_byte_be_in} & {BANK_DATA_WIDTH_IN_BYTES{requested_packet_space_granted_dly}});

integer i;
always@(*)
begin
  data_bit_enable = {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
  for (i=0;i<BANK_DATA_WIDTH_IN_BYTES;i=i+1)
    data_bit_enable[(i*8)+:8] = {8{data_byte_be_expanded[i]}};
end

always @(*) begin
     cross_connect_data_in =  (frame_fill_packet & frame_fill_packet_bit_enable)| ((BANK_DATA_WIDTH_IN_BYTES*8)'(data_in) & data_bit_enable);
     cross_connect_data_byte_be_in = (frame_fill)? (frame_fill_packet_be | data_byte_be_expanded): data_byte_be_expanded;
end

cross_connect #(
    .ACCUMULATOR_DATA_WIDTH_IN_BYTES(ACCUMULATOR_DATA_WIDTH_IN_BYTES),
    .BANK_DATA_WIDTH_IN_BYTES(BANK_DATA_WIDTH_IN_BYTES)
) cross_connect_instance (
    .cross_connect_data_in(cross_connect_data_in),
    .cross_connect_data_byte_be_in(cross_connect_data_byte_be_in),
    .write_byte_boundary(write_byte_boundary),
    .accumulator_data(accumulator_data),
    .accumulator_byte_enables(accumulator_byte_enables)
);

accumulator
#(
     .ACCUMULATOR_DATA_WIDTH_IN_BYTES(ACCUMULATOR_DATA_WIDTH_IN_BYTES),
     .FIFO_WIDTH_IN_BYTES(FIFO_WIDTH_IN_BYTES),
     .BANK_DATA_WIDTH_IN_BYTES(BANK_DATA_WIDTH_IN_BYTES)
) accumulator_instance (
    .clock  (clock),
    .reset_n(i_reset_n),

    .write_byte_boundary(write_byte_boundary),
    .accumulator_data(accumulator_data),
    .accumulator_byte_enables(accumulator_byte_enables),

    .request_packet_space_in_bytes_with_frame_support(request_packet_space_in_bytes_with_frame_support),
    .requested_packet_space_granted (requested_packet_space_granted_from_accumulator),

    .accumulator_empty(accumulator_empty),

    .fifo_space_available(fifo_space_available),
    .fifo_threshold(fifo_threshold),
    .fifo_push(fifo_push),
    .bank_to_fifo_data_out({fifo_write_data[1],fifo_write_data[0]})
);

assign fifo_empty = (fifo_entry_count == 0)?1'b1:1'b0;
assign fifo_space_available = (fifo_entry_count <= ($clog2(FIFO_ENTRIES)+1)'(FIFO_ENTRIES-2));
assign fifo_threshold = (fifo_entry_count>= ($clog2(FIFO_ENTRIES)+1)'(FIFO_ENTRIES-4));
assign tnif_req_out = (fifo_entry_count > ($clog2(FIFO_ENTRIES)+1)'(0));
assign fifo_pop = tnif_data_pull_data_in;
assign tnif_data_out = fifo_read_data;

generic_fifoMN
#(
    .DATA_WIDTH(FIFO_WIDTH_IN_BYTES*8),
    .ENTRIES(FIFO_ENTRIES),
    .NUM_WR(2),
    .NUM_RD(1)
) fifo_instance (
     .o_cnt(fifo_entry_count),
     .o_data(fifo_read_data),
     .o_broadside_data(),
     .o_rdptr(),
     .o_wrptr(),
     .i_data({fifo_write_data[1],fifo_write_data[0]}),
     .i_psh({2{fifo_push}}),
     .i_pop(fifo_pop),
     .i_clear({FIFO_ENTRIES{1'b0}}),
     .i_clk(clock),
     .i_reset_n(i_reset_n)
   );

assign packetizer_empty = accumulator_empty && fifo_empty && (fifo_push == 1'b0);
assign flush_mode_exit = frame_fill && (fifo_push == 1'b0);

endmodule
