// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************

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
