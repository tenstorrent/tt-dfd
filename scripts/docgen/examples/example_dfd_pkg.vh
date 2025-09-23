// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

package example_dfd_pkg;

localparam L0_DBG_LANE_WIDTH = 16;
localparam L0_DBG_NUM_INPUT_LANES = 8;

localparam L1_DBG_LANE_WIDTH = 16;
localparam L1_DBG_NUM_INPUT_LANES = 9;
localparam FINE_GRAIN_TSTAMP_COUNTER_WIDTH = 8;

typedef struct packed {
  logic   [L0_DBG_LANE_WIDTH-1:0] data;
} hw_t;

endpackage
