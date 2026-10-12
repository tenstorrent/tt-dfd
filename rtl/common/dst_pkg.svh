// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`ifndef DST_PKG_SVH
`define DST_PKG_SVH

package dst_pkg;

parameter VLT_HDR_TRACE_INFO_WIDTH      = 2;
parameter TRACE_INFO_TRACE_START_POS    = 0;
parameter TRACE_INFO_TRACE_STOP_POS     = 1;
parameter DEBUG_SIGNALS_SOURCE_ID_WIDTH = 4;

parameter NUMBER_OF_BYTES_ON_FLUSH      = 10;
parameter NUMBER_OF_BYTES_IN_TS_PACKET  = 10;
parameter NUMBER_OF_BYTES_IN_TINFO_PACKET  = 2;
parameter CYCLE_COUNT_DST_MODE          = 2;
parameter STREAM_COUNT_DST_MODE         = 1;
parameter COUNT_OFF_DST_MODE            = 0;
parameter PERIODIC_SYNC_CTR_MAX_WIDTH   = 20;

typedef enum logic [2:0] {NO_COMPRESSION = 3'b0, XOR_COMPRESSION_ONLY = 3'b1, VLT_XOR_COMPRESSION = 3'b11} dst_format_mode_e;

typedef struct packed {
  logic                                     pkt_type;
  logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] source_id;
  logic                                     packet_lost;
  logic                                     hdr_extended;
  logic                                     null_packet;
} vlt_support_pkt_header0_s;

typedef struct packed {
  logic [3:0]                               support_form;
  logic [3:0]                               support_info;
} vlt_support_pkt_header1_s;

typedef struct packed {
  vlt_support_pkt_header1_s header1;
  vlt_support_pkt_header0_s header0;
} vlt_support_pkt_header;

typedef struct packed {
  logic [63:0]                              time_val;
} timestamp_s;

endpackage

`endif
