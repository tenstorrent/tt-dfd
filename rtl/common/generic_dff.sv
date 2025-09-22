// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module generic_dff #(parameter WIDTH=8,
                    parameter RESET_VALUE=0,
                    parameter BYPASS=0)
(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] in,
    input logic en,
    output logic [WIDTH-1:0] out
);

    if (BYPASS) begin
        assign out = in;
    end else begin
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                out <= WIDTH'(RESET_VALUE);
            end else if (en) begin
                out <= in;
            end
        end 
    end
endmodule