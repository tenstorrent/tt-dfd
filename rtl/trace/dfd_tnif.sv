// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

 // Trace Network Interface - Block that connects the Packet source to the Trace Network

module dfd_tnif import dfd_tn_pkg::*; # (
    parameter DATA_PORTS = 2,                                         //Numer of data ports
    parameter DATA_WIDTH_IN_BYTES = TNIF_DATA_OUT_WIDTH_IN_BYTES      //Width of the data
)
(   
    input   logic                                                    clock,
    input   logic                                                    reset_n,

    //Interface to the functional blocks
    input   logic                                                    dst_req_in,
    input   logic                                                    ntr_req_in,
    input   logic [DATA_WIDTH_IN_BYTES*8-1:0]                        dst_data_in,
    input   logic [DATA_WIDTH_IN_BYTES*8-1:0]                        ntr_data_in,
    
    output  logic                                                    dst_pull_out,
    output  logic                                                    ntr_pull_out,

    output  logic                                                    dst_flush_out,
    output  logic                                                    ntr_flush_out,
    output  logic                                                    dst_bp_out,
    output  logic                                                    ntr_bp_out,

    //Interface to the trace network
    input   logic                                                    tr_gnt_in,
    input   logic                                                    dst_bp_in,
    input   logic                                                    ntr_bp_in,
    input   logic                                                    dst_flush_in,
    input   logic                                                    ntr_flush_in,
    
    output  logic                                                    tr_valid_out,
    output  logic                                                    tr_src_out,
    output  logic [DATA_WIDTH_IN_BYTES*8-1:0]                        tr_data_out
);

    tnifState_e prev_gnt;
    
    assign dst_pull_out = tr_gnt_in & ~(dst_bp_in & ~dst_flush_in) & dst_req_in & ((ntr_req_in & ~(ntr_bp_in & ~ntr_flush_in))?(prev_gnt == tnifState_e'(DST_GNT)):1'b1);
    assign ntr_pull_out = tr_gnt_in & ~(ntr_bp_in & ~ntr_flush_in) & ntr_req_in & ((dst_req_in & ~(dst_bp_in & ~dst_flush_in))?(prev_gnt == tnifState_e'(NTR_GNT)):1'b1);

    // Prev grant tracking
    tt_dfd_generic_dff #(.WIDTH($bits(tnifState_e)), .RESET_VALUE(NTR_GNT)) prev_gnt_ff (.out({prev_gnt}), .in(~prev_gnt), .en(tr_gnt_in & (ntr_req_in & dst_req_in)), .clk(clock), .rst_n(reset_n)); 

    assign tr_data_out = {(DATA_WIDTH_IN_BYTES*8){1'b1}} & (dst_pull_out?dst_data_in:ntr_data_in); 
    assign tr_valid_out = dst_pull_out | ntr_pull_out;
    assign tr_src_out = (ntr_pull_out == 1'b1);

    assign dst_flush_out = dst_flush_in;
    assign ntr_flush_out = ntr_flush_in;
    assign dst_bp_out = dst_bp_in;
    assign ntr_bp_out = ntr_bp_in;
    
    `ASSERT_MACRO_ONE_HOT(PfxHitDeAllocMultiHotErrBP2, clock,reset_n,(dst_pull_out | ntr_pull_out) ,{dst_pull_out, ntr_pull_out}, "ERROR: TNIF data pull is not one_hot") 
endmodule

