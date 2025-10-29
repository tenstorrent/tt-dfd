// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

 // Trace Encoder: Generates trace messages as specified by N-trace protocol
module dfd_te_encoder import dfd_te_pkg::*; import dfd_tr_csr_pkg::*; import dfd_ntr_csr_pkg::*; #(
    parameter PKT_FIFO_CNT = 12                                  // The packet FIFO count before sending to dfd_packetizer
  )(
  input   logic                                                 clock,
  input   logic                                                 reset_n,

  // RISC-V Standard Hart to TE interface
  input   logic [NUM_BLOCKS-1:0] [IRETIRE_WIDTH-1:0]            trIRetire_RE6,
  input   logic [NUM_BLOCKS-1:0] [ITYPE_WIDTH-1:0]              trIType_RE6,
  input   logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                 trIAddr_RE6,
  input   logic [NUM_BLOCKS-1:0]                                trILastSize_RE6,

  input   PrivMode_e                                            trPriv_RE6,
  input   logic [CONTEXT_WIDTH-1:0]                             trContext_RE6,
  input   logic [TSTAMP_WIDTH-1:0]                              trTstamp_RE6,
  input   logic [TVAL_WIDTH-1:0]                                trTval_RE6,

  // Side-Band signals from/to BTHB
  input   logic                                                 MC_MS_trError_RE6,
  output  logic                                                 MS_MC_trActive_ANY,
  output  logic                                                 MS_MC_trStallModeEn_ANY,
  output  logic                                                 MS_MC_trStartStop_ANY,
  output  logic                                                 MS_MC_trBackpressure_ANY,

  // Trigger module actions output from MC
  input   TrigTraceControl_e                                    MC_MS_trTrigControl_ANY,

  // CLA trace control triggers
  input   logic                                                 cla_trigger_trace_start_ANY,
  input   logic                                                 cla_trigger_trace_stop_ANY,
  input   logic                                                 cla_trigger_trace_pulse_ANY,

  // Trace MMRs
  input   Cr4BTrtecontrolCsr_s                                  Cr4BTrtecontrol,
  input   Cr4BTrteimplCsr_s                                     Cr4BTrteimpl,
  input   Cr4BTrteinstfeaturesCsr_s                             Cr4BTrteinstfeatures,
  input   Cr4BTrteinstfiltersCsr_s                              Cr4BTrteinstfilters,
  input   Cr4BTrtefilter0ControlCsr_s                           Cr4BTrtefilter0Control,
  input   Cr4BTrtefilter0MatchinstCsr_s                         Cr4BTrtefilter0Matchinst,
  output  Cr4BTrtecontrolCsrWr_s                                Cr4BTrtecontrolWr,

  // Trace Encoder to Packetizer Interface
  output  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0]        data_in,
  output  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0]          data_byte_be_in,
  output  logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0]    request_packet_space_in_bytes,
  input   logic                                                 requested_packet_space_granted,

  input   logic                                                 trace_hardware_flush,
  input   logic                                                 trace_hardware_stop,

  output  logic                                                 flush_mode_enable,
  input   logic                                                 flush_mode_exit,
  input   logic                                                 packetizer_empty
);

  // --------------------------------------------------------------------------
  // Internal Signals
  // --------------------------------------------------------------------------

  logic [NUM_BLOCKS-1:0] [IRETIRE_WIDTH-1:0]                    trIRetire_TE0;
  logic [NUM_BLOCKS-1:0] [ITYPE_WIDTH-1:0]                      trIType_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         trIAddr_TE0;
  logic [NUM_BLOCKS-1:0]                                        trILastSize_TE0;

  PrivMode_e                                                    trPriv_TE0;
  logic [CONTEXT_WIDTH-1:0]                                     trContext_TE0;
  logic [TVAL_WIDTH-1:0]                                        trTval_TE0;
  logic [TSTAMP_WIDTH-1:0]                                      trTstamp_TE0;

  // Pipe valid signals for the TE0 and TE1 stages
  logic [NUM_BLOCKS-1:0]                                        pipe_vld_RE6, pipe_vld_TE0, pipe_vld_TE1;
  logic [NUM_BLOCKS-1:0]                                        packet_pipe_vld_TE0, packet_pipe_vld_TE1;
  logic                                                         rb_packet_pipe_vld_TE1, rb_packet_pipe_vld_TE2;
  logic [NUM_BLOCKS-1:0]                                        own_vdm_packet_pipe_vld_TE0, own_vdm_packet_pipe_vld_TE1;

  // PrivMode and Start/Stop handling for Encoder
  PrivMode_e                                                    trEncPriv_TE0;
  logic                                                         trBthbStartStop_ANY, trBthbStartStop_ANY_d1;

  // Trace Start/Stop signals
  logic                                                         trStartStop_ANY, trStartStop_ANY_d1;
  logic                                                         trace_hardware_stop_d1;
  logic                                                         trProgressed_after_DebugEntry_ANY;
  logic                                                         trStart_ANY, trStop_ANY, trStop_ANY_d1;
  logic                                                         trSwControlStop_ANY, trSwControlStop_ANY_m1, trSwControlStop_PTC_pending_ANY;
  logic                                                         trTeActive_ANY, trTeActive_ANY_d1;
  logic                                                         trTeEnable_ANY, trTeEnable_ANY_d1;
  logic                                                         trTeSwEnable_ANY;
  logic                                                         trTeInsttracing_Enable_ANY, trTeInsttracing_Enable_ANY_d1;
  logic                                                         trTeEnable_Trace_ANY, trTeEnable_Trace_ANY_d1;
  logic                                                         trFlush_ANY; 
  logic                                                         trReEnable_ANY;
  logic                                                         trTeTrigEnable_ANY;
  logic                                                         trStartfromTrig_ANY, trStopfromTrig_ANY, trNotifyfromTrig_ANY;
  logic                                                         trNotifySyncfromTrig_ANY;
  logic                                                         trTeTracingStartfromTrigger_ANY;
  logic                                                         trTracingInProgress_ANY, trTracingInProgress_ANY_d1;
  logic                                                         trBackpressure_ANY;
  logic                                                         trace_stop_after_error_wo_sync;

  logic                                                         trace_hardware_flush_d1;
  logic                                                         trace_hardware_flush_pulse, trace_hardware_flush_pulse_valid;
  logic                                                         trace_hw_flush_in_progress;
  logic                                                         trPacketizer_Flushmode_enable_ANY;

  // Patch control signals
  logic                                                         trTeTraceInPatchEnable_ANY;
  
  // CLA trace trigger control signals
  logic                                                         trTeCLATrigEnable_ANY;
  logic                                                         trStartfromCLA_ANY, trStopfromCLA_ANY, trPulsefromCLA_ANY;

  // Trace filtering control signals
  logic                                                         trPrivModeFilterEnable_ANY;
  PrivMode_e                                                    trPrivModeFilterChoice_ANY;
  logic                                                         trPrivFiltered_RE6, trPrivFiltered_TE0;

  // Entry and Exit from Debug Debug mode
  logic                                                         trPrivisDebug_RE6, trPrivisDebug_TE0, trPrivisDebug_TE1;
  logic                                                         trPrivDebugModeEntry_ANY, trPrivDebugEntry_PTC_pending_ANY;
  logic                                                         trPrivDebugModeExit_ANY, trPrivDebugModeExit_ANY_d1;
  logic                                                         trTeReStartAfterDebugMode_ANY;

  // Internal HIST register
  logic [HIST_WIDTH-1:0]                                        hist_TE1, next_hist_TE0;
  logic [NUM_BLOCKS-1:0] [HIST_WIDTH-1:0]                       hist_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_hist_to_report_TE0;
  logic [CONTEXT_WIDTH+5-1:0]                                   context_to_report_TE0; 
  logic [NUM_BLOCKS-1:0]                                        is_hist_overflow_to_report_TE0;
  logic [HIST_WIDTH-1:0]                                        hist_overflow_to_report_TE0, hist_overflow_to_report_delay;

  // Internal ICount Field Registers
  logic [ICOUNT_WIDTH-1:0]                                      iCount_TE1, next_iCount_TE0;
  logic [NUM_BLOCKS-1:0] [ICOUNT_WIDTH-1:0]                     iCount_to_report_TE0;
  logic [ICOUNT_WIDTH-1:0]                                      trStop_iCount_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_iCount_overflow_TE0;
  logic                                                         trStop_iCount_Hist_to_report_TE0, trStop_iCount_Hist_to_report_TE1;

  // Sequential I-Count overflow
  logic [NUM_BLOCKS-1:0]                                        seq_icnt_overflow_TE0;
  logic                                                         seq_icnt_overflow_delay;
  logic [PC_WIDTH-1:1]                                          seq_icnt_overflow_faddr_to_report;

  //Auxilary IBH packets in case of SIC - IBHS or Rsfull ICNT
  logic                                                         aux_ibh_packet_pipe_vld_TE0;
  logic                                                         aux_ibh_use_sic_uaddr_TE0;
  logic                                                         aux_ibh_packet_tgt_pending_TE0;
  logic [ICOUNT_WIDTH-1:0]                                      aux_ibh_packet_icount_TE0;
  logic [PC_WIDTH-1:1]                                          aux_ibh_uaddr_TE0;

  // Select betweeen I-CNT and HIST reporting cases in RESOURCEFULL packet
  logic [NUM_BLOCKS-1:0]                                        rsfull_msg_vld_ANY, rsfull_msg_icnt_or_hist_TE0; //0-ICNT, 1-HIST

  // Control signal to clear the internal state varaibles after PTC
  logic                                                         trCorrelationMessageSent_ANY;

  // Context switch -> Generate ownership packet
  logic                                                         context_switch_TE0, context_switch_TE1, context_switch_report_pend, context_switch_IBH_reported_TE0, context_switch_IBH_reported_TE1;
  logic                                                         own_vdm_packet_pipe_is_vdm_vld_TE0;
  
  logic                                                         is_tval_to_report_TE0, is_tval_to_report_TE1, is_tval_to_report_pend;
  logic [TVAL_WIDTH-1:0]                                        tval_to_report_TE0;

  // B-Type field
  logic [NUM_BLOCKS-1:0] [BTYPE_WIDTH-1:0]                      bType_to_report_TE0, ibh_btype_reported_TE0, ibh_btype_reported_TE1;
  logic [BTYPE_WIDTH-1:0]                                       pend_btype_to_report_delay;

  // B-CNT field
  logic [BCNT_WIDTH-1:0]                                        bcnt_TE2, next_bcnt_TE1, bcnt_to_report_TE1;
  logic [NUM_BLOCKS-1:0]                                        is_bcnt_overflow_cond_hit_TE1;
  logic                                                         bcnt_overflow_TE1, bcnt_TE2_overflowed;

  // Reference Address for U-ADDR computation
  logic [PC_WIDTH-1:1]                                          ref_addr_TE1;
  /* verilator lint_off UNOPTFLAT */
  logic [NUM_BLOCKS-1:0]                                        next_ref_addr_vld_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         next_ref_addr_TE0;
   /* verilator lint_on UNOPTFLAT */
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         u_addr_TE0;

  // Indirect Branch Instruction
  logic [NUM_BLOCKS-1:0]                                        indirectBranchInst_TE0;

  // Time-stamp
  logic [TSTAMP_WIDTH-1:0]                                      trTstamp_TE1;
  logic [TSTAMP_WIDTH-1:0]                                      trStop_tstamp_TE0;

  // SyncPending flop & Periodic counters
  InstSyncMode_e                                                InstSyncMode;
  logic [PERIODIC_SYNC_COUNT_WIDTH-1:0]                         periodic_sync_count;
  logic [PERIODIC_SYNC_COUNT_WIDTH:0]                           periodic_sync_max_count, periodic_sync_pkt_count, periodic_sync_iretire_count, periodic_sync_cycle_count;
  logic [PERIODIC_SYNC_COUNT_WIDTH-1:0]                         next_periodic_sync_count, next_periodic_sync_pkt_count, next_periodic_sync_iretire_count, next_periodic_sync_cycle_count;
  logic                                                         periodic_sync_pkt_count_overflow, periodic_sync_cycle_count_overflow, periodic_sync_iretire_count_overflow;
  logic                                                         periodic_sync_count_overflow, periodic_sync_count_overflow_delay, periodic_sync_count_overflow_stg;
  logic                                                         periodic_sync_count_clr;
  logic                                                         trIBHS_trig_psync_ANY, trIBHS_trig_psync_ANY_delay;

  //Sdtrig Notify
  logic                                                         trNotifyIBHS_ANY, trNotifyIBHS_ANY_delay;

  // Curr packet being generated in TE0 stage
  Pkt_TCode_e [NUM_BLOCKS-1:0]                                  curr_pkt_TE0, curr_pkt_TE1;

  // Entry to be written in the packet buffer
  pkt_buffer_t [NUM_BLOCKS-1:0]                                 pkt_buffer_data_TE1, own_vdm_pkt_buffer_data_TE1;
  pkt_buffer_t                                                  rb_pkt_buffer_data_TE1;
  logic                                                         pkt_fifo_pop;
  
  logic [NUM_BLOCKS-1:0]                                        dataBlock, addrBlock;
  logic [NUM_BLOCKS-1:0]                                        use_pend_addr, use_flopped_tgt_addr;
  logic [NUM_BLOCKS-1:0]                                        use_pend_btype;

  // Pending data's for Addr on the next block
  logic [NUM_BLOCKS-1:0]                                        isAddrPending_TE0, isAddrPending_delay;
  logic [NUM_BLOCKS-1:0]                                        is_sic_AddrPending_TE0, is_sic_AddrPending_delay; 
  logic                                                         pend_addr_available;
  logic [ICOUNT_WIDTH-1:0]                                      pend_iCount_to_report_delay, pend_ptc_iCount_to_report_delay;
  logic [HIST_WIDTH-1:0]                                        pend_hist_to_report_delay;
  logic [HIST_WIDTH-1:0]                                        pend_ptc_hist_overflow_to_report_delay;
  logic [TSTAMP_WIDTH-1:0]                                      pend_tstamp_to_report_delay, rb_tstamp_to_report, pend_trstart_tstamp_to_report_delay;
  logic [PC_WIDTH-1:1]                                          pend_uaddr_to_report_delay, pend_faddr_to_report_delay;

  logic [$clog2(ICOUNT_WIDTH):0]                                pend_iCount_to_report_delay_len, pend_ptc_iCount_to_report_delay_len;
  logic [$clog2(TSTAMP_WIDTH):0]                                pend_tstamp_to_report_delay_len, rb_tstamp_to_report_len, pend_trstart_tstamp_to_report_delay_len;
  logic [$clog2(HIST_WIDTH):0]                                  pend_hist_to_report_delay_len;
  logic [$clog2(HIST_WIDTH):0]                                  pend_ptc_hist_overflow_to_report_delay_len;
  logic [$clog2(PC_WIDTH):0]                                    pend_uaddr_to_report_delay_len, pend_faddr_to_report_delay_len; 

  // Pending signals _ff & _clr for each of the packet
  logic                                                         isProgTraceSync_Pending, isProgTraceSync_Pending_clr;
  logic                                                         isOwnership_Pending, isOwnership_Pending_clr;
  logic                                                         isProgTraceCorrelation_Pending, isProgTraceCorrelation_Pending_clr;
  logic                                                         isIndirectBranchHist_Pending, isIndirectBranchHist_Pending_clr;
  logic                                                         isIndirectBranchHistSync_Pending, isIndirectBranchHistSync_Pending_clr;
  logic                                                         isResourceFull_Packet_TE0, isResourceFull_Packet_TE1;

  // Error packet control signals
  logic                                                         isErrorGeneration_TE0, isErrorGeneration_TE1;
  logic                                                         isBTHBOverflow_TE0;
  logic                                                         isErrorClear_ANY, isEncoderBufferOverflow_ANY, isEncoderBufferOverflowflop_ANY;
  logic                                                         isErrorPacketPushed_ANY, isErrorPacketPushed_d1_ANY, isErrorPacketPushed_TE1;
  logic                                                         isBTHBOverflowErrorPushed_TE0, isBTHBOverflowErrorPushed_TE1;
  logic                                                         trTeResyncAfterEncOverflowError_ANY, trTeResyncAfterBTHBOverflowError_ANY, trTeResyncAfterError_ANY;

  // Outputs of the FF's for the variable length fields
  logic [NUM_BLOCKS-1:0] [$clog2(ICOUNT_WIDTH)-1:0]             icnt_raw_len_TE0;
  logic [$clog2(ICOUNT_WIDTH)-1:0]                              trStop_iCount_to_report_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH)-1:0]                 faddr_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH)-1:0]                 uaddr_raw_len_TE0;
  logic [$clog2(CONTEXT_WIDTH+5)-1:0]                           process_context_raw_len_TE0;
  logic [$clog2(TVAL_WIDTH)-1:0]                                tval_to_report_raw_len_TE0;
  logic [$clog2(TSTAMP_WIDTH)-1:0]                              tstamp_raw_len_TE0, trStop_tstamp_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(HIST_WIDTH)-1:0]               hist_raw_len_TE0;
  logic [$clog2(HIST_WIDTH)-1:0]                                hist_overflow_to_report_raw_len_TE0; 
  logic [$clog2(BCNT_WIDTH)-1:0]                                bcnt_raw_len_TE1;
  logic [$clog2(PC_WIDTH)-1:0]                                  aux_ibh_uaddr_raw_len_TE0;
  logic [$clog2(ICOUNT_WIDTH)-1:0]                              aux_ibh_packet_icount_raw_len_TE0;

  logic [NUM_BLOCKS-1:0] [$clog2(ICOUNT_WIDTH):0]               iCount_to_report_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH):0]                   faddr_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH):0]                   uaddr_len_TE0;
  logic [$clog2(CONTEXT_WIDTH+5):0]                             process_context_len_TE0;
  logic [$clog2(TVAL_WIDTH):0]                                  tval_to_report_len_TE0;
  logic [$clog2(TSTAMP_WIDTH):0]                                tstamp_len_TE0, trStop_tstamp_len_TE0;
  logic [$clog2(HIST_WIDTH):0]                                  hist_overflow_to_report_len_TE0; 
  logic [NUM_BLOCKS-1:0] [$clog2(HIST_WIDTH):0]                 hist_report_len_TE0;
  logic [$clog2(BCNT_WIDTH):0]                                  bcnt_len_TE1; 
  logic [$clog2(PC_WIDTH):0]                                    aux_ibh_uaddr_len_TE0;
  logic [$clog2(ICOUNT_WIDTH):0]                                aux_ibh_packet_icount_len_TE0; 

  // Inputs and Outputs of the MSO logic clokcs
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_IN_WIDTH-1:0]                   mso_data_in_TE0, mso_data_in_TE1; 
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [$clog2(MSO_DATA_IN_WIDTH):0]             mso_data_in_len_TE0, mso_data_in_len_TE1; 
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0]                                           mso_data_is_var_TE0, mso_data_is_var_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0]                                           mso_data_is_last_TE0, mso_data_is_last_TE1;

  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_OUT_WIDTH-1:0]                  mso_data_out_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         mso_data_out_be_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   mso_data_out_len_in_bytes_TE1; 

  logic [1:0] [MSO_DATA_IN_WIDTH-1:0]                   rb_mso_data_in_TE0, rb_mso_data_in_TE1; 
  logic [1:0] [$clog2(MSO_DATA_IN_WIDTH):0]             rb_mso_data_in_len_TE0, rb_mso_data_in_len_TE1; 
  logic [1:0]                                           rb_mso_data_is_var_TE0, rb_mso_data_is_var_TE1;
  logic [1:0]                                           rb_mso_data_is_last_TE0, rb_mso_data_is_last_TE1;

  logic [1:0] [MSO_DATA_OUT_WIDTH-1:0]                  rb_mso_data_out_TE1;
  logic [1:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         rb_mso_data_out_be_TE1;
  logic [1:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   rb_mso_data_out_len_in_bytes_TE1;

  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_IN_WIDTH-1:0]                   own_vdm_mso_data_in_TE0, own_vdm_mso_data_in_TE1; 
  logic [NUM_BLOCKS-1:0] [3:0] [$clog2(MSO_DATA_IN_WIDTH):0]             own_vdm_mso_data_in_len_TE0, own_vdm_mso_data_in_len_TE1; 
  logic [NUM_BLOCKS-1:0] [3:0]                                           own_vdm_mso_data_is_var_TE0, own_vdm_mso_data_is_var_TE1;
  logic [NUM_BLOCKS-1:0] [3:0]                                           own_vdm_mso_data_is_last_TE0, own_vdm_mso_data_is_last_TE1;

  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_OUT_WIDTH-1:0]                  own_vdm_mso_data_out_TE1;
  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         own_vdm_mso_data_out_be_TE1;
  logic [NUM_BLOCKS-1:0] [3:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   own_vdm_mso_data_out_len_in_bytes_TE1;

  // Generated IndirectBranchHist Messgaes fields (to be flopped)
  logic [NUM_BLOCKS-1:0] [ICOUNT_WIDTH-1:0]                     next_inbrhist_icnt_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         next_inbrhist_uaddr_TE0;
  logic [NUM_BLOCKS-1:0] [HIST_WIDTH-1:0]                       next_inbrhist_hist_TE0;

  logic [NUM_BLOCKS-1:0] [ICOUNT_WIDTH-1:0]                     inbrhist_icnt_TE1;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         inbrhist_uaddr_TE1;
  logic [NUM_BLOCKS-1:0] [HIST_WIDTH-1:0]                       inbrhist_hist_TE1;

  logic [ICOUNT_WIDTH-1:0]                                      inbrhist_icnt_TE2;
  logic [PC_WIDTH-1:1]                                          inbrhist_uaddr_TE2;
  logic [HIST_WIDTH-1:0]                                        inbrhist_hist_TE2;

  logic [NUM_BLOCKS-1:0]                                        inbrhist_hist_repeat_TE1, inbrhist_icnt_repeat_TE1, inbrhist_uaddr_repeat_TE1, inbrhist_pkt_repeat_matches_TE1, inbrhist_pkt_repeat_TE1, is_repatbranch_generating_packets_TE1;
  logic                                                         inbrhist_pkt_interpipe_repeat_matches_TE1;
  logic                                                         inbrhist_pkt_repeat_reset_TE1;
  logic                                                         inbrhist_pkt_repeat_clr_TE1;
  logic                                                         inbrhist_ibh_pkt_clr_after_bcnt_overflow;

  // Generated packet information
  logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0]            pkt_len_in_bytes;
  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0]                pkt_data_out;
  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0]                  pkt_data_out_be;
  logic [NUM_BLOCKS-1:0]                                        pkt_buffer_data_vld_TE1, pkt_buffer_data_vld_TE2;
  logic [4:0]                                                   pkt_fifo_push_TE1;
  pkt_buffer_t [4:0]                                            pkt_fifo_wr_data_TE1;
  logic [$clog2(PKT_FIFO_CNT):0]                                pkt_fifo_cnt_TE2;

  // --------------------------------------------------------------------------
  // RE6
  // --------------------------------------------------------------------------
  // Flop the incoming RE6 signals
  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    generic_dff #(.WIDTH(IRETIRE_WIDTH)) trIRetireTE0_ff (.out(trIRetire_TE0[i]), .in(trIRetire_RE6[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
    generic_dff #(.WIDTH(ITYPE_WIDTH)) trItypeTE0_ff (.out(trIType_TE0[i]), .in(trIType_RE6[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
    generic_dff #(.WIDTH(PC_WIDTH-1)) trIAddrTE0_ff (.out(trIAddr_TE0[i]), .in(trIAddr_RE6[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
    generic_dff #(.WIDTH(1)) trILastSizeTE0_ff (.out(trILastSize_TE0[i]), .in(trILastSize_RE6[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));

    assign pipe_vld_TE0[i] = (|trIRetire_TE0[i]) | (trIType_TE0[i] inside {ITYPE_EXCEPTION, ITYPE_INTERRUPT});
  end   

  generic_dff #(.WIDTH(TSTAMP_WIDTH)) trTstampTE0_ff (.out(trTstamp_TE0), .in(trTstamp_RE6), .en(1'b1), .clk(clock), .rst_n(reset_n)); 
  generic_dff #(.WIDTH($bits(PrivMode_e))) trPriv_TE0_ff (.out({trPriv_TE0}), .in(trPriv_RE6), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(CONTEXT_WIDTH)) trContext_TE0_ff (.out(trContext_TE0), .in(trContext_RE6), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(TVAL_WIDTH)) trTval_TE0_ff (.out(trTval_TE0), .in(trTval_RE6), .en(1'b1), .clk(clock), .rst_n(reset_n));
  
  generic_dff #(.WIDTH(1)) trBTHBError_TE0_ff (.out(isBTHBOverflow_TE0), .in(MC_MS_trError_RE6), .en(1'b1), .clk(clock), .rst_n(reset_n));
  
  assign trEncPriv_TE0 = trPriv_RE6;

  // --------------------------------------------------------------------------
  // TE0
  // --------------------------------------------------------------------------

  // Get the pipe valid from the incoming Retire Block and do the bType computation
  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    assign bType_to_report_TE0[i] = trStartStop_ANY_d1 & (trIType_TE0[i]==ITYPE_EXCEPTION)?2'h2:(trIType_TE0[i]==ITYPE_INTERRUPT?2'h3:2'h0);

    assign indirectBranchInst_TE0[i] = trStartStop_ANY_d1 & ((trIType_TE0[i] == ITYPE_EXCEPTION) | (trIType_TE0[i] == ITYPE_INTERRUPT) | (trIType_TE0[i] == ITYPE_EXCEPTION_INTERRUPT_RETURN) | (trIType_TE0[i] == ITYPE_JUMP));
  end

  // Check for Context switch cases to report OWNERSHIP
  assign context_switch_TE0 = trStartStop_ANY_d1 & pipe_vld_TE0[0] & ((trIType_TE0[0]==ITYPE_EXCEPTION) | (trIType_TE0[0]==ITYPE_INTERRUPT) | (trIType_TE0[0] == ITYPE_EXCEPTION_INTERRUPT_RETURN)); 
  assign context_to_report_TE0 = {trContext_TE0,trEncPriv_TE0,2'b00};

  generic_dff #(.WIDTH(1)) context_switch_TE1_ff (.out(context_switch_TE1), .in(context_switch_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) is_tval_to_report_TE1_ff (.out(is_tval_to_report_TE1), .in(is_tval_to_report_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));
  
  // Check for EXCEPTION/INTERRUPT to generate VDM with tvals
  assign is_tval_to_report_TE0 = trStartStop_ANY_d1 & pipe_vld_TE0[0] & ((trIType_TE0[0]==ITYPE_EXCEPTION) | (trIType_TE0[0]==ITYPE_INTERRUPT));
  assign tval_to_report_TE0 = trTval_TE0; 
  generic_dff_clr #(.WIDTH(1)) is_tval_to_report_pend_ff (.out(is_tval_to_report_pend), .in(1'b1), .clr((~is_tval_to_report_TE0 & context_switch_IBH_reported_TE0) | trStop_ANY | isErrorClear_ANY), .en(is_tval_to_report_TE0 & trStartStop_ANY & ~isErrorPacketPushed_ANY), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(TSTAMP_WIDTH)) trStop_tstamp_TE0_ff (.out(trStop_tstamp_TE0), .in(trTstamp_TE0), .clr(trStart_ANY), .en(trStop_ANY | (isProgTraceSync_Pending_clr)), .clk(clock), .rst_n(reset_n));

  assign trStop_iCount_Hist_to_report_TE0 = ((trTstamp_TE0 >= trStop_tstamp_TE0) & (isProgTraceCorrelation_Pending)) | (trStop_ANY & ~|pipe_vld_TE0);

  // HIST and I-CNT Field computation 
  // Combination logic to decide the amount of shift
  always_comb begin
    next_hist_TE0 = trStart_ANY?HIST_WIDTH'('h1):hist_TE1; // The updated HIST field after parsing the incoming blocks of data

    is_hist_to_report_TE0 = 2'b0; // Any of the two incoming block's data can be generating an IndirectBranch packet
    hist_to_report_TE0 = {NUM_BLOCKS{next_hist_TE0}};

    is_hist_overflow_to_report_TE0 = 'b0; // Only one of the incoming blocks can cause the overflow and generate the RESOURCEFULL packet
    hist_overflow_to_report_TE0 = '0;

    next_iCount_TE0 = trStart_ANY?ICOUNT_WIDTH'('h0):iCount_TE1; // The next ICNT computation starts with the previous I-CNT

    iCount_to_report_TE0 = {{NUM_BLOCKS{iCount_TE1}}};
    is_iCount_overflow_TE0 = 'h0;
    seq_icnt_overflow_TE0 = 'h0;
    seq_icnt_overflow_faddr_to_report = 'h0;

    // Pending Flops which stores the dat when the packet is waiting for a address that comes in the next block
    isAddrPending_TE0 = '0;
    is_sic_AddrPending_TE0 = '0;
    pend_addr_available = '0;

    aux_ibh_packet_pipe_vld_TE0 = '0;
    aux_ibh_use_sic_uaddr_TE0 = '0;
    aux_ibh_packet_tgt_pending_TE0 = '0;
    aux_ibh_packet_icount_TE0 = '0;
    
    for (int i=0; i<NUM_BLOCKS; i++) begin
      if (pipe_vld_TE0[0] & isAddrPending_delay[i]) begin
        pend_addr_available = pipe_vld_TE0[0] & isAddrPending_delay[i]; // If there's pending address, it's always available on block zero
      end

      // When the Trace stops, flush out the iCount
      if (trStop_iCount_Hist_to_report_TE0) begin
        iCount_to_report_TE0[0] = next_iCount_TE0; // Only the first pipe to be reported
      end

      else if(pipe_vld_TE0[i] & ~isErrorClear_ANY & ~(isErrorPacketPushed_TE1 | isBTHBOverflow_TE0 | isErrorPacketPushed_ANY) & trStartStop_ANY_d1 /* & ~trStart_ANY */) begin // Only the Non ITYPE-UNKNOWN will generate the Indirect Branch Packet or Update the HIST field
        // Increment the I-CNT 
        next_iCount_TE0 = next_iCount_TE0 + ((~(trStop_ANY & |indirectBranchInst_TE0))?ICOUNT_WIDTH'(trIRetire_TE0[i]):ICOUNT_WIDTH'(0));
        
        // Look for an I-CNT overflow case
        if (next_iCount_TE0[ICOUNT_WIDTH-1]) begin  
          // Compute the icount to be reported
          iCount_to_report_TE0[i] = next_iCount_TE0;
          // Compute the hist including this packet
          if (trIType_TE0[i] == ITYPE_NOT_TAKEN)
            next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b0};
          else if (trIType_TE0[i] == ITYPE_TAKEN)
            next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b1};

          // Check if hist buffer is empty
          if (((next_hist_TE0 == 'h1) | (next_hist_TE0[HIST_WIDTH-1] == 'h1)) & ~(indirectBranchInst_TE0[i] | trIBHS_trig_psync_ANY)) begin //Hist Buffer is empty or Hist overflow
            is_iCount_overflow_TE0[i] = 1'b1; // Generate the RESOURCEFULL packet
          end
          else begin //Hist buffer is non-empty
            seq_icnt_overflow_TE0[i] = 1'b1; //Should generate the IndirectBranchHistSync
            is_sic_AddrPending_TE0[i] = ~((i==0) & pipe_vld_TE0[1]); 
            seq_icnt_overflow_faddr_to_report = trIAddr_TE0[1]; 
            hist_to_report_TE0[i] = next_hist_TE0;
            next_hist_TE0 = $bits(next_hist_TE0)'(1'b1); 
          end

          next_iCount_TE0 = $bits(next_iCount_TE0)'((~indirectBranchInst_TE0[i])?(next_iCount_TE0 - iCount_to_report_TE0[i]):(ICOUNT_WIDTH'('h0))); // Reset the I_CNT field
        end

        else begin
          // Check for the Itypes that will generate the packet
          if ( ((i==0) & (trIBHS_trig_psync_ANY & ~|isAddrPending_delay & trStartStop_ANY) & ~isIndirectBranchHist_Pending) | (indirectBranchInst_TE0[i] & trStartStop_ANY)) begin 
            is_hist_to_report_TE0[i] = 1'b1; // Should generate an Indirect Branch packet
            
            isAddrPending_TE0[i] = ~((i==0) & pipe_vld_TE0[1]); // When the pipe-0 generates packet and pipe-1 has a valid data, then don't set the addr_pending
            
            iCount_to_report_TE0[i] = next_iCount_TE0;
            hist_to_report_TE0[i] = next_hist_TE0;

            next_hist_TE0 = $bits(next_hist_TE0)'(1'b1); // Resetting the HIST field, once it's broken for packet generation
            next_iCount_TE0 = ICOUNT_WIDTH'('h0); // Reset the ICount field, once it's reported
          end
          else if (~(trStop_ANY & |indirectBranchInst_TE0)) begin // Update the HIST field 
            if (trIType_TE0[i] == ITYPE_NOT_TAKEN)
              next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b0};
            else if (trIType_TE0[i] == ITYPE_TAKEN)
              next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b1};
          end
        end

        // RESOURCEFULL packet conditions (HIST overflow condition)
        if (next_hist_TE0[HIST_WIDTH-1]) begin
          is_hist_overflow_to_report_TE0[i] = next_hist_TE0[HIST_WIDTH-1];
          hist_overflow_to_report_TE0 = next_hist_TE0; 
          next_hist_TE0 = $bits(next_hist_TE0)'(1'b1); 
        end

      end      

    end
  end

  // Resourcefull Packet control
  assign isResourceFull_Packet_TE0 = (|is_hist_overflow_to_report_TE0) | (|is_iCount_overflow_TE0);
  generic_dff #(.WIDTH(1)) isResourceFull_Packet_TE1_ff (.out(isResourceFull_Packet_TE1), .in(isResourceFull_Packet_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  // Flops the reporting conditional signals
  generic_dff_clr #(.WIDTH(NUM_BLOCKS)) isAddrPending_delay_ff (.out(isAddrPending_delay), .in(isAddrPending_TE0 | is_sic_AddrPending_TE0), .clr(isErrorClear_ANY | trStop_iCount_Hist_to_report_TE0 | trStop_ANY), .en(|pipe_vld_TE0), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(NUM_BLOCKS)) is_sic_AddrPending_delay_ff (.out(is_sic_AddrPending_delay), .in(is_sic_AddrPending_TE0), .clr(isErrorClear_ANY | trStop_iCount_Hist_to_report_TE0), .en(|pipe_vld_TE0), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) seq_icnt_overflow_delay_ff (.out(seq_icnt_overflow_delay), .in(1'b1), .clr(isIndirectBranchHistSync_Pending_clr | trStart_ANY), .en(|seq_icnt_overflow_TE0), .clk(clock), .rst_n(reset_n)); 

  // Flops to store the data to be used in the next cycle or when the next address block is available
  generic_dff #(.WIDTH(BTYPE_WIDTH)) pend_btype_to_report_delay_ff (.out(pend_btype_to_report_delay), .in((isAddrPending_TE0[0] | is_sic_AddrPending_TE0[0])?bType_to_report_TE0[0]:bType_to_report_TE0[1]), .en((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0)), .clk(clock), .rst_n(reset_n)); 
  generic_dff #(.WIDTH(HIST_WIDTH)) pend_hist_to_report_delay_ff (.out(pend_hist_to_report_delay), .in(aux_ibh_packet_tgt_pending_TE0?'b1:((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?hist_to_report_TE0[0]:hist_to_report_TE0[1])), .en((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(ICOUNT_WIDTH)) pend_iCount_to_report_delay_ff (.out(pend_iCount_to_report_delay), .in(aux_ibh_packet_tgt_pending_TE0?aux_ibh_packet_icount_TE0:((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?iCount_to_report_TE0[0]:iCount_to_report_TE0[1])), .en((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(TSTAMP_WIDTH)) pend_tstamp_to_report_delay_ff (.out(pend_tstamp_to_report_delay), .in(trTstamp_TE0), .en(((|is_sic_AddrPending_TE0) | (|isAddrPending_TE0) | (|inbrhist_pkt_repeat_TE1)) & (trStartStop_ANY | trStop_ANY)), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(TSTAMP_WIDTH)) rb_tstamp_to_report_ff (.out(rb_tstamp_to_report), .in((|inbrhist_pkt_repeat_TE1 & (trStartStop_ANY | trStop_ANY))?trTstamp_TE1:pend_tstamp_to_report_delay), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(PC_WIDTH-1)) pend_uaddr_to_report_delay_ff (.out(pend_uaddr_to_report_delay), .in(isAddrPending_TE0[0]?u_addr_TE0[0]:u_addr_TE0[1]), .en(|isAddrPending_TE0), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(ICOUNT_WIDTH)) pend_ptc_iCount_to_report_delay_ff (.out(pend_ptc_iCount_to_report_delay), .in(seq_icnt_overflow_TE0[1]?iCount_to_report_TE0[1]:iCount_to_report_TE0[0]), .en(|seq_icnt_overflow_TE0), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(ICOUNT_WIDTH)+1)) pend_ptc_iCount_to_report_delay_len_ff (.out(pend_ptc_iCount_to_report_delay_len), .in(seq_icnt_overflow_TE0[1]?iCount_to_report_len_TE0[1]:iCount_to_report_len_TE0[0]), .en(|seq_icnt_overflow_TE0), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(HIST_WIDTH)) pend_ptc_hist_overflow_to_report_delay_ff (.out(pend_ptc_hist_overflow_to_report_delay), .in(seq_icnt_overflow_TE0[1]?hist_to_report_TE0[1]:hist_to_report_TE0[0]), .en(|seq_icnt_overflow_TE0), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(HIST_WIDTH)+1)) pend_ptc_hist_overflow_to_report_delay_len_ff (.out(pend_ptc_hist_overflow_to_report_delay_len), .in(seq_icnt_overflow_TE0[1]?hist_report_len_TE0[1]:hist_report_len_TE0[0]), .en(|seq_icnt_overflow_TE0), .clk(clock), .rst_n(reset_n));
  
  // Flop their lengths after the FF logic
  generic_dff #(.WIDTH($clog2(HIST_WIDTH)+1)) pend_hist_to_report_delay_len_ff (.out(pend_hist_to_report_delay_len), .in(aux_ibh_packet_tgt_pending_TE0?$bits(pend_hist_to_report_delay_len)'('b1):((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?hist_report_len_TE0[0]:hist_report_len_TE0[1])), .en((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(ICOUNT_WIDTH)+1)) pend_iCount_to_report_delay_len_ff (.out(pend_iCount_to_report_delay_len), .in(aux_ibh_packet_tgt_pending_TE0?aux_ibh_packet_icount_len_TE0:((trStop_ANY | isAddrPending_TE0[0] | is_sic_AddrPending_TE0[0])?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1])), .en((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(TSTAMP_WIDTH)+1)) pend_tstamp_to_report_delay_len_ff (.out(pend_tstamp_to_report_delay_len), .in(tstamp_len_TE0), .en(((|is_sic_AddrPending_TE0) | (|isAddrPending_TE0) | (|inbrhist_pkt_repeat_TE1)) & (trStartStop_ANY | trStop_ANY)), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(TSTAMP_WIDTH)+1)) rb_tstamp_to_report_len_ff (.out(rb_tstamp_to_report_len), .in((|inbrhist_pkt_repeat_TE1 & (trStartStop_ANY | trStop_ANY))?tstamp_len_TE0:pend_tstamp_to_report_delay_len), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH($clog2(TSTAMP_WIDTH)+1)) pend_uaddr_to_report_delay_len_ff (.out(pend_uaddr_to_report_delay_len), .in(isAddrPending_TE0[0]?uaddr_len_TE0[0]:uaddr_len_TE0[1]), .en(|isAddrPending_TE0), .clk(clock), .rst_n(reset_n)); 

  // Flop the Computed HIST, I-CNT field after the TE0 stage
  generic_dff #(.WIDTH(HIST_WIDTH), .RESET_VALUE(1)) hist_TE1_ff (.out(hist_TE1), .in((trCorrelationMessageSent_ANY | isErrorClear_ANY)?HIST_WIDTH'('h1):next_hist_TE0), .en(isErrorClear_ANY | trCorrelationMessageSent_ANY | (|pipe_vld_TE0) | hist_TE1[HIST_WIDTH-1] | |trStart_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(ICOUNT_WIDTH)) iCount_TE1_ff (.out(iCount_TE1), .in((trCorrelationMessageSent_ANY | isErrorClear_ANY)?ICOUNT_WIDTH'('h0):next_iCount_TE0), .en(isErrorClear_ANY | trCorrelationMessageSent_ANY | (|pipe_vld_TE0) | trStart_ANY), .clk(clock), .rst_n(reset_n)); 

  generic_dff_clr #(.WIDTH(1)) context_switch_report_pend_ff (.out(context_switch_report_pend), .in(1'b1), .clr(trStop_ANY | isErrorClear_ANY | (context_switch_IBH_reported_TE0 & ~context_switch_TE0)), .en(trStartStop_ANY & context_switch_TE0 & ~isErrorPacketPushed_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) context_switch_IBH_reported_TE1_ff (.out(context_switch_IBH_reported_TE1), .in(context_switch_IBH_reported_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trTracingInProgress_flop_ANY_ff (.out(trTracingInProgress_ANY), .in(1'b1), .clr((curr_pkt_TE0[0] == PROGTRACECORRELATION) | (curr_pkt_TE1[1] == PROGTRACECORRELATION) | (curr_pkt_TE0[0] == ERROR)), .en((curr_pkt_TE0[0] == PROGTRACESYNC) & packet_pipe_vld_TE0[0]), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trTracingInProgress_ANY_d1_ff (.out(trTracingInProgress_ANY_d1), .in(trTracingInProgress_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));

  assign trCorrelationMessageSent_ANY = (curr_pkt_TE0[0] == PROGTRACECORRELATION & packet_pipe_vld_TE0[0]) | (curr_pkt_TE0[1] == PROGTRACECORRELATION & packet_pipe_vld_TE0[1]);
  // ----------------------------------------------------------------------------------------------
  // Find first logics for all the variable length fields (TE0)
  // ----------------------------------------------------------------------------------------------
  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    // I-CNT
    generic_ffs_fast #(
    .DIR_L2H(1'b0),
    .WIDTH(ICOUNT_WIDTH),
    .DATA_WIDTH(ICOUNT_WIDTH)
    ) ff_icnt (
        .req_in(iCount_to_report_TE0[i]),
        .data_in('0),
        .enc_req_out(icnt_raw_len_TE0[i]),

        .data_out(),
        .req_out(),
        .req_out_therm()
    );
    assign iCount_to_report_len_TE0[i] = ($clog2(ICOUNT_WIDTH)+1)'(|iCount_to_report_TE0[i]) + icnt_raw_len_TE0[i];

    // F-Addr
    generic_ffs_fast #(
    .DIR_L2H(1'b0),
    .WIDTH(PC_WIDTH-1),
    .DATA_WIDTH(PC_WIDTH-1)
    ) ff_faddr (
        .req_in(seq_icnt_overflow_TE0[i]?seq_icnt_overflow_faddr_to_report:trIAddr_TE0[i]),
        .data_in('0),
        .enc_req_out(faddr_raw_len_TE0[i]),

        .data_out(),
        .req_out(),
        .req_out_therm()
    );
    assign faddr_len_TE0[i] = ($clog2(PC_WIDTH)+1)'(|(seq_icnt_overflow_TE0[i]?seq_icnt_overflow_faddr_to_report:trIAddr_TE0[i])) + faddr_raw_len_TE0[i];

    // U-Addr
    assign u_addr_TE0[i] = trIAddr_TE0[i]^((|i & (&next_ref_addr_vld_TE0))?trIAddr_TE0[0]:ref_addr_TE1); 
    generic_ffs_fast #(
    .DIR_L2H(1'b0),
    .WIDTH(PC_WIDTH-1),
    .DATA_WIDTH(PC_WIDTH-1)
    ) ff_uaddr (
        .req_in(u_addr_TE0[i]),
        .data_in('0),
        .enc_req_out(uaddr_raw_len_TE0[i]),

        .data_out(),
        .req_out(),
        .req_out_therm()
    );
    assign uaddr_len_TE0[i] = ($clog2(PC_WIDTH)+1)'(|u_addr_TE0[i]) + uaddr_raw_len_TE0[i];

    // HIST
    generic_ffs_fast #(
    .DIR_L2H(1'b0),
    .WIDTH(HIST_WIDTH),
    .DATA_WIDTH(HIST_WIDTH)
    ) ff_hist (
        .req_in(hist_to_report_TE0[i]),
        .data_in('0),
        .enc_req_out(hist_raw_len_TE0[i]),

        .data_out(),
        .req_out(),
        .req_out_therm()
    );
    assign hist_report_len_TE0[i] = ($clog2(HIST_WIDTH)+1)'(|hist_to_report_TE0[i]) + hist_raw_len_TE0[i];
  end

  // HIST Overflow
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(HIST_WIDTH),
  .DATA_WIDTH(HIST_WIDTH)
  ) ff_hist (
      .req_in(hist_overflow_to_report_TE0),
      .data_in('0),
      .enc_req_out(hist_overflow_to_report_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign hist_overflow_to_report_len_TE0 = ($clog2(HIST_WIDTH)+1)'(|hist_overflow_to_report_TE0) + hist_overflow_to_report_raw_len_TE0;

  // B-Cnt (for RepeatBranch Message)
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(BCNT_WIDTH),
  .DATA_WIDTH(BCNT_WIDTH)
  ) ff_bcnt (
      .req_in(bcnt_to_report_TE1), 
      .data_in('0),
      .enc_req_out(bcnt_raw_len_TE1),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign bcnt_len_TE1 = ($clog2(BCNT_WIDTH)+1)'(|bcnt_to_report_TE1) + bcnt_raw_len_TE1;

  // Process-context
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(CONTEXT_WIDTH+5),
  .DATA_WIDTH(CONTEXT_WIDTH+5)
  ) ff_process_context (
      .req_in(context_to_report_TE0),
      .data_in('0),
      .enc_req_out(process_context_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign process_context_len_TE0 = ($clog2(CONTEXT_WIDTH+5)+1)'(|context_to_report_TE0) + process_context_raw_len_TE0;

  // Tval
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(TVAL_WIDTH),
  .DATA_WIDTH(TVAL_WIDTH)
  ) ff_tval_to_report (
      .req_in(tval_to_report_TE0),
      .data_in('0),
      .enc_req_out(tval_to_report_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign tval_to_report_len_TE0 = ($clog2(TVAL_WIDTH)+1)'(|tval_to_report_TE0) + tval_to_report_raw_len_TE0;

  // T-Stamp
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(TSTAMP_WIDTH),
  .DATA_WIDTH(TSTAMP_WIDTH)
  ) ff_tstamp (
      .req_in(trTstamp_TE0),
      .data_in('0),
      .enc_req_out(tstamp_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign tstamp_len_TE0 = ($clog2(TSTAMP_WIDTH)+1)'(|trTstamp_TE0) + tstamp_raw_len_TE0;

  // Trace Stop T-Stamp
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(TSTAMP_WIDTH),
  .DATA_WIDTH(TSTAMP_WIDTH)
  ) ff_stop_tstamp (
      .req_in(trStop_tstamp_TE0),
      .data_in('0),
      .enc_req_out(trStop_tstamp_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign trStop_tstamp_len_TE0 = ($clog2(TSTAMP_WIDTH)+1)'(|trStop_tstamp_TE0) + trStop_tstamp_raw_len_TE0;

  // AUX IBH U-Addr 
  assign aux_ibh_uaddr_TE0 = (trIAddr_TE0[0] + ((PC_WIDTH-1)'({1'b1,{(ICOUNT_WIDTH-1){1'b0}}}) - (PC_WIDTH-1)'(iCount_TE1))) ^ (trIAddr_TE0[1]);
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(PC_WIDTH-1),
  .DATA_WIDTH(PC_WIDTH-1)
  ) ff_aux_ibh_uaddr (
      .req_in(aux_ibh_uaddr_TE0),
      .data_in('0),
      .enc_req_out(aux_ibh_uaddr_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign aux_ibh_uaddr_len_TE0 = ($clog2(PC_WIDTH)+1)'(|aux_ibh_uaddr_TE0) + aux_ibh_uaddr_raw_len_TE0;

  // AUX IBH Icount
  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(ICOUNT_WIDTH),
  .DATA_WIDTH(ICOUNT_WIDTH)
  ) ff_aux_ibh_icount (
      .req_in(aux_ibh_packet_icount_TE0),
      .data_in('0),
      .enc_req_out(aux_ibh_packet_icount_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign aux_ibh_packet_icount_len_TE0 = ($clog2(ICOUNT_WIDTH)+1)'(|aux_ibh_packet_icount_TE0) + aux_ibh_packet_icount_raw_len_TE0;

  // ----------------------------------------------------------------------------------------------
  // Packet assignments (TE0 stage)
  // ----------------------------------------------------------------------------------------------
  always_comb begin
    for (int i=0; i<NUM_BLOCKS; i++) begin
      unique case (curr_pkt_TE0[i])
        PROGTRACESYNC: begin // In the case of Start/Re-start of trace, the PROGTRACESYNC + OWNERSHIP is generated together
          next_ref_addr_vld_TE0[i] = '1;
          next_ref_addr_TE0[i] = trIAddr_TE0[i]; 

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;

          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({'0,trTeResyncAfterError_ANY?RESTART_FIFO_OVERFLOW:(trTeReStartAfterDebugMode_ANY?EXIT_FROM_DEBUG:(trReEnable_ANY?TRACE_ENABLE:EXIT_FROM_RESET)),Cr4BTrteinstfeatures.Trtesrcid[3:0],PROGTRACESYNC}); 
          mso_data_in_len_TE0[i][0] = 'he;
          mso_data_is_var_TE0[i][0] = 'h1;
          mso_data_is_last_TE0[i][0] = (faddr_len_TE0[i] == 0) & (tstamp_len_TE0 == 0); 

          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'(trIAddr_TE0[i]); 
          mso_data_in_len_TE0[i][1] = faddr_len_TE0[i];  
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = (tstamp_len_TE0 == 0);  

          mso_data_in_TE0[i][2] = MSO_DATA_IN_WIDTH'(trTstamp_TE0); 
          mso_data_in_len_TE0[i][2] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0); 
          mso_data_is_var_TE0[i][2] = '1;
          mso_data_is_last_TE0[i][2] = '1;

          mso_data_in_TE0[i][3] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,Cr4BTrteinstfeatures.Trtesrcid[3:0],OWNERSHIP});
          mso_data_in_len_TE0[i][3] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((process_context_len_TE0) + 6'hb);
          mso_data_is_var_TE0[i][3] = '1;
          mso_data_is_last_TE0[i][3] = '1; 

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;
        end
        PROGTRACECORRELATION: begin
          next_ref_addr_vld_TE0[i] = '0;
          next_ref_addr_TE0[i] = '0;

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;

          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({(trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h0:(trStart_ANY?pend_iCount_to_report_delay:(seq_icnt_overflow_delay?pend_ptc_iCount_to_report_delay:(pipe_vld_TE0[1]?iCount_to_report_TE0[1]:iCount_to_report_TE0[0]))),2'b01,((trTeInsttracing_Enable_ANY | trTeInsttracing_Enable_ANY_d1 | ~trTeTraceInPatchEnable_ANY) & ((trPrivDebugModeEntry_ANY | trPrivDebugEntry_PTC_pending_ANY) & ~(trSwControlStop_PTC_pending_ANY | trSwControlStop_ANY)))?DEBUG_ENTRY:((trace_stop_after_error_wo_sync | (trStop_ANY & trTeResyncAfterError_ANY & isProgTraceSync_Pending))?TRACE_STOP_WITHOUT_SYNC_AFTER_ERROR:PROG_TRACE_DISABLE),Cr4BTrteinstfeatures.Trtesrcid[3:0],PROGTRACECORRELATION});          
          
          /* verilator lint_off WIDTHEXPAND */
          mso_data_in_len_TE0[i][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h0:(trStart_ANY?pend_iCount_to_report_delay_len:(seq_icnt_overflow_delay?pend_ptc_iCount_to_report_delay_len:(pipe_vld_TE0[1]?iCount_to_report_len_TE0[1]:iCount_to_report_len_TE0[0])))) + 'h10;
          /* verilator lint_on WIDTHEXPAND */
          mso_data_is_var_TE0[i][0] = '1;
          mso_data_is_last_TE0[i][0] = '0; 

          /* verilator lint_off WIDTHEXPAND */
          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h1:(trStart_ANY?pend_hist_to_report_delay:(seq_icnt_overflow_delay?pend_ptc_hist_overflow_to_report_delay:hist_to_report_TE0[i])));
          mso_data_in_len_TE0[i][1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h1:(trStart_ANY?pend_hist_to_report_delay_len:(seq_icnt_overflow_delay?pend_ptc_hist_overflow_to_report_delay_len:hist_report_len_TE0[i])));
          /* verilator lint_on WIDTHEXPAND */
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = '0;

          mso_data_in_TE0[i][2] = MSO_DATA_IN_WIDTH'(((trStop_iCount_Hist_to_report_TE0) & ~isProgTraceCorrelation_Pending)?trTstamp_TE0:trStop_tstamp_TE0); 
          mso_data_in_len_TE0[i][2] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(((trStop_iCount_Hist_to_report_TE0) & ~isProgTraceCorrelation_Pending)?tstamp_len_TE0:trStop_tstamp_len_TE0); 
          mso_data_is_var_TE0[i][2] = '1;
          mso_data_is_last_TE0[i][2] = '1;

          mso_data_in_TE0[i][3] = '0;
          mso_data_in_len_TE0[i][3] = '0;
          mso_data_is_var_TE0[i][3] = '0;
          mso_data_is_last_TE0[i][3] = '0;

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;
        end
        RESOURCEFULL: begin
          next_ref_addr_vld_TE0[i] = '0;
          next_ref_addr_TE0[i] = '0;

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;

          /* verilator lint_off WIDTH */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({rsfull_msg_icnt_or_hist_TE0[0]?hist_overflow_to_report_TE0:(is_iCount_overflow_TE0[0]?iCount_to_report_TE0[0]:iCount_to_report_TE0[1]),(rsfull_msg_icnt_or_hist_TE0[0]?4'b1:4'b0),Cr4BTrteinstfeatures.Trtesrcid[3:0],RESOURCEFULL}); 
          mso_data_in_len_TE0[i][0] = (rsfull_msg_icnt_or_hist_TE0[0]?($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_overflow_to_report_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'((is_iCount_overflow_TE0[0]?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1]))) + 'he;
          /* verilator lint_on WIDTH */
          mso_data_is_var_TE0[i][0] = '1;
          mso_data_is_last_TE0[i][0] = '0; 

          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'(trTstamp_TE0);
          mso_data_in_len_TE0[i][1] =($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0);
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = '1;

          /* verilator lint_off WIDTH */
          mso_data_in_TE0[i][2] = rsfull_msg_vld_ANY[1]?(MSO_DATA_IN_WIDTH'({rsfull_msg_icnt_or_hist_TE0[1]?hist_overflow_to_report_TE0:(is_iCount_overflow_TE0[0]?iCount_to_report_TE0[0]:iCount_to_report_TE0[1]),(rsfull_msg_icnt_or_hist_TE0[1]?4'b1:4'b0),Cr4BTrteinstfeatures.Trtesrcid[3:0],RESOURCEFULL})):(MSO_DATA_IN_WIDTH'('b0));
          mso_data_in_len_TE0[i][2] = rsfull_msg_vld_ANY[1]?((rsfull_msg_icnt_or_hist_TE0[1]?($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_overflow_to_report_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'((is_iCount_overflow_TE0[0]?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1]))) + 'he):(($clog2(MSO_DATA_IN_WIDTH)+1)'('b0));
          /* verilator lint_on WIDTH */ 
          mso_data_is_var_TE0[i][2] = rsfull_msg_vld_ANY[1];
          mso_data_is_last_TE0[i][2] = '0;

          mso_data_in_TE0[i][3] = rsfull_msg_vld_ANY[1]?(MSO_DATA_IN_WIDTH'(trTstamp_TE0)):(MSO_DATA_IN_WIDTH'('b0));
          mso_data_in_len_TE0[i][3] = rsfull_msg_vld_ANY[1]?(($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0)):(($clog2(MSO_DATA_IN_WIDTH)+1)'('b0));
          mso_data_is_var_TE0[i][3] = rsfull_msg_vld_ANY[1];
          mso_data_is_last_TE0[i][3] = rsfull_msg_vld_ANY[1];

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;          
        end 
        INDIRECTBRANCHHIST: begin
          next_ref_addr_vld_TE0[i] = '1;
          next_ref_addr_TE0[i] = trIAddr_TE0[addrBlock[i]];

          next_inbrhist_icnt_TE0[i] = use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]];
          next_inbrhist_uaddr_TE0[i] = u_addr_TE0[addrBlock[i]];
          next_inbrhist_hist_TE0[i] = use_pend_addr[i]?pend_hist_to_report_delay:hist_to_report_TE0[dataBlock[i]];

          ibh_btype_reported_TE0[i] = use_pend_btype[i]?pend_btype_to_report_delay:bType_to_report_TE0[dataBlock[i]]; 

          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({aux_ibh_packet_pipe_vld_TE0?(aux_ibh_packet_icount_TE0):(use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]]),use_pend_btype[i]?pend_btype_to_report_delay:bType_to_report_TE0[dataBlock[i]],Cr4BTrteinstfeatures.Trtesrcid[3:0],INDIRECTBRANCHHIST});
          mso_data_in_len_TE0[i][0] = (aux_ibh_packet_pipe_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(aux_ibh_packet_icount_len_TE0)):(use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_iCount_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(iCount_to_report_len_TE0[dataBlock[i]]))) + 'hc;
          mso_data_is_var_TE0[i][0] = 1'b1;
          mso_data_is_last_TE0[i][0] = '0;

          mso_data_in_TE0[i][1] = (aux_ibh_packet_pipe_vld_TE0 & aux_ibh_use_sic_uaddr_TE0)?(MSO_DATA_IN_WIDTH'(aux_ibh_uaddr_TE0)):(use_flopped_tgt_addr[i]?MSO_DATA_IN_WIDTH'(0):MSO_DATA_IN_WIDTH'(u_addr_TE0[addrBlock[i]]));
          mso_data_in_len_TE0[i][1] = (aux_ibh_packet_pipe_vld_TE0 & aux_ibh_use_sic_uaddr_TE0)?(aux_ibh_uaddr_len_TE0):(use_flopped_tgt_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(0):($clog2(MSO_DATA_IN_WIDTH)+1)'(uaddr_len_TE0[addrBlock[i]]));
          mso_data_is_var_TE0[i][1] = 1'b1;
          mso_data_is_last_TE0[i][1] = '0; 

          mso_data_in_TE0[i][2] = aux_ibh_packet_pipe_vld_TE0?(MSO_DATA_IN_WIDTH'(1'b1)):(use_pend_addr[i]?MSO_DATA_IN_WIDTH'(pend_hist_to_report_delay):MSO_DATA_IN_WIDTH'(hist_to_report_TE0[dataBlock[i]]));
          mso_data_in_len_TE0[i][2] =  aux_ibh_packet_pipe_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(1'b1)):(use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_hist_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_report_len_TE0[dataBlock[i]]));
          mso_data_is_var_TE0[i][2] = 1'b1;
          mso_data_is_last_TE0[i][2] = '0; 

          mso_data_in_TE0[i][3] = MSO_DATA_IN_WIDTH'((use_pend_addr[i] & ~isProgTraceSync_Pending)?pend_tstamp_to_report_delay:trTstamp_TE0);
          mso_data_in_len_TE0[i][3] =($clog2(MSO_DATA_IN_WIDTH)+1)'(((use_pend_addr[i] & ~isProgTraceSync_Pending)?pend_tstamp_to_report_delay_len:tstamp_len_TE0));
          mso_data_is_var_TE0[i][3] = '1;
          mso_data_is_last_TE0[i][3] = '1;

          mso_data_in_TE0[i][4] = '0; 
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;  
        end
        INDIRECTBRANCHHISTSYNC: begin
          next_ref_addr_vld_TE0[i] = '1;
          next_ref_addr_TE0[i] = (|seq_icnt_overflow_TE0)?seq_icnt_overflow_faddr_to_report:trIAddr_TE0[addrBlock[i]];

          next_inbrhist_icnt_TE0[i] = use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]];
          next_inbrhist_uaddr_TE0[i] = u_addr_TE0[addrBlock[i]];
          next_inbrhist_hist_TE0[i] = use_pend_addr[i]?pend_hist_to_report_delay:hist_to_report_TE0[dataBlock[i]];

          ibh_btype_reported_TE0[i] = '0;

          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({(use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]]),use_pend_btype[i]?pend_btype_to_report_delay:bType_to_report_TE0[dataBlock[i]],(use_pend_addr[i]?seq_icnt_overflow_delay:seq_icnt_overflow_TE0[dataBlock[i]])?SEQ_INCT_OVERFLOW:((trNotifyIBHS_ANY | trNotifyIBHS_ANY_delay)?TRACE_EVENT:PERIODIC_SYNC),Cr4BTrteinstfeatures.Trtesrcid[3:0],INDIRECTBRANCHHISTSYNC});
          mso_data_in_len_TE0[i][0] = (use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_iCount_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(iCount_to_report_len_TE0[dataBlock[i]])) + 'h10;
          mso_data_is_var_TE0[i][0] = 1'b1; 
          mso_data_is_last_TE0[i][0] = '0; 

          mso_data_in_TE0[i][1] = (|seq_icnt_overflow_TE0)?MSO_DATA_IN_WIDTH'(seq_icnt_overflow_faddr_to_report):MSO_DATA_IN_WIDTH'(trIAddr_TE0[addrBlock[i]]);
          mso_data_in_len_TE0[i][1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(faddr_len_TE0[addrBlock[i]]);
          mso_data_is_var_TE0[i][1] = 1'b1;
          mso_data_is_last_TE0[i][1] = '0; 

          mso_data_in_TE0[i][2] = use_pend_addr[i]?MSO_DATA_IN_WIDTH'(pend_hist_to_report_delay):MSO_DATA_IN_WIDTH'(hist_to_report_TE0[dataBlock[i]]);
          mso_data_in_len_TE0[i][2] = use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_hist_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_report_len_TE0[dataBlock[i]]);
          mso_data_is_var_TE0[i][2] = 1'b1; 
          mso_data_is_last_TE0[i][2] = '0; 

          mso_data_in_TE0[i][3] = MSO_DATA_IN_WIDTH'(trTstamp_TE0);
          mso_data_in_len_TE0[i][3] =($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0);
          mso_data_is_var_TE0[i][3] = '1;
          mso_data_is_last_TE0[i][3] = '1;

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;

        end 
        ERROR: begin
          next_ref_addr_vld_TE0[i] = '0;
          next_ref_addr_TE0[i] = '0;

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;

          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({8'h04,4'h0,Cr4BTrteinstfeatures.Trtesrcid[3:0],ERROR});
          mso_data_in_len_TE0[i][0] = 'h16;
          mso_data_is_var_TE0[i][0] = '1;
          mso_data_is_last_TE0[i][0] = '0; 

          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'(trTstamp_TE0);
          mso_data_in_len_TE0[i][1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0);
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = '1;

          mso_data_in_TE0[i][2] = '0;
          mso_data_in_len_TE0[i][2] = '0;
          mso_data_is_var_TE0[i][2] = '0;
          mso_data_is_last_TE0[i][2] = '0;

          mso_data_in_TE0[i][3] = '0;
          mso_data_in_len_TE0[i][3] = '0;
          mso_data_is_var_TE0[i][3] = '0;
          mso_data_is_last_TE0[i][3] = '0;

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;
        end
        default: begin
          next_ref_addr_vld_TE0[i] = '0;
          next_ref_addr_TE0[i] = '0;

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;

          mso_data_in_TE0[i][0] = '0;
          mso_data_in_len_TE0[i][0] = '0;
          mso_data_is_var_TE0[i][0] = '0;
          mso_data_is_last_TE0[i][0] = '0;

          mso_data_in_TE0[i][1] = '0;
          mso_data_in_len_TE0[i][1] = '0;
          mso_data_is_var_TE0[i][1] = '0;
          mso_data_is_last_TE0[i][1] = '0;

          mso_data_in_TE0[i][2] = '0;
          mso_data_in_len_TE0[i][2] = '0;
          mso_data_is_var_TE0[i][2] = '0;
          mso_data_is_last_TE0[i][2] = '0;

          mso_data_in_TE0[i][3] = '0;
          mso_data_in_len_TE0[i][3] = '0;
          mso_data_is_var_TE0[i][3] = '0;
          mso_data_is_last_TE0[i][3] = '0;

          mso_data_in_TE0[i][4] = '0;
          mso_data_in_len_TE0[i][4] = '0;
          mso_data_is_var_TE0[i][4] = '0;
          mso_data_is_last_TE0[i][4] = '0;
        end
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // TE1
  // --------------------------------------------------------------------------
  // Flop the pipe valid signal to TE1
  // Flop the current packet to TE1 cycle
  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    generic_dff #(.WIDTH(1)) pipe_vld_TE1_ff (.out(pipe_vld_TE1[i]), .in(pipe_vld_TE0[i]), .en(1'b1), .clk(clock), .rst_n(reset_n));
    generic_dff #(.WIDTH($bits(Pkt_TCode_e))) curr_pkt_TE1_ff (.out({curr_pkt_TE1[i]}), .in(packet_pipe_vld_TE0[i]?curr_pkt_TE0[i]:PKT_UNKNOWN), .en(1'b1), .clk(clock), .rst_n(reset_n));
  end
  // Flop the time stamp to TE1 cycle to compute the cycle_count
  generic_dff #(.WIDTH(TSTAMP_WIDTH)) tstamp_TE1_ff (.out(trTstamp_TE1), .in(trStop_ANY?TSTAMP_WIDTH'('h0):trTstamp_TE0), .en(trStop_ANY | (trStartStop_ANY & (|pipe_vld_TE0))), .clk(clock), .rst_n(reset_n));

  // Flop the ref-addr to use it with the next addr computation
  // MUX-ed scheme to select which one as the reference address based on the pipe_vld
  // Ref-Addr is updated only when the address is reported, not on every incoming block from BTHB
  generic_dff #(.WIDTH(PC_WIDTH-1)) ref_addr_TE1_ff (.out(ref_addr_TE1), .in(aux_ibh_packet_pipe_vld_TE0?trIAddr_TE0[1]:(next_ref_addr_vld_TE0[1]?next_ref_addr_TE0[1]:next_ref_addr_TE0[0])), .en(aux_ibh_packet_pipe_vld_TE0 | (|next_ref_addr_vld_TE0)), .clk(clock), .rst_n(reset_n));

  // Propogate the packet pipe valid to the TE1 stage
  generic_dff #(.WIDTH(NUM_BLOCKS)) packet_pipe_vld_TE1_ff (.out(packet_pipe_vld_TE1), .in(packet_pipe_vld_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trStop_iCount_Hist_to_report_TE1_ff (.out(trStop_iCount_Hist_to_report_TE1), .in(trStop_iCount_Hist_to_report_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));  
  
  // Iterate over the total number of MSO logic blocks
  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    for (genvar j=0; j<NUM_MSO; j++) begin
      // Flop the TE0 data to feed into the MSO logic
      generic_dff #(.WIDTH(MSO_DATA_IN_WIDTH)) mso_data_in_TE1_ff (.out(mso_data_in_TE1[i][j]), .in(mso_data_in_TE0[i][j]), .en(packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH($clog2(MSO_DATA_IN_WIDTH)+1)) mso_data_in_len_TE1_ff (.out(mso_data_in_len_TE1[i][j]), .in(mso_data_in_len_TE0[i][j]), .en(packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH(1)) mso_data_is_var_TE1_ff (.out(mso_data_is_var_TE1[i][j]), .in(mso_data_is_var_TE0[i][j]), .en(packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH(1)) mso_data_is_last_TE1_ff (.out(mso_data_is_last_TE1[i][j]), .in(mso_data_is_last_TE0[i][j]), .en(packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
 
        dfd_te_mso #(
          .DATA_WIDTH(MSO_DATA_IN_WIDTH)
        ) i_te_mso (
          .data_in(mso_data_in_TE1[i][j]),
          .data_len(mso_data_in_len_TE1[i][j]),
          .is_var(mso_data_is_var_TE1[i][j]),
          .is_last(mso_data_is_last_TE1[i][j]), 
          .data_out(mso_data_out_TE1[i][j]),
          .data_out_be(mso_data_out_be_TE1[i][j]),
          .data_out_len_in_bytes(mso_data_out_len_in_bytes_TE1[i][j])
        );
    end

    // Packet Buffer data struct assignments
    assign pkt_buffer_data_TE1[i].pkt_data_len = ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1] + mso_data_out_len_in_bytes_TE1[i][2] + mso_data_out_len_in_bytes_TE1[i][3] + mso_data_out_len_in_bytes_TE1[i][4]);
    
    assign pkt_buffer_data_TE1[i].pkt_data_be = (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((mso_data_out_be_TE1[i][4])) << (mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1] + mso_data_out_len_in_bytes_TE1[i][2] + mso_data_out_len_in_bytes_TE1[i][3]))
                                              | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((mso_data_out_be_TE1[i][3])) << (mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1] + mso_data_out_len_in_bytes_TE1[i][2]))
                                              | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(mso_data_out_be_TE1[i][2]) << (mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1]))
                                              | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(mso_data_out_be_TE1[i][1]) << (mso_data_out_len_in_bytes_TE1[i][0] ))
                                              | NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(mso_data_out_be_TE1[i][0]);
    assign pkt_buffer_data_TE1[i].pkt_data = ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(mso_data_out_TE1[i][4]) << ((mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1] + mso_data_out_len_in_bytes_TE1[i][2] + mso_data_out_len_in_bytes_TE1[i][3]) * 'h8)) 
                                            | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(mso_data_out_TE1[i][3]) << ((mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1] + mso_data_out_len_in_bytes_TE1[i][2]) * 'h8)) 
                                            | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(mso_data_out_TE1[i][2]) << ((mso_data_out_len_in_bytes_TE1[i][0] + mso_data_out_len_in_bytes_TE1[i][1]) * 'h8))
                                            | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(mso_data_out_TE1[i][1]) << (mso_data_out_len_in_bytes_TE1[i][0] * 'h8))
                                            | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(mso_data_out_TE1[i][0]);

    assign pkt_buffer_data_vld_TE1[i] = ((curr_pkt_TE1[i] != PKT_UNKNOWN) & packet_pipe_vld_TE1[i]) & ~inbrhist_pkt_repeat_TE1[i]; 

  end

  generic_dff #(.WIDTH(NUM_BLOCKS)) pkt_buffer_data_vld_TE2_ff (.out(pkt_buffer_data_vld_TE2), .in(pkt_buffer_data_vld_TE1), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_ffs_N #(.DIR_L2H    (1),
            .WIDTH      (5),
            .DATA_WIDTH ($bits(pkt_buffer_t)),
            .NUM_SEL    (5)
  ) Find_Packet_Writes_TE1 (
    .req_in       ({own_vdm_packet_pipe_vld_TE1[1], pkt_buffer_data_vld_TE1[1], own_vdm_packet_pipe_vld_TE1[0], pkt_buffer_data_vld_TE1[0], rb_packet_pipe_vld_TE1}),
    .data_in      ({own_vdm_pkt_buffer_data_TE1[1], pkt_buffer_data_TE1[1], own_vdm_pkt_buffer_data_TE1[0], pkt_buffer_data_TE1[0], rb_pkt_buffer_data_TE1}),
    .req_out      (),
    .req_sum      (pkt_fifo_push_TE1),
    .data_out     (pkt_fifo_wr_data_TE1),
    .enc_req_out  ()
  );

  // ----------------------------------------------------------------------------------------------
  // RepeatBranch Packet Generation
  // ----------------------------------------------------------------------------------------------
  // Flop the fields of IBH packet TE0 (Both pipes)
  for (genvar i=0; i<NUM_BLOCKS; i++) begin 
    generic_dff_clr #(.WIDTH(ICOUNT_WIDTH)) inbrhist_icnt_TE1_ff (.out(inbrhist_icnt_TE1[i]), .in(next_inbrhist_icnt_TE0[i]), .clr(trStop_ANY_d1 | isErrorClear_ANY), .en((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i] & ~(ibh_btype_reported_TE0[i] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) & ~context_switch_IBH_reported_TE0), .clk(clock), .rst_n(reset_n));
    generic_dff_clr #(.WIDTH(PC_WIDTH-1)) inbrhist_uaddr_TE1_ff (.out(inbrhist_uaddr_TE1[i]), .in(next_inbrhist_uaddr_TE0[i]), .clr(trStop_ANY_d1 | isErrorClear_ANY), .en((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i] & ~(ibh_btype_reported_TE0[i] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) & ~context_switch_IBH_reported_TE0), .clk(clock), .rst_n(reset_n));
    generic_dff_clr #(.WIDTH(HIST_WIDTH)) inbrhist_hist_TE1_ff (.out(inbrhist_hist_TE1[i]), .in(next_inbrhist_hist_TE0[i]), .clr(trStop_ANY_d1 | isErrorClear_ANY), .en((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i] & ~(ibh_btype_reported_TE0[i] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) & ~context_switch_IBH_reported_TE0),  .clk(clock), .rst_n(reset_n));

    generic_dff #(.WIDTH(BTYPE_WIDTH)) ibh_btype_reported_TE1_ff (.out(ibh_btype_reported_TE1[i]), .in(ibh_btype_reported_TE0[i]), .en((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i]),  .clk(clock), .rst_n(reset_n)); 
  end
  // Flop the fields of IBH packet TE1 (Single entry)
  generic_dff_clr #(.WIDTH(ICOUNT_WIDTH)) inbrhist_icnt_TE2_ff (.out(inbrhist_icnt_TE2), .in(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1])?inbrhist_icnt_TE1[1]:inbrhist_icnt_TE1[0]), .clr(trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE1), .en(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1] & ~(ibh_btype_reported_TE1[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE1[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[0] & ~(ibh_btype_reported_TE1[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(PC_WIDTH-1)) inbrhist_uaddr_TE2_ff (.out(inbrhist_uaddr_TE2), .in(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1])?inbrhist_uaddr_TE1[1]:inbrhist_uaddr_TE1[0]), .clr(trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE1), .en(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1] & ~(ibh_btype_reported_TE1[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE1[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[0] & ~(ibh_btype_reported_TE1[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(HIST_WIDTH)) inbrhist_hist_TE2_ff (.out(inbrhist_hist_TE2), .in(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1])?inbrhist_hist_TE1[1]:inbrhist_hist_TE1[0]), .clr(trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE1), .en(((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1] & ~(ibh_btype_reported_TE1[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE1[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[0] & ~(ibh_btype_reported_TE1[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE1), .clk(clock), .rst_n(reset_n));

  // B-CNT flop in TE2
  generic_dff_clr #(.WIDTH(BCNT_WIDTH)) bcnt_TE2_ff (.out(bcnt_TE2), .in(inbrhist_pkt_repeat_clr_TE1?BCNT_WIDTH'('h0):next_bcnt_TE1), .clr(isErrorClear_ANY | (rb_packet_pipe_vld_TE1 & ~bcnt_overflow_TE1)), .en(|inbrhist_pkt_repeat_TE1 | inbrhist_pkt_repeat_clr_TE1 | bcnt_overflow_TE1), .clk(clock), .rst_n(reset_n));

  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    assign inbrhist_hist_repeat_TE1[i] = (inbrhist_hist_TE1[i] == inbrhist_hist_TE2);
    assign inbrhist_icnt_repeat_TE1[i] = (inbrhist_icnt_TE1[i] == inbrhist_icnt_TE2);
    assign inbrhist_uaddr_repeat_TE1[i] = (inbrhist_uaddr_TE1[i] == inbrhist_uaddr_TE2); 

    assign is_repatbranch_generating_packets_TE1[i] = (curr_pkt_TE1[i] inside {INDIRECTBRANCHHIST, INDIRECTBRANCHHISTSYNC, RESOURCEFULL}) & packet_pipe_vld_TE1[i];
    assign inbrhist_pkt_repeat_matches_TE1[i] = inbrhist_hist_repeat_TE1[i] & inbrhist_icnt_repeat_TE1[i] & inbrhist_uaddr_repeat_TE1[i] & ((curr_pkt_TE1[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[i] & ~((ibh_btype_reported_TE1[i] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | context_switch_IBH_reported_TE1)) & ~(trIBHS_trig_psync_ANY_delay) & ~trStop_iCount_Hist_to_report_TE1 & ~(isErrorClear_ANY & ~isBTHBOverflow_TE0) & (trStartStop_ANY | trStop_ANY | trStop_ANY_d1) & ~isErrorPacketPushed_ANY;
    // While checking repeat branch condition, make sure that it's not Ret/Intr/Excp instructions
  end

  assign inbrhist_pkt_interpipe_repeat_matches_TE1 = (inbrhist_hist_TE1[0] == inbrhist_hist_TE1[1]) & (inbrhist_icnt_TE1[0] == inbrhist_icnt_TE1[1]) & (inbrhist_uaddr_TE1[0] == inbrhist_uaddr_TE1[1]) & ((curr_pkt_TE1[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[1] & ~(context_switch_IBH_reported_TE1) & ~(ibh_btype_reported_TE1[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ((curr_pkt_TE1[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE1[0] & ~(ibh_btype_reported_TE1[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~(trIBHS_trig_psync_ANY_delay) & ~trStop_iCount_Hist_to_report_TE1 & ~isErrorClear_ANY & (trStartStop_ANY | trStop_ANY | trStop_ANY_d1) & ~isErrorPacketPushed_ANY; 

  assign inbrhist_pkt_repeat_TE1 = (inbrhist_pkt_repeat_matches_TE1[0]?inbrhist_pkt_repeat_matches_TE1:NUM_BLOCKS'('b0)) | {inbrhist_pkt_interpipe_repeat_matches_TE1, 1'b0};
  assign inbrhist_pkt_repeat_reset_TE1 = (|(is_repatbranch_generating_packets_TE1 & ~inbrhist_pkt_repeat_TE1) | bcnt_overflow_TE1) & ((bcnt_TE2!=0) | (bcnt_TE2_overflowed & |next_bcnt_TE1) | ((&is_repatbranch_generating_packets_TE1) & (inbrhist_pkt_repeat_TE1[0] & ~inbrhist_pkt_repeat_TE1[1]))); 

  assign inbrhist_pkt_repeat_clr_TE1 = (isResourceFull_Packet_TE1 | trStop_iCount_Hist_to_report_TE1 | ((ibh_btype_reported_TE1[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | (ibh_btype_reported_TE1[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | context_switch_IBH_reported_TE1)); 
  assign bcnt_to_report_TE1 = bcnt_overflow_TE1?{BCNT_WIDTH{1'b1}}:next_bcnt_TE1;
  assign bcnt_overflow_TE1 = |is_bcnt_overflow_cond_hit_TE1; 

  always_comb begin
    next_bcnt_TE1 = bcnt_TE2;
    is_bcnt_overflow_cond_hit_TE1 = {NUM_BLOCKS{1'b0}};
    for (int i=0; i<NUM_BLOCKS; i++) begin
      next_bcnt_TE1 = $bits(next_bcnt_TE1)'(next_bcnt_TE1 + BCNT_WIDTH'(inbrhist_pkt_repeat_TE1[i]));
      is_bcnt_overflow_cond_hit_TE1[i] = &next_bcnt_TE1 & ~|i;
      next_bcnt_TE1 = is_bcnt_overflow_cond_hit_TE1[i]?$bits(next_bcnt_TE1)'(1'b0):next_bcnt_TE1;
    end
  end

  assign inbrhist_ibh_pkt_clr_after_bcnt_overflow = (|is_repatbranch_generating_packets_TE1 & ~inbrhist_pkt_interpipe_repeat_matches_TE1) & ~bcnt_overflow_TE1;
  generic_dff_clr #(.WIDTH(1)) bcnt_TE2_overflowed_ff (.out(bcnt_TE2_overflowed), .in(1'b1), .clr(isErrorClear_ANY | (|next_bcnt_TE1) | inbrhist_ibh_pkt_clr_after_bcnt_overflow), .en(bcnt_overflow_TE1 & rb_packet_pipe_vld_TE1), .clk(clock), .rst_n(reset_n));

  // RepeatBranch Packet framing
  assign rb_mso_data_in_TE1[0] = MSO_DATA_IN_WIDTH'({bcnt_to_report_TE1,Cr4BTrteinstfeatures.Trtesrcid[3:0],REPEATBRANCH});
  assign rb_mso_data_in_len_TE1[0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(bcnt_len_TE1) + ($clog2(MSO_DATA_IN_WIDTH)+1)'('ha);
  assign rb_mso_data_is_var_TE1[0] = '1;
  assign rb_mso_data_is_last_TE1[0] = '0;

  assign rb_mso_data_in_TE1[1] = MSO_DATA_IN_WIDTH'(rb_tstamp_to_report); 
  assign rb_mso_data_in_len_TE1[1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(rb_tstamp_to_report_len); 
  assign rb_mso_data_is_var_TE1[1] = '1;
  assign rb_mso_data_is_last_TE1[1] = '1;

  assign rb_packet_pipe_vld_TE1 = ((inbrhist_pkt_repeat_clr_TE1 & (bcnt_TE2!=0)) | inbrhist_pkt_repeat_reset_TE1) & ~(isErrorGeneration_TE0 & ~isBTHBOverflow_TE0);

  generic_dff #(.WIDTH(1)) rb_packet_pipe_vld_TE2_ff (.out(rb_packet_pipe_vld_TE2), .in(rb_packet_pipe_vld_TE1), .en(1'b1), .clk(clock), .rst_n(reset_n));

  for (genvar j=0; j<2; j++) begin
      dfd_te_mso #(
        .DATA_WIDTH(MSO_DATA_IN_WIDTH)
      ) i_rb_te_mso (
        .data_in(rb_mso_data_in_TE1[j]),
        .data_len(rb_mso_data_in_len_TE1[j]),
        .is_var(rb_mso_data_is_var_TE1[j]),
        .is_last(rb_mso_data_is_last_TE1[j]), 
        .data_out(rb_mso_data_out_TE1[j]),
        .data_out_be(rb_mso_data_out_be_TE1[j]),
        .data_out_len_in_bytes(rb_mso_data_out_len_in_bytes_TE1[j])
      );
  end

  assign rb_pkt_buffer_data_TE1.pkt_data_len = ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(rb_mso_data_out_len_in_bytes_TE1[0] + rb_mso_data_out_len_in_bytes_TE1[1]);
    
  assign rb_pkt_buffer_data_TE1.pkt_data_be = (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((rb_mso_data_out_be_TE1[1])) << (rb_mso_data_out_len_in_bytes_TE1[0]))
                                            | NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(rb_mso_data_out_be_TE1[0]);
  assign rb_pkt_buffer_data_TE1.pkt_data = ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(rb_mso_data_out_TE1[1]) << (rb_mso_data_out_len_in_bytes_TE1[0] * 'h8))
                                          | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(rb_mso_data_out_TE1[0]);

  // ----------------------------------------------------------------------------------------------
  // Ownership and VDM Generation
  // ----------------------------------------------------------------------------------------------
  // Packet pipe valids
  assign own_vdm_packet_pipe_vld_TE0[0] = (((context_switch_report_pend & (curr_pkt_TE0[0] == INDIRECTBRANCHHIST)) | (curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC)) & packet_pipe_vld_TE0[0]); // (~isAddrPending_TE0[0] | (pend_addr_available & isAddrPending_delay[0]))
  assign own_vdm_packet_pipe_vld_TE0[1] = ((curr_pkt_TE0[1] == INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[1]) | ((context_switch_report_pend & (curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & (curr_pkt_TE0[0] == PROGTRACESYNC)) & (&packet_pipe_vld_TE0));
  assign own_vdm_packet_pipe_is_vdm_vld_TE0 = is_tval_to_report_pend & ~((curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[0] & ~(pend_btype_to_report_delay inside {2'h2, 2'h3}));

  // Packet framing
  assign own_vdm_mso_data_in_TE0[0][0] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,Cr4BTrteinstfeatures.Trtesrcid[3:0],OWNERSHIP});
  assign own_vdm_mso_data_in_len_TE0[0][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(process_context_len_TE0 + 6'ha);
  assign own_vdm_mso_data_is_var_TE0[0][0] = '1;
  assign own_vdm_mso_data_is_last_TE0[0][0] = own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[0][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'({2'b00, Cr4BTrteinstfeatures.Trtesrcid[3:0],VENDORDEFINED}):MSO_DATA_IN_WIDTH'(trTstamp_TE0);
  assign own_vdm_mso_data_in_len_TE0[0][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(4'hc)):($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0);
  assign own_vdm_mso_data_is_var_TE0[0][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[0][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0; 

  assign own_vdm_mso_data_in_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(tval_to_report_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(tval_to_report_len_TE0)):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[0][2] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[0][3] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(trTstamp_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[0][3] = own_vdm_packet_pipe_is_vdm_vld_TE0?($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[0][3] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[0][3] = own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[1][0] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,Cr4BTrteinstfeatures.Trtesrcid[3:0],OWNERSHIP});
  assign own_vdm_mso_data_in_len_TE0[1][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(process_context_len_TE0 + 6'ha);
  assign own_vdm_mso_data_is_var_TE0[1][0] = '1;
  assign own_vdm_mso_data_is_last_TE0[1][0] = own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[1][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'({2'b00, Cr4BTrteinstfeatures.Trtesrcid[3:0],VENDORDEFINED}):MSO_DATA_IN_WIDTH'(trTstamp_TE0);
  assign own_vdm_mso_data_in_len_TE0[1][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(4'hc)):($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0);
  assign own_vdm_mso_data_is_var_TE0[1][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[1][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0; 

  assign own_vdm_mso_data_in_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(tval_to_report_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(tval_to_report_len_TE0)):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[1][2] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[1][3] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(trTstamp_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[1][3] = own_vdm_packet_pipe_is_vdm_vld_TE0?($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[1][3] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[1][3] = own_vdm_packet_pipe_is_vdm_vld_TE0;

  generic_dff #(.WIDTH(NUM_BLOCKS)) own_vdm_packet_pipe_vld_TE1_ff (.out(own_vdm_packet_pipe_vld_TE1), .in(own_vdm_packet_pipe_vld_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n));

  for (genvar i=0; i<NUM_BLOCKS; i++) begin
    for (genvar j=0; j<4; j++) begin
      // Flop the TE0 data to feed into the MSO logic
      generic_dff #(.WIDTH(MSO_DATA_IN_WIDTH)) own_vdm_mso_data_in_TE1_ff (.out(own_vdm_mso_data_in_TE1[i][j]), .in(own_vdm_mso_data_in_TE0[i][j]), .en(own_vdm_packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH($clog2(MSO_DATA_IN_WIDTH)+1)) own_vdm_mso_data_in_len_TE1_ff (.out(own_vdm_mso_data_in_len_TE1[i][j]), .in(own_vdm_mso_data_in_len_TE0[i][j]), .en(own_vdm_packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH(1)) own_vdm_mso_data_is_var_TE1_ff (.out(own_vdm_mso_data_is_var_TE1[i][j]), .in(own_vdm_mso_data_is_var_TE0[i][j]), .en(own_vdm_packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));
      generic_dff #(.WIDTH(1)) own_vdm_mso_data_is_last_TE1_ff (.out(own_vdm_mso_data_is_last_TE1[i][j]), .in(own_vdm_mso_data_is_last_TE0[i][j]), .en(own_vdm_packet_pipe_vld_TE0[i]), .clk(clock), .rst_n(reset_n));

      dfd_te_mso #(
        .DATA_WIDTH(MSO_DATA_IN_WIDTH)
      ) i_own_vdm_te_mso (
        .data_in(own_vdm_mso_data_in_TE1[i][j]),
        .data_len(own_vdm_mso_data_in_len_TE1[i][j]),
        .is_var(own_vdm_mso_data_is_var_TE1[i][j]),
        .is_last(own_vdm_mso_data_is_last_TE1[i][j]), 
        .data_out(own_vdm_mso_data_out_TE1[i][j]),
        .data_out_be(own_vdm_mso_data_out_be_TE1[i][j]),
        .data_out_len_in_bytes(own_vdm_mso_data_out_len_in_bytes_TE1[i][j])
      );
    end

    assign own_vdm_pkt_buffer_data_TE1[i].pkt_data_len = ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(own_vdm_mso_data_out_len_in_bytes_TE1[i][0] + own_vdm_mso_data_out_len_in_bytes_TE1[i][1] + own_vdm_mso_data_out_len_in_bytes_TE1[i][2]+ own_vdm_mso_data_out_len_in_bytes_TE1[i][3]);
    assign own_vdm_pkt_buffer_data_TE1[i].pkt_data_be = (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((own_vdm_mso_data_out_be_TE1[i][3])) << (own_vdm_mso_data_out_len_in_bytes_TE1[i][0] + own_vdm_mso_data_out_len_in_bytes_TE1[i][1] + own_vdm_mso_data_out_len_in_bytes_TE1[i][2]))
                                                  | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(own_vdm_mso_data_out_be_TE1[i][2]) << (own_vdm_mso_data_out_len_in_bytes_TE1[i][0] + own_vdm_mso_data_out_len_in_bytes_TE1[i][1]))
                                                  | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(own_vdm_mso_data_out_be_TE1[i][1]) << (own_vdm_mso_data_out_len_in_bytes_TE1[i][0] ))
                                                  | NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(own_vdm_mso_data_out_be_TE1[i][0]);
    assign own_vdm_pkt_buffer_data_TE1[i].pkt_data = ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(own_vdm_mso_data_out_TE1[i][3]) << ((own_vdm_mso_data_out_len_in_bytes_TE1[i][0] + own_vdm_mso_data_out_len_in_bytes_TE1[i][1] + own_vdm_mso_data_out_len_in_bytes_TE1[i][2]) * 'h8)) 
                                                | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(own_vdm_mso_data_out_TE1[i][2]) << ((own_vdm_mso_data_out_len_in_bytes_TE1[i][0] + own_vdm_mso_data_out_len_in_bytes_TE1[i][1]) * 'h8))
                                                | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(own_vdm_mso_data_out_TE1[i][1]) << (own_vdm_mso_data_out_len_in_bytes_TE1[i][0] * 'h8))
                                                | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(own_vdm_mso_data_out_TE1[i][0]);
  end

  

  // ----------------------------------------------------------------------------------------------
  // Packet Buffer (4 Entries) (TE2/Output to TNIF)
  // ----------------------------------------------------------------------------------------------
  // 2W = Max of two packets can be generated in a single cycle
  // 1R = The dfd_packetizer reads one packet
  generic_fifoMN #(
    .ALLOW_CLEAR  (0),
    .DATA_WIDTH   ($bits(pkt_buffer_t)),
    .ENTRIES      (PKT_FIFO_CNT),
    .NUM_WR       (5),
    .NUM_RD       (1)) pkt_buffer (
      // Outputs
      .o_cnt            (pkt_fifo_cnt_TE2),
      .o_data           ({pkt_data_out_be,pkt_len_in_bytes,pkt_data_out}),
      .o_broadside_data (/* Not needed */),
      .o_rdptr          (/* Not needed */),
      .o_wrptr          (/* Not needed */),
      // Inputs
      .i_data           (pkt_fifo_wr_data_TE1),
      .i_psh            (pkt_fifo_push_TE1 & {5{~isErrorPacketPushed_ANY}}),
      .i_pop            (requested_packet_space_granted & |pkt_fifo_cnt_TE2),
      .i_clear          ({PKT_FIFO_CNT{1'b0}}),
      .i_clk            (clock),
      .i_reset_n        (reset_n)
  );

  // ----------------------------------------------------------------------------------------------
  // Error Packet Conditions:
  // ----------------------------------------------------------------------------------------------
  generic_dff #(.WIDTH(1)) isErrorGeneration_TE1_ff (.out(isErrorGeneration_TE1), .in(isErrorGeneration_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  generic_dff_clr #(.WIDTH(1)) isEncoderBufferOverflowflop_ANY_ff (.out(isEncoderBufferOverflowflop_ANY), .in(1'b1), .clr(pkt_fifo_cnt_TE2 < 2), .en(pkt_fifo_cnt_TE2 >= 4), .clk(clock), .rst_n(reset_n)); 
  assign isEncoderBufferOverflow_ANY = isEncoderBufferOverflowflop_ANY; 
  
  assign isErrorPacketPushed_TE1 = (curr_pkt_TE1[0] == ERROR) & packet_pipe_vld_TE1[0] & (pkt_fifo_cnt_TE2 <= (PKT_FIFO_CNT-1));

  generic_dff_clr #(.WIDTH(1)) isErrorPacketPushed_ANY_ff (.out(isErrorPacketPushed_ANY), .in(1'b1), .clr(pkt_fifo_cnt_TE2 < 2), .en(isErrorPacketPushed_TE1), .clk(clock), .rst_n(reset_n)); 
  generic_dff #(.WIDTH(1)) isErrorPacketPushed_d1_ANY_ff (.out(isErrorPacketPushed_d1_ANY), .in(isErrorPacketPushed_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  assign isErrorClear_ANY = (isEncoderBufferOverflow_ANY | isBTHBOverflow_TE0) & trStartStop_ANY; 

  assign isBTHBOverflowErrorPushed_TE0 = (curr_pkt_TE0[0] == ERROR) & packet_pipe_vld_TE0[0] & isBTHBOverflow_TE0;
  generic_dff_clr #(.WIDTH(1)) isBTHBOverflowErrorPushed_TE1_ff (.out(isBTHBOverflowErrorPushed_TE1), .in(isBTHBOverflowErrorPushed_TE0), .clr((curr_pkt_TE0[0] == PROGTRACESYNC) & packet_pipe_vld_TE0[0]), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  assign trTeResyncAfterEncOverflowError_ANY = (~isErrorPacketPushed_ANY & isErrorPacketPushed_d1_ANY);
  generic_dff_clr #(.WIDTH(1)) trTeResyncAfterBTHBOverflowError_ANY_ff (.out(trTeResyncAfterBTHBOverflowError_ANY), .in(1'b1), .clr((curr_pkt_TE0[0] inside {PROGTRACESYNC, PROGTRACECORRELATION}) & packet_pipe_vld_TE0[0]), .en((~isErrorPacketPushed_ANY & isErrorPacketPushed_d1_ANY) | (isBTHBOverflow_TE0 & trStartStop_ANY)), .clk(clock), .rst_n(reset_n)); 
  
  assign trTeResyncAfterError_ANY = trTeResyncAfterEncOverflowError_ANY | trTeResyncAfterBTHBOverflowError_ANY; 

  // StallEnable Conditions
  assign trBackpressure_ANY = isEncoderBufferOverflow_ANY & Cr4BTrtecontrol.Trteinststallena;
  generic_dff #(.WIDTH(1)) MS_MC_trBackpressure_ANY_stg_ff (.out(MS_MC_trBackpressure_ANY), .in(trBackpressure_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  // ----------------------------------------------------------------------------------------------
  // TE - Packetizer Interface
  // ----------------------------------------------------------------------------------------------
  assign request_packet_space_in_bytes = (flush_mode_enable & ~ flush_mode_exit)?(($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'('h4)):{($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1){|pkt_fifo_cnt_TE2}} & ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(pkt_len_in_bytes);
  
  // Flop out the data from the FIFO before sending out to dfd_packetizer
  generic_dff #(.WIDTH(NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)) pktzr_data_in_ff (.out(data_in), .in((flush_mode_enable & ~ flush_mode_exit)?(256'hffffffff):pkt_data_out), .en(request_packet_space_in_bytes!=0 & requested_packet_space_granted), .clk(clock), .rst_n(reset_n)); 
  generic_dff #(.WIDTH(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)) pktzr_data_in_be_ff (.out(data_byte_be_in), .in((flush_mode_enable & ~ flush_mode_exit)?(32'hf):pkt_data_out_be), .en(request_packet_space_in_bytes!=0 & requested_packet_space_granted), .clk(clock), .rst_n(reset_n)); 

  // ----------------------------------------------------------------------------------------------
  // Entry to and Exit from Debug Mode 
  // ----------------------------------------------------------------------------------------------
  // Based on Enc Priv_TE0
  assign trPrivisDebug_TE0 = ((trEncPriv_TE0 == PRIVMODE_DEBUG) | (~trTeTraceInPatchEnable_ANY & (trEncPriv_TE0 == PRIVMODE_PATCH))); 
  assign trPrivFiltered_TE0 = (trPrivModeFilterEnable_ANY?(trEncPriv_TE0 == trPrivModeFilterChoice_ANY):1'b1);

  generic_dff #(.WIDTH(1)) trPrivisDebug_TE1_ff (.out(trPrivisDebug_TE1), .in(trPrivisDebug_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n)); 

  assign trPrivDebugModeEntry_ANY = trPrivisDebug_TE0 & ~trPrivisDebug_TE1;
  assign trPrivDebugModeExit_ANY = ~trPrivisDebug_TE0 & trPrivisDebug_TE1;

  generic_dff_clr #(.WIDTH(1)) trPrivDebugEntry_PTC_pending_ANY_ff (.out(trPrivDebugEntry_PTC_pending_ANY), .in(1'b1), .en(trPrivDebugModeEntry_ANY & trTracingInProgress_ANY), .clr(trPrivDebugModeExit_ANY | ~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACECORRELATION) & packet_pipe_vld_TE0[0])), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) trSwControlStop_PTC_pending_ANY_ff (.out(trSwControlStop_PTC_pending_ANY), .in(1'b1), .en(trSwControlStop_ANY & trTracingInProgress_ANY), .clr(~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACECORRELATION) & packet_pipe_vld_TE0[0])), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trTeReStartAfterDebugMode_ANY_ff (.out(trTeReStartAfterDebugMode_ANY), .in(1'b1), .clr(~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACESYNC) & packet_pipe_vld_TE0[0] & ~trTeResyncAfterError_ANY)), .en(trPrivDebugModeExit_ANY & trTeInsttracing_Enable_ANY), .clk(clock), .rst_n(reset_n));

  // ----------------------------------------------------------------------------------------------
  // Trace MMR control logic
  // ----------------------------------------------------------------------------------------------
  assign MS_MC_trActive_ANY = trTeActive_ANY; //Control to MC to notify trace is active
  assign MS_MC_trStallModeEn_ANY = Cr4BTrtecontrol.Trteinststallena;

  assign trTeActive_ANY = Cr4BTrtecontrol.Trteactive;
  assign trTeSwEnable_ANY = trTeActive_ANY & Cr4BTrtecontrol.Trteenable;
  assign trTeEnable_ANY = trTeSwEnable_ANY & ~trace_hardware_stop & ~(trace_hw_flush_in_progress); 
  assign trTeInsttracing_Enable_ANY = trTeEnable_ANY & Cr4BTrtecontrol.Trteinsttracing; 

  assign trBthbStartStop_ANY = trTeSwEnable_ANY; 

  assign trTeEnable_Trace_ANY = trTeInsttracing_Enable_ANY & trPrivFiltered_TE0;
  assign trStartStop_ANY = trTeInsttracing_Enable_ANY & trPrivFiltered_TE0 & ~trPrivisDebug_TE0;

  assign trStart_ANY = trStartStop_ANY & ~trStartStop_ANY_d1;
  assign trStop_ANY = ~trStartStop_ANY & trStartStop_ANY_d1;

  assign trSwControlStop_ANY_m1 = ~trTeInsttracing_Enable_ANY & trTeInsttracing_Enable_ANY_d1; 

  // Trigger Controls
  assign trTeTrigEnable_ANY = Cr4BTrtecontrol.Trteinsttriggerenable;
  assign trStartfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_ON);
  assign trStopfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_OFF);
  assign trNotifyfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_NOTIFY); 

  assign trNotifySyncfromTrig_ANY = (trPulsefromCLA_ANY | trNotifyfromTrig_ANY) & trTracingInProgress_ANY & ~trStop_ANY;

  // Trace Patch mode controls
  assign trTeTraceInPatchEnable_ANY = Cr4BTrteimpl.Trtetracepatchenable;

  // CLA trigger controls
  assign trTeCLATrigEnable_ANY = Cr4BTrteimpl.Trteclatriggerenable;
  assign trStartfromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_start_ANY;
  assign trStopfromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_stop_ANY;
  assign trPulsefromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_pulse_ANY; 
  
  // Always Update the Empty status to the TrTeControl
  always_comb begin 
    Cr4BTrtecontrolWr = '0;
    Cr4BTrtecontrolWr.TrteinststalloroverflowWrEn = isErrorGeneration_TE0 | (trTeInsttracing_Enable_ANY & ~trTeInsttracing_Enable_ANY_d1) | (trTeActive_ANY & ~trTeActive_ANY_d1);
    Cr4BTrtecontrolWr.Data.Trteinststalloroverflow = isErrorGeneration_TE0?1'b1:1'b0;
    Cr4BTrtecontrolWr.TrteinsttracingWrEn = trTeActive_ANY & ((trTeEnable_ANY & (trStartfromTrig_ANY | trStopfromTrig_ANY)) | (trace_hardware_stop & ~trace_hardware_stop_d1 & Cr4BTrtecontrol.Trteenable) | (trTeEnable_ANY & (trStartfromCLA_ANY | trStopfromCLA_ANY)));
    Cr4BTrtecontrolWr.Data.Trteinsttracing = ((trace_hardware_stop & ~trace_hardware_stop_d1) | trStopfromCLA_ANY)?1'b0:((trStartfromTrig_ANY | trStartfromCLA_ANY) | ~(trStopfromTrig_ANY | trStopfromCLA_ANY));
    Cr4BTrtecontrolWr.TrteemptyWrEn = 1'b1;
    Cr4BTrtecontrolWr.Data.Trteempty = packetizer_empty & (pkt_fifo_cnt_TE2 == '0);
  end

  assign trPrivModeFilterEnable_ANY = Cr4BTrteinstfilters.Trteinstfilters[0] & Cr4BTrtefilter0Control.Trtefilterenable & Cr4BTrtefilter0Control.Trtefiltermatchprivilege;
  assign trPrivModeFilterChoice_ANY = PrivMode_e'(Cr4BTrtefilter0Matchinst.Trtefiltermatchchoiceprivilege);

  assign trNotifyIBHS_ANY = trTracingInProgress_ANY & trNotifySyncfromTrig_ANY; 

  generic_dff_clr #(.WIDTH(1)) trTeTracingStartfromTrigger_ANY_ff (.out(trTeTracingStartfromTrigger_ANY), .in(1'b1), .clr(~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACESYNC) & packet_pipe_vld_TE0[0] & ~trTeResyncAfterError_ANY)), .en(trStartfromTrig_ANY), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) trNotifyIBHS_ANY_delay_ff (.out(trNotifyIBHS_ANY_delay), .in(1'b1), .clr(~trNotifyIBHS_ANY & (trStart_ANY | ((curr_pkt_TE1[0]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE1[0]) | ((curr_pkt_TE1[1]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE1[1]))), .en(trTracingInProgress_ANY & trNotifyIBHS_ANY), .clk(clock), .rst_n(reset_n)); //trStartStop_ANY
 
  generic_dff_clr #(.WIDTH(1)) trIBHS_trig_psync_ANY_ff (.out(trIBHS_trig_psync_ANY), .in(1'b1), .en(periodic_sync_count_overflow | trNotifyIBHS_ANY), .clr(trStart_ANY |((curr_pkt_TE0[0]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[0]) | ((curr_pkt_TE0[1]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[1])), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trIBHS_trig_psync_ANY_delay_ff (.out(trIBHS_trig_psync_ANY_delay), .in(trIBHS_trig_psync_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  // ----------------------------------------------------------------------------------------------
  // Trace Start/Stop/Flush control logic
  // ----------------------------------------------------------------------------------------------
  generic_dff #(.WIDTH(1)) trStop_ANY_d1_ff (.out(trStop_ANY_d1), .in(trStop_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trStartStop_ANY_d1_ff (.out(trStartStop_ANY_d1), .in(trStartStop_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trBthbStartStop_ANY_d1_ff (.out(trBthbStartStop_ANY_d1), .in(trBthbStartStop_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  assign MS_MC_trStartStop_ANY = trBthbStartStop_ANY_d1;

  generic_dff #(.WIDTH(1)) trTeActive_ANY_d1_ff (.out(trTeActive_ANY_d1), .in(trTeActive_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trTeEnable_ANY_d1_ff (.out(trTeEnable_ANY_d1), .in(trTeEnable_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trTeInsttracing_Enable_ANY_d1_ff (.out(trTeInsttracing_Enable_ANY_d1), .in(trTeInsttracing_Enable_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trSwControlStop_ANY_ff (.out(trSwControlStop_ANY), .in(trSwControlStop_ANY_m1), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trPrivDebugModeExit_ANY_d1_ff (.out(trPrivDebugModeExit_ANY_d1), .in(trPrivDebugModeExit_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trProgressed_after_DebugEntry_ANY_ff (.out(trProgressed_after_DebugEntry_ANY), .in(1'b1), .clr((trSwControlStop_ANY & ~trPrivDebugModeEntry_ANY) | ((curr_pkt_TE0[0] == PROGTRACESYNC) & packet_pipe_vld_TE0[0])), .en(Cr4BTrtecontrol.Trteactive & (trTeInsttracing_Enable_ANY | trTeInsttracing_Enable_ANY_d1) & (trTracingInProgress_ANY) & (trPrivDebugModeEntry_ANY | trPrivDebugEntry_PTC_pending_ANY)), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trTeEnable_Trace_ANY_d1_ff (.out(trTeEnable_Trace_ANY_d1), .in(trTeEnable_Trace_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) trReEnable_ANY_ff (.out(trReEnable_ANY), .in((~trTeInsttracing_Enable_ANY & trTeInsttracing_Enable_ANY_d1) | trReEnable_ANY), .clr(~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACESYNC) & packet_pipe_vld_TE0[0] & ~trTeResyncAfterError_ANY)), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trFlush_ANY_ff (.out(trFlush_ANY), .in(1'b1), .clr(~|pkt_fifo_cnt_TE2 & flush_mode_exit & flush_mode_enable), .en(~trTeEnable_ANY & trTeEnable_ANY_d1), .clk(clock), .rst_n(reset_n));
  
  assign trPacketizer_Flushmode_enable_ANY = trFlush_ANY & (pkt_fifo_cnt_TE2 == '0) & (curr_pkt_TE0[0] != PROGTRACECORRELATION) & ~|pkt_fifo_push_TE1;
  generic_dff_clr #(.WIDTH(1)) flush_mode_enable_ff (.out(flush_mode_enable), .in(1'b1), .clr(flush_mode_enable & flush_mode_exit), .en(trPacketizer_Flushmode_enable_ANY), .clk(clock), .rst_n(reset_n));
  
  generic_dff #(.WIDTH(1)) trace_hardware_flush_d1_ff (.out(trace_hardware_flush_d1), .in(trace_hardware_flush), .en(1'b1), .clk(clock), .rst_n(reset_n));
  assign trace_hardware_flush_pulse = ~trace_hardware_flush_d1 & trace_hardware_flush; 

  generic_dff_clr #(.WIDTH(1)) trace_hardware_flush_pulse_valid_ff (.out(trace_hardware_flush_pulse_valid), .in(1'b1), .clr((flush_mode_enable & ~trace_hardware_flush_pulse) | flush_mode_exit), .en(trace_hardware_flush_pulse), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) trace_hw_flush_in_progress_ff (.out(trace_hw_flush_in_progress), .in(1'b1), .clr(~trTracingInProgress_ANY & ~|pkt_fifo_push_TE1 & ~|pkt_fifo_cnt_TE2 & ~flush_mode_enable & flush_mode_exit & packetizer_empty /*& ~trace_hardware_flush*/), .en(trace_hardware_flush_pulse & trTeEnable_ANY), .clk(clock), .rst_n(reset_n));

  generic_dff #(.WIDTH(1)) trace_hardware_stop_d1_ff (.out(trace_hardware_stop_d1), .in(trace_hardware_stop), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trace_stop_after_error_wo_sync_ff (.out(trace_stop_after_error_wo_sync), .in(1'b1), .clr((curr_pkt_TE0[0] inside {PROGTRACESYNC, PROGTRACECORRELATION}) & packet_pipe_vld_TE0[0]), .en(isErrorPacketPushed_ANY & isProgTraceSync_Pending & ~isProgTraceSync_Pending_clr), .clk(clock), .rst_n(reset_n));
  // ----------------------------------------------------------------------------------------------
  // Periodic SYNC Pending
  // ----------------------------------------------------------------------------------------------
  generic_dff #(.WIDTH($bits(InstSyncMode))) inst_sync_mode_ff (.out({InstSyncMode}), .in(InstSyncMode_e'(Cr4BTrtecontrol.Trtesyncmode)), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(PERIODIC_SYNC_COUNT_WIDTH + 1)) periodic_sync_max_count_ff (.out(periodic_sync_max_count), .in((PERIODIC_SYNC_COUNT_WIDTH+1)'({1 << (Cr4BTrtecontrol.Trtesyncmax + 4)})), .en(1'b1), .clk(clock), .rst_n(reset_n));

  assign periodic_sync_count_clr = trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0) | trStop_ANY | isErrorClear_ANY | trTeResyncAfterError_ANY;

  generic_dff #(.WIDTH(1)) periodic_sync_count_overflow_delay_ff (.out(periodic_sync_count_overflow_delay), .in(periodic_sync_count_overflow), .en(1'b1), .clk(clock), .rst_n(reset_n)); 
  generic_dff_clr #(.WIDTH(1)) periodic_sync_count_overflow_ff (.out(periodic_sync_count_overflow), .in(1'b1), .clr(periodic_sync_count_clr/*periodic_sync_count_overflow*/), .en(periodic_sync_count_overflow_stg), .clk(clock), .rst_n(reset_n));

  // Compute the next value of the periodic sync counter based on the SYNC mode
  generic_dff_clr #(.WIDTH(PERIODIC_SYNC_COUNT_WIDTH)) periodic_sync_count_ff (.out(periodic_sync_count), .in(next_periodic_sync_count), .clr(periodic_sync_count_clr), .en(InstSyncMode != SYNC_OFF), .clk(clock), .rst_n(reset_n)); //Should be cleared when any SYNC message is generated or trace stop
  always_comb begin
    periodic_sync_pkt_count = periodic_sync_count + (PERIODIC_SYNC_COUNT_WIDTH+1)'(|pkt_buffer_data_vld_TE2) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(&pkt_buffer_data_vld_TE2) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(trStart_ANY) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(trTeResyncAfterError_ANY) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(rb_packet_pipe_vld_TE2) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(context_switch_TE1) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(is_tval_to_report_TE1); // Packet Push happens in TE1 Stage, but trStart_ANY is in TE0 stage
    periodic_sync_iretire_count = $bits(periodic_sync_iretire_count)'(periodic_sync_count + ({(PERIODIC_SYNC_COUNT_WIDTH+1){pipe_vld_TE0[0] & (trStartStop_ANY | trStop_ANY)}} & (PERIODIC_SYNC_COUNT_WIDTH+1)'(trIRetire_TE0[0])) + ({(PERIODIC_SYNC_COUNT_WIDTH+1){pipe_vld_TE0[1] & (trStartStop_ANY | trStop_ANY)}} & (PERIODIC_SYNC_COUNT_WIDTH+1)'(trIRetire_TE0[1])));
    periodic_sync_cycle_count = periodic_sync_count + (PERIODIC_SYNC_COUNT_WIDTH)'(|trTstamp_TE0?(trTstamp_RE6 - trTstamp_TE0):'h0);

    periodic_sync_pkt_count_overflow = (InstSyncMode == PKT_COUNT) & (periodic_sync_pkt_count > periodic_sync_max_count);
    periodic_sync_cycle_count_overflow = (InstSyncMode == CYCLE_COUNT) & (periodic_sync_cycle_count > periodic_sync_max_count);
    periodic_sync_iretire_count_overflow = (InstSyncMode == IRETIRE_COUNT) & (periodic_sync_iretire_count > periodic_sync_max_count);

    periodic_sync_count_overflow_stg = trStartStop_ANY & (periodic_sync_pkt_count_overflow | (|periodic_sync_iretire_count_overflow) | periodic_sync_cycle_count_overflow);

    next_periodic_sync_pkt_count = $bits(next_periodic_sync_pkt_count)'(periodic_sync_pkt_count);
    next_periodic_sync_cycle_count = $bits(next_periodic_sync_cycle_count)'(periodic_sync_cycle_count);
    next_periodic_sync_iretire_count = $bits(next_periodic_sync_iretire_count)'(periodic_sync_iretire_count);

    next_periodic_sync_count = (InstSyncMode == PKT_COUNT)?next_periodic_sync_pkt_count:((InstSyncMode == IRETIRE_COUNT)?next_periodic_sync_iretire_count:next_periodic_sync_cycle_count);
  end

  // ----------------------------------------------------------------------------------------------
  // Control Logic for the Packet generation : Pending packet flops for each type
  // ---------------------------------------------------------------------------------------------- 
  // Flop for the SyncPending conditions
  generic_dff_clr #(.WIDTH(1)) isProgTraceSync_Pending_TE0_ff (.out(isProgTraceSync_Pending), .in(trStart_ANY | isErrorGeneration_TE0 | isProgTraceSync_Pending), .clr((isProgTraceSync_Pending_clr | trStop_ANY) & ~isErrorGeneration_TE0), .en(1'b1), .clk(clock), .rst_n(reset_n)); 
  generic_dff_clr #(.WIDTH(1)) isOwnership_Pending_TE0_ff (.out(isOwnership_Pending), .in(curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC | curr_pkt_TE0[1] == INDIRECTBRANCHHISTSYNC | context_switch_TE0 | isOwnership_Pending), .clr(isOwnership_Pending_clr), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) isProgTraceCorrelation_Pending_TE0_ff (.out(isProgTraceCorrelation_Pending), .in(isProgTraceCorrelation_Pending | (trStop_ANY & ~(packet_pipe_vld_TE0[0] & (curr_pkt_TE0[0] == PROGTRACECORRELATION)))), .clr(isProgTraceCorrelation_Pending_clr | trStart_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) isIndirectBranchHist_Pending_TE0_ff (.out(isIndirectBranchHist_Pending), .in(isIndirectBranchHist_Pending | (is_hist_to_report_TE0[0] & (~trIBHS_trig_psync_ANY | isAddrPending_TE0[0])) | is_hist_to_report_TE0[1] | aux_ibh_packet_tgt_pending_TE0), .clr((isIndirectBranchHist_Pending_clr | isIndirectBranchHistSync_Pending_clr | trIBHS_trig_psync_ANY) & ~((is_hist_to_report_TE0[0] & isAddrPending_TE0[0]) | is_hist_to_report_TE0[1] | aux_ibh_packet_tgt_pending_TE0)), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff_clr #(.WIDTH(1)) isIndirectBranchHistSync_Pending_TE0_ff (.out(isIndirectBranchHistSync_Pending), .in((isIndirectBranchHistSync_Pending | trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0)) & ~trSwControlStop_ANY), .clr(isIndirectBranchHistSync_Pending_clr | trStart_ANY), .en(1'b1), .clk(clock), .rst_n(reset_n));

  // Clear conditions for each of the packet flops
  always_comb begin
    isProgTraceSync_Pending_clr = 'b0;
    isOwnership_Pending_clr = 'b0;
    isProgTraceCorrelation_Pending_clr = 'b0;
    isIndirectBranchHist_Pending_clr = 'b0;
    isIndirectBranchHistSync_Pending_clr = 'b0;
    for(int i=0; i<NUM_BLOCKS; i++) begin
      isProgTraceSync_Pending_clr = isProgTraceSync_Pending_clr | ((curr_pkt_TE0[i] == PROGTRACESYNC) & packet_pipe_vld_TE0[i]);
      isOwnership_Pending_clr = isOwnership_Pending_clr | ((curr_pkt_TE0[i] == OWNERSHIP) & packet_pipe_vld_TE0[i]) & ~context_switch_TE0;
      isProgTraceCorrelation_Pending_clr = isProgTraceCorrelation_Pending_clr | ((curr_pkt_TE0[i] == PROGTRACECORRELATION) & isProgTraceCorrelation_Pending); 
      isIndirectBranchHist_Pending_clr = isIndirectBranchHist_Pending_clr | ((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i]) & ~|(is_hist_to_report_TE0 & isAddrPending_TE0);
      isIndirectBranchHistSync_Pending_clr = isIndirectBranchHistSync_Pending_clr | ((curr_pkt_TE0[i] == INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[i]);
    end
  end

  assign isErrorGeneration_TE0 = trStartStop_ANY & (isBTHBOverflow_TE0 | (isEncoderBufferOverflow_ANY & ~isErrorPacketPushed_ANY));

  // Priority MUX for deciding the packet type to be generated
  always_comb begin
    // The reset value for both the packet generation pipes
    curr_pkt_TE0[0] = PKT_UNKNOWN;
    curr_pkt_TE0[1] = PKT_UNKNOWN;

    addrBlock = 'b0;
    dataBlock = 'b0;
    use_pend_addr = 'b0;
    use_pend_btype = 'b0;
    use_flopped_tgt_addr = 'b0;
    packet_pipe_vld_TE0 = 'b0;
    rsfull_msg_icnt_or_hist_TE0 = 'b0;
    rsfull_msg_vld_ANY = 'b0;
    context_switch_IBH_reported_TE0 = 'b0;

    if (isErrorGeneration_TE0) begin
      curr_pkt_TE0[0] = ERROR;
      packet_pipe_vld_TE0[0] = 1'b1;
    end

    else if (~(isErrorPacketPushed_TE1 | isErrorPacketPushed_ANY)) begin    
      if (isProgTraceSync_Pending & ~trSwControlStop_ANY) begin
        curr_pkt_TE0[0] = PROGTRACESYNC;
        packet_pipe_vld_TE0[0] = pipe_vld_TE0[0]; 
      end

      if ((trSwControlStop_ANY & ((~trTracingInProgress_ANY & trProgressed_after_DebugEntry_ANY))) | (trTracingInProgress_ANY & (isProgTraceCorrelation_Pending | trStop_iCount_Hist_to_report_TE0))) begin
        curr_pkt_TE0[0] = PROGTRACECORRELATION;
        use_pend_addr[0] = isProgTraceCorrelation_Pending;
        packet_pipe_vld_TE0[0] = 1'b1;
      end

      if (isResourceFull_Packet_TE0) begin
        if (|is_hist_overflow_to_report_TE0 & |is_iCount_overflow_TE0) begin
          curr_pkt_TE0[0] = RESOURCEFULL;

          if (is_hist_overflow_to_report_TE0 == is_iCount_overflow_TE0) begin
            rsfull_msg_icnt_or_hist_TE0[0] = 1'b0; //ICNT on pipe-0
            rsfull_msg_icnt_or_hist_TE0[1] = 1'b1; //HIST on pipe-1
          end
          else begin
            rsfull_msg_icnt_or_hist_TE0[0] = is_iCount_overflow_TE0[1]?1'b1:1'b0;
            rsfull_msg_icnt_or_hist_TE0[1] = is_iCount_overflow_TE0[1]?1'b0:1'b1;
          end

          packet_pipe_vld_TE0 = 2'b01;
          rsfull_msg_vld_ANY = 2'b11;
        end
        else begin
          if (|is_iCount_overflow_TE0) begin
            rsfull_msg_vld_ANY = 2'b01;
            curr_pkt_TE0[0] = RESOURCEFULL;
            rsfull_msg_icnt_or_hist_TE0[0] = 1'b0;

            packet_pipe_vld_TE0[0] = 1'b1;
          end
          else if (|is_hist_overflow_to_report_TE0) begin
            rsfull_msg_vld_ANY = 2'b01;
            curr_pkt_TE0[0] = RESOURCEFULL;
            rsfull_msg_icnt_or_hist_TE0[0] = 1'b1;
            packet_pipe_vld_TE0[0] = 1'b1; 
          end
        end
      end

      if ((|seq_icnt_overflow_TE0) | (|is_hist_to_report_TE0) | isIndirectBranchHist_Pending | isIndirectBranchHistSync_Pending | aux_ibh_packet_pipe_vld_TE0) begin 
        if (isProgTraceSync_Pending | isProgTraceCorrelation_Pending | isResourceFull_Packet_TE0) begin // Pipe-0 is occupied, use the Pipe-1 packet gen flow
          // 1. First Look for pending on any of the previous pipes (Only one of them can be pending at any point of time)
          // 2. Look for the to reports on this pipe, if possible with addr then take it, else keep them pending
          if (trTracingInProgress_ANY & |isAddrPending_delay & (pend_addr_available | trStop_iCount_Hist_to_report_TE0)) begin // If there's pending already from previous pipe-0 or pipe-1
            curr_pkt_TE0[1] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | seq_icnt_overflow_delay)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            addrBlock[1] = 1'b0;
            dataBlock[1] = 1'b0;
            use_pend_addr[1] = 1'b1;
            use_pend_btype[1] = 1'b1;
            use_flopped_tgt_addr[1] = trStop_iCount_Hist_to_report_TE0; 
            // Whenever the stop comes and we use that to generate pending IBHS without target address, the uaddr reported will be 0x0
            packet_pipe_vld_TE0[1] = 1'b1;
            context_switch_IBH_reported_TE0 = context_switch_report_pend?1'b1:1'b0;
            // Wait for the next valid to come and clear the isAddrPending_TE0[0]
          end 
          else begin
            if ((is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0]) | aux_ibh_packet_pipe_vld_TE0) begin // If there's no pending then from previous pipes and current pipe-0 has a ready to go
              curr_pkt_TE0[1] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
              dataBlock[1] = 1'b0;
              addrBlock[1] = 1'b1;
              packet_pipe_vld_TE0[1] = 1'b1;
            end
          end
        end

        else begin // Pipe-0 is free to use for the packet gen flow
          // 1. First Look for pending on any of the previous pipes (Only one of them can be pending at any point of time)
          // 2. Look for the to reports on this pipe, if possible with addr then take it, else keep them pending
          if (trTracingInProgress_ANY & |isAddrPending_delay & (pend_addr_available | trStop_iCount_Hist_to_report_TE0)) begin // If there's pending already from previous pipe-0 or pipe-1
            curr_pkt_TE0[0] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | seq_icnt_overflow_delay)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            addrBlock[0] = 1'b0; //This matters
            dataBlock[0] = 1'b0; //Don't care in this case
            use_pend_addr[0] = 1'b1; //This matters
            use_pend_btype[0] = 1'b1; //This matters 
            use_flopped_tgt_addr[0] = trStop_iCount_Hist_to_report_TE0;  
            packet_pipe_vld_TE0[0] = 1'b1;
            // Wait for the next valid to come and clear the isAddrPending_TE0[0]
            context_switch_IBH_reported_TE0 = context_switch_report_pend?1'b1:1'b0;

            if (is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0]) begin  
              curr_pkt_TE0[1] = ((trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending) & ~(curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC))?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
              dataBlock[1] = 1'b0;
              addrBlock[1] = 1'b1;
              packet_pipe_vld_TE0[1] = 1'b1;
            end
          end 
          else if (|(seq_icnt_overflow_TE0 & ~is_sic_AddrPending_TE0) | (is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0])) begin // If there's no pending then from previous pipes and current pipe-0 has a ready to go
            curr_pkt_TE0[0] = (trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0) | isIndirectBranchHistSync_Pending)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            dataBlock[0] = seq_icnt_overflow_TE0[1]?1'b1:1'b0;
            addrBlock[0] = 1'b1;
            packet_pipe_vld_TE0[0] = 1'b1;

            // AUX IBH packet to be generated for SIC IBHS case
            curr_pkt_TE0[1] = aux_ibh_packet_pipe_vld_TE0?INDIRECTBRANCHHIST:PKT_UNKNOWN;
            packet_pipe_vld_TE0[1] = aux_ibh_packet_pipe_vld_TE0;
          end 
        end
      end
    end
  end

endmodule

