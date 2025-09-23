// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

`ifndef DFD_CLA_PKG_SVH
`define DFD_CLA_PKG_SVH

package dfd_cla_pkg;
parameter DEBUG_SIGNALS_WIDTH = 64;
parameter LOG2_DEBUG_SIGNALS_WIDTH = $clog2(DEBUG_SIGNALS_WIDTH);
parameter XTRIGGER_WIDTH      = 2;
parameter CLA_APB_REG_DATA_WIDTH  = 64; //Dont support any other value.
parameter CLA_APB_REG_ADDR_WIDTH  = 23;
parameter CLA_APB_PSTRB_WIDTH     = 2;  //Only suppport 32 bit upper and 32 bit lowe access.
parameter CLA_GPIO_WIDTH      = 2;
parameter CLA_REG_DATA_WIDTH  = 32;
parameter CLA_REG_ADDR_WIDTH  = 32;
parameter CLA_NUMBER_OF_EVENTS =64;
parameter CLA_EVENT_TYPE_MSB   =$clog2(CLA_NUMBER_OF_EVENTS)-1;
parameter CLA_NUMBER_OF_ACTIONS=64;
parameter CLA_ACTION_TYPE_MSB  =$clog2(CLA_NUMBER_OF_ACTIONS)-1;
parameter CLA_NUMBER_OF_NODES  =4;
parameter CLA_NUMBER_OF_EAPS_PER_NODE  =4;
parameter CLA_NODE_ID_MSB      =$clog2(CLA_NUMBER_OF_NODES)-1;
parameter CLA_NUMBER_OF_COUNTERS =4;
parameter CLA_COUNTER_WIDTH    = 31;
parameter LOWER_CLA_NUMBER_OF_MASK_MATCH_SET =2;
parameter UPPER_CLA_NUMBER_OF_MASK_MATCH_SET =2;
parameter CLA_NUMBER_OF_MASK_MATCH_SET = LOWER_CLA_NUMBER_OF_MASK_MATCH_SET + UPPER_CLA_NUMBER_OF_MASK_MATCH_SET;
parameter CLA_NUMBER_OF_EDGE_DETECT_SET=2;
parameter CLA_NUMBER_OF_ACTIONS_PER_COUNTER = 4;
parameter CLA_NUMBER_OF_CUSTOM_ACTIONS = 16;

//Action Signal Positions
parameter ACTION_NULL                         = 0;  
parameter ACTION_CLOCK_HALT                   = 1;  
parameter ACTION_DEBUG_INTERRUPT              = 2;
parameter ACTION_TOOGLE_GPIO                  = 3;
parameter ACTION_START_TRACE                  = 4;
parameter ACTION_STOP_TRACE                   = 5;
parameter ACTION_TRACE_PLUSE                  = 6;
parameter ACTION_XTRIGGER0_OUT                = 7;
parameter ACTION_XTRIGGER1_OUT                = 8;
parameter ACTION_BASE_COUNTER_INCREMENT_PULSE      = 16;
parameter ACTION_BASE_COUNTER_CLEAR_CTR            = 17;
parameter ACTION_BASE_COUNTER_AUTO_INCREMENT       = 18;
parameter ACTION_BASE_COUNTER_STOP_AUTO_INCREMENT  = 19;

//Event Positions
parameter NUMBER_OF_EVENTS_PER_COUNTER = 3;
parameter NUMBER_OF_EVENTS_PER_MASK_MATCH = 2;
parameter LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS= 2; 
parameter DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS      = LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+(LOWER_CLA_NUMBER_OF_MASK_MATCH_SET*NUMBER_OF_EVENTS_PER_MASK_MATCH);
parameter DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS = DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS+CLA_NUMBER_OF_EDGE_DETECT_SET;
parameter XTRIGGER_EVTBUS_POS                       = DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS+1;
parameter DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS       = XTRIGGER_EVTBUS_POS + 2;
parameter DEBUG_SIGNALS_CHANGE_EVTBUS_POS           = DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS + 1;
parameter COUNTER_CONDITIONS_FIRST_EVTBUS_POS       = 16;
parameter UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS= COUNTER_CONDITIONS_FIRST_EVTBUS_POS + (NUMBER_OF_EVENTS_PER_COUNTER *CLA_NUMBER_OF_COUNTERS);

typedef struct packed {
  logic increment_pulse;
  logic clear_ctr;
  logic auto_increment;
  logic stop_auto_increment;  
} counter_controls;

typedef struct packed {
  logic [XTRIGGER_WIDTH-1:0] xtrigger;
  logic                      clock_halt;
} cla_network_pkt_s;

typedef dfd_cla_csr_pkg::CrCdbgclacounter0CfgCsr_s       ClacounterCfgCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgclacounter0CfgCsrWr_s     ClacounterCfgCsrWr_s;
typedef dfd_cla_csr_pkg::CrCdbgsignalmatch0Csr_s         DebugsignalmatchCsr_s ; 
typedef dfd_cla_csr_pkg::CrCdbgsignalmask0Csr_s          DebugsignalmaskCsr_s ; 
typedef dfd_cla_csr_pkg::CrCdbgsignaledgedetectcfgCsr_s  DebugsignaledgedetectcfgCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgnode0Eap0Csr_s            NodeEapCsr_s;
// typedef dfd_cla_csr_pkg::CrCdbgmuxselCsr_s               DbmDebugbusmuxCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgtransitionmaskCsr_s       DebugsignalTransitionmaskCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgtransitionfromvalueCsr_s  DebugsignalTransitionfromCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgtransitiontovalueCsr_s    DebugsignalTransitiontoCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgonescountmaskCsr_s        DebugsignalOnescountmaskCsr_s;
typedef dfd_cla_csr_pkg::CrCdbgonescountvalueCsr_s       DebugsignalOnescountvalueCsr_s;
typedef dfd_cla_csr_pkg::CrCdbganychangeCsr_s            DebugsignalchangeCsr_s;

endpackage

`endif

