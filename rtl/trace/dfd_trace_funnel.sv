// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Trace Funnel - Gets the data from the trace hop and sinks it to Trace RAM or Memory

module dfd_trace_funnel
  import dfd_tn_pkg::*;
  import dfd_tr_csr_pkg::*;
  import dfd_CL_axi_pkg::*;
#(
  parameter NUM_CORES = 8,
  localparam NUM_CORES_IN_PATH = NUM_CORES>>1,
  parameter TRC_RAM_INDEX = 512,
  type SinkMemPktIn_s = logic,
  type SinkMemPktOut_s = logic,
  parameter DATA_WIDTH_IN_BYTES = 16,
  parameter BASE_ADDR = 0,
  parameter DATA_WIDTH = DATA_WIDTH_IN_BYTES*8,
  parameter NUM_CORES_WIDTH = (NUM_CORES == 1) ? 1 : $clog2(NUM_CORES)
) (
  input  logic                                            clk,
  input  logic                                            clk_mmr,
  input  logic                                            reset_n,
  // input  logic                                            cold_reset_n,

  // DFD Trace MMRs
  input TrCsrs_s 											                    TrCsrs,
  output TrCsrsWr_s 										                  TrCsrsWr,

  // Clock gate controls
  output logic                                            trfunnelactive,
  output logic                                            trfunnelfuse,
  output logic                                            trfunnelfuselock,

  // North branch data interface
  input  logic [NUM_CORES_IN_PATH-1:0]                    TN_TR_North_Vld,
  input  logic                                            TN_TR_North_Src,
  input  logic [DATA_WIDTH-1:0]                           TN_TR_North_Data,

  // South branch data interface
  input  logic [NUM_CORES_IN_PATH-1:0]                    TN_TR_South_Vld,
  input  logic                                            TN_TR_South_Src,
  input  logic [DATA_WIDTH-1:0]                           TN_TR_South_Data,

  // Funnel interface for the Backpressure
  output logic                                            TN_TR_Ntrace_Bp,TN_TR_Dst_Bp,
  output logic                                            TN_TR_Ntrace_Flush,TN_TR_Dst_Flush,
  output logic [NUM_CORES-1:0]                            TN_TR_Enabled_Srcs,

  // AXI Interface the Memory
  output dfd_tr_slv_axi_req_t                                 TS_TR_SlvReq,
  input  dfd_tr_slv_axi_rsp_t                                 TR_TS_SlvResp,

  // JTAG-MMR Control Interface
  input  logic                                            jt_tr_mmr_req_vld_o,
  input  logic                                            jt_tr_mmr_req_we_o,
  input  logic [DfdAxiAddrWidth-1:0]                       jt_tr_mmr_req_addr_o,
  input  logic [31:0]                                     jt_tr_mmr_req_data_o,
  output logic [DfdAxiDataWidth-1:0]                       tr_jt_mmr_rsp_data_i,
  output logic                                            tr_jt_mmr_rsp_vld_i,

  // Trace Sink Memory Interface
  output SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0]          funnel_mem_SinkMemPktIn_ANY,
  input  SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0]          mem_funnel_SinkMemPktOut_ANY
);

  // --------------------------------------------------------------------------
  // Internal Signals
  // --------------------------------------------------------------------------

  logic [$clog2(8):0]                       TR_TS_Ntrace_NumEnabled_Srcs, TR_TS_Ntrace_NumEnabled_Srcs_stg;
  logic [$clog2(8):0]                       TR_TS_Dst_NumEnabled_Srcs, TR_TS_Dst_NumEnabled_Srcs_stg;
  logic                                     trRamDataRdEn_ANY;
  logic                                     trdstRamDataRdEn_ANY;
  logic                                     CsrCs;
  logic                                     CsrWrEn;
  logic [1:0]                               CsrWrStrb;
  logic                                     CsrRegSel;
  logic [22:0]                              CsrAddr;
  logic [31:0]                              CsrWrData;
  logic [1:0]                               CsrWrInstrType;
  logic                                     CsrWrReady;
  logic                                     CsrHit;
  logic [31:0]                              CsrRdData;
  logic                                     slave_read_ready;
  logic                                     slave_busy;
  logic                                     NxtCsrCs;
  logic                                     CsrCs_d1;
  logic                                     CsrCs_d2;
  logic                                     CsrCs_d3;
  logic                                     TraceRamWrEn_TS0;

  logic                                     TrMemAxiWrVld_ANY; 
  logic [DfdTrAxiAddrWidth-1:0]                TrMemAxiWrAddr_ANY;
  logic [DfdTrAxiDataWidth-1:0]                TrMemAxiWrData_ANY;
  logic                                     TrMemAxiWrRdy_ANY; 
  
  logic                                     tr_jt_mmr_wr_rsp_vld;
  logic                                     jt_tr_mmr_rd_req_pend;
  logic                                     jt_tr_eff_mmr_req_vld_with_fuse_chk;

  logic [8-1:0][NUM_CORES_WIDTH-1:0]        Core_fuse_vid_map_vector; 
  logic [8-1:0]                             Core_fuse_enable_map_vector;

  logic [NUM_CORES-1:0]                     TN_TR_Enabled_Srcs_stg;

  logic [NUM_CORES-1:0]                     Trfunnel_enable_input_ntrace_Pid_vector, Trfunnel_enable_input_dst_Pid_vector;
  logic [15:0]                              Trfunneldisinput_Pid_vector, Trfunneldisinput_Pid_vector_stg;

  logic                                     Trfusedisabled, trfunnelntracefuse, trfunneldstfuse;

  // --------------------------------------------------------------------------
  // Trace Sink
  // --------------------------------------------------------------------------
  dfd_trace_sink #(
    .NUM_CORES(NUM_CORES),
    .SinkMemPktIn_s(SinkMemPktIn_s),
    .SinkMemPktOut_s(SinkMemPktOut_s),
    .TRC_RAM_INDEX(TRC_RAM_INDEX),
    .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
    .AXI_ADDR_WIDTH(DfdTrAxiAddrWidth),
    .AXI_DATA_WIDTH(DfdTrAxiDataWidth)
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

    .TrCsrTrramcontrol                        (TrCsrs.TrCsrTrramcontrol),
    .TrCsrTrramimpl                           (TrCsrs.TrCsrTrramimpl),
    .TrCsrTrramstartlow                       (TrCsrs.TrCsrTrramstartlow),
    .TrCsrTrramstarthigh                      (TrCsrs.TrCsrTrramstarthigh),
    .TrCsrTrramlimitlow                       (TrCsrs.TrCsrTrramlimitlow),
    .TrCsrTrramlimithigh                      (TrCsrs.TrCsrTrramlimithigh),
    .TrCsrTrramwplow                          (TrCsrs.TrCsrTrramwplow),
    .TrCsrTrramwphigh                         (TrCsrs.TrCsrTrramwphigh),
    .TrCsrTrramrplow                          (TrCsrs.TrCsrTrramrplow),
    .trRamDataRdEn_ANY                        (trRamDataRdEn_ANY),

    .TrCsrTrramcontrolWr                      (TrCsrsWr.TrCsrTrramcontrolWr),
    .TrCsrTrramwplowWr                        (TrCsrsWr.TrCsrTrramwplowWr),
    .TrCsrTrramwphighWr                       (TrCsrsWr.TrCsrTrramwphighWr),
    .TrCsrTrramrplowWr                        (TrCsrsWr.TrCsrTrramrplowWr),
    .TrCsrTrramrphighWr                       (TrCsrsWr.TrCsrTrramrphighWr),
    .TrCsrTrramdataWr                         (TrCsrsWr.TrCsrTrramdataWr),

    .TrCsrTrcustomramsmemlimitlow             (TrCsrs.TrCsrTrcustomramsmemlimitlow),

    .TrCsrTrdstramcontrol                     (TrCsrs.TrCsrTrdstramcontrol),
    .TrCsrTrdstramimpl                        (TrCsrs.TrCsrTrdstramimpl),
    .TrCsrTrdstramstartlow                    (TrCsrs.TrCsrTrdstramstartlow),
    .TrCsrTrdstramstarthigh                   (TrCsrs.TrCsrTrdstramstarthigh),
    .TrCsrTrdstramlimitlow                    (TrCsrs.TrCsrTrdstramlimitlow),
    .TrCsrTrdstramlimithigh                   (TrCsrs.TrCsrTrdstramlimithigh),
    .TrCsrTrdstramwplow                       (TrCsrs.TrCsrTrdstramwplow),
    .TrCsrTrdstramwphigh                      (TrCsrs.TrCsrTrdstramwphigh),
    .TrCsrTrdstramrplow                       (TrCsrs.TrCsrTrdstramrplow),
    .trdstRamDataRdEn_ANY                     (trdstRamDataRdEn_ANY),

    .TrCsrTrdstramcontrolWr                   (TrCsrsWr.TrCsrTrdstramcontrolWr),
    .TrCsrTrdstramwplowWr                     (TrCsrsWr.TrCsrTrdstramwplowWr),
    .TrCsrTrdstramwphighWr                    (TrCsrsWr.TrCsrTrdstramwphighWr),
    .TrCsrTrdstramrplowWr                     (TrCsrsWr.TrCsrTrdstramrplowWr),
    .TrCsrTrdstramrphighWr                    (TrCsrsWr.TrCsrTrdstramrphighWr),
    .TrCsrTrdstramdataWr                      (TrCsrsWr.TrCsrTrdstramdataWr),

    .TraceRamWrEn_TS0                         (TraceRamWrEn_TS0),

    .TrMemAxiWrVld_ANY                        (TrMemAxiWrVld_ANY),
    .TrMemAxiWrAddr_ANY                       (TrMemAxiWrAddr_ANY),
    .TrMemAxiWrData_ANY                       (TrMemAxiWrData_ANY),
    .TrMemAxiWrRdy_ANY                        (TrMemAxiWrRdy_ANY),

    .SinkMemPktIn                             (funnel_mem_SinkMemPktIn_ANY),
    .SinkMemPktOut                            (mem_funnel_SinkMemPktOut_ANY)
  );

  // --------------------------------------------------------------------------
  // Trace Sink MMRs
  // --------------------------------------------------------------------------

  assign CsrRegSel = 1'b0;
  assign CsrWrInstrType = '0;

  assign jt_tr_eff_mmr_req_vld_with_fuse_chk = (jt_tr_mmr_req_vld_o & ~Trfusedisabled); 

  assign CsrCs      = jt_tr_eff_mmr_req_vld_with_fuse_chk;
  assign CsrWrEn    = jt_tr_eff_mmr_req_vld_with_fuse_chk & jt_tr_mmr_req_we_o;
  assign CsrWrStrb  = {1'b0,(jt_tr_eff_mmr_req_vld_with_fuse_chk & jt_tr_mmr_req_we_o)};
  assign CsrAddr    = jt_tr_mmr_req_addr_o;
  assign CsrWrData  = jt_tr_mmr_req_data_o;

  assign CsrRdData = '0;
  assign tr_jt_mmr_rsp_data_i = {32'b0, CsrRdData};
  assign tr_jt_mmr_rsp_vld_i = tr_jt_mmr_wr_rsp_vld | (jt_tr_mmr_rd_req_pend & CsrCs_d3);

  generic_dff_clr #(.WIDTH(1)) tr_jt_mmr_wr_rsp_vld_ff (
    .out(tr_jt_mmr_wr_rsp_vld), 
    .in(1'b1),
    .clr(tr_jt_mmr_wr_rsp_vld),
    .en(jt_tr_eff_mmr_req_vld_with_fuse_chk & jt_tr_mmr_req_we_o),
    .clk(clk_mmr),
    .rst_n(reset_n)
  );
  
  generic_dff_clr #(.WIDTH(1)) jt_tr_mmr_rd_req_pend_ff (
    .out          (jt_tr_mmr_rd_req_pend),
    .in          (1'b1),
    .clr        (tr_jt_mmr_rsp_vld_i),
    .en         (jt_tr_eff_mmr_req_vld_with_fuse_chk & ~jt_tr_mmr_req_we_o),
    .clk        (clk_mmr),
    .rst_n    (reset_n)
  );

  // --------------------------------------------------------------------------
  // Core Harvesting - Fuse Map
  // --------------------------------------------------------------------------
  always_comb begin
    Core_fuse_vid_map_vector[0]  = TrCsrs.TrCsrTrclusterfusecfglow.Core0Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[1]  = TrCsrs.TrCsrTrclusterfusecfglow.Core1Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[2]  = TrCsrs.TrCsrTrclusterfusecfglow.Core2Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[3]  = TrCsrs.TrCsrTrclusterfusecfglow.Core3Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[4]  = TrCsrs.TrCsrTrclusterfusecfghi.Core4Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[5]  = TrCsrs.TrCsrTrclusterfusecfghi.Core5Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[6]  = TrCsrs.TrCsrTrclusterfusecfghi.Core6Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_vid_map_vector[7]  = TrCsrs.TrCsrTrclusterfusecfghi.Core7Vid[NUM_CORES_WIDTH-1:0];
    Core_fuse_enable_map_vector[0] = TrCsrs.TrCsrTrclusterfusecfglow.Core0Enable;
    Core_fuse_enable_map_vector[1] = TrCsrs.TrCsrTrclusterfusecfglow.Core1Enable;
    Core_fuse_enable_map_vector[2] = TrCsrs.TrCsrTrclusterfusecfglow.Core2Enable;
    Core_fuse_enable_map_vector[3] = TrCsrs.TrCsrTrclusterfusecfglow.Core3Enable;
    Core_fuse_enable_map_vector[4] = TrCsrs.TrCsrTrclusterfusecfghi.Core4Enable;
    Core_fuse_enable_map_vector[5] = TrCsrs.TrCsrTrclusterfusecfghi.Core5Enable;
    Core_fuse_enable_map_vector[6] = TrCsrs.TrCsrTrclusterfusecfghi.Core6Enable;
    Core_fuse_enable_map_vector[7] = TrCsrs.TrCsrTrclusterfusecfghi.Core7Enable;
end

  generic_vidtopid #(.NumHarts(NUM_CORES)) i_vidtopid_ntrace_disinput (
    .fuse_map(Core_fuse_enable_map_vector[NUM_CORES-1:0]),
    .vid_map(Core_fuse_vid_map_vector[NUM_CORES-1:0]),
    .vid('0),
    .vid_vector(~TrCsrs.TrCsrTrfunneldisinput.Trfunneldisinput[(NUM_CORES-1):0]),
    .pid(),
    .pid_vector(Trfunnel_enable_input_ntrace_Pid_vector),
    .map_avail()
  );

  generic_vidtopid #(.NumHarts(NUM_CORES)) i_vidtopid_dst_disinput (
    .fuse_map(Core_fuse_enable_map_vector[NUM_CORES-1:0]),
    .vid_map(Core_fuse_vid_map_vector[NUM_CORES-1:0]),
    .vid('0),
    .vid_vector(~TrCsrs.TrCsrTrfunneldisinput.Trfunneldisinput[(NUM_CORES+7):8]),
    .pid(),
    .pid_vector(Trfunnel_enable_input_dst_Pid_vector),
    .map_avail()
  );

  assign trfunnelactive = TrCsrs.TrCsrTrfunnelcontrol.Trfunnelactive;
  assign trfunnelfuse = trfunnelntracefuse || trfunneldstfuse;
  assign trfunnelfuselock = TrCsrs.TrCsrTrclusterfusecfghi.Lock;

  assign trfunnelntracefuse = TrCsrs.TrCsrTrclusterfusecfghi.TraceEnable && TrCsrs.TrCsrTrclusterfusecfghi.Lock;
  assign trfunneldstfuse = TrCsrs.TrCsrTrclusterfusecfghi.DstEnable && TrCsrs.TrCsrTrclusterfusecfghi.Lock;

  generic_dff #(.WIDTH(NUM_CORES)) TN_TR_Enabled_Srcs_ff (
    .out          (TN_TR_Enabled_Srcs),
    .in          (TN_TR_Enabled_Srcs_stg),
    .en         (1'b1),
    .clk        (clk),
    .rst_n    (reset_n)
  ); 

  generic_dff #(.WIDTH(16)) Trfunneldisinput_Pid_vector_ff (
    .out          (Trfunneldisinput_Pid_vector),
    .in          (Trfunneldisinput_Pid_vector_stg),
    .en         (1'b1),
    .clk        (clk),
    .rst_n    (reset_n)
  ); 
  assign Trfusedisabled = ~trfunnelfuse & trfunnelfuselock; 
  assign TN_TR_Enabled_Srcs_stg = {NUM_CORES{TrCsrs.TrCsrTrfunnelcontrol.Trfunnelactive}} & (Trfunnel_enable_input_ntrace_Pid_vector | Trfunnel_enable_input_dst_Pid_vector);

  /* verilator lint_off WIDTHEXPAND */ 
  assign Trfunneldisinput_Pid_vector_stg = {8'(~Trfunnel_enable_input_dst_Pid_vector), 8'(~Trfunnel_enable_input_ntrace_Pid_vector)};
  /* verilator lint_on WIDTHEXPAND */
  
  always_comb begin
    TR_TS_Ntrace_NumEnabled_Srcs_stg = '0;
    TR_TS_Dst_NumEnabled_Srcs_stg = '0;
    for (int i=0; i<NUM_CORES; i++) begin
      /* verilator lint_off WIDTHEXPAND */
      TR_TS_Ntrace_NumEnabled_Srcs_stg = $bits(TR_TS_Ntrace_NumEnabled_Srcs_stg)'(TR_TS_Ntrace_NumEnabled_Srcs_stg + $bits(TR_TS_Ntrace_NumEnabled_Srcs_stg)'(~Trfunneldisinput_Pid_vector[i]));
      TR_TS_Dst_NumEnabled_Srcs_stg = $bits(TR_TS_Dst_NumEnabled_Srcs_stg)'(TR_TS_Dst_NumEnabled_Srcs_stg + $bits(TR_TS_Dst_NumEnabled_Srcs_stg)'(~Trfunneldisinput_Pid_vector[i+8]));
      /* verilator lint_on WIDTHEXPAND */
    end
  end

  generic_dff #(.WIDTH($clog2(8)+1)) TR_TS_Ntrace_NumEnabled_Srcs_ff (
    .out          (TR_TS_Ntrace_NumEnabled_Srcs),
    .in          (TR_TS_Ntrace_NumEnabled_Srcs_stg),
    .en         (1'b1),
    .clk        (clk),
    .rst_n    (reset_n)
  ); 

  generic_dff #(.WIDTH($clog2(8)+1)) TR_TS_Dst_NumEnabled_Srcs_ff (
    .out          (TR_TS_Dst_NumEnabled_Srcs),
    .in          (TR_TS_Dst_NumEnabled_Srcs_stg),
    .en         (1'b1),
    .clk        (clk),
    .rst_n    (reset_n)
  );
   
  // --------------------------------------------------------------------------
  // Funnel Control Ram Empty
  // --------------------------------------------------------------------------
  // Keep Funnel empty always high at the reset value as it doesn't buffer anytime
  always_comb begin
    TrCsrsWr.TrCsrTrfunnelcontrolWr = '0;
  end

  // Read data takes 3 cycles to be reflected on the `trramdata` register
  //  - Cycle 1 -> Set-up SRAM read enables, prioritize writes
  //  - Cycle 2 -> SRAM data available and set-up write to trramdata
  //  - Cycle 3 -> trramdata read data is now available
  assign trRamDataRdEn_ANY = CsrCs & ~CsrWrEn & (CsrAddr == (TR_TRRAMDATA_REG_OFFSET + BASE_ADDR)) &
                            ~CsrCs_d1;

  assign trdstRamDataRdEn_ANY = CsrCs & ~CsrWrEn & (CsrAddr == TR_TRDSTRAMDATA_REG_OFFSET + BASE_ADDR) &
                               ~CsrCs_d1;

  // Assert slave_read_ready after three cycles to account for flop stages in MMRs and
  // ramdata register reads
  assign NxtCsrCs = (CsrCs & ~CsrWrEn); // | ((jt_tr_eff_mmr_req_vld_with_fuse_chk & ~jt_tr_mmr_req_we_o) | jt_tr_mmr_rd_req_pend);

  generic_dff #(.WIDTH(1)) CsrCsd1_ff (
    .out          (CsrCs_d1),
    .in          (NxtCsrCs),
    .en         (~|TraceRamWrEn_TS0 | ~NxtCsrCs), // Ensre no writes is enabled in this cycle
    .clk        (clk_mmr),
    .rst_n    (reset_n)
  );

  generic_dff #(.WIDTH(1)) CsrCsd2_ff (
    .out          (CsrCs_d2),
    .in          (CsrCs_d1),
    .en         (1'b1),
    .clk        (clk_mmr),
    .rst_n    (reset_n)
  );

  generic_dff #(.WIDTH(1)) CsrCsd3_ff (
    .out          (CsrCs_d3),
    .in          (CsrCs_d2),
    .en         (1'b1),
    .clk        (clk_mmr),
    .rst_n    (reset_n)
  );

  // assign slave_read_ready = CsrCs_d3 & CsrCs_d1;
  // assign slave_busy = CsrCs_d1;

  // --------------------------------------------------------------------------
  // Trace Sink SMEM (AXI Interface)
  // --------------------------------------------------------------------------
  // Convert internal SRAM reads to AXI Bridge interface
  dfd_trace_axi_master #(
      .AXI_ADDR_WIDTH (DfdTrAxiAddrWidth),
      .AXI_DATA_WIDTH (DfdTrAxiDataWidth),
      .AXI_ID_WIDTH   (TrAxiIdWidthSlvPorts),
      .axi_req_t      (dfd_tr_slv_axi_req_t),
      .axi_resp_t     (dfd_tr_slv_axi_rsp_t)
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

  // Keep certain TrWr Signals Unconnected
  always_comb begin
   TrCsrsWr.TrCsrTrfunnelimplWr       = '0;
   TrCsrsWr.TrCsrTrfunneldisinputWr   = '0;
   TrCsrsWr.TrCsrTrramimplWr          = '0;
   TrCsrsWr.TrCsrTrramstartlowWr      = '0;  
   TrCsrsWr.TrCsrTrramstarthighWr     = '0;
   TrCsrsWr.TrCsrTrramlimitlowWr      = '0;
   TrCsrsWr.TrCsrTrramlimithighWr     = '0;
   TrCsrsWr.TrCsrTrcustomramsmemlimitlowWr = '0;
   TrCsrsWr.TrCsrTrdstramimplWr       = '0;
   TrCsrsWr.TrCsrTrdstramstartlowWr   = '0;
   TrCsrsWr.TrCsrTrdstramstarthighWr  = '0;
   TrCsrsWr.TrCsrTrdstramlimitlowWr   = '0;
   TrCsrsWr.TrCsrTrdstramlimithighWr  = '0;
  end

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eust]$"
// End:

