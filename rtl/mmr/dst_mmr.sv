// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dst_mmr
import dst_mmr_pkg::*;
`include "dst_mmr_pkg_list.svh"
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
output DstMmrHit_s                              MmrHitList,
output logic                             [31:0] MmrRdData,

output DstTrdstcontrolMmr_s                     DstMmrTrdstcontrol,
output DstTrdstimplMmr_s                        DstMmrTrdstimpl,
output DstTrdstinstfeaturesMmr_s                DstMmrTrdstinstfeatures,
output DstCdbgdebugtracecfgMmr_s                DstMmrCdbgdebugtracecfg,
output DstScratchloMmr_s                        DstMmrScratchlo,
output DstScratchhiMmr_s                        DstMmrScratchhi,

input DstTrdstcontrolMmrWr_s                    DstMmrTrdstcontrolWr,

output logic                                    MmrUpdateEn,
output logic                       [ADDR_W-1:0] MmrUpdateAddr,
output logic                       [ADDR_W_INDIR-1:0] MmrUpdateIndirAddr,
output logic                             [31:0] MmrUpdateData

);

localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTCONTROL          = ADDR_W'(BASE_ADDR + 'h0);
localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTIMPL             = ADDR_W'(BASE_ADDR + 'h4);
localparam   [ADDR_W-1:0] ADDR_MMR_TRDSTINSTFEATURES     = ADDR_W'(BASE_ADDR + 'h8);
localparam   [ADDR_W-1:0] ADDR_MMR_CDBGDEBUGTRACECFG     = ADDR_W'(BASE_ADDR + 'h1A0);
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
DstMmrHit_s                 reg_prehit;
logic                       reg_hit;
logic                [31:0] reg_rd_data;

logic                       reg_write;
logic                       reg_read;

logic          [ADDR_W-1:0] reg_addr_d1;
logic          [ADDR_W_INDIR-1:0] reg_addr_select_d1;
logic                       reg_write_d1;
logic                       reg_hit_d1;
logic                [31:0] reg_rd_data_d1;

logic                [31:0] MMR_Trdstcontrol;
logic                [31:0] MMR_Trdstimpl;
logic                [31:0] MMR_Trdstinstfeatures;
logic                [31:0] MMR_CDbgDebugTraceCfg;
logic                [31:0] MMR_ScratchLo;
logic                [31:0] MMR_ScratchHi;

logic                 [4:0] MMR_Trdstcontrol_F_Rsvd3127;
logic                 [2:0] MMR_Trdstcontrol_F_Trdstformat;
logic                 [3:0] MMR_Trdstcontrol_F_Trdstsyncmax;
logic                 [1:0] MMR_Trdstcontrol_F_Rsvd1918;
logic                 [1:0] MMR_Trdstcontrol_F_Trdstsyncmode;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstinhibitsrc;
logic                 [0:0] MMR_Trdstcontrol_F_Rsvd1414;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstinststallena;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstinststalloroverflow;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstinsttriggerenable;
logic                 [0:0] MMR_Trdstcontrol_F_Rsvd1010;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstcontext;
logic                 [1:0] MMR_Trdstcontrol_F_Rsvd87;
logic                 [2:0] MMR_Trdstcontrol_F_Trdstinstmode;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstempty;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstinsttracing;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstenable;
logic                 [0:0] MMR_Trdstcontrol_F_Trdstactive;
logic                 [0:0] MMR_Trdstimpl_F_Trdsttimestampconfig;
logic                 [2:0] MMR_Trdstimpl_F_Trdstvendorstreamlength;
logic                 [3:0] MMR_Trdstimpl_F_Trdstvendorframelength;
logic                 [3:0] MMR_Trdstimpl_F_Trdstprotocolminor;
logic                 [3:0] MMR_Trdstimpl_F_Trdstprotocolmajor;
logic                 [3:0] MMR_Trdstimpl_F_Rsvd1512;
logic                 [3:0] MMR_Trdstimpl_F_Trdstcomptype;
logic                 [3:0] MMR_Trdstimpl_F_Trdstverminor;
logic                 [3:0] MMR_Trdstimpl_F_Trdstvermajor;
logic                 [3:0] MMR_Trdstinstfeatures_F_Trdstsrcbits;
logic                [11:0] MMR_Trdstinstfeatures_F_Trdstsrcid;
logic                 [6:0] MMR_Trdstinstfeatures_F_Rsvd159;
logic                 [0:0] MMR_Trdstinstfeatures_F_Trdstinstenrepeatedhistory;
logic                 [5:0] MMR_Trdstinstfeatures_F_Rsvd72;
logic                 [0:0] MMR_Trdstinstfeatures_F_Trdstinstnotrapaddr;
logic                 [0:0] MMR_Trdstinstfeatures_F_Trdstinstnoaddrdiff;
logic                 [9:0] MMR_CDbgDebugTraceCfg_F_Rsvd3122;
logic                 [0:0] MMR_CDbgDebugTraceCfg_F_FrameClosureMode;
logic                 [0:0] MMR_CDbgDebugTraceCfg_F_FrameModeEnable;
logic                 [3:0] MMR_CDbgDebugTraceCfg_F_Rsvd1916;
logic                 [3:0] MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes;
logic                 [7:0] MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte;
logic                 [3:0] MMR_CDbgDebugTraceCfg_F_TraceSourceId;
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

assign MMR_Trdstcontrol_F_Rsvd3127 = 5'h0;

logic                                           MMR_Trdstcontrol_F_Trdstformat_WrEn;
logic [DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstformat_Data;
logic [DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstformat_DataEff;
logic [DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstformat_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstformat_Data_prev;
assign MMR_Trdstcontrol_F_Trdstformat_DataEff = {reg_wr_data[26:24]};
assign MMR_Trdstcontrol_F_Trdstformat_Data = (DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstformat), 64'(MMR_Trdstcontrol_F_Trdstformat_DataEff[2:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstformat_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstformat_Data_prev = MMR_Trdstcontrol_F_Trdstformat;
assign MMR_Trdstcontrol_F_Trdstformat_Data_muxed = MMR_Trdstcontrol_F_Trdstformat_WrEn ? MMR_Trdstcontrol_F_Trdstformat_Data : MMR_Trdstcontrol_F_Trdstformat_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTFORMAT_WIDTH'(3'h3))
) MMR_Trdstcontrol_F_Trdstformat_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstformat_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstformat_Data),
    .out   (MMR_Trdstcontrol_F_Trdstformat)
);

logic                                           MMR_Trdstcontrol_F_Trdstsyncmax_WrEn;
logic [DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmax_Data;
logic [DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmax_DataEff;
logic [DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmax_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmax_Data_prev;
assign MMR_Trdstcontrol_F_Trdstsyncmax_DataEff = {reg_wr_data[23:20]};
assign MMR_Trdstcontrol_F_Trdstsyncmax_Data = (DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstsyncmax), 64'(MMR_Trdstcontrol_F_Trdstsyncmax_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstsyncmax_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstsyncmax_Data_prev = MMR_Trdstcontrol_F_Trdstsyncmax;
assign MMR_Trdstcontrol_F_Trdstsyncmax_Data_muxed = MMR_Trdstcontrol_F_Trdstsyncmax_WrEn ? MMR_Trdstcontrol_F_Trdstsyncmax_Data : MMR_Trdstcontrol_F_Trdstsyncmax_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTSYNCMAX_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstsyncmax_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstsyncmax_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstsyncmax_Data),
    .out   (MMR_Trdstcontrol_F_Trdstsyncmax)
);

assign MMR_Trdstcontrol_F_Rsvd1918 = 2'h0;

logic                                           MMR_Trdstcontrol_F_Trdstsyncmode_WrEn;
logic [DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmode_Data;
logic [DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmode_DataEff;
logic [DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmode_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstsyncmode_Data_prev;
assign MMR_Trdstcontrol_F_Trdstsyncmode_DataEff = {reg_wr_data[17:16]};
assign MMR_Trdstcontrol_F_Trdstsyncmode_Data = (DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstsyncmode), 64'(MMR_Trdstcontrol_F_Trdstsyncmode_DataEff[1:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstsyncmode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstsyncmode_Data_prev = MMR_Trdstcontrol_F_Trdstsyncmode;
assign MMR_Trdstcontrol_F_Trdstsyncmode_Data_muxed = MMR_Trdstcontrol_F_Trdstsyncmode_WrEn ? MMR_Trdstcontrol_F_Trdstsyncmode_Data : MMR_Trdstcontrol_F_Trdstsyncmode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTSYNCMODE_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstsyncmode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstsyncmode_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstsyncmode_Data),
    .out   (MMR_Trdstcontrol_F_Trdstsyncmode)
);

assign MMR_Trdstcontrol_F_Trdstinhibitsrc = 1'h0;

assign MMR_Trdstcontrol_F_Rsvd1414 = 1'h0;

assign MMR_Trdstcontrol_F_Trdstinststallena = 1'h0;

assign MMR_Trdstcontrol_F_Trdstinststalloroverflow = 1'h0;

logic                                           MMR_Trdstcontrol_F_Trdstinsttriggerenable_WrEn;
logic [DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data;
logic [DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttriggerenable_DataEff;
logic [DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_prev;
assign MMR_Trdstcontrol_F_Trdstinsttriggerenable_DataEff = {reg_wr_data[11:11]};
assign MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data = (DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstinsttriggerenable), 64'(MMR_Trdstcontrol_F_Trdstinsttriggerenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstinsttriggerenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_prev = MMR_Trdstcontrol_F_Trdstinsttriggerenable;
assign MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_muxed = MMR_Trdstcontrol_F_Trdstinsttriggerenable_WrEn ? MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data : MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTINSTTRIGGERENABLE_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstinsttriggerenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstinsttriggerenable_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data),
    .out   (MMR_Trdstcontrol_F_Trdstinsttriggerenable)
);

assign MMR_Trdstcontrol_F_Rsvd1010 = 1'h0;

assign MMR_Trdstcontrol_F_Trdstcontext = 1'h0;

assign MMR_Trdstcontrol_F_Rsvd87 = 2'h0;

assign MMR_Trdstcontrol_F_Trdstinstmode = 3'h6;

logic                                           MMR_Trdstcontrol_F_Trdstempty_WrEn;
logic [DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH  -1:0] MMR_Trdstcontrol_F_Trdstempty_Data;
logic [DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH  -1:0] MMR_Trdstcontrol_F_Trdstempty_DataEff;
logic [DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH  -1:0] MMR_Trdstcontrol_F_Trdstempty_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH  -1:0] MMR_Trdstcontrol_F_Trdstempty_Data_prev;
assign MMR_Trdstcontrol_F_Trdstempty_DataEff = {reg_wr_data[3:3]};
assign MMR_Trdstcontrol_F_Trdstempty_Data = (DstMmrTrdstcontrolWr.Data.Trdstempty);
assign MMR_Trdstcontrol_F_Trdstempty_WrEn = ((DstMmrTrdstcontrolWr.TrdstemptyWrEn));
assign MMR_Trdstcontrol_F_Trdstempty_Data_prev = MMR_Trdstcontrol_F_Trdstempty;
assign MMR_Trdstcontrol_F_Trdstempty_Data_muxed = MMR_Trdstcontrol_F_Trdstempty_WrEn ? MMR_Trdstcontrol_F_Trdstempty_Data : MMR_Trdstcontrol_F_Trdstempty_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTEMPTY_WIDTH'(1))
) MMR_Trdstcontrol_F_Trdstempty_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstempty_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstempty_Data),
    .out   (MMR_Trdstcontrol_F_Trdstempty)
);

logic                                           MMR_Trdstcontrol_F_Trdstinsttracing_WrEn;
logic [DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttracing_Data;
logic [DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttracing_DataEff;
logic [DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttracing_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH-1:0] MMR_Trdstcontrol_F_Trdstinsttracing_Data_prev;
assign MMR_Trdstcontrol_F_Trdstinsttracing_DataEff = {reg_wr_data[2:2]};
assign MMR_Trdstcontrol_F_Trdstinsttracing_Data = ((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL)) ? DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstinsttracing), 64'(MMR_Trdstcontrol_F_Trdstinsttracing_DataEff[0:0]), reg_wr_instr_type)) : DstMmrTrdstcontrolWr.Data.Trdstinsttracing);
assign MMR_Trdstcontrol_F_Trdstinsttracing_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL)) | DstMmrTrdstcontrolWr.TrdstinsttracingWrEn));
assign MMR_Trdstcontrol_F_Trdstinsttracing_Data_prev = MMR_Trdstcontrol_F_Trdstinsttracing;
assign MMR_Trdstcontrol_F_Trdstinsttracing_Data_muxed = MMR_Trdstcontrol_F_Trdstinsttracing_WrEn ? MMR_Trdstcontrol_F_Trdstinsttracing_Data : MMR_Trdstcontrol_F_Trdstinsttracing_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTINSTTRACING_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstinsttracing_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstinsttracing_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstinsttracing_Data),
    .out   (MMR_Trdstcontrol_F_Trdstinsttracing)
);

logic                                           MMR_Trdstcontrol_F_Trdstenable_WrEn;
logic [DST_TRDSTCONTROL_TRDSTENABLE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstenable_Data;
logic [DST_TRDSTCONTROL_TRDSTENABLE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstenable_DataEff;
logic [DST_TRDSTCONTROL_TRDSTENABLE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstenable_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTENABLE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstenable_Data_prev;
assign MMR_Trdstcontrol_F_Trdstenable_DataEff = {reg_wr_data[1:1]};
assign MMR_Trdstcontrol_F_Trdstenable_Data = (DST_TRDSTCONTROL_TRDSTENABLE_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstenable), 64'(MMR_Trdstcontrol_F_Trdstenable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstenable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstenable_Data_prev = MMR_Trdstcontrol_F_Trdstenable;
assign MMR_Trdstcontrol_F_Trdstenable_Data_muxed = MMR_Trdstcontrol_F_Trdstenable_WrEn ? MMR_Trdstcontrol_F_Trdstenable_Data : MMR_Trdstcontrol_F_Trdstenable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTENABLE_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTENABLE_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstenable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstenable_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstenable_Data),
    .out   (MMR_Trdstcontrol_F_Trdstenable)
);

logic                                           MMR_Trdstcontrol_F_Trdstactive_WrEn;
logic [DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstactive_Data;
logic [DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstactive_DataEff;
logic [DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstactive_Data_muxed;
logic [DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH -1:0] MMR_Trdstcontrol_F_Trdstactive_Data_prev;
assign MMR_Trdstcontrol_F_Trdstactive_DataEff = {reg_wr_data[0:0]};
assign MMR_Trdstcontrol_F_Trdstactive_Data = (DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH'(update_value(64'(MMR_Trdstcontrol_F_Trdstactive), 64'(MMR_Trdstcontrol_F_Trdstactive_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trdstcontrol_F_Trdstactive_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTCONTROL))));
assign MMR_Trdstcontrol_F_Trdstactive_Data_prev = MMR_Trdstcontrol_F_Trdstactive;
assign MMR_Trdstcontrol_F_Trdstactive_Data_muxed = MMR_Trdstcontrol_F_Trdstactive_WrEn ? MMR_Trdstcontrol_F_Trdstactive_Data : MMR_Trdstcontrol_F_Trdstactive_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTCONTROL_TRDSTACTIVE_WIDTH'(0))
) MMR_Trdstcontrol_F_Trdstactive_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstcontrol_F_Trdstactive_WrEn),
    .in    (MMR_Trdstcontrol_F_Trdstactive_Data),
    .out   (MMR_Trdstcontrol_F_Trdstactive)
);

logic                                           MMR_Trdstimpl_F_Trdsttimestampconfig_WrEn;
logic [DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH-1:0] MMR_Trdstimpl_F_Trdsttimestampconfig_Data;
logic [DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH-1:0] MMR_Trdstimpl_F_Trdsttimestampconfig_DataEff;
logic [DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH-1:0] MMR_Trdstimpl_F_Trdsttimestampconfig_Data_muxed;
logic [DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH-1:0] MMR_Trdstimpl_F_Trdsttimestampconfig_Data_prev;
assign MMR_Trdstimpl_F_Trdsttimestampconfig_DataEff = {reg_wr_data[31:31]};
assign MMR_Trdstimpl_F_Trdsttimestampconfig_Data = (DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH'(update_value(64'(MMR_Trdstimpl_F_Trdsttimestampconfig), 64'(MMR_Trdstimpl_F_Trdsttimestampconfig_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_Trdstimpl_F_Trdsttimestampconfig_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTIMPL))));
assign MMR_Trdstimpl_F_Trdsttimestampconfig_Data_prev = MMR_Trdstimpl_F_Trdsttimestampconfig;
assign MMR_Trdstimpl_F_Trdsttimestampconfig_Data_muxed = MMR_Trdstimpl_F_Trdsttimestampconfig_WrEn ? MMR_Trdstimpl_F_Trdsttimestampconfig_Data : MMR_Trdstimpl_F_Trdsttimestampconfig_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTIMPL_TRDSTTIMESTAMPCONFIG_WIDTH'(0))
) MMR_Trdstimpl_F_Trdsttimestampconfig_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstimpl_F_Trdsttimestampconfig_WrEn),
    .in    (MMR_Trdstimpl_F_Trdsttimestampconfig_Data),
    .out   (MMR_Trdstimpl_F_Trdsttimestampconfig)
);

logic                                           MMR_Trdstimpl_F_Trdstvendorstreamlength_WrEn;
logic [DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorstreamlength_Data;
logic [DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorstreamlength_DataEff;
logic [DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_muxed;
logic [DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_prev;
assign MMR_Trdstimpl_F_Trdstvendorstreamlength_DataEff = {reg_wr_data[30:28]};
assign MMR_Trdstimpl_F_Trdstvendorstreamlength_Data = (DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH'(update_value(64'(MMR_Trdstimpl_F_Trdstvendorstreamlength), 64'(MMR_Trdstimpl_F_Trdstvendorstreamlength_DataEff[2:0]), reg_wr_instr_type)));
assign MMR_Trdstimpl_F_Trdstvendorstreamlength_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTIMPL))));
assign MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_prev = MMR_Trdstimpl_F_Trdstvendorstreamlength;
assign MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_muxed = MMR_Trdstimpl_F_Trdstvendorstreamlength_WrEn ? MMR_Trdstimpl_F_Trdstvendorstreamlength_Data : MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTIMPL_TRDSTVENDORSTREAMLENGTH_WIDTH'(3'h4))
) MMR_Trdstimpl_F_Trdstvendorstreamlength_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstimpl_F_Trdstvendorstreamlength_WrEn),
    .in    (MMR_Trdstimpl_F_Trdstvendorstreamlength_Data),
    .out   (MMR_Trdstimpl_F_Trdstvendorstreamlength)
);

logic                                           MMR_Trdstimpl_F_Trdstvendorframelength_WrEn;
logic [DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorframelength_Data;
logic [DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorframelength_DataEff;
logic [DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorframelength_Data_muxed;
logic [DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH-1:0] MMR_Trdstimpl_F_Trdstvendorframelength_Data_prev;
assign MMR_Trdstimpl_F_Trdstvendorframelength_DataEff = {reg_wr_data[27:24]};
assign MMR_Trdstimpl_F_Trdstvendorframelength_Data = (DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH'(update_value(64'(MMR_Trdstimpl_F_Trdstvendorframelength), 64'(MMR_Trdstimpl_F_Trdstvendorframelength_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trdstimpl_F_Trdstvendorframelength_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTIMPL))));
assign MMR_Trdstimpl_F_Trdstvendorframelength_Data_prev = MMR_Trdstimpl_F_Trdstvendorframelength;
assign MMR_Trdstimpl_F_Trdstvendorframelength_Data_muxed = MMR_Trdstimpl_F_Trdstvendorframelength_WrEn ? MMR_Trdstimpl_F_Trdstvendorframelength_Data : MMR_Trdstimpl_F_Trdstvendorframelength_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTIMPL_TRDSTVENDORFRAMELENGTH_WIDTH'(1))
) MMR_Trdstimpl_F_Trdstvendorframelength_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstimpl_F_Trdstvendorframelength_WrEn),
    .in    (MMR_Trdstimpl_F_Trdstvendorframelength_Data),
    .out   (MMR_Trdstimpl_F_Trdstvendorframelength)
);

assign MMR_Trdstimpl_F_Trdstprotocolminor = 4'h0;

assign MMR_Trdstimpl_F_Trdstprotocolmajor = 4'h1;

assign MMR_Trdstimpl_F_Rsvd1512 = 4'h0;

assign MMR_Trdstimpl_F_Trdstcomptype = 4'h1;

assign MMR_Trdstimpl_F_Trdstverminor = 4'h0;

assign MMR_Trdstimpl_F_Trdstvermajor = 4'h1;

logic                                           MMR_Trdstinstfeatures_F_Trdstsrcbits_WrEn;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcbits_Data;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcbits_DataEff;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_muxed;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_prev;
assign MMR_Trdstinstfeatures_F_Trdstsrcbits_DataEff = {reg_wr_data[31:28]};
assign MMR_Trdstinstfeatures_F_Trdstsrcbits_Data = (DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH'(update_value(64'(MMR_Trdstinstfeatures_F_Trdstsrcbits), 64'(MMR_Trdstinstfeatures_F_Trdstsrcbits_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_Trdstinstfeatures_F_Trdstsrcbits_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTINSTFEATURES))));
assign MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_prev = MMR_Trdstinstfeatures_F_Trdstsrcbits;
assign MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_muxed = MMR_Trdstinstfeatures_F_Trdstsrcbits_WrEn ? MMR_Trdstinstfeatures_F_Trdstsrcbits_Data : MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTINSTFEATURES_TRDSTSRCBITS_WIDTH'(4'h4))
) MMR_Trdstinstfeatures_F_Trdstsrcbits_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstinstfeatures_F_Trdstsrcbits_WrEn),
    .in    (MMR_Trdstinstfeatures_F_Trdstsrcbits_Data),
    .out   (MMR_Trdstinstfeatures_F_Trdstsrcbits)
);

logic                                           MMR_Trdstinstfeatures_F_Trdstsrcid_WrEn;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcid_Data;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcid_DataEff;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcid_Data_muxed;
logic [DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH-1:0] MMR_Trdstinstfeatures_F_Trdstsrcid_Data_prev;
assign MMR_Trdstinstfeatures_F_Trdstsrcid_DataEff = {reg_wr_data[27:16]};
assign MMR_Trdstinstfeatures_F_Trdstsrcid_Data = (DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH'(update_value(64'(MMR_Trdstinstfeatures_F_Trdstsrcid), 64'(MMR_Trdstinstfeatures_F_Trdstsrcid_DataEff[11:0]), reg_wr_instr_type)));
assign MMR_Trdstinstfeatures_F_Trdstsrcid_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_TRDSTINSTFEATURES))));
assign MMR_Trdstinstfeatures_F_Trdstsrcid_Data_prev = MMR_Trdstinstfeatures_F_Trdstsrcid;
assign MMR_Trdstinstfeatures_F_Trdstsrcid_Data_muxed = MMR_Trdstinstfeatures_F_Trdstsrcid_WrEn ? MMR_Trdstinstfeatures_F_Trdstsrcid_Data : MMR_Trdstinstfeatures_F_Trdstsrcid_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH-1:0])),
    .RESET_VALUE (DST_TRDSTINSTFEATURES_TRDSTSRCID_WIDTH'(0))
) MMR_Trdstinstfeatures_F_Trdstsrcid_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_Trdstinstfeatures_F_Trdstsrcid_WrEn),
    .in    (MMR_Trdstinstfeatures_F_Trdstsrcid_Data),
    .out   (MMR_Trdstinstfeatures_F_Trdstsrcid)
);

assign MMR_Trdstinstfeatures_F_Rsvd159 = 7'h0;

assign MMR_Trdstinstfeatures_F_Trdstinstenrepeatedhistory = 1'h0;

assign MMR_Trdstinstfeatures_F_Rsvd72 = 6'h0;

assign MMR_Trdstinstfeatures_F_Trdstinstnotrapaddr = 1'h0;

assign MMR_Trdstinstfeatures_F_Trdstinstnoaddrdiff = 1'h0;

assign MMR_CDbgDebugTraceCfg_F_Rsvd3122 = 10'h0;

logic                                           MMR_CDbgDebugTraceCfg_F_FrameClosureMode_WrEn;
logic [DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data;
logic [DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameClosureMode_DataEff;
logic [DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_muxed;
logic [DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_prev;
assign MMR_CDbgDebugTraceCfg_F_FrameClosureMode_DataEff = {reg_wr_data[21:21]};
assign MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data = (DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH'(update_value(64'(MMR_CDbgDebugTraceCfg_F_FrameClosureMode), 64'(MMR_CDbgDebugTraceCfg_F_FrameClosureMode_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgDebugTraceCfg_F_FrameClosureMode_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGDEBUGTRACECFG))));
assign MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_prev = MMR_CDbgDebugTraceCfg_F_FrameClosureMode;
assign MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_muxed = MMR_CDbgDebugTraceCfg_F_FrameClosureMode_WrEn ? MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data : MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH-1:0])),
    .RESET_VALUE (DST_CDBGDEBUGTRACECFG_FRAMECLOSUREMODE_WIDTH'(0))
) MMR_CDbgDebugTraceCfg_F_FrameClosureMode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgDebugTraceCfg_F_FrameClosureMode_WrEn),
    .in    (MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data),
    .out   (MMR_CDbgDebugTraceCfg_F_FrameClosureMode)
);

logic                                           MMR_CDbgDebugTraceCfg_F_FrameModeEnable_WrEn;
logic [DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data;
logic [DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameModeEnable_DataEff;
logic [DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_muxed;
logic [DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_prev;
assign MMR_CDbgDebugTraceCfg_F_FrameModeEnable_DataEff = {reg_wr_data[20:20]};
assign MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data = (DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH'(update_value(64'(MMR_CDbgDebugTraceCfg_F_FrameModeEnable), 64'(MMR_CDbgDebugTraceCfg_F_FrameModeEnable_DataEff[0:0]), reg_wr_instr_type)));
assign MMR_CDbgDebugTraceCfg_F_FrameModeEnable_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGDEBUGTRACECFG))));
assign MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_prev = MMR_CDbgDebugTraceCfg_F_FrameModeEnable;
assign MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_muxed = MMR_CDbgDebugTraceCfg_F_FrameModeEnable_WrEn ? MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data : MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH-1:0])),
    .RESET_VALUE (DST_CDBGDEBUGTRACECFG_FRAMEMODEENABLE_WIDTH'(1))
) MMR_CDbgDebugTraceCfg_F_FrameModeEnable_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgDebugTraceCfg_F_FrameModeEnable_WrEn),
    .in    (MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data),
    .out   (MMR_CDbgDebugTraceCfg_F_FrameModeEnable)
);

assign MMR_CDbgDebugTraceCfg_F_Rsvd1916 = 4'h0;

logic                                           MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_WrEn;
logic [DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data;
logic [DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_DataEff;
logic [DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_muxed;
logic [DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_prev;
assign MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_DataEff = {reg_wr_data[15:12]};
assign MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data = (DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH'(update_value(64'(MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes), 64'(MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGDEBUGTRACECFG))));
assign MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_prev = MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes;
assign MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_muxed = MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_WrEn ? MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data : MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH-1:0])),
    .RESET_VALUE (DST_CDBGDEBUGTRACECFG_FRAMELENGHTINBYTES_WIDTH'(4'h2))
) MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_WrEn),
    .in    (MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data),
    .out   (MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes)
);

logic                                           MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_WrEn;
logic [DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data;
logic [DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_DataEff;
logic [DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_muxed;
logic [DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_prev;
assign MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_DataEff = {reg_wr_data[11:4]};
assign MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data = (DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH'(update_value(64'(MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte), 64'(MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_DataEff[7:0]), reg_wr_instr_type)));
assign MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGDEBUGTRACECFG))));
assign MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_prev = MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte;
assign MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_muxed = MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_WrEn ? MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data : MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH-1:0])),
    .RESET_VALUE (DST_CDBGDEBUGTRACECFG_TRACEFRAMEFILLBYTE_WIDTH'(8'h81))
) MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_WrEn),
    .in    (MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data),
    .out   (MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte)
);

logic                                           MMR_CDbgDebugTraceCfg_F_TraceSourceId_WrEn;
logic [DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data;
logic [DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceSourceId_DataEff;
logic [DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_muxed;
logic [DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH-1:0] MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_prev;
assign MMR_CDbgDebugTraceCfg_F_TraceSourceId_DataEff = {reg_wr_data[3:0]};
assign MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data = (DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH'(update_value(64'(MMR_CDbgDebugTraceCfg_F_TraceSourceId), 64'(MMR_CDbgDebugTraceCfg_F_TraceSourceId_DataEff[3:0]), reg_wr_instr_type)));
assign MMR_CDbgDebugTraceCfg_F_TraceSourceId_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_CDBGDEBUGTRACECFG))));
assign MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_prev = MMR_CDbgDebugTraceCfg_F_TraceSourceId;
assign MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_muxed = MMR_CDbgDebugTraceCfg_F_TraceSourceId_WrEn ? MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data : MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH-1:0])),
    .RESET_VALUE (DST_CDBGDEBUGTRACECFG_TRACESOURCEID_WIDTH'(0))
) MMR_CDbgDebugTraceCfg_F_TraceSourceId_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_CDbgDebugTraceCfg_F_TraceSourceId_WrEn),
    .in    (MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data),
    .out   (MMR_CDbgDebugTraceCfg_F_TraceSourceId)
);

logic                                           MMR_ScratchLo_F_Data_WrEn;
logic [DST_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data;
logic [DST_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_DataEff;
logic [DST_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data_muxed;
logic [DST_SCRATCHLO_DATA_WIDTH           -1:0] MMR_ScratchLo_F_Data_Data_prev;
assign MMR_ScratchLo_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchLo_F_Data_Data = (DST_SCRATCHLO_DATA_WIDTH'(update_value(64'(MMR_ScratchLo_F_Data), 64'(MMR_ScratchLo_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchLo_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHLO))));
assign MMR_ScratchLo_F_Data_Data_prev = MMR_ScratchLo_F_Data;
assign MMR_ScratchLo_F_Data_Data_muxed = MMR_ScratchLo_F_Data_WrEn ? MMR_ScratchLo_F_Data_Data : MMR_ScratchLo_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_SCRATCHLO_DATA_WIDTH-1:0])),
    .RESET_VALUE (DST_SCRATCHLO_DATA_WIDTH'(0))
) MMR_ScratchLo_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchLo_F_Data_WrEn),
    .in    (MMR_ScratchLo_F_Data_Data),
    .out   (MMR_ScratchLo_F_Data)
);

logic                                           MMR_ScratchHi_F_Data_WrEn;
logic [DST_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data;
logic [DST_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_DataEff;
logic [DST_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data_muxed;
logic [DST_SCRATCHHI_DATA_WIDTH           -1:0] MMR_ScratchHi_F_Data_Data_prev;
assign MMR_ScratchHi_F_Data_DataEff = {reg_wr_data[31:0]};
assign MMR_ScratchHi_F_Data_Data = (DST_SCRATCHHI_DATA_WIDTH'(update_value(64'(MMR_ScratchHi_F_Data), 64'(MMR_ScratchHi_F_Data_DataEff[31:0]), reg_wr_instr_type)));
assign MMR_ScratchHi_F_Data_WrEn = (((reg_write & reg_wr_strb[0] & (reg_addr == ADDR_MMR_SCRATCHHI))));
assign MMR_ScratchHi_F_Data_Data_prev = MMR_ScratchHi_F_Data;
assign MMR_ScratchHi_F_Data_Data_muxed = MMR_ScratchHi_F_Data_WrEn ? MMR_ScratchHi_F_Data_Data : MMR_ScratchHi_F_Data_Data_prev;
generic_dff #(
    .WIDTH       ($bits(logic [DST_SCRATCHHI_DATA_WIDTH-1:0])),
    .RESET_VALUE (DST_SCRATCHHI_DATA_WIDTH'(0))
) MMR_ScratchHi_F_Data_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (MMR_ScratchHi_F_Data_WrEn),
    .in    (MMR_ScratchHi_F_Data_Data),
    .out   (MMR_ScratchHi_F_Data)
);

assign MMR_Trdstcontrol = {
    MMR_Trdstcontrol_F_Rsvd3127,
    MMR_Trdstcontrol_F_Trdstformat,
    MMR_Trdstcontrol_F_Trdstsyncmax,
    MMR_Trdstcontrol_F_Rsvd1918,
    MMR_Trdstcontrol_F_Trdstsyncmode,
    MMR_Trdstcontrol_F_Trdstinhibitsrc,
    MMR_Trdstcontrol_F_Rsvd1414,
    MMR_Trdstcontrol_F_Trdstinststallena,
    MMR_Trdstcontrol_F_Trdstinststalloroverflow,
    MMR_Trdstcontrol_F_Trdstinsttriggerenable,
    MMR_Trdstcontrol_F_Rsvd1010,
    MMR_Trdstcontrol_F_Trdstcontext,
    MMR_Trdstcontrol_F_Rsvd87,
    MMR_Trdstcontrol_F_Trdstinstmode,
    MMR_Trdstcontrol_F_Trdstempty,
    MMR_Trdstcontrol_F_Trdstinsttracing,
    MMR_Trdstcontrol_F_Trdstenable,
    MMR_Trdstcontrol_F_Trdstactive
};
logic [31:0] MMR_Trdstcontrol_muxed;
assign MMR_Trdstcontrol_muxed = {
    MMR_Trdstcontrol_F_Rsvd3127,
    MMR_Trdstcontrol_F_Trdstformat_Data_muxed,
    MMR_Trdstcontrol_F_Trdstsyncmax_Data_muxed,
    MMR_Trdstcontrol_F_Rsvd1918,
    MMR_Trdstcontrol_F_Trdstsyncmode_Data_muxed,
    MMR_Trdstcontrol_F_Trdstinhibitsrc,
    MMR_Trdstcontrol_F_Rsvd1414,
    MMR_Trdstcontrol_F_Trdstinststallena,
    MMR_Trdstcontrol_F_Trdstinststalloroverflow,
    MMR_Trdstcontrol_F_Trdstinsttriggerenable_Data_muxed,
    MMR_Trdstcontrol_F_Rsvd1010,
    MMR_Trdstcontrol_F_Trdstcontext,
    MMR_Trdstcontrol_F_Rsvd87,
    MMR_Trdstcontrol_F_Trdstinstmode,
    MMR_Trdstcontrol_F_Trdstempty_Data_muxed,
    MMR_Trdstcontrol_F_Trdstinsttracing_Data_muxed,
    MMR_Trdstcontrol_F_Trdstenable_Data_muxed,
    MMR_Trdstcontrol_F_Trdstactive_Data_muxed
};
assign MMR_Trdstimpl = {
    MMR_Trdstimpl_F_Trdsttimestampconfig,
    MMR_Trdstimpl_F_Trdstvendorstreamlength,
    MMR_Trdstimpl_F_Trdstvendorframelength,
    MMR_Trdstimpl_F_Trdstprotocolminor,
    MMR_Trdstimpl_F_Trdstprotocolmajor,
    MMR_Trdstimpl_F_Rsvd1512,
    MMR_Trdstimpl_F_Trdstcomptype,
    MMR_Trdstimpl_F_Trdstverminor,
    MMR_Trdstimpl_F_Trdstvermajor
};
logic [31:0] MMR_Trdstimpl_muxed;
assign MMR_Trdstimpl_muxed = {
    MMR_Trdstimpl_F_Trdsttimestampconfig_Data_muxed,
    MMR_Trdstimpl_F_Trdstvendorstreamlength_Data_muxed,
    MMR_Trdstimpl_F_Trdstvendorframelength_Data_muxed,
    MMR_Trdstimpl_F_Trdstprotocolminor,
    MMR_Trdstimpl_F_Trdstprotocolmajor,
    MMR_Trdstimpl_F_Rsvd1512,
    MMR_Trdstimpl_F_Trdstcomptype,
    MMR_Trdstimpl_F_Trdstverminor,
    MMR_Trdstimpl_F_Trdstvermajor
};
assign MMR_Trdstinstfeatures = {
    MMR_Trdstinstfeatures_F_Trdstsrcbits,
    MMR_Trdstinstfeatures_F_Trdstsrcid,
    MMR_Trdstinstfeatures_F_Rsvd159,
    MMR_Trdstinstfeatures_F_Trdstinstenrepeatedhistory,
    MMR_Trdstinstfeatures_F_Rsvd72,
    MMR_Trdstinstfeatures_F_Trdstinstnotrapaddr,
    MMR_Trdstinstfeatures_F_Trdstinstnoaddrdiff
};
logic [31:0] MMR_Trdstinstfeatures_muxed;
assign MMR_Trdstinstfeatures_muxed = {
    MMR_Trdstinstfeatures_F_Trdstsrcbits_Data_muxed,
    MMR_Trdstinstfeatures_F_Trdstsrcid_Data_muxed,
    MMR_Trdstinstfeatures_F_Rsvd159,
    MMR_Trdstinstfeatures_F_Trdstinstenrepeatedhistory,
    MMR_Trdstinstfeatures_F_Rsvd72,
    MMR_Trdstinstfeatures_F_Trdstinstnotrapaddr,
    MMR_Trdstinstfeatures_F_Trdstinstnoaddrdiff
};
assign MMR_CDbgDebugTraceCfg = {
    MMR_CDbgDebugTraceCfg_F_Rsvd3122,
    MMR_CDbgDebugTraceCfg_F_FrameClosureMode,
    MMR_CDbgDebugTraceCfg_F_FrameModeEnable,
    MMR_CDbgDebugTraceCfg_F_Rsvd1916,
    MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes,
    MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte,
    MMR_CDbgDebugTraceCfg_F_TraceSourceId
};
logic [31:0] MMR_CDbgDebugTraceCfg_muxed;
assign MMR_CDbgDebugTraceCfg_muxed = {
    MMR_CDbgDebugTraceCfg_F_Rsvd3122,
    MMR_CDbgDebugTraceCfg_F_FrameClosureMode_Data_muxed,
    MMR_CDbgDebugTraceCfg_F_FrameModeEnable_Data_muxed,
    MMR_CDbgDebugTraceCfg_F_Rsvd1916,
    MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes_Data_muxed,
    MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte_Data_muxed,
    MMR_CDbgDebugTraceCfg_F_TraceSourceId_Data_muxed
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
        ADDR_MMR_TRDSTCONTROL                   : begin : mmr_rd_hit_MMR_Trdstcontrol reg_prehit.DstMmrTrdstcontrolHit = 1'b1; reg_rd_data = {MMR_Trdstcontrol}; end
        ADDR_MMR_TRDSTIMPL                      : begin : mmr_rd_hit_MMR_Trdstimpl reg_prehit.DstMmrTrdstimplHit = 1'b1; reg_rd_data = {MMR_Trdstimpl}; end
        ADDR_MMR_TRDSTINSTFEATURES              : begin : mmr_rd_hit_MMR_Trdstinstfeatures reg_prehit.DstMmrTrdstinstfeaturesHit = 1'b1; reg_rd_data = {MMR_Trdstinstfeatures}; end
        ADDR_MMR_CDBGDEBUGTRACECFG              : begin : mmr_rd_hit_MMR_CDbgDebugTraceCfg reg_prehit.DstMmrCdbgdebugtracecfgHit = 1'b1; reg_rd_data = {MMR_CDbgDebugTraceCfg}; end
        ADDR_MMR_SCRATCHLO                      : begin : mmr_rd_hit_MMR_ScratchLo reg_prehit.DstMmrScratchloHit = 1'b1; reg_rd_data = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : mmr_rd_hit_MMR_ScratchHi reg_prehit.DstMmrScratchhiHit = 1'b1; reg_rd_data = {MMR_ScratchHi}; end
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
        ADDR_MMR_TRDSTCONTROL                   : begin : mmr_rd_d1_MMR_Trdstcontrol reg_rd_data_d1 = {MMR_Trdstcontrol}; end
        ADDR_MMR_TRDSTIMPL                      : begin : mmr_rd_d1_MMR_Trdstimpl reg_rd_data_d1 = {MMR_Trdstimpl}; end
        ADDR_MMR_TRDSTINSTFEATURES              : begin : mmr_rd_d1_MMR_Trdstinstfeatures reg_rd_data_d1 = {MMR_Trdstinstfeatures}; end
        ADDR_MMR_CDBGDEBUGTRACECFG              : begin : mmr_rd_d1_MMR_CDbgDebugTraceCfg reg_rd_data_d1 = {MMR_CDbgDebugTraceCfg}; end
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
        .WIDTH ($bits(logic [DST_NUM_REGISTERS-1:0])),
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

assign DstMmrTrdstcontrol.Rsvd3127              = MMR_Trdstcontrol_F_Rsvd3127;
assign DstMmrTrdstcontrol.Trdstformat           = MMR_Trdstcontrol_F_Trdstformat;
assign DstMmrTrdstcontrol.Trdstsyncmax          = MMR_Trdstcontrol_F_Trdstsyncmax;
assign DstMmrTrdstcontrol.Rsvd1918              = MMR_Trdstcontrol_F_Rsvd1918;
assign DstMmrTrdstcontrol.Trdstsyncmode         = MMR_Trdstcontrol_F_Trdstsyncmode;
assign DstMmrTrdstcontrol.Trdstinhibitsrc       = MMR_Trdstcontrol_F_Trdstinhibitsrc;
assign DstMmrTrdstcontrol.Rsvd1414              = MMR_Trdstcontrol_F_Rsvd1414;
assign DstMmrTrdstcontrol.Trdstinststallena     = MMR_Trdstcontrol_F_Trdstinststallena;
assign DstMmrTrdstcontrol.Trdstinststalloroverflow = MMR_Trdstcontrol_F_Trdstinststalloroverflow;
assign DstMmrTrdstcontrol.Trdstinsttriggerenable = MMR_Trdstcontrol_F_Trdstinsttriggerenable;
assign DstMmrTrdstcontrol.Rsvd1010              = MMR_Trdstcontrol_F_Rsvd1010;
assign DstMmrTrdstcontrol.Trdstcontext          = MMR_Trdstcontrol_F_Trdstcontext;
assign DstMmrTrdstcontrol.Rsvd87                = MMR_Trdstcontrol_F_Rsvd87;
assign DstMmrTrdstcontrol.Trdstinstmode         = MMR_Trdstcontrol_F_Trdstinstmode;
assign DstMmrTrdstcontrol.Trdstempty            = MMR_Trdstcontrol_F_Trdstempty;
assign DstMmrTrdstcontrol.Trdstinsttracing      = MMR_Trdstcontrol_F_Trdstinsttracing;
assign DstMmrTrdstcontrol.Trdstenable           = MMR_Trdstcontrol_F_Trdstenable;
assign DstMmrTrdstcontrol.Trdstactive           = MMR_Trdstcontrol_F_Trdstactive;
assign DstMmrTrdstimpl.Trdsttimestampconfig     = MMR_Trdstimpl_F_Trdsttimestampconfig;
assign DstMmrTrdstimpl.Trdstvendorstreamlength  = MMR_Trdstimpl_F_Trdstvendorstreamlength;
assign DstMmrTrdstimpl.Trdstvendorframelength   = MMR_Trdstimpl_F_Trdstvendorframelength;
assign DstMmrTrdstimpl.Trdstprotocolminor       = MMR_Trdstimpl_F_Trdstprotocolminor;
assign DstMmrTrdstimpl.Trdstprotocolmajor       = MMR_Trdstimpl_F_Trdstprotocolmajor;
assign DstMmrTrdstimpl.Rsvd1512                 = MMR_Trdstimpl_F_Rsvd1512;
assign DstMmrTrdstimpl.Trdstcomptype            = MMR_Trdstimpl_F_Trdstcomptype;
assign DstMmrTrdstimpl.Trdstverminor            = MMR_Trdstimpl_F_Trdstverminor;
assign DstMmrTrdstimpl.Trdstvermajor            = MMR_Trdstimpl_F_Trdstvermajor;
assign DstMmrTrdstinstfeatures.Trdstsrcbits     = MMR_Trdstinstfeatures_F_Trdstsrcbits;
assign DstMmrTrdstinstfeatures.Trdstsrcid       = MMR_Trdstinstfeatures_F_Trdstsrcid;
assign DstMmrTrdstinstfeatures.Rsvd159          = MMR_Trdstinstfeatures_F_Rsvd159;
assign DstMmrTrdstinstfeatures.Trdstinstenrepeatedhistory = MMR_Trdstinstfeatures_F_Trdstinstenrepeatedhistory;
assign DstMmrTrdstinstfeatures.Rsvd72           = MMR_Trdstinstfeatures_F_Rsvd72;
assign DstMmrTrdstinstfeatures.Trdstinstnotrapaddr = MMR_Trdstinstfeatures_F_Trdstinstnotrapaddr;
assign DstMmrTrdstinstfeatures.Trdstinstnoaddrdiff = MMR_Trdstinstfeatures_F_Trdstinstnoaddrdiff;
assign DstMmrCdbgdebugtracecfg.Rsvd3122         = MMR_CDbgDebugTraceCfg_F_Rsvd3122;
assign DstMmrCdbgdebugtracecfg.FrameClosureMode = MMR_CDbgDebugTraceCfg_F_FrameClosureMode;
assign DstMmrCdbgdebugtracecfg.FrameModeEnable  = MMR_CDbgDebugTraceCfg_F_FrameModeEnable;
assign DstMmrCdbgdebugtracecfg.Rsvd1916         = MMR_CDbgDebugTraceCfg_F_Rsvd1916;
assign DstMmrCdbgdebugtracecfg.FrameLenghtInBytes = MMR_CDbgDebugTraceCfg_F_FrameLenghtInBytes;
assign DstMmrCdbgdebugtracecfg.TraceFrameFillByte = MMR_CDbgDebugTraceCfg_F_TraceFrameFillByte;
assign DstMmrCdbgdebugtracecfg.TraceSourceId    = MMR_CDbgDebugTraceCfg_F_TraceSourceId;
assign DstMmrScratchlo.Data                     = MMR_ScratchLo_F_Data;
assign DstMmrScratchhi.Data                     = MMR_ScratchHi_F_Data;

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
        ADDR_MMR_TRDSTCONTROL                   : begin : get_reg_val_MMR_Trdstcontrol get_register_value = {MMR_Trdstcontrol}; end
        ADDR_MMR_TRDSTIMPL                      : begin : get_reg_val_MMR_Trdstimpl get_register_value = {MMR_Trdstimpl}; end
        ADDR_MMR_TRDSTINSTFEATURES              : begin : get_reg_val_MMR_Trdstinstfeatures get_register_value = {MMR_Trdstinstfeatures}; end
        ADDR_MMR_CDBGDEBUGTRACECFG              : begin : get_reg_val_MMR_CDbgDebugTraceCfg get_register_value = {MMR_CDbgDebugTraceCfg}; end
        ADDR_MMR_SCRATCHLO                      : begin : get_reg_val_MMR_ScratchLo get_register_value = {MMR_ScratchLo}; end
        ADDR_MMR_SCRATCHHI                      : begin : get_reg_val_MMR_ScratchHi get_register_value = {MMR_ScratchHi}; end
        default                                 : begin : get_reg_val_default get_register_value = 'x; end
    endcase
  end
endfunction

endmodule
