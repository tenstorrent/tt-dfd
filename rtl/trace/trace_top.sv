// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module trace_top
import tn_pkg::*;
import ntr_sink_mmr_pkg::*;
import dst_sink_mmr_pkg::*;
import funnel_mmr_pkg::*;

#(
	parameter NUM_CORES = 8,
	parameter NUM_CORES_WIDTH = (NUM_CORES == 1) ? 1 : $clog2(NUM_CORES),
	localparam NUM_CORES_IN_NORTH_PATH = (NUM_CORES + 1) >> 1,
	localparam NUM_CORES_IN_SOUTH_PATH = (NUM_CORES >> 1) == 0 ? 1 : NUM_CORES >> 1,
	parameter DATA_WIDTH_IN_BYTES = 16,
	parameter DATA_WIDTH = DATA_WIDTH_IN_BYTES*8,
	parameter TRC_RAM_INDEX = 512,
	parameter TRC_SIZE = 32 * 1024 * 8,
	parameter BASE_ADDR = 0,
	parameter AXI_ADDR_WIDTH = 12,
	parameter AXI_DATA_WIDTH = 32,
	parameter AXI_ID_WIDTH = 4,
	type axi_req_t = logic,
	type axi_rsp_t = logic,
	type SinkMemPktIn_s = logic,
	type SinkMemPktOut_s = logic
) (
	input  logic                                            clk,
	input  logic                                            reset_n,

	input  logic [NUM_CORES-1:0] [NUM_CORES_WIDTH-1:0]     i_vid_map,
	input  logic                                            i_func_clamp,

	input  logic [NUM_CORES-1:0]                            Core_fuse_enable_Dst,
	input  logic [NUM_CORES-1:0]                            Core_fuse_enable_Ntrace,

	input  NtrSinkMmrs_s                                    NtrSinkMmrs,
	output NtrSinkMmrsWr_s                                  NtrSinkMmrsWr,

	input  DstSinkMmrs_s                                    DstSinkMmrs,
	output DstSinkMmrsWr_s                                  DstSinkMmrsWr,

	input  FunnelMmrs_s                                     FunnelMmrs,
	output FunnelMmrsWr_s                                   FunnelMmrsWr,

	output logic [NUM_CORES-1:0]                            TN_MS_Gnt,
	output logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Bp,
	output logic [NUM_CORES-1:0]                            TN_MS_Dst_Bp,
	output logic [NUM_CORES-1:0]                            TN_MS_Ntrace_Flush,
	output logic [NUM_CORES-1:0]                            TN_MS_Dst_Flush,
	input  logic [NUM_CORES-1:0]                            tnif_tr_valid,
	input  logic [NUM_CORES-1:0]                            tnif_tr_src,
	input  logic [NUM_CORES-1:0] [DATA_WIDTH-1:0]           tnif_tr_data,

	output axi_req_t                                    trc_axi_req,
	input  axi_rsp_t                                    trc_axi_rsp,

	output logic                                            TraceRamWrEn,
	input  logic                                            trRamDataRdEn,
	input  logic                                            trdstRamDataRdEn,

	output SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0]          funnel_mem_SinkMemPktIn_ANY,
	input  SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0]          mem_funnel_SinkMemPktOut_ANY
);

	logic [NUM_CORES_IN_NORTH_PATH-1:0]              TN_TR_North_Vld;
	logic                                            TN_TR_North_Src;
	logic [DATA_WIDTH-1:0]                           TN_TR_North_Data;

	logic [NUM_CORES_IN_SOUTH_PATH-1:0]              TN_TR_South_Vld;
	logic                                            TN_TR_South_Src;
	logic [DATA_WIDTH-1:0]                           TN_TR_South_Data;

	logic                                            TN_TR_Ntrace_Bp;
	logic                                            TN_TR_Dst_Bp;
	logic                                            TN_TR_Ntrace_Flush;
	logic                                            TN_TR_Dst_Flush;

	logic [NUM_CORES-1:0]                            MS_TN_Vld_Internal_Active_Cores;
	logic [NUM_CORES-1:0]                            MS_TN_Src_Internal_Active_Cores;
	logic [NUM_CORES-1:0] [DATA_WIDTH-1:0]           MS_TN_Data_Internal_Active_Cores;

	logic [NUM_CORES-1:0]                            TN_TR_Enabled_Srcs;

	always_comb begin
		MS_TN_Vld_Internal_Active_Cores = '0;
		MS_TN_Src_Internal_Active_Cores = '0;
		MS_TN_Data_Internal_Active_Cores = '0;

		for (int i=0; i<NUM_CORES; i++) begin
			MS_TN_Vld_Internal_Active_Cores[i] = tnif_tr_valid[i];
			MS_TN_Src_Internal_Active_Cores[i] = tnif_tr_src[i];
			MS_TN_Data_Internal_Active_Cores[i] = tnif_tr_data[i];
		end
	end

	trace_network #(
		.NUM_CORES(NUM_CORES),
		.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
		.DATA_WIDTH(DATA_WIDTH)
	) trace_network_inst (
		.clk(clk),
		.reset_n(reset_n),
		.TN_MS_Gnt(TN_MS_Gnt),
		.TN_MS_Ntrace_Bp(TN_MS_Ntrace_Bp),
		.TN_MS_Dst_Bp(TN_MS_Dst_Bp),
		.TN_MS_Ntrace_Flush(TN_MS_Ntrace_Flush),
		.TN_MS_Dst_Flush(TN_MS_Dst_Flush),
		.MS_TN_Vld(MS_TN_Vld_Internal_Active_Cores),
		.MS_TN_Src(MS_TN_Src_Internal_Active_Cores),
		.MS_TN_Data(MS_TN_Data_Internal_Active_Cores),
		.TN_TR_North_Vld(TN_TR_North_Vld),
		.TN_TR_North_Src(TN_TR_North_Src),
		.TN_TR_North_Data(TN_TR_North_Data),
		.TN_TR_South_Vld(TN_TR_South_Vld),
		.TN_TR_South_Src(TN_TR_South_Src),
		.TN_TR_South_Data(TN_TR_South_Data),
		.TN_TR_Ntrace_Bp(TN_TR_Ntrace_Bp),
		.TN_TR_Dst_Bp(TN_TR_Dst_Bp),
		.TN_TR_Ntrace_Flush(TN_TR_Ntrace_Flush),
		.TN_TR_Dst_Flush(TN_TR_Dst_Flush),
		.TN_TR_Enabled_Srcs(TN_TR_Enabled_Srcs)
	);

	trace_funnel #(
		.NUM_CORES(NUM_CORES),
		.TRC_RAM_INDEX(TRC_RAM_INDEX),
		.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
		.TRC_SIZE(TRC_SIZE),
		.SinkMemPktIn_s(SinkMemPktIn_s),
		.SinkMemPktOut_s(SinkMemPktOut_s),
		.DATA_WIDTH(DATA_WIDTH),
		.BASE_ADDR(BASE_ADDR),
		.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
		.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
		.AXI_ID_WIDTH(AXI_ID_WIDTH),
		.axi_req_t(axi_req_t),
		.axi_rsp_t(axi_rsp_t)
	) trace_funnel_inst (
		.clk(clk),
		.clk_mmr(clk),
		.reset_n(reset_n),
		.i_vid_map(i_vid_map),
		.i_func_clamp(i_func_clamp),
		.NtrSinkMmrs(NtrSinkMmrs),
		.NtrSinkMmrsWr(NtrSinkMmrsWr),
		.DstSinkMmrs(DstSinkMmrs),
		.DstSinkMmrsWr(DstSinkMmrsWr),
		.FunnelMmrs(FunnelMmrs),
		.FunnelMmrsWr(FunnelMmrsWr),
		.TN_TR_Enabled_Srcs(TN_TR_Enabled_Srcs),
		.TN_TR_North_Vld(TN_TR_North_Vld),
		.TN_TR_North_Src(TN_TR_North_Src),
		.TN_TR_North_Data(TN_TR_North_Data),
		.TN_TR_South_Vld(TN_TR_South_Vld),
		.TN_TR_South_Src(TN_TR_South_Src),
		.TN_TR_South_Data(TN_TR_South_Data),
		.TN_TR_Ntrace_Bp(TN_TR_Ntrace_Bp),
		.TN_TR_Dst_Bp(TN_TR_Dst_Bp),
		.TN_TR_Ntrace_Flush(TN_TR_Ntrace_Flush),
		.TN_TR_Dst_Flush(TN_TR_Dst_Flush),
		.Core_fuse_enable_Dst(Core_fuse_enable_Dst),
		.Core_fuse_enable_Ntrace(Core_fuse_enable_Ntrace),
		.TS_TR_SlvReq(trc_axi_req),
		.TR_TS_SlvResp(trc_axi_rsp),
		.trRamDataRdEn(trRamDataRdEn),
		.trdstRamDataRdEn(trdstRamDataRdEn),
		.funnel_mem_SinkMemPktIn_ANY(funnel_mem_SinkMemPktIn_ANY),
		.mem_funnel_SinkMemPktOut_ANY(mem_funnel_SinkMemPktOut_ANY),
		.TraceRamWrEn(TraceRamWrEn)
	);

endmodule
