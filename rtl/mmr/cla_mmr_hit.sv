// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_mmr_hit
import cla_mmr_pkg::*;
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

localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER0CFG          = ADDR_W'(BASE_ADDR + 'h100);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER1CFG          = ADDR_W'(BASE_ADDR + 'h108);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER2CFG          = ADDR_W'(BASE_ADDR + 'h110);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER3CFG          = ADDR_W'(BASE_ADDR + 'h118);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP0               = ADDR_W'(BASE_ADDR + 'h120);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP1               = ADDR_W'(BASE_ADDR + 'h128);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP0               = ADDR_W'(BASE_ADDR + 'h130);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP1               = ADDR_W'(BASE_ADDR + 'h138);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP0               = ADDR_W'(BASE_ADDR + 'h140);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP1               = ADDR_W'(BASE_ADDR + 'h148);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP0               = ADDR_W'(BASE_ADDR + 'h150);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP1               = ADDR_W'(BASE_ADDR + 'h158);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK0LO           = ADDR_W'(BASE_ADDR + 'h160);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH0LO          = ADDR_W'(BASE_ADDR + 'h168);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK1LO           = ADDR_W'(BASE_ADDR + 'h170);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH1LO          = ADDR_W'(BASE_ADDR + 'h178);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALEDGEDETECTCFG        = ADDR_W'(BASE_ADDR + 'h180);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGEAPSTATUS               = ADDR_W'(BASE_ADDR + 'h188);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACTRLSTATUS           = ADDR_W'(BASE_ADDR + 'h190);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGMUXSELLO                = ADDR_W'(BASE_ADDR + 'h198);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGRSVD1                   = ADDR_W'(BASE_ADDR + 'h1A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGRSVD2                   = ADDR_W'(BASE_ADDR + 'h1A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONMASKLO        = ADDR_W'(BASE_ADDR + 'h1B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONFROMVALUELO        = ADDR_W'(BASE_ADDR + 'h1B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONTOVALUELO        = ADDR_W'(BASE_ADDR + 'h1C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTMASKLO         = ADDR_W'(BASE_ADDR + 'h1C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTVALUE          = ADDR_W'(BASE_ADDR + 'h1D0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGANYCHANGELO             = ADDR_W'(BASE_ADDR + 'h1D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO        = ADDR_W'(BASE_ADDR + 'h1E0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO        = ADDR_W'(BASE_ADDR + 'h1E8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO        = ADDR_W'(BASE_ADDR + 'h1F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO        = ADDR_W'(BASE_ADDR + 'h1F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO        = ADDR_W'(BASE_ADDR + 'h200);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO        = ADDR_W'(BASE_ADDR + 'h208);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO        = ADDR_W'(BASE_ADDR + 'h210);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO        = ADDR_W'(BASE_ADDR + 'h218);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMEMATCH            = ADDR_W'(BASE_ADDR + 'h220);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK2LO           = ADDR_W'(BASE_ADDR + 'h228);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH2LO          = ADDR_W'(BASE_ADDR + 'h230);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK3LO           = ADDR_W'(BASE_ADDR + 'h238);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH3LO          = ADDR_W'(BASE_ADDR + 'h240);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP2               = ADDR_W'(BASE_ADDR + 'h248);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP3               = ADDR_W'(BASE_ADDR + 'h250);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP2               = ADDR_W'(BASE_ADDR + 'h258);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP3               = ADDR_W'(BASE_ADDR + 'h260);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP2               = ADDR_W'(BASE_ADDR + 'h268);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP3               = ADDR_W'(BASE_ADDR + 'h270);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP2               = ADDR_W'(BASE_ADDR + 'h278);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP3               = ADDR_W'(BASE_ADDR + 'h280);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO        = ADDR_W'(BASE_ADDR + 'h288);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO        = ADDR_W'(BASE_ADDR + 'h290);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO        = ADDR_W'(BASE_ADDR + 'h298);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO        = ADDR_W'(BASE_ADDR + 'h2A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO        = ADDR_W'(BASE_ADDR + 'h2A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO        = ADDR_W'(BASE_ADDR + 'h2B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO        = ADDR_W'(BASE_ADDR + 'h2B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO        = ADDR_W'(BASE_ADDR + 'h2C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALDELAYMUXSEL        = ADDR_W'(BASE_ADDR + 'h2C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH        = ADDR_W'(BASE_ADDR + 'h2D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMP            = ADDR_W'(BASE_ADDR + 'h2F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPSYNC        = ADDR_W'(BASE_ADDR + 'h2F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPCONFIG        = ADDR_W'(BASE_ADDR + 'h300);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPOFFSET        = ADDR_W'(BASE_ADDR + 'h308);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK0HI           = ADDR_W'(BASE_ADDR + 'h400);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH0HI          = ADDR_W'(BASE_ADDR + 'h408);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK1HI           = ADDR_W'(BASE_ADDR + 'h410);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH1HI          = ADDR_W'(BASE_ADDR + 'h418);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK2HI           = ADDR_W'(BASE_ADDR + 'h420);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH2HI          = ADDR_W'(BASE_ADDR + 'h428);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK3HI           = ADDR_W'(BASE_ADDR + 'h430);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH3HI          = ADDR_W'(BASE_ADDR + 'h438);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGMUXSELHI                = ADDR_W'(BASE_ADDR + 'h440);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONMASKHI        = ADDR_W'(BASE_ADDR + 'h448);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONFROMVALUEHI        = ADDR_W'(BASE_ADDR + 'h450);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONTOVALUEHI        = ADDR_W'(BASE_ADDR + 'h458);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTMASKHI         = ADDR_W'(BASE_ADDR + 'h460);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGANYCHANGEHI             = ADDR_W'(BASE_ADDR + 'h468);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI        = ADDR_W'(BASE_ADDR + 'h470);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI        = ADDR_W'(BASE_ADDR + 'h478);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI        = ADDR_W'(BASE_ADDR + 'h480);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI        = ADDR_W'(BASE_ADDR + 'h488);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI        = ADDR_W'(BASE_ADDR + 'h490);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI        = ADDR_W'(BASE_ADDR + 'h498);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI        = ADDR_W'(BASE_ADDR + 'h4A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI        = ADDR_W'(BASE_ADDR + 'h4A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI        = ADDR_W'(BASE_ADDR + 'h4B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI        = ADDR_W'(BASE_ADDR + 'h4B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI        = ADDR_W'(BASE_ADDR + 'h4C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI        = ADDR_W'(BASE_ADDR + 'h4C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI        = ADDR_W'(BASE_ADDR + 'h4D0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI        = ADDR_W'(BASE_ADDR + 'h4D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI        = ADDR_W'(BASE_ADDR + 'h4E0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI        = ADDR_W'(BASE_ADDR + 'h4E8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGLFSR                    = ADDR_W'(BASE_ADDR + 'h4F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGLFSRMASK                = ADDR_W'(BASE_ADDR + 'h4F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTIMESTAMPCAPTURE        = ADDR_W'(BASE_ADDR + 'h500);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0LO              = ADDR_W'(BASE_ADDR + 'h508);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0MASKLO          = ADDR_W'(BASE_ADDR + 'h510);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1LO              = ADDR_W'(BASE_ADDR + 'h518);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1MASKLO          = ADDR_W'(BASE_ADDR + 'h520);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2LO              = ADDR_W'(BASE_ADDR + 'h528);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2MASKLO          = ADDR_W'(BASE_ADDR + 'h530);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3LO              = ADDR_W'(BASE_ADDR + 'h538);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3MASKLO          = ADDR_W'(BASE_ADDR + 'h540);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0HI              = ADDR_W'(BASE_ADDR + 'h548);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0MASKHI          = ADDR_W'(BASE_ADDR + 'h550);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1HI              = ADDR_W'(BASE_ADDR + 'h558);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1MASKHI          = ADDR_W'(BASE_ADDR + 'h560);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2HI              = ADDR_W'(BASE_ADDR + 'h568);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2MASKHI          = ADDR_W'(BASE_ADDR + 'h570);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3HI              = ADDR_W'(BASE_ADDR + 'h578);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3MASKHI          = ADDR_W'(BASE_ADDR + 'h580);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGVERSION                 = ADDR_W'(BASE_ADDR + 'hFF0);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCH                     = ADDR_W'(BASE_ADDR + 'hFF8);

