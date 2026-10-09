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

module cla_arithmetic_compare #(
    parameter DEBUG_SIGNAL_WIDTH = 64
)
(
    input logic clock,
    input logic reset_n,
    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_compare,
    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signal_mask,
    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals,
    output logic below_compare,
    output logic above_compare,
    output logic below_compare_match,
    output logic above_compare_match
);

    logic [DEBUG_SIGNAL_WIDTH-1:0] debug_signals_masked;
    logic compare_equal, below_compare_int;

    always_comb begin
        debug_signals_masked = ((debug_signals & debug_signal_mask));
        compare_equal = (debug_signals_masked == debug_signal_compare);
        below_compare_int = (debug_signals_masked < debug_signal_compare);
    end

    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_below_compare (
        .clk   (clock),
        .rst_n (reset_n),
        .en    ('1),
        .in    (below_compare_int),
        .out   (below_compare)
    );

    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_below_compare_match (
        .clk   (clock),
        .rst_n (reset_n),
        .en    ('1),
        .in    (below_compare_int | compare_equal),
        .out   (below_compare_match)
    );

    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_above_compare (
        .clk   (clock),
        .rst_n (reset_n),
        .en    ('1),
        .in    (~below_compare_int & ~compare_equal),
        .out   (above_compare)
    );

    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_above_compare_match (
        .clk   (clock),
        .rst_n (reset_n),
        .en    ('1),
        .in    (~below_compare_int | compare_equal),
        .out   (above_compare_match)
    );

endmodule
