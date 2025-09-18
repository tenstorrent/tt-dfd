// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************
// Accumulator Control and Banks instantiation

module dfd_accumulator
import dfd_packetizer_pkg::*;
#(
     parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64, 
               FIFO_WIDTH_IN_BYTES = 16,
               BANK_DATA_WIDTH_IN_BYTES = 32 
) (
    input  logic clock,
    input  logic reset_n,
    
    //Cross Connect
    output logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] write_byte_boundary, 
    input  logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8      -1:0] accumulator_data,         //dfd_accumulator data aligned to write boundary
    input  logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES        -1:0] accumulator_byte_enables, 

    //Interface tp Packet Generator
    input  logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)            :0] request_packet_space_in_bytes_with_frame_support,
    output logic requested_packet_space_granted,
    //Flush Support
    output logic accumulator_empty,
    //Interface to FIFO
    input  logic fifo_space_available,
    input  logic fifo_threshold,
    output logic fifo_push,
    output logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] bank_to_fifo_data_out
);

   localparam NUMBER_OF_BANKS = ACCUMULATOR_DATA_WIDTH_IN_BYTES/BANK_DATA_WIDTH_IN_BYTES;
   localparam NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY = $clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES);

   //Control to Banks. (would have used structs, but data width is an override-able parameter)
   logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] target_write_byte_boundary;
   logic                                               bank_flush[NUMBER_OF_BANKS];
   logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0]              bank_data[NUMBER_OF_BANKS];
   logic [BANK_DATA_WIDTH_IN_BYTES  -1:0]              bank_byte_enable[NUMBER_OF_BANKS];
   bank_status_t                                       bank_status[NUMBER_OF_BANKS];
   logic [$clog2(BANK_DATA_WIDTH_IN_BYTES):0]          bank_free_space_in_bytes[NUMBER_OF_BANKS];
   logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0]              bank_data_out[NUMBER_OF_BANKS];

   logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] next_write_byte_boundary;
   logic [$clog2(NUMBER_OF_BANKS)           -1:0]      bank_pointer, next_bank_pointer;
   logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)  :0] total_free_space_in_bytes;

   genvar i;
   generate
    for(i=0;i<NUMBER_OF_BANKS;i=i+1) begin
      always@(*)
       begin
        bank_data[i]= accumulator_data[(i*BANK_DATA_WIDTH_IN_BYTES*8) +: (BANK_DATA_WIDTH_IN_BYTES*8)];
        bank_byte_enable[i]= accumulator_byte_enables[i*BANK_DATA_WIDTH_IN_BYTES +: BANK_DATA_WIDTH_IN_BYTES];
       end
    end
   endgenerate

   //Instantiate banks.
   generate
    for(i=0;i<NUMBER_OF_BANKS;i=i+1) begin
      dfd_accumulator_bank 
     #(.ACCUMULATOR_DATA_WIDTH_IN_BYTES(ACCUMULATOR_DATA_WIDTH_IN_BYTES),
       .BANK_DATA_WIDTH_IN_BYTES(BANK_DATA_WIDTH_IN_BYTES),
       .WRITE_BYTE_POINTER_RANGE_START(BANK_DATA_WIDTH_IN_BYTES*i),
       .WRITE_BYTE_POINTER_RANGE_END(BANK_DATA_WIDTH_IN_BYTES*(i+1)-1)) accumulator_bank_instance (
       .clock(clock),
       .reset_n(reset_n),
       .target_write_byte_boundary(target_write_byte_boundary),
       .write_byte_boundary(write_byte_boundary),
       .bank_flush(bank_flush[i]),
       .bank_data(bank_data[i]),
       .bank_byte_enable(bank_byte_enable[i]),
       .bank_status(bank_status[i]),
       .bank_free_space_in_bytes(bank_free_space_in_bytes[i]),
       .bank_data_out(bank_data_out[i])
       );  
    end
   endgenerate
  
  // Increment bank pointer when a bank becomes full and flush is issued...
   always@(posedge clock)
      if (!reset_n)
         bank_pointer <= {$clog2(NUMBER_OF_BANKS){1'b0}};
      else 
         bank_pointer <= next_bank_pointer;

  
  // Caculate target write byte boundary.
  // Target byte boundary does not consider "bank free space" since the handshake
  // of sending packet is done AFTER free space is guaranteed.
   always@(posedge clock) 
   begin
    if (!reset_n)
     target_write_byte_boundary <= {$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES){1'b0}};
    else if (requested_packet_space_granted)
     target_write_byte_boundary <= (((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY+1)'(next_write_byte_boundary)+(NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY+1)'(request_packet_space_in_bytes_with_frame_support))
                                     >= (NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY+1)'(ACCUMULATOR_DATA_WIDTH_IN_BYTES))?
                                    (NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'((next_write_byte_boundary+request_packet_space_in_bytes_with_frame_support)-NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY'(ACCUMULATOR_DATA_WIDTH_IN_BYTES)):
                                    (NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(next_write_byte_boundary + request_packet_space_in_bytes_with_frame_support)  ;
   end

  always@(posedge clock)  
  begin
    if (!reset_n)
      write_byte_boundary <= { $clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES) {1'b0}};
    else 
      write_byte_boundary <=  target_write_byte_boundary;
  end

  always@(*)
  begin
    if (requested_packet_space_granted)
    next_write_byte_boundary = target_write_byte_boundary;
   else 
    next_write_byte_boundary = write_byte_boundary;
  end
 
  //Walk through the banks. If bank id = bank pointer,
  //check bank full & fifo not full and if true, issue fifo push with selected bank pointer. 
  int j;
  always @(*) begin
    fifo_push    = 1'b0;
    bank_to_fifo_data_out = {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
    next_bank_pointer = bank_pointer;
    for(j=0;j<NUMBER_OF_BANKS;j=j+1) begin
        bank_flush[j]= 1'b0;
        if (bank_pointer == ($clog2(NUMBER_OF_BANKS))'(j)) begin
          if ((bank_status[j] == BANK_FULL) & (fifo_space_available == 1))
            begin
             bank_flush[j]= 1'b1; 
             fifo_push = 1'b1;
             bank_to_fifo_data_out = bank_data_out[j];
             next_bank_pointer = (bank_pointer == ($clog2(NUMBER_OF_BANKS))'(NUMBER_OF_BANKS-1))? 0 : bank_pointer + 1'b1; 
            end
        end
      end
    end

  //Caclulate free space...
  //Free Space is sum of all free space in each bank
  //If we see a flush, reset the free space to full (the flush is too late signal for the Bank FSM)
  always @(*) begin
    total_free_space_in_bytes = bank_flush[0]?(($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES)):(($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(bank_free_space_in_bytes[0]));
    for(j=1;j<NUMBER_OF_BANKS;j=j+1) begin
         total_free_space_in_bytes = total_free_space_in_bytes + (bank_flush[j]? (($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES)):(($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(bank_free_space_in_bytes[j])));
     end
  end 
  //Accumulator empty is total free space = dfd_accumulator max capacity
  assign accumulator_empty = (total_free_space_in_bytes == (NUMBER_OF_BANKS*($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES)))?1'b1:1'b0;
  //Grant packet space if free space available to accomodate packet (including filler packets).
  assign requested_packet_space_granted = ((request_packet_space_in_bytes_with_frame_support!= '0) && !fifo_threshold && (total_free_space_in_bytes >= ($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(request_packet_space_in_bytes_with_frame_support))) ? 1'b1:1'b0; 


endmodule

