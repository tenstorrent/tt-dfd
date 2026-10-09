// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module trace_mem
import tn_pkg::*;
# (
    parameter TSEL_CONFIGURABLE = 0,
    parameter TRC_RAM_INDEX_WIDTH = 9,
    type SinkMemPktIn_s = logic,
    type SinkMemPktOut_s = logic
) (

	input  SinkMemPktIn_s [TRC_RAM_INSTANCES-1:0]    funnel_mem_SinkMemPktIn_ANY,
	output SinkMemPktOut_s[TRC_RAM_INSTANCES-1:0]    mem_funnel_SinkMemPktOut_ANY,

    input  logic                                clk,
	input  logic                                reset_n,
    input  logic[10:0]						    i_mem_tsel_settings
);

trace_mem_sink #(
    .SinkMemPktIn_s(SinkMemPktIn_s),
    .SinkMemPktOut_s(SinkMemPktOut_s),
    .TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
    .TRC_RAM_INDEX_WIDTH(TRC_RAM_INDEX_WIDTH)
    ) sink_mem (
    .clk(clk),
    .reset_n(reset_n),
    .i_mem_tsel_settings(i_mem_tsel_settings),
    .MemPktIn(funnel_mem_SinkMemPktIn_ANY),
    .MemPktOut(mem_funnel_SinkMemPktOut_ANY)
);

endmodule
