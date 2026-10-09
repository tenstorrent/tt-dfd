// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************

// clk_rst_wrapper (open-source variant):
//
//
// Functional clock enable sources (unchanged, extracted in mmrs.sv):
//   cla      : ClaMmrs[i].Cdbgclactrlstatus.EnableCla
//   dst      : DstMmrs[i].Trdstcontrol.Trdstactive
//   ntr      : NtrMmrs[i].Trtecontrol.Trteactive
//   dst_sink : DstSinkMmrs.Trdstramcontrol.Trdstramactive
//   ntr_sink : NtrSinkMmrs.Trramcontrol.Trramactive
//   funnel   : FunnelMmrs.Trfunnelcontrol.Trfunnelactive
//   tnif     : dst_func_enable | ntr_func_enable (per connection)
//

// The clock gate is held open while reset is asserted so the synchronous
// reset-staging flops in the gated domains (notably tnif) are clocked during
// the reset window instead of powering up X.

module clk_rst_wrapper
#(
    parameter int unsigned NUM_CLA_INST    = 8,
    parameter int unsigned NUM_DST_INST    = 8,
    parameter int unsigned NUM_NTRACE_INST = 8,

    // Zero-safe port widths so a single-block flavor (e.g. NTRACE-only,
    // NUM_DST_INST==0) never produces a [-1:0] port. Generate logic below uses
    // the real counts.
    localparam int unsigned CLA_W = (NUM_CLA_INST    == 0) ? 32'd1 : NUM_CLA_INST,
    localparam int unsigned DST_W = (NUM_DST_INST    == 0) ? 32'd1 : NUM_DST_INST,
    localparam int unsigned NTR_W = (NUM_NTRACE_INST == 0) ? 32'd1 : NUM_NTRACE_INST,

    // Combined trace-network (tnif) connection count = larger of DST/NTRACE.
    localparam int unsigned TNIF_CONNECTIONS = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST,
    localparam int unsigned TNIF_W = ((NUM_DST_INST == 0) && (NUM_NTRACE_INST == 0)) ? 32'd1
                                     : ((NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST)
)(
    // Global controls
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_critical_signal_hold,

    input  logic i_test_icg_en,

    // CLA controls

    // DST controls

    // NTRACE controls

    // DST sink controls

    // NTR sink controls

    // Funnel controls

    // MMR enables that gate the functional clock (per-instance).
    input  logic [CLA_W-1:0] cla_func_enable,
    input  logic [DST_W-1:0] dst_func_enable,
    input  logic [NTR_W-1:0] ntr_func_enable,
    input  logic dst_sink_func_enable,
    input  logic ntr_sink_func_enable,
    input  logic funnel_func_enable,

    // CLA gated outputs (per-instance)
    output logic [CLA_W-1:0]         cla_gated_clock,
    output logic [CLA_W-1:0]         cla_gated_reset_n,
    output logic [CLA_W-1:0]         cla_gated_reset_n_warm_ovrride,
    output logic [CLA_W-1:0]         cla_gated_func_clamp,

    // DST gated outputs (per-instance)
    output logic [DST_W-1:0]         dst_gated_clock,
    output logic [DST_W-1:0]         dst_gated_reset_n,
    output logic [DST_W-1:0]         dst_gated_reset_n_warm_ovrride,
    output logic [DST_W-1:0]         dst_gated_func_clamp,

    // NTRACE gated outputs (per-instance)
    output logic [NTR_W-1:0]         ntr_gated_clock,
    output logic [NTR_W-1:0]         ntr_gated_reset_n,
    output logic [NTR_W-1:0]         ntr_gated_reset_n_warm_ovrride,
    output logic [NTR_W-1:0]         ntr_gated_func_clamp,

    // TNIF (combined trace-network) gated outputs (per-connection)
    output logic [TNIF_W-1:0]        tnif_gated_clock,
    output logic [TNIF_W-1:0]        tnif_gated_reset_n,
    output logic [TNIF_W-1:0]        tnif_gated_reset_n_warm_ovrride,
    output logic [TNIF_W-1:0]        tnif_gated_func_clamp,

    // DST sink gated outputs (scalar)
    output logic                     dst_sink_gated_clock,
    output logic                     dst_sink_gated_reset_n,
    output logic                     dst_sink_gated_reset_n_warm_ovrride,
    output logic                     dst_sink_gated_func_clamp,

    // NTR sink gated outputs (scalar)
    output logic                     ntr_sink_gated_clock,
    output logic                     ntr_sink_gated_reset_n,
    output logic                     ntr_sink_gated_reset_n_warm_ovrride,
    output logic                     ntr_sink_gated_func_clamp,

    // Funnel gated outputs (scalar)
    output logic                     funnel_gated_clock,
    output logic                     funnel_gated_reset_n,
    output logic                     funnel_gated_reset_n_warm_ovrride,
    output logic                     funnel_gated_func_clamp
);

    // -------------------------------------------------------------------------
    // Reset distribution. The functional reset is used directly; there is no
    // sequencing.
    // -------------------------------------------------------------------------
    logic reset_n_eff;
    assign reset_n_eff = i_rst_n;

    // -------------------------------------------------------------------------
    // CLA per-instance clock gate. Enable = Cdbgclactrlstatus.EnableCla.
    // -------------------------------------------------------------------------
    if (NUM_CLA_INST > 0) begin : cla_ccg_gen
        for (genvar ii = 0; ii < NUM_CLA_INST; ii++) begin : cla_ccg
            logic cla_clk_en;
            assign cla_clk_en = cla_func_enable[ii] | ~reset_n_eff;

            generic_ccg #(.HYST_EN(0)) u_cla_ccg (
                .out_clk    (cla_gated_clock[ii]),
                .clk    (i_clk),
                .en     (cla_clk_en),
                .rst_n(reset_n_eff),
                .force_en  ('0),
                .hyst   ('0),
                .te     (i_test_icg_en)
            );
        end
        assign cla_gated_reset_n = {CLA_W{reset_n_eff}};
    end else begin : cla_ccg_tie
        assign cla_gated_clock   = '0;
        assign cla_gated_reset_n = '0;
    end
    assign cla_gated_func_clamp           = '0;
    assign cla_gated_reset_n_warm_ovrride = {CLA_W{i_critical_signal_hold}} | cla_gated_reset_n;

    // -------------------------------------------------------------------------
    // DST per-instance clock gate. Enable = Trdstcontrol.Trdstactive.
    // -------------------------------------------------------------------------
    if (NUM_DST_INST > 0) begin : dst_ccg_gen
        for (genvar ii = 0; ii < NUM_DST_INST; ii++) begin : dst_ccg
            logic dst_clk_en;
            assign dst_clk_en = dst_func_enable[ii] | ~reset_n_eff;

            generic_ccg #(.HYST_EN(0)) u_dst_ccg (
                .out_clk    (dst_gated_clock[ii]),
                .clk    (i_clk),
                .en     (dst_clk_en),
                .rst_n(reset_n_eff),
                .force_en  ('0),
                .hyst   ('0),
                .te     (i_test_icg_en)
            );
        end
        assign dst_gated_reset_n = {DST_W{reset_n_eff}};
    end else begin : dst_ccg_tie
        assign dst_gated_clock   = '0;
        assign dst_gated_reset_n = '0;
    end
    assign dst_gated_func_clamp           = '0;
    assign dst_gated_reset_n_warm_ovrride = {DST_W{i_critical_signal_hold}} | dst_gated_reset_n;

    // -------------------------------------------------------------------------
    // NTRACE per-instance clock gate. Enable = Trtecontrol.Trteactive.
    // -------------------------------------------------------------------------
    if (NUM_NTRACE_INST > 0) begin : ntr_ccg_gen
        for (genvar ii = 0; ii < NUM_NTRACE_INST; ii++) begin : ntr_ccg
            logic ntr_clk_en;
            assign ntr_clk_en = ntr_func_enable[ii] | ~reset_n_eff;

            generic_ccg #(.HYST_EN(0)) u_ntr_ccg (
                .out_clk    (ntr_gated_clock[ii]),
                .clk    (i_clk),
                .en     (ntr_clk_en),
                .rst_n(reset_n_eff),
                .force_en  ('0),
                .hyst   ('0),
                .te     (i_test_icg_en)
            );
        end
        assign ntr_gated_reset_n = {NTR_W{reset_n_eff}};
    end else begin : ntr_ccg_tie
        assign ntr_gated_clock   = '0;
        assign ntr_gated_reset_n = '0;
    end
    assign ntr_gated_func_clamp           = '0;
    assign ntr_gated_reset_n_warm_ovrride = {NTR_W{i_critical_signal_hold}} | ntr_gated_reset_n;

    // -------------------------------------------------------------------------
    // TNIF (combined trace-network) clock gate: a lane runs when the DST or the
    // NTRACE instance feeding it is active. Absent blocks contribute 0 to the
    // OR, so the present block governs.
    // -------------------------------------------------------------------------
    if ((NUM_DST_INST > 0) || (NUM_NTRACE_INST > 0)) begin : tnif_ccg_gen
        logic [TNIF_W-1:0] tnif_func_clk_en;
        logic [TNIF_W-1:0] dst_func_enable_ext;
        logic [TNIF_W-1:0] ntr_func_enable_ext;

        always_comb begin
            dst_func_enable_ext = '0;
            ntr_func_enable_ext = '0;
            for (int unsigned ii = 0; ii < NUM_DST_INST; ii++) begin
                dst_func_enable_ext[ii] = dst_func_enable[ii];
            end
            for (int unsigned ii = 0; ii < NUM_NTRACE_INST; ii++) begin
                ntr_func_enable_ext[ii] = ntr_func_enable[ii];
            end
        end

        assign tnif_func_clk_en = dst_func_enable_ext | ntr_func_enable_ext;

        for (genvar ii = 0; ii < TNIF_CONNECTIONS; ii++) begin : tnif_ccg
            logic tnif_clk_en;
            assign tnif_clk_en = tnif_func_clk_en[ii] | ~reset_n_eff;

            generic_ccg #(.HYST_EN(0)) u_tnif_ccg (
                .out_clk    (tnif_gated_clock[ii]),
                .clk    (i_clk),
                .en     (tnif_clk_en),
                .rst_n(reset_n_eff),
                .force_en  ('0),
                .hyst   ('0),
                .te     (i_test_icg_en)
            );
        end
        assign tnif_gated_reset_n = {TNIF_W{reset_n_eff}};
    end else begin : tnif_ccg_tie
        assign tnif_gated_clock   = '0;
        assign tnif_gated_reset_n = '0;
    end
    assign tnif_gated_func_clamp           = '0;
    assign tnif_gated_reset_n_warm_ovrride = {TNIF_W{i_critical_signal_hold}} | tnif_gated_reset_n;

    // -------------------------------------------------------------------------
    // DST sink clock gate (scalar). Enable = Trdstramcontrol.Trdstramactive.
    // -------------------------------------------------------------------------
    logic dst_sink_clk_en;
    assign dst_sink_clk_en = dst_sink_func_enable | ~reset_n_eff;

    generic_ccg #(.HYST_EN(0)) u_dst_sink_ccg (
        .out_clk    (dst_sink_gated_clock),
        .clk    (i_clk),
        .en     (dst_sink_clk_en),
        .rst_n(reset_n_eff),
        .force_en  ('0),
        .hyst   ('0),
        .te     (i_test_icg_en)
    );
    assign dst_sink_gated_reset_n              = reset_n_eff;
    assign dst_sink_gated_func_clamp           = '0;
    assign dst_sink_gated_reset_n_warm_ovrride = i_critical_signal_hold | dst_sink_gated_reset_n;

    // -------------------------------------------------------------------------
    // NTR sink clock gate (scalar). Enable = Trramcontrol.Trramactive.
    // -------------------------------------------------------------------------
    logic ntr_sink_clk_en;
    assign ntr_sink_clk_en = ntr_sink_func_enable | ~reset_n_eff;

    generic_ccg #(.HYST_EN(0)) u_ntr_sink_ccg (
        .out_clk    (ntr_sink_gated_clock),
        .clk    (i_clk),
        .en     (ntr_sink_clk_en),
        .rst_n(reset_n_eff),
        .force_en  ('0),
        .hyst   ('0),
        .te     (i_test_icg_en)
    );
    assign ntr_sink_gated_reset_n              = reset_n_eff;
    assign ntr_sink_gated_func_clamp           = '0;
    assign ntr_sink_gated_reset_n_warm_ovrride = i_critical_signal_hold | ntr_sink_gated_reset_n;

    // -------------------------------------------------------------------------
    // Funnel clock gate (scalar). Enable = Trfunnelcontrol.Trfunnelactive.
    // -------------------------------------------------------------------------
    logic funnel_clk_en;
    assign funnel_clk_en = funnel_func_enable | ~reset_n_eff;

    generic_ccg #(.HYST_EN(0)) u_funnel_ccg (
        .out_clk    (funnel_gated_clock),
        .clk    (i_clk),
        .en     (funnel_clk_en),
        .rst_n(reset_n_eff),
        .force_en  ('0),
        .hyst   ('0),
        .te     (i_test_icg_en)
    );
    assign funnel_gated_reset_n              = reset_n_eff;
    assign funnel_gated_func_clamp           = '0;
    assign funnel_gated_reset_n_warm_ovrride = i_critical_signal_hold | funnel_gated_reset_n;

endmodule
