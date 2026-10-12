// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`include "axi/typedef.svh"

module mmrs
import cla_mmr_pkg::*;
import ntr_sink_mmr_pkg::*;
import dst_sink_mmr_pkg::*;
import funnel_mmr_pkg::*;

import ntr_mmr_pkg::*;
import dst_mmr_pkg::*;
import cla_pkg::ClaMmrsWrMinimal_s;

#(

    parameter int unsigned NUM_CLA_INST = 8,
    parameter int unsigned NUM_DST_INST = 8,
    parameter int unsigned NUM_NTRACE_INST = 8,
    parameter DEBUG_SIGNAL_WIDTH = 64,

    parameter bit TRACE_SINK_SUPPORT = 1,
    parameter bit NTRACE_SUPPORT = 1,
    parameter bit DST_SUPPORT = 1,

    parameter MMR_ADDR_WIDTH = 17,
    parameter MMR_DATA_WIDTH = 32,

    parameter MMR_AXI_ID_WIDTH = 4,
    parameter MMR_AXI_USER_WIDTH = 8,
    localparam MMR_PSTRB_WIDTH = MMR_DATA_WIDTH / 8,

    parameter MMR_BASE_ADDRESS = (MMR_ADDR_WIDTH)'('h0),

    parameter TRC_SIZE_IN_KB = 32,
    localparam TRC_SIZE = TRC_SIZE_IN_KB * 1024 * 8,

    parameter bit USE_AXI_INTF = 0,

    localparam bit CLA_EN = (NUM_CLA_INST    > 0),
    localparam bit DST_EN = (NUM_DST_INST    > 0),
    localparam bit NTR_EN = (NUM_NTRACE_INST > 0),

    localparam bit DST_SINK_EN = TRACE_SINK_SUPPORT && DST_SUPPORT,
    localparam bit NTR_SINK_EN = TRACE_SINK_SUPPORT && NTRACE_SUPPORT,

    localparam int unsigned NUM_CLA_INST_SAFE    = (NUM_CLA_INST    > 0) ? NUM_CLA_INST    : 32'd1,
    localparam int unsigned NUM_DST_INST_SAFE    = (NUM_DST_INST    > 0) ? NUM_DST_INST    : 32'd1,
    localparam int unsigned NUM_NTRACE_INST_SAFE = (NUM_NTRACE_INST > 0) ? NUM_NTRACE_INST : 32'd1,

    /* verilator lint_off WIDTHEXPAND */
    localparam NUM_MMR_BLOCKS = (TRACE_SINK_SUPPORT ? (unsigned'(DST_SINK_EN) + unsigned'(NTR_SINK_EN) + 32'd1) : 32'd0) + unsigned'(NUM_CLA_INST) + unsigned'(NUM_DST_INST) + unsigned'(NUM_NTRACE_INST)
    /* verilator lint_on WIDTHEXPAND */

) (
    input logic        i_clk,
    input logic        i_rst_n,
    input logic        i_critical_signal_hold,

    input logic        TraceRamWrEn,

    output logic [NUM_CLA_INST_SAFE-1:0] cla_func_enable,
    output logic [NUM_DST_INST_SAFE-1:0] dst_func_enable,
    output logic [NUM_NTRACE_INST_SAFE-1:0] ntr_func_enable,
    output logic dst_sink_func_enable,
    output logic ntr_sink_func_enable,
    output logic funnel_func_enable,

    // verilint W240 off

    output ClaMmrs_s [NUM_CLA_INST_SAFE-1:0] ClaMmrs,
    output DstMmrs_s [NUM_DST_INST_SAFE-1:0] DstMmrs,
    output NtrMmrs_s [NUM_NTRACE_INST_SAFE-1:0] NtrMmrs,
    output NtrSinkMmrs_s NtrSinkMmrs,
    output DstSinkMmrs_s DstSinkMmrs,
    output FunnelMmrs_s FunnelMmrs,

    input ClaMmrsWrMinimal_s [NUM_CLA_INST_SAFE-1:0] ClaMmrsWr,
    input DstMmrsWr_s [NUM_DST_INST_SAFE-1:0] DstMmrsWr,
    input NtrMmrsWr_s [NUM_NTRACE_INST_SAFE-1:0] NtrMmrsWr,
    input NtrSinkMmrsWr_s NtrSinkMmrsWr,
    input DstSinkMmrsWr_s DstSinkMmrsWr,
    input FunnelMmrsWr_s FunnelMmrsWr,

    output logic                                            trRamDataRdEn,
    output logic                                            trdstRamDataRdEn,

    input  logic                                            i_jtag_mmr_req_vld,
    input  logic                                            i_jtag_mmr_req_we,
    input  logic [MMR_ADDR_WIDTH-1:0]                       i_jtag_mmr_req_addr,
    input  logic [MMR_DATA_WIDTH-1:0]                       i_jtag_mmr_req_data,
    output logic [MMR_DATA_WIDTH-1:0]                       o_jtag_mmr_rsp_data,
    output logic                                            o_jtag_mmr_rsp_vld,

    input  logic [MMR_ADDR_WIDTH-1:0]       paddr,
    input  logic                            psel,
    input  logic                            penable,
    input  logic [MMR_PSTRB_WIDTH-1:0]      pstrb,
    input  logic                            pwrite,
    input  logic [MMR_DATA_WIDTH-1:0]       pwdata,
    output logic                            pready,
    output logic [MMR_DATA_WIDTH-1:0]       prdata,
    output logic                            pslverr,

    input  logic [MMR_AXI_ID_WIDTH-1:0]         s_mmr_axi_awid,
    input  logic [MMR_ADDR_WIDTH-1:0]           s_mmr_axi_awaddr,
    input  logic [7:0]                      s_mmr_axi_awlen,
    input  logic [2:0]                      s_mmr_axi_awsize,
    input  logic [1:0]                      s_mmr_axi_awburst,
    input  logic                            s_mmr_axi_awlock,
    input  logic [3:0]                      s_mmr_axi_awcache,
    input  logic [2:0]                      s_mmr_axi_awprot,
    input  logic [3:0]                      s_mmr_axi_awqos,
    input  logic [3:0]                      s_mmr_axi_awregion,
    input  logic [5:0]                      s_mmr_axi_awatop,
    input  logic [MMR_AXI_USER_WIDTH-1:0]       s_mmr_axi_awuser,
    input  logic                            s_mmr_axi_awvalid,
    output logic                            s_mmr_axi_awready,

    input  logic [MMR_DATA_WIDTH-1:0]           s_mmr_axi_wdata,
    input  logic [(MMR_DATA_WIDTH/8)-1:0]       s_mmr_axi_wstrb,
    input  logic                            s_mmr_axi_wlast,
    input  logic [MMR_AXI_USER_WIDTH-1:0]       s_mmr_axi_wuser,
    input  logic                            s_mmr_axi_wvalid,
    output logic                            s_mmr_axi_wready,

    output logic [MMR_AXI_ID_WIDTH-1:0]         s_mmr_axi_bid,
    output logic [1:0]                      s_mmr_axi_bresp,
    output logic [MMR_AXI_USER_WIDTH-1:0]       s_mmr_axi_buser,
    output logic                            s_mmr_axi_bvalid,
    input  logic                            s_mmr_axi_bready,

    input  logic [MMR_AXI_ID_WIDTH-1:0]         s_mmr_axi_arid,
    input  logic [MMR_ADDR_WIDTH-1:0]           s_mmr_axi_araddr,
    input  logic [7:0]                      s_mmr_axi_arlen,
    input  logic [2:0]                      s_mmr_axi_arsize,
    input  logic [1:0]                      s_mmr_axi_arburst,
    input  logic                            s_mmr_axi_arlock,
    input  logic [3:0]                      s_mmr_axi_arcache,
    input  logic [2:0]                      s_mmr_axi_arprot,
    input  logic [3:0]                      s_mmr_axi_arqos,
    input  logic [3:0]                      s_mmr_axi_arregion,
    input  logic [MMR_AXI_USER_WIDTH-1:0]       s_mmr_axi_aruser,
    input  logic                            s_mmr_axi_arvalid,
    output logic                            s_mmr_axi_arready,

    output logic [MMR_AXI_ID_WIDTH-1:0]         s_mmr_axi_rid,
    output logic [MMR_DATA_WIDTH-1:0]           s_mmr_axi_rdata,
    output logic [1:0]                      s_mmr_axi_rresp,
    output logic                            s_mmr_axi_rlast,
    output logic [MMR_AXI_USER_WIDTH-1:0]       s_mmr_axi_ruser,
    output logic                            s_mmr_axi_rvalid,
    input  logic                            s_mmr_axi_rready

);

    localparam int unsigned DST_SINK_BLK_IDX = 0;
    localparam int unsigned NTR_SINK_BLK_IDX = TRACE_SINK_SUPPORT ? 32'(DST_SINK_EN)                         : 0;
    localparam int unsigned FUNNEL_BLK_IDX   = TRACE_SINK_SUPPORT ? 32'(DST_SINK_EN) + 32'(NTR_SINK_EN)     : 0;
    localparam int unsigned CLA_START_IDX    = TRACE_SINK_SUPPORT ? 32'(DST_SINK_EN) + 32'(NTR_SINK_EN) + 1 : 0;
    localparam int unsigned DST_START_IDX = CLA_START_IDX + NUM_CLA_INST;
    localparam int unsigned NTR_START_IDX = DST_START_IDX + NUM_DST_INST;

    typedef logic [MMR_ADDR_WIDTH-1:0]       s_mmr_axi_addr_t;
    typedef logic [MMR_DATA_WIDTH-1:0]       s_mmr_axi_data_t;
    typedef logic [(MMR_DATA_WIDTH/8)-1:0]   s_mmr_axi_strb_t;
    typedef logic [MMR_AXI_USER_WIDTH-1:0]   s_mmr_axi_user_t;
    typedef logic [MMR_AXI_ID_WIDTH-1:0]     s_mmr_axi_id_t;
    `AXI_TYPEDEF_ALL_CT(s_mmr_axi, s_mmr_axi_req_t, s_mmr_axi_rsp_t, s_mmr_axi_addr_t, s_mmr_axi_id_t, s_mmr_axi_data_t, s_mmr_axi_strb_t, s_mmr_axi_user_t)

    typedef struct packed {
        int unsigned idx;
        logic [MMR_ADDR_WIDTH-1:0] start_addr;
        logic [MMR_ADDR_WIDTH-1:0] end_addr;
    } mmr_rule_t;

    localparam [MMR_ADDR_WIDTH-1:0] MMR_END_ADDR = (MMR_ADDR_WIDTH)'(MMR_BASE_ADDRESS) + ((MMR_ADDR_WIDTH)'(NUM_MMR_BLOCKS) << 12);

    localparam mmr_rule_t mmr_slv_map = '{idx: 0, start_addr: MMR_BASE_ADDRESS, end_addr: MMR_END_ADDR};

    localparam axi_pkg::xbar_cfg_t mmr_cfg = '{
        NoSlvPorts:         1,
        NoMstPorts:         1,
        MaxMstTrans:        1,
        MaxSlvTrans:        1,
        FallThrough:        1'b0,
        LatencyMode:        axi_pkg::CUT_SLV_PORTS,
        AxiIdWidthSlvPorts: MMR_AXI_ID_WIDTH,
        AxiIdUsedSlvPorts:  1,
        UniqueIds:          1'b0,
        AxiAddrWidth:       MMR_ADDR_WIDTH,
        AxiDataWidth:       MMR_DATA_WIDTH,
        NoAddrRules:        1,
        default:            '0
    };

    s_mmr_axi_req_t s_mmr_axi_req, xbar_req;
    s_mmr_axi_rsp_t s_mmr_axi_rsp, xbar_rsp;

    logic [NUM_CLA_INST_SAFE-1:0] cla_reset_n_warm_ovrride, cla_reset_n_warm_ovrride_hi;
    logic [NUM_DST_INST_SAFE-1:0] dst_reset_n_warm_ovrride;
    logic [NUM_NTRACE_INST_SAFE-1:0] ntr_reset_n_warm_ovrride;
    logic dst_sink_reset_n_warm_ovrride;
    logic ntr_sink_reset_n_warm_ovrride;
    logic funnel_reset_n_warm_ovrride;

    assign cla_reset_n_warm_ovrride = ({NUM_CLA_INST_SAFE{i_critical_signal_hold}} | {NUM_CLA_INST_SAFE{i_rst_n}});
    assign cla_reset_n_warm_ovrride_hi = (DEBUG_SIGNAL_WIDTH == 64) ? '0 : cla_reset_n_warm_ovrride;
    assign dst_reset_n_warm_ovrride = ({NUM_DST_INST_SAFE{i_critical_signal_hold}} | {NUM_DST_INST_SAFE{i_rst_n}});
    assign ntr_reset_n_warm_ovrride = ({NUM_NTRACE_INST_SAFE{i_critical_signal_hold}} | {NUM_NTRACE_INST_SAFE{i_rst_n}});
    assign dst_sink_reset_n_warm_ovrride = i_critical_signal_hold | i_rst_n;
    assign ntr_sink_reset_n_warm_ovrride = i_critical_signal_hold | i_rst_n;
    assign funnel_reset_n_warm_ovrride = i_critical_signal_hold | i_rst_n;

    always_comb begin
        s_mmr_axi_req           = '0;
        s_mmr_axi_req.aw.id     = s_mmr_axi_awid;
        s_mmr_axi_req.aw.addr   = s_mmr_axi_awaddr;
        s_mmr_axi_req.aw.len    = s_mmr_axi_awlen;
        s_mmr_axi_req.aw.size   = s_mmr_axi_awsize;
        s_mmr_axi_req.aw.burst  = s_mmr_axi_awburst;
        s_mmr_axi_req.aw.lock   = s_mmr_axi_awlock;
        s_mmr_axi_req.aw.cache  = s_mmr_axi_awcache;
        s_mmr_axi_req.aw.prot   = s_mmr_axi_awprot;
        s_mmr_axi_req.aw.qos    = s_mmr_axi_awqos;
        s_mmr_axi_req.aw.region = s_mmr_axi_awregion;
        s_mmr_axi_req.aw.atop   = s_mmr_axi_awatop;
        s_mmr_axi_req.aw.user   = s_mmr_axi_awuser;
        s_mmr_axi_req.aw_valid  = s_mmr_axi_awvalid;
        s_mmr_axi_req.w.data    = s_mmr_axi_wdata;
        s_mmr_axi_req.w.strb    = s_mmr_axi_wstrb;
        s_mmr_axi_req.w.last    = s_mmr_axi_wlast;
        s_mmr_axi_req.w.user    = s_mmr_axi_wuser;
        s_mmr_axi_req.w_valid   = s_mmr_axi_wvalid;
        s_mmr_axi_req.b_ready   = s_mmr_axi_bready;
        s_mmr_axi_req.ar.id     = s_mmr_axi_arid;
        s_mmr_axi_req.ar.addr   = s_mmr_axi_araddr;
        s_mmr_axi_req.ar.len    = s_mmr_axi_arlen;
        s_mmr_axi_req.ar.size   = s_mmr_axi_arsize;
        s_mmr_axi_req.ar.burst  = s_mmr_axi_arburst;
        s_mmr_axi_req.ar.lock   = s_mmr_axi_arlock;
        s_mmr_axi_req.ar.cache  = s_mmr_axi_arcache;
        s_mmr_axi_req.ar.prot   = s_mmr_axi_arprot;
        s_mmr_axi_req.ar.qos    = s_mmr_axi_arqos;
        s_mmr_axi_req.ar.region = s_mmr_axi_arregion;
        s_mmr_axi_req.ar.user   = s_mmr_axi_aruser;
        s_mmr_axi_req.ar_valid  = s_mmr_axi_arvalid;
        s_mmr_axi_req.r_ready   = s_mmr_axi_rready;
    end

    assign s_mmr_axi_awready = s_mmr_axi_rsp.aw_ready;
    assign s_mmr_axi_wready  = s_mmr_axi_rsp.w_ready;
    assign s_mmr_axi_bid     = s_mmr_axi_rsp.b.id;
    assign s_mmr_axi_bresp   = s_mmr_axi_rsp.b.resp;
    assign s_mmr_axi_buser   = s_mmr_axi_rsp.b.user;
    assign s_mmr_axi_bvalid  = s_mmr_axi_rsp.b_valid;
    assign s_mmr_axi_arready = s_mmr_axi_rsp.ar_ready;
    assign s_mmr_axi_rid     = s_mmr_axi_rsp.r.id;
    assign s_mmr_axi_rdata   = s_mmr_axi_rsp.r.data;
    assign s_mmr_axi_rresp   = s_mmr_axi_rsp.r.resp;
    assign s_mmr_axi_rlast   = s_mmr_axi_rsp.r.last;
    assign s_mmr_axi_ruser   = s_mmr_axi_rsp.r.user;
    assign s_mmr_axi_rvalid  = s_mmr_axi_rsp.r_valid;

    logic                [NUM_MMR_BLOCKS-1:0] mmr_blk_sel;

    logic          [MMR_ADDR_WIDTH-1:0] cs_decode_addr;

    logic                               conv_MmrReqVld;
    logic          [MMR_ADDR_WIDTH-1:0] conv_MmrAddr_full;
    localparam int unsigned NUM_MMR_BLOCKS_ALIGNED = 2**$clog2(NUM_MMR_BLOCKS);
    logic                         			  conv_MmrWrEn, MmrWrEn;
    logic 							  [2-1:0] conv_MmrWrStrb, MmrWrStrb;
    logic 							  [2-1:0] MmrWrStrb8B;
    logic                         			  MmrRegSel;
    logic        		  			  [2-1:0] MmrWrInstrType;
    logic            [12-1:0] conv_MmrAddr, MmrAddr;
    logic            [12-1:0] MmrAddr8B;
    logic            [MMR_DATA_WIDTH-1:0] conv_MmrWrData, MmrWrData;
    logic                            [64-1:0] MmrWrData8B;

    logic                 			          MmrHit;
    logic            [MMR_DATA_WIDTH-1:0] MmrRdData;
    logic            [MMR_DATA_WIDTH-1:0] rsp_data;

    logic                [NUM_MMR_BLOCKS-1:0] MmrCs;
    logic                                     bus_req_rdy;
    logic                                     rsp_vld, rsp_err;

    logic                          [NUM_DST_INST_SAFE-1:0] MmrHit_DST;
    logic  [NUM_DST_INST_SAFE-1:0][MMR_DATA_WIDTH-1:0] MmrRdData_DST;

    logic                          [NUM_NTRACE_INST_SAFE-1:0] MmrHit_NTR;
    logic  [NUM_NTRACE_INST_SAFE-1:0][MMR_DATA_WIDTH-1:0] MmrRdData_NTR;

    logic                          [NUM_CLA_INST_SAFE-1:0] MmrHit_CLA;
    logic  [NUM_CLA_INST_SAFE-1:0][MMR_DATA_WIDTH-1:0] MmrRdData_CLA;
    logic                  [NUM_CLA_INST_SAFE-1:0][64-1:0] MmrRdData8B_CLA;

    logic                                    MmrHit_NTR_SINK;
    logic           [MMR_DATA_WIDTH-1:0] MmrRdData_NTR_SINK;

    logic                                    MmrHit_DST_SINK;
    logic           [MMR_DATA_WIDTH-1:0] MmrRdData_DST_SINK;

    logic                                    MmrHit_FUNNEL;
    logic           [MMR_DATA_WIDTH-1:0] MmrRdData_FUNNEL;

    assign MmrAddr8B   = {MmrAddr[12-1:3], 3'b000};
    assign MmrWrData8B = {(64/MMR_DATA_WIDTH){MmrWrData}};
    assign MmrWrStrb8B = (MmrAddr[2] == 1'b0) ? {1'b0, MmrWrStrb[0]} : {MmrWrStrb[0], 1'b0};
    assign MmrWrInstrType = '0;

    logic [NUM_MMR_BLOCKS-1:0] jt_blk_sel;

    always_comb begin
        jt_blk_sel = '0;
        if (i_jtag_mmr_req_vld) begin
            jt_blk_sel = (NUM_MMR_BLOCKS)'(1) << (i_jtag_mmr_req_addr[MMR_ADDR_WIDTH-1:12] - MMR_BASE_ADDRESS[MMR_ADDR_WIDTH-1:12]);
        end
    end

    assign rsp_data            = (|MmrHit) ? MmrRdData : '0;
    assign o_jtag_mmr_rsp_data = rsp_data;

    mmr_req_ctrl #(
        .NUM_MMR_BLOCKS     (NUM_MMR_BLOCKS),
        .MMR_PIPE_LAT       (2),
        .NTR_SINK_EN        (NTR_SINK_EN),
        .DST_SINK_EN        (DST_SINK_EN),
        .NTR_SINK_BLK_IDX   (NTR_SINK_BLK_IDX),
        .DST_SINK_BLK_IDX   (DST_SINK_BLK_IDX),
        .NTR_RAMDATA_OFFSET (12'(NTR_SINK_TRRAMDATA_REG_ADDR)),
        .DST_RAMDATA_OFFSET (12'(DST_SINK_TRDSTRAMDATA_REG_ADDR))
    ) u_mmr_req_ctrl (
        .clk             (i_clk),
        .reset_n         (i_rst_n),

        .bus_req_vld     (conv_MmrReqVld),
        .bus_req_we      (conv_MmrWrEn),
        .bus_req_blk_sel (mmr_blk_sel),
        .bus_req_addr    (conv_MmrAddr),
        .bus_req_data    (conv_MmrWrData),
        .bus_req_strb    (conv_MmrWrStrb),
        .bus_req_err     (1'b0),
        .bus_req_rdy     (bus_req_rdy),

        .jt_req_vld      (i_jtag_mmr_req_vld),
        .jt_req_we       (i_jtag_mmr_req_we),
        .jt_req_blk_sel  (jt_blk_sel),
        .jt_req_addr     (i_jtag_mmr_req_addr[12-1:0]),
        .jt_req_data     (i_jtag_mmr_req_data),
        .jt_rsp_vld      (o_jtag_mmr_rsp_vld),

        .TraceRamWrEn    (TraceRamWrEn),
        .ram_rd_en_ntr   (trRamDataRdEn),
        .ram_rd_en_dst   (trdstRamDataRdEn),

        .MmrCs           (MmrCs),
        .MmrWrEn         (MmrWrEn),
        .MmrRegSel       (MmrRegSel),
        .MmrWrStrb       (MmrWrStrb),
        .MmrAddr         (MmrAddr),
        .MmrWrData       (MmrWrData),

        .rsp_vld         (rsp_vld),
        .rsp_err         (rsp_err)
    );

    localparam MAX_RAM_SIZE = TRC_SIZE >> 3;
    localparam MIN_RAM_SIZE = 32'h0;
    localparam MAX_RAM_STARTLOW = MAX_RAM_SIZE - MIN_RAM_SIZE;

    logic         Trntrissrammode;
    logic         Trramstartlow_Warl_Check_ANY, Trramlimitlow_Warl_Check_ANY;
    logic         Trramstarthigh_Warl_Check_ANY, Trramlimithigh_Warl_Check_ANY;
    logic         Warl_Updated_WrEn_ANY;
    logic [31:0]  Trramstartlow_Warl_Data_ANY, Trramlimitlow_Warl_Data_ANY, Warl_Updated_Data_ANY, Warl_Muxed_MmrWrData;

    assign Trntrissrammode = ~NtrSinkMmrs.Trramcontrol.Trrammode;
    assign Trramstartlow_Warl_Check_ANY = (MmrAddr == NTR_SINK_TRRAMSTARTLOW_REG_ADDR) & MmrCs[NTR_SINK_BLK_IDX];
    assign Trramlimitlow_Warl_Check_ANY = (MmrAddr == NTR_SINK_TRRAMLIMITLOW_REG_ADDR) & MmrCs[NTR_SINK_BLK_IDX];

    assign Trramstarthigh_Warl_Check_ANY = (MmrAddr == NTR_SINK_TRRAMSTARTHIGH_REG_ADDR) & MmrCs[NTR_SINK_BLK_IDX];
    assign Trramlimithigh_Warl_Check_ANY = (MmrAddr == NTR_SINK_TRRAMLIMITHIGH_REG_ADDR) & MmrCs[NTR_SINK_BLK_IDX];

    assign Trramstartlow_Warl_Data_ANY = (MmrWrData > MAX_RAM_STARTLOW)?MAX_RAM_STARTLOW:MmrWrData;
    assign Trramlimitlow_Warl_Data_ANY = (MmrWrData > MAX_RAM_SIZE)?MAX_RAM_SIZE:MmrWrData;

    assign Warl_Updated_WrEn_ANY = ((Trramstarthigh_Warl_Check_ANY | Trramlimithigh_Warl_Check_ANY) & MmrWrEn & Trntrissrammode)?1'b0:MmrWrEn;

    assign Warl_Updated_Data_ANY = Trramstartlow_Warl_Check_ANY?Trramstartlow_Warl_Data_ANY:Trramlimitlow_Warl_Data_ANY;
    assign Warl_Muxed_MmrWrData = ((Trramstartlow_Warl_Check_ANY | Trramlimitlow_Warl_Check_ANY) & MmrWrEn & Trntrissrammode)?Warl_Updated_Data_ANY:MmrWrData;

    assign MmrHit = |{MmrHit_CLA, MmrHit_DST, MmrHit_NTR, MmrHit_NTR_SINK, MmrHit_DST_SINK, MmrHit_FUNNEL};

		generic_decoded_mux #(
			.DISABLE_ASSERTIONS(0),
			.VALUE_WIDTH(MMR_DATA_WIDTH),
			.MUX_WIDTH(3 + NUM_CLA_INST_SAFE + NUM_DST_INST_SAFE + NUM_NTRACE_INST_SAFE)
		) u_csrrddata_mux (
			.clk      (i_clk),
			.rst_n  (i_rst_n),
			.en   (MmrHit),
			.in   ({MmrRdData_CLA,MmrRdData_DST,MmrRdData_NTR, MmrRdData_NTR_SINK, MmrRdData_DST_SINK, MmrRdData_FUNNEL}),
			.sel   ({MmrHit_CLA, MmrHit_DST, MmrHit_NTR, MmrHit_NTR_SINK, MmrHit_DST_SINK, MmrHit_FUNNEL}),
			.out   (MmrRdData)
		);

    always_comb begin
        mmr_blk_sel = '0;
        if (conv_MmrReqVld)
            mmr_blk_sel = NUM_MMR_BLOCKS'((NUM_MMR_BLOCKS_ALIGNED)'(1)
                       << (cs_decode_addr[MMR_ADDR_WIDTH-1:12]
                           - MMR_BASE_ADDRESS[MMR_ADDR_WIDTH-1:12]));
    end

    if (!USE_AXI_INTF) begin : gen_apb_inf_blk

        assign cs_decode_addr = MMR_ADDR_WIDTH'(paddr);

        assign s_mmr_axi_rsp = '0;

        apb2mmr #(
            .ADDR_WIDTH(MMR_ADDR_WIDTH),
            .BASE_ADDR(MMR_BASE_ADDRESS),
            .DATA_WIDTH(MMR_DATA_WIDTH),
            .NUM_MMR_BLOCKS(NUM_MMR_BLOCKS)
        ) u_apb2mmr (
            .clk        (i_clk),
            .reset_n    (i_rst_n),
            .paddr      (paddr),
            .psel       (psel),
            .penable    (penable),
            .pstrb      (pstrb),
            .pwrite     (pwrite),
            .pwdata     (pwdata),
            .pready     (pready),
            .prdata     (prdata),
            .pslverr    (pslverr),
            .MmrCs      (conv_MmrReqVld),
            .MmrWrEn    (conv_MmrWrEn),
            .MmrWrStrb  (conv_MmrWrStrb),
            .MmrAddr    (conv_MmrAddr),
            .MmrWrData  (conv_MmrWrData),
            .MmrRdData  (rsp_data),
            .rsp_vld    (rsp_vld),
            .rsp_err    (rsp_err)
        );
    end else begin : gen_axi_intf_blk

        logic [NUM_MMR_BLOCKS-1:0] [MMR_ADDR_WIDTH-1:0] mmr_block_start_addr, mmr_block_addr_mask;

        s_mmr_axi_req_t norm_axi_req;
        s_mmr_axi_rsp_t norm_axi_rsp;

        assign norm_axi_req  = s_mmr_axi_req;
        assign s_mmr_axi_rsp = norm_axi_rsp;

        for (genvar i = 0; i < NUM_MMR_BLOCKS; i++) begin : gen_mmr_block_start_addr
            assign mmr_block_start_addr[i] = MMR_BASE_ADDRESS + MMR_ADDR_WIDTH'(i << 12);
            assign mmr_block_addr_mask[i] = {{(MMR_ADDR_WIDTH-12){1'b1}}, 12'h0};
        end

        assign pready  = 1'b0;
        assign prdata  = '0;
        assign pslverr = 1'b0;

        assign cs_decode_addr = conv_MmrAddr_full;
        assign conv_MmrAddr   = conv_MmrAddr_full[12-1:0];

        axi_xbar #(
            .Cfg          (mmr_cfg),
            .ATOPs        (1'b0),
            .slv_aw_chan_t(s_mmr_axi_aw_chan_t),
            .mst_aw_chan_t(s_mmr_axi_aw_chan_t),
            .w_chan_t     (s_mmr_axi_w_chan_t),
            .slv_b_chan_t (s_mmr_axi_b_chan_t),
            .mst_b_chan_t (s_mmr_axi_b_chan_t),
            .slv_ar_chan_t(s_mmr_axi_ar_chan_t),
            .mst_ar_chan_t(s_mmr_axi_ar_chan_t),
            .slv_r_chan_t (s_mmr_axi_r_chan_t),
            .mst_r_chan_t (s_mmr_axi_r_chan_t),
            .slv_req_t    (s_mmr_axi_req_t),
            .mst_req_t    (s_mmr_axi_req_t),
            .slv_resp_t   (s_mmr_axi_rsp_t),
            .mst_resp_t   (s_mmr_axi_rsp_t),
            .rule_t       (mmr_rule_t)
        ) u_mmr_xbar (
            .clk_i                (i_clk),
            .rst_ni               (i_rst_n),
            .test_i               (1'b0),
            .slv_ports_req_i      (norm_axi_req),
            .slv_ports_resp_o     (norm_axi_rsp),
            .mst_ports_req_o      (xbar_req),
            .mst_ports_resp_i     (xbar_rsp),
            .addr_map_i           (mmr_slv_map),

            .en_default_mst_port_i('0),
            .default_mst_port_i   ('0)
        );

        generic_axilitetommr #(
            .axi_req_t      (s_mmr_axi_req_t),
            .axi_rsp_t      (s_mmr_axi_rsp_t),
            .AXI_ID_WIDTH   (MMR_AXI_ID_WIDTH),

            .PART_4B_WREN   (0),
            .CPL_SRCID_WIDTH(1),
            .CPL_SRCID      (1'b0),
            .SRCID_CHKEN    (0),
            .AXI_ADDR_WIDTH (MMR_ADDR_WIDTH),
            .AXI_DATA_WIDTH (MMR_DATA_WIDTH),
            .NUM_SRCID_ENTRY (1),
            .NUM_FUSE_ADDR_FILTERS (NUM_MMR_BLOCKS),
            .FUSE_CHKEN     (1)
        ) u_axitommr (
            .clk                                      (i_clk),
            .reset_n                                  (i_rst_n),
            .axi_req_i                                (xbar_req),
            .axi_rsp_o                                (xbar_rsp),

            .o_req_vld                                (conv_MmrReqVld),
            .i_req_rdy                                (bus_req_rdy),
            .i_wr_rsp_stall                           (1'b0),
            .o_wr_init_req                            (),
            .o_we                                     (conv_MmrWrEn),
            .o_wrstobe                                (conv_MmrWrStrb),
            .o_wrbyteen                               (),
            .o_addr                                   (conv_MmrAddr_full),
            .o_data                                   (conv_MmrWrData),
            .i_data                                   (rsp_data),
            .i_data_valid                             (rsp_vld),
            .o_busy                                   (),
            .state_dbg_o                              (),

            .FilStartAddr                             ('0),
            .FilAddrMask                              ('0),
            .FuseFilStartAddr                         (mmr_block_start_addr),
            .FuseFilAddrMask                          (mmr_block_addr_mask),
            .FuseBlockDisable                         ('0)
        );

    end

    if (NUM_NTRACE_INST > 0) begin : ntr_csr_gen_blk
        for (genvar ii = 0; ii < NUM_NTRACE_INST; ii++) begin : ntr_csr_inst
                localparam int unsigned BLK_IDX = NTR_START_IDX + ii;

                assign ntr_func_enable[ii] = NtrMmrs[ii].Trtecontrol.Trteactive;

                ntr_mmr #(

                ) u_ntr_mmr (
                    .clk                        (i_clk),
                    .reset_n                    (i_rst_n),
                    /* verilator lint_off WIDTHEXPAND */
                    .MmrCs                      (MmrCs[BLK_IDX]),
                    /* verilator lint_on WIDTHEXPAND */
                    .MmrWrEn                    (MmrWrEn),
                    .MmrWrStrb                  (MmrWrStrb),
                    .MmrRegSel                  (MmrRegSel),
                    .MmrAddr                    (MmrAddr),
                    .MmrWrData                  (MmrWrData),
                    .MmrWrInstrType             (MmrWrInstrType),
                    .MmrWrReady                 (),
                    .MmrHit                     (MmrHit_NTR[ii]),
                    .MmrHitList                 (),
                    .MmrRdData                  (MmrRdData_NTR[ii]),
                    .NtrMmrTrtecontrol			(NtrMmrs[ii].Trtecontrol),
                    .NtrMmrTrtscontrol         (NtrMmrs[ii].Trtscontrol),
                    .NtrMmrTrteimpl			(NtrMmrs[ii].Trteimpl),
                    .NtrMmrTrteinstfeatures	(NtrMmrs[ii].Trteinstfeatures),
                    .NtrMmrTrteinstfilters		(NtrMmrs[ii].Trteinstfilters),
                    .NtrMmrTrtefilter0Control	(NtrMmrs[ii].Trtefilter0Control),
                    .NtrMmrTrtefilter0Matchinst(NtrMmrs[ii].Trtefilter0Matchinst),
                    .NtrMmrCdbgntraceframecfg	(NtrMmrs[ii].Cdbgntraceframecfg),
                    .NtrMmrScratchlo			(NtrMmrs[ii].Scratchlo),
                    .NtrMmrScratchhi			(NtrMmrs[ii].Scratchhi),
                    .NtrMmrTrtecontrolWr		(NtrMmrsWr[ii].TrtecontrolWr),
                    .MmrUpdateEn                (),
                    .MmrUpdateAddr              (),
                    .MmrUpdateData              (),
                    .MmrUpdateIndirAddr         ()
                );
        end
    end else begin : no_ntr_csr_gen_blk
        assign ntr_func_enable = '0;
        assign NtrMmrs = '0;
        assign MmrHit_NTR = '0;
        assign MmrRdData_NTR = '0;

    end
    if (NTR_SINK_EN) begin : ntr_sink_csr_gen_blk

        assign ntr_sink_func_enable = NtrSinkMmrs.Trramcontrol.Trramactive;

        ntr_sink_mmr #(

            .MMR_TRCUSTOMRAMSMEMLIMITLOW_F_TRCUSTOMRAMSMEMLIMITLOW_RESET_VALUE(TRC_SIZE >> 6)
        ) u_ntr_sink_mmr (
            .clk                        (i_clk),
            .reset_n                    (i_rst_n),
            .MmrCs                      (MmrCs[NTR_SINK_BLK_IDX]),
            .MmrWrEn                    (MmrWrEn),
            .MmrWrStrb                  (MmrWrStrb),
            .MmrRegSel                  (MmrRegSel),
            .MmrAddr                    (MmrAddr),
            .MmrWrData                  (MmrWrData),
            .MmrWrInstrType             (MmrWrInstrType),
            .MmrWrReady                 (),
            .MmrHit                     (MmrHit_NTR_SINK),
            .MmrRdData                  (MmrRdData_NTR_SINK),
            .MmrHitList                 (),
            .MmrUpdateEn                (),
            .MmrUpdateAddr              (),
            .MmrUpdateData              (),

            .NtrSinkMmrTrramcontrol                        (NtrSinkMmrs.Trramcontrol),
            .NtrSinkMmrTrramimpl                           (NtrSinkMmrs.Trramimpl),
            .NtrSinkMmrTrramstartlow                       (NtrSinkMmrs.Trramstartlow),
            .NtrSinkMmrTrramstarthigh                      (NtrSinkMmrs.Trramstarthigh),
            .NtrSinkMmrTrramlimitlow                       (NtrSinkMmrs.Trramlimitlow),
            .NtrSinkMmrTrramlimithigh                      (NtrSinkMmrs.Trramlimithigh),
            .NtrSinkMmrTrramwplow                          (NtrSinkMmrs.Trramwplow),
            .NtrSinkMmrTrramwphigh                         (NtrSinkMmrs.Trramwphigh),
            .NtrSinkMmrTrramrplow                          (NtrSinkMmrs.Trramrplow),
            .NtrSinkMmrTrramrphigh                         (NtrSinkMmrs.Trramrphigh),
            .NtrSinkMmrTrramdata                           (NtrSinkMmrs.Trramdata),

            .NtrSinkMmrTrramcontrolWr                      (NtrSinkMmrsWr.TrramcontrolWr),
            .NtrSinkMmrTrramstartlowWr                     ('0),
            .NtrSinkMmrTrramstarthighWr                    ('0),
            .NtrSinkMmrTrramlimitlowWr                     ('0),
            .NtrSinkMmrTrramlimithighWr                    ('0),
            .NtrSinkMmrTrramwplowWr                        (NtrSinkMmrsWr.TrramwplowWr),
            .NtrSinkMmrTrramwphighWr                       (NtrSinkMmrsWr.TrramwphighWr),
            .NtrSinkMmrTrramrplowWr                        (NtrSinkMmrsWr.TrramrplowWr),
            .NtrSinkMmrTrramrphighWr                       (NtrSinkMmrsWr.TrramrphighWr),
            .NtrSinkMmrTrramdataWr                         (NtrSinkMmrsWr.TrramdataWr),

            .NtrSinkMmrTrcustomramsmemlimitlow             (NtrSinkMmrs.Trcustomramsmemlimitlow),
            .NtrSinkMmrScratchlo                           (NtrSinkMmrs.Scratchlo),
            .NtrSinkMmrScratchhi                           (NtrSinkMmrs.Scratchhi),
            .MmrUpdateIndirAddr         ()
        );
    end else begin : no_ntr_sink_csr_gen_blk
        assign ntr_sink_func_enable = '0;
        assign NtrSinkMmrs = '0;
        assign MmrHit_NTR_SINK = '0;
        assign MmrRdData_NTR_SINK = '0;
        end

    if (NUM_DST_INST > 0) begin : dst_csr_gen_blk
        for (genvar ii = 0; ii < NUM_DST_INST; ii++) begin : dst_csr_inst
                localparam int unsigned BLK_IDX = DST_START_IDX + ii;

                assign dst_func_enable[ii] = DstMmrs[ii].Trdstcontrol.Trdstactive;

                    dst_mmr #(

                    ) u_dst_mmr (
                        .clk                        (i_clk),
                        .reset_n                    (i_rst_n),

                    /* verilator lint_off WIDTHEXPAND */
                    .MmrCs                      (MmrCs[BLK_IDX]),
                    /* verilator lint_on WIDTHEXPAND */
                    .MmrWrEn                    (MmrWrEn),
                    .MmrWrStrb                  (MmrWrStrb),
                    .MmrRegSel                  (MmrRegSel),
                    .MmrAddr                    (MmrAddr),
                    .MmrWrData                  (MmrWrData),
                    .MmrWrInstrType             (MmrWrInstrType),
                    .MmrWrReady                 (),
                    .MmrHit                     (MmrHit_DST[ii]),
                    .MmrHitList                 (),
                    .MmrRdData                  (MmrRdData_DST[ii]),
                    .DstMmrTrdstcontrol        (DstMmrs[ii].Trdstcontrol),
                    .DstMmrTrdstimpl           (DstMmrs[ii].Trdstimpl),
                    .DstMmrTrdstinstfeatures   (DstMmrs[ii].Trdstinstfeatures),
                    .DstMmrCdbgdebugtracecfg   (DstMmrs[ii].Cdbgdebugtracecfg),
                    .DstMmrScratchlo           (DstMmrs[ii].Scratchlo),
                    .DstMmrScratchhi           (DstMmrs[ii].Scratchhi),
                    .DstMmrTrdstcontrolWr      (DstMmrsWr[ii].TrdstcontrolWr),
                    .MmrUpdateEn                (),
                    .MmrUpdateAddr              (),
                    .MmrUpdateData              (),
                    .MmrUpdateIndirAddr         ()
                );

        end
    end else begin : no_dst_csr_gen_blk
        assign dst_func_enable = '0;
        assign DstMmrs = '0;
        assign MmrHit_DST = '0;
        assign MmrRdData_DST = '0;

    end
    if (DST_SINK_EN) begin : dst_sink_csr_gen_blk

        assign dst_sink_func_enable = DstSinkMmrs.Trdstramcontrol.Trdstramactive;

        dst_sink_mmr #(

        ) u_dst_sink_mmr (
            .clk                                      (i_clk),
            .reset_n                                  (i_rst_n),
            .MmrCs                                    (MmrCs[DST_SINK_BLK_IDX]),
            .MmrWrEn                                  (Warl_Updated_WrEn_ANY),
            .MmrWrStrb                                (MmrWrStrb),
            .MmrRegSel                                (MmrRegSel),
            .MmrAddr                                  (MmrAddr),
            .MmrWrData                                (Warl_Muxed_MmrWrData),
            .MmrWrInstrType                           (MmrWrInstrType),
            .MmrWrReady                               (),
            .MmrHit                                   (MmrHit_DST_SINK),
            .MmrRdData                                (MmrRdData_DST_SINK),
            .MmrHitList                               (),
            .MmrUpdateEn                              (),
            .MmrUpdateAddr                            (),
            .MmrUpdateData                            (),
            .DstSinkMmrTrdstramcontrol                     (DstSinkMmrs.Trdstramcontrol),
            .DstSinkMmrTrdstramimpl                        (DstSinkMmrs.Trdstramimpl),
            .DstSinkMmrTrdstramstartlow                    (DstSinkMmrs.Trdstramstartlow),
            .DstSinkMmrTrdstramstarthigh                   (DstSinkMmrs.Trdstramstarthigh),
            .DstSinkMmrTrdstramlimitlow                    (DstSinkMmrs.Trdstramlimitlow),
            .DstSinkMmrTrdstramlimithigh                   (DstSinkMmrs.Trdstramlimithigh),
            .DstSinkMmrTrdstramwplow                       (DstSinkMmrs.Trdstramwplow),
            .DstSinkMmrTrdstramwphigh                      (DstSinkMmrs.Trdstramwphigh),
            .DstSinkMmrTrdstramrplow                       (DstSinkMmrs.Trdstramrplow),
            .DstSinkMmrTrdstramrphigh                      (DstSinkMmrs.Trdstramrphigh),
            .DstSinkMmrTrdstramdata                        (DstSinkMmrs.Trdstramdata),

            .DstSinkMmrTrdstramcontrolWr                   (DstSinkMmrsWr.TrdstramcontrolWr),
            .DstSinkMmrTrdstramstartlowWr                  ('0),
            .DstSinkMmrTrdstramstarthighWr                 ('0),
            .DstSinkMmrTrdstramlimitlowWr                  ('0),
            .DstSinkMmrTrdstramlimithighWr                 ('0),
            .DstSinkMmrTrdstramwplowWr                     (DstSinkMmrsWr.TrdstramwplowWr),
            .DstSinkMmrTrdstramwphighWr                    (DstSinkMmrsWr.TrdstramwphighWr),
            .DstSinkMmrTrdstramrplowWr                     (DstSinkMmrsWr.TrdstramrplowWr),
            .DstSinkMmrTrdstramrphighWr                    (DstSinkMmrsWr.TrdstramrphighWr),
            .DstSinkMmrTrdstramdataWr                      (DstSinkMmrsWr.TrdstramdataWr),
            .DstSinkMmrScratchlo                           (DstSinkMmrs.Scratchlo),
            .DstSinkMmrScratchhi                           (DstSinkMmrs.Scratchhi),
            .MmrUpdateIndirAddr         ()
        );

    end else begin : no_dst_sink_csr_gen_blk
        assign dst_sink_func_enable = '0;
        assign DstSinkMmrs = '0;
        assign MmrHit_DST_SINK = '0;
        assign MmrRdData_DST_SINK = '0;
        end

    if (CLA_EN) begin : cla_csr_gen_blk
        ClaCdbgmuxselloMmrWr_s [NUM_CLA_INST-1:0] CdbgmuxselloWr;
        for (genvar ii = 0; ii < NUM_CLA_INST; ii++) begin : cla_csr_inst
                localparam int unsigned BLK_IDX = CLA_START_IDX + ii;

                assign cla_func_enable[ii] = ClaMmrs[ii].Cdbgclactrlstatus.EnableCla;

            cla_mmr #(

            ) u_cla_mmr (
                        .clk                    (i_clk),
                        .reset_n                (i_rst_n),
                    .reset_n_warm_ovrride   (cla_reset_n_warm_ovrride[ii]),
                    .reset_n_warm_ovrride_hi(cla_reset_n_warm_ovrride_hi[ii]),
                    /* verilator lint_off WIDTHEXPAND */
                    .MmrCs          (MmrCs[BLK_IDX]),
                    /* verilator lint_on WIDTHEXPAND */
                    .MmrWrEn        (MmrWrEn),
                    .MmrWrStrb      (MmrWrStrb8B),
                    .MmrRegSel      (MmrRegSel),
                    .MmrAddr        (MmrAddr8B),
                    .MmrWrData      (MmrWrData8B),
                    .MmrWrInstrType (MmrWrInstrType),
                    .MmrWrReady     (),
                    .MmrHit         (MmrHit_CLA[ii]),
                    .MmrHitList     (),
                    .MmrRdData      (MmrRdData8B_CLA[ii]),

                    .ClaMmrCdbgclacounter0Cfg    (ClaMmrs[ii].Cdbgclacounter0Cfg),
                    .ClaMmrCdbgclacounter1Cfg    (ClaMmrs[ii].Cdbgclacounter1Cfg),
                    .ClaMmrCdbgclacounter2Cfg    (ClaMmrs[ii].Cdbgclacounter2Cfg),
                    .ClaMmrCdbgclacounter3Cfg    (ClaMmrs[ii].Cdbgclacounter3Cfg),
                    .ClaMmrCdbgnode0Eap0         (ClaMmrs[ii].Cdbgnode0Eap0),
                    .ClaMmrCdbgnode0Eap1         (ClaMmrs[ii].Cdbgnode0Eap1),
                    .ClaMmrCdbgnode0Eap2         (ClaMmrs[ii].Cdbgnode0Eap2),
                    .ClaMmrCdbgnode0Eap3         (ClaMmrs[ii].Cdbgnode0Eap3),
                    .ClaMmrCdbgnode1Eap0         (ClaMmrs[ii].Cdbgnode1Eap0),
                    .ClaMmrCdbgnode1Eap1         (ClaMmrs[ii].Cdbgnode1Eap1),
                    .ClaMmrCdbgnode1Eap2         (ClaMmrs[ii].Cdbgnode1Eap2),
                    .ClaMmrCdbgnode1Eap3         (ClaMmrs[ii].Cdbgnode1Eap3),
                    .ClaMmrCdbgnode2Eap0         (ClaMmrs[ii].Cdbgnode2Eap0),
                    .ClaMmrCdbgnode2Eap1         (ClaMmrs[ii].Cdbgnode2Eap1),
                    .ClaMmrCdbgnode2Eap2         (ClaMmrs[ii].Cdbgnode2Eap2),
                    .ClaMmrCdbgnode2Eap3         (ClaMmrs[ii].Cdbgnode2Eap3),
                    .ClaMmrCdbgnode3Eap0         (ClaMmrs[ii].Cdbgnode3Eap0),
                    .ClaMmrCdbgnode3Eap1         (ClaMmrs[ii].Cdbgnode3Eap1),
                    .ClaMmrCdbgnode3Eap2         (ClaMmrs[ii].Cdbgnode3Eap2),
                    .ClaMmrCdbgnode3Eap3         (ClaMmrs[ii].Cdbgnode3Eap3),
                    .ClaMmrCdbgsignalmask0Lo     (ClaMmrs[ii].Cdbgsignalmask0Lo),
                    .ClaMmrCdbgsignalmask0Hi     (ClaMmrs[ii].Cdbgsignalmask0Hi),
                    .ClaMmrCdbgsignalmatch0Lo    (ClaMmrs[ii].Cdbgsignalmatch0Lo),
                    .ClaMmrCdbgsignalmatch0Hi    (ClaMmrs[ii].Cdbgsignalmatch0Hi),
                    .ClaMmrCdbgsignalmask1Lo     (ClaMmrs[ii].Cdbgsignalmask1Lo),
                    .ClaMmrCdbgsignalmask1Hi     (ClaMmrs[ii].Cdbgsignalmask1Hi),
                    .ClaMmrCdbgsignalmatch1Lo    (ClaMmrs[ii].Cdbgsignalmatch1Lo),
                    .ClaMmrCdbgsignalmatch1Hi    (ClaMmrs[ii].Cdbgsignalmatch1Hi),
                    .ClaMmrCdbgsignalmask2Lo     (ClaMmrs[ii].Cdbgsignalmask2Lo),
                    .ClaMmrCdbgsignalmask2Hi     (ClaMmrs[ii].Cdbgsignalmask2Hi),
                    .ClaMmrCdbgsignalmatch2Lo    (ClaMmrs[ii].Cdbgsignalmatch2Lo),
                    .ClaMmrCdbgsignalmatch2Hi    (ClaMmrs[ii].Cdbgsignalmatch2Hi),
                    .ClaMmrCdbgsignalmask3Lo     (ClaMmrs[ii].Cdbgsignalmask3Lo),
                    .ClaMmrCdbgsignalmask3Hi     (ClaMmrs[ii].Cdbgsignalmask3Hi),
                    .ClaMmrCdbgsignalmatch3Lo    (ClaMmrs[ii].Cdbgsignalmatch3Lo),
                    .ClaMmrCdbgsignalmatch3Hi    (ClaMmrs[ii].Cdbgsignalmatch3Hi),
                    .ClaMmrCdbgsignaledgedetectcfg(ClaMmrs[ii].Cdbgsignaledgedetectcfg),
                    .ClaMmrCdbgeapstatus         (ClaMmrs[ii].Cdbgeapstatus),
                    .ClaMmrCdbgclactrlstatus     (ClaMmrs[ii].Cdbgclactrlstatus),
                    .ClaMmrCdbgmuxsello          (ClaMmrs[ii].Cdbgmuxsello),
                    .ClaMmrCdbgmuxselhi          (ClaMmrs[ii].Cdbgmuxselhi),
                    .ClaMmrCdbgrsvd1             (ClaMmrs[ii].Cdbgrsvd1),
                    .ClaMmrCdbgrsvd2             (ClaMmrs[ii].Cdbgrsvd2),
                    .ClaMmrCdbgtransitionmasklo  (ClaMmrs[ii].Cdbgtransitionmasklo),
                    .ClaMmrCdbgtransitionmaskhi  (ClaMmrs[ii].Cdbgtransitionmaskhi),
                    .ClaMmrCdbgtransitionfromvaluelo(ClaMmrs[ii].Cdbgtransitionfromvaluelo),
                    .ClaMmrCdbgtransitionfromvaluehi(ClaMmrs[ii].Cdbgtransitionfromvaluehi),
                    .ClaMmrCdbgtransitiontovaluelo(ClaMmrs[ii].Cdbgtransitiontovaluelo),
                    .ClaMmrCdbgtransitiontovaluehi(ClaMmrs[ii].Cdbgtransitiontovaluehi),
                    .ClaMmrCdbgonescountmasklo   (ClaMmrs[ii].Cdbgonescountmasklo),
                    .ClaMmrCdbgonescountmaskhi   (ClaMmrs[ii].Cdbgonescountmaskhi),
                    .ClaMmrCdbgonescountvalue  (ClaMmrs[ii].Cdbgonescountvalue),
                    .ClaMmrCdbganychangelo       (ClaMmrs[ii].Cdbganychangelo),
                    .ClaMmrCdbganychangehi       (ClaMmrs[ii].Cdbganychangehi),
                    .ClaMmrCdbgsignalsnapshotnode0Eap0Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap0Lo),
                    .ClaMmrCdbgsignalsnapshotnode0Eap0Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap0Hi),
                    .ClaMmrCdbgsignalsnapshotnode0Eap1Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap1Lo),
                    .ClaMmrCdbgsignalsnapshotnode0Eap1Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap1Hi),
                    .ClaMmrCdbgsignalsnapshotnode0Eap2Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap2Lo),
                    .ClaMmrCdbgsignalsnapshotnode0Eap2Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap2Hi),
                    .ClaMmrCdbgsignalsnapshotnode0Eap3Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap3Lo),
                    .ClaMmrCdbgsignalsnapshotnode0Eap3Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode0Eap3Hi),
                    .ClaMmrCdbgsignalsnapshotnode1Eap0Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap0Lo),
                    .ClaMmrCdbgsignalsnapshotnode1Eap0Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap0Hi),
                    .ClaMmrCdbgsignalsnapshotnode1Eap1Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap1Lo),
                    .ClaMmrCdbgsignalsnapshotnode1Eap1Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap1Hi),
                    .ClaMmrCdbgsignalsnapshotnode1Eap2Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap2Lo),
                    .ClaMmrCdbgsignalsnapshotnode1Eap2Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap2Hi),
                    .ClaMmrCdbgsignalsnapshotnode1Eap3Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap3Lo),
                    .ClaMmrCdbgsignalsnapshotnode1Eap3Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode1Eap3Hi),
                    .ClaMmrCdbgsignalsnapshotnode2Eap0Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap0Lo),
                    .ClaMmrCdbgsignalsnapshotnode2Eap0Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap0Hi),
                    .ClaMmrCdbgsignalsnapshotnode2Eap1Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap1Lo),
                    .ClaMmrCdbgsignalsnapshotnode2Eap1Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap1Hi),
                    .ClaMmrCdbgsignalsnapshotnode2Eap2Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap2Lo),
                    .ClaMmrCdbgsignalsnapshotnode2Eap2Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap2Hi),
                    .ClaMmrCdbgsignalsnapshotnode2Eap3Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap3Lo),
                    .ClaMmrCdbgsignalsnapshotnode2Eap3Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode2Eap3Hi),
                    .ClaMmrCdbgsignalsnapshotnode3Eap0Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap0Lo),
                    .ClaMmrCdbgsignalsnapshotnode3Eap0Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap0Hi),
                    .ClaMmrCdbgsignalsnapshotnode3Eap1Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap1Lo),
                    .ClaMmrCdbgsignalsnapshotnode3Eap1Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap1Hi),
                    .ClaMmrCdbgsignalsnapshotnode3Eap2Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap2Lo),
                    .ClaMmrCdbgsignalsnapshotnode3Eap2Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap2Hi),
                    .ClaMmrCdbgsignalsnapshotnode3Eap3Lo(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap3Lo),
                    .ClaMmrCdbgsignalsnapshotnode3Eap3Hi(ClaMmrs[ii].Cdbgsignalsnapshotnode3Eap3Hi),
                    .ClaMmrCdbgclatimematch      (ClaMmrs[ii].Cdbgclatimematch),
                    .ClaMmrCdbgsignaldelaymuxsel (ClaMmrs[ii].Cdbgsignaldelaymuxsel),
                    .ClaMmrCdbgclaxtriggertimestretch(ClaMmrs[ii].Cdbgclaxtriggertimestretch),
                    .ClaMmrCdbgclatimestamp      (ClaMmrs[ii].Cdbgclatimestamp),
                    .ClaMmrCdbgclatimestampsync  (ClaMmrs[ii].Cdbgclatimestampsync),
                    .ClaMmrCdbgclatimestampoffset  (ClaMmrs[ii].Cdbgclatimestampoffset),
                    .ClaMmrCdbgclatimestampconfig(ClaMmrs[ii].Cdbgclatimestampconfig),
                    .ClaMmrScratch               (ClaMmrs[ii].Scratch),
                    .ClaMmrCdbglfsr              (ClaMmrs[ii].Cdbglfsr),
                    .ClaMmrCdbglfsrmask          (ClaMmrs[ii].Cdbglfsrmask),
                    .ClaMmrCdbgtimestampcapture  (ClaMmrs[ii].Cdbgtimestampcapture),
                    .ClaMmrCdbgcompare0Lo        (ClaMmrs[ii].Cdbgcompare0Lo),
                    .ClaMmrCdbgcompare0Masklo    (ClaMmrs[ii].Cdbgcompare0Masklo),
                    .ClaMmrCdbgcompare0Hi        (ClaMmrs[ii].Cdbgcompare0Hi),
                    .ClaMmrCdbgcompare0Maskhi    (ClaMmrs[ii].Cdbgcompare0Maskhi),
                    .ClaMmrCdbgcompare1Lo        (ClaMmrs[ii].Cdbgcompare1Lo),
                    .ClaMmrCdbgcompare1Masklo    (ClaMmrs[ii].Cdbgcompare1Masklo),
                    .ClaMmrCdbgcompare1Hi        (ClaMmrs[ii].Cdbgcompare1Hi),
                    .ClaMmrCdbgcompare1Maskhi    (ClaMmrs[ii].Cdbgcompare1Maskhi),
                    .ClaMmrCdbgcompare2Lo        (ClaMmrs[ii].Cdbgcompare2Lo),
                    .ClaMmrCdbgcompare2Masklo    (ClaMmrs[ii].Cdbgcompare2Masklo),
                    .ClaMmrCdbgcompare2Hi        (ClaMmrs[ii].Cdbgcompare2Hi),
                    .ClaMmrCdbgcompare2Maskhi    (ClaMmrs[ii].Cdbgcompare2Maskhi),
                    .ClaMmrCdbgcompare3Lo        (ClaMmrs[ii].Cdbgcompare3Lo),
                    .ClaMmrCdbgcompare3Masklo    (ClaMmrs[ii].Cdbgcompare3Masklo),
                    .ClaMmrCdbgcompare3Hi        (ClaMmrs[ii].Cdbgcompare3Hi),
                    .ClaMmrCdbgcompare3Maskhi    (ClaMmrs[ii].Cdbgcompare3Maskhi),
                    .ClaMmrCdbgversion           (ClaMmrs[ii].Cdbgversion),
                    .ClaMmrCdbgmuxselloWr        (CdbgmuxselloWr[ii]),
                    .ClaMmrCdbgclacounter0CfgWr  (ClaMmrsWr[ii].Cdbgclacounter0CfgWr),
                    .ClaMmrCdbgclacounter1CfgWr  (ClaMmrsWr[ii].Cdbgclacounter1CfgWr),
                    .ClaMmrCdbgclacounter2CfgWr  (ClaMmrsWr[ii].Cdbgclacounter2CfgWr),
                    .ClaMmrCdbgclacounter3CfgWr  (ClaMmrsWr[ii].Cdbgclacounter3CfgWr),
                    .ClaMmrCdbgeapstatusWr       (ClaMmrsWr[ii].CdbgeapstatusWr),
                    .ClaMmrCdbgclactrlstatusWr   (ClaMmrsWr[ii].CdbgclactrlstatusWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap0LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap0LoWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap0HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap0HiWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap1LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap1LoWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap1HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap1HiWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap2LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap2LoWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap2HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap2HiWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap3LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap3LoWr),
                    .ClaMmrCdbgsignalsnapshotnode0Eap3HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode0Eap3HiWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap0LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap0LoWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap0HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap0HiWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap1LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap1LoWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap1HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap1HiWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap2LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap2LoWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap2HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap2HiWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap3LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap3LoWr),
                    .ClaMmrCdbgsignalsnapshotnode1Eap3HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode1Eap3HiWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap0LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap0LoWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap0HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap0HiWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap1LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap1LoWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap1HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap1HiWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap2LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap2LoWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap2HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap2HiWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap3LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap3LoWr),
                    .ClaMmrCdbgsignalsnapshotnode2Eap3HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode2Eap3HiWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap0LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap0LoWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap0HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap0HiWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap1LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap1LoWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap1HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap1HiWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap2LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap2LoWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap2HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap2HiWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap3LoWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap3LoWr),
                    .ClaMmrCdbgsignalsnapshotnode3Eap3HiWr(ClaMmrsWr[ii].Cdbgsignalsnapshotnode3Eap3HiWr),
                    .ClaMmrCdbgclatimestampWr    (ClaMmrsWr[ii].CdbgclatimestampWr),
                    .ClaMmrCdbgclatimestampconfigWr(ClaMmrsWr[ii].CdbgclatimestampconfigWr),
                    .ClaMmrCdbglfsrWr             (ClaMmrsWr[ii].CdbglfsrWr),
                    .ClaMmrCdbgtimestampcaptureWr (ClaMmrsWr[ii].CdbgtimestampcaptureWr),
                    .MmrUpdateEn                (),
                    .MmrUpdateAddr              (),
                    .MmrUpdateData              (),
                    .MmrUpdateIndirAddr         ()
            );

                assign CdbgmuxselloWr[ii].Data            = '0;
                assign CdbgmuxselloWr[ii].ValidWrEn  = ClaMmrs[ii].Cdbgmuxsello.Valid;

                assign MmrRdData_CLA[ii] = (MmrAddr[2] == 1'b0) ? MmrRdData8B_CLA[ii][31:0] : MmrRdData8B_CLA[ii][63:32];
        end
    end else begin : no_cla_csr_gen_blk
        assign cla_func_enable = '0;
        assign ClaMmrs = '0;
        assign MmrHit_CLA = '0;
        assign MmrRdData_CLA = '0;
    end

    if (TRACE_SINK_SUPPORT == 1) begin : funnel_mmr_gen_blk

        assign funnel_func_enable = FunnelMmrs.Trfunnelcontrol.Trfunnelactive;

        funnel_mmr #(

        ) u_funnel_mmr (
                .clk                                      (i_clk),
                .reset_n                                  (i_rst_n),
            .MmrCs                                    (MmrCs[FUNNEL_BLK_IDX]),
            .MmrWrEn                                  (Warl_Updated_WrEn_ANY),
            .MmrWrStrb                                (MmrWrStrb),
            .MmrRegSel                                (MmrRegSel),
            .MmrAddr                                  (MmrAddr),
            .MmrWrData                                (Warl_Muxed_MmrWrData),
            .MmrWrInstrType                           (MmrWrInstrType),
            .MmrWrReady                               (),
            .MmrHit                                   (MmrHit_FUNNEL),
            .MmrRdData                                (MmrRdData_FUNNEL),
            .MmrHitList                               (),
            .MmrUpdateEn                              (),
            .MmrUpdateAddr                            (),
            .MmrUpdateData                            (),

            .FunnelMmrTrfunnelcontrol                     (FunnelMmrs.Trfunnelcontrol),
            .FunnelMmrTrfunnelimpl                        (FunnelMmrs.Trfunnelimpl),
            .FunnelMmrTrfunneldisinput                    (FunnelMmrs.Trfunneldisinput),
            .FunnelMmrScratchlo                           (FunnelMmrs.Scratchlo),
            .FunnelMmrScratchhi                           (FunnelMmrs.Scratchhi),

            .FunnelMmrTrfunnelcontrolWr                   (FunnelMmrsWr.TrfunnelcontrolWr),
            .FunnelMmrTrfunneldisinputWr                  ('0),
            .MmrUpdateIndirAddr         ()
        );

    end else begin : no_funnel_csr_gen_blk

        assign funnel_func_enable = '0;
        assign FunnelMmrs = '0;
        assign MmrHit_FUNNEL = '0;
        assign MmrRdData_FUNNEL = '0;
    end

endmodule
