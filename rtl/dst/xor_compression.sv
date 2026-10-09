// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module xor_compression
import dst_pkg::*;
#(
    parameter DEBUG_SIGNAL_WIDTH = 64,
    localparam DEBUG_BUS_BYTE_ENABLE_WIDTH = DEBUG_SIGNAL_WIDTH/8,
    localparam WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD = $clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH)+1

)
 (
    input logic clock,
    input logic reset_n,
    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_in,
    input logic trace_start, trace_stop, trace_pulse, trace_enable,
    input logic retain_original_input,
    input dst_format_mode_e dst_format_mode,
    output logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_out,
    output logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable,
    output logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info,
    output logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH],
    output logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH]

);

logic trace_valid,trace_valid_next,trace_valid_dly,trace_pulse_dly;
logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable_next;
logic trace_pulse_stop;
logic trace_start_stop;

assign trace_start_stop = (trace_valid == 1'b1 && trace_valid_dly == 1'b0)
                           || (trace_stop == 1'b1);

assign trace_pulse_stop = (trace_pulse_dly) && (~trace_pulse);
always @(*)
    if(trace_enable==0)
       trace_valid_next = 1'b0;
    else if (trace_start)
       trace_valid_next = 1'b1;
    else if (trace_stop | trace_pulse_stop )
       trace_valid_next = 1'b0;
    else
       trace_valid_next = trace_valid;

always @(posedge clock)
    if (!reset_n)
      begin
        trace_valid <= 1'b0;
        trace_valid_dly <= 1'b0;
        trace_pulse_dly <= 1'b0;
     end
    else
     begin
        trace_valid <= trace_valid_next | trace_pulse;
        trace_valid_dly <= trace_valid;
        trace_pulse_dly <= trace_pulse;
     end

always @(posedge clock)
    if (!reset_n)
       debug_bus_out <= {DEBUG_SIGNAL_WIDTH{1'b0}};
    else if (trace_valid == 1'b1)
       debug_bus_out <= debug_bus_in ;

genvar i;
generate
   for(i=0;i<DEBUG_BUS_BYTE_ENABLE_WIDTH;i=i+1)
   begin
      always @(*)
      begin
         if(trace_valid == 1'b0)
         begin
            debug_bus_byte_enable_next[i] = 1'b0;
         end
         else if(retain_original_input || trace_start_stop || (dst_format_mode == NO_COMPRESSION))
         begin
            debug_bus_byte_enable_next[i] = 1'b1;
         end
         else if(dst_format_mode == XOR_COMPRESSION_ONLY)
         begin
            debug_bus_byte_enable_next[i] = |(debug_bus_in ^ debug_bus_out);
         end
         else if(dst_format_mode == VLT_XOR_COMPRESSION)
         begin
            debug_bus_byte_enable_next[i] = |(debug_bus_in[i*8+7:i*8] ^ debug_bus_out[i*8+7:i*8]);
         end
         else
         begin
            debug_bus_byte_enable_next[i] = 1'b0;
         end
      end
   end
endgenerate

always@(*) begin
   pyramid_of_byte_enable_sums_next[0] =  WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD'(debug_bus_byte_enable_next[0]);
   for(int j=1;j<DEBUG_BUS_BYTE_ENABLE_WIDTH;j=j+1) begin
      pyramid_of_byte_enable_sums_next[j] = WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD'(pyramid_of_byte_enable_sums_next[j-1] + WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD'(debug_bus_byte_enable_next[j]));
   end
end

    always @(posedge clock)
      if (!reset_n || !trace_valid)
        trace_info <= {VLT_HDR_TRACE_INFO_WIDTH{1'b0}};
      else if (trace_valid)
       begin

        trace_info[0] <= (trace_valid_dly | trace_stop)?1'b0:1'b1;
        trace_info[1] <= trace_stop;
      end

    always @(posedge clock)
      if (!reset_n )
       begin
        debug_bus_byte_enable <= '0;
        pyramid_of_byte_enable_sums <= '{DEBUG_BUS_BYTE_ENABLE_WIDTH{'0}};
       end
      else
       begin
        debug_bus_byte_enable <= debug_bus_byte_enable_next;
        pyramid_of_byte_enable_sums <= pyramid_of_byte_enable_sums_next;
       end
endmodule
