// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// *************************************************************************
//
// dfd_compat_pkg — legacy-interface compatibility package.
//
// Re-creates the parameters and types that the legacy (pre-autowrap) DFD tops
// in rtl/gen_files/ imported from packages that no longer exist in this repo:
//
//   dfd_pkg         : DFD_APB_* widths, DEBUG_SIGNALS_WIDTH, MAX_NUM_TRACE_INST
//   dfd_CL_axi_pkg  : dfd_slv_axi_req_t/rsp_t, dfd_tr_slv_axi_req_t/rsp_t
//   dfd_te_pkg      : NUM_BLOCKS, I*_WIDTH, PrivMode_e, TrigTraceControl_e, ...
//   dfd_dst_pkg     : timestamp_s
//   dfd_cla_pkg     : XTRIGGER_WIDTH, CLA_NUMBER_OF_CUSTOM_ACTIONS
//
// Values are chosen to match the legacy design so that legacy port
// declarations compile verbatim in the compatibility wrappers.
//
// Provenance of the reconstructed values:
//   * DFD_APB_{ADDR,DATA,PSTRB}_WIDTH = 23/32/4 — documented in
//     param_comparison.csv / diff_report.md, corroborated by the 23'h9000
//     per-instance APB stride in the legacy tops.
//   * DEBUG_SIGNALS_WIDTH = 64 — the legacy debug bus is 64 bits, i.e. the
//     legacy DBM is a 16:4 mux of 16-bit lanes (hw0..hw15 are the *mux
//     inputs*, not the bus itself).
//   * AXI struct field names/order — reconstructed from the DV testbench
//     re-bundling in dv/dfd/tb/dfd_trc_axi_pkg.sv + dv/dfd/tb/dfd_uvm_tb.sv,
//     the only surviving evidence of dfd_CL_axi_pkg. NOTE: the legacy AXI ID
//     width was 10; it is 4 here to match the current trace AXI master port.
//
// Enums/structs that still exist in the current packages are aliased rather
// than redefined, so a legacy-facing port and the new top port are the same
// type (no struct-shape drift).

`ifndef DFD_COMPAT_PKG_SVH
`define DFD_COMPAT_PKG_SVH

