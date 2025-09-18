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
//Align inocming packets as per current write boundary for dfd_accumulator.
module dfd_cross_connect #(
    parameter ACCUMULATOR_DATA_WIDTH_IN_BYTES = 64,
    parameter BANK_DATA_WIDTH_IN_BYTES = 32
) (
    input logic [BANK_DATA_WIDTH_IN_BYTES*8-1:0] cross_connect_data_in,
    input logic [BANK_DATA_WIDTH_IN_BYTES-1  :0] cross_connect_data_byte_be_in, 
    input logic [$clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES)-1:0] write_byte_boundary,
    output logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8     -1:0] accumulator_data,         //dfd_accumulator data aligned to write boundary
    output logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES       -1:0] accumulator_byte_enables 
); 
// Reroute input data as per write byte boundary. Accumulator will update using the re-routed data as per write boundary.
localparam ACCUMULATOR_DATA_WIDTH = ACCUMULATOR_DATA_WIDTH_IN_BYTES * 8;
localparam BANK_DATA_WIDTH           = BANK_DATA_WIDTH_IN_BYTES * 8;
localparam NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY = $clog2(ACCUMULATOR_DATA_WIDTH_IN_BYTES);
int i;

logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8     -1:0] accumulator_data_set0;
logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8     -1:0] accumulator_data_set1;
logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES       -1:0] accumulator_byte_enables_set0;
logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES       -1:0] accumulator_byte_enables_set1;

//when position of write boundary can accomodate one complete packet in dfd_accumulator without roll-over
  always@(*)
   begin
    accumulator_data_set0         = {ACCUMULATOR_DATA_WIDTH{1'b0}};   
    accumulator_byte_enables_set0 = {ACCUMULATOR_DATA_WIDTH_IN_BYTES{1'b0}};   
    for(i =0; i<=ACCUMULATOR_DATA_WIDTH_IN_BYTES-BANK_DATA_WIDTH_IN_BYTES; i=i+1) 
     begin
       if (write_byte_boundary == ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(i))) begin
           accumulator_data_set0         = (ACCUMULATOR_DATA_WIDTH)'(cross_connect_data_in * (2**(i*8)));     //{cross_connect_data_in,{i*8{1'b0}}};
           accumulator_byte_enables_set0 = (ACCUMULATOR_DATA_WIDTH_IN_BYTES)'(cross_connect_data_byte_be_in * (2**i)); //{cross_connect_data_byte_be_in,{i{1'b0}}};
       end
     end
   end

// when position of write boundary requires dfd_accumulator roll over
//had to use generate to work-around use of "variable" for index select...
logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES*8     -1:0] accumulator_data_set1_array[BANK_DATA_WIDTH_IN_BYTES-1];
logic [ACCUMULATOR_DATA_WIDTH_IN_BYTES       -1:0] accumulator_byte_enables_set1_array[BANK_DATA_WIDTH_IN_BYTES-1];
genvar j;
generate
for(j = 1; j<BANK_DATA_WIDTH_IN_BYTES; j=j+1) 
begin
always@(*)
  begin
        if (write_byte_boundary == ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(ACCUMULATOR_DATA_WIDTH_IN_BYTES-BANK_DATA_WIDTH_IN_BYTES + j))) 
          begin
           accumulator_data_set1_array[j-1] = {cross_connect_data_in[0+:BANK_DATA_WIDTH-(j*8)],
                              {((ACCUMULATOR_DATA_WIDTH-BANK_DATA_WIDTH)){1'b0}},
                               cross_connect_data_in[(BANK_DATA_WIDTH-(j*8))+:(j*8)]}; 
           accumulator_byte_enables_set1_array[j-1] = {cross_connect_data_byte_be_in[0+:BANK_DATA_WIDTH_IN_BYTES-j],
                               {(ACCUMULATOR_DATA_WIDTH_IN_BYTES-BANK_DATA_WIDTH_IN_BYTES){1'b0}},
                               cross_connect_data_byte_be_in[(BANK_DATA_WIDTH_IN_BYTES-j)+:j]}; 
         end
        else
         begin
          accumulator_data_set1_array[j-1]         = {ACCUMULATOR_DATA_WIDTH{1'b0}};   
          accumulator_byte_enables_set1_array[j-1] = {ACCUMULATOR_DATA_WIDTH_IN_BYTES{1'b0}};   
         end 
   end
  end
  endgenerate

always @(*) begin
  accumulator_data_set1           = accumulator_data_set1_array[0];
  accumulator_byte_enables_set1   = accumulator_byte_enables_set1_array[0];
  for(i = 1; i<BANK_DATA_WIDTH_IN_BYTES; i=i+1) 
    begin
        if (write_byte_boundary == ((NUMBER_OF_BITS_IN_WRITE_BYTE_BOUNDARY)'(ACCUMULATOR_DATA_WIDTH_IN_BYTES-BANK_DATA_WIDTH_IN_BYTES + i))) begin
           accumulator_data_set1           = accumulator_data_set1_array[i-1];
           accumulator_byte_enables_set1   = accumulator_byte_enables_set1_array[i-1];
        end
    end
end

assign accumulator_data = accumulator_data_set0 | accumulator_data_set1;
assign accumulator_byte_enables = accumulator_byte_enables_set0 | accumulator_byte_enables_set1;
endmodule
