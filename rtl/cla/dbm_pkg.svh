// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

`ifndef DBM_CSR_PKG_SVH
`define DBM_PKG_SVH

package dbm_pkg;

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

