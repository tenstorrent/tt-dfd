module ntr_wrapper
    import te_pkg::*;
    import ntr_sink_mmr_pkg::*;
    import ntr_mmr_pkg::*;
    import packetizer_pkg::*;
#(
    parameter int unsigned NUM_NTRACE_INST = 8,
    parameter int unsigned NUM_DST_INST = 8,
    parameter int unsigned NUM_CLA_INST = 8,
    parameter int unsigned IRETIRE_WIDTH = 5,
    parameter int unsigned PC_WIDTH = te_pkg::TE_PC_WIDTH,
    parameter int unsigned CONTEXT_WIDTH = te_pkg::TE_CONTEXT_WIDTH,
    parameter int unsigned TVAL_WIDTH = te_pkg::TE_TVAL_WIDTH,
    parameter int unsigned TSTAMP_WIDTH = te_pkg::TE_TSTAMP_WIDTH,
    localparam int unsigned ITYPE_WIDTH = te_pkg::TE_ITYPE_WIDTH,
    localparam int unsigned NUM_BLOCKS = te_pkg::TE_NUM_BLOCKS,
    localparam int DATA_WIDTH = 128,
    localparam MAX_DST_NTR_INST = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST,
    // Zero-safe width for the unrelated CLA count (CLA may be absent while NTRACE is present)
    localparam CLA_W = (NUM_CLA_INST == 0) ? 1 : NUM_CLA_INST
)(

  // Gated clock / reset / clamp from clk_rst_wrapper (per-instance)
  input   logic [NUM_NTRACE_INST-1:0]                            ntr_gated_clock,
  input   logic [NUM_NTRACE_INST-1:0]                            ntr_gated_reset_n,
  input   logic [NUM_NTRACE_INST-1:0]                            ntr_gated_func_clamp,
  input   logic [NUM_NTRACE_INST-1:0]                            ntr_gated_reset_n_warm_ovrride,

    // NTRACE inputs
    input  logic [NUM_NTRACE_INST-1:0][NUM_BLOCKS-1:0][IRETIRE_WIDTH-1:0] i_ntr_hart_te_iretire,
    input  logic [NUM_NTRACE_INST-1:0][NUM_BLOCKS-1:0][  ITYPE_WIDTH-1:0] i_ntr_hart_te_itype,
    input  logic [NUM_NTRACE_INST-1:0][NUM_BLOCKS-1:0][     PC_WIDTH-1:1] i_ntr_hart_te_iaddr,
    input  logic [NUM_NTRACE_INST-1:0][NUM_BLOCKS-1:0]                    i_ntr_hart_te_ilastsize,
    input  logic [NUM_NTRACE_INST-1:0][TSTAMP_WIDTH-1:0]                  i_ntr_hart_te_tstamp,

    input  logic [NUM_NTRACE_INST-1:0] [2:0]                   i_ntr_hart_te_priv,
    input  logic      [NUM_NTRACE_INST-1:0][CONTEXT_WIDTH-1:0] i_ntr_hart_te_context,
    input  logic      [NUM_NTRACE_INST-1:0][TVAL_WIDTH-1:0]    i_ntr_hart_te_tval,

    input  logic [CLA_W-1:0] cla_trigger_trace_start,
    input  logic [CLA_W-1:0] cla_trigger_trace_stop,
    input  logic [CLA_W-1:0] cla_trigger_trace_pulse,

    input  logic [NUM_NTRACE_INST-1:0] i_ntr_hart_te_error,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_active,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_stall_mode_en,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_start_stop,
    output logic [NUM_NTRACE_INST-1:0] o_ntr_tr_start_backpressure,

    input  logic [MAX_DST_NTR_INST-1:0] [1:0] i_sdtrig_control,

    // MMRs
    input  NtrMmrs_s [NUM_NTRACE_INST-1:0] NtrMmrs,
    output NtrMmrsWr_s [NUM_NTRACE_INST-1:0] NtrMmrsWr,

    // TNIF Interface
    input  logic [NUM_NTRACE_INST-1:0] tnif_ntr_pull,
    input  logic [NUM_NTRACE_INST-1:0] tnif_ntr_flush,
    input  logic [NUM_NTRACE_INST-1:0] tnif_ntr_bp,

    output logic [NUM_NTRACE_INST-1:0] ntr_tnif_req,
    output logic [NUM_NTRACE_INST-1:0] [DATA_WIDTH-1:0] ntr_tnif_data

);

    for (genvar ii = 0; ii < NUM_NTRACE_INST; ii++) begin : ntrace_inst

        te_pkg::TrigTraceControl_e trig_control_e;
        assign trig_control_e = te_pkg::TrigTraceControl_e'(i_sdtrig_control[ii]);

        te_pkg::PrivMode_e priv_mode_e;
        assign priv_mode_e = te_pkg::PrivMode_e'(i_ntr_hart_te_priv[ii]);
        // Frame Info
        frame_info_s n_trace_frame_info;

        // Leaf outputs (pre-clamp); clamped to the wrapper boundary below.
        logic                  ntr_active_w, ntr_stallmodeen_w, ntr_startstop_w, ntr_backpressure_w;
        logic                  ntr_tnif_req_w;
        logic [DATA_WIDTH-1:0] ntr_tnif_data_w;

        // Encoder <-> Packetizer interface
        logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0]      ntrace_packet;
        logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0]        ntrace_packet_byte_enable;
        logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0]  ntrace_request_packet_space_in_bytes;
        logic                                               ntrace_requested_packet_space_granted;
        logic                                               ntrace_flush_mode_enable;
        logic                                               ntrace_flush_mode_exit;
        logic                                               ntrace_packetizer_empty;

        // TNIF-derived hardware flush/stop
        logic ntr_hardware_flush;
        logic ntr_hardware_stop;
        assign ntr_hardware_flush = tnif_ntr_flush[ii] & ~tnif_ntr_bp[ii];
        assign ntr_hardware_stop  = tnif_ntr_flush[ii] &  tnif_ntr_bp[ii];

        // NTRACE MMRs
        NtrTrtecontrolMmr_s          Trtecontrol;
        NtrTrtscontrolMmr_s          Trtscontrol;
        NtrTrteimplMmr_s             Trteimpl;
        NtrTrteinstfeaturesMmr_s     Trteinstfeatures;
        NtrTrteinstfiltersMmr_s      Trteinstfilters;
        NtrTrtefilter0ControlMmr_s   Trtefilter0Control;
        NtrTrtefilter0MatchinstMmr_s Trtefilter0Matchinst;
        NtrCdbgntraceframecfgMmr_s   Cdbgntraceframecfg;
        NtrTrtecontrolMmrWr_s        TrtecontrolWr;

        assign Trtecontrol          = NtrMmrs[ii].Trtecontrol;
        assign Trtscontrol          = NtrMmrs[ii].Trtscontrol;
        assign Trteimpl             = NtrMmrs[ii].Trteimpl;
        assign Trteinstfeatures     = NtrMmrs[ii].Trteinstfeatures;
        assign Trteinstfilters      = NtrMmrs[ii].Trteinstfilters;
        assign Trtefilter0Control   = NtrMmrs[ii].Trtefilter0Control;
        assign Trtefilter0Matchinst = NtrMmrs[ii].Trtefilter0Matchinst;
        assign Cdbgntraceframecfg   = NtrMmrs[ii].Cdbgntraceframecfg;
        assign NtrMmrsWr[ii].TrtecontrolWr = ntr_gated_func_clamp[ii] ? '0 : TrtecontrolWr;

        // Frame Information
        assign n_trace_frame_info.stream_count_enable = '0;
        assign n_trace_frame_info.stream_depth        = '0;
        assign n_trace_frame_info.frame_length        = {Trteimpl.Trtevendorframelength, 6'b0};
        assign n_trace_frame_info.frame_fill_byte     = Cdbgntraceframecfg.TraceFrameFillByte;
        assign n_trace_frame_info.frame_mode_enable   = Cdbgntraceframecfg.FrameModeEnable;
        assign n_trace_frame_info.frame_closure_mode  = Cdbgntraceframecfg.FrameClosureMode;

        te_encoder #(
            .IRETIRE_WIDTH(IRETIRE_WIDTH),
            .PC_WIDTH(PC_WIDTH),
            .CONTEXT_WIDTH(CONTEXT_WIDTH),
            .TVAL_WIDTH(TVAL_WIDTH),
            .TSTAMP_WIDTH(TSTAMP_WIDTH)
        )ntrace_encoder (
            .clock  					(ntr_gated_clock[ii]),
            .i_reset_n					(ntr_gated_reset_n[ii]),
            .reset_n_warm_ovrride (ntr_gated_reset_n_warm_ovrride[ii]),
            .trIRetire_RE6				(i_ntr_hart_te_iretire[ii]),
            .trIType_RE6				(i_ntr_hart_te_itype[ii]),
            .trIAddr_RE6				(i_ntr_hart_te_iaddr[ii]),
            .trILastSize_RE6			(i_ntr_hart_te_ilastsize[ii]),
            .trPriv_RE6					(priv_mode_e),
            .trContext_RE6				(i_ntr_hart_te_context[ii]),
            .trTstamp_RE6				(i_ntr_hart_te_tstamp[ii]),
            .trTval_RE6					(i_ntr_hart_te_tval[ii]),
            .MC_MS_trError_RE6			(i_ntr_hart_te_error[ii]),
            .MS_MC_trActive_ANY			(ntr_active_w),
            .MS_MC_trStallModeEn_ANY	(ntr_stallmodeen_w),
            .MS_MC_trStartStop_ANY		(ntr_startstop_w),
            .MS_MC_trBackpressure_ANY	(ntr_backpressure_w),
            .MC_MS_trTrigControl_ANY	(trig_control_e),
            .cla_trigger_trace_start_ANY(ii < NUM_CLA_INST ? cla_trigger_trace_start[ii] : 1'b0),
            .cla_trigger_trace_stop_ANY	(ii < NUM_CLA_INST ? cla_trigger_trace_stop[ii] : 1'b0),
            .cla_trigger_trace_pulse_ANY(ii < NUM_CLA_INST ? cla_trigger_trace_pulse[ii] : 1'b0),
            .Trtecontrol				(Trtecontrol),
            .Trtscontrol				(Trtscontrol),
            .Trteimpl					(Trteimpl),
            .Trteinstfeatures			(Trteinstfeatures),
            .Trteinstfilters			(Trteinstfilters),
            .Trtefilter0Control			(Trtefilter0Control),
            .Trtefilter0Matchinst		(Trtefilter0Matchinst),
            .TrtecontrolWr				(TrtecontrolWr),
            .data_in					(ntrace_packet),
            .data_byte_be_in			(ntrace_packet_byte_enable),
            .request_packet_space_in_bytes	(ntrace_request_packet_space_in_bytes),
            .requested_packet_space_granted	(ntrace_requested_packet_space_granted),
            .trace_hardware_flush		(ntr_hardware_flush),
            .trace_hardware_stop		(ntr_hardware_stop),
            .flush_mode_enable			(ntrace_flush_mode_enable),
            .flush_mode_exit			(ntrace_flush_mode_exit),
            .packetizer_empty			(ntrace_packetizer_empty)
        );

        packetizer #(
            .PACKET_WIDTH_IN_BYTES(NTRACE_MAX_PACKET_WIDTH_IN_BYTES),
            .FIFO_ENTRIES(NTRACE_PACKETIZER_FIFO_DEPTH)
        ) n_trace_packetizer (
            .clock							(ntr_gated_clock[ii]),
            .i_reset_n						(ntr_gated_reset_n[ii]),
            .reset_n_warm_ovrride (ntr_gated_reset_n_warm_ovrride[ii]),
            .data_in						(ntrace_packet),
            .data_byte_be_in				(ntrace_packet_byte_enable),
            .request_packet_space_in_bytes	(ntrace_request_packet_space_in_bytes),
            .requested_packet_space_granted	(ntrace_requested_packet_space_granted),
            .tnif_req_out					(ntr_tnif_req_w),
            .tnif_data_pull_data_in			(tnif_ntr_pull[ii]),
            .tnif_data_out					(ntr_tnif_data_w),
            .flush_mode_enable				(ntrace_flush_mode_enable),
            .flush_mode_exit				(ntrace_flush_mode_exit),
            .packetizer_empty				(ntrace_packetizer_empty),
            .frame_info						(n_trace_frame_info),
            .stream_full					()
        );

        // Functional clamp applied at the wrapper boundary (leaf runs unclamped).
        assign o_ntr_tr_active[ii]        = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_active_w;
        assign o_ntr_tr_stall_mode_en[ii]   = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_stallmodeen_w;
        assign o_ntr_tr_start_stop[ii]     = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_startstop_w;
        assign o_ntr_tr_start_backpressure[ii]  = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_backpressure_w;
        assign ntr_tnif_req[ii]  = ntr_gated_func_clamp[ii] ? 1'b0 : ntr_tnif_req_w;
        assign ntr_tnif_data[ii] = ntr_gated_func_clamp[ii] ? '0   : ntr_tnif_data_w;
    end

endmodule
