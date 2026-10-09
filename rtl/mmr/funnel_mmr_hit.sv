// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module funnel_mmr_hit
import funnel_mmr_pkg::*;
#(
    parameter BASE_ADDR    = 0,
    parameter ADDR_W       = 12,
    parameter ENC_W        = 1,
    parameter ENC          = 0
)
(
    input   [ENC_W-1:0]      enctype,
    input   [ADDR_W-1:0]     reg_addr,
    output  logic            reg_rd_hit,
    output  logic            reg_wr_hit
);

logic [ADDR_W-1:0] MMR_ADDR;

assign MMR_ADDR = reg_addr;

localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELCONTROL             = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELIMPL                = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELDISINPUT            = ADDR_W'(BASE_ADDR + 'h8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHLO                   = ADDR_W'(BASE_ADDR + 'hFF8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHHI                   = ADDR_W'(BASE_ADDR + 'hFFC);

always_comb begin : mmr_hit_rd_comb
    if (enctype == ENC) begin : mmr_hit_rd_enc
        unique case (MMR_ADDR)

        ADDR_MMR_TRFUNNELCONTROL                : reg_rd_hit = 1'b1;
        ADDR_MMR_TRFUNNELIMPL                   : reg_rd_hit = 1'b1;
        ADDR_MMR_TRFUNNELDISINPUT               : reg_rd_hit = 1'b1;
        ADDR_MMR_SCRATCHLO                      : reg_rd_hit = 1'b1;
        ADDR_MMR_SCRATCHHI                      : reg_rd_hit = 1'b1;

        default:  begin : mmr_hit_rd_default
            reg_rd_hit     = 0;
        end
        endcase
    end else begin : mmr_hit_rd_not_enc
        reg_rd_hit      = 1;
    end
end

always_comb begin : mmr_hit_wr_comb
    if (enctype == ENC) begin : mmr_hit_wr_enc
        unique case (MMR_ADDR)

        ADDR_MMR_TRFUNNELCONTROL                : reg_wr_hit = 1'b1;
        ADDR_MMR_TRFUNNELIMPL                   : reg_wr_hit = 1'b0;
        ADDR_MMR_TRFUNNELDISINPUT               : reg_wr_hit = 1'b1;
        ADDR_MMR_SCRATCHLO                      : reg_wr_hit = 1'b1;
        ADDR_MMR_SCRATCHHI                      : reg_wr_hit = 1'b1;

        default:  begin : mmr_hit_wr_default
            reg_wr_hit     = 0;
        end
        endcase
    end else begin : mmr_hit_wr_not_enc
        reg_wr_hit      = 1;
    end
end
endmodule
