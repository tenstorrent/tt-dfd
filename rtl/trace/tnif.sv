`include "generic_macro_assertion.vh"
/*************************************************************************
 *
 * Tenstorrent CONFIDENTIAL
 *__________________
 *
 *  Tenstorrent Inc.
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Tenstorrent Inc.  The intellectual
 * and technical concepts contained
 * herein are proprietary to Tenstorrent Inc.
 * and may be covered by U.S., Canadian and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Tenstorrent Inc.
 */
 // Trace Network Interface - Block that connects the Packet source to the Trace Network

module tnif import tn_pkg::*; # (
    parameter DATA_PORTS = 2,                                         //Numer of data ports
    parameter DATA_WIDTH_IN_BYTES = TNIF_DATA_OUT_WIDTH_IN_BYTES      //Width of the data
)
(
    input   logic                                                    clock,
    input   logic                                                    i_reset_n,
    input   logic                                                    reset_n_warm_ovrride,

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
    tnifState_e next_gnt;

    assign dst_pull_out = tr_gnt_in & ~(dst_bp_in & ~dst_flush_in) & dst_req_in & ((ntr_req_in & ~(ntr_bp_in & ~ntr_flush_in))?(prev_gnt == tnifState_e'(DST_GNT)):1'b1);
    assign ntr_pull_out = tr_gnt_in & ~(ntr_bp_in & ~ntr_flush_in) & ntr_req_in & ((dst_req_in & ~(dst_bp_in & ~dst_flush_in))?(prev_gnt == tnifState_e'(NTR_GNT)):1'b1);

    // Prev grant tracking
    assign next_gnt = (prev_gnt inside {NTR_GNT}) ? DST_GNT : NTR_GNT;
    generic_dff #(
        .WIDTH       ($bits(tnifState_e)),
        .RESET_VALUE (NTR_GNT)
    ) prev_gnt_ff (
        .clk   (clock),
        .rst_n (i_reset_n),
        .en    (tr_gnt_in & (ntr_req_in & dst_req_in)),
        .in    (next_gnt),
        .out   (prev_gnt)
    );

    assign tr_data_out = {(DATA_WIDTH_IN_BYTES*8){1'b1}} & (dst_pull_out?dst_data_in:ntr_data_in);
    assign tr_valid_out = dst_pull_out | ntr_pull_out;
    assign tr_src_out = (ntr_pull_out == 1'b1);

    assign dst_flush_out = dst_flush_in;
    assign ntr_flush_out = ntr_flush_in;
    assign dst_bp_out = dst_bp_in;
    assign ntr_bp_out = ntr_bp_in;

    `ASSERT_MACRO_ONE_HOT(PfxHitDeAllocMultiHotErrBP2, clock,i_reset_n,(dst_pull_out | ntr_pull_out) ,{dst_pull_out, ntr_pull_out}, "ERROR: TNIF data pull is not one_hot")

endmodule
