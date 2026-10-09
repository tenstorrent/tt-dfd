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

module trace_mem_sink
import tn_pkg::*;
# (
	type SinkMemPktIn_s = logic,
	type SinkMemPktOut_s = logic,
	parameter TSEL_CONFIGURABLE = 0,
	parameter TRC_RAM_INDEX_WIDTH = 9
) (
	// Trace Sink Cells
	input  SinkMemPktIn_s [TRC_RAM_INSTANCES-1:0]    MemPktIn,
	output SinkMemPktOut_s[TRC_RAM_INSTANCES-1:0]    MemPktOut,

    input  logic                                clk,
	input  logic                                reset_n,
	input  logic[10:0]						    i_mem_tsel_settings
);

	for (genvar gc=0; gc<TRC_RAM_INSTANCES; gc++) begin: TrcSinkCells
		generic_mem_model #(
						.ADDR_WIDTH(TRC_RAM_INDEX_WIDTH),
						.DATA_WIDTH(TRC_RAM_DATA_WIDTH),
						.RW_PORTS(1)
		) TrcSinkRam (
		//Inputs
		.i_clk                   (clk),
		.i_reset_n               (reset_n),
		.i_mem_chip_en           (MemPktIn[gc].mem_chip_en),
		.i_mem_wr_en             (MemPktIn[gc].mem_wr_en),
		.i_mem_addr              (MemPktIn[gc].mem_wr_addr),
		.i_mem_wr_data           (MemPktIn[gc].mem_wr_data),
		.i_mem_wr_mask_en        (MemPktIn[gc].mem_wr_mask_en),

		.i_mem_rd_en             ('0),
		.i_mem_rd_addr           ('0),
		.i_mem_wr_gen            ('0),
		.i_mem_wr_addr           ('0),
		.i_mem_wr_data_all       ('0),
		.i_mem_wr_en_all         ('0),


		//Outputs

		.o_mem_rd_data           (MemPktOut[gc].mem_rd_data),
		.i_reg_mem_shut_down_mode  ('0),
		.i_reg_mem_deep_sleep_mode ('0),
		.i_reg_mem_diode_bypass_mode ('0),
		.i_mem_dft_bypass_enable  ('0),
		.i_mem_scan_enable         ('0),
		.i_mem_scan_in_left        ('0),
		.i_mem_scan_in_right       ('0),
		.i_reg_mem_faulty_io       ('0),
		.i_reg_mem_column_repair   ('0),
		.i_mem_tsel_settings       (i_mem_tsel_settings),
		.o_mem_scan_out_left       (),
		.o_mem_scan_out_right      (),
		.o_mem_pudelay_shut_down   (),
		.o_mem_pudelay_deep_sleep  ()
		);
	end

endmodule

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".h" ".v")
// verilog-typedef-regexp: "_[eus]$"
// End:
