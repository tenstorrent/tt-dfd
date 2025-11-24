// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_trace_mem_sink
  import dfd_tn_pkg::*;
#(
    type SinkMemPktIn_s = logic,
    type SinkMemPktOut_s = logic,
    parameter TSEL_CONFIGURABLE = 0,
    parameter TRC_RAM_INDEX_WIDTH = 9,
    parameter mem_gen_pkg::MemCell_e SINK_CELL = mem_gen_pkg::mem_cell_undefined // Unused for generic model, customer can modify as needed
) (
    // Trace Sink Cells
    input  SinkMemPktIn_s  [TRC_RAM_INSTANCES-1:0] MemPktIn,
    output SinkMemPktOut_s [TRC_RAM_INSTANCES-1:0] MemPktOut,

    input logic        clk,
    input logic        reset_n,
    input logic [10:0] i_mem_tsel_settings
);

  // 32KB = 8 instances of [512x64 macros] 
  // if(TRC_RAM_INDEX_WIDTH == 8) begin: UHD_SRAM_16KB // HACK for 16KB
  // 	for (genvar gc=0; gc<TRC_RAM_INSTANCES; gc++) begin: TrcSinkCells
  // 		tt_mem_wrapper_ln04lpp_s00_mc_rf1rw_uhdrw_lvt_256x64m2b1c1r2 TrcSinkRam (
  // 			.i_mem_clk(clk),
  // 			.i_mem_chip_enb(~MemPktIn[gc].mem_chip_en), // active low
  // 			.i_mem_wr_enb(~MemPktIn[gc].mem_wr_en), // active low
  // 			.i_mem_addr(MemPktIn[gc].mem_wr_addr),
  // 			.i_mem_wr_data(MemPktIn[gc].mem_wr_data),
  // 			.i_mem_wr_bit_enb({TRC_RAM_DATA_WIDTH{MemPktIn[gc].mem_wr_mask_en}}), // active low
  // 			.o_mem_rd_data(MemPktOut[gc].mem_rd_data),
  // 			.i_reg_mem_retention_enable('0), // active high
  // 			.i_mem_dft_bypass_enable('0), // active high
  // 			.i_mem_scan_enable('0), // active high
  // 			.i_mem_scan_in_left('0),
  // 			.i_mem_scan_in_right('0),
  // 			.o_mem_scan_out_left(),
  // 			.o_mem_scan_out_right(),
  // 			.i_reg_mem_col_repair_addr1('0),
  // 			.i_reg_mem_col_repair_en1('0),
  // 			.i_reg_mem_col_repair_addr2('0),
  // 			.i_reg_mem_col_repair_en2('0),
  // 			.i_reg_mem_row_repair_addr1('0),
  // 			.i_reg_mem_row_repair_en1('0),
  // 			.i_reg_mem_row_repair_addr2('0),
  // 			.i_reg_mem_row_repair_en2('0),
  // 			.i_mem_tsel_settings(i_mem_tsel_settings)
  // 		);
  // 	end 
  // end else begin: HS_SRAM
  for (genvar gc = 0; gc < TRC_RAM_INSTANCES; gc++) begin : TrcSinkCells
    tt_dfd_generic_mem_model #(
        .TSEL_CONFIGURABLE(TSEL_CONFIGURABLE),
        .ADDR_WIDTH(TRC_RAM_INDEX_WIDTH),
        .DATA_WIDTH(TRC_RAM_DATA_WIDTH),
        .RW_PORTS(1)
    ) TrcSinkRam (
        //Inputs
        .i_clk           (clk),
        .i_reset_n       (reset_n),
        .i_mem_chip_en   (MemPktIn[gc].mem_chip_en),
        .i_mem_wr_en     (MemPktIn[gc].mem_wr_en),
        .i_mem_addr      (MemPktIn[gc].mem_wr_addr),
        .i_mem_wr_data   (MemPktIn[gc].mem_wr_data),
        .i_mem_wr_mask_en(MemPktIn[gc].mem_wr_mask_en),

        .i_mem_rd_en            ('0),
        .i_reg_mem_faulty_io    ('0),
        .i_reg_mem_column_repair(1'b0),

        .i_mem_rd_addr('0),
        .i_mem_wr_gen('0),
        .i_mem_wr_addr('0),
        .i_mem_wr_data_all('0),
        .i_mem_wr_en_all('0),

        // Waiving off un-connected inputs for below DFT interfaces which are unused
        .i_reg_mem_shut_down_mode(),  //spyglass disable W287a
        .i_reg_mem_deep_sleep_mode(),  //spyglass disable W287a
        .i_reg_mem_diode_bypass_mode(),  //spyglass disable W287a
        .i_mem_dft_bypass_enable(),  //spyglass disable W287a
        .i_mem_scan_enable(),  //spyglass disable W287a
        .i_mem_scan_in_left(),  //spyglass disable W287a
        .i_mem_scan_in_right(),  //spyglass disable W287a
        .i_mem_tsel_settings(i_mem_tsel_settings),  //spyglass disable W287a

        //Outputs
        .o_mem_rd_data           (MemPktOut[gc].mem_rd_data),
        .o_mem_scan_out_left     (),
        .o_mem_scan_out_right    (),
        .o_mem_pudelay_shut_down (),
        .o_mem_pudelay_deep_sleep()
    );
  end
  // end

endmodule

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eus]$"
// End:

