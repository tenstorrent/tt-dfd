// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

// Generic clock gating cell that infers a technology-specific clock gate during synthesis
module generic_clkgate (
    input logic clk,    // Input clock
    input logic en,     // Enable signal
    input logic te,     // Test enable
    output logic clk_out // Gated clock output
);

  logic latched_en;


  /* verilator lint_off LATCH */
  always_latch begin
    if (~clk) latched_en = en || te;
  end
  /* verilator lint_off LATCH */
  assign clk_out = clk & latched_en;

endmodule
