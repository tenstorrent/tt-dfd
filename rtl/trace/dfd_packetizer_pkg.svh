`ifndef DFD_PACKETIZER_PKG_SVH
`define DFD_PACKETIZER_PKG_SVH

package dfd_packetizer_pkg;

typedef enum logic [1:0] {BANK_EMPTY, BANK_PARTIAL, BANK_FULL} bank_status_t;

parameter MAX_FRAME_LENGTH_IN_BYTES = 512;
parameter DBG_TRACE_PACKETIZER_FIFO_DEPTH = 9;
parameter NTRACE_PACKETIZER_FIFO_DEPTH   = 11;
parameter MAX_STREAM_DEPTH = 512; // setting it to 512 as vendorstreamlength reset value is set to 4 which is equivalent to stream depth of 512
parameter MIN_STREAM_DEPTH = 32;

typedef struct packed {
    logic stream_count_enable;
    logic [$clog2(MAX_STREAM_DEPTH):0] stream_depth;
    logic [$clog2(MAX_FRAME_LENGTH_IN_BYTES):0] frame_length;
    logic [7:0] frame_fill_byte;
    logic frame_mode_enable;
    logic frame_closure_mode;
 } frame_info_s;
endpackage

`endif

