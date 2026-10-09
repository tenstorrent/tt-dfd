module dst_mmr_hit
import dst_mmr_pkg::*;
#(
    parameter BASE_ADDR    = 0,                 // base address
    parameter ADDR_W       = 12,                // bit width of address
    parameter ENC_W        = 1,                 // bit width of encoding
    parameter ENC          = 0                  // encoding value to trigger hit lookup
)
(
    input   [ENC_W-1:0]      enctype,
    input   [ADDR_W-1:0]     reg_addr,
    output  logic            reg_rd_hit,
    output  logic            reg_wr_hit
);

logic [ADDR_W-1:0] MMR_ADDR;

assign MMR_ADDR = reg_addr;

// Addresses
localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTCONTROL                = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTIMPL                   = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTINSTFEATURES           = ADDR_W'(BASE_ADDR + 'h8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGDEBUGTRACECFG           = ADDR_W'(BASE_ADDR + 'h1A0);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHLO                   = ADDR_W'(BASE_ADDR + 'hFF8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHHI                   = ADDR_W'(BASE_ADDR + 'hFFC);



// Register reads
always_comb begin : mmr_hit_rd_comb
    if (enctype == ENC) begin : mmr_hit_rd_enc
        unique case (MMR_ADDR)
        //mmr address found
        ADDR_MMR_TRDSTCONTROL                   : reg_rd_hit = 1'b1;
        ADDR_MMR_TRDSTIMPL                      : reg_rd_hit = 1'b1;
        ADDR_MMR_TRDSTINSTFEATURES              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGDEBUGTRACECFG              : reg_rd_hit = 1'b1;
        ADDR_MMR_SCRATCHLO                      : reg_rd_hit = 1'b1;
        ADDR_MMR_SCRATCHHI                      : reg_rd_hit = 1'b1;
        //mmr address not found
        default:  begin : mmr_hit_rd_default
            reg_rd_hit     = 0;
        end
        endcase
    end else begin : mmr_hit_rd_not_enc
        reg_rd_hit      = 1;
    end
end

// Register writes
always_comb begin : mmr_hit_wr_comb
    if (enctype == ENC) begin : mmr_hit_wr_enc
        unique case (MMR_ADDR)
        //mmr address found
        ADDR_MMR_TRDSTCONTROL                   : reg_wr_hit = 1'b1;
        ADDR_MMR_TRDSTIMPL                      : reg_wr_hit = 1'b1;
        ADDR_MMR_TRDSTINSTFEATURES              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGDEBUGTRACECFG              : reg_wr_hit = 1'b1;
        ADDR_MMR_SCRATCHLO                      : reg_wr_hit = 1'b1;
        ADDR_MMR_SCRATCHHI                      : reg_wr_hit = 1'b1;
        //mmr address not found
        default:  begin : mmr_hit_wr_default
            reg_wr_hit     = 0;
        end
        endcase
    end else begin : mmr_hit_wr_not_enc
        reg_wr_hit      = 1;
    end
end
endmodule
