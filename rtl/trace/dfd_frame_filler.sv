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
// Frmae Filler : Generate Request adjusted to frame support, generate frame_fill data/byte-enables.
module dfd_frame_filler
import dfd_cr_csr_pkg::*;
import dfd_packetizer_pkg::*;
#(
    parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64,
              PACKET_WIDTH_IN_BYTES = 10,
              BANK_DATA_WIDTH_IN_BYTES = 32 
) (
    input  logic clock,
    input  logic reset_n,

    //Interface to packet generator
    input logic [$clog2(PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes,
    input logic requested_packet_space_granted_from_accumulator,

    //Overflow Condition
    output logic frame_overflow_with_new_request,

    //Flush
    input  logic flush_mode_enable,   //Transition to flush mode. start last_packet_in_frame tracking. Generator to send flush packets. 
    output logic flush_mode_exit,     //Exiting flush mode, last_packet_in_frame sent.

    //Frame Information
    input frame_info_s    frame_info,

    output logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet,
    output logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] frame_fill_packet_bit_enable,
    output logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] frame_fill_packet_be,
    output logic frame_fill,
    output logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)  :0]   request_packet_space_in_bytes_with_frame_support,    
    output logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] bytes_in_current_frame

);

    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] ovrflw_adjust_packet_space_in_bytes;
    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] next_bytes_in_current_frame, frame_length, nummber_of_frame_fill_packets;
    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] frame_length_minus_bytes_in_current_frame;
    logic [7:0] frame_fill_byte;
    logic frame_mode_enable,last_packet_in_frame,frame_closure_mode;
    logic reset_bytes_in_current_frame_counter;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] next_frame_fill_packet_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] next_ovrflw_adjust_packet_bit_enable;
    logic [BANK_DATA_WIDTH_IN_BYTES  -1:0] frame_data_byte_be_in,next_frame_fill_packet_be,next_ovrflw_adjust_packet_be;

    logic [$clog2(PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes_to_frame_filler;
    logic [$clog2(PACKET_WIDTH_IN_BYTES):0] frame_closure_threshold;

assign frame_length     = frame_info.frame_length     ; 
assign frame_fill_byte  = frame_info.frame_fill_byte  ; 
assign frame_mode_enable= frame_info.frame_mode_enable;
assign frame_closure_mode = frame_info.frame_closure_mode ;
assign frame_closure_threshold= frame_closure_mode?($clog2(PACKET_WIDTH_IN_BYTES)+1)'(PACKET_WIDTH_IN_BYTES):($clog2(PACKET_WIDTH_IN_BYTES)+1)'(0);

//Detect overflow. Check if overflow happens w/ original request.
//If frame_closure_mode is set to 1, we close the frame sooner (one MAX Packet sooner),So overflow never happens.
//If frame_closure_mode is set to 0, we allow overflow and need to detect the same.
assign frame_overflow_with_new_request = ((frame_closure_mode == 1'b0) && (frame_mode_enable || flush_mode_enable) && (($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(request_packet_space_in_bytes) > (frame_length_minus_bytes_in_current_frame)))?1'b1:1'b0;
assign ovrflw_adjust_packet_space_in_bytes = (frame_overflow_with_new_request)?(frame_length_minus_bytes_in_current_frame):'0;
/* verilator lint_off WIDTHEXPAND */
`ASSERT_MACRO(FRAME_OVF_ONLY_WHEN_LAST_PKT_FRAME_SET, clock, reset_n, frame_overflow_with_new_request, last_packet_in_frame, "frame_overflow_with_new_request will happen only when last_packet_in_frame is set")
/* verilator lint_on WIDTHEXPAND */
//If overflow, override the request packet size to fill the bank.
always@(*)
begin
  request_packet_space_in_bytes_to_frame_filler = (frame_overflow_with_new_request)?($clog2(PACKET_WIDTH_IN_BYTES)+1)'(frame_length_minus_bytes_in_current_frame):($clog2(PACKET_WIDTH_IN_BYTES)+1)'(request_packet_space_in_bytes);
end

//Time to add frame adjust bytes?
assign last_packet_in_frame = reset_bytes_in_current_frame_counter && (frame_mode_enable||flush_mode_enable); 
assign flush_mode_exit =   frame_fill;
assign nummber_of_frame_fill_packets = (last_packet_in_frame)?(frame_length_minus_bytes_in_current_frame-($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(request_packet_space_in_bytes_to_frame_filler)):(($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(0));
/* verilator lint_off WIDTHEXPAND */
`ASSERT_MACRO(NUM_FRAME_FILL_PACKET_CHECK, clock, reset_n, 1'b1, (nummber_of_frame_fill_packets <= BANK_DATA_WIDTH_IN_BYTES) , "nummber_of_frame_fill_packets shold not exceed BANK_DATA_WIDTH_IN_BYTES")
/* verilator lint_on WIDTHEXPAND */

//Counter for bytes in current frame
always@(posedge clock)
 if (!reset_n)
    bytes_in_current_frame <= 0;
 else
    bytes_in_current_frame <= next_bytes_in_current_frame;

always@(*)
 if (requested_packet_space_granted_from_accumulator != 0)
    next_bytes_in_current_frame = reset_bytes_in_current_frame_counter?0:($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(bytes_in_current_frame+($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(request_packet_space_in_bytes_to_frame_filler));
 else 
    next_bytes_in_current_frame = bytes_in_current_frame;

always@(*)
 if (request_packet_space_in_bytes_to_frame_filler == '0) 
  reset_bytes_in_current_frame_counter = 1'b0;
 else if (frame_overflow_with_new_request) 
  reset_bytes_in_current_frame_counter = 1'b1;
 else 
  reset_bytes_in_current_frame_counter = ((($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(request_packet_space_in_bytes)+($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(frame_closure_threshold)) >= (frame_length_minus_bytes_in_current_frame)) ? 1'b1:1'b0;

always@(posedge clock)
 if (!reset_n)
    frame_length_minus_bytes_in_current_frame <= '0;
 else 
    frame_length_minus_bytes_in_current_frame <= ($clog2(MAX_FRAME_LENGTH_IN_BYTES)+1)'(frame_length - next_bytes_in_current_frame);

always@(posedge clock)
 if (!reset_n)
  begin
    frame_fill <= 1'b0;
    frame_fill_packet_bit_enable <= {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
    frame_fill_packet_be         <= {BANK_DATA_WIDTH_IN_BYTES{1'b0}};
  end
 else if (requested_packet_space_granted_from_accumulator != 0)
   begin
    frame_fill                   <= last_packet_in_frame;
    frame_fill_packet_bit_enable <= next_frame_fill_packet_bit_enable | next_ovrflw_adjust_packet_bit_enable;
    frame_fill_packet_be         <= next_frame_fill_packet_be | next_ovrflw_adjust_packet_be;
   end


//re-calcuate request packet sapce for last packet in frame..
assign request_packet_space_in_bytes_with_frame_support = last_packet_in_frame?
                                                          ($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(request_packet_space_in_bytes_to_frame_filler)+($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(nummber_of_frame_fill_packets))
                                                          :($clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)+1)'(request_packet_space_in_bytes_to_frame_filler); 

//Gen Frame fill packets and byte-enables (adjusted to requested packet space).
integer i;

always@(*)
begin
  next_frame_fill_packet_bit_enable = {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
  next_frame_fill_packet_be         = {BANK_DATA_WIDTH_IN_BYTES{1'b0}};
  for (i=0;i<BANK_DATA_WIDTH_IN_BYTES;i=i+1)
   begin
    next_frame_fill_packet_bit_enable[(i*8)+:8] = ((($clog2(BANK_DATA_WIDTH_IN_BYTES))'(i)>=($clog2(BANK_DATA_WIDTH_IN_BYTES))'(request_packet_space_in_bytes_to_frame_filler))&&(($clog2(BANK_DATA_WIDTH_IN_BYTES))'(i)<(($clog2(BANK_DATA_WIDTH_IN_BYTES))'(request_packet_space_in_bytes_to_frame_filler)+($clog2(BANK_DATA_WIDTH_IN_BYTES))'(nummber_of_frame_fill_packets))))?8'hff:8'h0;
    next_frame_fill_packet_be[i]                = ((($clog2(BANK_DATA_WIDTH_IN_BYTES))'(i)>=($clog2(BANK_DATA_WIDTH_IN_BYTES))'(request_packet_space_in_bytes_to_frame_filler))&&(($clog2(BANK_DATA_WIDTH_IN_BYTES))'(i)<(($clog2(BANK_DATA_WIDTH_IN_BYTES))'(request_packet_space_in_bytes_to_frame_filler)+($clog2(BANK_DATA_WIDTH_IN_BYTES))'(nummber_of_frame_fill_packets))))?1'b1:1'b0;
   end 
end
always@(*)
begin
  next_ovrflw_adjust_packet_bit_enable = {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
  next_ovrflw_adjust_packet_be         = {BANK_DATA_WIDTH_IN_BYTES{1'b0}};
  for (i=0;i<BANK_DATA_WIDTH_IN_BYTES;i=i+1)
   begin
    next_ovrflw_adjust_packet_bit_enable[(i*8)+:8] = (($clog2(MAX_FRAME_LENGTH_IN_BYTES+1))'(i)<(ovrflw_adjust_packet_space_in_bytes))?8'hff:8'h0;
    next_ovrflw_adjust_packet_be[i]                = (($clog2(MAX_FRAME_LENGTH_IN_BYTES+1))'(i)<(ovrflw_adjust_packet_space_in_bytes))?1'b1:1'b0;
   end 
end
/* verilator lint_off WIDTHEXPAND */
`ASSERT_MACRO(NUM_FRAME_FILL_AND_REQ_PACKET_SPACE_CHECK, clock, reset_n, 1'b1, ((request_packet_space_in_bytes_to_frame_filler + nummber_of_frame_fill_packets) <= BANK_DATA_WIDTH_IN_BYTES) , "request_packet_space_in_bytes_to_frame_filler+nummber_of_frame_fill_packets shold not exceed BANK_DATA_WIDTH_IN_BYTES")
/* verilator lint_on WIDTHEXPAND */

assign frame_fill_packet = {(BANK_DATA_WIDTH_IN_BYTES){frame_fill_byte}};

endmodule

