

`ifndef DFD_TN_PKG_SVH
`define DFD_TN_PKG_SVH

package dfd_tn_pkg;

  localparam TNIF_DATA_OUT_WIDTH_IN_BYTES = 16;

  localparam TRC_RAM_DATA_WIDTH = 64;
  localparam TRC_RAM_INSTANCES = 8 ; // TRC_SIZE / (TRC_RAM_DATA_WIDTH * TRC_RAM_INDEX);
  localparam TRC_RAM_WAYS = 4;

  typedef enum logic {
    NTR_GNT=0, // 1'b0
    DST_GNT=1  // 1'b1
  } tnifState_e;

endpackage

`endif

