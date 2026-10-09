module dst_wrapper
    import dst_pkg::*;
    import dst_mmr_pkg::*;
    import te_pkg::*;
    import packetizer_pkg::*;
#(
    parameter NUM_DST_INST = 1,
    parameter NUM_CLA_INST = 1,
    parameter NUM_NTRACE_INST = 1,
    parameter DEBUG_SIGNAL_WIDTH = 64,
    localparam int DATA_WIDTH = 128,
    localparam DEBUG_BUS_BYTE_ENABLE_WIDTH = DEBUG_SIGNAL_WIDTH/8,
    localparam MAX_DST_NTR_INST = (NUM_NTRACE_INST > NUM_DST_INST) ? NUM_NTRACE_INST : NUM_DST_INST,
    localparam VLT_HDR_WIDTH = 8 + DEBUG_BUS_BYTE_ENABLE_WIDTH,
    localparam VLT_PACKET_WIDTH = VLT_HDR_WIDTH + DEBUG_SIGNAL_WIDTH,
    // Zero-safe width for the unrelated CLA count (CLA may be absent while DST is present)
    localparam CLA_W = (NUM_CLA_INST == 0) ? 1 : NUM_CLA_INST
)(

    // Gated clock / reset / clamp from clk_rst_wrapper (per-instance)
    input logic [NUM_DST_INST-1:0] dst_gated_clock,
    input logic [NUM_DST_INST-1:0] dst_gated_reset_n,
    input logic [NUM_DST_INST-1:0] dst_gated_reset_n_warm_ovrride,
    input logic [NUM_DST_INST-1:0] dst_gated_func_clamp,

    // DST inputs
    input  logic      [NUM_DST_INST-1:0][DEBUG_SIGNAL_WIDTH-1:0] debug_bus,
    input  logic [NUM_DST_INST-1:0][63:0]                       i_timestamp,
    input  timestamp_s [NUM_DST_INST-1:0]                        timesync_cla_timestamp,

    // Trigger control (from N-Trace, used for sdtrig)
    input  logic [MAX_DST_NTR_INST-1:0] [1:0] i_sdtrig_control,

    // CLA inputs
    input  logic [CLA_W-1:0] cla_trigger_trace_start,
    input  logic [CLA_W-1:0] cla_trigger_trace_stop,
    input  logic [CLA_W-1:0] cla_trigger_trace_pulse,

    // MMRs
    input  DstMmrs_s   [NUM_DST_INST-1:0] DstMmrs,
    output DstMmrsWr_s [NUM_DST_INST-1:0] DstMmrsWr,

    // TNIF Interface
    input  logic [NUM_DST_INST-1:0] tnif_dst_pull,
    input  logic [NUM_DST_INST-1:0] tnif_dst_flush,
    input  logic [NUM_DST_INST-1:0] tnif_dst_bp,

    output logic [NUM_DST_INST-1:0] dst_tnif_req,
    output logic [NUM_DST_INST-1:0] [DATA_WIDTH-1:0] dst_tnif_data
);



    for (genvar ii = 0; ii < NUM_DST_INST; ii++) begin : dst_inst
        te_pkg::TrigTraceControl_e trig_control_e;
        assign trig_control_e = te_pkg::TrigTraceControl_e'(i_sdtrig_control[ii]);
        // Frame Info
        frame_info_s dst_trace_info;

        // Sdtrig to DST control connections
        logic sdtrig_dst_trace_start;
        logic sdtrig_dst_trace_stop;

        // Packetizer outputs (pre-clamp); clamped to the wrapper boundary below.
        logic                    dst_tnif_req_w;
        logic [DATA_WIDTH-1:0]   dst_tnif_data_w;
        DstMmrsWr_s     DstMmrsWr_int;

        // Generator <-> Packetizer interface
        logic [VLT_PACKET_WIDTH-1:0]            vlt_packet;
        logic [VLT_PACKET_WIDTH/8-1:0]          vlt_packet_byte_enable;
        logic [$clog2(VLT_PACKET_WIDTH/8):0]    dbg_trace_request_packet_space_in_bytes;
        logic                                   dbg_trace_requested_packet_space_granted;
        logic                                   dst_flush_mode_enable;
        logic                                   dst_flush_mode_exit;
        logic                                   dst_packetizer_empty;
        logic                                   stream_full;

        // TNIF-derived hardware flush/stop
        logic dst_hardware_flush;
        logic dst_hardware_stop;
        assign dst_hardware_flush = tnif_dst_flush[ii] & ~tnif_dst_bp[ii];
        assign dst_hardware_stop  = tnif_dst_flush[ii] &  tnif_dst_bp[ii];

        // DST MMRs
        DstTrdstcontrolMmr_s        Trdstcontrol;
        DstTrdstimplMmr_s           Trdstimpl;
        DstTrdstinstfeaturesMmr_s   Trdstinstfeatures;
        DstCdbgdebugtracecfgMmr_s   Cdbgdebugtracecfg;
        DstTrdstcontrolMmrWr_s      TrdstcontrolWr;

        assign Trdstcontrol      = DstMmrs[ii].Trdstcontrol;
        assign Trdstimpl         = DstMmrs[ii].Trdstimpl;
        assign Trdstinstfeatures = DstMmrs[ii].Trdstinstfeatures;
        assign Cdbgdebugtracecfg = DstMmrs[ii].Cdbgdebugtracecfg;
        // Functional clamp applied at the wrapper boundary (leaf runs unclamped).
        assign DstMmrsWr_int.TrdstcontrolWr = TrdstcontrolWr;

        // SDtrig (only valid when corresponding NTRACE exists)

        assign sdtrig_dst_trace_start = (trig_control_e == TRIG_TRACE_ON);
        assign sdtrig_dst_trace_stop  = (trig_control_e == TRIG_TRACE_OFF);

        // Frame Information
        assign dst_trace_info.stream_count_enable = (Trdstcontrol.Trdstsyncmode == STREAM_COUNT_DST_MODE);
        assign dst_trace_info.stream_depth        = (Trdstimpl.Trdstvendorstreamlength == $bits(Trdstimpl.Trdstvendorstreamlength)'(3'b000)) ?
                                                        (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH))      : (Trdstimpl.Trdstvendorstreamlength == $bits(Trdstimpl.Trdstvendorstreamlength)'(3'b001)) ?
                                                        (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 1 : (Trdstimpl.Trdstvendorstreamlength == $bits(Trdstimpl.Trdstvendorstreamlength)'(3'b010)) ?
                                                        (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 2 : (Trdstimpl.Trdstvendorstreamlength == $bits(Trdstimpl.Trdstvendorstreamlength)'(3'b011)) ?
                                                        (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 3 : (Trdstimpl.Trdstvendorstreamlength == $bits(Trdstimpl.Trdstvendorstreamlength)'(3'b100)) ?
                                                        (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 4 : (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH));
        assign dst_trace_info.frame_length        = {Trdstimpl.Trdstvendorframelength, 6'b0};
        assign dst_trace_info.frame_fill_byte     = Cdbgdebugtracecfg.TraceFrameFillByte;
        assign dst_trace_info.frame_mode_enable   = Cdbgdebugtracecfg.FrameModeEnable;
        assign dst_trace_info.frame_closure_mode  = Cdbgdebugtracecfg.FrameClosureMode;

        debug_sig_trace_gen #(
            .DEBUG_SIGNAL_WIDTH(DEBUG_SIGNAL_WIDTH)
        ) debug_sig_trace_gen (
            .clock					(dst_gated_clock[ii]),
            .i_reset_n				(dst_gated_reset_n[ii]),
            .reset_n_warm_ovrride (dst_gated_reset_n_warm_ovrride[ii]),
            .trace_start			((ii < NUM_CLA_INST ? cla_trigger_trace_start[ii] : 1'b0) | (sdtrig_dst_trace_start & Trdstcontrol.Trdstinsttriggerenable)),
            .trace_stop				((ii < NUM_CLA_INST ? cla_trigger_trace_stop[ii]  : 1'b0) | (sdtrig_dst_trace_stop  & Trdstcontrol.Trdstinsttriggerenable)),
            .trace_pulse			((ii < NUM_CLA_INST ? cla_trigger_trace_pulse[ii] : 1'b0)),
            .Trdstinstfeatures	    (Trdstinstfeatures),
            .Trdstcontrol			(Trdstcontrol),
            .Trdstimpl				(Trdstimpl),
            .TrdstcontrolWr			(TrdstcontrolWr),
            .timestamp		        (dst_pkg::timestamp_s'(i_timestamp[ii])),
            .cla_timesync_timestamp	(timesync_cla_timestamp[ii]),
            .trace_hardware_flush	(dst_hardware_flush),
            .trace_hardware_stop	(dst_hardware_stop),
            .debug_bus_in			(debug_bus[ii]),
            .debug_bus_byte_enable	('0),
            .vlt_packet				(vlt_packet),
            .vlt_packet_byte_enable	(vlt_packet_byte_enable),
            .flush_mode_enable		(dst_flush_mode_enable),
            .flush_mode_exit		(dst_flush_mode_exit),
            .packetizer_empty		(dst_packetizer_empty),
            .request_packet_space_in_bytes	(dbg_trace_request_packet_space_in_bytes),
            .requested_packet_space_granted	(dbg_trace_requested_packet_space_granted),
            .stream_full			(stream_full)
        );

        packetizer #(
            .PACKET_WIDTH_IN_BYTES(VLT_PACKET_WIDTH / 8),
            .FIFO_ENTRIES(DBG_TRACE_PACKETIZER_FIFO_DEPTH)
        ) debug_sig_trace_packetizer (
            .clock							(dst_gated_clock[ii]),
            .i_reset_n						(dst_gated_reset_n[ii]),
            .reset_n_warm_ovrride (dst_gated_reset_n_warm_ovrride[ii]),
            .data_in						(vlt_packet),
            .data_byte_be_in				(vlt_packet_byte_enable),
            .request_packet_space_in_bytes	(dbg_trace_request_packet_space_in_bytes),
            .requested_packet_space_granted	(dbg_trace_requested_packet_space_granted),
            .tnif_req_out					(dst_tnif_req_w),
            .tnif_data_pull_data_in			(tnif_dst_pull[ii]),
            .tnif_data_out					(dst_tnif_data_w),
            .flush_mode_enable				(dst_flush_mode_enable),
            .flush_mode_exit				(dst_flush_mode_exit),
            .packetizer_empty				(dst_packetizer_empty),
            .frame_info						(dst_trace_info),
            .stream_full					(stream_full)
        );

        // Functional clamp applied at the wrapper boundary (leaf runs unclamped).
        assign dst_tnif_req[ii]  = dst_gated_func_clamp[ii] ? 1'b0 : dst_tnif_req_w;
        assign dst_tnif_data[ii] = dst_gated_func_clamp[ii] ? '0   : dst_tnif_data_w;
        assign DstMmrsWr[ii]     = dst_gated_func_clamp[ii] ? '0 : DstMmrsWr_int;
    end

endmodule
