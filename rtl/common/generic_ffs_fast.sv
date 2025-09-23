// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Generic fast find-first-set (priority encoder) with thermometer output
// Optimized parallel logic implementation suitable for open-source use
module generic_ffs_fast #(
    parameter DIR_L2H    = 1,              // Direction: 1=Low-to-High (LSB first), 0=High-to-Low (MSB first)
    parameter WIDTH      = 8,              // Number of request inputs
    parameter SIZE       = $clog2(WIDTH),  // Encoded output width
    parameter DATA_WIDTH = 4               // Width of data associated with each request
) (
    input  logic [WIDTH-1:0]                    req_in,           // Request inputs
    input  logic [WIDTH-1:0][DATA_WIDTH-1:0]   data_in,          // Data associated with each request
    
    output logic [DATA_WIDTH-1:0]              data_out,         // Data from selected request
    output logic [WIDTH-1:0]                   req_out,          // One-hot output showing selected request
    output logic [WIDTH-1:0]                   req_out_therm,    // Thermometer output (all bits up to winner)
    output logic [SIZE-1:0]                    enc_req_out       // Binary encoded position of selected request
);

    integer i, j;

    logic continue_flag, temp_therm;
    
    always_comb begin
        req_out = '0;
        data_out = '0;
        enc_req_out = '0;
        continue_flag = 1'b1;
        req_out_therm = '0;
        temp_therm = '0;
        if (DIR_L2H) begin
            req_out_therm[0] = req_in[0];
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (req_in[i] && continue_flag) begin
                    continue_flag = 1'b0;
                    req_out[i] = 1'b1;
                    data_out = data_in[i];
                    enc_req_out = SIZE'(i);
                end
            end
            
            for (i = 1; i < WIDTH; i = i + 1) begin
                temp_therm = temp_therm | req_in[i-1];
                req_out_therm[i] = temp_therm | req_in[i];
            end

        end else begin
            req_out_therm[WIDTH-1] = req_in[WIDTH-1];
            for (j = WIDTH-1; j >= 0; j = j - 1) begin
                if (req_in[j] && continue_flag) begin
                    continue_flag = 1'b0;
                    req_out[j] = 1'b1;
                    data_out = data_in[j];
                    enc_req_out = SIZE'(j);
                end
            end
            for (i = WIDTH-2; i >= 0; i = i - 1) begin
                temp_therm = temp_therm | req_in[i+1];
                req_out_therm[i] = temp_therm | req_in[i];
            end
        end
    end

endmodule