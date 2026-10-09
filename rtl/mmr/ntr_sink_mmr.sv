// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module ntr_sink_mmr
import ntr_sink_mmr_pkg::*;
`include "ntr_sink_mmr_pkg_list.svh"
`include "generic_macro_assertion.vh"
#(
    parameter BASE_ADDR    = 0,
    parameter ADDR_W       = 12,
    parameter ADDR_W_INDIR = 64,
    parameter FLOP_IN_REQ  = 1,
    parameter FLOP_RD_DATA = 1,
    parameter INSTR_TYPE_W = 2,

    parameter MMR_TRCUSTOMRAMSMEMLIMITLOW_F_TRCUSTOMRAMSMEMLIMITLOW_RESET_VALUE = 0
) (

input  logic                                    clk,
input  logic                                    reset_n,

input  logic                                    MmrCs,
input  logic                                    MmrWrEn,
input  logic                        [1:0]       MmrWrStrb,
input  logic                                    MmrRegSel,
input  logic                       [ADDR_W-1:0] MmrAddr,
input  logic                             [31:0] MmrWrData,
input  logic                 [INSTR_TYPE_W-1:0] MmrWrInstrType,
output logic                                    MmrWrReady,
output logic                                    MmrHit,
output NtrSinkMmrHit_s                           MmrHitList,
output logic                             [31:0] MmrRdData,

output NtrSinkTrramcontrolMmr_s                 NtrSinkMmrTrramcontrol,
output NtrSinkTrramimplMmr_s                    NtrSinkMmrTrramimpl,
output NtrSinkTrramstartlowMmr_s                NtrSinkMmrTrramstartlow,
output NtrSinkTrramstarthighMmr_s               NtrSinkMmrTrramstarthigh,
output NtrSinkTrramlimitlowMmr_s                NtrSinkMmrTrramlimitlow,
output NtrSinkTrramlimithighMmr_s               NtrSinkMmrTrramlimithigh,
output NtrSinkTrramwplowMmr_s                   NtrSinkMmrTrramwplow,
output NtrSinkTrramwphighMmr_s                  NtrSinkMmrTrramwphigh,
output NtrSinkTrramrplowMmr_s                   NtrSinkMmrTrramrplow,
output NtrSinkTrramrphighMmr_s                  NtrSinkMmrTrramrphigh,
output NtrSinkTrramdataMmr_s                    NtrSinkMmrTrramdata,
output NtrSinkTrcustomramsmemlimitlowMmr_s      NtrSinkMmrTrcustomramsmemlimitlow,
output NtrSinkScratchloMmr_s                    NtrSinkMmrScratchlo,
output NtrSinkScratchhiMmr_s                    NtrSinkMmrScratchhi,

input NtrSinkTrramcontrolMmrWr_s                NtrSinkMmrTrramcontrolWr,
input NtrSinkTrramstartlowMmrWr_s               NtrSinkMmrTrramstartlowWr,
input NtrSinkTrramstarthighMmrWr_s              NtrSinkMmrTrramstarthighWr,
input NtrSinkTrramlimitlowMmrWr_s               NtrSinkMmrTrramlimitlowWr,
input NtrSinkTrramlimithighMmrWr_s              NtrSinkMmrTrramlimithighWr,
input NtrSinkTrramwplowMmrWr_s                  NtrSinkMmrTrramwplowWr,
input NtrSinkTrramwphighMmrWr_s                 NtrSinkMmrTrramwphighWr,
input NtrSinkTrramrplowMmrWr_s                  NtrSinkMmrTrramrplowWr,
input NtrSinkTrramrphighMmrWr_s                 NtrSinkMmrTrramrphighWr,
input NtrSinkTrramdataMmrWr_s                   NtrSinkMmrTrramdataWr,

output logic                                    MmrUpdateEn,
output logic                       [ADDR_W-1:0] MmrUpdateAddr,
output logic                       [ADDR_W_INDIR-1:0] MmrUpdateIndirAddr,
output logic                             [31:0] MmrUpdateData

);

localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMCONTROL          = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMIMPL             = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMSTARTLOW         = ADDR_W'(BASE_ADDR + 'h10);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMSTARTHIGH        = ADDR_W'(BASE_ADDR + 'h14);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMLIMITLOW         = ADDR_W'(BASE_ADDR + 'h18);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMLIMITHIGH        = ADDR_W'(BASE_ADDR + 'h1C);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMWPLOW            = ADDR_W'(BASE_ADDR + 'h20);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMWPHIGH           = ADDR_W'(BASE_ADDR + 'h24);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMRPLOW            = ADDR_W'(BASE_ADDR + 'h28);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMRPHIGH           = ADDR_W'(BASE_ADDR + 'h2C);
localparam   [ADDR_W-1:0] ADDR_MMR_TRRAMDATA             = ADDR_W'(BASE_ADDR + 'h40);
localparam   [ADDR_W-1:0] ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW = ADDR_W'(BASE_ADDR + 'hE00);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHLO             = ADDR_W'(BASE_ADDR + 'hFF8);
localparam   [ADDR_W-1:0] ADDR_MMR_SCRATCHHI             = ADDR_W'(BASE_ADDR + 'hFFC);

logic                       reg_cs;
logic                       reg_wr_en;
logic           [1:0]       reg_wr_strb;
logic          [ADDR_W-1:0] reg_addr;
logic                       reg_wr_sel;
logic                       reg_rd_sel;
logic                [31:0] reg_wr_data;
logic    [INSTR_TYPE_W-1:0] reg_wr_instr_type;

logic                       reg_wr_ready;
NtrSinkMmrHit_s              reg_prehit;
logic                       reg_hit;
logic                [31:0] reg_rd_data;

logic                       reg_write;
logic                       reg_read;

logic          [ADDR_W-1:0] reg_addr_d1;
logic          [ADDR_W_INDIR-1:0] reg_addr_select_d1;
logic                       reg_write_d1;
logic                       reg_hit_d1;
logic                [31:0] reg_rd_data_d1;

logic                [31:0] MMR_Trramcontrol;
logic                [31:0] MMR_Trramimpl;
logic                [31:0] MMR_Trramstartlow;
logic                [31:0] MMR_Trramstarthigh;
logic                [31:0] MMR_Trramlimitlow;
logic                [31:0] MMR_Trramlimithigh;
logic                [31:0] MMR_Trramwplow;
logic                [31:0] MMR_Trramwphigh;
logic                [31:0] MMR_Trramrplow;
logic                [31:0] MMR_Trramrphigh;
logic                [31:0] MMR_Trramdata;
logic                [31:0] MMR_Trcustomramsmemlimitlow;
logic                [31:0] MMR_ScratchLo;
logic                [31:0] MMR_ScratchHi;

logic                [22:0] MMR_Trramcontrol_F_Rsvd319;
logic                 [0:0] MMR_Trramcontrol_F_Trramstoponwrap;
logic                 [2:0] MMR_Trramcontrol_F_Rsvd75;
logic                 [0:0] MMR_Trramcontrol_F_Trrammode;
logic                 [0:0] MMR_Trramcontrol_F_Trramempty;
logic                 [0:0] MMR_Trramcontrol_F_Rsvd22;
logic                 [0:0] MMR_Trramcontrol_F_Trramenable;
logic                 [0:0] MMR_Trramcontrol_F_Trramactive;
logic                 [3:0] MMR_Trramimpl_F_Rsvd3128;
logic                 [3:0] MMR_Trramimpl_F_Trramvendorframelength;
logic                 [9:0] MMR_Trramimpl_F_Rsvd2314;
logic                 [0:0] MMR_Trramimpl_F_Trramhassmem;
logic                 [0:0] MMR_Trramimpl_F_Trramhassram;
logic                 [3:0] MMR_Trramimpl_F_Trramcomptype;
logic                 [3:0] MMR_Trramimpl_F_Trramverminor;
logic                 [3:0] MMR_Trramimpl_F_Trramvermajor;
logic                [29:0] MMR_Trramstartlow_F_Trramstartlow;
logic                 [1:0] MMR_Trramstartlow_F_Rsvd10;
logic                [31:0] MMR_Trramstarthigh_F_Trramstarthigh;
logic                [29:0] MMR_Trramlimitlow_F_Trramlimitlow;
logic                 [1:0] MMR_Trramlimitlow_F_Rsvd10;
logic                [31:0] MMR_Trramlimithigh_F_Trramlimithigh;
logic                [29:0] MMR_Trramwplow_F_Trramwplow;
logic                 [0:0] MMR_Trramwplow_F_Rsvd11;
logic                 [0:0] MMR_Trramwplow_F_Trramwrap;
logic                [31:0] MMR_Trramwphigh_F_Trramwphigh;
logic                [29:0] MMR_Trramrplow_F_Trramrplow;
logic                 [1:0] MMR_Trramrplow_F_Rsvd10;
logic                [31:0] MMR_Trramrphigh_F_Trramrphigh;
logic                [31:0] MMR_Trramdata_F_Trramdata;
logic                [29:0] MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow;
logic                 [1:0] MMR_Trcustomramsmemlimitlow_F_Rsvd10;
logic                [31:0] MMR_ScratchLo_F_Data;
logic                [31:0] MMR_ScratchHi_F_Data;

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
        .WIDTH ($bits(logic [32-1:0])),
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

logic                                           MMR_Trramcontrol_F_Rsvd319_WrEn;
logic [NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH-1:0] MMR_Trramcontrol_F_Rsvd319_Data;
logic [NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH-1:0] MMR_Trramcontrol_F_Rsvd319_DataEff;
logic [NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH-1:0] MMR_Trramcontrol_F_Rsvd319_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH-1:0] MMR_Trramcontrol_F_Rsvd319_Data_prev;
assign MMR_Trramcontrol_F_Rsvd319_DataEff = {reg_wr_data[31:9]};
assign MMR_Trramcontrol_F_Rsvd319_Data = (NtrSinkMmrTrramcontrolWr.Data.Rsvd319);
assign MMR_Trramcontrol_F_Rsvd319_WrEn = ((NtrSinkMmrTrramcontrolWr.Rsvd319WrEn));
assign MMR_Trramcontrol_F_Rsvd319_Data_prev = MMR_Trramcontrol_F_Rsvd319;
assign MMR_Trramcontrol_F_Rsvd319_Data_muxed = MMR_Trramcontrol_F_Rsvd319_WrEn ? MMR_Trramcontrol_F_Rsvd319_Data : MMR_Trramcontrol_F_Rsvd319_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH'(0))
) MMR_Trramcontrol_F_Rsvd319_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Rsvd319_WrEn),
    .in    (MMR_Trramcontrol_F_Rsvd319_Data),
    .out   (MMR_Trramcontrol_F_Rsvd319)
);

logic                                           MMR_Trramcontrol_F_Trramstoponwrap_WrEn;
logic [NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH-1:0] MMR_Trramcontrol_F_Trramstoponwrap_Data;
logic [NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH-1:0] MMR_Trramcontrol_F_Trramstoponwrap_DataEff;
logic [NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH-1:0] MMR_Trramcontrol_F_Trramstoponwrap_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH-1:0] MMR_Trramcontrol_F_Trramstoponwrap_Data_prev;
assign MMR_Trramcontrol_F_Trramstoponwrap_DataEff = {reg_wr_data[8:8]};
assign MMR_Trramcontrol_F_Trramstoponwrap_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) ? NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH'(update_value(64'(MMR_Trramcontrol_F_Trramstoponwrap), 64'(MMR_Trramcontrol_F_Trramstoponwrap_DataEff[0:0]), reg_wr_instr_type)) : NtrSinkMmrTrramcontrolWr.Data.Trramstoponwrap);
assign MMR_Trramcontrol_F_Trramstoponwrap_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) | NtrSinkMmrTrramcontrolWr.TrramstoponwrapWrEn));
assign MMR_Trramcontrol_F_Trramstoponwrap_Data_prev = MMR_Trramcontrol_F_Trramstoponwrap;
assign MMR_Trramcontrol_F_Trramstoponwrap_Data_muxed = MMR_Trramcontrol_F_Trramstoponwrap_WrEn ? MMR_Trramcontrol_F_Trramstoponwrap_Data : MMR_Trramcontrol_F_Trramstoponwrap_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH'(0))
) MMR_Trramcontrol_F_Trramstoponwrap_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Trramstoponwrap_WrEn),
    .in    (MMR_Trramcontrol_F_Trramstoponwrap_Data),
    .out   (MMR_Trramcontrol_F_Trramstoponwrap)
);

logic                                           MMR_Trramcontrol_F_Rsvd75_WrEn;
logic [NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd75_Data;
logic [NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd75_DataEff;
logic [NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd75_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd75_Data_prev;
assign MMR_Trramcontrol_F_Rsvd75_DataEff = {reg_wr_data[7:5]};
assign MMR_Trramcontrol_F_Rsvd75_Data = (NtrSinkMmrTrramcontrolWr.Data.Rsvd75);
assign MMR_Trramcontrol_F_Rsvd75_WrEn = ((NtrSinkMmrTrramcontrolWr.Rsvd75WrEn));
assign MMR_Trramcontrol_F_Rsvd75_Data_prev = MMR_Trramcontrol_F_Rsvd75;
assign MMR_Trramcontrol_F_Rsvd75_Data_muxed = MMR_Trramcontrol_F_Rsvd75_WrEn ? MMR_Trramcontrol_F_Rsvd75_Data : MMR_Trramcontrol_F_Rsvd75_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH'(0))
) MMR_Trramcontrol_F_Rsvd75_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Rsvd75_WrEn),
    .in    (MMR_Trramcontrol_F_Rsvd75_Data),
    .out   (MMR_Trramcontrol_F_Rsvd75)
);

logic                                           MMR_Trramcontrol_F_Trrammode_WrEn;
logic [NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH-1:0] MMR_Trramcontrol_F_Trrammode_Data;
logic [NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH-1:0] MMR_Trramcontrol_F_Trrammode_DataEff;
logic [NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH-1:0] MMR_Trramcontrol_F_Trrammode_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH-1:0] MMR_Trramcontrol_F_Trrammode_Data_prev;
assign MMR_Trramcontrol_F_Trrammode_DataEff = {reg_wr_data[4:4]};
assign MMR_Trramcontrol_F_Trrammode_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) ? NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH'(update_value(64'(MMR_Trramcontrol_F_Trrammode), 64'(MMR_Trramcontrol_F_Trrammode_DataEff[0:0]), reg_wr_instr_type)) : NtrSinkMmrTrramcontrolWr.Data.Trrammode);
assign MMR_Trramcontrol_F_Trrammode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) | NtrSinkMmrTrramcontrolWr.TrrammodeWrEn));
assign MMR_Trramcontrol_F_Trrammode_Data_prev = MMR_Trramcontrol_F_Trrammode;
assign MMR_Trramcontrol_F_Trrammode_Data_muxed = MMR_Trramcontrol_F_Trrammode_WrEn ? MMR_Trramcontrol_F_Trrammode_Data : MMR_Trramcontrol_F_Trrammode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH'(0))
) MMR_Trramcontrol_F_Trrammode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Trrammode_WrEn),
    .in    (MMR_Trramcontrol_F_Trrammode_Data),
    .out   (MMR_Trramcontrol_F_Trrammode)
);

logic                                           MMR_Trramcontrol_F_Trramempty_WrEn;
logic [NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH-1:0] MMR_Trramcontrol_F_Trramempty_Data;
logic [NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH-1:0] MMR_Trramcontrol_F_Trramempty_DataEff;
logic [NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH-1:0] MMR_Trramcontrol_F_Trramempty_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH-1:0] MMR_Trramcontrol_F_Trramempty_Data_prev;
assign MMR_Trramcontrol_F_Trramempty_DataEff = {reg_wr_data[3:3]};
assign MMR_Trramcontrol_F_Trramempty_Data = (NtrSinkMmrTrramcontrolWr.Data.Trramempty);
assign MMR_Trramcontrol_F_Trramempty_WrEn = ((NtrSinkMmrTrramcontrolWr.TrramemptyWrEn));
assign MMR_Trramcontrol_F_Trramempty_Data_prev = MMR_Trramcontrol_F_Trramempty;
assign MMR_Trramcontrol_F_Trramempty_Data_muxed = MMR_Trramcontrol_F_Trramempty_WrEn ? MMR_Trramcontrol_F_Trramempty_Data : MMR_Trramcontrol_F_Trramempty_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH'(1))
) MMR_Trramcontrol_F_Trramempty_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Trramempty_WrEn),
    .in    (MMR_Trramcontrol_F_Trramempty_Data),
    .out   (MMR_Trramcontrol_F_Trramempty)
);

