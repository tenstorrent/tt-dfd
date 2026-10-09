// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module dst_priority_mux #(parameter WIDTH = 8, parameter LEVELS = 4) (
  input logic [WIDTH-1:0] inputs [0:LEVELS-1],
  input logic [LEVELS-1:0] select,
  output logic [WIDTH-1:0] mux_out
);

  always_comb begin
    mux_out = {WIDTH{1'b0}};

    for (int i = 0; i < LEVELS; i++) begin
      if (select[(LEVELS-1)-i])
        mux_out = inputs[(LEVELS-1)-i];
    end
  end

endmodule
