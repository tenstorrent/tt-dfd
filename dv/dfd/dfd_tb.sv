// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_tb
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
    parameter NUM_TRACE_AND_ANALYZER_INST = 2
) ();

  // Clock and reset
  logic                           clk;
  logic                           reset_n;
  logic                           reset_n_warm_ovrride;
  logic                           cold_reset_n;

  logic [ DFD_APB_ADDR_WIDTH-1:0] paddr;
  logic                           psel;
  logic                           penable;
  logic [DFD_APB_PSTRB_WIDTH-1:0] pstrb;
  logic                           pwrite;
  logic [ DFD_APB_DATA_WIDTH-1:0] pwdata;
  logic                           pready;
  logic [ DFD_APB_DATA_WIDTH-1:0] prdata;
  logic                           pslverr;

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
    pwdata  = 32'h0;
    reset_n = 1'b0;
    cold_reset_n = 1'b0;
    reset_n_warm_ovrride = 1'b0;
    repeat (2) @(negedge clk) cold_reset_n = 1'b1;
    reset_n = 1'b1;
    reset_n_warm_ovrride = 1'b1;
    repeat (10) @(negedge clk) paddr = 23'h000248;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = '1;
    pwdata  = 64'hDEADBEEF;

    @(negedge clk);
    penable = 1'b1;

    repeat (2) @(negedge clk) paddr = 23'h000248;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = '0;
    pwdata  = '0;

    @(negedge clk);
    penable = 1'b1;

    @(posedge clk iff (pready == 1'b1));
    #1;
    psel = 1'b0;

    repeat (10) @(negedge clk) paddr = 23'h166040;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = '1;
    pwdata  = 32'hBEEFDEAD;

    @(posedge clk);
    #1 penable = 1'b1;

    @(posedge clk iff (pready == 1'b1));
    #1;
    paddr   = 23'h000248;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = '0;
    pwdata  = '0;

    @(posedge clk);
    #1 penable = 1'b1;

    @(posedge clk iff (pready == 1'b1));
    #1;
    paddr   = 23'h00024C;
    psel    = 1'b1;
    penable = 1'b0;
    pstrb   = '1;
    pwrite  = '0;
    pwdata  = '0;

    @(posedge clk);
    #1 penable = 1'b1;

    repeat (2) @(negedge clk) psel = 1'b0;

  end

  initial begin
`ifdef FSDB_DEBUG
    $fsdbDumpvars(0, dfd_tb, "+all", "+mda", "+fsdbfile+dfd_tb_novas.fsdb");
`endif
    #1000 $display("Hello, World!");
    $finish;
  end

  initial begin

  end

  dfd_top #(
      .BASE_ADDR(0),
      .NUM_TRACE_AND_ANALYZER_INST(NUM_TRACE_AND_ANALYZER_INST),
      .NTRACE_SUPPORT(1),
      .DST_SUPPORT(1),
      .CLA_SUPPORT(1),
      .INTERNAL_MMRS(1),
      .TSEL_CONFIGURABLE(1)
  ) u_dfd_top (
      .clk(clk),
      .reset_n(reset_n),
      .reset_n_warm_ovrride(reset_n_warm_ovrride),
      .cold_reset_n(cold_reset_n),
      .i_mem_tsel_settings('0),

      // APB Interface
      .paddr('0),
      .psel('0),
      .penable('0),
      .pstrb('0),
      .pwrite('0),
      .pwdata('0),
      .pready(),
      .prdata(),
      .pslverr(),

      // Debug Mux
      .hw0('0),
      .hw1('0),
      .hw2('0),
      .hw3('0),
      .hw4('0),
      .hw5('0),
      .hw6('0),
      .hw7('0),
      .hw8('0),
      .hw9('0),
      .hw10('0),
      .hw11('0),
      .hw12('0),
      .hw13('0),
      .hw14('0),
      .hw15('0),
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
      .external_cla_action_trace_start('0),
      .external_cla_action_trace_stop('0),
      .external_cla_action_trace_pulse('0),
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

      // DST Interface
      .CoreTime('0),

      // Trace AXI Interface
      .TR_EXT_SlvReq (),
      .EXT_TR_SlvResp('0),
      .JT_TR_SlvReq  ('0),
      .TR_JT_SlvResp (),

      // External MMRs Interface
      .DfdCsrs_external  ('0),
      .DfdCsrsWr_external()
  );

  dfd_top_cla_dst_mmr #(
      .BASE_ADDR(64'HC0160000),
      .NUM_TRACE_AND_ANALYZER_INST(1),
      .NTRACE_SUPPORT(0),
      .DST_SUPPORT(1),
      .CLA_SUPPORT(1),
      .INTERNAL_MMRS(1),
      .TSEL_CONFIGURABLE(1),
      .SINK_CELL(mem_gen_pkg::mem_cell_undefined)
  ) u_dfd_top_cla_dst_mmr (
      .clk(clk),
      .reset_n(reset_n),
      .reset_n_warm_ovrride(reset_n_warm_ovrride),
      .cold_reset_n(cold_reset_n),
      .i_mem_tsel_settings('0),

      // APB Interface
      .paddr(paddr),
      .psel(psel),
      .penable(penable),
      .pstrb(pstrb),
      .pwrite(pwrite),
      .pwdata(pwdata),
      .pready(pready),
      .prdata(prdata),
      .pslverr(pslverr),

      // Debug Mux
      .hw0('0),
      .hw1('0),
      .hw2('0),
      .hw3('0),
      .hw4('0),
      .hw5('0),
      .hw6('0),
      .hw7('0),
      .hw8('0),
      .hw9('0),
      .hw10('0),
      .hw11('0),
      .hw12('0),
      .hw13('0),
      .hw14('0),
      .hw15('0),
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

      // DST Interface
      .CoreTime('0),

      // Trace AXI Interface
      .TR_EXT_SlvReq (),
      .EXT_TR_SlvResp('0),
      .JT_TR_SlvReq  ('0),
      .TR_JT_SlvResp ()
  );
endmodule
