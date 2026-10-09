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

`ifndef CLA_PKG_SVH
`define CLA_PKG_SVH

package cla_pkg;
import cla_mmr_pkg::*;

parameter CLA_MMR_WIDTH       = 64;
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
parameter LFSR_WIDTH = 63;
parameter CLA_NUMBER_OF_ARITHMETIC_COMPARE = 4;

//Action Signal Positions
parameter ACTION_NULL                         = 0;
parameter ACTION_CLOCK_HALT                   = 1;
parameter ACTION_DEBUG_INTERRUPT              = 2;
parameter ACTION_TOGGLE_GPIO                   = 3;
parameter ACTION_START_TRACE                  = 4;
parameter ACTION_STOP_TRACE                   = 5;
parameter ACTION_TRACE_PULSE                   = 6;
parameter ACTION_XTRIGGER0_OUT                = 7;
parameter ACTION_XTRIGGER1_OUT                = 8;
parameter ACTION_BASE_COUNTER_INCREMENT_PULSE      = 16;
parameter ACTION_BASE_COUNTER_CLEAR_CTR            = 17;
parameter ACTION_BASE_COUNTER_AUTO_INCREMENT       = 18;
parameter ACTION_BASE_COUNTER_STOP_AUTO_INCREMENT  = 19;

//Event Positions
parameter NUMBER_OF_EVENTS_PER_COUNTER = 3;
parameter NUMBER_OF_EVENTS_PER_MASK_MATCH = 2;
parameter NUMBER_OF_EVENTS_PER_ARITHMETIC_COMPARE = 4;
parameter LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS= 2;
parameter DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS      = LOWER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS+(LOWER_CLA_NUMBER_OF_MASK_MATCH_SET*NUMBER_OF_EVENTS_PER_MASK_MATCH);
parameter DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS = DEBUG_SIGNALS_EDGE_DETECT_EVTBUS_POS+CLA_NUMBER_OF_EDGE_DETECT_SET;
parameter XTRIGGER_EVTBUS_POS                       = DEBUG_SIGNALS_TRANSITION_MATCH_EVTBUS_POS+1;
parameter DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS       = XTRIGGER_EVTBUS_POS + 2;
parameter DEBUG_SIGNALS_CHANGE_EVTBUS_POS           = DEBUG_SIGNALS_ONES_COUNT_EVTBUS_POS + 1;
parameter CLA_EXT_POSEDGE_EVTBUS_POS                = DEBUG_SIGNALS_CHANGE_EVTBUS_POS + 1;
parameter COUNTER_CONDITIONS_FIRST_EVTBUS_POS       = 16;
parameter UPPER_DEBUG_SIGNALS_MATCH_EVENT_EVTBUS_POS= COUNTER_CONDITIONS_FIRST_EVTBUS_POS + (NUMBER_OF_EVENTS_PER_COUNTER *CLA_NUMBER_OF_COUNTERS);
parameter LFSR_EVTBUS_POS                           = 32;
parameter ARITHMETIC_COMPARE_FIRST_EVTBUS_POS       = LFSR_EVTBUS_POS + 1;

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

