// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module trace_funnel
  import tn_pkg::*;
  import funnel_mmr_pkg::*;
  import dst_sink_mmr_pkg::*;
  import ntr_sink_mmr_pkg::*;

#(
  parameter NUM_CORES = 8,
  localparam NUM_CORES_IN_NORTH_PATH = (NUM_CORES + 1) >> 1,
  localparam NUM_CORES_IN_SOUTH_PATH = (NUM_CORES >> 1) == 0 ? 1 : NUM_CORES >> 1,
  parameter TRC_RAM_INDEX = 512,
  parameter TRC_SIZE = 32 * 1024 * 8,
  type SinkMemPktIn_s = logic,
  type SinkMemPktOut_s = logic,
  parameter DATA_WIDTH_IN_BYTES = 16,
  parameter ADDR_WIDTH = 12,
  parameter BASE_ADDR = 0,
  parameter DATA_WIDTH = DATA_WIDTH_IN_BYTES*8,
  parameter AXI_ADDR_WIDTH = 12,
  parameter AXI_DATA_WIDTH = 32,
  parameter AXI_ID_WIDTH = 4,
  type axi_req_t = logic,
  type axi_rsp_t = logic,
  parameter NUM_CORES_WIDTH = (NUM_CORES == 1) ? 1 : $clog2(NUM_CORES),
  localparam MAX_NUM_CORES = 8
) (
  input  logic                                            clk,
  input  logic                                            clk_mmr,
  input  logic                                            reset_n,
  input  logic                                            i_func_clamp,
  input  logic [NUM_CORES-1:0]                            Core_fuse_enable_Dst,
  input  logic [NUM_CORES-1:0]                            Core_fuse_enable_Ntrace,

  input NtrSinkMmrs_s 											                    NtrSinkMmrs,
  output NtrSinkMmrsWr_s 										                  NtrSinkMmrsWr,

  input DstSinkMmrs_s 											                    DstSinkMmrs,
  output DstSinkMmrsWr_s 										                  DstSinkMmrsWr,

  input FunnelMmrs_s 											                    FunnelMmrs,
  output FunnelMmrsWr_s 										                  FunnelMmrsWr,

  input  logic [NUM_CORES-1:0] [NUM_CORES_WIDTH-1:0]      i_vid_map,

  input  logic [NUM_CORES_IN_NORTH_PATH-1:0]              TN_TR_North_Vld,
  input  logic                                            TN_TR_North_Src,
  input  logic [DATA_WIDTH-1:0]                           TN_TR_North_Data,

  input  logic [NUM_CORES_IN_SOUTH_PATH-1:0]              TN_TR_South_Vld,
  input  logic                                            TN_TR_South_Src,
  input  logic [DATA_WIDTH-1:0]                           TN_TR_South_Data,

  output logic                                            TN_TR_Ntrace_Bp,TN_TR_Dst_Bp,
  output logic                                            TN_TR_Ntrace_Flush,TN_TR_Dst_Flush,

  output axi_req_t                                    TS_TR_SlvReq,
  input  axi_rsp_t                                    TR_TS_SlvResp,

  output logic [NUM_CORES-1:0]                            TN_TR_Enabled_Srcs,

  output logic                                            TraceRamWrEn,
  input logic                                             trRamDataRdEn,
  input logic                                             trdstRamDataRdEn,

  output SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0]          funnel_mem_SinkMemPktIn_ANY,
  input  SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0]          mem_funnel_SinkMemPktOut_ANY
);

  logic [$clog2(MAX_NUM_CORES):0]           TR_TS_Ntrace_NumEnabled_Srcs, TR_TS_Ntrace_NumEnabled_Srcs_stg;
  logic [$clog2(MAX_NUM_CORES):0]           TR_TS_Dst_NumEnabled_Srcs, TR_TS_Dst_NumEnabled_Srcs_stg;
  logic                                     TR_TS_Dst_SrcEnabled_i_ANY, TR_TS_Ntrace_SrcEnabled_i_ANY;
  logic                                     TraceRamWrEn_TS0;

  logic                                     TrMemAxiWrVld_ANY;
  logic [AXI_ADDR_WIDTH-1:0]            TrMemAxiWrAddr_ANY;
  logic [AXI_DATA_WIDTH-1:0]            TrMemAxiWrData_ANY;
  logic                                     TrMemAxiWrRdy_ANY;

  logic [NUM_CORES-1:0]                     TN_TR_Enabled_Srcs_stg;

  logic [NUM_CORES-1:0]                     Trfunnel_enable_input_ntrace_Pid_vector, Trfunnel_enable_input_dst_Pid_vector;
  logic [15:0]                              Trfunneldisinput_Pid_vector, Trfunneldisinput_Pid_vector_stg;

  trace_sink #(
    .NUM_CORES(NUM_CORES),
    .TRC_SIZE(TRC_SIZE),
    .SinkMemPktIn_s(SinkMemPktIn_s),
    .SinkMemPktOut_s(SinkMemPktOut_s),
    .TRC_RAM_INDEX(TRC_RAM_INDEX),
    .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) trace_sink0 (
    .clk                                      (clk),
    .reset_n                                  (reset_n),

    .TR_TS_North_Src                          (TN_TR_North_Src),
    .TR_TS_North_Data                         (TN_TR_North_Data),
    .TR_TS_North_Vld                          (TN_TR_North_Vld),

    .TR_TS_Ntrace_NumEnabled_Srcs             (TR_TS_Ntrace_NumEnabled_Srcs),
    .TR_TS_Dst_NumEnabled_Srcs                (TR_TS_Dst_NumEnabled_Srcs),

    .TR_TS_South_Src                          (TN_TR_South_Src),
    .TR_TS_South_Data                         (TN_TR_South_Data),
    .TR_TS_South_Vld                          (TN_TR_South_Vld),

    .TS_TR_Ntrace_Bp                          (TN_TR_Ntrace_Bp),
    .TS_TR_Dst_Bp                             (TN_TR_Dst_Bp),
    .TS_TR_Ntrace_Flush                       (TN_TR_Ntrace_Flush),
    .TS_TR_Dst_Flush                          (TN_TR_Dst_Flush),

    .Trramcontrol                        (NtrSinkMmrs.Trramcontrol),
    .Trramimpl                           (NtrSinkMmrs.Trramimpl),
    .Trramstartlow                       (NtrSinkMmrs.Trramstartlow),
    .Trramstarthigh                      (NtrSinkMmrs.Trramstarthigh),
    .Trramlimitlow                       (NtrSinkMmrs.Trramlimitlow),
    .Trramlimithigh                      (NtrSinkMmrs.Trramlimithigh),
    .Trramwplow                          (NtrSinkMmrs.Trramwplow),
    .Trramwphigh                         (NtrSinkMmrs.Trramwphigh),
    .Trramrplow                          (NtrSinkMmrs.Trramrplow),
    .trRamDataRdEn_ANY                        (trRamDataRdEn),

    .TrramcontrolWr                      (NtrSinkMmrsWr.TrramcontrolWr),
    .TrramwplowWr                        (NtrSinkMmrsWr.TrramwplowWr),
    .TrramwphighWr                       (NtrSinkMmrsWr.TrramwphighWr),
    .TrramrplowWr                        (NtrSinkMmrsWr.TrramrplowWr),
    .TrramrphighWr                       (NtrSinkMmrsWr.TrramrphighWr),
    .TrramdataWr                         (NtrSinkMmrsWr.TrramdataWr),

    .Trcustomramsmemlimitlow             (NtrSinkMmrs.Trcustomramsmemlimitlow),

    .Trdstramcontrol                     (DstSinkMmrs.Trdstramcontrol),
    .Trdstramimpl                        (DstSinkMmrs.Trdstramimpl),
    .Trdstramstartlow                    (DstSinkMmrs.Trdstramstartlow),
    .Trdstramstarthigh                   (DstSinkMmrs.Trdstramstarthigh),
    .Trdstramlimitlow                    (DstSinkMmrs.Trdstramlimitlow),
    .Trdstramlimithigh                   (DstSinkMmrs.Trdstramlimithigh),
    .Trdstramwplow                       (DstSinkMmrs.Trdstramwplow),
    .Trdstramwphigh                      (DstSinkMmrs.Trdstramwphigh),
    .Trdstramrplow                       (DstSinkMmrs.Trdstramrplow),
    .trdstRamDataRdEn_ANY                     (trdstRamDataRdEn),

    .TrdstramcontrolWr                   (DstSinkMmrsWr.TrdstramcontrolWr),
    .TrdstramwplowWr                     (DstSinkMmrsWr.TrdstramwplowWr),
    .TrdstramwphighWr                    (DstSinkMmrsWr.TrdstramwphighWr),
    .TrdstramrplowWr                     (DstSinkMmrsWr.TrdstramrplowWr),
    .TrdstramrphighWr                    (DstSinkMmrsWr.TrdstramrphighWr),
    .TrdstramdataWr                      (DstSinkMmrsWr.TrdstramdataWr),

    .TraceRamWrEn_TS0                         (TraceRamWrEn_TS0),

    .TrMemAxiWrVld_ANY                        (TrMemAxiWrVld_ANY),
    .TrMemAxiWrAddr_ANY                       (TrMemAxiWrAddr_ANY),
    .TrMemAxiWrData_ANY                       (TrMemAxiWrData_ANY),
    .TrMemAxiWrRdy_ANY                        (TrMemAxiWrRdy_ANY),

    .SinkMemPktIn                             (funnel_mem_SinkMemPktIn_ANY),
    .SinkMemPktOut                            (mem_funnel_SinkMemPktOut_ANY)
  );

  assign TraceRamWrEn = |TraceRamWrEn_TS0;

  generic_vidtopid #(.NumHarts(NUM_CORES)) i_vidtopid_ntrace_disinput (
    .fuse_map(Core_fuse_enable_Ntrace),
    .vid_map(i_vid_map[NUM_CORES-1:0]),
    .vid('0),
    .vid_vector(~FunnelMmrs.Trfunneldisinput.Trfunneldisinput[(NUM_CORES-1):0]),
    .pid(),
    .pid_vector(Trfunnel_enable_input_ntrace_Pid_vector),
    .map_avail()
  );

  generic_vidtopid #(.NumHarts(NUM_CORES)) i_vidtopid_dst_disinput (
    .fuse_map(Core_fuse_enable_Dst),
    .vid_map(i_vid_map[NUM_CORES-1:0]),
    .vid('0),
    .vid_vector(~FunnelMmrs.Trfunneldisinput.Trfunneldisinput[(NUM_CORES+7):8]),
    .pid(),
    .pid_vector(Trfunnel_enable_input_dst_Pid_vector),
    .map_avail()
  );

  generic_dff #(
      .WIDTH       ($bits(logic [NUM_CORES-1:0])),
      .RESET_VALUE ('0)
  ) TN_TR_Enabled_Srcs_ff (
      .clk   (clk),
      .rst_n (reset_n),
      .en    ('1),
      .in    (TN_TR_Enabled_Srcs_stg),
      .out   (TN_TR_Enabled_Srcs)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [15:0])),
      .RESET_VALUE ('0)
  ) Trfunneldisinput_Pid_vector_ff (
      .clk   (clk),
      .rst_n (reset_n),
      .en    ('1),
      .in    (Trfunneldisinput_Pid_vector_stg),
      .out   (Trfunneldisinput_Pid_vector)
  );

  assign TN_TR_Enabled_Srcs_stg = {NUM_CORES{{~i_func_clamp}}} & (Trfunnel_enable_input_ntrace_Pid_vector | Trfunnel_enable_input_dst_Pid_vector);

  /* verilator lint_off WIDTHEXPAND */
  assign Trfunneldisinput_Pid_vector_stg = {MAX_NUM_CORES'(~Trfunnel_enable_input_dst_Pid_vector), MAX_NUM_CORES'(~Trfunnel_enable_input_ntrace_Pid_vector)};
  /* verilator lint_on WIDTHEXPAND */

  always_comb begin
    TR_TS_Ntrace_NumEnabled_Srcs_stg = '0;
    TR_TS_Dst_NumEnabled_Srcs_stg = '0;
    for (int i=0; i<NUM_CORES; i++) begin
      TR_TS_Dst_SrcEnabled_i_ANY = ~Trfunneldisinput_Pid_vector[i + MAX_NUM_CORES];
      TR_TS_Ntrace_SrcEnabled_i_ANY = ~Trfunneldisinput_Pid_vector[i];
      /* verilator lint_off WIDTHEXPAND */
      TR_TS_Ntrace_NumEnabled_Srcs_stg = $bits(TR_TS_Ntrace_NumEnabled_Srcs_stg)'(TR_TS_Ntrace_NumEnabled_Srcs_stg + $bits(TR_TS_Ntrace_NumEnabled_Srcs_stg)'(TR_TS_Ntrace_SrcEnabled_i_ANY));
      TR_TS_Dst_NumEnabled_Srcs_stg = $bits(TR_TS_Dst_NumEnabled_Srcs_stg)'(TR_TS_Dst_NumEnabled_Srcs_stg + $bits(TR_TS_Dst_NumEnabled_Srcs_stg)'(TR_TS_Dst_SrcEnabled_i_ANY));
      /* verilator lint_on WIDTHEXPAND */
    end
  end

  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(MAX_NUM_CORES)+1-1:0])),
      .RESET_VALUE ('0)
  ) TR_TS_Ntrace_NumEnabled_Srcs_ff (
      .clk   (clk),
      .rst_n (reset_n),
      .en    ('1),
      .in    (TR_TS_Ntrace_NumEnabled_Srcs_stg),
      .out   (TR_TS_Ntrace_NumEnabled_Srcs)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(MAX_NUM_CORES)+1-1:0])),
      .RESET_VALUE ('0)
  ) TR_TS_Dst_NumEnabled_Srcs_ff (
      .clk   (clk),
      .rst_n (reset_n),
      .en    ('1),
      .in    (TR_TS_Dst_NumEnabled_Srcs_stg),
      .out   (TR_TS_Dst_NumEnabled_Srcs)
  );

  always_comb begin
    FunnelMmrsWr.TrfunnelcontrolWr = '0;
  end

  trace_axi_master #(
      .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH   (AXI_ID_WIDTH),
      .axi_req_t      (axi_req_t),
      .axi_resp_t     (axi_rsp_t)
  ) trace_smem_axi_master (
    .clk_i                                    (clk),
    .rst_ni                                   (reset_n),
    .id_i                                     ('0),
    .axi_req_o                                (TS_TR_SlvReq),
    .axi_resp_i                               (TR_TS_SlvResp),
    .ready_o                                  (TrMemAxiWrRdy_ANY),
    .valid_i                                  (TrMemAxiWrVld_ANY),
    .addr_i                                   (TrMemAxiWrAddr_ANY),
    .data_i                                   (TrMemAxiWrData_ANY)
  );

  always_comb begin

   FunnelMmrsWr.TrfunneldisinputWr   = '0;

   NtrSinkMmrsWr.TrramstartlowWr      = '0;
   NtrSinkMmrsWr.TrramstarthighWr     = '0;
   NtrSinkMmrsWr.TrramlimitlowWr      = '0;
   NtrSinkMmrsWr.TrramlimithighWr     = '0;

   DstSinkMmrsWr.TrdstramstartlowWr   = '0;
   DstSinkMmrsWr.TrdstramstarthighWr  = '0;
   DstSinkMmrsWr.TrdstramlimitlowWr   = '0;
   DstSinkMmrsWr.TrdstramlimithighWr  = '0;
  end

endmodule
