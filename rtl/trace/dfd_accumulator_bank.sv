// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Accumulator Banks
module dfd_accumulator_bank 
import dfd_packetizer_pkg::*;
#(
    parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64,
              BANK_DATA_WIDTH_IN_BYTES = 16,
              WRITE_BYTE_POINTER_RANGE_START = 0,
              WRITE_BYTE_POINTER_RANGE_END = 15
) (
    input  logic clock,
    input  logic reset_n,
    input  logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] target_write_byte_boundary,
    input  logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] write_byte_boundary,
    input  logic                                               bank_flush,
    input  logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0]              bank_data,
    input  logic [BANK_DATA_WIDTH_IN_BYTES  -1:0]              bank_byte_enable,
    output bank_status_t                                       bank_status,
    output logic [$clog2(BANK_DATA_WIDTH_IN_BYTES)    :0]      bank_free_space_in_bytes,
    output logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0]              bank_data_out

);

  localparam NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY = $clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES);
  localparam NUMBER_OF_BITS_IN_FREE_SPACE          = $clog2(BANK_DATA_WIDTH_IN_BYTES) + 1;
  
  bank_status_t next_bank_status;
  logic [NUMBER_OF_BITS_IN_FREE_SPACE-1      :0]      next_bank_free_space_in_bytes;
  logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0]              next_bank_data_out;
  logic target_write_byte_boundary_in_range, target_write_byte_boundary_above_range , target_write_byte_wraparound;
  logic target_write_byte_boundary_equals_range_end,target_write_byte_boundary_crosses_bank_range;

//Each Bank has following inputs, outputs and state elements.
//Inputs
//1.	Write Pointer Range (Write Byte pointer range owned by the bank)
//2.	Target Write Byte Boundary (Write Boundary + Incoming packet length, input from Accumulator Control)
//3.	Flush
//4.	Data and Byte Enables (from Cross Connect)
//Outputs
//1.	Bank Status: Empty, Partial, Full
//2.	Free Space (in Bytes): Number of free space that are available in the bank
//3.	Data
//State Element
//1.	Data (updated as per Byte enables)
//2.	Bank Status
//3.	Bytes Availability

// Have to turn of this lint check, because for specific instance of accumlator_bank, 
// the instance with WRITE_BYTE_POINTER_RANGE_END), the WRITE_BYTE_POINTER_RANGE_END will equal max value of (write_boundary +1).
// the comparision of write_boundary w/ range end will always be true. Works as expected.
/* verilator lint_off CMPCONST */
assign target_write_byte_boundary_in_range    = (target_write_byte_boundary != write_byte_boundary) &&  
                                                ((target_write_byte_boundary >=((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_START))) &&
                                                (target_write_byte_boundary <=((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_END  ))));
assign target_write_byte_boundary_above_range = (target_write_byte_boundary > ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_END)));
assign target_write_byte_wraparound           = (target_write_byte_boundary < write_byte_boundary) &&
                                                (target_write_byte_boundary_in_range == 0) &&
                                                (write_byte_boundary <= ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_END)));
assign target_write_byte_boundary_equals_range_end = (target_write_byte_boundary == (NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_END));
assign target_write_byte_boundary_crosses_bank_range = (write_byte_boundary <= ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_START))) && 
                                                       (target_write_byte_boundary > ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(WRITE_BYTE_POINTER_RANGE_END)));
/* verilator lint_on CMPCONST */

//Bank Status FSM (See MAS)
// EMPTY --> PARTIAL or FULL (depending on target write pointer) --> back to BANK EMPTY (on flush)
always@(*) begin
     next_bank_status = bank_status;
     next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES));
     unique case (bank_status)
       BANK_EMPTY  :begin 
                    if (target_write_byte_boundary_in_range) begin  
                      next_bank_status = BANK_PARTIAL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(WRITE_BYTE_POINTER_RANGE_END + 1))
                                                    - (target_write_byte_boundary);
                    end
//                    else if (target_write_byte_boundary_above_range || target_write_byte_wraparound) begin 
                    else if (target_write_byte_boundary_equals_range_end || target_write_byte_boundary_crosses_bank_range || target_write_byte_wraparound) begin 
                      next_bank_status = BANK_FULL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(0));
                    end
                    else begin 
                      next_bank_status = BANK_EMPTY;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES));
                    end
                    end
       BANK_PARTIAL:begin 
                    if (target_write_byte_boundary_above_range || target_write_byte_wraparound) begin      
                      next_bank_status = BANK_FULL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(0));
                    end
                    else begin    
                      next_bank_status = BANK_PARTIAL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(WRITE_BYTE_POINTER_RANGE_END + 1)) 
                                                    - (target_write_byte_boundary);
                    end
                    end
       BANK_FULL   :begin
                    if (target_write_byte_boundary_in_range && bank_flush) begin  
                      next_bank_status = BANK_PARTIAL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(WRITE_BYTE_POINTER_RANGE_END + 1))
                                                    - (target_write_byte_boundary);
                    end
                    else if (bank_flush) begin                                  
                      next_bank_status = BANK_EMPTY;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES));
                    end
                    else  begin                                           
                      next_bank_status = BANK_FULL;
                      next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(0));
                    end
                    end
       default     :begin
                     next_bank_status = bank_status;
                     next_bank_free_space_in_bytes = (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES));
                    end 
     endcase
end

always@(posedge clock) begin
 if (!reset_n) begin
    bank_status   <= BANK_EMPTY;
    bank_free_space_in_bytes <= (($clog2(BANK_DATA_WIDTH_IN_BYTES)+1)'(BANK_DATA_WIDTH_IN_BYTES));
 end  
 else begin
    bank_status   <= next_bank_status;
    bank_free_space_in_bytes <= next_bank_free_space_in_bytes;
 end
end

// Update bank_data_out as per byte enables. Ensure byte lanes w/ ByteEnable set to 0 retains existing value.
always@(posedge clock) begin
 if (!reset_n) 
    bank_data_out <= {BANK_DATA_WIDTH_IN_BYTES*8{1'b0}};
 else 
    bank_data_out <= next_bank_data_out;
end

always@(*)  
 begin
   for (int i=0;i<BANK_DATA_WIDTH_IN_BYTES;i=i+1)
     if (bank_byte_enable[i]==1)
       next_bank_data_out[(i*8)+:8] = bank_data[(i*8)+:8];
     else
       next_bank_data_out[(i*8)+:8] = bank_data_out[(i*8)+:8];
 end

endmodule

