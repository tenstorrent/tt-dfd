module ntr_sink_mmr_hit
import ntr_sink_mmr_pkg::*;
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
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMCONTROL                = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMIMPL                   = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMSTARTLOW               = ADDR_W'(BASE_ADDR + 'h10);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMSTARTHIGH              = ADDR_W'(BASE_ADDR + 'h14);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMLIMITLOW               = ADDR_W'(BASE_ADDR + 'h18);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMLIMITHIGH              = ADDR_W'(BASE_ADDR + 'h1C);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMWPLOW                  = ADDR_W'(BASE_ADDR + 'h20);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMWPHIGH                 = ADDR_W'(BASE_ADDR + 'h24);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMRPLOW                  = ADDR_W'(BASE_ADDR + 'h28);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMRPHIGH                 = ADDR_W'(BASE_ADDR + 'h2C);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMDATA                   = ADDR_W'(BASE_ADDR + 'h40);
localparam   [ADDR_W-1:0] ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW        = ADDR_W'(BASE_ADDR + 'hE00);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHLO                   = ADDR_W'(BASE_ADDR + 'hFF8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHHI                   = ADDR_W'(BASE_ADDR + 'hFFC);



// Register reads
always_comb begin : mmr_hit_rd_comb
    if (enctype == ENC) begin : mmr_hit_rd_enc
        unique case (MMR_ADDR)
        //mmr address found
        ADDR_MMR_TRRAMCONTROL                   : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMIMPL                      : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMSTARTLOW                  : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMSTARTHIGH                 : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMLIMITLOW                  : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMLIMITHIGH                 : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMWPLOW                     : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMWPHIGH                    : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMRPLOW                     : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMRPHIGH                    : reg_rd_hit = 1'b1;
        ADDR_MMR_TRRAMDATA                      : reg_rd_hit = 1'b1;
        ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW           : reg_rd_hit = 1'b1;
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
        ADDR_MMR_TRRAMCONTROL                   : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMIMPL                      : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMSTARTLOW                  : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMSTARTHIGH                 : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMLIMITLOW                  : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMLIMITHIGH                 : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMWPLOW                     : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMWPHIGH                    : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMRPLOW                     : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMRPHIGH                    : reg_wr_hit = 1'b1;
        ADDR_MMR_TRRAMDATA                      : reg_wr_hit = 1'b0;
        ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW           : reg_wr_hit = 1'b1;
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
