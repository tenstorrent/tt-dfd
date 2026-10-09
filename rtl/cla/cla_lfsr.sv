// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_lfsr
import cla_mmr_pkg::*;

#(
    parameter LFSR_WIDTH = 63
) (
    input logic clock,
    input logic reset_n,
    input logic cla_en,
    input ClaCdbglfsrMmr_s lfsr_mmr,
    input ClaCdbglfsrmaskMmr_s lfsr_mask_mmr,
    output ClaCdbglfsrMmrWr_s lfsr_mmr_wr,
    output logic lfsr_out
);

    logic next_lfsr_value;
    logic [LFSR_WIDTH-1:0] lfsr_value;
    logic lfsr_en;

    always_comb begin
        next_lfsr_value = ^(lfsr_mmr.Lfsr & lfsr_mask_mmr.Mask);
        lfsr_en = lfsr_mmr.LfsrActive & cla_en;
        lfsr_value = lfsr_mmr.Lfsr;
    end

    assign lfsr_out = lfsr_en ? lfsr_value[0] : 1'b0;

    always_comb begin
        lfsr_mmr_wr = '0;
        lfsr_mmr_wr.LfsrWrEn = lfsr_en;
        lfsr_mmr_wr.Data.Lfsr = (LFSR_WIDTH)'({next_lfsr_value, lfsr_value[LFSR_WIDTH-1:1]});
    end

endmodule
