// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

/*************************************************************************
 *
 *  Generic DFD memory model (simplified)
 *
 *  Compatible with the instantiation in dfd_trace_mem_sink_smc.sv:
 *   - Single RW port via i_mem_chip_en/i_mem_wr_en/i_mem_addr
 *   - Write masking via i_mem_wr_mask_en
 *   - Registered read (3-cycle) to o_mem_rd_data when not writing
 *   - All DFT/TSEL/scan outputs are tied off; other inputs ignored
 */

module generic_mem_model #(
    // Commonly used parameters in the sink
    parameter int ADDR_WIDTH = 9,
    parameter int DATA_WIDTH = 64,
    parameter int RW_PORTS = 1,
    parameter bit TSEL_CONFIGURABLE = 0,

    // Minimal set for type compatibility
    parameter int RO_PORTS = 0,
    parameter int WO_PORTS = 0,
    parameter int WRITE_MASK_GRANULARITY = DATA_WIDTH,
    parameter bit ONE_HOT_READ_ADDR = 0,
    parameter bit ONE_HOT_WRITE_ADDR = 0
) (
    // Clock and reset
    input logic i_clk,
    input logic i_reset_n,

    // RW ports (only index 0 used by the sink)
    input logic [(RW_PORTS != 0 ? RW_PORTS : 1) - 1 : 0]                 i_mem_chip_en,
    input logic [(RW_PORTS != 0 ? RW_PORTS : 1) - 1 : 0][ADDR_WIDTH-1:0] i_mem_addr,

    // RO ports (unused by the sink)
    input logic [(RO_PORTS != 0 ? RO_PORTS : 1) - 1 : 0] i_mem_rd_en,
    input logic [(RO_PORTS != 0 ? RO_PORTS : 1) - 1 : 0]
                  [ONE_HOT_READ_ADDR ? (1<<ADDR_WIDTH) : ADDR_WIDTH -1:0]  i_mem_rd_addr,

    // RW and WO write controls
    input logic [(RW_PORTS + WO_PORTS) - 1 : 0] i_mem_wr_gen,
    input logic [(RW_PORTS + WO_PORTS) - 1 : 0] i_mem_wr_en,
    input logic [(RW_PORTS + WO_PORTS) - 1 : 0]
                  [DATA_WIDTH/WRITE_MASK_GRANULARITY -1:0]                  i_mem_wr_mask_en,
    input logic [(RW_PORTS + WO_PORTS) - 1 : 0][DATA_WIDTH-1:0] i_mem_wr_data,
    input logic [(WO_PORTS != 0 ? WO_PORTS : 1) - 1 : 0]
                  [ONE_HOT_WRITE_ADDR ? (1<<ADDR_WIDTH) : ADDR_WIDTH -1:0]  i_mem_wr_addr,

    // Optional broadcast write (unused by the sink)
    input logic                  i_mem_wr_en_all,
    input logic [DATA_WIDTH-1:0] i_mem_wr_data_all,

    // Read data outputs
    output logic [(RW_PORTS + RO_PORTS) - 1 : 0][DATA_WIDTH-1:0] o_mem_rd_data,

    // DFT/TSEL/scan and misc (tied off or ignored)
    input logic i_reg_mem_shut_down_mode,
    input logic i_reg_mem_deep_sleep_mode,
    input logic i_reg_mem_diode_bypass_mode,
    input logic i_mem_dft_bypass_enable,
    input logic i_mem_scan_enable,
    input logic i_mem_scan_in_left,
    input logic i_mem_scan_in_right,
    input logic i_reg_mem_faulty_io,
    input logic i_reg_mem_column_repair,
    input logic [10:0] i_mem_tsel_settings,
    output logic o_mem_scan_out_left,
    output logic o_mem_scan_out_right,
    output logic o_mem_pudelay_shut_down,
    output logic o_mem_pudelay_deep_sleep
);

  // Derived widths
  localparam int NumRows = (1 << ADDR_WIDTH);
  localparam int Dw = DATA_WIDTH;
  localparam int Wmg = WRITE_MASK_GRANULARITY;
  localparam int Wmw = (Wmg == 0) ? 1 : (Dw / Wmg);
  localparam int Rwp = RW_PORTS;
  localparam int Rop = RO_PORTS;
  localparam int Rp = Rwp + Rop;

  // Storage
  logic [Dw-1:0] mem_data[NumRows];

  // Read data pipelines to realize 3-cycle read latency
  // RW ports pipeline (per port)
  localparam int RwpArr = (Rwp != 0 ? Rwp : 1);
  localparam int RopArr = (Rop != 0 ? Rop : 1);
  logic [RwpArr-1:0][Dw-1:0] rw_pipe0, rw_pipe1;
  logic [RwpArr-1:0] rw_valid0, rw_valid1;

  // RO ports pipeline (per port)
  logic [RopArr-1:0][Dw-1:0] ro_pipe0, ro_pipe1;
  logic [RopArr-1:0] ro_valid0, ro_valid1;

  // Tie-off unused outputs
  assign o_mem_scan_out_left      = 1'b0;
  assign o_mem_scan_out_right     = 1'b0;
  assign o_mem_pudelay_shut_down  = 1'b0;
  assign o_mem_pudelay_deep_sleep = 1'b0;

  logic [RopArr-1:0][ADDR_WIDTH-1:0] ra;

  always_comb begin
    for (int p = 0; p < Rop; p++) begin
      ra[p] = '0;
      for (int i = 0; i < (1 << ADDR_WIDTH); i++) begin
        if (i_mem_rd_addr[p][i]) begin
          ra[p] = ADDR_WIDTH'(i);  // Proper type cast to address width
        end
      end
    end
  end

  // Sequential write/read behavior; 3-cycle read latency
  always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
      for (int p = 0; p < Rp; p++) begin
        o_mem_rd_data[p] <= '0;
      end
      // Clear read pipelines and valids
      rw_pipe0  <= '{default: '0};
      rw_pipe1  <= '{default: '0};
      rw_valid0 <= '0;
      rw_valid1 <= '0;

      ro_pipe0  <= '{default: '0};
      ro_pipe1  <= '{default: '0};
      ro_valid0 <= '0;
      ro_valid1 <= '0;
    end else begin
      // Default: shift read pipelines each cycle
      rw_pipe1  <= rw_pipe0;
      rw_valid1 <= rw_valid0;
      rw_valid0 <= '0;  // will be set per-port when a new read is launched

      ro_pipe1  <= ro_pipe0;
      ro_valid1 <= ro_valid0;
      ro_valid0 <= '0;  // will be set per-port when a new read is launched

      // RW ports behavior
      for (int p = 0; p < Rwp; p++) begin
        if (i_mem_chip_en[p]) begin
          if (i_mem_wr_en[p]) begin
            for (int m = 0; m < Wmw; m++) begin
              if ((Wmw == 1) || i_mem_wr_mask_en[p][m]) begin
                mem_data[i_mem_addr[p]][m*Wmg+:Wmg] <= i_mem_wr_data[p][m*Wmg+:Wmg];
              end
            end
          end else begin
            /* verilator lint_off WIDTH */
            // Launch a read into the 3-stage pipeline
            rw_pipe0[p]  <= mem_data[i_mem_addr[p]];
            rw_valid0[p] <= 1'b1;
            /* verilator lint_on WIDTH */
          end
        end
        // Update output when pipeline matures (3 cycles after launch)
        if (rw_valid1[p]) begin
          o_mem_rd_data[p] <= rw_pipe1[p];
        end else begin
          o_mem_rd_data[p] <= o_mem_rd_data[p];
        end
      end

      // RO ports behavior (if ever used)
      for (int p = 0; p < Rop; p++) begin
        if (i_mem_rd_en[p]) begin
          if (ONE_HOT_READ_ADDR) begin
            // logic [ADDR_WIDTH-1:0] ra;
            // ra = '0;
            // for (int i = 0; i < (1 << ADDR_WIDTH); i++) begin
            //   if (i_mem_rd_addr[p][i]) begin
            //     ra = ADDR_WIDTH'(i); // Proper type cast to address width
            //   end
            // end
            // Use computed address to read memory
            ro_pipe0[p]  <= mem_data[ra[p]];
            ro_valid0[p] <= 1'b1;
          end else begin
            /* verilator lint_off WIDTH */
            ro_pipe0[p]  <= mem_data[i_mem_rd_addr[p]];
            ro_valid0[p] <= 1'b1;
            /* verilator lint_on WIDTH */
          end
        end
        // Update output when RO pipeline matures (3 cycles after launch)
        if (ro_valid1[p]) begin
          o_mem_rd_data[Rwp+p] <= ro_pipe1[p];
        end else begin
          o_mem_rd_data[Rwp+p] <= o_mem_rd_data[Rwp+p];
        end
      end
    end
  end

endmodule


