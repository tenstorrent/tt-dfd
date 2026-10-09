// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module funnel_mmr
import funnel_mmr_pkg::*;
`include "funnel_mmr_pkg_list.svh"
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

input  logic                                    MmrCs,
input  logic                                    MmrWrEn,
input  logic                        [1:0]       MmrWrStrb,
input  logic                                    MmrRegSel,
input  logic                       [ADDR_W-1:0] MmrAddr,
input  logic                             [31:0] MmrWrData,
input  logic                 [INSTR_TYPE_W-1:0] MmrWrInstrType,
output logic                                    MmrWrReady,
output logic                                    MmrHit,
output FunnelMmrHit_s                           MmrHitList,
output logic                             [31:0] MmrRdData,

output FunnelTrfunnelcontrolMmr_s               FunnelMmrTrfunnelcontrol,
output FunnelTrfunnelimplMmr_s                  FunnelMmrTrfunnelimpl,
output FunnelTrfunneldisinputMmr_s              FunnelMmrTrfunneldisinput,
output FunnelScratchloMmr_s                     FunnelMmrScratchlo,
output FunnelScratchhiMmr_s                     FunnelMmrScratchhi,

input FunnelTrfunnelcontrolMmrWr_s              FunnelMmrTrfunnelcontrolWr,
input FunnelTrfunneldisinputMmrWr_s             FunnelMmrTrfunneldisinputWr,

output logic                                    MmrUpdateEn,
output logic                       [ADDR_W-1:0] MmrUpdateAddr,
output logic                       [ADDR_W_INDIR-1:0] MmrUpdateIndirAddr,
output logic                             [31:0] MmrUpdateData

);

localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELCONTROL       = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELIMPL          = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRFUNNELDISINPUT      = ADDR_W'(BASE_ADDR + 'h8);
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
FunnelMmrHit_s              reg_prehit;
logic                       reg_hit;
logic                [31:0] reg_rd_data;

logic                       reg_write;
logic                       reg_read;

logic          [ADDR_W-1:0] reg_addr_d1;
logic          [ADDR_W_INDIR-1:0] reg_addr_select_d1;
logic                       reg_write_d1;
logic                       reg_hit_d1;
logic                [31:0] reg_rd_data_d1;

logic                [31:0] MMR_Trfunnelcontrol;
logic                [31:0] MMR_Trfunnelimpl;
logic                [31:0] MMR_Trfunneldisinput;
logic                [31:0] MMR_ScratchLo;
logic                [31:0] MMR_ScratchHi;

logic                [27:0] MMR_Trfunnelcontrol_F_Rsvd314;
logic                 [0:0] MMR_Trfunnelcontrol_F_Trfunnelempty;
logic                 [0:0] MMR_Trfunnelcontrol_F_Rsvd22;
logic                 [0:0] MMR_Trfunnelcontrol_F_Trfunnelenable;
logic                 [0:0] MMR_Trfunnelcontrol_F_Trfunnelactive;
logic                [19:0] MMR_Trfunnelimpl_F_Rsvd3112;
logic                 [3:0] MMR_Trfunnelimpl_F_Trfunnelcomptype;
logic                 [3:0] MMR_Trfunnelimpl_F_Trfunnelverminor;
logic                 [3:0] MMR_Trfunnelimpl_F_Trfunnelvermajor;
logic                [15:0] MMR_Trfunneldisinput_F_Rsvd3116;
logic                [15:0] MMR_Trfunneldisinput_F_Trfunneldisinput;
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

logic                                           MMR_Trfunnelcontrol_F_Rsvd314_WrEn;
logic [FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd314_Data;
logic [FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd314_DataEff;
logic [FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd314_Data_muxed;
logic [FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd314_Data_prev;
assign MMR_Trfunnelcontrol_F_Rsvd314_DataEff = {reg_wr_data[31:4]};
assign MMR_Trfunnelcontrol_F_Rsvd314_Data = (FunnelMmrTrfunnelcontrolWr.Data.Rsvd314);
assign MMR_Trfunnelcontrol_F_Rsvd314_WrEn = ((FunnelMmrTrfunnelcontrolWr.Rsvd314WrEn));
assign MMR_Trfunnelcontrol_F_Rsvd314_Data_prev = MMR_Trfunnelcontrol_F_Rsvd314;
assign MMR_Trfunnelcontrol_F_Rsvd314_Data_muxed = MMR_Trfunnelcontrol_F_Rsvd314_WrEn ? MMR_Trfunnelcontrol_F_Rsvd314_Data : MMR_Trfunnelcontrol_F_Rsvd314_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELCONTROL_RSVD314_WIDTH'(0))
) MMR_Trfunnelcontrol_F_Rsvd314_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunnelcontrol_F_Rsvd314_WrEn),
    .in    (MMR_Trfunnelcontrol_F_Rsvd314_Data),
    .out   (MMR_Trfunnelcontrol_F_Rsvd314)
);

logic                                           MMR_Trfunnelcontrol_F_Trfunnelempty_WrEn;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelempty_Data;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelempty_DataEff;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelempty_Data_muxed;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelempty_Data_prev;
assign MMR_Trfunnelcontrol_F_Trfunnelempty_DataEff = {reg_wr_data[3:3]};
assign MMR_Trfunnelcontrol_F_Trfunnelempty_Data = (FunnelMmrTrfunnelcontrolWr.Data.Trfunnelempty);
assign MMR_Trfunnelcontrol_F_Trfunnelempty_WrEn = ((FunnelMmrTrfunnelcontrolWr.TrfunnelemptyWrEn));
assign MMR_Trfunnelcontrol_F_Trfunnelempty_Data_prev = MMR_Trfunnelcontrol_F_Trfunnelempty;
assign MMR_Trfunnelcontrol_F_Trfunnelempty_Data_muxed = MMR_Trfunnelcontrol_F_Trfunnelempty_WrEn ? MMR_Trfunnelcontrol_F_Trfunnelempty_Data : MMR_Trfunnelcontrol_F_Trfunnelempty_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELCONTROL_TRFUNNELEMPTY_WIDTH'(1))
) MMR_Trfunnelcontrol_F_Trfunnelempty_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunnelcontrol_F_Trfunnelempty_WrEn),
    .in    (MMR_Trfunnelcontrol_F_Trfunnelempty_Data),
    .out   (MMR_Trfunnelcontrol_F_Trfunnelempty)
);

logic                                           MMR_Trfunnelcontrol_F_Rsvd22_WrEn;
logic [FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd22_Data;
logic [FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd22_DataEff;
logic [FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd22_Data_muxed;
logic [FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH-1:0] MMR_Trfunnelcontrol_F_Rsvd22_Data_prev;
assign MMR_Trfunnelcontrol_F_Rsvd22_DataEff = {reg_wr_data[2:2]};
assign MMR_Trfunnelcontrol_F_Rsvd22_Data = (FunnelMmrTrfunnelcontrolWr.Data.Rsvd22);
assign MMR_Trfunnelcontrol_F_Rsvd22_WrEn = ((FunnelMmrTrfunnelcontrolWr.Rsvd22WrEn));
assign MMR_Trfunnelcontrol_F_Rsvd22_Data_prev = MMR_Trfunnelcontrol_F_Rsvd22;
assign MMR_Trfunnelcontrol_F_Rsvd22_Data_muxed = MMR_Trfunnelcontrol_F_Rsvd22_WrEn ? MMR_Trfunnelcontrol_F_Rsvd22_Data : MMR_Trfunnelcontrol_F_Rsvd22_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELCONTROL_RSVD22_WIDTH'(0))
) MMR_Trfunnelcontrol_F_Rsvd22_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunnelcontrol_F_Rsvd22_WrEn),
    .in    (MMR_Trfunnelcontrol_F_Rsvd22_Data),
    .out   (MMR_Trfunnelcontrol_F_Rsvd22)
);

logic                                           MMR_Trfunnelcontrol_F_Trfunnelenable_WrEn;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelenable_Data;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelenable_DataEff;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelenable_Data_muxed;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelenable_Data_prev;
assign MMR_Trfunnelcontrol_F_Trfunnelenable_DataEff = {reg_wr_data[1:1]};
assign MMR_Trfunnelcontrol_F_Trfunnelenable_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELCONTROL)) ? FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH'(update_value(64'(MMR_Trfunnelcontrol_F_Trfunnelenable), 64'(MMR_Trfunnelcontrol_F_Trfunnelenable_DataEff[0:0]), reg_wr_instr_type)) : FunnelMmrTrfunnelcontrolWr.Data.Trfunnelenable);
assign MMR_Trfunnelcontrol_F_Trfunnelenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELCONTROL)) | FunnelMmrTrfunnelcontrolWr.TrfunnelenableWrEn));
assign MMR_Trfunnelcontrol_F_Trfunnelenable_Data_prev = MMR_Trfunnelcontrol_F_Trfunnelenable;
assign MMR_Trfunnelcontrol_F_Trfunnelenable_Data_muxed = MMR_Trfunnelcontrol_F_Trfunnelenable_WrEn ? MMR_Trfunnelcontrol_F_Trfunnelenable_Data : MMR_Trfunnelcontrol_F_Trfunnelenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELCONTROL_TRFUNNELENABLE_WIDTH'(0))
) MMR_Trfunnelcontrol_F_Trfunnelenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunnelcontrol_F_Trfunnelenable_WrEn),
    .in    (MMR_Trfunnelcontrol_F_Trfunnelenable_Data),
    .out   (MMR_Trfunnelcontrol_F_Trfunnelenable)
);

logic                                           MMR_Trfunnelcontrol_F_Trfunnelactive_WrEn;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelactive_Data;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelactive_DataEff;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelactive_Data_muxed;
logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH-1:0] MMR_Trfunnelcontrol_F_Trfunnelactive_Data_prev;
assign MMR_Trfunnelcontrol_F_Trfunnelactive_DataEff = {reg_wr_data[0:0]};
assign MMR_Trfunnelcontrol_F_Trfunnelactive_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELCONTROL)) ? FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH'(update_value(64'(MMR_Trfunnelcontrol_F_Trfunnelactive), 64'(MMR_Trfunnelcontrol_F_Trfunnelactive_DataEff[0:0]), reg_wr_instr_type)) : FunnelMmrTrfunnelcontrolWr.Data.Trfunnelactive);
assign MMR_Trfunnelcontrol_F_Trfunnelactive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELCONTROL)) | FunnelMmrTrfunnelcontrolWr.TrfunnelactiveWrEn));
assign MMR_Trfunnelcontrol_F_Trfunnelactive_Data_prev = MMR_Trfunnelcontrol_F_Trfunnelactive;
assign MMR_Trfunnelcontrol_F_Trfunnelactive_Data_muxed = MMR_Trfunnelcontrol_F_Trfunnelactive_WrEn ? MMR_Trfunnelcontrol_F_Trfunnelactive_Data : MMR_Trfunnelcontrol_F_Trfunnelactive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELCONTROL_TRFUNNELACTIVE_WIDTH'(0))
) MMR_Trfunnelcontrol_F_Trfunnelactive_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunnelcontrol_F_Trfunnelactive_WrEn),
    .in    (MMR_Trfunnelcontrol_F_Trfunnelactive_Data),
    .out   (MMR_Trfunnelcontrol_F_Trfunnelactive)
);

assign MMR_Trfunnelimpl_F_Rsvd3112 = 20'h0;

assign MMR_Trfunnelimpl_F_Trfunnelcomptype = 4'h8;

assign MMR_Trfunnelimpl_F_Trfunnelverminor = 4'h0;

assign MMR_Trfunnelimpl_F_Trfunnelvermajor = 4'h1;

logic                                           MMR_Trfunneldisinput_F_Rsvd3116_WrEn;
logic [FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH-1:0] MMR_Trfunneldisinput_F_Rsvd3116_Data;
logic [FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH-1:0] MMR_Trfunneldisinput_F_Rsvd3116_DataEff;
logic [FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH-1:0] MMR_Trfunneldisinput_F_Rsvd3116_Data_muxed;
logic [FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH-1:0] MMR_Trfunneldisinput_F_Rsvd3116_Data_prev;
assign MMR_Trfunneldisinput_F_Rsvd3116_DataEff = {reg_wr_data[31:16]};
assign MMR_Trfunneldisinput_F_Rsvd3116_Data = (FunnelMmrTrfunneldisinputWr.Data.Rsvd3116);
assign MMR_Trfunneldisinput_F_Rsvd3116_WrEn = ((FunnelMmrTrfunneldisinputWr.Rsvd3116WrEn));
assign MMR_Trfunneldisinput_F_Rsvd3116_Data_prev = MMR_Trfunneldisinput_F_Rsvd3116;
assign MMR_Trfunneldisinput_F_Rsvd3116_Data_muxed = MMR_Trfunneldisinput_F_Rsvd3116_WrEn ? MMR_Trfunneldisinput_F_Rsvd3116_Data : MMR_Trfunneldisinput_F_Rsvd3116_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELDISINPUT_RSVD3116_WIDTH'(0))
) MMR_Trfunneldisinput_F_Rsvd3116_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunneldisinput_F_Rsvd3116_WrEn),
    .in    (MMR_Trfunneldisinput_F_Rsvd3116_Data),
    .out   (MMR_Trfunneldisinput_F_Rsvd3116)
);

logic                                           MMR_Trfunneldisinput_F_Trfunneldisinput_WrEn;
logic [FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH-1:0] MMR_Trfunneldisinput_F_Trfunneldisinput_Data;
logic [FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH-1:0] MMR_Trfunneldisinput_F_Trfunneldisinput_DataEff;
logic [FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH-1:0] MMR_Trfunneldisinput_F_Trfunneldisinput_Data_muxed;
logic [FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH-1:0] MMR_Trfunneldisinput_F_Trfunneldisinput_Data_prev;
assign MMR_Trfunneldisinput_F_Trfunneldisinput_DataEff = {reg_wr_data[15:0]};
assign MMR_Trfunneldisinput_F_Trfunneldisinput_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELDISINPUT)) ? FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH'(update_value(64'(MMR_Trfunneldisinput_F_Trfunneldisinput), 64'(MMR_Trfunneldisinput_F_Trfunneldisinput_DataEff[15:0]), reg_wr_instr_type)) : FunnelMmrTrfunneldisinputWr.Data.Trfunneldisinput);
assign MMR_Trfunneldisinput_F_Trfunneldisinput_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRFUNNELDISINPUT)) | FunnelMmrTrfunneldisinputWr.TrfunneldisinputWrEn));
assign MMR_Trfunneldisinput_F_Trfunneldisinput_Data_prev = MMR_Trfunneldisinput_F_Trfunneldisinput;
assign MMR_Trfunneldisinput_F_Trfunneldisinput_Data_muxed = MMR_Trfunneldisinput_F_Trfunneldisinput_WrEn ? MMR_Trfunneldisinput_F_Trfunneldisinput_Data : MMR_Trfunneldisinput_F_Trfunneldisinput_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_TRFUNNELDISINPUT_TRFUNNELDISINPUT_WIDTH'(0))
) MMR_Trfunneldisinput_F_Trfunneldisinput_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trfunneldisinput_F_Trfunneldisinput_WrEn),
    .in    (MMR_Trfunneldisinput_F_Trfunneldisinput_Data),
    .out   (MMR_Trfunneldisinput_F_Trfunneldisinput)
);

logic                                           MMR_ScratchLo_F_Data_WrEn;
logic [FUNNEL_SCRATCHLO_DATA_WIDTH        -1:0] MMR_ScratchLo_F_Data_Data;
logic [FUNNEL_SCRATCHLO_DATA_WIDTH        -1:0] MMR_ScratchLo_F_Data_DataEff;
logic [FUNNEL_SCRATCHLO_DATA_WIDTH        -1:0] MMR_ScratchLo_F_Data_Data_muxed;
logic [FUNNEL_SCRATCHLO_DATA_WIDTH        -1:0] MMR_ScratchLo_F_Data_Data_prev;
assign MMR_ScratchLo_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchLo_F_Data_Data = (FUNNEL_SCRATCHLO_DATA_WIDTH'(update_value(64'(MMR_ScratchLo_F_Data), 64'(MMR_ScratchLo_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchLo_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHLO))));
assign MMR_ScratchLo_F_Data_Data_prev = MMR_ScratchLo_F_Data;
assign MMR_ScratchLo_F_Data_Data_muxed = MMR_ScratchLo_F_Data_WrEn ? MMR_ScratchLo_F_Data_Data : MMR_ScratchLo_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_SCRATCHLO_DATA_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_SCRATCHLO_DATA_WIDTH'(0))
) MMR_ScratchLo_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchLo_F_Data_WrEn),
    .in    (MMR_ScratchLo_F_Data_Data),
    .out   (MMR_ScratchLo_F_Data)
);

logic                                           MMR_ScratchHi_F_Data_WrEn;
logic [FUNNEL_SCRATCHHI_DATA_WIDTH        -1:0] MMR_ScratchHi_F_Data_Data;
logic [FUNNEL_SCRATCHHI_DATA_WIDTH        -1:0] MMR_ScratchHi_F_Data_DataEff;
logic [FUNNEL_SCRATCHHI_DATA_WIDTH        -1:0] MMR_ScratchHi_F_Data_Data_muxed;
logic [FUNNEL_SCRATCHHI_DATA_WIDTH        -1:0] MMR_ScratchHi_F_Data_Data_prev;
assign MMR_ScratchHi_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchHi_F_Data_Data = (FUNNEL_SCRATCHHI_DATA_WIDTH'(update_value(64'(MMR_ScratchHi_F_Data), 64'(MMR_ScratchHi_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchHi_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHHI))));
assign MMR_ScratchHi_F_Data_Data_prev = MMR_ScratchHi_F_Data;
assign MMR_ScratchHi_F_Data_Data_muxed = MMR_ScratchHi_F_Data_WrEn ? MMR_ScratchHi_F_Data_Data : MMR_ScratchHi_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [FUNNEL_SCRATCHHI_DATA_WIDTH-1:0])),
    .RESET_VALUE (FUNNEL_SCRATCHHI_DATA_WIDTH'(0))
) MMR_ScratchHi_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchHi_F_Data_WrEn),
    .in    (MMR_ScratchHi_F_Data_Data),
    .out   (MMR_ScratchHi_F_Data)
);

assign MMR_Trfunnelcontrol = {
    MMR_Trfunnelcontrol_F_Rsvd314,
    MMR_Trfunnelcontrol_F_Trfunnelempty,
    MMR_Trfunnelcontrol_F_Rsvd22,
    MMR_Trfunnelcontrol_F_Trfunnelenable,
    MMR_Trfunnelcontrol_F_Trfunnelactive
};
logic [31:0] MMR_Trfunnelcontrol_muxed;
assign MMR_Trfunnelcontrol_muxed = {
    MMR_Trfunnelcontrol_F_Rsvd314_Data_muxed,
    MMR_Trfunnelcontrol_F_Trfunnelempty_Data_muxed,
    MMR_Trfunnelcontrol_F_Rsvd22_Data_muxed,
    MMR_Trfunnelcontrol_F_Trfunnelenable_Data_muxed,
    MMR_Trfunnelcontrol_F_Trfunnelactive_Data_muxed
};
assign MMR_Trfunnelimpl = {
    MMR_Trfunnelimpl_F_Rsvd3112,
    MMR_Trfunnelimpl_F_Trfunnelcomptype,
    MMR_Trfunnelimpl_F_Trfunnelverminor,
    MMR_Trfunnelimpl_F_Trfunnelvermajor
};
logic [31:0] MMR_Trfunnelimpl_muxed;
assign MMR_Trfunnelimpl_muxed = {
    MMR_Trfunnelimpl_F_Rsvd3112,
    MMR_Trfunnelimpl_F_Trfunnelcomptype,
    MMR_Trfunnelimpl_F_Trfunnelverminor,
    MMR_Trfunnelimpl_F_Trfunnelvermajor
};
assign MMR_Trfunneldisinput = {
    MMR_Trfunneldisinput_F_Rsvd3116,
    MMR_Trfunneldisinput_F_Trfunneldisinput
};
logic [31:0] MMR_Trfunneldisinput_muxed;
assign MMR_Trfunneldisinput_muxed = {
    MMR_Trfunneldisinput_F_Rsvd3116_Data_muxed,
    MMR_Trfunneldisinput_F_Trfunneldisinput_Data_muxed
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
        ADDR_MMR_TRFUNNELCONTROL                : begin : mmr_rd_hit_MMR_Trfunnelcontrol reg_prehit.FunnelMmrTrfunnelcontrolHit = 1'b1; reg_rd_data = {MMR_Trfunnelcontrol}; end
        ADDR_MMR_TRFUNNELIMPL                   : begin : mmr_rd_hit_MMR_Trfunnelimpl reg_prehit.FunnelMmrTrfunnelimplHit = 1'b1; reg_rd_data = {MMR_Trfunnelimpl}; end
        ADDR_MMR_TRFUNNELDISINPUT               : begin : mmr_rd_hit_MMR_Trfunneldisinput reg_prehit.FunnelMmrTrfunneldisinputHit = 1'b1; reg_rd_data = {MMR_Trfunneldisinput}; end
        ADDR_MMR_SCRATCHLO                      : begin : mmr_rd_hit_MMR_ScratchLo reg_prehit.FunnelMmrScratchloHit = 1'b1; reg_rd_data = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : mmr_rd_hit_MMR_ScratchHi reg_prehit.FunnelMmrScratchhiHit = 1'b1; reg_rd_data = {MMR_ScratchHi}; end
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
        ADDR_MMR_TRFUNNELCONTROL                : begin : mmr_rd_d1_MMR_Trfunnelcontrol reg_rd_data_d1 = {MMR_Trfunnelcontrol}; end
        ADDR_MMR_TRFUNNELIMPL                   : begin : mmr_rd_d1_MMR_Trfunnelimpl reg_rd_data_d1 = {MMR_Trfunnelimpl}; end
        ADDR_MMR_TRFUNNELDISINPUT               : begin : mmr_rd_d1_MMR_Trfunneldisinput reg_rd_data_d1 = {MMR_Trfunneldisinput}; end
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
        .WIDTH ($bits(logic [FUNNEL_NUM_REGISTERS-1:0])),
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

assign FunnelMmrTrfunnelcontrol.Rsvd314         = MMR_Trfunnelcontrol_F_Rsvd314;
assign FunnelMmrTrfunnelcontrol.Trfunnelempty   = MMR_Trfunnelcontrol_F_Trfunnelempty;
assign FunnelMmrTrfunnelcontrol.Rsvd22          = MMR_Trfunnelcontrol_F_Rsvd22;
assign FunnelMmrTrfunnelcontrol.Trfunnelenable  = MMR_Trfunnelcontrol_F_Trfunnelenable;
assign FunnelMmrTrfunnelcontrol.Trfunnelactive  = MMR_Trfunnelcontrol_F_Trfunnelactive;
assign FunnelMmrTrfunnelimpl.Rsvd3112           = MMR_Trfunnelimpl_F_Rsvd3112;
assign FunnelMmrTrfunnelimpl.Trfunnelcomptype   = MMR_Trfunnelimpl_F_Trfunnelcomptype;
assign FunnelMmrTrfunnelimpl.Trfunnelverminor   = MMR_Trfunnelimpl_F_Trfunnelverminor;
assign FunnelMmrTrfunnelimpl.Trfunnelvermajor   = MMR_Trfunnelimpl_F_Trfunnelvermajor;
assign FunnelMmrTrfunneldisinput.Rsvd3116       = MMR_Trfunneldisinput_F_Rsvd3116;
assign FunnelMmrTrfunneldisinput.Trfunneldisinput = MMR_Trfunneldisinput_F_Trfunneldisinput;
assign FunnelMmrScratchlo.Data                  = MMR_ScratchLo_F_Data;
assign FunnelMmrScratchhi.Data                  = MMR_ScratchHi_F_Data;

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
        ADDR_MMR_TRFUNNELCONTROL                : begin : get_reg_val_MMR_Trfunnelcontrol get_register_value = {MMR_Trfunnelcontrol}; end
        ADDR_MMR_TRFUNNELIMPL                   : begin : get_reg_val_MMR_Trfunnelimpl get_register_value = {MMR_Trfunnelimpl}; end
        ADDR_MMR_TRFUNNELDISINPUT               : begin : get_reg_val_MMR_Trfunneldisinput get_register_value = {MMR_Trfunneldisinput}; end
        ADDR_MMR_SCRATCHLO                      : begin : get_reg_val_MMR_ScratchLo get_register_value = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : get_reg_val_MMR_ScratchHi get_register_value = {MMR_ScratchHi}; end
        default                                 : begin : get_reg_val_default get_register_value = 'x; end
    endcase
  end
endfunction

endmodule