package dfd_compat_pkg;

  // ----------------------------------------------------------------------
  // legacy dfd_pkg scalars
  // ----------------------------------------------------------------------
  parameter int unsigned DFD_APB_ADDR_WIDTH  = 23;
  parameter int unsigned DFD_APB_DATA_WIDTH  = 32;
  parameter int unsigned DFD_APB_PSTRB_WIDTH = DFD_APB_DATA_WIDTH / 8;
  parameter int unsigned DEBUG_SIGNALS_WIDTH = 64;
  parameter int unsigned MAX_NUM_TRACE_INST  = 8;

  // Legacy debug-bus mux geometry: 16 input lanes of 16 bits feeding a 64-bit
  // (4 x 16-bit output lane) debug bus, i.e. a 16:4 DBM.
  parameter int unsigned LEGACY_HW_BUS_WIDTH = 16;
  parameter int unsigned LEGACY_NUM_HW_BUSES = 16;

  // ----------------------------------------------------------------------
  // legacy dfd_te_pkg / dfd_dst_pkg / dfd_cla_pkg names (aliases)
  // ----------------------------------------------------------------------
  parameter int unsigned NUM_BLOCKS    = te_pkg::TE_NUM_BLOCKS;
  parameter int unsigned IRETIRE_WIDTH = 5;
  parameter int unsigned ITYPE_WIDTH   = te_pkg::TE_ITYPE_WIDTH;
  parameter int unsigned PC_WIDTH      = te_pkg::TE_PC_WIDTH;
  parameter int unsigned TSTAMP_WIDTH  = te_pkg::TE_TSTAMP_WIDTH;
  parameter int unsigned CONTEXT_WIDTH = te_pkg::TE_CONTEXT_WIDTH;
  parameter int unsigned TVAL_WIDTH    = te_pkg::TE_TVAL_WIDTH;

  parameter int unsigned XTRIGGER_WIDTH               = cla_pkg::XTRIGGER_WIDTH;
  parameter int unsigned CLA_NUMBER_OF_CUSTOM_ACTIONS = cla_pkg::CLA_NUMBER_OF_CUSTOM_ACTIONS;

  typedef dst_pkg::timestamp_s       timestamp_s;
  typedef te_pkg::PrivMode_e         PrivMode_e;
  typedef te_pkg::TrigTraceControl_e TrigTraceControl_e;

  // ----------------------------------------------------------------------
  // legacy dfd_CL_axi_pkg geometry + structs
  // ----------------------------------------------------------------------
  parameter int unsigned TRC_AXI_ADDR_WIDTH = 52;
  parameter int unsigned TRC_AXI_DATA_WIDTH = 512;
  parameter int unsigned TRC_AXI_STRB_WIDTH = TRC_AXI_DATA_WIDTH / 8;
  parameter int unsigned TRC_AXI_ID_WIDTH   = 4;
  parameter int unsigned TRC_AXI_USER_WIDTH = 8;

  typedef struct packed {
    logic [TRC_AXI_ID_WIDTH-1:0]   id;
    logic [TRC_AXI_ADDR_WIDTH-1:0] addr;
    logic [7:0]                    len;
    logic [2:0]                    size;
    logic [1:0]                    burst;
    logic                          lock;
    logic [3:0]                    cache;
    logic [2:0]                    prot;
    logic [3:0]                    qos;
    logic [3:0]                    region;
    logic [5:0]                    atop;
    logic [TRC_AXI_USER_WIDTH-1:0] user;
  } dfd_axi_aw_t;

  typedef struct packed {
    logic [TRC_AXI_DATA_WIDTH-1:0] data;
    logic [TRC_AXI_STRB_WIDTH-1:0] strb;
    logic                          last;
    logic [TRC_AXI_USER_WIDTH-1:0] user;
  } dfd_axi_w_t;

  typedef struct packed {
    logic [TRC_AXI_ID_WIDTH-1:0]   id;
    logic [1:0]                    resp;
    logic [TRC_AXI_USER_WIDTH-1:0] user;
  } dfd_axi_b_t;

  typedef struct packed {
    logic [TRC_AXI_ID_WIDTH-1:0]   id;
    logic [TRC_AXI_ADDR_WIDTH-1:0] addr;
    logic [7:0]                    len;
    logic [2:0]                    size;
    logic [1:0]                    burst;
    logic                          lock;
    logic [3:0]                    cache;
    logic [2:0]                    prot;
    logic [3:0]                    qos;
    logic [3:0]                    region;
    logic [TRC_AXI_USER_WIDTH-1:0] user;
  } dfd_axi_ar_t;

  typedef struct packed {
    logic [TRC_AXI_ID_WIDTH-1:0]   id;
    logic [TRC_AXI_DATA_WIDTH-1:0] data;
    logic [1:0]                    resp;
    logic                          last;
    logic [TRC_AXI_USER_WIDTH-1:0] user;
  } dfd_axi_r_t;

  typedef struct packed {
    dfd_axi_aw_t aw;
    logic        aw_valid;
    dfd_axi_w_t  w;
    logic        w_valid;
    logic        b_ready;
    dfd_axi_ar_t ar;
    logic        ar_valid;
    logic        r_ready;
  } dfd_slv_axi_req_t;

  typedef struct packed {
    logic        aw_ready;
    logic        w_ready;
    dfd_axi_b_t  b;
    logic        b_valid;
    logic        ar_ready;
    dfd_axi_r_t  r;
    logic        r_valid;
  } dfd_slv_axi_rsp_t;

  // The legacy JTAG-AXI control slave carried the same AXI4 shape. The new
  // design has no equivalent port (see rtl/compat/README.md); the types exist
  // only so legacy port declarations still compile.
  typedef dfd_slv_axi_req_t dfd_tr_slv_axi_req_t;
  typedef dfd_slv_axi_rsp_t dfd_tr_slv_axi_rsp_t;

endpackage

`endif
