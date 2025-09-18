// Packetizer : Cross Connect + Accumlator (+ Banks) + FIFO
module dfd_packetizer
import dfd_cr_csr_pkg::*;
import dfd_packetizer_pkg::*;
#(
    parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64,
              PACKET_WIDTH_IN_BYTES = 10,
              FIFO_WIDTH_IN_BYTES = 16,
              FIFO_ENTRIES = 8,
              BANK_DATA_WIDTH_IN_BYTES = 32 

) (
    input  logic clock,
    input  logic reset_n,

    //Interface to packet generator
    input logic [PACKET_WIDTH_IN_BYTES*8-1:0] data_in,
    input logic [PACKET_WIDTH_IN_BYTES-1  :0] data_byte_be_in, 
    input  logic [$clog2(PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes,
    output logic requested_packet_space_granted,

    //FIFO o/p -> Trace Network Interface block
    output logic tnif_req_out,
    input  logic tnif_data_pull_data_in,
    output logic [FIFO_WIDTH_IN_BYTES*8-1:0] tnif_data_out,

    //Flush
    input  logic flush_mode_enable,   //Transition to flush mode. start last_packet_in_frame tracking. Generator to send flush packets. 
    output logic flush_mode_exit,     //Exiting flush mode, last_packet_in_frame sent.
    output logic packetizer_empty,    //Packetizer Empty
    //Frame Information
    input frame_info_s    frame_info,

    // stream_full signal to dst
    output logic stream_full
);

    logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] write_byte_boundary;
    logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8      -1:0] accumulator_data;         //dfd_accumulator data aligned to write boundary
    logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES        -1:0] accumulator_byte_enables; 
    logic requested_packet_space_granted_from_accumulator;

    //Fifo Connectivity 
    logic [$clog2(FIFO_ENTRIES):0] fifo_entry_count; 
    logic fifo_space_available,fifo_threshold;
    logic fifo_empty,accumulator_empty;
    logic fifo_pop, fifo_push;
    logic frame_fill;
    logic [FIFO_WIDTH_IN_BYTES*8-1:0] fifo_write_data [1:0]; 
    logic [FIFO_WIDTH_IN_BYTES*8-1:0] fifo_read_data;

    //Frame Filler Connectivity
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] frame_fill_packet_be;
    
    logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)  :0]   request_packet_space_in_bytes_with_frame_support;    
    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] bytes_in_current_frame;
    
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] data_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] data_byte_be_expanded;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] cross_connect_data_in;
    logic [BANK_DATA_WIDTH_IN_BYTES-1  :0] cross_connect_data_byte_be_in;

    //Overflow Condition
    logic frame_overflow_with_new_request;

    logic stream_full_next;
    logic [$clog2(MAX_STREAM_DEPTH):0] frames_in_stream, frames_in_stream_next;
    logic [$clog2(MAX_STREAM_DEPTH):0] stream_depth;

assign stream_depth = frame_info.stream_depth;

// Allow Grant only of no overflow 
assign requested_packet_space_granted = (frame_overflow_with_new_request == 1'b0) && requested_packet_space_granted_from_accumulator;

dfd_frame_filler #(
    .ACCUMULATOR_DATA_WIDTH_IN_BYTES (ACCUMULATOR_DATA_WIDTH_IN_BYTES),
    .PACKET_WIDTH_IN_BYTES (PACKET_WIDTH_IN_BYTES),
    .BANK_DATA_WIDTH_IN_BYTES (BANK_DATA_WIDTH_IN_BYTES)
) frame_filler_instance ( 
    .clock (clock),
    .reset_n (reset_n),

    //Interface to packet generator
    .request_packet_space_in_bytes(request_packet_space_in_bytes),
    .requested_packet_space_granted_from_accumulator (requested_packet_space_granted_from_accumulator),

    //Overflow related..
    .frame_overflow_with_new_request (frame_overflow_with_new_request),

    //Flush
    .flush_mode_enable (flush_mode_enable), 
    .flush_mode_exit  (), 
    //Frame Information
    .frame_info (frame_info),

    .frame_fill_packet(frame_fill_packet),
    .frame_fill_packet_bit_enable(frame_fill_packet_bit_enable),
    .frame_fill_packet_be(frame_fill_packet_be),
    .frame_fill(frame_fill),
    .request_packet_space_in_bytes_with_frame_support(request_packet_space_in_bytes_with_frame_support),    
    .bytes_in_current_frame(bytes_in_current_frame)

);

