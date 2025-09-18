module generic_ffs_N#(parameter DIR_L2H    = 1,              //Direction of Priority
                parameter WIDTH      = 8,              //Number of inputs.
                parameter SIZE       = ($clog2(WIDTH) > 1 ? $clog2(WIDTH) : 1), //Log2 Number of inputs
                parameter DATA_WIDTH = 4,              //Width of data  
                parameter NUM_SEL    = 3)              //Number of muxed outputs   (
   
   (input  [WIDTH-1:0]                         req_in,
    input [WIDTH-1:0] [DATA_WIDTH-1:0]         data_in,
    
    output logic [NUM_SEL-1:0]                 req_sum,
    output logic [NUM_SEL-1:0][DATA_WIDTH-1:0] data_out,
    output logic [NUM_SEL-1:0][WIDTH-1:0]      req_out,
    output logic [NUM_SEL-1:0][SIZE-1:0]       enc_req_out
);


// genvar i;
    // generate
        // for (i = 0; i < NUM_SEL; i = i + 1) begin
        //     generic_ffs #(
        //         .DIR_L2H(DIR_L2H), 
        //         .WIDTH(WIDTH), 
        //         .SIZE(SIZE), 
        //         .DATA_WIDTH(DATA_WIDTH)
        //     ) 
        //     ffs_inst (
        //         .req_in(req_in), 
        //         .data_in(data_in), 
        //         .req_sum(req_sum[i]),
        //         .data_out(data_out[i]), 
        //         .req_out(req_out[i]), 
        //         .enc_req_out(enc_req_out[i])
        //     );
        // end
    // endgenerate
    integer i, j;
    logic continue_flag;
    logic [WIDTH-1:0] req_in_masked;

    // generic_ffs #(
    //     .DIR_L2H(DIR_L2H), 
    //     .WIDTH(WIDTH), 
    //     .SIZE(SIZE), 
    //     .DATA_WIDTH(DATA_WIDTH)
    // ) 
    // ffs_inst (
    //     .req_in(req_in), 
    //     .data_in(data_in), 
    //     .req_sum(req_sum[0]),
    //     .data_out(data_out[0]), 
    //     .req_out(req_out[0]), 
    //     .enc_req_out(enc_req_out[0])
    // );
    always_comb begin
        // req_in_masked = req_in;
        // req_out = '0;
        // data_out = '0;
        // enc_req_out = '0;
        // continue_flag = '1;


        req_in_masked = req_in;
        req_out = '0;
        data_out = '0;
        req_sum = '0;
        enc_req_out = '0;
        continue_flag = '1;   

        req_sum[0] = |req_in;
        if (req_sum[0]) begin
            if (DIR_L2H) begin
                data_out[0] = data_in[WIDTH-1];  // High index for L2H direction
                enc_req_out[0] = '0;              // All 1s for L2H
                for (j = 0; j < WIDTH; j = j + 1) begin
                    if (req_in_masked[j] && continue_flag) begin
                        continue_flag = 1'b0;
                        data_out[0] = data_in[j];
                        enc_req_out[0] = SIZE'(unsigned'(j));
                        req_out[0][j] = 1'b1;
                    end
                end
            end
            else begin
                data_out[0] = data_in[0];         // Low index for H2L direction  
                enc_req_out[0] = '0;              // All 0s for H2L
                for (j = WIDTH - 1; j >= 0; j = j - 1) begin
                    if (req_in_masked[j] && continue_flag) begin
                        continue_flag = 1'b0;
                        data_out[0] = data_in[j];
                        enc_req_out[0] = SIZE'(unsigned'(j));
                        req_out[0][j] = 1'b1;
                    end
                end
            end
        end

        for (i = 1; i < NUM_SEL; i = i + 1) begin
            if (req_sum[i - 1]) begin
                req_in_masked = req_in_masked & ~req_out[i-1];

                req_sum[i] = |req_in_masked;
                continue_flag = '1;

                if (DIR_L2H) begin
                    data_out[i] = data_in[WIDTH- 1];  // High index for L2H direction
                    enc_req_out[i] = '0;              // All 1s for L2H
                    for (j = 0; j < WIDTH; j = j + 1) begin
                        if (req_in_masked[j] && continue_flag) begin
                            continue_flag = 1'b0;
                            data_out[i] = data_in[j];
                            enc_req_out[i] = SIZE'(unsigned'(j));
                            req_out[i][j] = 1'b1;
                        end
                    end
                end else begin
                    data_out[i] = data_in[0];         // Low index for H2L direction  
                    enc_req_out[i] = '0;              // All 0s for H2L
                    for (j = WIDTH - 1; j >= 0; j = j - 1) begin
                        if (req_in_masked[j] && continue_flag) begin
                            continue_flag = 1'b0;
                            data_out[i] = data_in[j];
                            enc_req_out[i] = SIZE'(unsigned'(j));
                            req_out[i][j] = 1'b1;
                        end
                    end
                end
            end
        end
    end
    

endmodule

