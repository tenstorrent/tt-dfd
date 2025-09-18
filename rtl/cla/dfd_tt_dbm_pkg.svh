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

`ifndef DFD_TT_DBM_PKG_SVH
`define DFD_TT_DBM_PKG_SVH

package dfd_tt_dbm_pkg;

typedef struct packed {
    logic    [5:0]        Muxselseg7 ;
    logic    [5:0]        Muxselseg6 ;
    logic    [5:0]        Muxselseg5 ;
    logic    [5:0]        Muxselseg4 ;
    logic    [5:0]        Muxselseg3 ;
    logic    [5:0]        Muxselseg2 ;
    logic    [5:0]        Muxselseg1 ;
    logic    [5:0]        Muxselseg0 ;
    logic    [7:0]        Rsvd158 ;
    logic    [5:0]        DbmId;
    logic    [1:0]        DbmMode;    
} DbgMuxSelCsr_s;

typedef struct packed {
    logic    [7:0]        Muxselset7 ;
    logic    [7:0]        Muxselset6 ;
    logic    [7:0]        Muxselset5 ;
    logic    [7:0]        Muxselset4 ;
    logic    [7:0]        Muxselset3 ;
    logic    [7:0]        Muxselset2 ;
    logic    [7:0]        Muxselset1 ;
    logic    [7:0]        Muxselset0 ;
} DbmMuxControl_s;

typedef struct packed {
    logic    [5:0]        DbmId;
    logic    [1:0]        DbmMode;    
} DbmMuxIdMode_s;

//typedef logic [LANE_WIDTH-1:0][NUMBER_OF_INPUT_LANES] HwSignalsFromBlock;

endpackage

`endif


