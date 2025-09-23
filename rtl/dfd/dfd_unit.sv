// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

/*
	This block contains the encaoders for both NTrace and DST (Debug Signal Trace) alongisde a TNIF.

	There are parameter to enable/disable generation of NTrace and DST respectively. If both are disabled,
*/

module dfd_unit
  import dfd_dst_pkg::*;
  import dfd_dst_csr_pkg::*;
  import dfd_ntr_csr_pkg::*;
  import dfd_cla_pkg::*;
  import dfd_packetizer_pkg::*;
  import dfd_te_pkg::*;
  import dfd_tn_pkg::*;
#(
    parameter DATA_WIDTH_IN_BYTES = 16,
	parameter BASE_ADDR = 0,
    parameter NTRACE_SUPPORT = 1,
    parameter DST_SUPPORT = 1
) (
    //Globals
    input  logic clk,
    input  logic reset_n,
    input  logic reset_n_warm_ovrride,

	// CLA
	input  logic external_action_trace_start,
	input  logic external_action_trace_stop,
	input  logic external_action_trace_pulse,
	input  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_bus,

    // Timestamp value
    input  timestamp_s 	CoreTime,

    // MMR Registers
	// verilint W240 off
	input  DstCsrs_s 	DstCsrs,
	input  NtrCsrs_s 	NtrCsrs,
	output DstCsrsWr_s 	DstCsrsWr,
	output NtrCsrsWr_s 	NtrCsrsWr,
	// verilint W240 on
	
    // MC BTHB connections to TE
	// verilint W240 off
    input logic [NUM_BLOCKS-1:0][IRETIRE_WIDTH-1:0] IRetire,
    input logic [NUM_BLOCKS-1:0][  ITYPE_WIDTH-1:0] IType,
    input logic [NUM_BLOCKS-1:0][     PC_WIDTH-1:1] IAddr,
    input logic [NUM_BLOCKS-1:0]                    ILastSize,
    input logic [TSTAMP_WIDTH-1:0]                  Tstamp,

    input  PrivMode_e                     			Priv,
    input  logic      [CONTEXT_WIDTH-1:0] 			Context,
    input  logic      [TVAL_WIDTH-1:0]    			Tval,

    // Side-Band signals from/to BTHB
    input  logic         							Error,
    output logic         							Active,
    output logic         							StallModeEn,
    output logic         							StartStop,
    output logic         							Backpressure,

    // Trigger module actions output
    input  TrigTraceControl_e  						TrigControl,
	// verilint W240 on

    //TNIF Connectivity
    input  logic  tnif_tr_gnt_in,
    input  logic  tnif_dst_bp_in, tnif_ntr_bp_in,
    input  logic  tnif_dst_flush_in, tnif_ntr_flush_in,

    output logic  tnif_tr_vld_out,
    output logic  tnif_tr_src_out,
    output logic  [DATA_WIDTH_IN_BYTES*8-1:0] tnif_tr_data_out
);

	//Interface from Packetizers to TNIF
	logic dbg_packetizer_req_out;
	logic dbg_packetizer_pull_data_in;
	logic [DATA_WIDTH_IN_BYTES*8-1:0] dbg_packetizer_data_out;

	logic ntrace_packetizer_req_out;
	logic ntrace_packetizer_pull_data_in;
	logic [DATA_WIDTH_IN_BYTES*8-1:0] ntrace_packetizer_data_out;

	//Hardware flush/stop control signals to source generators
	logic  dst_hardware_flush, ntr_hardware_flush;
	logic  dst_hardware_stop, ntr_hardware_stop;
	logic  tnif_dst_flush_out, tnif_ntr_flush_out;
	logic  tnif_dst_bp_out, tnif_ntr_bp_out;

	// MISC (unused)
	logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0] debug_bus_byte_enable;
	logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] debug_source;

	generate
		//Instantiate the Debug Sig Trace Gen Block if enabled
		if (DST_SUPPORT == 1) begin

			// Frame Info
			frame_info_s dst_trace_info;

			// Sdtrig to DST control connections
			logic sdtrig_dst_trace_start;
			logic sdtrig_dst_trace_stop;

			//Signals from VLT Generator to Packetizer
			logic [VLT_PACKET_WIDTH-1:0] vlt_packet;
			logic [VLT_PACKET_WIDTH/8-1:0] vlt_packet_byte_enable;
			logic dst_flush_mode_enable;
			logic [$clog2(VLT_PACKET_WIDTH/8):0] dbg_trace_request_packet_space_in_bytes;
			
			//Signals from Packetizer to VLT Generator
			logic  dst_flush_mode_exit, dst_packetizer_empty;
			logic  dbg_trace_requested_packet_space_granted;
			logic  stream_full;

			// DST MMRs
			Cr4BTrdstcontrolCsr_s        Cr4BCsrTrdstcontrol;
			Cr4BTrdstimplCsr_s           Cr4BCsrTrdstimpl;
			Cr4BTrdstinstfeaturesCsr_s   Cr4BCsrTrdstinstfeatures;
			Cr4BCdbgdebugtracecfgCsr_s   Cr4BCsrCdbgdebugtracecfg;
			Cr4BTrdstcontrolCsrWr_s      Cr4BCsrTrdstcontrolWr;

			assign Cr4BCsrTrdstcontrol = DstCsrs.Cr4BCsrTrdstcontrol;
			assign Cr4BCsrTrdstimpl = DstCsrs.Cr4BCsrTrdstimpl;
			assign Cr4BCsrTrdstinstfeatures = DstCsrs.Cr4BCsrTrdstinstfeatures;
			assign Cr4BCsrCdbgdebugtracecfg = DstCsrs.Cr4BCsrCdbgdebugtracecfg;
			assign DstCsrsWr.Cr4BCsrTrdstcontrolWr = Cr4BCsrTrdstcontrolWr;
			assign DstCsrsWr.Cr4BCsrTrdstimplWr = '0;
			assign DstCsrsWr.Cr4BCsrTrdstinstfeaturesWr = '0;

			// SDtrig
			assign sdtrig_dst_trace_start = (TrigControl == TRIG_TRACE_ON);
			assign sdtrig_dst_trace_stop = (TrigControl == TRIG_TRACE_OFF);

			// Generate Frame Information
			assign dst_trace_info.stream_count_enable    = (Cr4BCsrTrdstcontrol.Trdstsyncmode == STREAM_COUNT_DST_MODE);
			assign dst_trace_info.stream_depth           = (Cr4BCsrTrdstimpl.Trdstvendorstreamlength == $bits(Cr4BCsrTrdstimpl.Trdstvendorstreamlength)'(3'b000)) ?  // = (32 * 2^Cr4BCsrTrdstimpl.Trdstvendorstreamlength)
																												(($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH))      : (Cr4BCsrTrdstimpl.Trdstvendorstreamlength == $bits(Cr4BCsrTrdstimpl.Trdstvendorstreamlength)'(3'b001)) ? // 32
																												(($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 1 : (Cr4BCsrTrdstimpl.Trdstvendorstreamlength == $bits(Cr4BCsrTrdstimpl.Trdstvendorstreamlength)'(3'b010)) ? // 64
																												(($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 2 : (Cr4BCsrTrdstimpl.Trdstvendorstreamlength == $bits(Cr4BCsrTrdstimpl.Trdstvendorstreamlength)'(3'b011)) ? // 128
																												(($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 3 : (Cr4BCsrTrdstimpl.Trdstvendorstreamlength == $bits(Cr4BCsrTrdstimpl.Trdstvendorstreamlength)'(3'b100)) ? // 256
																												(($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)) << 4 : (($clog2(MAX_STREAM_DEPTH)+1)'(MIN_STREAM_DEPTH)); // 512
			assign dst_trace_info.frame_length           = {Cr4BCsrTrdstimpl.Trdstvendorframelength, 6'b0};
			assign dst_trace_info.frame_fill_byte        = Cr4BCsrCdbgdebugtracecfg.TraceFrameFillByte;
			assign dst_trace_info.frame_mode_enable      = Cr4BCsrCdbgdebugtracecfg.FrameModeEnable;
			assign dst_trace_info.frame_closure_mode     = Cr4BCsrCdbgdebugtracecfg.FrameClosureMode;

			dfd_debug_sig_trace_gen dfd_debug_sig_trace_gen
			(
				.clock					(clk),
				.reset_n				(reset_n),
				.trace_start			(external_action_trace_start | (sdtrig_dst_trace_start & Cr4BCsrTrdstcontrol.Trdstinsttriggerenable)),
				.trace_stop				(external_action_trace_stop | (sdtrig_dst_trace_stop & Cr4BCsrTrdstcontrol.Trdstinsttriggerenable)),
				.trace_pulse			(external_action_trace_pulse),
				.debug_source 			(Cr4BCsrTrdstinstfeatures.Trdstsrcid[DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0]),
				.Cr4BCsrTrdstcontrol	(Cr4BCsrTrdstcontrol),
				.Cr4BCsrTrdstcontrolWr	(Cr4BCsrTrdstcontrolWr),
				.timestamp				(CoreTime),

				.trace_hardware_flush	(dst_hardware_flush),
				.trace_hardware_stop	(dst_hardware_stop),

				.debug_bus_in			(debug_bus),
				.debug_bus_byte_enable	('0),  //FIXME_MUSTFIX_NONATHENA: Future optimization, if CLA implements Byte Enables.

				.vlt_packet				(vlt_packet),
				.vlt_packet_byte_enable	(vlt_packet_byte_enable),
				.flush_mode_enable		(dst_flush_mode_enable),
				.flush_mode_exit		(dst_flush_mode_exit),
				.packetizer_empty		(dst_packetizer_empty),
				.request_packet_space_in_bytes	(dbg_trace_request_packet_space_in_bytes),
				.requested_packet_space_granted	(dbg_trace_requested_packet_space_granted),
				.stream_full			(stream_full)
			);

			dfd_packetizer #(
				.PACKET_WIDTH_IN_BYTES(VLT_PACKET_WIDTH / 8),
				.FIFO_ENTRIES(DBG_TRACE_PACKETIZER_FIFO_DEPTH)
			) debug_sig_trace_packetizer (
				.clock							(clk),
				.reset_n						(reset_n),
				.data_in						(vlt_packet),
				.data_byte_be_in				(vlt_packet_byte_enable),
				.request_packet_space_in_bytes	(dbg_trace_request_packet_space_in_bytes),
				.requested_packet_space_granted	(dbg_trace_requested_packet_space_granted),
				.tnif_req_out					(dbg_packetizer_req_out),
				.tnif_data_pull_data_in			(dbg_packetizer_pull_data_in),
				.tnif_data_out					(dbg_packetizer_data_out),
				.flush_mode_enable				(dst_flush_mode_enable),
				.flush_mode_exit				(dst_flush_mode_exit),
				.packetizer_empty				(dst_packetizer_empty),
				.frame_info						(dst_trace_info),
				.stream_full					(stream_full)
			);
			
		end else begin
			assign dbg_packetizer_req_out = '0;
			assign dbg_packetizer_data_out = '0;
		end

		if (NTRACE_SUPPORT == 1) begin
			
			// Frame Info
			frame_info_s n_trace_frame_info;

			//Interface from N-Trace Encoder to Packetizer
			logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0] ntrace_packet;
			logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0] ntrace_packet_byte_enable;
			logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0] ntrace_request_packet_space_in_bytes;
			logic ntrace_flush_mode_enable;

			// Interface from Packetizer to N-Trace Encoder
			logic ntrace_requested_packet_space_granted;
			logic ntrace_flush_mode_exit, ntrace_packetizer_empty;

			// Ntrace MMR
			Cr4BTrtecontrolCsr_s                     Cr4BCsrTrtecontrol;
			Cr4BTrteimplCsr_s                        Cr4BCsrTrteimpl;
			Cr4BTrteinstfeaturesCsr_s                Cr4BCsrTrteinstfeatures;
			Cr4BTrteinstfiltersCsr_s                 Cr4BCsrTrteinstfilters;
			Cr4BTrtefilter0ControlCsr_s              Cr4BCsrTrtefilter0Control;
			Cr4BTrtefilter0MatchinstCsr_s            Cr4BCsrTrtefilter0Matchinst;
			Cr4BCdbgntraceframecfgCsr_s              Cr4BCsrCdbgntraceframecfg;
			Cr4BTrtecontrolCsrWr_s                   Cr4BCsrTrtecontrolWr;

			assign Cr4BCsrTrtecontrol = NtrCsrs.Cr4BCsrTrtecontrol;
			assign Cr4BCsrTrteimpl = NtrCsrs.Cr4BCsrTrteimpl;
			assign Cr4BCsrTrteinstfeatures = NtrCsrs.Cr4BCsrTrteinstfeatures;
			assign Cr4BCsrTrteinstfilters = NtrCsrs.Cr4BCsrTrteinstfilters;
			assign Cr4BCsrTrtefilter0Control = NtrCsrs.Cr4BCsrTrtefilter0Control;
			assign Cr4BCsrTrtefilter0Matchinst = NtrCsrs.Cr4BCsrTrtefilter0Matchinst;
			assign Cr4BCsrCdbgntraceframecfg = NtrCsrs.Cr4BCsrCdbgntraceframecfg;
			assign NtrCsrsWr.Cr4BCsrTrtecontrolWr = Cr4BCsrTrtecontrolWr;
			assign NtrCsrsWr.Cr4BCsrTrteimplWr = '0;

			// Generate Frame Information
			assign n_trace_frame_info.stream_count_enable = '0;
			assign n_trace_frame_info.stream_depth       = '0;
			assign n_trace_frame_info.frame_length       = {Cr4BCsrTrteimpl.Trtevendorframelength, 6'b0};
			assign n_trace_frame_info.frame_fill_byte    = Cr4BCsrCdbgntraceframecfg.TraceFrameFillByte;
			assign n_trace_frame_info.frame_mode_enable  = Cr4BCsrCdbgntraceframecfg.FrameModeEnable;
			assign n_trace_frame_info.frame_closure_mode = Cr4BCsrCdbgntraceframecfg.FrameClosureMode;

			dfd_te_encoder ntrace_encoder (
					.clock  		(clk),
					.reset_n		(reset_n),

					.trIRetire_RE6	(IRetire),
					.trIType_RE6	(IType),
					.trIAddr_RE6	(IAddr),
					.trILastSize_RE6(ILastSize),
					.trPriv_RE6		(Priv),
					.trContext_RE6	(Context),
					.trTstamp_RE6	(Tval),
					.trTval_RE6		(Tstamp),

					.MC_MS_trError_RE6			(Error),
					.MS_MC_trActive_ANY			(Active),
					.MS_MC_trStallModeEn_ANY	(StallModeEn),
					.MS_MC_trStartStop_ANY		(StartStop),
					.MS_MC_trBackpressure_ANY	(Backpressure),
					.MC_MS_trTrigControl_ANY	(TrigControl),

					.Cr4BTrtecontrol			(Cr4BCsrTrtecontrol),
					.Cr4BTrteimpl				(Cr4BCsrTrteimpl),
					.Cr4BTrteinstfeatures		(Cr4BCsrTrteinstfeatures),
					.Cr4BTrteinstfilters		(Cr4BCsrTrteinstfilters),
					.Cr4BTrtefilter0Control		(Cr4BCsrTrtefilter0Control),
					.Cr4BTrtefilter0Matchinst	(Cr4BCsrTrtefilter0Matchinst),
					.Cr4BTrtecontrolWr			(Cr4BCsrTrtecontrolWr),

					.cla_trigger_trace_start_ANY(external_action_trace_start),
					.cla_trigger_trace_stop_ANY	(external_action_trace_stop),
					.cla_trigger_trace_pulse_ANY(external_action_trace_pulse),

					.data_in					(ntrace_packet),
					.data_byte_be_in			(ntrace_packet_byte_enable),
					.request_packet_space_in_bytes	(ntrace_request_packet_space_in_bytes),
					.requested_packet_space_granted	(ntrace_requested_packet_space_granted),

					.trace_hardware_flush		(ntr_hardware_flush),
					.trace_hardware_stop		(ntr_hardware_stop),

					.flush_mode_enable			(ntrace_flush_mode_enable),
					.flush_mode_exit  			(ntrace_flush_mode_exit),
					.packetizer_empty 			(ntrace_packetizer_empty)
			);

			dfd_packetizer #(
					.PACKET_WIDTH_IN_BYTES(NTRACE_MAX_PACKET_WIDTH_IN_BYTES),
					.FIFO_ENTRIES(NTRACE_PACKETIZER_FIFO_DEPTH)
			) n_trace_packetizer (
					.clock							(clk),
					.reset_n						(reset_n),
					.data_in						(ntrace_packet),
					.data_byte_be_in				(ntrace_packet_byte_enable),
					.request_packet_space_in_bytes	(ntrace_request_packet_space_in_bytes),
					.requested_packet_space_granted	(ntrace_requested_packet_space_granted),
					.tnif_req_out					(ntrace_packetizer_req_out),
					.tnif_data_pull_data_in			(ntrace_packetizer_pull_data_in),
					.tnif_data_out					(ntrace_packetizer_data_out),
					.flush_mode_enable				(ntrace_flush_mode_enable),
					.flush_mode_exit				(ntrace_flush_mode_exit),
					.packetizer_empty				(ntrace_packetizer_empty),
					.frame_info						(n_trace_frame_info),
					.stream_full					()
			);
			
		end else begin
			assign Active = '0;
			assign StallModeEn = '0;
			assign StartStop = '0;
			assign Backpressure = '0;

			assign ntrace_packetizer_req_out = '0;
			assign ntrace_packetizer_data_out = '0;

			assign NtrCsrsWr = '0;
		end

		if ((DST_SUPPORT == 1) || (NTRACE_SUPPORT == 1)) begin
			// TNIF to Signal Generator Flush and Stop
			assign dst_hardware_flush = tnif_dst_flush_out & ~tnif_dst_bp_out;
			assign ntr_hardware_flush = tnif_ntr_flush_out & ~tnif_ntr_bp_out;

			assign dst_hardware_stop = tnif_dst_flush_out & tnif_dst_bp_out;
			assign ntr_hardware_stop = tnif_ntr_flush_out & tnif_ntr_bp_out;

			dfd_tnif i_tnif (
				.clock  		(clk),
				.reset_n		(reset_n),

				.dst_req_in 	(dbg_packetizer_req_out),
				.ntr_req_in 	(ntrace_packetizer_req_out),
				.dst_data_in	(dbg_packetizer_data_out),
				.ntr_data_in	(ntrace_packetizer_data_out),

				.dst_pull_out	(dbg_packetizer_pull_data_in),
				.ntr_pull_out	(ntrace_packetizer_pull_data_in),

				.dst_flush_out	(tnif_dst_flush_out),
				.ntr_flush_out	(tnif_ntr_flush_out),
				.dst_bp_out		(tnif_dst_bp_out),
				.ntr_bp_out		(tnif_ntr_bp_out),

				.tr_gnt_in		(tnif_tr_gnt_in),
				.dst_bp_in		(tnif_dst_bp_in),
				.ntr_bp_in		(tnif_ntr_bp_in),
				.dst_flush_in	(tnif_dst_flush_in),
				.ntr_flush_in	(tnif_ntr_flush_in),

				.tr_valid_out	(tnif_tr_vld_out),
				.tr_src_out  	(tnif_tr_src_out),
				.tr_data_out 	(tnif_tr_data_out)
			);
		end else begin
			assign tnif_tr_vld_out = '0;
			assign tnif_tr_src_out = '0;
			assign tnif_tr_data_out = '0;
		end

	endgenerate

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eus]$"
// End:

