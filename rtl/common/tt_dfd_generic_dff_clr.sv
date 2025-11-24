// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module tt_dfd_generic_dff_clr #(parameter WIDTH=8,
                    parameter RESET_VALUE=0)
(
   input  logic		     clk,
   input  logic		     rst_n,
   input  logic		     en,
   input  logic              clr,
   input  logic [WIDTH-1:0]  in,

   output logic [WIDTH-1:0]  out
);

    logic [WIDTH-1:0] new_in;
    assign new_in = {WIDTH{~clr}} & (en ? in : out);

    tt_dfd_generic_dff #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE)) u_dff (
        .clk(clk),
        .rst_n(rst_n),
        .en(en | clr),
        .in(new_in),
        .out(out)
    );
    
endmodule