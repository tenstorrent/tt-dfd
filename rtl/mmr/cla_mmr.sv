// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module cla_mmr
import cla_mmr_pkg::*;
`include "cla_mmr_pkg_list.svh"
`include "generic_macro_assertion.vh"
#(
    parameter BASE_ADDR    = 0,
    parameter ADDR_W       = 12,
    parameter ADDR_W_INDIR = 64,
    parameter FLOP_IN_REQ  = 1,
    parameter FLOP_RD_DATA = 1,
    parameter INSTR_TYPE_W = 2

) (

input  logic                                    clk,
input  logic                                    reset_n,
input  logic                                    reset_n_warm_ovrride,
input  logic                                    reset_n_warm_ovrride_hi,

input  logic                                    MmrCs,
input  logic                                    MmrWrEn,
input  logic                        [1:0]       MmrWrStrb,
input  logic                                    MmrRegSel,
input  logic                       [ADDR_W-1:0] MmrAddr,
input  logic                             [63:0] MmrWrData,
input  logic                 [INSTR_TYPE_W-1:0] MmrWrInstrType,
output logic                                    MmrWrReady,
output logic                                    MmrHit,
output ClaMmrHit_s                              MmrHitList,
output logic                             [63:0] MmrRdData,

output ClaCdbgclacounter0CfgMmr_s               ClaMmrCdbgclacounter0Cfg,
output ClaCdbgclacounter1CfgMmr_s               ClaMmrCdbgclacounter1Cfg,
output ClaCdbgclacounter2CfgMmr_s               ClaMmrCdbgclacounter2Cfg,
output ClaCdbgclacounter3CfgMmr_s               ClaMmrCdbgclacounter3Cfg,
output ClaCdbgnode0Eap0Mmr_s                    ClaMmrCdbgnode0Eap0,
output ClaCdbgnode0Eap1Mmr_s                    ClaMmrCdbgnode0Eap1,
output ClaCdbgnode1Eap0Mmr_s                    ClaMmrCdbgnode1Eap0,
output ClaCdbgnode1Eap1Mmr_s                    ClaMmrCdbgnode1Eap1,
output ClaCdbgnode2Eap0Mmr_s                    ClaMmrCdbgnode2Eap0,
output ClaCdbgnode2Eap1Mmr_s                    ClaMmrCdbgnode2Eap1,
output ClaCdbgnode3Eap0Mmr_s                    ClaMmrCdbgnode3Eap0,
output ClaCdbgnode3Eap1Mmr_s                    ClaMmrCdbgnode3Eap1,
output ClaCdbgsignalmask0LoMmr_s                ClaMmrCdbgsignalmask0Lo,
output ClaCdbgsignalmatch0LoMmr_s               ClaMmrCdbgsignalmatch0Lo,
output ClaCdbgsignalmask1LoMmr_s                ClaMmrCdbgsignalmask1Lo,
output ClaCdbgsignalmatch1LoMmr_s               ClaMmrCdbgsignalmatch1Lo,
output ClaCdbgsignaledgedetectcfgMmr_s          ClaMmrCdbgsignaledgedetectcfg,
output ClaCdbgeapstatusMmr_s                    ClaMmrCdbgeapstatus,
output ClaCdbgclactrlstatusMmr_s                ClaMmrCdbgclactrlstatus,
output ClaCdbgmuxselloMmr_s                     ClaMmrCdbgmuxsello,
output ClaCdbgrsvd1Mmr_s                        ClaMmrCdbgrsvd1,
output ClaCdbgrsvd2Mmr_s                        ClaMmrCdbgrsvd2,
output ClaCdbgtransitionmaskloMmr_s             ClaMmrCdbgtransitionmasklo,
output ClaCdbgtransitionfromvalueloMmr_s        ClaMmrCdbgtransitionfromvaluelo,
output ClaCdbgtransitiontovalueloMmr_s          ClaMmrCdbgtransitiontovaluelo,
output ClaCdbgonescountmaskloMmr_s              ClaMmrCdbgonescountmasklo,
output ClaCdbgonescountvalueMmr_s               ClaMmrCdbgonescountvalue,
output ClaCdbganychangeloMmr_s                  ClaMmrCdbganychangelo,
output ClaCdbgsignalsnapshotnode0Eap0LoMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap0Lo,
output ClaCdbgsignalsnapshotnode0Eap1LoMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap1Lo,
output ClaCdbgsignalsnapshotnode1Eap0LoMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap0Lo,
output ClaCdbgsignalsnapshotnode1Eap1LoMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap1Lo,
output ClaCdbgsignalsnapshotnode2Eap0LoMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap0Lo,
output ClaCdbgsignalsnapshotnode2Eap1LoMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap1Lo,
output ClaCdbgsignalsnapshotnode3Eap0LoMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap0Lo,
output ClaCdbgsignalsnapshotnode3Eap1LoMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap1Lo,
output ClaCdbgclatimematchMmr_s                 ClaMmrCdbgclatimematch,
output ClaCdbgsignalmask2LoMmr_s                ClaMmrCdbgsignalmask2Lo,
output ClaCdbgsignalmatch2LoMmr_s               ClaMmrCdbgsignalmatch2Lo,
output ClaCdbgsignalmask3LoMmr_s                ClaMmrCdbgsignalmask3Lo,
output ClaCdbgsignalmatch3LoMmr_s               ClaMmrCdbgsignalmatch3Lo,
output ClaCdbgnode0Eap2Mmr_s                    ClaMmrCdbgnode0Eap2,
output ClaCdbgnode0Eap3Mmr_s                    ClaMmrCdbgnode0Eap3,
output ClaCdbgnode1Eap2Mmr_s                    ClaMmrCdbgnode1Eap2,
output ClaCdbgnode1Eap3Mmr_s                    ClaMmrCdbgnode1Eap3,
output ClaCdbgnode2Eap2Mmr_s                    ClaMmrCdbgnode2Eap2,
output ClaCdbgnode2Eap3Mmr_s                    ClaMmrCdbgnode2Eap3,
output ClaCdbgnode3Eap2Mmr_s                    ClaMmrCdbgnode3Eap2,
output ClaCdbgnode3Eap3Mmr_s                    ClaMmrCdbgnode3Eap3,
output ClaCdbgsignalsnapshotnode0Eap2LoMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap2Lo,
output ClaCdbgsignalsnapshotnode0Eap3LoMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap3Lo,
output ClaCdbgsignalsnapshotnode1Eap2LoMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap2Lo,
output ClaCdbgsignalsnapshotnode1Eap3LoMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap3Lo,
output ClaCdbgsignalsnapshotnode2Eap2LoMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap2Lo,
output ClaCdbgsignalsnapshotnode2Eap3LoMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap3Lo,
output ClaCdbgsignalsnapshotnode3Eap2LoMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap2Lo,
output ClaCdbgsignalsnapshotnode3Eap3LoMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap3Lo,
output ClaCdbgsignaldelaymuxselMmr_s            ClaMmrCdbgsignaldelaymuxsel,
output ClaCdbgclaxtriggertimestretchMmr_s       ClaMmrCdbgclaxtriggertimestretch,
output ClaCdbgclatimestampMmr_s                 ClaMmrCdbgclatimestamp,
output ClaCdbgclatimestampsyncMmr_s             ClaMmrCdbgclatimestampsync,
output ClaCdbgclatimestampconfigMmr_s           ClaMmrCdbgclatimestampconfig,
output ClaCdbgclatimestampoffsetMmr_s           ClaMmrCdbgclatimestampoffset,
output ClaCdbgsignalmask0HiMmr_s                ClaMmrCdbgsignalmask0Hi,
output ClaCdbgsignalmatch0HiMmr_s               ClaMmrCdbgsignalmatch0Hi,
output ClaCdbgsignalmask1HiMmr_s                ClaMmrCdbgsignalmask1Hi,
output ClaCdbgsignalmatch1HiMmr_s               ClaMmrCdbgsignalmatch1Hi,
output ClaCdbgsignalmask2HiMmr_s                ClaMmrCdbgsignalmask2Hi,
output ClaCdbgsignalmatch2HiMmr_s               ClaMmrCdbgsignalmatch2Hi,
output ClaCdbgsignalmask3HiMmr_s                ClaMmrCdbgsignalmask3Hi,
output ClaCdbgsignalmatch3HiMmr_s               ClaMmrCdbgsignalmatch3Hi,
output ClaCdbgmuxselhiMmr_s                     ClaMmrCdbgmuxselhi,
output ClaCdbgtransitionmaskhiMmr_s             ClaMmrCdbgtransitionmaskhi,
output ClaCdbgtransitionfromvaluehiMmr_s        ClaMmrCdbgtransitionfromvaluehi,
output ClaCdbgtransitiontovaluehiMmr_s          ClaMmrCdbgtransitiontovaluehi,
output ClaCdbgonescountmaskhiMmr_s              ClaMmrCdbgonescountmaskhi,
output ClaCdbganychangehiMmr_s                  ClaMmrCdbganychangehi,
output ClaCdbgsignalsnapshotnode0Eap0HiMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap0Hi,
output ClaCdbgsignalsnapshotnode0Eap1HiMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap1Hi,
output ClaCdbgsignalsnapshotnode1Eap0HiMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap0Hi,
output ClaCdbgsignalsnapshotnode1Eap1HiMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap1Hi,
output ClaCdbgsignalsnapshotnode2Eap0HiMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap0Hi,
output ClaCdbgsignalsnapshotnode2Eap1HiMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap1Hi,
output ClaCdbgsignalsnapshotnode3Eap0HiMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap0Hi,
output ClaCdbgsignalsnapshotnode3Eap1HiMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap1Hi,
output ClaCdbgsignalsnapshotnode0Eap2HiMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap2Hi,
output ClaCdbgsignalsnapshotnode0Eap3HiMmr_s    ClaMmrCdbgsignalsnapshotnode0Eap3Hi,
output ClaCdbgsignalsnapshotnode1Eap2HiMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap2Hi,
output ClaCdbgsignalsnapshotnode1Eap3HiMmr_s    ClaMmrCdbgsignalsnapshotnode1Eap3Hi,
output ClaCdbgsignalsnapshotnode2Eap2HiMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap2Hi,
output ClaCdbgsignalsnapshotnode2Eap3HiMmr_s    ClaMmrCdbgsignalsnapshotnode2Eap3Hi,
output ClaCdbgsignalsnapshotnode3Eap2HiMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap2Hi,
output ClaCdbgsignalsnapshotnode3Eap3HiMmr_s    ClaMmrCdbgsignalsnapshotnode3Eap3Hi,
output ClaCdbglfsrMmr_s                         ClaMmrCdbglfsr,
output ClaCdbglfsrmaskMmr_s                     ClaMmrCdbglfsrmask,
output ClaCdbgtimestampcaptureMmr_s             ClaMmrCdbgtimestampcapture,
output ClaCdbgcompare0LoMmr_s                   ClaMmrCdbgcompare0Lo,
output ClaCdbgcompare0MaskloMmr_s               ClaMmrCdbgcompare0Masklo,
output ClaCdbgcompare1LoMmr_s                   ClaMmrCdbgcompare1Lo,
output ClaCdbgcompare1MaskloMmr_s               ClaMmrCdbgcompare1Masklo,
output ClaCdbgcompare2LoMmr_s                   ClaMmrCdbgcompare2Lo,
output ClaCdbgcompare2MaskloMmr_s               ClaMmrCdbgcompare2Masklo,
output ClaCdbgcompare3LoMmr_s                   ClaMmrCdbgcompare3Lo,
output ClaCdbgcompare3MaskloMmr_s               ClaMmrCdbgcompare3Masklo,
output ClaCdbgcompare0HiMmr_s                   ClaMmrCdbgcompare0Hi,
output ClaCdbgcompare0MaskhiMmr_s               ClaMmrCdbgcompare0Maskhi,
output ClaCdbgcompare1HiMmr_s                   ClaMmrCdbgcompare1Hi,
output ClaCdbgcompare1MaskhiMmr_s               ClaMmrCdbgcompare1Maskhi,
output ClaCdbgcompare2HiMmr_s                   ClaMmrCdbgcompare2Hi,
output ClaCdbgcompare2MaskhiMmr_s               ClaMmrCdbgcompare2Maskhi,
output ClaCdbgcompare3HiMmr_s                   ClaMmrCdbgcompare3Hi,
output ClaCdbgcompare3MaskhiMmr_s               ClaMmrCdbgcompare3Maskhi,
output ClaCdbgversionMmr_s                      ClaMmrCdbgversion,
output ClaScratchMmr_s                          ClaMmrScratch,

input ClaCdbgclacounter0CfgMmrWr_s              ClaMmrCdbgclacounter0CfgWr,
input ClaCdbgclacounter1CfgMmrWr_s              ClaMmrCdbgclacounter1CfgWr,
input ClaCdbgclacounter2CfgMmrWr_s              ClaMmrCdbgclacounter2CfgWr,
input ClaCdbgclacounter3CfgMmrWr_s              ClaMmrCdbgclacounter3CfgWr,
input ClaCdbgeapstatusMmrWr_s                   ClaMmrCdbgeapstatusWr,
input ClaCdbgclactrlstatusMmrWr_s               ClaMmrCdbgclactrlstatusWr,
input ClaCdbgmuxselloMmrWr_s                    ClaMmrCdbgmuxselloWr,
input ClaCdbgsignalsnapshotnode0Eap0LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap0LoWr,
input ClaCdbgsignalsnapshotnode0Eap1LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap1LoWr,
input ClaCdbgsignalsnapshotnode1Eap0LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap0LoWr,
input ClaCdbgsignalsnapshotnode1Eap1LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap1LoWr,
input ClaCdbgsignalsnapshotnode2Eap0LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap0LoWr,
input ClaCdbgsignalsnapshotnode2Eap1LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap1LoWr,
input ClaCdbgsignalsnapshotnode3Eap0LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap0LoWr,
input ClaCdbgsignalsnapshotnode3Eap1LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap1LoWr,
input ClaCdbgsignalsnapshotnode0Eap2LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap2LoWr,
input ClaCdbgsignalsnapshotnode0Eap3LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap3LoWr,
input ClaCdbgsignalsnapshotnode1Eap2LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap2LoWr,
input ClaCdbgsignalsnapshotnode1Eap3LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap3LoWr,
input ClaCdbgsignalsnapshotnode2Eap2LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap2LoWr,
input ClaCdbgsignalsnapshotnode2Eap3LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap3LoWr,
input ClaCdbgsignalsnapshotnode3Eap2LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap2LoWr,
input ClaCdbgsignalsnapshotnode3Eap3LoMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap3LoWr,
input ClaCdbgclatimestampMmrWr_s                ClaMmrCdbgclatimestampWr,
input ClaCdbgclatimestampconfigMmrWr_s          ClaMmrCdbgclatimestampconfigWr,
input ClaCdbgsignalsnapshotnode0Eap0HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap0HiWr,
input ClaCdbgsignalsnapshotnode0Eap1HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap1HiWr,
input ClaCdbgsignalsnapshotnode1Eap0HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap0HiWr,
input ClaCdbgsignalsnapshotnode1Eap1HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap1HiWr,
input ClaCdbgsignalsnapshotnode2Eap0HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap0HiWr,
input ClaCdbgsignalsnapshotnode2Eap1HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap1HiWr,
input ClaCdbgsignalsnapshotnode3Eap0HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap0HiWr,
input ClaCdbgsignalsnapshotnode3Eap1HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap1HiWr,
input ClaCdbgsignalsnapshotnode0Eap2HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap2HiWr,
input ClaCdbgsignalsnapshotnode0Eap3HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode0Eap3HiWr,
input ClaCdbgsignalsnapshotnode1Eap2HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap2HiWr,
input ClaCdbgsignalsnapshotnode1Eap3HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode1Eap3HiWr,
input ClaCdbgsignalsnapshotnode2Eap2HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap2HiWr,
input ClaCdbgsignalsnapshotnode2Eap3HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode2Eap3HiWr,
input ClaCdbgsignalsnapshotnode3Eap2HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap2HiWr,
input ClaCdbgsignalsnapshotnode3Eap3HiMmrWr_s   ClaMmrCdbgsignalsnapshotnode3Eap3HiWr,
input ClaCdbglfsrMmrWr_s                        ClaMmrCdbglfsrWr,
input ClaCdbgtimestampcaptureMmrWr_s            ClaMmrCdbgtimestampcaptureWr,

output logic                                    MmrUpdateEn,
output logic                       [ADDR_W-1:0] MmrUpdateAddr,
output logic                       [ADDR_W_INDIR-1:0] MmrUpdateIndirAddr,
output logic                             [63:0] MmrUpdateData

);

localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER0CFG    = ADDR_W'(BASE_ADDR + 'h100);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER1CFG    = ADDR_W'(BASE_ADDR + 'h108);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER2CFG    = ADDR_W'(BASE_ADDR + 'h110);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACOUNTER3CFG    = ADDR_W'(BASE_ADDR + 'h118);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP0         = ADDR_W'(BASE_ADDR + 'h120);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP1         = ADDR_W'(BASE_ADDR + 'h128);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP0         = ADDR_W'(BASE_ADDR + 'h130);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP1         = ADDR_W'(BASE_ADDR + 'h138);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP0         = ADDR_W'(BASE_ADDR + 'h140);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP1         = ADDR_W'(BASE_ADDR + 'h148);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP0         = ADDR_W'(BASE_ADDR + 'h150);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP1         = ADDR_W'(BASE_ADDR + 'h158);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK0LO     = ADDR_W'(BASE_ADDR + 'h160);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH0LO    = ADDR_W'(BASE_ADDR + 'h168);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK1LO     = ADDR_W'(BASE_ADDR + 'h170);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH1LO    = ADDR_W'(BASE_ADDR + 'h178);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALEDGEDETECTCFG = ADDR_W'(BASE_ADDR + 'h180);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGEAPSTATUS         = ADDR_W'(BASE_ADDR + 'h188);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLACTRLSTATUS     = ADDR_W'(BASE_ADDR + 'h190);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGMUXSELLO          = ADDR_W'(BASE_ADDR + 'h198);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGRSVD1             = ADDR_W'(BASE_ADDR + 'h1A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGRSVD2             = ADDR_W'(BASE_ADDR + 'h1A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONMASKLO  = ADDR_W'(BASE_ADDR + 'h1B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONFROMVALUELO = ADDR_W'(BASE_ADDR + 'h1B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONTOVALUELO = ADDR_W'(BASE_ADDR + 'h1C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTMASKLO   = ADDR_W'(BASE_ADDR + 'h1C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTVALUE    = ADDR_W'(BASE_ADDR + 'h1D0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGANYCHANGELO       = ADDR_W'(BASE_ADDR + 'h1D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO = ADDR_W'(BASE_ADDR + 'h1E0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO = ADDR_W'(BASE_ADDR + 'h1E8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO = ADDR_W'(BASE_ADDR + 'h1F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO = ADDR_W'(BASE_ADDR + 'h1F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO = ADDR_W'(BASE_ADDR + 'h200);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO = ADDR_W'(BASE_ADDR + 'h208);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO = ADDR_W'(BASE_ADDR + 'h210);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO = ADDR_W'(BASE_ADDR + 'h218);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMEMATCH      = ADDR_W'(BASE_ADDR + 'h220);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK2LO     = ADDR_W'(BASE_ADDR + 'h228);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH2LO    = ADDR_W'(BASE_ADDR + 'h230);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK3LO     = ADDR_W'(BASE_ADDR + 'h238);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH3LO    = ADDR_W'(BASE_ADDR + 'h240);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP2         = ADDR_W'(BASE_ADDR + 'h248);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE0EAP3         = ADDR_W'(BASE_ADDR + 'h250);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP2         = ADDR_W'(BASE_ADDR + 'h258);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE1EAP3         = ADDR_W'(BASE_ADDR + 'h260);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP2         = ADDR_W'(BASE_ADDR + 'h268);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE2EAP3         = ADDR_W'(BASE_ADDR + 'h270);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP2         = ADDR_W'(BASE_ADDR + 'h278);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNODE3EAP3         = ADDR_W'(BASE_ADDR + 'h280);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO = ADDR_W'(BASE_ADDR + 'h288);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO = ADDR_W'(BASE_ADDR + 'h290);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO = ADDR_W'(BASE_ADDR + 'h298);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO = ADDR_W'(BASE_ADDR + 'h2A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO = ADDR_W'(BASE_ADDR + 'h2A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO = ADDR_W'(BASE_ADDR + 'h2B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO = ADDR_W'(BASE_ADDR + 'h2B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO = ADDR_W'(BASE_ADDR + 'h2C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALDELAYMUXSEL = ADDR_W'(BASE_ADDR + 'h2C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH = ADDR_W'(BASE_ADDR + 'h2D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMP      = ADDR_W'(BASE_ADDR + 'h2F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPSYNC  = ADDR_W'(BASE_ADDR + 'h2F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPCONFIG = ADDR_W'(BASE_ADDR + 'h300);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCLATIMESTAMPOFFSET = ADDR_W'(BASE_ADDR + 'h308);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK0HI     = ADDR_W'(BASE_ADDR + 'h400);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH0HI    = ADDR_W'(BASE_ADDR + 'h408);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK1HI     = ADDR_W'(BASE_ADDR + 'h410);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH1HI    = ADDR_W'(BASE_ADDR + 'h418);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK2HI     = ADDR_W'(BASE_ADDR + 'h420);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH2HI    = ADDR_W'(BASE_ADDR + 'h428);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMASK3HI     = ADDR_W'(BASE_ADDR + 'h430);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALMATCH3HI    = ADDR_W'(BASE_ADDR + 'h438);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGMUXSELHI          = ADDR_W'(BASE_ADDR + 'h440);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONMASKHI  = ADDR_W'(BASE_ADDR + 'h448);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONFROMVALUEHI = ADDR_W'(BASE_ADDR + 'h450);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTRANSITIONTOVALUEHI = ADDR_W'(BASE_ADDR + 'h458);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGONESCOUNTMASKHI   = ADDR_W'(BASE_ADDR + 'h460);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGANYCHANGEHI       = ADDR_W'(BASE_ADDR + 'h468);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI = ADDR_W'(BASE_ADDR + 'h470);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI = ADDR_W'(BASE_ADDR + 'h478);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI = ADDR_W'(BASE_ADDR + 'h480);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI = ADDR_W'(BASE_ADDR + 'h488);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI = ADDR_W'(BASE_ADDR + 'h490);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI = ADDR_W'(BASE_ADDR + 'h498);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI = ADDR_W'(BASE_ADDR + 'h4A0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI = ADDR_W'(BASE_ADDR + 'h4A8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI = ADDR_W'(BASE_ADDR + 'h4B0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI = ADDR_W'(BASE_ADDR + 'h4B8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI = ADDR_W'(BASE_ADDR + 'h4C0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI = ADDR_W'(BASE_ADDR + 'h4C8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI = ADDR_W'(BASE_ADDR + 'h4D0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI = ADDR_W'(BASE_ADDR + 'h4D8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI = ADDR_W'(BASE_ADDR + 'h4E0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI = ADDR_W'(BASE_ADDR + 'h4E8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGLFSR              = ADDR_W'(BASE_ADDR + 'h4F0);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGLFSRMASK          = ADDR_W'(BASE_ADDR + 'h4F8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGTIMESTAMPCAPTURE  = ADDR_W'(BASE_ADDR + 'h500);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0LO        = ADDR_W'(BASE_ADDR + 'h508);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0MASKLO    = ADDR_W'(BASE_ADDR + 'h510);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1LO        = ADDR_W'(BASE_ADDR + 'h518);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1MASKLO    = ADDR_W'(BASE_ADDR + 'h520);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2LO        = ADDR_W'(BASE_ADDR + 'h528);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2MASKLO    = ADDR_W'(BASE_ADDR + 'h530);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3LO        = ADDR_W'(BASE_ADDR + 'h538);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3MASKLO    = ADDR_W'(BASE_ADDR + 'h540);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0HI        = ADDR_W'(BASE_ADDR + 'h548);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE0MASKHI    = ADDR_W'(BASE_ADDR + 'h550);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1HI        = ADDR_W'(BASE_ADDR + 'h558);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE1MASKHI    = ADDR_W'(BASE_ADDR + 'h560);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2HI        = ADDR_W'(BASE_ADDR + 'h568);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE2MASKHI    = ADDR_W'(BASE_ADDR + 'h570);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3HI        = ADDR_W'(BASE_ADDR + 'h578);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGCOMPARE3MASKHI    = ADDR_W'(BASE_ADDR + 'h580);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGVERSION           = ADDR_W'(BASE_ADDR + 'hFF0);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCH               = ADDR_W'(BASE_ADDR + 'hFF8);

logic                       reg_cs;
logic                       reg_wr_en;
logic           [1:0]       reg_wr_strb;
logic          [ADDR_W-1:0] reg_addr;
logic                       reg_wr_sel;
logic                       reg_rd_sel;
logic                [63:0] reg_wr_data;
logic    [INSTR_TYPE_W-1:0] reg_wr_instr_type;

logic                       reg_wr_ready;
ClaMmrHit_s                 reg_prehit;
logic                       reg_hit;
logic                [63:0] reg_rd_data;

logic                       reg_write;
logic                       reg_read;

logic          [ADDR_W-1:0] reg_addr_d1;
logic          [ADDR_W_INDIR-1:0] reg_addr_select_d1;
logic                       reg_write_d1;
logic                       reg_hit_d1;
logic                [63:0] reg_rd_data_d1;

logic                [63:0] MMR_CDbgClaCounter0Cfg;
logic                [63:0] MMR_CDbgClaCounter1Cfg;
logic                [63:0] MMR_CDbgClaCounter2Cfg;
logic                [63:0] MMR_CDbgClaCounter3Cfg;
logic                [63:0] MMR_CDbgNode0Eap0;
logic                [63:0] MMR_CDbgNode0Eap1;
logic                [63:0] MMR_CDbgNode1Eap0;
logic                [63:0] MMR_CDbgNode1Eap1;
logic                [63:0] MMR_CDbgNode2Eap0;
logic                [63:0] MMR_CDbgNode2Eap1;
logic                [63:0] MMR_CDbgNode3Eap0;
logic                [63:0] MMR_CDbgNode3Eap1;
logic                [63:0] MMR_CDbgSignalMask0Lo;
logic                [63:0] MMR_CDbgSignalMatch0Lo;
logic                [63:0] MMR_CDbgSignalMask1Lo;
logic                [63:0] MMR_CDbgSignalMatch1Lo;
logic                [63:0] MMR_CDbgSignalEdgeDetectCfg;
logic                [63:0] MMR_CDbgEapStatus;
logic                [63:0] MMR_CDbgClaCtrlStatus;
logic                [63:0] MMR_CDbgMuxSelLo;
logic                [63:0] MMR_CDbgRsvd1;
logic                [63:0] MMR_CDbgRsvd2;
logic                [63:0] MMR_CDbgTransitionMaskLo;
logic                [63:0] MMR_CDbgTransitionFromValueLo;
logic                [63:0] MMR_CDbgTransitionToValueLo;
logic                [63:0] MMR_CDbgOnesCountMaskLo;
logic                [63:0] MMR_CDbgOnesCountValue;
logic                [63:0] MMR_CDbgAnyChangeLo;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap0Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap1Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap0Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap1Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap0Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap1Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap0Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap1Lo;
logic                [63:0] MMR_CDbgClaTimeMatch;
logic                [63:0] MMR_CDbgSignalMask2Lo;
logic                [63:0] MMR_CDbgSignalMatch2Lo;
logic                [63:0] MMR_CDbgSignalMask3Lo;
logic                [63:0] MMR_CDbgSignalMatch3Lo;
logic                [63:0] MMR_CDbgNode0Eap2;
logic                [63:0] MMR_CDbgNode0Eap3;
logic                [63:0] MMR_CDbgNode1Eap2;
logic                [63:0] MMR_CDbgNode1Eap3;
logic                [63:0] MMR_CDbgNode2Eap2;
logic                [63:0] MMR_CDbgNode2Eap3;
logic                [63:0] MMR_CDbgNode3Eap2;
logic                [63:0] MMR_CDbgNode3Eap3;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap2Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap3Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap2Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap3Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap2Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap3Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap2Lo;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap3Lo;
logic                [63:0] MMR_CDbgSignalDelayMuxSel;
logic                [63:0] MMR_CDbgClaXtriggerTimestretch;
logic                [63:0] MMR_CDbgClaTimestamp;
logic                [63:0] MMR_CDbgClaTimestampSync;
logic                [63:0] MMR_CDbgClaTimestampConfig;
logic                [63:0] MMR_CDbgClaTimestampOffset;
logic                [63:0] MMR_CDbgSignalMask0Hi;
logic                [63:0] MMR_CDbgSignalMatch0Hi;
logic                [63:0] MMR_CDbgSignalMask1Hi;
logic                [63:0] MMR_CDbgSignalMatch1Hi;
logic                [63:0] MMR_CDbgSignalMask2Hi;
logic                [63:0] MMR_CDbgSignalMatch2Hi;
logic                [63:0] MMR_CDbgSignalMask3Hi;
logic                [63:0] MMR_CDbgSignalMatch3Hi;
logic                [63:0] MMR_CDbgMuxSelHi;
logic                [63:0] MMR_CDbgTransitionMaskHi;
logic                [63:0] MMR_CDbgTransitionFromValueHi;
logic                [63:0] MMR_CDbgTransitionToValueHi;
logic                [63:0] MMR_CDbgOnesCountMaskHi;
logic                [63:0] MMR_CDbgAnyChangeHi;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap0Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap1Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap0Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap1Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap0Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap1Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap0Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap1Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap2Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap3Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap2Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap3Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap2Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap3Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap2Hi;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap3Hi;
logic                [63:0] MMR_CDbgLfsr;
logic                [63:0] MMR_CDbgLfsrMask;
logic                [63:0] MMR_CDbgTimestampCapture;
logic                [63:0] MMR_CDbgCompare0Lo;
logic                [63:0] MMR_CDbgCompare0MaskLo;
logic                [63:0] MMR_CDbgCompare1Lo;
logic                [63:0] MMR_CDbgCompare1MaskLo;
logic                [63:0] MMR_CDbgCompare2Lo;
logic                [63:0] MMR_CDbgCompare2MaskLo;
logic                [63:0] MMR_CDbgCompare3Lo;
logic                [63:0] MMR_CDbgCompare3MaskLo;
logic                [63:0] MMR_CDbgCompare0Hi;
logic                [63:0] MMR_CDbgCompare0MaskHi;
logic                [63:0] MMR_CDbgCompare1Hi;
logic                [63:0] MMR_CDbgCompare1MaskHi;
logic                [63:0] MMR_CDbgCompare2Hi;
logic                [63:0] MMR_CDbgCompare2MaskHi;
logic                [63:0] MMR_CDbgCompare3Hi;
logic                [63:0] MMR_CDbgCompare3MaskHi;
logic                [63:0] MMR_CDbgVersion;
logic                [63:0] MMR_Scratch;

logic                 [0:0] MMR_CDbgClaCounter0Cfg_F_Rsvd;
logic                [14:0] MMR_CDbgClaCounter0Cfg_F_UpperTarget;
logic                [14:0] MMR_CDbgClaCounter0Cfg_F_UpperCounter;
logic                 [0:0] MMR_CDbgClaCounter0Cfg_F_ResetOnTarget;
logic                [15:0] MMR_CDbgClaCounter0Cfg_F_Target;
logic                [15:0] MMR_CDbgClaCounter0Cfg_F_Counter;
logic                 [0:0] MMR_CDbgClaCounter1Cfg_F_Rsvd;
logic                [14:0] MMR_CDbgClaCounter1Cfg_F_UpperTarget;
logic                [14:0] MMR_CDbgClaCounter1Cfg_F_UpperCounter;
logic                 [0:0] MMR_CDbgClaCounter1Cfg_F_ResetOnTarget;
logic                [15:0] MMR_CDbgClaCounter1Cfg_F_Target;
logic                [15:0] MMR_CDbgClaCounter1Cfg_F_Counter;
logic                 [0:0] MMR_CDbgClaCounter2Cfg_F_Rsvd;
logic                [14:0] MMR_CDbgClaCounter2Cfg_F_UpperTarget;
logic                [14:0] MMR_CDbgClaCounter2Cfg_F_UpperCounter;
logic                 [0:0] MMR_CDbgClaCounter2Cfg_F_ResetOnTarget;
logic                [15:0] MMR_CDbgClaCounter2Cfg_F_Target;
logic                [15:0] MMR_CDbgClaCounter2Cfg_F_Counter;
logic                 [0:0] MMR_CDbgClaCounter3Cfg_F_Rsvd;
logic                [14:0] MMR_CDbgClaCounter3Cfg_F_UpperTarget;
logic                [14:0] MMR_CDbgClaCounter3Cfg_F_UpperCounter;
logic                 [0:0] MMR_CDbgClaCounter3Cfg_F_ResetOnTarget;
logic                [15:0] MMR_CDbgClaCounter3Cfg_F_Target;
logic                [15:0] MMR_CDbgClaCounter3Cfg_F_Counter;
logic                 [5:0] MMR_CDbgNode0Eap0_F_Action3;
logic                 [5:0] MMR_CDbgNode0Eap0_F_Action2;
logic                 [7:0] MMR_CDbgNode0Eap0_F_Udf;
logic                 [5:0] MMR_CDbgNode0Eap0_F_EventType2;
logic                 [0:0] MMR_CDbgNode0Eap0_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode0Eap0_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode0Eap0_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode0Eap0_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode0Eap0_F_EventType1;
logic                 [5:0] MMR_CDbgNode0Eap0_F_EventType0;
logic                 [1:0] MMR_CDbgNode0Eap0_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode0Eap0_F_Action1;
logic                 [5:0] MMR_CDbgNode0Eap0_F_Action0;
logic                 [1:0] MMR_CDbgNode0Eap0_F_DestNode;
logic                 [5:0] MMR_CDbgNode0Eap1_F_Action3;
logic                 [5:0] MMR_CDbgNode0Eap1_F_Action2;
logic                 [7:0] MMR_CDbgNode0Eap1_F_Udf;
logic                 [5:0] MMR_CDbgNode0Eap1_F_EventType2;
logic                 [0:0] MMR_CDbgNode0Eap1_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode0Eap1_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode0Eap1_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode0Eap1_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode0Eap1_F_EventType1;
logic                 [5:0] MMR_CDbgNode0Eap1_F_EventType0;
logic                 [1:0] MMR_CDbgNode0Eap1_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode0Eap1_F_Action1;
logic                 [5:0] MMR_CDbgNode0Eap1_F_Action0;
logic                 [1:0] MMR_CDbgNode0Eap1_F_DestNode;
logic                 [5:0] MMR_CDbgNode1Eap0_F_Action3;
logic                 [5:0] MMR_CDbgNode1Eap0_F_Action2;
logic                 [7:0] MMR_CDbgNode1Eap0_F_Udf;
logic                 [5:0] MMR_CDbgNode1Eap0_F_EventType2;
logic                 [0:0] MMR_CDbgNode1Eap0_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode1Eap0_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode1Eap0_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode1Eap0_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode1Eap0_F_EventType1;
logic                 [5:0] MMR_CDbgNode1Eap0_F_EventType0;
logic                 [1:0] MMR_CDbgNode1Eap0_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode1Eap0_F_Action1;
logic                 [5:0] MMR_CDbgNode1Eap0_F_Action0;
logic                 [1:0] MMR_CDbgNode1Eap0_F_DestNode;
logic                 [5:0] MMR_CDbgNode1Eap1_F_Action3;
logic                 [5:0] MMR_CDbgNode1Eap1_F_Action2;
logic                 [7:0] MMR_CDbgNode1Eap1_F_Udf;
logic                 [5:0] MMR_CDbgNode1Eap1_F_EventType2;
logic                 [0:0] MMR_CDbgNode1Eap1_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode1Eap1_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode1Eap1_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode1Eap1_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode1Eap1_F_EventType1;
logic                 [5:0] MMR_CDbgNode1Eap1_F_EventType0;
logic                 [1:0] MMR_CDbgNode1Eap1_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode1Eap1_F_Action1;
logic                 [5:0] MMR_CDbgNode1Eap1_F_Action0;
logic                 [1:0] MMR_CDbgNode1Eap1_F_DestNode;
logic                 [5:0] MMR_CDbgNode2Eap0_F_Action3;
logic                 [5:0] MMR_CDbgNode2Eap0_F_Action2;
logic                 [7:0] MMR_CDbgNode2Eap0_F_Udf;
logic                 [5:0] MMR_CDbgNode2Eap0_F_EventType2;
logic                 [0:0] MMR_CDbgNode2Eap0_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode2Eap0_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode2Eap0_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode2Eap0_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode2Eap0_F_EventType1;
logic                 [5:0] MMR_CDbgNode2Eap0_F_EventType0;
logic                 [1:0] MMR_CDbgNode2Eap0_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode2Eap0_F_Action1;
logic                 [5:0] MMR_CDbgNode2Eap0_F_Action0;
logic                 [1:0] MMR_CDbgNode2Eap0_F_DestNode;
logic                 [5:0] MMR_CDbgNode2Eap1_F_Action3;
logic                 [5:0] MMR_CDbgNode2Eap1_F_Action2;
logic                 [7:0] MMR_CDbgNode2Eap1_F_Udf;
logic                 [5:0] MMR_CDbgNode2Eap1_F_EventType2;
logic                 [0:0] MMR_CDbgNode2Eap1_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode2Eap1_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode2Eap1_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode2Eap1_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode2Eap1_F_EventType1;
logic                 [5:0] MMR_CDbgNode2Eap1_F_EventType0;
logic                 [1:0] MMR_CDbgNode2Eap1_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode2Eap1_F_Action1;
logic                 [5:0] MMR_CDbgNode2Eap1_F_Action0;
logic                 [1:0] MMR_CDbgNode2Eap1_F_DestNode;
logic                 [5:0] MMR_CDbgNode3Eap0_F_Action3;
logic                 [5:0] MMR_CDbgNode3Eap0_F_Action2;
logic                 [7:0] MMR_CDbgNode3Eap0_F_Udf;
logic                 [5:0] MMR_CDbgNode3Eap0_F_EventType2;
logic                 [0:0] MMR_CDbgNode3Eap0_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode3Eap0_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode3Eap0_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode3Eap0_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode3Eap0_F_EventType1;
logic                 [5:0] MMR_CDbgNode3Eap0_F_EventType0;
logic                 [1:0] MMR_CDbgNode3Eap0_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode3Eap0_F_Action1;
logic                 [5:0] MMR_CDbgNode3Eap0_F_Action0;
logic                 [1:0] MMR_CDbgNode3Eap0_F_DestNode;
logic                 [5:0] MMR_CDbgNode3Eap1_F_Action3;
logic                 [5:0] MMR_CDbgNode3Eap1_F_Action2;
logic                 [7:0] MMR_CDbgNode3Eap1_F_Udf;
logic                 [5:0] MMR_CDbgNode3Eap1_F_EventType2;
logic                 [0:0] MMR_CDbgNode3Eap1_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode3Eap1_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode3Eap1_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode3Eap1_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode3Eap1_F_EventType1;
logic                 [5:0] MMR_CDbgNode3Eap1_F_EventType0;
logic                 [1:0] MMR_CDbgNode3Eap1_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode3Eap1_F_Action1;
logic                 [5:0] MMR_CDbgNode3Eap1_F_Action0;
logic                 [1:0] MMR_CDbgNode3Eap1_F_DestNode;
logic                [63:0] MMR_CDbgSignalMask0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMatch0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMask1Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMatch1Lo_F_Value;
logic                 [0:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1;
logic                 [6:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select;
logic                 [0:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0;
logic                 [6:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap3W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap2W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap1W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap0W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap3W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap2W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap1W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap0W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap3W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap2W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap1W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap0W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap3W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap2W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap1W2C;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap0W2C;
logic                [15:0] MMR_CDbgEapStatus_F_Rsvd3116;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap3;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap2;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap1;
logic                 [0:0] MMR_CDbgEapStatus_F_Node3Eap0;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap3;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap2;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap1;
logic                 [0:0] MMR_CDbgEapStatus_F_Node2Eap0;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap3;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap2;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap1;
logic                 [0:0] MMR_CDbgEapStatus_F_Node1Eap0;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap3;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap2;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap1;
logic                 [0:0] MMR_CDbgEapStatus_F_Node0Eap0;
logic                 [0:0] MMR_CDbgClaCtrlStatus_F_ClaLock;
logic                [46:0] MMR_CDbgClaCtrlStatus_F_Rsvd6216;
logic                 [0:0] MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt;
logic                 [0:0] MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt;
logic                 [6:0] MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay;
logic                 [0:0] MMR_CDbgClaCtrlStatus_F_EnableCla;
logic                 [0:0] MMR_CDbgClaCtrlStatus_F_EnableEap;
logic                 [1:0] MMR_CDbgClaCtrlStatus_F_CurrentNode;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg7;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg6;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg5;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg4;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg3;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg2;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg1;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Muxselseg0;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Rsvd1510;
logic                 [0:0] MMR_CDbgMuxSelLo_F_Valid;
logic                 [0:0] MMR_CDbgMuxSelLo_F_Finegraintime;
logic                 [5:0] MMR_CDbgMuxSelLo_F_Dbmid;
logic                 [1:0] MMR_CDbgMuxSelLo_F_Dbmmode;
logic                [63:0] MMR_CDbgRsvd1_F_Value;
logic                [63:0] MMR_CDbgRsvd2_F_Value;
logic                [63:0] MMR_CDbgTransitionMaskLo_F_Value;
logic                [63:0] MMR_CDbgTransitionFromValueLo_F_Value;
logic                [63:0] MMR_CDbgTransitionToValueLo_F_Value;
logic                [63:0] MMR_CDbgOnesCountMaskLo_F_Value;
logic                [63:0] MMR_CDbgOnesCountValue_F_Value;
logic                [63:0] MMR_CDbgAnyChangeLo_F_Mask;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value;
logic                [63:0] MMR_CDbgClaTimeMatch_F_TimeMatchVal;
logic                [63:0] MMR_CDbgSignalMask2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMatch2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMask3Lo_F_Value;
logic                [63:0] MMR_CDbgSignalMatch3Lo_F_Value;
logic                 [5:0] MMR_CDbgNode0Eap2_F_Action3;
logic                 [5:0] MMR_CDbgNode0Eap2_F_Action2;
logic                 [7:0] MMR_CDbgNode0Eap2_F_Udf;
logic                 [5:0] MMR_CDbgNode0Eap2_F_EventType2;
logic                 [0:0] MMR_CDbgNode0Eap2_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode0Eap2_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode0Eap2_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode0Eap2_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode0Eap2_F_EventType1;
logic                 [5:0] MMR_CDbgNode0Eap2_F_EventType0;
logic                 [1:0] MMR_CDbgNode0Eap2_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode0Eap2_F_Action1;
logic                 [5:0] MMR_CDbgNode0Eap2_F_Action0;
logic                 [1:0] MMR_CDbgNode0Eap2_F_DestNode;
logic                 [5:0] MMR_CDbgNode0Eap3_F_Action3;
logic                 [5:0] MMR_CDbgNode0Eap3_F_Action2;
logic                 [7:0] MMR_CDbgNode0Eap3_F_Udf;
logic                 [5:0] MMR_CDbgNode0Eap3_F_EventType2;
logic                 [0:0] MMR_CDbgNode0Eap3_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode0Eap3_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode0Eap3_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode0Eap3_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode0Eap3_F_EventType1;
logic                 [5:0] MMR_CDbgNode0Eap3_F_EventType0;
logic                 [1:0] MMR_CDbgNode0Eap3_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode0Eap3_F_Action1;
logic                 [5:0] MMR_CDbgNode0Eap3_F_Action0;
logic                 [1:0] MMR_CDbgNode0Eap3_F_DestNode;
logic                 [5:0] MMR_CDbgNode1Eap2_F_Action3;
logic                 [5:0] MMR_CDbgNode1Eap2_F_Action2;
logic                 [7:0] MMR_CDbgNode1Eap2_F_Udf;
logic                 [5:0] MMR_CDbgNode1Eap2_F_EventType2;
logic                 [0:0] MMR_CDbgNode1Eap2_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode1Eap2_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode1Eap2_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode1Eap2_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode1Eap2_F_EventType1;
logic                 [5:0] MMR_CDbgNode1Eap2_F_EventType0;
logic                 [1:0] MMR_CDbgNode1Eap2_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode1Eap2_F_Action1;
logic                 [5:0] MMR_CDbgNode1Eap2_F_Action0;
logic                 [1:0] MMR_CDbgNode1Eap2_F_DestNode;
logic                 [5:0] MMR_CDbgNode1Eap3_F_Action3;
logic                 [5:0] MMR_CDbgNode1Eap3_F_Action2;
logic                 [7:0] MMR_CDbgNode1Eap3_F_Udf;
logic                 [5:0] MMR_CDbgNode1Eap3_F_EventType2;
logic                 [0:0] MMR_CDbgNode1Eap3_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode1Eap3_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode1Eap3_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode1Eap3_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode1Eap3_F_EventType1;
logic                 [5:0] MMR_CDbgNode1Eap3_F_EventType0;
logic                 [1:0] MMR_CDbgNode1Eap3_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode1Eap3_F_Action1;
logic                 [5:0] MMR_CDbgNode1Eap3_F_Action0;
logic                 [1:0] MMR_CDbgNode1Eap3_F_DestNode;
logic                 [5:0] MMR_CDbgNode2Eap2_F_Action3;
logic                 [5:0] MMR_CDbgNode2Eap2_F_Action2;
logic                 [7:0] MMR_CDbgNode2Eap2_F_Udf;
logic                 [5:0] MMR_CDbgNode2Eap2_F_EventType2;
logic                 [0:0] MMR_CDbgNode2Eap2_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode2Eap2_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode2Eap2_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode2Eap2_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode2Eap2_F_EventType1;
logic                 [5:0] MMR_CDbgNode2Eap2_F_EventType0;
logic                 [1:0] MMR_CDbgNode2Eap2_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode2Eap2_F_Action1;
logic                 [5:0] MMR_CDbgNode2Eap2_F_Action0;
logic                 [1:0] MMR_CDbgNode2Eap2_F_DestNode;
logic                 [5:0] MMR_CDbgNode2Eap3_F_Action3;
logic                 [5:0] MMR_CDbgNode2Eap3_F_Action2;
logic                 [7:0] MMR_CDbgNode2Eap3_F_Udf;
logic                 [5:0] MMR_CDbgNode2Eap3_F_EventType2;
logic                 [0:0] MMR_CDbgNode2Eap3_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode2Eap3_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode2Eap3_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode2Eap3_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode2Eap3_F_EventType1;
logic                 [5:0] MMR_CDbgNode2Eap3_F_EventType0;
logic                 [1:0] MMR_CDbgNode2Eap3_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode2Eap3_F_Action1;
logic                 [5:0] MMR_CDbgNode2Eap3_F_Action0;
logic                 [1:0] MMR_CDbgNode2Eap3_F_DestNode;
logic                 [5:0] MMR_CDbgNode3Eap2_F_Action3;
logic                 [5:0] MMR_CDbgNode3Eap2_F_Action2;
logic                 [7:0] MMR_CDbgNode3Eap2_F_Udf;
logic                 [5:0] MMR_CDbgNode3Eap2_F_EventType2;
logic                 [0:0] MMR_CDbgNode3Eap2_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode3Eap2_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode3Eap2_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode3Eap2_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode3Eap2_F_EventType1;
logic                 [5:0] MMR_CDbgNode3Eap2_F_EventType0;
logic                 [1:0] MMR_CDbgNode3Eap2_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode3Eap2_F_Action1;
logic                 [5:0] MMR_CDbgNode3Eap2_F_Action0;
logic                 [1:0] MMR_CDbgNode3Eap2_F_DestNode;
logic                 [5:0] MMR_CDbgNode3Eap3_F_Action3;
logic                 [5:0] MMR_CDbgNode3Eap3_F_Action2;
logic                 [7:0] MMR_CDbgNode3Eap3_F_Udf;
logic                 [5:0] MMR_CDbgNode3Eap3_F_EventType2;
logic                 [0:0] MMR_CDbgNode3Eap3_F_CustomAction1Enable;
logic                 [0:0] MMR_CDbgNode3Eap3_F_CustomAction0Enable;
logic                 [3:0] MMR_CDbgNode3Eap3_F_CustomAction1;
logic                 [3:0] MMR_CDbgNode3Eap3_F_CustomAction0;
logic                 [5:0] MMR_CDbgNode3Eap3_F_EventType1;
logic                 [5:0] MMR_CDbgNode3Eap3_F_EventType0;
logic                 [1:0] MMR_CDbgNode3Eap3_F_LogicalOp;
logic                 [5:0] MMR_CDbgNode3Eap3_F_Action1;
logic                 [5:0] MMR_CDbgNode3Eap3_F_Action0;
logic                 [1:0] MMR_CDbgNode3Eap3_F_DestNode;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value;
logic                [31:0] MMR_CDbgSignalDelayMuxSel_F_Rsvd;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg15;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg14;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg13;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg12;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg11;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg10;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg9;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg8;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg7;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg6;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg5;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg4;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg3;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg2;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg1;
logic                 [1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg0;
logic                [47:0] MMR_CDbgClaXtriggerTimestretch_F_Rsvd;
logic                 [7:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch;
logic                 [7:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch;
logic                [55:0] MMR_CDbgClaTimestamp_F_TimestampUpper;
logic                 [7:0] MMR_CDbgClaTimestamp_F_TimestampLower;
logic                [63:0] MMR_CDbgClaTimestampSync_F_TimestampSync;
logic                [53:0] MMR_CDbgClaTimestampConfig_F_Rsvd1;
logic                 [0:0] MMR_CDbgClaTimestampConfig_F_TsCapture;
logic                 [7:0] MMR_CDbgClaTimestampConfig_F_DebugMarker;
logic                 [0:0] MMR_CDbgClaTimestampConfig_F_Resync;
logic                 [7:0] MMR_CDbgClaTimestampOffset_F_Rsvd0;
logic                [55:0] MMR_CDbgClaTimestampOffset_F_Offset;
logic                [63:0] MMR_CDbgSignalMask0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMatch0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMask1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMatch1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMask2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMatch2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMask3Hi_F_Value;
logic                [63:0] MMR_CDbgSignalMatch3Hi_F_Value;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg15;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg14;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg13;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg12;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg11;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg10;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg9;
logic                 [5:0] MMR_CDbgMuxSelHi_F_Muxselseg8;
logic                [15:0] MMR_CDbgMuxSelHi_F_Rsvd150;
logic                [63:0] MMR_CDbgTransitionMaskHi_F_Value;
logic                [63:0] MMR_CDbgTransitionFromValueHi_F_Value;
logic                [63:0] MMR_CDbgTransitionToValueHi_F_Value;
logic                [63:0] MMR_CDbgOnesCountMaskHi_F_Value;
logic                [63:0] MMR_CDbgAnyChangeHi_F_Mask;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value;
logic                [63:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value;
logic                [62:0] MMR_CDbgLfsr_F_Lfsr;
logic                 [0:0] MMR_CDbgLfsr_F_LfsrActive;
logic                [62:0] MMR_CDbgLfsrMask_F_Mask;
logic                 [0:0] MMR_CDbgLfsrMask_F_Rsvd0;
logic                [63:0] MMR_CDbgTimestampCapture_F_Timestamp;
logic                [63:0] MMR_CDbgCompare0Lo_F_Value;
logic                [63:0] MMR_CDbgCompare0MaskLo_F_Value;
logic                [63:0] MMR_CDbgCompare1Lo_F_Value;
logic                [63:0] MMR_CDbgCompare1MaskLo_F_Value;
logic                [63:0] MMR_CDbgCompare2Lo_F_Value;
logic                [63:0] MMR_CDbgCompare2MaskLo_F_Value;
logic                [63:0] MMR_CDbgCompare3Lo_F_Value;
logic                [63:0] MMR_CDbgCompare3MaskLo_F_Value;
logic                [63:0] MMR_CDbgCompare0Hi_F_Value;
logic                [63:0] MMR_CDbgCompare0MaskHi_F_Value;
logic                [63:0] MMR_CDbgCompare1Hi_F_Value;
logic                [63:0] MMR_CDbgCompare1MaskHi_F_Value;
logic                [63:0] MMR_CDbgCompare2Hi_F_Value;
logic                [63:0] MMR_CDbgCompare2MaskHi_F_Value;
logic                [63:0] MMR_CDbgCompare3Hi_F_Value;
logic                [63:0] MMR_CDbgCompare3MaskHi_F_Value;
logic                [51:0] MMR_CDbgVersion_F_Rsvd6312;
logic                 [3:0] MMR_CDbgVersion_F_Major;
logic                 [3:0] MMR_CDbgVersion_F_Minor;
logic                 [3:0] MMR_CDbgVersion_F_Patch;
logic                [63:0] MMR_Scratch_F_Data;

if (FLOP_IN_REQ) begin : flop_in_req
    generic_dff #(
        .WIDTH ($bits(logic)),
        .RESET_VALUE (0)
    ) reg_cs_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs|reg_cs),
        .in (MmrCs),
        .out (reg_cs)
    );
    generic_dff #(
        .WIDTH ($bits(logic)),
        .RESET_VALUE (0)
    ) reg_wr_en_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrWrEn),
        .out (reg_wr_en)
    );
    generic_dff #(
        .WIDTH ($bits(logic [1:0])),
        .RESET_VALUE (0)
    ) reg_wr_strb_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrWrStrb),
        .out (reg_wr_strb)
    );
    generic_dff #(
        .WIDTH ($bits(logic [ADDR_W-1:0])),
        .RESET_VALUE (0)
    ) reg_addr_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrAddr),
        .out (reg_addr)
    );
    generic_dff #(
        .WIDTH ($bits(logic [64-1:0])),
        .RESET_VALUE (0)
    ) reg_wr_data_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrWrData),
        .out (reg_wr_data)
    );
    generic_dff #(
        .WIDTH ($bits(logic [INSTR_TYPE_W-1:0])),
        .RESET_VALUE (0)
    ) reg_wr_instr_type_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrWrInstrType),
        .out (reg_wr_instr_type)
    );
    generic_dff #(
        .WIDTH ($bits(logic)),
        .RESET_VALUE (0)
    ) reg_wr_ready_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (MmrCs),
        .in (MmrCs & MmrWrEn),
        .out (reg_wr_ready)
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) reg_rd_sel_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (MmrCs),
        .in    (~MmrRegSel),
        .out   (reg_rd_sel)
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) reg_wr_sel_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (MmrCs),
        .in    (MmrRegSel),
        .out   (reg_wr_sel)
    );
end else begin : no_flop_in_req
    assign reg_cs                          = MmrCs;
    assign reg_wr_en                       = MmrWrEn;
    assign reg_wr_strb                     = MmrWrStrb;
    assign reg_addr                        = MmrAddr;
    assign reg_wr_data                     = MmrWrData;
    assign reg_wr_instr_type               = MmrWrInstrType;
    assign reg_wr_ready                    = MmrCs & MmrWrEn;
    assign reg_rd_sel                      = ~MmrRegSel;
    assign reg_wr_sel                      = MmrRegSel;
end

assign reg_write    = reg_cs &  reg_wr_en;
assign reg_read     = reg_cs;

generic_dff #(
    .WIDTH ($bits(logic [ADDR_W-1:0])),
    .RESET_VALUE (0)
) reg_addr_d1_ff (
    .clk (clk),
    .rst_n (reset_n),
    .en (reg_cs),
    .in (reg_addr),
    .out (reg_addr_d1)
);
generic_dff #(
    .WIDTH ($bits(logic)),
    .RESET_VALUE (0)
) reg_wren_d1_ff (
    .clk (clk),
    .rst_n (reset_n),
    .en (reg_cs | reg_write_d1),
    .in (reg_write),
    .out (reg_write_d1)
);

assign MMR_CDbgClaCounter0Cfg_F_Rsvd = 1'h0;

logic                                           MMR_CDbgClaCounter0Cfg_F_UpperTarget_WrEn;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperTarget_DataEff;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_prev;
assign MMR_CDbgClaCounter0Cfg_F_UpperTarget_DataEff = {reg_wr_data[62:48]};
assign MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data = (CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter0Cfg_F_UpperTarget), 64'(MMR_CDbgClaCounter0Cfg_F_UpperTarget_DataEff[14:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter0Cfg_F_UpperTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG))));
assign MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_prev = MMR_CDbgClaCounter0Cfg_F_UpperTarget;
assign MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_muxed = MMR_CDbgClaCounter0Cfg_F_UpperTarget_WrEn ? MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data : MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER0CFG_UPPERTARGET_WIDTH'(0))
) MMR_CDbgClaCounter0Cfg_F_UpperTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter0Cfg_F_UpperTarget_WrEn),
    .in    (MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data),
    .out   (MMR_CDbgClaCounter0Cfg_F_UpperTarget)
);

logic                                           MMR_CDbgClaCounter0Cfg_F_UpperCounter_WrEn;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperCounter_DataEff;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_muxed;
logic [CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_prev;
assign MMR_CDbgClaCounter0Cfg_F_UpperCounter_DataEff = {reg_wr_data[47:33]};
assign MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG)) ? CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter0Cfg_F_UpperCounter), 64'(MMR_CDbgClaCounter0Cfg_F_UpperCounter_DataEff[14:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter0CfgWr.Data.UpperCounter);
assign MMR_CDbgClaCounter0Cfg_F_UpperCounter_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG)) | ClaMmrCdbgclacounter0CfgWr.UpperCounterWrEn));
assign MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_prev = MMR_CDbgClaCounter0Cfg_F_UpperCounter;
assign MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_muxed = MMR_CDbgClaCounter0Cfg_F_UpperCounter_WrEn ? MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data : MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER0CFG_UPPERCOUNTER_WIDTH'(0))
) MMR_CDbgClaCounter0Cfg_F_UpperCounter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter0Cfg_F_UpperCounter_WrEn),
    .in    (MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data),
    .out   (MMR_CDbgClaCounter0Cfg_F_UpperCounter)
);

logic                                           MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_WrEn;
logic [CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data;
logic [CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_DataEff;
logic [CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_prev;
assign MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_DataEff = {reg_wr_data[32:32]};
assign MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data = (CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter0Cfg_F_ResetOnTarget), 64'(MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG))));
assign MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_prev = MMR_CDbgClaCounter0Cfg_F_ResetOnTarget;
assign MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_muxed = MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_WrEn ? MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data : MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER0CFG_RESETONTARGET_WIDTH'(0))
) MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_WrEn),
    .in    (MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data),
    .out   (MMR_CDbgClaCounter0Cfg_F_ResetOnTarget)
);

logic                                           MMR_CDbgClaCounter0Cfg_F_Target_WrEn;
logic [CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Target_Data;
logic [CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Target_DataEff;
logic [CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Target_Data_muxed;
logic [CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Target_Data_prev;
assign MMR_CDbgClaCounter0Cfg_F_Target_DataEff = {reg_wr_data[31:16]};
assign MMR_CDbgClaCounter0Cfg_F_Target_Data = (CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter0Cfg_F_Target), 64'(MMR_CDbgClaCounter0Cfg_F_Target_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter0Cfg_F_Target_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG))));
assign MMR_CDbgClaCounter0Cfg_F_Target_Data_prev = MMR_CDbgClaCounter0Cfg_F_Target;
assign MMR_CDbgClaCounter0Cfg_F_Target_Data_muxed = MMR_CDbgClaCounter0Cfg_F_Target_WrEn ? MMR_CDbgClaCounter0Cfg_F_Target_Data : MMR_CDbgClaCounter0Cfg_F_Target_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER0CFG_TARGET_WIDTH'(0))
) MMR_CDbgClaCounter0Cfg_F_Target_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter0Cfg_F_Target_WrEn),
    .in    (MMR_CDbgClaCounter0Cfg_F_Target_Data),
    .out   (MMR_CDbgClaCounter0Cfg_F_Target)
);

logic                                           MMR_CDbgClaCounter0Cfg_F_Counter_WrEn;
logic [CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Counter_Data;
logic [CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Counter_DataEff;
logic [CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Counter_Data_muxed;
logic [CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter0Cfg_F_Counter_Data_prev;
assign MMR_CDbgClaCounter0Cfg_F_Counter_DataEff = {reg_wr_data[15:0]};
assign MMR_CDbgClaCounter0Cfg_F_Counter_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG)) ? CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter0Cfg_F_Counter), 64'(MMR_CDbgClaCounter0Cfg_F_Counter_DataEff[15:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter0CfgWr.Data.Counter);
assign MMR_CDbgClaCounter0Cfg_F_Counter_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER0CFG)) | ClaMmrCdbgclacounter0CfgWr.CounterWrEn));
assign MMR_CDbgClaCounter0Cfg_F_Counter_Data_prev = MMR_CDbgClaCounter0Cfg_F_Counter;
assign MMR_CDbgClaCounter0Cfg_F_Counter_Data_muxed = MMR_CDbgClaCounter0Cfg_F_Counter_WrEn ? MMR_CDbgClaCounter0Cfg_F_Counter_Data : MMR_CDbgClaCounter0Cfg_F_Counter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER0CFG_COUNTER_WIDTH'(0))
) MMR_CDbgClaCounter0Cfg_F_Counter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter0Cfg_F_Counter_WrEn),
    .in    (MMR_CDbgClaCounter0Cfg_F_Counter_Data),
    .out   (MMR_CDbgClaCounter0Cfg_F_Counter)
);

assign MMR_CDbgClaCounter1Cfg_F_Rsvd = 1'h0;

logic                                           MMR_CDbgClaCounter1Cfg_F_UpperTarget_WrEn;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperTarget_DataEff;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_prev;
assign MMR_CDbgClaCounter1Cfg_F_UpperTarget_DataEff = {reg_wr_data[62:48]};
assign MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data = (CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter1Cfg_F_UpperTarget), 64'(MMR_CDbgClaCounter1Cfg_F_UpperTarget_DataEff[14:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter1Cfg_F_UpperTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG))));
assign MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_prev = MMR_CDbgClaCounter1Cfg_F_UpperTarget;
assign MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_muxed = MMR_CDbgClaCounter1Cfg_F_UpperTarget_WrEn ? MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data : MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER1CFG_UPPERTARGET_WIDTH'(0))
) MMR_CDbgClaCounter1Cfg_F_UpperTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter1Cfg_F_UpperTarget_WrEn),
    .in    (MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data),
    .out   (MMR_CDbgClaCounter1Cfg_F_UpperTarget)
);

logic                                           MMR_CDbgClaCounter1Cfg_F_UpperCounter_WrEn;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperCounter_DataEff;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_muxed;
logic [CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_prev;
assign MMR_CDbgClaCounter1Cfg_F_UpperCounter_DataEff = {reg_wr_data[47:33]};
assign MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG)) ? CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter1Cfg_F_UpperCounter), 64'(MMR_CDbgClaCounter1Cfg_F_UpperCounter_DataEff[14:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter1CfgWr.Data.UpperCounter);
assign MMR_CDbgClaCounter1Cfg_F_UpperCounter_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG)) | ClaMmrCdbgclacounter1CfgWr.UpperCounterWrEn));
assign MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_prev = MMR_CDbgClaCounter1Cfg_F_UpperCounter;
assign MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_muxed = MMR_CDbgClaCounter1Cfg_F_UpperCounter_WrEn ? MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data : MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER1CFG_UPPERCOUNTER_WIDTH'(0))
) MMR_CDbgClaCounter1Cfg_F_UpperCounter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter1Cfg_F_UpperCounter_WrEn),
    .in    (MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data),
    .out   (MMR_CDbgClaCounter1Cfg_F_UpperCounter)
);

logic                                           MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_WrEn;
logic [CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data;
logic [CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_DataEff;
logic [CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_prev;
assign MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_DataEff = {reg_wr_data[32:32]};
assign MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data = (CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter1Cfg_F_ResetOnTarget), 64'(MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG))));
assign MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_prev = MMR_CDbgClaCounter1Cfg_F_ResetOnTarget;
assign MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_muxed = MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_WrEn ? MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data : MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER1CFG_RESETONTARGET_WIDTH'(0))
) MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_WrEn),
    .in    (MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data),
    .out   (MMR_CDbgClaCounter1Cfg_F_ResetOnTarget)
);

logic                                           MMR_CDbgClaCounter1Cfg_F_Target_WrEn;
logic [CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Target_Data;
logic [CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Target_DataEff;
logic [CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Target_Data_muxed;
logic [CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Target_Data_prev;
assign MMR_CDbgClaCounter1Cfg_F_Target_DataEff = {reg_wr_data[31:16]};
assign MMR_CDbgClaCounter1Cfg_F_Target_Data = (CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter1Cfg_F_Target), 64'(MMR_CDbgClaCounter1Cfg_F_Target_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter1Cfg_F_Target_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG))));
assign MMR_CDbgClaCounter1Cfg_F_Target_Data_prev = MMR_CDbgClaCounter1Cfg_F_Target;
assign MMR_CDbgClaCounter1Cfg_F_Target_Data_muxed = MMR_CDbgClaCounter1Cfg_F_Target_WrEn ? MMR_CDbgClaCounter1Cfg_F_Target_Data : MMR_CDbgClaCounter1Cfg_F_Target_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER1CFG_TARGET_WIDTH'(0))
) MMR_CDbgClaCounter1Cfg_F_Target_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter1Cfg_F_Target_WrEn),
    .in    (MMR_CDbgClaCounter1Cfg_F_Target_Data),
    .out   (MMR_CDbgClaCounter1Cfg_F_Target)
);

logic                                           MMR_CDbgClaCounter1Cfg_F_Counter_WrEn;
logic [CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Counter_Data;
logic [CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Counter_DataEff;
logic [CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Counter_Data_muxed;
logic [CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter1Cfg_F_Counter_Data_prev;
assign MMR_CDbgClaCounter1Cfg_F_Counter_DataEff = {reg_wr_data[15:0]};
assign MMR_CDbgClaCounter1Cfg_F_Counter_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG)) ? CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter1Cfg_F_Counter), 64'(MMR_CDbgClaCounter1Cfg_F_Counter_DataEff[15:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter1CfgWr.Data.Counter);
assign MMR_CDbgClaCounter1Cfg_F_Counter_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER1CFG)) | ClaMmrCdbgclacounter1CfgWr.CounterWrEn));
assign MMR_CDbgClaCounter1Cfg_F_Counter_Data_prev = MMR_CDbgClaCounter1Cfg_F_Counter;
assign MMR_CDbgClaCounter1Cfg_F_Counter_Data_muxed = MMR_CDbgClaCounter1Cfg_F_Counter_WrEn ? MMR_CDbgClaCounter1Cfg_F_Counter_Data : MMR_CDbgClaCounter1Cfg_F_Counter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER1CFG_COUNTER_WIDTH'(0))
) MMR_CDbgClaCounter1Cfg_F_Counter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter1Cfg_F_Counter_WrEn),
    .in    (MMR_CDbgClaCounter1Cfg_F_Counter_Data),
    .out   (MMR_CDbgClaCounter1Cfg_F_Counter)
);

assign MMR_CDbgClaCounter2Cfg_F_Rsvd = 1'h0;

logic                                           MMR_CDbgClaCounter2Cfg_F_UpperTarget_WrEn;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperTarget_DataEff;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_prev;
assign MMR_CDbgClaCounter2Cfg_F_UpperTarget_DataEff = {reg_wr_data[62:48]};
assign MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data = (CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter2Cfg_F_UpperTarget), 64'(MMR_CDbgClaCounter2Cfg_F_UpperTarget_DataEff[14:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter2Cfg_F_UpperTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG))));
assign MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_prev = MMR_CDbgClaCounter2Cfg_F_UpperTarget;
assign MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_muxed = MMR_CDbgClaCounter2Cfg_F_UpperTarget_WrEn ? MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data : MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER2CFG_UPPERTARGET_WIDTH'(0))
) MMR_CDbgClaCounter2Cfg_F_UpperTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter2Cfg_F_UpperTarget_WrEn),
    .in    (MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data),
    .out   (MMR_CDbgClaCounter2Cfg_F_UpperTarget)
);

logic                                           MMR_CDbgClaCounter2Cfg_F_UpperCounter_WrEn;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperCounter_DataEff;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_muxed;
logic [CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_prev;
assign MMR_CDbgClaCounter2Cfg_F_UpperCounter_DataEff = {reg_wr_data[47:33]};
assign MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG)) ? CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter2Cfg_F_UpperCounter), 64'(MMR_CDbgClaCounter2Cfg_F_UpperCounter_DataEff[14:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter2CfgWr.Data.UpperCounter);
assign MMR_CDbgClaCounter2Cfg_F_UpperCounter_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG)) | ClaMmrCdbgclacounter2CfgWr.UpperCounterWrEn));
assign MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_prev = MMR_CDbgClaCounter2Cfg_F_UpperCounter;
assign MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_muxed = MMR_CDbgClaCounter2Cfg_F_UpperCounter_WrEn ? MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data : MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER2CFG_UPPERCOUNTER_WIDTH'(0))
) MMR_CDbgClaCounter2Cfg_F_UpperCounter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter2Cfg_F_UpperCounter_WrEn),
    .in    (MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data),
    .out   (MMR_CDbgClaCounter2Cfg_F_UpperCounter)
);

logic                                           MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_WrEn;
logic [CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data;
logic [CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_DataEff;
logic [CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_prev;
assign MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_DataEff = {reg_wr_data[32:32]};
assign MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data = (CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter2Cfg_F_ResetOnTarget), 64'(MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG))));
assign MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_prev = MMR_CDbgClaCounter2Cfg_F_ResetOnTarget;
assign MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_muxed = MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_WrEn ? MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data : MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER2CFG_RESETONTARGET_WIDTH'(0))
) MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_WrEn),
    .in    (MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data),
    .out   (MMR_CDbgClaCounter2Cfg_F_ResetOnTarget)
);

logic                                           MMR_CDbgClaCounter2Cfg_F_Target_WrEn;
logic [CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Target_Data;
logic [CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Target_DataEff;
logic [CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Target_Data_muxed;
logic [CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Target_Data_prev;
assign MMR_CDbgClaCounter2Cfg_F_Target_DataEff = {reg_wr_data[31:16]};
assign MMR_CDbgClaCounter2Cfg_F_Target_Data = (CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter2Cfg_F_Target), 64'(MMR_CDbgClaCounter2Cfg_F_Target_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter2Cfg_F_Target_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG))));
assign MMR_CDbgClaCounter2Cfg_F_Target_Data_prev = MMR_CDbgClaCounter2Cfg_F_Target;
assign MMR_CDbgClaCounter2Cfg_F_Target_Data_muxed = MMR_CDbgClaCounter2Cfg_F_Target_WrEn ? MMR_CDbgClaCounter2Cfg_F_Target_Data : MMR_CDbgClaCounter2Cfg_F_Target_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER2CFG_TARGET_WIDTH'(0))
) MMR_CDbgClaCounter2Cfg_F_Target_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter2Cfg_F_Target_WrEn),
    .in    (MMR_CDbgClaCounter2Cfg_F_Target_Data),
    .out   (MMR_CDbgClaCounter2Cfg_F_Target)
);

logic                                           MMR_CDbgClaCounter2Cfg_F_Counter_WrEn;
logic [CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Counter_Data;
logic [CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Counter_DataEff;
logic [CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Counter_Data_muxed;
logic [CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter2Cfg_F_Counter_Data_prev;
assign MMR_CDbgClaCounter2Cfg_F_Counter_DataEff = {reg_wr_data[15:0]};
assign MMR_CDbgClaCounter2Cfg_F_Counter_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG)) ? CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter2Cfg_F_Counter), 64'(MMR_CDbgClaCounter2Cfg_F_Counter_DataEff[15:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter2CfgWr.Data.Counter);
assign MMR_CDbgClaCounter2Cfg_F_Counter_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER2CFG)) | ClaMmrCdbgclacounter2CfgWr.CounterWrEn));
assign MMR_CDbgClaCounter2Cfg_F_Counter_Data_prev = MMR_CDbgClaCounter2Cfg_F_Counter;
assign MMR_CDbgClaCounter2Cfg_F_Counter_Data_muxed = MMR_CDbgClaCounter2Cfg_F_Counter_WrEn ? MMR_CDbgClaCounter2Cfg_F_Counter_Data : MMR_CDbgClaCounter2Cfg_F_Counter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER2CFG_COUNTER_WIDTH'(0))
) MMR_CDbgClaCounter2Cfg_F_Counter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter2Cfg_F_Counter_WrEn),
    .in    (MMR_CDbgClaCounter2Cfg_F_Counter_Data),
    .out   (MMR_CDbgClaCounter2Cfg_F_Counter)
);

assign MMR_CDbgClaCounter3Cfg_F_Rsvd = 1'h0;

logic                                           MMR_CDbgClaCounter3Cfg_F_UpperTarget_WrEn;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperTarget_DataEff;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_prev;
assign MMR_CDbgClaCounter3Cfg_F_UpperTarget_DataEff = {reg_wr_data[62:48]};
assign MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data = (CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter3Cfg_F_UpperTarget), 64'(MMR_CDbgClaCounter3Cfg_F_UpperTarget_DataEff[14:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter3Cfg_F_UpperTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG))));
assign MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_prev = MMR_CDbgClaCounter3Cfg_F_UpperTarget;
assign MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_muxed = MMR_CDbgClaCounter3Cfg_F_UpperTarget_WrEn ? MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data : MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER3CFG_UPPERTARGET_WIDTH'(0))
) MMR_CDbgClaCounter3Cfg_F_UpperTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter3Cfg_F_UpperTarget_WrEn),
    .in    (MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data),
    .out   (MMR_CDbgClaCounter3Cfg_F_UpperTarget)
);

logic                                           MMR_CDbgClaCounter3Cfg_F_UpperCounter_WrEn;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperCounter_DataEff;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_muxed;
logic [CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_prev;
assign MMR_CDbgClaCounter3Cfg_F_UpperCounter_DataEff = {reg_wr_data[47:33]};
assign MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG)) ? CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter3Cfg_F_UpperCounter), 64'(MMR_CDbgClaCounter3Cfg_F_UpperCounter_DataEff[14:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter3CfgWr.Data.UpperCounter);
assign MMR_CDbgClaCounter3Cfg_F_UpperCounter_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG)) | ClaMmrCdbgclacounter3CfgWr.UpperCounterWrEn));
assign MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_prev = MMR_CDbgClaCounter3Cfg_F_UpperCounter;
assign MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_muxed = MMR_CDbgClaCounter3Cfg_F_UpperCounter_WrEn ? MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data : MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER3CFG_UPPERCOUNTER_WIDTH'(0))
) MMR_CDbgClaCounter3Cfg_F_UpperCounter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter3Cfg_F_UpperCounter_WrEn),
    .in    (MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data),
    .out   (MMR_CDbgClaCounter3Cfg_F_UpperCounter)
);

logic                                           MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_WrEn;
logic [CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data;
logic [CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_DataEff;
logic [CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_muxed;
logic [CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_prev;
assign MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_DataEff = {reg_wr_data[32:32]};
assign MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data = (CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter3Cfg_F_ResetOnTarget), 64'(MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG))));
assign MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_prev = MMR_CDbgClaCounter3Cfg_F_ResetOnTarget;
assign MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_muxed = MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_WrEn ? MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data : MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER3CFG_RESETONTARGET_WIDTH'(0))
) MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_WrEn),
    .in    (MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data),
    .out   (MMR_CDbgClaCounter3Cfg_F_ResetOnTarget)
);

logic                                           MMR_CDbgClaCounter3Cfg_F_Target_WrEn;
logic [CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Target_Data;
logic [CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Target_DataEff;
logic [CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Target_Data_muxed;
logic [CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Target_Data_prev;
assign MMR_CDbgClaCounter3Cfg_F_Target_DataEff = {reg_wr_data[31:16]};
assign MMR_CDbgClaCounter3Cfg_F_Target_Data = (CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH'(update_value(64'(MMR_CDbgClaCounter3Cfg_F_Target), 64'(MMR_CDbgClaCounter3Cfg_F_Target_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCounter3Cfg_F_Target_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG))));
assign MMR_CDbgClaCounter3Cfg_F_Target_Data_prev = MMR_CDbgClaCounter3Cfg_F_Target;
assign MMR_CDbgClaCounter3Cfg_F_Target_Data_muxed = MMR_CDbgClaCounter3Cfg_F_Target_WrEn ? MMR_CDbgClaCounter3Cfg_F_Target_Data : MMR_CDbgClaCounter3Cfg_F_Target_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER3CFG_TARGET_WIDTH'(0))
) MMR_CDbgClaCounter3Cfg_F_Target_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter3Cfg_F_Target_WrEn),
    .in    (MMR_CDbgClaCounter3Cfg_F_Target_Data),
    .out   (MMR_CDbgClaCounter3Cfg_F_Target)
);

logic                                           MMR_CDbgClaCounter3Cfg_F_Counter_WrEn;
logic [CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Counter_Data;
logic [CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Counter_DataEff;
logic [CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Counter_Data_muxed;
logic [CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH-1:0] MMR_CDbgClaCounter3Cfg_F_Counter_Data_prev;
assign MMR_CDbgClaCounter3Cfg_F_Counter_DataEff = {reg_wr_data[15:0]};
assign MMR_CDbgClaCounter3Cfg_F_Counter_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG)) ? CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH'(update_value(64'(MMR_CDbgClaCounter3Cfg_F_Counter), 64'(MMR_CDbgClaCounter3Cfg_F_Counter_DataEff[15:0]), reg_wr_instr_type)) : ClaMmrCdbgclacounter3CfgWr.Data.Counter);
assign MMR_CDbgClaCounter3Cfg_F_Counter_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACOUNTER3CFG)) | ClaMmrCdbgclacounter3CfgWr.CounterWrEn));
assign MMR_CDbgClaCounter3Cfg_F_Counter_Data_prev = MMR_CDbgClaCounter3Cfg_F_Counter;
assign MMR_CDbgClaCounter3Cfg_F_Counter_Data_muxed = MMR_CDbgClaCounter3Cfg_F_Counter_WrEn ? MMR_CDbgClaCounter3Cfg_F_Counter_Data : MMR_CDbgClaCounter3Cfg_F_Counter_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACOUNTER3CFG_COUNTER_WIDTH'(0))
) MMR_CDbgClaCounter3Cfg_F_Counter_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCounter3Cfg_F_Counter_WrEn),
    .in    (MMR_CDbgClaCounter3Cfg_F_Counter_Data),
    .out   (MMR_CDbgClaCounter3Cfg_F_Counter)
);

logic                                           MMR_CDbgNode0Eap0_F_Action3_WrEn;
logic [CLA_CDBGNODE0EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action3_Data;
logic [CLA_CDBGNODE0EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action3_DataEff;
logic [CLA_CDBGNODE0EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action3_Data_muxed;
logic [CLA_CDBGNODE0EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action3_Data_prev;
assign MMR_CDbgNode0Eap0_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode0Eap0_F_Action3_Data = (CLA_CDBGNODE0EAP0_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_Action3), 64'(MMR_CDbgNode0Eap0_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_Action3_Data_prev = MMR_CDbgNode0Eap0_F_Action3;
assign MMR_CDbgNode0Eap0_F_Action3_Data_muxed = MMR_CDbgNode0Eap0_F_Action3_WrEn ? MMR_CDbgNode0Eap0_F_Action3_Data : MMR_CDbgNode0Eap0_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_ACTION3_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_Action3_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_Action3_Data),
    .out   (MMR_CDbgNode0Eap0_F_Action3)
);

logic                                           MMR_CDbgNode0Eap0_F_Action2_WrEn;
logic [CLA_CDBGNODE0EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action2_Data;
logic [CLA_CDBGNODE0EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action2_DataEff;
logic [CLA_CDBGNODE0EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action2_Data_muxed;
logic [CLA_CDBGNODE0EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action2_Data_prev;
assign MMR_CDbgNode0Eap0_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode0Eap0_F_Action2_Data = (CLA_CDBGNODE0EAP0_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_Action2), 64'(MMR_CDbgNode0Eap0_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_Action2_Data_prev = MMR_CDbgNode0Eap0_F_Action2;
assign MMR_CDbgNode0Eap0_F_Action2_Data_muxed = MMR_CDbgNode0Eap0_F_Action2_WrEn ? MMR_CDbgNode0Eap0_F_Action2_Data : MMR_CDbgNode0Eap0_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_ACTION2_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_Action2_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_Action2_Data),
    .out   (MMR_CDbgNode0Eap0_F_Action2)
);

logic                                           MMR_CDbgNode0Eap0_F_Udf_WrEn;
logic [CLA_CDBGNODE0EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap0_F_Udf_Data;
logic [CLA_CDBGNODE0EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap0_F_Udf_DataEff;
logic [CLA_CDBGNODE0EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap0_F_Udf_Data_muxed;
logic [CLA_CDBGNODE0EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap0_F_Udf_Data_prev;
assign MMR_CDbgNode0Eap0_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode0Eap0_F_Udf_Data = (CLA_CDBGNODE0EAP0_UDF_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_Udf), 64'(MMR_CDbgNode0Eap0_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_Udf_Data_prev = MMR_CDbgNode0Eap0_F_Udf;
assign MMR_CDbgNode0Eap0_F_Udf_Data_muxed = MMR_CDbgNode0Eap0_F_Udf_WrEn ? MMR_CDbgNode0Eap0_F_Udf_Data : MMR_CDbgNode0Eap0_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_UDF_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_Udf_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_Udf_Data),
    .out   (MMR_CDbgNode0Eap0_F_Udf)
);

logic                                           MMR_CDbgNode0Eap0_F_EventType2_WrEn;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType2_Data;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType2_DataEff;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType2_Data_prev;
assign MMR_CDbgNode0Eap0_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode0Eap0_F_EventType2_Data = (CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_EventType2), 64'(MMR_CDbgNode0Eap0_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_EventType2_Data_prev = MMR_CDbgNode0Eap0_F_EventType2;
assign MMR_CDbgNode0Eap0_F_EventType2_Data_muxed = MMR_CDbgNode0Eap0_F_EventType2_WrEn ? MMR_CDbgNode0Eap0_F_EventType2_Data : MMR_CDbgNode0Eap0_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_EventType2_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_EventType2_Data),
    .out   (MMR_CDbgNode0Eap0_F_EventType2)
);

logic                                           MMR_CDbgNode0Eap0_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode0Eap0_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data = (CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_CustomAction1Enable), 64'(MMR_CDbgNode0Eap0_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_prev = MMR_CDbgNode0Eap0_F_CustomAction1Enable;
assign MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode0Eap0_F_CustomAction1Enable_WrEn ? MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data : MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode0Eap0_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode0Eap0_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode0Eap0_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data = (CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_CustomAction0Enable), 64'(MMR_CDbgNode0Eap0_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_prev = MMR_CDbgNode0Eap0_F_CustomAction0Enable;
assign MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode0Eap0_F_CustomAction0Enable_WrEn ? MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data : MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode0Eap0_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode0Eap0_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1_Data;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction1_Data_prev;
assign MMR_CDbgNode0Eap0_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode0Eap0_F_CustomAction1_Data = (CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_CustomAction1), 64'(MMR_CDbgNode0Eap0_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_CustomAction1_Data_prev = MMR_CDbgNode0Eap0_F_CustomAction1;
assign MMR_CDbgNode0Eap0_F_CustomAction1_Data_muxed = MMR_CDbgNode0Eap0_F_CustomAction1_WrEn ? MMR_CDbgNode0Eap0_F_CustomAction1_Data : MMR_CDbgNode0Eap0_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_CustomAction1_Data),
    .out   (MMR_CDbgNode0Eap0_F_CustomAction1)
);

logic                                           MMR_CDbgNode0Eap0_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0_Data;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap0_F_CustomAction0_Data_prev;
assign MMR_CDbgNode0Eap0_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode0Eap0_F_CustomAction0_Data = (CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_CustomAction0), 64'(MMR_CDbgNode0Eap0_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_CustomAction0_Data_prev = MMR_CDbgNode0Eap0_F_CustomAction0;
assign MMR_CDbgNode0Eap0_F_CustomAction0_Data_muxed = MMR_CDbgNode0Eap0_F_CustomAction0_WrEn ? MMR_CDbgNode0Eap0_F_CustomAction0_Data : MMR_CDbgNode0Eap0_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_CustomAction0_Data),
    .out   (MMR_CDbgNode0Eap0_F_CustomAction0)
);

logic                                           MMR_CDbgNode0Eap0_F_EventType1_WrEn;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType1_Data;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType1_DataEff;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType1_Data_prev;
assign MMR_CDbgNode0Eap0_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode0Eap0_F_EventType1_Data = (CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_EventType1), 64'(MMR_CDbgNode0Eap0_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_EventType1_Data_prev = MMR_CDbgNode0Eap0_F_EventType1;
assign MMR_CDbgNode0Eap0_F_EventType1_Data_muxed = MMR_CDbgNode0Eap0_F_EventType1_WrEn ? MMR_CDbgNode0Eap0_F_EventType1_Data : MMR_CDbgNode0Eap0_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_EventType1_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_EventType1_Data),
    .out   (MMR_CDbgNode0Eap0_F_EventType1)
);

logic                                           MMR_CDbgNode0Eap0_F_EventType0_WrEn;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType0_Data;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType0_DataEff;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap0_F_EventType0_Data_prev;
assign MMR_CDbgNode0Eap0_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode0Eap0_F_EventType0_Data = (CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_EventType0), 64'(MMR_CDbgNode0Eap0_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_EventType0_Data_prev = MMR_CDbgNode0Eap0_F_EventType0;
assign MMR_CDbgNode0Eap0_F_EventType0_Data_muxed = MMR_CDbgNode0Eap0_F_EventType0_WrEn ? MMR_CDbgNode0Eap0_F_EventType0_Data : MMR_CDbgNode0Eap0_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_EventType0_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_EventType0_Data),
    .out   (MMR_CDbgNode0Eap0_F_EventType0)
);

logic                                           MMR_CDbgNode0Eap0_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap0_F_LogicalOp_Data;
logic [CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap0_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap0_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap0_F_LogicalOp_Data_prev;
assign MMR_CDbgNode0Eap0_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode0Eap0_F_LogicalOp_Data = (CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_LogicalOp), 64'(MMR_CDbgNode0Eap0_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_LogicalOp_Data_prev = MMR_CDbgNode0Eap0_F_LogicalOp;
assign MMR_CDbgNode0Eap0_F_LogicalOp_Data_muxed = MMR_CDbgNode0Eap0_F_LogicalOp_WrEn ? MMR_CDbgNode0Eap0_F_LogicalOp_Data : MMR_CDbgNode0Eap0_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_LogicalOp_Data),
    .out   (MMR_CDbgNode0Eap0_F_LogicalOp)
);

logic                                           MMR_CDbgNode0Eap0_F_Action1_WrEn;
logic [CLA_CDBGNODE0EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action1_Data;
logic [CLA_CDBGNODE0EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action1_DataEff;
logic [CLA_CDBGNODE0EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action1_Data_muxed;
logic [CLA_CDBGNODE0EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action1_Data_prev;
assign MMR_CDbgNode0Eap0_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode0Eap0_F_Action1_Data = (CLA_CDBGNODE0EAP0_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_Action1), 64'(MMR_CDbgNode0Eap0_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_Action1_Data_prev = MMR_CDbgNode0Eap0_F_Action1;
assign MMR_CDbgNode0Eap0_F_Action1_Data_muxed = MMR_CDbgNode0Eap0_F_Action1_WrEn ? MMR_CDbgNode0Eap0_F_Action1_Data : MMR_CDbgNode0Eap0_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_ACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_Action1_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_Action1_Data),
    .out   (MMR_CDbgNode0Eap0_F_Action1)
);

logic                                           MMR_CDbgNode0Eap0_F_Action0_WrEn;
logic [CLA_CDBGNODE0EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action0_Data;
logic [CLA_CDBGNODE0EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action0_DataEff;
logic [CLA_CDBGNODE0EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action0_Data_muxed;
logic [CLA_CDBGNODE0EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap0_F_Action0_Data_prev;
assign MMR_CDbgNode0Eap0_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode0Eap0_F_Action0_Data = (CLA_CDBGNODE0EAP0_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_Action0), 64'(MMR_CDbgNode0Eap0_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_Action0_Data_prev = MMR_CDbgNode0Eap0_F_Action0;
assign MMR_CDbgNode0Eap0_F_Action0_Data_muxed = MMR_CDbgNode0Eap0_F_Action0_WrEn ? MMR_CDbgNode0Eap0_F_Action0_Data : MMR_CDbgNode0Eap0_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_ACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_Action0_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_Action0_Data),
    .out   (MMR_CDbgNode0Eap0_F_Action0)
);

logic                                           MMR_CDbgNode0Eap0_F_DestNode_WrEn;
logic [CLA_CDBGNODE0EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap0_F_DestNode_Data;
logic [CLA_CDBGNODE0EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap0_F_DestNode_DataEff;
logic [CLA_CDBGNODE0EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap0_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE0EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap0_F_DestNode_Data_prev;
assign MMR_CDbgNode0Eap0_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode0Eap0_F_DestNode_Data = (CLA_CDBGNODE0EAP0_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap0_F_DestNode), 64'(MMR_CDbgNode0Eap0_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap0_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP0))));
assign MMR_CDbgNode0Eap0_F_DestNode_Data_prev = MMR_CDbgNode0Eap0_F_DestNode;
assign MMR_CDbgNode0Eap0_F_DestNode_Data_muxed = MMR_CDbgNode0Eap0_F_DestNode_WrEn ? MMR_CDbgNode0Eap0_F_DestNode_Data : MMR_CDbgNode0Eap0_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP0_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP0_DESTNODE_WIDTH'(0))
) MMR_CDbgNode0Eap0_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap0_F_DestNode_WrEn),
    .in    (MMR_CDbgNode0Eap0_F_DestNode_Data),
    .out   (MMR_CDbgNode0Eap0_F_DestNode)
);

logic                                           MMR_CDbgNode0Eap1_F_Action3_WrEn;
logic [CLA_CDBGNODE0EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action3_Data;
logic [CLA_CDBGNODE0EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action3_DataEff;
logic [CLA_CDBGNODE0EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action3_Data_muxed;
logic [CLA_CDBGNODE0EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action3_Data_prev;
assign MMR_CDbgNode0Eap1_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode0Eap1_F_Action3_Data = (CLA_CDBGNODE0EAP1_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_Action3), 64'(MMR_CDbgNode0Eap1_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_Action3_Data_prev = MMR_CDbgNode0Eap1_F_Action3;
assign MMR_CDbgNode0Eap1_F_Action3_Data_muxed = MMR_CDbgNode0Eap1_F_Action3_WrEn ? MMR_CDbgNode0Eap1_F_Action3_Data : MMR_CDbgNode0Eap1_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_ACTION3_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_Action3_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_Action3_Data),
    .out   (MMR_CDbgNode0Eap1_F_Action3)
);

logic                                           MMR_CDbgNode0Eap1_F_Action2_WrEn;
logic [CLA_CDBGNODE0EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action2_Data;
logic [CLA_CDBGNODE0EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action2_DataEff;
logic [CLA_CDBGNODE0EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action2_Data_muxed;
logic [CLA_CDBGNODE0EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action2_Data_prev;
assign MMR_CDbgNode0Eap1_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode0Eap1_F_Action2_Data = (CLA_CDBGNODE0EAP1_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_Action2), 64'(MMR_CDbgNode0Eap1_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_Action2_Data_prev = MMR_CDbgNode0Eap1_F_Action2;
assign MMR_CDbgNode0Eap1_F_Action2_Data_muxed = MMR_CDbgNode0Eap1_F_Action2_WrEn ? MMR_CDbgNode0Eap1_F_Action2_Data : MMR_CDbgNode0Eap1_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_ACTION2_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_Action2_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_Action2_Data),
    .out   (MMR_CDbgNode0Eap1_F_Action2)
);

logic                                           MMR_CDbgNode0Eap1_F_Udf_WrEn;
logic [CLA_CDBGNODE0EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap1_F_Udf_Data;
logic [CLA_CDBGNODE0EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap1_F_Udf_DataEff;
logic [CLA_CDBGNODE0EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap1_F_Udf_Data_muxed;
logic [CLA_CDBGNODE0EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap1_F_Udf_Data_prev;
assign MMR_CDbgNode0Eap1_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode0Eap1_F_Udf_Data = (CLA_CDBGNODE0EAP1_UDF_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_Udf), 64'(MMR_CDbgNode0Eap1_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_Udf_Data_prev = MMR_CDbgNode0Eap1_F_Udf;
assign MMR_CDbgNode0Eap1_F_Udf_Data_muxed = MMR_CDbgNode0Eap1_F_Udf_WrEn ? MMR_CDbgNode0Eap1_F_Udf_Data : MMR_CDbgNode0Eap1_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_UDF_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_Udf_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_Udf_Data),
    .out   (MMR_CDbgNode0Eap1_F_Udf)
);

logic                                           MMR_CDbgNode0Eap1_F_EventType2_WrEn;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType2_Data;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType2_DataEff;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType2_Data_prev;
assign MMR_CDbgNode0Eap1_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode0Eap1_F_EventType2_Data = (CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_EventType2), 64'(MMR_CDbgNode0Eap1_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_EventType2_Data_prev = MMR_CDbgNode0Eap1_F_EventType2;
assign MMR_CDbgNode0Eap1_F_EventType2_Data_muxed = MMR_CDbgNode0Eap1_F_EventType2_WrEn ? MMR_CDbgNode0Eap1_F_EventType2_Data : MMR_CDbgNode0Eap1_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_EventType2_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_EventType2_Data),
    .out   (MMR_CDbgNode0Eap1_F_EventType2)
);

logic                                           MMR_CDbgNode0Eap1_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode0Eap1_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data = (CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_CustomAction1Enable), 64'(MMR_CDbgNode0Eap1_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_prev = MMR_CDbgNode0Eap1_F_CustomAction1Enable;
assign MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode0Eap1_F_CustomAction1Enable_WrEn ? MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data : MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode0Eap1_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode0Eap1_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode0Eap1_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data = (CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_CustomAction0Enable), 64'(MMR_CDbgNode0Eap1_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_prev = MMR_CDbgNode0Eap1_F_CustomAction0Enable;
assign MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode0Eap1_F_CustomAction0Enable_WrEn ? MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data : MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode0Eap1_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode0Eap1_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1_Data;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction1_Data_prev;
assign MMR_CDbgNode0Eap1_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode0Eap1_F_CustomAction1_Data = (CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_CustomAction1), 64'(MMR_CDbgNode0Eap1_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_CustomAction1_Data_prev = MMR_CDbgNode0Eap1_F_CustomAction1;
assign MMR_CDbgNode0Eap1_F_CustomAction1_Data_muxed = MMR_CDbgNode0Eap1_F_CustomAction1_WrEn ? MMR_CDbgNode0Eap1_F_CustomAction1_Data : MMR_CDbgNode0Eap1_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_CustomAction1_Data),
    .out   (MMR_CDbgNode0Eap1_F_CustomAction1)
);

logic                                           MMR_CDbgNode0Eap1_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0_Data;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap1_F_CustomAction0_Data_prev;
assign MMR_CDbgNode0Eap1_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode0Eap1_F_CustomAction0_Data = (CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_CustomAction0), 64'(MMR_CDbgNode0Eap1_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_CustomAction0_Data_prev = MMR_CDbgNode0Eap1_F_CustomAction0;
assign MMR_CDbgNode0Eap1_F_CustomAction0_Data_muxed = MMR_CDbgNode0Eap1_F_CustomAction0_WrEn ? MMR_CDbgNode0Eap1_F_CustomAction0_Data : MMR_CDbgNode0Eap1_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_CustomAction0_Data),
    .out   (MMR_CDbgNode0Eap1_F_CustomAction0)
);

logic                                           MMR_CDbgNode0Eap1_F_EventType1_WrEn;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType1_Data;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType1_DataEff;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType1_Data_prev;
assign MMR_CDbgNode0Eap1_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode0Eap1_F_EventType1_Data = (CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_EventType1), 64'(MMR_CDbgNode0Eap1_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_EventType1_Data_prev = MMR_CDbgNode0Eap1_F_EventType1;
assign MMR_CDbgNode0Eap1_F_EventType1_Data_muxed = MMR_CDbgNode0Eap1_F_EventType1_WrEn ? MMR_CDbgNode0Eap1_F_EventType1_Data : MMR_CDbgNode0Eap1_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_EventType1_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_EventType1_Data),
    .out   (MMR_CDbgNode0Eap1_F_EventType1)
);

logic                                           MMR_CDbgNode0Eap1_F_EventType0_WrEn;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType0_Data;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType0_DataEff;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap1_F_EventType0_Data_prev;
assign MMR_CDbgNode0Eap1_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode0Eap1_F_EventType0_Data = (CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_EventType0), 64'(MMR_CDbgNode0Eap1_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_EventType0_Data_prev = MMR_CDbgNode0Eap1_F_EventType0;
assign MMR_CDbgNode0Eap1_F_EventType0_Data_muxed = MMR_CDbgNode0Eap1_F_EventType0_WrEn ? MMR_CDbgNode0Eap1_F_EventType0_Data : MMR_CDbgNode0Eap1_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_EventType0_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_EventType0_Data),
    .out   (MMR_CDbgNode0Eap1_F_EventType0)
);

logic                                           MMR_CDbgNode0Eap1_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap1_F_LogicalOp_Data;
logic [CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap1_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap1_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap1_F_LogicalOp_Data_prev;
assign MMR_CDbgNode0Eap1_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode0Eap1_F_LogicalOp_Data = (CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_LogicalOp), 64'(MMR_CDbgNode0Eap1_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_LogicalOp_Data_prev = MMR_CDbgNode0Eap1_F_LogicalOp;
assign MMR_CDbgNode0Eap1_F_LogicalOp_Data_muxed = MMR_CDbgNode0Eap1_F_LogicalOp_WrEn ? MMR_CDbgNode0Eap1_F_LogicalOp_Data : MMR_CDbgNode0Eap1_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_LogicalOp_Data),
    .out   (MMR_CDbgNode0Eap1_F_LogicalOp)
);

logic                                           MMR_CDbgNode0Eap1_F_Action1_WrEn;
logic [CLA_CDBGNODE0EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action1_Data;
logic [CLA_CDBGNODE0EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action1_DataEff;
logic [CLA_CDBGNODE0EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action1_Data_muxed;
logic [CLA_CDBGNODE0EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action1_Data_prev;
assign MMR_CDbgNode0Eap1_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode0Eap1_F_Action1_Data = (CLA_CDBGNODE0EAP1_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_Action1), 64'(MMR_CDbgNode0Eap1_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_Action1_Data_prev = MMR_CDbgNode0Eap1_F_Action1;
assign MMR_CDbgNode0Eap1_F_Action1_Data_muxed = MMR_CDbgNode0Eap1_F_Action1_WrEn ? MMR_CDbgNode0Eap1_F_Action1_Data : MMR_CDbgNode0Eap1_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_ACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_Action1_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_Action1_Data),
    .out   (MMR_CDbgNode0Eap1_F_Action1)
);

logic                                           MMR_CDbgNode0Eap1_F_Action0_WrEn;
logic [CLA_CDBGNODE0EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action0_Data;
logic [CLA_CDBGNODE0EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action0_DataEff;
logic [CLA_CDBGNODE0EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action0_Data_muxed;
logic [CLA_CDBGNODE0EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap1_F_Action0_Data_prev;
assign MMR_CDbgNode0Eap1_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode0Eap1_F_Action0_Data = (CLA_CDBGNODE0EAP1_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_Action0), 64'(MMR_CDbgNode0Eap1_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_Action0_Data_prev = MMR_CDbgNode0Eap1_F_Action0;
assign MMR_CDbgNode0Eap1_F_Action0_Data_muxed = MMR_CDbgNode0Eap1_F_Action0_WrEn ? MMR_CDbgNode0Eap1_F_Action0_Data : MMR_CDbgNode0Eap1_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_ACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_Action0_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_Action0_Data),
    .out   (MMR_CDbgNode0Eap1_F_Action0)
);

logic                                           MMR_CDbgNode0Eap1_F_DestNode_WrEn;
logic [CLA_CDBGNODE0EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap1_F_DestNode_Data;
logic [CLA_CDBGNODE0EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap1_F_DestNode_DataEff;
logic [CLA_CDBGNODE0EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap1_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE0EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap1_F_DestNode_Data_prev;
assign MMR_CDbgNode0Eap1_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode0Eap1_F_DestNode_Data = (CLA_CDBGNODE0EAP1_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap1_F_DestNode), 64'(MMR_CDbgNode0Eap1_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap1_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP1))));
assign MMR_CDbgNode0Eap1_F_DestNode_Data_prev = MMR_CDbgNode0Eap1_F_DestNode;
assign MMR_CDbgNode0Eap1_F_DestNode_Data_muxed = MMR_CDbgNode0Eap1_F_DestNode_WrEn ? MMR_CDbgNode0Eap1_F_DestNode_Data : MMR_CDbgNode0Eap1_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP1_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP1_DESTNODE_WIDTH'(0))
) MMR_CDbgNode0Eap1_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap1_F_DestNode_WrEn),
    .in    (MMR_CDbgNode0Eap1_F_DestNode_Data),
    .out   (MMR_CDbgNode0Eap1_F_DestNode)
);

logic                                           MMR_CDbgNode1Eap0_F_Action3_WrEn;
logic [CLA_CDBGNODE1EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action3_Data;
logic [CLA_CDBGNODE1EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action3_DataEff;
logic [CLA_CDBGNODE1EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action3_Data_muxed;
logic [CLA_CDBGNODE1EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action3_Data_prev;
assign MMR_CDbgNode1Eap0_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode1Eap0_F_Action3_Data = (CLA_CDBGNODE1EAP0_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_Action3), 64'(MMR_CDbgNode1Eap0_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_Action3_Data_prev = MMR_CDbgNode1Eap0_F_Action3;
assign MMR_CDbgNode1Eap0_F_Action3_Data_muxed = MMR_CDbgNode1Eap0_F_Action3_WrEn ? MMR_CDbgNode1Eap0_F_Action3_Data : MMR_CDbgNode1Eap0_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_ACTION3_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_Action3_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_Action3_Data),
    .out   (MMR_CDbgNode1Eap0_F_Action3)
);

logic                                           MMR_CDbgNode1Eap0_F_Action2_WrEn;
logic [CLA_CDBGNODE1EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action2_Data;
logic [CLA_CDBGNODE1EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action2_DataEff;
logic [CLA_CDBGNODE1EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action2_Data_muxed;
logic [CLA_CDBGNODE1EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action2_Data_prev;
assign MMR_CDbgNode1Eap0_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode1Eap0_F_Action2_Data = (CLA_CDBGNODE1EAP0_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_Action2), 64'(MMR_CDbgNode1Eap0_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_Action2_Data_prev = MMR_CDbgNode1Eap0_F_Action2;
assign MMR_CDbgNode1Eap0_F_Action2_Data_muxed = MMR_CDbgNode1Eap0_F_Action2_WrEn ? MMR_CDbgNode1Eap0_F_Action2_Data : MMR_CDbgNode1Eap0_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_ACTION2_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_Action2_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_Action2_Data),
    .out   (MMR_CDbgNode1Eap0_F_Action2)
);

logic                                           MMR_CDbgNode1Eap0_F_Udf_WrEn;
logic [CLA_CDBGNODE1EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap0_F_Udf_Data;
logic [CLA_CDBGNODE1EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap0_F_Udf_DataEff;
logic [CLA_CDBGNODE1EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap0_F_Udf_Data_muxed;
logic [CLA_CDBGNODE1EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap0_F_Udf_Data_prev;
assign MMR_CDbgNode1Eap0_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode1Eap0_F_Udf_Data = (CLA_CDBGNODE1EAP0_UDF_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_Udf), 64'(MMR_CDbgNode1Eap0_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_Udf_Data_prev = MMR_CDbgNode1Eap0_F_Udf;
assign MMR_CDbgNode1Eap0_F_Udf_Data_muxed = MMR_CDbgNode1Eap0_F_Udf_WrEn ? MMR_CDbgNode1Eap0_F_Udf_Data : MMR_CDbgNode1Eap0_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_UDF_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_Udf_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_Udf_Data),
    .out   (MMR_CDbgNode1Eap0_F_Udf)
);

logic                                           MMR_CDbgNode1Eap0_F_EventType2_WrEn;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType2_Data;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType2_DataEff;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType2_Data_prev;
assign MMR_CDbgNode1Eap0_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode1Eap0_F_EventType2_Data = (CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_EventType2), 64'(MMR_CDbgNode1Eap0_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_EventType2_Data_prev = MMR_CDbgNode1Eap0_F_EventType2;
assign MMR_CDbgNode1Eap0_F_EventType2_Data_muxed = MMR_CDbgNode1Eap0_F_EventType2_WrEn ? MMR_CDbgNode1Eap0_F_EventType2_Data : MMR_CDbgNode1Eap0_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_EventType2_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_EventType2_Data),
    .out   (MMR_CDbgNode1Eap0_F_EventType2)
);

logic                                           MMR_CDbgNode1Eap0_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode1Eap0_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data = (CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_CustomAction1Enable), 64'(MMR_CDbgNode1Eap0_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_prev = MMR_CDbgNode1Eap0_F_CustomAction1Enable;
assign MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode1Eap0_F_CustomAction1Enable_WrEn ? MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data : MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode1Eap0_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode1Eap0_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode1Eap0_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data = (CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_CustomAction0Enable), 64'(MMR_CDbgNode1Eap0_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_prev = MMR_CDbgNode1Eap0_F_CustomAction0Enable;
assign MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode1Eap0_F_CustomAction0Enable_WrEn ? MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data : MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode1Eap0_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode1Eap0_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1_Data;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction1_Data_prev;
assign MMR_CDbgNode1Eap0_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode1Eap0_F_CustomAction1_Data = (CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_CustomAction1), 64'(MMR_CDbgNode1Eap0_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_CustomAction1_Data_prev = MMR_CDbgNode1Eap0_F_CustomAction1;
assign MMR_CDbgNode1Eap0_F_CustomAction1_Data_muxed = MMR_CDbgNode1Eap0_F_CustomAction1_WrEn ? MMR_CDbgNode1Eap0_F_CustomAction1_Data : MMR_CDbgNode1Eap0_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_CustomAction1_Data),
    .out   (MMR_CDbgNode1Eap0_F_CustomAction1)
);

logic                                           MMR_CDbgNode1Eap0_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0_Data;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap0_F_CustomAction0_Data_prev;
assign MMR_CDbgNode1Eap0_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode1Eap0_F_CustomAction0_Data = (CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_CustomAction0), 64'(MMR_CDbgNode1Eap0_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_CustomAction0_Data_prev = MMR_CDbgNode1Eap0_F_CustomAction0;
assign MMR_CDbgNode1Eap0_F_CustomAction0_Data_muxed = MMR_CDbgNode1Eap0_F_CustomAction0_WrEn ? MMR_CDbgNode1Eap0_F_CustomAction0_Data : MMR_CDbgNode1Eap0_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_CustomAction0_Data),
    .out   (MMR_CDbgNode1Eap0_F_CustomAction0)
);

logic                                           MMR_CDbgNode1Eap0_F_EventType1_WrEn;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType1_Data;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType1_DataEff;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType1_Data_prev;
assign MMR_CDbgNode1Eap0_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode1Eap0_F_EventType1_Data = (CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_EventType1), 64'(MMR_CDbgNode1Eap0_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_EventType1_Data_prev = MMR_CDbgNode1Eap0_F_EventType1;
assign MMR_CDbgNode1Eap0_F_EventType1_Data_muxed = MMR_CDbgNode1Eap0_F_EventType1_WrEn ? MMR_CDbgNode1Eap0_F_EventType1_Data : MMR_CDbgNode1Eap0_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_EventType1_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_EventType1_Data),
    .out   (MMR_CDbgNode1Eap0_F_EventType1)
);

logic                                           MMR_CDbgNode1Eap0_F_EventType0_WrEn;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType0_Data;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType0_DataEff;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap0_F_EventType0_Data_prev;
assign MMR_CDbgNode1Eap0_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode1Eap0_F_EventType0_Data = (CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_EventType0), 64'(MMR_CDbgNode1Eap0_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_EventType0_Data_prev = MMR_CDbgNode1Eap0_F_EventType0;
assign MMR_CDbgNode1Eap0_F_EventType0_Data_muxed = MMR_CDbgNode1Eap0_F_EventType0_WrEn ? MMR_CDbgNode1Eap0_F_EventType0_Data : MMR_CDbgNode1Eap0_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_EventType0_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_EventType0_Data),
    .out   (MMR_CDbgNode1Eap0_F_EventType0)
);

logic                                           MMR_CDbgNode1Eap0_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap0_F_LogicalOp_Data;
logic [CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap0_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap0_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap0_F_LogicalOp_Data_prev;
assign MMR_CDbgNode1Eap0_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode1Eap0_F_LogicalOp_Data = (CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_LogicalOp), 64'(MMR_CDbgNode1Eap0_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_LogicalOp_Data_prev = MMR_CDbgNode1Eap0_F_LogicalOp;
assign MMR_CDbgNode1Eap0_F_LogicalOp_Data_muxed = MMR_CDbgNode1Eap0_F_LogicalOp_WrEn ? MMR_CDbgNode1Eap0_F_LogicalOp_Data : MMR_CDbgNode1Eap0_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_LogicalOp_Data),
    .out   (MMR_CDbgNode1Eap0_F_LogicalOp)
);

logic                                           MMR_CDbgNode1Eap0_F_Action1_WrEn;
logic [CLA_CDBGNODE1EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action1_Data;
logic [CLA_CDBGNODE1EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action1_DataEff;
logic [CLA_CDBGNODE1EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action1_Data_muxed;
logic [CLA_CDBGNODE1EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action1_Data_prev;
assign MMR_CDbgNode1Eap0_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode1Eap0_F_Action1_Data = (CLA_CDBGNODE1EAP0_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_Action1), 64'(MMR_CDbgNode1Eap0_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_Action1_Data_prev = MMR_CDbgNode1Eap0_F_Action1;
assign MMR_CDbgNode1Eap0_F_Action1_Data_muxed = MMR_CDbgNode1Eap0_F_Action1_WrEn ? MMR_CDbgNode1Eap0_F_Action1_Data : MMR_CDbgNode1Eap0_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_ACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_Action1_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_Action1_Data),
    .out   (MMR_CDbgNode1Eap0_F_Action1)
);

logic                                           MMR_CDbgNode1Eap0_F_Action0_WrEn;
logic [CLA_CDBGNODE1EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action0_Data;
logic [CLA_CDBGNODE1EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action0_DataEff;
logic [CLA_CDBGNODE1EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action0_Data_muxed;
logic [CLA_CDBGNODE1EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap0_F_Action0_Data_prev;
assign MMR_CDbgNode1Eap0_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode1Eap0_F_Action0_Data = (CLA_CDBGNODE1EAP0_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_Action0), 64'(MMR_CDbgNode1Eap0_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_Action0_Data_prev = MMR_CDbgNode1Eap0_F_Action0;
assign MMR_CDbgNode1Eap0_F_Action0_Data_muxed = MMR_CDbgNode1Eap0_F_Action0_WrEn ? MMR_CDbgNode1Eap0_F_Action0_Data : MMR_CDbgNode1Eap0_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_ACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_Action0_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_Action0_Data),
    .out   (MMR_CDbgNode1Eap0_F_Action0)
);

logic                                           MMR_CDbgNode1Eap0_F_DestNode_WrEn;
logic [CLA_CDBGNODE1EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap0_F_DestNode_Data;
logic [CLA_CDBGNODE1EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap0_F_DestNode_DataEff;
logic [CLA_CDBGNODE1EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap0_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE1EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap0_F_DestNode_Data_prev;
assign MMR_CDbgNode1Eap0_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode1Eap0_F_DestNode_Data = (CLA_CDBGNODE1EAP0_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap0_F_DestNode), 64'(MMR_CDbgNode1Eap0_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap0_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP0))));
assign MMR_CDbgNode1Eap0_F_DestNode_Data_prev = MMR_CDbgNode1Eap0_F_DestNode;
assign MMR_CDbgNode1Eap0_F_DestNode_Data_muxed = MMR_CDbgNode1Eap0_F_DestNode_WrEn ? MMR_CDbgNode1Eap0_F_DestNode_Data : MMR_CDbgNode1Eap0_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP0_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP0_DESTNODE_WIDTH'(0))
) MMR_CDbgNode1Eap0_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap0_F_DestNode_WrEn),
    .in    (MMR_CDbgNode1Eap0_F_DestNode_Data),
    .out   (MMR_CDbgNode1Eap0_F_DestNode)
);

logic                                           MMR_CDbgNode1Eap1_F_Action3_WrEn;
logic [CLA_CDBGNODE1EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action3_Data;
logic [CLA_CDBGNODE1EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action3_DataEff;
logic [CLA_CDBGNODE1EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action3_Data_muxed;
logic [CLA_CDBGNODE1EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action3_Data_prev;
assign MMR_CDbgNode1Eap1_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode1Eap1_F_Action3_Data = (CLA_CDBGNODE1EAP1_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_Action3), 64'(MMR_CDbgNode1Eap1_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_Action3_Data_prev = MMR_CDbgNode1Eap1_F_Action3;
assign MMR_CDbgNode1Eap1_F_Action3_Data_muxed = MMR_CDbgNode1Eap1_F_Action3_WrEn ? MMR_CDbgNode1Eap1_F_Action3_Data : MMR_CDbgNode1Eap1_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_ACTION3_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_Action3_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_Action3_Data),
    .out   (MMR_CDbgNode1Eap1_F_Action3)
);

logic                                           MMR_CDbgNode1Eap1_F_Action2_WrEn;
logic [CLA_CDBGNODE1EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action2_Data;
logic [CLA_CDBGNODE1EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action2_DataEff;
logic [CLA_CDBGNODE1EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action2_Data_muxed;
logic [CLA_CDBGNODE1EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action2_Data_prev;
assign MMR_CDbgNode1Eap1_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode1Eap1_F_Action2_Data = (CLA_CDBGNODE1EAP1_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_Action2), 64'(MMR_CDbgNode1Eap1_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_Action2_Data_prev = MMR_CDbgNode1Eap1_F_Action2;
assign MMR_CDbgNode1Eap1_F_Action2_Data_muxed = MMR_CDbgNode1Eap1_F_Action2_WrEn ? MMR_CDbgNode1Eap1_F_Action2_Data : MMR_CDbgNode1Eap1_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_ACTION2_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_Action2_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_Action2_Data),
    .out   (MMR_CDbgNode1Eap1_F_Action2)
);

logic                                           MMR_CDbgNode1Eap1_F_Udf_WrEn;
logic [CLA_CDBGNODE1EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap1_F_Udf_Data;
logic [CLA_CDBGNODE1EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap1_F_Udf_DataEff;
logic [CLA_CDBGNODE1EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap1_F_Udf_Data_muxed;
logic [CLA_CDBGNODE1EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap1_F_Udf_Data_prev;
assign MMR_CDbgNode1Eap1_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode1Eap1_F_Udf_Data = (CLA_CDBGNODE1EAP1_UDF_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_Udf), 64'(MMR_CDbgNode1Eap1_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_Udf_Data_prev = MMR_CDbgNode1Eap1_F_Udf;
assign MMR_CDbgNode1Eap1_F_Udf_Data_muxed = MMR_CDbgNode1Eap1_F_Udf_WrEn ? MMR_CDbgNode1Eap1_F_Udf_Data : MMR_CDbgNode1Eap1_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_UDF_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_Udf_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_Udf_Data),
    .out   (MMR_CDbgNode1Eap1_F_Udf)
);

logic                                           MMR_CDbgNode1Eap1_F_EventType2_WrEn;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType2_Data;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType2_DataEff;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType2_Data_prev;
assign MMR_CDbgNode1Eap1_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode1Eap1_F_EventType2_Data = (CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_EventType2), 64'(MMR_CDbgNode1Eap1_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_EventType2_Data_prev = MMR_CDbgNode1Eap1_F_EventType2;
assign MMR_CDbgNode1Eap1_F_EventType2_Data_muxed = MMR_CDbgNode1Eap1_F_EventType2_WrEn ? MMR_CDbgNode1Eap1_F_EventType2_Data : MMR_CDbgNode1Eap1_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_EventType2_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_EventType2_Data),
    .out   (MMR_CDbgNode1Eap1_F_EventType2)
);

logic                                           MMR_CDbgNode1Eap1_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode1Eap1_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data = (CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_CustomAction1Enable), 64'(MMR_CDbgNode1Eap1_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_prev = MMR_CDbgNode1Eap1_F_CustomAction1Enable;
assign MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode1Eap1_F_CustomAction1Enable_WrEn ? MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data : MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode1Eap1_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode1Eap1_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode1Eap1_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data = (CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_CustomAction0Enable), 64'(MMR_CDbgNode1Eap1_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_prev = MMR_CDbgNode1Eap1_F_CustomAction0Enable;
assign MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode1Eap1_F_CustomAction0Enable_WrEn ? MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data : MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode1Eap1_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode1Eap1_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1_Data;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction1_Data_prev;
assign MMR_CDbgNode1Eap1_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode1Eap1_F_CustomAction1_Data = (CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_CustomAction1), 64'(MMR_CDbgNode1Eap1_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_CustomAction1_Data_prev = MMR_CDbgNode1Eap1_F_CustomAction1;
assign MMR_CDbgNode1Eap1_F_CustomAction1_Data_muxed = MMR_CDbgNode1Eap1_F_CustomAction1_WrEn ? MMR_CDbgNode1Eap1_F_CustomAction1_Data : MMR_CDbgNode1Eap1_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_CustomAction1_Data),
    .out   (MMR_CDbgNode1Eap1_F_CustomAction1)
);

logic                                           MMR_CDbgNode1Eap1_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0_Data;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap1_F_CustomAction0_Data_prev;
assign MMR_CDbgNode1Eap1_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode1Eap1_F_CustomAction0_Data = (CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_CustomAction0), 64'(MMR_CDbgNode1Eap1_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_CustomAction0_Data_prev = MMR_CDbgNode1Eap1_F_CustomAction0;
assign MMR_CDbgNode1Eap1_F_CustomAction0_Data_muxed = MMR_CDbgNode1Eap1_F_CustomAction0_WrEn ? MMR_CDbgNode1Eap1_F_CustomAction0_Data : MMR_CDbgNode1Eap1_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_CustomAction0_Data),
    .out   (MMR_CDbgNode1Eap1_F_CustomAction0)
);

logic                                           MMR_CDbgNode1Eap1_F_EventType1_WrEn;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType1_Data;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType1_DataEff;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType1_Data_prev;
assign MMR_CDbgNode1Eap1_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode1Eap1_F_EventType1_Data = (CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_EventType1), 64'(MMR_CDbgNode1Eap1_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_EventType1_Data_prev = MMR_CDbgNode1Eap1_F_EventType1;
assign MMR_CDbgNode1Eap1_F_EventType1_Data_muxed = MMR_CDbgNode1Eap1_F_EventType1_WrEn ? MMR_CDbgNode1Eap1_F_EventType1_Data : MMR_CDbgNode1Eap1_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_EventType1_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_EventType1_Data),
    .out   (MMR_CDbgNode1Eap1_F_EventType1)
);

logic                                           MMR_CDbgNode1Eap1_F_EventType0_WrEn;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType0_Data;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType0_DataEff;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap1_F_EventType0_Data_prev;
assign MMR_CDbgNode1Eap1_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode1Eap1_F_EventType0_Data = (CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_EventType0), 64'(MMR_CDbgNode1Eap1_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_EventType0_Data_prev = MMR_CDbgNode1Eap1_F_EventType0;
assign MMR_CDbgNode1Eap1_F_EventType0_Data_muxed = MMR_CDbgNode1Eap1_F_EventType0_WrEn ? MMR_CDbgNode1Eap1_F_EventType0_Data : MMR_CDbgNode1Eap1_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_EventType0_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_EventType0_Data),
    .out   (MMR_CDbgNode1Eap1_F_EventType0)
);

logic                                           MMR_CDbgNode1Eap1_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap1_F_LogicalOp_Data;
logic [CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap1_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap1_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap1_F_LogicalOp_Data_prev;
assign MMR_CDbgNode1Eap1_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode1Eap1_F_LogicalOp_Data = (CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_LogicalOp), 64'(MMR_CDbgNode1Eap1_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_LogicalOp_Data_prev = MMR_CDbgNode1Eap1_F_LogicalOp;
assign MMR_CDbgNode1Eap1_F_LogicalOp_Data_muxed = MMR_CDbgNode1Eap1_F_LogicalOp_WrEn ? MMR_CDbgNode1Eap1_F_LogicalOp_Data : MMR_CDbgNode1Eap1_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_LogicalOp_Data),
    .out   (MMR_CDbgNode1Eap1_F_LogicalOp)
);

logic                                           MMR_CDbgNode1Eap1_F_Action1_WrEn;
logic [CLA_CDBGNODE1EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action1_Data;
logic [CLA_CDBGNODE1EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action1_DataEff;
logic [CLA_CDBGNODE1EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action1_Data_muxed;
logic [CLA_CDBGNODE1EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action1_Data_prev;
assign MMR_CDbgNode1Eap1_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode1Eap1_F_Action1_Data = (CLA_CDBGNODE1EAP1_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_Action1), 64'(MMR_CDbgNode1Eap1_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_Action1_Data_prev = MMR_CDbgNode1Eap1_F_Action1;
assign MMR_CDbgNode1Eap1_F_Action1_Data_muxed = MMR_CDbgNode1Eap1_F_Action1_WrEn ? MMR_CDbgNode1Eap1_F_Action1_Data : MMR_CDbgNode1Eap1_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_ACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_Action1_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_Action1_Data),
    .out   (MMR_CDbgNode1Eap1_F_Action1)
);

logic                                           MMR_CDbgNode1Eap1_F_Action0_WrEn;
logic [CLA_CDBGNODE1EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action0_Data;
logic [CLA_CDBGNODE1EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action0_DataEff;
logic [CLA_CDBGNODE1EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action0_Data_muxed;
logic [CLA_CDBGNODE1EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap1_F_Action0_Data_prev;
assign MMR_CDbgNode1Eap1_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode1Eap1_F_Action0_Data = (CLA_CDBGNODE1EAP1_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_Action0), 64'(MMR_CDbgNode1Eap1_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_Action0_Data_prev = MMR_CDbgNode1Eap1_F_Action0;
assign MMR_CDbgNode1Eap1_F_Action0_Data_muxed = MMR_CDbgNode1Eap1_F_Action0_WrEn ? MMR_CDbgNode1Eap1_F_Action0_Data : MMR_CDbgNode1Eap1_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_ACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_Action0_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_Action0_Data),
    .out   (MMR_CDbgNode1Eap1_F_Action0)
);

logic                                           MMR_CDbgNode1Eap1_F_DestNode_WrEn;
logic [CLA_CDBGNODE1EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap1_F_DestNode_Data;
logic [CLA_CDBGNODE1EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap1_F_DestNode_DataEff;
logic [CLA_CDBGNODE1EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap1_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE1EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap1_F_DestNode_Data_prev;
assign MMR_CDbgNode1Eap1_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode1Eap1_F_DestNode_Data = (CLA_CDBGNODE1EAP1_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap1_F_DestNode), 64'(MMR_CDbgNode1Eap1_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap1_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP1))));
assign MMR_CDbgNode1Eap1_F_DestNode_Data_prev = MMR_CDbgNode1Eap1_F_DestNode;
assign MMR_CDbgNode1Eap1_F_DestNode_Data_muxed = MMR_CDbgNode1Eap1_F_DestNode_WrEn ? MMR_CDbgNode1Eap1_F_DestNode_Data : MMR_CDbgNode1Eap1_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP1_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP1_DESTNODE_WIDTH'(0))
) MMR_CDbgNode1Eap1_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap1_F_DestNode_WrEn),
    .in    (MMR_CDbgNode1Eap1_F_DestNode_Data),
    .out   (MMR_CDbgNode1Eap1_F_DestNode)
);

logic                                           MMR_CDbgNode2Eap0_F_Action3_WrEn;
logic [CLA_CDBGNODE2EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action3_Data;
logic [CLA_CDBGNODE2EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action3_DataEff;
logic [CLA_CDBGNODE2EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action3_Data_muxed;
logic [CLA_CDBGNODE2EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action3_Data_prev;
assign MMR_CDbgNode2Eap0_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode2Eap0_F_Action3_Data = (CLA_CDBGNODE2EAP0_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_Action3), 64'(MMR_CDbgNode2Eap0_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_Action3_Data_prev = MMR_CDbgNode2Eap0_F_Action3;
assign MMR_CDbgNode2Eap0_F_Action3_Data_muxed = MMR_CDbgNode2Eap0_F_Action3_WrEn ? MMR_CDbgNode2Eap0_F_Action3_Data : MMR_CDbgNode2Eap0_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_ACTION3_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_Action3_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_Action3_Data),
    .out   (MMR_CDbgNode2Eap0_F_Action3)
);

logic                                           MMR_CDbgNode2Eap0_F_Action2_WrEn;
logic [CLA_CDBGNODE2EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action2_Data;
logic [CLA_CDBGNODE2EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action2_DataEff;
logic [CLA_CDBGNODE2EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action2_Data_muxed;
logic [CLA_CDBGNODE2EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action2_Data_prev;
assign MMR_CDbgNode2Eap0_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode2Eap0_F_Action2_Data = (CLA_CDBGNODE2EAP0_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_Action2), 64'(MMR_CDbgNode2Eap0_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_Action2_Data_prev = MMR_CDbgNode2Eap0_F_Action2;
assign MMR_CDbgNode2Eap0_F_Action2_Data_muxed = MMR_CDbgNode2Eap0_F_Action2_WrEn ? MMR_CDbgNode2Eap0_F_Action2_Data : MMR_CDbgNode2Eap0_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_ACTION2_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_Action2_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_Action2_Data),
    .out   (MMR_CDbgNode2Eap0_F_Action2)
);

logic                                           MMR_CDbgNode2Eap0_F_Udf_WrEn;
logic [CLA_CDBGNODE2EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap0_F_Udf_Data;
logic [CLA_CDBGNODE2EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap0_F_Udf_DataEff;
logic [CLA_CDBGNODE2EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap0_F_Udf_Data_muxed;
logic [CLA_CDBGNODE2EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap0_F_Udf_Data_prev;
assign MMR_CDbgNode2Eap0_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode2Eap0_F_Udf_Data = (CLA_CDBGNODE2EAP0_UDF_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_Udf), 64'(MMR_CDbgNode2Eap0_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_Udf_Data_prev = MMR_CDbgNode2Eap0_F_Udf;
assign MMR_CDbgNode2Eap0_F_Udf_Data_muxed = MMR_CDbgNode2Eap0_F_Udf_WrEn ? MMR_CDbgNode2Eap0_F_Udf_Data : MMR_CDbgNode2Eap0_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_UDF_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_Udf_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_Udf_Data),
    .out   (MMR_CDbgNode2Eap0_F_Udf)
);

logic                                           MMR_CDbgNode2Eap0_F_EventType2_WrEn;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType2_Data;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType2_DataEff;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType2_Data_prev;
assign MMR_CDbgNode2Eap0_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode2Eap0_F_EventType2_Data = (CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_EventType2), 64'(MMR_CDbgNode2Eap0_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_EventType2_Data_prev = MMR_CDbgNode2Eap0_F_EventType2;
assign MMR_CDbgNode2Eap0_F_EventType2_Data_muxed = MMR_CDbgNode2Eap0_F_EventType2_WrEn ? MMR_CDbgNode2Eap0_F_EventType2_Data : MMR_CDbgNode2Eap0_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_EventType2_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_EventType2_Data),
    .out   (MMR_CDbgNode2Eap0_F_EventType2)
);

logic                                           MMR_CDbgNode2Eap0_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode2Eap0_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data = (CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_CustomAction1Enable), 64'(MMR_CDbgNode2Eap0_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_prev = MMR_CDbgNode2Eap0_F_CustomAction1Enable;
assign MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode2Eap0_F_CustomAction1Enable_WrEn ? MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data : MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode2Eap0_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode2Eap0_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode2Eap0_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data = (CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_CustomAction0Enable), 64'(MMR_CDbgNode2Eap0_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_prev = MMR_CDbgNode2Eap0_F_CustomAction0Enable;
assign MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode2Eap0_F_CustomAction0Enable_WrEn ? MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data : MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode2Eap0_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode2Eap0_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1_Data;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction1_Data_prev;
assign MMR_CDbgNode2Eap0_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode2Eap0_F_CustomAction1_Data = (CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_CustomAction1), 64'(MMR_CDbgNode2Eap0_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_CustomAction1_Data_prev = MMR_CDbgNode2Eap0_F_CustomAction1;
assign MMR_CDbgNode2Eap0_F_CustomAction1_Data_muxed = MMR_CDbgNode2Eap0_F_CustomAction1_WrEn ? MMR_CDbgNode2Eap0_F_CustomAction1_Data : MMR_CDbgNode2Eap0_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_CustomAction1_Data),
    .out   (MMR_CDbgNode2Eap0_F_CustomAction1)
);

logic                                           MMR_CDbgNode2Eap0_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0_Data;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap0_F_CustomAction0_Data_prev;
assign MMR_CDbgNode2Eap0_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode2Eap0_F_CustomAction0_Data = (CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_CustomAction0), 64'(MMR_CDbgNode2Eap0_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_CustomAction0_Data_prev = MMR_CDbgNode2Eap0_F_CustomAction0;
assign MMR_CDbgNode2Eap0_F_CustomAction0_Data_muxed = MMR_CDbgNode2Eap0_F_CustomAction0_WrEn ? MMR_CDbgNode2Eap0_F_CustomAction0_Data : MMR_CDbgNode2Eap0_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_CustomAction0_Data),
    .out   (MMR_CDbgNode2Eap0_F_CustomAction0)
);

logic                                           MMR_CDbgNode2Eap0_F_EventType1_WrEn;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType1_Data;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType1_DataEff;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType1_Data_prev;
assign MMR_CDbgNode2Eap0_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode2Eap0_F_EventType1_Data = (CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_EventType1), 64'(MMR_CDbgNode2Eap0_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_EventType1_Data_prev = MMR_CDbgNode2Eap0_F_EventType1;
assign MMR_CDbgNode2Eap0_F_EventType1_Data_muxed = MMR_CDbgNode2Eap0_F_EventType1_WrEn ? MMR_CDbgNode2Eap0_F_EventType1_Data : MMR_CDbgNode2Eap0_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_EventType1_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_EventType1_Data),
    .out   (MMR_CDbgNode2Eap0_F_EventType1)
);

logic                                           MMR_CDbgNode2Eap0_F_EventType0_WrEn;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType0_Data;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType0_DataEff;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap0_F_EventType0_Data_prev;
assign MMR_CDbgNode2Eap0_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode2Eap0_F_EventType0_Data = (CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_EventType0), 64'(MMR_CDbgNode2Eap0_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_EventType0_Data_prev = MMR_CDbgNode2Eap0_F_EventType0;
assign MMR_CDbgNode2Eap0_F_EventType0_Data_muxed = MMR_CDbgNode2Eap0_F_EventType0_WrEn ? MMR_CDbgNode2Eap0_F_EventType0_Data : MMR_CDbgNode2Eap0_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_EventType0_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_EventType0_Data),
    .out   (MMR_CDbgNode2Eap0_F_EventType0)
);

logic                                           MMR_CDbgNode2Eap0_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap0_F_LogicalOp_Data;
logic [CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap0_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap0_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap0_F_LogicalOp_Data_prev;
assign MMR_CDbgNode2Eap0_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode2Eap0_F_LogicalOp_Data = (CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_LogicalOp), 64'(MMR_CDbgNode2Eap0_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_LogicalOp_Data_prev = MMR_CDbgNode2Eap0_F_LogicalOp;
assign MMR_CDbgNode2Eap0_F_LogicalOp_Data_muxed = MMR_CDbgNode2Eap0_F_LogicalOp_WrEn ? MMR_CDbgNode2Eap0_F_LogicalOp_Data : MMR_CDbgNode2Eap0_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_LogicalOp_Data),
    .out   (MMR_CDbgNode2Eap0_F_LogicalOp)
);

logic                                           MMR_CDbgNode2Eap0_F_Action1_WrEn;
logic [CLA_CDBGNODE2EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action1_Data;
logic [CLA_CDBGNODE2EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action1_DataEff;
logic [CLA_CDBGNODE2EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action1_Data_muxed;
logic [CLA_CDBGNODE2EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action1_Data_prev;
assign MMR_CDbgNode2Eap0_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode2Eap0_F_Action1_Data = (CLA_CDBGNODE2EAP0_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_Action1), 64'(MMR_CDbgNode2Eap0_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_Action1_Data_prev = MMR_CDbgNode2Eap0_F_Action1;
assign MMR_CDbgNode2Eap0_F_Action1_Data_muxed = MMR_CDbgNode2Eap0_F_Action1_WrEn ? MMR_CDbgNode2Eap0_F_Action1_Data : MMR_CDbgNode2Eap0_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_ACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_Action1_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_Action1_Data),
    .out   (MMR_CDbgNode2Eap0_F_Action1)
);

logic                                           MMR_CDbgNode2Eap0_F_Action0_WrEn;
logic [CLA_CDBGNODE2EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action0_Data;
logic [CLA_CDBGNODE2EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action0_DataEff;
logic [CLA_CDBGNODE2EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action0_Data_muxed;
logic [CLA_CDBGNODE2EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap0_F_Action0_Data_prev;
assign MMR_CDbgNode2Eap0_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode2Eap0_F_Action0_Data = (CLA_CDBGNODE2EAP0_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_Action0), 64'(MMR_CDbgNode2Eap0_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_Action0_Data_prev = MMR_CDbgNode2Eap0_F_Action0;
assign MMR_CDbgNode2Eap0_F_Action0_Data_muxed = MMR_CDbgNode2Eap0_F_Action0_WrEn ? MMR_CDbgNode2Eap0_F_Action0_Data : MMR_CDbgNode2Eap0_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_ACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_Action0_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_Action0_Data),
    .out   (MMR_CDbgNode2Eap0_F_Action0)
);

logic                                           MMR_CDbgNode2Eap0_F_DestNode_WrEn;
logic [CLA_CDBGNODE2EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap0_F_DestNode_Data;
logic [CLA_CDBGNODE2EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap0_F_DestNode_DataEff;
logic [CLA_CDBGNODE2EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap0_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE2EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap0_F_DestNode_Data_prev;
assign MMR_CDbgNode2Eap0_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode2Eap0_F_DestNode_Data = (CLA_CDBGNODE2EAP0_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap0_F_DestNode), 64'(MMR_CDbgNode2Eap0_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap0_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP0))));
assign MMR_CDbgNode2Eap0_F_DestNode_Data_prev = MMR_CDbgNode2Eap0_F_DestNode;
assign MMR_CDbgNode2Eap0_F_DestNode_Data_muxed = MMR_CDbgNode2Eap0_F_DestNode_WrEn ? MMR_CDbgNode2Eap0_F_DestNode_Data : MMR_CDbgNode2Eap0_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP0_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP0_DESTNODE_WIDTH'(0))
) MMR_CDbgNode2Eap0_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap0_F_DestNode_WrEn),
    .in    (MMR_CDbgNode2Eap0_F_DestNode_Data),
    .out   (MMR_CDbgNode2Eap0_F_DestNode)
);

logic                                           MMR_CDbgNode2Eap1_F_Action3_WrEn;
logic [CLA_CDBGNODE2EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action3_Data;
logic [CLA_CDBGNODE2EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action3_DataEff;
logic [CLA_CDBGNODE2EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action3_Data_muxed;
logic [CLA_CDBGNODE2EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action3_Data_prev;
assign MMR_CDbgNode2Eap1_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode2Eap1_F_Action3_Data = (CLA_CDBGNODE2EAP1_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_Action3), 64'(MMR_CDbgNode2Eap1_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_Action3_Data_prev = MMR_CDbgNode2Eap1_F_Action3;
assign MMR_CDbgNode2Eap1_F_Action3_Data_muxed = MMR_CDbgNode2Eap1_F_Action3_WrEn ? MMR_CDbgNode2Eap1_F_Action3_Data : MMR_CDbgNode2Eap1_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_ACTION3_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_Action3_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_Action3_Data),
    .out   (MMR_CDbgNode2Eap1_F_Action3)
);

logic                                           MMR_CDbgNode2Eap1_F_Action2_WrEn;
logic [CLA_CDBGNODE2EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action2_Data;
logic [CLA_CDBGNODE2EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action2_DataEff;
logic [CLA_CDBGNODE2EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action2_Data_muxed;
logic [CLA_CDBGNODE2EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action2_Data_prev;
assign MMR_CDbgNode2Eap1_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode2Eap1_F_Action2_Data = (CLA_CDBGNODE2EAP1_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_Action2), 64'(MMR_CDbgNode2Eap1_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_Action2_Data_prev = MMR_CDbgNode2Eap1_F_Action2;
assign MMR_CDbgNode2Eap1_F_Action2_Data_muxed = MMR_CDbgNode2Eap1_F_Action2_WrEn ? MMR_CDbgNode2Eap1_F_Action2_Data : MMR_CDbgNode2Eap1_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_ACTION2_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_Action2_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_Action2_Data),
    .out   (MMR_CDbgNode2Eap1_F_Action2)
);

logic                                           MMR_CDbgNode2Eap1_F_Udf_WrEn;
logic [CLA_CDBGNODE2EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap1_F_Udf_Data;
logic [CLA_CDBGNODE2EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap1_F_Udf_DataEff;
logic [CLA_CDBGNODE2EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap1_F_Udf_Data_muxed;
logic [CLA_CDBGNODE2EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap1_F_Udf_Data_prev;
assign MMR_CDbgNode2Eap1_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode2Eap1_F_Udf_Data = (CLA_CDBGNODE2EAP1_UDF_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_Udf), 64'(MMR_CDbgNode2Eap1_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_Udf_Data_prev = MMR_CDbgNode2Eap1_F_Udf;
assign MMR_CDbgNode2Eap1_F_Udf_Data_muxed = MMR_CDbgNode2Eap1_F_Udf_WrEn ? MMR_CDbgNode2Eap1_F_Udf_Data : MMR_CDbgNode2Eap1_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_UDF_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_Udf_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_Udf_Data),
    .out   (MMR_CDbgNode2Eap1_F_Udf)
);

logic                                           MMR_CDbgNode2Eap1_F_EventType2_WrEn;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType2_Data;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType2_DataEff;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType2_Data_prev;
assign MMR_CDbgNode2Eap1_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode2Eap1_F_EventType2_Data = (CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_EventType2), 64'(MMR_CDbgNode2Eap1_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_EventType2_Data_prev = MMR_CDbgNode2Eap1_F_EventType2;
assign MMR_CDbgNode2Eap1_F_EventType2_Data_muxed = MMR_CDbgNode2Eap1_F_EventType2_WrEn ? MMR_CDbgNode2Eap1_F_EventType2_Data : MMR_CDbgNode2Eap1_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_EventType2_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_EventType2_Data),
    .out   (MMR_CDbgNode2Eap1_F_EventType2)
);

logic                                           MMR_CDbgNode2Eap1_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode2Eap1_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data = (CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_CustomAction1Enable), 64'(MMR_CDbgNode2Eap1_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_prev = MMR_CDbgNode2Eap1_F_CustomAction1Enable;
assign MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode2Eap1_F_CustomAction1Enable_WrEn ? MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data : MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode2Eap1_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode2Eap1_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode2Eap1_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data = (CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_CustomAction0Enable), 64'(MMR_CDbgNode2Eap1_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_prev = MMR_CDbgNode2Eap1_F_CustomAction0Enable;
assign MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode2Eap1_F_CustomAction0Enable_WrEn ? MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data : MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode2Eap1_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode2Eap1_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1_Data;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction1_Data_prev;
assign MMR_CDbgNode2Eap1_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode2Eap1_F_CustomAction1_Data = (CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_CustomAction1), 64'(MMR_CDbgNode2Eap1_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_CustomAction1_Data_prev = MMR_CDbgNode2Eap1_F_CustomAction1;
assign MMR_CDbgNode2Eap1_F_CustomAction1_Data_muxed = MMR_CDbgNode2Eap1_F_CustomAction1_WrEn ? MMR_CDbgNode2Eap1_F_CustomAction1_Data : MMR_CDbgNode2Eap1_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_CustomAction1_Data),
    .out   (MMR_CDbgNode2Eap1_F_CustomAction1)
);

logic                                           MMR_CDbgNode2Eap1_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0_Data;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap1_F_CustomAction0_Data_prev;
assign MMR_CDbgNode2Eap1_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode2Eap1_F_CustomAction0_Data = (CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_CustomAction0), 64'(MMR_CDbgNode2Eap1_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_CustomAction0_Data_prev = MMR_CDbgNode2Eap1_F_CustomAction0;
assign MMR_CDbgNode2Eap1_F_CustomAction0_Data_muxed = MMR_CDbgNode2Eap1_F_CustomAction0_WrEn ? MMR_CDbgNode2Eap1_F_CustomAction0_Data : MMR_CDbgNode2Eap1_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_CustomAction0_Data),
    .out   (MMR_CDbgNode2Eap1_F_CustomAction0)
);

logic                                           MMR_CDbgNode2Eap1_F_EventType1_WrEn;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType1_Data;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType1_DataEff;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType1_Data_prev;
assign MMR_CDbgNode2Eap1_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode2Eap1_F_EventType1_Data = (CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_EventType1), 64'(MMR_CDbgNode2Eap1_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_EventType1_Data_prev = MMR_CDbgNode2Eap1_F_EventType1;
assign MMR_CDbgNode2Eap1_F_EventType1_Data_muxed = MMR_CDbgNode2Eap1_F_EventType1_WrEn ? MMR_CDbgNode2Eap1_F_EventType1_Data : MMR_CDbgNode2Eap1_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_EventType1_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_EventType1_Data),
    .out   (MMR_CDbgNode2Eap1_F_EventType1)
);

logic                                           MMR_CDbgNode2Eap1_F_EventType0_WrEn;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType0_Data;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType0_DataEff;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap1_F_EventType0_Data_prev;
assign MMR_CDbgNode2Eap1_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode2Eap1_F_EventType0_Data = (CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_EventType0), 64'(MMR_CDbgNode2Eap1_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_EventType0_Data_prev = MMR_CDbgNode2Eap1_F_EventType0;
assign MMR_CDbgNode2Eap1_F_EventType0_Data_muxed = MMR_CDbgNode2Eap1_F_EventType0_WrEn ? MMR_CDbgNode2Eap1_F_EventType0_Data : MMR_CDbgNode2Eap1_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_EventType0_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_EventType0_Data),
    .out   (MMR_CDbgNode2Eap1_F_EventType0)
);

logic                                           MMR_CDbgNode2Eap1_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap1_F_LogicalOp_Data;
logic [CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap1_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap1_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap1_F_LogicalOp_Data_prev;
assign MMR_CDbgNode2Eap1_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode2Eap1_F_LogicalOp_Data = (CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_LogicalOp), 64'(MMR_CDbgNode2Eap1_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_LogicalOp_Data_prev = MMR_CDbgNode2Eap1_F_LogicalOp;
assign MMR_CDbgNode2Eap1_F_LogicalOp_Data_muxed = MMR_CDbgNode2Eap1_F_LogicalOp_WrEn ? MMR_CDbgNode2Eap1_F_LogicalOp_Data : MMR_CDbgNode2Eap1_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_LogicalOp_Data),
    .out   (MMR_CDbgNode2Eap1_F_LogicalOp)
);

logic                                           MMR_CDbgNode2Eap1_F_Action1_WrEn;
logic [CLA_CDBGNODE2EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action1_Data;
logic [CLA_CDBGNODE2EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action1_DataEff;
logic [CLA_CDBGNODE2EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action1_Data_muxed;
logic [CLA_CDBGNODE2EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action1_Data_prev;
assign MMR_CDbgNode2Eap1_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode2Eap1_F_Action1_Data = (CLA_CDBGNODE2EAP1_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_Action1), 64'(MMR_CDbgNode2Eap1_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_Action1_Data_prev = MMR_CDbgNode2Eap1_F_Action1;
assign MMR_CDbgNode2Eap1_F_Action1_Data_muxed = MMR_CDbgNode2Eap1_F_Action1_WrEn ? MMR_CDbgNode2Eap1_F_Action1_Data : MMR_CDbgNode2Eap1_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_ACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_Action1_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_Action1_Data),
    .out   (MMR_CDbgNode2Eap1_F_Action1)
);

logic                                           MMR_CDbgNode2Eap1_F_Action0_WrEn;
logic [CLA_CDBGNODE2EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action0_Data;
logic [CLA_CDBGNODE2EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action0_DataEff;
logic [CLA_CDBGNODE2EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action0_Data_muxed;
logic [CLA_CDBGNODE2EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap1_F_Action0_Data_prev;
assign MMR_CDbgNode2Eap1_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode2Eap1_F_Action0_Data = (CLA_CDBGNODE2EAP1_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_Action0), 64'(MMR_CDbgNode2Eap1_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_Action0_Data_prev = MMR_CDbgNode2Eap1_F_Action0;
assign MMR_CDbgNode2Eap1_F_Action0_Data_muxed = MMR_CDbgNode2Eap1_F_Action0_WrEn ? MMR_CDbgNode2Eap1_F_Action0_Data : MMR_CDbgNode2Eap1_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_ACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_Action0_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_Action0_Data),
    .out   (MMR_CDbgNode2Eap1_F_Action0)
);

logic                                           MMR_CDbgNode2Eap1_F_DestNode_WrEn;
logic [CLA_CDBGNODE2EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap1_F_DestNode_Data;
logic [CLA_CDBGNODE2EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap1_F_DestNode_DataEff;
logic [CLA_CDBGNODE2EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap1_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE2EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap1_F_DestNode_Data_prev;
assign MMR_CDbgNode2Eap1_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode2Eap1_F_DestNode_Data = (CLA_CDBGNODE2EAP1_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap1_F_DestNode), 64'(MMR_CDbgNode2Eap1_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap1_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP1))));
assign MMR_CDbgNode2Eap1_F_DestNode_Data_prev = MMR_CDbgNode2Eap1_F_DestNode;
assign MMR_CDbgNode2Eap1_F_DestNode_Data_muxed = MMR_CDbgNode2Eap1_F_DestNode_WrEn ? MMR_CDbgNode2Eap1_F_DestNode_Data : MMR_CDbgNode2Eap1_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP1_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP1_DESTNODE_WIDTH'(0))
) MMR_CDbgNode2Eap1_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap1_F_DestNode_WrEn),
    .in    (MMR_CDbgNode2Eap1_F_DestNode_Data),
    .out   (MMR_CDbgNode2Eap1_F_DestNode)
);

logic                                           MMR_CDbgNode3Eap0_F_Action3_WrEn;
logic [CLA_CDBGNODE3EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action3_Data;
logic [CLA_CDBGNODE3EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action3_DataEff;
logic [CLA_CDBGNODE3EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action3_Data_muxed;
logic [CLA_CDBGNODE3EAP0_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action3_Data_prev;
assign MMR_CDbgNode3Eap0_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode3Eap0_F_Action3_Data = (CLA_CDBGNODE3EAP0_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_Action3), 64'(MMR_CDbgNode3Eap0_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_Action3_Data_prev = MMR_CDbgNode3Eap0_F_Action3;
assign MMR_CDbgNode3Eap0_F_Action3_Data_muxed = MMR_CDbgNode3Eap0_F_Action3_WrEn ? MMR_CDbgNode3Eap0_F_Action3_Data : MMR_CDbgNode3Eap0_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_ACTION3_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_Action3_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_Action3_Data),
    .out   (MMR_CDbgNode3Eap0_F_Action3)
);

logic                                           MMR_CDbgNode3Eap0_F_Action2_WrEn;
logic [CLA_CDBGNODE3EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action2_Data;
logic [CLA_CDBGNODE3EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action2_DataEff;
logic [CLA_CDBGNODE3EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action2_Data_muxed;
logic [CLA_CDBGNODE3EAP0_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action2_Data_prev;
assign MMR_CDbgNode3Eap0_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode3Eap0_F_Action2_Data = (CLA_CDBGNODE3EAP0_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_Action2), 64'(MMR_CDbgNode3Eap0_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_Action2_Data_prev = MMR_CDbgNode3Eap0_F_Action2;
assign MMR_CDbgNode3Eap0_F_Action2_Data_muxed = MMR_CDbgNode3Eap0_F_Action2_WrEn ? MMR_CDbgNode3Eap0_F_Action2_Data : MMR_CDbgNode3Eap0_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_ACTION2_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_Action2_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_Action2_Data),
    .out   (MMR_CDbgNode3Eap0_F_Action2)
);

logic                                           MMR_CDbgNode3Eap0_F_Udf_WrEn;
logic [CLA_CDBGNODE3EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap0_F_Udf_Data;
logic [CLA_CDBGNODE3EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap0_F_Udf_DataEff;
logic [CLA_CDBGNODE3EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap0_F_Udf_Data_muxed;
logic [CLA_CDBGNODE3EAP0_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap0_F_Udf_Data_prev;
assign MMR_CDbgNode3Eap0_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode3Eap0_F_Udf_Data = (CLA_CDBGNODE3EAP0_UDF_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_Udf), 64'(MMR_CDbgNode3Eap0_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_Udf_Data_prev = MMR_CDbgNode3Eap0_F_Udf;
assign MMR_CDbgNode3Eap0_F_Udf_Data_muxed = MMR_CDbgNode3Eap0_F_Udf_WrEn ? MMR_CDbgNode3Eap0_F_Udf_Data : MMR_CDbgNode3Eap0_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_UDF_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_Udf_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_Udf_Data),
    .out   (MMR_CDbgNode3Eap0_F_Udf)
);

logic                                           MMR_CDbgNode3Eap0_F_EventType2_WrEn;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType2_Data;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType2_DataEff;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType2_Data_prev;
assign MMR_CDbgNode3Eap0_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode3Eap0_F_EventType2_Data = (CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_EventType2), 64'(MMR_CDbgNode3Eap0_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_EventType2_Data_prev = MMR_CDbgNode3Eap0_F_EventType2;
assign MMR_CDbgNode3Eap0_F_EventType2_Data_muxed = MMR_CDbgNode3Eap0_F_EventType2_WrEn ? MMR_CDbgNode3Eap0_F_EventType2_Data : MMR_CDbgNode3Eap0_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_EventType2_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_EventType2_Data),
    .out   (MMR_CDbgNode3Eap0_F_EventType2)
);

logic                                           MMR_CDbgNode3Eap0_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode3Eap0_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data = (CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_CustomAction1Enable), 64'(MMR_CDbgNode3Eap0_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_prev = MMR_CDbgNode3Eap0_F_CustomAction1Enable;
assign MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode3Eap0_F_CustomAction1Enable_WrEn ? MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data : MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode3Eap0_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode3Eap0_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode3Eap0_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data = (CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_CustomAction0Enable), 64'(MMR_CDbgNode3Eap0_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_prev = MMR_CDbgNode3Eap0_F_CustomAction0Enable;
assign MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode3Eap0_F_CustomAction0Enable_WrEn ? MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data : MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode3Eap0_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode3Eap0_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1_Data;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction1_Data_prev;
assign MMR_CDbgNode3Eap0_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode3Eap0_F_CustomAction1_Data = (CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_CustomAction1), 64'(MMR_CDbgNode3Eap0_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_CustomAction1_Data_prev = MMR_CDbgNode3Eap0_F_CustomAction1;
assign MMR_CDbgNode3Eap0_F_CustomAction1_Data_muxed = MMR_CDbgNode3Eap0_F_CustomAction1_WrEn ? MMR_CDbgNode3Eap0_F_CustomAction1_Data : MMR_CDbgNode3Eap0_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_CustomAction1_Data),
    .out   (MMR_CDbgNode3Eap0_F_CustomAction1)
);

logic                                           MMR_CDbgNode3Eap0_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0_Data;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap0_F_CustomAction0_Data_prev;
assign MMR_CDbgNode3Eap0_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode3Eap0_F_CustomAction0_Data = (CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_CustomAction0), 64'(MMR_CDbgNode3Eap0_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_CustomAction0_Data_prev = MMR_CDbgNode3Eap0_F_CustomAction0;
assign MMR_CDbgNode3Eap0_F_CustomAction0_Data_muxed = MMR_CDbgNode3Eap0_F_CustomAction0_WrEn ? MMR_CDbgNode3Eap0_F_CustomAction0_Data : MMR_CDbgNode3Eap0_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_CustomAction0_Data),
    .out   (MMR_CDbgNode3Eap0_F_CustomAction0)
);

logic                                           MMR_CDbgNode3Eap0_F_EventType1_WrEn;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType1_Data;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType1_DataEff;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType1_Data_prev;
assign MMR_CDbgNode3Eap0_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode3Eap0_F_EventType1_Data = (CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_EventType1), 64'(MMR_CDbgNode3Eap0_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_EventType1_Data_prev = MMR_CDbgNode3Eap0_F_EventType1;
assign MMR_CDbgNode3Eap0_F_EventType1_Data_muxed = MMR_CDbgNode3Eap0_F_EventType1_WrEn ? MMR_CDbgNode3Eap0_F_EventType1_Data : MMR_CDbgNode3Eap0_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_EventType1_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_EventType1_Data),
    .out   (MMR_CDbgNode3Eap0_F_EventType1)
);

logic                                           MMR_CDbgNode3Eap0_F_EventType0_WrEn;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType0_Data;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType0_DataEff;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap0_F_EventType0_Data_prev;
assign MMR_CDbgNode3Eap0_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode3Eap0_F_EventType0_Data = (CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_EventType0), 64'(MMR_CDbgNode3Eap0_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_EventType0_Data_prev = MMR_CDbgNode3Eap0_F_EventType0;
assign MMR_CDbgNode3Eap0_F_EventType0_Data_muxed = MMR_CDbgNode3Eap0_F_EventType0_WrEn ? MMR_CDbgNode3Eap0_F_EventType0_Data : MMR_CDbgNode3Eap0_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_EventType0_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_EventType0_Data),
    .out   (MMR_CDbgNode3Eap0_F_EventType0)
);

logic                                           MMR_CDbgNode3Eap0_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap0_F_LogicalOp_Data;
logic [CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap0_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap0_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap0_F_LogicalOp_Data_prev;
assign MMR_CDbgNode3Eap0_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode3Eap0_F_LogicalOp_Data = (CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_LogicalOp), 64'(MMR_CDbgNode3Eap0_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_LogicalOp_Data_prev = MMR_CDbgNode3Eap0_F_LogicalOp;
assign MMR_CDbgNode3Eap0_F_LogicalOp_Data_muxed = MMR_CDbgNode3Eap0_F_LogicalOp_WrEn ? MMR_CDbgNode3Eap0_F_LogicalOp_Data : MMR_CDbgNode3Eap0_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_LogicalOp_Data),
    .out   (MMR_CDbgNode3Eap0_F_LogicalOp)
);

logic                                           MMR_CDbgNode3Eap0_F_Action1_WrEn;
logic [CLA_CDBGNODE3EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action1_Data;
logic [CLA_CDBGNODE3EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action1_DataEff;
logic [CLA_CDBGNODE3EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action1_Data_muxed;
logic [CLA_CDBGNODE3EAP0_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action1_Data_prev;
assign MMR_CDbgNode3Eap0_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode3Eap0_F_Action1_Data = (CLA_CDBGNODE3EAP0_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_Action1), 64'(MMR_CDbgNode3Eap0_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_Action1_Data_prev = MMR_CDbgNode3Eap0_F_Action1;
assign MMR_CDbgNode3Eap0_F_Action1_Data_muxed = MMR_CDbgNode3Eap0_F_Action1_WrEn ? MMR_CDbgNode3Eap0_F_Action1_Data : MMR_CDbgNode3Eap0_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_ACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_Action1_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_Action1_Data),
    .out   (MMR_CDbgNode3Eap0_F_Action1)
);

logic                                           MMR_CDbgNode3Eap0_F_Action0_WrEn;
logic [CLA_CDBGNODE3EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action0_Data;
logic [CLA_CDBGNODE3EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action0_DataEff;
logic [CLA_CDBGNODE3EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action0_Data_muxed;
logic [CLA_CDBGNODE3EAP0_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap0_F_Action0_Data_prev;
assign MMR_CDbgNode3Eap0_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode3Eap0_F_Action0_Data = (CLA_CDBGNODE3EAP0_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_Action0), 64'(MMR_CDbgNode3Eap0_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_Action0_Data_prev = MMR_CDbgNode3Eap0_F_Action0;
assign MMR_CDbgNode3Eap0_F_Action0_Data_muxed = MMR_CDbgNode3Eap0_F_Action0_WrEn ? MMR_CDbgNode3Eap0_F_Action0_Data : MMR_CDbgNode3Eap0_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_ACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_Action0_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_Action0_Data),
    .out   (MMR_CDbgNode3Eap0_F_Action0)
);

logic                                           MMR_CDbgNode3Eap0_F_DestNode_WrEn;
logic [CLA_CDBGNODE3EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap0_F_DestNode_Data;
logic [CLA_CDBGNODE3EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap0_F_DestNode_DataEff;
logic [CLA_CDBGNODE3EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap0_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE3EAP0_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap0_F_DestNode_Data_prev;
assign MMR_CDbgNode3Eap0_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode3Eap0_F_DestNode_Data = (CLA_CDBGNODE3EAP0_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap0_F_DestNode), 64'(MMR_CDbgNode3Eap0_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap0_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP0))));
assign MMR_CDbgNode3Eap0_F_DestNode_Data_prev = MMR_CDbgNode3Eap0_F_DestNode;
assign MMR_CDbgNode3Eap0_F_DestNode_Data_muxed = MMR_CDbgNode3Eap0_F_DestNode_WrEn ? MMR_CDbgNode3Eap0_F_DestNode_Data : MMR_CDbgNode3Eap0_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP0_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP0_DESTNODE_WIDTH'(0))
) MMR_CDbgNode3Eap0_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap0_F_DestNode_WrEn),
    .in    (MMR_CDbgNode3Eap0_F_DestNode_Data),
    .out   (MMR_CDbgNode3Eap0_F_DestNode)
);

logic                                           MMR_CDbgNode3Eap1_F_Action3_WrEn;
logic [CLA_CDBGNODE3EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action3_Data;
logic [CLA_CDBGNODE3EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action3_DataEff;
logic [CLA_CDBGNODE3EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action3_Data_muxed;
logic [CLA_CDBGNODE3EAP1_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action3_Data_prev;
assign MMR_CDbgNode3Eap1_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode3Eap1_F_Action3_Data = (CLA_CDBGNODE3EAP1_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_Action3), 64'(MMR_CDbgNode3Eap1_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_Action3_Data_prev = MMR_CDbgNode3Eap1_F_Action3;
assign MMR_CDbgNode3Eap1_F_Action3_Data_muxed = MMR_CDbgNode3Eap1_F_Action3_WrEn ? MMR_CDbgNode3Eap1_F_Action3_Data : MMR_CDbgNode3Eap1_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_ACTION3_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_Action3_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_Action3_Data),
    .out   (MMR_CDbgNode3Eap1_F_Action3)
);

logic                                           MMR_CDbgNode3Eap1_F_Action2_WrEn;
logic [CLA_CDBGNODE3EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action2_Data;
logic [CLA_CDBGNODE3EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action2_DataEff;
logic [CLA_CDBGNODE3EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action2_Data_muxed;
logic [CLA_CDBGNODE3EAP1_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action2_Data_prev;
assign MMR_CDbgNode3Eap1_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode3Eap1_F_Action2_Data = (CLA_CDBGNODE3EAP1_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_Action2), 64'(MMR_CDbgNode3Eap1_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_Action2_Data_prev = MMR_CDbgNode3Eap1_F_Action2;
assign MMR_CDbgNode3Eap1_F_Action2_Data_muxed = MMR_CDbgNode3Eap1_F_Action2_WrEn ? MMR_CDbgNode3Eap1_F_Action2_Data : MMR_CDbgNode3Eap1_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_ACTION2_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_Action2_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_Action2_Data),
    .out   (MMR_CDbgNode3Eap1_F_Action2)
);

logic                                           MMR_CDbgNode3Eap1_F_Udf_WrEn;
logic [CLA_CDBGNODE3EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap1_F_Udf_Data;
logic [CLA_CDBGNODE3EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap1_F_Udf_DataEff;
logic [CLA_CDBGNODE3EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap1_F_Udf_Data_muxed;
logic [CLA_CDBGNODE3EAP1_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap1_F_Udf_Data_prev;
assign MMR_CDbgNode3Eap1_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode3Eap1_F_Udf_Data = (CLA_CDBGNODE3EAP1_UDF_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_Udf), 64'(MMR_CDbgNode3Eap1_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_Udf_Data_prev = MMR_CDbgNode3Eap1_F_Udf;
assign MMR_CDbgNode3Eap1_F_Udf_Data_muxed = MMR_CDbgNode3Eap1_F_Udf_WrEn ? MMR_CDbgNode3Eap1_F_Udf_Data : MMR_CDbgNode3Eap1_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_UDF_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_Udf_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_Udf_Data),
    .out   (MMR_CDbgNode3Eap1_F_Udf)
);

logic                                           MMR_CDbgNode3Eap1_F_EventType2_WrEn;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType2_Data;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType2_DataEff;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType2_Data_prev;
assign MMR_CDbgNode3Eap1_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode3Eap1_F_EventType2_Data = (CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_EventType2), 64'(MMR_CDbgNode3Eap1_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_EventType2_Data_prev = MMR_CDbgNode3Eap1_F_EventType2;
assign MMR_CDbgNode3Eap1_F_EventType2_Data_muxed = MMR_CDbgNode3Eap1_F_EventType2_WrEn ? MMR_CDbgNode3Eap1_F_EventType2_Data : MMR_CDbgNode3Eap1_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_EventType2_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_EventType2_Data),
    .out   (MMR_CDbgNode3Eap1_F_EventType2)
);

logic                                           MMR_CDbgNode3Eap1_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode3Eap1_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data = (CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_CustomAction1Enable), 64'(MMR_CDbgNode3Eap1_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_prev = MMR_CDbgNode3Eap1_F_CustomAction1Enable;
assign MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode3Eap1_F_CustomAction1Enable_WrEn ? MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data : MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode3Eap1_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode3Eap1_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode3Eap1_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data = (CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_CustomAction0Enable), 64'(MMR_CDbgNode3Eap1_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_prev = MMR_CDbgNode3Eap1_F_CustomAction0Enable;
assign MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode3Eap1_F_CustomAction0Enable_WrEn ? MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data : MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode3Eap1_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode3Eap1_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1_Data;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction1_Data_prev;
assign MMR_CDbgNode3Eap1_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode3Eap1_F_CustomAction1_Data = (CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_CustomAction1), 64'(MMR_CDbgNode3Eap1_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_CustomAction1_Data_prev = MMR_CDbgNode3Eap1_F_CustomAction1;
assign MMR_CDbgNode3Eap1_F_CustomAction1_Data_muxed = MMR_CDbgNode3Eap1_F_CustomAction1_WrEn ? MMR_CDbgNode3Eap1_F_CustomAction1_Data : MMR_CDbgNode3Eap1_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_CustomAction1_Data),
    .out   (MMR_CDbgNode3Eap1_F_CustomAction1)
);

logic                                           MMR_CDbgNode3Eap1_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0_Data;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap1_F_CustomAction0_Data_prev;
assign MMR_CDbgNode3Eap1_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode3Eap1_F_CustomAction0_Data = (CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_CustomAction0), 64'(MMR_CDbgNode3Eap1_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_CustomAction0_Data_prev = MMR_CDbgNode3Eap1_F_CustomAction0;
assign MMR_CDbgNode3Eap1_F_CustomAction0_Data_muxed = MMR_CDbgNode3Eap1_F_CustomAction0_WrEn ? MMR_CDbgNode3Eap1_F_CustomAction0_Data : MMR_CDbgNode3Eap1_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_CustomAction0_Data),
    .out   (MMR_CDbgNode3Eap1_F_CustomAction0)
);

logic                                           MMR_CDbgNode3Eap1_F_EventType1_WrEn;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType1_Data;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType1_DataEff;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType1_Data_prev;
assign MMR_CDbgNode3Eap1_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode3Eap1_F_EventType1_Data = (CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_EventType1), 64'(MMR_CDbgNode3Eap1_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_EventType1_Data_prev = MMR_CDbgNode3Eap1_F_EventType1;
assign MMR_CDbgNode3Eap1_F_EventType1_Data_muxed = MMR_CDbgNode3Eap1_F_EventType1_WrEn ? MMR_CDbgNode3Eap1_F_EventType1_Data : MMR_CDbgNode3Eap1_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_EventType1_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_EventType1_Data),
    .out   (MMR_CDbgNode3Eap1_F_EventType1)
);

logic                                           MMR_CDbgNode3Eap1_F_EventType0_WrEn;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType0_Data;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType0_DataEff;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap1_F_EventType0_Data_prev;
assign MMR_CDbgNode3Eap1_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode3Eap1_F_EventType0_Data = (CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_EventType0), 64'(MMR_CDbgNode3Eap1_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_EventType0_Data_prev = MMR_CDbgNode3Eap1_F_EventType0;
assign MMR_CDbgNode3Eap1_F_EventType0_Data_muxed = MMR_CDbgNode3Eap1_F_EventType0_WrEn ? MMR_CDbgNode3Eap1_F_EventType0_Data : MMR_CDbgNode3Eap1_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_EventType0_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_EventType0_Data),
    .out   (MMR_CDbgNode3Eap1_F_EventType0)
);

logic                                           MMR_CDbgNode3Eap1_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap1_F_LogicalOp_Data;
logic [CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap1_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap1_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap1_F_LogicalOp_Data_prev;
assign MMR_CDbgNode3Eap1_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode3Eap1_F_LogicalOp_Data = (CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_LogicalOp), 64'(MMR_CDbgNode3Eap1_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_LogicalOp_Data_prev = MMR_CDbgNode3Eap1_F_LogicalOp;
assign MMR_CDbgNode3Eap1_F_LogicalOp_Data_muxed = MMR_CDbgNode3Eap1_F_LogicalOp_WrEn ? MMR_CDbgNode3Eap1_F_LogicalOp_Data : MMR_CDbgNode3Eap1_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_LogicalOp_Data),
    .out   (MMR_CDbgNode3Eap1_F_LogicalOp)
);

logic                                           MMR_CDbgNode3Eap1_F_Action1_WrEn;
logic [CLA_CDBGNODE3EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action1_Data;
logic [CLA_CDBGNODE3EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action1_DataEff;
logic [CLA_CDBGNODE3EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action1_Data_muxed;
logic [CLA_CDBGNODE3EAP1_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action1_Data_prev;
assign MMR_CDbgNode3Eap1_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode3Eap1_F_Action1_Data = (CLA_CDBGNODE3EAP1_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_Action1), 64'(MMR_CDbgNode3Eap1_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_Action1_Data_prev = MMR_CDbgNode3Eap1_F_Action1;
assign MMR_CDbgNode3Eap1_F_Action1_Data_muxed = MMR_CDbgNode3Eap1_F_Action1_WrEn ? MMR_CDbgNode3Eap1_F_Action1_Data : MMR_CDbgNode3Eap1_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_ACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_Action1_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_Action1_Data),
    .out   (MMR_CDbgNode3Eap1_F_Action1)
);

logic                                           MMR_CDbgNode3Eap1_F_Action0_WrEn;
logic [CLA_CDBGNODE3EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action0_Data;
logic [CLA_CDBGNODE3EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action0_DataEff;
logic [CLA_CDBGNODE3EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action0_Data_muxed;
logic [CLA_CDBGNODE3EAP1_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap1_F_Action0_Data_prev;
assign MMR_CDbgNode3Eap1_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode3Eap1_F_Action0_Data = (CLA_CDBGNODE3EAP1_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_Action0), 64'(MMR_CDbgNode3Eap1_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_Action0_Data_prev = MMR_CDbgNode3Eap1_F_Action0;
assign MMR_CDbgNode3Eap1_F_Action0_Data_muxed = MMR_CDbgNode3Eap1_F_Action0_WrEn ? MMR_CDbgNode3Eap1_F_Action0_Data : MMR_CDbgNode3Eap1_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_ACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_Action0_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_Action0_Data),
    .out   (MMR_CDbgNode3Eap1_F_Action0)
);

logic                                           MMR_CDbgNode3Eap1_F_DestNode_WrEn;
logic [CLA_CDBGNODE3EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap1_F_DestNode_Data;
logic [CLA_CDBGNODE3EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap1_F_DestNode_DataEff;
logic [CLA_CDBGNODE3EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap1_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE3EAP1_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap1_F_DestNode_Data_prev;
assign MMR_CDbgNode3Eap1_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode3Eap1_F_DestNode_Data = (CLA_CDBGNODE3EAP1_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap1_F_DestNode), 64'(MMR_CDbgNode3Eap1_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap1_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP1))));
assign MMR_CDbgNode3Eap1_F_DestNode_Data_prev = MMR_CDbgNode3Eap1_F_DestNode;
assign MMR_CDbgNode3Eap1_F_DestNode_Data_muxed = MMR_CDbgNode3Eap1_F_DestNode_WrEn ? MMR_CDbgNode3Eap1_F_DestNode_Data : MMR_CDbgNode3Eap1_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP1_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP1_DESTNODE_WIDTH'(0))
) MMR_CDbgNode3Eap1_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap1_F_DestNode_WrEn),
    .in    (MMR_CDbgNode3Eap1_F_DestNode_Data),
    .out   (MMR_CDbgNode3Eap1_F_DestNode)
);

logic                                           MMR_CDbgSignalMask0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMask0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask0Lo_F_Value[31:0]};
assign MMR_CDbgSignalMask0Lo_F_Value_Data = (CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask0Lo_F_Value), 64'(MMR_CDbgSignalMask0Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask0Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK0LO))));
assign MMR_CDbgSignalMask0Lo_F_Value_Data_prev = MMR_CDbgSignalMask0Lo_F_Value;
assign MMR_CDbgSignalMask0Lo_F_Value_Data_muxed = MMR_CDbgSignalMask0Lo_F_Value_WrEn ? MMR_CDbgSignalMask0Lo_F_Value_Data : MMR_CDbgSignalMask0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMask0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMask0Lo_F_Value)
);

logic                                           MMR_CDbgSignalMatch0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMatch0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch0Lo_F_Value[31:0]};
assign MMR_CDbgSignalMatch0Lo_F_Value_Data = (CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch0Lo_F_Value), 64'(MMR_CDbgSignalMatch0Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch0Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH0LO))));
assign MMR_CDbgSignalMatch0Lo_F_Value_Data_prev = MMR_CDbgSignalMatch0Lo_F_Value;
assign MMR_CDbgSignalMatch0Lo_F_Value_Data_muxed = MMR_CDbgSignalMatch0Lo_F_Value_WrEn ? MMR_CDbgSignalMatch0Lo_F_Value_Data : MMR_CDbgSignalMatch0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMatch0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMatch0Lo_F_Value)
);

logic                                           MMR_CDbgSignalMask1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMask1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask1Lo_F_Value[31:0]};
assign MMR_CDbgSignalMask1Lo_F_Value_Data = (CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask1Lo_F_Value), 64'(MMR_CDbgSignalMask1Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask1Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK1LO))));
assign MMR_CDbgSignalMask1Lo_F_Value_Data_prev = MMR_CDbgSignalMask1Lo_F_Value;
assign MMR_CDbgSignalMask1Lo_F_Value_Data_muxed = MMR_CDbgSignalMask1Lo_F_Value_WrEn ? MMR_CDbgSignalMask1Lo_F_Value_Data : MMR_CDbgSignalMask1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMask1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMask1Lo_F_Value)
);

logic                                           MMR_CDbgSignalMatch1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMatch1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch1Lo_F_Value[31:0]};
assign MMR_CDbgSignalMatch1Lo_F_Value_Data = (CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch1Lo_F_Value), 64'(MMR_CDbgSignalMatch1Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch1Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH1LO))));
assign MMR_CDbgSignalMatch1Lo_F_Value_Data_prev = MMR_CDbgSignalMatch1Lo_F_Value;
assign MMR_CDbgSignalMatch1Lo_F_Value_Data_muxed = MMR_CDbgSignalMatch1Lo_F_Value_WrEn ? MMR_CDbgSignalMatch1Lo_F_Value_Data : MMR_CDbgSignalMatch1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMatch1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMatch1Lo_F_Value)
);

logic                                           MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_WrEn;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_DataEff;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_muxed;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_prev;
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_DataEff = {reg_wr_data[15:15]};
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data = (CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH'(update_value(64'(MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1), 64'(MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALEDGEDETECTCFG))));
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_prev = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1;
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_muxed = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_WrEn ? MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data : MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL1_WIDTH'(0))
) MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_WrEn),
    .in    (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data),
    .out   (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1)
);

logic                                           MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_WrEn;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_DataEff;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_muxed;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_prev;
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_DataEff = {reg_wr_data[14:8]};
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data = (CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH'(update_value(64'(MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select), 64'(MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_DataEff[6:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALEDGEDETECTCFG))));
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_prev = MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select;
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_muxed = MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_WrEn ? MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data : MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL1SELECT_WIDTH'(0))
) MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_WrEn),
    .in    (MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data),
    .out   (MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select)
);

logic                                           MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_WrEn;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_DataEff;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_muxed;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_prev;
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_DataEff = {reg_wr_data[7:7]};
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data = (CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH'(update_value(64'(MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0), 64'(MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALEDGEDETECTCFG))));
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_prev = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0;
assign MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_muxed = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_WrEn ? MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data : MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALEDGEDETECTCFG_POSEDGESIGNAL0_WIDTH'(0))
) MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_WrEn),
    .in    (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data),
    .out   (MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0)
);

logic                                           MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_WrEn;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_DataEff;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_muxed;
logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH-1:0] MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_prev;
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_DataEff = {reg_wr_data[6:0]};
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data = (CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH'(update_value(64'(MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select), 64'(MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_DataEff[6:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALEDGEDETECTCFG))));
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_prev = MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select;
assign MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_muxed = MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_WrEn ? MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data : MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALEDGEDETECTCFG_SIGNAL0SELECT_WIDTH'(0))
) MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_WrEn),
    .in    (MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data),
    .out   (MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap3W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap3W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap3W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap3W2C_DataEff = {reg_wr_data[47:47]};
assign MMR_CDbgEapStatus_F_Node3Eap3W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node3Eap3W2C), 64'(MMR_CDbgEapStatus_F_Node3Eap3W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node3Eap3W2C);
assign MMR_CDbgEapStatus_F_Node3Eap3W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node3Eap3W2CWrEn));
assign MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_prev = MMR_CDbgEapStatus_F_Node3Eap3W2C;
assign MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap3W2C_WrEn ? MMR_CDbgEapStatus_F_Node3Eap3W2C_Data : MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP3W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap3W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap3W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap3W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap3W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap2W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap2W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap2W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap2W2C_DataEff = {reg_wr_data[46:46]};
assign MMR_CDbgEapStatus_F_Node3Eap2W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node3Eap2W2C), 64'(MMR_CDbgEapStatus_F_Node3Eap2W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node3Eap2W2C);
assign MMR_CDbgEapStatus_F_Node3Eap2W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node3Eap2W2CWrEn));
assign MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_prev = MMR_CDbgEapStatus_F_Node3Eap2W2C;
assign MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap2W2C_WrEn ? MMR_CDbgEapStatus_F_Node3Eap2W2C_Data : MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP2W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap2W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap2W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap2W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap2W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap1W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap1W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap1W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap1W2C_DataEff = {reg_wr_data[45:45]};
assign MMR_CDbgEapStatus_F_Node3Eap1W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node3Eap1W2C), 64'(MMR_CDbgEapStatus_F_Node3Eap1W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node3Eap1W2C);
assign MMR_CDbgEapStatus_F_Node3Eap1W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node3Eap1W2CWrEn));
assign MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_prev = MMR_CDbgEapStatus_F_Node3Eap1W2C;
assign MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap1W2C_WrEn ? MMR_CDbgEapStatus_F_Node3Eap1W2C_Data : MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP1W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap1W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap1W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap1W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap1W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap0W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap0W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap0W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap0W2C_DataEff = {reg_wr_data[44:44]};
assign MMR_CDbgEapStatus_F_Node3Eap0W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node3Eap0W2C), 64'(MMR_CDbgEapStatus_F_Node3Eap0W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node3Eap0W2C);
assign MMR_CDbgEapStatus_F_Node3Eap0W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node3Eap0W2CWrEn));
assign MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_prev = MMR_CDbgEapStatus_F_Node3Eap0W2C;
assign MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap0W2C_WrEn ? MMR_CDbgEapStatus_F_Node3Eap0W2C_Data : MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP0W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap0W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap0W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap0W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap0W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap3W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap3W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap3W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap3W2C_DataEff = {reg_wr_data[43:43]};
assign MMR_CDbgEapStatus_F_Node2Eap3W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node2Eap3W2C), 64'(MMR_CDbgEapStatus_F_Node2Eap3W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node2Eap3W2C);
assign MMR_CDbgEapStatus_F_Node2Eap3W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node2Eap3W2CWrEn));
assign MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_prev = MMR_CDbgEapStatus_F_Node2Eap3W2C;
assign MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap3W2C_WrEn ? MMR_CDbgEapStatus_F_Node2Eap3W2C_Data : MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP3W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap3W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap3W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap3W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap3W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap2W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap2W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap2W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap2W2C_DataEff = {reg_wr_data[42:42]};
assign MMR_CDbgEapStatus_F_Node2Eap2W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node2Eap2W2C), 64'(MMR_CDbgEapStatus_F_Node2Eap2W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node2Eap2W2C);
assign MMR_CDbgEapStatus_F_Node2Eap2W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node2Eap2W2CWrEn));
assign MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_prev = MMR_CDbgEapStatus_F_Node2Eap2W2C;
assign MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap2W2C_WrEn ? MMR_CDbgEapStatus_F_Node2Eap2W2C_Data : MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP2W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap2W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap2W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap2W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap2W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap1W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap1W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap1W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap1W2C_DataEff = {reg_wr_data[41:41]};
assign MMR_CDbgEapStatus_F_Node2Eap1W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node2Eap1W2C), 64'(MMR_CDbgEapStatus_F_Node2Eap1W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node2Eap1W2C);
assign MMR_CDbgEapStatus_F_Node2Eap1W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node2Eap1W2CWrEn));
assign MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_prev = MMR_CDbgEapStatus_F_Node2Eap1W2C;
assign MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap1W2C_WrEn ? MMR_CDbgEapStatus_F_Node2Eap1W2C_Data : MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP1W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap1W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap1W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap1W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap1W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap0W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap0W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap0W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap0W2C_DataEff = {reg_wr_data[40:40]};
assign MMR_CDbgEapStatus_F_Node2Eap0W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node2Eap0W2C), 64'(MMR_CDbgEapStatus_F_Node2Eap0W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node2Eap0W2C);
assign MMR_CDbgEapStatus_F_Node2Eap0W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node2Eap0W2CWrEn));
assign MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_prev = MMR_CDbgEapStatus_F_Node2Eap0W2C;
assign MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap0W2C_WrEn ? MMR_CDbgEapStatus_F_Node2Eap0W2C_Data : MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP0W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap0W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap0W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap0W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap0W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap3W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap3W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap3W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap3W2C_DataEff = {reg_wr_data[39:39]};
assign MMR_CDbgEapStatus_F_Node1Eap3W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node1Eap3W2C), 64'(MMR_CDbgEapStatus_F_Node1Eap3W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node1Eap3W2C);
assign MMR_CDbgEapStatus_F_Node1Eap3W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node1Eap3W2CWrEn));
assign MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_prev = MMR_CDbgEapStatus_F_Node1Eap3W2C;
assign MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap3W2C_WrEn ? MMR_CDbgEapStatus_F_Node1Eap3W2C_Data : MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP3W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap3W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap3W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap3W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap3W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap2W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap2W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap2W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap2W2C_DataEff = {reg_wr_data[38:38]};
assign MMR_CDbgEapStatus_F_Node1Eap2W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node1Eap2W2C), 64'(MMR_CDbgEapStatus_F_Node1Eap2W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node1Eap2W2C);
assign MMR_CDbgEapStatus_F_Node1Eap2W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node1Eap2W2CWrEn));
assign MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_prev = MMR_CDbgEapStatus_F_Node1Eap2W2C;
assign MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap2W2C_WrEn ? MMR_CDbgEapStatus_F_Node1Eap2W2C_Data : MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP2W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap2W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap2W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap2W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap2W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap1W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap1W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap1W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap1W2C_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgEapStatus_F_Node1Eap1W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node1Eap1W2C), 64'(MMR_CDbgEapStatus_F_Node1Eap1W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node1Eap1W2C);
assign MMR_CDbgEapStatus_F_Node1Eap1W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node1Eap1W2CWrEn));
assign MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_prev = MMR_CDbgEapStatus_F_Node1Eap1W2C;
assign MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap1W2C_WrEn ? MMR_CDbgEapStatus_F_Node1Eap1W2C_Data : MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP1W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap1W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap1W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap1W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap1W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap0W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap0W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap0W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap0W2C_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgEapStatus_F_Node1Eap0W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node1Eap0W2C), 64'(MMR_CDbgEapStatus_F_Node1Eap0W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node1Eap0W2C);
assign MMR_CDbgEapStatus_F_Node1Eap0W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node1Eap0W2CWrEn));
assign MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_prev = MMR_CDbgEapStatus_F_Node1Eap0W2C;
assign MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap0W2C_WrEn ? MMR_CDbgEapStatus_F_Node1Eap0W2C_Data : MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP0W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap0W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap0W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap0W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap0W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap3W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap3W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap3W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap3W2C_DataEff = {reg_wr_data[35:35]};
assign MMR_CDbgEapStatus_F_Node0Eap3W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node0Eap3W2C), 64'(MMR_CDbgEapStatus_F_Node0Eap3W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node0Eap3W2C);
assign MMR_CDbgEapStatus_F_Node0Eap3W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node0Eap3W2CWrEn));
assign MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_prev = MMR_CDbgEapStatus_F_Node0Eap3W2C;
assign MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap3W2C_WrEn ? MMR_CDbgEapStatus_F_Node0Eap3W2C_Data : MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP3W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap3W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap3W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap3W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap3W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap2W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap2W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap2W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap2W2C_DataEff = {reg_wr_data[34:34]};
assign MMR_CDbgEapStatus_F_Node0Eap2W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node0Eap2W2C), 64'(MMR_CDbgEapStatus_F_Node0Eap2W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node0Eap2W2C);
assign MMR_CDbgEapStatus_F_Node0Eap2W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node0Eap2W2CWrEn));
assign MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_prev = MMR_CDbgEapStatus_F_Node0Eap2W2C;
assign MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap2W2C_WrEn ? MMR_CDbgEapStatus_F_Node0Eap2W2C_Data : MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP2W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap2W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap2W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap2W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap2W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap1W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap1W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap1W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap1W2C_DataEff = {reg_wr_data[33:33]};
assign MMR_CDbgEapStatus_F_Node0Eap1W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node0Eap1W2C), 64'(MMR_CDbgEapStatus_F_Node0Eap1W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node0Eap1W2C);
assign MMR_CDbgEapStatus_F_Node0Eap1W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node0Eap1W2CWrEn));
assign MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_prev = MMR_CDbgEapStatus_F_Node0Eap1W2C;
assign MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap1W2C_WrEn ? MMR_CDbgEapStatus_F_Node0Eap1W2C_Data : MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP1W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap1W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap1W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap1W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap1W2C)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap0W2C_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap0W2C_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap0W2C_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH-1:0] MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap0W2C_DataEff = {reg_wr_data[32:32]};
assign MMR_CDbgEapStatus_F_Node0Eap0W2C_Data = ((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) ? CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH'(update_value(64'(MMR_CDbgEapStatus_F_Node0Eap0W2C), 64'(MMR_CDbgEapStatus_F_Node0Eap0W2C_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgeapstatusWr.Data.Node0Eap0W2C);
assign MMR_CDbgEapStatus_F_Node0Eap0W2C_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGEAPSTATUS)) | ClaMmrCdbgeapstatusWr.Node0Eap0W2CWrEn));
assign MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_prev = MMR_CDbgEapStatus_F_Node0Eap0W2C;
assign MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap0W2C_WrEn ? MMR_CDbgEapStatus_F_Node0Eap0W2C_Data : MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP0W2C_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap0W2C_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap0W2C_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap0W2C_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap0W2C)
);

logic                                           MMR_CDbgEapStatus_F_Rsvd3116_WrEn;
logic [CLA_CDBGEAPSTATUS_RSVD3116_WIDTH   -1:0] MMR_CDbgEapStatus_F_Rsvd3116_Data;
logic [CLA_CDBGEAPSTATUS_RSVD3116_WIDTH   -1:0] MMR_CDbgEapStatus_F_Rsvd3116_DataEff;
logic [CLA_CDBGEAPSTATUS_RSVD3116_WIDTH   -1:0] MMR_CDbgEapStatus_F_Rsvd3116_Data_muxed;
logic [CLA_CDBGEAPSTATUS_RSVD3116_WIDTH   -1:0] MMR_CDbgEapStatus_F_Rsvd3116_Data_prev;
assign MMR_CDbgEapStatus_F_Rsvd3116_DataEff = {reg_wr_data[31:16]};
assign MMR_CDbgEapStatus_F_Rsvd3116_Data = (ClaMmrCdbgeapstatusWr.Data.Rsvd3116);
assign MMR_CDbgEapStatus_F_Rsvd3116_WrEn = ((ClaMmrCdbgeapstatusWr.Rsvd3116WrEn));
assign MMR_CDbgEapStatus_F_Rsvd3116_Data_prev = MMR_CDbgEapStatus_F_Rsvd3116;
assign MMR_CDbgEapStatus_F_Rsvd3116_Data_muxed = MMR_CDbgEapStatus_F_Rsvd3116_WrEn ? MMR_CDbgEapStatus_F_Rsvd3116_Data : MMR_CDbgEapStatus_F_Rsvd3116_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_RSVD3116_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_RSVD3116_WIDTH'(0))
) MMR_CDbgEapStatus_F_Rsvd3116_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Rsvd3116_WrEn),
    .in    (MMR_CDbgEapStatus_F_Rsvd3116_Data),
    .out   (MMR_CDbgEapStatus_F_Rsvd3116)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap3_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap3_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap3_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap3_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap3_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap3_DataEff = {reg_wr_data[15:15]};
assign MMR_CDbgEapStatus_F_Node3Eap3_Data = (ClaMmrCdbgeapstatusWr.Data.Node3Eap3);
assign MMR_CDbgEapStatus_F_Node3Eap3_WrEn = ((ClaMmrCdbgeapstatusWr.Node3Eap3WrEn));
assign MMR_CDbgEapStatus_F_Node3Eap3_Data_prev = MMR_CDbgEapStatus_F_Node3Eap3;
assign MMR_CDbgEapStatus_F_Node3Eap3_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap3_WrEn ? MMR_CDbgEapStatus_F_Node3Eap3_Data : MMR_CDbgEapStatus_F_Node3Eap3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP3_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap3_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap3_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap3)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap2_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap2_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap2_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap2_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap2_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap2_DataEff = {reg_wr_data[14:14]};
assign MMR_CDbgEapStatus_F_Node3Eap2_Data = (ClaMmrCdbgeapstatusWr.Data.Node3Eap2);
assign MMR_CDbgEapStatus_F_Node3Eap2_WrEn = ((ClaMmrCdbgeapstatusWr.Node3Eap2WrEn));
assign MMR_CDbgEapStatus_F_Node3Eap2_Data_prev = MMR_CDbgEapStatus_F_Node3Eap2;
assign MMR_CDbgEapStatus_F_Node3Eap2_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap2_WrEn ? MMR_CDbgEapStatus_F_Node3Eap2_Data : MMR_CDbgEapStatus_F_Node3Eap2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP2_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap2_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap2_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap2)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap1_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap1_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap1_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap1_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap1_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap1_DataEff = {reg_wr_data[13:13]};
assign MMR_CDbgEapStatus_F_Node3Eap1_Data = (ClaMmrCdbgeapstatusWr.Data.Node3Eap1);
assign MMR_CDbgEapStatus_F_Node3Eap1_WrEn = ((ClaMmrCdbgeapstatusWr.Node3Eap1WrEn));
assign MMR_CDbgEapStatus_F_Node3Eap1_Data_prev = MMR_CDbgEapStatus_F_Node3Eap1;
assign MMR_CDbgEapStatus_F_Node3Eap1_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap1_WrEn ? MMR_CDbgEapStatus_F_Node3Eap1_Data : MMR_CDbgEapStatus_F_Node3Eap1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP1_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap1_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap1_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap1)
);

logic                                           MMR_CDbgEapStatus_F_Node3Eap0_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap0_Data;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap0_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap0_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node3Eap0_Data_prev;
assign MMR_CDbgEapStatus_F_Node3Eap0_DataEff = {reg_wr_data[12:12]};
assign MMR_CDbgEapStatus_F_Node3Eap0_Data = (ClaMmrCdbgeapstatusWr.Data.Node3Eap0);
assign MMR_CDbgEapStatus_F_Node3Eap0_WrEn = ((ClaMmrCdbgeapstatusWr.Node3Eap0WrEn));
assign MMR_CDbgEapStatus_F_Node3Eap0_Data_prev = MMR_CDbgEapStatus_F_Node3Eap0;
assign MMR_CDbgEapStatus_F_Node3Eap0_Data_muxed = MMR_CDbgEapStatus_F_Node3Eap0_WrEn ? MMR_CDbgEapStatus_F_Node3Eap0_Data : MMR_CDbgEapStatus_F_Node3Eap0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE3EAP0_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node3Eap0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node3Eap0_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node3Eap0_Data),
    .out   (MMR_CDbgEapStatus_F_Node3Eap0)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap3_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap3_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap3_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap3_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap3_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap3_DataEff = {reg_wr_data[11:11]};
assign MMR_CDbgEapStatus_F_Node2Eap3_Data = (ClaMmrCdbgeapstatusWr.Data.Node2Eap3);
assign MMR_CDbgEapStatus_F_Node2Eap3_WrEn = ((ClaMmrCdbgeapstatusWr.Node2Eap3WrEn));
assign MMR_CDbgEapStatus_F_Node2Eap3_Data_prev = MMR_CDbgEapStatus_F_Node2Eap3;
assign MMR_CDbgEapStatus_F_Node2Eap3_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap3_WrEn ? MMR_CDbgEapStatus_F_Node2Eap3_Data : MMR_CDbgEapStatus_F_Node2Eap3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP3_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap3_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap3_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap3)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap2_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap2_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap2_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap2_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap2_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap2_DataEff = {reg_wr_data[10:10]};
assign MMR_CDbgEapStatus_F_Node2Eap2_Data = (ClaMmrCdbgeapstatusWr.Data.Node2Eap2);
assign MMR_CDbgEapStatus_F_Node2Eap2_WrEn = ((ClaMmrCdbgeapstatusWr.Node2Eap2WrEn));
assign MMR_CDbgEapStatus_F_Node2Eap2_Data_prev = MMR_CDbgEapStatus_F_Node2Eap2;
assign MMR_CDbgEapStatus_F_Node2Eap2_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap2_WrEn ? MMR_CDbgEapStatus_F_Node2Eap2_Data : MMR_CDbgEapStatus_F_Node2Eap2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP2_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap2_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap2_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap2)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap1_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap1_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap1_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap1_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap1_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap1_DataEff = {reg_wr_data[9:9]};
assign MMR_CDbgEapStatus_F_Node2Eap1_Data = (ClaMmrCdbgeapstatusWr.Data.Node2Eap1);
assign MMR_CDbgEapStatus_F_Node2Eap1_WrEn = ((ClaMmrCdbgeapstatusWr.Node2Eap1WrEn));
assign MMR_CDbgEapStatus_F_Node2Eap1_Data_prev = MMR_CDbgEapStatus_F_Node2Eap1;
assign MMR_CDbgEapStatus_F_Node2Eap1_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap1_WrEn ? MMR_CDbgEapStatus_F_Node2Eap1_Data : MMR_CDbgEapStatus_F_Node2Eap1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP1_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap1_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap1_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap1)
);

logic                                           MMR_CDbgEapStatus_F_Node2Eap0_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap0_Data;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap0_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap0_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node2Eap0_Data_prev;
assign MMR_CDbgEapStatus_F_Node2Eap0_DataEff = {reg_wr_data[8:8]};
assign MMR_CDbgEapStatus_F_Node2Eap0_Data = (ClaMmrCdbgeapstatusWr.Data.Node2Eap0);
assign MMR_CDbgEapStatus_F_Node2Eap0_WrEn = ((ClaMmrCdbgeapstatusWr.Node2Eap0WrEn));
assign MMR_CDbgEapStatus_F_Node2Eap0_Data_prev = MMR_CDbgEapStatus_F_Node2Eap0;
assign MMR_CDbgEapStatus_F_Node2Eap0_Data_muxed = MMR_CDbgEapStatus_F_Node2Eap0_WrEn ? MMR_CDbgEapStatus_F_Node2Eap0_Data : MMR_CDbgEapStatus_F_Node2Eap0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE2EAP0_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node2Eap0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node2Eap0_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node2Eap0_Data),
    .out   (MMR_CDbgEapStatus_F_Node2Eap0)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap3_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap3_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap3_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap3_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap3_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap3_DataEff = {reg_wr_data[7:7]};
assign MMR_CDbgEapStatus_F_Node1Eap3_Data = (ClaMmrCdbgeapstatusWr.Data.Node1Eap3);
assign MMR_CDbgEapStatus_F_Node1Eap3_WrEn = ((ClaMmrCdbgeapstatusWr.Node1Eap3WrEn));
assign MMR_CDbgEapStatus_F_Node1Eap3_Data_prev = MMR_CDbgEapStatus_F_Node1Eap3;
assign MMR_CDbgEapStatus_F_Node1Eap3_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap3_WrEn ? MMR_CDbgEapStatus_F_Node1Eap3_Data : MMR_CDbgEapStatus_F_Node1Eap3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP3_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap3_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap3_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap3)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap2_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap2_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap2_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap2_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap2_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap2_DataEff = {reg_wr_data[6:6]};
assign MMR_CDbgEapStatus_F_Node1Eap2_Data = (ClaMmrCdbgeapstatusWr.Data.Node1Eap2);
assign MMR_CDbgEapStatus_F_Node1Eap2_WrEn = ((ClaMmrCdbgeapstatusWr.Node1Eap2WrEn));
assign MMR_CDbgEapStatus_F_Node1Eap2_Data_prev = MMR_CDbgEapStatus_F_Node1Eap2;
assign MMR_CDbgEapStatus_F_Node1Eap2_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap2_WrEn ? MMR_CDbgEapStatus_F_Node1Eap2_Data : MMR_CDbgEapStatus_F_Node1Eap2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP2_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap2_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap2_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap2)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap1_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap1_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap1_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap1_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap1_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap1_DataEff = {reg_wr_data[5:5]};
assign MMR_CDbgEapStatus_F_Node1Eap1_Data = (ClaMmrCdbgeapstatusWr.Data.Node1Eap1);
assign MMR_CDbgEapStatus_F_Node1Eap1_WrEn = ((ClaMmrCdbgeapstatusWr.Node1Eap1WrEn));
assign MMR_CDbgEapStatus_F_Node1Eap1_Data_prev = MMR_CDbgEapStatus_F_Node1Eap1;
assign MMR_CDbgEapStatus_F_Node1Eap1_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap1_WrEn ? MMR_CDbgEapStatus_F_Node1Eap1_Data : MMR_CDbgEapStatus_F_Node1Eap1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP1_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap1_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap1_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap1)
);

logic                                           MMR_CDbgEapStatus_F_Node1Eap0_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap0_Data;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap0_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap0_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node1Eap0_Data_prev;
assign MMR_CDbgEapStatus_F_Node1Eap0_DataEff = {reg_wr_data[4:4]};
assign MMR_CDbgEapStatus_F_Node1Eap0_Data = (ClaMmrCdbgeapstatusWr.Data.Node1Eap0);
assign MMR_CDbgEapStatus_F_Node1Eap0_WrEn = ((ClaMmrCdbgeapstatusWr.Node1Eap0WrEn));
assign MMR_CDbgEapStatus_F_Node1Eap0_Data_prev = MMR_CDbgEapStatus_F_Node1Eap0;
assign MMR_CDbgEapStatus_F_Node1Eap0_Data_muxed = MMR_CDbgEapStatus_F_Node1Eap0_WrEn ? MMR_CDbgEapStatus_F_Node1Eap0_Data : MMR_CDbgEapStatus_F_Node1Eap0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE1EAP0_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node1Eap0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node1Eap0_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node1Eap0_Data),
    .out   (MMR_CDbgEapStatus_F_Node1Eap0)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap3_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap3_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap3_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap3_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap3_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap3_DataEff = {reg_wr_data[3:3]};
assign MMR_CDbgEapStatus_F_Node0Eap3_Data = (ClaMmrCdbgeapstatusWr.Data.Node0Eap3);
assign MMR_CDbgEapStatus_F_Node0Eap3_WrEn = ((ClaMmrCdbgeapstatusWr.Node0Eap3WrEn));
assign MMR_CDbgEapStatus_F_Node0Eap3_Data_prev = MMR_CDbgEapStatus_F_Node0Eap3;
assign MMR_CDbgEapStatus_F_Node0Eap3_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap3_WrEn ? MMR_CDbgEapStatus_F_Node0Eap3_Data : MMR_CDbgEapStatus_F_Node0Eap3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP3_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap3_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap3_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap3)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap2_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap2_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap2_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap2_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap2_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap2_DataEff = {reg_wr_data[2:2]};
assign MMR_CDbgEapStatus_F_Node0Eap2_Data = (ClaMmrCdbgeapstatusWr.Data.Node0Eap2);
assign MMR_CDbgEapStatus_F_Node0Eap2_WrEn = ((ClaMmrCdbgeapstatusWr.Node0Eap2WrEn));
assign MMR_CDbgEapStatus_F_Node0Eap2_Data_prev = MMR_CDbgEapStatus_F_Node0Eap2;
assign MMR_CDbgEapStatus_F_Node0Eap2_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap2_WrEn ? MMR_CDbgEapStatus_F_Node0Eap2_Data : MMR_CDbgEapStatus_F_Node0Eap2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP2_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap2_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap2_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap2)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap1_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap1_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap1_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap1_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap1_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap1_DataEff = {reg_wr_data[1:1]};
assign MMR_CDbgEapStatus_F_Node0Eap1_Data = (ClaMmrCdbgeapstatusWr.Data.Node0Eap1);
assign MMR_CDbgEapStatus_F_Node0Eap1_WrEn = ((ClaMmrCdbgeapstatusWr.Node0Eap1WrEn));
assign MMR_CDbgEapStatus_F_Node0Eap1_Data_prev = MMR_CDbgEapStatus_F_Node0Eap1;
assign MMR_CDbgEapStatus_F_Node0Eap1_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap1_WrEn ? MMR_CDbgEapStatus_F_Node0Eap1_Data : MMR_CDbgEapStatus_F_Node0Eap1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP1_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap1_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap1_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap1)
);

logic                                           MMR_CDbgEapStatus_F_Node0Eap0_WrEn;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap0_Data;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap0_DataEff;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap0_Data_muxed;
logic [CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH  -1:0] MMR_CDbgEapStatus_F_Node0Eap0_Data_prev;
assign MMR_CDbgEapStatus_F_Node0Eap0_DataEff = {reg_wr_data[0:0]};
assign MMR_CDbgEapStatus_F_Node0Eap0_Data = (ClaMmrCdbgeapstatusWr.Data.Node0Eap0);
assign MMR_CDbgEapStatus_F_Node0Eap0_WrEn = ((ClaMmrCdbgeapstatusWr.Node0Eap0WrEn));
assign MMR_CDbgEapStatus_F_Node0Eap0_Data_prev = MMR_CDbgEapStatus_F_Node0Eap0;
assign MMR_CDbgEapStatus_F_Node0Eap0_Data_muxed = MMR_CDbgEapStatus_F_Node0Eap0_WrEn ? MMR_CDbgEapStatus_F_Node0Eap0_Data : MMR_CDbgEapStatus_F_Node0Eap0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGEAPSTATUS_NODE0EAP0_WIDTH'(0))
) MMR_CDbgEapStatus_F_Node0Eap0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgEapStatus_F_Node0Eap0_WrEn),
    .in    (MMR_CDbgEapStatus_F_Node0Eap0_Data),
    .out   (MMR_CDbgEapStatus_F_Node0Eap0)
);

logic                                           MMR_CDbgClaCtrlStatus_F_ClaLock_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaLock_Data;
logic [CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaLock_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaLock_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaLock_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_ClaLock_DataEff = {reg_wr_data[63:63]};
assign MMR_CDbgClaCtrlStatus_F_ClaLock_Data = (CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_ClaLock), 64'(MMR_CDbgClaCtrlStatus_F_ClaLock_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_ClaLock_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS)))) & ~MMR_CDbgClaCtrlStatus_F_ClaLock;
assign MMR_CDbgClaCtrlStatus_F_ClaLock_Data_prev = MMR_CDbgClaCtrlStatus_F_ClaLock;
assign MMR_CDbgClaCtrlStatus_F_ClaLock_Data_muxed = MMR_CDbgClaCtrlStatus_F_ClaLock_WrEn ? MMR_CDbgClaCtrlStatus_F_ClaLock_Data : MMR_CDbgClaCtrlStatus_F_ClaLock_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_CLALOCK_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_ClaLock_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_ClaLock_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_ClaLock_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_ClaLock)
);

logic                                           MMR_CDbgClaCtrlStatus_F_Rsvd6216_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data;
logic [CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_Rsvd6216_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_Rsvd6216_DataEff = {reg_wr_strb[1] ? reg_wr_data[62:32] : MMR_CDbgClaCtrlStatus_F_Rsvd6216[46:16] , reg_wr_strb[0] ? reg_wr_data[31:16] : MMR_CDbgClaCtrlStatus_F_Rsvd6216[15:0]};
assign MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data = (CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_Rsvd6216), 64'(MMR_CDbgClaCtrlStatus_F_Rsvd6216_DataEff[46:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_Rsvd6216_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS))));
assign MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_prev = MMR_CDbgClaCtrlStatus_F_Rsvd6216;
assign MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_muxed = MMR_CDbgClaCtrlStatus_F_Rsvd6216_WrEn ? MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data : MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_RSVD6216_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_Rsvd6216_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_Rsvd6216_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_Rsvd6216)
);

logic                                           MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data;
logic [CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_DataEff = {reg_wr_data[15:15]};
assign MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data = (CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt), 64'(MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS))));
assign MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_prev = MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt;
assign MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_muxed = MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_WrEn ? MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data : MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_DISABLELOCALCLOCKHALT_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt)
);

logic                                           MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data;
logic [CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_DataEff = {reg_wr_data[14:14]};
assign MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data = (CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt), 64'(MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS))));
assign MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_prev = MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt;
assign MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_muxed = MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_WrEn ? MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data : MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_DISABLEGLOBALCLOCKHALT_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt)
);

logic                                           MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data;
logic [CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_DataEff = {reg_wr_data[13:7]};
assign MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data = (CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay), 64'(MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_DataEff[6:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS))));
assign MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_prev = MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay;
assign MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_muxed = MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_WrEn ? MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data : MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_CLACHAINLOOPDELAY_WIDTH'(7'h36))
) MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay)
);

logic                                           MMR_CDbgClaCtrlStatus_F_EnableCla_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableCla_Data;
logic [CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableCla_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableCla_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableCla_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_EnableCla_DataEff = {reg_wr_data[6:6]};
assign MMR_CDbgClaCtrlStatus_F_EnableCla_Data = (CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_EnableCla), 64'(MMR_CDbgClaCtrlStatus_F_EnableCla_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_EnableCla_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS)))) & ~MMR_CDbgClaCtrlStatus_F_ClaLock;
assign MMR_CDbgClaCtrlStatus_F_EnableCla_Data_prev = MMR_CDbgClaCtrlStatus_F_EnableCla;
assign MMR_CDbgClaCtrlStatus_F_EnableCla_Data_muxed = MMR_CDbgClaCtrlStatus_F_EnableCla_WrEn ? MMR_CDbgClaCtrlStatus_F_EnableCla_Data : MMR_CDbgClaCtrlStatus_F_EnableCla_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_ENABLECLA_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_EnableCla_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_EnableCla_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_EnableCla_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_EnableCla)
);

logic                                           MMR_CDbgClaCtrlStatus_F_EnableEap_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableEap_Data;
logic [CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableEap_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableEap_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_EnableEap_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_EnableEap_DataEff = {reg_wr_data[5:5]};
assign MMR_CDbgClaCtrlStatus_F_EnableEap_Data = (CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH'(update_value(64'(MMR_CDbgClaCtrlStatus_F_EnableEap), 64'(MMR_CDbgClaCtrlStatus_F_EnableEap_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgClaCtrlStatus_F_EnableEap_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLACTRLSTATUS))));
assign MMR_CDbgClaCtrlStatus_F_EnableEap_Data_prev = MMR_CDbgClaCtrlStatus_F_EnableEap;
assign MMR_CDbgClaCtrlStatus_F_EnableEap_Data_muxed = MMR_CDbgClaCtrlStatus_F_EnableEap_WrEn ? MMR_CDbgClaCtrlStatus_F_EnableEap_Data : MMR_CDbgClaCtrlStatus_F_EnableEap_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_ENABLEEAP_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_EnableEap_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_EnableEap_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_EnableEap_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_EnableEap)
);

logic                                           MMR_CDbgClaCtrlStatus_F_CurrentNode_WrEn;
logic [CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_CurrentNode_Data;
logic [CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_CurrentNode_DataEff;
logic [CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_muxed;
logic [CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH-1:0] MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_prev;
assign MMR_CDbgClaCtrlStatus_F_CurrentNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgClaCtrlStatus_F_CurrentNode_Data = (ClaMmrCdbgclactrlstatusWr.Data.CurrentNode);
assign MMR_CDbgClaCtrlStatus_F_CurrentNode_WrEn = ((ClaMmrCdbgclactrlstatusWr.CurrentNodeWrEn));
assign MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_prev = MMR_CDbgClaCtrlStatus_F_CurrentNode;
assign MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_muxed = MMR_CDbgClaCtrlStatus_F_CurrentNode_WrEn ? MMR_CDbgClaCtrlStatus_F_CurrentNode_Data : MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLACTRLSTATUS_CURRENTNODE_WIDTH'(0))
) MMR_CDbgClaCtrlStatus_F_CurrentNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaCtrlStatus_F_CurrentNode_WrEn),
    .in    (MMR_CDbgClaCtrlStatus_F_CurrentNode_Data),
    .out   (MMR_CDbgClaCtrlStatus_F_CurrentNode)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg7_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg7_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg7_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg7_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg7_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg7_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgMuxSelLo_F_Muxselseg7_Data = (CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg7), 64'(MMR_CDbgMuxSelLo_F_Muxselseg7_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg7_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg7_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg7;
assign MMR_CDbgMuxSelLo_F_Muxselseg7_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg7_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg7_Data : MMR_CDbgMuxSelLo_F_Muxselseg7_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG7_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg7_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg7_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg7_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg7)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg6_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg6_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg6_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg6_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg6_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg6_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgMuxSelLo_F_Muxselseg6_Data = (CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg6), 64'(MMR_CDbgMuxSelLo_F_Muxselseg6_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg6_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg6_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg6;
assign MMR_CDbgMuxSelLo_F_Muxselseg6_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg6_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg6_Data : MMR_CDbgMuxSelLo_F_Muxselseg6_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG6_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg6_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg6_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg6_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg6)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg5_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg5_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg5_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg5_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg5_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg5_DataEff = {reg_wr_data[51:46]};
assign MMR_CDbgMuxSelLo_F_Muxselseg5_Data = (CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg5), 64'(MMR_CDbgMuxSelLo_F_Muxselseg5_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg5_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg5_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg5;
assign MMR_CDbgMuxSelLo_F_Muxselseg5_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg5_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg5_Data : MMR_CDbgMuxSelLo_F_Muxselseg5_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG5_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg5_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg5_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg5_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg5)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg4_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg4_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg4_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg4_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg4_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg4_DataEff = {reg_wr_data[45:40]};
assign MMR_CDbgMuxSelLo_F_Muxselseg4_Data = (CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg4), 64'(MMR_CDbgMuxSelLo_F_Muxselseg4_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg4_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg4_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg4;
assign MMR_CDbgMuxSelLo_F_Muxselseg4_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg4_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg4_Data : MMR_CDbgMuxSelLo_F_Muxselseg4_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG4_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg4_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg4_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg4_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg4)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg3_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg3_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg3_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg3_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg3_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg3_DataEff = {reg_wr_data[39:34]};
assign MMR_CDbgMuxSelLo_F_Muxselseg3_Data = (CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg3), 64'(MMR_CDbgMuxSelLo_F_Muxselseg3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg3_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg3;
assign MMR_CDbgMuxSelLo_F_Muxselseg3_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg3_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg3_Data : MMR_CDbgMuxSelLo_F_Muxselseg3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG3_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg3_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg3_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg3)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg2_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg2_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg2_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg2_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg2_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg2_DataEff = {reg_wr_strb[1] ? reg_wr_data[33:32] : MMR_CDbgMuxSelLo_F_Muxselseg2[5:4] , reg_wr_strb[0] ? reg_wr_data[31:28] : MMR_CDbgMuxSelLo_F_Muxselseg2[3:0]};
assign MMR_CDbgMuxSelLo_F_Muxselseg2_Data = (CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg2), 64'(MMR_CDbgMuxSelLo_F_Muxselseg2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg2_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg2_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg2;
assign MMR_CDbgMuxSelLo_F_Muxselseg2_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg2_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg2_Data : MMR_CDbgMuxSelLo_F_Muxselseg2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG2_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg2_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg2_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg2)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg1_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg1_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg1_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg1_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg1_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgMuxSelLo_F_Muxselseg1_Data = (CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg1), 64'(MMR_CDbgMuxSelLo_F_Muxselseg1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg1_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg1;
assign MMR_CDbgMuxSelLo_F_Muxselseg1_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg1_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg1_Data : MMR_CDbgMuxSelLo_F_Muxselseg1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG1_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg1_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg1_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg1)
);

logic                                           MMR_CDbgMuxSelLo_F_Muxselseg0_WrEn;
logic [CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg0_Data;
logic [CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg0_DataEff;
logic [CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg0_Data_muxed;
logic [CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH  -1:0] MMR_CDbgMuxSelLo_F_Muxselseg0_Data_prev;
assign MMR_CDbgMuxSelLo_F_Muxselseg0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgMuxSelLo_F_Muxselseg0_Data = (CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Muxselseg0), 64'(MMR_CDbgMuxSelLo_F_Muxselseg0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Muxselseg0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Muxselseg0_Data_prev = MMR_CDbgMuxSelLo_F_Muxselseg0;
assign MMR_CDbgMuxSelLo_F_Muxselseg0_Data_muxed = MMR_CDbgMuxSelLo_F_Muxselseg0_WrEn ? MMR_CDbgMuxSelLo_F_Muxselseg0_Data : MMR_CDbgMuxSelLo_F_Muxselseg0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_MUXSELSEG0_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Muxselseg0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Muxselseg0_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Muxselseg0_Data),
    .out   (MMR_CDbgMuxSelLo_F_Muxselseg0)
);

logic                                           MMR_CDbgMuxSelLo_F_Rsvd1510_WrEn;
logic [CLA_CDBGMUXSELLO_RSVD1510_WIDTH    -1:0] MMR_CDbgMuxSelLo_F_Rsvd1510_Data;
logic [CLA_CDBGMUXSELLO_RSVD1510_WIDTH    -1:0] MMR_CDbgMuxSelLo_F_Rsvd1510_DataEff;
logic [CLA_CDBGMUXSELLO_RSVD1510_WIDTH    -1:0] MMR_CDbgMuxSelLo_F_Rsvd1510_Data_muxed;
logic [CLA_CDBGMUXSELLO_RSVD1510_WIDTH    -1:0] MMR_CDbgMuxSelLo_F_Rsvd1510_Data_prev;
assign MMR_CDbgMuxSelLo_F_Rsvd1510_DataEff = {reg_wr_data[15:10]};
assign MMR_CDbgMuxSelLo_F_Rsvd1510_Data = (CLA_CDBGMUXSELLO_RSVD1510_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Rsvd1510), 64'(MMR_CDbgMuxSelLo_F_Rsvd1510_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Rsvd1510_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Rsvd1510_Data_prev = MMR_CDbgMuxSelLo_F_Rsvd1510;
assign MMR_CDbgMuxSelLo_F_Rsvd1510_Data_muxed = MMR_CDbgMuxSelLo_F_Rsvd1510_WrEn ? MMR_CDbgMuxSelLo_F_Rsvd1510_Data : MMR_CDbgMuxSelLo_F_Rsvd1510_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_RSVD1510_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_RSVD1510_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Rsvd1510_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Rsvd1510_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Rsvd1510_Data),
    .out   (MMR_CDbgMuxSelLo_F_Rsvd1510)
);

logic                                           MMR_CDbgMuxSelLo_F_Valid_WrEn;
logic [CLA_CDBGMUXSELLO_VALID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Valid_Data;
logic [CLA_CDBGMUXSELLO_VALID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Valid_DataEff;
logic [CLA_CDBGMUXSELLO_VALID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Valid_Data_muxed;
logic [CLA_CDBGMUXSELLO_VALID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Valid_Data_prev;
assign MMR_CDbgMuxSelLo_F_Valid_DataEff = {reg_wr_data[9:9]};
assign MMR_CDbgMuxSelLo_F_Valid_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO)) ? CLA_CDBGMUXSELLO_VALID_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Valid), 64'(MMR_CDbgMuxSelLo_F_Valid_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgmuxselloWr.Data.Valid);
assign MMR_CDbgMuxSelLo_F_Valid_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO)) | ClaMmrCdbgmuxselloWr.ValidWrEn));
assign MMR_CDbgMuxSelLo_F_Valid_Data_prev = MMR_CDbgMuxSelLo_F_Valid;
assign MMR_CDbgMuxSelLo_F_Valid_Data_muxed = MMR_CDbgMuxSelLo_F_Valid_WrEn ? MMR_CDbgMuxSelLo_F_Valid_Data : MMR_CDbgMuxSelLo_F_Valid_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_VALID_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_VALID_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Valid_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Valid_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Valid_Data),
    .out   (MMR_CDbgMuxSelLo_F_Valid)
);

logic                                           MMR_CDbgMuxSelLo_F_Finegraintime_WrEn;
logic [CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH-1:0] MMR_CDbgMuxSelLo_F_Finegraintime_Data;
logic [CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH-1:0] MMR_CDbgMuxSelLo_F_Finegraintime_DataEff;
logic [CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH-1:0] MMR_CDbgMuxSelLo_F_Finegraintime_Data_muxed;
logic [CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH-1:0] MMR_CDbgMuxSelLo_F_Finegraintime_Data_prev;
assign MMR_CDbgMuxSelLo_F_Finegraintime_DataEff = {reg_wr_data[8:8]};
assign MMR_CDbgMuxSelLo_F_Finegraintime_Data = (CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Finegraintime), 64'(MMR_CDbgMuxSelLo_F_Finegraintime_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Finegraintime_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Finegraintime_Data_prev = MMR_CDbgMuxSelLo_F_Finegraintime;
assign MMR_CDbgMuxSelLo_F_Finegraintime_Data_muxed = MMR_CDbgMuxSelLo_F_Finegraintime_WrEn ? MMR_CDbgMuxSelLo_F_Finegraintime_Data : MMR_CDbgMuxSelLo_F_Finegraintime_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_FINEGRAINTIME_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Finegraintime_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Finegraintime_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Finegraintime_Data),
    .out   (MMR_CDbgMuxSelLo_F_Finegraintime)
);

logic                                           MMR_CDbgMuxSelLo_F_Dbmid_WrEn;
logic [CLA_CDBGMUXSELLO_DBMID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Dbmid_Data;
logic [CLA_CDBGMUXSELLO_DBMID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Dbmid_DataEff;
logic [CLA_CDBGMUXSELLO_DBMID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Dbmid_Data_muxed;
logic [CLA_CDBGMUXSELLO_DBMID_WIDTH       -1:0] MMR_CDbgMuxSelLo_F_Dbmid_Data_prev;
assign MMR_CDbgMuxSelLo_F_Dbmid_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgMuxSelLo_F_Dbmid_Data = (CLA_CDBGMUXSELLO_DBMID_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Dbmid), 64'(MMR_CDbgMuxSelLo_F_Dbmid_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Dbmid_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Dbmid_Data_prev = MMR_CDbgMuxSelLo_F_Dbmid;
assign MMR_CDbgMuxSelLo_F_Dbmid_Data_muxed = MMR_CDbgMuxSelLo_F_Dbmid_WrEn ? MMR_CDbgMuxSelLo_F_Dbmid_Data : MMR_CDbgMuxSelLo_F_Dbmid_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_DBMID_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_DBMID_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Dbmid_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Dbmid_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Dbmid_Data),
    .out   (MMR_CDbgMuxSelLo_F_Dbmid)
);

logic                                           MMR_CDbgMuxSelLo_F_Dbmmode_WrEn;
logic [CLA_CDBGMUXSELLO_DBMMODE_WIDTH     -1:0] MMR_CDbgMuxSelLo_F_Dbmmode_Data;
logic [CLA_CDBGMUXSELLO_DBMMODE_WIDTH     -1:0] MMR_CDbgMuxSelLo_F_Dbmmode_DataEff;
logic [CLA_CDBGMUXSELLO_DBMMODE_WIDTH     -1:0] MMR_CDbgMuxSelLo_F_Dbmmode_Data_muxed;
logic [CLA_CDBGMUXSELLO_DBMMODE_WIDTH     -1:0] MMR_CDbgMuxSelLo_F_Dbmmode_Data_prev;
assign MMR_CDbgMuxSelLo_F_Dbmmode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgMuxSelLo_F_Dbmmode_Data = (CLA_CDBGMUXSELLO_DBMMODE_WIDTH'(update_value(64'(MMR_CDbgMuxSelLo_F_Dbmmode), 64'(MMR_CDbgMuxSelLo_F_Dbmmode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelLo_F_Dbmmode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELLO))));
assign MMR_CDbgMuxSelLo_F_Dbmmode_Data_prev = MMR_CDbgMuxSelLo_F_Dbmmode;
assign MMR_CDbgMuxSelLo_F_Dbmmode_Data_muxed = MMR_CDbgMuxSelLo_F_Dbmmode_WrEn ? MMR_CDbgMuxSelLo_F_Dbmmode_Data : MMR_CDbgMuxSelLo_F_Dbmmode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELLO_DBMMODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELLO_DBMMODE_WIDTH'(0))
) MMR_CDbgMuxSelLo_F_Dbmmode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgMuxSelLo_F_Dbmmode_WrEn),
    .in    (MMR_CDbgMuxSelLo_F_Dbmmode_Data),
    .out   (MMR_CDbgMuxSelLo_F_Dbmmode)
);

logic                                           MMR_CDbgRsvd1_F_Value_WrEn;
logic [CLA_CDBGRSVD1_VALUE_WIDTH          -1:0] MMR_CDbgRsvd1_F_Value_Data;
logic [CLA_CDBGRSVD1_VALUE_WIDTH          -1:0] MMR_CDbgRsvd1_F_Value_DataEff;
logic [CLA_CDBGRSVD1_VALUE_WIDTH          -1:0] MMR_CDbgRsvd1_F_Value_Data_muxed;
logic [CLA_CDBGRSVD1_VALUE_WIDTH          -1:0] MMR_CDbgRsvd1_F_Value_Data_prev;
assign MMR_CDbgRsvd1_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgRsvd1_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgRsvd1_F_Value[31:0]};
assign MMR_CDbgRsvd1_F_Value_Data = (CLA_CDBGRSVD1_VALUE_WIDTH'(update_value(64'(MMR_CDbgRsvd1_F_Value), 64'(MMR_CDbgRsvd1_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgRsvd1_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGRSVD1))));
assign MMR_CDbgRsvd1_F_Value_Data_prev = MMR_CDbgRsvd1_F_Value;
assign MMR_CDbgRsvd1_F_Value_Data_muxed = MMR_CDbgRsvd1_F_Value_WrEn ? MMR_CDbgRsvd1_F_Value_Data : MMR_CDbgRsvd1_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGRSVD1_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGRSVD1_VALUE_WIDTH'(0))
) MMR_CDbgRsvd1_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgRsvd1_F_Value_WrEn),
    .in    (MMR_CDbgRsvd1_F_Value_Data),
    .out   (MMR_CDbgRsvd1_F_Value)
);

logic                                           MMR_CDbgRsvd2_F_Value_WrEn;
logic [CLA_CDBGRSVD2_VALUE_WIDTH          -1:0] MMR_CDbgRsvd2_F_Value_Data;
logic [CLA_CDBGRSVD2_VALUE_WIDTH          -1:0] MMR_CDbgRsvd2_F_Value_DataEff;
logic [CLA_CDBGRSVD2_VALUE_WIDTH          -1:0] MMR_CDbgRsvd2_F_Value_Data_muxed;
logic [CLA_CDBGRSVD2_VALUE_WIDTH          -1:0] MMR_CDbgRsvd2_F_Value_Data_prev;
assign MMR_CDbgRsvd2_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgRsvd2_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgRsvd2_F_Value[31:0]};
assign MMR_CDbgRsvd2_F_Value_Data = (CLA_CDBGRSVD2_VALUE_WIDTH'(update_value(64'(MMR_CDbgRsvd2_F_Value), 64'(MMR_CDbgRsvd2_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgRsvd2_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGRSVD2))));
assign MMR_CDbgRsvd2_F_Value_Data_prev = MMR_CDbgRsvd2_F_Value;
assign MMR_CDbgRsvd2_F_Value_Data_muxed = MMR_CDbgRsvd2_F_Value_WrEn ? MMR_CDbgRsvd2_F_Value_Data : MMR_CDbgRsvd2_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGRSVD2_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGRSVD2_VALUE_WIDTH'(0))
) MMR_CDbgRsvd2_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgRsvd2_F_Value_WrEn),
    .in    (MMR_CDbgRsvd2_F_Value_Data),
    .out   (MMR_CDbgRsvd2_F_Value)
);

logic                                           MMR_CDbgTransitionMaskLo_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskLo_F_Value_Data;
logic [CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskLo_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskLo_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskLo_F_Value_Data_prev;
assign MMR_CDbgTransitionMaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionMaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionMaskLo_F_Value[31:0]};
assign MMR_CDbgTransitionMaskLo_F_Value_Data = (CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionMaskLo_F_Value), 64'(MMR_CDbgTransitionMaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionMaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONMASKLO))));
assign MMR_CDbgTransitionMaskLo_F_Value_Data_prev = MMR_CDbgTransitionMaskLo_F_Value;
assign MMR_CDbgTransitionMaskLo_F_Value_Data_muxed = MMR_CDbgTransitionMaskLo_F_Value_WrEn ? MMR_CDbgTransitionMaskLo_F_Value_Data : MMR_CDbgTransitionMaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONMASKLO_VALUE_WIDTH'(0))
) MMR_CDbgTransitionMaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgTransitionMaskLo_F_Value_WrEn),
    .in    (MMR_CDbgTransitionMaskLo_F_Value_Data),
    .out   (MMR_CDbgTransitionMaskLo_F_Value)
);

logic                                           MMR_CDbgTransitionFromValueLo_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueLo_F_Value_Data;
logic [CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueLo_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueLo_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueLo_F_Value_Data_prev;
assign MMR_CDbgTransitionFromValueLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionFromValueLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionFromValueLo_F_Value[31:0]};
assign MMR_CDbgTransitionFromValueLo_F_Value_Data = (CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionFromValueLo_F_Value), 64'(MMR_CDbgTransitionFromValueLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionFromValueLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONFROMVALUELO))));
assign MMR_CDbgTransitionFromValueLo_F_Value_Data_prev = MMR_CDbgTransitionFromValueLo_F_Value;
assign MMR_CDbgTransitionFromValueLo_F_Value_Data_muxed = MMR_CDbgTransitionFromValueLo_F_Value_WrEn ? MMR_CDbgTransitionFromValueLo_F_Value_Data : MMR_CDbgTransitionFromValueLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONFROMVALUELO_VALUE_WIDTH'(0))
) MMR_CDbgTransitionFromValueLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgTransitionFromValueLo_F_Value_WrEn),
    .in    (MMR_CDbgTransitionFromValueLo_F_Value_Data),
    .out   (MMR_CDbgTransitionFromValueLo_F_Value)
);

logic                                           MMR_CDbgTransitionToValueLo_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueLo_F_Value_Data;
logic [CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueLo_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueLo_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueLo_F_Value_Data_prev;
assign MMR_CDbgTransitionToValueLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionToValueLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionToValueLo_F_Value[31:0]};
assign MMR_CDbgTransitionToValueLo_F_Value_Data = (CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionToValueLo_F_Value), 64'(MMR_CDbgTransitionToValueLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionToValueLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONTOVALUELO))));
assign MMR_CDbgTransitionToValueLo_F_Value_Data_prev = MMR_CDbgTransitionToValueLo_F_Value;
assign MMR_CDbgTransitionToValueLo_F_Value_Data_muxed = MMR_CDbgTransitionToValueLo_F_Value_WrEn ? MMR_CDbgTransitionToValueLo_F_Value_Data : MMR_CDbgTransitionToValueLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONTOVALUELO_VALUE_WIDTH'(0))
) MMR_CDbgTransitionToValueLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgTransitionToValueLo_F_Value_WrEn),
    .in    (MMR_CDbgTransitionToValueLo_F_Value_Data),
    .out   (MMR_CDbgTransitionToValueLo_F_Value)
);

logic                                           MMR_CDbgOnesCountMaskLo_F_Value_WrEn;
logic [CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskLo_F_Value_Data;
logic [CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskLo_F_Value_DataEff;
logic [CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskLo_F_Value_Data_muxed;
logic [CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskLo_F_Value_Data_prev;
assign MMR_CDbgOnesCountMaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgOnesCountMaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgOnesCountMaskLo_F_Value[31:0]};
assign MMR_CDbgOnesCountMaskLo_F_Value_Data = (CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgOnesCountMaskLo_F_Value), 64'(MMR_CDbgOnesCountMaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgOnesCountMaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGONESCOUNTMASKLO))));
assign MMR_CDbgOnesCountMaskLo_F_Value_Data_prev = MMR_CDbgOnesCountMaskLo_F_Value;
assign MMR_CDbgOnesCountMaskLo_F_Value_Data_muxed = MMR_CDbgOnesCountMaskLo_F_Value_WrEn ? MMR_CDbgOnesCountMaskLo_F_Value_Data : MMR_CDbgOnesCountMaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGONESCOUNTMASKLO_VALUE_WIDTH'(0))
) MMR_CDbgOnesCountMaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgOnesCountMaskLo_F_Value_WrEn),
    .in    (MMR_CDbgOnesCountMaskLo_F_Value_Data),
    .out   (MMR_CDbgOnesCountMaskLo_F_Value)
);

logic                                           MMR_CDbgOnesCountValue_F_Value_WrEn;
logic [CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH -1:0] MMR_CDbgOnesCountValue_F_Value_Data;
logic [CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH -1:0] MMR_CDbgOnesCountValue_F_Value_DataEff;
logic [CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH -1:0] MMR_CDbgOnesCountValue_F_Value_Data_muxed;
logic [CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH -1:0] MMR_CDbgOnesCountValue_F_Value_Data_prev;
assign MMR_CDbgOnesCountValue_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgOnesCountValue_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgOnesCountValue_F_Value[31:0]};
assign MMR_CDbgOnesCountValue_F_Value_Data = (CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH'(update_value(64'(MMR_CDbgOnesCountValue_F_Value), 64'(MMR_CDbgOnesCountValue_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgOnesCountValue_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGONESCOUNTVALUE))));
assign MMR_CDbgOnesCountValue_F_Value_Data_prev = MMR_CDbgOnesCountValue_F_Value;
assign MMR_CDbgOnesCountValue_F_Value_Data_muxed = MMR_CDbgOnesCountValue_F_Value_WrEn ? MMR_CDbgOnesCountValue_F_Value_Data : MMR_CDbgOnesCountValue_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGONESCOUNTVALUE_VALUE_WIDTH'(0))
) MMR_CDbgOnesCountValue_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgOnesCountValue_F_Value_WrEn),
    .in    (MMR_CDbgOnesCountValue_F_Value_Data),
    .out   (MMR_CDbgOnesCountValue_F_Value)
);

logic                                           MMR_CDbgAnyChangeLo_F_Mask_WrEn;
logic [CLA_CDBGANYCHANGELO_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeLo_F_Mask_Data;
logic [CLA_CDBGANYCHANGELO_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeLo_F_Mask_DataEff;
logic [CLA_CDBGANYCHANGELO_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeLo_F_Mask_Data_muxed;
logic [CLA_CDBGANYCHANGELO_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeLo_F_Mask_Data_prev;
assign MMR_CDbgAnyChangeLo_F_Mask_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgAnyChangeLo_F_Mask[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgAnyChangeLo_F_Mask[31:0]};
assign MMR_CDbgAnyChangeLo_F_Mask_Data = (CLA_CDBGANYCHANGELO_MASK_WIDTH'(update_value(64'(MMR_CDbgAnyChangeLo_F_Mask), 64'(MMR_CDbgAnyChangeLo_F_Mask_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgAnyChangeLo_F_Mask_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGANYCHANGELO))));
assign MMR_CDbgAnyChangeLo_F_Mask_Data_prev = MMR_CDbgAnyChangeLo_F_Mask;
assign MMR_CDbgAnyChangeLo_F_Mask_Data_muxed = MMR_CDbgAnyChangeLo_F_Mask_WrEn ? MMR_CDbgAnyChangeLo_F_Mask_Data : MMR_CDbgAnyChangeLo_F_Mask_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGANYCHANGELO_MASK_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGANYCHANGELO_MASK_WIDTH'(0))
) MMR_CDbgAnyChangeLo_F_Mask_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgAnyChangeLo_F_Mask_WrEn),
    .in    (MMR_CDbgAnyChangeLo_F_Mask_Data),
    .out   (MMR_CDbgAnyChangeLo_F_Mask)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap0LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap0LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap1LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap1LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap0LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap0LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap1LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap1LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap0LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap0LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap1LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap1LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap0LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap0LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP0LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap1LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap1LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP1LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value)
);

logic                                           MMR_CDbgClaTimeMatch_F_TimeMatchVal_WrEn;
logic [CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH-1:0] MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data;
logic [CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH-1:0] MMR_CDbgClaTimeMatch_F_TimeMatchVal_DataEff;
logic [CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH-1:0] MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_muxed;
logic [CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH-1:0] MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_prev;
assign MMR_CDbgClaTimeMatch_F_TimeMatchVal_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgClaTimeMatch_F_TimeMatchVal[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgClaTimeMatch_F_TimeMatchVal[31:0]};
assign MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data = (CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH'(update_value(64'(MMR_CDbgClaTimeMatch_F_TimeMatchVal), 64'(MMR_CDbgClaTimeMatch_F_TimeMatchVal_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimeMatch_F_TimeMatchVal_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMEMATCH))));
assign MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_prev = MMR_CDbgClaTimeMatch_F_TimeMatchVal;
assign MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_muxed = MMR_CDbgClaTimeMatch_F_TimeMatchVal_WrEn ? MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data : MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMEMATCH_TIMEMATCHVAL_WIDTH'(0))
) MMR_CDbgClaTimeMatch_F_TimeMatchVal_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimeMatch_F_TimeMatchVal_WrEn),
    .in    (MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data),
    .out   (MMR_CDbgClaTimeMatch_F_TimeMatchVal)
);

logic                                           MMR_CDbgSignalMask2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMask2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask2Lo_F_Value[31:0]};
assign MMR_CDbgSignalMask2Lo_F_Value_Data = (CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask2Lo_F_Value), 64'(MMR_CDbgSignalMask2Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask2Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK2LO))));
assign MMR_CDbgSignalMask2Lo_F_Value_Data_prev = MMR_CDbgSignalMask2Lo_F_Value;
assign MMR_CDbgSignalMask2Lo_F_Value_Data_muxed = MMR_CDbgSignalMask2Lo_F_Value_WrEn ? MMR_CDbgSignalMask2Lo_F_Value_Data : MMR_CDbgSignalMask2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMask2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMask2Lo_F_Value)
);

logic                                           MMR_CDbgSignalMatch2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMatch2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch2Lo_F_Value[31:0]};
assign MMR_CDbgSignalMatch2Lo_F_Value_Data = (CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch2Lo_F_Value), 64'(MMR_CDbgSignalMatch2Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch2Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH2LO))));
assign MMR_CDbgSignalMatch2Lo_F_Value_Data_prev = MMR_CDbgSignalMatch2Lo_F_Value;
assign MMR_CDbgSignalMatch2Lo_F_Value_Data_muxed = MMR_CDbgSignalMatch2Lo_F_Value_WrEn ? MMR_CDbgSignalMatch2Lo_F_Value_Data : MMR_CDbgSignalMatch2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMatch2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMatch2Lo_F_Value)
);

logic                                           MMR_CDbgSignalMask3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMask3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask3Lo_F_Value[31:0]};
assign MMR_CDbgSignalMask3Lo_F_Value_Data = (CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask3Lo_F_Value), 64'(MMR_CDbgSignalMask3Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask3Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK3LO))));
assign MMR_CDbgSignalMask3Lo_F_Value_Data_prev = MMR_CDbgSignalMask3Lo_F_Value;
assign MMR_CDbgSignalMask3Lo_F_Value_Data_muxed = MMR_CDbgSignalMask3Lo_F_Value_WrEn ? MMR_CDbgSignalMask3Lo_F_Value_Data : MMR_CDbgSignalMask3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMask3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMask3Lo_F_Value)
);

logic                                           MMR_CDbgSignalMatch3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalMatch3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch3Lo_F_Value[31:0]};
assign MMR_CDbgSignalMatch3Lo_F_Value_Data = (CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch3Lo_F_Value), 64'(MMR_CDbgSignalMatch3Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch3Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH3LO))));
assign MMR_CDbgSignalMatch3Lo_F_Value_Data_prev = MMR_CDbgSignalMatch3Lo_F_Value;
assign MMR_CDbgSignalMatch3Lo_F_Value_Data_muxed = MMR_CDbgSignalMatch3Lo_F_Value_WrEn ? MMR_CDbgSignalMatch3Lo_F_Value_Data : MMR_CDbgSignalMatch3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalMatch3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalMatch3Lo_F_Value)
);

logic                                           MMR_CDbgNode0Eap2_F_Action3_WrEn;
logic [CLA_CDBGNODE0EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action3_Data;
logic [CLA_CDBGNODE0EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action3_DataEff;
logic [CLA_CDBGNODE0EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action3_Data_muxed;
logic [CLA_CDBGNODE0EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action3_Data_prev;
assign MMR_CDbgNode0Eap2_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode0Eap2_F_Action3_Data = (CLA_CDBGNODE0EAP2_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_Action3), 64'(MMR_CDbgNode0Eap2_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_Action3_Data_prev = MMR_CDbgNode0Eap2_F_Action3;
assign MMR_CDbgNode0Eap2_F_Action3_Data_muxed = MMR_CDbgNode0Eap2_F_Action3_WrEn ? MMR_CDbgNode0Eap2_F_Action3_Data : MMR_CDbgNode0Eap2_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_ACTION3_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_Action3_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_Action3_Data),
    .out   (MMR_CDbgNode0Eap2_F_Action3)
);

logic                                           MMR_CDbgNode0Eap2_F_Action2_WrEn;
logic [CLA_CDBGNODE0EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action2_Data;
logic [CLA_CDBGNODE0EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action2_DataEff;
logic [CLA_CDBGNODE0EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action2_Data_muxed;
logic [CLA_CDBGNODE0EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action2_Data_prev;
assign MMR_CDbgNode0Eap2_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode0Eap2_F_Action2_Data = (CLA_CDBGNODE0EAP2_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_Action2), 64'(MMR_CDbgNode0Eap2_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_Action2_Data_prev = MMR_CDbgNode0Eap2_F_Action2;
assign MMR_CDbgNode0Eap2_F_Action2_Data_muxed = MMR_CDbgNode0Eap2_F_Action2_WrEn ? MMR_CDbgNode0Eap2_F_Action2_Data : MMR_CDbgNode0Eap2_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_ACTION2_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_Action2_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_Action2_Data),
    .out   (MMR_CDbgNode0Eap2_F_Action2)
);

logic                                           MMR_CDbgNode0Eap2_F_Udf_WrEn;
logic [CLA_CDBGNODE0EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap2_F_Udf_Data;
logic [CLA_CDBGNODE0EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap2_F_Udf_DataEff;
logic [CLA_CDBGNODE0EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap2_F_Udf_Data_muxed;
logic [CLA_CDBGNODE0EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap2_F_Udf_Data_prev;
assign MMR_CDbgNode0Eap2_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode0Eap2_F_Udf_Data = (CLA_CDBGNODE0EAP2_UDF_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_Udf), 64'(MMR_CDbgNode0Eap2_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_Udf_Data_prev = MMR_CDbgNode0Eap2_F_Udf;
assign MMR_CDbgNode0Eap2_F_Udf_Data_muxed = MMR_CDbgNode0Eap2_F_Udf_WrEn ? MMR_CDbgNode0Eap2_F_Udf_Data : MMR_CDbgNode0Eap2_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_UDF_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_Udf_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_Udf_Data),
    .out   (MMR_CDbgNode0Eap2_F_Udf)
);

logic                                           MMR_CDbgNode0Eap2_F_EventType2_WrEn;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType2_Data;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType2_DataEff;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType2_Data_prev;
assign MMR_CDbgNode0Eap2_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode0Eap2_F_EventType2_Data = (CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_EventType2), 64'(MMR_CDbgNode0Eap2_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_EventType2_Data_prev = MMR_CDbgNode0Eap2_F_EventType2;
assign MMR_CDbgNode0Eap2_F_EventType2_Data_muxed = MMR_CDbgNode0Eap2_F_EventType2_WrEn ? MMR_CDbgNode0Eap2_F_EventType2_Data : MMR_CDbgNode0Eap2_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_EventType2_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_EventType2_Data),
    .out   (MMR_CDbgNode0Eap2_F_EventType2)
);

logic                                           MMR_CDbgNode0Eap2_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode0Eap2_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data = (CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_CustomAction1Enable), 64'(MMR_CDbgNode0Eap2_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_prev = MMR_CDbgNode0Eap2_F_CustomAction1Enable;
assign MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode0Eap2_F_CustomAction1Enable_WrEn ? MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data : MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode0Eap2_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode0Eap2_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode0Eap2_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data = (CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_CustomAction0Enable), 64'(MMR_CDbgNode0Eap2_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_prev = MMR_CDbgNode0Eap2_F_CustomAction0Enable;
assign MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode0Eap2_F_CustomAction0Enable_WrEn ? MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data : MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode0Eap2_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode0Eap2_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1_Data;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction1_Data_prev;
assign MMR_CDbgNode0Eap2_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode0Eap2_F_CustomAction1_Data = (CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_CustomAction1), 64'(MMR_CDbgNode0Eap2_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_CustomAction1_Data_prev = MMR_CDbgNode0Eap2_F_CustomAction1;
assign MMR_CDbgNode0Eap2_F_CustomAction1_Data_muxed = MMR_CDbgNode0Eap2_F_CustomAction1_WrEn ? MMR_CDbgNode0Eap2_F_CustomAction1_Data : MMR_CDbgNode0Eap2_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_CustomAction1_Data),
    .out   (MMR_CDbgNode0Eap2_F_CustomAction1)
);

logic                                           MMR_CDbgNode0Eap2_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0_Data;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap2_F_CustomAction0_Data_prev;
assign MMR_CDbgNode0Eap2_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode0Eap2_F_CustomAction0_Data = (CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_CustomAction0), 64'(MMR_CDbgNode0Eap2_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_CustomAction0_Data_prev = MMR_CDbgNode0Eap2_F_CustomAction0;
assign MMR_CDbgNode0Eap2_F_CustomAction0_Data_muxed = MMR_CDbgNode0Eap2_F_CustomAction0_WrEn ? MMR_CDbgNode0Eap2_F_CustomAction0_Data : MMR_CDbgNode0Eap2_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_CustomAction0_Data),
    .out   (MMR_CDbgNode0Eap2_F_CustomAction0)
);

logic                                           MMR_CDbgNode0Eap2_F_EventType1_WrEn;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType1_Data;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType1_DataEff;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType1_Data_prev;
assign MMR_CDbgNode0Eap2_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode0Eap2_F_EventType1_Data = (CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_EventType1), 64'(MMR_CDbgNode0Eap2_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_EventType1_Data_prev = MMR_CDbgNode0Eap2_F_EventType1;
assign MMR_CDbgNode0Eap2_F_EventType1_Data_muxed = MMR_CDbgNode0Eap2_F_EventType1_WrEn ? MMR_CDbgNode0Eap2_F_EventType1_Data : MMR_CDbgNode0Eap2_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_EventType1_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_EventType1_Data),
    .out   (MMR_CDbgNode0Eap2_F_EventType1)
);

logic                                           MMR_CDbgNode0Eap2_F_EventType0_WrEn;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType0_Data;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType0_DataEff;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap2_F_EventType0_Data_prev;
assign MMR_CDbgNode0Eap2_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode0Eap2_F_EventType0_Data = (CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_EventType0), 64'(MMR_CDbgNode0Eap2_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_EventType0_Data_prev = MMR_CDbgNode0Eap2_F_EventType0;
assign MMR_CDbgNode0Eap2_F_EventType0_Data_muxed = MMR_CDbgNode0Eap2_F_EventType0_WrEn ? MMR_CDbgNode0Eap2_F_EventType0_Data : MMR_CDbgNode0Eap2_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_EventType0_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_EventType0_Data),
    .out   (MMR_CDbgNode0Eap2_F_EventType0)
);

logic                                           MMR_CDbgNode0Eap2_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap2_F_LogicalOp_Data;
logic [CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap2_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap2_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap2_F_LogicalOp_Data_prev;
assign MMR_CDbgNode0Eap2_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode0Eap2_F_LogicalOp_Data = (CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_LogicalOp), 64'(MMR_CDbgNode0Eap2_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_LogicalOp_Data_prev = MMR_CDbgNode0Eap2_F_LogicalOp;
assign MMR_CDbgNode0Eap2_F_LogicalOp_Data_muxed = MMR_CDbgNode0Eap2_F_LogicalOp_WrEn ? MMR_CDbgNode0Eap2_F_LogicalOp_Data : MMR_CDbgNode0Eap2_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_LogicalOp_Data),
    .out   (MMR_CDbgNode0Eap2_F_LogicalOp)
);

logic                                           MMR_CDbgNode0Eap2_F_Action1_WrEn;
logic [CLA_CDBGNODE0EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action1_Data;
logic [CLA_CDBGNODE0EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action1_DataEff;
logic [CLA_CDBGNODE0EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action1_Data_muxed;
logic [CLA_CDBGNODE0EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action1_Data_prev;
assign MMR_CDbgNode0Eap2_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode0Eap2_F_Action1_Data = (CLA_CDBGNODE0EAP2_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_Action1), 64'(MMR_CDbgNode0Eap2_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_Action1_Data_prev = MMR_CDbgNode0Eap2_F_Action1;
assign MMR_CDbgNode0Eap2_F_Action1_Data_muxed = MMR_CDbgNode0Eap2_F_Action1_WrEn ? MMR_CDbgNode0Eap2_F_Action1_Data : MMR_CDbgNode0Eap2_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_ACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_Action1_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_Action1_Data),
    .out   (MMR_CDbgNode0Eap2_F_Action1)
);

logic                                           MMR_CDbgNode0Eap2_F_Action0_WrEn;
logic [CLA_CDBGNODE0EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action0_Data;
logic [CLA_CDBGNODE0EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action0_DataEff;
logic [CLA_CDBGNODE0EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action0_Data_muxed;
logic [CLA_CDBGNODE0EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap2_F_Action0_Data_prev;
assign MMR_CDbgNode0Eap2_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode0Eap2_F_Action0_Data = (CLA_CDBGNODE0EAP2_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_Action0), 64'(MMR_CDbgNode0Eap2_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_Action0_Data_prev = MMR_CDbgNode0Eap2_F_Action0;
assign MMR_CDbgNode0Eap2_F_Action0_Data_muxed = MMR_CDbgNode0Eap2_F_Action0_WrEn ? MMR_CDbgNode0Eap2_F_Action0_Data : MMR_CDbgNode0Eap2_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_ACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_Action0_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_Action0_Data),
    .out   (MMR_CDbgNode0Eap2_F_Action0)
);

logic                                           MMR_CDbgNode0Eap2_F_DestNode_WrEn;
logic [CLA_CDBGNODE0EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap2_F_DestNode_Data;
logic [CLA_CDBGNODE0EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap2_F_DestNode_DataEff;
logic [CLA_CDBGNODE0EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap2_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE0EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap2_F_DestNode_Data_prev;
assign MMR_CDbgNode0Eap2_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode0Eap2_F_DestNode_Data = (CLA_CDBGNODE0EAP2_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap2_F_DestNode), 64'(MMR_CDbgNode0Eap2_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap2_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP2))));
assign MMR_CDbgNode0Eap2_F_DestNode_Data_prev = MMR_CDbgNode0Eap2_F_DestNode;
assign MMR_CDbgNode0Eap2_F_DestNode_Data_muxed = MMR_CDbgNode0Eap2_F_DestNode_WrEn ? MMR_CDbgNode0Eap2_F_DestNode_Data : MMR_CDbgNode0Eap2_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP2_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP2_DESTNODE_WIDTH'(0))
) MMR_CDbgNode0Eap2_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap2_F_DestNode_WrEn),
    .in    (MMR_CDbgNode0Eap2_F_DestNode_Data),
    .out   (MMR_CDbgNode0Eap2_F_DestNode)
);

logic                                           MMR_CDbgNode0Eap3_F_Action3_WrEn;
logic [CLA_CDBGNODE0EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action3_Data;
logic [CLA_CDBGNODE0EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action3_DataEff;
logic [CLA_CDBGNODE0EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action3_Data_muxed;
logic [CLA_CDBGNODE0EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action3_Data_prev;
assign MMR_CDbgNode0Eap3_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode0Eap3_F_Action3_Data = (CLA_CDBGNODE0EAP3_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_Action3), 64'(MMR_CDbgNode0Eap3_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_Action3_Data_prev = MMR_CDbgNode0Eap3_F_Action3;
assign MMR_CDbgNode0Eap3_F_Action3_Data_muxed = MMR_CDbgNode0Eap3_F_Action3_WrEn ? MMR_CDbgNode0Eap3_F_Action3_Data : MMR_CDbgNode0Eap3_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_ACTION3_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_Action3_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_Action3_Data),
    .out   (MMR_CDbgNode0Eap3_F_Action3)
);

logic                                           MMR_CDbgNode0Eap3_F_Action2_WrEn;
logic [CLA_CDBGNODE0EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action2_Data;
logic [CLA_CDBGNODE0EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action2_DataEff;
logic [CLA_CDBGNODE0EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action2_Data_muxed;
logic [CLA_CDBGNODE0EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action2_Data_prev;
assign MMR_CDbgNode0Eap3_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode0Eap3_F_Action2_Data = (CLA_CDBGNODE0EAP3_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_Action2), 64'(MMR_CDbgNode0Eap3_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_Action2_Data_prev = MMR_CDbgNode0Eap3_F_Action2;
assign MMR_CDbgNode0Eap3_F_Action2_Data_muxed = MMR_CDbgNode0Eap3_F_Action2_WrEn ? MMR_CDbgNode0Eap3_F_Action2_Data : MMR_CDbgNode0Eap3_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_ACTION2_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_Action2_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_Action2_Data),
    .out   (MMR_CDbgNode0Eap3_F_Action2)
);

logic                                           MMR_CDbgNode0Eap3_F_Udf_WrEn;
logic [CLA_CDBGNODE0EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap3_F_Udf_Data;
logic [CLA_CDBGNODE0EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap3_F_Udf_DataEff;
logic [CLA_CDBGNODE0EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap3_F_Udf_Data_muxed;
logic [CLA_CDBGNODE0EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode0Eap3_F_Udf_Data_prev;
assign MMR_CDbgNode0Eap3_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode0Eap3_F_Udf_Data = (CLA_CDBGNODE0EAP3_UDF_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_Udf), 64'(MMR_CDbgNode0Eap3_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_Udf_Data_prev = MMR_CDbgNode0Eap3_F_Udf;
assign MMR_CDbgNode0Eap3_F_Udf_Data_muxed = MMR_CDbgNode0Eap3_F_Udf_WrEn ? MMR_CDbgNode0Eap3_F_Udf_Data : MMR_CDbgNode0Eap3_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_UDF_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_Udf_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_Udf_Data),
    .out   (MMR_CDbgNode0Eap3_F_Udf)
);

logic                                           MMR_CDbgNode0Eap3_F_EventType2_WrEn;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType2_Data;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType2_DataEff;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType2_Data_prev;
assign MMR_CDbgNode0Eap3_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode0Eap3_F_EventType2_Data = (CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_EventType2), 64'(MMR_CDbgNode0Eap3_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_EventType2_Data_prev = MMR_CDbgNode0Eap3_F_EventType2;
assign MMR_CDbgNode0Eap3_F_EventType2_Data_muxed = MMR_CDbgNode0Eap3_F_EventType2_WrEn ? MMR_CDbgNode0Eap3_F_EventType2_Data : MMR_CDbgNode0Eap3_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_EventType2_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_EventType2_Data),
    .out   (MMR_CDbgNode0Eap3_F_EventType2)
);

logic                                           MMR_CDbgNode0Eap3_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode0Eap3_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data = (CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_CustomAction1Enable), 64'(MMR_CDbgNode0Eap3_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_prev = MMR_CDbgNode0Eap3_F_CustomAction1Enable;
assign MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode0Eap3_F_CustomAction1Enable_WrEn ? MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data : MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode0Eap3_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode0Eap3_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode0Eap3_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data = (CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_CustomAction0Enable), 64'(MMR_CDbgNode0Eap3_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_prev = MMR_CDbgNode0Eap3_F_CustomAction0Enable;
assign MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode0Eap3_F_CustomAction0Enable_WrEn ? MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data : MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode0Eap3_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode0Eap3_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1_Data;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction1_Data_prev;
assign MMR_CDbgNode0Eap3_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode0Eap3_F_CustomAction1_Data = (CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_CustomAction1), 64'(MMR_CDbgNode0Eap3_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_CustomAction1_Data_prev = MMR_CDbgNode0Eap3_F_CustomAction1;
assign MMR_CDbgNode0Eap3_F_CustomAction1_Data_muxed = MMR_CDbgNode0Eap3_F_CustomAction1_WrEn ? MMR_CDbgNode0Eap3_F_CustomAction1_Data : MMR_CDbgNode0Eap3_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_CustomAction1_Data),
    .out   (MMR_CDbgNode0Eap3_F_CustomAction1)
);

logic                                           MMR_CDbgNode0Eap3_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0_Data;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode0Eap3_F_CustomAction0_Data_prev;
assign MMR_CDbgNode0Eap3_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode0Eap3_F_CustomAction0_Data = (CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_CustomAction0), 64'(MMR_CDbgNode0Eap3_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_CustomAction0_Data_prev = MMR_CDbgNode0Eap3_F_CustomAction0;
assign MMR_CDbgNode0Eap3_F_CustomAction0_Data_muxed = MMR_CDbgNode0Eap3_F_CustomAction0_WrEn ? MMR_CDbgNode0Eap3_F_CustomAction0_Data : MMR_CDbgNode0Eap3_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_CustomAction0_Data),
    .out   (MMR_CDbgNode0Eap3_F_CustomAction0)
);

logic                                           MMR_CDbgNode0Eap3_F_EventType1_WrEn;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType1_Data;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType1_DataEff;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType1_Data_prev;
assign MMR_CDbgNode0Eap3_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode0Eap3_F_EventType1_Data = (CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_EventType1), 64'(MMR_CDbgNode0Eap3_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_EventType1_Data_prev = MMR_CDbgNode0Eap3_F_EventType1;
assign MMR_CDbgNode0Eap3_F_EventType1_Data_muxed = MMR_CDbgNode0Eap3_F_EventType1_WrEn ? MMR_CDbgNode0Eap3_F_EventType1_Data : MMR_CDbgNode0Eap3_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_EventType1_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_EventType1_Data),
    .out   (MMR_CDbgNode0Eap3_F_EventType1)
);

logic                                           MMR_CDbgNode0Eap3_F_EventType0_WrEn;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType0_Data;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType0_DataEff;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode0Eap3_F_EventType0_Data_prev;
assign MMR_CDbgNode0Eap3_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode0Eap3_F_EventType0_Data = (CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_EventType0), 64'(MMR_CDbgNode0Eap3_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_EventType0_Data_prev = MMR_CDbgNode0Eap3_F_EventType0;
assign MMR_CDbgNode0Eap3_F_EventType0_Data_muxed = MMR_CDbgNode0Eap3_F_EventType0_WrEn ? MMR_CDbgNode0Eap3_F_EventType0_Data : MMR_CDbgNode0Eap3_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_EventType0_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_EventType0_Data),
    .out   (MMR_CDbgNode0Eap3_F_EventType0)
);

logic                                           MMR_CDbgNode0Eap3_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap3_F_LogicalOp_Data;
logic [CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap3_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap3_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode0Eap3_F_LogicalOp_Data_prev;
assign MMR_CDbgNode0Eap3_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode0Eap3_F_LogicalOp_Data = (CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_LogicalOp), 64'(MMR_CDbgNode0Eap3_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_LogicalOp_Data_prev = MMR_CDbgNode0Eap3_F_LogicalOp;
assign MMR_CDbgNode0Eap3_F_LogicalOp_Data_muxed = MMR_CDbgNode0Eap3_F_LogicalOp_WrEn ? MMR_CDbgNode0Eap3_F_LogicalOp_Data : MMR_CDbgNode0Eap3_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_LogicalOp_Data),
    .out   (MMR_CDbgNode0Eap3_F_LogicalOp)
);

logic                                           MMR_CDbgNode0Eap3_F_Action1_WrEn;
logic [CLA_CDBGNODE0EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action1_Data;
logic [CLA_CDBGNODE0EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action1_DataEff;
logic [CLA_CDBGNODE0EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action1_Data_muxed;
logic [CLA_CDBGNODE0EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action1_Data_prev;
assign MMR_CDbgNode0Eap3_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode0Eap3_F_Action1_Data = (CLA_CDBGNODE0EAP3_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_Action1), 64'(MMR_CDbgNode0Eap3_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_Action1_Data_prev = MMR_CDbgNode0Eap3_F_Action1;
assign MMR_CDbgNode0Eap3_F_Action1_Data_muxed = MMR_CDbgNode0Eap3_F_Action1_WrEn ? MMR_CDbgNode0Eap3_F_Action1_Data : MMR_CDbgNode0Eap3_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_ACTION1_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_Action1_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_Action1_Data),
    .out   (MMR_CDbgNode0Eap3_F_Action1)
);

logic                                           MMR_CDbgNode0Eap3_F_Action0_WrEn;
logic [CLA_CDBGNODE0EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action0_Data;
logic [CLA_CDBGNODE0EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action0_DataEff;
logic [CLA_CDBGNODE0EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action0_Data_muxed;
logic [CLA_CDBGNODE0EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode0Eap3_F_Action0_Data_prev;
assign MMR_CDbgNode0Eap3_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode0Eap3_F_Action0_Data = (CLA_CDBGNODE0EAP3_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_Action0), 64'(MMR_CDbgNode0Eap3_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_Action0_Data_prev = MMR_CDbgNode0Eap3_F_Action0;
assign MMR_CDbgNode0Eap3_F_Action0_Data_muxed = MMR_CDbgNode0Eap3_F_Action0_WrEn ? MMR_CDbgNode0Eap3_F_Action0_Data : MMR_CDbgNode0Eap3_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_ACTION0_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_Action0_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_Action0_Data),
    .out   (MMR_CDbgNode0Eap3_F_Action0)
);

logic                                           MMR_CDbgNode0Eap3_F_DestNode_WrEn;
logic [CLA_CDBGNODE0EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap3_F_DestNode_Data;
logic [CLA_CDBGNODE0EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap3_F_DestNode_DataEff;
logic [CLA_CDBGNODE0EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap3_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE0EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode0Eap3_F_DestNode_Data_prev;
assign MMR_CDbgNode0Eap3_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode0Eap3_F_DestNode_Data = (CLA_CDBGNODE0EAP3_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode0Eap3_F_DestNode), 64'(MMR_CDbgNode0Eap3_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode0Eap3_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE0EAP3))));
assign MMR_CDbgNode0Eap3_F_DestNode_Data_prev = MMR_CDbgNode0Eap3_F_DestNode;
assign MMR_CDbgNode0Eap3_F_DestNode_Data_muxed = MMR_CDbgNode0Eap3_F_DestNode_WrEn ? MMR_CDbgNode0Eap3_F_DestNode_Data : MMR_CDbgNode0Eap3_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE0EAP3_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE0EAP3_DESTNODE_WIDTH'(0))
) MMR_CDbgNode0Eap3_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode0Eap3_F_DestNode_WrEn),
    .in    (MMR_CDbgNode0Eap3_F_DestNode_Data),
    .out   (MMR_CDbgNode0Eap3_F_DestNode)
);

logic                                           MMR_CDbgNode1Eap2_F_Action3_WrEn;
logic [CLA_CDBGNODE1EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action3_Data;
logic [CLA_CDBGNODE1EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action3_DataEff;
logic [CLA_CDBGNODE1EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action3_Data_muxed;
logic [CLA_CDBGNODE1EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action3_Data_prev;
assign MMR_CDbgNode1Eap2_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode1Eap2_F_Action3_Data = (CLA_CDBGNODE1EAP2_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_Action3), 64'(MMR_CDbgNode1Eap2_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_Action3_Data_prev = MMR_CDbgNode1Eap2_F_Action3;
assign MMR_CDbgNode1Eap2_F_Action3_Data_muxed = MMR_CDbgNode1Eap2_F_Action3_WrEn ? MMR_CDbgNode1Eap2_F_Action3_Data : MMR_CDbgNode1Eap2_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_ACTION3_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_Action3_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_Action3_Data),
    .out   (MMR_CDbgNode1Eap2_F_Action3)
);

logic                                           MMR_CDbgNode1Eap2_F_Action2_WrEn;
logic [CLA_CDBGNODE1EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action2_Data;
logic [CLA_CDBGNODE1EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action2_DataEff;
logic [CLA_CDBGNODE1EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action2_Data_muxed;
logic [CLA_CDBGNODE1EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action2_Data_prev;
assign MMR_CDbgNode1Eap2_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode1Eap2_F_Action2_Data = (CLA_CDBGNODE1EAP2_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_Action2), 64'(MMR_CDbgNode1Eap2_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_Action2_Data_prev = MMR_CDbgNode1Eap2_F_Action2;
assign MMR_CDbgNode1Eap2_F_Action2_Data_muxed = MMR_CDbgNode1Eap2_F_Action2_WrEn ? MMR_CDbgNode1Eap2_F_Action2_Data : MMR_CDbgNode1Eap2_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_ACTION2_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_Action2_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_Action2_Data),
    .out   (MMR_CDbgNode1Eap2_F_Action2)
);

logic                                           MMR_CDbgNode1Eap2_F_Udf_WrEn;
logic [CLA_CDBGNODE1EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap2_F_Udf_Data;
logic [CLA_CDBGNODE1EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap2_F_Udf_DataEff;
logic [CLA_CDBGNODE1EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap2_F_Udf_Data_muxed;
logic [CLA_CDBGNODE1EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap2_F_Udf_Data_prev;
assign MMR_CDbgNode1Eap2_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode1Eap2_F_Udf_Data = (CLA_CDBGNODE1EAP2_UDF_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_Udf), 64'(MMR_CDbgNode1Eap2_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_Udf_Data_prev = MMR_CDbgNode1Eap2_F_Udf;
assign MMR_CDbgNode1Eap2_F_Udf_Data_muxed = MMR_CDbgNode1Eap2_F_Udf_WrEn ? MMR_CDbgNode1Eap2_F_Udf_Data : MMR_CDbgNode1Eap2_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_UDF_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_Udf_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_Udf_Data),
    .out   (MMR_CDbgNode1Eap2_F_Udf)
);

logic                                           MMR_CDbgNode1Eap2_F_EventType2_WrEn;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType2_Data;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType2_DataEff;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType2_Data_prev;
assign MMR_CDbgNode1Eap2_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode1Eap2_F_EventType2_Data = (CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_EventType2), 64'(MMR_CDbgNode1Eap2_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_EventType2_Data_prev = MMR_CDbgNode1Eap2_F_EventType2;
assign MMR_CDbgNode1Eap2_F_EventType2_Data_muxed = MMR_CDbgNode1Eap2_F_EventType2_WrEn ? MMR_CDbgNode1Eap2_F_EventType2_Data : MMR_CDbgNode1Eap2_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_EventType2_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_EventType2_Data),
    .out   (MMR_CDbgNode1Eap2_F_EventType2)
);

logic                                           MMR_CDbgNode1Eap2_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode1Eap2_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data = (CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_CustomAction1Enable), 64'(MMR_CDbgNode1Eap2_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_prev = MMR_CDbgNode1Eap2_F_CustomAction1Enable;
assign MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode1Eap2_F_CustomAction1Enable_WrEn ? MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data : MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode1Eap2_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode1Eap2_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode1Eap2_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data = (CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_CustomAction0Enable), 64'(MMR_CDbgNode1Eap2_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_prev = MMR_CDbgNode1Eap2_F_CustomAction0Enable;
assign MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode1Eap2_F_CustomAction0Enable_WrEn ? MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data : MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode1Eap2_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode1Eap2_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1_Data;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction1_Data_prev;
assign MMR_CDbgNode1Eap2_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode1Eap2_F_CustomAction1_Data = (CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_CustomAction1), 64'(MMR_CDbgNode1Eap2_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_CustomAction1_Data_prev = MMR_CDbgNode1Eap2_F_CustomAction1;
assign MMR_CDbgNode1Eap2_F_CustomAction1_Data_muxed = MMR_CDbgNode1Eap2_F_CustomAction1_WrEn ? MMR_CDbgNode1Eap2_F_CustomAction1_Data : MMR_CDbgNode1Eap2_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_CustomAction1_Data),
    .out   (MMR_CDbgNode1Eap2_F_CustomAction1)
);

logic                                           MMR_CDbgNode1Eap2_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0_Data;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap2_F_CustomAction0_Data_prev;
assign MMR_CDbgNode1Eap2_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode1Eap2_F_CustomAction0_Data = (CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_CustomAction0), 64'(MMR_CDbgNode1Eap2_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_CustomAction0_Data_prev = MMR_CDbgNode1Eap2_F_CustomAction0;
assign MMR_CDbgNode1Eap2_F_CustomAction0_Data_muxed = MMR_CDbgNode1Eap2_F_CustomAction0_WrEn ? MMR_CDbgNode1Eap2_F_CustomAction0_Data : MMR_CDbgNode1Eap2_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_CustomAction0_Data),
    .out   (MMR_CDbgNode1Eap2_F_CustomAction0)
);

logic                                           MMR_CDbgNode1Eap2_F_EventType1_WrEn;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType1_Data;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType1_DataEff;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType1_Data_prev;
assign MMR_CDbgNode1Eap2_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode1Eap2_F_EventType1_Data = (CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_EventType1), 64'(MMR_CDbgNode1Eap2_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_EventType1_Data_prev = MMR_CDbgNode1Eap2_F_EventType1;
assign MMR_CDbgNode1Eap2_F_EventType1_Data_muxed = MMR_CDbgNode1Eap2_F_EventType1_WrEn ? MMR_CDbgNode1Eap2_F_EventType1_Data : MMR_CDbgNode1Eap2_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_EventType1_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_EventType1_Data),
    .out   (MMR_CDbgNode1Eap2_F_EventType1)
);

logic                                           MMR_CDbgNode1Eap2_F_EventType0_WrEn;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType0_Data;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType0_DataEff;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap2_F_EventType0_Data_prev;
assign MMR_CDbgNode1Eap2_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode1Eap2_F_EventType0_Data = (CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_EventType0), 64'(MMR_CDbgNode1Eap2_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_EventType0_Data_prev = MMR_CDbgNode1Eap2_F_EventType0;
assign MMR_CDbgNode1Eap2_F_EventType0_Data_muxed = MMR_CDbgNode1Eap2_F_EventType0_WrEn ? MMR_CDbgNode1Eap2_F_EventType0_Data : MMR_CDbgNode1Eap2_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_EventType0_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_EventType0_Data),
    .out   (MMR_CDbgNode1Eap2_F_EventType0)
);

logic                                           MMR_CDbgNode1Eap2_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap2_F_LogicalOp_Data;
logic [CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap2_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap2_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap2_F_LogicalOp_Data_prev;
assign MMR_CDbgNode1Eap2_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode1Eap2_F_LogicalOp_Data = (CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_LogicalOp), 64'(MMR_CDbgNode1Eap2_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_LogicalOp_Data_prev = MMR_CDbgNode1Eap2_F_LogicalOp;
assign MMR_CDbgNode1Eap2_F_LogicalOp_Data_muxed = MMR_CDbgNode1Eap2_F_LogicalOp_WrEn ? MMR_CDbgNode1Eap2_F_LogicalOp_Data : MMR_CDbgNode1Eap2_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_LogicalOp_Data),
    .out   (MMR_CDbgNode1Eap2_F_LogicalOp)
);

logic                                           MMR_CDbgNode1Eap2_F_Action1_WrEn;
logic [CLA_CDBGNODE1EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action1_Data;
logic [CLA_CDBGNODE1EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action1_DataEff;
logic [CLA_CDBGNODE1EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action1_Data_muxed;
logic [CLA_CDBGNODE1EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action1_Data_prev;
assign MMR_CDbgNode1Eap2_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode1Eap2_F_Action1_Data = (CLA_CDBGNODE1EAP2_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_Action1), 64'(MMR_CDbgNode1Eap2_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_Action1_Data_prev = MMR_CDbgNode1Eap2_F_Action1;
assign MMR_CDbgNode1Eap2_F_Action1_Data_muxed = MMR_CDbgNode1Eap2_F_Action1_WrEn ? MMR_CDbgNode1Eap2_F_Action1_Data : MMR_CDbgNode1Eap2_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_ACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_Action1_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_Action1_Data),
    .out   (MMR_CDbgNode1Eap2_F_Action1)
);

logic                                           MMR_CDbgNode1Eap2_F_Action0_WrEn;
logic [CLA_CDBGNODE1EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action0_Data;
logic [CLA_CDBGNODE1EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action0_DataEff;
logic [CLA_CDBGNODE1EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action0_Data_muxed;
logic [CLA_CDBGNODE1EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap2_F_Action0_Data_prev;
assign MMR_CDbgNode1Eap2_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode1Eap2_F_Action0_Data = (CLA_CDBGNODE1EAP2_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_Action0), 64'(MMR_CDbgNode1Eap2_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_Action0_Data_prev = MMR_CDbgNode1Eap2_F_Action0;
assign MMR_CDbgNode1Eap2_F_Action0_Data_muxed = MMR_CDbgNode1Eap2_F_Action0_WrEn ? MMR_CDbgNode1Eap2_F_Action0_Data : MMR_CDbgNode1Eap2_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_ACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_Action0_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_Action0_Data),
    .out   (MMR_CDbgNode1Eap2_F_Action0)
);

logic                                           MMR_CDbgNode1Eap2_F_DestNode_WrEn;
logic [CLA_CDBGNODE1EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap2_F_DestNode_Data;
logic [CLA_CDBGNODE1EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap2_F_DestNode_DataEff;
logic [CLA_CDBGNODE1EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap2_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE1EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap2_F_DestNode_Data_prev;
assign MMR_CDbgNode1Eap2_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode1Eap2_F_DestNode_Data = (CLA_CDBGNODE1EAP2_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap2_F_DestNode), 64'(MMR_CDbgNode1Eap2_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap2_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP2))));
assign MMR_CDbgNode1Eap2_F_DestNode_Data_prev = MMR_CDbgNode1Eap2_F_DestNode;
assign MMR_CDbgNode1Eap2_F_DestNode_Data_muxed = MMR_CDbgNode1Eap2_F_DestNode_WrEn ? MMR_CDbgNode1Eap2_F_DestNode_Data : MMR_CDbgNode1Eap2_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP2_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP2_DESTNODE_WIDTH'(0))
) MMR_CDbgNode1Eap2_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap2_F_DestNode_WrEn),
    .in    (MMR_CDbgNode1Eap2_F_DestNode_Data),
    .out   (MMR_CDbgNode1Eap2_F_DestNode)
);

logic                                           MMR_CDbgNode1Eap3_F_Action3_WrEn;
logic [CLA_CDBGNODE1EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action3_Data;
logic [CLA_CDBGNODE1EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action3_DataEff;
logic [CLA_CDBGNODE1EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action3_Data_muxed;
logic [CLA_CDBGNODE1EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action3_Data_prev;
assign MMR_CDbgNode1Eap3_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode1Eap3_F_Action3_Data = (CLA_CDBGNODE1EAP3_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_Action3), 64'(MMR_CDbgNode1Eap3_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_Action3_Data_prev = MMR_CDbgNode1Eap3_F_Action3;
assign MMR_CDbgNode1Eap3_F_Action3_Data_muxed = MMR_CDbgNode1Eap3_F_Action3_WrEn ? MMR_CDbgNode1Eap3_F_Action3_Data : MMR_CDbgNode1Eap3_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_ACTION3_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_Action3_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_Action3_Data),
    .out   (MMR_CDbgNode1Eap3_F_Action3)
);

logic                                           MMR_CDbgNode1Eap3_F_Action2_WrEn;
logic [CLA_CDBGNODE1EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action2_Data;
logic [CLA_CDBGNODE1EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action2_DataEff;
logic [CLA_CDBGNODE1EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action2_Data_muxed;
logic [CLA_CDBGNODE1EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action2_Data_prev;
assign MMR_CDbgNode1Eap3_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode1Eap3_F_Action2_Data = (CLA_CDBGNODE1EAP3_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_Action2), 64'(MMR_CDbgNode1Eap3_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_Action2_Data_prev = MMR_CDbgNode1Eap3_F_Action2;
assign MMR_CDbgNode1Eap3_F_Action2_Data_muxed = MMR_CDbgNode1Eap3_F_Action2_WrEn ? MMR_CDbgNode1Eap3_F_Action2_Data : MMR_CDbgNode1Eap3_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_ACTION2_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_Action2_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_Action2_Data),
    .out   (MMR_CDbgNode1Eap3_F_Action2)
);

logic                                           MMR_CDbgNode1Eap3_F_Udf_WrEn;
logic [CLA_CDBGNODE1EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap3_F_Udf_Data;
logic [CLA_CDBGNODE1EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap3_F_Udf_DataEff;
logic [CLA_CDBGNODE1EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap3_F_Udf_Data_muxed;
logic [CLA_CDBGNODE1EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode1Eap3_F_Udf_Data_prev;
assign MMR_CDbgNode1Eap3_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode1Eap3_F_Udf_Data = (CLA_CDBGNODE1EAP3_UDF_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_Udf), 64'(MMR_CDbgNode1Eap3_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_Udf_Data_prev = MMR_CDbgNode1Eap3_F_Udf;
assign MMR_CDbgNode1Eap3_F_Udf_Data_muxed = MMR_CDbgNode1Eap3_F_Udf_WrEn ? MMR_CDbgNode1Eap3_F_Udf_Data : MMR_CDbgNode1Eap3_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_UDF_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_Udf_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_Udf_Data),
    .out   (MMR_CDbgNode1Eap3_F_Udf)
);

logic                                           MMR_CDbgNode1Eap3_F_EventType2_WrEn;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType2_Data;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType2_DataEff;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType2_Data_prev;
assign MMR_CDbgNode1Eap3_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode1Eap3_F_EventType2_Data = (CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_EventType2), 64'(MMR_CDbgNode1Eap3_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_EventType2_Data_prev = MMR_CDbgNode1Eap3_F_EventType2;
assign MMR_CDbgNode1Eap3_F_EventType2_Data_muxed = MMR_CDbgNode1Eap3_F_EventType2_WrEn ? MMR_CDbgNode1Eap3_F_EventType2_Data : MMR_CDbgNode1Eap3_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_EventType2_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_EventType2_Data),
    .out   (MMR_CDbgNode1Eap3_F_EventType2)
);

logic                                           MMR_CDbgNode1Eap3_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode1Eap3_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data = (CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_CustomAction1Enable), 64'(MMR_CDbgNode1Eap3_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_prev = MMR_CDbgNode1Eap3_F_CustomAction1Enable;
assign MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode1Eap3_F_CustomAction1Enable_WrEn ? MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data : MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode1Eap3_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode1Eap3_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode1Eap3_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data = (CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_CustomAction0Enable), 64'(MMR_CDbgNode1Eap3_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_prev = MMR_CDbgNode1Eap3_F_CustomAction0Enable;
assign MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode1Eap3_F_CustomAction0Enable_WrEn ? MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data : MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode1Eap3_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode1Eap3_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1_Data;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction1_Data_prev;
assign MMR_CDbgNode1Eap3_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode1Eap3_F_CustomAction1_Data = (CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_CustomAction1), 64'(MMR_CDbgNode1Eap3_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_CustomAction1_Data_prev = MMR_CDbgNode1Eap3_F_CustomAction1;
assign MMR_CDbgNode1Eap3_F_CustomAction1_Data_muxed = MMR_CDbgNode1Eap3_F_CustomAction1_WrEn ? MMR_CDbgNode1Eap3_F_CustomAction1_Data : MMR_CDbgNode1Eap3_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_CustomAction1_Data),
    .out   (MMR_CDbgNode1Eap3_F_CustomAction1)
);

logic                                           MMR_CDbgNode1Eap3_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0_Data;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode1Eap3_F_CustomAction0_Data_prev;
assign MMR_CDbgNode1Eap3_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode1Eap3_F_CustomAction0_Data = (CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_CustomAction0), 64'(MMR_CDbgNode1Eap3_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_CustomAction0_Data_prev = MMR_CDbgNode1Eap3_F_CustomAction0;
assign MMR_CDbgNode1Eap3_F_CustomAction0_Data_muxed = MMR_CDbgNode1Eap3_F_CustomAction0_WrEn ? MMR_CDbgNode1Eap3_F_CustomAction0_Data : MMR_CDbgNode1Eap3_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_CustomAction0_Data),
    .out   (MMR_CDbgNode1Eap3_F_CustomAction0)
);

logic                                           MMR_CDbgNode1Eap3_F_EventType1_WrEn;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType1_Data;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType1_DataEff;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType1_Data_prev;
assign MMR_CDbgNode1Eap3_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode1Eap3_F_EventType1_Data = (CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_EventType1), 64'(MMR_CDbgNode1Eap3_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_EventType1_Data_prev = MMR_CDbgNode1Eap3_F_EventType1;
assign MMR_CDbgNode1Eap3_F_EventType1_Data_muxed = MMR_CDbgNode1Eap3_F_EventType1_WrEn ? MMR_CDbgNode1Eap3_F_EventType1_Data : MMR_CDbgNode1Eap3_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_EventType1_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_EventType1_Data),
    .out   (MMR_CDbgNode1Eap3_F_EventType1)
);

logic                                           MMR_CDbgNode1Eap3_F_EventType0_WrEn;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType0_Data;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType0_DataEff;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode1Eap3_F_EventType0_Data_prev;
assign MMR_CDbgNode1Eap3_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode1Eap3_F_EventType0_Data = (CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_EventType0), 64'(MMR_CDbgNode1Eap3_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_EventType0_Data_prev = MMR_CDbgNode1Eap3_F_EventType0;
assign MMR_CDbgNode1Eap3_F_EventType0_Data_muxed = MMR_CDbgNode1Eap3_F_EventType0_WrEn ? MMR_CDbgNode1Eap3_F_EventType0_Data : MMR_CDbgNode1Eap3_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_EventType0_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_EventType0_Data),
    .out   (MMR_CDbgNode1Eap3_F_EventType0)
);

logic                                           MMR_CDbgNode1Eap3_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap3_F_LogicalOp_Data;
logic [CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap3_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap3_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode1Eap3_F_LogicalOp_Data_prev;
assign MMR_CDbgNode1Eap3_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode1Eap3_F_LogicalOp_Data = (CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_LogicalOp), 64'(MMR_CDbgNode1Eap3_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_LogicalOp_Data_prev = MMR_CDbgNode1Eap3_F_LogicalOp;
assign MMR_CDbgNode1Eap3_F_LogicalOp_Data_muxed = MMR_CDbgNode1Eap3_F_LogicalOp_WrEn ? MMR_CDbgNode1Eap3_F_LogicalOp_Data : MMR_CDbgNode1Eap3_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_LogicalOp_Data),
    .out   (MMR_CDbgNode1Eap3_F_LogicalOp)
);

logic                                           MMR_CDbgNode1Eap3_F_Action1_WrEn;
logic [CLA_CDBGNODE1EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action1_Data;
logic [CLA_CDBGNODE1EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action1_DataEff;
logic [CLA_CDBGNODE1EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action1_Data_muxed;
logic [CLA_CDBGNODE1EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action1_Data_prev;
assign MMR_CDbgNode1Eap3_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode1Eap3_F_Action1_Data = (CLA_CDBGNODE1EAP3_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_Action1), 64'(MMR_CDbgNode1Eap3_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_Action1_Data_prev = MMR_CDbgNode1Eap3_F_Action1;
assign MMR_CDbgNode1Eap3_F_Action1_Data_muxed = MMR_CDbgNode1Eap3_F_Action1_WrEn ? MMR_CDbgNode1Eap3_F_Action1_Data : MMR_CDbgNode1Eap3_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_ACTION1_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_Action1_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_Action1_Data),
    .out   (MMR_CDbgNode1Eap3_F_Action1)
);

logic                                           MMR_CDbgNode1Eap3_F_Action0_WrEn;
logic [CLA_CDBGNODE1EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action0_Data;
logic [CLA_CDBGNODE1EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action0_DataEff;
logic [CLA_CDBGNODE1EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action0_Data_muxed;
logic [CLA_CDBGNODE1EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode1Eap3_F_Action0_Data_prev;
assign MMR_CDbgNode1Eap3_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode1Eap3_F_Action0_Data = (CLA_CDBGNODE1EAP3_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_Action0), 64'(MMR_CDbgNode1Eap3_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_Action0_Data_prev = MMR_CDbgNode1Eap3_F_Action0;
assign MMR_CDbgNode1Eap3_F_Action0_Data_muxed = MMR_CDbgNode1Eap3_F_Action0_WrEn ? MMR_CDbgNode1Eap3_F_Action0_Data : MMR_CDbgNode1Eap3_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_ACTION0_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_Action0_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_Action0_Data),
    .out   (MMR_CDbgNode1Eap3_F_Action0)
);

logic                                           MMR_CDbgNode1Eap3_F_DestNode_WrEn;
logic [CLA_CDBGNODE1EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap3_F_DestNode_Data;
logic [CLA_CDBGNODE1EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap3_F_DestNode_DataEff;
logic [CLA_CDBGNODE1EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap3_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE1EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode1Eap3_F_DestNode_Data_prev;
assign MMR_CDbgNode1Eap3_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode1Eap3_F_DestNode_Data = (CLA_CDBGNODE1EAP3_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode1Eap3_F_DestNode), 64'(MMR_CDbgNode1Eap3_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode1Eap3_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE1EAP3))));
assign MMR_CDbgNode1Eap3_F_DestNode_Data_prev = MMR_CDbgNode1Eap3_F_DestNode;
assign MMR_CDbgNode1Eap3_F_DestNode_Data_muxed = MMR_CDbgNode1Eap3_F_DestNode_WrEn ? MMR_CDbgNode1Eap3_F_DestNode_Data : MMR_CDbgNode1Eap3_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE1EAP3_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE1EAP3_DESTNODE_WIDTH'(0))
) MMR_CDbgNode1Eap3_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode1Eap3_F_DestNode_WrEn),
    .in    (MMR_CDbgNode1Eap3_F_DestNode_Data),
    .out   (MMR_CDbgNode1Eap3_F_DestNode)
);

logic                                           MMR_CDbgNode2Eap2_F_Action3_WrEn;
logic [CLA_CDBGNODE2EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action3_Data;
logic [CLA_CDBGNODE2EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action3_DataEff;
logic [CLA_CDBGNODE2EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action3_Data_muxed;
logic [CLA_CDBGNODE2EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action3_Data_prev;
assign MMR_CDbgNode2Eap2_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode2Eap2_F_Action3_Data = (CLA_CDBGNODE2EAP2_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_Action3), 64'(MMR_CDbgNode2Eap2_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_Action3_Data_prev = MMR_CDbgNode2Eap2_F_Action3;
assign MMR_CDbgNode2Eap2_F_Action3_Data_muxed = MMR_CDbgNode2Eap2_F_Action3_WrEn ? MMR_CDbgNode2Eap2_F_Action3_Data : MMR_CDbgNode2Eap2_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_ACTION3_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_Action3_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_Action3_Data),
    .out   (MMR_CDbgNode2Eap2_F_Action3)
);

logic                                           MMR_CDbgNode2Eap2_F_Action2_WrEn;
logic [CLA_CDBGNODE2EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action2_Data;
logic [CLA_CDBGNODE2EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action2_DataEff;
logic [CLA_CDBGNODE2EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action2_Data_muxed;
logic [CLA_CDBGNODE2EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action2_Data_prev;
assign MMR_CDbgNode2Eap2_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode2Eap2_F_Action2_Data = (CLA_CDBGNODE2EAP2_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_Action2), 64'(MMR_CDbgNode2Eap2_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_Action2_Data_prev = MMR_CDbgNode2Eap2_F_Action2;
assign MMR_CDbgNode2Eap2_F_Action2_Data_muxed = MMR_CDbgNode2Eap2_F_Action2_WrEn ? MMR_CDbgNode2Eap2_F_Action2_Data : MMR_CDbgNode2Eap2_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_ACTION2_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_Action2_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_Action2_Data),
    .out   (MMR_CDbgNode2Eap2_F_Action2)
);

logic                                           MMR_CDbgNode2Eap2_F_Udf_WrEn;
logic [CLA_CDBGNODE2EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap2_F_Udf_Data;
logic [CLA_CDBGNODE2EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap2_F_Udf_DataEff;
logic [CLA_CDBGNODE2EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap2_F_Udf_Data_muxed;
logic [CLA_CDBGNODE2EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap2_F_Udf_Data_prev;
assign MMR_CDbgNode2Eap2_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode2Eap2_F_Udf_Data = (CLA_CDBGNODE2EAP2_UDF_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_Udf), 64'(MMR_CDbgNode2Eap2_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_Udf_Data_prev = MMR_CDbgNode2Eap2_F_Udf;
assign MMR_CDbgNode2Eap2_F_Udf_Data_muxed = MMR_CDbgNode2Eap2_F_Udf_WrEn ? MMR_CDbgNode2Eap2_F_Udf_Data : MMR_CDbgNode2Eap2_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_UDF_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_Udf_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_Udf_Data),
    .out   (MMR_CDbgNode2Eap2_F_Udf)
);

logic                                           MMR_CDbgNode2Eap2_F_EventType2_WrEn;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType2_Data;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType2_DataEff;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType2_Data_prev;
assign MMR_CDbgNode2Eap2_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode2Eap2_F_EventType2_Data = (CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_EventType2), 64'(MMR_CDbgNode2Eap2_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_EventType2_Data_prev = MMR_CDbgNode2Eap2_F_EventType2;
assign MMR_CDbgNode2Eap2_F_EventType2_Data_muxed = MMR_CDbgNode2Eap2_F_EventType2_WrEn ? MMR_CDbgNode2Eap2_F_EventType2_Data : MMR_CDbgNode2Eap2_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_EventType2_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_EventType2_Data),
    .out   (MMR_CDbgNode2Eap2_F_EventType2)
);

logic                                           MMR_CDbgNode2Eap2_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode2Eap2_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data = (CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_CustomAction1Enable), 64'(MMR_CDbgNode2Eap2_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_prev = MMR_CDbgNode2Eap2_F_CustomAction1Enable;
assign MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode2Eap2_F_CustomAction1Enable_WrEn ? MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data : MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode2Eap2_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode2Eap2_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode2Eap2_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data = (CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_CustomAction0Enable), 64'(MMR_CDbgNode2Eap2_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_prev = MMR_CDbgNode2Eap2_F_CustomAction0Enable;
assign MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode2Eap2_F_CustomAction0Enable_WrEn ? MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data : MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode2Eap2_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode2Eap2_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1_Data;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction1_Data_prev;
assign MMR_CDbgNode2Eap2_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode2Eap2_F_CustomAction1_Data = (CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_CustomAction1), 64'(MMR_CDbgNode2Eap2_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_CustomAction1_Data_prev = MMR_CDbgNode2Eap2_F_CustomAction1;
assign MMR_CDbgNode2Eap2_F_CustomAction1_Data_muxed = MMR_CDbgNode2Eap2_F_CustomAction1_WrEn ? MMR_CDbgNode2Eap2_F_CustomAction1_Data : MMR_CDbgNode2Eap2_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_CustomAction1_Data),
    .out   (MMR_CDbgNode2Eap2_F_CustomAction1)
);

logic                                           MMR_CDbgNode2Eap2_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0_Data;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap2_F_CustomAction0_Data_prev;
assign MMR_CDbgNode2Eap2_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode2Eap2_F_CustomAction0_Data = (CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_CustomAction0), 64'(MMR_CDbgNode2Eap2_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_CustomAction0_Data_prev = MMR_CDbgNode2Eap2_F_CustomAction0;
assign MMR_CDbgNode2Eap2_F_CustomAction0_Data_muxed = MMR_CDbgNode2Eap2_F_CustomAction0_WrEn ? MMR_CDbgNode2Eap2_F_CustomAction0_Data : MMR_CDbgNode2Eap2_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_CustomAction0_Data),
    .out   (MMR_CDbgNode2Eap2_F_CustomAction0)
);

logic                                           MMR_CDbgNode2Eap2_F_EventType1_WrEn;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType1_Data;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType1_DataEff;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType1_Data_prev;
assign MMR_CDbgNode2Eap2_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode2Eap2_F_EventType1_Data = (CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_EventType1), 64'(MMR_CDbgNode2Eap2_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_EventType1_Data_prev = MMR_CDbgNode2Eap2_F_EventType1;
assign MMR_CDbgNode2Eap2_F_EventType1_Data_muxed = MMR_CDbgNode2Eap2_F_EventType1_WrEn ? MMR_CDbgNode2Eap2_F_EventType1_Data : MMR_CDbgNode2Eap2_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_EventType1_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_EventType1_Data),
    .out   (MMR_CDbgNode2Eap2_F_EventType1)
);

logic                                           MMR_CDbgNode2Eap2_F_EventType0_WrEn;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType0_Data;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType0_DataEff;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap2_F_EventType0_Data_prev;
assign MMR_CDbgNode2Eap2_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode2Eap2_F_EventType0_Data = (CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_EventType0), 64'(MMR_CDbgNode2Eap2_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_EventType0_Data_prev = MMR_CDbgNode2Eap2_F_EventType0;
assign MMR_CDbgNode2Eap2_F_EventType0_Data_muxed = MMR_CDbgNode2Eap2_F_EventType0_WrEn ? MMR_CDbgNode2Eap2_F_EventType0_Data : MMR_CDbgNode2Eap2_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_EventType0_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_EventType0_Data),
    .out   (MMR_CDbgNode2Eap2_F_EventType0)
);

logic                                           MMR_CDbgNode2Eap2_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap2_F_LogicalOp_Data;
logic [CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap2_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap2_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap2_F_LogicalOp_Data_prev;
assign MMR_CDbgNode2Eap2_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode2Eap2_F_LogicalOp_Data = (CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_LogicalOp), 64'(MMR_CDbgNode2Eap2_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_LogicalOp_Data_prev = MMR_CDbgNode2Eap2_F_LogicalOp;
assign MMR_CDbgNode2Eap2_F_LogicalOp_Data_muxed = MMR_CDbgNode2Eap2_F_LogicalOp_WrEn ? MMR_CDbgNode2Eap2_F_LogicalOp_Data : MMR_CDbgNode2Eap2_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_LogicalOp_Data),
    .out   (MMR_CDbgNode2Eap2_F_LogicalOp)
);

logic                                           MMR_CDbgNode2Eap2_F_Action1_WrEn;
logic [CLA_CDBGNODE2EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action1_Data;
logic [CLA_CDBGNODE2EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action1_DataEff;
logic [CLA_CDBGNODE2EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action1_Data_muxed;
logic [CLA_CDBGNODE2EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action1_Data_prev;
assign MMR_CDbgNode2Eap2_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode2Eap2_F_Action1_Data = (CLA_CDBGNODE2EAP2_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_Action1), 64'(MMR_CDbgNode2Eap2_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_Action1_Data_prev = MMR_CDbgNode2Eap2_F_Action1;
assign MMR_CDbgNode2Eap2_F_Action1_Data_muxed = MMR_CDbgNode2Eap2_F_Action1_WrEn ? MMR_CDbgNode2Eap2_F_Action1_Data : MMR_CDbgNode2Eap2_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_ACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_Action1_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_Action1_Data),
    .out   (MMR_CDbgNode2Eap2_F_Action1)
);

logic                                           MMR_CDbgNode2Eap2_F_Action0_WrEn;
logic [CLA_CDBGNODE2EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action0_Data;
logic [CLA_CDBGNODE2EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action0_DataEff;
logic [CLA_CDBGNODE2EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action0_Data_muxed;
logic [CLA_CDBGNODE2EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap2_F_Action0_Data_prev;
assign MMR_CDbgNode2Eap2_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode2Eap2_F_Action0_Data = (CLA_CDBGNODE2EAP2_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_Action0), 64'(MMR_CDbgNode2Eap2_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_Action0_Data_prev = MMR_CDbgNode2Eap2_F_Action0;
assign MMR_CDbgNode2Eap2_F_Action0_Data_muxed = MMR_CDbgNode2Eap2_F_Action0_WrEn ? MMR_CDbgNode2Eap2_F_Action0_Data : MMR_CDbgNode2Eap2_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_ACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_Action0_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_Action0_Data),
    .out   (MMR_CDbgNode2Eap2_F_Action0)
);

logic                                           MMR_CDbgNode2Eap2_F_DestNode_WrEn;
logic [CLA_CDBGNODE2EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap2_F_DestNode_Data;
logic [CLA_CDBGNODE2EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap2_F_DestNode_DataEff;
logic [CLA_CDBGNODE2EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap2_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE2EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap2_F_DestNode_Data_prev;
assign MMR_CDbgNode2Eap2_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode2Eap2_F_DestNode_Data = (CLA_CDBGNODE2EAP2_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap2_F_DestNode), 64'(MMR_CDbgNode2Eap2_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap2_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP2))));
assign MMR_CDbgNode2Eap2_F_DestNode_Data_prev = MMR_CDbgNode2Eap2_F_DestNode;
assign MMR_CDbgNode2Eap2_F_DestNode_Data_muxed = MMR_CDbgNode2Eap2_F_DestNode_WrEn ? MMR_CDbgNode2Eap2_F_DestNode_Data : MMR_CDbgNode2Eap2_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP2_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP2_DESTNODE_WIDTH'(0))
) MMR_CDbgNode2Eap2_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap2_F_DestNode_WrEn),
    .in    (MMR_CDbgNode2Eap2_F_DestNode_Data),
    .out   (MMR_CDbgNode2Eap2_F_DestNode)
);

logic                                           MMR_CDbgNode2Eap3_F_Action3_WrEn;
logic [CLA_CDBGNODE2EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action3_Data;
logic [CLA_CDBGNODE2EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action3_DataEff;
logic [CLA_CDBGNODE2EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action3_Data_muxed;
logic [CLA_CDBGNODE2EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action3_Data_prev;
assign MMR_CDbgNode2Eap3_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode2Eap3_F_Action3_Data = (CLA_CDBGNODE2EAP3_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_Action3), 64'(MMR_CDbgNode2Eap3_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_Action3_Data_prev = MMR_CDbgNode2Eap3_F_Action3;
assign MMR_CDbgNode2Eap3_F_Action3_Data_muxed = MMR_CDbgNode2Eap3_F_Action3_WrEn ? MMR_CDbgNode2Eap3_F_Action3_Data : MMR_CDbgNode2Eap3_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_ACTION3_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_Action3_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_Action3_Data),
    .out   (MMR_CDbgNode2Eap3_F_Action3)
);

logic                                           MMR_CDbgNode2Eap3_F_Action2_WrEn;
logic [CLA_CDBGNODE2EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action2_Data;
logic [CLA_CDBGNODE2EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action2_DataEff;
logic [CLA_CDBGNODE2EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action2_Data_muxed;
logic [CLA_CDBGNODE2EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action2_Data_prev;
assign MMR_CDbgNode2Eap3_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode2Eap3_F_Action2_Data = (CLA_CDBGNODE2EAP3_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_Action2), 64'(MMR_CDbgNode2Eap3_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_Action2_Data_prev = MMR_CDbgNode2Eap3_F_Action2;
assign MMR_CDbgNode2Eap3_F_Action2_Data_muxed = MMR_CDbgNode2Eap3_F_Action2_WrEn ? MMR_CDbgNode2Eap3_F_Action2_Data : MMR_CDbgNode2Eap3_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_ACTION2_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_Action2_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_Action2_Data),
    .out   (MMR_CDbgNode2Eap3_F_Action2)
);

logic                                           MMR_CDbgNode2Eap3_F_Udf_WrEn;
logic [CLA_CDBGNODE2EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap3_F_Udf_Data;
logic [CLA_CDBGNODE2EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap3_F_Udf_DataEff;
logic [CLA_CDBGNODE2EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap3_F_Udf_Data_muxed;
logic [CLA_CDBGNODE2EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode2Eap3_F_Udf_Data_prev;
assign MMR_CDbgNode2Eap3_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode2Eap3_F_Udf_Data = (CLA_CDBGNODE2EAP3_UDF_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_Udf), 64'(MMR_CDbgNode2Eap3_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_Udf_Data_prev = MMR_CDbgNode2Eap3_F_Udf;
assign MMR_CDbgNode2Eap3_F_Udf_Data_muxed = MMR_CDbgNode2Eap3_F_Udf_WrEn ? MMR_CDbgNode2Eap3_F_Udf_Data : MMR_CDbgNode2Eap3_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_UDF_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_Udf_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_Udf_Data),
    .out   (MMR_CDbgNode2Eap3_F_Udf)
);

logic                                           MMR_CDbgNode2Eap3_F_EventType2_WrEn;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType2_Data;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType2_DataEff;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType2_Data_prev;
assign MMR_CDbgNode2Eap3_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode2Eap3_F_EventType2_Data = (CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_EventType2), 64'(MMR_CDbgNode2Eap3_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_EventType2_Data_prev = MMR_CDbgNode2Eap3_F_EventType2;
assign MMR_CDbgNode2Eap3_F_EventType2_Data_muxed = MMR_CDbgNode2Eap3_F_EventType2_WrEn ? MMR_CDbgNode2Eap3_F_EventType2_Data : MMR_CDbgNode2Eap3_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_EventType2_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_EventType2_Data),
    .out   (MMR_CDbgNode2Eap3_F_EventType2)
);

logic                                           MMR_CDbgNode2Eap3_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode2Eap3_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data = (CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_CustomAction1Enable), 64'(MMR_CDbgNode2Eap3_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_prev = MMR_CDbgNode2Eap3_F_CustomAction1Enable;
assign MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode2Eap3_F_CustomAction1Enable_WrEn ? MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data : MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode2Eap3_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode2Eap3_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode2Eap3_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data = (CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_CustomAction0Enable), 64'(MMR_CDbgNode2Eap3_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_prev = MMR_CDbgNode2Eap3_F_CustomAction0Enable;
assign MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode2Eap3_F_CustomAction0Enable_WrEn ? MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data : MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode2Eap3_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode2Eap3_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1_Data;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction1_Data_prev;
assign MMR_CDbgNode2Eap3_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode2Eap3_F_CustomAction1_Data = (CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_CustomAction1), 64'(MMR_CDbgNode2Eap3_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_CustomAction1_Data_prev = MMR_CDbgNode2Eap3_F_CustomAction1;
assign MMR_CDbgNode2Eap3_F_CustomAction1_Data_muxed = MMR_CDbgNode2Eap3_F_CustomAction1_WrEn ? MMR_CDbgNode2Eap3_F_CustomAction1_Data : MMR_CDbgNode2Eap3_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_CustomAction1_Data),
    .out   (MMR_CDbgNode2Eap3_F_CustomAction1)
);

logic                                           MMR_CDbgNode2Eap3_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0_Data;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode2Eap3_F_CustomAction0_Data_prev;
assign MMR_CDbgNode2Eap3_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode2Eap3_F_CustomAction0_Data = (CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_CustomAction0), 64'(MMR_CDbgNode2Eap3_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_CustomAction0_Data_prev = MMR_CDbgNode2Eap3_F_CustomAction0;
assign MMR_CDbgNode2Eap3_F_CustomAction0_Data_muxed = MMR_CDbgNode2Eap3_F_CustomAction0_WrEn ? MMR_CDbgNode2Eap3_F_CustomAction0_Data : MMR_CDbgNode2Eap3_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_CustomAction0_Data),
    .out   (MMR_CDbgNode2Eap3_F_CustomAction0)
);

logic                                           MMR_CDbgNode2Eap3_F_EventType1_WrEn;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType1_Data;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType1_DataEff;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType1_Data_prev;
assign MMR_CDbgNode2Eap3_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode2Eap3_F_EventType1_Data = (CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_EventType1), 64'(MMR_CDbgNode2Eap3_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_EventType1_Data_prev = MMR_CDbgNode2Eap3_F_EventType1;
assign MMR_CDbgNode2Eap3_F_EventType1_Data_muxed = MMR_CDbgNode2Eap3_F_EventType1_WrEn ? MMR_CDbgNode2Eap3_F_EventType1_Data : MMR_CDbgNode2Eap3_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_EventType1_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_EventType1_Data),
    .out   (MMR_CDbgNode2Eap3_F_EventType1)
);

logic                                           MMR_CDbgNode2Eap3_F_EventType0_WrEn;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType0_Data;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType0_DataEff;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode2Eap3_F_EventType0_Data_prev;
assign MMR_CDbgNode2Eap3_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode2Eap3_F_EventType0_Data = (CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_EventType0), 64'(MMR_CDbgNode2Eap3_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_EventType0_Data_prev = MMR_CDbgNode2Eap3_F_EventType0;
assign MMR_CDbgNode2Eap3_F_EventType0_Data_muxed = MMR_CDbgNode2Eap3_F_EventType0_WrEn ? MMR_CDbgNode2Eap3_F_EventType0_Data : MMR_CDbgNode2Eap3_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_EventType0_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_EventType0_Data),
    .out   (MMR_CDbgNode2Eap3_F_EventType0)
);

logic                                           MMR_CDbgNode2Eap3_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap3_F_LogicalOp_Data;
logic [CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap3_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap3_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode2Eap3_F_LogicalOp_Data_prev;
assign MMR_CDbgNode2Eap3_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode2Eap3_F_LogicalOp_Data = (CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_LogicalOp), 64'(MMR_CDbgNode2Eap3_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_LogicalOp_Data_prev = MMR_CDbgNode2Eap3_F_LogicalOp;
assign MMR_CDbgNode2Eap3_F_LogicalOp_Data_muxed = MMR_CDbgNode2Eap3_F_LogicalOp_WrEn ? MMR_CDbgNode2Eap3_F_LogicalOp_Data : MMR_CDbgNode2Eap3_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_LogicalOp_Data),
    .out   (MMR_CDbgNode2Eap3_F_LogicalOp)
);

logic                                           MMR_CDbgNode2Eap3_F_Action1_WrEn;
logic [CLA_CDBGNODE2EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action1_Data;
logic [CLA_CDBGNODE2EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action1_DataEff;
logic [CLA_CDBGNODE2EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action1_Data_muxed;
logic [CLA_CDBGNODE2EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action1_Data_prev;
assign MMR_CDbgNode2Eap3_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode2Eap3_F_Action1_Data = (CLA_CDBGNODE2EAP3_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_Action1), 64'(MMR_CDbgNode2Eap3_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_Action1_Data_prev = MMR_CDbgNode2Eap3_F_Action1;
assign MMR_CDbgNode2Eap3_F_Action1_Data_muxed = MMR_CDbgNode2Eap3_F_Action1_WrEn ? MMR_CDbgNode2Eap3_F_Action1_Data : MMR_CDbgNode2Eap3_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_ACTION1_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_Action1_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_Action1_Data),
    .out   (MMR_CDbgNode2Eap3_F_Action1)
);

logic                                           MMR_CDbgNode2Eap3_F_Action0_WrEn;
logic [CLA_CDBGNODE2EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action0_Data;
logic [CLA_CDBGNODE2EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action0_DataEff;
logic [CLA_CDBGNODE2EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action0_Data_muxed;
logic [CLA_CDBGNODE2EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode2Eap3_F_Action0_Data_prev;
assign MMR_CDbgNode2Eap3_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode2Eap3_F_Action0_Data = (CLA_CDBGNODE2EAP3_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_Action0), 64'(MMR_CDbgNode2Eap3_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_Action0_Data_prev = MMR_CDbgNode2Eap3_F_Action0;
assign MMR_CDbgNode2Eap3_F_Action0_Data_muxed = MMR_CDbgNode2Eap3_F_Action0_WrEn ? MMR_CDbgNode2Eap3_F_Action0_Data : MMR_CDbgNode2Eap3_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_ACTION0_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_Action0_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_Action0_Data),
    .out   (MMR_CDbgNode2Eap3_F_Action0)
);

logic                                           MMR_CDbgNode2Eap3_F_DestNode_WrEn;
logic [CLA_CDBGNODE2EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap3_F_DestNode_Data;
logic [CLA_CDBGNODE2EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap3_F_DestNode_DataEff;
logic [CLA_CDBGNODE2EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap3_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE2EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode2Eap3_F_DestNode_Data_prev;
assign MMR_CDbgNode2Eap3_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode2Eap3_F_DestNode_Data = (CLA_CDBGNODE2EAP3_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode2Eap3_F_DestNode), 64'(MMR_CDbgNode2Eap3_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode2Eap3_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE2EAP3))));
assign MMR_CDbgNode2Eap3_F_DestNode_Data_prev = MMR_CDbgNode2Eap3_F_DestNode;
assign MMR_CDbgNode2Eap3_F_DestNode_Data_muxed = MMR_CDbgNode2Eap3_F_DestNode_WrEn ? MMR_CDbgNode2Eap3_F_DestNode_Data : MMR_CDbgNode2Eap3_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE2EAP3_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE2EAP3_DESTNODE_WIDTH'(0))
) MMR_CDbgNode2Eap3_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode2Eap3_F_DestNode_WrEn),
    .in    (MMR_CDbgNode2Eap3_F_DestNode_Data),
    .out   (MMR_CDbgNode2Eap3_F_DestNode)
);

logic                                           MMR_CDbgNode3Eap2_F_Action3_WrEn;
logic [CLA_CDBGNODE3EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action3_Data;
logic [CLA_CDBGNODE3EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action3_DataEff;
logic [CLA_CDBGNODE3EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action3_Data_muxed;
logic [CLA_CDBGNODE3EAP2_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action3_Data_prev;
assign MMR_CDbgNode3Eap2_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode3Eap2_F_Action3_Data = (CLA_CDBGNODE3EAP2_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_Action3), 64'(MMR_CDbgNode3Eap2_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_Action3_Data_prev = MMR_CDbgNode3Eap2_F_Action3;
assign MMR_CDbgNode3Eap2_F_Action3_Data_muxed = MMR_CDbgNode3Eap2_F_Action3_WrEn ? MMR_CDbgNode3Eap2_F_Action3_Data : MMR_CDbgNode3Eap2_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_ACTION3_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_Action3_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_Action3_Data),
    .out   (MMR_CDbgNode3Eap2_F_Action3)
);

logic                                           MMR_CDbgNode3Eap2_F_Action2_WrEn;
logic [CLA_CDBGNODE3EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action2_Data;
logic [CLA_CDBGNODE3EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action2_DataEff;
logic [CLA_CDBGNODE3EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action2_Data_muxed;
logic [CLA_CDBGNODE3EAP2_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action2_Data_prev;
assign MMR_CDbgNode3Eap2_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode3Eap2_F_Action2_Data = (CLA_CDBGNODE3EAP2_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_Action2), 64'(MMR_CDbgNode3Eap2_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_Action2_Data_prev = MMR_CDbgNode3Eap2_F_Action2;
assign MMR_CDbgNode3Eap2_F_Action2_Data_muxed = MMR_CDbgNode3Eap2_F_Action2_WrEn ? MMR_CDbgNode3Eap2_F_Action2_Data : MMR_CDbgNode3Eap2_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_ACTION2_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_Action2_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_Action2_Data),
    .out   (MMR_CDbgNode3Eap2_F_Action2)
);

logic                                           MMR_CDbgNode3Eap2_F_Udf_WrEn;
logic [CLA_CDBGNODE3EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap2_F_Udf_Data;
logic [CLA_CDBGNODE3EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap2_F_Udf_DataEff;
logic [CLA_CDBGNODE3EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap2_F_Udf_Data_muxed;
logic [CLA_CDBGNODE3EAP2_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap2_F_Udf_Data_prev;
assign MMR_CDbgNode3Eap2_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode3Eap2_F_Udf_Data = (CLA_CDBGNODE3EAP2_UDF_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_Udf), 64'(MMR_CDbgNode3Eap2_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_Udf_Data_prev = MMR_CDbgNode3Eap2_F_Udf;
assign MMR_CDbgNode3Eap2_F_Udf_Data_muxed = MMR_CDbgNode3Eap2_F_Udf_WrEn ? MMR_CDbgNode3Eap2_F_Udf_Data : MMR_CDbgNode3Eap2_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_UDF_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_Udf_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_Udf_Data),
    .out   (MMR_CDbgNode3Eap2_F_Udf)
);

logic                                           MMR_CDbgNode3Eap2_F_EventType2_WrEn;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType2_Data;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType2_DataEff;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType2_Data_prev;
assign MMR_CDbgNode3Eap2_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode3Eap2_F_EventType2_Data = (CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_EventType2), 64'(MMR_CDbgNode3Eap2_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_EventType2_Data_prev = MMR_CDbgNode3Eap2_F_EventType2;
assign MMR_CDbgNode3Eap2_F_EventType2_Data_muxed = MMR_CDbgNode3Eap2_F_EventType2_WrEn ? MMR_CDbgNode3Eap2_F_EventType2_Data : MMR_CDbgNode3Eap2_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_EventType2_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_EventType2_Data),
    .out   (MMR_CDbgNode3Eap2_F_EventType2)
);

logic                                           MMR_CDbgNode3Eap2_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode3Eap2_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data = (CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_CustomAction1Enable), 64'(MMR_CDbgNode3Eap2_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_prev = MMR_CDbgNode3Eap2_F_CustomAction1Enable;
assign MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode3Eap2_F_CustomAction1Enable_WrEn ? MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data : MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode3Eap2_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode3Eap2_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode3Eap2_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data = (CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_CustomAction0Enable), 64'(MMR_CDbgNode3Eap2_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_prev = MMR_CDbgNode3Eap2_F_CustomAction0Enable;
assign MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode3Eap2_F_CustomAction0Enable_WrEn ? MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data : MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode3Eap2_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode3Eap2_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1_Data;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction1_Data_prev;
assign MMR_CDbgNode3Eap2_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode3Eap2_F_CustomAction1_Data = (CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_CustomAction1), 64'(MMR_CDbgNode3Eap2_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_CustomAction1_Data_prev = MMR_CDbgNode3Eap2_F_CustomAction1;
assign MMR_CDbgNode3Eap2_F_CustomAction1_Data_muxed = MMR_CDbgNode3Eap2_F_CustomAction1_WrEn ? MMR_CDbgNode3Eap2_F_CustomAction1_Data : MMR_CDbgNode3Eap2_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_CustomAction1_Data),
    .out   (MMR_CDbgNode3Eap2_F_CustomAction1)
);

logic                                           MMR_CDbgNode3Eap2_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0_Data;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap2_F_CustomAction0_Data_prev;
assign MMR_CDbgNode3Eap2_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode3Eap2_F_CustomAction0_Data = (CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_CustomAction0), 64'(MMR_CDbgNode3Eap2_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_CustomAction0_Data_prev = MMR_CDbgNode3Eap2_F_CustomAction0;
assign MMR_CDbgNode3Eap2_F_CustomAction0_Data_muxed = MMR_CDbgNode3Eap2_F_CustomAction0_WrEn ? MMR_CDbgNode3Eap2_F_CustomAction0_Data : MMR_CDbgNode3Eap2_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_CustomAction0_Data),
    .out   (MMR_CDbgNode3Eap2_F_CustomAction0)
);

logic                                           MMR_CDbgNode3Eap2_F_EventType1_WrEn;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType1_Data;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType1_DataEff;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType1_Data_prev;
assign MMR_CDbgNode3Eap2_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode3Eap2_F_EventType1_Data = (CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_EventType1), 64'(MMR_CDbgNode3Eap2_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_EventType1_Data_prev = MMR_CDbgNode3Eap2_F_EventType1;
assign MMR_CDbgNode3Eap2_F_EventType1_Data_muxed = MMR_CDbgNode3Eap2_F_EventType1_WrEn ? MMR_CDbgNode3Eap2_F_EventType1_Data : MMR_CDbgNode3Eap2_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_EventType1_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_EventType1_Data),
    .out   (MMR_CDbgNode3Eap2_F_EventType1)
);

logic                                           MMR_CDbgNode3Eap2_F_EventType0_WrEn;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType0_Data;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType0_DataEff;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap2_F_EventType0_Data_prev;
assign MMR_CDbgNode3Eap2_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode3Eap2_F_EventType0_Data = (CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_EventType0), 64'(MMR_CDbgNode3Eap2_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_EventType0_Data_prev = MMR_CDbgNode3Eap2_F_EventType0;
assign MMR_CDbgNode3Eap2_F_EventType0_Data_muxed = MMR_CDbgNode3Eap2_F_EventType0_WrEn ? MMR_CDbgNode3Eap2_F_EventType0_Data : MMR_CDbgNode3Eap2_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_EventType0_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_EventType0_Data),
    .out   (MMR_CDbgNode3Eap2_F_EventType0)
);

logic                                           MMR_CDbgNode3Eap2_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap2_F_LogicalOp_Data;
logic [CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap2_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap2_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap2_F_LogicalOp_Data_prev;
assign MMR_CDbgNode3Eap2_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode3Eap2_F_LogicalOp_Data = (CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_LogicalOp), 64'(MMR_CDbgNode3Eap2_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_LogicalOp_Data_prev = MMR_CDbgNode3Eap2_F_LogicalOp;
assign MMR_CDbgNode3Eap2_F_LogicalOp_Data_muxed = MMR_CDbgNode3Eap2_F_LogicalOp_WrEn ? MMR_CDbgNode3Eap2_F_LogicalOp_Data : MMR_CDbgNode3Eap2_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_LogicalOp_Data),
    .out   (MMR_CDbgNode3Eap2_F_LogicalOp)
);

logic                                           MMR_CDbgNode3Eap2_F_Action1_WrEn;
logic [CLA_CDBGNODE3EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action1_Data;
logic [CLA_CDBGNODE3EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action1_DataEff;
logic [CLA_CDBGNODE3EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action1_Data_muxed;
logic [CLA_CDBGNODE3EAP2_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action1_Data_prev;
assign MMR_CDbgNode3Eap2_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode3Eap2_F_Action1_Data = (CLA_CDBGNODE3EAP2_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_Action1), 64'(MMR_CDbgNode3Eap2_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_Action1_Data_prev = MMR_CDbgNode3Eap2_F_Action1;
assign MMR_CDbgNode3Eap2_F_Action1_Data_muxed = MMR_CDbgNode3Eap2_F_Action1_WrEn ? MMR_CDbgNode3Eap2_F_Action1_Data : MMR_CDbgNode3Eap2_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_ACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_Action1_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_Action1_Data),
    .out   (MMR_CDbgNode3Eap2_F_Action1)
);

logic                                           MMR_CDbgNode3Eap2_F_Action0_WrEn;
logic [CLA_CDBGNODE3EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action0_Data;
logic [CLA_CDBGNODE3EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action0_DataEff;
logic [CLA_CDBGNODE3EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action0_Data_muxed;
logic [CLA_CDBGNODE3EAP2_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap2_F_Action0_Data_prev;
assign MMR_CDbgNode3Eap2_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode3Eap2_F_Action0_Data = (CLA_CDBGNODE3EAP2_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_Action0), 64'(MMR_CDbgNode3Eap2_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_Action0_Data_prev = MMR_CDbgNode3Eap2_F_Action0;
assign MMR_CDbgNode3Eap2_F_Action0_Data_muxed = MMR_CDbgNode3Eap2_F_Action0_WrEn ? MMR_CDbgNode3Eap2_F_Action0_Data : MMR_CDbgNode3Eap2_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_ACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_Action0_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_Action0_Data),
    .out   (MMR_CDbgNode3Eap2_F_Action0)
);

logic                                           MMR_CDbgNode3Eap2_F_DestNode_WrEn;
logic [CLA_CDBGNODE3EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap2_F_DestNode_Data;
logic [CLA_CDBGNODE3EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap2_F_DestNode_DataEff;
logic [CLA_CDBGNODE3EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap2_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE3EAP2_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap2_F_DestNode_Data_prev;
assign MMR_CDbgNode3Eap2_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode3Eap2_F_DestNode_Data = (CLA_CDBGNODE3EAP2_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap2_F_DestNode), 64'(MMR_CDbgNode3Eap2_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap2_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP2))));
assign MMR_CDbgNode3Eap2_F_DestNode_Data_prev = MMR_CDbgNode3Eap2_F_DestNode;
assign MMR_CDbgNode3Eap2_F_DestNode_Data_muxed = MMR_CDbgNode3Eap2_F_DestNode_WrEn ? MMR_CDbgNode3Eap2_F_DestNode_Data : MMR_CDbgNode3Eap2_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP2_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP2_DESTNODE_WIDTH'(0))
) MMR_CDbgNode3Eap2_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap2_F_DestNode_WrEn),
    .in    (MMR_CDbgNode3Eap2_F_DestNode_Data),
    .out   (MMR_CDbgNode3Eap2_F_DestNode)
);

logic                                           MMR_CDbgNode3Eap3_F_Action3_WrEn;
logic [CLA_CDBGNODE3EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action3_Data;
logic [CLA_CDBGNODE3EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action3_DataEff;
logic [CLA_CDBGNODE3EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action3_Data_muxed;
logic [CLA_CDBGNODE3EAP3_ACTION3_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action3_Data_prev;
assign MMR_CDbgNode3Eap3_F_Action3_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgNode3Eap3_F_Action3_Data = (CLA_CDBGNODE3EAP3_ACTION3_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_Action3), 64'(MMR_CDbgNode3Eap3_F_Action3_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_Action3_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_Action3_Data_prev = MMR_CDbgNode3Eap3_F_Action3;
assign MMR_CDbgNode3Eap3_F_Action3_Data_muxed = MMR_CDbgNode3Eap3_F_Action3_WrEn ? MMR_CDbgNode3Eap3_F_Action3_Data : MMR_CDbgNode3Eap3_F_Action3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_ACTION3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_ACTION3_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_Action3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_Action3_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_Action3_Data),
    .out   (MMR_CDbgNode3Eap3_F_Action3)
);

logic                                           MMR_CDbgNode3Eap3_F_Action2_WrEn;
logic [CLA_CDBGNODE3EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action2_Data;
logic [CLA_CDBGNODE3EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action2_DataEff;
logic [CLA_CDBGNODE3EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action2_Data_muxed;
logic [CLA_CDBGNODE3EAP3_ACTION2_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action2_Data_prev;
assign MMR_CDbgNode3Eap3_F_Action2_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgNode3Eap3_F_Action2_Data = (CLA_CDBGNODE3EAP3_ACTION2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_Action2), 64'(MMR_CDbgNode3Eap3_F_Action2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_Action2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_Action2_Data_prev = MMR_CDbgNode3Eap3_F_Action2;
assign MMR_CDbgNode3Eap3_F_Action2_Data_muxed = MMR_CDbgNode3Eap3_F_Action2_WrEn ? MMR_CDbgNode3Eap3_F_Action2_Data : MMR_CDbgNode3Eap3_F_Action2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_ACTION2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_ACTION2_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_Action2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_Action2_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_Action2_Data),
    .out   (MMR_CDbgNode3Eap3_F_Action2)
);

logic                                           MMR_CDbgNode3Eap3_F_Udf_WrEn;
logic [CLA_CDBGNODE3EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap3_F_Udf_Data;
logic [CLA_CDBGNODE3EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap3_F_Udf_DataEff;
logic [CLA_CDBGNODE3EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap3_F_Udf_Data_muxed;
logic [CLA_CDBGNODE3EAP3_UDF_WIDTH        -1:0] MMR_CDbgNode3Eap3_F_Udf_Data_prev;
assign MMR_CDbgNode3Eap3_F_Udf_DataEff = {reg_wr_data[51:44]};
assign MMR_CDbgNode3Eap3_F_Udf_Data = (CLA_CDBGNODE3EAP3_UDF_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_Udf), 64'(MMR_CDbgNode3Eap3_F_Udf_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_Udf_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_Udf_Data_prev = MMR_CDbgNode3Eap3_F_Udf;
assign MMR_CDbgNode3Eap3_F_Udf_Data_muxed = MMR_CDbgNode3Eap3_F_Udf_WrEn ? MMR_CDbgNode3Eap3_F_Udf_Data : MMR_CDbgNode3Eap3_F_Udf_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_UDF_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_UDF_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_Udf_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_Udf_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_Udf_Data),
    .out   (MMR_CDbgNode3Eap3_F_Udf)
);

logic                                           MMR_CDbgNode3Eap3_F_EventType2_WrEn;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType2_Data;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType2_DataEff;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType2_Data_muxed;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType2_Data_prev;
assign MMR_CDbgNode3Eap3_F_EventType2_DataEff = {reg_wr_data[43:38]};
assign MMR_CDbgNode3Eap3_F_EventType2_Data = (CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_EventType2), 64'(MMR_CDbgNode3Eap3_F_EventType2_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_EventType2_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_EventType2_Data_prev = MMR_CDbgNode3Eap3_F_EventType2;
assign MMR_CDbgNode3Eap3_F_EventType2_Data_muxed = MMR_CDbgNode3Eap3_F_EventType2_WrEn ? MMR_CDbgNode3Eap3_F_EventType2_Data : MMR_CDbgNode3Eap3_F_EventType2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_EVENTTYPE2_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_EventType2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_EventType2_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_EventType2_Data),
    .out   (MMR_CDbgNode3Eap3_F_EventType2)
);

logic                                           MMR_CDbgNode3Eap3_F_CustomAction1Enable_WrEn;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1Enable_DataEff;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_prev;
assign MMR_CDbgNode3Eap3_F_CustomAction1Enable_DataEff = {reg_wr_data[37:37]};
assign MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data = (CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_CustomAction1Enable), 64'(MMR_CDbgNode3Eap3_F_CustomAction1Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_CustomAction1Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_prev = MMR_CDbgNode3Eap3_F_CustomAction1Enable;
assign MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_muxed = MMR_CDbgNode3Eap3_F_CustomAction1Enable_WrEn ? MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data : MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_CUSTOMACTION1ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_CustomAction1Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_CustomAction1Enable_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data),
    .out   (MMR_CDbgNode3Eap3_F_CustomAction1Enable)
);

logic                                           MMR_CDbgNode3Eap3_F_CustomAction0Enable_WrEn;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0Enable_DataEff;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_muxed;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_prev;
assign MMR_CDbgNode3Eap3_F_CustomAction0Enable_DataEff = {reg_wr_data[36:36]};
assign MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data = (CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_CustomAction0Enable), 64'(MMR_CDbgNode3Eap3_F_CustomAction0Enable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_CustomAction0Enable_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_prev = MMR_CDbgNode3Eap3_F_CustomAction0Enable;
assign MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_muxed = MMR_CDbgNode3Eap3_F_CustomAction0Enable_WrEn ? MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data : MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_CUSTOMACTION0ENABLE_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_CustomAction0Enable_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_CustomAction0Enable_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data),
    .out   (MMR_CDbgNode3Eap3_F_CustomAction0Enable)
);

logic                                           MMR_CDbgNode3Eap3_F_CustomAction1_WrEn;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1_Data;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1_DataEff;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1_Data_muxed;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction1_Data_prev;
assign MMR_CDbgNode3Eap3_F_CustomAction1_DataEff = {reg_wr_data[35:32]};
assign MMR_CDbgNode3Eap3_F_CustomAction1_Data = (CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_CustomAction1), 64'(MMR_CDbgNode3Eap3_F_CustomAction1_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_CustomAction1_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_CustomAction1_Data_prev = MMR_CDbgNode3Eap3_F_CustomAction1;
assign MMR_CDbgNode3Eap3_F_CustomAction1_Data_muxed = MMR_CDbgNode3Eap3_F_CustomAction1_WrEn ? MMR_CDbgNode3Eap3_F_CustomAction1_Data : MMR_CDbgNode3Eap3_F_CustomAction1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_CUSTOMACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_CustomAction1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_CustomAction1_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_CustomAction1_Data),
    .out   (MMR_CDbgNode3Eap3_F_CustomAction1)
);

logic                                           MMR_CDbgNode3Eap3_F_CustomAction0_WrEn;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0_Data;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0_DataEff;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0_Data_muxed;
logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH-1:0] MMR_CDbgNode3Eap3_F_CustomAction0_Data_prev;
assign MMR_CDbgNode3Eap3_F_CustomAction0_DataEff = {reg_wr_data[31:28]};
assign MMR_CDbgNode3Eap3_F_CustomAction0_Data = (CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_CustomAction0), 64'(MMR_CDbgNode3Eap3_F_CustomAction0_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_CustomAction0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_CustomAction0_Data_prev = MMR_CDbgNode3Eap3_F_CustomAction0;
assign MMR_CDbgNode3Eap3_F_CustomAction0_Data_muxed = MMR_CDbgNode3Eap3_F_CustomAction0_WrEn ? MMR_CDbgNode3Eap3_F_CustomAction0_Data : MMR_CDbgNode3Eap3_F_CustomAction0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_CUSTOMACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_CustomAction0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_CustomAction0_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_CustomAction0_Data),
    .out   (MMR_CDbgNode3Eap3_F_CustomAction0)
);

logic                                           MMR_CDbgNode3Eap3_F_EventType1_WrEn;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType1_Data;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType1_DataEff;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType1_Data_muxed;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType1_Data_prev;
assign MMR_CDbgNode3Eap3_F_EventType1_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgNode3Eap3_F_EventType1_Data = (CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_EventType1), 64'(MMR_CDbgNode3Eap3_F_EventType1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_EventType1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_EventType1_Data_prev = MMR_CDbgNode3Eap3_F_EventType1;
assign MMR_CDbgNode3Eap3_F_EventType1_Data_muxed = MMR_CDbgNode3Eap3_F_EventType1_WrEn ? MMR_CDbgNode3Eap3_F_EventType1_Data : MMR_CDbgNode3Eap3_F_EventType1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_EVENTTYPE1_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_EventType1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_EventType1_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_EventType1_Data),
    .out   (MMR_CDbgNode3Eap3_F_EventType1)
);

logic                                           MMR_CDbgNode3Eap3_F_EventType0_WrEn;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType0_Data;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType0_DataEff;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType0_Data_muxed;
logic [CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH -1:0] MMR_CDbgNode3Eap3_F_EventType0_Data_prev;
assign MMR_CDbgNode3Eap3_F_EventType0_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgNode3Eap3_F_EventType0_Data = (CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_EventType0), 64'(MMR_CDbgNode3Eap3_F_EventType0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_EventType0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_EventType0_Data_prev = MMR_CDbgNode3Eap3_F_EventType0;
assign MMR_CDbgNode3Eap3_F_EventType0_Data_muxed = MMR_CDbgNode3Eap3_F_EventType0_WrEn ? MMR_CDbgNode3Eap3_F_EventType0_Data : MMR_CDbgNode3Eap3_F_EventType0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_EVENTTYPE0_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_EventType0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_EventType0_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_EventType0_Data),
    .out   (MMR_CDbgNode3Eap3_F_EventType0)
);

logic                                           MMR_CDbgNode3Eap3_F_LogicalOp_WrEn;
logic [CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap3_F_LogicalOp_Data;
logic [CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap3_F_LogicalOp_DataEff;
logic [CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap3_F_LogicalOp_Data_muxed;
logic [CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH  -1:0] MMR_CDbgNode3Eap3_F_LogicalOp_Data_prev;
assign MMR_CDbgNode3Eap3_F_LogicalOp_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgNode3Eap3_F_LogicalOp_Data = (CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_LogicalOp), 64'(MMR_CDbgNode3Eap3_F_LogicalOp_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_LogicalOp_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_LogicalOp_Data_prev = MMR_CDbgNode3Eap3_F_LogicalOp;
assign MMR_CDbgNode3Eap3_F_LogicalOp_Data_muxed = MMR_CDbgNode3Eap3_F_LogicalOp_WrEn ? MMR_CDbgNode3Eap3_F_LogicalOp_Data : MMR_CDbgNode3Eap3_F_LogicalOp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_LOGICALOP_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_LogicalOp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_LogicalOp_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_LogicalOp_Data),
    .out   (MMR_CDbgNode3Eap3_F_LogicalOp)
);

logic                                           MMR_CDbgNode3Eap3_F_Action1_WrEn;
logic [CLA_CDBGNODE3EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action1_Data;
logic [CLA_CDBGNODE3EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action1_DataEff;
logic [CLA_CDBGNODE3EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action1_Data_muxed;
logic [CLA_CDBGNODE3EAP3_ACTION1_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action1_Data_prev;
assign MMR_CDbgNode3Eap3_F_Action1_DataEff = {reg_wr_data[13:8]};
assign MMR_CDbgNode3Eap3_F_Action1_Data = (CLA_CDBGNODE3EAP3_ACTION1_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_Action1), 64'(MMR_CDbgNode3Eap3_F_Action1_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_Action1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_Action1_Data_prev = MMR_CDbgNode3Eap3_F_Action1;
assign MMR_CDbgNode3Eap3_F_Action1_Data_muxed = MMR_CDbgNode3Eap3_F_Action1_WrEn ? MMR_CDbgNode3Eap3_F_Action1_Data : MMR_CDbgNode3Eap3_F_Action1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_ACTION1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_ACTION1_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_Action1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_Action1_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_Action1_Data),
    .out   (MMR_CDbgNode3Eap3_F_Action1)
);

logic                                           MMR_CDbgNode3Eap3_F_Action0_WrEn;
logic [CLA_CDBGNODE3EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action0_Data;
logic [CLA_CDBGNODE3EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action0_DataEff;
logic [CLA_CDBGNODE3EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action0_Data_muxed;
logic [CLA_CDBGNODE3EAP3_ACTION0_WIDTH    -1:0] MMR_CDbgNode3Eap3_F_Action0_Data_prev;
assign MMR_CDbgNode3Eap3_F_Action0_DataEff = {reg_wr_data[7:2]};
assign MMR_CDbgNode3Eap3_F_Action0_Data = (CLA_CDBGNODE3EAP3_ACTION0_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_Action0), 64'(MMR_CDbgNode3Eap3_F_Action0_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_Action0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_Action0_Data_prev = MMR_CDbgNode3Eap3_F_Action0;
assign MMR_CDbgNode3Eap3_F_Action0_Data_muxed = MMR_CDbgNode3Eap3_F_Action0_WrEn ? MMR_CDbgNode3Eap3_F_Action0_Data : MMR_CDbgNode3Eap3_F_Action0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_ACTION0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_ACTION0_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_Action0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_Action0_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_Action0_Data),
    .out   (MMR_CDbgNode3Eap3_F_Action0)
);

logic                                           MMR_CDbgNode3Eap3_F_DestNode_WrEn;
logic [CLA_CDBGNODE3EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap3_F_DestNode_Data;
logic [CLA_CDBGNODE3EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap3_F_DestNode_DataEff;
logic [CLA_CDBGNODE3EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap3_F_DestNode_Data_muxed;
logic [CLA_CDBGNODE3EAP3_DESTNODE_WIDTH   -1:0] MMR_CDbgNode3Eap3_F_DestNode_Data_prev;
assign MMR_CDbgNode3Eap3_F_DestNode_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgNode3Eap3_F_DestNode_Data = (CLA_CDBGNODE3EAP3_DESTNODE_WIDTH'(update_value(64'(MMR_CDbgNode3Eap3_F_DestNode), 64'(MMR_CDbgNode3Eap3_F_DestNode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgNode3Eap3_F_DestNode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNODE3EAP3))));
assign MMR_CDbgNode3Eap3_F_DestNode_Data_prev = MMR_CDbgNode3Eap3_F_DestNode;
assign MMR_CDbgNode3Eap3_F_DestNode_Data_muxed = MMR_CDbgNode3Eap3_F_DestNode_WrEn ? MMR_CDbgNode3Eap3_F_DestNode_Data : MMR_CDbgNode3Eap3_F_DestNode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGNODE3EAP3_DESTNODE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGNODE3EAP3_DESTNODE_WIDTH'(0))
) MMR_CDbgNode3Eap3_F_DestNode_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgNode3Eap3_F_DestNode_WrEn),
    .in    (MMR_CDbgNode3Eap3_F_DestNode_Data),
    .out   (MMR_CDbgNode3Eap3_F_DestNode)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap2LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap2LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap3LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap3LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap2LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap2LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap3LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap3LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap2LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap2LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap3LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap3LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap2LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap2LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP2LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap3LoWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap3LoWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP3LO_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Rsvd_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Rsvd_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Rsvd_DataEff = {reg_wr_data[63:32]};
assign MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data = (CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Rsvd), 64'(MMR_CDbgSignalDelayMuxSel_F_Rsvd_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Rsvd_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Rsvd;
assign MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Rsvd_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data : MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_RSVD_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Rsvd_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Rsvd_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Rsvd)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_DataEff = {reg_wr_data[31:30]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg15), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg15;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG15_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg15)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_DataEff = {reg_wr_data[29:28]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg14), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg14;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG14_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg14)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_DataEff = {reg_wr_data[27:26]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg13), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg13;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG13_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg13)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_DataEff = {reg_wr_data[25:24]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg12), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg12;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG12_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg12)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_DataEff = {reg_wr_data[23:22]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg11), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg11;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG11_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg11)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_DataEff = {reg_wr_data[21:20]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg10), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg10;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG10_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg10)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_DataEff = {reg_wr_data[19:18]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg9), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg9;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG9_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg9)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_DataEff = {reg_wr_data[17:16]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg8), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg8;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG8_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg8)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_DataEff = {reg_wr_data[15:14]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg7), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg7;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG7_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg7)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_DataEff = {reg_wr_data[13:12]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg6), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg6;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG6_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg6)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_DataEff = {reg_wr_data[11:10]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg5), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg5;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG5_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg5)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_DataEff = {reg_wr_data[9:8]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg4), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg4;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG4_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg4)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_DataEff = {reg_wr_data[7:6]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg3), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg3;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG3_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg3)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_DataEff = {reg_wr_data[5:4]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg2), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg2;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG2_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg2)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_DataEff = {reg_wr_data[3:2]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg1), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg1;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG1_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg1)
);

logic                                           MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_WrEn;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_DataEff;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_muxed;
logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH-1:0] MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_prev;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_DataEff = {reg_wr_data[1:0]};
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data = (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH'(update_value(64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg0), 64'(MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGSIGNALDELAYMUXSEL))));
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_prev = MMR_CDbgSignalDelayMuxSel_F_Muxselseg0;
assign MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_muxed = MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_WrEn ? MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data : MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALDELAYMUXSEL_MUXSELSEG0_WIDTH'(0))
) MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_WrEn),
    .in    (MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data),
    .out   (MMR_CDbgSignalDelayMuxSel_F_Muxselseg0)
);

logic                                           MMR_CDbgClaXtriggerTimestretch_F_Rsvd_WrEn;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Rsvd_DataEff;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_muxed;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_prev;
assign MMR_CDbgClaXtriggerTimestretch_F_Rsvd_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgClaXtriggerTimestretch_F_Rsvd[47:16] , reg_wr_strb[0] ? reg_wr_data[31:16] : MMR_CDbgClaXtriggerTimestretch_F_Rsvd[15:0]};
assign MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data = (CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH'(update_value(64'(MMR_CDbgClaXtriggerTimestretch_F_Rsvd), 64'(MMR_CDbgClaXtriggerTimestretch_F_Rsvd_DataEff[47:0]), reg_wr_instr_type)));
assign MMR_CDbgClaXtriggerTimestretch_F_Rsvd_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH))));
assign MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_prev = MMR_CDbgClaXtriggerTimestretch_F_Rsvd;
assign MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_muxed = MMR_CDbgClaXtriggerTimestretch_F_Rsvd_WrEn ? MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data : MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLAXTRIGGERTIMESTRETCH_RSVD_WIDTH'(0))
) MMR_CDbgClaXtriggerTimestretch_F_Rsvd_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaXtriggerTimestretch_F_Rsvd_WrEn),
    .in    (MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data),
    .out   (MMR_CDbgClaXtriggerTimestretch_F_Rsvd)
);

logic                                           MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_WrEn;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_DataEff;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_muxed;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_prev;
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_DataEff = {reg_wr_data[15:8]};
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data = (CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH'(update_value(64'(MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch), 64'(MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH))));
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_prev = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch;
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_muxed = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_WrEn ? MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data : MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER1STRETCH_WIDTH'(0))
) MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_WrEn),
    .in    (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data),
    .out   (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch)
);

logic                                           MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_WrEn;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_DataEff;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_muxed;
logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH-1:0] MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_prev;
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_DataEff = {reg_wr_data[7:0]};
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data = (CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH'(update_value(64'(MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch), 64'(MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH))));
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_prev = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch;
assign MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_muxed = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_WrEn ? MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data : MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLAXTRIGGERTIMESTRETCH_XTRIGGER0STRETCH_WIDTH'(0))
) MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_WrEn),
    .in    (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data),
    .out   (MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch)
);

logic                                           MMR_CDbgClaTimestamp_F_TimestampUpper_WrEn;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampUpper_Data;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampUpper_DataEff;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampUpper_Data_muxed;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampUpper_Data_prev;
assign MMR_CDbgClaTimestamp_F_TimestampUpper_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgClaTimestamp_F_TimestampUpper[55:24] , reg_wr_strb[0] ? reg_wr_data[31:8] : MMR_CDbgClaTimestamp_F_TimestampUpper[23:0]};
assign MMR_CDbgClaTimestamp_F_TimestampUpper_Data = ((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMP)) ? CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH'(update_value(64'(MMR_CDbgClaTimestamp_F_TimestampUpper), 64'(MMR_CDbgClaTimestamp_F_TimestampUpper_DataEff[55:0]), reg_wr_instr_type)) : ClaMmrCdbgclatimestampWr.Data.TimestampUpper);
assign MMR_CDbgClaTimestamp_F_TimestampUpper_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMP)) | ClaMmrCdbgclatimestampWr.TimestampUpperWrEn));
assign MMR_CDbgClaTimestamp_F_TimestampUpper_Data_prev = MMR_CDbgClaTimestamp_F_TimestampUpper;
assign MMR_CDbgClaTimestamp_F_TimestampUpper_Data_muxed = MMR_CDbgClaTimestamp_F_TimestampUpper_WrEn ? MMR_CDbgClaTimestamp_F_TimestampUpper_Data : MMR_CDbgClaTimestamp_F_TimestampUpper_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMP_TIMESTAMPUPPER_WIDTH'(0))
) MMR_CDbgClaTimestamp_F_TimestampUpper_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestamp_F_TimestampUpper_WrEn),
    .in    (MMR_CDbgClaTimestamp_F_TimestampUpper_Data),
    .out   (MMR_CDbgClaTimestamp_F_TimestampUpper)
);

logic                                           MMR_CDbgClaTimestamp_F_TimestampLower_WrEn;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampLower_Data;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampLower_DataEff;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampLower_Data_muxed;
logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH-1:0] MMR_CDbgClaTimestamp_F_TimestampLower_Data_prev;
assign MMR_CDbgClaTimestamp_F_TimestampLower_DataEff = {reg_wr_data[7:0]};
assign MMR_CDbgClaTimestamp_F_TimestampLower_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMP)) ? CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH'(update_value(64'(MMR_CDbgClaTimestamp_F_TimestampLower), 64'(MMR_CDbgClaTimestamp_F_TimestampLower_DataEff[7:0]), reg_wr_instr_type)) : ClaMmrCdbgclatimestampWr.Data.TimestampLower);
assign MMR_CDbgClaTimestamp_F_TimestampLower_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMP)) | ClaMmrCdbgclatimestampWr.TimestampLowerWrEn));
assign MMR_CDbgClaTimestamp_F_TimestampLower_Data_prev = MMR_CDbgClaTimestamp_F_TimestampLower;
assign MMR_CDbgClaTimestamp_F_TimestampLower_Data_muxed = MMR_CDbgClaTimestamp_F_TimestampLower_WrEn ? MMR_CDbgClaTimestamp_F_TimestampLower_Data : MMR_CDbgClaTimestamp_F_TimestampLower_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMP_TIMESTAMPLOWER_WIDTH'(0))
) MMR_CDbgClaTimestamp_F_TimestampLower_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestamp_F_TimestampLower_WrEn),
    .in    (MMR_CDbgClaTimestamp_F_TimestampLower_Data),
    .out   (MMR_CDbgClaTimestamp_F_TimestampLower)
);

logic                                           MMR_CDbgClaTimestampSync_F_TimestampSync_WrEn;
logic [CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH-1:0] MMR_CDbgClaTimestampSync_F_TimestampSync_Data;
logic [CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH-1:0] MMR_CDbgClaTimestampSync_F_TimestampSync_DataEff;
logic [CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH-1:0] MMR_CDbgClaTimestampSync_F_TimestampSync_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH-1:0] MMR_CDbgClaTimestampSync_F_TimestampSync_Data_prev;
assign MMR_CDbgClaTimestampSync_F_TimestampSync_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgClaTimestampSync_F_TimestampSync[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgClaTimestampSync_F_TimestampSync[31:0]};
assign MMR_CDbgClaTimestampSync_F_TimestampSync_Data = (CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH'(update_value(64'(MMR_CDbgClaTimestampSync_F_TimestampSync), 64'(MMR_CDbgClaTimestampSync_F_TimestampSync_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimestampSync_F_TimestampSync_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPSYNC))));
assign MMR_CDbgClaTimestampSync_F_TimestampSync_Data_prev = MMR_CDbgClaTimestampSync_F_TimestampSync;
assign MMR_CDbgClaTimestampSync_F_TimestampSync_Data_muxed = MMR_CDbgClaTimestampSync_F_TimestampSync_WrEn ? MMR_CDbgClaTimestampSync_F_TimestampSync_Data : MMR_CDbgClaTimestampSync_F_TimestampSync_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPSYNC_TIMESTAMPSYNC_WIDTH'(0))
) MMR_CDbgClaTimestampSync_F_TimestampSync_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampSync_F_TimestampSync_WrEn),
    .in    (MMR_CDbgClaTimestampSync_F_TimestampSync_Data),
    .out   (MMR_CDbgClaTimestampSync_F_TimestampSync)
);

logic                                           MMR_CDbgClaTimestampConfig_F_Rsvd1_WrEn;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Rsvd1_Data;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Rsvd1_DataEff;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_prev;
assign MMR_CDbgClaTimestampConfig_F_Rsvd1_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgClaTimestampConfig_F_Rsvd1[53:22] , reg_wr_strb[0] ? reg_wr_data[31:10] : MMR_CDbgClaTimestampConfig_F_Rsvd1[21:0]};
assign MMR_CDbgClaTimestampConfig_F_Rsvd1_Data = (CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH'(update_value(64'(MMR_CDbgClaTimestampConfig_F_Rsvd1), 64'(MMR_CDbgClaTimestampConfig_F_Rsvd1_DataEff[53:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimestampConfig_F_Rsvd1_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG))));
assign MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_prev = MMR_CDbgClaTimestampConfig_F_Rsvd1;
assign MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_muxed = MMR_CDbgClaTimestampConfig_F_Rsvd1_WrEn ? MMR_CDbgClaTimestampConfig_F_Rsvd1_Data : MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPCONFIG_RSVD1_WIDTH'(0))
) MMR_CDbgClaTimestampConfig_F_Rsvd1_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampConfig_F_Rsvd1_WrEn),
    .in    (MMR_CDbgClaTimestampConfig_F_Rsvd1_Data),
    .out   (MMR_CDbgClaTimestampConfig_F_Rsvd1)
);

logic                                           MMR_CDbgClaTimestampConfig_F_TsCapture_WrEn;
logic [CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_TsCapture_Data;
logic [CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_TsCapture_DataEff;
logic [CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_TsCapture_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_TsCapture_Data_prev;
assign MMR_CDbgClaTimestampConfig_F_TsCapture_DataEff = {reg_wr_data[9:9]};
assign MMR_CDbgClaTimestampConfig_F_TsCapture_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG)) ? CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH'(update_value(64'(MMR_CDbgClaTimestampConfig_F_TsCapture), 64'(MMR_CDbgClaTimestampConfig_F_TsCapture_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgclatimestampconfigWr.Data.TsCapture);
assign MMR_CDbgClaTimestampConfig_F_TsCapture_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG)) | ClaMmrCdbgclatimestampconfigWr.TsCaptureWrEn));
assign MMR_CDbgClaTimestampConfig_F_TsCapture_Data_prev = MMR_CDbgClaTimestampConfig_F_TsCapture;
assign MMR_CDbgClaTimestampConfig_F_TsCapture_Data_muxed = MMR_CDbgClaTimestampConfig_F_TsCapture_WrEn ? MMR_CDbgClaTimestampConfig_F_TsCapture_Data : MMR_CDbgClaTimestampConfig_F_TsCapture_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPCONFIG_TSCAPTURE_WIDTH'(0))
) MMR_CDbgClaTimestampConfig_F_TsCapture_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampConfig_F_TsCapture_WrEn),
    .in    (MMR_CDbgClaTimestampConfig_F_TsCapture_Data),
    .out   (MMR_CDbgClaTimestampConfig_F_TsCapture)
);

logic                                           MMR_CDbgClaTimestampConfig_F_DebugMarker_WrEn;
logic [CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_DebugMarker_Data;
logic [CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_DebugMarker_DataEff;
logic [CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_prev;
assign MMR_CDbgClaTimestampConfig_F_DebugMarker_DataEff = {reg_wr_data[8:1]};
assign MMR_CDbgClaTimestampConfig_F_DebugMarker_Data = (CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH'(update_value(64'(MMR_CDbgClaTimestampConfig_F_DebugMarker), 64'(MMR_CDbgClaTimestampConfig_F_DebugMarker_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimestampConfig_F_DebugMarker_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG))));
assign MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_prev = MMR_CDbgClaTimestampConfig_F_DebugMarker;
assign MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_muxed = MMR_CDbgClaTimestampConfig_F_DebugMarker_WrEn ? MMR_CDbgClaTimestampConfig_F_DebugMarker_Data : MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPCONFIG_DEBUGMARKER_WIDTH'(0))
) MMR_CDbgClaTimestampConfig_F_DebugMarker_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampConfig_F_DebugMarker_WrEn),
    .in    (MMR_CDbgClaTimestampConfig_F_DebugMarker_Data),
    .out   (MMR_CDbgClaTimestampConfig_F_DebugMarker)
);

logic                                           MMR_CDbgClaTimestampConfig_F_Resync_WrEn;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Resync_Data;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Resync_DataEff;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Resync_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH-1:0] MMR_CDbgClaTimestampConfig_F_Resync_Data_prev;
assign MMR_CDbgClaTimestampConfig_F_Resync_DataEff = {reg_wr_data[0:0]};
assign MMR_CDbgClaTimestampConfig_F_Resync_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG)) ? CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH'(update_value(64'(MMR_CDbgClaTimestampConfig_F_Resync), 64'(MMR_CDbgClaTimestampConfig_F_Resync_DataEff[0:0]), reg_wr_instr_type)) : ClaMmrCdbgclatimestampconfigWr.Data.Resync);
assign MMR_CDbgClaTimestampConfig_F_Resync_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPCONFIG)) | ClaMmrCdbgclatimestampconfigWr.ResyncWrEn));
assign MMR_CDbgClaTimestampConfig_F_Resync_Data_prev = MMR_CDbgClaTimestampConfig_F_Resync;
assign MMR_CDbgClaTimestampConfig_F_Resync_Data_muxed = MMR_CDbgClaTimestampConfig_F_Resync_WrEn ? MMR_CDbgClaTimestampConfig_F_Resync_Data : MMR_CDbgClaTimestampConfig_F_Resync_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPCONFIG_RESYNC_WIDTH'(0))
) MMR_CDbgClaTimestampConfig_F_Resync_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampConfig_F_Resync_WrEn),
    .in    (MMR_CDbgClaTimestampConfig_F_Resync_Data),
    .out   (MMR_CDbgClaTimestampConfig_F_Resync)
);

logic                                           MMR_CDbgClaTimestampOffset_F_Rsvd0_WrEn;
logic [CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Rsvd0_Data;
logic [CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Rsvd0_DataEff;
logic [CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_prev;
assign MMR_CDbgClaTimestampOffset_F_Rsvd0_DataEff = {reg_wr_data[63:56]};
assign MMR_CDbgClaTimestampOffset_F_Rsvd0_Data = (CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH'(update_value(64'(MMR_CDbgClaTimestampOffset_F_Rsvd0), 64'(MMR_CDbgClaTimestampOffset_F_Rsvd0_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimestampOffset_F_Rsvd0_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPOFFSET))));
assign MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_prev = MMR_CDbgClaTimestampOffset_F_Rsvd0;
assign MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_muxed = MMR_CDbgClaTimestampOffset_F_Rsvd0_WrEn ? MMR_CDbgClaTimestampOffset_F_Rsvd0_Data : MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPOFFSET_RSVD0_WIDTH'(0))
) MMR_CDbgClaTimestampOffset_F_Rsvd0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampOffset_F_Rsvd0_WrEn),
    .in    (MMR_CDbgClaTimestampOffset_F_Rsvd0_Data),
    .out   (MMR_CDbgClaTimestampOffset_F_Rsvd0)
);

logic                                           MMR_CDbgClaTimestampOffset_F_Offset_WrEn;
logic [CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Offset_Data;
logic [CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Offset_DataEff;
logic [CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Offset_Data_muxed;
logic [CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH-1:0] MMR_CDbgClaTimestampOffset_F_Offset_Data_prev;
assign MMR_CDbgClaTimestampOffset_F_Offset_DataEff = {reg_wr_strb[1] ? reg_wr_data[55:32] : MMR_CDbgClaTimestampOffset_F_Offset[55:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgClaTimestampOffset_F_Offset[31:0]};
assign MMR_CDbgClaTimestampOffset_F_Offset_Data = (CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH'(update_value(64'(MMR_CDbgClaTimestampOffset_F_Offset), 64'(MMR_CDbgClaTimestampOffset_F_Offset_DataEff[55:0]), reg_wr_instr_type)));
assign MMR_CDbgClaTimestampOffset_F_Offset_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCLATIMESTAMPOFFSET))));
assign MMR_CDbgClaTimestampOffset_F_Offset_Data_prev = MMR_CDbgClaTimestampOffset_F_Offset;
assign MMR_CDbgClaTimestampOffset_F_Offset_Data_muxed = MMR_CDbgClaTimestampOffset_F_Offset_WrEn ? MMR_CDbgClaTimestampOffset_F_Offset_Data : MMR_CDbgClaTimestampOffset_F_Offset_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCLATIMESTAMPOFFSET_OFFSET_WIDTH'(0))
) MMR_CDbgClaTimestampOffset_F_Offset_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgClaTimestampOffset_F_Offset_WrEn),
    .in    (MMR_CDbgClaTimestampOffset_F_Offset_Data),
    .out   (MMR_CDbgClaTimestampOffset_F_Offset)
);

logic                                           MMR_CDbgSignalMask0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMask0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask0Hi_F_Value[31:0]};
assign MMR_CDbgSignalMask0Hi_F_Value_Data = (CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask0Hi_F_Value), 64'(MMR_CDbgSignalMask0Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask0Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK0HI))));
assign MMR_CDbgSignalMask0Hi_F_Value_Data_prev = MMR_CDbgSignalMask0Hi_F_Value;
assign MMR_CDbgSignalMask0Hi_F_Value_Data_muxed = MMR_CDbgSignalMask0Hi_F_Value_WrEn ? MMR_CDbgSignalMask0Hi_F_Value_Data : MMR_CDbgSignalMask0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMask0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMask0Hi_F_Value)
);

logic                                           MMR_CDbgSignalMatch0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMatch0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch0Hi_F_Value[31:0]};
assign MMR_CDbgSignalMatch0Hi_F_Value_Data = (CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch0Hi_F_Value), 64'(MMR_CDbgSignalMatch0Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch0Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH0HI))));
assign MMR_CDbgSignalMatch0Hi_F_Value_Data_prev = MMR_CDbgSignalMatch0Hi_F_Value;
assign MMR_CDbgSignalMatch0Hi_F_Value_Data_muxed = MMR_CDbgSignalMatch0Hi_F_Value_WrEn ? MMR_CDbgSignalMatch0Hi_F_Value_Data : MMR_CDbgSignalMatch0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMatch0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMatch0Hi_F_Value)
);

logic                                           MMR_CDbgSignalMask1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMask1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask1Hi_F_Value[31:0]};
assign MMR_CDbgSignalMask1Hi_F_Value_Data = (CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask1Hi_F_Value), 64'(MMR_CDbgSignalMask1Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask1Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK1HI))));
assign MMR_CDbgSignalMask1Hi_F_Value_Data_prev = MMR_CDbgSignalMask1Hi_F_Value;
assign MMR_CDbgSignalMask1Hi_F_Value_Data_muxed = MMR_CDbgSignalMask1Hi_F_Value_WrEn ? MMR_CDbgSignalMask1Hi_F_Value_Data : MMR_CDbgSignalMask1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMask1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMask1Hi_F_Value)
);

logic                                           MMR_CDbgSignalMatch1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMatch1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch1Hi_F_Value[31:0]};
assign MMR_CDbgSignalMatch1Hi_F_Value_Data = (CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch1Hi_F_Value), 64'(MMR_CDbgSignalMatch1Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch1Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH1HI))));
assign MMR_CDbgSignalMatch1Hi_F_Value_Data_prev = MMR_CDbgSignalMatch1Hi_F_Value;
assign MMR_CDbgSignalMatch1Hi_F_Value_Data_muxed = MMR_CDbgSignalMatch1Hi_F_Value_WrEn ? MMR_CDbgSignalMatch1Hi_F_Value_Data : MMR_CDbgSignalMatch1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMatch1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMatch1Hi_F_Value)
);

logic                                           MMR_CDbgSignalMask2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMask2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask2Hi_F_Value[31:0]};
assign MMR_CDbgSignalMask2Hi_F_Value_Data = (CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask2Hi_F_Value), 64'(MMR_CDbgSignalMask2Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask2Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK2HI))));
assign MMR_CDbgSignalMask2Hi_F_Value_Data_prev = MMR_CDbgSignalMask2Hi_F_Value;
assign MMR_CDbgSignalMask2Hi_F_Value_Data_muxed = MMR_CDbgSignalMask2Hi_F_Value_WrEn ? MMR_CDbgSignalMask2Hi_F_Value_Data : MMR_CDbgSignalMask2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMask2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMask2Hi_F_Value)
);

logic                                           MMR_CDbgSignalMatch2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMatch2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch2Hi_F_Value[31:0]};
assign MMR_CDbgSignalMatch2Hi_F_Value_Data = (CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch2Hi_F_Value), 64'(MMR_CDbgSignalMatch2Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch2Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH2HI))));
assign MMR_CDbgSignalMatch2Hi_F_Value_Data_prev = MMR_CDbgSignalMatch2Hi_F_Value;
assign MMR_CDbgSignalMatch2Hi_F_Value_Data_muxed = MMR_CDbgSignalMatch2Hi_F_Value_WrEn ? MMR_CDbgSignalMatch2Hi_F_Value_Data : MMR_CDbgSignalMatch2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMatch2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMatch2Hi_F_Value)
);

logic                                           MMR_CDbgSignalMask3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH  -1:0] MMR_CDbgSignalMask3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMask3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMask3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMask3Hi_F_Value[31:0]};
assign MMR_CDbgSignalMask3Hi_F_Value_Data = (CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMask3Hi_F_Value), 64'(MMR_CDbgSignalMask3Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMask3Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMASK3HI))));
assign MMR_CDbgSignalMask3Hi_F_Value_Data_prev = MMR_CDbgSignalMask3Hi_F_Value;
assign MMR_CDbgSignalMask3Hi_F_Value_Data_muxed = MMR_CDbgSignalMask3Hi_F_Value_WrEn ? MMR_CDbgSignalMask3Hi_F_Value_Data : MMR_CDbgSignalMask3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMASK3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMask3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMask3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMask3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMask3Hi_F_Value)
);

logic                                           MMR_CDbgSignalMatch3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH -1:0] MMR_CDbgSignalMatch3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalMatch3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalMatch3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalMatch3Hi_F_Value[31:0]};
assign MMR_CDbgSignalMatch3Hi_F_Value_Data = (CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgSignalMatch3Hi_F_Value), 64'(MMR_CDbgSignalMatch3Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgSignalMatch3Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGSIGNALMATCH3HI))));
assign MMR_CDbgSignalMatch3Hi_F_Value_Data_prev = MMR_CDbgSignalMatch3Hi_F_Value;
assign MMR_CDbgSignalMatch3Hi_F_Value_Data_muxed = MMR_CDbgSignalMatch3Hi_F_Value_WrEn ? MMR_CDbgSignalMatch3Hi_F_Value_Data : MMR_CDbgSignalMatch3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALMATCH3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalMatch3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalMatch3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalMatch3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalMatch3Hi_F_Value)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg15_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg15_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg15_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg15_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg15_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg15_DataEff = {reg_wr_data[63:58]};
assign MMR_CDbgMuxSelHi_F_Muxselseg15_Data = (CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg15), 64'(MMR_CDbgMuxSelHi_F_Muxselseg15_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg15_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg15_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg15;
assign MMR_CDbgMuxSelHi_F_Muxselseg15_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg15_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg15_Data : MMR_CDbgMuxSelHi_F_Muxselseg15_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG15_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg15_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg15_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg15_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg15)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg14_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg14_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg14_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg14_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg14_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg14_DataEff = {reg_wr_data[57:52]};
assign MMR_CDbgMuxSelHi_F_Muxselseg14_Data = (CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg14), 64'(MMR_CDbgMuxSelHi_F_Muxselseg14_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg14_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg14_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg14;
assign MMR_CDbgMuxSelHi_F_Muxselseg14_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg14_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg14_Data : MMR_CDbgMuxSelHi_F_Muxselseg14_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG14_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg14_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg14_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg14_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg14)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg13_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg13_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg13_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg13_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg13_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg13_DataEff = {reg_wr_data[51:46]};
assign MMR_CDbgMuxSelHi_F_Muxselseg13_Data = (CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg13), 64'(MMR_CDbgMuxSelHi_F_Muxselseg13_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg13_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg13_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg13;
assign MMR_CDbgMuxSelHi_F_Muxselseg13_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg13_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg13_Data : MMR_CDbgMuxSelHi_F_Muxselseg13_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG13_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg13_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg13_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg13_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg13)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg12_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg12_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg12_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg12_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg12_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg12_DataEff = {reg_wr_data[45:40]};
assign MMR_CDbgMuxSelHi_F_Muxselseg12_Data = (CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg12), 64'(MMR_CDbgMuxSelHi_F_Muxselseg12_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg12_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg12_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg12;
assign MMR_CDbgMuxSelHi_F_Muxselseg12_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg12_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg12_Data : MMR_CDbgMuxSelHi_F_Muxselseg12_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG12_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg12_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg12_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg12_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg12)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg11_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg11_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg11_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg11_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg11_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg11_DataEff = {reg_wr_data[39:34]};
assign MMR_CDbgMuxSelHi_F_Muxselseg11_Data = (CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg11), 64'(MMR_CDbgMuxSelHi_F_Muxselseg11_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg11_WrEn = (((reg_write & reg_wr_strb[1] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg11_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg11;
assign MMR_CDbgMuxSelHi_F_Muxselseg11_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg11_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg11_Data : MMR_CDbgMuxSelHi_F_Muxselseg11_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG11_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg11_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg11_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg11_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg11)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg10_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg10_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg10_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg10_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH -1:0] MMR_CDbgMuxSelHi_F_Muxselseg10_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg10_DataEff = {reg_wr_strb[1] ? reg_wr_data[33:32] : MMR_CDbgMuxSelHi_F_Muxselseg10[5:4] , reg_wr_strb[0] ? reg_wr_data[31:28] : MMR_CDbgMuxSelHi_F_Muxselseg10[3:0]};
assign MMR_CDbgMuxSelHi_F_Muxselseg10_Data = (CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg10), 64'(MMR_CDbgMuxSelHi_F_Muxselseg10_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg10_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg10_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg10;
assign MMR_CDbgMuxSelHi_F_Muxselseg10_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg10_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg10_Data : MMR_CDbgMuxSelHi_F_Muxselseg10_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG10_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg10_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg10_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg10_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg10)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg9_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg9_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg9_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg9_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg9_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg9_DataEff = {reg_wr_data[27:22]};
assign MMR_CDbgMuxSelHi_F_Muxselseg9_Data = (CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg9), 64'(MMR_CDbgMuxSelHi_F_Muxselseg9_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg9_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg9_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg9;
assign MMR_CDbgMuxSelHi_F_Muxselseg9_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg9_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg9_Data : MMR_CDbgMuxSelHi_F_Muxselseg9_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG9_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg9_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg9_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg9_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg9)
);

logic                                           MMR_CDbgMuxSelHi_F_Muxselseg8_WrEn;
logic [CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg8_Data;
logic [CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg8_DataEff;
logic [CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg8_Data_muxed;
logic [CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH  -1:0] MMR_CDbgMuxSelHi_F_Muxselseg8_Data_prev;
assign MMR_CDbgMuxSelHi_F_Muxselseg8_DataEff = {reg_wr_data[21:16]};
assign MMR_CDbgMuxSelHi_F_Muxselseg8_Data = (CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Muxselseg8), 64'(MMR_CDbgMuxSelHi_F_Muxselseg8_DataEff[5:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Muxselseg8_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Muxselseg8_Data_prev = MMR_CDbgMuxSelHi_F_Muxselseg8;
assign MMR_CDbgMuxSelHi_F_Muxselseg8_Data_muxed = MMR_CDbgMuxSelHi_F_Muxselseg8_WrEn ? MMR_CDbgMuxSelHi_F_Muxselseg8_Data : MMR_CDbgMuxSelHi_F_Muxselseg8_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_MUXSELSEG8_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Muxselseg8_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Muxselseg8_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Muxselseg8_Data),
    .out   (MMR_CDbgMuxSelHi_F_Muxselseg8)
);

logic                                           MMR_CDbgMuxSelHi_F_Rsvd150_WrEn;
logic [CLA_CDBGMUXSELHI_RSVD150_WIDTH     -1:0] MMR_CDbgMuxSelHi_F_Rsvd150_Data;
logic [CLA_CDBGMUXSELHI_RSVD150_WIDTH     -1:0] MMR_CDbgMuxSelHi_F_Rsvd150_DataEff;
logic [CLA_CDBGMUXSELHI_RSVD150_WIDTH     -1:0] MMR_CDbgMuxSelHi_F_Rsvd150_Data_muxed;
logic [CLA_CDBGMUXSELHI_RSVD150_WIDTH     -1:0] MMR_CDbgMuxSelHi_F_Rsvd150_Data_prev;
assign MMR_CDbgMuxSelHi_F_Rsvd150_DataEff = {reg_wr_data[15:0]};
assign MMR_CDbgMuxSelHi_F_Rsvd150_Data = (CLA_CDBGMUXSELHI_RSVD150_WIDTH'(update_value(64'(MMR_CDbgMuxSelHi_F_Rsvd150), 64'(MMR_CDbgMuxSelHi_F_Rsvd150_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_CDbgMuxSelHi_F_Rsvd150_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGMUXSELHI))));
assign MMR_CDbgMuxSelHi_F_Rsvd150_Data_prev = MMR_CDbgMuxSelHi_F_Rsvd150;
assign MMR_CDbgMuxSelHi_F_Rsvd150_Data_muxed = MMR_CDbgMuxSelHi_F_Rsvd150_WrEn ? MMR_CDbgMuxSelHi_F_Rsvd150_Data : MMR_CDbgMuxSelHi_F_Rsvd150_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGMUXSELHI_RSVD150_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGMUXSELHI_RSVD150_WIDTH'(0))
) MMR_CDbgMuxSelHi_F_Rsvd150_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgMuxSelHi_F_Rsvd150_WrEn),
    .in    (MMR_CDbgMuxSelHi_F_Rsvd150_Data),
    .out   (MMR_CDbgMuxSelHi_F_Rsvd150)
);

logic                                           MMR_CDbgTransitionMaskHi_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskHi_F_Value_Data;
logic [CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskHi_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskHi_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionMaskHi_F_Value_Data_prev;
assign MMR_CDbgTransitionMaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionMaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionMaskHi_F_Value[31:0]};
assign MMR_CDbgTransitionMaskHi_F_Value_Data = (CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionMaskHi_F_Value), 64'(MMR_CDbgTransitionMaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionMaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONMASKHI))));
assign MMR_CDbgTransitionMaskHi_F_Value_Data_prev = MMR_CDbgTransitionMaskHi_F_Value;
assign MMR_CDbgTransitionMaskHi_F_Value_Data_muxed = MMR_CDbgTransitionMaskHi_F_Value_WrEn ? MMR_CDbgTransitionMaskHi_F_Value_Data : MMR_CDbgTransitionMaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONMASKHI_VALUE_WIDTH'(0))
) MMR_CDbgTransitionMaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgTransitionMaskHi_F_Value_WrEn),
    .in    (MMR_CDbgTransitionMaskHi_F_Value_Data),
    .out   (MMR_CDbgTransitionMaskHi_F_Value)
);

logic                                           MMR_CDbgTransitionFromValueHi_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueHi_F_Value_Data;
logic [CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueHi_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueHi_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionFromValueHi_F_Value_Data_prev;
assign MMR_CDbgTransitionFromValueHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionFromValueHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionFromValueHi_F_Value[31:0]};
assign MMR_CDbgTransitionFromValueHi_F_Value_Data = (CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionFromValueHi_F_Value), 64'(MMR_CDbgTransitionFromValueHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionFromValueHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONFROMVALUEHI))));
assign MMR_CDbgTransitionFromValueHi_F_Value_Data_prev = MMR_CDbgTransitionFromValueHi_F_Value;
assign MMR_CDbgTransitionFromValueHi_F_Value_Data_muxed = MMR_CDbgTransitionFromValueHi_F_Value_WrEn ? MMR_CDbgTransitionFromValueHi_F_Value_Data : MMR_CDbgTransitionFromValueHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONFROMVALUEHI_VALUE_WIDTH'(0))
) MMR_CDbgTransitionFromValueHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgTransitionFromValueHi_F_Value_WrEn),
    .in    (MMR_CDbgTransitionFromValueHi_F_Value_Data),
    .out   (MMR_CDbgTransitionFromValueHi_F_Value)
);

logic                                           MMR_CDbgTransitionToValueHi_F_Value_WrEn;
logic [CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueHi_F_Value_Data;
logic [CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueHi_F_Value_DataEff;
logic [CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueHi_F_Value_Data_muxed;
logic [CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH-1:0] MMR_CDbgTransitionToValueHi_F_Value_Data_prev;
assign MMR_CDbgTransitionToValueHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTransitionToValueHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTransitionToValueHi_F_Value[31:0]};
assign MMR_CDbgTransitionToValueHi_F_Value_Data = (CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgTransitionToValueHi_F_Value), 64'(MMR_CDbgTransitionToValueHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgTransitionToValueHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGTRANSITIONTOVALUEHI))));
assign MMR_CDbgTransitionToValueHi_F_Value_Data_prev = MMR_CDbgTransitionToValueHi_F_Value;
assign MMR_CDbgTransitionToValueHi_F_Value_Data_muxed = MMR_CDbgTransitionToValueHi_F_Value_WrEn ? MMR_CDbgTransitionToValueHi_F_Value_Data : MMR_CDbgTransitionToValueHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTRANSITIONTOVALUEHI_VALUE_WIDTH'(0))
) MMR_CDbgTransitionToValueHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgTransitionToValueHi_F_Value_WrEn),
    .in    (MMR_CDbgTransitionToValueHi_F_Value_Data),
    .out   (MMR_CDbgTransitionToValueHi_F_Value)
);

logic                                           MMR_CDbgOnesCountMaskHi_F_Value_WrEn;
logic [CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskHi_F_Value_Data;
logic [CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskHi_F_Value_DataEff;
logic [CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskHi_F_Value_Data_muxed;
logic [CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH-1:0] MMR_CDbgOnesCountMaskHi_F_Value_Data_prev;
assign MMR_CDbgOnesCountMaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgOnesCountMaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgOnesCountMaskHi_F_Value[31:0]};
assign MMR_CDbgOnesCountMaskHi_F_Value_Data = (CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgOnesCountMaskHi_F_Value), 64'(MMR_CDbgOnesCountMaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgOnesCountMaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGONESCOUNTMASKHI))));
assign MMR_CDbgOnesCountMaskHi_F_Value_Data_prev = MMR_CDbgOnesCountMaskHi_F_Value;
assign MMR_CDbgOnesCountMaskHi_F_Value_Data_muxed = MMR_CDbgOnesCountMaskHi_F_Value_WrEn ? MMR_CDbgOnesCountMaskHi_F_Value_Data : MMR_CDbgOnesCountMaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGONESCOUNTMASKHI_VALUE_WIDTH'(0))
) MMR_CDbgOnesCountMaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgOnesCountMaskHi_F_Value_WrEn),
    .in    (MMR_CDbgOnesCountMaskHi_F_Value_Data),
    .out   (MMR_CDbgOnesCountMaskHi_F_Value)
);

logic                                           MMR_CDbgAnyChangeHi_F_Mask_WrEn;
logic [CLA_CDBGANYCHANGEHI_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeHi_F_Mask_Data;
logic [CLA_CDBGANYCHANGEHI_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeHi_F_Mask_DataEff;
logic [CLA_CDBGANYCHANGEHI_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeHi_F_Mask_Data_muxed;
logic [CLA_CDBGANYCHANGEHI_MASK_WIDTH     -1:0] MMR_CDbgAnyChangeHi_F_Mask_Data_prev;
assign MMR_CDbgAnyChangeHi_F_Mask_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgAnyChangeHi_F_Mask[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgAnyChangeHi_F_Mask[31:0]};
assign MMR_CDbgAnyChangeHi_F_Mask_Data = (CLA_CDBGANYCHANGEHI_MASK_WIDTH'(update_value(64'(MMR_CDbgAnyChangeHi_F_Mask), 64'(MMR_CDbgAnyChangeHi_F_Mask_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgAnyChangeHi_F_Mask_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGANYCHANGEHI))));
assign MMR_CDbgAnyChangeHi_F_Mask_Data_prev = MMR_CDbgAnyChangeHi_F_Mask;
assign MMR_CDbgAnyChangeHi_F_Mask_Data_muxed = MMR_CDbgAnyChangeHi_F_Mask_WrEn ? MMR_CDbgAnyChangeHi_F_Mask_Data : MMR_CDbgAnyChangeHi_F_Mask_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGANYCHANGEHI_MASK_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGANYCHANGEHI_MASK_WIDTH'(0))
) MMR_CDbgAnyChangeHi_F_Mask_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgAnyChangeHi_F_Mask_WrEn),
    .in    (MMR_CDbgAnyChangeHi_F_Mask_Data),
    .out   (MMR_CDbgAnyChangeHi_F_Mask)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap0HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap0HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap1HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap1HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap0HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap0HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap1HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap1HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap0HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap0HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap1HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap1HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap0HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap0HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP0HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap1HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap1HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP1HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap2HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap2HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode0Eap3HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode0Eap3HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE0EAP3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap2HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap2HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode1Eap3HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode1Eap3HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE1EAP3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap2HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap2HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode2Eap3HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode2Eap3HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE2EAP3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap2HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap2HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP2HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value)
);

logic                                           MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_WrEn;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_DataEff;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_muxed;
logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH-1:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_prev;
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value[31:0]};
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data = (ClaMmrCdbgsignalsnapshotnode3Eap3HiWr.Data.Value);
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_WrEn = ((ClaMmrCdbgsignalsnapshotnode3Eap3HiWr.ValueWrEn));
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_prev = MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value;
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_muxed = MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_WrEn ? MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data : MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGSIGNALSNAPSHOTNODE3EAP3HI_VALUE_WIDTH'(0))
) MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_WrEn),
    .in    (MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data),
    .out   (MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value)
);

logic                                           MMR_CDbgLfsr_F_Lfsr_WrEn;
logic [CLA_CDBGLFSR_LFSR_WIDTH            -1:0] MMR_CDbgLfsr_F_Lfsr_Data;
logic [CLA_CDBGLFSR_LFSR_WIDTH            -1:0] MMR_CDbgLfsr_F_Lfsr_DataEff;
logic [CLA_CDBGLFSR_LFSR_WIDTH            -1:0] MMR_CDbgLfsr_F_Lfsr_Data_muxed;
logic [CLA_CDBGLFSR_LFSR_WIDTH            -1:0] MMR_CDbgLfsr_F_Lfsr_Data_prev;
assign MMR_CDbgLfsr_F_Lfsr_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgLfsr_F_Lfsr[62:31] , reg_wr_strb[0] ? reg_wr_data[31:1] : MMR_CDbgLfsr_F_Lfsr[30:0]};
assign MMR_CDbgLfsr_F_Lfsr_Data = ((reg_write & (reg_addr == ADDR_MMR_CDBGLFSR)) ? CLA_CDBGLFSR_LFSR_WIDTH'(update_value(64'(MMR_CDbgLfsr_F_Lfsr), 64'(MMR_CDbgLfsr_F_Lfsr_DataEff[62:0]), reg_wr_instr_type)) : ClaMmrCdbglfsrWr.Data.Lfsr);
assign MMR_CDbgLfsr_F_Lfsr_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGLFSR)) | ClaMmrCdbglfsrWr.LfsrWrEn));
assign MMR_CDbgLfsr_F_Lfsr_Data_prev = MMR_CDbgLfsr_F_Lfsr;
assign MMR_CDbgLfsr_F_Lfsr_Data_muxed = MMR_CDbgLfsr_F_Lfsr_WrEn ? MMR_CDbgLfsr_F_Lfsr_Data : MMR_CDbgLfsr_F_Lfsr_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGLFSR_LFSR_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGLFSR_LFSR_WIDTH'(0))
) MMR_CDbgLfsr_F_Lfsr_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgLfsr_F_Lfsr_WrEn),
    .in    (MMR_CDbgLfsr_F_Lfsr_Data),
    .out   (MMR_CDbgLfsr_F_Lfsr)
);

logic                                           MMR_CDbgLfsr_F_LfsrActive_WrEn;
logic [CLA_CDBGLFSR_LFSRACTIVE_WIDTH      -1:0] MMR_CDbgLfsr_F_LfsrActive_Data;
logic [CLA_CDBGLFSR_LFSRACTIVE_WIDTH      -1:0] MMR_CDbgLfsr_F_LfsrActive_DataEff;
logic [CLA_CDBGLFSR_LFSRACTIVE_WIDTH      -1:0] MMR_CDbgLfsr_F_LfsrActive_Data_muxed;
logic [CLA_CDBGLFSR_LFSRACTIVE_WIDTH      -1:0] MMR_CDbgLfsr_F_LfsrActive_Data_prev;
assign MMR_CDbgLfsr_F_LfsrActive_DataEff = {reg_wr_data[0:0]};
assign MMR_CDbgLfsr_F_LfsrActive_Data = (CLA_CDBGLFSR_LFSRACTIVE_WIDTH'(update_value(64'(MMR_CDbgLfsr_F_LfsrActive), 64'(MMR_CDbgLfsr_F_LfsrActive_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgLfsr_F_LfsrActive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGLFSR))));
assign MMR_CDbgLfsr_F_LfsrActive_Data_prev = MMR_CDbgLfsr_F_LfsrActive;
assign MMR_CDbgLfsr_F_LfsrActive_Data_muxed = MMR_CDbgLfsr_F_LfsrActive_WrEn ? MMR_CDbgLfsr_F_LfsrActive_Data : MMR_CDbgLfsr_F_LfsrActive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGLFSR_LFSRACTIVE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGLFSR_LFSRACTIVE_WIDTH'(0))
) MMR_CDbgLfsr_F_LfsrActive_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgLfsr_F_LfsrActive_WrEn),
    .in    (MMR_CDbgLfsr_F_LfsrActive_Data),
    .out   (MMR_CDbgLfsr_F_LfsrActive)
);

logic                                           MMR_CDbgLfsrMask_F_Mask_WrEn;
logic [CLA_CDBGLFSRMASK_MASK_WIDTH        -1:0] MMR_CDbgLfsrMask_F_Mask_Data;
logic [CLA_CDBGLFSRMASK_MASK_WIDTH        -1:0] MMR_CDbgLfsrMask_F_Mask_DataEff;
logic [CLA_CDBGLFSRMASK_MASK_WIDTH        -1:0] MMR_CDbgLfsrMask_F_Mask_Data_muxed;
logic [CLA_CDBGLFSRMASK_MASK_WIDTH        -1:0] MMR_CDbgLfsrMask_F_Mask_Data_prev;
assign MMR_CDbgLfsrMask_F_Mask_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgLfsrMask_F_Mask[62:31] , reg_wr_strb[0] ? reg_wr_data[31:1] : MMR_CDbgLfsrMask_F_Mask[30:0]};
assign MMR_CDbgLfsrMask_F_Mask_Data = (CLA_CDBGLFSRMASK_MASK_WIDTH'(update_value(64'(MMR_CDbgLfsrMask_F_Mask), 64'(MMR_CDbgLfsrMask_F_Mask_DataEff[62:0]), reg_wr_instr_type)));
assign MMR_CDbgLfsrMask_F_Mask_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGLFSRMASK))));
assign MMR_CDbgLfsrMask_F_Mask_Data_prev = MMR_CDbgLfsrMask_F_Mask;
assign MMR_CDbgLfsrMask_F_Mask_Data_muxed = MMR_CDbgLfsrMask_F_Mask_WrEn ? MMR_CDbgLfsrMask_F_Mask_Data : MMR_CDbgLfsrMask_F_Mask_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGLFSRMASK_MASK_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGLFSRMASK_MASK_WIDTH'(0))
) MMR_CDbgLfsrMask_F_Mask_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgLfsrMask_F_Mask_WrEn),
    .in    (MMR_CDbgLfsrMask_F_Mask_Data),
    .out   (MMR_CDbgLfsrMask_F_Mask)
);

logic                                           MMR_CDbgLfsrMask_F_Rsvd0_WrEn;
logic [CLA_CDBGLFSRMASK_RSVD0_WIDTH       -1:0] MMR_CDbgLfsrMask_F_Rsvd0_Data;
logic [CLA_CDBGLFSRMASK_RSVD0_WIDTH       -1:0] MMR_CDbgLfsrMask_F_Rsvd0_DataEff;
logic [CLA_CDBGLFSRMASK_RSVD0_WIDTH       -1:0] MMR_CDbgLfsrMask_F_Rsvd0_Data_muxed;
logic [CLA_CDBGLFSRMASK_RSVD0_WIDTH       -1:0] MMR_CDbgLfsrMask_F_Rsvd0_Data_prev;
assign MMR_CDbgLfsrMask_F_Rsvd0_DataEff = {reg_wr_data[0:0]};
assign MMR_CDbgLfsrMask_F_Rsvd0_Data = (CLA_CDBGLFSRMASK_RSVD0_WIDTH'(update_value(64'(MMR_CDbgLfsrMask_F_Rsvd0), 64'(MMR_CDbgLfsrMask_F_Rsvd0_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgLfsrMask_F_Rsvd0_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGLFSRMASK))));
assign MMR_CDbgLfsrMask_F_Rsvd0_Data_prev = MMR_CDbgLfsrMask_F_Rsvd0;
assign MMR_CDbgLfsrMask_F_Rsvd0_Data_muxed = MMR_CDbgLfsrMask_F_Rsvd0_WrEn ? MMR_CDbgLfsrMask_F_Rsvd0_Data : MMR_CDbgLfsrMask_F_Rsvd0_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGLFSRMASK_RSVD0_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGLFSRMASK_RSVD0_WIDTH'(0))
) MMR_CDbgLfsrMask_F_Rsvd0_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgLfsrMask_F_Rsvd0_WrEn),
    .in    (MMR_CDbgLfsrMask_F_Rsvd0_Data),
    .out   (MMR_CDbgLfsrMask_F_Rsvd0)
);

logic                                           MMR_CDbgTimestampCapture_F_Timestamp_WrEn;
logic [CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH-1:0] MMR_CDbgTimestampCapture_F_Timestamp_Data;
logic [CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH-1:0] MMR_CDbgTimestampCapture_F_Timestamp_DataEff;
logic [CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH-1:0] MMR_CDbgTimestampCapture_F_Timestamp_Data_muxed;
logic [CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH-1:0] MMR_CDbgTimestampCapture_F_Timestamp_Data_prev;
assign MMR_CDbgTimestampCapture_F_Timestamp_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgTimestampCapture_F_Timestamp[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgTimestampCapture_F_Timestamp[31:0]};
assign MMR_CDbgTimestampCapture_F_Timestamp_Data = (ClaMmrCdbgtimestampcaptureWr.Data.Timestamp);
assign MMR_CDbgTimestampCapture_F_Timestamp_WrEn = ((ClaMmrCdbgtimestampcaptureWr.TimestampWrEn));
assign MMR_CDbgTimestampCapture_F_Timestamp_Data_prev = MMR_CDbgTimestampCapture_F_Timestamp;
assign MMR_CDbgTimestampCapture_F_Timestamp_Data_muxed = MMR_CDbgTimestampCapture_F_Timestamp_WrEn ? MMR_CDbgTimestampCapture_F_Timestamp_Data : MMR_CDbgTimestampCapture_F_Timestamp_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGTIMESTAMPCAPTURE_TIMESTAMP_WIDTH'(0))
) MMR_CDbgTimestampCapture_F_Timestamp_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgTimestampCapture_F_Timestamp_WrEn),
    .in    (MMR_CDbgTimestampCapture_F_Timestamp_Data),
    .out   (MMR_CDbgTimestampCapture_F_Timestamp)
);

logic                                           MMR_CDbgCompare0Lo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE0LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Lo_F_Value_Data;
logic [CLA_CDBGCOMPARE0LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Lo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE0LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Lo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE0LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Lo_F_Value_Data_prev;
assign MMR_CDbgCompare0Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare0Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare0Lo_F_Value[31:0]};
assign MMR_CDbgCompare0Lo_F_Value_Data = (CLA_CDBGCOMPARE0LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare0Lo_F_Value), 64'(MMR_CDbgCompare0Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare0Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE0LO))));
assign MMR_CDbgCompare0Lo_F_Value_Data_prev = MMR_CDbgCompare0Lo_F_Value;
assign MMR_CDbgCompare0Lo_F_Value_Data_muxed = MMR_CDbgCompare0Lo_F_Value_WrEn ? MMR_CDbgCompare0Lo_F_Value_Data : MMR_CDbgCompare0Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE0LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE0LO_VALUE_WIDTH'(0))
) MMR_CDbgCompare0Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare0Lo_F_Value_WrEn),
    .in    (MMR_CDbgCompare0Lo_F_Value_Data),
    .out   (MMR_CDbgCompare0Lo_F_Value)
);

logic                                           MMR_CDbgCompare0MaskLo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskLo_F_Value_Data;
logic [CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskLo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskLo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskLo_F_Value_Data_prev;
assign MMR_CDbgCompare0MaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare0MaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare0MaskLo_F_Value[31:0]};
assign MMR_CDbgCompare0MaskLo_F_Value_Data = (CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare0MaskLo_F_Value), 64'(MMR_CDbgCompare0MaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare0MaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE0MASKLO))));
assign MMR_CDbgCompare0MaskLo_F_Value_Data_prev = MMR_CDbgCompare0MaskLo_F_Value;
assign MMR_CDbgCompare0MaskLo_F_Value_Data_muxed = MMR_CDbgCompare0MaskLo_F_Value_WrEn ? MMR_CDbgCompare0MaskLo_F_Value_Data : MMR_CDbgCompare0MaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE0MASKLO_VALUE_WIDTH'(0))
) MMR_CDbgCompare0MaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare0MaskLo_F_Value_WrEn),
    .in    (MMR_CDbgCompare0MaskLo_F_Value_Data),
    .out   (MMR_CDbgCompare0MaskLo_F_Value)
);

logic                                           MMR_CDbgCompare1Lo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE1LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Lo_F_Value_Data;
logic [CLA_CDBGCOMPARE1LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Lo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE1LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Lo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE1LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Lo_F_Value_Data_prev;
assign MMR_CDbgCompare1Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare1Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare1Lo_F_Value[31:0]};
assign MMR_CDbgCompare1Lo_F_Value_Data = (CLA_CDBGCOMPARE1LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare1Lo_F_Value), 64'(MMR_CDbgCompare1Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare1Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE1LO))));
assign MMR_CDbgCompare1Lo_F_Value_Data_prev = MMR_CDbgCompare1Lo_F_Value;
assign MMR_CDbgCompare1Lo_F_Value_Data_muxed = MMR_CDbgCompare1Lo_F_Value_WrEn ? MMR_CDbgCompare1Lo_F_Value_Data : MMR_CDbgCompare1Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE1LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE1LO_VALUE_WIDTH'(0))
) MMR_CDbgCompare1Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare1Lo_F_Value_WrEn),
    .in    (MMR_CDbgCompare1Lo_F_Value_Data),
    .out   (MMR_CDbgCompare1Lo_F_Value)
);

logic                                           MMR_CDbgCompare1MaskLo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskLo_F_Value_Data;
logic [CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskLo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskLo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskLo_F_Value_Data_prev;
assign MMR_CDbgCompare1MaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare1MaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare1MaskLo_F_Value[31:0]};
assign MMR_CDbgCompare1MaskLo_F_Value_Data = (CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare1MaskLo_F_Value), 64'(MMR_CDbgCompare1MaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare1MaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE1MASKLO))));
assign MMR_CDbgCompare1MaskLo_F_Value_Data_prev = MMR_CDbgCompare1MaskLo_F_Value;
assign MMR_CDbgCompare1MaskLo_F_Value_Data_muxed = MMR_CDbgCompare1MaskLo_F_Value_WrEn ? MMR_CDbgCompare1MaskLo_F_Value_Data : MMR_CDbgCompare1MaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE1MASKLO_VALUE_WIDTH'(0))
) MMR_CDbgCompare1MaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare1MaskLo_F_Value_WrEn),
    .in    (MMR_CDbgCompare1MaskLo_F_Value_Data),
    .out   (MMR_CDbgCompare1MaskLo_F_Value)
);

logic                                           MMR_CDbgCompare2Lo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE2LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Lo_F_Value_Data;
logic [CLA_CDBGCOMPARE2LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Lo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE2LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Lo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE2LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Lo_F_Value_Data_prev;
assign MMR_CDbgCompare2Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare2Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare2Lo_F_Value[31:0]};
assign MMR_CDbgCompare2Lo_F_Value_Data = (CLA_CDBGCOMPARE2LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare2Lo_F_Value), 64'(MMR_CDbgCompare2Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare2Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE2LO))));
assign MMR_CDbgCompare2Lo_F_Value_Data_prev = MMR_CDbgCompare2Lo_F_Value;
assign MMR_CDbgCompare2Lo_F_Value_Data_muxed = MMR_CDbgCompare2Lo_F_Value_WrEn ? MMR_CDbgCompare2Lo_F_Value_Data : MMR_CDbgCompare2Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE2LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE2LO_VALUE_WIDTH'(0))
) MMR_CDbgCompare2Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare2Lo_F_Value_WrEn),
    .in    (MMR_CDbgCompare2Lo_F_Value_Data),
    .out   (MMR_CDbgCompare2Lo_F_Value)
);

logic                                           MMR_CDbgCompare2MaskLo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskLo_F_Value_Data;
logic [CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskLo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskLo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskLo_F_Value_Data_prev;
assign MMR_CDbgCompare2MaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare2MaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare2MaskLo_F_Value[31:0]};
assign MMR_CDbgCompare2MaskLo_F_Value_Data = (CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare2MaskLo_F_Value), 64'(MMR_CDbgCompare2MaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare2MaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE2MASKLO))));
assign MMR_CDbgCompare2MaskLo_F_Value_Data_prev = MMR_CDbgCompare2MaskLo_F_Value;
assign MMR_CDbgCompare2MaskLo_F_Value_Data_muxed = MMR_CDbgCompare2MaskLo_F_Value_WrEn ? MMR_CDbgCompare2MaskLo_F_Value_Data : MMR_CDbgCompare2MaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE2MASKLO_VALUE_WIDTH'(0))
) MMR_CDbgCompare2MaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare2MaskLo_F_Value_WrEn),
    .in    (MMR_CDbgCompare2MaskLo_F_Value_Data),
    .out   (MMR_CDbgCompare2MaskLo_F_Value)
);

logic                                           MMR_CDbgCompare3Lo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE3LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Lo_F_Value_Data;
logic [CLA_CDBGCOMPARE3LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Lo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE3LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Lo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE3LO_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Lo_F_Value_Data_prev;
assign MMR_CDbgCompare3Lo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare3Lo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare3Lo_F_Value[31:0]};
assign MMR_CDbgCompare3Lo_F_Value_Data = (CLA_CDBGCOMPARE3LO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare3Lo_F_Value), 64'(MMR_CDbgCompare3Lo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare3Lo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE3LO))));
assign MMR_CDbgCompare3Lo_F_Value_Data_prev = MMR_CDbgCompare3Lo_F_Value;
assign MMR_CDbgCompare3Lo_F_Value_Data_muxed = MMR_CDbgCompare3Lo_F_Value_WrEn ? MMR_CDbgCompare3Lo_F_Value_Data : MMR_CDbgCompare3Lo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE3LO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE3LO_VALUE_WIDTH'(0))
) MMR_CDbgCompare3Lo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare3Lo_F_Value_WrEn),
    .in    (MMR_CDbgCompare3Lo_F_Value_Data),
    .out   (MMR_CDbgCompare3Lo_F_Value)
);

logic                                           MMR_CDbgCompare3MaskLo_F_Value_WrEn;
logic [CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskLo_F_Value_Data;
logic [CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskLo_F_Value_DataEff;
logic [CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskLo_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskLo_F_Value_Data_prev;
assign MMR_CDbgCompare3MaskLo_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare3MaskLo_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare3MaskLo_F_Value[31:0]};
assign MMR_CDbgCompare3MaskLo_F_Value_Data = (CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare3MaskLo_F_Value), 64'(MMR_CDbgCompare3MaskLo_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare3MaskLo_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE3MASKLO))));
assign MMR_CDbgCompare3MaskLo_F_Value_Data_prev = MMR_CDbgCompare3MaskLo_F_Value;
assign MMR_CDbgCompare3MaskLo_F_Value_Data_muxed = MMR_CDbgCompare3MaskLo_F_Value_WrEn ? MMR_CDbgCompare3MaskLo_F_Value_Data : MMR_CDbgCompare3MaskLo_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE3MASKLO_VALUE_WIDTH'(0))
) MMR_CDbgCompare3MaskLo_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride),
    .en    (MMR_CDbgCompare3MaskLo_F_Value_WrEn),
    .in    (MMR_CDbgCompare3MaskLo_F_Value_Data),
    .out   (MMR_CDbgCompare3MaskLo_F_Value)
);

logic                                           MMR_CDbgCompare0Hi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE0HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Hi_F_Value_Data;
logic [CLA_CDBGCOMPARE0HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Hi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE0HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Hi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE0HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare0Hi_F_Value_Data_prev;
assign MMR_CDbgCompare0Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare0Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare0Hi_F_Value[31:0]};
assign MMR_CDbgCompare0Hi_F_Value_Data = (CLA_CDBGCOMPARE0HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare0Hi_F_Value), 64'(MMR_CDbgCompare0Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare0Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE0HI))));
assign MMR_CDbgCompare0Hi_F_Value_Data_prev = MMR_CDbgCompare0Hi_F_Value;
assign MMR_CDbgCompare0Hi_F_Value_Data_muxed = MMR_CDbgCompare0Hi_F_Value_WrEn ? MMR_CDbgCompare0Hi_F_Value_Data : MMR_CDbgCompare0Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE0HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE0HI_VALUE_WIDTH'(0))
) MMR_CDbgCompare0Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare0Hi_F_Value_WrEn),
    .in    (MMR_CDbgCompare0Hi_F_Value_Data),
    .out   (MMR_CDbgCompare0Hi_F_Value)
);

logic                                           MMR_CDbgCompare0MaskHi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskHi_F_Value_Data;
logic [CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskHi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskHi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare0MaskHi_F_Value_Data_prev;
assign MMR_CDbgCompare0MaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare0MaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare0MaskHi_F_Value[31:0]};
assign MMR_CDbgCompare0MaskHi_F_Value_Data = (CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare0MaskHi_F_Value), 64'(MMR_CDbgCompare0MaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare0MaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE0MASKHI))));
assign MMR_CDbgCompare0MaskHi_F_Value_Data_prev = MMR_CDbgCompare0MaskHi_F_Value;
assign MMR_CDbgCompare0MaskHi_F_Value_Data_muxed = MMR_CDbgCompare0MaskHi_F_Value_WrEn ? MMR_CDbgCompare0MaskHi_F_Value_Data : MMR_CDbgCompare0MaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE0MASKHI_VALUE_WIDTH'(0))
) MMR_CDbgCompare0MaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare0MaskHi_F_Value_WrEn),
    .in    (MMR_CDbgCompare0MaskHi_F_Value_Data),
    .out   (MMR_CDbgCompare0MaskHi_F_Value)
);

logic                                           MMR_CDbgCompare1Hi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE1HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Hi_F_Value_Data;
logic [CLA_CDBGCOMPARE1HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Hi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE1HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Hi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE1HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare1Hi_F_Value_Data_prev;
assign MMR_CDbgCompare1Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare1Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare1Hi_F_Value[31:0]};
assign MMR_CDbgCompare1Hi_F_Value_Data = (CLA_CDBGCOMPARE1HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare1Hi_F_Value), 64'(MMR_CDbgCompare1Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare1Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE1HI))));
assign MMR_CDbgCompare1Hi_F_Value_Data_prev = MMR_CDbgCompare1Hi_F_Value;
assign MMR_CDbgCompare1Hi_F_Value_Data_muxed = MMR_CDbgCompare1Hi_F_Value_WrEn ? MMR_CDbgCompare1Hi_F_Value_Data : MMR_CDbgCompare1Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE1HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE1HI_VALUE_WIDTH'(0))
) MMR_CDbgCompare1Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare1Hi_F_Value_WrEn),
    .in    (MMR_CDbgCompare1Hi_F_Value_Data),
    .out   (MMR_CDbgCompare1Hi_F_Value)
);

logic                                           MMR_CDbgCompare1MaskHi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskHi_F_Value_Data;
logic [CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskHi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskHi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare1MaskHi_F_Value_Data_prev;
assign MMR_CDbgCompare1MaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare1MaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare1MaskHi_F_Value[31:0]};
assign MMR_CDbgCompare1MaskHi_F_Value_Data = (CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare1MaskHi_F_Value), 64'(MMR_CDbgCompare1MaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare1MaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE1MASKHI))));
assign MMR_CDbgCompare1MaskHi_F_Value_Data_prev = MMR_CDbgCompare1MaskHi_F_Value;
assign MMR_CDbgCompare1MaskHi_F_Value_Data_muxed = MMR_CDbgCompare1MaskHi_F_Value_WrEn ? MMR_CDbgCompare1MaskHi_F_Value_Data : MMR_CDbgCompare1MaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE1MASKHI_VALUE_WIDTH'(0))
) MMR_CDbgCompare1MaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare1MaskHi_F_Value_WrEn),
    .in    (MMR_CDbgCompare1MaskHi_F_Value_Data),
    .out   (MMR_CDbgCompare1MaskHi_F_Value)
);

logic                                           MMR_CDbgCompare2Hi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE2HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Hi_F_Value_Data;
logic [CLA_CDBGCOMPARE2HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Hi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE2HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Hi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE2HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare2Hi_F_Value_Data_prev;
assign MMR_CDbgCompare2Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare2Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare2Hi_F_Value[31:0]};
assign MMR_CDbgCompare2Hi_F_Value_Data = (CLA_CDBGCOMPARE2HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare2Hi_F_Value), 64'(MMR_CDbgCompare2Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare2Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE2HI))));
assign MMR_CDbgCompare2Hi_F_Value_Data_prev = MMR_CDbgCompare2Hi_F_Value;
assign MMR_CDbgCompare2Hi_F_Value_Data_muxed = MMR_CDbgCompare2Hi_F_Value_WrEn ? MMR_CDbgCompare2Hi_F_Value_Data : MMR_CDbgCompare2Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE2HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE2HI_VALUE_WIDTH'(0))
) MMR_CDbgCompare2Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare2Hi_F_Value_WrEn),
    .in    (MMR_CDbgCompare2Hi_F_Value_Data),
    .out   (MMR_CDbgCompare2Hi_F_Value)
);

logic                                           MMR_CDbgCompare2MaskHi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskHi_F_Value_Data;
logic [CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskHi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskHi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare2MaskHi_F_Value_Data_prev;
assign MMR_CDbgCompare2MaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare2MaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare2MaskHi_F_Value[31:0]};
assign MMR_CDbgCompare2MaskHi_F_Value_Data = (CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare2MaskHi_F_Value), 64'(MMR_CDbgCompare2MaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare2MaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE2MASKHI))));
assign MMR_CDbgCompare2MaskHi_F_Value_Data_prev = MMR_CDbgCompare2MaskHi_F_Value;
assign MMR_CDbgCompare2MaskHi_F_Value_Data_muxed = MMR_CDbgCompare2MaskHi_F_Value_WrEn ? MMR_CDbgCompare2MaskHi_F_Value_Data : MMR_CDbgCompare2MaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE2MASKHI_VALUE_WIDTH'(0))
) MMR_CDbgCompare2MaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare2MaskHi_F_Value_WrEn),
    .in    (MMR_CDbgCompare2MaskHi_F_Value_Data),
    .out   (MMR_CDbgCompare2MaskHi_F_Value)
);

logic                                           MMR_CDbgCompare3Hi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE3HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Hi_F_Value_Data;
logic [CLA_CDBGCOMPARE3HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Hi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE3HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Hi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE3HI_VALUE_WIDTH     -1:0] MMR_CDbgCompare3Hi_F_Value_Data_prev;
assign MMR_CDbgCompare3Hi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare3Hi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare3Hi_F_Value[31:0]};
assign MMR_CDbgCompare3Hi_F_Value_Data = (CLA_CDBGCOMPARE3HI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare3Hi_F_Value), 64'(MMR_CDbgCompare3Hi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare3Hi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE3HI))));
assign MMR_CDbgCompare3Hi_F_Value_Data_prev = MMR_CDbgCompare3Hi_F_Value;
assign MMR_CDbgCompare3Hi_F_Value_Data_muxed = MMR_CDbgCompare3Hi_F_Value_WrEn ? MMR_CDbgCompare3Hi_F_Value_Data : MMR_CDbgCompare3Hi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE3HI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE3HI_VALUE_WIDTH'(0))
) MMR_CDbgCompare3Hi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare3Hi_F_Value_WrEn),
    .in    (MMR_CDbgCompare3Hi_F_Value_Data),
    .out   (MMR_CDbgCompare3Hi_F_Value)
);

logic                                           MMR_CDbgCompare3MaskHi_F_Value_WrEn;
logic [CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskHi_F_Value_Data;
logic [CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskHi_F_Value_DataEff;
logic [CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskHi_F_Value_Data_muxed;
logic [CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH -1:0] MMR_CDbgCompare3MaskHi_F_Value_Data_prev;
assign MMR_CDbgCompare3MaskHi_F_Value_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_CDbgCompare3MaskHi_F_Value[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_CDbgCompare3MaskHi_F_Value[31:0]};
assign MMR_CDbgCompare3MaskHi_F_Value_Data = (CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH'(update_value(64'(MMR_CDbgCompare3MaskHi_F_Value), 64'(MMR_CDbgCompare3MaskHi_F_Value_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_CDbgCompare3MaskHi_F_Value_WrEn = (((reg_write & (reg_addr == ADDR_MMR_CDBGCOMPARE3MASKHI))));
assign MMR_CDbgCompare3MaskHi_F_Value_Data_prev = MMR_CDbgCompare3MaskHi_F_Value;
assign MMR_CDbgCompare3MaskHi_F_Value_Data_muxed = MMR_CDbgCompare3MaskHi_F_Value_WrEn ? MMR_CDbgCompare3MaskHi_F_Value_Data : MMR_CDbgCompare3MaskHi_F_Value_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH-1:0])),
    .RESET_VALUE (CLA_CDBGCOMPARE3MASKHI_VALUE_WIDTH'(0))
) MMR_CDbgCompare3MaskHi_F_Value_ff (
    .clk   (clk),
    .rst_n (reset_n_warm_ovrride_hi),
    .en    (MMR_CDbgCompare3MaskHi_F_Value_WrEn),
    .in    (MMR_CDbgCompare3MaskHi_F_Value_Data),
    .out   (MMR_CDbgCompare3MaskHi_F_Value)
);

assign MMR_CDbgVersion_F_Rsvd6312 = 52'h0;

assign MMR_CDbgVersion_F_Major = 4'h2;

assign MMR_CDbgVersion_F_Minor = 4'h0;

assign MMR_CDbgVersion_F_Patch = 4'h0;

logic                                           MMR_Scratch_F_Data_WrEn;
logic [CLA_SCRATCH_DATA_WIDTH             -1:0] MMR_Scratch_F_Data_Data;
logic [CLA_SCRATCH_DATA_WIDTH             -1:0] MMR_Scratch_F_Data_DataEff;
logic [CLA_SCRATCH_DATA_WIDTH             -1:0] MMR_Scratch_F_Data_Data_muxed;
logic [CLA_SCRATCH_DATA_WIDTH             -1:0] MMR_Scratch_F_Data_Data_prev;
assign MMR_Scratch_F_Data_DataEff = {reg_wr_strb[1] ? reg_wr_data[63:32] : MMR_Scratch_F_Data[63:32] , reg_wr_strb[0] ? reg_wr_data[31:0] : MMR_Scratch_F_Data[31:0]};
assign MMR_Scratch_F_Data_Data = (CLA_SCRATCH_DATA_WIDTH'(update_value(64'(MMR_Scratch_F_Data), 64'(MMR_Scratch_F_Data_DataEff[63:0]), reg_wr_instr_type)));
assign MMR_Scratch_F_Data_WrEn = (((reg_write & (reg_addr == ADDR_MMR_SCRATCH))));
assign MMR_Scratch_F_Data_Data_prev = MMR_Scratch_F_Data;
assign MMR_Scratch_F_Data_Data_muxed = MMR_Scratch_F_Data_WrEn ? MMR_Scratch_F_Data_Data : MMR_Scratch_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [CLA_SCRATCH_DATA_WIDTH-1:0])),
    .RESET_VALUE (CLA_SCRATCH_DATA_WIDTH'(0))
) MMR_Scratch_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Scratch_F_Data_WrEn),
    .in    (MMR_Scratch_F_Data_Data),
    .out   (MMR_Scratch_F_Data)
);

assign MMR_CDbgClaCounter0Cfg = {
    MMR_CDbgClaCounter0Cfg_F_Rsvd,
    MMR_CDbgClaCounter0Cfg_F_UpperTarget,
    MMR_CDbgClaCounter0Cfg_F_UpperCounter,
    MMR_CDbgClaCounter0Cfg_F_ResetOnTarget,
    MMR_CDbgClaCounter0Cfg_F_Target,
    MMR_CDbgClaCounter0Cfg_F_Counter
};
logic [63:0] MMR_CDbgClaCounter0Cfg_muxed;
assign MMR_CDbgClaCounter0Cfg_muxed = {
    MMR_CDbgClaCounter0Cfg_F_Rsvd,
    MMR_CDbgClaCounter0Cfg_F_UpperTarget_Data_muxed,
    MMR_CDbgClaCounter0Cfg_F_UpperCounter_Data_muxed,
    MMR_CDbgClaCounter0Cfg_F_ResetOnTarget_Data_muxed,
    MMR_CDbgClaCounter0Cfg_F_Target_Data_muxed,
    MMR_CDbgClaCounter0Cfg_F_Counter_Data_muxed
};
assign MMR_CDbgClaCounter1Cfg = {
    MMR_CDbgClaCounter1Cfg_F_Rsvd,
    MMR_CDbgClaCounter1Cfg_F_UpperTarget,
    MMR_CDbgClaCounter1Cfg_F_UpperCounter,
    MMR_CDbgClaCounter1Cfg_F_ResetOnTarget,
    MMR_CDbgClaCounter1Cfg_F_Target,
    MMR_CDbgClaCounter1Cfg_F_Counter
};
logic [63:0] MMR_CDbgClaCounter1Cfg_muxed;
assign MMR_CDbgClaCounter1Cfg_muxed = {
    MMR_CDbgClaCounter1Cfg_F_Rsvd,
    MMR_CDbgClaCounter1Cfg_F_UpperTarget_Data_muxed,
    MMR_CDbgClaCounter1Cfg_F_UpperCounter_Data_muxed,
    MMR_CDbgClaCounter1Cfg_F_ResetOnTarget_Data_muxed,
    MMR_CDbgClaCounter1Cfg_F_Target_Data_muxed,
    MMR_CDbgClaCounter1Cfg_F_Counter_Data_muxed
};
assign MMR_CDbgClaCounter2Cfg = {
    MMR_CDbgClaCounter2Cfg_F_Rsvd,
    MMR_CDbgClaCounter2Cfg_F_UpperTarget,
    MMR_CDbgClaCounter2Cfg_F_UpperCounter,
    MMR_CDbgClaCounter2Cfg_F_ResetOnTarget,
    MMR_CDbgClaCounter2Cfg_F_Target,
    MMR_CDbgClaCounter2Cfg_F_Counter
};
logic [63:0] MMR_CDbgClaCounter2Cfg_muxed;
assign MMR_CDbgClaCounter2Cfg_muxed = {
    MMR_CDbgClaCounter2Cfg_F_Rsvd,
    MMR_CDbgClaCounter2Cfg_F_UpperTarget_Data_muxed,
    MMR_CDbgClaCounter2Cfg_F_UpperCounter_Data_muxed,
    MMR_CDbgClaCounter2Cfg_F_ResetOnTarget_Data_muxed,
    MMR_CDbgClaCounter2Cfg_F_Target_Data_muxed,
    MMR_CDbgClaCounter2Cfg_F_Counter_Data_muxed
};
assign MMR_CDbgClaCounter3Cfg = {
    MMR_CDbgClaCounter3Cfg_F_Rsvd,
    MMR_CDbgClaCounter3Cfg_F_UpperTarget,
    MMR_CDbgClaCounter3Cfg_F_UpperCounter,
    MMR_CDbgClaCounter3Cfg_F_ResetOnTarget,
    MMR_CDbgClaCounter3Cfg_F_Target,
    MMR_CDbgClaCounter3Cfg_F_Counter
};
logic [63:0] MMR_CDbgClaCounter3Cfg_muxed;
assign MMR_CDbgClaCounter3Cfg_muxed = {
    MMR_CDbgClaCounter3Cfg_F_Rsvd,
    MMR_CDbgClaCounter3Cfg_F_UpperTarget_Data_muxed,
    MMR_CDbgClaCounter3Cfg_F_UpperCounter_Data_muxed,
    MMR_CDbgClaCounter3Cfg_F_ResetOnTarget_Data_muxed,
    MMR_CDbgClaCounter3Cfg_F_Target_Data_muxed,
    MMR_CDbgClaCounter3Cfg_F_Counter_Data_muxed
};
assign MMR_CDbgNode0Eap0 = {
    MMR_CDbgNode0Eap0_F_Action3,
    MMR_CDbgNode0Eap0_F_Action2,
    MMR_CDbgNode0Eap0_F_Udf,
    MMR_CDbgNode0Eap0_F_EventType2,
    MMR_CDbgNode0Eap0_F_CustomAction1Enable,
    MMR_CDbgNode0Eap0_F_CustomAction0Enable,
    MMR_CDbgNode0Eap0_F_CustomAction1,
    MMR_CDbgNode0Eap0_F_CustomAction0,
    MMR_CDbgNode0Eap0_F_EventType1,
    MMR_CDbgNode0Eap0_F_EventType0,
    MMR_CDbgNode0Eap0_F_LogicalOp,
    MMR_CDbgNode0Eap0_F_Action1,
    MMR_CDbgNode0Eap0_F_Action0,
    MMR_CDbgNode0Eap0_F_DestNode
};
logic [63:0] MMR_CDbgNode0Eap0_muxed;
assign MMR_CDbgNode0Eap0_muxed = {
    MMR_CDbgNode0Eap0_F_Action3_Data_muxed,
    MMR_CDbgNode0Eap0_F_Action2_Data_muxed,
    MMR_CDbgNode0Eap0_F_Udf_Data_muxed,
    MMR_CDbgNode0Eap0_F_EventType2_Data_muxed,
    MMR_CDbgNode0Eap0_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode0Eap0_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode0Eap0_F_CustomAction1_Data_muxed,
    MMR_CDbgNode0Eap0_F_CustomAction0_Data_muxed,
    MMR_CDbgNode0Eap0_F_EventType1_Data_muxed,
    MMR_CDbgNode0Eap0_F_EventType0_Data_muxed,
    MMR_CDbgNode0Eap0_F_LogicalOp_Data_muxed,
    MMR_CDbgNode0Eap0_F_Action1_Data_muxed,
    MMR_CDbgNode0Eap0_F_Action0_Data_muxed,
    MMR_CDbgNode0Eap0_F_DestNode_Data_muxed
};
assign MMR_CDbgNode0Eap1 = {
    MMR_CDbgNode0Eap1_F_Action3,
    MMR_CDbgNode0Eap1_F_Action2,
    MMR_CDbgNode0Eap1_F_Udf,
    MMR_CDbgNode0Eap1_F_EventType2,
    MMR_CDbgNode0Eap1_F_CustomAction1Enable,
    MMR_CDbgNode0Eap1_F_CustomAction0Enable,
    MMR_CDbgNode0Eap1_F_CustomAction1,
    MMR_CDbgNode0Eap1_F_CustomAction0,
    MMR_CDbgNode0Eap1_F_EventType1,
    MMR_CDbgNode0Eap1_F_EventType0,
    MMR_CDbgNode0Eap1_F_LogicalOp,
    MMR_CDbgNode0Eap1_F_Action1,
    MMR_CDbgNode0Eap1_F_Action0,
    MMR_CDbgNode0Eap1_F_DestNode
};
logic [63:0] MMR_CDbgNode0Eap1_muxed;
assign MMR_CDbgNode0Eap1_muxed = {
    MMR_CDbgNode0Eap1_F_Action3_Data_muxed,
    MMR_CDbgNode0Eap1_F_Action2_Data_muxed,
    MMR_CDbgNode0Eap1_F_Udf_Data_muxed,
    MMR_CDbgNode0Eap1_F_EventType2_Data_muxed,
    MMR_CDbgNode0Eap1_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode0Eap1_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode0Eap1_F_CustomAction1_Data_muxed,
    MMR_CDbgNode0Eap1_F_CustomAction0_Data_muxed,
    MMR_CDbgNode0Eap1_F_EventType1_Data_muxed,
    MMR_CDbgNode0Eap1_F_EventType0_Data_muxed,
    MMR_CDbgNode0Eap1_F_LogicalOp_Data_muxed,
    MMR_CDbgNode0Eap1_F_Action1_Data_muxed,
    MMR_CDbgNode0Eap1_F_Action0_Data_muxed,
    MMR_CDbgNode0Eap1_F_DestNode_Data_muxed
};
assign MMR_CDbgNode1Eap0 = {
    MMR_CDbgNode1Eap0_F_Action3,
    MMR_CDbgNode1Eap0_F_Action2,
    MMR_CDbgNode1Eap0_F_Udf,
    MMR_CDbgNode1Eap0_F_EventType2,
    MMR_CDbgNode1Eap0_F_CustomAction1Enable,
    MMR_CDbgNode1Eap0_F_CustomAction0Enable,
    MMR_CDbgNode1Eap0_F_CustomAction1,
    MMR_CDbgNode1Eap0_F_CustomAction0,
    MMR_CDbgNode1Eap0_F_EventType1,
    MMR_CDbgNode1Eap0_F_EventType0,
    MMR_CDbgNode1Eap0_F_LogicalOp,
    MMR_CDbgNode1Eap0_F_Action1,
    MMR_CDbgNode1Eap0_F_Action0,
    MMR_CDbgNode1Eap0_F_DestNode
};
logic [63:0] MMR_CDbgNode1Eap0_muxed;
assign MMR_CDbgNode1Eap0_muxed = {
    MMR_CDbgNode1Eap0_F_Action3_Data_muxed,
    MMR_CDbgNode1Eap0_F_Action2_Data_muxed,
    MMR_CDbgNode1Eap0_F_Udf_Data_muxed,
    MMR_CDbgNode1Eap0_F_EventType2_Data_muxed,
    MMR_CDbgNode1Eap0_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode1Eap0_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode1Eap0_F_CustomAction1_Data_muxed,
    MMR_CDbgNode1Eap0_F_CustomAction0_Data_muxed,
    MMR_CDbgNode1Eap0_F_EventType1_Data_muxed,
    MMR_CDbgNode1Eap0_F_EventType0_Data_muxed,
    MMR_CDbgNode1Eap0_F_LogicalOp_Data_muxed,
    MMR_CDbgNode1Eap0_F_Action1_Data_muxed,
    MMR_CDbgNode1Eap0_F_Action0_Data_muxed,
    MMR_CDbgNode1Eap0_F_DestNode_Data_muxed
};
assign MMR_CDbgNode1Eap1 = {
    MMR_CDbgNode1Eap1_F_Action3,
    MMR_CDbgNode1Eap1_F_Action2,
    MMR_CDbgNode1Eap1_F_Udf,
    MMR_CDbgNode1Eap1_F_EventType2,
    MMR_CDbgNode1Eap1_F_CustomAction1Enable,
    MMR_CDbgNode1Eap1_F_CustomAction0Enable,
    MMR_CDbgNode1Eap1_F_CustomAction1,
    MMR_CDbgNode1Eap1_F_CustomAction0,
    MMR_CDbgNode1Eap1_F_EventType1,
    MMR_CDbgNode1Eap1_F_EventType0,
    MMR_CDbgNode1Eap1_F_LogicalOp,
    MMR_CDbgNode1Eap1_F_Action1,
    MMR_CDbgNode1Eap1_F_Action0,
    MMR_CDbgNode1Eap1_F_DestNode
};
logic [63:0] MMR_CDbgNode1Eap1_muxed;
assign MMR_CDbgNode1Eap1_muxed = {
    MMR_CDbgNode1Eap1_F_Action3_Data_muxed,
    MMR_CDbgNode1Eap1_F_Action2_Data_muxed,
    MMR_CDbgNode1Eap1_F_Udf_Data_muxed,
    MMR_CDbgNode1Eap1_F_EventType2_Data_muxed,
    MMR_CDbgNode1Eap1_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode1Eap1_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode1Eap1_F_CustomAction1_Data_muxed,
    MMR_CDbgNode1Eap1_F_CustomAction0_Data_muxed,
    MMR_CDbgNode1Eap1_F_EventType1_Data_muxed,
    MMR_CDbgNode1Eap1_F_EventType0_Data_muxed,
    MMR_CDbgNode1Eap1_F_LogicalOp_Data_muxed,
    MMR_CDbgNode1Eap1_F_Action1_Data_muxed,
    MMR_CDbgNode1Eap1_F_Action0_Data_muxed,
    MMR_CDbgNode1Eap1_F_DestNode_Data_muxed
};
assign MMR_CDbgNode2Eap0 = {
    MMR_CDbgNode2Eap0_F_Action3,
    MMR_CDbgNode2Eap0_F_Action2,
    MMR_CDbgNode2Eap0_F_Udf,
    MMR_CDbgNode2Eap0_F_EventType2,
    MMR_CDbgNode2Eap0_F_CustomAction1Enable,
    MMR_CDbgNode2Eap0_F_CustomAction0Enable,
    MMR_CDbgNode2Eap0_F_CustomAction1,
    MMR_CDbgNode2Eap0_F_CustomAction0,
    MMR_CDbgNode2Eap0_F_EventType1,
    MMR_CDbgNode2Eap0_F_EventType0,
    MMR_CDbgNode2Eap0_F_LogicalOp,
    MMR_CDbgNode2Eap0_F_Action1,
    MMR_CDbgNode2Eap0_F_Action0,
    MMR_CDbgNode2Eap0_F_DestNode
};
logic [63:0] MMR_CDbgNode2Eap0_muxed;
assign MMR_CDbgNode2Eap0_muxed = {
    MMR_CDbgNode2Eap0_F_Action3_Data_muxed,
    MMR_CDbgNode2Eap0_F_Action2_Data_muxed,
    MMR_CDbgNode2Eap0_F_Udf_Data_muxed,
    MMR_CDbgNode2Eap0_F_EventType2_Data_muxed,
    MMR_CDbgNode2Eap0_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode2Eap0_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode2Eap0_F_CustomAction1_Data_muxed,
    MMR_CDbgNode2Eap0_F_CustomAction0_Data_muxed,
    MMR_CDbgNode2Eap0_F_EventType1_Data_muxed,
    MMR_CDbgNode2Eap0_F_EventType0_Data_muxed,
    MMR_CDbgNode2Eap0_F_LogicalOp_Data_muxed,
    MMR_CDbgNode2Eap0_F_Action1_Data_muxed,
    MMR_CDbgNode2Eap0_F_Action0_Data_muxed,
    MMR_CDbgNode2Eap0_F_DestNode_Data_muxed
};
assign MMR_CDbgNode2Eap1 = {
    MMR_CDbgNode2Eap1_F_Action3,
    MMR_CDbgNode2Eap1_F_Action2,
    MMR_CDbgNode2Eap1_F_Udf,
    MMR_CDbgNode2Eap1_F_EventType2,
    MMR_CDbgNode2Eap1_F_CustomAction1Enable,
    MMR_CDbgNode2Eap1_F_CustomAction0Enable,
    MMR_CDbgNode2Eap1_F_CustomAction1,
    MMR_CDbgNode2Eap1_F_CustomAction0,
    MMR_CDbgNode2Eap1_F_EventType1,
    MMR_CDbgNode2Eap1_F_EventType0,
    MMR_CDbgNode2Eap1_F_LogicalOp,
    MMR_CDbgNode2Eap1_F_Action1,
    MMR_CDbgNode2Eap1_F_Action0,
    MMR_CDbgNode2Eap1_F_DestNode
};
logic [63:0] MMR_CDbgNode2Eap1_muxed;
assign MMR_CDbgNode2Eap1_muxed = {
    MMR_CDbgNode2Eap1_F_Action3_Data_muxed,
    MMR_CDbgNode2Eap1_F_Action2_Data_muxed,
    MMR_CDbgNode2Eap1_F_Udf_Data_muxed,
    MMR_CDbgNode2Eap1_F_EventType2_Data_muxed,
    MMR_CDbgNode2Eap1_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode2Eap1_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode2Eap1_F_CustomAction1_Data_muxed,
    MMR_CDbgNode2Eap1_F_CustomAction0_Data_muxed,
    MMR_CDbgNode2Eap1_F_EventType1_Data_muxed,
    MMR_CDbgNode2Eap1_F_EventType0_Data_muxed,
    MMR_CDbgNode2Eap1_F_LogicalOp_Data_muxed,
    MMR_CDbgNode2Eap1_F_Action1_Data_muxed,
    MMR_CDbgNode2Eap1_F_Action0_Data_muxed,
    MMR_CDbgNode2Eap1_F_DestNode_Data_muxed
};
assign MMR_CDbgNode3Eap0 = {
    MMR_CDbgNode3Eap0_F_Action3,
    MMR_CDbgNode3Eap0_F_Action2,
    MMR_CDbgNode3Eap0_F_Udf,
    MMR_CDbgNode3Eap0_F_EventType2,
    MMR_CDbgNode3Eap0_F_CustomAction1Enable,
    MMR_CDbgNode3Eap0_F_CustomAction0Enable,
    MMR_CDbgNode3Eap0_F_CustomAction1,
    MMR_CDbgNode3Eap0_F_CustomAction0,
    MMR_CDbgNode3Eap0_F_EventType1,
    MMR_CDbgNode3Eap0_F_EventType0,
    MMR_CDbgNode3Eap0_F_LogicalOp,
    MMR_CDbgNode3Eap0_F_Action1,
    MMR_CDbgNode3Eap0_F_Action0,
    MMR_CDbgNode3Eap0_F_DestNode
};
logic [63:0] MMR_CDbgNode3Eap0_muxed;
assign MMR_CDbgNode3Eap0_muxed = {
    MMR_CDbgNode3Eap0_F_Action3_Data_muxed,
    MMR_CDbgNode3Eap0_F_Action2_Data_muxed,
    MMR_CDbgNode3Eap0_F_Udf_Data_muxed,
    MMR_CDbgNode3Eap0_F_EventType2_Data_muxed,
    MMR_CDbgNode3Eap0_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode3Eap0_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode3Eap0_F_CustomAction1_Data_muxed,
    MMR_CDbgNode3Eap0_F_CustomAction0_Data_muxed,
    MMR_CDbgNode3Eap0_F_EventType1_Data_muxed,
    MMR_CDbgNode3Eap0_F_EventType0_Data_muxed,
    MMR_CDbgNode3Eap0_F_LogicalOp_Data_muxed,
    MMR_CDbgNode3Eap0_F_Action1_Data_muxed,
    MMR_CDbgNode3Eap0_F_Action0_Data_muxed,
    MMR_CDbgNode3Eap0_F_DestNode_Data_muxed
};
assign MMR_CDbgNode3Eap1 = {
    MMR_CDbgNode3Eap1_F_Action3,
    MMR_CDbgNode3Eap1_F_Action2,
    MMR_CDbgNode3Eap1_F_Udf,
    MMR_CDbgNode3Eap1_F_EventType2,
    MMR_CDbgNode3Eap1_F_CustomAction1Enable,
    MMR_CDbgNode3Eap1_F_CustomAction0Enable,
    MMR_CDbgNode3Eap1_F_CustomAction1,
    MMR_CDbgNode3Eap1_F_CustomAction0,
    MMR_CDbgNode3Eap1_F_EventType1,
    MMR_CDbgNode3Eap1_F_EventType0,
    MMR_CDbgNode3Eap1_F_LogicalOp,
    MMR_CDbgNode3Eap1_F_Action1,
    MMR_CDbgNode3Eap1_F_Action0,
    MMR_CDbgNode3Eap1_F_DestNode
};
logic [63:0] MMR_CDbgNode3Eap1_muxed;
assign MMR_CDbgNode3Eap1_muxed = {
    MMR_CDbgNode3Eap1_F_Action3_Data_muxed,
    MMR_CDbgNode3Eap1_F_Action2_Data_muxed,
    MMR_CDbgNode3Eap1_F_Udf_Data_muxed,
    MMR_CDbgNode3Eap1_F_EventType2_Data_muxed,
    MMR_CDbgNode3Eap1_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode3Eap1_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode3Eap1_F_CustomAction1_Data_muxed,
    MMR_CDbgNode3Eap1_F_CustomAction0_Data_muxed,
    MMR_CDbgNode3Eap1_F_EventType1_Data_muxed,
    MMR_CDbgNode3Eap1_F_EventType0_Data_muxed,
    MMR_CDbgNode3Eap1_F_LogicalOp_Data_muxed,
    MMR_CDbgNode3Eap1_F_Action1_Data_muxed,
    MMR_CDbgNode3Eap1_F_Action0_Data_muxed,
    MMR_CDbgNode3Eap1_F_DestNode_Data_muxed
};
assign MMR_CDbgSignalMask0Lo = {
    MMR_CDbgSignalMask0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMask0Lo_muxed;
assign MMR_CDbgSignalMask0Lo_muxed = {
    MMR_CDbgSignalMask0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch0Lo = {
    MMR_CDbgSignalMatch0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMatch0Lo_muxed;
assign MMR_CDbgSignalMatch0Lo_muxed = {
    MMR_CDbgSignalMatch0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMask1Lo = {
    MMR_CDbgSignalMask1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMask1Lo_muxed;
assign MMR_CDbgSignalMask1Lo_muxed = {
    MMR_CDbgSignalMask1Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch1Lo = {
    MMR_CDbgSignalMatch1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMatch1Lo_muxed;
assign MMR_CDbgSignalMatch1Lo_muxed = {
    MMR_CDbgSignalMatch1Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalEdgeDetectCfg = {
    48'h0,
    MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1,
    MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select,
    MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0,
    MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select
};
logic [63:0] MMR_CDbgSignalEdgeDetectCfg_muxed;
assign MMR_CDbgSignalEdgeDetectCfg_muxed = {
    48'h0,
    MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1_Data_muxed,
    MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select_Data_muxed,
    MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0_Data_muxed,
    MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select_Data_muxed
};
assign MMR_CDbgEapStatus = {
    16'h0,
    MMR_CDbgEapStatus_F_Node3Eap3W2C,
    MMR_CDbgEapStatus_F_Node3Eap2W2C,
    MMR_CDbgEapStatus_F_Node3Eap1W2C,
    MMR_CDbgEapStatus_F_Node3Eap0W2C,
    MMR_CDbgEapStatus_F_Node2Eap3W2C,
    MMR_CDbgEapStatus_F_Node2Eap2W2C,
    MMR_CDbgEapStatus_F_Node2Eap1W2C,
    MMR_CDbgEapStatus_F_Node2Eap0W2C,
    MMR_CDbgEapStatus_F_Node1Eap3W2C,
    MMR_CDbgEapStatus_F_Node1Eap2W2C,
    MMR_CDbgEapStatus_F_Node1Eap1W2C,
    MMR_CDbgEapStatus_F_Node1Eap0W2C,
    MMR_CDbgEapStatus_F_Node0Eap3W2C,
    MMR_CDbgEapStatus_F_Node0Eap2W2C,
    MMR_CDbgEapStatus_F_Node0Eap1W2C,
    MMR_CDbgEapStatus_F_Node0Eap0W2C,
    MMR_CDbgEapStatus_F_Rsvd3116,
    MMR_CDbgEapStatus_F_Node3Eap3,
    MMR_CDbgEapStatus_F_Node3Eap2,
    MMR_CDbgEapStatus_F_Node3Eap1,
    MMR_CDbgEapStatus_F_Node3Eap0,
    MMR_CDbgEapStatus_F_Node2Eap3,
    MMR_CDbgEapStatus_F_Node2Eap2,
    MMR_CDbgEapStatus_F_Node2Eap1,
    MMR_CDbgEapStatus_F_Node2Eap0,
    MMR_CDbgEapStatus_F_Node1Eap3,
    MMR_CDbgEapStatus_F_Node1Eap2,
    MMR_CDbgEapStatus_F_Node1Eap1,
    MMR_CDbgEapStatus_F_Node1Eap0,
    MMR_CDbgEapStatus_F_Node0Eap3,
    MMR_CDbgEapStatus_F_Node0Eap2,
    MMR_CDbgEapStatus_F_Node0Eap1,
    MMR_CDbgEapStatus_F_Node0Eap0
};
logic [63:0] MMR_CDbgEapStatus_muxed;
assign MMR_CDbgEapStatus_muxed = {
    16'h0,
    MMR_CDbgEapStatus_F_Node3Eap3W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap2W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap1W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap0W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap3W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap2W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap1W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap0W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap3W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap2W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap1W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap0W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap3W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap2W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap1W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap0W2C_Data_muxed,
    MMR_CDbgEapStatus_F_Rsvd3116_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap3_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap2_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap1_Data_muxed,
    MMR_CDbgEapStatus_F_Node3Eap0_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap3_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap2_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap1_Data_muxed,
    MMR_CDbgEapStatus_F_Node2Eap0_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap3_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap2_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap1_Data_muxed,
    MMR_CDbgEapStatus_F_Node1Eap0_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap3_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap2_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap1_Data_muxed,
    MMR_CDbgEapStatus_F_Node0Eap0_Data_muxed
};
assign MMR_CDbgClaCtrlStatus = {
    MMR_CDbgClaCtrlStatus_F_ClaLock,
    MMR_CDbgClaCtrlStatus_F_Rsvd6216,
    MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt,
    MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt,
    MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay,
    MMR_CDbgClaCtrlStatus_F_EnableCla,
    MMR_CDbgClaCtrlStatus_F_EnableEap,
    3'h0,
    MMR_CDbgClaCtrlStatus_F_CurrentNode
};
logic [63:0] MMR_CDbgClaCtrlStatus_muxed;
assign MMR_CDbgClaCtrlStatus_muxed = {
    MMR_CDbgClaCtrlStatus_F_ClaLock_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_Rsvd6216_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_EnableCla_Data_muxed,
    MMR_CDbgClaCtrlStatus_F_EnableEap_Data_muxed,
    3'h0,
    MMR_CDbgClaCtrlStatus_F_CurrentNode_Data_muxed
};
assign MMR_CDbgMuxSelLo = {
    MMR_CDbgMuxSelLo_F_Muxselseg7,
    MMR_CDbgMuxSelLo_F_Muxselseg6,
    MMR_CDbgMuxSelLo_F_Muxselseg5,
    MMR_CDbgMuxSelLo_F_Muxselseg4,
    MMR_CDbgMuxSelLo_F_Muxselseg3,
    MMR_CDbgMuxSelLo_F_Muxselseg2,
    MMR_CDbgMuxSelLo_F_Muxselseg1,
    MMR_CDbgMuxSelLo_F_Muxselseg0,
    MMR_CDbgMuxSelLo_F_Rsvd1510,
    MMR_CDbgMuxSelLo_F_Valid,
    MMR_CDbgMuxSelLo_F_Finegraintime,
    MMR_CDbgMuxSelLo_F_Dbmid,
    MMR_CDbgMuxSelLo_F_Dbmmode
};
logic [63:0] MMR_CDbgMuxSelLo_muxed;
assign MMR_CDbgMuxSelLo_muxed = {
    MMR_CDbgMuxSelLo_F_Muxselseg7_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg6_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg5_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg4_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg3_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg2_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg1_Data_muxed,
    MMR_CDbgMuxSelLo_F_Muxselseg0_Data_muxed,
    MMR_CDbgMuxSelLo_F_Rsvd1510_Data_muxed,
    MMR_CDbgMuxSelLo_F_Valid_Data_muxed,
    MMR_CDbgMuxSelLo_F_Finegraintime_Data_muxed,
    MMR_CDbgMuxSelLo_F_Dbmid_Data_muxed,
    MMR_CDbgMuxSelLo_F_Dbmmode_Data_muxed
};
assign MMR_CDbgRsvd1 = {
    MMR_CDbgRsvd1_F_Value
};
logic [63:0] MMR_CDbgRsvd1_muxed;
assign MMR_CDbgRsvd1_muxed = {
    MMR_CDbgRsvd1_F_Value_Data_muxed
};
assign MMR_CDbgRsvd2 = {
    MMR_CDbgRsvd2_F_Value
};
logic [63:0] MMR_CDbgRsvd2_muxed;
assign MMR_CDbgRsvd2_muxed = {
    MMR_CDbgRsvd2_F_Value_Data_muxed
};
assign MMR_CDbgTransitionMaskLo = {
    MMR_CDbgTransitionMaskLo_F_Value
};
logic [63:0] MMR_CDbgTransitionMaskLo_muxed;
assign MMR_CDbgTransitionMaskLo_muxed = {
    MMR_CDbgTransitionMaskLo_F_Value_Data_muxed
};
assign MMR_CDbgTransitionFromValueLo = {
    MMR_CDbgTransitionFromValueLo_F_Value
};
logic [63:0] MMR_CDbgTransitionFromValueLo_muxed;
assign MMR_CDbgTransitionFromValueLo_muxed = {
    MMR_CDbgTransitionFromValueLo_F_Value_Data_muxed
};
assign MMR_CDbgTransitionToValueLo = {
    MMR_CDbgTransitionToValueLo_F_Value
};
logic [63:0] MMR_CDbgTransitionToValueLo_muxed;
assign MMR_CDbgTransitionToValueLo_muxed = {
    MMR_CDbgTransitionToValueLo_F_Value_Data_muxed
};
assign MMR_CDbgOnesCountMaskLo = {
    MMR_CDbgOnesCountMaskLo_F_Value
};
logic [63:0] MMR_CDbgOnesCountMaskLo_muxed;
assign MMR_CDbgOnesCountMaskLo_muxed = {
    MMR_CDbgOnesCountMaskLo_F_Value_Data_muxed
};
assign MMR_CDbgOnesCountValue = {
    MMR_CDbgOnesCountValue_F_Value
};
logic [63:0] MMR_CDbgOnesCountValue_muxed;
assign MMR_CDbgOnesCountValue_muxed = {
    MMR_CDbgOnesCountValue_F_Value_Data_muxed
};
assign MMR_CDbgAnyChangeLo = {
    MMR_CDbgAnyChangeLo_F_Mask
};
logic [63:0] MMR_CDbgAnyChangeLo_muxed;
assign MMR_CDbgAnyChangeLo_muxed = {
    MMR_CDbgAnyChangeLo_F_Mask_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap0Lo = {
    MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap0Lo_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap0Lo_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap1Lo = {
    MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap1Lo_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap1Lo_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap0Lo = {
    MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap0Lo_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap0Lo_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap1Lo = {
    MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap1Lo_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap1Lo_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap0Lo = {
    MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap0Lo_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap0Lo_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap1Lo = {
    MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap1Lo_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap1Lo_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap0Lo = {
    MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap0Lo_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap0Lo_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap1Lo = {
    MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap1Lo_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap1Lo_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value_Data_muxed
};
assign MMR_CDbgClaTimeMatch = {
    MMR_CDbgClaTimeMatch_F_TimeMatchVal
};
logic [63:0] MMR_CDbgClaTimeMatch_muxed;
assign MMR_CDbgClaTimeMatch_muxed = {
    MMR_CDbgClaTimeMatch_F_TimeMatchVal_Data_muxed
};
assign MMR_CDbgSignalMask2Lo = {
    MMR_CDbgSignalMask2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMask2Lo_muxed;
assign MMR_CDbgSignalMask2Lo_muxed = {
    MMR_CDbgSignalMask2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch2Lo = {
    MMR_CDbgSignalMatch2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMatch2Lo_muxed;
assign MMR_CDbgSignalMatch2Lo_muxed = {
    MMR_CDbgSignalMatch2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMask3Lo = {
    MMR_CDbgSignalMask3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMask3Lo_muxed;
assign MMR_CDbgSignalMask3Lo_muxed = {
    MMR_CDbgSignalMask3Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch3Lo = {
    MMR_CDbgSignalMatch3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalMatch3Lo_muxed;
assign MMR_CDbgSignalMatch3Lo_muxed = {
    MMR_CDbgSignalMatch3Lo_F_Value_Data_muxed
};
assign MMR_CDbgNode0Eap2 = {
    MMR_CDbgNode0Eap2_F_Action3,
    MMR_CDbgNode0Eap2_F_Action2,
    MMR_CDbgNode0Eap2_F_Udf,
    MMR_CDbgNode0Eap2_F_EventType2,
    MMR_CDbgNode0Eap2_F_CustomAction1Enable,
    MMR_CDbgNode0Eap2_F_CustomAction0Enable,
    MMR_CDbgNode0Eap2_F_CustomAction1,
    MMR_CDbgNode0Eap2_F_CustomAction0,
    MMR_CDbgNode0Eap2_F_EventType1,
    MMR_CDbgNode0Eap2_F_EventType0,
    MMR_CDbgNode0Eap2_F_LogicalOp,
    MMR_CDbgNode0Eap2_F_Action1,
    MMR_CDbgNode0Eap2_F_Action0,
    MMR_CDbgNode0Eap2_F_DestNode
};
logic [63:0] MMR_CDbgNode0Eap2_muxed;
assign MMR_CDbgNode0Eap2_muxed = {
    MMR_CDbgNode0Eap2_F_Action3_Data_muxed,
    MMR_CDbgNode0Eap2_F_Action2_Data_muxed,
    MMR_CDbgNode0Eap2_F_Udf_Data_muxed,
    MMR_CDbgNode0Eap2_F_EventType2_Data_muxed,
    MMR_CDbgNode0Eap2_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode0Eap2_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode0Eap2_F_CustomAction1_Data_muxed,
    MMR_CDbgNode0Eap2_F_CustomAction0_Data_muxed,
    MMR_CDbgNode0Eap2_F_EventType1_Data_muxed,
    MMR_CDbgNode0Eap2_F_EventType0_Data_muxed,
    MMR_CDbgNode0Eap2_F_LogicalOp_Data_muxed,
    MMR_CDbgNode0Eap2_F_Action1_Data_muxed,
    MMR_CDbgNode0Eap2_F_Action0_Data_muxed,
    MMR_CDbgNode0Eap2_F_DestNode_Data_muxed
};
assign MMR_CDbgNode0Eap3 = {
    MMR_CDbgNode0Eap3_F_Action3,
    MMR_CDbgNode0Eap3_F_Action2,
    MMR_CDbgNode0Eap3_F_Udf,
    MMR_CDbgNode0Eap3_F_EventType2,
    MMR_CDbgNode0Eap3_F_CustomAction1Enable,
    MMR_CDbgNode0Eap3_F_CustomAction0Enable,
    MMR_CDbgNode0Eap3_F_CustomAction1,
    MMR_CDbgNode0Eap3_F_CustomAction0,
    MMR_CDbgNode0Eap3_F_EventType1,
    MMR_CDbgNode0Eap3_F_EventType0,
    MMR_CDbgNode0Eap3_F_LogicalOp,
    MMR_CDbgNode0Eap3_F_Action1,
    MMR_CDbgNode0Eap3_F_Action0,
    MMR_CDbgNode0Eap3_F_DestNode
};
logic [63:0] MMR_CDbgNode0Eap3_muxed;
assign MMR_CDbgNode0Eap3_muxed = {
    MMR_CDbgNode0Eap3_F_Action3_Data_muxed,
    MMR_CDbgNode0Eap3_F_Action2_Data_muxed,
    MMR_CDbgNode0Eap3_F_Udf_Data_muxed,
    MMR_CDbgNode0Eap3_F_EventType2_Data_muxed,
    MMR_CDbgNode0Eap3_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode0Eap3_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode0Eap3_F_CustomAction1_Data_muxed,
    MMR_CDbgNode0Eap3_F_CustomAction0_Data_muxed,
    MMR_CDbgNode0Eap3_F_EventType1_Data_muxed,
    MMR_CDbgNode0Eap3_F_EventType0_Data_muxed,
    MMR_CDbgNode0Eap3_F_LogicalOp_Data_muxed,
    MMR_CDbgNode0Eap3_F_Action1_Data_muxed,
    MMR_CDbgNode0Eap3_F_Action0_Data_muxed,
    MMR_CDbgNode0Eap3_F_DestNode_Data_muxed
};
assign MMR_CDbgNode1Eap2 = {
    MMR_CDbgNode1Eap2_F_Action3,
    MMR_CDbgNode1Eap2_F_Action2,
    MMR_CDbgNode1Eap2_F_Udf,
    MMR_CDbgNode1Eap2_F_EventType2,
    MMR_CDbgNode1Eap2_F_CustomAction1Enable,
    MMR_CDbgNode1Eap2_F_CustomAction0Enable,
    MMR_CDbgNode1Eap2_F_CustomAction1,
    MMR_CDbgNode1Eap2_F_CustomAction0,
    MMR_CDbgNode1Eap2_F_EventType1,
    MMR_CDbgNode1Eap2_F_EventType0,
    MMR_CDbgNode1Eap2_F_LogicalOp,
    MMR_CDbgNode1Eap2_F_Action1,
    MMR_CDbgNode1Eap2_F_Action0,
    MMR_CDbgNode1Eap2_F_DestNode
};
logic [63:0] MMR_CDbgNode1Eap2_muxed;
assign MMR_CDbgNode1Eap2_muxed = {
    MMR_CDbgNode1Eap2_F_Action3_Data_muxed,
    MMR_CDbgNode1Eap2_F_Action2_Data_muxed,
    MMR_CDbgNode1Eap2_F_Udf_Data_muxed,
    MMR_CDbgNode1Eap2_F_EventType2_Data_muxed,
    MMR_CDbgNode1Eap2_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode1Eap2_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode1Eap2_F_CustomAction1_Data_muxed,
    MMR_CDbgNode1Eap2_F_CustomAction0_Data_muxed,
    MMR_CDbgNode1Eap2_F_EventType1_Data_muxed,
    MMR_CDbgNode1Eap2_F_EventType0_Data_muxed,
    MMR_CDbgNode1Eap2_F_LogicalOp_Data_muxed,
    MMR_CDbgNode1Eap2_F_Action1_Data_muxed,
    MMR_CDbgNode1Eap2_F_Action0_Data_muxed,
    MMR_CDbgNode1Eap2_F_DestNode_Data_muxed
};
assign MMR_CDbgNode1Eap3 = {
    MMR_CDbgNode1Eap3_F_Action3,
    MMR_CDbgNode1Eap3_F_Action2,
    MMR_CDbgNode1Eap3_F_Udf,
    MMR_CDbgNode1Eap3_F_EventType2,
    MMR_CDbgNode1Eap3_F_CustomAction1Enable,
    MMR_CDbgNode1Eap3_F_CustomAction0Enable,
    MMR_CDbgNode1Eap3_F_CustomAction1,
    MMR_CDbgNode1Eap3_F_CustomAction0,
    MMR_CDbgNode1Eap3_F_EventType1,
    MMR_CDbgNode1Eap3_F_EventType0,
    MMR_CDbgNode1Eap3_F_LogicalOp,
    MMR_CDbgNode1Eap3_F_Action1,
    MMR_CDbgNode1Eap3_F_Action0,
    MMR_CDbgNode1Eap3_F_DestNode
};
logic [63:0] MMR_CDbgNode1Eap3_muxed;
assign MMR_CDbgNode1Eap3_muxed = {
    MMR_CDbgNode1Eap3_F_Action3_Data_muxed,
    MMR_CDbgNode1Eap3_F_Action2_Data_muxed,
    MMR_CDbgNode1Eap3_F_Udf_Data_muxed,
    MMR_CDbgNode1Eap3_F_EventType2_Data_muxed,
    MMR_CDbgNode1Eap3_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode1Eap3_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode1Eap3_F_CustomAction1_Data_muxed,
    MMR_CDbgNode1Eap3_F_CustomAction0_Data_muxed,
    MMR_CDbgNode1Eap3_F_EventType1_Data_muxed,
    MMR_CDbgNode1Eap3_F_EventType0_Data_muxed,
    MMR_CDbgNode1Eap3_F_LogicalOp_Data_muxed,
    MMR_CDbgNode1Eap3_F_Action1_Data_muxed,
    MMR_CDbgNode1Eap3_F_Action0_Data_muxed,
    MMR_CDbgNode1Eap3_F_DestNode_Data_muxed
};
assign MMR_CDbgNode2Eap2 = {
    MMR_CDbgNode2Eap2_F_Action3,
    MMR_CDbgNode2Eap2_F_Action2,
    MMR_CDbgNode2Eap2_F_Udf,
    MMR_CDbgNode2Eap2_F_EventType2,
    MMR_CDbgNode2Eap2_F_CustomAction1Enable,
    MMR_CDbgNode2Eap2_F_CustomAction0Enable,
    MMR_CDbgNode2Eap2_F_CustomAction1,
    MMR_CDbgNode2Eap2_F_CustomAction0,
    MMR_CDbgNode2Eap2_F_EventType1,
    MMR_CDbgNode2Eap2_F_EventType0,
    MMR_CDbgNode2Eap2_F_LogicalOp,
    MMR_CDbgNode2Eap2_F_Action1,
    MMR_CDbgNode2Eap2_F_Action0,
    MMR_CDbgNode2Eap2_F_DestNode
};
logic [63:0] MMR_CDbgNode2Eap2_muxed;
assign MMR_CDbgNode2Eap2_muxed = {
    MMR_CDbgNode2Eap2_F_Action3_Data_muxed,
    MMR_CDbgNode2Eap2_F_Action2_Data_muxed,
    MMR_CDbgNode2Eap2_F_Udf_Data_muxed,
    MMR_CDbgNode2Eap2_F_EventType2_Data_muxed,
    MMR_CDbgNode2Eap2_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode2Eap2_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode2Eap2_F_CustomAction1_Data_muxed,
    MMR_CDbgNode2Eap2_F_CustomAction0_Data_muxed,
    MMR_CDbgNode2Eap2_F_EventType1_Data_muxed,
    MMR_CDbgNode2Eap2_F_EventType0_Data_muxed,
    MMR_CDbgNode2Eap2_F_LogicalOp_Data_muxed,
    MMR_CDbgNode2Eap2_F_Action1_Data_muxed,
    MMR_CDbgNode2Eap2_F_Action0_Data_muxed,
    MMR_CDbgNode2Eap2_F_DestNode_Data_muxed
};
assign MMR_CDbgNode2Eap3 = {
    MMR_CDbgNode2Eap3_F_Action3,
    MMR_CDbgNode2Eap3_F_Action2,
    MMR_CDbgNode2Eap3_F_Udf,
    MMR_CDbgNode2Eap3_F_EventType2,
    MMR_CDbgNode2Eap3_F_CustomAction1Enable,
    MMR_CDbgNode2Eap3_F_CustomAction0Enable,
    MMR_CDbgNode2Eap3_F_CustomAction1,
    MMR_CDbgNode2Eap3_F_CustomAction0,
    MMR_CDbgNode2Eap3_F_EventType1,
    MMR_CDbgNode2Eap3_F_EventType0,
    MMR_CDbgNode2Eap3_F_LogicalOp,
    MMR_CDbgNode2Eap3_F_Action1,
    MMR_CDbgNode2Eap3_F_Action0,
    MMR_CDbgNode2Eap3_F_DestNode
};
logic [63:0] MMR_CDbgNode2Eap3_muxed;
assign MMR_CDbgNode2Eap3_muxed = {
    MMR_CDbgNode2Eap3_F_Action3_Data_muxed,
    MMR_CDbgNode2Eap3_F_Action2_Data_muxed,
    MMR_CDbgNode2Eap3_F_Udf_Data_muxed,
    MMR_CDbgNode2Eap3_F_EventType2_Data_muxed,
    MMR_CDbgNode2Eap3_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode2Eap3_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode2Eap3_F_CustomAction1_Data_muxed,
    MMR_CDbgNode2Eap3_F_CustomAction0_Data_muxed,
    MMR_CDbgNode2Eap3_F_EventType1_Data_muxed,
    MMR_CDbgNode2Eap3_F_EventType0_Data_muxed,
    MMR_CDbgNode2Eap3_F_LogicalOp_Data_muxed,
    MMR_CDbgNode2Eap3_F_Action1_Data_muxed,
    MMR_CDbgNode2Eap3_F_Action0_Data_muxed,
    MMR_CDbgNode2Eap3_F_DestNode_Data_muxed
};
assign MMR_CDbgNode3Eap2 = {
    MMR_CDbgNode3Eap2_F_Action3,
    MMR_CDbgNode3Eap2_F_Action2,
    MMR_CDbgNode3Eap2_F_Udf,
    MMR_CDbgNode3Eap2_F_EventType2,
    MMR_CDbgNode3Eap2_F_CustomAction1Enable,
    MMR_CDbgNode3Eap2_F_CustomAction0Enable,
    MMR_CDbgNode3Eap2_F_CustomAction1,
    MMR_CDbgNode3Eap2_F_CustomAction0,
    MMR_CDbgNode3Eap2_F_EventType1,
    MMR_CDbgNode3Eap2_F_EventType0,
    MMR_CDbgNode3Eap2_F_LogicalOp,
    MMR_CDbgNode3Eap2_F_Action1,
    MMR_CDbgNode3Eap2_F_Action0,
    MMR_CDbgNode3Eap2_F_DestNode
};
logic [63:0] MMR_CDbgNode3Eap2_muxed;
assign MMR_CDbgNode3Eap2_muxed = {
    MMR_CDbgNode3Eap2_F_Action3_Data_muxed,
    MMR_CDbgNode3Eap2_F_Action2_Data_muxed,
    MMR_CDbgNode3Eap2_F_Udf_Data_muxed,
    MMR_CDbgNode3Eap2_F_EventType2_Data_muxed,
    MMR_CDbgNode3Eap2_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode3Eap2_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode3Eap2_F_CustomAction1_Data_muxed,
    MMR_CDbgNode3Eap2_F_CustomAction0_Data_muxed,
    MMR_CDbgNode3Eap2_F_EventType1_Data_muxed,
    MMR_CDbgNode3Eap2_F_EventType0_Data_muxed,
    MMR_CDbgNode3Eap2_F_LogicalOp_Data_muxed,
    MMR_CDbgNode3Eap2_F_Action1_Data_muxed,
    MMR_CDbgNode3Eap2_F_Action0_Data_muxed,
    MMR_CDbgNode3Eap2_F_DestNode_Data_muxed
};
assign MMR_CDbgNode3Eap3 = {
    MMR_CDbgNode3Eap3_F_Action3,
    MMR_CDbgNode3Eap3_F_Action2,
    MMR_CDbgNode3Eap3_F_Udf,
    MMR_CDbgNode3Eap3_F_EventType2,
    MMR_CDbgNode3Eap3_F_CustomAction1Enable,
    MMR_CDbgNode3Eap3_F_CustomAction0Enable,
    MMR_CDbgNode3Eap3_F_CustomAction1,
    MMR_CDbgNode3Eap3_F_CustomAction0,
    MMR_CDbgNode3Eap3_F_EventType1,
    MMR_CDbgNode3Eap3_F_EventType0,
    MMR_CDbgNode3Eap3_F_LogicalOp,
    MMR_CDbgNode3Eap3_F_Action1,
    MMR_CDbgNode3Eap3_F_Action0,
    MMR_CDbgNode3Eap3_F_DestNode
};
logic [63:0] MMR_CDbgNode3Eap3_muxed;
assign MMR_CDbgNode3Eap3_muxed = {
    MMR_CDbgNode3Eap3_F_Action3_Data_muxed,
    MMR_CDbgNode3Eap3_F_Action2_Data_muxed,
    MMR_CDbgNode3Eap3_F_Udf_Data_muxed,
    MMR_CDbgNode3Eap3_F_EventType2_Data_muxed,
    MMR_CDbgNode3Eap3_F_CustomAction1Enable_Data_muxed,
    MMR_CDbgNode3Eap3_F_CustomAction0Enable_Data_muxed,
    MMR_CDbgNode3Eap3_F_CustomAction1_Data_muxed,
    MMR_CDbgNode3Eap3_F_CustomAction0_Data_muxed,
    MMR_CDbgNode3Eap3_F_EventType1_Data_muxed,
    MMR_CDbgNode3Eap3_F_EventType0_Data_muxed,
    MMR_CDbgNode3Eap3_F_LogicalOp_Data_muxed,
    MMR_CDbgNode3Eap3_F_Action1_Data_muxed,
    MMR_CDbgNode3Eap3_F_Action0_Data_muxed,
    MMR_CDbgNode3Eap3_F_DestNode_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap2Lo = {
    MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap2Lo_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap2Lo_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap3Lo = {
    MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap3Lo_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap3Lo_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap2Lo = {
    MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap2Lo_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap2Lo_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap3Lo = {
    MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap3Lo_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap3Lo_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap2Lo = {
    MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap2Lo_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap2Lo_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap3Lo = {
    MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap3Lo_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap3Lo_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap2Lo = {
    MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap2Lo_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap2Lo_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap3Lo = {
    MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap3Lo_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap3Lo_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value_Data_muxed
};
assign MMR_CDbgSignalDelayMuxSel = {
    MMR_CDbgSignalDelayMuxSel_F_Rsvd,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg15,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg14,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg13,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg12,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg11,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg10,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg9,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg8,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg7,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg6,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg5,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg4,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg3,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg2,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg1,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg0
};
logic [63:0] MMR_CDbgSignalDelayMuxSel_muxed;
assign MMR_CDbgSignalDelayMuxSel_muxed = {
    MMR_CDbgSignalDelayMuxSel_F_Rsvd_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg15_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg14_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg13_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg12_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg11_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg10_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg9_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg8_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg7_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg6_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg5_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg4_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg3_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg2_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg1_Data_muxed,
    MMR_CDbgSignalDelayMuxSel_F_Muxselseg0_Data_muxed
};
assign MMR_CDbgClaXtriggerTimestretch = {
    MMR_CDbgClaXtriggerTimestretch_F_Rsvd,
    MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch,
    MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch
};
logic [63:0] MMR_CDbgClaXtriggerTimestretch_muxed;
assign MMR_CDbgClaXtriggerTimestretch_muxed = {
    MMR_CDbgClaXtriggerTimestretch_F_Rsvd_Data_muxed,
    MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch_Data_muxed,
    MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch_Data_muxed
};
assign MMR_CDbgClaTimestamp = {
    MMR_CDbgClaTimestamp_F_TimestampUpper,
    MMR_CDbgClaTimestamp_F_TimestampLower
};
logic [63:0] MMR_CDbgClaTimestamp_muxed;
assign MMR_CDbgClaTimestamp_muxed = {
    MMR_CDbgClaTimestamp_F_TimestampUpper_Data_muxed,
    MMR_CDbgClaTimestamp_F_TimestampLower_Data_muxed
};
assign MMR_CDbgClaTimestampSync = {
    MMR_CDbgClaTimestampSync_F_TimestampSync
};
logic [63:0] MMR_CDbgClaTimestampSync_muxed;
assign MMR_CDbgClaTimestampSync_muxed = {
    MMR_CDbgClaTimestampSync_F_TimestampSync_Data_muxed
};
assign MMR_CDbgClaTimestampConfig = {
    MMR_CDbgClaTimestampConfig_F_Rsvd1,
    MMR_CDbgClaTimestampConfig_F_TsCapture,
    MMR_CDbgClaTimestampConfig_F_DebugMarker,
    MMR_CDbgClaTimestampConfig_F_Resync
};
logic [63:0] MMR_CDbgClaTimestampConfig_muxed;
assign MMR_CDbgClaTimestampConfig_muxed = {
    MMR_CDbgClaTimestampConfig_F_Rsvd1_Data_muxed,
    MMR_CDbgClaTimestampConfig_F_TsCapture_Data_muxed,
    MMR_CDbgClaTimestampConfig_F_DebugMarker_Data_muxed,
    MMR_CDbgClaTimestampConfig_F_Resync_Data_muxed
};
assign MMR_CDbgClaTimestampOffset = {
    MMR_CDbgClaTimestampOffset_F_Rsvd0,
    MMR_CDbgClaTimestampOffset_F_Offset
};
logic [63:0] MMR_CDbgClaTimestampOffset_muxed;
assign MMR_CDbgClaTimestampOffset_muxed = {
    MMR_CDbgClaTimestampOffset_F_Rsvd0_Data_muxed,
    MMR_CDbgClaTimestampOffset_F_Offset_Data_muxed
};
assign MMR_CDbgSignalMask0Hi = {
    MMR_CDbgSignalMask0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMask0Hi_muxed;
assign MMR_CDbgSignalMask0Hi_muxed = {
    MMR_CDbgSignalMask0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch0Hi = {
    MMR_CDbgSignalMatch0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMatch0Hi_muxed;
assign MMR_CDbgSignalMatch0Hi_muxed = {
    MMR_CDbgSignalMatch0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMask1Hi = {
    MMR_CDbgSignalMask1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMask1Hi_muxed;
assign MMR_CDbgSignalMask1Hi_muxed = {
    MMR_CDbgSignalMask1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch1Hi = {
    MMR_CDbgSignalMatch1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMatch1Hi_muxed;
assign MMR_CDbgSignalMatch1Hi_muxed = {
    MMR_CDbgSignalMatch1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMask2Hi = {
    MMR_CDbgSignalMask2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMask2Hi_muxed;
assign MMR_CDbgSignalMask2Hi_muxed = {
    MMR_CDbgSignalMask2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch2Hi = {
    MMR_CDbgSignalMatch2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMatch2Hi_muxed;
assign MMR_CDbgSignalMatch2Hi_muxed = {
    MMR_CDbgSignalMatch2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMask3Hi = {
    MMR_CDbgSignalMask3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMask3Hi_muxed;
assign MMR_CDbgSignalMask3Hi_muxed = {
    MMR_CDbgSignalMask3Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalMatch3Hi = {
    MMR_CDbgSignalMatch3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalMatch3Hi_muxed;
assign MMR_CDbgSignalMatch3Hi_muxed = {
    MMR_CDbgSignalMatch3Hi_F_Value_Data_muxed
};
assign MMR_CDbgMuxSelHi = {
    MMR_CDbgMuxSelHi_F_Muxselseg15,
    MMR_CDbgMuxSelHi_F_Muxselseg14,
    MMR_CDbgMuxSelHi_F_Muxselseg13,
    MMR_CDbgMuxSelHi_F_Muxselseg12,
    MMR_CDbgMuxSelHi_F_Muxselseg11,
    MMR_CDbgMuxSelHi_F_Muxselseg10,
    MMR_CDbgMuxSelHi_F_Muxselseg9,
    MMR_CDbgMuxSelHi_F_Muxselseg8,
    MMR_CDbgMuxSelHi_F_Rsvd150
};
logic [63:0] MMR_CDbgMuxSelHi_muxed;
assign MMR_CDbgMuxSelHi_muxed = {
    MMR_CDbgMuxSelHi_F_Muxselseg15_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg14_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg13_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg12_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg11_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg10_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg9_Data_muxed,
    MMR_CDbgMuxSelHi_F_Muxselseg8_Data_muxed,
    MMR_CDbgMuxSelHi_F_Rsvd150_Data_muxed
};
assign MMR_CDbgTransitionMaskHi = {
    MMR_CDbgTransitionMaskHi_F_Value
};
logic [63:0] MMR_CDbgTransitionMaskHi_muxed;
assign MMR_CDbgTransitionMaskHi_muxed = {
    MMR_CDbgTransitionMaskHi_F_Value_Data_muxed
};
assign MMR_CDbgTransitionFromValueHi = {
    MMR_CDbgTransitionFromValueHi_F_Value
};
logic [63:0] MMR_CDbgTransitionFromValueHi_muxed;
assign MMR_CDbgTransitionFromValueHi_muxed = {
    MMR_CDbgTransitionFromValueHi_F_Value_Data_muxed
};
assign MMR_CDbgTransitionToValueHi = {
    MMR_CDbgTransitionToValueHi_F_Value
};
logic [63:0] MMR_CDbgTransitionToValueHi_muxed;
assign MMR_CDbgTransitionToValueHi_muxed = {
    MMR_CDbgTransitionToValueHi_F_Value_Data_muxed
};
assign MMR_CDbgOnesCountMaskHi = {
    MMR_CDbgOnesCountMaskHi_F_Value
};
logic [63:0] MMR_CDbgOnesCountMaskHi_muxed;
assign MMR_CDbgOnesCountMaskHi_muxed = {
    MMR_CDbgOnesCountMaskHi_F_Value_Data_muxed
};
assign MMR_CDbgAnyChangeHi = {
    MMR_CDbgAnyChangeHi_F_Mask
};
logic [63:0] MMR_CDbgAnyChangeHi_muxed;
assign MMR_CDbgAnyChangeHi_muxed = {
    MMR_CDbgAnyChangeHi_F_Mask_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap0Hi = {
    MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap0Hi_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap0Hi_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap1Hi = {
    MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap1Hi_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap1Hi_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap0Hi = {
    MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap0Hi_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap0Hi_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap1Hi = {
    MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap1Hi_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap1Hi_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap0Hi = {
    MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap0Hi_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap0Hi_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap1Hi = {
    MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap1Hi_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap1Hi_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap0Hi = {
    MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap0Hi_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap0Hi_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap1Hi = {
    MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap1Hi_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap1Hi_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap2Hi = {
    MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap2Hi_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap2Hi_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode0Eap3Hi = {
    MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode0Eap3Hi_muxed;
assign MMR_CDbgSignalSnapshotNode0Eap3Hi_muxed = {
    MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap2Hi = {
    MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap2Hi_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap2Hi_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode1Eap3Hi = {
    MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode1Eap3Hi_muxed;
assign MMR_CDbgSignalSnapshotNode1Eap3Hi_muxed = {
    MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap2Hi = {
    MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap2Hi_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap2Hi_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode2Eap3Hi = {
    MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode2Eap3Hi_muxed;
assign MMR_CDbgSignalSnapshotNode2Eap3Hi_muxed = {
    MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap2Hi = {
    MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap2Hi_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap2Hi_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value_Data_muxed
};
assign MMR_CDbgSignalSnapshotNode3Eap3Hi = {
    MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value
};
logic [63:0] MMR_CDbgSignalSnapshotNode3Eap3Hi_muxed;
assign MMR_CDbgSignalSnapshotNode3Eap3Hi_muxed = {
    MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value_Data_muxed
};
assign MMR_CDbgLfsr = {
    MMR_CDbgLfsr_F_Lfsr,
    MMR_CDbgLfsr_F_LfsrActive
};
logic [63:0] MMR_CDbgLfsr_muxed;
assign MMR_CDbgLfsr_muxed = {
    MMR_CDbgLfsr_F_Lfsr_Data_muxed,
    MMR_CDbgLfsr_F_LfsrActive_Data_muxed
};
assign MMR_CDbgLfsrMask = {
    MMR_CDbgLfsrMask_F_Mask,
    MMR_CDbgLfsrMask_F_Rsvd0
};
logic [63:0] MMR_CDbgLfsrMask_muxed;
assign MMR_CDbgLfsrMask_muxed = {
    MMR_CDbgLfsrMask_F_Mask_Data_muxed,
    MMR_CDbgLfsrMask_F_Rsvd0_Data_muxed
};
assign MMR_CDbgTimestampCapture = {
    MMR_CDbgTimestampCapture_F_Timestamp
};
logic [63:0] MMR_CDbgTimestampCapture_muxed;
assign MMR_CDbgTimestampCapture_muxed = {
    MMR_CDbgTimestampCapture_F_Timestamp_Data_muxed
};
assign MMR_CDbgCompare0Lo = {
    MMR_CDbgCompare0Lo_F_Value
};
logic [63:0] MMR_CDbgCompare0Lo_muxed;
assign MMR_CDbgCompare0Lo_muxed = {
    MMR_CDbgCompare0Lo_F_Value_Data_muxed
};
assign MMR_CDbgCompare0MaskLo = {
    MMR_CDbgCompare0MaskLo_F_Value
};
logic [63:0] MMR_CDbgCompare0MaskLo_muxed;
assign MMR_CDbgCompare0MaskLo_muxed = {
    MMR_CDbgCompare0MaskLo_F_Value_Data_muxed
};
assign MMR_CDbgCompare1Lo = {
    MMR_CDbgCompare1Lo_F_Value
};
logic [63:0] MMR_CDbgCompare1Lo_muxed;
assign MMR_CDbgCompare1Lo_muxed = {
    MMR_CDbgCompare1Lo_F_Value_Data_muxed
};
assign MMR_CDbgCompare1MaskLo = {
    MMR_CDbgCompare1MaskLo_F_Value
};
logic [63:0] MMR_CDbgCompare1MaskLo_muxed;
assign MMR_CDbgCompare1MaskLo_muxed = {
    MMR_CDbgCompare1MaskLo_F_Value_Data_muxed
};
assign MMR_CDbgCompare2Lo = {
    MMR_CDbgCompare2Lo_F_Value
};
logic [63:0] MMR_CDbgCompare2Lo_muxed;
assign MMR_CDbgCompare2Lo_muxed = {
    MMR_CDbgCompare2Lo_F_Value_Data_muxed
};
assign MMR_CDbgCompare2MaskLo = {
    MMR_CDbgCompare2MaskLo_F_Value
};
logic [63:0] MMR_CDbgCompare2MaskLo_muxed;
assign MMR_CDbgCompare2MaskLo_muxed = {
    MMR_CDbgCompare2MaskLo_F_Value_Data_muxed
};
assign MMR_CDbgCompare3Lo = {
    MMR_CDbgCompare3Lo_F_Value
};
logic [63:0] MMR_CDbgCompare3Lo_muxed;
assign MMR_CDbgCompare3Lo_muxed = {
    MMR_CDbgCompare3Lo_F_Value_Data_muxed
};
assign MMR_CDbgCompare3MaskLo = {
    MMR_CDbgCompare3MaskLo_F_Value
};
logic [63:0] MMR_CDbgCompare3MaskLo_muxed;
assign MMR_CDbgCompare3MaskLo_muxed = {
    MMR_CDbgCompare3MaskLo_F_Value_Data_muxed
};
assign MMR_CDbgCompare0Hi = {
    MMR_CDbgCompare0Hi_F_Value
};
logic [63:0] MMR_CDbgCompare0Hi_muxed;
assign MMR_CDbgCompare0Hi_muxed = {
    MMR_CDbgCompare0Hi_F_Value_Data_muxed
};
assign MMR_CDbgCompare0MaskHi = {
    MMR_CDbgCompare0MaskHi_F_Value
};
logic [63:0] MMR_CDbgCompare0MaskHi_muxed;
assign MMR_CDbgCompare0MaskHi_muxed = {
    MMR_CDbgCompare0MaskHi_F_Value_Data_muxed
};
assign MMR_CDbgCompare1Hi = {
    MMR_CDbgCompare1Hi_F_Value
};
logic [63:0] MMR_CDbgCompare1Hi_muxed;
assign MMR_CDbgCompare1Hi_muxed = {
    MMR_CDbgCompare1Hi_F_Value_Data_muxed
};
assign MMR_CDbgCompare1MaskHi = {
    MMR_CDbgCompare1MaskHi_F_Value
};
logic [63:0] MMR_CDbgCompare1MaskHi_muxed;
assign MMR_CDbgCompare1MaskHi_muxed = {
    MMR_CDbgCompare1MaskHi_F_Value_Data_muxed
};
assign MMR_CDbgCompare2Hi = {
    MMR_CDbgCompare2Hi_F_Value
};
logic [63:0] MMR_CDbgCompare2Hi_muxed;
assign MMR_CDbgCompare2Hi_muxed = {
    MMR_CDbgCompare2Hi_F_Value_Data_muxed
};
assign MMR_CDbgCompare2MaskHi = {
    MMR_CDbgCompare2MaskHi_F_Value
};
logic [63:0] MMR_CDbgCompare2MaskHi_muxed;
assign MMR_CDbgCompare2MaskHi_muxed = {
    MMR_CDbgCompare2MaskHi_F_Value_Data_muxed
};
assign MMR_CDbgCompare3Hi = {
    MMR_CDbgCompare3Hi_F_Value
};
logic [63:0] MMR_CDbgCompare3Hi_muxed;
assign MMR_CDbgCompare3Hi_muxed = {
    MMR_CDbgCompare3Hi_F_Value_Data_muxed
};
assign MMR_CDbgCompare3MaskHi = {
    MMR_CDbgCompare3MaskHi_F_Value
};
logic [63:0] MMR_CDbgCompare3MaskHi_muxed;
assign MMR_CDbgCompare3MaskHi_muxed = {
    MMR_CDbgCompare3MaskHi_F_Value_Data_muxed
};
assign MMR_CDbgVersion = {
    MMR_CDbgVersion_F_Rsvd6312,
    MMR_CDbgVersion_F_Major,
    MMR_CDbgVersion_F_Minor,
    MMR_CDbgVersion_F_Patch
};
logic [63:0] MMR_CDbgVersion_muxed;
assign MMR_CDbgVersion_muxed = {
    MMR_CDbgVersion_F_Rsvd6312,
    MMR_CDbgVersion_F_Major,
    MMR_CDbgVersion_F_Minor,
    MMR_CDbgVersion_F_Patch
};
assign MMR_Scratch = {
    MMR_Scratch_F_Data
};
logic [63:0] MMR_Scratch_muxed;
assign MMR_Scratch_muxed = {
    MMR_Scratch_F_Data_Data_muxed
};

always_comb begin : mmr_rd_comb
    reg_prehit  = '0;
    reg_rd_data = '0;
    unique case (reg_addr)
        ADDR_MMR_CDBGCLACOUNTER0CFG             : begin : mmr_rd_hit_MMR_CDbgClaCounter0Cfg reg_prehit.ClaMmrCdbgclacounter0CfgHit = 1'b1; reg_rd_data = {MMR_CDbgClaCounter0Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER1CFG             : begin : mmr_rd_hit_MMR_CDbgClaCounter1Cfg reg_prehit.ClaMmrCdbgclacounter1CfgHit = 1'b1; reg_rd_data = {MMR_CDbgClaCounter1Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER2CFG             : begin : mmr_rd_hit_MMR_CDbgClaCounter2Cfg reg_prehit.ClaMmrCdbgclacounter2CfgHit = 1'b1; reg_rd_data = {MMR_CDbgClaCounter2Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER3CFG             : begin : mmr_rd_hit_MMR_CDbgClaCounter3Cfg reg_prehit.ClaMmrCdbgclacounter3CfgHit = 1'b1; reg_rd_data = {MMR_CDbgClaCounter3Cfg}; end
        ADDR_MMR_CDBGNODE0EAP0                  : begin : mmr_rd_hit_MMR_CDbgNode0Eap0 reg_prehit.ClaMmrCdbgnode0Eap0Hit = 1'b1; reg_rd_data = {MMR_CDbgNode0Eap0}; end
        ADDR_MMR_CDBGNODE0EAP1                  : begin : mmr_rd_hit_MMR_CDbgNode0Eap1 reg_prehit.ClaMmrCdbgnode0Eap1Hit = 1'b1; reg_rd_data = {MMR_CDbgNode0Eap1}; end
        ADDR_MMR_CDBGNODE1EAP0                  : begin : mmr_rd_hit_MMR_CDbgNode1Eap0 reg_prehit.ClaMmrCdbgnode1Eap0Hit = 1'b1; reg_rd_data = {MMR_CDbgNode1Eap0}; end
        ADDR_MMR_CDBGNODE1EAP1                  : begin : mmr_rd_hit_MMR_CDbgNode1Eap1 reg_prehit.ClaMmrCdbgnode1Eap1Hit = 1'b1; reg_rd_data = {MMR_CDbgNode1Eap1}; end
        ADDR_MMR_CDBGNODE2EAP0                  : begin : mmr_rd_hit_MMR_CDbgNode2Eap0 reg_prehit.ClaMmrCdbgnode2Eap0Hit = 1'b1; reg_rd_data = {MMR_CDbgNode2Eap0}; end
        ADDR_MMR_CDBGNODE2EAP1                  : begin : mmr_rd_hit_MMR_CDbgNode2Eap1 reg_prehit.ClaMmrCdbgnode2Eap1Hit = 1'b1; reg_rd_data = {MMR_CDbgNode2Eap1}; end
        ADDR_MMR_CDBGNODE3EAP0                  : begin : mmr_rd_hit_MMR_CDbgNode3Eap0 reg_prehit.ClaMmrCdbgnode3Eap0Hit = 1'b1; reg_rd_data = {MMR_CDbgNode3Eap0}; end
        ADDR_MMR_CDBGNODE3EAP1                  : begin : mmr_rd_hit_MMR_CDbgNode3Eap1 reg_prehit.ClaMmrCdbgnode3Eap1Hit = 1'b1; reg_rd_data = {MMR_CDbgNode3Eap1}; end
        ADDR_MMR_CDBGSIGNALMASK0LO              : begin : mmr_rd_hit_MMR_CDbgSignalMask0Lo reg_prehit.ClaMmrCdbgsignalmask0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask0Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH0LO             : begin : mmr_rd_hit_MMR_CDbgSignalMatch0Lo reg_prehit.ClaMmrCdbgsignalmatch0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch0Lo}; end
        ADDR_MMR_CDBGSIGNALMASK1LO              : begin : mmr_rd_hit_MMR_CDbgSignalMask1Lo reg_prehit.ClaMmrCdbgsignalmask1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask1Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH1LO             : begin : mmr_rd_hit_MMR_CDbgSignalMatch1Lo reg_prehit.ClaMmrCdbgsignalmatch1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch1Lo}; end
        ADDR_MMR_CDBGSIGNALEDGEDETECTCFG        : begin : mmr_rd_hit_MMR_CDbgSignalEdgeDetectCfg reg_prehit.ClaMmrCdbgsignaledgedetectcfgHit = 1'b1; reg_rd_data = {MMR_CDbgSignalEdgeDetectCfg}; end
        ADDR_MMR_CDBGEAPSTATUS                  : begin : mmr_rd_hit_MMR_CDbgEapStatus reg_prehit.ClaMmrCdbgeapstatusHit = 1'b1; reg_rd_data = {MMR_CDbgEapStatus}; end
        ADDR_MMR_CDBGCLACTRLSTATUS              : begin : mmr_rd_hit_MMR_CDbgClaCtrlStatus reg_prehit.ClaMmrCdbgclactrlstatusHit = 1'b1; reg_rd_data = {MMR_CDbgClaCtrlStatus}; end
        ADDR_MMR_CDBGMUXSELLO                   : begin : mmr_rd_hit_MMR_CDbgMuxSelLo reg_prehit.ClaMmrCdbgmuxselloHit = 1'b1; reg_rd_data = {MMR_CDbgMuxSelLo}; end
        ADDR_MMR_CDBGRSVD1                      : begin : mmr_rd_hit_MMR_CDbgRsvd1 reg_prehit.ClaMmrCdbgrsvd1Hit = 1'b1; reg_rd_data = {MMR_CDbgRsvd1}; end
        ADDR_MMR_CDBGRSVD2                      : begin : mmr_rd_hit_MMR_CDbgRsvd2 reg_prehit.ClaMmrCdbgrsvd2Hit = 1'b1; reg_rd_data = {MMR_CDbgRsvd2}; end
        ADDR_MMR_CDBGTRANSITIONMASKLO           : begin : mmr_rd_hit_MMR_CDbgTransitionMaskLo reg_prehit.ClaMmrCdbgtransitionmaskloHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionMaskLo}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUELO      : begin : mmr_rd_hit_MMR_CDbgTransitionFromValueLo reg_prehit.ClaMmrCdbgtransitionfromvalueloHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionFromValueLo}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUELO        : begin : mmr_rd_hit_MMR_CDbgTransitionToValueLo reg_prehit.ClaMmrCdbgtransitiontovalueloHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionToValueLo}; end
        ADDR_MMR_CDBGONESCOUNTMASKLO            : begin : mmr_rd_hit_MMR_CDbgOnesCountMaskLo reg_prehit.ClaMmrCdbgonescountmaskloHit = 1'b1; reg_rd_data = {MMR_CDbgOnesCountMaskLo}; end
        ADDR_MMR_CDBGONESCOUNTVALUE             : begin : mmr_rd_hit_MMR_CDbgOnesCountValue reg_prehit.ClaMmrCdbgonescountvalueHit = 1'b1; reg_rd_data = {MMR_CDbgOnesCountValue}; end
        ADDR_MMR_CDBGANYCHANGELO                : begin : mmr_rd_hit_MMR_CDbgAnyChangeLo reg_prehit.ClaMmrCdbganychangeloHit = 1'b1; reg_rd_data = {MMR_CDbgAnyChangeLo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap0Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap1Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap0Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap1Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap0Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap1Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap0Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap0LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap1Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap1LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap1Lo}; end
        ADDR_MMR_CDBGCLATIMEMATCH               : begin : mmr_rd_hit_MMR_CDbgClaTimeMatch reg_prehit.ClaMmrCdbgclatimematchHit = 1'b1; reg_rd_data = {MMR_CDbgClaTimeMatch}; end
        ADDR_MMR_CDBGSIGNALMASK2LO              : begin : mmr_rd_hit_MMR_CDbgSignalMask2Lo reg_prehit.ClaMmrCdbgsignalmask2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask2Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH2LO             : begin : mmr_rd_hit_MMR_CDbgSignalMatch2Lo reg_prehit.ClaMmrCdbgsignalmatch2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch2Lo}; end
        ADDR_MMR_CDBGSIGNALMASK3LO              : begin : mmr_rd_hit_MMR_CDbgSignalMask3Lo reg_prehit.ClaMmrCdbgsignalmask3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask3Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH3LO             : begin : mmr_rd_hit_MMR_CDbgSignalMatch3Lo reg_prehit.ClaMmrCdbgsignalmatch3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch3Lo}; end
        ADDR_MMR_CDBGNODE0EAP2                  : begin : mmr_rd_hit_MMR_CDbgNode0Eap2 reg_prehit.ClaMmrCdbgnode0Eap2Hit = 1'b1; reg_rd_data = {MMR_CDbgNode0Eap2}; end
        ADDR_MMR_CDBGNODE0EAP3                  : begin : mmr_rd_hit_MMR_CDbgNode0Eap3 reg_prehit.ClaMmrCdbgnode0Eap3Hit = 1'b1; reg_rd_data = {MMR_CDbgNode0Eap3}; end
        ADDR_MMR_CDBGNODE1EAP2                  : begin : mmr_rd_hit_MMR_CDbgNode1Eap2 reg_prehit.ClaMmrCdbgnode1Eap2Hit = 1'b1; reg_rd_data = {MMR_CDbgNode1Eap2}; end
        ADDR_MMR_CDBGNODE1EAP3                  : begin : mmr_rd_hit_MMR_CDbgNode1Eap3 reg_prehit.ClaMmrCdbgnode1Eap3Hit = 1'b1; reg_rd_data = {MMR_CDbgNode1Eap3}; end
        ADDR_MMR_CDBGNODE2EAP2                  : begin : mmr_rd_hit_MMR_CDbgNode2Eap2 reg_prehit.ClaMmrCdbgnode2Eap2Hit = 1'b1; reg_rd_data = {MMR_CDbgNode2Eap2}; end
        ADDR_MMR_CDBGNODE2EAP3                  : begin : mmr_rd_hit_MMR_CDbgNode2Eap3 reg_prehit.ClaMmrCdbgnode2Eap3Hit = 1'b1; reg_rd_data = {MMR_CDbgNode2Eap3}; end
        ADDR_MMR_CDBGNODE3EAP2                  : begin : mmr_rd_hit_MMR_CDbgNode3Eap2 reg_prehit.ClaMmrCdbgnode3Eap2Hit = 1'b1; reg_rd_data = {MMR_CDbgNode3Eap2}; end
        ADDR_MMR_CDBGNODE3EAP3                  : begin : mmr_rd_hit_MMR_CDbgNode3Eap3 reg_prehit.ClaMmrCdbgnode3Eap3Hit = 1'b1; reg_rd_data = {MMR_CDbgNode3Eap3}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap2Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap3Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap2Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap3Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap2Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap3Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap2Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap2LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap3Lo reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap3LoHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALDELAYMUXSEL          : begin : mmr_rd_hit_MMR_CDbgSignalDelayMuxSel reg_prehit.ClaMmrCdbgsignaldelaymuxselHit = 1'b1; reg_rd_data = {MMR_CDbgSignalDelayMuxSel}; end
        ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH     : begin : mmr_rd_hit_MMR_CDbgClaXtriggerTimestretch reg_prehit.ClaMmrCdbgclaxtriggertimestretchHit = 1'b1; reg_rd_data = {MMR_CDbgClaXtriggerTimestretch}; end
        ADDR_MMR_CDBGCLATIMESTAMP               : begin : mmr_rd_hit_MMR_CDbgClaTimestamp reg_prehit.ClaMmrCdbgclatimestampHit = 1'b1; reg_rd_data = {MMR_CDbgClaTimestamp}; end
        ADDR_MMR_CDBGCLATIMESTAMPSYNC           : begin : mmr_rd_hit_MMR_CDbgClaTimestampSync reg_prehit.ClaMmrCdbgclatimestampsyncHit = 1'b1; reg_rd_data = {MMR_CDbgClaTimestampSync}; end
        ADDR_MMR_CDBGCLATIMESTAMPCONFIG         : begin : mmr_rd_hit_MMR_CDbgClaTimestampConfig reg_prehit.ClaMmrCdbgclatimestampconfigHit = 1'b1; reg_rd_data = {MMR_CDbgClaTimestampConfig}; end
        ADDR_MMR_CDBGCLATIMESTAMPOFFSET         : begin : mmr_rd_hit_MMR_CDbgClaTimestampOffset reg_prehit.ClaMmrCdbgclatimestampoffsetHit = 1'b1; reg_rd_data = {MMR_CDbgClaTimestampOffset}; end
        ADDR_MMR_CDBGSIGNALMASK0HI              : begin : mmr_rd_hit_MMR_CDbgSignalMask0Hi reg_prehit.ClaMmrCdbgsignalmask0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask0Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH0HI             : begin : mmr_rd_hit_MMR_CDbgSignalMatch0Hi reg_prehit.ClaMmrCdbgsignalmatch0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch0Hi}; end
        ADDR_MMR_CDBGSIGNALMASK1HI              : begin : mmr_rd_hit_MMR_CDbgSignalMask1Hi reg_prehit.ClaMmrCdbgsignalmask1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask1Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH1HI             : begin : mmr_rd_hit_MMR_CDbgSignalMatch1Hi reg_prehit.ClaMmrCdbgsignalmatch1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch1Hi}; end
        ADDR_MMR_CDBGSIGNALMASK2HI              : begin : mmr_rd_hit_MMR_CDbgSignalMask2Hi reg_prehit.ClaMmrCdbgsignalmask2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask2Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH2HI             : begin : mmr_rd_hit_MMR_CDbgSignalMatch2Hi reg_prehit.ClaMmrCdbgsignalmatch2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch2Hi}; end
        ADDR_MMR_CDBGSIGNALMASK3HI              : begin : mmr_rd_hit_MMR_CDbgSignalMask3Hi reg_prehit.ClaMmrCdbgsignalmask3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMask3Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH3HI             : begin : mmr_rd_hit_MMR_CDbgSignalMatch3Hi reg_prehit.ClaMmrCdbgsignalmatch3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalMatch3Hi}; end
        ADDR_MMR_CDBGMUXSELHI                   : begin : mmr_rd_hit_MMR_CDbgMuxSelHi reg_prehit.ClaMmrCdbgmuxselhiHit = 1'b1; reg_rd_data = {MMR_CDbgMuxSelHi}; end
        ADDR_MMR_CDBGTRANSITIONMASKHI           : begin : mmr_rd_hit_MMR_CDbgTransitionMaskHi reg_prehit.ClaMmrCdbgtransitionmaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionMaskHi}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUEHI      : begin : mmr_rd_hit_MMR_CDbgTransitionFromValueHi reg_prehit.ClaMmrCdbgtransitionfromvaluehiHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionFromValueHi}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUEHI        : begin : mmr_rd_hit_MMR_CDbgTransitionToValueHi reg_prehit.ClaMmrCdbgtransitiontovaluehiHit = 1'b1; reg_rd_data = {MMR_CDbgTransitionToValueHi}; end
        ADDR_MMR_CDBGONESCOUNTMASKHI            : begin : mmr_rd_hit_MMR_CDbgOnesCountMaskHi reg_prehit.ClaMmrCdbgonescountmaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgOnesCountMaskHi}; end
        ADDR_MMR_CDBGANYCHANGEHI                : begin : mmr_rd_hit_MMR_CDbgAnyChangeHi reg_prehit.ClaMmrCdbganychangehiHit = 1'b1; reg_rd_data = {MMR_CDbgAnyChangeHi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap0Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap1Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap0Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap1Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap0Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap1Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap0Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap0HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap1Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap1HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap2Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode0Eap3Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode0Eap3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode0Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap2Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode1Eap3Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode1Eap3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode1Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap2Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode2Eap3Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode2Eap3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode2Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap2Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap2HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI  : begin : mmr_rd_hit_MMR_CDbgSignalSnapshotNode3Eap3Hi reg_prehit.ClaMmrCdbgsignalsnapshotnode3Eap3HiHit = 1'b1; reg_rd_data = {MMR_CDbgSignalSnapshotNode3Eap3Hi}; end
        ADDR_MMR_CDBGLFSR                       : begin : mmr_rd_hit_MMR_CDbgLfsr reg_prehit.ClaMmrCdbglfsrHit = 1'b1; reg_rd_data = {MMR_CDbgLfsr}; end
        ADDR_MMR_CDBGLFSRMASK                   : begin : mmr_rd_hit_MMR_CDbgLfsrMask reg_prehit.ClaMmrCdbglfsrmaskHit = 1'b1; reg_rd_data = {MMR_CDbgLfsrMask}; end
        ADDR_MMR_CDBGTIMESTAMPCAPTURE           : begin : mmr_rd_hit_MMR_CDbgTimestampCapture reg_prehit.ClaMmrCdbgtimestampcaptureHit = 1'b1; reg_rd_data = {MMR_CDbgTimestampCapture}; end
        ADDR_MMR_CDBGCOMPARE0LO                 : begin : mmr_rd_hit_MMR_CDbgCompare0Lo reg_prehit.ClaMmrCdbgcompare0LoHit = 1'b1; reg_rd_data = {MMR_CDbgCompare0Lo}; end
        ADDR_MMR_CDBGCOMPARE0MASKLO             : begin : mmr_rd_hit_MMR_CDbgCompare0MaskLo reg_prehit.ClaMmrCdbgcompare0MaskloHit = 1'b1; reg_rd_data = {MMR_CDbgCompare0MaskLo}; end
        ADDR_MMR_CDBGCOMPARE1LO                 : begin : mmr_rd_hit_MMR_CDbgCompare1Lo reg_prehit.ClaMmrCdbgcompare1LoHit = 1'b1; reg_rd_data = {MMR_CDbgCompare1Lo}; end
        ADDR_MMR_CDBGCOMPARE1MASKLO             : begin : mmr_rd_hit_MMR_CDbgCompare1MaskLo reg_prehit.ClaMmrCdbgcompare1MaskloHit = 1'b1; reg_rd_data = {MMR_CDbgCompare1MaskLo}; end
        ADDR_MMR_CDBGCOMPARE2LO                 : begin : mmr_rd_hit_MMR_CDbgCompare2Lo reg_prehit.ClaMmrCdbgcompare2LoHit = 1'b1; reg_rd_data = {MMR_CDbgCompare2Lo}; end
        ADDR_MMR_CDBGCOMPARE2MASKLO             : begin : mmr_rd_hit_MMR_CDbgCompare2MaskLo reg_prehit.ClaMmrCdbgcompare2MaskloHit = 1'b1; reg_rd_data = {MMR_CDbgCompare2MaskLo}; end
        ADDR_MMR_CDBGCOMPARE3LO                 : begin : mmr_rd_hit_MMR_CDbgCompare3Lo reg_prehit.ClaMmrCdbgcompare3LoHit = 1'b1; reg_rd_data = {MMR_CDbgCompare3Lo}; end
        ADDR_MMR_CDBGCOMPARE3MASKLO             : begin : mmr_rd_hit_MMR_CDbgCompare3MaskLo reg_prehit.ClaMmrCdbgcompare3MaskloHit = 1'b1; reg_rd_data = {MMR_CDbgCompare3MaskLo}; end
        ADDR_MMR_CDBGCOMPARE0HI                 : begin : mmr_rd_hit_MMR_CDbgCompare0Hi reg_prehit.ClaMmrCdbgcompare0HiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare0Hi}; end
        ADDR_MMR_CDBGCOMPARE0MASKHI             : begin : mmr_rd_hit_MMR_CDbgCompare0MaskHi reg_prehit.ClaMmrCdbgcompare0MaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare0MaskHi}; end
        ADDR_MMR_CDBGCOMPARE1HI                 : begin : mmr_rd_hit_MMR_CDbgCompare1Hi reg_prehit.ClaMmrCdbgcompare1HiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare1Hi}; end
        ADDR_MMR_CDBGCOMPARE1MASKHI             : begin : mmr_rd_hit_MMR_CDbgCompare1MaskHi reg_prehit.ClaMmrCdbgcompare1MaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare1MaskHi}; end
        ADDR_MMR_CDBGCOMPARE2HI                 : begin : mmr_rd_hit_MMR_CDbgCompare2Hi reg_prehit.ClaMmrCdbgcompare2HiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare2Hi}; end
        ADDR_MMR_CDBGCOMPARE2MASKHI             : begin : mmr_rd_hit_MMR_CDbgCompare2MaskHi reg_prehit.ClaMmrCdbgcompare2MaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare2MaskHi}; end
        ADDR_MMR_CDBGCOMPARE3HI                 : begin : mmr_rd_hit_MMR_CDbgCompare3Hi reg_prehit.ClaMmrCdbgcompare3HiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare3Hi}; end
        ADDR_MMR_CDBGCOMPARE3MASKHI             : begin : mmr_rd_hit_MMR_CDbgCompare3MaskHi reg_prehit.ClaMmrCdbgcompare3MaskhiHit = 1'b1; reg_rd_data = {MMR_CDbgCompare3MaskHi}; end
        ADDR_MMR_CDBGVERSION                    : begin : mmr_rd_hit_MMR_CDbgVersion reg_prehit.ClaMmrCdbgversionHit = 1'b1; reg_rd_data = {MMR_CDbgVersion}; end
        ADDR_MMR_SCRATCH                        : begin : mmr_rd_hit_MMR_Scratch reg_prehit.ClaMmrScratchHit = 1'b1; reg_rd_data = {MMR_Scratch}; end
        default:  begin : mmr_rd_default
            reg_prehit  = '0;
            reg_rd_data = '0;
        end
    endcase
end

assign reg_hit = reg_read & |reg_prehit;

generic_dff #(
    .WIDTH ($bits(logic)),
    .RESET_VALUE (0)
) reg_hit_d1_ff (
    .clk (clk),
    .rst_n (reset_n),
    .en (reg_cs | reg_hit_d1),
    .in (reg_hit),
    .out (reg_hit_d1)
);

always_comb begin : mmr_rd_d1_comb
    reg_addr_select_d1 = '0;
    unique case (reg_addr_d1)
        ADDR_MMR_CDBGCLACOUNTER0CFG             : begin : mmr_rd_d1_MMR_CDbgClaCounter0Cfg reg_rd_data_d1 = {MMR_CDbgClaCounter0Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER1CFG             : begin : mmr_rd_d1_MMR_CDbgClaCounter1Cfg reg_rd_data_d1 = {MMR_CDbgClaCounter1Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER2CFG             : begin : mmr_rd_d1_MMR_CDbgClaCounter2Cfg reg_rd_data_d1 = {MMR_CDbgClaCounter2Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER3CFG             : begin : mmr_rd_d1_MMR_CDbgClaCounter3Cfg reg_rd_data_d1 = {MMR_CDbgClaCounter3Cfg}; end
        ADDR_MMR_CDBGNODE0EAP0                  : begin : mmr_rd_d1_MMR_CDbgNode0Eap0 reg_rd_data_d1 = {MMR_CDbgNode0Eap0}; end
        ADDR_MMR_CDBGNODE0EAP1                  : begin : mmr_rd_d1_MMR_CDbgNode0Eap1 reg_rd_data_d1 = {MMR_CDbgNode0Eap1}; end
        ADDR_MMR_CDBGNODE1EAP0                  : begin : mmr_rd_d1_MMR_CDbgNode1Eap0 reg_rd_data_d1 = {MMR_CDbgNode1Eap0}; end
        ADDR_MMR_CDBGNODE1EAP1                  : begin : mmr_rd_d1_MMR_CDbgNode1Eap1 reg_rd_data_d1 = {MMR_CDbgNode1Eap1}; end
        ADDR_MMR_CDBGNODE2EAP0                  : begin : mmr_rd_d1_MMR_CDbgNode2Eap0 reg_rd_data_d1 = {MMR_CDbgNode2Eap0}; end
        ADDR_MMR_CDBGNODE2EAP1                  : begin : mmr_rd_d1_MMR_CDbgNode2Eap1 reg_rd_data_d1 = {MMR_CDbgNode2Eap1}; end
        ADDR_MMR_CDBGNODE3EAP0                  : begin : mmr_rd_d1_MMR_CDbgNode3Eap0 reg_rd_data_d1 = {MMR_CDbgNode3Eap0}; end
        ADDR_MMR_CDBGNODE3EAP1                  : begin : mmr_rd_d1_MMR_CDbgNode3Eap1 reg_rd_data_d1 = {MMR_CDbgNode3Eap1}; end
        ADDR_MMR_CDBGSIGNALMASK0LO              : begin : mmr_rd_d1_MMR_CDbgSignalMask0Lo reg_rd_data_d1 = {MMR_CDbgSignalMask0Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH0LO             : begin : mmr_rd_d1_MMR_CDbgSignalMatch0Lo reg_rd_data_d1 = {MMR_CDbgSignalMatch0Lo}; end
        ADDR_MMR_CDBGSIGNALMASK1LO              : begin : mmr_rd_d1_MMR_CDbgSignalMask1Lo reg_rd_data_d1 = {MMR_CDbgSignalMask1Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH1LO             : begin : mmr_rd_d1_MMR_CDbgSignalMatch1Lo reg_rd_data_d1 = {MMR_CDbgSignalMatch1Lo}; end
        ADDR_MMR_CDBGSIGNALEDGEDETECTCFG        : begin : mmr_rd_d1_MMR_CDbgSignalEdgeDetectCfg reg_rd_data_d1 = {MMR_CDbgSignalEdgeDetectCfg}; end
        ADDR_MMR_CDBGEAPSTATUS                  : begin : mmr_rd_d1_MMR_CDbgEapStatus reg_rd_data_d1 = {MMR_CDbgEapStatus}; end
        ADDR_MMR_CDBGCLACTRLSTATUS              : begin : mmr_rd_d1_MMR_CDbgClaCtrlStatus reg_rd_data_d1 = {MMR_CDbgClaCtrlStatus}; end
        ADDR_MMR_CDBGMUXSELLO                   : begin : mmr_rd_d1_MMR_CDbgMuxSelLo reg_rd_data_d1 = {MMR_CDbgMuxSelLo}; end
        ADDR_MMR_CDBGRSVD1                      : begin : mmr_rd_d1_MMR_CDbgRsvd1 reg_rd_data_d1 = {MMR_CDbgRsvd1}; end
        ADDR_MMR_CDBGRSVD2                      : begin : mmr_rd_d1_MMR_CDbgRsvd2 reg_rd_data_d1 = {MMR_CDbgRsvd2}; end
        ADDR_MMR_CDBGTRANSITIONMASKLO           : begin : mmr_rd_d1_MMR_CDbgTransitionMaskLo reg_rd_data_d1 = {MMR_CDbgTransitionMaskLo}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUELO      : begin : mmr_rd_d1_MMR_CDbgTransitionFromValueLo reg_rd_data_d1 = {MMR_CDbgTransitionFromValueLo}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUELO        : begin : mmr_rd_d1_MMR_CDbgTransitionToValueLo reg_rd_data_d1 = {MMR_CDbgTransitionToValueLo}; end
        ADDR_MMR_CDBGONESCOUNTMASKLO            : begin : mmr_rd_d1_MMR_CDbgOnesCountMaskLo reg_rd_data_d1 = {MMR_CDbgOnesCountMaskLo}; end
        ADDR_MMR_CDBGONESCOUNTVALUE             : begin : mmr_rd_d1_MMR_CDbgOnesCountValue reg_rd_data_d1 = {MMR_CDbgOnesCountValue}; end
        ADDR_MMR_CDBGANYCHANGELO                : begin : mmr_rd_d1_MMR_CDbgAnyChangeLo reg_rd_data_d1 = {MMR_CDbgAnyChangeLo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap0Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap1Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap0Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap1Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap0Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap1Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap0Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap1Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap1Lo}; end
        ADDR_MMR_CDBGCLATIMEMATCH               : begin : mmr_rd_d1_MMR_CDbgClaTimeMatch reg_rd_data_d1 = {MMR_CDbgClaTimeMatch}; end
        ADDR_MMR_CDBGSIGNALMASK2LO              : begin : mmr_rd_d1_MMR_CDbgSignalMask2Lo reg_rd_data_d1 = {MMR_CDbgSignalMask2Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH2LO             : begin : mmr_rd_d1_MMR_CDbgSignalMatch2Lo reg_rd_data_d1 = {MMR_CDbgSignalMatch2Lo}; end
        ADDR_MMR_CDBGSIGNALMASK3LO              : begin : mmr_rd_d1_MMR_CDbgSignalMask3Lo reg_rd_data_d1 = {MMR_CDbgSignalMask3Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH3LO             : begin : mmr_rd_d1_MMR_CDbgSignalMatch3Lo reg_rd_data_d1 = {MMR_CDbgSignalMatch3Lo}; end
        ADDR_MMR_CDBGNODE0EAP2                  : begin : mmr_rd_d1_MMR_CDbgNode0Eap2 reg_rd_data_d1 = {MMR_CDbgNode0Eap2}; end
        ADDR_MMR_CDBGNODE0EAP3                  : begin : mmr_rd_d1_MMR_CDbgNode0Eap3 reg_rd_data_d1 = {MMR_CDbgNode0Eap3}; end
        ADDR_MMR_CDBGNODE1EAP2                  : begin : mmr_rd_d1_MMR_CDbgNode1Eap2 reg_rd_data_d1 = {MMR_CDbgNode1Eap2}; end
        ADDR_MMR_CDBGNODE1EAP3                  : begin : mmr_rd_d1_MMR_CDbgNode1Eap3 reg_rd_data_d1 = {MMR_CDbgNode1Eap3}; end
        ADDR_MMR_CDBGNODE2EAP2                  : begin : mmr_rd_d1_MMR_CDbgNode2Eap2 reg_rd_data_d1 = {MMR_CDbgNode2Eap2}; end
        ADDR_MMR_CDBGNODE2EAP3                  : begin : mmr_rd_d1_MMR_CDbgNode2Eap3 reg_rd_data_d1 = {MMR_CDbgNode2Eap3}; end
        ADDR_MMR_CDBGNODE3EAP2                  : begin : mmr_rd_d1_MMR_CDbgNode3Eap2 reg_rd_data_d1 = {MMR_CDbgNode3Eap2}; end
        ADDR_MMR_CDBGNODE3EAP3                  : begin : mmr_rd_d1_MMR_CDbgNode3Eap3 reg_rd_data_d1 = {MMR_CDbgNode3Eap3}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap2Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap3Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap2Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap3Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap2Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap3Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap2Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap3Lo reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALDELAYMUXSEL          : begin : mmr_rd_d1_MMR_CDbgSignalDelayMuxSel reg_rd_data_d1 = {MMR_CDbgSignalDelayMuxSel}; end
        ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH     : begin : mmr_rd_d1_MMR_CDbgClaXtriggerTimestretch reg_rd_data_d1 = {MMR_CDbgClaXtriggerTimestretch}; end
        ADDR_MMR_CDBGCLATIMESTAMP               : begin : mmr_rd_d1_MMR_CDbgClaTimestamp reg_rd_data_d1 = {MMR_CDbgClaTimestamp}; end
        ADDR_MMR_CDBGCLATIMESTAMPSYNC           : begin : mmr_rd_d1_MMR_CDbgClaTimestampSync reg_rd_data_d1 = {MMR_CDbgClaTimestampSync}; end
        ADDR_MMR_CDBGCLATIMESTAMPCONFIG         : begin : mmr_rd_d1_MMR_CDbgClaTimestampConfig reg_rd_data_d1 = {MMR_CDbgClaTimestampConfig}; end
        ADDR_MMR_CDBGCLATIMESTAMPOFFSET         : begin : mmr_rd_d1_MMR_CDbgClaTimestampOffset reg_rd_data_d1 = {MMR_CDbgClaTimestampOffset}; end
        ADDR_MMR_CDBGSIGNALMASK0HI              : begin : mmr_rd_d1_MMR_CDbgSignalMask0Hi reg_rd_data_d1 = {MMR_CDbgSignalMask0Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH0HI             : begin : mmr_rd_d1_MMR_CDbgSignalMatch0Hi reg_rd_data_d1 = {MMR_CDbgSignalMatch0Hi}; end
        ADDR_MMR_CDBGSIGNALMASK1HI              : begin : mmr_rd_d1_MMR_CDbgSignalMask1Hi reg_rd_data_d1 = {MMR_CDbgSignalMask1Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH1HI             : begin : mmr_rd_d1_MMR_CDbgSignalMatch1Hi reg_rd_data_d1 = {MMR_CDbgSignalMatch1Hi}; end
        ADDR_MMR_CDBGSIGNALMASK2HI              : begin : mmr_rd_d1_MMR_CDbgSignalMask2Hi reg_rd_data_d1 = {MMR_CDbgSignalMask2Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH2HI             : begin : mmr_rd_d1_MMR_CDbgSignalMatch2Hi reg_rd_data_d1 = {MMR_CDbgSignalMatch2Hi}; end
        ADDR_MMR_CDBGSIGNALMASK3HI              : begin : mmr_rd_d1_MMR_CDbgSignalMask3Hi reg_rd_data_d1 = {MMR_CDbgSignalMask3Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH3HI             : begin : mmr_rd_d1_MMR_CDbgSignalMatch3Hi reg_rd_data_d1 = {MMR_CDbgSignalMatch3Hi}; end
        ADDR_MMR_CDBGMUXSELHI                   : begin : mmr_rd_d1_MMR_CDbgMuxSelHi reg_rd_data_d1 = {MMR_CDbgMuxSelHi}; end
        ADDR_MMR_CDBGTRANSITIONMASKHI           : begin : mmr_rd_d1_MMR_CDbgTransitionMaskHi reg_rd_data_d1 = {MMR_CDbgTransitionMaskHi}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUEHI      : begin : mmr_rd_d1_MMR_CDbgTransitionFromValueHi reg_rd_data_d1 = {MMR_CDbgTransitionFromValueHi}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUEHI        : begin : mmr_rd_d1_MMR_CDbgTransitionToValueHi reg_rd_data_d1 = {MMR_CDbgTransitionToValueHi}; end
        ADDR_MMR_CDBGONESCOUNTMASKHI            : begin : mmr_rd_d1_MMR_CDbgOnesCountMaskHi reg_rd_data_d1 = {MMR_CDbgOnesCountMaskHi}; end
        ADDR_MMR_CDBGANYCHANGEHI                : begin : mmr_rd_d1_MMR_CDbgAnyChangeHi reg_rd_data_d1 = {MMR_CDbgAnyChangeHi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap0Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap1Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap0Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap1Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap0Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap1Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap0Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap1Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap2Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode0Eap3Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode0Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap2Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode1Eap3Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode1Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap2Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode2Eap3Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode2Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap2Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI  : begin : mmr_rd_d1_MMR_CDbgSignalSnapshotNode3Eap3Hi reg_rd_data_d1 = {MMR_CDbgSignalSnapshotNode3Eap3Hi}; end
        ADDR_MMR_CDBGLFSR                       : begin : mmr_rd_d1_MMR_CDbgLfsr reg_rd_data_d1 = {MMR_CDbgLfsr}; end
        ADDR_MMR_CDBGLFSRMASK                   : begin : mmr_rd_d1_MMR_CDbgLfsrMask reg_rd_data_d1 = {MMR_CDbgLfsrMask}; end
        ADDR_MMR_CDBGTIMESTAMPCAPTURE           : begin : mmr_rd_d1_MMR_CDbgTimestampCapture reg_rd_data_d1 = {MMR_CDbgTimestampCapture}; end
        ADDR_MMR_CDBGCOMPARE0LO                 : begin : mmr_rd_d1_MMR_CDbgCompare0Lo reg_rd_data_d1 = {MMR_CDbgCompare0Lo}; end
        ADDR_MMR_CDBGCOMPARE0MASKLO             : begin : mmr_rd_d1_MMR_CDbgCompare0MaskLo reg_rd_data_d1 = {MMR_CDbgCompare0MaskLo}; end
        ADDR_MMR_CDBGCOMPARE1LO                 : begin : mmr_rd_d1_MMR_CDbgCompare1Lo reg_rd_data_d1 = {MMR_CDbgCompare1Lo}; end
        ADDR_MMR_CDBGCOMPARE1MASKLO             : begin : mmr_rd_d1_MMR_CDbgCompare1MaskLo reg_rd_data_d1 = {MMR_CDbgCompare1MaskLo}; end
        ADDR_MMR_CDBGCOMPARE2LO                 : begin : mmr_rd_d1_MMR_CDbgCompare2Lo reg_rd_data_d1 = {MMR_CDbgCompare2Lo}; end
        ADDR_MMR_CDBGCOMPARE2MASKLO             : begin : mmr_rd_d1_MMR_CDbgCompare2MaskLo reg_rd_data_d1 = {MMR_CDbgCompare2MaskLo}; end
        ADDR_MMR_CDBGCOMPARE3LO                 : begin : mmr_rd_d1_MMR_CDbgCompare3Lo reg_rd_data_d1 = {MMR_CDbgCompare3Lo}; end
        ADDR_MMR_CDBGCOMPARE3MASKLO             : begin : mmr_rd_d1_MMR_CDbgCompare3MaskLo reg_rd_data_d1 = {MMR_CDbgCompare3MaskLo}; end
        ADDR_MMR_CDBGCOMPARE0HI                 : begin : mmr_rd_d1_MMR_CDbgCompare0Hi reg_rd_data_d1 = {MMR_CDbgCompare0Hi}; end
        ADDR_MMR_CDBGCOMPARE0MASKHI             : begin : mmr_rd_d1_MMR_CDbgCompare0MaskHi reg_rd_data_d1 = {MMR_CDbgCompare0MaskHi}; end
        ADDR_MMR_CDBGCOMPARE1HI                 : begin : mmr_rd_d1_MMR_CDbgCompare1Hi reg_rd_data_d1 = {MMR_CDbgCompare1Hi}; end
        ADDR_MMR_CDBGCOMPARE1MASKHI             : begin : mmr_rd_d1_MMR_CDbgCompare1MaskHi reg_rd_data_d1 = {MMR_CDbgCompare1MaskHi}; end
        ADDR_MMR_CDBGCOMPARE2HI                 : begin : mmr_rd_d1_MMR_CDbgCompare2Hi reg_rd_data_d1 = {MMR_CDbgCompare2Hi}; end
        ADDR_MMR_CDBGCOMPARE2MASKHI             : begin : mmr_rd_d1_MMR_CDbgCompare2MaskHi reg_rd_data_d1 = {MMR_CDbgCompare2MaskHi}; end
        ADDR_MMR_CDBGCOMPARE3HI                 : begin : mmr_rd_d1_MMR_CDbgCompare3Hi reg_rd_data_d1 = {MMR_CDbgCompare3Hi}; end
        ADDR_MMR_CDBGCOMPARE3MASKHI             : begin : mmr_rd_d1_MMR_CDbgCompare3MaskHi reg_rd_data_d1 = {MMR_CDbgCompare3MaskHi}; end
        ADDR_MMR_CDBGVERSION                    : begin : mmr_rd_d1_MMR_CDbgVersion reg_rd_data_d1 = {MMR_CDbgVersion}; end
        ADDR_MMR_SCRATCH                        : begin : mmr_rd_d1_MMR_Scratch reg_rd_data_d1 = {MMR_Scratch}; end
        default:  begin : mmr_rd_d1_default
            reg_rd_data_d1 = '0;
        end
    endcase
end

assign MmrWrReady = reg_wr_ready;

if (FLOP_RD_DATA) begin : flop_rd_data
    assign MmrHit     = reg_hit_d1;
    generic_dff #(
        .WIDTH ($bits(logic [CLA_NUM_REGISTERS-1:0])),
        .RESET_VALUE (0)
    ) Mmr_Hit_List_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (reg_cs | MmrHit),
        .in (reg_prehit),
        .out (MmrHitList)
    );
    generic_dff #(
        .WIDTH ($bits(logic [64-1:0])),
        .RESET_VALUE (0)
    ) Mmr_RdData_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (reg_cs),
        .in (reg_rd_data),
        .out (MmrRdData)
    );
end else begin : no_flop_rd_data
    assign MmrHit                     = reg_hit;
    assign MmrHitList                 = reg_prehit;
    assign MmrRdData                  = reg_rd_data;
end

assign MmrUpdateEn                              = reg_write_d1 & reg_hit_d1;
assign MmrUpdateAddr                            = reg_addr_d1;
assign MmrUpdateIndirAddr                       = reg_addr_select_d1;
assign MmrUpdateData                            = reg_rd_data_d1;

`ASSERT_MACRO(ERR_BROADCAST_BUS_MISSING_UPDATE_EN, clk, reset_n, $past(MmrCs & MmrWrEn, 1 + FLOP_IN_REQ) & $past(reg_hit, 1), MmrUpdateEn, "Broadcast bus signal MmrUpdateEn is not high 1 cycle after a SW write.")
`ASSERT_MACRO(ERR_BROADCAST_BUS_INCORRECT_ADDRESS, clk, reset_n, $past(MmrCs & MmrWrEn, 1 + FLOP_IN_REQ), MmrUpdateAddr == $past(MmrAddr, 1 + FLOP_IN_REQ), "Broadcast bus signal MmrUpdateAddr does not match SW write address.")
`ASSERT_MACRO(ERR_BROADCAST_BUS_INCORRECT_DATA, clk, reset_n, $past(MmrCs & MmrWrEn, 1 + FLOP_IN_REQ) & $past(reg_hit, 1), MmrUpdateData == get_register_value($past(MmrAddr, 1 + FLOP_IN_REQ)), "Broadcast bus signal MmrUpdateData does not match the value which was written.")

assign ClaMmrCdbgclacounter0Cfg.Rsvd            = MMR_CDbgClaCounter0Cfg_F_Rsvd;
assign ClaMmrCdbgclacounter0Cfg.UpperTarget     = MMR_CDbgClaCounter0Cfg_F_UpperTarget;
assign ClaMmrCdbgclacounter0Cfg.UpperCounter    = MMR_CDbgClaCounter0Cfg_F_UpperCounter;
assign ClaMmrCdbgclacounter0Cfg.ResetOnTarget   = MMR_CDbgClaCounter0Cfg_F_ResetOnTarget;
assign ClaMmrCdbgclacounter0Cfg.Target          = MMR_CDbgClaCounter0Cfg_F_Target;
assign ClaMmrCdbgclacounter0Cfg.Counter         = MMR_CDbgClaCounter0Cfg_F_Counter;
assign ClaMmrCdbgclacounter1Cfg.Rsvd            = MMR_CDbgClaCounter1Cfg_F_Rsvd;
assign ClaMmrCdbgclacounter1Cfg.UpperTarget     = MMR_CDbgClaCounter1Cfg_F_UpperTarget;
assign ClaMmrCdbgclacounter1Cfg.UpperCounter    = MMR_CDbgClaCounter1Cfg_F_UpperCounter;
assign ClaMmrCdbgclacounter1Cfg.ResetOnTarget   = MMR_CDbgClaCounter1Cfg_F_ResetOnTarget;
assign ClaMmrCdbgclacounter1Cfg.Target          = MMR_CDbgClaCounter1Cfg_F_Target;
assign ClaMmrCdbgclacounter1Cfg.Counter         = MMR_CDbgClaCounter1Cfg_F_Counter;
assign ClaMmrCdbgclacounter2Cfg.Rsvd            = MMR_CDbgClaCounter2Cfg_F_Rsvd;
assign ClaMmrCdbgclacounter2Cfg.UpperTarget     = MMR_CDbgClaCounter2Cfg_F_UpperTarget;
assign ClaMmrCdbgclacounter2Cfg.UpperCounter    = MMR_CDbgClaCounter2Cfg_F_UpperCounter;
assign ClaMmrCdbgclacounter2Cfg.ResetOnTarget   = MMR_CDbgClaCounter2Cfg_F_ResetOnTarget;
assign ClaMmrCdbgclacounter2Cfg.Target          = MMR_CDbgClaCounter2Cfg_F_Target;
assign ClaMmrCdbgclacounter2Cfg.Counter         = MMR_CDbgClaCounter2Cfg_F_Counter;
assign ClaMmrCdbgclacounter3Cfg.Rsvd            = MMR_CDbgClaCounter3Cfg_F_Rsvd;
assign ClaMmrCdbgclacounter3Cfg.UpperTarget     = MMR_CDbgClaCounter3Cfg_F_UpperTarget;
assign ClaMmrCdbgclacounter3Cfg.UpperCounter    = MMR_CDbgClaCounter3Cfg_F_UpperCounter;
assign ClaMmrCdbgclacounter3Cfg.ResetOnTarget   = MMR_CDbgClaCounter3Cfg_F_ResetOnTarget;
assign ClaMmrCdbgclacounter3Cfg.Target          = MMR_CDbgClaCounter3Cfg_F_Target;
assign ClaMmrCdbgclacounter3Cfg.Counter         = MMR_CDbgClaCounter3Cfg_F_Counter;
assign ClaMmrCdbgnode0Eap0.Action3              = MMR_CDbgNode0Eap0_F_Action3;
assign ClaMmrCdbgnode0Eap0.Action2              = MMR_CDbgNode0Eap0_F_Action2;
assign ClaMmrCdbgnode0Eap0.Udf                  = MMR_CDbgNode0Eap0_F_Udf;
assign ClaMmrCdbgnode0Eap0.EventType2           = MMR_CDbgNode0Eap0_F_EventType2;
assign ClaMmrCdbgnode0Eap0.CustomAction1Enable  = MMR_CDbgNode0Eap0_F_CustomAction1Enable;
assign ClaMmrCdbgnode0Eap0.CustomAction0Enable  = MMR_CDbgNode0Eap0_F_CustomAction0Enable;
assign ClaMmrCdbgnode0Eap0.CustomAction1        = MMR_CDbgNode0Eap0_F_CustomAction1;
assign ClaMmrCdbgnode0Eap0.CustomAction0        = MMR_CDbgNode0Eap0_F_CustomAction0;
assign ClaMmrCdbgnode0Eap0.EventType1           = MMR_CDbgNode0Eap0_F_EventType1;
assign ClaMmrCdbgnode0Eap0.EventType0           = MMR_CDbgNode0Eap0_F_EventType0;
assign ClaMmrCdbgnode0Eap0.LogicalOp            = MMR_CDbgNode0Eap0_F_LogicalOp;
assign ClaMmrCdbgnode0Eap0.Action1              = MMR_CDbgNode0Eap0_F_Action1;
assign ClaMmrCdbgnode0Eap0.Action0              = MMR_CDbgNode0Eap0_F_Action0;
assign ClaMmrCdbgnode0Eap0.DestNode             = MMR_CDbgNode0Eap0_F_DestNode;
assign ClaMmrCdbgnode0Eap1.Action3              = MMR_CDbgNode0Eap1_F_Action3;
assign ClaMmrCdbgnode0Eap1.Action2              = MMR_CDbgNode0Eap1_F_Action2;
assign ClaMmrCdbgnode0Eap1.Udf                  = MMR_CDbgNode0Eap1_F_Udf;
assign ClaMmrCdbgnode0Eap1.EventType2           = MMR_CDbgNode0Eap1_F_EventType2;
assign ClaMmrCdbgnode0Eap1.CustomAction1Enable  = MMR_CDbgNode0Eap1_F_CustomAction1Enable;
assign ClaMmrCdbgnode0Eap1.CustomAction0Enable  = MMR_CDbgNode0Eap1_F_CustomAction0Enable;
assign ClaMmrCdbgnode0Eap1.CustomAction1        = MMR_CDbgNode0Eap1_F_CustomAction1;
assign ClaMmrCdbgnode0Eap1.CustomAction0        = MMR_CDbgNode0Eap1_F_CustomAction0;
assign ClaMmrCdbgnode0Eap1.EventType1           = MMR_CDbgNode0Eap1_F_EventType1;
assign ClaMmrCdbgnode0Eap1.EventType0           = MMR_CDbgNode0Eap1_F_EventType0;
assign ClaMmrCdbgnode0Eap1.LogicalOp            = MMR_CDbgNode0Eap1_F_LogicalOp;
assign ClaMmrCdbgnode0Eap1.Action1              = MMR_CDbgNode0Eap1_F_Action1;
assign ClaMmrCdbgnode0Eap1.Action0              = MMR_CDbgNode0Eap1_F_Action0;
assign ClaMmrCdbgnode0Eap1.DestNode             = MMR_CDbgNode0Eap1_F_DestNode;
assign ClaMmrCdbgnode1Eap0.Action3              = MMR_CDbgNode1Eap0_F_Action3;
assign ClaMmrCdbgnode1Eap0.Action2              = MMR_CDbgNode1Eap0_F_Action2;
assign ClaMmrCdbgnode1Eap0.Udf                  = MMR_CDbgNode1Eap0_F_Udf;
assign ClaMmrCdbgnode1Eap0.EventType2           = MMR_CDbgNode1Eap0_F_EventType2;
assign ClaMmrCdbgnode1Eap0.CustomAction1Enable  = MMR_CDbgNode1Eap0_F_CustomAction1Enable;
assign ClaMmrCdbgnode1Eap0.CustomAction0Enable  = MMR_CDbgNode1Eap0_F_CustomAction0Enable;
assign ClaMmrCdbgnode1Eap0.CustomAction1        = MMR_CDbgNode1Eap0_F_CustomAction1;
assign ClaMmrCdbgnode1Eap0.CustomAction0        = MMR_CDbgNode1Eap0_F_CustomAction0;
assign ClaMmrCdbgnode1Eap0.EventType1           = MMR_CDbgNode1Eap0_F_EventType1;
assign ClaMmrCdbgnode1Eap0.EventType0           = MMR_CDbgNode1Eap0_F_EventType0;
assign ClaMmrCdbgnode1Eap0.LogicalOp            = MMR_CDbgNode1Eap0_F_LogicalOp;
assign ClaMmrCdbgnode1Eap0.Action1              = MMR_CDbgNode1Eap0_F_Action1;
assign ClaMmrCdbgnode1Eap0.Action0              = MMR_CDbgNode1Eap0_F_Action0;
assign ClaMmrCdbgnode1Eap0.DestNode             = MMR_CDbgNode1Eap0_F_DestNode;
assign ClaMmrCdbgnode1Eap1.Action3              = MMR_CDbgNode1Eap1_F_Action3;
assign ClaMmrCdbgnode1Eap1.Action2              = MMR_CDbgNode1Eap1_F_Action2;
assign ClaMmrCdbgnode1Eap1.Udf                  = MMR_CDbgNode1Eap1_F_Udf;
assign ClaMmrCdbgnode1Eap1.EventType2           = MMR_CDbgNode1Eap1_F_EventType2;
assign ClaMmrCdbgnode1Eap1.CustomAction1Enable  = MMR_CDbgNode1Eap1_F_CustomAction1Enable;
assign ClaMmrCdbgnode1Eap1.CustomAction0Enable  = MMR_CDbgNode1Eap1_F_CustomAction0Enable;
assign ClaMmrCdbgnode1Eap1.CustomAction1        = MMR_CDbgNode1Eap1_F_CustomAction1;
assign ClaMmrCdbgnode1Eap1.CustomAction0        = MMR_CDbgNode1Eap1_F_CustomAction0;
assign ClaMmrCdbgnode1Eap1.EventType1           = MMR_CDbgNode1Eap1_F_EventType1;
assign ClaMmrCdbgnode1Eap1.EventType0           = MMR_CDbgNode1Eap1_F_EventType0;
assign ClaMmrCdbgnode1Eap1.LogicalOp            = MMR_CDbgNode1Eap1_F_LogicalOp;
assign ClaMmrCdbgnode1Eap1.Action1              = MMR_CDbgNode1Eap1_F_Action1;
assign ClaMmrCdbgnode1Eap1.Action0              = MMR_CDbgNode1Eap1_F_Action0;
assign ClaMmrCdbgnode1Eap1.DestNode             = MMR_CDbgNode1Eap1_F_DestNode;
assign ClaMmrCdbgnode2Eap0.Action3              = MMR_CDbgNode2Eap0_F_Action3;
assign ClaMmrCdbgnode2Eap0.Action2              = MMR_CDbgNode2Eap0_F_Action2;
assign ClaMmrCdbgnode2Eap0.Udf                  = MMR_CDbgNode2Eap0_F_Udf;
assign ClaMmrCdbgnode2Eap0.EventType2           = MMR_CDbgNode2Eap0_F_EventType2;
assign ClaMmrCdbgnode2Eap0.CustomAction1Enable  = MMR_CDbgNode2Eap0_F_CustomAction1Enable;
assign ClaMmrCdbgnode2Eap0.CustomAction0Enable  = MMR_CDbgNode2Eap0_F_CustomAction0Enable;
assign ClaMmrCdbgnode2Eap0.CustomAction1        = MMR_CDbgNode2Eap0_F_CustomAction1;
assign ClaMmrCdbgnode2Eap0.CustomAction0        = MMR_CDbgNode2Eap0_F_CustomAction0;
assign ClaMmrCdbgnode2Eap0.EventType1           = MMR_CDbgNode2Eap0_F_EventType1;
assign ClaMmrCdbgnode2Eap0.EventType0           = MMR_CDbgNode2Eap0_F_EventType0;
assign ClaMmrCdbgnode2Eap0.LogicalOp            = MMR_CDbgNode2Eap0_F_LogicalOp;
assign ClaMmrCdbgnode2Eap0.Action1              = MMR_CDbgNode2Eap0_F_Action1;
assign ClaMmrCdbgnode2Eap0.Action0              = MMR_CDbgNode2Eap0_F_Action0;
assign ClaMmrCdbgnode2Eap0.DestNode             = MMR_CDbgNode2Eap0_F_DestNode;
assign ClaMmrCdbgnode2Eap1.Action3              = MMR_CDbgNode2Eap1_F_Action3;
assign ClaMmrCdbgnode2Eap1.Action2              = MMR_CDbgNode2Eap1_F_Action2;
assign ClaMmrCdbgnode2Eap1.Udf                  = MMR_CDbgNode2Eap1_F_Udf;
assign ClaMmrCdbgnode2Eap1.EventType2           = MMR_CDbgNode2Eap1_F_EventType2;
assign ClaMmrCdbgnode2Eap1.CustomAction1Enable  = MMR_CDbgNode2Eap1_F_CustomAction1Enable;
assign ClaMmrCdbgnode2Eap1.CustomAction0Enable  = MMR_CDbgNode2Eap1_F_CustomAction0Enable;
assign ClaMmrCdbgnode2Eap1.CustomAction1        = MMR_CDbgNode2Eap1_F_CustomAction1;
assign ClaMmrCdbgnode2Eap1.CustomAction0        = MMR_CDbgNode2Eap1_F_CustomAction0;
assign ClaMmrCdbgnode2Eap1.EventType1           = MMR_CDbgNode2Eap1_F_EventType1;
assign ClaMmrCdbgnode2Eap1.EventType0           = MMR_CDbgNode2Eap1_F_EventType0;
assign ClaMmrCdbgnode2Eap1.LogicalOp            = MMR_CDbgNode2Eap1_F_LogicalOp;
assign ClaMmrCdbgnode2Eap1.Action1              = MMR_CDbgNode2Eap1_F_Action1;
assign ClaMmrCdbgnode2Eap1.Action0              = MMR_CDbgNode2Eap1_F_Action0;
assign ClaMmrCdbgnode2Eap1.DestNode             = MMR_CDbgNode2Eap1_F_DestNode;
assign ClaMmrCdbgnode3Eap0.Action3              = MMR_CDbgNode3Eap0_F_Action3;
assign ClaMmrCdbgnode3Eap0.Action2              = MMR_CDbgNode3Eap0_F_Action2;
assign ClaMmrCdbgnode3Eap0.Udf                  = MMR_CDbgNode3Eap0_F_Udf;
assign ClaMmrCdbgnode3Eap0.EventType2           = MMR_CDbgNode3Eap0_F_EventType2;
assign ClaMmrCdbgnode3Eap0.CustomAction1Enable  = MMR_CDbgNode3Eap0_F_CustomAction1Enable;
assign ClaMmrCdbgnode3Eap0.CustomAction0Enable  = MMR_CDbgNode3Eap0_F_CustomAction0Enable;
assign ClaMmrCdbgnode3Eap0.CustomAction1        = MMR_CDbgNode3Eap0_F_CustomAction1;
assign ClaMmrCdbgnode3Eap0.CustomAction0        = MMR_CDbgNode3Eap0_F_CustomAction0;
assign ClaMmrCdbgnode3Eap0.EventType1           = MMR_CDbgNode3Eap0_F_EventType1;
assign ClaMmrCdbgnode3Eap0.EventType0           = MMR_CDbgNode3Eap0_F_EventType0;
assign ClaMmrCdbgnode3Eap0.LogicalOp            = MMR_CDbgNode3Eap0_F_LogicalOp;
assign ClaMmrCdbgnode3Eap0.Action1              = MMR_CDbgNode3Eap0_F_Action1;
assign ClaMmrCdbgnode3Eap0.Action0              = MMR_CDbgNode3Eap0_F_Action0;
assign ClaMmrCdbgnode3Eap0.DestNode             = MMR_CDbgNode3Eap0_F_DestNode;
assign ClaMmrCdbgnode3Eap1.Action3              = MMR_CDbgNode3Eap1_F_Action3;
assign ClaMmrCdbgnode3Eap1.Action2              = MMR_CDbgNode3Eap1_F_Action2;
assign ClaMmrCdbgnode3Eap1.Udf                  = MMR_CDbgNode3Eap1_F_Udf;
assign ClaMmrCdbgnode3Eap1.EventType2           = MMR_CDbgNode3Eap1_F_EventType2;
assign ClaMmrCdbgnode3Eap1.CustomAction1Enable  = MMR_CDbgNode3Eap1_F_CustomAction1Enable;
assign ClaMmrCdbgnode3Eap1.CustomAction0Enable  = MMR_CDbgNode3Eap1_F_CustomAction0Enable;
assign ClaMmrCdbgnode3Eap1.CustomAction1        = MMR_CDbgNode3Eap1_F_CustomAction1;
assign ClaMmrCdbgnode3Eap1.CustomAction0        = MMR_CDbgNode3Eap1_F_CustomAction0;
assign ClaMmrCdbgnode3Eap1.EventType1           = MMR_CDbgNode3Eap1_F_EventType1;
assign ClaMmrCdbgnode3Eap1.EventType0           = MMR_CDbgNode3Eap1_F_EventType0;
assign ClaMmrCdbgnode3Eap1.LogicalOp            = MMR_CDbgNode3Eap1_F_LogicalOp;
assign ClaMmrCdbgnode3Eap1.Action1              = MMR_CDbgNode3Eap1_F_Action1;
assign ClaMmrCdbgnode3Eap1.Action0              = MMR_CDbgNode3Eap1_F_Action0;
assign ClaMmrCdbgnode3Eap1.DestNode             = MMR_CDbgNode3Eap1_F_DestNode;
assign ClaMmrCdbgsignalmask0Lo.Value            = MMR_CDbgSignalMask0Lo_F_Value;
assign ClaMmrCdbgsignalmatch0Lo.Value           = MMR_CDbgSignalMatch0Lo_F_Value;
assign ClaMmrCdbgsignalmask1Lo.Value            = MMR_CDbgSignalMask1Lo_F_Value;
assign ClaMmrCdbgsignalmatch1Lo.Value           = MMR_CDbgSignalMatch1Lo_F_Value;
assign ClaMmrCdbgsignaledgedetectcfg.PosEdgeSignal1 = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal1;
assign ClaMmrCdbgsignaledgedetectcfg.Signal1Select = MMR_CDbgSignalEdgeDetectCfg_F_Signal1Select;
assign ClaMmrCdbgsignaledgedetectcfg.PosEdgeSignal0 = MMR_CDbgSignalEdgeDetectCfg_F_PosEdgeSignal0;
assign ClaMmrCdbgsignaledgedetectcfg.Signal0Select = MMR_CDbgSignalEdgeDetectCfg_F_Signal0Select;
assign ClaMmrCdbgeapstatus.Node3Eap3W2C         = MMR_CDbgEapStatus_F_Node3Eap3W2C;
assign ClaMmrCdbgeapstatus.Node3Eap2W2C         = MMR_CDbgEapStatus_F_Node3Eap2W2C;
assign ClaMmrCdbgeapstatus.Node3Eap1W2C         = MMR_CDbgEapStatus_F_Node3Eap1W2C;
assign ClaMmrCdbgeapstatus.Node3Eap0W2C         = MMR_CDbgEapStatus_F_Node3Eap0W2C;
assign ClaMmrCdbgeapstatus.Node2Eap3W2C         = MMR_CDbgEapStatus_F_Node2Eap3W2C;
assign ClaMmrCdbgeapstatus.Node2Eap2W2C         = MMR_CDbgEapStatus_F_Node2Eap2W2C;
assign ClaMmrCdbgeapstatus.Node2Eap1W2C         = MMR_CDbgEapStatus_F_Node2Eap1W2C;
assign ClaMmrCdbgeapstatus.Node2Eap0W2C         = MMR_CDbgEapStatus_F_Node2Eap0W2C;
assign ClaMmrCdbgeapstatus.Node1Eap3W2C         = MMR_CDbgEapStatus_F_Node1Eap3W2C;
assign ClaMmrCdbgeapstatus.Node1Eap2W2C         = MMR_CDbgEapStatus_F_Node1Eap2W2C;
assign ClaMmrCdbgeapstatus.Node1Eap1W2C         = MMR_CDbgEapStatus_F_Node1Eap1W2C;
assign ClaMmrCdbgeapstatus.Node1Eap0W2C         = MMR_CDbgEapStatus_F_Node1Eap0W2C;
assign ClaMmrCdbgeapstatus.Node0Eap3W2C         = MMR_CDbgEapStatus_F_Node0Eap3W2C;
assign ClaMmrCdbgeapstatus.Node0Eap2W2C         = MMR_CDbgEapStatus_F_Node0Eap2W2C;
assign ClaMmrCdbgeapstatus.Node0Eap1W2C         = MMR_CDbgEapStatus_F_Node0Eap1W2C;
assign ClaMmrCdbgeapstatus.Node0Eap0W2C         = MMR_CDbgEapStatus_F_Node0Eap0W2C;
assign ClaMmrCdbgeapstatus.Rsvd3116             = MMR_CDbgEapStatus_F_Rsvd3116;
assign ClaMmrCdbgeapstatus.Node3Eap3            = MMR_CDbgEapStatus_F_Node3Eap3;
assign ClaMmrCdbgeapstatus.Node3Eap2            = MMR_CDbgEapStatus_F_Node3Eap2;
assign ClaMmrCdbgeapstatus.Node3Eap1            = MMR_CDbgEapStatus_F_Node3Eap1;
assign ClaMmrCdbgeapstatus.Node3Eap0            = MMR_CDbgEapStatus_F_Node3Eap0;
assign ClaMmrCdbgeapstatus.Node2Eap3            = MMR_CDbgEapStatus_F_Node2Eap3;
assign ClaMmrCdbgeapstatus.Node2Eap2            = MMR_CDbgEapStatus_F_Node2Eap2;
assign ClaMmrCdbgeapstatus.Node2Eap1            = MMR_CDbgEapStatus_F_Node2Eap1;
assign ClaMmrCdbgeapstatus.Node2Eap0            = MMR_CDbgEapStatus_F_Node2Eap0;
assign ClaMmrCdbgeapstatus.Node1Eap3            = MMR_CDbgEapStatus_F_Node1Eap3;
assign ClaMmrCdbgeapstatus.Node1Eap2            = MMR_CDbgEapStatus_F_Node1Eap2;
assign ClaMmrCdbgeapstatus.Node1Eap1            = MMR_CDbgEapStatus_F_Node1Eap1;
assign ClaMmrCdbgeapstatus.Node1Eap0            = MMR_CDbgEapStatus_F_Node1Eap0;
assign ClaMmrCdbgeapstatus.Node0Eap3            = MMR_CDbgEapStatus_F_Node0Eap3;
assign ClaMmrCdbgeapstatus.Node0Eap2            = MMR_CDbgEapStatus_F_Node0Eap2;
assign ClaMmrCdbgeapstatus.Node0Eap1            = MMR_CDbgEapStatus_F_Node0Eap1;
assign ClaMmrCdbgeapstatus.Node0Eap0            = MMR_CDbgEapStatus_F_Node0Eap0;
assign ClaMmrCdbgclactrlstatus.ClaLock          = MMR_CDbgClaCtrlStatus_F_ClaLock;
assign ClaMmrCdbgclactrlstatus.Rsvd6216         = MMR_CDbgClaCtrlStatus_F_Rsvd6216;
assign ClaMmrCdbgclactrlstatus.DisableLocalClockHalt = MMR_CDbgClaCtrlStatus_F_DisableLocalClockHalt;
assign ClaMmrCdbgclactrlstatus.DisableGlobalClockHalt = MMR_CDbgClaCtrlStatus_F_DisableGlobalClockHalt;
assign ClaMmrCdbgclactrlstatus.ClaChainLoopDelay = MMR_CDbgClaCtrlStatus_F_ClaChainLoopDelay;
assign ClaMmrCdbgclactrlstatus.EnableCla        = MMR_CDbgClaCtrlStatus_F_EnableCla;
assign ClaMmrCdbgclactrlstatus.EnableEap        = MMR_CDbgClaCtrlStatus_F_EnableEap;
assign ClaMmrCdbgclactrlstatus.CurrentNode      = MMR_CDbgClaCtrlStatus_F_CurrentNode;
assign ClaMmrCdbgmuxsello.Muxselseg7            = MMR_CDbgMuxSelLo_F_Muxselseg7;
assign ClaMmrCdbgmuxsello.Muxselseg6            = MMR_CDbgMuxSelLo_F_Muxselseg6;
assign ClaMmrCdbgmuxsello.Muxselseg5            = MMR_CDbgMuxSelLo_F_Muxselseg5;
assign ClaMmrCdbgmuxsello.Muxselseg4            = MMR_CDbgMuxSelLo_F_Muxselseg4;
assign ClaMmrCdbgmuxsello.Muxselseg3            = MMR_CDbgMuxSelLo_F_Muxselseg3;
assign ClaMmrCdbgmuxsello.Muxselseg2            = MMR_CDbgMuxSelLo_F_Muxselseg2;
assign ClaMmrCdbgmuxsello.Muxselseg1            = MMR_CDbgMuxSelLo_F_Muxselseg1;
assign ClaMmrCdbgmuxsello.Muxselseg0            = MMR_CDbgMuxSelLo_F_Muxselseg0;
assign ClaMmrCdbgmuxsello.Rsvd1510              = MMR_CDbgMuxSelLo_F_Rsvd1510;
assign ClaMmrCdbgmuxsello.Valid                 = MMR_CDbgMuxSelLo_F_Valid;
assign ClaMmrCdbgmuxsello.Finegraintime         = MMR_CDbgMuxSelLo_F_Finegraintime;
assign ClaMmrCdbgmuxsello.Dbmid                 = MMR_CDbgMuxSelLo_F_Dbmid;
assign ClaMmrCdbgmuxsello.Dbmmode               = MMR_CDbgMuxSelLo_F_Dbmmode;
assign ClaMmrCdbgrsvd1.Value                    = MMR_CDbgRsvd1_F_Value;
assign ClaMmrCdbgrsvd2.Value                    = MMR_CDbgRsvd2_F_Value;
assign ClaMmrCdbgtransitionmasklo.Value         = MMR_CDbgTransitionMaskLo_F_Value;
assign ClaMmrCdbgtransitionfromvaluelo.Value    = MMR_CDbgTransitionFromValueLo_F_Value;
assign ClaMmrCdbgtransitiontovaluelo.Value      = MMR_CDbgTransitionToValueLo_F_Value;
assign ClaMmrCdbgonescountmasklo.Value          = MMR_CDbgOnesCountMaskLo_F_Value;
assign ClaMmrCdbgonescountvalue.Value           = MMR_CDbgOnesCountValue_F_Value;
assign ClaMmrCdbganychangelo.Mask               = MMR_CDbgAnyChangeLo_F_Mask;
assign ClaMmrCdbgsignalsnapshotnode0Eap0Lo.Value = MMR_CDbgSignalSnapshotNode0Eap0Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode0Eap1Lo.Value = MMR_CDbgSignalSnapshotNode0Eap1Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap0Lo.Value = MMR_CDbgSignalSnapshotNode1Eap0Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap1Lo.Value = MMR_CDbgSignalSnapshotNode1Eap1Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap0Lo.Value = MMR_CDbgSignalSnapshotNode2Eap0Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap1Lo.Value = MMR_CDbgSignalSnapshotNode2Eap1Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap0Lo.Value = MMR_CDbgSignalSnapshotNode3Eap0Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap1Lo.Value = MMR_CDbgSignalSnapshotNode3Eap1Lo_F_Value;
assign ClaMmrCdbgclatimematch.TimeMatchVal      = MMR_CDbgClaTimeMatch_F_TimeMatchVal;
assign ClaMmrCdbgsignalmask2Lo.Value            = MMR_CDbgSignalMask2Lo_F_Value;
assign ClaMmrCdbgsignalmatch2Lo.Value           = MMR_CDbgSignalMatch2Lo_F_Value;
assign ClaMmrCdbgsignalmask3Lo.Value            = MMR_CDbgSignalMask3Lo_F_Value;
assign ClaMmrCdbgsignalmatch3Lo.Value           = MMR_CDbgSignalMatch3Lo_F_Value;
assign ClaMmrCdbgnode0Eap2.Action3              = MMR_CDbgNode0Eap2_F_Action3;
assign ClaMmrCdbgnode0Eap2.Action2              = MMR_CDbgNode0Eap2_F_Action2;
assign ClaMmrCdbgnode0Eap2.Udf                  = MMR_CDbgNode0Eap2_F_Udf;
assign ClaMmrCdbgnode0Eap2.EventType2           = MMR_CDbgNode0Eap2_F_EventType2;
assign ClaMmrCdbgnode0Eap2.CustomAction1Enable  = MMR_CDbgNode0Eap2_F_CustomAction1Enable;
assign ClaMmrCdbgnode0Eap2.CustomAction0Enable  = MMR_CDbgNode0Eap2_F_CustomAction0Enable;
assign ClaMmrCdbgnode0Eap2.CustomAction1        = MMR_CDbgNode0Eap2_F_CustomAction1;
assign ClaMmrCdbgnode0Eap2.CustomAction0        = MMR_CDbgNode0Eap2_F_CustomAction0;
assign ClaMmrCdbgnode0Eap2.EventType1           = MMR_CDbgNode0Eap2_F_EventType1;
assign ClaMmrCdbgnode0Eap2.EventType0           = MMR_CDbgNode0Eap2_F_EventType0;
assign ClaMmrCdbgnode0Eap2.LogicalOp            = MMR_CDbgNode0Eap2_F_LogicalOp;
assign ClaMmrCdbgnode0Eap2.Action1              = MMR_CDbgNode0Eap2_F_Action1;
assign ClaMmrCdbgnode0Eap2.Action0              = MMR_CDbgNode0Eap2_F_Action0;
assign ClaMmrCdbgnode0Eap2.DestNode             = MMR_CDbgNode0Eap2_F_DestNode;
assign ClaMmrCdbgnode0Eap3.Action3              = MMR_CDbgNode0Eap3_F_Action3;
assign ClaMmrCdbgnode0Eap3.Action2              = MMR_CDbgNode0Eap3_F_Action2;
assign ClaMmrCdbgnode0Eap3.Udf                  = MMR_CDbgNode0Eap3_F_Udf;
assign ClaMmrCdbgnode0Eap3.EventType2           = MMR_CDbgNode0Eap3_F_EventType2;
assign ClaMmrCdbgnode0Eap3.CustomAction1Enable  = MMR_CDbgNode0Eap3_F_CustomAction1Enable;
assign ClaMmrCdbgnode0Eap3.CustomAction0Enable  = MMR_CDbgNode0Eap3_F_CustomAction0Enable;
assign ClaMmrCdbgnode0Eap3.CustomAction1        = MMR_CDbgNode0Eap3_F_CustomAction1;
assign ClaMmrCdbgnode0Eap3.CustomAction0        = MMR_CDbgNode0Eap3_F_CustomAction0;
assign ClaMmrCdbgnode0Eap3.EventType1           = MMR_CDbgNode0Eap3_F_EventType1;
assign ClaMmrCdbgnode0Eap3.EventType0           = MMR_CDbgNode0Eap3_F_EventType0;
assign ClaMmrCdbgnode0Eap3.LogicalOp            = MMR_CDbgNode0Eap3_F_LogicalOp;
assign ClaMmrCdbgnode0Eap3.Action1              = MMR_CDbgNode0Eap3_F_Action1;
assign ClaMmrCdbgnode0Eap3.Action0              = MMR_CDbgNode0Eap3_F_Action0;
assign ClaMmrCdbgnode0Eap3.DestNode             = MMR_CDbgNode0Eap3_F_DestNode;
assign ClaMmrCdbgnode1Eap2.Action3              = MMR_CDbgNode1Eap2_F_Action3;
assign ClaMmrCdbgnode1Eap2.Action2              = MMR_CDbgNode1Eap2_F_Action2;
assign ClaMmrCdbgnode1Eap2.Udf                  = MMR_CDbgNode1Eap2_F_Udf;
assign ClaMmrCdbgnode1Eap2.EventType2           = MMR_CDbgNode1Eap2_F_EventType2;
assign ClaMmrCdbgnode1Eap2.CustomAction1Enable  = MMR_CDbgNode1Eap2_F_CustomAction1Enable;
assign ClaMmrCdbgnode1Eap2.CustomAction0Enable  = MMR_CDbgNode1Eap2_F_CustomAction0Enable;
assign ClaMmrCdbgnode1Eap2.CustomAction1        = MMR_CDbgNode1Eap2_F_CustomAction1;
assign ClaMmrCdbgnode1Eap2.CustomAction0        = MMR_CDbgNode1Eap2_F_CustomAction0;
assign ClaMmrCdbgnode1Eap2.EventType1           = MMR_CDbgNode1Eap2_F_EventType1;
assign ClaMmrCdbgnode1Eap2.EventType0           = MMR_CDbgNode1Eap2_F_EventType0;
assign ClaMmrCdbgnode1Eap2.LogicalOp            = MMR_CDbgNode1Eap2_F_LogicalOp;
assign ClaMmrCdbgnode1Eap2.Action1              = MMR_CDbgNode1Eap2_F_Action1;
assign ClaMmrCdbgnode1Eap2.Action0              = MMR_CDbgNode1Eap2_F_Action0;
assign ClaMmrCdbgnode1Eap2.DestNode             = MMR_CDbgNode1Eap2_F_DestNode;
assign ClaMmrCdbgnode1Eap3.Action3              = MMR_CDbgNode1Eap3_F_Action3;
assign ClaMmrCdbgnode1Eap3.Action2              = MMR_CDbgNode1Eap3_F_Action2;
assign ClaMmrCdbgnode1Eap3.Udf                  = MMR_CDbgNode1Eap3_F_Udf;
assign ClaMmrCdbgnode1Eap3.EventType2           = MMR_CDbgNode1Eap3_F_EventType2;
assign ClaMmrCdbgnode1Eap3.CustomAction1Enable  = MMR_CDbgNode1Eap3_F_CustomAction1Enable;
assign ClaMmrCdbgnode1Eap3.CustomAction0Enable  = MMR_CDbgNode1Eap3_F_CustomAction0Enable;
assign ClaMmrCdbgnode1Eap3.CustomAction1        = MMR_CDbgNode1Eap3_F_CustomAction1;
assign ClaMmrCdbgnode1Eap3.CustomAction0        = MMR_CDbgNode1Eap3_F_CustomAction0;
assign ClaMmrCdbgnode1Eap3.EventType1           = MMR_CDbgNode1Eap3_F_EventType1;
assign ClaMmrCdbgnode1Eap3.EventType0           = MMR_CDbgNode1Eap3_F_EventType0;
assign ClaMmrCdbgnode1Eap3.LogicalOp            = MMR_CDbgNode1Eap3_F_LogicalOp;
assign ClaMmrCdbgnode1Eap3.Action1              = MMR_CDbgNode1Eap3_F_Action1;
assign ClaMmrCdbgnode1Eap3.Action0              = MMR_CDbgNode1Eap3_F_Action0;
assign ClaMmrCdbgnode1Eap3.DestNode             = MMR_CDbgNode1Eap3_F_DestNode;
assign ClaMmrCdbgnode2Eap2.Action3              = MMR_CDbgNode2Eap2_F_Action3;
assign ClaMmrCdbgnode2Eap2.Action2              = MMR_CDbgNode2Eap2_F_Action2;
assign ClaMmrCdbgnode2Eap2.Udf                  = MMR_CDbgNode2Eap2_F_Udf;
assign ClaMmrCdbgnode2Eap2.EventType2           = MMR_CDbgNode2Eap2_F_EventType2;
assign ClaMmrCdbgnode2Eap2.CustomAction1Enable  = MMR_CDbgNode2Eap2_F_CustomAction1Enable;
assign ClaMmrCdbgnode2Eap2.CustomAction0Enable  = MMR_CDbgNode2Eap2_F_CustomAction0Enable;
assign ClaMmrCdbgnode2Eap2.CustomAction1        = MMR_CDbgNode2Eap2_F_CustomAction1;
assign ClaMmrCdbgnode2Eap2.CustomAction0        = MMR_CDbgNode2Eap2_F_CustomAction0;
assign ClaMmrCdbgnode2Eap2.EventType1           = MMR_CDbgNode2Eap2_F_EventType1;
assign ClaMmrCdbgnode2Eap2.EventType0           = MMR_CDbgNode2Eap2_F_EventType0;
assign ClaMmrCdbgnode2Eap2.LogicalOp            = MMR_CDbgNode2Eap2_F_LogicalOp;
assign ClaMmrCdbgnode2Eap2.Action1              = MMR_CDbgNode2Eap2_F_Action1;
assign ClaMmrCdbgnode2Eap2.Action0              = MMR_CDbgNode2Eap2_F_Action0;
assign ClaMmrCdbgnode2Eap2.DestNode             = MMR_CDbgNode2Eap2_F_DestNode;
assign ClaMmrCdbgnode2Eap3.Action3              = MMR_CDbgNode2Eap3_F_Action3;
assign ClaMmrCdbgnode2Eap3.Action2              = MMR_CDbgNode2Eap3_F_Action2;
assign ClaMmrCdbgnode2Eap3.Udf                  = MMR_CDbgNode2Eap3_F_Udf;
assign ClaMmrCdbgnode2Eap3.EventType2           = MMR_CDbgNode2Eap3_F_EventType2;
assign ClaMmrCdbgnode2Eap3.CustomAction1Enable  = MMR_CDbgNode2Eap3_F_CustomAction1Enable;
assign ClaMmrCdbgnode2Eap3.CustomAction0Enable  = MMR_CDbgNode2Eap3_F_CustomAction0Enable;
assign ClaMmrCdbgnode2Eap3.CustomAction1        = MMR_CDbgNode2Eap3_F_CustomAction1;
assign ClaMmrCdbgnode2Eap3.CustomAction0        = MMR_CDbgNode2Eap3_F_CustomAction0;
assign ClaMmrCdbgnode2Eap3.EventType1           = MMR_CDbgNode2Eap3_F_EventType1;
assign ClaMmrCdbgnode2Eap3.EventType0           = MMR_CDbgNode2Eap3_F_EventType0;
assign ClaMmrCdbgnode2Eap3.LogicalOp            = MMR_CDbgNode2Eap3_F_LogicalOp;
assign ClaMmrCdbgnode2Eap3.Action1              = MMR_CDbgNode2Eap3_F_Action1;
assign ClaMmrCdbgnode2Eap3.Action0              = MMR_CDbgNode2Eap3_F_Action0;
assign ClaMmrCdbgnode2Eap3.DestNode             = MMR_CDbgNode2Eap3_F_DestNode;
assign ClaMmrCdbgnode3Eap2.Action3              = MMR_CDbgNode3Eap2_F_Action3;
assign ClaMmrCdbgnode3Eap2.Action2              = MMR_CDbgNode3Eap2_F_Action2;
assign ClaMmrCdbgnode3Eap2.Udf                  = MMR_CDbgNode3Eap2_F_Udf;
assign ClaMmrCdbgnode3Eap2.EventType2           = MMR_CDbgNode3Eap2_F_EventType2;
assign ClaMmrCdbgnode3Eap2.CustomAction1Enable  = MMR_CDbgNode3Eap2_F_CustomAction1Enable;
assign ClaMmrCdbgnode3Eap2.CustomAction0Enable  = MMR_CDbgNode3Eap2_F_CustomAction0Enable;
assign ClaMmrCdbgnode3Eap2.CustomAction1        = MMR_CDbgNode3Eap2_F_CustomAction1;
assign ClaMmrCdbgnode3Eap2.CustomAction0        = MMR_CDbgNode3Eap2_F_CustomAction0;
assign ClaMmrCdbgnode3Eap2.EventType1           = MMR_CDbgNode3Eap2_F_EventType1;
assign ClaMmrCdbgnode3Eap2.EventType0           = MMR_CDbgNode3Eap2_F_EventType0;
assign ClaMmrCdbgnode3Eap2.LogicalOp            = MMR_CDbgNode3Eap2_F_LogicalOp;
assign ClaMmrCdbgnode3Eap2.Action1              = MMR_CDbgNode3Eap2_F_Action1;
assign ClaMmrCdbgnode3Eap2.Action0              = MMR_CDbgNode3Eap2_F_Action0;
assign ClaMmrCdbgnode3Eap2.DestNode             = MMR_CDbgNode3Eap2_F_DestNode;
assign ClaMmrCdbgnode3Eap3.Action3              = MMR_CDbgNode3Eap3_F_Action3;
assign ClaMmrCdbgnode3Eap3.Action2              = MMR_CDbgNode3Eap3_F_Action2;
assign ClaMmrCdbgnode3Eap3.Udf                  = MMR_CDbgNode3Eap3_F_Udf;
assign ClaMmrCdbgnode3Eap3.EventType2           = MMR_CDbgNode3Eap3_F_EventType2;
assign ClaMmrCdbgnode3Eap3.CustomAction1Enable  = MMR_CDbgNode3Eap3_F_CustomAction1Enable;
assign ClaMmrCdbgnode3Eap3.CustomAction0Enable  = MMR_CDbgNode3Eap3_F_CustomAction0Enable;
assign ClaMmrCdbgnode3Eap3.CustomAction1        = MMR_CDbgNode3Eap3_F_CustomAction1;
assign ClaMmrCdbgnode3Eap3.CustomAction0        = MMR_CDbgNode3Eap3_F_CustomAction0;
assign ClaMmrCdbgnode3Eap3.EventType1           = MMR_CDbgNode3Eap3_F_EventType1;
assign ClaMmrCdbgnode3Eap3.EventType0           = MMR_CDbgNode3Eap3_F_EventType0;
assign ClaMmrCdbgnode3Eap3.LogicalOp            = MMR_CDbgNode3Eap3_F_LogicalOp;
assign ClaMmrCdbgnode3Eap3.Action1              = MMR_CDbgNode3Eap3_F_Action1;
assign ClaMmrCdbgnode3Eap3.Action0              = MMR_CDbgNode3Eap3_F_Action0;
assign ClaMmrCdbgnode3Eap3.DestNode             = MMR_CDbgNode3Eap3_F_DestNode;
assign ClaMmrCdbgsignalsnapshotnode0Eap2Lo.Value = MMR_CDbgSignalSnapshotNode0Eap2Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode0Eap3Lo.Value = MMR_CDbgSignalSnapshotNode0Eap3Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap2Lo.Value = MMR_CDbgSignalSnapshotNode1Eap2Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap3Lo.Value = MMR_CDbgSignalSnapshotNode1Eap3Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap2Lo.Value = MMR_CDbgSignalSnapshotNode2Eap2Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap3Lo.Value = MMR_CDbgSignalSnapshotNode2Eap3Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap2Lo.Value = MMR_CDbgSignalSnapshotNode3Eap2Lo_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap3Lo.Value = MMR_CDbgSignalSnapshotNode3Eap3Lo_F_Value;
assign ClaMmrCdbgsignaldelaymuxsel.Rsvd         = MMR_CDbgSignalDelayMuxSel_F_Rsvd;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg15  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg15;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg14  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg14;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg13  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg13;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg12  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg12;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg11  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg11;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg10  = MMR_CDbgSignalDelayMuxSel_F_Muxselseg10;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg9   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg9;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg8   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg8;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg7   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg7;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg6   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg6;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg5   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg5;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg4   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg4;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg3   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg3;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg2   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg2;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg1   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg1;
assign ClaMmrCdbgsignaldelaymuxsel.Muxselseg0   = MMR_CDbgSignalDelayMuxSel_F_Muxselseg0;
assign ClaMmrCdbgclaxtriggertimestretch.Rsvd    = MMR_CDbgClaXtriggerTimestretch_F_Rsvd;
assign ClaMmrCdbgclaxtriggertimestretch.Xtrigger1Stretch = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger1Stretch;
assign ClaMmrCdbgclaxtriggertimestretch.Xtrigger0Stretch = MMR_CDbgClaXtriggerTimestretch_F_Xtrigger0Stretch;
assign ClaMmrCdbgclatimestamp.TimestampUpper    = MMR_CDbgClaTimestamp_F_TimestampUpper;
assign ClaMmrCdbgclatimestamp.TimestampLower    = MMR_CDbgClaTimestamp_F_TimestampLower;
assign ClaMmrCdbgclatimestampsync.TimestampSync = MMR_CDbgClaTimestampSync_F_TimestampSync;
assign ClaMmrCdbgclatimestampconfig.Rsvd1       = MMR_CDbgClaTimestampConfig_F_Rsvd1;
assign ClaMmrCdbgclatimestampconfig.TsCapture   = MMR_CDbgClaTimestampConfig_F_TsCapture;
assign ClaMmrCdbgclatimestampconfig.DebugMarker = MMR_CDbgClaTimestampConfig_F_DebugMarker;
assign ClaMmrCdbgclatimestampconfig.Resync      = MMR_CDbgClaTimestampConfig_F_Resync;
assign ClaMmrCdbgclatimestampoffset.Rsvd0       = MMR_CDbgClaTimestampOffset_F_Rsvd0;
assign ClaMmrCdbgclatimestampoffset.Offset      = MMR_CDbgClaTimestampOffset_F_Offset;
assign ClaMmrCdbgsignalmask0Hi.Value            = MMR_CDbgSignalMask0Hi_F_Value;
assign ClaMmrCdbgsignalmatch0Hi.Value           = MMR_CDbgSignalMatch0Hi_F_Value;
assign ClaMmrCdbgsignalmask1Hi.Value            = MMR_CDbgSignalMask1Hi_F_Value;
assign ClaMmrCdbgsignalmatch1Hi.Value           = MMR_CDbgSignalMatch1Hi_F_Value;
assign ClaMmrCdbgsignalmask2Hi.Value            = MMR_CDbgSignalMask2Hi_F_Value;
assign ClaMmrCdbgsignalmatch2Hi.Value           = MMR_CDbgSignalMatch2Hi_F_Value;
assign ClaMmrCdbgsignalmask3Hi.Value            = MMR_CDbgSignalMask3Hi_F_Value;
assign ClaMmrCdbgsignalmatch3Hi.Value           = MMR_CDbgSignalMatch3Hi_F_Value;
assign ClaMmrCdbgmuxselhi.Muxselseg15           = MMR_CDbgMuxSelHi_F_Muxselseg15;
assign ClaMmrCdbgmuxselhi.Muxselseg14           = MMR_CDbgMuxSelHi_F_Muxselseg14;
assign ClaMmrCdbgmuxselhi.Muxselseg13           = MMR_CDbgMuxSelHi_F_Muxselseg13;
assign ClaMmrCdbgmuxselhi.Muxselseg12           = MMR_CDbgMuxSelHi_F_Muxselseg12;
assign ClaMmrCdbgmuxselhi.Muxselseg11           = MMR_CDbgMuxSelHi_F_Muxselseg11;
assign ClaMmrCdbgmuxselhi.Muxselseg10           = MMR_CDbgMuxSelHi_F_Muxselseg10;
assign ClaMmrCdbgmuxselhi.Muxselseg9            = MMR_CDbgMuxSelHi_F_Muxselseg9;
assign ClaMmrCdbgmuxselhi.Muxselseg8            = MMR_CDbgMuxSelHi_F_Muxselseg8;
assign ClaMmrCdbgmuxselhi.Rsvd150               = MMR_CDbgMuxSelHi_F_Rsvd150;
assign ClaMmrCdbgtransitionmaskhi.Value         = MMR_CDbgTransitionMaskHi_F_Value;
assign ClaMmrCdbgtransitionfromvaluehi.Value    = MMR_CDbgTransitionFromValueHi_F_Value;
assign ClaMmrCdbgtransitiontovaluehi.Value      = MMR_CDbgTransitionToValueHi_F_Value;
assign ClaMmrCdbgonescountmaskhi.Value          = MMR_CDbgOnesCountMaskHi_F_Value;
assign ClaMmrCdbganychangehi.Mask               = MMR_CDbgAnyChangeHi_F_Mask;
assign ClaMmrCdbgsignalsnapshotnode0Eap0Hi.Value = MMR_CDbgSignalSnapshotNode0Eap0Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode0Eap1Hi.Value = MMR_CDbgSignalSnapshotNode0Eap1Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap0Hi.Value = MMR_CDbgSignalSnapshotNode1Eap0Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap1Hi.Value = MMR_CDbgSignalSnapshotNode1Eap1Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap0Hi.Value = MMR_CDbgSignalSnapshotNode2Eap0Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap1Hi.Value = MMR_CDbgSignalSnapshotNode2Eap1Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap0Hi.Value = MMR_CDbgSignalSnapshotNode3Eap0Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap1Hi.Value = MMR_CDbgSignalSnapshotNode3Eap1Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode0Eap2Hi.Value = MMR_CDbgSignalSnapshotNode0Eap2Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode0Eap3Hi.Value = MMR_CDbgSignalSnapshotNode0Eap3Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap2Hi.Value = MMR_CDbgSignalSnapshotNode1Eap2Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode1Eap3Hi.Value = MMR_CDbgSignalSnapshotNode1Eap3Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap2Hi.Value = MMR_CDbgSignalSnapshotNode2Eap2Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode2Eap3Hi.Value = MMR_CDbgSignalSnapshotNode2Eap3Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap2Hi.Value = MMR_CDbgSignalSnapshotNode3Eap2Hi_F_Value;
assign ClaMmrCdbgsignalsnapshotnode3Eap3Hi.Value = MMR_CDbgSignalSnapshotNode3Eap3Hi_F_Value;
assign ClaMmrCdbglfsr.Lfsr                      = MMR_CDbgLfsr_F_Lfsr;
assign ClaMmrCdbglfsr.LfsrActive                = MMR_CDbgLfsr_F_LfsrActive;
assign ClaMmrCdbglfsrmask.Mask                  = MMR_CDbgLfsrMask_F_Mask;
assign ClaMmrCdbglfsrmask.Rsvd0                 = MMR_CDbgLfsrMask_F_Rsvd0;
assign ClaMmrCdbgtimestampcapture.Timestamp     = MMR_CDbgTimestampCapture_F_Timestamp;
assign ClaMmrCdbgcompare0Lo.Value               = MMR_CDbgCompare0Lo_F_Value;
assign ClaMmrCdbgcompare0Masklo.Value           = MMR_CDbgCompare0MaskLo_F_Value;
assign ClaMmrCdbgcompare1Lo.Value               = MMR_CDbgCompare1Lo_F_Value;
assign ClaMmrCdbgcompare1Masklo.Value           = MMR_CDbgCompare1MaskLo_F_Value;
assign ClaMmrCdbgcompare2Lo.Value               = MMR_CDbgCompare2Lo_F_Value;
assign ClaMmrCdbgcompare2Masklo.Value           = MMR_CDbgCompare2MaskLo_F_Value;
assign ClaMmrCdbgcompare3Lo.Value               = MMR_CDbgCompare3Lo_F_Value;
assign ClaMmrCdbgcompare3Masklo.Value           = MMR_CDbgCompare3MaskLo_F_Value;
assign ClaMmrCdbgcompare0Hi.Value               = MMR_CDbgCompare0Hi_F_Value;
assign ClaMmrCdbgcompare0Maskhi.Value           = MMR_CDbgCompare0MaskHi_F_Value;
assign ClaMmrCdbgcompare1Hi.Value               = MMR_CDbgCompare1Hi_F_Value;
assign ClaMmrCdbgcompare1Maskhi.Value           = MMR_CDbgCompare1MaskHi_F_Value;
assign ClaMmrCdbgcompare2Hi.Value               = MMR_CDbgCompare2Hi_F_Value;
assign ClaMmrCdbgcompare2Maskhi.Value           = MMR_CDbgCompare2MaskHi_F_Value;
assign ClaMmrCdbgcompare3Hi.Value               = MMR_CDbgCompare3Hi_F_Value;
assign ClaMmrCdbgcompare3Maskhi.Value           = MMR_CDbgCompare3MaskHi_F_Value;
assign ClaMmrCdbgversion.Rsvd6312               = MMR_CDbgVersion_F_Rsvd6312;
assign ClaMmrCdbgversion.Major                  = MMR_CDbgVersion_F_Major;
assign ClaMmrCdbgversion.Minor                  = MMR_CDbgVersion_F_Minor;
assign ClaMmrCdbgversion.Patch                  = MMR_CDbgVersion_F_Patch;
assign ClaMmrScratch.Data                       = MMR_Scratch_F_Data;

function automatic [63:0] update_value;
input [63:0] old_value;
input [63:0] op1;
input  [1:0] instr_type;
  begin : upd_value_body
    if (instr_type == 2'b01)
       update_value = old_value | op1;
    else if (instr_type == 2'b10)
       update_value = old_value & ~op1;
    else
       update_value = op1;
  end
endfunction

function automatic [63:0] get_register_value;
input [ADDR_W-1:0] addr;
  begin : get_reg_val_body
    unique case (addr)
        ADDR_MMR_CDBGCLACOUNTER0CFG             : begin : get_reg_val_MMR_CDbgClaCounter0Cfg get_register_value = {MMR_CDbgClaCounter0Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER1CFG             : begin : get_reg_val_MMR_CDbgClaCounter1Cfg get_register_value = {MMR_CDbgClaCounter1Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER2CFG             : begin : get_reg_val_MMR_CDbgClaCounter2Cfg get_register_value = {MMR_CDbgClaCounter2Cfg}; end
        ADDR_MMR_CDBGCLACOUNTER3CFG             : begin : get_reg_val_MMR_CDbgClaCounter3Cfg get_register_value = {MMR_CDbgClaCounter3Cfg}; end
        ADDR_MMR_CDBGNODE0EAP0                  : begin : get_reg_val_MMR_CDbgNode0Eap0 get_register_value = {MMR_CDbgNode0Eap0}; end
        ADDR_MMR_CDBGNODE0EAP1                  : begin : get_reg_val_MMR_CDbgNode0Eap1 get_register_value = {MMR_CDbgNode0Eap1}; end
        ADDR_MMR_CDBGNODE1EAP0                  : begin : get_reg_val_MMR_CDbgNode1Eap0 get_register_value = {MMR_CDbgNode1Eap0}; end
        ADDR_MMR_CDBGNODE1EAP1                  : begin : get_reg_val_MMR_CDbgNode1Eap1 get_register_value = {MMR_CDbgNode1Eap1}; end
        ADDR_MMR_CDBGNODE2EAP0                  : begin : get_reg_val_MMR_CDbgNode2Eap0 get_register_value = {MMR_CDbgNode2Eap0}; end
        ADDR_MMR_CDBGNODE2EAP1                  : begin : get_reg_val_MMR_CDbgNode2Eap1 get_register_value = {MMR_CDbgNode2Eap1}; end
        ADDR_MMR_CDBGNODE3EAP0                  : begin : get_reg_val_MMR_CDbgNode3Eap0 get_register_value = {MMR_CDbgNode3Eap0}; end
        ADDR_MMR_CDBGNODE3EAP1                  : begin : get_reg_val_MMR_CDbgNode3Eap1 get_register_value = {MMR_CDbgNode3Eap1}; end
        ADDR_MMR_CDBGSIGNALMASK0LO              : begin : get_reg_val_MMR_CDbgSignalMask0Lo get_register_value = {MMR_CDbgSignalMask0Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH0LO             : begin : get_reg_val_MMR_CDbgSignalMatch0Lo get_register_value = {MMR_CDbgSignalMatch0Lo}; end
        ADDR_MMR_CDBGSIGNALMASK1LO              : begin : get_reg_val_MMR_CDbgSignalMask1Lo get_register_value = {MMR_CDbgSignalMask1Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH1LO             : begin : get_reg_val_MMR_CDbgSignalMatch1Lo get_register_value = {MMR_CDbgSignalMatch1Lo}; end
        ADDR_MMR_CDBGSIGNALEDGEDETECTCFG        : begin : get_reg_val_MMR_CDbgSignalEdgeDetectCfg get_register_value = {MMR_CDbgSignalEdgeDetectCfg}; end
        ADDR_MMR_CDBGEAPSTATUS                  : begin : get_reg_val_MMR_CDbgEapStatus get_register_value = {MMR_CDbgEapStatus}; end
        ADDR_MMR_CDBGCLACTRLSTATUS              : begin : get_reg_val_MMR_CDbgClaCtrlStatus get_register_value = {MMR_CDbgClaCtrlStatus}; end
        ADDR_MMR_CDBGMUXSELLO                   : begin : get_reg_val_MMR_CDbgMuxSelLo get_register_value = {MMR_CDbgMuxSelLo}; end
        ADDR_MMR_CDBGRSVD1                      : begin : get_reg_val_MMR_CDbgRsvd1 get_register_value = {MMR_CDbgRsvd1}; end
        ADDR_MMR_CDBGRSVD2                      : begin : get_reg_val_MMR_CDbgRsvd2 get_register_value = {MMR_CDbgRsvd2}; end
        ADDR_MMR_CDBGTRANSITIONMASKLO           : begin : get_reg_val_MMR_CDbgTransitionMaskLo get_register_value = {MMR_CDbgTransitionMaskLo}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUELO      : begin : get_reg_val_MMR_CDbgTransitionFromValueLo get_register_value = {MMR_CDbgTransitionFromValueLo}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUELO        : begin : get_reg_val_MMR_CDbgTransitionToValueLo get_register_value = {MMR_CDbgTransitionToValueLo}; end
        ADDR_MMR_CDBGONESCOUNTMASKLO            : begin : get_reg_val_MMR_CDbgOnesCountMaskLo get_register_value = {MMR_CDbgOnesCountMaskLo}; end
        ADDR_MMR_CDBGONESCOUNTVALUE             : begin : get_reg_val_MMR_CDbgOnesCountValue get_register_value = {MMR_CDbgOnesCountValue}; end
        ADDR_MMR_CDBGANYCHANGELO                : begin : get_reg_val_MMR_CDbgAnyChangeLo get_register_value = {MMR_CDbgAnyChangeLo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap0Lo get_register_value = {MMR_CDbgSignalSnapshotNode0Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap1Lo get_register_value = {MMR_CDbgSignalSnapshotNode0Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap0Lo get_register_value = {MMR_CDbgSignalSnapshotNode1Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap1Lo get_register_value = {MMR_CDbgSignalSnapshotNode1Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap0Lo get_register_value = {MMR_CDbgSignalSnapshotNode2Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap1Lo get_register_value = {MMR_CDbgSignalSnapshotNode2Eap1Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap0Lo get_register_value = {MMR_CDbgSignalSnapshotNode3Eap0Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap1Lo get_register_value = {MMR_CDbgSignalSnapshotNode3Eap1Lo}; end
        ADDR_MMR_CDBGCLATIMEMATCH               : begin : get_reg_val_MMR_CDbgClaTimeMatch get_register_value = {MMR_CDbgClaTimeMatch}; end
        ADDR_MMR_CDBGSIGNALMASK2LO              : begin : get_reg_val_MMR_CDbgSignalMask2Lo get_register_value = {MMR_CDbgSignalMask2Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH2LO             : begin : get_reg_val_MMR_CDbgSignalMatch2Lo get_register_value = {MMR_CDbgSignalMatch2Lo}; end
        ADDR_MMR_CDBGSIGNALMASK3LO              : begin : get_reg_val_MMR_CDbgSignalMask3Lo get_register_value = {MMR_CDbgSignalMask3Lo}; end
        ADDR_MMR_CDBGSIGNALMATCH3LO             : begin : get_reg_val_MMR_CDbgSignalMatch3Lo get_register_value = {MMR_CDbgSignalMatch3Lo}; end
        ADDR_MMR_CDBGNODE0EAP2                  : begin : get_reg_val_MMR_CDbgNode0Eap2 get_register_value = {MMR_CDbgNode0Eap2}; end
        ADDR_MMR_CDBGNODE0EAP3                  : begin : get_reg_val_MMR_CDbgNode0Eap3 get_register_value = {MMR_CDbgNode0Eap3}; end
        ADDR_MMR_CDBGNODE1EAP2                  : begin : get_reg_val_MMR_CDbgNode1Eap2 get_register_value = {MMR_CDbgNode1Eap2}; end
        ADDR_MMR_CDBGNODE1EAP3                  : begin : get_reg_val_MMR_CDbgNode1Eap3 get_register_value = {MMR_CDbgNode1Eap3}; end
        ADDR_MMR_CDBGNODE2EAP2                  : begin : get_reg_val_MMR_CDbgNode2Eap2 get_register_value = {MMR_CDbgNode2Eap2}; end
        ADDR_MMR_CDBGNODE2EAP3                  : begin : get_reg_val_MMR_CDbgNode2Eap3 get_register_value = {MMR_CDbgNode2Eap3}; end
        ADDR_MMR_CDBGNODE3EAP2                  : begin : get_reg_val_MMR_CDbgNode3Eap2 get_register_value = {MMR_CDbgNode3Eap2}; end
        ADDR_MMR_CDBGNODE3EAP3                  : begin : get_reg_val_MMR_CDbgNode3Eap3 get_register_value = {MMR_CDbgNode3Eap3}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap2Lo get_register_value = {MMR_CDbgSignalSnapshotNode0Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap3Lo get_register_value = {MMR_CDbgSignalSnapshotNode0Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap2Lo get_register_value = {MMR_CDbgSignalSnapshotNode1Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap3Lo get_register_value = {MMR_CDbgSignalSnapshotNode1Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap2Lo get_register_value = {MMR_CDbgSignalSnapshotNode2Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap3Lo get_register_value = {MMR_CDbgSignalSnapshotNode2Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap2Lo get_register_value = {MMR_CDbgSignalSnapshotNode3Eap2Lo}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3LO  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap3Lo get_register_value = {MMR_CDbgSignalSnapshotNode3Eap3Lo}; end
        ADDR_MMR_CDBGSIGNALDELAYMUXSEL          : begin : get_reg_val_MMR_CDbgSignalDelayMuxSel get_register_value = {MMR_CDbgSignalDelayMuxSel}; end
        ADDR_MMR_CDBGCLAXTRIGGERTIMESTRETCH     : begin : get_reg_val_MMR_CDbgClaXtriggerTimestretch get_register_value = {MMR_CDbgClaXtriggerTimestretch}; end
        ADDR_MMR_CDBGCLATIMESTAMP               : begin : get_reg_val_MMR_CDbgClaTimestamp get_register_value = {MMR_CDbgClaTimestamp}; end
        ADDR_MMR_CDBGCLATIMESTAMPSYNC           : begin : get_reg_val_MMR_CDbgClaTimestampSync get_register_value = {MMR_CDbgClaTimestampSync}; end
        ADDR_MMR_CDBGCLATIMESTAMPCONFIG         : begin : get_reg_val_MMR_CDbgClaTimestampConfig get_register_value = {MMR_CDbgClaTimestampConfig}; end
        ADDR_MMR_CDBGCLATIMESTAMPOFFSET         : begin : get_reg_val_MMR_CDbgClaTimestampOffset get_register_value = {MMR_CDbgClaTimestampOffset}; end
        ADDR_MMR_CDBGSIGNALMASK0HI              : begin : get_reg_val_MMR_CDbgSignalMask0Hi get_register_value = {MMR_CDbgSignalMask0Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH0HI             : begin : get_reg_val_MMR_CDbgSignalMatch0Hi get_register_value = {MMR_CDbgSignalMatch0Hi}; end
        ADDR_MMR_CDBGSIGNALMASK1HI              : begin : get_reg_val_MMR_CDbgSignalMask1Hi get_register_value = {MMR_CDbgSignalMask1Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH1HI             : begin : get_reg_val_MMR_CDbgSignalMatch1Hi get_register_value = {MMR_CDbgSignalMatch1Hi}; end
        ADDR_MMR_CDBGSIGNALMASK2HI              : begin : get_reg_val_MMR_CDbgSignalMask2Hi get_register_value = {MMR_CDbgSignalMask2Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH2HI             : begin : get_reg_val_MMR_CDbgSignalMatch2Hi get_register_value = {MMR_CDbgSignalMatch2Hi}; end
        ADDR_MMR_CDBGSIGNALMASK3HI              : begin : get_reg_val_MMR_CDbgSignalMask3Hi get_register_value = {MMR_CDbgSignalMask3Hi}; end
        ADDR_MMR_CDBGSIGNALMATCH3HI             : begin : get_reg_val_MMR_CDbgSignalMatch3Hi get_register_value = {MMR_CDbgSignalMatch3Hi}; end
        ADDR_MMR_CDBGMUXSELHI                   : begin : get_reg_val_MMR_CDbgMuxSelHi get_register_value = {MMR_CDbgMuxSelHi}; end
        ADDR_MMR_CDBGTRANSITIONMASKHI           : begin : get_reg_val_MMR_CDbgTransitionMaskHi get_register_value = {MMR_CDbgTransitionMaskHi}; end
        ADDR_MMR_CDBGTRANSITIONFROMVALUEHI      : begin : get_reg_val_MMR_CDbgTransitionFromValueHi get_register_value = {MMR_CDbgTransitionFromValueHi}; end
        ADDR_MMR_CDBGTRANSITIONTOVALUEHI        : begin : get_reg_val_MMR_CDbgTransitionToValueHi get_register_value = {MMR_CDbgTransitionToValueHi}; end
        ADDR_MMR_CDBGONESCOUNTMASKHI            : begin : get_reg_val_MMR_CDbgOnesCountMaskHi get_register_value = {MMR_CDbgOnesCountMaskHi}; end
        ADDR_MMR_CDBGANYCHANGEHI                : begin : get_reg_val_MMR_CDbgAnyChangeHi get_register_value = {MMR_CDbgAnyChangeHi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP0HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap0Hi get_register_value = {MMR_CDbgSignalSnapshotNode0Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP1HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap1Hi get_register_value = {MMR_CDbgSignalSnapshotNode0Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP0HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap0Hi get_register_value = {MMR_CDbgSignalSnapshotNode1Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP1HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap1Hi get_register_value = {MMR_CDbgSignalSnapshotNode1Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP0HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap0Hi get_register_value = {MMR_CDbgSignalSnapshotNode2Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP1HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap1Hi get_register_value = {MMR_CDbgSignalSnapshotNode2Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP0HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap0Hi get_register_value = {MMR_CDbgSignalSnapshotNode3Eap0Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP1HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap1Hi get_register_value = {MMR_CDbgSignalSnapshotNode3Eap1Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP2HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap2Hi get_register_value = {MMR_CDbgSignalSnapshotNode0Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE0EAP3HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode0Eap3Hi get_register_value = {MMR_CDbgSignalSnapshotNode0Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP2HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap2Hi get_register_value = {MMR_CDbgSignalSnapshotNode1Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE1EAP3HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode1Eap3Hi get_register_value = {MMR_CDbgSignalSnapshotNode1Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP2HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap2Hi get_register_value = {MMR_CDbgSignalSnapshotNode2Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE2EAP3HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode2Eap3Hi get_register_value = {MMR_CDbgSignalSnapshotNode2Eap3Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP2HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap2Hi get_register_value = {MMR_CDbgSignalSnapshotNode3Eap2Hi}; end
        ADDR_MMR_CDBGSIGNALSNAPSHOTNODE3EAP3HI  : begin : get_reg_val_MMR_CDbgSignalSnapshotNode3Eap3Hi get_register_value = {MMR_CDbgSignalSnapshotNode3Eap3Hi}; end
        ADDR_MMR_CDBGLFSR                       : begin : get_reg_val_MMR_CDbgLfsr get_register_value = {MMR_CDbgLfsr}; end
        ADDR_MMR_CDBGLFSRMASK                   : begin : get_reg_val_MMR_CDbgLfsrMask get_register_value = {MMR_CDbgLfsrMask}; end
        ADDR_MMR_CDBGTIMESTAMPCAPTURE           : begin : get_reg_val_MMR_CDbgTimestampCapture get_register_value = {MMR_CDbgTimestampCapture}; end
        ADDR_MMR_CDBGCOMPARE0LO                 : begin : get_reg_val_MMR_CDbgCompare0Lo get_register_value = {MMR_CDbgCompare0Lo}; end
        ADDR_MMR_CDBGCOMPARE0MASKLO             : begin : get_reg_val_MMR_CDbgCompare0MaskLo get_register_value = {MMR_CDbgCompare0MaskLo}; end
        ADDR_MMR_CDBGCOMPARE1LO                 : begin : get_reg_val_MMR_CDbgCompare1Lo get_register_value = {MMR_CDbgCompare1Lo}; end
        ADDR_MMR_CDBGCOMPARE1MASKLO             : begin : get_reg_val_MMR_CDbgCompare1MaskLo get_register_value = {MMR_CDbgCompare1MaskLo}; end
        ADDR_MMR_CDBGCOMPARE2LO                 : begin : get_reg_val_MMR_CDbgCompare2Lo get_register_value = {MMR_CDbgCompare2Lo}; end
        ADDR_MMR_CDBGCOMPARE2MASKLO             : begin : get_reg_val_MMR_CDbgCompare2MaskLo get_register_value = {MMR_CDbgCompare2MaskLo}; end
        ADDR_MMR_CDBGCOMPARE3LO                 : begin : get_reg_val_MMR_CDbgCompare3Lo get_register_value = {MMR_CDbgCompare3Lo}; end
        ADDR_MMR_CDBGCOMPARE3MASKLO             : begin : get_reg_val_MMR_CDbgCompare3MaskLo get_register_value = {MMR_CDbgCompare3MaskLo}; end
        ADDR_MMR_CDBGCOMPARE0HI                 : begin : get_reg_val_MMR_CDbgCompare0Hi get_register_value = {MMR_CDbgCompare0Hi}; end
        ADDR_MMR_CDBGCOMPARE0MASKHI             : begin : get_reg_val_MMR_CDbgCompare0MaskHi get_register_value = {MMR_CDbgCompare0MaskHi}; end
        ADDR_MMR_CDBGCOMPARE1HI                 : begin : get_reg_val_MMR_CDbgCompare1Hi get_register_value = {MMR_CDbgCompare1Hi}; end
        ADDR_MMR_CDBGCOMPARE1MASKHI             : begin : get_reg_val_MMR_CDbgCompare1MaskHi get_register_value = {MMR_CDbgCompare1MaskHi}; end
        ADDR_MMR_CDBGCOMPARE2HI                 : begin : get_reg_val_MMR_CDbgCompare2Hi get_register_value = {MMR_CDbgCompare2Hi}; end
        ADDR_MMR_CDBGCOMPARE2MASKHI             : begin : get_reg_val_MMR_CDbgCompare2MaskHi get_register_value = {MMR_CDbgCompare2MaskHi}; end
        ADDR_MMR_CDBGCOMPARE3HI                 : begin : get_reg_val_MMR_CDbgCompare3Hi get_register_value = {MMR_CDbgCompare3Hi}; end
        ADDR_MMR_CDBGCOMPARE3MASKHI             : begin : get_reg_val_MMR_CDbgCompare3MaskHi get_register_value = {MMR_CDbgCompare3MaskHi}; end
        ADDR_MMR_CDBGVERSION                    : begin : get_reg_val_MMR_CDbgVersion get_register_value = {MMR_CDbgVersion}; end
        ADDR_MMR_SCRATCH                        : begin : get_reg_val_MMR_Scratch get_register_value = {MMR_Scratch}; end
        default                                 : begin : get_reg_val_default get_register_value = 'x; end
    endcase
  end
endfunction

endmodule