logic                                           MMR_Trramcontrol_F_Rsvd22_WrEn;
logic [NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd22_Data;
logic [NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd22_DataEff;
logic [NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd22_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH -1:0] MMR_Trramcontrol_F_Rsvd22_Data_prev;
assign MMR_Trramcontrol_F_Rsvd22_DataEff = {reg_wr_data[2:2]};
assign MMR_Trramcontrol_F_Rsvd22_Data = (NtrSinkMmrTrramcontrolWr.Data.Rsvd22);
assign MMR_Trramcontrol_F_Rsvd22_WrEn = ((NtrSinkMmrTrramcontrolWr.Rsvd22WrEn));
assign MMR_Trramcontrol_F_Rsvd22_Data_prev = MMR_Trramcontrol_F_Rsvd22;
assign MMR_Trramcontrol_F_Rsvd22_Data_muxed = MMR_Trramcontrol_F_Rsvd22_WrEn ? MMR_Trramcontrol_F_Rsvd22_Data : MMR_Trramcontrol_F_Rsvd22_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH'(0))
) MMR_Trramcontrol_F_Rsvd22_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Rsvd22_WrEn),
    .in    (MMR_Trramcontrol_F_Rsvd22_Data),
    .out   (MMR_Trramcontrol_F_Rsvd22)
);

logic                                           MMR_Trramcontrol_F_Trramenable_WrEn;
logic [NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH-1:0] MMR_Trramcontrol_F_Trramenable_Data;
logic [NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH-1:0] MMR_Trramcontrol_F_Trramenable_DataEff;
logic [NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH-1:0] MMR_Trramcontrol_F_Trramenable_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH-1:0] MMR_Trramcontrol_F_Trramenable_Data_prev;
assign MMR_Trramcontrol_F_Trramenable_DataEff = {reg_wr_data[1:1]};
assign MMR_Trramcontrol_F_Trramenable_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) ? NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH'(update_value(64'(MMR_Trramcontrol_F_Trramenable), 64'(MMR_Trramcontrol_F_Trramenable_DataEff[0:0]), reg_wr_instr_type)) : NtrSinkMmrTrramcontrolWr.Data.Trramenable);
assign MMR_Trramcontrol_F_Trramenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) | NtrSinkMmrTrramcontrolWr.TrramenableWrEn));
assign MMR_Trramcontrol_F_Trramenable_Data_prev = MMR_Trramcontrol_F_Trramenable;
assign MMR_Trramcontrol_F_Trramenable_Data_muxed = MMR_Trramcontrol_F_Trramenable_WrEn ? MMR_Trramcontrol_F_Trramenable_Data : MMR_Trramcontrol_F_Trramenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH'(0))
) MMR_Trramcontrol_F_Trramenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Trramenable_WrEn),
    .in    (MMR_Trramcontrol_F_Trramenable_Data),
    .out   (MMR_Trramcontrol_F_Trramenable)
);

logic                                           MMR_Trramcontrol_F_Trramactive_WrEn;
logic [NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH-1:0] MMR_Trramcontrol_F_Trramactive_Data;
logic [NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH-1:0] MMR_Trramcontrol_F_Trramactive_DataEff;
logic [NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH-1:0] MMR_Trramcontrol_F_Trramactive_Data_muxed;
logic [NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH-1:0] MMR_Trramcontrol_F_Trramactive_Data_prev;
assign MMR_Trramcontrol_F_Trramactive_DataEff = {reg_wr_data[0:0]};
assign MMR_Trramcontrol_F_Trramactive_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) ? NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH'(update_value(64'(MMR_Trramcontrol_F_Trramactive), 64'(MMR_Trramcontrol_F_Trramactive_DataEff[0:0]), reg_wr_instr_type)) : NtrSinkMmrTrramcontrolWr.Data.Trramactive);
assign MMR_Trramcontrol_F_Trramactive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMCONTROL)) | NtrSinkMmrTrramcontrolWr.TrramactiveWrEn));
assign MMR_Trramcontrol_F_Trramactive_Data_prev = MMR_Trramcontrol_F_Trramactive;
assign MMR_Trramcontrol_F_Trramactive_Data_muxed = MMR_Trramcontrol_F_Trramactive_WrEn ? MMR_Trramcontrol_F_Trramactive_Data : MMR_Trramcontrol_F_Trramactive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH'(0))
) MMR_Trramcontrol_F_Trramactive_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramcontrol_F_Trramactive_WrEn),
    .in    (MMR_Trramcontrol_F_Trramactive_Data),
    .out   (MMR_Trramcontrol_F_Trramactive)
);

assign MMR_Trramimpl_F_Rsvd3128 = 4'h0;

logic                                           MMR_Trramimpl_F_Trramvendorframelength_WrEn;
logic [NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trramimpl_F_Trramvendorframelength_Data;
logic [NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trramimpl_F_Trramvendorframelength_DataEff;
logic [NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trramimpl_F_Trramvendorframelength_Data_muxed;
logic [NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trramimpl_F_Trramvendorframelength_Data_prev;
assign MMR_Trramimpl_F_Trramvendorframelength_DataEff = {reg_wr_data[27:24]};
assign MMR_Trramimpl_F_Trramvendorframelength_Data = (NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH'(update_value(64'(MMR_Trramimpl_F_Trramvendorframelength), 64'(MMR_Trramimpl_F_Trramvendorframelength_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trramimpl_F_Trramvendorframelength_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMIMPL))));
assign MMR_Trramimpl_F_Trramvendorframelength_Data_prev = MMR_Trramimpl_F_Trramvendorframelength;
assign MMR_Trramimpl_F_Trramvendorframelength_Data_muxed = MMR_Trramimpl_F_Trramvendorframelength_WrEn ? MMR_Trramimpl_F_Trramvendorframelength_Data : MMR_Trramimpl_F_Trramvendorframelength_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH'(1))
) MMR_Trramimpl_F_Trramvendorframelength_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramimpl_F_Trramvendorframelength_WrEn),
    .in    (MMR_Trramimpl_F_Trramvendorframelength_Data),
    .out   (MMR_Trramimpl_F_Trramvendorframelength)
);

assign MMR_Trramimpl_F_Rsvd2314 = 10'h0;

assign MMR_Trramimpl_F_Trramhassmem = 1'h1;

assign MMR_Trramimpl_F_Trramhassram = 1'h1;

assign MMR_Trramimpl_F_Trramcomptype = 4'h9;

assign MMR_Trramimpl_F_Trramverminor = 4'h0;

assign MMR_Trramimpl_F_Trramvermajor = 4'h1;

logic                                           MMR_Trramstartlow_F_Trramstartlow_WrEn;
logic [NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH-1:0] MMR_Trramstartlow_F_Trramstartlow_Data;
logic [NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH-1:0] MMR_Trramstartlow_F_Trramstartlow_DataEff;
logic [NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH-1:0] MMR_Trramstartlow_F_Trramstartlow_Data_muxed;
logic [NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH-1:0] MMR_Trramstartlow_F_Trramstartlow_Data_prev;
assign MMR_Trramstartlow_F_Trramstartlow_DataEff = {reg_wr_data[31:2]};
assign MMR_Trramstartlow_F_Trramstartlow_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMSTARTLOW)) ? NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH'(update_value(64'(MMR_Trramstartlow_F_Trramstartlow), 64'(MMR_Trramstartlow_F_Trramstartlow_DataEff[29:0]), reg_wr_instr_type)) : NtrSinkMmrTrramstartlowWr.Data.Trramstartlow);
assign MMR_Trramstartlow_F_Trramstartlow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMSTARTLOW)) | NtrSinkMmrTrramstartlowWr.TrramstartlowWrEn));
assign MMR_Trramstartlow_F_Trramstartlow_Data_prev = MMR_Trramstartlow_F_Trramstartlow;
assign MMR_Trramstartlow_F_Trramstartlow_Data_muxed = MMR_Trramstartlow_F_Trramstartlow_WrEn ? MMR_Trramstartlow_F_Trramstartlow_Data : MMR_Trramstartlow_F_Trramstartlow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH'(0))
) MMR_Trramstartlow_F_Trramstartlow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramstartlow_F_Trramstartlow_WrEn),
    .in    (MMR_Trramstartlow_F_Trramstartlow_Data),
    .out   (MMR_Trramstartlow_F_Trramstartlow)
);

