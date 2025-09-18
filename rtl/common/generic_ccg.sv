
// Generic, non-proprietary clock gating cell (scrubbed version)
// Functionally equivalent to a typical clock gate: o_clk is i_clk when enabled, otherwise held low.
module generic_ccg #(
    parameter WIDTH = 1,
    parameter LATE_EN = 0,  
    parameter HYST_EN = 1,     
    parameter HYST_CYC = 2 
) (
    input  logic              clk,
    input  logic              rst_n,
    input  logic [WIDTH-1:0]  en,
    input  logic              force_en,
    input  logic              hyst,
    input  logic              te,
    output logic [WIDTH-1:0]  out_clk
);
    // Ensure parameters are at least 1 to avoid negative array indices
    localparam HYST_SIZE = (HYST_CYC == 1) ? 1 : $clog2(HYST_CYC);
    localparam ARRAY_WIDTH = (WIDTH > 0) ? WIDTH : 1;
    localparam HYST_WIDTH = (HYST_SIZE > 0) ? HYST_SIZE : 1;

    /* verilator lint_off ASCRANGE */
    logic [ARRAY_WIDTH-1:0]            o_en;
    logic [ARRAY_WIDTH-1:0]            hyst_on;
    logic [ARRAY_WIDTH-1:0]            latched_en;
    logic [ARRAY_WIDTH-1:0][HYST_WIDTH-1:0] hyst_count;
    /* verilator lint_on ASCRANGE */
    genvar i;
    


    generate
        
        if (LATE_EN[0]) begin
            always_ff @(posedge clk) begin
                o_en <= en | {WIDTH{~rst_n | force_en}} | hyst_on;
            end
        end else begin
            for (i = 0; i < WIDTH; i++) begin
                always_ff @(posedge clk) begin
                    if (en[i] | ~rst_n | force_en | hyst_on[i]) begin
                        o_en[i] <= 1'b1;
                    end else begin
                        o_en[i] <= 1'b0;
                    end
                end
            end
        end
    
        if (HYST_EN[0]) begin
            for (i = 0; i < WIDTH; i++) begin
                always_ff @(posedge clk) begin
                    if (~rst_n) 
                        hyst_count[i] <= '0;
                    else if (en[i] & hyst)
                        hyst_count[i] <= (HYST_SIZE)'(HYST_CYC-1);
                    else
                        hyst_count[i] <= hyst_count[i] - (HYST_SIZE)'(|hyst_count[i]);
                end
                assign hyst_on[i] = |hyst_count[i];
            end
        end
        else 
            assign hyst_on = '0;
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i++) begin
            generic_clkgate clkgate (
                .clk(clk),
                .en(o_en[i]),
                .te(te),
                .clk_out(out_clk[i])
            );
        end
    endgenerate
    
    // always_latch begin
    //     if (!clk) 
    //         latched_en = o_en;
    // end
    
    // assign out_clk = {WIDTH{clk}} & latched_en; 

endmodule