// Frame counting logic
// This assumes that the second last frame has been filled and there will be 2
// packets stored in the last frame by the time an uncompressed packet gets
// stored in the frame. 
// Pessimistically, if those two already stored packets in frame are of max packet
// length, then it should be ensured that the total frame size doesn't go below the
// size of 2 packets, to avoid receiving another frame full signal before sending
// the uncompressed packet. Currently, with packet size set to 10 bytes and frame size
// set to 512 bytes, it is acceptable.
generic_dff #(.WIDTH($clog2(MAX_STREAM_DEPTH)+1)) frames_in_stream_ff (.out(frames_in_stream), .in(frames_in_stream_next), .en(frame_info.stream_count_enable), .clk(clock), .rst_n(reset_n));
generic_dff #(.WIDTH(1)) stream_full_ff (.out(stream_full), .in(stream_full_next), .en(1'b1), .clk(clock), .rst_n(reset_n));

// Whenever a frame_full signal from dfd_packetizer is received, the frames_in_stream value
// is updated. If the number of frames filled is equal to the second last stream entry idx
// before wrap happens, stream_full is asserted high. This serves to notify that this
// is the last frame before the wrap and is used to generate a pulse, which is used 
// to trigger retain_original_input to disable compression
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

//Append frame fill packet to cross-connect..
logic requested_packet_space_granted_dly;
always @(posedge clock)
 if (!reset_n)
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

//Frame Fill Mux
always @(*) begin
     cross_connect_data_in =  (frame_fill_packet & frame_fill_packet_bit_enable)| ((BANK_DATA_WIDTH_IN_BYTES*8)'(data_in) & data_bit_enable);
     cross_connect_data_byte_be_in = (frame_fill)? (frame_fill_packet_be | data_byte_be_expanded): data_byte_be_expanded;
end

dfd_cross_connect #(
    .ACCUMULATOR_DATA_WIDTH_IN_BYTES(ACCUMULATOR_DATA_WIDTH_IN_BYTES),
    .BANK_DATA_WIDTH_IN_BYTES(BANK_DATA_WIDTH_IN_BYTES)
) cross_connect_instance (
    .cross_connect_data_in(cross_connect_data_in),
    .cross_connect_data_byte_be_in(cross_connect_data_byte_be_in), 
    .write_byte_boundary(write_byte_boundary),
    .accumulator_data(accumulator_data),
    .accumulator_byte_enables(accumulator_byte_enables) 
); 

dfd_accumulator
#(
     .ACCUMULATOR_DATA_WIDTH_IN_BYTES(ACCUMULATOR_DATA_WIDTH_IN_BYTES),
     .FIFO_WIDTH_IN_BYTES(FIFO_WIDTH_IN_BYTES),
     .BANK_DATA_WIDTH_IN_BYTES(BANK_DATA_WIDTH_IN_BYTES)
) accumulator_instance (
    .clock  (clock),
    .reset_n(reset_n),
    
    //Cross Connect
    .write_byte_boundary(write_byte_boundary),
    .accumulator_data(accumulator_data),
    .accumulator_byte_enables(accumulator_byte_enables), 

    //Interface tp Packet Generator
    .request_packet_space_in_bytes_with_frame_support(request_packet_space_in_bytes_with_frame_support),
    .requested_packet_space_granted (requested_packet_space_granted_from_accumulator),
    //Flush Support
    .accumulator_empty(accumulator_empty),
    //Interface to FIFO
    .fifo_space_available(fifo_space_available), 
    .fifo_threshold(fifo_threshold),
    .fifo_push(fifo_push), 
    .bank_to_fifo_data_out({fifo_write_data[1],fifo_write_data[0]})
);    


//FIFO Connectivity and instantiaion. For now, go with single read and write ports.
//Additional logic required in Acculuator (for multiple writes) and in this module for multiple reads. 
assign fifo_empty = (fifo_entry_count == 0)?1'b1:1'b0;
assign fifo_space_available = (fifo_entry_count <= ($clog2(FIFO_ENTRIES)+1)'(FIFO_ENTRIES-2));
assign fifo_threshold = (fifo_entry_count>= ($clog2(FIFO_ENTRIES)+1)'(FIFO_ENTRIES-4)); //Provide grant only if there's space for atleast 2 banks of data in FIFO. (2 banks = 4 entries in FIFO)
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
     .i_reset_n(reset_n)
   );

//Drive flush done if both fifo and dfd_accumulator is empty,
assign packetizer_empty = accumulator_empty && fifo_empty && (fifo_push == 1'b0);
assign flush_mode_exit = frame_fill && (fifo_push == 1'b0); 

endmodule

