// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`ifndef TN_PKG_SVH
`define TN_PKG_SVH

package tn_pkg;

  localparam TNIF_DATA_OUT_WIDTH_IN_BYTES = 16;

  localparam TRC_RAM_DATA_WIDTH = 64;
  localparam TRC_RAM_INSTANCES = 8 ;
  localparam TRC_RAM_WAYS = 4;

  typedef enum logic {
    NTR_GNT=0,
    DST_GNT=1
  } tnifState_e;

endpackage

`endif