always_comb begin : mmr_hit_rd_comb
    if (enctype == ENC) begin : mmr_hit_rd_enc
        unique case (MMR_ADDR)

        ADDR_MMR_CDBGCLACOUNTER0CFG             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER1CFG             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER2CFG             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER3CFG             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP0                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP1                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP0                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP1                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP0                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP1                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP0                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP1                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK0LO              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH0LO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK1LO              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH1LO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALEDGEDETECTCFG           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGEAPSTATUS                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLACTRLSTATUS              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGMUXSELLO                   : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGRSVD1                      : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGRSVD2                      : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONMASKLO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONFROMVALUELO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONTOVALUELO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTMASKLO            : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTVALUE             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGANYCHANGELO                : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMEMATCH               : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK2LO              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH2LO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK3LO              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH3LO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP2                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP3                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP2                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP3                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP2                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP3                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP2                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP3                  : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALDELAYMUXSEL           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMP               : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPSYNC           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPCONFIG           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPOFFSET           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK0HI              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH0HI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK1HI              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH1HI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK2HI              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH2HI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK3HI              : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH3HI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGMUXSELHI                   : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONMASKHI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONFROMVALUEHI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONTOVALUEHI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTMASKHI            : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGANYCHANGEHI                : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGLFSR                       : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGLFSRMASK                   : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGTIMESTAMPCAPTURE           : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0LO                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0MASKLO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1LO                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1MASKLO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2LO                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2MASKLO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3LO                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3MASKLO             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0HI                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0MASKHI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1HI                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1MASKHI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2HI                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2MASKHI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3HI                 : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3MASKHI             : reg_rd_hit = 1'b1;
        ADDR_MMR_CDBGVERSION                    : reg_rd_hit = 1'b1;
        ADDR_MMR_SCRATCH                        : reg_rd_hit = 1'b1;

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

        ADDR_MMR_CDBGCLACOUNTER0CFG             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER1CFG             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER2CFG             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLACOUNTER3CFG             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP0                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP1                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP0                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP1                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP0                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP1                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP0                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP1                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK0LO              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH0LO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK1LO              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH1LO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALEDGEDETECTCFG           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGEAPSTATUS                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLACTRLSTATUS              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGMUXSELLO                   : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGRSVD1                      : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGRSVD2                      : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONMASKLO           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONFROMVALUELO           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONTOVALUELO           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTMASKLO            : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTVALUE             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGANYCHANGELO                : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGCLATIMEMATCH               : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK2LO              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH2LO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK3LO              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH3LO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP2                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE0EAP3                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP2                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE1EAP3                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP2                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE2EAP3                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP2                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGNODE3EAP3                  : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALDELAYMUXSEL           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMP               : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPSYNC           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPCONFIG           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCLATIMESTAMPOFFSET           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK0HI              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH0HI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK1HI              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH1HI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK2HI              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH2HI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMASK3HI              : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALMATCH3HI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGMUXSELHI                   : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONMASKHI           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONFROMVALUEHI           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTRANSITIONTOVALUEHI           : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGONESCOUNTMASKHI            : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGANYCHANGEHI                : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGLFSR                       : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGLFSRMASK                   : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGTIMESTAMPCAPTURE           : reg_wr_hit = 1'b0;
        ADDR_MMR_CDBGCOMPARE0LO                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0MASKLO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1LO                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1MASKLO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2LO                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2MASKLO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3LO                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3MASKLO             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0HI                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE0MASKHI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1HI                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE1MASKHI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2HI                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE2MASKHI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3HI                 : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGCOMPARE3MASKHI             : reg_wr_hit = 1'b1;
        ADDR_MMR_CDBGVERSION                    : reg_wr_hit = 1'b0;
        ADDR_MMR_SCRATCH                        : reg_wr_hit = 1'b1;

        default:  begin : mmr_hit_wr_default
            reg_wr_hit     = 0;
        end
        endcase
    end else begin : mmr_hit_wr_not_enc
        reg_wr_hit      = 1;
    end
end
endmodule
