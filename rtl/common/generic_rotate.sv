// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module generic_rotate #(
    parameter int unsigned NUM_IN   = 6,
    parameter int unsigned NUM_OUT  = 8,
    parameter int unsigned ROT_LEFT = 1,
    parameter int unsigned IS_SHIFT = 0,
    parameter int unsigned DATA_SIZE= 10,
     
    parameter int unsigned NUM_OUT_ENC_WIDTH = (NUM_OUT == 1) ? 1 : $clog2(NUM_OUT)
    
) (
    input [NUM_IN-1:0] [DATA_SIZE-1:0]         data_in,
    input [NUM_OUT_ENC_WIDTH-1:0]              ptr_out,
      
    output logic [NUM_OUT-1:0] [DATA_SIZE-1:0] data_out
);

    // Exactly mimic the original's concatenation and bit-shifting
    logic [2*NUM_OUT*DATA_SIZE-1:0] concat_data;
    logic [DATA_SIZE*(NUM_OUT-NUM_IN)-1:0] zeros;
    logic [DATA_SIZE*(NUM_OUT-NUM_IN)+NUM_IN*DATA_SIZE-1:0] pattern;

    always_comb begin
        zeros = '0;
        pattern = '0;
        concat_data = '0;
        data_out = '0;
        if (ROT_LEFT) begin
            if (IS_SHIFT) begin
                concat_data = (2*NUM_OUT*DATA_SIZE)'(data_in) << (ptr_out * DATA_SIZE);
                data_out = concat_data[NUM_OUT*DATA_SIZE-1:0];
            end else begin
                pattern = {zeros, data_in};
                concat_data = {pattern, pattern} << (ptr_out * DATA_SIZE);
                data_out = concat_data[2*NUM_OUT*DATA_SIZE-1:NUM_OUT*DATA_SIZE];
            end
        end else begin
            if (IS_SHIFT) begin
                concat_data = (2*NUM_OUT*DATA_SIZE)'(data_in) >> (ptr_out * DATA_SIZE);
                data_out = concat_data[NUM_OUT*DATA_SIZE-1:0];
            end else begin
                pattern = {zeros, data_in};
                concat_data = {pattern, pattern} >> (ptr_out * DATA_SIZE);
                data_out = concat_data[NUM_OUT*DATA_SIZE-1:0];
            end
        end
    end
 
 endmodule