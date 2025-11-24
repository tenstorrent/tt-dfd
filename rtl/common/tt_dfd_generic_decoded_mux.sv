// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module tt_dfd_generic_decoded_mux #(
    parameter DISABLE_ASSERTIONS = 0,
    parameter VALUE_WIDTH = 32,
    parameter MUX_WIDTH = 4
) (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic [MUX_WIDTH-1:0][VALUE_WIDTH-1:0] in,
    input logic [MUX_WIDTH-1:0] sel,
    output logic [VALUE_WIDTH-1:0] out
);


    always_ff @(posedge clk) begin
        if (rst_n) begin
            en_x_MuxSelectNotOneHot: assert(!$isunknown(en)) else $error("Xs in assertion en");
            if (en) begin
                x_MuxSelectNotOneHot: assert(!$isunknown(sel)) else $error("Xs in assertion");
                MuxSelectNotOneHot: assert($onehot(sel)) else $error("decoded_mux received a select input signal which was not one-hot");
            end
        end
    end

    always_comb begin
        out = VALUE_WIDTH'('0);
        for (int i = 0; i < MUX_WIDTH; i++) begin
            if (sel[i]) begin
                out = out | in[i];
            end
        end
    end

endmodule