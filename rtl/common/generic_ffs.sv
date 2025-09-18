// SPDX-License-Identifier: Apache-2.0
// Generic find-first-set (priority encoder) with data multiplexing
// Simple, standard implementation suitable for open-source use

module generic_ffs #(
    parameter DIR_L2H    = 1,              // Direction: 1=Low-to-High (LSB first), 0=High-to-Low (MSB first)
    parameter WIDTH      = 8,              // Number of request inputs
    parameter SIZE       = ($clog2(WIDTH) > 1 ? $clog2(WIDTH) : 1),  // Encoded output width
    parameter DATA_WIDTH = 4               // Width of data associated with each request
) (
    input  logic [WIDTH-1:0]                    req_in,        // Request inputs
    input  logic [WIDTH-1:0][DATA_WIDTH-1:0]   data_in,       // Data associated with each request
    
    output logic                               req_sum,       // Any request present
    output logic [DATA_WIDTH-1:0]              data_out,      // Data from selected request
    output logic [WIDTH-1:0]                   req_out,       // One-hot output showing selected request
    output logic [SIZE-1:0]                    enc_req_out    // Binary encoded position of selected request
);

    logic continue_flag;
    
    always_comb begin
        req_out = '0;
        // When no requests are active, default values depend on DIR_L2H
        
        continue_flag = 1'b1;
        req_sum = |req_in;
        
        
        if (DIR_L2H) begin
            data_out = data_in[WIDTH-1];  // High index for L2H direction
            enc_req_out = '1;              // All 1s for L2H
            for (int i = 0; i < WIDTH; i = i + 1) begin
                if (req_in[i] && continue_flag) begin
                    continue_flag = 1'b0;
                    req_out[i] = 1'b1;
                    data_out = data_in[i];
                    enc_req_out = SIZE'(unsigned'(i));
                end
            end
        end else begin
            data_out = data_in[0];         // Low index for H2L direction  
            enc_req_out = '0;              // All 0s for H2L
            for (int j = WIDTH-1; j >= 0; j = j - 1) begin
                if (req_in[j] && continue_flag) begin
                    continue_flag = 1'b0;
                    req_out[j] = 1'b1;
                    data_out = data_in[j];
                    enc_req_out = SIZE'(unsigned'(j));
                end
            end
        end
    end

endmodule 