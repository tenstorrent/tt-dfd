// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Connectivity testbench for the split trace topology:
//   * dfd_top_cla_ntrace_notrace_mmr : trace sources (CLA + NTRACE encoders), the
//     trace network is external -> exposes the core-facing TNIF as ports.
//   * dfd_top_tnif                    : trace network/funnel/mem only, the encoders
//     are external -> exposes the mirror TNIF as ports.
// The two are wired together over the TNIF boundary to reconstruct a full trace path.
module dfd_tnif_tb
  import dfd_dst_pkg::*;
  import dfd_pkg::*;
  import dfd_cla_csr_pkg::*;
  import dfd_tr_csr_pkg::*;
  import dfd_mcr_csr_pkg::*;
  import dfd_dst_csr_pkg::*;
  import dfd_ntr_csr_pkg::*;
  import dfd_cla_pkg::*;
  import dfd_packetizer_pkg::*;
  import dfd_te_pkg::*;
  import dfd_tn_pkg::*;
  import dfd_CL_axi_pkg::*;
#(
    parameter TEST = 1,
    // Must be EVEN: the _notrace source block (TRACE_SUPPORT=0) sizes its TNIF to
    // NUM_TRACE_AND_ANALYZER_INST, while the _tnif network block (TRACE_SUPPORT=1) rounds
    // up to an even number. The two TNIF boundaries only have matching widths when
    // NUM_TRACE_AND_ANALYZER_INST is already even (then NUM == even-rounded(NUM)).
    parameter int unsigned NUM_TRACE_AND_ANALYZER_INST = 2
) ();

  // TNIF_CONNECTIONS must match the (trace-supported) formula used inside the variants so
  // the bus widths line up on both sides of the boundary.
  localparam int unsigned TNIF_CONNECTIONS =
      (NUM_TRACE_AND_ANALYZER_INST <= 1) ? 2 : ((NUM_TRACE_AND_ANALYZER_INST + 1) & ~1);
  localparam int unsigned TR_TNIF_DATA_WIDTH = 16 * 8;  // DATA_WIDTH_IN_BYTES * 8

  // Clock and reset
  logic clk;
  logic reset_n;
  logic reset_n_warm_ovrride;
  logic cold_reset_n;

  // APB (driven into the encoder block's MMR space)
  logic [ DFD_APB_ADDR_WIDTH-1:0] paddr;
  logic                           psel;
  logic                           penable;
  logic [DFD_APB_PSTRB_WIDTH-1:0] pstrb;
  logic                           pwrite;
  logic [ DFD_APB_DATA_WIDTH-1:0] pwdata;
  logic                           pready;
  logic [ DFD_APB_DATA_WIDTH-1:0] prdata;
  logic                           pslverr;

  // ---------------------------------------------------------------------------
  // TNIF boundary nets connecting encoder (sources) <-> network
  // ---------------------------------------------------------------------------
  // Network -> sources (flow control / flush / grant)
  logic [TNIF_CONNECTIONS-1:0]                          tnif_tr_gnt;
  logic [TNIF_CONNECTIONS-1:0]                          tnif_dst_bp;
  logic [TNIF_CONNECTIONS-1:0]                          tnif_ntr_bp;
  logic [TNIF_CONNECTIONS-1:0]                          tnif_dst_flush;
  logic [TNIF_CONNECTIONS-1:0]                          tnif_ntr_flush;
  // Sources -> network (trace data stream)
  logic [TNIF_CONNECTIONS-1:0]                          tnif_tr_vld;
  logic [TNIF_CONNECTIONS-1:0]                          tnif_tr_src;
  logic [TNIF_CONNECTIONS-1:0][TR_TNIF_DATA_WIDTH-1:0]  tnif_tr_data;

  // Trace memory AXI (handled by the network block); left unconnected here.
  dfd_slv_axi_req_t    TR_EXT_SlvReq;
  dfd_tr_slv_axi_rsp_t TR_JT_SlvResp;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    paddr   = '0;
    psel    = 1'b0;
    penable = 1'b0;
    pstrb   = '0;
    pwrite  = '0;
    pwdata  = '0;
    reset_n = 1'b0;
    cold_reset_n = 1'b0;
    reset_n_warm_ovrride = 1'b0;

    repeat (2) @(negedge clk) cold_reset_n = 1'b1;
    reset_n = 1'b1;
    reset_n_warm_ovrride = 1'b1;

    // Simple APB write then read-back into the encoder block.
    repeat (10) @(negedge clk);
    paddr   = 23'h000248;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = 1'b1;
    pwdata  = 64'hDEADBEEF;
    @(negedge clk);
    penable = 1'b1;
    @(posedge clk iff (pready == 1'b1));
    #1;

    paddr   = 23'h000248;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = 1'b0;
    pwdata  = '0;
    @(negedge clk);
    penable = 1'b1;
    @(posedge clk iff (pready == 1'b1));
    #1;
    psel    = 1'b0;
    penable = 1'b0;
  end

  initial begin
`ifdef FSDB_DEBUG
    $fsdbDumpvars(0, dfd_tnif_tb, "+all", "+mda", "+fsdbfile+dfd_tnif_tb_novas.fsdb");
`endif
    #1000 $display("dfd_tnif_tb: done");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Trace sources: CLA + NTRACE encoders, trace network external (NOTRACE).
  // Exposes the TNIF as ports (encoder side).
  // ---------------------------------------------------------------------------
  dfd_top_cla_ntrace_notrace_mmr #(
      .BASE_ADDR(64'hC0160000),
      .NUM_TRACE_AND_ANALYZER_INST(NUM_TRACE_AND_ANALYZER_INST),
      .NTRACE_SUPPORT(1),
      .DST_SUPPORT(0),
      .CLA_SUPPORT(1),
      .INTERNAL_MMRS(1),
      .TSEL_CONFIGURABLE(1)
  ) u_dfd_sources (
      .clk(clk),
      .reset_n(reset_n),
      .reset_n_warm_ovrride(reset_n_warm_ovrride),
      .cold_reset_n(cold_reset_n),
      .i_mem_tsel_settings('0),

      // Debug Mux
      .hw0('0), .hw1('0), .hw2('0),  .hw3('0),  .hw4('0),  .hw5('0),  .hw6('0),  .hw7('0),
      .hw8('0), .hw9('0), .hw10('0), .hw11('0), .hw12('0), .hw13('0), .hw14('0), .hw15('0),
      .Time_Tick('0),

      // CLA Interface
      .xtrigger_in('0),
      .time_match_event('0),
      .xtrigger_out(),
      .cla_debug_marker(),
      .external_action_trace_start(),
      .external_action_trace_stop(),
      .external_action_trace_pulse(),
      .external_action_halt_clock_out(),
      .external_action_halt_clock_local_out(),
      .external_action_debug_interrupt_out(),
      .external_action_toggle_gpio_out(),
      .external_action_custom(),
      .timesync_cla_timestamp(),

      // NTRACE Interface
      .IRetire('0),
      .IType('0),
      .IAddr('0),
      .ILastSize('0),
      .Tstamp('0),
      .Priv({NUM_TRACE_AND_ANALYZER_INST{PRIVMODE_USER}}),
      .Context('0),
      .Tval('0),
      .Error('0),
      .Active(),
      .StallModeEn(),
      .StartStop(),
      .Backpressure(),
      .TrigControl({NUM_TRACE_AND_ANALYZER_INST{TRIG_TRACE_OFF}}),

      // TNIF boundary (encoder side): data out, flow-control in
      .tnif_tr_gnt_i(tnif_tr_gnt),
      .tnif_dst_bp_i(tnif_dst_bp),
      .tnif_ntr_bp_i(tnif_ntr_bp),
      .tnif_dst_flush_i(tnif_dst_flush),
      .tnif_ntr_flush_i(tnif_ntr_flush),
      .tnif_tr_vld_o(tnif_tr_vld),
      .tnif_tr_src_o(tnif_tr_src),
      .tnif_tr_data_o(tnif_tr_data),

      // APB Interface
      .paddr(paddr),
      .psel(psel),
      .penable(penable),
      .pstrb(pstrb),
      .pwrite(pwrite),
      .pwdata(pwdata),
      .pready(pready),
      .prdata(prdata),
      .pslverr(pslverr)
  );

  // ---------------------------------------------------------------------------
  // Trace network/funnel/mem only, encoders external (TNIF variant).
  // Exposes the mirror TNIF as ports (network side).
  // ---------------------------------------------------------------------------
  dfd_top_tnif #(
      .BASE_ADDR(64'hC0170000),
      .NUM_TRACE_AND_ANALYZER_INST(NUM_TRACE_AND_ANALYZER_INST),
      .INTERNAL_MMRS(1),
      .TSEL_CONFIGURABLE(1),
      .SINK_CELL(mem_gen_pkg::mem_cell_undefined)
  ) u_dfd_network (
      .clk(clk),
      .reset_n(reset_n),
      .reset_n_warm_ovrride(reset_n_warm_ovrride),
      .cold_reset_n(cold_reset_n),
      .i_mem_tsel_settings('0),

      // External CLA action inputs (unused here)
      .external_cla_action_trace_start('0),
      .external_cla_action_trace_stop('0),
      .external_cla_action_trace_pulse('0),

      // Trace AXI Interface
      .TR_EXT_SlvReq (TR_EXT_SlvReq),
      .EXT_TR_SlvResp('0),
      .JT_TR_SlvReq  ('0),
      .TR_JT_SlvResp (TR_JT_SlvResp),

      // TNIF boundary (network side): data in, flow-control out
      .tnif_tr_gnt_o(tnif_tr_gnt),
      .tnif_dst_bp_o(tnif_dst_bp),
      .tnif_ntr_bp_o(tnif_ntr_bp),
      .tnif_dst_flush_o(tnif_dst_flush),
      .tnif_ntr_flush_o(tnif_ntr_flush),
      .tnif_tr_vld_i(tnif_tr_vld),
      .tnif_tr_src_i(tnif_tr_src),
      .tnif_tr_data_i(tnif_tr_data),

      // APB Interface (tied off; encoder block owns the stimulus)
      .paddr('0),
      .psel('0),
      .penable('0),
      .pstrb('0),
      .pwrite('0),
      .pwdata('0),
      .pready(),
      .prdata(),
      .pslverr()
  );

endmodule
