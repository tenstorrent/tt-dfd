// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`ifndef DFD_COMPAT_PKG_SVH
`define DFD_COMPAT_PKG_SVH

package dfd_compat_pkg;

  parameter int unsigned DFD_APB_ADDR_WIDTH  = 23;
  parameter int unsigned DFD_APB_DATA_WIDTH  = 32;
  parameter int unsigned DFD_APB_PSTRB_WIDTH = DFD_APB_DATA_WIDTH / 8;
  parameter int unsigned DEBUG_SIGNALS_WIDTH = 64;
  parameter int unsigned MAX_NUM_TRACE_INST  = 8;

  parameter int unsigned LEGACY_HW_BUS_WIDTH = 16;
  parameter int unsigned LEGACY_NUM_HW_BUSES = 16;

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

  typedef dfd_slv_axi_req_t dfd_tr_slv_axi_req_t;
  typedef dfd_slv_axi_rsp_t dfd_tr_slv_axi_rsp_t;

endpackage

`endif
