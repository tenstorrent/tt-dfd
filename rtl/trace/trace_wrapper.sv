// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`include "axi/typedef.svh"

module trace_wrapper
import tn_pkg::*;
import ntr_sink_mmr_pkg::*;
import dst_sink_mmr_pkg::*;
import funnel_mmr_pkg::*;
#(
	parameter NUM_DST_INST = 8,
	parameter NUM_NTRACE_INST = 8,

	localparam NUM_CORES = (NUM_DST_INST > NUM_NTRACE_INST) ? NUM_DST_INST : NUM_NTRACE_INST,
	localparam NUM_CORES_WIDTH = (NUM_CORES == 1) ? 1 : $clog2(NUM_CORES),
	localparam NUM_CORES_IN_NORTH_PATH = (NUM_CORES + 1) >> 1,
	localparam NUM_CORES_IN_SOUTH_PATH = (NUM_CORES >> 1) == 0 ? 1 : NUM_CORES >> 1,

	parameter TRC_BASE_ADDR = 0,
	parameter TRC_AXI_ADDR_WIDTH = 52,
	parameter TRC_AXI_ID_WIDTH = 4,
	parameter TRC_AXI_USER_WIDTH = 8,
	parameter TRC_AXI_DATA_WIDTH = 512,

	parameter TRC_RAM_INDEX = 512,
	parameter TRC_SIZE_IN_KB = 32,
	parameter TSEL_CONFIGURABLE = 0,
	localparam int DATA_WIDTH = 128,
	localparam NUM_DST_INST_SAFE = (NUM_DST_INST > 0) ? NUM_DST_INST : 32'd1,
	localparam NUM_NTRACE_INST_SAFE = (NUM_NTRACE_INST > 0) ? NUM_NTRACE_INST : 32'd1
) (

	input  logic                                            dst_sink_gated_clock,
	input  logic                                            dst_sink_gated_reset_n,
	input  logic                                            dst_sink_gated_reset_n_warm_ovrride,
	input  logic                                            dst_sink_gated_func_clamp,

	input  logic                                            ntr_sink_gated_clock,
	input  logic                                            ntr_sink_gated_reset_n,
	input  logic                                            ntr_sink_gated_reset_n_warm_ovrride,
	input  logic                                            ntr_sink_gated_func_clamp,

	input  logic                                            funnel_gated_clock,
	input  logic                                            funnel_gated_reset_n,
	input  logic                                            funnel_gated_reset_n_warm_ovrride,
	input  logic                                            funnel_gated_func_clamp,

	input logic [NUM_DST_INST_SAFE-1:0]                     dst_gated_func_clamp,
	input logic [NUM_NTRACE_INST_SAFE-1:0]                  ntr_gated_func_clamp,

	input  logic [NUM_CORES-1:0] [NUM_CORES_WIDTH-1:0]     i_vid_map,

	input  logic [10:0]										i_mem_tsel_settings,

	output logic [NUM_CORES-1:0]                            tr_tnif_gnt,
	output logic [NUM_CORES-1:0]                            tr_tnif_ntr_bp,
	output logic [NUM_CORES-1:0]                            tr_tnif_dst_bp,
	output logic [NUM_CORES-1:0]                            tr_tnif_ntr_flush,
	output logic [NUM_CORES-1:0]                            tr_tnif_dst_flush,
	input  logic [NUM_CORES-1:0]                            tnif_tr_valid,
	input  logic [NUM_CORES-1:0]                            tnif_tr_src,
	input  logic [NUM_CORES-1:0] [DATA_WIDTH-1:0]           tnif_tr_data,

	input NtrSinkMmrs_s 										NtrSinkMmrs,
	output NtrSinkMmrsWr_s 										NtrSinkMmrsWr,

	input DstSinkMmrs_s 										DstSinkMmrs,
	output DstSinkMmrsWr_s 										DstSinkMmrsWr,

	input FunnelMmrs_s 											FunnelMmrs,
	output FunnelMmrsWr_s 										FunnelMmrsWr,

 	output  logic [TRC_AXI_ID_WIDTH-1:0]         m_trc_axi_awid,
    output  logic [TRC_AXI_ADDR_WIDTH-1:0]           m_trc_axi_awaddr,
    output  logic [7:0]                      m_trc_axi_awlen,
    output  logic [2:0]                      m_trc_axi_awsize,
    output  logic [1:0]                      m_trc_axi_awburst,
    output  logic                            m_trc_axi_awlock,
    output  logic [3:0]                      m_trc_axi_awcache,
    output  logic [2:0]                      m_trc_axi_awprot,
    output  logic [3:0]                      m_trc_axi_awqos,
    output  logic [3:0]                      m_trc_axi_awregion,
    output  logic [5:0]                      m_trc_axi_awatop,
    output  logic [TRC_AXI_USER_WIDTH-1:0]       m_trc_axi_awuser,
    output logic                            m_trc_axi_awvalid,
    input logic                            m_trc_axi_awready,

    output  logic [TRC_AXI_DATA_WIDTH-1:0]           m_trc_axi_wdata,
    output  logic [(TRC_AXI_DATA_WIDTH/8)-1:0]       m_trc_axi_wstrb,
    output  logic                            m_trc_axi_wlast,
    output  logic [TRC_AXI_USER_WIDTH-1:0]       m_trc_axi_wuser,
    output logic                            m_trc_axi_wvalid,
    input logic                            m_trc_axi_wready,

    input logic [TRC_AXI_ID_WIDTH-1:0]         m_trc_axi_bid,
    input logic [1:0]                      m_trc_axi_bresp,
    input logic [TRC_AXI_USER_WIDTH-1:0]       m_trc_axi_buser,
    input logic                            m_trc_axi_bvalid,
    output  logic                            m_trc_axi_bready,

    output  logic [TRC_AXI_ID_WIDTH-1:0]         m_trc_axi_arid,
    output  logic [TRC_AXI_ADDR_WIDTH-1:0]           m_trc_axi_araddr,
    output  logic [7:0]                      m_trc_axi_arlen,
    output  logic [2:0]                      m_trc_axi_arsize,
    output  logic [1:0]                      m_trc_axi_arburst,
    output  logic                            m_trc_axi_arlock,
    output  logic [3:0]                      m_trc_axi_arcache,
    output  logic [2:0]                      m_trc_axi_arprot,
    output  logic [3:0]                      m_trc_axi_arqos,
    output  logic [3:0]                      m_trc_axi_arregion,
    output  logic [TRC_AXI_USER_WIDTH-1:0]       m_trc_axi_aruser,
    output  logic                            m_trc_axi_arvalid,
    input logic                            m_trc_axi_arready,

    input logic [TRC_AXI_ID_WIDTH-1:0]         m_trc_axi_rid,
    input logic [TRC_AXI_DATA_WIDTH-1:0]           m_trc_axi_rdata,
    input logic [1:0]                      m_trc_axi_rresp,
    input logic                            m_trc_axi_rlast,
    input logic [TRC_AXI_USER_WIDTH-1:0]       m_trc_axi_ruser,
    input logic                            m_trc_axi_rvalid,
    output  logic                            m_trc_axi_rready,

	input logic                                             trRamDataRdEn,
	input logic                                             trdstRamDataRdEn,
	output logic                                            TraceRamWrEn
 );

	localparam int unsigned DATA_WIDTH_IN_BYTES = DATA_WIDTH / 8;

    typedef logic [TRC_AXI_ADDR_WIDTH-1:0]       m_trc_axi_addr_t;
    typedef logic [TRC_AXI_DATA_WIDTH-1:0]       m_trc_axi_data_t;
    typedef logic [(TRC_AXI_DATA_WIDTH/8)-1:0]   m_trc_axi_strb_t;
    typedef logic [TRC_AXI_USER_WIDTH-1:0]   m_trc_axi_user_t;
    typedef logic [TRC_AXI_ID_WIDTH-1:0]     m_trc_axi_id_t;
    `AXI_TYPEDEF_ALL_CT(m_trc_axi, m_trc_axi_req_t, m_trc_axi_rsp_t, m_trc_axi_addr_t, m_trc_axi_id_t, m_trc_axi_data_t, m_trc_axi_strb_t, m_trc_axi_user_t)

	m_trc_axi_req_t m_trc_axi_req, m_trc_axi_req_int;
	m_trc_axi_rsp_t m_trc_axi_rsp;

	always_comb begin
		m_trc_axi_awid = m_trc_axi_req.aw.id;
		m_trc_axi_awaddr = m_trc_axi_req.aw.addr;
		m_trc_axi_awlen = m_trc_axi_req.aw.len;
		m_trc_axi_awsize = m_trc_axi_req.aw.size;
		m_trc_axi_awburst = m_trc_axi_req.aw.burst;
		m_trc_axi_awlock = m_trc_axi_req.aw.lock;
		m_trc_axi_awcache = m_trc_axi_req.aw.cache;
		m_trc_axi_awprot = m_trc_axi_req.aw.prot;
		m_trc_axi_awqos = m_trc_axi_req.aw.qos;
		m_trc_axi_awregion = m_trc_axi_req.aw.region;
		m_trc_axi_awatop = m_trc_axi_req.aw.atop;
		m_trc_axi_awuser = m_trc_axi_req.aw.user;
		m_trc_axi_awvalid = m_trc_axi_req.aw_valid;

		m_trc_axi_wdata = m_trc_axi_req.w.data;
		m_trc_axi_wstrb = m_trc_axi_req.w.strb;
		m_trc_axi_wlast = m_trc_axi_req.w.last;
		m_trc_axi_wuser = m_trc_axi_req.w.user;
		m_trc_axi_wvalid = m_trc_axi_req.w_valid;
		m_trc_axi_bready = m_trc_axi_req.b_ready;

		m_trc_axi_arid = m_trc_axi_req.ar.id;
		m_trc_axi_araddr = m_trc_axi_req.ar.addr;
		m_trc_axi_arlen = m_trc_axi_req.ar.len;
		m_trc_axi_arsize = m_trc_axi_req.ar.size;
		m_trc_axi_arburst = m_trc_axi_req.ar.burst;
		m_trc_axi_arlock = m_trc_axi_req.ar.lock;
		m_trc_axi_arcache = m_trc_axi_req.ar.cache;
		m_trc_axi_arprot = m_trc_axi_req.ar.prot;
		m_trc_axi_arqos = m_trc_axi_req.ar.qos;
		m_trc_axi_arregion = m_trc_axi_req.ar.region;
		m_trc_axi_aruser = m_trc_axi_req.ar.user;
		m_trc_axi_arvalid = m_trc_axi_req.ar_valid;
		m_trc_axi_rready = m_trc_axi_req.r_ready;

		m_trc_axi_rsp = '0;
		m_trc_axi_rsp.aw_ready = m_trc_axi_awready;
		m_trc_axi_rsp.w_ready = m_trc_axi_wready;
		m_trc_axi_rsp.b.id = m_trc_axi_bid;
		m_trc_axi_rsp.b.resp = m_trc_axi_bresp;
		m_trc_axi_rsp.b.user = m_trc_axi_buser;
		m_trc_axi_rsp.b_valid = m_trc_axi_bvalid;
		m_trc_axi_rsp.ar_ready = m_trc_axi_arready;
		m_trc_axi_rsp.r.id = m_trc_axi_rid;
		m_trc_axi_rsp.r.data = m_trc_axi_rdata;
		m_trc_axi_rsp.r.resp = m_trc_axi_rresp;
		m_trc_axi_rsp.r.last = m_trc_axi_rlast;
		m_trc_axi_rsp.r.user = m_trc_axi_ruser;
		m_trc_axi_rsp.r_valid = m_trc_axi_rvalid;
	end

  	localparam TRC_RAM_INDEX_WIDTH = $clog2(TRC_RAM_INDEX);
	localparam TRC_SIZE = TRC_SIZE_IN_KB * 1024 * 8;

	typedef struct packed {
		logic   mem_chip_en;
		logic   mem_wr_en;
		logic   [TRC_RAM_INDEX_WIDTH-1:0] mem_wr_addr;
		logic   mem_wr_mask_en;
		logic   [TRC_RAM_DATA_WIDTH-1:0] mem_wr_data;
	} SinkMemPktIn_s;

	typedef struct packed {
		logic   [TRC_RAM_DATA_WIDTH-1:0] mem_rd_data;
	} SinkMemPktOut_s;

	logic [NUM_CORES-1:0]                            Core_fuse_enable_Dst, Core_fuse_enable_Ntrace;

	logic [NUM_DST_INST_SAFE-1:0]    dst_inst_fuse_enable;
	logic [NUM_NTRACE_INST_SAFE-1:0] ntr_inst_fuse_enable;

	assign dst_inst_fuse_enable = {NUM_DST_INST_SAFE{~dst_sink_gated_func_clamp}}    & ~dst_gated_func_clamp;
	assign ntr_inst_fuse_enable = {NUM_NTRACE_INST_SAFE{~ntr_sink_gated_func_clamp}} & ~ntr_gated_func_clamp;

	assign Core_fuse_enable_Dst    = (NUM_DST_INST    > 0) ? NUM_CORES'(dst_inst_fuse_enable) : '0;
	assign Core_fuse_enable_Ntrace = (NUM_NTRACE_INST > 0) ? NUM_CORES'(ntr_inst_fuse_enable) : '0;

	SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0]    		 funnel_mem_SinkMemPktIn_ANY;
	SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0]    	     mem_funnel_SinkMemPktOut_ANY;

	logic [NUM_CORES-1:0]                            TN_MS_Gnt_int;
	logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Bp_int;
	logic [NUM_CORES-1:0]                            TN_MS_Dst_Bp_int;
	logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Flush_int;
	logic [NUM_CORES-1:0]                            TN_MS_Dst_Flush_int;
	NtrSinkMmrsWr_s                                  NtrSinkMmrsWr_int;
	DstSinkMmrsWr_s                                  DstSinkMmrsWr_int;
	FunnelMmrsWr_s                                   FunnelMmrsWr_int;

	trace_top #(
		.NUM_CORES(NUM_CORES),
		.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
		.DATA_WIDTH(DATA_WIDTH),
		.TRC_RAM_INDEX(TRC_RAM_INDEX),
		.TRC_SIZE(TRC_SIZE),
		.BASE_ADDR(TRC_BASE_ADDR),
		.AXI_ADDR_WIDTH(TRC_AXI_ADDR_WIDTH),
		.AXI_DATA_WIDTH(TRC_AXI_DATA_WIDTH),
		.AXI_ID_WIDTH(TRC_AXI_ID_WIDTH),
		.axi_req_t(m_trc_axi_req_t),
		.axi_rsp_t(m_trc_axi_rsp_t),
		.SinkMemPktIn_s(SinkMemPktIn_s),
		.SinkMemPktOut_s(SinkMemPktOut_s)
	) trace_inst (
		.clk(funnel_gated_clock),
		.reset_n(funnel_gated_reset_n),
		.i_vid_map(i_vid_map),
		.i_func_clamp(funnel_gated_func_clamp),
		.Core_fuse_enable_Dst(Core_fuse_enable_Dst),
		.Core_fuse_enable_Ntrace(Core_fuse_enable_Ntrace),
		.NtrSinkMmrs(NtrSinkMmrs),
		.NtrSinkMmrsWr(NtrSinkMmrsWr_int),
		.DstSinkMmrs(DstSinkMmrs),
		.DstSinkMmrsWr(DstSinkMmrsWr_int),
		.FunnelMmrs(FunnelMmrs),
		.FunnelMmrsWr(FunnelMmrsWr_int),
		.TN_MS_Gnt(TN_MS_Gnt_int),
		.TN_MS_Ntrace_Bp(TN_MS_Ntrace_Bp_int),
		.TN_MS_Dst_Bp(TN_MS_Dst_Bp_int),
		.TN_MS_Ntrace_Flush(TN_MS_Ntrace_Flush_int),
		.TN_MS_Dst_Flush(TN_MS_Dst_Flush_int),
		.tnif_tr_valid(tnif_tr_valid),
		.tnif_tr_src(tnif_tr_src),
		.tnif_tr_data(tnif_tr_data),
		.trc_axi_req(m_trc_axi_req_int),
		.trc_axi_rsp(m_trc_axi_rsp),
		.trRamDataRdEn(trRamDataRdEn),
		.trdstRamDataRdEn(trdstRamDataRdEn),
		.funnel_mem_SinkMemPktIn_ANY(funnel_mem_SinkMemPktIn_ANY),
		.mem_funnel_SinkMemPktOut_ANY(mem_funnel_SinkMemPktOut_ANY),
		.TraceRamWrEn(TraceRamWrEn)
	);

	trace_mem #(

		.TRC_RAM_INDEX_WIDTH(TRC_RAM_INDEX_WIDTH),
		.TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
		.SinkMemPktIn_s(SinkMemPktIn_s),
		.SinkMemPktOut_s(SinkMemPktOut_s)
	) trace_mem_inst (
		.clk(funnel_gated_clock),
		.reset_n(funnel_gated_reset_n),
		.i_mem_tsel_settings(i_mem_tsel_settings),
		.funnel_mem_SinkMemPktIn_ANY(funnel_mem_SinkMemPktIn_ANY),
		.mem_funnel_SinkMemPktOut_ANY(mem_funnel_SinkMemPktOut_ANY)
	);

	assign tr_tnif_gnt     = (dst_sink_gated_func_clamp && ntr_sink_gated_func_clamp) ? '0         : TN_MS_Gnt_int ;
	assign tr_tnif_ntr_bp     = ntr_sink_gated_func_clamp 		? '0         : TN_MS_Ntrace_Bp_int;
	assign tr_tnif_dst_bp     = dst_sink_gated_func_clamp 		? '0         : TN_MS_Dst_Bp_int;
	assign tr_tnif_ntr_flush  = ntr_sink_gated_func_clamp 		? '0         : TN_MS_Ntrace_Flush_int;
	assign tr_tnif_dst_flush  = dst_sink_gated_func_clamp 		? '0         : TN_MS_Dst_Flush_int;
	assign NtrSinkMmrsWr      = ntr_sink_gated_func_clamp 		? '0         : NtrSinkMmrsWr_int;
	assign DstSinkMmrsWr      = dst_sink_gated_func_clamp 		? '0         : DstSinkMmrsWr_int;
	assign FunnelMmrsWr       = funnel_gated_func_clamp 		? '0         : FunnelMmrsWr_int;
	assign m_trc_axi_req    = funnel_gated_func_clamp 		? '0         : m_trc_axi_req_int;

endmodule