assign MMR_Trramstartlow_F_Rsvd10 = 2'h0;

logic                                           MMR_Trramstarthigh_F_Trramstarthigh_WrEn;
logic [NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH-1:0] MMR_Trramstarthigh_F_Trramstarthigh_Data;
logic [NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH-1:0] MMR_Trramstarthigh_F_Trramstarthigh_DataEff;
logic [NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH-1:0] MMR_Trramstarthigh_F_Trramstarthigh_Data_muxed;
logic [NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH-1:0] MMR_Trramstarthigh_F_Trramstarthigh_Data_prev;
assign MMR_Trramstarthigh_F_Trramstarthigh_DataEff = {reg_wr_data[31:0]};
assign MMR_Trramstarthigh_F_Trramstarthigh_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMSTARTHIGH)) ? NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH'(update_value(64'(MMR_Trramstarthigh_F_Trramstarthigh), 64'(MMR_Trramstarthigh_F_Trramstarthigh_DataEff[31:0]), reg_wr_instr_type)) : NtrSinkMmrTrramstarthighWr.Data.Trramstarthigh);
assign MMR_Trramstarthigh_F_Trramstarthigh_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMSTARTHIGH)) | NtrSinkMmrTrramstarthighWr.TrramstarthighWrEn));
assign MMR_Trramstarthigh_F_Trramstarthigh_Data_prev = MMR_Trramstarthigh_F_Trramstarthigh;
assign MMR_Trramstarthigh_F_Trramstarthigh_Data_muxed = MMR_Trramstarthigh_F_Trramstarthigh_WrEn ? MMR_Trramstarthigh_F_Trramstarthigh_Data : MMR_Trramstarthigh_F_Trramstarthigh_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH'(0))
) MMR_Trramstarthigh_F_Trramstarthigh_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramstarthigh_F_Trramstarthigh_WrEn),
    .in    (MMR_Trramstarthigh_F_Trramstarthigh_Data),
    .out   (MMR_Trramstarthigh_F_Trramstarthigh)
);

logic                                           MMR_Trramlimitlow_F_Trramlimitlow_WrEn;
logic [NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH-1:0] MMR_Trramlimitlow_F_Trramlimitlow_Data;
logic [NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH-1:0] MMR_Trramlimitlow_F_Trramlimitlow_DataEff;
logic [NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH-1:0] MMR_Trramlimitlow_F_Trramlimitlow_Data_muxed;
logic [NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH-1:0] MMR_Trramlimitlow_F_Trramlimitlow_Data_prev;
assign MMR_Trramlimitlow_F_Trramlimitlow_DataEff = {reg_wr_data[31:2]};
assign MMR_Trramlimitlow_F_Trramlimitlow_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMLIMITLOW)) ? NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH'(update_value(64'(MMR_Trramlimitlow_F_Trramlimitlow), 64'(MMR_Trramlimitlow_F_Trramlimitlow_DataEff[29:0]), reg_wr_instr_type)) : NtrSinkMmrTrramlimitlowWr.Data.Trramlimitlow);
assign MMR_Trramlimitlow_F_Trramlimitlow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMLIMITLOW)) | NtrSinkMmrTrramlimitlowWr.TrramlimitlowWrEn));
assign MMR_Trramlimitlow_F_Trramlimitlow_Data_prev = MMR_Trramlimitlow_F_Trramlimitlow;
assign MMR_Trramlimitlow_F_Trramlimitlow_Data_muxed = MMR_Trramlimitlow_F_Trramlimitlow_WrEn ? MMR_Trramlimitlow_F_Trramlimitlow_Data : MMR_Trramlimitlow_F_Trramlimitlow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH'(30'h2000))
) MMR_Trramlimitlow_F_Trramlimitlow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramlimitlow_F_Trramlimitlow_WrEn),
    .in    (MMR_Trramlimitlow_F_Trramlimitlow_Data),
    .out   (MMR_Trramlimitlow_F_Trramlimitlow)
);

assign MMR_Trramlimitlow_F_Rsvd10 = 2'h0;

logic                                           MMR_Trramlimithigh_F_Trramlimithigh_WrEn;
logic [NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH-1:0] MMR_Trramlimithigh_F_Trramlimithigh_Data;
logic [NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH-1:0] MMR_Trramlimithigh_F_Trramlimithigh_DataEff;
logic [NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH-1:0] MMR_Trramlimithigh_F_Trramlimithigh_Data_muxed;
logic [NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH-1:0] MMR_Trramlimithigh_F_Trramlimithigh_Data_prev;
assign MMR_Trramlimithigh_F_Trramlimithigh_DataEff = {reg_wr_data[31:0]};
assign MMR_Trramlimithigh_F_Trramlimithigh_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMLIMITHIGH)) ? NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH'(update_value(64'(MMR_Trramlimithigh_F_Trramlimithigh), 64'(MMR_Trramlimithigh_F_Trramlimithigh_DataEff[31:0]), reg_wr_instr_type)) : NtrSinkMmrTrramlimithighWr.Data.Trramlimithigh);
assign MMR_Trramlimithigh_F_Trramlimithigh_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMLIMITHIGH)) | NtrSinkMmrTrramlimithighWr.TrramlimithighWrEn));
assign MMR_Trramlimithigh_F_Trramlimithigh_Data_prev = MMR_Trramlimithigh_F_Trramlimithigh;
assign MMR_Trramlimithigh_F_Trramlimithigh_Data_muxed = MMR_Trramlimithigh_F_Trramlimithigh_WrEn ? MMR_Trramlimithigh_F_Trramlimithigh_Data : MMR_Trramlimithigh_F_Trramlimithigh_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH'(0))
) MMR_Trramlimithigh_F_Trramlimithigh_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramlimithigh_F_Trramlimithigh_WrEn),
    .in    (MMR_Trramlimithigh_F_Trramlimithigh_Data),
    .out   (MMR_Trramlimithigh_F_Trramlimithigh)
);

logic                                           MMR_Trramwplow_F_Trramwplow_WrEn;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH-1:0] MMR_Trramwplow_F_Trramwplow_Data;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH-1:0] MMR_Trramwplow_F_Trramwplow_DataEff;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH-1:0] MMR_Trramwplow_F_Trramwplow_Data_muxed;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH-1:0] MMR_Trramwplow_F_Trramwplow_Data_prev;
assign MMR_Trramwplow_F_Trramwplow_DataEff = {reg_wr_data[31:2]};
assign MMR_Trramwplow_F_Trramwplow_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMWPLOW)) ? NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH'(update_value(64'(MMR_Trramwplow_F_Trramwplow), 64'(MMR_Trramwplow_F_Trramwplow_DataEff[29:0]), reg_wr_instr_type)) : NtrSinkMmrTrramwplowWr.Data.Trramwplow);
assign MMR_Trramwplow_F_Trramwplow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMWPLOW)) | NtrSinkMmrTrramwplowWr.TrramwplowWrEn));
assign MMR_Trramwplow_F_Trramwplow_Data_prev = MMR_Trramwplow_F_Trramwplow;
assign MMR_Trramwplow_F_Trramwplow_Data_muxed = MMR_Trramwplow_F_Trramwplow_WrEn ? MMR_Trramwplow_F_Trramwplow_Data : MMR_Trramwplow_F_Trramwplow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH'(0))
) MMR_Trramwplow_F_Trramwplow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramwplow_F_Trramwplow_WrEn),
    .in    (MMR_Trramwplow_F_Trramwplow_Data),
    .out   (MMR_Trramwplow_F_Trramwplow)
);

