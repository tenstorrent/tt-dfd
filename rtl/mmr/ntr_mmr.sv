// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module ntr_mmr
import ntr_mmr_pkg::*;
`include "ntr_mmr_pkg_list.svh"
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
output NtrMmrHit_s                              MmrHitList,
output logic                             [31:0] MmrRdData,

output NtrTrtecontrolMmr_s                      NtrMmrTrtecontrol,
output NtrTrteimplMmr_s                         NtrMmrTrteimpl,
output NtrTrteinstfeaturesMmr_s                 NtrMmrTrteinstfeatures,
output NtrTrteinstfiltersMmr_s                  NtrMmrTrteinstfilters,
output NtrTrtefilter0ControlMmr_s               NtrMmrTrtefilter0Control,
output NtrTrtefilter0MatchinstMmr_s             NtrMmrTrtefilter0Matchinst,
output NtrTrtscontrolMmr_s                      NtrMmrTrtscontrol,
output NtrCdbgntraceframecfgMmr_s               NtrMmrCdbgntraceframecfg,
output NtrScratchloMmr_s                        NtrMmrScratchlo,
output NtrScratchhiMmr_s                        NtrMmrScratchhi,

input NtrTrtecontrolMmrWr_s                     NtrMmrTrtecontrolWr,

output logic                                    MmrUpdateEn,
output logic                       [ADDR_W-1:0] MmrUpdateAddr,
output logic                       [ADDR_W_INDIR-1:0] MmrUpdateIndirAddr,
output logic                             [31:0] MmrUpdateData

);

localparam   [ADDR_W-1:0] ADDR_MMR_TRTECONTROL           = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEIMPL              = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEINSTFEATURES      = ADDR_W'(BASE_ADDR + 'h8);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEINSTFILTERS       = ADDR_W'(BASE_ADDR + 'hC);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEFILTER0CONTROL    = ADDR_W'(BASE_ADDR + 'h10);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTEFILTER0MATCHINST  = ADDR_W'(BASE_ADDR + 'h14);
localparam   [ADDR_W-1:0] ADDR_MMR_TRTSCONTROL           = ADDR_W'(BASE_ADDR + 'h40);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGNTRACEFRAMECFG    = ADDR_W'(BASE_ADDR + 'h1A8);
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
NtrMmrHit_s                 reg_prehit;
logic                       reg_hit;
logic                [31:0] reg_rd_data;

logic                       reg_write;
logic                       reg_read;

logic          [ADDR_W-1:0] reg_addr_d1;
logic          [ADDR_W_INDIR-1:0] reg_addr_select_d1;
logic                       reg_write_d1;
logic                       reg_hit_d1;
logic                [31:0] reg_rd_data_d1;

logic                [31:0] MMR_Trtecontrol;
logic                [31:0] MMR_Trteimpl;
logic                [31:0] MMR_Trteinstfeatures;
logic                [31:0] MMR_Trteinstfilters;
logic                [31:0] MMR_Trtefilter0Control;
logic                [31:0] MMR_Trtefilter0Matchinst;
logic                [31:0] MMR_Trtscontrol;
logic                [31:0] MMR_CDbgNtraceFrameCfg;
logic                [31:0] MMR_ScratchLo;
logic                [31:0] MMR_ScratchHi;

logic                 [4:0] MMR_Trtecontrol_F_Rsvd3127;
logic                 [2:0] MMR_Trtecontrol_F_Trteformat;
logic                 [3:0] MMR_Trtecontrol_F_Trtesyncmax;
logic                 [1:0] MMR_Trtecontrol_F_Rsvd1918;
logic                 [1:0] MMR_Trtecontrol_F_Trtesyncmode;
logic                 [0:0] MMR_Trtecontrol_F_Trteinhibitsrc;
logic                 [0:0] MMR_Trtecontrol_F_Rsvd1414;
logic                 [0:0] MMR_Trtecontrol_F_Trteinststallena;
logic                 [0:0] MMR_Trtecontrol_F_Trteinststalloroverflow;
logic                 [0:0] MMR_Trtecontrol_F_Trteinsttriggerenable;
logic                 [0:0] MMR_Trtecontrol_F_Rsvd1010;
logic                 [0:0] MMR_Trtecontrol_F_Trtecontext;
logic                 [1:0] MMR_Trtecontrol_F_Rsvd87;
logic                 [2:0] MMR_Trtecontrol_F_Trteinstmode;
logic                 [0:0] MMR_Trtecontrol_F_Trteempty;
logic                 [0:0] MMR_Trtecontrol_F_Trteinsttracing;
logic                 [0:0] MMR_Trtecontrol_F_Trteenable;
logic                 [0:0] MMR_Trtecontrol_F_Trteactive;
logic                 [1:0] MMR_Trteimpl_F_Rsvd3130;
logic                 [0:0] MMR_Trteimpl_F_Trtetracepatchenable;
logic                 [0:0] MMR_Trteimpl_F_Trteclatriggerenable;
logic                 [3:0] MMR_Trteimpl_F_Trtevendorframelength;
logic                 [3:0] MMR_Trteimpl_F_Trteprotocolminor;
logic                 [3:0] MMR_Trteimpl_F_Trteprotocolmajor;
logic                 [3:0] MMR_Trteimpl_F_Rsvd1512;
logic                 [3:0] MMR_Trteimpl_F_Trtecomptype;
logic                 [3:0] MMR_Trteimpl_F_Trteverminor;
logic                 [3:0] MMR_Trteimpl_F_Trtevermajor;
logic                 [3:0] MMR_Trteinstfeatures_F_Trtesrcbits;
logic                [11:0] MMR_Trteinstfeatures_F_Trtesrcid;
logic                 [6:0] MMR_Trteinstfeatures_F_Rsvd159;
logic                 [0:0] MMR_Trteinstfeatures_F_Trteinstenrepeatedhistory;
logic                 [5:0] MMR_Trteinstfeatures_F_Rsvd72;
logic                 [0:0] MMR_Trteinstfeatures_F_Trteinstnotrapaddr;
logic                 [0:0] MMR_Trteinstfeatures_F_Trteinstnoaddrdiff;
logic                [15:0] MMR_Trteinstfilters_F_Rsvd3116;
logic                [15:0] MMR_Trteinstfilters_F_Trteinstfilters;
logic                [29:0] MMR_Trtefilter0Control_F_Rsvd312;
logic                 [0:0] MMR_Trtefilter0Control_F_Trtefiltermatchprivilege;
logic                 [0:0] MMR_Trtefilter0Control_F_Trtefilterenable;
logic                [23:0] MMR_Trtefilter0Matchinst_F_Rsvd318;
logic                 [7:0] MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege;
logic                 [1:0] MMR_Trtscontrol_F_Rsvd3130;
logic                 [5:0] MMR_Trtscontrol_F_Trtswidth;
logic                 [7:0] MMR_Trtscontrol_F_Rsvd2316;
logic                 [0:0] MMR_Trtscontrol_F_Trtsenable;
logic                 [4:0] MMR_Trtscontrol_F_Rsvd1410;
logic                 [1:0] MMR_Trtscontrol_F_Trtsprescale;
logic                 [0:0] MMR_Trtscontrol_F_Rsvd77;
logic                 [2:0] MMR_Trtscontrol_F_Trtstype;
logic                 [0:0] MMR_Trtscontrol_F_Trtsrunindebug;
logic                 [0:0] MMR_Trtscontrol_F_Trtsreset;
logic                 [0:0] MMR_Trtscontrol_F_Trtscount;
logic                 [0:0] MMR_Trtscontrol_F_Trtsactive;
logic                 [9:0] MMR_CDbgNtraceFrameCfg_F_Rsvd3122;
logic                 [0:0] MMR_CDbgNtraceFrameCfg_F_FrameClosureMode;
logic                 [0:0] MMR_CDbgNtraceFrameCfg_F_FrameModeEnable;
logic                 [3:0] MMR_CDbgNtraceFrameCfg_F_Rsvd1916;
logic                 [3:0] MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes;
logic                 [7:0] MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte;
logic                 [3:0] MMR_CDbgNtraceFrameCfg_F_TraceSourceId;
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

assign MMR_Trtecontrol_F_Rsvd3127 = 5'h0;

logic                                           MMR_Trtecontrol_F_Trteformat_WrEn;
logic [NTR_TRTECONTROL_TRTEFORMAT_WIDTH   -1:0] MMR_Trtecontrol_F_Trteformat_Data;
logic [NTR_TRTECONTROL_TRTEFORMAT_WIDTH   -1:0] MMR_Trtecontrol_F_Trteformat_DataEff;
logic [NTR_TRTECONTROL_TRTEFORMAT_WIDTH   -1:0] MMR_Trtecontrol_F_Trteformat_Data_muxed;
logic [NTR_TRTECONTROL_TRTEFORMAT_WIDTH   -1:0] MMR_Trtecontrol_F_Trteformat_Data_prev;
assign MMR_Trtecontrol_F_Trteformat_DataEff = {reg_wr_data[26:24]};
assign MMR_Trtecontrol_F_Trteformat_Data = (NTR_TRTECONTROL_TRTEFORMAT_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteformat), 64'(MMR_Trtecontrol_F_Trteformat_DataEff[2:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteformat_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteformat_Data_prev = MMR_Trtecontrol_F_Trteformat;
assign MMR_Trtecontrol_F_Trteformat_Data_muxed = MMR_Trtecontrol_F_Trteformat_WrEn ? MMR_Trtecontrol_F_Trteformat_Data : MMR_Trtecontrol_F_Trteformat_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEFORMAT_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEFORMAT_WIDTH'(1))
) MMR_Trtecontrol_F_Trteformat_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteformat_WrEn),
    .in    (MMR_Trtecontrol_F_Trteformat_Data),
    .out   (MMR_Trtecontrol_F_Trteformat)
);

logic                                           MMR_Trtecontrol_F_Trtesyncmax_WrEn;
logic [NTR_TRTECONTROL_TRTESYNCMAX_WIDTH  -1:0] MMR_Trtecontrol_F_Trtesyncmax_Data;
logic [NTR_TRTECONTROL_TRTESYNCMAX_WIDTH  -1:0] MMR_Trtecontrol_F_Trtesyncmax_DataEff;
logic [NTR_TRTECONTROL_TRTESYNCMAX_WIDTH  -1:0] MMR_Trtecontrol_F_Trtesyncmax_Data_muxed;
logic [NTR_TRTECONTROL_TRTESYNCMAX_WIDTH  -1:0] MMR_Trtecontrol_F_Trtesyncmax_Data_prev;
assign MMR_Trtecontrol_F_Trtesyncmax_DataEff = {reg_wr_data[23:20]};
assign MMR_Trtecontrol_F_Trtesyncmax_Data = (NTR_TRTECONTROL_TRTESYNCMAX_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trtesyncmax), 64'(MMR_Trtecontrol_F_Trtesyncmax_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trtesyncmax_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trtesyncmax_Data_prev = MMR_Trtecontrol_F_Trtesyncmax;
assign MMR_Trtecontrol_F_Trtesyncmax_Data_muxed = MMR_Trtecontrol_F_Trtesyncmax_WrEn ? MMR_Trtecontrol_F_Trtesyncmax_Data : MMR_Trtecontrol_F_Trtesyncmax_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTESYNCMAX_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTESYNCMAX_WIDTH'(0))
) MMR_Trtecontrol_F_Trtesyncmax_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trtesyncmax_WrEn),
    .in    (MMR_Trtecontrol_F_Trtesyncmax_Data),
    .out   (MMR_Trtecontrol_F_Trtesyncmax)
);

assign MMR_Trtecontrol_F_Rsvd1918 = 2'h0;

logic                                           MMR_Trtecontrol_F_Trtesyncmode_WrEn;
logic [NTR_TRTECONTROL_TRTESYNCMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trtesyncmode_Data;
logic [NTR_TRTECONTROL_TRTESYNCMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trtesyncmode_DataEff;
logic [NTR_TRTECONTROL_TRTESYNCMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trtesyncmode_Data_muxed;
logic [NTR_TRTECONTROL_TRTESYNCMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trtesyncmode_Data_prev;
assign MMR_Trtecontrol_F_Trtesyncmode_DataEff = {reg_wr_data[17:16]};
assign MMR_Trtecontrol_F_Trtesyncmode_Data = (NTR_TRTECONTROL_TRTESYNCMODE_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trtesyncmode), 64'(MMR_Trtecontrol_F_Trtesyncmode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trtesyncmode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trtesyncmode_Data_prev = MMR_Trtecontrol_F_Trtesyncmode;
assign MMR_Trtecontrol_F_Trtesyncmode_Data_muxed = MMR_Trtecontrol_F_Trtesyncmode_WrEn ? MMR_Trtecontrol_F_Trtesyncmode_Data : MMR_Trtecontrol_F_Trtesyncmode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTESYNCMODE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTESYNCMODE_WIDTH'(0))
) MMR_Trtecontrol_F_Trtesyncmode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trtesyncmode_WrEn),
    .in    (MMR_Trtecontrol_F_Trtesyncmode_Data),
    .out   (MMR_Trtecontrol_F_Trtesyncmode)
);

logic                                           MMR_Trtecontrol_F_Trteinhibitsrc_WrEn;
logic [NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH-1:0] MMR_Trtecontrol_F_Trteinhibitsrc_Data;
logic [NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH-1:0] MMR_Trtecontrol_F_Trteinhibitsrc_DataEff;
logic [NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH-1:0] MMR_Trtecontrol_F_Trteinhibitsrc_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH-1:0] MMR_Trtecontrol_F_Trteinhibitsrc_Data_prev;
assign MMR_Trtecontrol_F_Trteinhibitsrc_DataEff = {reg_wr_data[15:15]};
assign MMR_Trtecontrol_F_Trteinhibitsrc_Data = (NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinhibitsrc), 64'(MMR_Trtecontrol_F_Trteinhibitsrc_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteinhibitsrc_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteinhibitsrc_Data_prev = MMR_Trtecontrol_F_Trteinhibitsrc;
assign MMR_Trtecontrol_F_Trteinhibitsrc_Data_muxed = MMR_Trtecontrol_F_Trteinhibitsrc_WrEn ? MMR_Trtecontrol_F_Trteinhibitsrc_Data : MMR_Trtecontrol_F_Trteinhibitsrc_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH'(0))
) MMR_Trtecontrol_F_Trteinhibitsrc_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinhibitsrc_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinhibitsrc_Data),
    .out   (MMR_Trtecontrol_F_Trteinhibitsrc)
);

assign MMR_Trtecontrol_F_Rsvd1414 = 1'h0;

logic                                           MMR_Trtecontrol_F_Trteinststallena_WrEn;
logic [NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststallena_Data;
logic [NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststallena_DataEff;
logic [NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststallena_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststallena_Data_prev;
assign MMR_Trtecontrol_F_Trteinststallena_DataEff = {reg_wr_data[13:13]};
assign MMR_Trtecontrol_F_Trteinststallena_Data = (NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinststallena), 64'(MMR_Trtecontrol_F_Trteinststallena_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteinststallena_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteinststallena_Data_prev = MMR_Trtecontrol_F_Trteinststallena;
assign MMR_Trtecontrol_F_Trteinststallena_Data_muxed = MMR_Trtecontrol_F_Trteinststallena_WrEn ? MMR_Trtecontrol_F_Trteinststallena_Data : MMR_Trtecontrol_F_Trteinststallena_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH'(0))
) MMR_Trtecontrol_F_Trteinststallena_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinststallena_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinststallena_Data),
    .out   (MMR_Trtecontrol_F_Trteinststallena)
);

logic                                           MMR_Trtecontrol_F_Trteinststalloroverflow_WrEn;
logic [NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststalloroverflow_Data;
logic [NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststalloroverflow_DataEff;
logic [NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststalloroverflow_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH-1:0] MMR_Trtecontrol_F_Trteinststalloroverflow_Data_prev;
assign MMR_Trtecontrol_F_Trteinststalloroverflow_DataEff = {reg_wr_data[12:12]};
assign MMR_Trtecontrol_F_Trteinststalloroverflow_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL)) ? NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinststalloroverflow), 64'(MMR_Trtecontrol_F_Trteinststalloroverflow_DataEff[0:0]), reg_wr_instr_type)) : NtrMmrTrtecontrolWr.Data.Trteinststalloroverflow);
assign MMR_Trtecontrol_F_Trteinststalloroverflow_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL)) | NtrMmrTrtecontrolWr.TrteinststalloroverflowWrEn));
assign MMR_Trtecontrol_F_Trteinststalloroverflow_Data_prev = MMR_Trtecontrol_F_Trteinststalloroverflow;
assign MMR_Trtecontrol_F_Trteinststalloroverflow_Data_muxed = MMR_Trtecontrol_F_Trteinststalloroverflow_WrEn ? MMR_Trtecontrol_F_Trteinststalloroverflow_Data : MMR_Trtecontrol_F_Trteinststalloroverflow_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH'(0))
) MMR_Trtecontrol_F_Trteinststalloroverflow_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinststalloroverflow_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinststalloroverflow_Data),
    .out   (MMR_Trtecontrol_F_Trteinststalloroverflow)
);

logic                                           MMR_Trtecontrol_F_Trteinsttriggerenable_WrEn;
logic [NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttriggerenable_Data;
logic [NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttriggerenable_DataEff;
logic [NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttriggerenable_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttriggerenable_Data_prev;
assign MMR_Trtecontrol_F_Trteinsttriggerenable_DataEff = {reg_wr_data[11:11]};
assign MMR_Trtecontrol_F_Trteinsttriggerenable_Data = (NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinsttriggerenable), 64'(MMR_Trtecontrol_F_Trteinsttriggerenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteinsttriggerenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteinsttriggerenable_Data_prev = MMR_Trtecontrol_F_Trteinsttriggerenable;
assign MMR_Trtecontrol_F_Trteinsttriggerenable_Data_muxed = MMR_Trtecontrol_F_Trteinsttriggerenable_WrEn ? MMR_Trtecontrol_F_Trteinsttriggerenable_Data : MMR_Trtecontrol_F_Trteinsttriggerenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH'(0))
) MMR_Trtecontrol_F_Trteinsttriggerenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinsttriggerenable_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinsttriggerenable_Data),
    .out   (MMR_Trtecontrol_F_Trteinsttriggerenable)
);

assign MMR_Trtecontrol_F_Rsvd1010 = 1'h0;

logic                                           MMR_Trtecontrol_F_Trtecontext_WrEn;
logic [NTR_TRTECONTROL_TRTECONTEXT_WIDTH  -1:0] MMR_Trtecontrol_F_Trtecontext_Data;
logic [NTR_TRTECONTROL_TRTECONTEXT_WIDTH  -1:0] MMR_Trtecontrol_F_Trtecontext_DataEff;
logic [NTR_TRTECONTROL_TRTECONTEXT_WIDTH  -1:0] MMR_Trtecontrol_F_Trtecontext_Data_muxed;
logic [NTR_TRTECONTROL_TRTECONTEXT_WIDTH  -1:0] MMR_Trtecontrol_F_Trtecontext_Data_prev;
assign MMR_Trtecontrol_F_Trtecontext_DataEff = {reg_wr_data[9:9]};
assign MMR_Trtecontrol_F_Trtecontext_Data = (NTR_TRTECONTROL_TRTECONTEXT_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trtecontext), 64'(MMR_Trtecontrol_F_Trtecontext_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trtecontext_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trtecontext_Data_prev = MMR_Trtecontrol_F_Trtecontext;
assign MMR_Trtecontrol_F_Trtecontext_Data_muxed = MMR_Trtecontrol_F_Trtecontext_WrEn ? MMR_Trtecontrol_F_Trtecontext_Data : MMR_Trtecontrol_F_Trtecontext_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTECONTEXT_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTECONTEXT_WIDTH'(0))
) MMR_Trtecontrol_F_Trtecontext_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trtecontext_WrEn),
    .in    (MMR_Trtecontrol_F_Trtecontext_Data),
    .out   (MMR_Trtecontrol_F_Trtecontext)
);

assign MMR_Trtecontrol_F_Rsvd87 = 2'h0;

logic                                           MMR_Trtecontrol_F_Trteinstmode_WrEn;
logic [NTR_TRTECONTROL_TRTEINSTMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trteinstmode_Data;
logic [NTR_TRTECONTROL_TRTEINSTMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trteinstmode_DataEff;
logic [NTR_TRTECONTROL_TRTEINSTMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trteinstmode_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINSTMODE_WIDTH -1:0] MMR_Trtecontrol_F_Trteinstmode_Data_prev;
assign MMR_Trtecontrol_F_Trteinstmode_DataEff = {reg_wr_data[6:4]};
assign MMR_Trtecontrol_F_Trteinstmode_Data = (NTR_TRTECONTROL_TRTEINSTMODE_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinstmode), 64'(MMR_Trtecontrol_F_Trteinstmode_DataEff[2:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteinstmode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteinstmode_Data_prev = MMR_Trtecontrol_F_Trteinstmode;
assign MMR_Trtecontrol_F_Trteinstmode_Data_muxed = MMR_Trtecontrol_F_Trteinstmode_WrEn ? MMR_Trtecontrol_F_Trteinstmode_Data : MMR_Trtecontrol_F_Trteinstmode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINSTMODE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINSTMODE_WIDTH'(3'h6))
) MMR_Trtecontrol_F_Trteinstmode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinstmode_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinstmode_Data),
    .out   (MMR_Trtecontrol_F_Trteinstmode)
);

logic                                           MMR_Trtecontrol_F_Trteempty_WrEn;
logic [NTR_TRTECONTROL_TRTEEMPTY_WIDTH    -1:0] MMR_Trtecontrol_F_Trteempty_Data;
logic [NTR_TRTECONTROL_TRTEEMPTY_WIDTH    -1:0] MMR_Trtecontrol_F_Trteempty_DataEff;
logic [NTR_TRTECONTROL_TRTEEMPTY_WIDTH    -1:0] MMR_Trtecontrol_F_Trteempty_Data_muxed;
logic [NTR_TRTECONTROL_TRTEEMPTY_WIDTH    -1:0] MMR_Trtecontrol_F_Trteempty_Data_prev;
assign MMR_Trtecontrol_F_Trteempty_DataEff = {reg_wr_data[3:3]};
assign MMR_Trtecontrol_F_Trteempty_Data = (NtrMmrTrtecontrolWr.Data.Trteempty);
assign MMR_Trtecontrol_F_Trteempty_WrEn = ((NtrMmrTrtecontrolWr.TrteemptyWrEn));
assign MMR_Trtecontrol_F_Trteempty_Data_prev = MMR_Trtecontrol_F_Trteempty;
assign MMR_Trtecontrol_F_Trteempty_Data_muxed = MMR_Trtecontrol_F_Trteempty_WrEn ? MMR_Trtecontrol_F_Trteempty_Data : MMR_Trtecontrol_F_Trteempty_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEEMPTY_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEEMPTY_WIDTH'(1))
) MMR_Trtecontrol_F_Trteempty_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteempty_WrEn),
    .in    (MMR_Trtecontrol_F_Trteempty_Data),
    .out   (MMR_Trtecontrol_F_Trteempty)
);

logic                                           MMR_Trtecontrol_F_Trteinsttracing_WrEn;
logic [NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttracing_Data;
logic [NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttracing_DataEff;
logic [NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttracing_Data_muxed;
logic [NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH-1:0] MMR_Trtecontrol_F_Trteinsttracing_Data_prev;
assign MMR_Trtecontrol_F_Trteinsttracing_DataEff = {reg_wr_data[2:2]};
assign MMR_Trtecontrol_F_Trteinsttracing_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL)) ? NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteinsttracing), 64'(MMR_Trtecontrol_F_Trteinsttracing_DataEff[0:0]), reg_wr_instr_type)) : NtrMmrTrtecontrolWr.Data.Trteinsttracing);
assign MMR_Trtecontrol_F_Trteinsttracing_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL)) | NtrMmrTrtecontrolWr.TrteinsttracingWrEn));
assign MMR_Trtecontrol_F_Trteinsttracing_Data_prev = MMR_Trtecontrol_F_Trteinsttracing;
assign MMR_Trtecontrol_F_Trteinsttracing_Data_muxed = MMR_Trtecontrol_F_Trteinsttracing_WrEn ? MMR_Trtecontrol_F_Trteinsttracing_Data : MMR_Trtecontrol_F_Trteinsttracing_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH'(0))
) MMR_Trtecontrol_F_Trteinsttracing_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteinsttracing_WrEn),
    .in    (MMR_Trtecontrol_F_Trteinsttracing_Data),
    .out   (MMR_Trtecontrol_F_Trteinsttracing)
);

logic                                           MMR_Trtecontrol_F_Trteenable_WrEn;
logic [NTR_TRTECONTROL_TRTEENABLE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteenable_Data;
logic [NTR_TRTECONTROL_TRTEENABLE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteenable_DataEff;
logic [NTR_TRTECONTROL_TRTEENABLE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteenable_Data_muxed;
logic [NTR_TRTECONTROL_TRTEENABLE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteenable_Data_prev;
assign MMR_Trtecontrol_F_Trteenable_DataEff = {reg_wr_data[1:1]};
assign MMR_Trtecontrol_F_Trteenable_Data = (NTR_TRTECONTROL_TRTEENABLE_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteenable), 64'(MMR_Trtecontrol_F_Trteenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteenable_Data_prev = MMR_Trtecontrol_F_Trteenable;
assign MMR_Trtecontrol_F_Trteenable_Data_muxed = MMR_Trtecontrol_F_Trteenable_WrEn ? MMR_Trtecontrol_F_Trteenable_Data : MMR_Trtecontrol_F_Trteenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEENABLE_WIDTH'(0))
) MMR_Trtecontrol_F_Trteenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteenable_WrEn),
    .in    (MMR_Trtecontrol_F_Trteenable_Data),
    .out   (MMR_Trtecontrol_F_Trteenable)
);

logic                                           MMR_Trtecontrol_F_Trteactive_WrEn;
logic [NTR_TRTECONTROL_TRTEACTIVE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteactive_Data;
logic [NTR_TRTECONTROL_TRTEACTIVE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteactive_DataEff;
logic [NTR_TRTECONTROL_TRTEACTIVE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteactive_Data_muxed;
logic [NTR_TRTECONTROL_TRTEACTIVE_WIDTH   -1:0] MMR_Trtecontrol_F_Trteactive_Data_prev;
assign MMR_Trtecontrol_F_Trteactive_DataEff = {reg_wr_data[0:0]};
assign MMR_Trtecontrol_F_Trteactive_Data = (NTR_TRTECONTROL_TRTEACTIVE_WIDTH'(update_value(64'(MMR_Trtecontrol_F_Trteactive), 64'(MMR_Trtecontrol_F_Trteactive_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtecontrol_F_Trteactive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTECONTROL))));
assign MMR_Trtecontrol_F_Trteactive_Data_prev = MMR_Trtecontrol_F_Trteactive;
assign MMR_Trtecontrol_F_Trteactive_Data_muxed = MMR_Trtecontrol_F_Trteactive_WrEn ? MMR_Trtecontrol_F_Trteactive_Data : MMR_Trtecontrol_F_Trteactive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTECONTROL_TRTEACTIVE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTECONTROL_TRTEACTIVE_WIDTH'(0))
) MMR_Trtecontrol_F_Trteactive_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtecontrol_F_Trteactive_WrEn),
    .in    (MMR_Trtecontrol_F_Trteactive_Data),
    .out   (MMR_Trtecontrol_F_Trteactive)
);

assign MMR_Trteimpl_F_Rsvd3130 = 2'h0;

logic                                           MMR_Trteimpl_F_Trtetracepatchenable_WrEn;
logic [NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trtetracepatchenable_Data;
logic [NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trtetracepatchenable_DataEff;
logic [NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trtetracepatchenable_Data_muxed;
logic [NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trtetracepatchenable_Data_prev;
assign MMR_Trteimpl_F_Trtetracepatchenable_DataEff = {reg_wr_data[29:29]};
assign MMR_Trteimpl_F_Trtetracepatchenable_Data = (NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH'(update_value(64'(MMR_Trteimpl_F_Trtetracepatchenable), 64'(MMR_Trteimpl_F_Trtetracepatchenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trteimpl_F_Trtetracepatchenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEIMPL))));
assign MMR_Trteimpl_F_Trtetracepatchenable_Data_prev = MMR_Trteimpl_F_Trtetracepatchenable;
assign MMR_Trteimpl_F_Trtetracepatchenable_Data_muxed = MMR_Trteimpl_F_Trtetracepatchenable_WrEn ? MMR_Trteimpl_F_Trtetracepatchenable_Data : MMR_Trteimpl_F_Trtetracepatchenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH'(0))
) MMR_Trteimpl_F_Trtetracepatchenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteimpl_F_Trtetracepatchenable_WrEn),
    .in    (MMR_Trteimpl_F_Trtetracepatchenable_Data),
    .out   (MMR_Trteimpl_F_Trtetracepatchenable)
);

logic                                           MMR_Trteimpl_F_Trteclatriggerenable_WrEn;
logic [NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trteclatriggerenable_Data;
logic [NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trteclatriggerenable_DataEff;
logic [NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trteclatriggerenable_Data_muxed;
logic [NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH-1:0] MMR_Trteimpl_F_Trteclatriggerenable_Data_prev;
assign MMR_Trteimpl_F_Trteclatriggerenable_DataEff = {reg_wr_data[28:28]};
assign MMR_Trteimpl_F_Trteclatriggerenable_Data = (NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH'(update_value(64'(MMR_Trteimpl_F_Trteclatriggerenable), 64'(MMR_Trteimpl_F_Trteclatriggerenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trteimpl_F_Trteclatriggerenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEIMPL))));
assign MMR_Trteimpl_F_Trteclatriggerenable_Data_prev = MMR_Trteimpl_F_Trteclatriggerenable;
assign MMR_Trteimpl_F_Trteclatriggerenable_Data_muxed = MMR_Trteimpl_F_Trteclatriggerenable_WrEn ? MMR_Trteimpl_F_Trteclatriggerenable_Data : MMR_Trteimpl_F_Trteclatriggerenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH'(0))
) MMR_Trteimpl_F_Trteclatriggerenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteimpl_F_Trteclatriggerenable_WrEn),
    .in    (MMR_Trteimpl_F_Trteclatriggerenable_Data),
    .out   (MMR_Trteimpl_F_Trteclatriggerenable)
);

logic                                           MMR_Trteimpl_F_Trtevendorframelength_WrEn;
logic [NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trteimpl_F_Trtevendorframelength_Data;
logic [NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trteimpl_F_Trtevendorframelength_DataEff;
logic [NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trteimpl_F_Trtevendorframelength_Data_muxed;
logic [NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trteimpl_F_Trtevendorframelength_Data_prev;
assign MMR_Trteimpl_F_Trtevendorframelength_DataEff = {reg_wr_data[27:24]};
assign MMR_Trteimpl_F_Trtevendorframelength_Data = (NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH'(update_value(64'(MMR_Trteimpl_F_Trtevendorframelength), 64'(MMR_Trteimpl_F_Trtevendorframelength_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trteimpl_F_Trtevendorframelength_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEIMPL))));
assign MMR_Trteimpl_F_Trtevendorframelength_Data_prev = MMR_Trteimpl_F_Trtevendorframelength;
assign MMR_Trteimpl_F_Trtevendorframelength_Data_muxed = MMR_Trteimpl_F_Trtevendorframelength_WrEn ? MMR_Trteimpl_F_Trtevendorframelength_Data : MMR_Trteimpl_F_Trtevendorframelength_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH'(1))
) MMR_Trteimpl_F_Trtevendorframelength_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteimpl_F_Trtevendorframelength_WrEn),
    .in    (MMR_Trteimpl_F_Trtevendorframelength_Data),
    .out   (MMR_Trteimpl_F_Trtevendorframelength)
);

assign MMR_Trteimpl_F_Trteprotocolminor = 4'h0;

assign MMR_Trteimpl_F_Trteprotocolmajor = 4'h1;

assign MMR_Trteimpl_F_Rsvd1512 = 4'h0;

assign MMR_Trteimpl_F_Trtecomptype = 4'h1;

assign MMR_Trteimpl_F_Trteverminor = 4'h0;

assign MMR_Trteimpl_F_Trtevermajor = 4'h1;

logic                                           MMR_Trteinstfeatures_F_Trtesrcbits_WrEn;
logic [NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcbits_Data;
logic [NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcbits_DataEff;
logic [NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcbits_Data_muxed;
logic [NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcbits_Data_prev;
assign MMR_Trteinstfeatures_F_Trtesrcbits_DataEff = {reg_wr_data[31:28]};
assign MMR_Trteinstfeatures_F_Trtesrcbits_Data = (NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH'(update_value(64'(MMR_Trteinstfeatures_F_Trtesrcbits), 64'(MMR_Trteinstfeatures_F_Trtesrcbits_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trteinstfeatures_F_Trtesrcbits_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEINSTFEATURES))));
assign MMR_Trteinstfeatures_F_Trtesrcbits_Data_prev = MMR_Trteinstfeatures_F_Trtesrcbits;
assign MMR_Trteinstfeatures_F_Trtesrcbits_Data_muxed = MMR_Trteinstfeatures_F_Trtesrcbits_WrEn ? MMR_Trteinstfeatures_F_Trtesrcbits_Data : MMR_Trteinstfeatures_F_Trtesrcbits_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH'(4'h4))
) MMR_Trteinstfeatures_F_Trtesrcbits_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteinstfeatures_F_Trtesrcbits_WrEn),
    .in    (MMR_Trteinstfeatures_F_Trtesrcbits_Data),
    .out   (MMR_Trteinstfeatures_F_Trtesrcbits)
);

logic                                           MMR_Trteinstfeatures_F_Trtesrcid_WrEn;
logic [NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcid_Data;
logic [NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcid_DataEff;
logic [NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcid_Data_muxed;
logic [NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH-1:0] MMR_Trteinstfeatures_F_Trtesrcid_Data_prev;
assign MMR_Trteinstfeatures_F_Trtesrcid_DataEff = {reg_wr_data[27:16]};
assign MMR_Trteinstfeatures_F_Trtesrcid_Data = (NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH'(update_value(64'(MMR_Trteinstfeatures_F_Trtesrcid), 64'(MMR_Trteinstfeatures_F_Trtesrcid_DataEff[11:0]), reg_wr_instr_type)));
assign MMR_Trteinstfeatures_F_Trtesrcid_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEINSTFEATURES))));
assign MMR_Trteinstfeatures_F_Trtesrcid_Data_prev = MMR_Trteinstfeatures_F_Trtesrcid;
assign MMR_Trteinstfeatures_F_Trtesrcid_Data_muxed = MMR_Trteinstfeatures_F_Trtesrcid_WrEn ? MMR_Trteinstfeatures_F_Trtesrcid_Data : MMR_Trteinstfeatures_F_Trtesrcid_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH'(0))
) MMR_Trteinstfeatures_F_Trtesrcid_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteinstfeatures_F_Trtesrcid_WrEn),
    .in    (MMR_Trteinstfeatures_F_Trtesrcid_Data),
    .out   (MMR_Trteinstfeatures_F_Trtesrcid)
);

assign MMR_Trteinstfeatures_F_Rsvd159 = 7'h0;

assign MMR_Trteinstfeatures_F_Trteinstenrepeatedhistory = 1'h1;

assign MMR_Trteinstfeatures_F_Rsvd72 = 6'h0;

logic                                           MMR_Trteinstfeatures_F_Trteinstnotrapaddr_WrEn;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnotrapaddr_DataEff;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_muxed;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_prev;
assign MMR_Trteinstfeatures_F_Trteinstnotrapaddr_DataEff = {reg_wr_data[1:1]};
assign MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data = (NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH'(update_value(64'(MMR_Trteinstfeatures_F_Trteinstnotrapaddr), 64'(MMR_Trteinstfeatures_F_Trteinstnotrapaddr_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trteinstfeatures_F_Trteinstnotrapaddr_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEINSTFEATURES))));
assign MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_prev = MMR_Trteinstfeatures_F_Trteinstnotrapaddr;
assign MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_muxed = MMR_Trteinstfeatures_F_Trteinstnotrapaddr_WrEn ? MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data : MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH'(0))
) MMR_Trteinstfeatures_F_Trteinstnotrapaddr_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteinstfeatures_F_Trteinstnotrapaddr_WrEn),
    .in    (MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data),
    .out   (MMR_Trteinstfeatures_F_Trteinstnotrapaddr)
);

logic                                           MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_WrEn;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_DataEff;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_muxed;
logic [NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH-1:0] MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_prev;
assign MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_DataEff = {reg_wr_data[0:0]};
assign MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data = (NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH'(update_value(64'(MMR_Trteinstfeatures_F_Trteinstnoaddrdiff), 64'(MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEINSTFEATURES))));
assign MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_prev = MMR_Trteinstfeatures_F_Trteinstnoaddrdiff;
assign MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_muxed = MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_WrEn ? MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data : MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH'(0))
) MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_WrEn),
    .in    (MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data),
    .out   (MMR_Trteinstfeatures_F_Trteinstnoaddrdiff)
);

assign MMR_Trteinstfilters_F_Rsvd3116 = 16'h0;

logic                                           MMR_Trteinstfilters_F_Trteinstfilters_WrEn;
logic [NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH-1:0] MMR_Trteinstfilters_F_Trteinstfilters_Data;
logic [NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH-1:0] MMR_Trteinstfilters_F_Trteinstfilters_DataEff;
logic [NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH-1:0] MMR_Trteinstfilters_F_Trteinstfilters_Data_muxed;
logic [NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH-1:0] MMR_Trteinstfilters_F_Trteinstfilters_Data_prev;
assign MMR_Trteinstfilters_F_Trteinstfilters_DataEff = {reg_wr_data[15:0]};
assign MMR_Trteinstfilters_F_Trteinstfilters_Data = (NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH'(update_value(64'(MMR_Trteinstfilters_F_Trteinstfilters), 64'(MMR_Trteinstfilters_F_Trteinstfilters_DataEff[15:0]), reg_wr_instr_type)));
assign MMR_Trteinstfilters_F_Trteinstfilters_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEINSTFILTERS))));
assign MMR_Trteinstfilters_F_Trteinstfilters_Data_prev = MMR_Trteinstfilters_F_Trteinstfilters;
assign MMR_Trteinstfilters_F_Trteinstfilters_Data_muxed = MMR_Trteinstfilters_F_Trteinstfilters_WrEn ? MMR_Trteinstfilters_F_Trteinstfilters_Data : MMR_Trteinstfilters_F_Trteinstfilters_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH'(0))
) MMR_Trteinstfilters_F_Trteinstfilters_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trteinstfilters_F_Trteinstfilters_WrEn),
    .in    (MMR_Trteinstfilters_F_Trteinstfilters_Data),
    .out   (MMR_Trteinstfilters_F_Trteinstfilters)
);

assign MMR_Trtefilter0Control_F_Rsvd312 = 30'h0;

logic                                           MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_WrEn;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_DataEff;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_muxed;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_prev;
assign MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_DataEff = {reg_wr_data[1:1]};
assign MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data = (NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH'(update_value(64'(MMR_Trtefilter0Control_F_Trtefiltermatchprivilege), 64'(MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEFILTER0CONTROL))));
assign MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_prev = MMR_Trtefilter0Control_F_Trtefiltermatchprivilege;
assign MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_muxed = MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_WrEn ? MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data : MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH'(0))
) MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_WrEn),
    .in    (MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data),
    .out   (MMR_Trtefilter0Control_F_Trtefiltermatchprivilege)
);

logic                                           MMR_Trtefilter0Control_F_Trtefilterenable_WrEn;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefilterenable_Data;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefilterenable_DataEff;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefilterenable_Data_muxed;
logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH-1:0] MMR_Trtefilter0Control_F_Trtefilterenable_Data_prev;
assign MMR_Trtefilter0Control_F_Trtefilterenable_DataEff = {reg_wr_data[0:0]};
assign MMR_Trtefilter0Control_F_Trtefilterenable_Data = (NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH'(update_value(64'(MMR_Trtefilter0Control_F_Trtefilterenable), 64'(MMR_Trtefilter0Control_F_Trtefilterenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtefilter0Control_F_Trtefilterenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEFILTER0CONTROL))));
assign MMR_Trtefilter0Control_F_Trtefilterenable_Data_prev = MMR_Trtefilter0Control_F_Trtefilterenable;
assign MMR_Trtefilter0Control_F_Trtefilterenable_Data_muxed = MMR_Trtefilter0Control_F_Trtefilterenable_WrEn ? MMR_Trtefilter0Control_F_Trtefilterenable_Data : MMR_Trtefilter0Control_F_Trtefilterenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH'(0))
) MMR_Trtefilter0Control_F_Trtefilterenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtefilter0Control_F_Trtefilterenable_WrEn),
    .in    (MMR_Trtefilter0Control_F_Trtefilterenable_Data),
    .out   (MMR_Trtefilter0Control_F_Trtefilterenable)
);

assign MMR_Trtefilter0Matchinst_F_Rsvd318 = 24'h0;

logic                                           MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_WrEn;
logic [NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data;
logic [NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_DataEff;
logic [NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_muxed;
logic [NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH-1:0] MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_prev;
assign MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_DataEff = {reg_wr_data[7:0]};
assign MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data = (NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH'(update_value(64'(MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege), 64'(MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTEFILTER0MATCHINST))));
assign MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_prev = MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege;
assign MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_muxed = MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_WrEn ? MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data : MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH'(0))
) MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_WrEn),
    .in    (MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data),
    .out   (MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege)
);

assign MMR_Trtscontrol_F_Rsvd3130 = 2'h0;

assign MMR_Trtscontrol_F_Trtswidth = 6'h37;

assign MMR_Trtscontrol_F_Rsvd2316 = 8'h0;

logic                                           MMR_Trtscontrol_F_Trtsenable_WrEn;
logic [NTR_TRTSCONTROL_TRTSENABLE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsenable_Data;
logic [NTR_TRTSCONTROL_TRTSENABLE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsenable_DataEff;
logic [NTR_TRTSCONTROL_TRTSENABLE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsenable_Data_muxed;
logic [NTR_TRTSCONTROL_TRTSENABLE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsenable_Data_prev;
assign MMR_Trtscontrol_F_Trtsenable_DataEff = {reg_wr_data[15:15]};
assign MMR_Trtscontrol_F_Trtsenable_Data = (NTR_TRTSCONTROL_TRTSENABLE_WIDTH'(update_value(64'(MMR_Trtscontrol_F_Trtsenable), 64'(MMR_Trtscontrol_F_Trtsenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtscontrol_F_Trtsenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTSCONTROL))));
assign MMR_Trtscontrol_F_Trtsenable_Data_prev = MMR_Trtscontrol_F_Trtsenable;
assign MMR_Trtscontrol_F_Trtsenable_Data_muxed = MMR_Trtscontrol_F_Trtsenable_WrEn ? MMR_Trtscontrol_F_Trtsenable_Data : MMR_Trtscontrol_F_Trtsenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTSCONTROL_TRTSENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTSCONTROL_TRTSENABLE_WIDTH'(0))
) MMR_Trtscontrol_F_Trtsenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtscontrol_F_Trtsenable_WrEn),
    .in    (MMR_Trtscontrol_F_Trtsenable_Data),
    .out   (MMR_Trtscontrol_F_Trtsenable)
);

assign MMR_Trtscontrol_F_Rsvd1410 = 5'h0;

assign MMR_Trtscontrol_F_Trtsprescale = 2'h0;

assign MMR_Trtscontrol_F_Rsvd77 = 1'h0;

assign MMR_Trtscontrol_F_Trtstype = 3'h1;

assign MMR_Trtscontrol_F_Trtsrunindebug = 1'h0;

assign MMR_Trtscontrol_F_Trtsreset = 1'h0;

assign MMR_Trtscontrol_F_Trtscount = 1'h0;

logic                                           MMR_Trtscontrol_F_Trtsactive_WrEn;
logic [NTR_TRTSCONTROL_TRTSACTIVE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsactive_Data;
logic [NTR_TRTSCONTROL_TRTSACTIVE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsactive_DataEff;
logic [NTR_TRTSCONTROL_TRTSACTIVE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsactive_Data_muxed;
logic [NTR_TRTSCONTROL_TRTSACTIVE_WIDTH   -1:0] MMR_Trtscontrol_F_Trtsactive_Data_prev;
assign MMR_Trtscontrol_F_Trtsactive_DataEff = {reg_wr_data[0:0]};
assign MMR_Trtscontrol_F_Trtsactive_Data = (NTR_TRTSCONTROL_TRTSACTIVE_WIDTH'(update_value(64'(MMR_Trtscontrol_F_Trtsactive), 64'(MMR_Trtscontrol_F_Trtsactive_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trtscontrol_F_Trtsactive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRTSCONTROL))));
assign MMR_Trtscontrol_F_Trtsactive_Data_prev = MMR_Trtscontrol_F_Trtsactive;
assign MMR_Trtscontrol_F_Trtsactive_Data_muxed = MMR_Trtscontrol_F_Trtsactive_WrEn ? MMR_Trtscontrol_F_Trtsactive_Data : MMR_Trtscontrol_F_Trtsactive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_TRTSCONTROL_TRTSACTIVE_WIDTH-1:0])),
    .RESET_VALUE (NTR_TRTSCONTROL_TRTSACTIVE_WIDTH'(0))
) MMR_Trtscontrol_F_Trtsactive_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trtscontrol_F_Trtsactive_WrEn),
    .in    (MMR_Trtscontrol_F_Trtsactive_Data),
    .out   (MMR_Trtscontrol_F_Trtsactive)
);

assign MMR_CDbgNtraceFrameCfg_F_Rsvd3122 = 10'h0;

logic                                           MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_WrEn;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_DataEff;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_muxed;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_prev;
assign MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_DataEff = {reg_wr_data[21:21]};
assign MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data = (NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH'(update_value(64'(MMR_CDbgNtraceFrameCfg_F_FrameClosureMode), 64'(MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNTRACEFRAMECFG))));
assign MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_prev = MMR_CDbgNtraceFrameCfg_F_FrameClosureMode;
assign MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_muxed = MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_WrEn ? MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data : MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH-1:0])),
    .RESET_VALUE (NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH'(0))
) MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_WrEn),
    .in    (MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data),
    .out   (MMR_CDbgNtraceFrameCfg_F_FrameClosureMode)
);

logic                                           MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_WrEn;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_DataEff;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_muxed;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_prev;
assign MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_DataEff = {reg_wr_data[20:20]};
assign MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data = (NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH'(update_value(64'(MMR_CDbgNtraceFrameCfg_F_FrameModeEnable), 64'(MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNTRACEFRAMECFG))));
assign MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_prev = MMR_CDbgNtraceFrameCfg_F_FrameModeEnable;
assign MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_muxed = MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_WrEn ? MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data : MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH-1:0])),
    .RESET_VALUE (NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH'(1))
) MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_WrEn),
    .in    (MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data),
    .out   (MMR_CDbgNtraceFrameCfg_F_FrameModeEnable)
);

assign MMR_CDbgNtraceFrameCfg_F_Rsvd1916 = 4'h0;

logic                                           MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_WrEn;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_DataEff;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_muxed;
logic [NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_prev;
assign MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_DataEff = {reg_wr_data[15:12]};
assign MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data = (NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH'(update_value(64'(MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes), 64'(MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNTRACEFRAMECFG))));
assign MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_prev = MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes;
assign MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_muxed = MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_WrEn ? MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data : MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH-1:0])),
    .RESET_VALUE (NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH'(4'h2))
) MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_WrEn),
    .in    (MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data),
    .out   (MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes)
);

logic                                           MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_WrEn;
logic [NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data;
logic [NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_DataEff;
logic [NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_muxed;
logic [NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_prev;
assign MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_DataEff = {reg_wr_data[11:4]};
assign MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data = (NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH'(update_value(64'(MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte), 64'(MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNTRACEFRAMECFG))));
assign MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_prev = MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte;
assign MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_muxed = MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_WrEn ? MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data : MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0])),
    .RESET_VALUE (NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH'(8'hFF))
) MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_WrEn),
    .in    (MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data),
    .out   (MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte)
);

logic                                           MMR_CDbgNtraceFrameCfg_F_TraceSourceId_WrEn;
logic [NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data;
logic [NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceSourceId_DataEff;
logic [NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_muxed;
logic [NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_prev;
assign MMR_CDbgNtraceFrameCfg_F_TraceSourceId_DataEff = {reg_wr_data[3:0]};
assign MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data = (NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH'(update_value(64'(MMR_CDbgNtraceFrameCfg_F_TraceSourceId), 64'(MMR_CDbgNtraceFrameCfg_F_TraceSourceId_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgNtraceFrameCfg_F_TraceSourceId_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGNTRACEFRAMECFG))));
assign MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_prev = MMR_CDbgNtraceFrameCfg_F_TraceSourceId;
assign MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_muxed = MMR_CDbgNtraceFrameCfg_F_TraceSourceId_WrEn ? MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data : MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH-1:0])),
    .RESET_VALUE (NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH'(0))
) MMR_CDbgNtraceFrameCfg_F_TraceSourceId_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgNtraceFrameCfg_F_TraceSourceId_WrEn),
    .in    (MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data),
    .out   (MMR_CDbgNtraceFrameCfg_F_TraceSourceId)
);

logic                                           MMR_ScratchLo_F_Data_WrEn;
logic [NTR_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data;
logic [NTR_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_DataEff;
logic [NTR_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data_muxed;
logic [NTR_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data_prev;
assign MMR_ScratchLo_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchLo_F_Data_Data = (NTR_SCRATCHLO_DATA_WIDTH'(update_value(64'(MMR_ScratchLo_F_Data), 64'(MMR_ScratchLo_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchLo_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHLO))));
assign MMR_ScratchLo_F_Data_Data_prev = MMR_ScratchLo_F_Data;
assign MMR_ScratchLo_F_Data_Data_muxed = MMR_ScratchLo_F_Data_WrEn ? MMR_ScratchLo_F_Data_Data : MMR_ScratchLo_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SCRATCHLO_DATA_WIDTH-1:0])),
    .RESET_VALUE (NTR_SCRATCHLO_DATA_WIDTH'(0))
) MMR_ScratchLo_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchLo_F_Data_WrEn),
    .in    (MMR_ScratchLo_F_Data_Data),
    .out   (MMR_ScratchLo_F_Data)
);

logic                                           MMR_ScratchHi_F_Data_WrEn;
logic [NTR_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data;
logic [NTR_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_DataEff;
logic [NTR_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data_muxed;
logic [NTR_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data_prev;
assign MMR_ScratchHi_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchHi_F_Data_Data = (NTR_SCRATCHHI_DATA_WIDTH'(update_value(64'(MMR_ScratchHi_F_Data), 64'(MMR_ScratchHi_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchHi_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHHI))));
assign MMR_ScratchHi_F_Data_Data_prev = MMR_ScratchHi_F_Data;
assign MMR_ScratchHi_F_Data_Data_muxed = MMR_ScratchHi_F_Data_WrEn ? MMR_ScratchHi_F_Data_Data : MMR_ScratchHi_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [NTR_SCRATCHHI_DATA_WIDTH-1:0])),
    .RESET_VALUE (NTR_SCRATCHHI_DATA_WIDTH'(0))
) MMR_ScratchHi_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchHi_F_Data_WrEn),
    .in    (MMR_ScratchHi_F_Data_Data),
    .out   (MMR_ScratchHi_F_Data)
);

assign MMR_Trtecontrol = {
    MMR_Trtecontrol_F_Rsvd3127,
    MMR_Trtecontrol_F_Trteformat,
    MMR_Trtecontrol_F_Trtesyncmax,
    MMR_Trtecontrol_F_Rsvd1918,
    MMR_Trtecontrol_F_Trtesyncmode,
    MMR_Trtecontrol_F_Trteinhibitsrc,
    MMR_Trtecontrol_F_Rsvd1414,
    MMR_Trtecontrol_F_Trteinststallena,
    MMR_Trtecontrol_F_Trteinststalloroverflow,
    MMR_Trtecontrol_F_Trteinsttriggerenable,
    MMR_Trtecontrol_F_Rsvd1010,
    MMR_Trtecontrol_F_Trtecontext,
    MMR_Trtecontrol_F_Rsvd87,
    MMR_Trtecontrol_F_Trteinstmode,
    MMR_Trtecontrol_F_Trteempty,
    MMR_Trtecontrol_F_Trteinsttracing,
    MMR_Trtecontrol_F_Trteenable,
    MMR_Trtecontrol_F_Trteactive
};
logic [31:0] MMR_Trtecontrol_muxed;
assign MMR_Trtecontrol_muxed = {
    MMR_Trtecontrol_F_Rsvd3127,
    MMR_Trtecontrol_F_Trteformat_Data_muxed,
    MMR_Trtecontrol_F_Trtesyncmax_Data_muxed,
    MMR_Trtecontrol_F_Rsvd1918,
    MMR_Trtecontrol_F_Trtesyncmode_Data_muxed,
    MMR_Trtecontrol_F_Trteinhibitsrc_Data_muxed,
    MMR_Trtecontrol_F_Rsvd1414,
    MMR_Trtecontrol_F_Trteinststallena_Data_muxed,
    MMR_Trtecontrol_F_Trteinststalloroverflow_Data_muxed,
    MMR_Trtecontrol_F_Trteinsttriggerenable_Data_muxed,
    MMR_Trtecontrol_F_Rsvd1010,
    MMR_Trtecontrol_F_Trtecontext_Data_muxed,
    MMR_Trtecontrol_F_Rsvd87,
    MMR_Trtecontrol_F_Trteinstmode_Data_muxed,
    MMR_Trtecontrol_F_Trteempty_Data_muxed,
    MMR_Trtecontrol_F_Trteinsttracing_Data_muxed,
    MMR_Trtecontrol_F_Trteenable_Data_muxed,
    MMR_Trtecontrol_F_Trteactive_Data_muxed
};
assign MMR_Trteimpl = {
    MMR_Trteimpl_F_Rsvd3130,
    MMR_Trteimpl_F_Trtetracepatchenable,
    MMR_Trteimpl_F_Trteclatriggerenable,
    MMR_Trteimpl_F_Trtevendorframelength,
    MMR_Trteimpl_F_Trteprotocolminor,
    MMR_Trteimpl_F_Trteprotocolmajor,
    MMR_Trteimpl_F_Rsvd1512,
    MMR_Trteimpl_F_Trtecomptype,
    MMR_Trteimpl_F_Trteverminor,
    MMR_Trteimpl_F_Trtevermajor
};
logic [31:0] MMR_Trteimpl_muxed;
assign MMR_Trteimpl_muxed = {
    MMR_Trteimpl_F_Rsvd3130,
    MMR_Trteimpl_F_Trtetracepatchenable_Data_muxed,
    MMR_Trteimpl_F_Trteclatriggerenable_Data_muxed,
    MMR_Trteimpl_F_Trtevendorframelength_Data_muxed,
    MMR_Trteimpl_F_Trteprotocolminor,
    MMR_Trteimpl_F_Trteprotocolmajor,
    MMR_Trteimpl_F_Rsvd1512,
    MMR_Trteimpl_F_Trtecomptype,
    MMR_Trteimpl_F_Trteverminor,
    MMR_Trteimpl_F_Trtevermajor
};
assign MMR_Trteinstfeatures = {
    MMR_Trteinstfeatures_F_Trtesrcbits,
    MMR_Trteinstfeatures_F_Trtesrcid,
    MMR_Trteinstfeatures_F_Rsvd159,
    MMR_Trteinstfeatures_F_Trteinstenrepeatedhistory,
    MMR_Trteinstfeatures_F_Rsvd72,
    MMR_Trteinstfeatures_F_Trteinstnotrapaddr,
    MMR_Trteinstfeatures_F_Trteinstnoaddrdiff
};
logic [31:0] MMR_Trteinstfeatures_muxed;
assign MMR_Trteinstfeatures_muxed = {
    MMR_Trteinstfeatures_F_Trtesrcbits_Data_muxed,
    MMR_Trteinstfeatures_F_Trtesrcid_Data_muxed,
    MMR_Trteinstfeatures_F_Rsvd159,
    MMR_Trteinstfeatures_F_Trteinstenrepeatedhistory,
    MMR_Trteinstfeatures_F_Rsvd72,
    MMR_Trteinstfeatures_F_Trteinstnotrapaddr_Data_muxed,
    MMR_Trteinstfeatures_F_Trteinstnoaddrdiff_Data_muxed
};
assign MMR_Trteinstfilters = {
    MMR_Trteinstfilters_F_Rsvd3116,
    MMR_Trteinstfilters_F_Trteinstfilters
};
logic [31:0] MMR_Trteinstfilters_muxed;
assign MMR_Trteinstfilters_muxed = {
    MMR_Trteinstfilters_F_Rsvd3116,
    MMR_Trteinstfilters_F_Trteinstfilters_Data_muxed
};
assign MMR_Trtefilter0Control = {
    MMR_Trtefilter0Control_F_Rsvd312,
    MMR_Trtefilter0Control_F_Trtefiltermatchprivilege,
    MMR_Trtefilter0Control_F_Trtefilterenable
};
logic [31:0] MMR_Trtefilter0Control_muxed;
assign MMR_Trtefilter0Control_muxed = {
    MMR_Trtefilter0Control_F_Rsvd312,
    MMR_Trtefilter0Control_F_Trtefiltermatchprivilege_Data_muxed,
    MMR_Trtefilter0Control_F_Trtefilterenable_Data_muxed
};
assign MMR_Trtefilter0Matchinst = {
    MMR_Trtefilter0Matchinst_F_Rsvd318,
    MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege
};
logic [31:0] MMR_Trtefilter0Matchinst_muxed;
assign MMR_Trtefilter0Matchinst_muxed = {
    MMR_Trtefilter0Matchinst_F_Rsvd318,
    MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege_Data_muxed
};
assign MMR_Trtscontrol = {
    MMR_Trtscontrol_F_Rsvd3130,
    MMR_Trtscontrol_F_Trtswidth,
    MMR_Trtscontrol_F_Rsvd2316,
    MMR_Trtscontrol_F_Trtsenable,
    MMR_Trtscontrol_F_Rsvd1410,
    MMR_Trtscontrol_F_Trtsprescale,
    MMR_Trtscontrol_F_Rsvd77,
    MMR_Trtscontrol_F_Trtstype,
    MMR_Trtscontrol_F_Trtsrunindebug,
    MMR_Trtscontrol_F_Trtsreset,
    MMR_Trtscontrol_F_Trtscount,
    MMR_Trtscontrol_F_Trtsactive
};
logic [31:0] MMR_Trtscontrol_muxed;
assign MMR_Trtscontrol_muxed = {
    MMR_Trtscontrol_F_Rsvd3130,
    MMR_Trtscontrol_F_Trtswidth,
    MMR_Trtscontrol_F_Rsvd2316,
    MMR_Trtscontrol_F_Trtsenable_Data_muxed,
    MMR_Trtscontrol_F_Rsvd1410,
    MMR_Trtscontrol_F_Trtsprescale,
    MMR_Trtscontrol_F_Rsvd77,
    MMR_Trtscontrol_F_Trtstype,
    MMR_Trtscontrol_F_Trtsrunindebug,
    MMR_Trtscontrol_F_Trtsreset,
    MMR_Trtscontrol_F_Trtscount,
    MMR_Trtscontrol_F_Trtsactive_Data_muxed
};
assign MMR_CDbgNtraceFrameCfg = {
    MMR_CDbgNtraceFrameCfg_F_Rsvd3122,
    MMR_CDbgNtraceFrameCfg_F_FrameClosureMode,
    MMR_CDbgNtraceFrameCfg_F_FrameModeEnable,
    MMR_CDbgNtraceFrameCfg_F_Rsvd1916,
    MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes,
    MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte,
    MMR_CDbgNtraceFrameCfg_F_TraceSourceId
};
logic [31:0] MMR_CDbgNtraceFrameCfg_muxed;
assign MMR_CDbgNtraceFrameCfg_muxed = {
    MMR_CDbgNtraceFrameCfg_F_Rsvd3122,
    MMR_CDbgNtraceFrameCfg_F_FrameClosureMode_Data_muxed,
    MMR_CDbgNtraceFrameCfg_F_FrameModeEnable_Data_muxed,
    MMR_CDbgNtraceFrameCfg_F_Rsvd1916,
    MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes_Data_muxed,
    MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte_Data_muxed,
    MMR_CDbgNtraceFrameCfg_F_TraceSourceId_Data_muxed
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
        ADDR_MMR_TRTECONTROL                    : begin : mmr_rd_hit_MMR_Trtecontrol reg_prehit.NtrMmrTrtecontrolHit = 1'b1; reg_rd_data = {MMR_Trtecontrol}; end
        ADDR_MMR_TRTEIMPL                       : begin : mmr_rd_hit_MMR_Trteimpl reg_prehit.NtrMmrTrteimplHit = 1'b1; reg_rd_data = {MMR_Trteimpl}; end
        ADDR_MMR_TRTEINSTFEATURES               : begin : mmr_rd_hit_MMR_Trteinstfeatures reg_prehit.NtrMmrTrteinstfeaturesHit = 1'b1; reg_rd_data = {MMR_Trteinstfeatures}; end
        ADDR_MMR_TRTEINSTFILTERS                : begin : mmr_rd_hit_MMR_Trteinstfilters reg_prehit.NtrMmrTrteinstfiltersHit = 1'b1; reg_rd_data = {MMR_Trteinstfilters}; end
        ADDR_MMR_TRTEFILTER0CONTROL             : begin : mmr_rd_hit_MMR_Trtefilter0Control reg_prehit.NtrMmrTrtefilter0ControlHit = 1'b1; reg_rd_data = {MMR_Trtefilter0Control}; end
        ADDR_MMR_TRTEFILTER0MATCHINST           : begin : mmr_rd_hit_MMR_Trtefilter0Matchinst reg_prehit.NtrMmrTrtefilter0MatchinstHit = 1'b1; reg_rd_data = {MMR_Trtefilter0Matchinst}; end
        ADDR_MMR_TRTSCONTROL                    : begin : mmr_rd_hit_MMR_Trtscontrol reg_prehit.NtrMmrTrtscontrolHit = 1'b1; reg_rd_data = {MMR_Trtscontrol}; end
        ADDR_MMR_CDBGNTRACEFRAMECFG             : begin : mmr_rd_hit_MMR_CDbgNtraceFrameCfg reg_prehit.NtrMmrCdbgntraceframecfgHit = 1'b1; reg_rd_data = {MMR_CDbgNtraceFrameCfg}; end
        ADDR_MMR_SCRATCHLO                      : begin : mmr_rd_hit_MMR_ScratchLo reg_prehit.NtrMmrScratchloHit = 1'b1; reg_rd_data = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : mmr_rd_hit_MMR_ScratchHi reg_prehit.NtrMmrScratchhiHit = 1'b1; reg_rd_data = {MMR_ScratchHi}; end
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
        ADDR_MMR_TRTECONTROL                    : begin : mmr_rd_d1_MMR_Trtecontrol reg_rd_data_d1 = {MMR_Trtecontrol}; end
        ADDR_MMR_TRTEIMPL                       : begin : mmr_rd_d1_MMR_Trteimpl reg_rd_data_d1 = {MMR_Trteimpl}; end
        ADDR_MMR_TRTEINSTFEATURES               : begin : mmr_rd_d1_MMR_Trteinstfeatures reg_rd_data_d1 = {MMR_Trteinstfeatures}; end
        ADDR_MMR_TRTEINSTFILTERS                : begin : mmr_rd_d1_MMR_Trteinstfilters reg_rd_data_d1 = {MMR_Trteinstfilters}; end
        ADDR_MMR_TRTEFILTER0CONTROL             : begin : mmr_rd_d1_MMR_Trtefilter0Control reg_rd_data_d1 = {MMR_Trtefilter0Control}; end
        ADDR_MMR_TRTEFILTER0MATCHINST           : begin : mmr_rd_d1_MMR_Trtefilter0Matchinst reg_rd_data_d1 = {MMR_Trtefilter0Matchinst}; end
        ADDR_MMR_TRTSCONTROL                    : begin : mmr_rd_d1_MMR_Trtscontrol reg_rd_data_d1 = {MMR_Trtscontrol}; end
        ADDR_MMR_CDBGNTRACEFRAMECFG             : begin : mmr_rd_d1_MMR_CDbgNtraceFrameCfg reg_rd_data_d1 = {MMR_CDbgNtraceFrameCfg}; end
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
        .WIDTH ($bits(logic [NTR_NUM_REGISTERS-1:0])),
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

assign NtrMmrTrtecontrol.Rsvd3127               = MMR_Trtecontrol_F_Rsvd3127;
assign NtrMmrTrtecontrol.Trteformat             = MMR_Trtecontrol_F_Trteformat;
assign NtrMmrTrtecontrol.Trtesyncmax            = MMR_Trtecontrol_F_Trtesyncmax;
assign NtrMmrTrtecontrol.Rsvd1918               = MMR_Trtecontrol_F_Rsvd1918;
assign NtrMmrTrtecontrol.Trtesyncmode           = MMR_Trtecontrol_F_Trtesyncmode;
assign NtrMmrTrtecontrol.Trteinhibitsrc         = MMR_Trtecontrol_F_Trteinhibitsrc;
assign NtrMmrTrtecontrol.Rsvd1414               = MMR_Trtecontrol_F_Rsvd1414;
assign NtrMmrTrtecontrol.Trteinststallena       = MMR_Trtecontrol_F_Trteinststallena;
assign NtrMmrTrtecontrol.Trteinststalloroverflow = MMR_Trtecontrol_F_Trteinststalloroverflow;
assign NtrMmrTrtecontrol.Trteinsttriggerenable  = MMR_Trtecontrol_F_Trteinsttriggerenable;
assign NtrMmrTrtecontrol.Rsvd1010               = MMR_Trtecontrol_F_Rsvd1010;
assign NtrMmrTrtecontrol.Trtecontext            = MMR_Trtecontrol_F_Trtecontext;
assign NtrMmrTrtecontrol.Rsvd87                 = MMR_Trtecontrol_F_Rsvd87;
assign NtrMmrTrtecontrol.Trteinstmode           = MMR_Trtecontrol_F_Trteinstmode;
assign NtrMmrTrtecontrol.Trteempty              = MMR_Trtecontrol_F_Trteempty;
assign NtrMmrTrtecontrol.Trteinsttracing        = MMR_Trtecontrol_F_Trteinsttracing;
assign NtrMmrTrtecontrol.Trteenable             = MMR_Trtecontrol_F_Trteenable;
assign NtrMmrTrtecontrol.Trteactive             = MMR_Trtecontrol_F_Trteactive;
assign NtrMmrTrteimpl.Rsvd3130                  = MMR_Trteimpl_F_Rsvd3130;
assign NtrMmrTrteimpl.Trtetracepatchenable      = MMR_Trteimpl_F_Trtetracepatchenable;
assign NtrMmrTrteimpl.Trteclatriggerenable      = MMR_Trteimpl_F_Trteclatriggerenable;
assign NtrMmrTrteimpl.Trtevendorframelength     = MMR_Trteimpl_F_Trtevendorframelength;
assign NtrMmrTrteimpl.Trteprotocolminor         = MMR_Trteimpl_F_Trteprotocolminor;
assign NtrMmrTrteimpl.Trteprotocolmajor         = MMR_Trteimpl_F_Trteprotocolmajor;
assign NtrMmrTrteimpl.Rsvd1512                  = MMR_Trteimpl_F_Rsvd1512;
assign NtrMmrTrteimpl.Trtecomptype              = MMR_Trteimpl_F_Trtecomptype;
assign NtrMmrTrteimpl.Trteverminor              = MMR_Trteimpl_F_Trteverminor;
assign NtrMmrTrteimpl.Trtevermajor              = MMR_Trteimpl_F_Trtevermajor;
assign NtrMmrTrteinstfeatures.Trtesrcbits       = MMR_Trteinstfeatures_F_Trtesrcbits;
assign NtrMmrTrteinstfeatures.Trtesrcid         = MMR_Trteinstfeatures_F_Trtesrcid;
assign NtrMmrTrteinstfeatures.Rsvd159           = MMR_Trteinstfeatures_F_Rsvd159;
assign NtrMmrTrteinstfeatures.Trteinstenrepeatedhistory = MMR_Trteinstfeatures_F_Trteinstenrepeatedhistory;
assign NtrMmrTrteinstfeatures.Rsvd72            = MMR_Trteinstfeatures_F_Rsvd72;
assign NtrMmrTrteinstfeatures.Trteinstnotrapaddr = MMR_Trteinstfeatures_F_Trteinstnotrapaddr;
assign NtrMmrTrteinstfeatures.Trteinstnoaddrdiff = MMR_Trteinstfeatures_F_Trteinstnoaddrdiff;
assign NtrMmrTrteinstfilters.Rsvd3116           = MMR_Trteinstfilters_F_Rsvd3116;
assign NtrMmrTrteinstfilters.Trteinstfilters    = MMR_Trteinstfilters_F_Trteinstfilters;
assign NtrMmrTrtefilter0Control.Rsvd312         = MMR_Trtefilter0Control_F_Rsvd312;
assign NtrMmrTrtefilter0Control.Trtefiltermatchprivilege = MMR_Trtefilter0Control_F_Trtefiltermatchprivilege;
assign NtrMmrTrtefilter0Control.Trtefilterenable = MMR_Trtefilter0Control_F_Trtefilterenable;
assign NtrMmrTrtefilter0Matchinst.Rsvd318       = MMR_Trtefilter0Matchinst_F_Rsvd318;
assign NtrMmrTrtefilter0Matchinst.Trtefiltermatchchoiceprivilege = MMR_Trtefilter0Matchinst_F_Trtefiltermatchchoiceprivilege;
assign NtrMmrTrtscontrol.Rsvd3130               = MMR_Trtscontrol_F_Rsvd3130;
assign NtrMmrTrtscontrol.Trtswidth              = MMR_Trtscontrol_F_Trtswidth;
assign NtrMmrTrtscontrol.Rsvd2316               = MMR_Trtscontrol_F_Rsvd2316;
assign NtrMmrTrtscontrol.Trtsenable             = MMR_Trtscontrol_F_Trtsenable;
assign NtrMmrTrtscontrol.Rsvd1410               = MMR_Trtscontrol_F_Rsvd1410;
assign NtrMmrTrtscontrol.Trtsprescale           = MMR_Trtscontrol_F_Trtsprescale;
assign NtrMmrTrtscontrol.Rsvd77                 = MMR_Trtscontrol_F_Rsvd77;
assign NtrMmrTrtscontrol.Trtstype               = MMR_Trtscontrol_F_Trtstype;
assign NtrMmrTrtscontrol.Trtsrunindebug         = MMR_Trtscontrol_F_Trtsrunindebug;
assign NtrMmrTrtscontrol.Trtsreset              = MMR_Trtscontrol_F_Trtsreset;
assign NtrMmrTrtscontrol.Trtscount              = MMR_Trtscontrol_F_Trtscount;
assign NtrMmrTrtscontrol.Trtsactive             = MMR_Trtscontrol_F_Trtsactive;
assign NtrMmrCdbgntraceframecfg.Rsvd3122        = MMR_CDbgNtraceFrameCfg_F_Rsvd3122;
assign NtrMmrCdbgntraceframecfg.FrameClosureMode = MMR_CDbgNtraceFrameCfg_F_FrameClosureMode;
assign NtrMmrCdbgntraceframecfg.FrameModeEnable = MMR_CDbgNtraceFrameCfg_F_FrameModeEnable;
assign NtrMmrCdbgntraceframecfg.Rsvd1916        = MMR_CDbgNtraceFrameCfg_F_Rsvd1916;
assign NtrMmrCdbgntraceframecfg.FrameLenghtInBytes = MMR_CDbgNtraceFrameCfg_F_FrameLenghtInBytes;
assign NtrMmrCdbgntraceframecfg.TraceFrameFillByte = MMR_CDbgNtraceFrameCfg_F_TraceFrameFillByte;
assign NtrMmrCdbgntraceframecfg.TraceSourceId   = MMR_CDbgNtraceFrameCfg_F_TraceSourceId;
assign NtrMmrScratchlo.Data                     = MMR_ScratchLo_F_Data;
assign NtrMmrScratchhi.Data                     = MMR_ScratchHi_F_Data;

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
        ADDR_MMR_TRTECONTROL                    : begin : get_reg_val_MMR_Trtecontrol get_register_value = {MMR_Trtecontrol}; end
        ADDR_MMR_TRTEIMPL                       : begin : get_reg_val_MMR_Trteimpl get_register_value = {MMR_Trteimpl}; end
        ADDR_MMR_TRTEINSTFEATURES               : begin : get_reg_val_MMR_Trteinstfeatures get_register_value = {MMR_Trteinstfeatures}; end
        ADDR_MMR_TRTEINSTFILTERS                : begin : get_reg_val_MMR_Trteinstfilters get_register_value = {MMR_Trteinstfilters}; end
        ADDR_MMR_TRTEFILTER0CONTROL             : begin : get_reg_val_MMR_Trtefilter0Control get_register_value = {MMR_Trtefilter0Control}; end
        ADDR_MMR_TRTEFILTER0MATCHINST           : begin : get_reg_val_MMR_Trtefilter0Matchinst get_register_value = {MMR_Trtefilter0Matchinst}; end
        ADDR_MMR_TRTSCONTROL                    : begin : get_reg_val_MMR_Trtscontrol get_register_value = {MMR_Trtscontrol}; end
        ADDR_MMR_CDBGNTRACEFRAMECFG             : begin : get_reg_val_MMR_CDbgNtraceFrameCfg get_register_value = {MMR_CDbgNtraceFrameCfg}; end
        ADDR_MMR_SCRATCHLO                      : begin : get_reg_val_MMR_ScratchLo get_register_value = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : get_reg_val_MMR_ScratchHi get_register_value = {MMR_ScratchHi}; end
        default                                 : begin : get_reg_val_default get_register_value = 'x; end
    endcase
  end
endfunction

endmodule
