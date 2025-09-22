// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module generic_fifoMN #(
    parameter integer DATA_WIDTH  = 4,
    parameter integer ENTRIES     = 8,
    parameter bit     ALLOW_CLEAR = 1,
    parameter bit     CLEAR_ALL   = ALLOW_CLEAR ? 1 : 0,                   //FE clears all
    parameter integer ADDR_SIZE   = (ENTRIES == 1) ? 1 : $clog2(ENTRIES),
    parameter integer NUM_WR      = 2,
    parameter integer NUM_RD      = 2
) (
    output logic [ADDR_SIZE:0]                 o_cnt,
    output logic [ NUM_RD-1:0][DATA_WIDTH-1:0] o_data,
    output logic [ENTRIES-1:0][DATA_WIDTH-1:0] o_broadside_data,  // Done
    output logic [ADDR_SIZE:0]                 o_rdptr,
    output logic [ADDR_SIZE:0]                 o_wrptr,

    input logic [NUM_WR-1:0][DATA_WIDTH-1:0] i_data,
    input logic [NUM_WR-1:0]                 i_psh,
    input logic [NUM_RD-1:0]                 i_pop,

    input logic [ENTRIES-1:0] i_clear,
    input logic               i_clk,
    input logic               i_reset_n
);

  logic [ADDR_SIZE:0] nxt_rd_ptr, rd_ptr;
  logic [ADDR_SIZE:0] nxt_wr_ptr, wr_ptr;
  logic [ENTRIES-1:0][DATA_WIDTH-1:0] nxt_mem, mem;
  logic [ENTRIES-1:0] wr_en;
  logic [NUM_WR-1:0] int_psh;
  logic [NUM_RD-1:0][DATA_WIDTH-1:0] data;
  logic [ADDR_SIZE:0] nxt_cnt, cnt;

  // Broadside data
  assign o_broadside_data = mem;

  // Count
  assign o_cnt = cnt;

  // Data & Wr/Rd pointers
  assign o_data = data;
  assign o_rdptr = rd_ptr;
  assign o_wrptr = wr_ptr;

  generic_dff #(
      .WIDTH(ADDR_SIZE + 1),
      .RESET_VALUE(0),
      .BYPASS(0)
  ) rd_ptr_ff (
      .clk(i_clk),
      .rst_n(i_reset_n),
      .en(1'b1),
      .in(nxt_rd_ptr),
      .out(rd_ptr)
  );

  generic_dff #(
      .WIDTH(ADDR_SIZE + 1),
      .RESET_VALUE(0),
      .BYPASS(0)
  ) wr_ptr_ff (
      .clk(i_clk),
      .rst_n(i_reset_n),
      .en(1'b1),
      .in(nxt_wr_ptr),
      .out(wr_ptr)
  );


  always @(posedge i_clk) begin
    if (|i_psh) begin
      mem <= nxt_mem;
    end
  end

  generic_dff #(
      .WIDTH(ADDR_SIZE + 1),
      .RESET_VALUE(0),
      .BYPASS(0)
  ) cnt_ff (
      .clk(i_clk),
      .rst_n(i_reset_n),
      .en(1'b1),
      .in(nxt_cnt),
      .out(cnt)
  );

  // Data
  always_comb begin
    for (int i = 0; i < NUM_RD; i++) begin
      data[i] = mem[ADDR_SIZE'(rd_ptr+i)];
    end
  end



  // RD/WR pointer logic
  always_comb begin
    nxt_rd_ptr = rd_ptr;
    nxt_wr_ptr = wr_ptr;
    nxt_cnt = cnt;
    nxt_mem = mem;


    // For Writes
    int_psh = '0;
    for (int i = 0; i < NUM_WR; i++) begin
      if (i_psh[i]) begin
        int_psh[i] = {(NUM_WR) {1'b1}} >> (NUM_WR - 1 - i);
        nxt_cnt = nxt_cnt + 4'd1;
      end
    end

    for (int i = 0; i < NUM_WR; i++) begin
      if (int_psh[i]) begin
        nxt_mem[ADDR_SIZE'(wr_ptr+i)] = i_data[i];
        nxt_wr_ptr = nxt_wr_ptr + 4'd1;
      end
    end

    if (ALLOW_CLEAR && (|i_clear)) begin
      nxt_wr_ptr = rd_ptr;
      nxt_cnt = '0;
    end else begin
      // For Reads
      for (int i = 0; i < NUM_RD; i++) begin
        if (i_pop[i]) begin
          nxt_rd_ptr = nxt_rd_ptr + 4'd1;
          nxt_cnt = nxt_cnt - 4'd1;
        end
      end
    end
  end

endmodule