logic                                           MMR_Trramwplow_F_Rsvd11_WrEn;
logic [NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH   -1:0] MMR_Trramwplow_F_Rsvd11_Data;
logic [NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH   -1:0] MMR_Trramwplow_F_Rsvd11_DataEff;
logic [NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH   -1:0] MMR_Trramwplow_F_Rsvd11_Data_muxed;
logic [NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH   -1:0] MMR_Trramwplow_F_Rsvd11_Data_prev;
assign MMR_Trramwplow_F_Rsvd11_DataEff = {reg_wr_data[1:1]};
assign MMR_Trramwplow_F_Rsvd11_Data = (NtrSinkMmrTrramwplowWr.Data.Rsvd11);
assign MMR_Trramwplow_F_Rsvd11_WrEn = ((NtrSinkMmrTrramwplowWr.Rsvd11WrEn));
assign MMR_Trramwplow_F_Rsvd11_Data_prev = MMR_Trramwplow_F_Rsvd11;
assign MMR_Trramwplow_F_Rsvd11_Data_muxed = MMR_Trramwplow_F_Rsvd11_WrEn ? MMR_Trramwplow_F_Rsvd11_Data : MMR_Trramwplow_F_Rsvd11_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH'(0))
) MMR_Trramwplow_F_Rsvd11_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramwplow_F_Rsvd11_WrEn),
    .in    (MMR_Trramwplow_F_Rsvd11_Data),
    .out   (MMR_Trramwplow_F_Rsvd11)
);

logic                                           MMR_Trramwplow_F_Trramwrap_WrEn;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH-1:0] MMR_Trramwplow_F_Trramwrap_Data;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH-1:0] MMR_Trramwplow_F_Trramwrap_DataEff;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH-1:0] MMR_Trramwplow_F_Trramwrap_Data_muxed;
logic [NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH-1:0] MMR_Trramwplow_F_Trramwrap_Data_prev;
assign MMR_Trramwplow_F_Trramwrap_DataEff = {reg_wr_data[0:0]};
assign MMR_Trramwplow_F_Trramwrap_Data = (NtrSinkMmrTrramwplowWr.Data.Trramwrap);
assign MMR_Trramwplow_F_Trramwrap_WrEn = ((NtrSinkMmrTrramwplowWr.TrramwrapWrEn));
assign MMR_Trramwplow_F_Trramwrap_Data_prev = MMR_Trramwplow_F_Trramwrap;
assign MMR_Trramwplow_F_Trramwrap_Data_muxed = MMR_Trramwplow_F_Trramwrap_WrEn ? MMR_Trramwplow_F_Trramwrap_Data : MMR_Trramwplow_F_Trramwrap_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH'(0))
) MMR_Trramwplow_F_Trramwrap_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramwplow_F_Trramwrap_WrEn),
    .in    (MMR_Trramwplow_F_Trramwrap_Data),
    .out   (MMR_Trramwplow_F_Trramwrap)
);

logic                                           MMR_Trramwphigh_F_Trramwphigh_WrEn;
logic [NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH-1:0] MMR_Trramwphigh_F_Trramwphigh_Data;
logic [NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH-1:0] MMR_Trramwphigh_F_Trramwphigh_DataEff;
logic [NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH-1:0] MMR_Trramwphigh_F_Trramwphigh_Data_muxed;
logic [NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH-1:0] MMR_Trramwphigh_F_Trramwphigh_Data_prev;
assign MMR_Trramwphigh_F_Trramwphigh_DataEff = {reg_wr_data[31:0]};
assign MMR_Trramwphigh_F_Trramwphigh_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMWPHIGH)) ? NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH'(update_value(64'(MMR_Trramwphigh_F_Trramwphigh), 64'(MMR_Trramwphigh_F_Trramwphigh_DataEff[31:0]), reg_wr_instr_type)) : NtrSinkMmrTrramwphighWr.Data.Trramwphigh);
assign MMR_Trramwphigh_F_Trramwphigh_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMWPHIGH)) | NtrSinkMmrTrramwphighWr.TrramwphighWrEn));
assign MMR_Trramwphigh_F_Trramwphigh_Data_prev = MMR_Trramwphigh_F_Trramwphigh;
assign MMR_Trramwphigh_F_Trramwphigh_Data_muxed = MMR_Trramwphigh_F_Trramwphigh_WrEn ? MMR_Trramwphigh_F_Trramwphigh_Data : MMR_Trramwphigh_F_Trramwphigh_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH'(0))
) MMR_Trramwphigh_F_Trramwphigh_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramwphigh_F_Trramwphigh_WrEn),
    .in    (MMR_Trramwphigh_F_Trramwphigh_Data),
    .out   (MMR_Trramwphigh_F_Trramwphigh)
);

logic                                           MMR_Trramrplow_F_Trramrplow_WrEn;
logic [NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH-1:0] MMR_Trramrplow_F_Trramrplow_Data;
logic [NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH-1:0] MMR_Trramrplow_F_Trramrplow_DataEff;
logic [NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH-1:0] MMR_Trramrplow_F_Trramrplow_Data_muxed;
logic [NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH-1:0] MMR_Trramrplow_F_Trramrplow_Data_prev;
assign MMR_Trramrplow_F_Trramrplow_DataEff = {reg_wr_data[31:2]};
assign MMR_Trramrplow_F_Trramrplow_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMRPLOW)) ? NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH'(update_value(64'(MMR_Trramrplow_F_Trramrplow), 64'(MMR_Trramrplow_F_Trramrplow_DataEff[29:0]), reg_wr_instr_type)) : NtrSinkMmrTrramrplowWr.Data.Trramrplow);
assign MMR_Trramrplow_F_Trramrplow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMRPLOW)) | NtrSinkMmrTrramrplowWr.TrramrplowWrEn));
assign MMR_Trramrplow_F_Trramrplow_Data_prev = MMR_Trramrplow_F_Trramrplow;
assign MMR_Trramrplow_F_Trramrplow_Data_muxed = MMR_Trramrplow_F_Trramrplow_WrEn ? MMR_Trramrplow_F_Trramrplow_Data : MMR_Trramrplow_F_Trramrplow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH'(0))
) MMR_Trramrplow_F_Trramrplow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramrplow_F_Trramrplow_WrEn),
    .in    (MMR_Trramrplow_F_Trramrplow_Data),
    .out   (MMR_Trramrplow_F_Trramrplow)
);

assign MMR_Trramrplow_F_Rsvd10 = 2'h0;

logic                                           MMR_Trramrphigh_F_Trramrphigh_WrEn;
logic [NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH-1:0] MMR_Trramrphigh_F_Trramrphigh_Data;
logic [NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH-1:0] MMR_Trramrphigh_F_Trramrphigh_DataEff;
logic [NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH-1:0] MMR_Trramrphigh_F_Trramrphigh_Data_muxed;
logic [NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH-1:0] MMR_Trramrphigh_F_Trramrphigh_Data_prev;
assign MMR_Trramrphigh_F_Trramrphigh_DataEff = {reg_wr_data[31:0]};
assign MMR_Trramrphigh_F_Trramrphigh_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMRPHIGH)) ? NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH'(update_value(64'(MMR_Trramrphigh_F_Trramrphigh), 64'(MMR_Trramrphigh_F_Trramrphigh_DataEff[31:0]), reg_wr_instr_type)) : NtrSinkMmrTrramrphighWr.Data.Trramrphigh);
assign MMR_Trramrphigh_F_Trramrphigh_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRRAMRPHIGH)) | NtrSinkMmrTrramrphighWr.TrramrphighWrEn));
assign MMR_Trramrphigh_F_Trramrphigh_Data_prev = MMR_Trramrphigh_F_Trramrphigh;
assign MMR_Trramrphigh_F_Trramrphigh_Data_muxed = MMR_Trramrphigh_F_Trramrphigh_WrEn ? MMR_Trramrphigh_F_Trramrphigh_Data : MMR_Trramrphigh_F_Trramrphigh_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH'(0))
) MMR_Trramrphigh_F_Trramrphigh_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramrphigh_F_Trramrphigh_WrEn),
    .in    (MMR_Trramrphigh_F_Trramrphigh_Data),
    .out   (MMR_Trramrphigh_F_Trramrphigh)
);

