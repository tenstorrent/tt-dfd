module ntr_mmr_hit
import ntr_mmr_pkg::*;
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
localparam   [ADDR_W-1:0] ADDR_MMR_TRTECONTROL                 = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEIMPL                    = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEINSTFEATURES            = ADDR_W'(BASE_ADDR + 'h8);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEINSTFILTERS             = ADDR_W'(BASE_ADDR + 'hC);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEFILTER0CONTROL          = ADDR_W'(BASE_ADDR + 'h10);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEFILTER0MATCHINST        = ADDR_W'(BASE_ADDR + 'h14);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTSCONTROL                 = ADDR_W'(BASE_ADDR + 'h40);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNTRACEFRAMECFG          = ADDR_W'(BASE_ADDR + 'h1A8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHLO                   = ADDR_W'(BASE_ADDR + 'hFF8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHHI                   = ADDR_W'(BASE_ADDR + 'hFFC);



// Register reads
always_comb begin : mmr_hit_rd_comb
    if (enctype == ENC) begin : mmr_hit_rd_enc
        unique case (MMR_ADDR)
        //mmr address found
        ADDR_MMR_TRTECONTROL                    : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTEIMPL                       : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTEINSTFEATURES               : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTEINSTFILTERS                : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTEFILTER0CONTROL             : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTEFILTER0MATCHINST           : reg_rd_hit = 1'b1;
        ADDR_MMR_TRTSCONTROL                    : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNTRACEFRAMECFG             : reg_rd_hit = 1'b1;
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
        ADDR_MMR_TRTECONTROL                    : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTEIMPL                       : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTEINSTFEATURES               : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTEINSTFILTERS                : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTEFILTER0CONTROL             : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTEFILTER0MATCHINST           : reg_wr_hit = 1'b1;
        ADDR_MMR_TRTSCONTROL                    : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNTRACEFRAMECFG             : reg_wr_hit = 1'b1;
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
