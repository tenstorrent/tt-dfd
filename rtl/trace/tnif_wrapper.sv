module tnif_wrapper
    import tn_pkg::*;
#(
    parameter int unsigned NUM_DST_INST = 8,
    parameter int unsigned NUM_NTRACE_INST = 8,
    localparam int unsigned DATA_WIDTH = 128,

    // Derived counts (kept as localparams so they never surface as top-level
    // parameters in the auto-generated top).
    localparam int unsigned TNIF_CONNECTIONS = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST,

    // Safe port widths so a single-block flavor (e.g. NTRACE-only, NUM_DST_INST==0)
    // does not produce [-1:0] ports. Generate logic below uses the real counts.
    localparam int unsigned DST_W      = (NUM_DST_INST     == 0) ? 32'd1 : NUM_DST_INST,
    localparam int unsigned NTR_W      = (NUM_NTRACE_INST  == 0) ? 32'd1 : NUM_NTRACE_INST,
    // Kept self-contained (references only top parameters, not TNIF_CONNECTIONS)
    // so that when promoted into the auto-generated top's #() header it never
    // forward-references a body-scope localparam.
    localparam int unsigned TNIF_W     = ((NUM_DST_INST == 0) && (NUM_NTRACE_INST == 0)) ? 32'd1
                                         : ((NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST)
)(
  // Ungated free-running clock for the trace-network delay pipeline below.
  input   logic [TNIF_CONNECTIONS-1:0]                          tnif_gated_reset_n_warm_ovrride,

  // Per-feature gated clamps (from clk_rst_wrapper), used to clamp that
  // feature's own outputs.
  input   logic [DST_W-1:0]                                     dst_gated_func_clamp,
  input   logic [NTR_W-1:0]                                     ntr_gated_func_clamp,

  // Combined TNIF (trace-network) gated clock / reset / clamp (from clk_rst_wrapper).
  input   logic [TNIF_CONNECTIONS-1:0]                          tnif_gated_clock,
  input   logic [TNIF_CONNECTIONS-1:0]                          tnif_gated_reset_n,
  input   logic [TNIF_CONNECTIONS-1:0]                          tnif_gated_func_clamp,


    // Packetizer side (from dst_wrapper / ntr_wrapper)
    input  logic [DST_W-1:0]                            dst_tnif_req,
    input  logic [DST_W-1:0][DATA_WIDTH-1:0]            dst_tnif_data,
    output logic [DST_W-1:0]                            tnif_dst_pull,
    output logic [DST_W-1:0]                            tnif_dst_flush,
    output logic [DST_W-1:0]                            tnif_dst_bp,

    input  logic [NTR_W-1:0]                            ntr_tnif_req,
    input  logic [NTR_W-1:0][DATA_WIDTH-1:0]            ntr_tnif_data,
    output logic [NTR_W-1:0]                            tnif_ntr_pull,
    output logic [NTR_W-1:0]                            tnif_ntr_flush,
    output logic [NTR_W-1:0]                            tnif_ntr_bp,

    // Trace network side (to/from trace_top, undelayed)
    input  logic [TNIF_W-1:0]                            tr_tnif_gnt,
    input  logic [TNIF_W-1:0]                            tr_tnif_dst_bp,
    input  logic [TNIF_W-1:0]                            tr_tnif_ntr_bp,
    input  logic [TNIF_W-1:0]                            tr_tnif_dst_flush,
    input  logic [TNIF_W-1:0]                            tr_tnif_ntr_flush,

    output logic [TNIF_W-1:0]                            tnif_tr_valid,
    output logic [TNIF_W-1:0]                            tnif_tr_src,
    output logic [TNIF_W-1:0][DATA_WIDTH-1:0] tnif_tr_data
);

    localparam int unsigned DATA_WIDTH_IN_BYTES = DATA_WIDTH / 8;

    // Delayed (d1) versions of the trace-network handshake signals
    logic [TNIF_W-1:0]                            tr_gnt_in_d1;
    logic [TNIF_W-1:0]                            dst_bp_in_d1, ntr_bp_in_d1;
    logic [TNIF_W-1:0]                            dst_flush_in_d1, ntr_flush_in_d1;

    // Raw (undelayed) TNIF outputs toward the trace network
    logic [TNIF_W-1:0]                            tr_valid_out_raw, tnif_tr_valid_int;
    logic [TNIF_W-1:0]                            tr_src_out_raw, tnif_tr_src_int;
    logic [TNIF_W-1:0][DATA_WIDTH_IN_BYTES*8-1:0] tr_data_out_raw, tnif_tr_data_int;

    // Tie off packetizer-side outputs when the corresponding block is absent
    if (NUM_DST_INST == 0) begin : dst_unused_tieoff
        assign tnif_dst_pull  = '0;
        assign tnif_dst_flush = '0;
        assign tnif_dst_bp    = '0;
    end
    if (NUM_NTRACE_INST == 0) begin : ntr_unused_tieoff
        assign tnif_ntr_pull  = '0;
        assign tnif_ntr_flush = '0;
        assign tnif_ntr_bp    = '0;
    end

    for (genvar ii = 0; ii < TNIF_CONNECTIONS; ii++) begin : tnif_gen_blk

         // Input delay flops (trace_top -> tnif)
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_tr_gnt_in_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_tnif_gnt[ii]),
            .out   (tr_gnt_in_d1[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_dst_bp_in_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_tnif_dst_bp[ii]),
            .out   (dst_bp_in_d1[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_ntr_bp_in_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_tnif_ntr_bp[ii]),
            .out   (ntr_bp_in_d1[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_dst_flush_in_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_tnif_dst_flush[ii]),
            .out   (dst_flush_in_d1[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_ntr_flush_in_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_tnif_ntr_flush[ii]),
            .out   (ntr_flush_in_d1[ii])
        );

        // Output delay flops (tnif -> trace_top)
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_tr_vld_out_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_valid_out_raw[ii]),
            .out   (tnif_tr_valid_int[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic)),
            .RESET_VALUE ('0)
        ) tnif_tr_src_out_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_src_out_raw[ii]),
            .out   (tnif_tr_src_int[ii])
        );
        generic_dff #(
            .WIDTH       ($bits(logic [DATA_WIDTH_IN_BYTES*8-1:0])),
            .RESET_VALUE ('0)
        ) tnif_tr_data_out_d1_ff (
            .clk   (tnif_gated_clock[ii]),
            .rst_n (tnif_gated_reset_n[ii]),
            .en    ('1),
            .in    (tr_data_out_raw[ii]),
            .out   (tnif_tr_data_int[ii])
        );

        logic dst_pull_out_w, dst_flush_out_w, dst_bp_out_w;
        logic ntr_pull_out_w, ntr_flush_out_w, ntr_bp_out_w;

        // Per-connection block inputs. The loop spans TNIF_CONNECTIONS (the
        // larger of the DST/NTRACE counts), but the dst_*/ntr_* port arrays are
        // only as wide as their own block count (DST_W/NTR_W). Select via
        // generate-if so an out-of-range index is never elaborated when one
        // block has fewer (or zero) instances than the other.
        logic                 dst_req_w;
        logic [DATA_WIDTH-1:0] dst_data_w;
        logic                 ntr_req_w;
        logic [DATA_WIDTH-1:0] ntr_data_w;

        if (ii < NUM_DST_INST) begin : dst_in_conn
            assign dst_req_w  = dst_tnif_req[ii];
            assign dst_data_w = dst_tnif_data[ii];
        end else begin : dst_in_tie
            assign dst_req_w  = 1'b0;
            assign dst_data_w = {DATA_WIDTH{1'b0}};
        end

        if (ii < NUM_NTRACE_INST) begin : ntr_in_conn
            assign ntr_req_w  = ntr_tnif_req[ii];
            assign ntr_data_w = ntr_tnif_data[ii];
        end else begin : ntr_in_tie
            assign ntr_req_w  = 1'b0;
            assign ntr_data_w = {DATA_WIDTH{1'b0}};
        end

        tnif #(
            .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)
        ) i_tnif (
            .clock  		(tnif_gated_clock[ii]),
            .i_reset_n		(tnif_gated_reset_n[ii]),
            .reset_n_warm_ovrride (tnif_gated_reset_n_warm_ovrride[ii]),

            // DST
            .dst_req_in 	(dst_req_w),
            .dst_data_in	(dst_data_w),
            .dst_pull_out	(dst_pull_out_w),
            .dst_flush_out	(dst_flush_out_w),
            .dst_bp_out		(dst_bp_out_w),
            .dst_bp_in		(dst_bp_in_d1[ii]),
            .dst_flush_in	(dst_flush_in_d1[ii]),

            // NTRACE
            .ntr_req_in 	(ntr_req_w),
            .ntr_data_in	(ntr_data_w),
            .ntr_pull_out	(ntr_pull_out_w),
            .ntr_flush_out	(ntr_flush_out_w),
            .ntr_bp_out		(ntr_bp_out_w),
            .ntr_bp_in		(ntr_bp_in_d1[ii]),
            .ntr_flush_in	(ntr_flush_in_d1[ii]),

            // FUNNEL
            .tr_gnt_in		(tr_gnt_in_d1[ii]),
            .tr_valid_out	(tr_valid_out_raw[ii]),
            .tr_src_out  	(tr_src_out_raw[ii]),
            .tr_data_out 	(tr_data_out_raw[ii])
        );

        // DST outputs are clamped by the DST-specific gated clamp.
        if (ii < NUM_DST_INST) begin : dst_conn
            assign tnif_dst_pull[ii]  = dst_gated_func_clamp[ii] ? 1'b0 : dst_pull_out_w;
            assign tnif_dst_flush[ii] = dst_gated_func_clamp[ii] ? 1'b0 : dst_flush_out_w;
            assign tnif_dst_bp[ii]    = dst_gated_func_clamp[ii] ? 1'b0 : dst_bp_out_w;
        end
        // NTRACE outputs are clamped by the NTRACE-specific gated clamp.
        if (ii < NUM_NTRACE_INST) begin : ntr_conn
            assign tnif_ntr_pull[ii]  = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_pull_out_w;
            assign tnif_ntr_flush[ii] = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_flush_out_w;
            assign tnif_ntr_bp[ii]    = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_bp_out_w;
        end
    end

    // Trace-network outputs are clamped per-instance by the combined TNIF clamp
    // (bitwise combination of DST and NTRACE). Indices beyond TNIF_CONNECTIONS
    // (only reachable in a degenerate all-zero config) are tied off.
    for (genvar jj = 0; jj < TNIF_W; jj++) begin : tnif_tr_out_gen
        if (jj < TNIF_CONNECTIONS) begin : tnif_tr_clamp_gen
            assign tnif_tr_valid[jj] = tnif_gated_func_clamp[jj] ? 1'b0 : tnif_tr_valid_int[jj];
            assign tnif_tr_src[jj]   = tnif_gated_func_clamp[jj] ? 1'b0 : tnif_tr_src_int[jj];
            assign tnif_tr_data[jj]  = tnif_gated_func_clamp[jj] ? '0   : tnif_tr_data_int[jj];
        end else begin : tnif_tr_clamp_tie
            assign tnif_tr_valid[jj] = 1'b0;
            assign tnif_tr_src[jj]   = 1'b0;
            assign tnif_tr_data[jj]  = '0;
        end
    end

endmodule