logic                                           MMR_Trramdata_F_Trramdata_WrEn;
logic [NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH -1:0] MMR_Trramdata_F_Trramdata_Data;
logic [NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH -1:0] MMR_Trramdata_F_Trramdata_DataEff;
logic [NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH -1:0] MMR_Trramdata_F_Trramdata_Data_muxed;
logic [NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH -1:0] MMR_Trramdata_F_Trramdata_Data_prev;
assign MMR_Trramdata_F_Trramdata_DataEff = {reg_wr_data[31:0]};
assign MMR_Trramdata_F_Trramdata_Data = (NtrSinkMmrTrramdataWr.Data.Trramdata);
assign MMR_Trramdata_F_Trramdata_WrEn = ((NtrSinkMmrTrramdataWr.TrramdataWrEn));
assign MMR_Trramdata_F_Trramdata_Data_prev = MMR_Trramdata_F_Trramdata;
assign MMR_Trramdata_F_Trramdata_Data_muxed = MMR_Trramdata_F_Trramdata_WrEn ? MMR_Trramdata_F_Trramdata_Data : MMR_Trramdata_F_Trramdata_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH'(0))
) MMR_Trramdata_F_Trramdata_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trramdata_F_Trramdata_WrEn),
    .in    (MMR_Trramdata_F_Trramdata_Data),
    .out   (MMR_Trramdata_F_Trramdata)
);

logic                                           MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_WrEn;
logic [NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH-1:0] MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data;
logic [NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH-1:0] MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_DataEff;
logic [NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH-1:0] MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_muxed;
logic [NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH-1:0] MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_prev;
assign MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_DataEff = {reg_wr_data[31:2]};
assign MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data = (NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH'(update_value(64'(MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow), 64'(MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_DataEff[29:0]), reg_wr_instr_type)));
assign MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW))));
assign MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_prev = MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow;
assign MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_muxed = MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_WrEn ? MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data : MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH'(MMR_TRCUSTOMRAMSMEMLIMITLOW_F_TRCUSTOMRAMSMEMLIMITLOW_RESET_VALUE))
) MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_WrEn),
    .in    (MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data),
    .out   (MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow)
);

assign MMR_Trcustomramsmemlimitlow_F_Rsvd10 = 2'h0;

logic                                           MMR_ScratchLo_F_Data_WrEn;
logic [NTR_SINK_SCRATCHLO_DATA_WIDTH      -1:0] MMR_ScratchLo_F_Data_Data;
logic [NTR_SINK_SCRATCHLO_DATA_WIDTH      -1:0] MMR_ScratchLo_F_Data_DataEff;
logic [NTR_SINK_SCRATCHLO_DATA_WIDTH      -1:0] MMR_ScratchLo_F_Data_Data_muxed;
logic [NTR_SINK_SCRATCHLO_DATA_WIDTH      -1:0] MMR_ScratchLo_F_Data_Data_prev;
assign MMR_ScratchLo_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchLo_F_Data_Data = (NTR_SINK_SCRATCHLO_DATA_WIDTH'(update_value(64'(MMR_ScratchLo_F_Data), 64'(MMR_ScratchLo_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchLo_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHLO))));
assign MMR_ScratchLo_F_Data_Data_prev = MMR_ScratchLo_F_Data;
assign MMR_ScratchLo_F_Data_Data_muxed = MMR_ScratchLo_F_Data_WrEn ? MMR_ScratchLo_F_Data_Data : MMR_ScratchLo_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_SCRATCHLO_DATA_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_SCRATCHLO_DATA_WIDTH'(0))
) MMR_ScratchLo_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchLo_F_Data_WrEn),
    .in    (MMR_ScratchLo_F_Data_Data),
    .out   (MMR_ScratchLo_F_Data)
);

logic                                           MMR_ScratchHi_F_Data_WrEn;
logic [NTR_SINK_SCRATCHHI_DATA_WIDTH      -1:0] MMR_ScratchHi_F_Data_Data;
logic [NTR_SINK_SCRATCHHI_DATA_WIDTH      -1:0] MMR_ScratchHi_F_Data_DataEff;
logic [NTR_SINK_SCRATCHHI_DATA_WIDTH      -1:0] MMR_ScratchHi_F_Data_Data_muxed;
logic [NTR_SINK_SCRATCHHI_DATA_WIDTH      -1:0] MMR_ScratchHi_F_Data_Data_prev;
assign MMR_ScratchHi_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchHi_F_Data_Data = (NTR_SINK_SCRATCHHI_DATA_WIDTH'(update_value(64'(MMR_ScratchHi_F_Data), 64'(MMR_ScratchHi_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchHi_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHHI))));
assign MMR_ScratchHi_F_Data_Data_prev = MMR_ScratchHi_F_Data;
assign MMR_ScratchHi_F_Data_Data_muxed = MMR_ScratchHi_F_Data_WrEn ? MMR_ScratchHi_F_Data_Data : MMR_ScratchHi_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SINK_SCRATCHHI_DATA_WIDTH-1:0])),
    .RESET_VALUE (NTR_SINK_SCRATCHHI_DATA_WIDTH'(0))
) MMR_ScratchHi_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchHi_F_Data_WrEn),
    .in    (MMR_ScratchHi_F_Data_Data),
    .out   (MMR_ScratchHi_F_Data)
);

assign MMR_Trramcontrol = {
    MMR_Trramcontrol_F_Rsvd319,
    MMR_Trramcontrol_F_Trramstoponwrap,
    MMR_Trramcontrol_F_Rsvd75,
    MMR_Trramcontrol_F_Trrammode,
    MMR_Trramcontrol_F_Trramempty,
    MMR_Trramcontrol_F_Rsvd22,
    MMR_Trramcontrol_F_Trramenable,
    MMR_Trramcontrol_F_Trramactive
};
logic [31:0] MMR_Trramcontrol_muxed;
assign MMR_Trramcontrol_muxed = {
    MMR_Trramcontrol_F_Rsvd319_Data_muxed,
    MMR_Trramcontrol_F_Trramstoponwrap_Data_muxed,
    MMR_Trramcontrol_F_Rsvd75_Data_muxed,
    MMR_Trramcontrol_F_Trrammode_Data_muxed,
    MMR_Trramcontrol_F_Trramempty_Data_muxed,
    MMR_Trramcontrol_F_Rsvd22_Data_muxed,
    MMR_Trramcontrol_F_Trramenable_Data_muxed,
    MMR_Trramcontrol_F_Trramactive_Data_muxed
};
assign MMR_Trramimpl = {
    MMR_Trramimpl_F_Rsvd3128,
    MMR_Trramimpl_F_Trramvendorframelength,
    MMR_Trramimpl_F_Rsvd2314,
    MMR_Trramimpl_F_Trramhassmem,
    MMR_Trramimpl_F_Trramhassram,
    MMR_Trramimpl_F_Trramcomptype,
    MMR_Trramimpl_F_Trramverminor,
    MMR_Trramimpl_F_Trramvermajor
};
logic [31:0] MMR_Trramimpl_muxed;
assign MMR_Trramimpl_muxed = {
    MMR_Trramimpl_F_Rsvd3128,
    MMR_Trramimpl_F_Trramvendorframelength_Data_muxed,
    MMR_Trramimpl_F_Rsvd2314,
    MMR_Trramimpl_F_Trramhassmem,
    MMR_Trramimpl_F_Trramhassram,
    MMR_Trramimpl_F_Trramcomptype,
    MMR_Trramimpl_F_Trramverminor,
    MMR_Trramimpl_F_Trramvermajor
};
assign MMR_Trramstartlow = {
    MMR_Trramstartlow_F_Trramstartlow,
    MMR_Trramstartlow_F_Rsvd10
};
logic [31:0] MMR_Trramstartlow_muxed;
assign MMR_Trramstartlow_muxed = {
    MMR_Trramstartlow_F_Trramstartlow_Data_muxed,
    MMR_Trramstartlow_F_Rsvd10
};
assign MMR_Trramstarthigh = {
    MMR_Trramstarthigh_F_Trramstarthigh
};
logic [31:0] MMR_Trramstarthigh_muxed;
assign MMR_Trramstarthigh_muxed = {
    MMR_Trramstarthigh_F_Trramstarthigh_Data_muxed
};
assign MMR_Trramlimitlow = {
    MMR_Trramlimitlow_F_Trramlimitlow,
    MMR_Trramlimitlow_F_Rsvd10
};
logic [31:0] MMR_Trramlimitlow_muxed;
assign MMR_Trramlimitlow_muxed = {
    MMR_Trramlimitlow_F_Trramlimitlow_Data_muxed,
    MMR_Trramlimitlow_F_Rsvd10
};
assign MMR_Trramlimithigh = {
    MMR_Trramlimithigh_F_Trramlimithigh
};
logic [31:0] MMR_Trramlimithigh_muxed;
assign MMR_Trramlimithigh_muxed = {
    MMR_Trramlimithigh_F_Trramlimithigh_Data_muxed
};
assign MMR_Trramwplow = {
    MMR_Trramwplow_F_Trramwplow,
    MMR_Trramwplow_F_Rsvd11,
    MMR_Trramwplow_F_Trramwrap
};
logic [31:0] MMR_Trramwplow_muxed;
assign MMR_Trramwplow_muxed = {
    MMR_Trramwplow_F_Trramwplow_Data_muxed,
    MMR_Trramwplow_F_Rsvd11_Data_muxed,
    MMR_Trramwplow_F_Trramwrap_Data_muxed
};
assign MMR_Trramwphigh = {
    MMR_Trramwphigh_F_Trramwphigh
};
logic [31:0] MMR_Trramwphigh_muxed;
assign MMR_Trramwphigh_muxed = {
    MMR_Trramwphigh_F_Trramwphigh_Data_muxed
};
assign MMR_Trramrplow = {
    MMR_Trramrplow_F_Trramrplow,
    MMR_Trramrplow_F_Rsvd10
};
logic [31:0] MMR_Trramrplow_muxed;
assign MMR_Trramrplow_muxed = {
    MMR_Trramrplow_F_Trramrplow_Data_muxed,
    MMR_Trramrplow_F_Rsvd10
};
assign MMR_Trramrphigh = {
    MMR_Trramrphigh_F_Trramrphigh
};
logic [31:0] MMR_Trramrphigh_muxed;
assign MMR_Trramrphigh_muxed = {
    MMR_Trramrphigh_F_Trramrphigh_Data_muxed
};
assign MMR_Trramdata = {
    MMR_Trramdata_F_Trramdata
};
logic [31:0] MMR_Trramdata_muxed;
assign MMR_Trramdata_muxed = {
    MMR_Trramdata_F_Trramdata_Data_muxed
};
assign MMR_Trcustomramsmemlimitlow = {
    MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow,
    MMR_Trcustomramsmemlimitlow_F_Rsvd10
};
logic [31:0] MMR_Trcustomramsmemlimitlow_muxed;
assign MMR_Trcustomramsmemlimitlow_muxed = {
    MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow_Data_muxed,
    MMR_Trcustomramsmemlimitlow_F_Rsvd10
};
assign MMR_ScratchLo = {
    MMR_ScratchLo_F_Data
};
logic [31:0] MMR_ScratchLo_muxed;
assign MMR_ScratchLo_muxed = {
    MMR_ScratchLo_F_Data_Data_muxed
};
assign MMR_ScratchHi = {
    MMR_ScratchHi_F_Data
};
logic [31:0] MMR_ScratchHi_muxed;
assign MMR_ScratchHi_muxed = {
    MMR_ScratchHi_F_Data_Data_muxed
};

