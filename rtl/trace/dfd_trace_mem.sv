/*************************************************************************
 *
 * Tenstorrent CONFIDENTIAL
 * __________________
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

module dfd_trace_mem
  import dfd_tn_pkg::*;
#(
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined,
    parameter TSEL_CONFIGURABLE = 0,
    parameter TRC_RAM_INDEX_WIDTH = 9,
    type SinkMemPktIn_s = logic,
    type SinkMemPktOut_s = logic
) (
    // Trace Sink Cells
    input  SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0] funnel_mem_SinkMemPktIn_ANY,
    output SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0] mem_funnel_SinkMemPktOut_ANY,

    input logic        clk,
    input logic        reset_n,
    input logic [10:0] i_mem_tsel_settings
);

  dfd_trace_mem_sink #(
      .SinkMemPktIn_s(SinkMemPktIn_s),
      .SinkMemPktOut_s(SinkMemPktOut_s),
      .TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
      .TRC_RAM_INDEX_WIDTH(TRC_RAM_INDEX_WIDTH),
      .SINK_CELL(SINK_CELL)
  ) sink_mem (
      .clk(clk),
      .reset_n(reset_n),
      .i_mem_tsel_settings(i_mem_tsel_settings),
      .MemPktIn(funnel_mem_SinkMemPktIn_ANY),
      .MemPktOut(mem_funnel_SinkMemPktOut_ANY)
  );


endmodule

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eus]$"
// End:

