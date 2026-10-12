// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`include "generic_macro_assertion.vh"

module te_encoder
import te_pkg::*;
import ntr_sink_mmr_pkg::*;
import ntr_mmr_pkg::*;
  #(
    parameter PKT_FIFO_CNT = 12,
    parameter int unsigned IRETIRE_WIDTH = 5,
    parameter int unsigned PC_WIDTH = te_pkg::TE_PC_WIDTH,
    parameter int unsigned CONTEXT_WIDTH = te_pkg::TE_CONTEXT_WIDTH,
    parameter int unsigned TVAL_WIDTH = te_pkg::TE_TVAL_WIDTH,
    parameter int unsigned TSTAMP_WIDTH = te_pkg::TE_TSTAMP_WIDTH,
    localparam int unsigned ITYPE_WIDTH = te_pkg::TE_ITYPE_WIDTH,
    localparam int unsigned NUM_BLOCKS = te_pkg::TE_NUM_BLOCKS
  )(
  input   logic                                                 clock,
  input   logic                                                 i_reset_n,
  input   logic                                                 reset_n_warm_ovrride,

  input   logic [NUM_BLOCKS-1:0] [IRETIRE_WIDTH-1:0]            trIRetire_RE6,
  input   logic [NUM_BLOCKS-1:0] [ITYPE_WIDTH-1:0]              trIType_RE6,
  input   logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                 trIAddr_RE6,
  input   logic [NUM_BLOCKS-1:0]                                trILastSize_RE6,

  input   PrivMode_e                                            trPriv_RE6,
  input   logic [CONTEXT_WIDTH-1:0]                             trContext_RE6,
  input   logic [TSTAMP_WIDTH-1:0]                              trTstamp_RE6,
  input   logic [TVAL_WIDTH-1:0]                                trTval_RE6,

  input   logic                                                 MC_MS_trError_RE6,
  output  logic                                                 MS_MC_trActive_ANY,
  output  logic                                                 MS_MC_trStallModeEn_ANY,
  output  logic                                                 MS_MC_trStartStop_ANY,
  output  logic                                                 MS_MC_trBackpressure_ANY,

  input   TrigTraceControl_e                                    MC_MS_trTrigControl_ANY,

  input   logic                                                 cla_trigger_trace_start_ANY,
  input   logic                                                 cla_trigger_trace_stop_ANY,
  input   logic                                                 cla_trigger_trace_pulse_ANY,

  input   NtrTrtecontrolMmr_s                                  Trtecontrol,
  input   NtrTrtscontrolMmr_s                                  Trtscontrol,
  input   NtrTrteimplMmr_s                                     Trteimpl,
  input   NtrTrteinstfeaturesMmr_s                             Trteinstfeatures,
  input   NtrTrteinstfiltersMmr_s                              Trteinstfilters,
  input   NtrTrtefilter0ControlMmr_s                           Trtefilter0Control,
  input   NtrTrtefilter0MatchinstMmr_s                         Trtefilter0Matchinst,
  output  NtrTrtecontrolMmrWr_s                                TrtecontrolWr,

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

  logic [NUM_BLOCKS-1:0] [IRETIRE_WIDTH-1:0]                    trIRetire_TE0;
  logic [NUM_BLOCKS-1:0] [ITYPE_WIDTH-1:0]                      trIType_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         trIAddr_TE0;
  logic [NUM_BLOCKS-1:0]                                        trILastSize_TE0;

  PrivMode_e                                                    trPriv_TE0;
  logic [CONTEXT_WIDTH-1:0]                                     trContext_TE0;
  logic [TVAL_WIDTH-1:0]                                        trTval_TE0;
  logic [TSTAMP_WIDTH-1:0]                                      trTstamp_TE0;
  logic                                                         trtsenable;

  logic [NUM_BLOCKS-1:0]                                        pipe_vld_RE6, pipe_vld_TE0;
  logic [NUM_BLOCKS-1:0]                                        packet_pipe_vld_TE0, packet_pipe_vld_TE1;
  logic                                                         rb_packet_pipe_vld_TE0, rb_packet_pipe_vld_TE1;
  logic [NUM_BLOCKS-1:0]                                        own_vdm_packet_pipe_vld_TE0, own_vdm_packet_pipe_vld_TE1;

  PrivMode_e                                                    trEncPriv_TE0;
  logic                                                         trBthbStartStop_ANY, trBthbStartStop_ANY_d1;

  logic                                                         trStartStop_ANY, trStartStop_ANY_d1;
  logic                                                         trace_hardware_stop_d1;
  logic                                                         trProgressed_after_DebugEntry_ANY;
  logic                                                         trStart_ANY, trStop_ANY, trStop_ANY_d1;
  logic                                                         trSwControlStop_ANY, trSwControlStop_ANY_m1, trSwControlStop_PTC_pending_ANY;
  logic                                                         trTeActive_ANY, trTeActive_ANY_d1;
  logic                                                         trTeEnable_ANY, trTeEnable_ANY_d1;
  logic                                                         trTeSwEnable_ANY;
  logic                                                         trTeInsttracing_Enable_ANY, trTeInsttracing_Enable_ANY_d1;

  logic                                                         trFlush_ANY;
  logic                                                         trReEnable_ANY;
  logic                                                         trTeTrigEnable_ANY;
  logic                                                         trStartfromTrig_ANY, trStopfromTrig_ANY, trNotifyfromTrig_ANY;
  logic                                                         trNotifySyncfromTrig_ANY;

  logic                                                         trTracingInProgress_ANY;
  logic                                                         trBackpressure_ANY;
  logic                                                         trace_stop_after_error_wo_sync;

  logic                                                         trace_hardware_flush_d1;
  logic                                                         trace_hardware_flush_pulse;
  logic                                                         trace_hw_flush_in_progress;
  logic                                                         trPacketizer_Flushmode_enable_ANY;

  logic                                                         trTeTraceInPatchEnable_ANY;

  logic                                                         trTeCLATrigEnable_ANY;
  logic                                                         trStartfromCLA_ANY, trStopfromCLA_ANY, trPulsefromCLA_ANY;

  logic                                                         trPrivModeFilterEnable_ANY;
  PrivMode_e                                                    trPrivModeFilterChoice_ANY;
  logic                                                         trPrivFiltered_RE6, trPrivFiltered_TE0;

  logic                                                         trPrivisDebug_RE6, trPrivisDebug_TE0, trPrivisDebug_TE1;
  logic                                                         trPrivDebugModeEntry_ANY, trPrivDebugEntry_PTC_pending_ANY;
  logic                                                         trPrivDebugModeExit_ANY;
  logic                                                         trTeReStartAfterDebugMode_ANY;

  logic [HIST_WIDTH-1:0]                                        hist_TE1, next_hist_TE0;
  logic [NUM_BLOCKS-1:0] [HIST_WIDTH-1:0]                       hist_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_hist_to_report_TE0;
  logic [CONTEXT_WIDTH+5-1:0]                                   context_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_hist_overflow_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_hist_overflow_TE0;
  logic [HIST_WIDTH-1:0]                                        hist_overflow_to_report_TE0, hist_overflow_to_report_delay;

  logic [ICOUNT_WIDTH-1:0]                                      iCount_TE1, next_iCount_TE0;
  logic [NUM_BLOCKS-1:0] [ICOUNT_WIDTH-1:0]                     iCount_to_report_TE0;
  logic [ICOUNT_WIDTH-1:0]                                      trStop_iCount_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_iCount_overflow_TE0;
  logic                                                         trStop_iCount_Hist_to_report_TE0, trStop_iCount_Hist_to_report_TE1;

  logic [NUM_BLOCKS-1:0]                                        seq_icnt_overflow_TE0;
  logic                                                         seq_icnt_overflow_delay;
  logic [PC_WIDTH-1:1]                                          seq_icnt_overflow_faddr_to_report;

  logic                                                         aux_ibh_packet_pipe_vld_TE0;
  logic                                                         aux_ibh_use_sic_uaddr_TE0;
  logic                                                         aux_ibh_packet_tgt_pending_TE0;
  logic [ICOUNT_WIDTH-1:0]                                      aux_ibh_packet_icount_TE0;
  logic [PC_WIDTH-1:1]                                          aux_ibh_uaddr_TE0;

  logic [NUM_BLOCKS-1:0]                                        rsfull_msg_vld_ANY, rsfull_msg_icnt_or_hist_TE0;

  logic                                                         trCorrelationMessageSent_ANY;

  logic                                                         context_switch_TE0, context_switch_TE1, context_switch_report_pend, context_switch_IBH_reported_TE0, context_switch_IBH_reported_TE1;
  logic                                                         own_vdm_packet_pipe_is_vdm_vld_TE0;

  logic                                                         is_tval_to_report_TE0, is_tval_to_report_TE1, is_tval_to_report_pend;
  logic [TVAL_WIDTH-1:0]                                        tval_to_report_TE0;

  logic [NUM_BLOCKS-1:0] [BTYPE_WIDTH-1:0]                      bType_to_report_TE0, ibh_btype_reported_TE0;
  logic [BTYPE_WIDTH-1:0]                                       pend_btype_to_report_delay;

  logic [BCNT_WIDTH-1:0]                                        bcnt_TE1, next_bcnt_TE0, bcnt_to_report_TE0;
  logic [NUM_BLOCKS-1:0]                                        is_bcnt_overflow_cond_hit_TE0;
  logic                                                         bcnt_overflow_TE0, bcnt_TE1_overflowed;

  logic [PC_WIDTH-1:1]                                          ref_addr_TE1;
  /* verilator lint_off UNOPTFLAT */
  logic [NUM_BLOCKS-1:0]                                        next_ref_addr_vld_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         next_ref_addr_TE0;
   /* verilator lint_on UNOPTFLAT */
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         u_addr_TE0;

  logic [NUM_BLOCKS-1:0]                                        indirectBranchInst_TE0;

  logic [TSTAMP_WIDTH-1:0]                                      trTstamp_TE1;
  logic [TSTAMP_WIDTH-1:0]                                      trStop_tstamp_TE0;
  logic [TSTAMP_COUNTER_WIDTH-1:0]                              rel_tstamp_TE0;
  logic [$clog2(TSTAMP_COUNTER_WIDTH)-1:0]                      rel_tstamp_raw_len_TE0;
  logic [$clog2(TSTAMP_COUNTER_WIDTH):0]                        rel_tstamp_len_TE0;
  logic                                                         rel_tstamp_overflow_TE0;
  logic                                                         rel_tstamp_overflow_TE1;

  InstSyncMode_e                                                InstSyncMode;
  logic [PERIODIC_SYNC_COUNT_WIDTH-1:0]                         periodic_sync_count;
  logic [PERIODIC_SYNC_COUNT_WIDTH:0]                           periodic_sync_max_count, periodic_sync_pkt_count, periodic_sync_iretire_count, periodic_sync_cycle_count;
  logic [PERIODIC_SYNC_COUNT_WIDTH-1:0]                         next_periodic_sync_count, next_periodic_sync_pkt_count, next_periodic_sync_iretire_count, next_periodic_sync_cycle_count;
  logic                                                         periodic_sync_pkt_count_overflow, periodic_sync_cycle_count_overflow, periodic_sync_iretire_count_overflow;
  logic                                                         periodic_sync_count_overflow, periodic_sync_count_overflow_stg;
  logic                                                         periodic_sync_count_clr;
  logic                                                         trIBHS_trig_psync_ANY, trIBHS_trig_psync_ANY_delay;

  logic                                                         trNotifyIBHS_ANY, trNotifyIBHS_ANY_delay;

  Pkt_TCode_e [NUM_BLOCKS-1:0]                                  curr_pkt_TE0, curr_pkt_TE1;
  Pkt_TCode_e                                                   rb_hrepeat_pkt_TE0;

  pkt_buffer_t [NUM_BLOCKS-1:0]                                 pkt_buffer_data_TE1, own_vdm_pkt_buffer_data_TE1;
  pkt_buffer_t                                                  rb_pkt_buffer_data_TE1;
  logic                                                         pkt_fifo_pop;

  logic [NUM_BLOCKS-1:0]                                        dataBlock, addrBlock;
  logic [NUM_BLOCKS-1:0]                                        use_pend_addr, use_flopped_tgt_addr;
  logic [NUM_BLOCKS-1:0]                                        use_pend_btype;

  logic [NUM_BLOCKS-1:0]                                        isAddrPending_TE0, isAddrPending_delay;
  logic [NUM_BLOCKS-1:0]                                        is_sic_AddrPending_TE0;
  logic                                                         pend_addr_available;
  logic [ICOUNT_WIDTH-1:0]                                      pend_iCount_to_report_delay, pend_ptc_iCount_to_report_delay;
  logic [HIST_WIDTH-1:0]                                        pend_hist_to_report_delay;
  logic [HIST_WIDTH-1:0]                                        pend_ptc_hist_overflow_to_report_delay;
  logic [TSTAMP_WIDTH-1:0]                                      pend_trstart_tstamp_to_report_delay;
  logic [PC_WIDTH-1:1]                                          pend_faddr_to_report_delay;

  logic [$clog2(ICOUNT_WIDTH):0]                                pend_iCount_to_report_delay_len, pend_ptc_iCount_to_report_delay_len;
  logic [$clog2(TSTAMP_WIDTH):0]                                pend_trstart_tstamp_to_report_delay_len;
  logic [$clog2(HIST_WIDTH):0]                                  pend_hist_to_report_delay_len;
  logic [$clog2(HIST_WIDTH):0]                                  pend_ptc_hist_overflow_to_report_delay_len;
  logic [$clog2(PC_WIDTH):0]                                    pend_faddr_to_report_delay_len;

  logic                                                         isProgTraceSync_Pending, isProgTraceSync_Pending_clr;
  logic                                                         isOwnership_Pending_clr;
  logic                                                         isProgTraceCorrelation_Pending, isProgTraceCorrelation_Pending_clr;
  logic                                                         isIndirectBranchHist_Pending, isIndirectBranchHist_Pending_clr;
  logic                                                         isIndirectBranchHistSync_Pending, isIndirectBranchHistSync_Pending_clr;
  logic                                                         isResourceFull_Packet_TE0, isResourceFull_Packet_TE1;

  logic                                                         isErrorGeneration_TE0;
  logic                                                         isBTHBOverflow_TE0;
  logic                                                         isErrorClear_ANY, isEncoderBufferOverflow_ANY, isEncoderBufferOverflowflop_ANY;
  logic                                                         isErrorPacketPushed_ANY, isErrorPacketPushed_d1_ANY, isErrorPacketPushed_TE1;

  logic                                                         trTeResyncAfterEncOverflowError_ANY, trTeResyncAfterBTHBOverflowError_ANY, trTeResyncAfterError_ANY;

  logic [NUM_BLOCKS-1:0] [$clog2(ICOUNT_WIDTH)-1:0]             icnt_raw_len_TE0;
  logic [$clog2(ICOUNT_WIDTH)-1:0]                              trStop_iCount_to_report_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH)-1:0]                 faddr_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH)-1:0]                 uaddr_raw_len_TE0;
  logic [$clog2(CONTEXT_WIDTH+5)-1:0]                           process_context_raw_len_TE0;
  logic [$clog2(TVAL_WIDTH)-1:0]                                tval_to_report_raw_len_TE0;
  logic [$clog2(TSTAMP_WIDTH)-1:0]                              tstamp_raw_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(HIST_WIDTH)-1:0]               hist_raw_len_TE0;
  logic [$clog2(HIST_WIDTH)-1:0]                                hist_overflow_to_report_raw_len_TE0;
  logic [$clog2(BCNT_WIDTH)-1:0]                                bcnt_raw_len_TE0;
  logic [$clog2(HREPEAT_COUNTER_WIDTH)-1:0]                     hrepeat_counter_raw_len_TE0;
  logic [$clog2(HIST_WIDTH)-1:0]                                hrepeat_pattern_raw_len_TE0;
  logic [$clog2(PC_WIDTH)-1:0]                                  aux_ibh_uaddr_raw_len_TE0;
  logic [$clog2(ICOUNT_WIDTH)-1:0]                              aux_ibh_packet_icount_raw_len_TE0;

  logic [NUM_BLOCKS-1:0] [$clog2(ICOUNT_WIDTH):0]               iCount_to_report_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH):0]                   faddr_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(PC_WIDTH):0]                   uaddr_len_TE0;
  logic [$clog2(CONTEXT_WIDTH+5):0]                             process_context_len_TE0;
  logic [$clog2(TVAL_WIDTH):0]                                  tval_to_report_len_TE0;
  logic [$clog2(TSTAMP_WIDTH):0]                                tstamp_len_TE0;
  logic [$clog2(HIST_WIDTH):0]                                  hist_overflow_to_report_len_TE0;
  logic [$clog2(HIST_WIDTH):0]                                  hrepeat_pattern_len_TE0;
  logic [NUM_BLOCKS-1:0] [$clog2(HIST_WIDTH):0]                 hist_report_len_TE0;
  logic [$clog2(BCNT_WIDTH):0]                                  bcnt_len_TE0;
  logic [$clog2(HREPEAT_COUNTER_WIDTH):0]                       hrepeat_counter_len_TE0;
  logic [$clog2(PC_WIDTH):0]                                    aux_ibh_uaddr_len_TE0;
  logic [$clog2(ICOUNT_WIDTH):0]                                aux_ibh_packet_icount_len_TE0;

  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_IN_WIDTH-1:0]                   mso_data_in_TE0, mso_data_in_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [$clog2(MSO_DATA_IN_WIDTH):0]             mso_data_in_len_TE0, mso_data_in_len_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0]                                           mso_data_is_var_TE0, mso_data_is_var_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0]                                           mso_data_is_last_TE0, mso_data_is_last_TE1;

  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_OUT_WIDTH-1:0]                  mso_data_out_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         mso_data_out_be_TE1;
  logic [NUM_BLOCKS-1:0] [NUM_MSO-1:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   mso_data_out_len_in_bytes_TE1;

  logic [2:0] [MSO_DATA_IN_WIDTH-1:0]                   rb_mso_data_in_TE0, rb_mso_data_in_TE1;
  logic [2:0] [$clog2(MSO_DATA_IN_WIDTH):0]             rb_mso_data_in_len_TE0, rb_mso_data_in_len_TE1;
  logic [2:0]                                           rb_mso_data_is_var_TE0, rb_mso_data_is_var_TE1;
  logic [2:0]                                           rb_mso_data_is_last_TE0, rb_mso_data_is_last_TE1;

  logic [2:0] [MSO_DATA_OUT_WIDTH-1:0]                  rb_mso_data_out_TE1;
  logic [2:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         rb_mso_data_out_be_TE1;
  logic [2:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   rb_mso_data_out_len_in_bytes_TE1;

  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_IN_WIDTH-1:0]                   own_vdm_mso_data_in_TE0, own_vdm_mso_data_in_TE1;
  logic [NUM_BLOCKS-1:0] [3:0] [$clog2(MSO_DATA_IN_WIDTH):0]             own_vdm_mso_data_in_len_TE0, own_vdm_mso_data_in_len_TE1;
  logic [NUM_BLOCKS-1:0] [3:0]                                           own_vdm_mso_data_is_var_TE0, own_vdm_mso_data_is_var_TE1;
  logic [NUM_BLOCKS-1:0] [3:0]                                           own_vdm_mso_data_is_last_TE0, own_vdm_mso_data_is_last_TE1;

  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_OUT_WIDTH-1:0]                  own_vdm_mso_data_out_TE1;
  logic [NUM_BLOCKS-1:0] [3:0] [MSO_DATA_OUT_WIDTH_IN_BYTES-1:0]         own_vdm_mso_data_out_be_TE1;
  logic [NUM_BLOCKS-1:0] [3:0] [$clog2(MSO_DATA_OUT_WIDTH_IN_BYTES):0]   own_vdm_mso_data_out_len_in_bytes_TE1;

  logic [NUM_BLOCKS-1:0] [ICOUNT_WIDTH-1:0]                     next_inbrhist_icnt_TE0;
  logic [NUM_BLOCKS-1:0] [PC_WIDTH-1:1]                         next_inbrhist_uaddr_TE0;
  logic [NUM_BLOCKS-1:0] [HIST_WIDTH-1:0]                       next_inbrhist_hist_TE0;

  logic [ICOUNT_WIDTH-1:0]                                      inbrhist_icnt_TE1;
  logic [PC_WIDTH-1:1]                                          inbrhist_uaddr_TE1;
  logic [HIST_WIDTH-1:0]                                        inbrhist_hist_TE1;

  logic [NUM_BLOCKS-1:0]                                        inbrhist_hist_repeat_TE0, inbrhist_icnt_repeat_TE0, inbrhist_uaddr_repeat_TE0, inbrhist_pkt_repeat_matches_TE0, inbrhist_pkt_repeat_TE0, is_repeatbranch_generating_packets_TE0;
  logic                                                         inbrhist_pkt_interpipe_repeat_matches_TE0;
  logic                                                         inbrhist_pkt_repeat_reset_TE0;
  logic                                                         inbrhist_pkt_repeat_clr_TE0;
  logic                                                         inbrhist_ibh_pkt_clr_after_bcnt_overflow;

  logic [HIST_WIDTH-1:0]                                        hrepeat_pattern_TE0;
  logic [HREPEAT_COUNTER_WIDTH-1:0]                             hrepeat_counter_TE0, next_hrepeat_counter_TE0, hrepeat_counter_to_report_TE0;
  logic                                                         hrepeat_match_TE0, hrepeat_break_TE0;
  logic                                                         hrepeat_counter_overflow_TE0, hrepeat_pkt_vld_TE0, hrepeat_pkt_vld_TE1;

  logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0]            pkt_len_in_bytes;
  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0]                pkt_data_out;
  logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0]                  pkt_data_out_be;
  logic [NUM_BLOCKS-1:0]                                        pkt_buffer_data_vld_TE1, pkt_buffer_data_vld_TE2;
  logic [4:0]                                                   pkt_fifo_push_TE1;
  pkt_buffer_t [4:0]                                            pkt_fifo_wr_data_TE1;
  logic [$clog2(PKT_FIFO_CNT):0]                                pkt_fifo_cnt_TE2;

  logic [NUM_BLOCKS-1:0]                                        packet_pipe_vld_ibh_TE0;

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_input_flops
    generic_dff #(
        .WIDTH       ($bits(logic [IRETIRE_WIDTH-1:0])),
        .RESET_VALUE ('0)
    ) trIRetireTE0_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    ('1),
        .in    (trIRetire_RE6[i]),
        .out   (trIRetire_TE0[i])
    );
    generic_dff #(
        .WIDTH       ($bits(logic [ITYPE_WIDTH-1:0])),
        .RESET_VALUE ('0)
    ) trItypeTE0_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    ('1),
        .in    (trIType_RE6[i]),
        .out   (trIType_TE0[i])
    );
    generic_dff #(
        .WIDTH       ($bits(logic [PC_WIDTH-1-1:0])),
        .RESET_VALUE ('0)
    ) trIAddrTE0_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    ('1),
        .in    (trIAddr_RE6[i]),
        .out   (trIAddr_TE0[i])
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) trILastSizeTE0_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    ('1),
        .in    (trILastSize_RE6[i]),
        .out   (trILastSize_TE0[i])
    );

    assign pipe_vld_TE0[i] = (|trIRetire_TE0[i]) | (trIType_TE0[i] inside {ITYPE_EXCEPTION, ITYPE_INTERRUPT});

  end

  generic_dff #(
      .WIDTH       ($bits(logic [TSTAMP_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) trTstampTE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trTstamp_RE6),
      .out   (trTstamp_TE0)
  );
  generic_dff #(
      .WIDTH       ($bits(PrivMode_e)),
      .RESET_VALUE (PRIVMODE_USER)
  ) trPriv_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trPriv_RE6),
      .out   (trPriv_TE0)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [CONTEXT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) trContext_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trContext_RE6),
      .out   (trContext_TE0)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [TVAL_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) trTval_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trTval_RE6),
      .out   (trTval_TE0)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trBTHBError_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (MC_MS_trError_RE6),
      .out   (isBTHBOverflow_TE0)
  );

  assign trEncPriv_TE0 = trPriv_RE6;

  generic_dff_clr #(
      .WIDTH       ($bits(logic [TSTAMP_COUNTER_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) tstamp_counter_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trtsenable & trStartStop_ANY),
      .clr   (trStart_ANY | isErrorClear_ANY | trCorrelationMessageSent_ANY | (|(packet_pipe_vld_TE0 & ~inbrhist_pkt_repeat_TE0)) | rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0 | (|own_vdm_packet_pipe_vld_TE0)),
      .in    (TSTAMP_COUNTER_WIDTH'(rel_tstamp_TE0 + 1)),
      .out   (rel_tstamp_TE0)
  );

  assign rel_tstamp_overflow_TE0 = rel_tstamp_TE0[TSTAMP_COUNTER_WIDTH-1] & trtsenable & trStartStop_ANY;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) rel_tstamp_overflow_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (rel_tstamp_overflow_TE0),
      .clr   (trStart_ANY | isErrorClear_ANY | trCorrelationMessageSent_ANY | (|(packet_pipe_vld_TE0 & ~inbrhist_pkt_repeat_TE0)) | rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0 | (|own_vdm_packet_pipe_vld_TE0)),
      .in    (1'b1),
      .out   (rel_tstamp_overflow_TE1)
  );

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_bType_to_report_TE0
    assign bType_to_report_TE0[i] = trStartStop_ANY_d1 & (trIType_TE0[i]==ITYPE_EXCEPTION)?2'h2:(trIType_TE0[i]==ITYPE_INTERRUPT?2'h3:2'h0);

    assign indirectBranchInst_TE0[i] = trStartStop_ANY_d1 & ((trIType_TE0[i] == ITYPE_EXCEPTION) | (trIType_TE0[i] == ITYPE_INTERRUPT) | (trIType_TE0[i] == ITYPE_EXCEPTION_INTERRUPT_RETURN) | (trIType_TE0[i] == ITYPE_JUMP));
  end

  assign context_switch_TE0 = trStartStop_ANY_d1 & pipe_vld_TE0[0] & ((trIType_TE0[0]==ITYPE_EXCEPTION) | (trIType_TE0[0]==ITYPE_INTERRUPT) | (trIType_TE0[0] == ITYPE_EXCEPTION_INTERRUPT_RETURN));
  assign context_to_report_TE0 = {trContext_TE0,trEncPriv_TE0,2'b00};

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) context_switch_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (context_switch_TE0),
      .out   (context_switch_TE1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) is_tval_to_report_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (is_tval_to_report_TE0),
      .out   (is_tval_to_report_TE1)
  );

  assign is_tval_to_report_TE0 = trStartStop_ANY_d1 & pipe_vld_TE0[0] & ((trIType_TE0[0]==ITYPE_EXCEPTION) | (trIType_TE0[0]==ITYPE_INTERRUPT));
  assign tval_to_report_TE0 = trTval_TE0;
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) is_tval_to_report_pend_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (is_tval_to_report_TE0 & trStartStop_ANY & ~isErrorPacketPushed_ANY),
      .clr   ((~is_tval_to_report_TE0 & context_switch_IBH_reported_TE0) | trStop_ANY | isErrorClear_ANY),
      .in    (1'b1),
      .out   (is_tval_to_report_pend)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [TSTAMP_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) trStop_tstamp_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trStop_ANY | (isProgTraceSync_Pending_clr)),
      .clr   (trStart_ANY),
      .in    (trTstamp_TE0),
      .out   (trStop_tstamp_TE0)
  );

  assign trStop_iCount_Hist_to_report_TE0 = ((trTstamp_TE0 >= trStop_tstamp_TE0) & (isProgTraceCorrelation_Pending)) | (trStop_ANY & ~|pipe_vld_TE0);

  generic_dff_clr #(
      .WIDTH       ($bits(logic [HIST_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) hrepeat_pattern_store_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trStartStop_ANY & (|is_hist_overflow_TE0 | hrepeat_break_TE0)),
      .clr   (trStart_ANY | isErrorClear_ANY | trStop_ANY | trCorrelationMessageSent_ANY | (|is_hist_to_report_TE0) | (|seq_icnt_overflow_TE0) | trIBHS_trig_psync_ANY),
      .in    (hist_overflow_to_report_TE0),
      .out   (hrepeat_pattern_TE0)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [HREPEAT_COUNTER_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) hrepeat_counter_store_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trStartStop_ANY & (|is_hist_overflow_TE0 | hrepeat_break_TE0 | hrepeat_match_TE0)),
      .clr   (trStart_ANY | isErrorClear_ANY | trStop_ANY | trCorrelationMessageSent_ANY | (|is_hist_to_report_TE0) | (|seq_icnt_overflow_TE0) | trIBHS_trig_psync_ANY | hrepeat_counter_overflow_TE0),
      .in    (next_hrepeat_counter_TE0),
      .out   (hrepeat_counter_TE0)
  );

  always_comb begin
    next_hist_TE0 = trStart_ANY?HIST_WIDTH'('h1):hist_TE1;

    is_hist_to_report_TE0 = 2'b0;
    hist_to_report_TE0 = {NUM_BLOCKS{next_hist_TE0}};

    is_hist_overflow_to_report_TE0 = 'b0;
    is_hist_overflow_TE0 = 'b0;
    hist_overflow_to_report_TE0 = '0;

    next_iCount_TE0 = trStart_ANY?ICOUNT_WIDTH'('h0):iCount_TE1;

    iCount_to_report_TE0 = {{NUM_BLOCKS{iCount_TE1}}};
    is_iCount_overflow_TE0 = 'h0;
    seq_icnt_overflow_TE0 = 'h0;
    seq_icnt_overflow_faddr_to_report = 'h0;

    isAddrPending_TE0 = '0;
    is_sic_AddrPending_TE0 = '0;
    pend_addr_available = '0;

    aux_ibh_packet_pipe_vld_TE0 = '0;
    aux_ibh_use_sic_uaddr_TE0 = '0;
    aux_ibh_packet_tgt_pending_TE0 = '0;
    aux_ibh_packet_icount_TE0 = '0;

    hrepeat_match_TE0 = '0;
    hrepeat_break_TE0 = '0;
    hrepeat_counter_overflow_TE0 = '0;
    next_hrepeat_counter_TE0 = hrepeat_counter_TE0;

    for (int i=0; i<NUM_BLOCKS; i++) begin
      if (pipe_vld_TE0[0] & isAddrPending_delay[i]) begin
        pend_addr_available = pipe_vld_TE0[0] & isAddrPending_delay[i];
      end

      if (trStop_iCount_Hist_to_report_TE0) begin
        iCount_to_report_TE0[0] = next_iCount_TE0;
      end

      else if(pipe_vld_TE0[i] & ~isErrorClear_ANY & ~(isErrorPacketPushed_TE1 | isBTHBOverflow_TE0 | isErrorPacketPushed_ANY) & trStartStop_ANY_d1 ) begin

        next_iCount_TE0 = next_iCount_TE0 + ((~(trStop_ANY & |indirectBranchInst_TE0))?ICOUNT_WIDTH'(trIRetire_TE0[i]):ICOUNT_WIDTH'(0));

        if (next_iCount_TE0[ICOUNT_WIDTH-1]) begin

          iCount_to_report_TE0[i] = next_iCount_TE0;

          if (trIType_TE0[i] == ITYPE_NOT_TAKEN)
            next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b0};
          else if (trIType_TE0[i] == ITYPE_TAKEN)
            next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b1};

          if (((next_hist_TE0 == 'h1) | (next_hist_TE0[HIST_WIDTH-1] == 'h1)) & ~(indirectBranchInst_TE0[i] | trIBHS_trig_psync_ANY)) begin
            is_iCount_overflow_TE0[i] = 1'b1;
          end
          else begin
            seq_icnt_overflow_TE0[i] = 1'b1;
            is_sic_AddrPending_TE0[i] = ~((i==0) & pipe_vld_TE0[1]);
            seq_icnt_overflow_faddr_to_report = trIAddr_TE0[1];
            hist_to_report_TE0[i] = next_hist_TE0;
            next_hist_TE0 = $bits(next_hist_TE0)'(1'b1);
          end

          next_iCount_TE0 = $bits(next_iCount_TE0)'((~indirectBranchInst_TE0[i])?(next_iCount_TE0 - iCount_to_report_TE0[i]):(ICOUNT_WIDTH'('h0)));
        end

        else begin

          if ( ((i==0) & (trIBHS_trig_psync_ANY & ~|isAddrPending_delay & trStartStop_ANY) & ~isIndirectBranchHist_Pending) | (indirectBranchInst_TE0[i] & trStartStop_ANY)) begin
            is_hist_to_report_TE0[i] = 1'b1;

            isAddrPending_TE0[i] = ~((i==0) & pipe_vld_TE0[1]);

            iCount_to_report_TE0[i] = next_iCount_TE0;
            hist_to_report_TE0[i] = next_hist_TE0;

            next_hist_TE0 = $bits(next_hist_TE0)'(1'b1);
            next_iCount_TE0 = ICOUNT_WIDTH'('h0);
          end
          else if (~(trStop_ANY & |indirectBranchInst_TE0)) begin
            if (trIType_TE0[i] == ITYPE_NOT_TAKEN)
              next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b0};
            else if (trIType_TE0[i] == ITYPE_TAKEN)
              next_hist_TE0 = {next_hist_TE0[HIST_WIDTH-2:0], 1'b1};
          end
        end

        if (next_hist_TE0[HIST_WIDTH-1]) begin
          if (hrepeat_pattern_TE0[HIST_WIDTH-1]) begin
            if (hrepeat_pattern_TE0 == next_hist_TE0) begin

              next_hrepeat_counter_TE0 = hrepeat_counter_TE0 + 1;
              hrepeat_match_TE0 = 1'b1;

              hrepeat_counter_overflow_TE0 = ~hrepeat_counter_TE0[HREPEAT_COUNTER_WIDTH-1] &
                                              next_hrepeat_counter_TE0[HREPEAT_COUNTER_WIDTH-1];
            end
            else begin
              next_hrepeat_counter_TE0 = HREPEAT_COUNTER_WIDTH'(1);
              hrepeat_break_TE0 = 1'b1;
            end
          end
          else begin
            next_hrepeat_counter_TE0 = HREPEAT_COUNTER_WIDTH'(1);
          end
          is_hist_overflow_to_report_TE0[i] = (|is_hist_to_report_TE0) | (|seq_icnt_overflow_TE0) | trIBHS_trig_psync_ANY;
          is_hist_overflow_TE0[i] = 1'b1;
          hist_overflow_to_report_TE0 = next_hist_TE0;
          next_hist_TE0 = $bits(next_hist_TE0)'(1'b1);
        end

      end

    end
  end

  assign hrepeat_pkt_vld_TE0 = hrepeat_pattern_TE0[HIST_WIDTH-1]
                              & (  hrepeat_break_TE0
                                 | hrepeat_counter_overflow_TE0
                                 | (|is_hist_to_report_TE0)
                                 | (|seq_icnt_overflow_TE0)
                                 | trIBHS_trig_psync_ANY
                                 | trCorrelationMessageSent_ANY
                                 | trStop_ANY);

  assign hrepeat_counter_to_report_TE0 = hrepeat_counter_overflow_TE0 ? next_hrepeat_counter_TE0
                                                                      : hrepeat_counter_TE0;

  assign isResourceFull_Packet_TE0 = (|is_iCount_overflow_TE0) | (|is_hist_overflow_to_report_TE0);
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isResourceFull_Packet_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (isResourceFull_Packet_TE0),
      .out   (isResourceFull_Packet_TE1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [NUM_BLOCKS-1:0])),
      .RESET_VALUE ('0)
  ) isAddrPending_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|pipe_vld_TE0),
      .clr   (isErrorClear_ANY | trStop_iCount_Hist_to_report_TE0 | trStop_ANY),
      .in    (isAddrPending_TE0 | is_sic_AddrPending_TE0),
      .out   (isAddrPending_delay)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) seq_icnt_overflow_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|seq_icnt_overflow_TE0),
      .clr   (isIndirectBranchHistSync_Pending_clr | trStart_ANY),
      .in    (1'b1),
      .out   (seq_icnt_overflow_delay)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [BTYPE_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) pend_btype_to_report_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0)),
      .in    ((isAddrPending_TE0[0] | is_sic_AddrPending_TE0[0])?bType_to_report_TE0[0]:bType_to_report_TE0[1]),
      .out   (pend_btype_to_report_delay)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [HIST_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) pend_hist_to_report_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY),
      .in    (aux_ibh_packet_tgt_pending_TE0?'b1:((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?hist_to_report_TE0[0]:hist_to_report_TE0[1])),
      .out   (pend_hist_to_report_delay)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [ICOUNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) pend_iCount_to_report_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY),
      .in    (aux_ibh_packet_tgt_pending_TE0?aux_ibh_packet_icount_TE0:((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?iCount_to_report_TE0[0]:iCount_to_report_TE0[1])),
      .out   (pend_iCount_to_report_delay)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [ICOUNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) pend_ptc_iCount_to_report_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|seq_icnt_overflow_TE0),
      .in    (seq_icnt_overflow_TE0[1]?iCount_to_report_TE0[1]:iCount_to_report_TE0[0]),
      .out   (pend_ptc_iCount_to_report_delay)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(ICOUNT_WIDTH)+1-1:0])),
      .RESET_VALUE ('0)
  ) pend_ptc_iCount_to_report_delay_len_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|seq_icnt_overflow_TE0),
      .in    (seq_icnt_overflow_TE0[1]?iCount_to_report_len_TE0[1]:iCount_to_report_len_TE0[0]),
      .out   (pend_ptc_iCount_to_report_delay_len)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [HIST_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) pend_ptc_hist_overflow_to_report_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|seq_icnt_overflow_TE0),
      .in    (seq_icnt_overflow_TE0[1]?hist_to_report_TE0[1]:hist_to_report_TE0[0]),
      .out   (pend_ptc_hist_overflow_to_report_delay)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(HIST_WIDTH)+1-1:0])),
      .RESET_VALUE ('0)
  ) pend_ptc_hist_overflow_to_report_delay_len_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|seq_icnt_overflow_TE0),
      .in    (seq_icnt_overflow_TE0[1]?hist_report_len_TE0[1]:hist_report_len_TE0[0]),
      .out   (pend_ptc_hist_overflow_to_report_delay_len)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(HIST_WIDTH)+1-1:0])),
      .RESET_VALUE ('0)
  ) pend_hist_to_report_delay_len_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY),
      .in    (aux_ibh_packet_tgt_pending_TE0?$bits(pend_hist_to_report_delay_len)'('b1):((trStop_ANY | is_sic_AddrPending_TE0[0] | isAddrPending_TE0[0])?hist_report_len_TE0[0]:hist_report_len_TE0[1])),
      .out   (pend_hist_to_report_delay_len)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [$clog2(ICOUNT_WIDTH)+1-1:0])),
      .RESET_VALUE ('0)
  ) pend_iCount_to_report_delay_len_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((|isAddrPending_TE0) | (|is_sic_AddrPending_TE0) | trStop_ANY),
      .in    (aux_ibh_packet_tgt_pending_TE0?aux_ibh_packet_icount_len_TE0:((trStop_ANY | isAddrPending_TE0[0] | is_sic_AddrPending_TE0[0])?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1])),
      .out   (pend_iCount_to_report_delay_len)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [HIST_WIDTH-1:0])),
      .RESET_VALUE (HIST_WIDTH'(1))
  ) hist_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (isErrorClear_ANY | trCorrelationMessageSent_ANY | (|pipe_vld_TE0) | hist_TE1[HIST_WIDTH-1] | |trStart_ANY),
      .in    ((trCorrelationMessageSent_ANY | isErrorClear_ANY)?HIST_WIDTH'('h1):next_hist_TE0),
      .out   (hist_TE1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [ICOUNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) iCount_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (isErrorClear_ANY | trCorrelationMessageSent_ANY | (|pipe_vld_TE0) | trStart_ANY),
      .in    ((trCorrelationMessageSent_ANY | isErrorClear_ANY)?ICOUNT_WIDTH'('h0):next_iCount_TE0),
      .out   (iCount_TE1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) context_switch_report_pend_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trStartStop_ANY & context_switch_TE0 & ~isErrorPacketPushed_ANY),
      .clr   (trStop_ANY | isErrorClear_ANY | (context_switch_IBH_reported_TE0 & ~context_switch_TE0)),
      .in    (1'b1),
      .out   (context_switch_report_pend)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) context_switch_IBH_reported_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (context_switch_IBH_reported_TE0),
      .out   (context_switch_IBH_reported_TE1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTracingInProgress_flop_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((curr_pkt_TE0[0] == PROGTRACESYNC) & packet_pipe_vld_TE0[0]),
      .clr   ((curr_pkt_TE0[0] == PROGTRACECORRELATION) | (curr_pkt_TE1[1] == PROGTRACECORRELATION) | (curr_pkt_TE0[0] == ERROR)),
      .in    (1'b1),
      .out   (trTracingInProgress_ANY)
  );

  assign trCorrelationMessageSent_ANY = (curr_pkt_TE0[0] == PROGTRACECORRELATION & packet_pipe_vld_TE0[0]) | (curr_pkt_TE0[1] == PROGTRACECORRELATION & packet_pipe_vld_TE0[1]);

  assign trtsenable = (Trtscontrol.Trtsactive & Trtscontrol.Trtsenable);

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_block_ffs

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

  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(BCNT_WIDTH),
  .DATA_WIDTH(BCNT_WIDTH)
  ) ff_bcnt (
      .req_in(bcnt_to_report_TE0),
      .data_in('0),
      .enc_req_out(bcnt_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign bcnt_len_TE0 = ($clog2(BCNT_WIDTH)+1)'(|bcnt_to_report_TE0) + bcnt_raw_len_TE0;

  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(HIST_WIDTH),
  .DATA_WIDTH(HIST_WIDTH)
  ) ff_hrepeat_pattern (
      .req_in(hrepeat_pattern_TE0),
      .data_in('0),
      .enc_req_out(hrepeat_pattern_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign hrepeat_pattern_len_TE0 = ($clog2(HIST_WIDTH)+1)'(hrepeat_pattern_TE0[HIST_WIDTH-1]) + hrepeat_pattern_raw_len_TE0;

  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(HREPEAT_COUNTER_WIDTH),
  .DATA_WIDTH(HREPEAT_COUNTER_WIDTH)
  ) ff_hrepeat_counter (
      .req_in(hrepeat_counter_to_report_TE0),
      .data_in('0),
      .enc_req_out(hrepeat_counter_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign hrepeat_counter_len_TE0 = ($clog2(HREPEAT_COUNTER_WIDTH)+1)'(|hrepeat_counter_to_report_TE0) + hrepeat_counter_raw_len_TE0;

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

  generic_ffs_fast #(
  .DIR_L2H(1'b0),
  .WIDTH(TSTAMP_COUNTER_WIDTH),
  .DATA_WIDTH(TSTAMP_COUNTER_WIDTH)
  ) ff_rel_tstamp (
      .req_in(rel_tstamp_TE0),
      .data_in('0),
      .enc_req_out(rel_tstamp_raw_len_TE0),

      .data_out(),
      .req_out(),
      .req_out_therm()
  );
  assign rel_tstamp_len_TE0 = ($clog2(TSTAMP_COUNTER_WIDTH)+1)'(|rel_tstamp_TE0) + rel_tstamp_raw_len_TE0;

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

  always_comb begin
    for (int i=0; i<NUM_BLOCKS; i++) begin
      unique case (curr_pkt_TE0[i])
        PROGTRACESYNC: begin
          next_ref_addr_vld_TE0[i] = '1;
          next_ref_addr_TE0[i] = trIAddr_TE0[i];

          next_inbrhist_icnt_TE0[i] = '0;
          next_inbrhist_uaddr_TE0[i] = '0;
          next_inbrhist_hist_TE0[i] = '0;

          ibh_btype_reported_TE0[i] = '0;
          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({'0,trTeResyncAfterError_ANY?RESTART_FIFO_OVERFLOW:(trTeReStartAfterDebugMode_ANY?EXIT_FROM_DEBUG:(trReEnable_ANY?TRACE_ENABLE:EXIT_FROM_RESET)),(Trtecontrol.Trteinhibitsrc?PROGTRACESYNC:{Trteinstfeatures.Trtesrcid[3:0],PROGTRACESYNC})});
          mso_data_in_len_TE0[i][0] = (Trtecontrol.Trteinhibitsrc? 'ha : 'he);
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][0] = 'h1;
          mso_data_is_last_TE0[i][0] = (faddr_len_TE0[i] == 0) & (tstamp_len_TE0 == 0);

          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'(trIAddr_TE0[i]);
          mso_data_in_len_TE0[i][1] = faddr_len_TE0[i];
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = ~trtsenable | (tstamp_len_TE0 == 0);

          mso_data_in_TE0[i][2] = (trtsenable & ~(tstamp_len_TE0 == 0))?MSO_DATA_IN_WIDTH'(trTstamp_TE0):MSO_DATA_IN_WIDTH'(0);
          mso_data_in_len_TE0[i][2] = (trtsenable & ~(tstamp_len_TE0 == 0))?($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0);
          mso_data_is_var_TE0[i][2] = (trtsenable & ~(tstamp_len_TE0 == 0))?'1:'0;
          mso_data_is_last_TE0[i][2] = (trtsenable & ~(tstamp_len_TE0 == 0))?'1:'0;

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][3] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,(Trtecontrol.Trteinhibitsrc?OWNERSHIP:{Trteinstfeatures.Trtesrcid[3:0],OWNERSHIP})});
          mso_data_in_len_TE0[i][3] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((process_context_len_TE0) + (Trtecontrol.Trteinhibitsrc? 6'h7 : 6'hb));
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
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

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({(trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h0:(trStart_ANY?pend_iCount_to_report_delay:(seq_icnt_overflow_delay?pend_ptc_iCount_to_report_delay:(pipe_vld_TE0[1]?iCount_to_report_TE0[1]:iCount_to_report_TE0[0]))),2'b01,((trTeInsttracing_Enable_ANY | trTeInsttracing_Enable_ANY_d1 | ~trTeTraceInPatchEnable_ANY) & ((trPrivDebugModeEntry_ANY | trPrivDebugEntry_PTC_pending_ANY) & ~(trSwControlStop_PTC_pending_ANY | trSwControlStop_ANY)))?DEBUG_ENTRY:((trace_stop_after_error_wo_sync | (trStop_ANY & trTeResyncAfterError_ANY & isProgTraceSync_Pending))?TRACE_STOP_WITHOUT_SYNC_AFTER_ERROR:PROG_TRACE_DISABLE),(Trtecontrol.Trteinhibitsrc?PROGTRACECORRELATION:{Trteinstfeatures.Trtesrcid[3:0],PROGTRACECORRELATION})});

          mso_data_in_len_TE0[i][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h0:(trStart_ANY?pend_iCount_to_report_delay_len:(seq_icnt_overflow_delay?pend_ptc_iCount_to_report_delay_len:(pipe_vld_TE0[1]?iCount_to_report_len_TE0[1]:iCount_to_report_len_TE0[0])))) + ((Trtecontrol.Trteinhibitsrc)? 'hc :'h10);
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][0] = '1;
          mso_data_is_last_TE0[i][0] = '0;

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][1] = MSO_DATA_IN_WIDTH'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h1:(trStart_ANY?pend_hist_to_report_delay:(seq_icnt_overflow_delay?pend_ptc_hist_overflow_to_report_delay:hist_to_report_TE0[i])));
          mso_data_in_len_TE0[i][1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'((trSwControlStop_ANY & ~trTracingInProgress_ANY)?'h1:(trStart_ANY?pend_hist_to_report_delay_len:(seq_icnt_overflow_delay?pend_ptc_hist_overflow_to_report_delay_len:hist_report_len_TE0[i])));
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][1] = '1;
          mso_data_is_last_TE0[i][1] = ~(trtsenable);

          mso_data_in_TE0[i][2] = (trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0));
          mso_data_in_len_TE0[i][2] = (trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0));
          mso_data_is_var_TE0[i][2] = trtsenable?'1:'0;
          mso_data_is_last_TE0[i][2] = trtsenable?'1:'0;

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
          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({rsfull_msg_icnt_or_hist_TE0[0]?hist_overflow_to_report_TE0:(is_iCount_overflow_TE0[0]?iCount_to_report_TE0[0]:iCount_to_report_TE0[1]),(rsfull_msg_icnt_or_hist_TE0[0]?4'b1:4'b0),(Trtecontrol.Trteinhibitsrc?RESOURCEFULL:{Trteinstfeatures.Trtesrcid[3:0],RESOURCEFULL})});
          mso_data_in_len_TE0[i][0] = (rsfull_msg_icnt_or_hist_TE0[0]?($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_overflow_to_report_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'((is_iCount_overflow_TE0[0]?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1]))) + ((Trtecontrol.Trteinhibitsrc)? 'ha : 'he);
          /* verilator lint_on WIDTH */
          /* verilator lint_on WIDTHTRUNC */
          /* verilator lint_on WIDTHEXPAND */
          mso_data_is_var_TE0[i][0] = '1;
          mso_data_is_last_TE0[i][0] = ~(trtsenable);

          mso_data_in_TE0[i][1] = trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0);
          mso_data_in_len_TE0[i][1] = trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0);
          mso_data_is_var_TE0[i][1] = trtsenable;
          mso_data_is_last_TE0[i][1] = trtsenable;

          /* verilator lint_off WIDTH */
          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][2] = rsfull_msg_vld_ANY[1]?(MSO_DATA_IN_WIDTH'({rsfull_msg_icnt_or_hist_TE0[1]?hist_overflow_to_report_TE0:(is_iCount_overflow_TE0[0]?iCount_to_report_TE0[0]:iCount_to_report_TE0[1]),(rsfull_msg_icnt_or_hist_TE0[1]?4'b1:4'b0),(Trtecontrol.Trteinhibitsrc?RESOURCEFULL:{Trteinstfeatures.Trtesrcid[3:0],RESOURCEFULL})})):(MSO_DATA_IN_WIDTH'('b0));
          mso_data_in_len_TE0[i][2] = rsfull_msg_vld_ANY[1]?((rsfull_msg_icnt_or_hist_TE0[1]?($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_overflow_to_report_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'((is_iCount_overflow_TE0[0]?iCount_to_report_len_TE0[0]:iCount_to_report_len_TE0[1]))) + (Trtecontrol.Trteinhibitsrc? 'ha : 'he)):(($clog2(MSO_DATA_IN_WIDTH)+1)'('b0));
          /* verilator lint_on WIDTH */
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][2] = rsfull_msg_vld_ANY[1];
          mso_data_is_last_TE0[i][2] = ~(rsfull_msg_vld_ANY[1] & trtsenable);

          mso_data_in_TE0[i][3] = (trtsenable & rsfull_msg_vld_ANY[1])?(MSO_DATA_IN_WIDTH'(rel_tstamp_TE0)):MSO_DATA_IN_WIDTH'(0);
          mso_data_in_len_TE0[i][3] = ((trtsenable & rsfull_msg_vld_ANY[1])?(rsfull_msg_vld_ANY[1]?(($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0)):(($clog2(MSO_DATA_IN_WIDTH)+1)'('b0))):($clog2(MSO_DATA_IN_WIDTH)+1)'(0));
          mso_data_is_var_TE0[i][3] = (trtsenable & rsfull_msg_vld_ANY[1]);
          mso_data_is_last_TE0[i][3] = (trtsenable & rsfull_msg_vld_ANY[1]);

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

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({aux_ibh_packet_pipe_vld_TE0?(aux_ibh_packet_icount_TE0):(use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]]),use_pend_btype[i]?pend_btype_to_report_delay:bType_to_report_TE0[dataBlock[i]],(Trtecontrol.Trteinhibitsrc?INDIRECTBRANCHHIST:{Trteinstfeatures.Trtesrcid[3:0],INDIRECTBRANCHHIST})});
          mso_data_in_len_TE0[i][0] = (aux_ibh_packet_pipe_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(aux_ibh_packet_icount_len_TE0)):(use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_iCount_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(iCount_to_report_len_TE0[dataBlock[i]]))) + ((Trtecontrol.Trteinhibitsrc)? 'h8 :'hc);
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][0] = 1'b1;
          mso_data_is_last_TE0[i][0] = '0;

          mso_data_in_TE0[i][1] = (aux_ibh_packet_pipe_vld_TE0 & aux_ibh_use_sic_uaddr_TE0)?(MSO_DATA_IN_WIDTH'(aux_ibh_uaddr_TE0)):(use_flopped_tgt_addr[i]?MSO_DATA_IN_WIDTH'(0):MSO_DATA_IN_WIDTH'(u_addr_TE0[addrBlock[i]]));
          mso_data_in_len_TE0[i][1] = (aux_ibh_packet_pipe_vld_TE0 & aux_ibh_use_sic_uaddr_TE0)?(aux_ibh_uaddr_len_TE0):(use_flopped_tgt_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(0):($clog2(MSO_DATA_IN_WIDTH)+1)'(uaddr_len_TE0[addrBlock[i]]));
          mso_data_is_var_TE0[i][1] = 1'b1;
          mso_data_is_last_TE0[i][1] = '0;

          mso_data_in_TE0[i][2] = aux_ibh_packet_pipe_vld_TE0?(MSO_DATA_IN_WIDTH'(1'b1)):(use_pend_addr[i]?MSO_DATA_IN_WIDTH'(pend_hist_to_report_delay):MSO_DATA_IN_WIDTH'(hist_to_report_TE0[dataBlock[i]]));
          mso_data_in_len_TE0[i][2] =  aux_ibh_packet_pipe_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(1'b1)):(use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_hist_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_report_len_TE0[dataBlock[i]]));
          mso_data_is_var_TE0[i][2] = 1'b1;
          mso_data_is_last_TE0[i][2] = ~(trtsenable);

          mso_data_in_TE0[i][3] = (trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0));
          mso_data_in_len_TE0[i][3] = (trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0));
          mso_data_is_var_TE0[i][3] = trtsenable?'1:'0;
          mso_data_is_last_TE0[i][3] = trtsenable?'1:'0;

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

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({(use_pend_addr[i]?pend_iCount_to_report_delay:iCount_to_report_TE0[dataBlock[i]]),use_pend_btype[i]?pend_btype_to_report_delay:bType_to_report_TE0[dataBlock[i]],(use_pend_addr[i]?seq_icnt_overflow_delay:seq_icnt_overflow_TE0[dataBlock[i]])?SEQ_INCT_OVERFLOW:((trNotifyIBHS_ANY | trNotifyIBHS_ANY_delay)?TRACE_EVENT:PERIODIC_SYNC),(Trtecontrol.Trteinhibitsrc?INDIRECTBRANCHHISTSYNC:{Trteinstfeatures.Trtesrcid[3:0],INDIRECTBRANCHHISTSYNC})});
          mso_data_in_len_TE0[i][0] = (use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_iCount_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(iCount_to_report_len_TE0[dataBlock[i]])) + ((Trtecontrol.Trteinhibitsrc)? 'hc : 'h10);
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_var_TE0[i][0] = 1'b1;
          mso_data_is_last_TE0[i][0] = '0;

          mso_data_in_TE0[i][1] = (|seq_icnt_overflow_TE0)?MSO_DATA_IN_WIDTH'(seq_icnt_overflow_faddr_to_report):MSO_DATA_IN_WIDTH'(trIAddr_TE0[addrBlock[i]]);
          mso_data_in_len_TE0[i][1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(faddr_len_TE0[addrBlock[i]]);
          mso_data_is_var_TE0[i][1] = 1'b1;
          mso_data_is_last_TE0[i][1] = '0;

          mso_data_in_TE0[i][2] = use_pend_addr[i]?MSO_DATA_IN_WIDTH'(pend_hist_to_report_delay):MSO_DATA_IN_WIDTH'(hist_to_report_TE0[dataBlock[i]]);
          mso_data_in_len_TE0[i][2] = use_pend_addr[i]?($clog2(MSO_DATA_IN_WIDTH)+1)'(pend_hist_to_report_delay_len):($clog2(MSO_DATA_IN_WIDTH)+1)'(hist_report_len_TE0[dataBlock[i]]);
          mso_data_is_var_TE0[i][2] = 1'b1;
          mso_data_is_last_TE0[i][2] = ~trtsenable;

          mso_data_in_TE0[i][3] = trtsenable?MSO_DATA_IN_WIDTH'(trTstamp_TE0):MSO_DATA_IN_WIDTH'(0);
          mso_data_in_len_TE0[i][3] = trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('b0);
          mso_data_is_var_TE0[i][3] = trtsenable?'1:'0;
          mso_data_is_last_TE0[i][3] = trtsenable?'1:'0;

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

          /* verilator lint_off WIDTHEXPAND */
          /* verilator lint_off WIDTHTRUNC */
          mso_data_in_TE0[i][0] = MSO_DATA_IN_WIDTH'({8'h04,4'h0,(Trtecontrol.Trteinhibitsrc?ERROR:{Trteinstfeatures.Trtesrcid[3:0],ERROR})});
          mso_data_in_len_TE0[i][0] = Trtecontrol.Trteinhibitsrc? 'h12 : 'h16;
          mso_data_is_var_TE0[i][0] = '1;
          /* verilator lint_on WIDTHEXPAND */
          /* verilator lint_on WIDTHTRUNC */
          mso_data_is_last_TE0[i][0] = ~(trtsenable);

          mso_data_in_TE0[i][1] = trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0);
          mso_data_in_len_TE0[i][1] = trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0);
          mso_data_is_var_TE0[i][1] = trtsenable?'1:'0;
          mso_data_is_last_TE0[i][1] = trtsenable?'1:'0;

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

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_curr_pkt_TE1_ff
    generic_dff #(
        .WIDTH       ($bits(Pkt_TCode_e)),
        .RESET_VALUE (Pkt_TCode_e'(0))
    ) curr_pkt_TE1_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    ('1),
        .in    ((packet_pipe_vld_TE0[i] & ~inbrhist_pkt_repeat_TE0[i])?curr_pkt_TE0[i]:PKT_UNKNOWN),
        .out   (curr_pkt_TE1[i])
    );
  end

  generic_dff #(
      .WIDTH       ($bits(logic [TSTAMP_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) tstamp_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trStop_ANY | (trStartStop_ANY & (|pipe_vld_TE0))),
      .in    (trStop_ANY?TSTAMP_WIDTH'('h0):trTstamp_TE0),
      .out   (trTstamp_TE1)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [PC_WIDTH-1-1:0])),
      .RESET_VALUE ('0)
  ) ref_addr_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (aux_ibh_packet_pipe_vld_TE0 | (|next_ref_addr_vld_TE0)),
      .in    (aux_ibh_packet_pipe_vld_TE0?trIAddr_TE0[1]:(next_ref_addr_vld_TE0[1]?next_ref_addr_TE0[1]:next_ref_addr_TE0[0])),
      .out   (ref_addr_TE1)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [NUM_BLOCKS-1:0])),
      .RESET_VALUE ('0)
  ) packet_pipe_vld_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (packet_pipe_vld_ibh_TE0),
      .out   (packet_pipe_vld_TE1)
  );

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_blocks_mso_TE1_ff
    for (genvar j=0; j<NUM_MSO; j++) begin : gen_mso_data_TE1_ff

      generic_dff #(
          .WIDTH       ($bits(logic [MSO_DATA_IN_WIDTH-1:0])),
          .RESET_VALUE ('0)
      ) mso_data_in_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (packet_pipe_vld_TE0[i]),
          .in    (mso_data_in_TE0[i][j]),
          .out   (mso_data_in_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic [$clog2(MSO_DATA_IN_WIDTH)+1-1:0])),
          .RESET_VALUE ('0)
      ) mso_data_in_len_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (packet_pipe_vld_TE0[i]),
          .in    (mso_data_in_len_TE0[i][j]),
          .out   (mso_data_in_len_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) mso_data_is_var_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (packet_pipe_vld_TE0[i]),
          .in    (mso_data_is_var_TE0[i][j]),
          .out   (mso_data_is_var_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) mso_data_is_last_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (packet_pipe_vld_TE0[i]),
          .in    (mso_data_is_last_TE0[i][j]),
          .out   (mso_data_is_last_TE1[i][j])
      );

        te_mso #(
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

    assign pkt_buffer_data_vld_TE1[i] = packet_pipe_vld_TE1[i];

  end

  generic_dff #(
      .WIDTH       ($bits(logic [NUM_BLOCKS-1:0])),
      .RESET_VALUE ('0)
  ) pkt_buffer_data_vld_TE2_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (pkt_buffer_data_vld_TE1),
      .out   (pkt_buffer_data_vld_TE2)
  );

  generic_ffs_N #(.DIR_L2H    (1),
            .WIDTH      (5),
            .DATA_WIDTH ($bits(pkt_buffer_t)),
            .NUM_SEL    (5)
  ) Find_Packet_Writes_TE1 (
    .req_in       ({own_vdm_packet_pipe_vld_TE1[1], pkt_buffer_data_vld_TE1[1], own_vdm_packet_pipe_vld_TE1[0], pkt_buffer_data_vld_TE1[0], rb_packet_pipe_vld_TE1 | hrepeat_pkt_vld_TE1}),
    .data_in      ({own_vdm_pkt_buffer_data_TE1[1], pkt_buffer_data_TE1[1], own_vdm_pkt_buffer_data_TE1[0], pkt_buffer_data_TE1[0], rb_pkt_buffer_data_TE1}),
    .req_out      (),
    .req_sum      (pkt_fifo_push_TE1),
    .data_out     (pkt_fifo_wr_data_TE1),
    .enc_req_out  ()
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [ICOUNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) inbrhist_icnt_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1] & ~(ibh_btype_reported_TE0[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE0[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[0] & ~(ibh_btype_reported_TE0[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE0),
      .clr   (trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE0),
      .in    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1])?next_inbrhist_icnt_TE0[1]:next_inbrhist_icnt_TE0[0]),
      .out   (inbrhist_icnt_TE1)
  );
  generic_dff_clr #(
      .WIDTH       ($bits(logic [PC_WIDTH-1-1:0])),
      .RESET_VALUE ('0)
  ) inbrhist_uaddr_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1] & ~(ibh_btype_reported_TE0[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE0[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[0] & ~(ibh_btype_reported_TE0[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE0),
      .clr   (trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE0),
      .in    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1])?next_inbrhist_uaddr_TE0[1]:next_inbrhist_uaddr_TE0[0]),
      .out   (inbrhist_uaddr_TE1)
  );
  generic_dff_clr #(
      .WIDTH       ($bits(logic [HIST_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) inbrhist_hist_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1] & ~(ibh_btype_reported_TE0[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) | ((curr_pkt_TE0[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[0] & ~(ibh_btype_reported_TE0[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~context_switch_IBH_reported_TE0),
      .clr   (trIBHS_trig_psync_ANY | trStop_iCount_Hist_to_report_TE0 | isErrorClear_ANY | inbrhist_pkt_repeat_clr_TE0),
      .in    (((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1])?next_inbrhist_hist_TE0[1]:next_inbrhist_hist_TE0[0]),
      .out   (inbrhist_hist_TE1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [BCNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) bcnt_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (|inbrhist_pkt_repeat_TE0 | inbrhist_pkt_repeat_clr_TE0 | bcnt_overflow_TE0),
      .clr   (isErrorClear_ANY | (rb_packet_pipe_vld_TE0 & ~bcnt_overflow_TE0)),
      .in    (inbrhist_pkt_repeat_clr_TE0?BCNT_WIDTH'('h0):next_bcnt_TE0),
      .out   (bcnt_TE1)
  );

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_inbrhist_pkt_repeat_matches_TE0
    assign inbrhist_hist_repeat_TE0[i] = (next_inbrhist_hist_TE0[i] == inbrhist_hist_TE1);
    assign inbrhist_icnt_repeat_TE0[i] = (next_inbrhist_icnt_TE0[i] == inbrhist_icnt_TE1);
    assign inbrhist_uaddr_repeat_TE0[i] = (next_inbrhist_uaddr_TE0[i] == inbrhist_uaddr_TE1);

    assign is_repeatbranch_generating_packets_TE0[i] = (curr_pkt_TE0[i] inside {INDIRECTBRANCHHIST, INDIRECTBRANCHHISTSYNC, RESOURCEFULL}) & packet_pipe_vld_TE0[i];
    assign inbrhist_pkt_repeat_matches_TE0[i] = inbrhist_hist_repeat_TE0[i] & inbrhist_icnt_repeat_TE0[i] & inbrhist_uaddr_repeat_TE0[i] & ((curr_pkt_TE0[i] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[i] & ~((ibh_btype_reported_TE0[i] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | context_switch_IBH_reported_TE0)) & ~(trIBHS_trig_psync_ANY) & ~trStop_iCount_Hist_to_report_TE0 & ~(isErrorClear_ANY & ~isBTHBOverflow_TE0) & (trStartStop_ANY | trStop_ANY | trStop_ANY_d1) & ~isErrorPacketPushed_ANY;
  end

  assign inbrhist_pkt_interpipe_repeat_matches_TE0 = (next_inbrhist_hist_TE0[0] == next_inbrhist_hist_TE0[1]) & (next_inbrhist_icnt_TE0[0] == next_inbrhist_icnt_TE0[1]) & (next_inbrhist_uaddr_TE0[0] == next_inbrhist_uaddr_TE0[1]) & ((curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[1] & ~(context_switch_IBH_reported_TE0) & ~(ibh_btype_reported_TE0[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ((curr_pkt_TE0[0] == INDIRECTBRANCHHIST) & packet_pipe_vld_TE0[0] & ~(ibh_btype_reported_TE0[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)})) & ~(trIBHS_trig_psync_ANY) & ~trStop_iCount_Hist_to_report_TE0 & ~isErrorClear_ANY & (trStartStop_ANY | trStop_ANY | trStop_ANY_d1) & ~isErrorPacketPushed_ANY;

  assign inbrhist_pkt_repeat_TE0 = (inbrhist_pkt_repeat_matches_TE0[0]?inbrhist_pkt_repeat_matches_TE0:NUM_BLOCKS'('b0)) | {inbrhist_pkt_interpipe_repeat_matches_TE0, 1'b0};
  assign inbrhist_pkt_repeat_reset_TE0 = (|(is_repeatbranch_generating_packets_TE0 & ~inbrhist_pkt_repeat_TE0) | bcnt_overflow_TE0) & ((bcnt_TE1!=0) | (bcnt_TE1_overflowed & |next_bcnt_TE0) | ((&is_repeatbranch_generating_packets_TE0) & (inbrhist_pkt_repeat_TE0[0] & ~inbrhist_pkt_repeat_TE0[1])));

  assign inbrhist_pkt_repeat_clr_TE0 = (isResourceFull_Packet_TE0 | (|is_hist_overflow_TE0) | trStop_iCount_Hist_to_report_TE0 | ((ibh_btype_reported_TE0[1] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | (ibh_btype_reported_TE0[0] inside {BTYPE_WIDTH'('h2), BTYPE_WIDTH'('h3)}) | context_switch_IBH_reported_TE0));
  assign bcnt_to_report_TE0 = bcnt_overflow_TE0?{BCNT_WIDTH{1'b1}}:next_bcnt_TE0;
  assign bcnt_overflow_TE0 = |is_bcnt_overflow_cond_hit_TE0;

  always_comb begin
    next_bcnt_TE0 = bcnt_TE1;
    is_bcnt_overflow_cond_hit_TE0 = {NUM_BLOCKS{1'b0}};
    for (int i=0; i<NUM_BLOCKS; i++) begin
      next_bcnt_TE0 = $bits(next_bcnt_TE0)'(next_bcnt_TE0 + BCNT_WIDTH'(inbrhist_pkt_repeat_TE0[i]));
      is_bcnt_overflow_cond_hit_TE0[i] = &next_bcnt_TE0 & ~|i;
      next_bcnt_TE0 = is_bcnt_overflow_cond_hit_TE0[i]?$bits(next_bcnt_TE0)'(1'b0):next_bcnt_TE0;
    end
  end

  assign inbrhist_ibh_pkt_clr_after_bcnt_overflow = (|is_repeatbranch_generating_packets_TE0 & ~inbrhist_pkt_interpipe_repeat_matches_TE0) & ~bcnt_overflow_TE0;
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) bcnt_TE1_overflowed_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (bcnt_overflow_TE0 & rb_packet_pipe_vld_TE0),
      .clr   (isErrorClear_ANY | (|next_bcnt_TE0) | inbrhist_ibh_pkt_clr_after_bcnt_overflow),
      .in    (1'b1),
      .out   (bcnt_TE1_overflowed)
  );

  /* verilator lint_off WIDTH */
  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  always_comb begin
    unique case (rb_hrepeat_pkt_TE0)
      REPEATBRANCH: begin
        rb_mso_data_in_TE0[0] = MSO_DATA_IN_WIDTH'({bcnt_to_report_TE0,(Trtecontrol.Trteinhibitsrc?REPEATBRANCH:{Trteinstfeatures.Trtesrcid[3:0],REPEATBRANCH})});
        rb_mso_data_in_len_TE0[0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(bcnt_len_TE0) + ($clog2(MSO_DATA_IN_WIDTH)+1)'(Trtecontrol.Trteinhibitsrc? 'h6 :'ha);
        rb_mso_data_is_var_TE0[0] = '1;
        rb_mso_data_is_last_TE0[0] = ~trtsenable;

        rb_mso_data_in_TE0[1] = trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0);
        rb_mso_data_in_len_TE0[1] = trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
        rb_mso_data_is_var_TE0[1] = trtsenable?'1:'0;
        rb_mso_data_is_last_TE0[1] = trtsenable?'1:'0;

        rb_mso_data_in_TE0[2] = MSO_DATA_IN_WIDTH'(0);
        rb_mso_data_in_len_TE0[2] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(0);
        rb_mso_data_is_var_TE0[2] = '0;
        rb_mso_data_is_last_TE0[2] = '0;
      end

      RESOURCEFULL: begin

        rb_mso_data_in_TE0[0] = MSO_DATA_IN_WIDTH'({hrepeat_pattern_TE0,4'h2,(Trtecontrol.Trteinhibitsrc?RESOURCEFULL:{Trteinstfeatures.Trtesrcid[3:0],RESOURCEFULL})});
        rb_mso_data_in_len_TE0[0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(hrepeat_pattern_len_TE0) + ($clog2(MSO_DATA_IN_WIDTH)+1)'((Trtecontrol.Trteinhibitsrc)? 'ha : 'he);
        rb_mso_data_is_var_TE0[0] = '1;
        rb_mso_data_is_last_TE0[0] = '0;

        rb_mso_data_in_TE0[1] = MSO_DATA_IN_WIDTH'(hrepeat_counter_to_report_TE0);
        rb_mso_data_in_len_TE0[1] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(hrepeat_counter_len_TE0);
        rb_mso_data_is_var_TE0[1] = '1;
        rb_mso_data_is_last_TE0[1] = ~(trtsenable);

        rb_mso_data_in_TE0[2] = trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0);
        rb_mso_data_in_len_TE0[2] = trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0);
        rb_mso_data_is_var_TE0[2] = trtsenable;
        rb_mso_data_is_last_TE0[2] = trtsenable;
      end

      default: begin
        rb_mso_data_in_TE0 = '0;
        rb_mso_data_in_len_TE0 = '0;
        rb_mso_data_is_var_TE0 = '0;
        rb_mso_data_is_last_TE0 = '0;
      end
    endcase
  end
  /* verilator lint_on WIDTH */
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */

  assign rb_packet_pipe_vld_TE0 = ((inbrhist_pkt_repeat_clr_TE0 & (bcnt_TE1!=0)) | inbrhist_pkt_repeat_reset_TE0) & ~(isErrorGeneration_TE0 & ~isBTHBOverflow_TE0);

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) rb_packet_pipe_vld_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (rb_packet_pipe_vld_TE0),
      .out   (rb_packet_pipe_vld_TE1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) hrepeat_pkt_vld_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (hrepeat_pkt_vld_TE0),
      .out   (hrepeat_pkt_vld_TE1)
  );

  for (genvar j=0; j<3; j++) begin : gen_rb_mso_data_in_TE1_ff
      generic_dff #(
          .WIDTH       ($bits(logic [MSO_DATA_IN_WIDTH-1:0])),
          .RESET_VALUE ('0)
      ) rb_mso_data_in_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0),
          .in    (rb_mso_data_in_TE0[j]),
          .out   (rb_mso_data_in_TE1[j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic [$clog2(MSO_DATA_IN_WIDTH)+1-1:0])),
          .RESET_VALUE ('0)
      ) rb_mso_data_in_len_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0),
          .in    (rb_mso_data_in_len_TE0[j]),
          .out   (rb_mso_data_in_len_TE1[j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) rb_mso_data_is_var_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0),
          .in    (rb_mso_data_is_var_TE0[j]),
          .out   (rb_mso_data_is_var_TE1[j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) rb_mso_data_is_last_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (rb_packet_pipe_vld_TE0 | hrepeat_pkt_vld_TE0),
          .in    (rb_mso_data_is_last_TE0[j]),
          .out   (rb_mso_data_is_last_TE1[j])
      );

      te_mso #(
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

  assign rb_pkt_buffer_data_TE1.pkt_data_len = ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(rb_mso_data_out_len_in_bytes_TE1[0] + rb_mso_data_out_len_in_bytes_TE1[1] + rb_mso_data_out_len_in_bytes_TE1[2]);

  assign rb_pkt_buffer_data_TE1.pkt_data_be = (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((rb_mso_data_out_be_TE1[2])) << (rb_mso_data_out_len_in_bytes_TE1[0] + rb_mso_data_out_len_in_bytes_TE1[1]))
                                            | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES'((rb_mso_data_out_be_TE1[1])) << (rb_mso_data_out_len_in_bytes_TE1[0]))
                                            | NTRACE_MAX_PACKET_WIDTH_IN_BYTES'(rb_mso_data_out_be_TE1[0]);
  assign rb_pkt_buffer_data_TE1.pkt_data = ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(rb_mso_data_out_TE1[2]) << ((rb_mso_data_out_len_in_bytes_TE1[0] + rb_mso_data_out_len_in_bytes_TE1[1]) * 'h8))
                                          | ((NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(rb_mso_data_out_TE1[1]) << (rb_mso_data_out_len_in_bytes_TE1[0] * 'h8))
                                          | (NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8)'(rb_mso_data_out_TE1[0]);

  assign own_vdm_packet_pipe_vld_TE0[0] = (((context_switch_report_pend & (curr_pkt_TE0[0] == INDIRECTBRANCHHIST)) | (curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC)) & packet_pipe_vld_TE0[0]);
  assign own_vdm_packet_pipe_vld_TE0[1] = ((curr_pkt_TE0[1] == INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[1]) | ((context_switch_report_pend & (curr_pkt_TE0[1] == INDIRECTBRANCHHIST) & (curr_pkt_TE0[0] == PROGTRACESYNC)) & (&packet_pipe_vld_TE0));
  assign own_vdm_packet_pipe_is_vdm_vld_TE0 = is_tval_to_report_pend & ~((curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[0] & ~(pend_btype_to_report_delay inside {2'h2, 2'h3}));

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign own_vdm_mso_data_in_TE0[0][0] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,(Trtecontrol.Trteinhibitsrc?OWNERSHIP:{Trteinstfeatures.Trtesrcid[3:0],OWNERSHIP})});
  assign own_vdm_mso_data_in_len_TE0[0][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(process_context_len_TE0 + (Trtecontrol.Trteinhibitsrc? 6'h6 : 6'ha));
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */
  assign own_vdm_mso_data_is_var_TE0[0][0] = '1;
  assign own_vdm_mso_data_is_last_TE0[0][0] = (own_vdm_packet_pipe_is_vdm_vld_TE0?'1:(trtsenable?'0:'1));

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign own_vdm_mso_data_in_TE0[0][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'({2'b00, (Trtecontrol.Trteinhibitsrc?VENDORDEFINED:{Trteinstfeatures.Trtesrcid[3:0],VENDORDEFINED})}):(trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0));
  assign own_vdm_mso_data_in_len_TE0[0][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(Trtecontrol.Trteinhibitsrc?4'h8 :4'hc)):(trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0));
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */
  assign own_vdm_mso_data_is_var_TE0[0][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[0][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(tval_to_report_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(tval_to_report_len_TE0)):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[0][2] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[0][2] = ~(own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);

  assign own_vdm_mso_data_in_TE0[0][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable)?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[0][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable)?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[0][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);
  assign own_vdm_mso_data_is_last_TE0[0][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign own_vdm_mso_data_in_TE0[1][0] = MSO_DATA_IN_WIDTH'({context_to_report_TE0,(Trtecontrol.Trteinhibitsrc?OWNERSHIP:{Trteinstfeatures.Trtesrcid[3:0],OWNERSHIP})});
  assign own_vdm_mso_data_in_len_TE0[1][0] = ($clog2(MSO_DATA_IN_WIDTH)+1)'(process_context_len_TE0 + (Trtecontrol.Trteinhibitsrc? 6'h6 : 6'ha));
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */
  assign own_vdm_mso_data_is_var_TE0[1][0] = '1;
  assign own_vdm_mso_data_is_last_TE0[1][0] = own_vdm_packet_pipe_is_vdm_vld_TE0?'1:trtsenable?'0:'1;

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign own_vdm_mso_data_in_TE0[1][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'({2'b00, (Trtecontrol.Trteinhibitsrc?VENDORDEFINED:{Trteinstfeatures.Trtesrcid[3:0],VENDORDEFINED})}):(trtsenable?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'(0));
  assign own_vdm_mso_data_in_len_TE0[1][1] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(Trtecontrol.Trteinhibitsrc?4'h8 :4'hc)):(trtsenable?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'(0));
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */
  assign own_vdm_mso_data_is_var_TE0[1][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[1][1] = ~own_vdm_packet_pipe_is_vdm_vld_TE0;

  assign own_vdm_mso_data_in_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?MSO_DATA_IN_WIDTH'(tval_to_report_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0?(($clog2(MSO_DATA_IN_WIDTH)+1)'(tval_to_report_len_TE0)):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[1][2] = own_vdm_packet_pipe_is_vdm_vld_TE0;
  assign own_vdm_mso_data_is_last_TE0[1][2] = ~(own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);

  assign own_vdm_mso_data_in_TE0[1][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable)?MSO_DATA_IN_WIDTH'(rel_tstamp_TE0):MSO_DATA_IN_WIDTH'('b0);
  assign own_vdm_mso_data_in_len_TE0[1][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable)?($clog2(MSO_DATA_IN_WIDTH)+1)'(rel_tstamp_len_TE0):($clog2(MSO_DATA_IN_WIDTH)+1)'('0);
  assign own_vdm_mso_data_is_var_TE0[1][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);
  assign own_vdm_mso_data_is_last_TE0[1][3] = (own_vdm_packet_pipe_is_vdm_vld_TE0 & trtsenable);

  generic_dff #(
      .WIDTH       ($bits(logic [NUM_BLOCKS-1:0])),
      .RESET_VALUE ('0)
  ) own_vdm_packet_pipe_vld_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (own_vdm_packet_pipe_vld_TE0),
      .out   (own_vdm_packet_pipe_vld_TE1)
  );

  for (genvar i=0; i<NUM_BLOCKS; i++) begin : gen_blocks_own_vdm_mso_data_in_TE1_ff
    for (genvar j=0; j<4; j++) begin : gen_own_vdm_mso_data_TE1_ff

      generic_dff #(
          .WIDTH       ($bits(logic [MSO_DATA_IN_WIDTH-1:0])),
          .RESET_VALUE ('0)
      ) own_vdm_mso_data_in_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (own_vdm_packet_pipe_vld_TE0[i]),
          .in    (own_vdm_mso_data_in_TE0[i][j]),
          .out   (own_vdm_mso_data_in_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic [$clog2(MSO_DATA_IN_WIDTH)+1-1:0])),
          .RESET_VALUE ('0)
      ) own_vdm_mso_data_in_len_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (own_vdm_packet_pipe_vld_TE0[i]),
          .in    (own_vdm_mso_data_in_len_TE0[i][j]),
          .out   (own_vdm_mso_data_in_len_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) own_vdm_mso_data_is_var_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (own_vdm_packet_pipe_vld_TE0[i]),
          .in    (own_vdm_mso_data_is_var_TE0[i][j]),
          .out   (own_vdm_mso_data_is_var_TE1[i][j])
      );
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) own_vdm_mso_data_is_last_TE1_ff (
          .clk   (clock),
          .rst_n (i_reset_n),
          .en    (own_vdm_packet_pipe_vld_TE0[i]),
          .in    (own_vdm_mso_data_is_last_TE0[i][j]),
          .out   (own_vdm_mso_data_is_last_TE1[i][j])
      );

      te_mso #(
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

  generic_fifoMN #(
    .ALLOW_CLEAR  (0),
    .DATA_WIDTH   ($bits(pkt_buffer_t)),
    .ENTRIES      (PKT_FIFO_CNT),
    .NUM_WR       (5),
    .NUM_RD       (1)) pkt_buffer (

      .o_cnt            (pkt_fifo_cnt_TE2),
      .o_data           ({pkt_data_out_be,pkt_len_in_bytes,pkt_data_out}),
      .o_broadside_data ( ),
      .o_rdptr          ( ),
      .o_wrptr          ( ),

      .i_data           (pkt_fifo_wr_data_TE1),
      .i_psh            (pkt_fifo_push_TE1 & {5{~isErrorPacketPushed_ANY}}),
      .i_pop            (requested_packet_space_granted & |pkt_fifo_cnt_TE2),
      .i_clear          ({PKT_FIFO_CNT{1'b0}}),
      .i_clk            (clock),
      .i_reset_n        (i_reset_n)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isEncoderBufferOverflowflop_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (pkt_fifo_cnt_TE2 >= 4),
      .clr   (pkt_fifo_cnt_TE2 < 2),
      .in    (1'b1),
      .out   (isEncoderBufferOverflowflop_ANY)
  );
  assign isEncoderBufferOverflow_ANY = isEncoderBufferOverflowflop_ANY;

  assign isErrorPacketPushed_TE1 = (curr_pkt_TE1[0] == ERROR) & packet_pipe_vld_TE1[0] & (pkt_fifo_cnt_TE2 <= (PKT_FIFO_CNT-1));

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isErrorPacketPushed_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (isErrorPacketPushed_TE1),
      .clr   (pkt_fifo_cnt_TE2 < 2),
      .in    (1'b1),
      .out   (isErrorPacketPushed_ANY)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isErrorPacketPushed_d1_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (isErrorPacketPushed_ANY),
      .out   (isErrorPacketPushed_d1_ANY)
  );

  assign isErrorClear_ANY = (isEncoderBufferOverflow_ANY | isBTHBOverflow_TE0) & trStartStop_ANY;

  assign trTeResyncAfterEncOverflowError_ANY = (~isErrorPacketPushed_ANY & isErrorPacketPushed_d1_ANY);
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTeResyncAfterBTHBOverflowError_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ((~isErrorPacketPushed_ANY & isErrorPacketPushed_d1_ANY) | (isBTHBOverflow_TE0 & trStartStop_ANY)),
      .clr   ((curr_pkt_TE0[0] inside {PROGTRACESYNC, PROGTRACECORRELATION}) & packet_pipe_vld_TE0[0]),
      .in    (1'b1),
      .out   (trTeResyncAfterBTHBOverflowError_ANY)
  );

  assign trTeResyncAfterError_ANY = trTeResyncAfterEncOverflowError_ANY | trTeResyncAfterBTHBOverflowError_ANY;

  assign trBackpressure_ANY = isEncoderBufferOverflow_ANY & Trtecontrol.Trteinststallena;
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) MS_MC_trBackpressure_ANY_stg_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trBackpressure_ANY),
      .out   (MS_MC_trBackpressure_ANY)
  );

  assign request_packet_space_in_bytes = (flush_mode_enable & ~ flush_mode_exit)?(($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'('h4)):{($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1){|pkt_fifo_cnt_TE2}} & ($clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES)+1)'(pkt_len_in_bytes);

  generic_dff #(
      .WIDTH       ($bits(logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0])),
      .RESET_VALUE ('0)
  ) pktzr_data_in_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (request_packet_space_in_bytes!=0 & requested_packet_space_granted),
      .in    ((flush_mode_enable & ~ flush_mode_exit)?(256'hffffffff):pkt_data_out),
      .out   (data_in)
  );
  generic_dff #(
      .WIDTH       ($bits(logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0])),
      .RESET_VALUE ('0)
  ) pktzr_data_in_be_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (request_packet_space_in_bytes!=0 & requested_packet_space_granted),
      .in    ((flush_mode_enable & ~ flush_mode_exit)?(32'hf):pkt_data_out_be),
      .out   (data_byte_be_in)
  );

  assign trPrivisDebug_TE0 = ((trEncPriv_TE0 == PRIVMODE_DEBUG) | (~trTeTraceInPatchEnable_ANY & (trEncPriv_TE0 == PRIVMODE_PATCH)));
  assign trPrivFiltered_TE0 = (trPrivModeFilterEnable_ANY?(trEncPriv_TE0 == trPrivModeFilterChoice_ANY):1'b1);

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trPrivisDebug_TE1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trPrivisDebug_TE0),
      .out   (trPrivisDebug_TE1)
  );

  assign trPrivDebugModeEntry_ANY = trPrivisDebug_TE0 & ~trPrivisDebug_TE1;
  assign trPrivDebugModeExit_ANY = ~trPrivisDebug_TE0 & trPrivisDebug_TE1;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trPrivDebugEntry_PTC_pending_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trPrivDebugModeEntry_ANY & trTracingInProgress_ANY),
      .clr   (trPrivDebugModeExit_ANY | ~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACECORRELATION) & packet_pipe_vld_TE0[0])),
      .in    (1'b1),
      .out   (trPrivDebugEntry_PTC_pending_ANY)
  );
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trSwControlStop_PTC_pending_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trSwControlStop_ANY & trTracingInProgress_ANY),
      .clr   (~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACECORRELATION) & packet_pipe_vld_TE0[0])),
      .in    (1'b1),
      .out   (trSwControlStop_PTC_pending_ANY)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTeReStartAfterDebugMode_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trPrivDebugModeExit_ANY & trTeInsttracing_Enable_ANY),
      .clr   (~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACESYNC) & packet_pipe_vld_TE0[0] & ~trTeResyncAfterError_ANY)),
      .in    (1'b1),
      .out   (trTeReStartAfterDebugMode_ANY)
  );

  assign MS_MC_trActive_ANY = trTeActive_ANY;
  assign MS_MC_trStallModeEn_ANY = Trtecontrol.Trteinststallena;

  assign trTeActive_ANY = Trtecontrol.Trteactive;
  assign trTeSwEnable_ANY = trTeActive_ANY & Trtecontrol.Trteenable;
  assign trTeEnable_ANY = trTeSwEnable_ANY & ~trace_hardware_stop & ~(trace_hw_flush_in_progress);
  assign trTeInsttracing_Enable_ANY = trTeEnable_ANY & Trtecontrol.Trteinsttracing;

  assign trBthbStartStop_ANY = trTeSwEnable_ANY;

  assign trStartStop_ANY = trTeInsttracing_Enable_ANY & trPrivFiltered_TE0 & ~trPrivisDebug_TE0;

  assign trStart_ANY = trStartStop_ANY & ~trStartStop_ANY_d1;
  assign trStop_ANY = ~trStartStop_ANY & trStartStop_ANY_d1;

  assign trSwControlStop_ANY_m1 = ~trTeInsttracing_Enable_ANY & trTeInsttracing_Enable_ANY_d1;

  assign trTeTrigEnable_ANY = Trtecontrol.Trteinsttriggerenable;
  assign trStartfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_ON);
  assign trStopfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_OFF);
  assign trNotifyfromTrig_ANY = trTeTrigEnable_ANY & (MC_MS_trTrigControl_ANY == TRIG_TRACE_NOTIFY);

  assign trNotifySyncfromTrig_ANY = (trPulsefromCLA_ANY | trNotifyfromTrig_ANY) & trTracingInProgress_ANY & ~trStop_ANY;

  assign trTeTraceInPatchEnable_ANY = Trteimpl.Trtetracepatchenable;

  assign trTeCLATrigEnable_ANY = Trteimpl.Trteclatriggerenable;
  assign trStartfromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_start_ANY;
  assign trStopfromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_stop_ANY;
  assign trPulsefromCLA_ANY = trTeCLATrigEnable_ANY & cla_trigger_trace_pulse_ANY;

  always_comb begin
    TrtecontrolWr = '0;
    TrtecontrolWr.TrteinststalloroverflowWrEn = isErrorGeneration_TE0 | (trTeInsttracing_Enable_ANY & ~trTeInsttracing_Enable_ANY_d1) | (trTeActive_ANY & ~trTeActive_ANY_d1);
    TrtecontrolWr.Data.Trteinststalloroverflow = isErrorGeneration_TE0?1'b1:1'b0;
    TrtecontrolWr.TrteinsttracingWrEn = trTeActive_ANY & ((trTeEnable_ANY & (trStartfromTrig_ANY | trStopfromTrig_ANY)) | (trace_hardware_stop & ~trace_hardware_stop_d1 & Trtecontrol.Trteenable) | (trTeEnable_ANY & (trStartfromCLA_ANY | trStopfromCLA_ANY)));
    TrtecontrolWr.Data.Trteinsttracing = ((trace_hardware_stop & ~trace_hardware_stop_d1) | trStopfromCLA_ANY)?1'b0:((trStartfromTrig_ANY | trStartfromCLA_ANY) | ~(trStopfromTrig_ANY | trStopfromCLA_ANY));
    TrtecontrolWr.TrteemptyWrEn = 1'b1;
    TrtecontrolWr.Data.Trteempty = packetizer_empty & (pkt_fifo_cnt_TE2 == '0);
  end

  assign trPrivModeFilterEnable_ANY = Trteinstfilters.Trteinstfilters[0] & Trtefilter0Control.Trtefilterenable & Trtefilter0Control.Trtefiltermatchprivilege;
  assign trPrivModeFilterChoice_ANY = PrivMode_e'(Trtefilter0Matchinst.Trtefiltermatchchoiceprivilege);

  assign trNotifyIBHS_ANY = trTracingInProgress_ANY & trNotifySyncfromTrig_ANY;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trNotifyIBHS_ANY_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trTracingInProgress_ANY & trNotifyIBHS_ANY),
      .clr   (~trNotifyIBHS_ANY & (trStart_ANY | ((curr_pkt_TE1[0]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE1[0]) | ((curr_pkt_TE1[1]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE1[1]))),
      .in    (1'b1),
      .out   (trNotifyIBHS_ANY_delay)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trIBHS_trig_psync_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (periodic_sync_count_overflow | trNotifyIBHS_ANY),
      .clr   (trStart_ANY |((curr_pkt_TE0[0]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[0]) | ((curr_pkt_TE0[1]==INDIRECTBRANCHHISTSYNC) & packet_pipe_vld_TE0[1])),
      .in    (1'b1),
      .out   (trIBHS_trig_psync_ANY)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trIBHS_trig_psync_ANY_delay_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trIBHS_trig_psync_ANY),
      .out   (trIBHS_trig_psync_ANY_delay)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trStop_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trStop_ANY),
      .out   (trStop_ANY_d1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trStartStop_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trStartStop_ANY),
      .out   (trStartStop_ANY_d1)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trBthbStartStop_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trBthbStartStop_ANY),
      .out   (trBthbStartStop_ANY_d1)
  );
  assign MS_MC_trStartStop_ANY = trBthbStartStop_ANY_d1;

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTeActive_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trTeActive_ANY),
      .out   (trTeActive_ANY_d1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTeEnable_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trTeEnable_ANY),
      .out   (trTeEnable_ANY_d1)
  );
  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trTeInsttracing_Enable_ANY_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trTeInsttracing_Enable_ANY),
      .out   (trTeInsttracing_Enable_ANY_d1)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trSwControlStop_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trSwControlStop_ANY_m1),
      .out   (trSwControlStop_ANY)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trProgressed_after_DebugEntry_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (Trtecontrol.Trteactive & (trTeInsttracing_Enable_ANY | trTeInsttracing_Enable_ANY_d1) & (trTracingInProgress_ANY) & (trPrivDebugModeEntry_ANY | trPrivDebugEntry_PTC_pending_ANY)),
      .clr   ((trSwControlStop_ANY & ~trPrivDebugModeEntry_ANY) | ((curr_pkt_TE0[0] == PROGTRACESYNC) & packet_pipe_vld_TE0[0])),
      .in    (1'b1),
      .out   (trProgressed_after_DebugEntry_ANY)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trReEnable_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .clr   (~trTeActive_ANY | ((curr_pkt_TE0[0]==PROGTRACESYNC) & packet_pipe_vld_TE0[0] & ~trTeResyncAfterError_ANY)),
      .in    ((~trTeInsttracing_Enable_ANY & trTeInsttracing_Enable_ANY_d1) | trReEnable_ANY),
      .out   (trReEnable_ANY)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trFlush_ANY_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (~trTeEnable_ANY & trTeEnable_ANY_d1),
      .clr   (~|pkt_fifo_cnt_TE2 & flush_mode_exit & flush_mode_enable),
      .in    (1'b1),
      .out   (trFlush_ANY)
  );

  assign trPacketizer_Flushmode_enable_ANY = trFlush_ANY & (pkt_fifo_cnt_TE2 == '0) & (curr_pkt_TE0[0] != PROGTRACECORRELATION) & ~|pkt_fifo_push_TE1;
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) flush_mode_enable_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trPacketizer_Flushmode_enable_ANY),
      .clr   (flush_mode_enable & flush_mode_exit),
      .in    (1'b1),
      .out   (flush_mode_enable)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_flush_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_hardware_flush),
      .out   (trace_hardware_flush_d1)
  );
  assign trace_hardware_flush_pulse = ~trace_hardware_flush_d1 & trace_hardware_flush;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hw_flush_in_progress_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (trace_hardware_flush_pulse & trTeEnable_ANY),
      .clr   (~trTracingInProgress_ANY & ~|pkt_fifo_push_TE1 & ~|pkt_fifo_cnt_TE2 & ~flush_mode_enable & flush_mode_exit & packetizer_empty),
      .in    (1'b1),
      .out   (trace_hw_flush_in_progress)
  );

  generic_dff #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_hardware_stop_d1_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (trace_hardware_stop),
      .out   (trace_hardware_stop_d1)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) trace_stop_after_error_wo_sync_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (isErrorPacketPushed_ANY & isProgTraceSync_Pending & ~isProgTraceSync_Pending_clr),
      .clr   ((curr_pkt_TE0[0] inside {PROGTRACESYNC, PROGTRACECORRELATION}) & packet_pipe_vld_TE0[0]),
      .in    (1'b1),
      .out   (trace_stop_after_error_wo_sync)
  );

  generic_dff #(
      .WIDTH       ($bits(logic [$bits(InstSyncMode)-1:0])),
      .RESET_VALUE ('0)
  ) inst_sync_mode_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    (InstSyncMode_e'(Trtecontrol.Trtesyncmode)),
      .out   ({InstSyncMode})
  );
  generic_dff #(
      .WIDTH       ($bits(logic [PERIODIC_SYNC_COUNT_WIDTH + 1-1:0])),
      .RESET_VALUE ('0)
  ) periodic_sync_max_count_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .in    ((PERIODIC_SYNC_COUNT_WIDTH+1)'({1 << (Trtecontrol.Trtesyncmax + 4)})),
      .out   (periodic_sync_max_count)
  );

  assign periodic_sync_count_clr = trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0) | trStop_ANY | isErrorClear_ANY | trTeResyncAfterError_ANY;

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) periodic_sync_count_overflow_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (periodic_sync_count_overflow_stg),
      .clr   (periodic_sync_count_clr),
      .in    (1'b1),
      .out   (periodic_sync_count_overflow)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic [PERIODIC_SYNC_COUNT_WIDTH-1:0])),
      .RESET_VALUE ('0)
  ) periodic_sync_count_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    (InstSyncMode != SYNC_OFF),
      .clr   (periodic_sync_count_clr),
      .in    (next_periodic_sync_count),
      .out   (periodic_sync_count)
  );
  always_comb begin
    periodic_sync_pkt_count = periodic_sync_count + (PERIODIC_SYNC_COUNT_WIDTH+1)'(|pkt_buffer_data_vld_TE2) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(&pkt_buffer_data_vld_TE2) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(trStart_ANY) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(trTeResyncAfterError_ANY) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(rb_packet_pipe_vld_TE1) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(context_switch_TE1) + (PERIODIC_SYNC_COUNT_WIDTH+1)'(is_tval_to_report_TE1);
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

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isProgTraceSync_Pending_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .clr   ((isProgTraceSync_Pending_clr | trStop_ANY) & ~isErrorGeneration_TE0),
      .in    (trStart_ANY | isErrorGeneration_TE0 | isProgTraceSync_Pending),
      .out   (isProgTraceSync_Pending)
  );
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isProgTraceCorrelation_Pending_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .clr   (isProgTraceCorrelation_Pending_clr | trStart_ANY),
      .in    (isProgTraceCorrelation_Pending | (trStop_ANY & ~(packet_pipe_vld_TE0[0] & (curr_pkt_TE0[0] == PROGTRACECORRELATION)))),
      .out   (isProgTraceCorrelation_Pending)
  );
  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isIndirectBranchHist_Pending_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .clr   ((isIndirectBranchHist_Pending_clr | isIndirectBranchHistSync_Pending_clr | trIBHS_trig_psync_ANY) & ~((is_hist_to_report_TE0[0] & isAddrPending_TE0[0]) | is_hist_to_report_TE0[1] | aux_ibh_packet_tgt_pending_TE0)),
      .in    (isIndirectBranchHist_Pending | (is_hist_to_report_TE0[0] & (~trIBHS_trig_psync_ANY | isAddrPending_TE0[0])) | is_hist_to_report_TE0[1] | aux_ibh_packet_tgt_pending_TE0),
      .out   (isIndirectBranchHist_Pending)
  );

  generic_dff_clr #(
      .WIDTH       ($bits(logic)),
      .RESET_VALUE ('0)
  ) isIndirectBranchHistSync_Pending_TE0_ff (
      .clk   (clock),
      .rst_n (i_reset_n),
      .en    ('1),
      .clr   (isIndirectBranchHistSync_Pending_clr | trStart_ANY),
      .in    ((isIndirectBranchHistSync_Pending | trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0) | (rel_tstamp_overflow_TE1 & ~isIndirectBranchHistSync_Pending_clr)) & ~trSwControlStop_ANY),
      .out   (isIndirectBranchHistSync_Pending)
  );

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

  always_comb begin

    curr_pkt_TE0[0] = PKT_UNKNOWN;
    curr_pkt_TE0[1] = PKT_UNKNOWN;
    packet_pipe_vld_ibh_TE0 = 'b0;

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

      if ((trSwControlStop_ANY & ( (~trTracingInProgress_ANY & trProgressed_after_DebugEntry_ANY))) | (trTracingInProgress_ANY & (isProgTraceCorrelation_Pending | trStop_iCount_Hist_to_report_TE0)) ) begin
        curr_pkt_TE0[0] = PROGTRACECORRELATION;
        use_pend_addr[0] = isProgTraceCorrelation_Pending;
        packet_pipe_vld_TE0[0] = 1'b1;
      end

      if (isResourceFull_Packet_TE0) begin
        if (|is_hist_overflow_to_report_TE0 & |is_iCount_overflow_TE0) begin
          curr_pkt_TE0[0] = RESOURCEFULL;

          if (is_hist_overflow_to_report_TE0 == is_iCount_overflow_TE0) begin
            rsfull_msg_icnt_or_hist_TE0[0] = 1'b0;
            rsfull_msg_icnt_or_hist_TE0[1] = 1'b1;
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
        if (isProgTraceSync_Pending | isProgTraceCorrelation_Pending | isResourceFull_Packet_TE0) begin

          if (trTracingInProgress_ANY & |isAddrPending_delay & (pend_addr_available | trStop_iCount_Hist_to_report_TE0)) begin
            curr_pkt_TE0[1] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | seq_icnt_overflow_delay | rel_tstamp_overflow_TE1)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            addrBlock[1] = 1'b0;
            dataBlock[1] = 1'b0;
            use_pend_addr[1] = 1'b1;
            use_pend_btype[1] = 1'b1;
            use_flopped_tgt_addr[1] = trStop_iCount_Hist_to_report_TE0;

            packet_pipe_vld_TE0[1] = 1'b1;
            context_switch_IBH_reported_TE0 = context_switch_report_pend?1'b1:1'b0;

          end
          else begin
            if ((is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0]) | aux_ibh_packet_pipe_vld_TE0) begin
              curr_pkt_TE0[1] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | rel_tstamp_overflow_TE1)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
              dataBlock[1] = 1'b0;
              addrBlock[1] = 1'b1;
              packet_pipe_vld_TE0[1] = 1'b1;
            end
          end
        end

        else begin

          if (trTracingInProgress_ANY & |isAddrPending_delay & (pend_addr_available | trStop_iCount_Hist_to_report_TE0)) begin
            curr_pkt_TE0[0] = (trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | seq_icnt_overflow_delay | rel_tstamp_overflow_TE1)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            addrBlock[0] = 1'b0;
            dataBlock[0] = 1'b0;
            use_pend_addr[0] = 1'b1;
            use_pend_btype[0] = 1'b1;
            use_flopped_tgt_addr[0] = trStop_iCount_Hist_to_report_TE0;
            packet_pipe_vld_TE0[0] = 1'b1;

            context_switch_IBH_reported_TE0 = context_switch_report_pend?1'b1:1'b0;

            if (is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0]) begin
              curr_pkt_TE0[1] = ((trIBHS_trig_psync_ANY | isIndirectBranchHistSync_Pending | rel_tstamp_overflow_TE1) & ~(curr_pkt_TE0[0] == INDIRECTBRANCHHISTSYNC))?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
              dataBlock[1] = 1'b0;
              addrBlock[1] = 1'b1;
              packet_pipe_vld_TE0[1] = 1'b1;
            end
          end
          else if (|(seq_icnt_overflow_TE0 & ~is_sic_AddrPending_TE0) | (is_hist_to_report_TE0[0] & ~isAddrPending_TE0[0])) begin
            curr_pkt_TE0[0] = (trIBHS_trig_psync_ANY | (|seq_icnt_overflow_TE0) | isIndirectBranchHistSync_Pending | rel_tstamp_overflow_TE1)?INDIRECTBRANCHHISTSYNC:INDIRECTBRANCHHIST;
            dataBlock[0] = seq_icnt_overflow_TE0[1]?1'b1:1'b0;
            addrBlock[0] = 1'b1;
            packet_pipe_vld_TE0[0] = 1'b1;

            curr_pkt_TE0[1] = aux_ibh_packet_pipe_vld_TE0?INDIRECTBRANCHHIST:PKT_UNKNOWN;
            packet_pipe_vld_TE0[1] = aux_ibh_packet_pipe_vld_TE0;
          end
        end
      end
    end

    for (int i=0; i<NUM_BLOCKS; i++) begin
      packet_pipe_vld_ibh_TE0[i] = (packet_pipe_vld_TE0[i] & ~inbrhist_pkt_repeat_TE0[i]) ?1'b1:1'b0;
    end
  end

  always_comb begin
    rb_hrepeat_pkt_TE0 = PKT_UNKNOWN;

    if (hrepeat_pkt_vld_TE0) begin
      rb_hrepeat_pkt_TE0 = RESOURCEFULL;
    end else if (rb_packet_pipe_vld_TE0) begin
      rb_hrepeat_pkt_TE0 = REPEATBRANCH;
    end
  end

endmodule