always_comb begin : mmr_rd_comb
    reg_prehit  = '0;
    reg_rd_data = '0;
    unique case (reg_addr)
        ADDR_MMR_TRRAMCONTROL                   : begin : mmr_rd_hit_MMR_Trramcontrol reg_prehit.NtrSinkMmrTrramcontrolHit = 1'b1; reg_rd_data = {MMR_Trramcontrol}; end
        ADDR_MMR_TRRAMIMPL                      : begin : mmr_rd_hit_MMR_Trramimpl reg_prehit.NtrSinkMmrTrramimplHit = 1'b1; reg_rd_data = {MMR_Trramimpl}; end
        ADDR_MMR_TRRAMSTARTLOW                  : begin : mmr_rd_hit_MMR_Trramstartlow reg_prehit.NtrSinkMmrTrramstartlowHit = 1'b1; reg_rd_data = {MMR_Trramstartlow}; end
        ADDR_MMR_TRRAMSTARTHIGH                 : begin : mmr_rd_hit_MMR_Trramstarthigh reg_prehit.NtrSinkMmrTrramstarthighHit = 1'b1; reg_rd_data = {MMR_Trramstarthigh}; end
        ADDR_MMR_TRRAMLIMITLOW                  : begin : mmr_rd_hit_MMR_Trramlimitlow reg_prehit.NtrSinkMmrTrramlimitlowHit = 1'b1; reg_rd_data = {MMR_Trramlimitlow}; end
        ADDR_MMR_TRRAMLIMITHIGH                 : begin : mmr_rd_hit_MMR_Trramlimithigh reg_prehit.NtrSinkMmrTrramlimithighHit = 1'b1; reg_rd_data = {MMR_Trramlimithigh}; end
        ADDR_MMR_TRRAMWPLOW                     : begin : mmr_rd_hit_MMR_Trramwplow reg_prehit.NtrSinkMmrTrramwplowHit = 1'b1; reg_rd_data = {MMR_Trramwplow}; end
        ADDR_MMR_TRRAMWPHIGH                    : begin : mmr_rd_hit_MMR_Trramwphigh reg_prehit.NtrSinkMmrTrramwphighHit = 1'b1; reg_rd_data = {MMR_Trramwphigh}; end
        ADDR_MMR_TRRAMRPLOW                     : begin : mmr_rd_hit_MMR_Trramrplow reg_prehit.NtrSinkMmrTrramrplowHit = 1'b1; reg_rd_data = {MMR_Trramrplow}; end
        ADDR_MMR_TRRAMRPHIGH                    : begin : mmr_rd_hit_MMR_Trramrphigh reg_prehit.NtrSinkMmrTrramrphighHit = 1'b1; reg_rd_data = {MMR_Trramrphigh}; end
        ADDR_MMR_TRRAMDATA                      : begin : mmr_rd_hit_MMR_Trramdata reg_prehit.NtrSinkMmrTrramdataHit = 1'b1; reg_rd_data = {MMR_Trramdata}; end
        ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW        : begin : mmr_rd_hit_MMR_Trcustomramsmemlimitlow reg_prehit.NtrSinkMmrTrcustomramsmemlimitlowHit = 1'b1; reg_rd_data = {MMR_Trcustomramsmemlimitlow}; end
        ADDR_MMR_SCRATCHLO                      : begin : mmr_rd_hit_MMR_ScratchLo reg_prehit.NtrSinkMmrScratchloHit = 1'b1; reg_rd_data = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : mmr_rd_hit_MMR_ScratchHi reg_prehit.NtrSinkMmrScratchhiHit = 1'b1; reg_rd_data = {MMR_ScratchHi}; end
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
        ADDR_MMR_TRRAMCONTROL                   : begin : mmr_rd_d1_MMR_Trramcontrol reg_rd_data_d1 = {MMR_Trramcontrol}; end
        ADDR_MMR_TRRAMIMPL                      : begin : mmr_rd_d1_MMR_Trramimpl reg_rd_data_d1 = {MMR_Trramimpl}; end
        ADDR_MMR_TRRAMSTARTLOW                  : begin : mmr_rd_d1_MMR_Trramstartlow reg_rd_data_d1 = {MMR_Trramstartlow}; end
        ADDR_MMR_TRRAMSTARTHIGH                 : begin : mmr_rd_d1_MMR_Trramstarthigh reg_rd_data_d1 = {MMR_Trramstarthigh}; end
        ADDR_MMR_TRRAMLIMITLOW                  : begin : mmr_rd_d1_MMR_Trramlimitlow reg_rd_data_d1 = {MMR_Trramlimitlow}; end
        ADDR_MMR_TRRAMLIMITHIGH                 : begin : mmr_rd_d1_MMR_Trramlimithigh reg_rd_data_d1 = {MMR_Trramlimithigh}; end
        ADDR_MMR_TRRAMWPLOW                     : begin : mmr_rd_d1_MMR_Trramwplow reg_rd_data_d1 = {MMR_Trramwplow}; end
        ADDR_MMR_TRRAMWPHIGH                    : begin : mmr_rd_d1_MMR_Trramwphigh reg_rd_data_d1 = {MMR_Trramwphigh}; end
        ADDR_MMR_TRRAMRPLOW                     : begin : mmr_rd_d1_MMR_Trramrplow reg_rd_data_d1 = {MMR_Trramrplow}; end
        ADDR_MMR_TRRAMRPHIGH                    : begin : mmr_rd_d1_MMR_Trramrphigh reg_rd_data_d1 = {MMR_Trramrphigh}; end
        ADDR_MMR_TRRAMDATA                      : begin : mmr_rd_d1_MMR_Trramdata reg_rd_data_d1 = {MMR_Trramdata}; end
        ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW        : begin : mmr_rd_d1_MMR_Trcustomramsmemlimitlow reg_rd_data_d1 = {MMR_Trcustomramsmemlimitlow}; end
        ADDR_MMR_SCRATCHLO                      : begin : mmr_rd_d1_MMR_ScratchLo reg_rd_data_d1 = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : mmr_rd_d1_MMR_ScratchHi reg_rd_data_d1 = {MMR_ScratchHi}; end
        default:  begin : mmr_rd_d1_default
            reg_rd_data_d1 = '0;
        end
    endcase
