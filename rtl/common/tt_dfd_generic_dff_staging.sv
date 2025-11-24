// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module tt_dfd_generic_dff_staging #(parameter WIDTH=8,
                parameter DEPTH=2,
                parameter RESET_VALUE=0)
(
   input  logic             clk,
   input  logic             rst_n,
   input  logic             en,
   input  logic [WIDTH-1:0] in,

   output logic [WIDTH-1:0] out
);

   generate 
    if(DEPTH<=0) begin
        tt_dfd_generic_dff #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE), .BYPASS(1)) dff_flop (
            .out(out),
            .in(in),
            .en(en),
            .clk(clk),
            .rst_n(rst_n)
        );
    end else if (DEPTH==1) begin
        tt_dfd_generic_dff #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE), .BYPASS(0)) dff_flop (
            .out(out),
            .in(in),
            .en(en),
            .clk(clk),
            .rst_n(rst_n)
        );
    end else begin
        logic [DEPTH:0][WIDTH-1:0] input_buffer;

        assign out = input_buffer[DEPTH];
        assign input_buffer[0] = in;
        
        for (genvar i = 0; i < DEPTH; i++) begin
            tt_dfd_generic_dff #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE), .BYPASS(0)) dff_staging (
                .out(input_buffer[i+1]),
                .in(input_buffer[i]),
                .en(en),
                .clk(clk),
                .rst_n(rst_n)
            );
        end
    end
   endgenerate
endmodule 