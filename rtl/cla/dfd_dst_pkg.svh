`ifndef DFD_DST_PKG_SVH
`define DFD_DST_PKG_SVH

package dfd_dst_pkg;
parameter DEBUG_SIGNAL_WIDTH            = 64;
parameter DEBUG_BUS_BYTE_ENABLE_WIDTH   = DEBUG_SIGNAL_WIDTH/8;
parameter VLT_HDR_WIDTH                 = 16;
parameter VLT_PACKET_WIDTH              = VLT_HDR_WIDTH+DEBUG_SIGNAL_WIDTH;
parameter VLT_PACKET_WIDTH_IN_BYTES     = VLT_PACKET_WIDTH/8;
parameter VLT_HDR_TRACE_INFO_WIDTH      = 2;
parameter TRACE_INFO_TRACE_START_POS    = 0;
parameter TRACE_INFO_TRACE_STOP_POS     = 1;
parameter DEBUG_SIGNALS_SOURCE_ID_WIDTH = 4; 
parameter WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD= $clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH)+1;
parameter NUMBER_OF_BYTES_ON_FLUSH      = 10; //Send max packet size to flush to reach frame boundary faster.
parameter NUMBER_OF_BYTES_IN_TS_PACKET  = 10; 
parameter NUMBER_OF_BYTES_IN_TINFO_PACKET  = 2; 
parameter CYCLE_COUNT_DST_MODE          = 2;
parameter STREAM_COUNT_DST_MODE         = 1;
parameter COUNT_OFF_DST_MODE            = 0;
parameter PERIODIC_SYNC_CTR_MAX_WIDTH   = 20;

typedef enum logic [2:0] {NO_COMPRESSION = 3'b0, XOR_COMPRESSION_ONLY = 3'b1, VLT_XOR_COMPRESSION = 3'b11} dst_format_mode_e;

typedef struct packed {
  logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]   byte_enable; 
  logic                                     pkt_type;       //1'b0: Data Packet, 1'b1: Support Packet
  logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] source_id;      //Source of debug trace {1'b1,core id}
  logic                                     packet_lost;
  logic [VLT_HDR_TRACE_INFO_WIDTH-1:0]      trace_info;     //2'b01: Trace Start, 2'b10: Trace Stop, 2'b11: Periodic Synch 
} vlt_data_header_s;

typedef struct packed {
  logic                                     pkt_type;       //1'b0: Data Packet, 1'b1: Support Packet
  logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] source_id;      //Source of debug trace {1'b1,core id}
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