end

assign MmrWrReady = reg_wr_ready;

if (FLOP_RD_DATA) begin : flop_rd_data
    assign MmrHit     = reg_hit_d1;
    generic_dff #(
        .WIDTH ($bits(logic [NTR_SINK_NUM_REGISTERS-1:0])),
        .RESET_VALUE (0)
    ) Mmr_Hit_List_ff (
        .clk (clk),
        .rst_n (reset_n),
        .en (reg_cs | MmrHit),
        .in (reg_prehit),
        .out (MmrHitList)
    );
    generic_dff #(
        .WIDTH ($bits(logic [32-1:0])),
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

assign NtrSinkMmrTrramcontrol.Rsvd319           = MMR_Trramcontrol_F_Rsvd319;
assign NtrSinkMmrTrramcontrol.Trramstoponwrap   = MMR_Trramcontrol_F_Trramstoponwrap;
assign NtrSinkMmrTrramcontrol.Rsvd75            = MMR_Trramcontrol_F_Rsvd75;
assign NtrSinkMmrTrramcontrol.Trrammode         = MMR_Trramcontrol_F_Trrammode;
assign NtrSinkMmrTrramcontrol.Trramempty        = MMR_Trramcontrol_F_Trramempty;
assign NtrSinkMmrTrramcontrol.Rsvd22            = MMR_Trramcontrol_F_Rsvd22;
assign NtrSinkMmrTrramcontrol.Trramenable       = MMR_Trramcontrol_F_Trramenable;
assign NtrSinkMmrTrramcontrol.Trramactive       = MMR_Trramcontrol_F_Trramactive;
assign NtrSinkMmrTrramimpl.Rsvd3128             = MMR_Trramimpl_F_Rsvd3128;
assign NtrSinkMmrTrramimpl.Trramvendorframelength = MMR_Trramimpl_F_Trramvendorframelength;
assign NtrSinkMmrTrramimpl.Rsvd2314             = MMR_Trramimpl_F_Rsvd2314;
assign NtrSinkMmrTrramimpl.Trramhassmem         = MMR_Trramimpl_F_Trramhassmem;
assign NtrSinkMmrTrramimpl.Trramhassram         = MMR_Trramimpl_F_Trramhassram;
assign NtrSinkMmrTrramimpl.Trramcomptype        = MMR_Trramimpl_F_Trramcomptype;
assign NtrSinkMmrTrramimpl.Trramverminor        = MMR_Trramimpl_F_Trramverminor;
assign NtrSinkMmrTrramimpl.Trramvermajor        = MMR_Trramimpl_F_Trramvermajor;
assign NtrSinkMmrTrramstartlow.Trramstartlow    = MMR_Trramstartlow_F_Trramstartlow;
assign NtrSinkMmrTrramstartlow.Rsvd10           = MMR_Trramstartlow_F_Rsvd10;
assign NtrSinkMmrTrramstarthigh.Trramstarthigh  = MMR_Trramstarthigh_F_Trramstarthigh;
assign NtrSinkMmrTrramlimitlow.Trramlimitlow    = MMR_Trramlimitlow_F_Trramlimitlow;
assign NtrSinkMmrTrramlimitlow.Rsvd10           = MMR_Trramlimitlow_F_Rsvd10;
assign NtrSinkMmrTrramlimithigh.Trramlimithigh  = MMR_Trramlimithigh_F_Trramlimithigh;
assign NtrSinkMmrTrramwplow.Trramwplow          = MMR_Trramwplow_F_Trramwplow;
assign NtrSinkMmrTrramwplow.Rsvd11              = MMR_Trramwplow_F_Rsvd11;
assign NtrSinkMmrTrramwplow.Trramwrap           = MMR_Trramwplow_F_Trramwrap;
assign NtrSinkMmrTrramwphigh.Trramwphigh        = MMR_Trramwphigh_F_Trramwphigh;
assign NtrSinkMmrTrramrplow.Trramrplow          = MMR_Trramrplow_F_Trramrplow;
assign NtrSinkMmrTrramrplow.Rsvd10              = MMR_Trramrplow_F_Rsvd10;
assign NtrSinkMmrTrramrphigh.Trramrphigh        = MMR_Trramrphigh_F_Trramrphigh;
assign NtrSinkMmrTrramdata.Trramdata            = MMR_Trramdata_F_Trramdata;
assign NtrSinkMmrTrcustomramsmemlimitlow.Trcustomramsmemlimitlow = MMR_Trcustomramsmemlimitlow_F_Trcustomramsmemlimitlow;
assign NtrSinkMmrTrcustomramsmemlimitlow.Rsvd10 = MMR_Trcustomramsmemlimitlow_F_Rsvd10;
assign NtrSinkMmrScratchlo.Data                 = MMR_ScratchLo_F_Data;
assign NtrSinkMmrScratchhi.Data                 = MMR_ScratchHi_F_Data;

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

function automatic [31:0] get_register_value;
input [ADDR_W-1:0] addr;
  begin : get_reg_val_body
    unique case (addr)
        ADDR_MMR_TRRAMCONTROL                   : begin : get_reg_val_MMR_Trramcontrol get_register_value = {MMR_Trramcontrol}; end
        ADDR_MMR_TRRAMIMPL                      : begin : get_reg_val_MMR_Trramimpl get_register_value = {MMR_Trramimpl}; end
        ADDR_MMR_TRRAMSTARTLOW                  : begin : get_reg_val_MMR_Trramstartlow get_register_value = {MMR_Trramstartlow}; end
        ADDR_MMR_TRRAMSTARTHIGH                 : begin : get_reg_val_MMR_Trramstarthigh get_register_value = {MMR_Trramstarthigh}; end
        ADDR_MMR_TRRAMLIMITLOW                  : begin : get_reg_val_MMR_Trramlimitlow get_register_value = {MMR_Trramlimitlow}; end
        ADDR_MMR_TRRAMLIMITHIGH                 : begin : get_reg_val_MMR_Trramlimithigh get_register_value = {MMR_Trramlimithigh}; end
        ADDR_MMR_TRRAMWPLOW                     : begin : get_reg_val_MMR_Trramwplow get_register_value = {MMR_Trramwplow}; end
        ADDR_MMR_TRRAMWPHIGH                    : begin : get_reg_val_MMR_Trramwphigh get_register_value = {MMR_Trramwphigh}; end
        ADDR_MMR_TRRAMRPLOW                     : begin : get_reg_val_MMR_Trramrplow get_register_value = {MMR_Trramrplow}; end
        ADDR_MMR_TRRAMRPHIGH                    : begin : get_reg_val_MMR_Trramrphigh get_register_value = {MMR_Trramrphigh}; end
        ADDR_MMR_TRRAMDATA                      : begin : get_reg_val_MMR_Trramdata get_register_value = {MMR_Trramdata}; end
        ADDR_MMR_TRCUSTOMRAMSMEMLIMITLOW        : begin : get_reg_val_MMR_Trcustomramsmemlimitlow get_register_value = {MMR_Trcustomramsmemlimitlow}; end
        ADDR_MMR_SCRATCHLO                      : begin : get_reg_val_MMR_ScratchLo get_register_value = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : get_reg_val_MMR_ScratchHi get_register_value = {MMR_ScratchHi}; end
        default                                 : begin : get_reg_val_default get_register_value = 'x; end
    endcase
  end
endfunction

endmodule