typedef struct packed {
    ClaCdbgclacounter0CfgMmrWr_s Cdbgclacounter0CfgWr;
    ClaCdbgclacounter1CfgMmrWr_s Cdbgclacounter1CfgWr;
    ClaCdbgclacounter2CfgMmrWr_s Cdbgclacounter2CfgWr;
    ClaCdbgclacounter3CfgMmrWr_s Cdbgclacounter3CfgWr;
    ClaCdbgeapstatusMmrWr_s CdbgeapstatusWr;
    ClaCdbgclactrlstatusMmrWr_s CdbgclactrlstatusWr;
    ClaCdbgsignalsnapshotnode0Eap0LoMmrWr_s Cdbgsignalsnapshotnode0Eap0LoWr;
    ClaCdbgsignalsnapshotnode0Eap1LoMmrWr_s Cdbgsignalsnapshotnode0Eap1LoWr;
    ClaCdbgsignalsnapshotnode1Eap0LoMmrWr_s Cdbgsignalsnapshotnode1Eap0LoWr;
    ClaCdbgsignalsnapshotnode1Eap1LoMmrWr_s Cdbgsignalsnapshotnode1Eap1LoWr;
    ClaCdbgsignalsnapshotnode2Eap0LoMmrWr_s Cdbgsignalsnapshotnode2Eap0LoWr;
    ClaCdbgsignalsnapshotnode2Eap1LoMmrWr_s Cdbgsignalsnapshotnode2Eap1LoWr;
    ClaCdbgsignalsnapshotnode3Eap0LoMmrWr_s Cdbgsignalsnapshotnode3Eap0LoWr;
    ClaCdbgsignalsnapshotnode3Eap1LoMmrWr_s Cdbgsignalsnapshotnode3Eap1LoWr;
    ClaCdbgsignalsnapshotnode0Eap2LoMmrWr_s Cdbgsignalsnapshotnode0Eap2LoWr;
    ClaCdbgsignalsnapshotnode0Eap3LoMmrWr_s Cdbgsignalsnapshotnode0Eap3LoWr;
    ClaCdbgsignalsnapshotnode1Eap2LoMmrWr_s Cdbgsignalsnapshotnode1Eap2LoWr;
    ClaCdbgsignalsnapshotnode1Eap3LoMmrWr_s Cdbgsignalsnapshotnode1Eap3LoWr;
    ClaCdbgsignalsnapshotnode2Eap2LoMmrWr_s Cdbgsignalsnapshotnode2Eap2LoWr;
    ClaCdbgsignalsnapshotnode2Eap3LoMmrWr_s Cdbgsignalsnapshotnode2Eap3LoWr;
    ClaCdbgsignalsnapshotnode3Eap2LoMmrWr_s Cdbgsignalsnapshotnode3Eap2LoWr;
    ClaCdbgsignalsnapshotnode3Eap3LoMmrWr_s Cdbgsignalsnapshotnode3Eap3LoWr;
    ClaCdbgclatimestampMmrWr_s CdbgclatimestampWr;
    ClaCdbgclatimestampconfigMmrWr_s CdbgclatimestampconfigWr;
    ClaCdbgsignalsnapshotnode0Eap0HiMmrWr_s Cdbgsignalsnapshotnode0Eap0HiWr;
    ClaCdbgsignalsnapshotnode0Eap1HiMmrWr_s Cdbgsignalsnapshotnode0Eap1HiWr;
    ClaCdbgsignalsnapshotnode1Eap0HiMmrWr_s Cdbgsignalsnapshotnode1Eap0HiWr;
    ClaCdbgsignalsnapshotnode1Eap1HiMmrWr_s Cdbgsignalsnapshotnode1Eap1HiWr;
    ClaCdbgsignalsnapshotnode2Eap0HiMmrWr_s Cdbgsignalsnapshotnode2Eap0HiWr;
    ClaCdbgsignalsnapshotnode2Eap1HiMmrWr_s Cdbgsignalsnapshotnode2Eap1HiWr;
    ClaCdbgsignalsnapshotnode3Eap0HiMmrWr_s Cdbgsignalsnapshotnode3Eap0HiWr;
    ClaCdbgsignalsnapshotnode3Eap1HiMmrWr_s Cdbgsignalsnapshotnode3Eap1HiWr;
    ClaCdbgsignalsnapshotnode0Eap2HiMmrWr_s Cdbgsignalsnapshotnode0Eap2HiWr;
    ClaCdbgsignalsnapshotnode0Eap3HiMmrWr_s Cdbgsignalsnapshotnode0Eap3HiWr;
    ClaCdbgsignalsnapshotnode1Eap2HiMmrWr_s Cdbgsignalsnapshotnode1Eap2HiWr;
    ClaCdbgsignalsnapshotnode1Eap3HiMmrWr_s Cdbgsignalsnapshotnode1Eap3HiWr;
    ClaCdbgsignalsnapshotnode2Eap2HiMmrWr_s Cdbgsignalsnapshotnode2Eap2HiWr;
    ClaCdbgsignalsnapshotnode2Eap3HiMmrWr_s Cdbgsignalsnapshotnode2Eap3HiWr;
    ClaCdbgsignalsnapshotnode3Eap2HiMmrWr_s Cdbgsignalsnapshotnode3Eap2HiWr;
    ClaCdbgsignalsnapshotnode3Eap3HiMmrWr_s Cdbgsignalsnapshotnode3Eap3HiWr;
    ClaCdbglfsrMmrWr_s    CdbglfsrWr;
    ClaCdbgtimestampcaptureMmrWr_s CdbgtimestampcaptureWr;
} ClaMmrsWrMinimal_s;

typedef cla_mmr_pkg::ClaCdbgsignalmask0LoMmr_s            DebugsignalMaskLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgsignalmask0HiMmr_s            DebugsignalMaskHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgsignalmatch0LoMmr_s           DebugsignalMatchLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgsignalmatch0HiMmr_s           DebugsignalMatchHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitionmaskloMmr_s         DebugsignalTransitionmaskLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitionmaskhiMmr_s         DebugsignalTransitionmaskHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitionfromvalueloMmr_s    DebugsignalTransitionfromLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitionfromvaluehiMmr_s    DebugsignalTransitionfromHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitiontovalueloMmr_s      DebugsignalTransitiontoLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgtransitiontovaluehiMmr_s      DebugsignalTransitiontoHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgonescountmaskloMmr_s          DebugsignalOnescountmaskLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgonescountmaskhiMmr_s          DebugsignalOnescountmaskHiMmr_s;
typedef cla_mmr_pkg::ClaCdbganychangeloMmr_s              DebugsignalChangeLoMmr_s;
typedef cla_mmr_pkg::ClaCdbganychangehiMmr_s              DebugsignalChangeHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgsignalsnapshotnode0Eap0LoMmr_s DebugsignalSnapshotLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgsignalsnapshotnode0Eap0HiMmr_s DebugsignalSnapshotHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgcompare0LoMmr_s                 DebugsignalCompareLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgcompare0MaskloMmr_s             DebugsignalCompareMaskLoMmr_s;
typedef cla_mmr_pkg::ClaCdbgcompare0HiMmr_s                 DebugsignalCompareHiMmr_s;
typedef cla_mmr_pkg::ClaCdbgcompare0MaskhiMmr_s             DebugsignalCompareMaskHiMmr_s;


typedef cla_mmr_pkg::ClaCdbgclacounter0CfgMmr_s       ClacounterCfgMmr_s;
typedef cla_mmr_pkg::ClaCdbgclacounter0CfgMmrWr_s     ClacounterCfgMmrWr_s;
typedef cla_mmr_pkg::ClaCdbgsignaledgedetectcfgMmr_s  DebugsignalEdgedetectcfgMmr_s;
typedef cla_mmr_pkg::ClaCdbgnode0Eap0Mmr_s            NodeEapMmr_s;
typedef cla_mmr_pkg::ClaCdbgonescountvalueMmr_s       DebugsignalOnescountvalueMmr_s;

endpackage

`endif
