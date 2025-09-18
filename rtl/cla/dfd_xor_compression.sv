// *************************************************************************
// *
// * Tenstorrent CONFIDENTIAL
// * __________________
// *
// *  Tenstorrent Inc.
// *  All Rights Reserved.
// *
// * NOTICE:  All information contained herein is, and remains the property
// * of Tenstorrent Inc.  The intellectual and technical concepts contained
// * herein are proprietary to Tenstorrent Inc, and may be covered by U.S.,
// * Canadian and Foreign Patents, patents in process, and are protected by
// * trade secret or copyright law.  Dissemination of this information or
// * reproduction of this material is strictly forbidden unless prior
// * written permission is obtained from Tenstorrent Inc.
// *
// *************************************************************************

module dfd_xor_compression 
import dfd_dst_pkg::*;
 (
    input logic clock,
    input logic reset_n,
    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_in,
    input logic trace_start, trace_stop, trace_pulse, trace_enable,
    input logic retain_original_input, //When packet is lost by dfd_packetizer, we need to restart the XOR stream w/ all bytes. This can also act as chicken bit.
    input dst_format_mode_e dst_format_mode,
    output logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_out,
    output logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable,
    output logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info,
    output logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH],
    output logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH]
    
);
//              |0      |1      |2      |3      |4      |5      |6      |7      |8      |9   
//
//              +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
//Clock        _|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |   
//Continous Trace Mode.
//---------------------
//                              +-------+   
//Trace Start  _________________|       |__________________________________________________________ (i/p)
//                                                              +-------+   
//Trace Stop    ________________________________________________|       |___________________________(i/p)
//                                      +--------------------------------------+   
//Trace Valid   ________________________|                                       |_____(internal sig.)__
//              _______________________________________________________________________________                 
//Debug Bus in  00000000111111112222222233333333444444445555555566666666777777778888888899999999    (i/p)
//              -------------------------------------------------------------------------------
//       Debug bus values captured starting from cycle 3 and terminated after cycle 7 (cycle 7 value captured). 
//              _______________________________________________________________________________                 
//Debug Bus out                                  3333333344444444555555556666666677777777           (o/p)              
//              -------------------------------------------------------------------------------
//Pulse Trace Mode.
//-----------------
//                              +-------+               +-------+ 
//Trace Pulse  _________________|       |_______________|       |____________________________________(i/p)
//                                      ________                 ________
//Debug Bus out ________________________33333333_________________66666666____________________________(o/p)
//                                      --------                 --------
//                                      +-------+                +------+   
//Trace Valid   ________________________|       |________________|      |_________________(internal sig.)__
//       Debug bus values captured for cycle 2 and cycle 5. Treat Trace Pulse as valid for debug bus.

logic trace_valid,trace_valid_next,trace_valid_dly,trace_pulse_dly;
logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable_next;
logic trace_pulse_stop;
logic trace_start_stop;

assign trace_start_stop = (trace_valid == 1'b1 && trace_valid_dly == 1'b0)   //Send entire packet on trace-start irrespective of debug bus content  
                           || (trace_stop == 1'b1);                          //Send entire packet on trace-stop  irrespective of debug bus content 

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


 //Calcualte logic [$clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH):0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH],
// pyramid_of_byte_enable_sums[0] = debug_bus_byte_enable[0]
// pyramid_of_byte_enable_sums[1] = debug_bus_byte_enable[0]+debug_bus_byte_enable[1];
// pyramid_of_byte_enable_sums[2] = debug_bus_byte_enable[0]+debug_bus_byte_enable[1]+debug_bus_byte_enable[2];
// .. and so on



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
        // 2?b01: Trace Start, 2?b10: Trace Stop    
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

