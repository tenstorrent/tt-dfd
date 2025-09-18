//Debug Bus --> VLT packets.
module dfd_debug_sig_trace_gen
import dfd_cr_csr_pkg::*;
import dfd_cr_4b_csr_pkg::*;
import dfd_dst_pkg::*;
(
    input logic clock,
    input logic reset_n,
    input logic trace_start, trace_stop, trace_pulse,
    input logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] debug_source, 

    input logic [DEBUG_SIGNAL_WIDTH-1:0] debug_bus_in,
    input logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  debug_bus_byte_enable,

    input logic trace_hardware_flush,
    input logic trace_hardware_stop,

   // Register Interface
    input  Cr4BTrdstcontrolCsr_s      Cr4BCsrTrdstcontrol,
    output Cr4BTrdstcontrolCsrWr_s    Cr4BCsrTrdstcontrolWr,
    input  timestamp_s				        timestamp,

  // Flush Interface
    output logic flush_mode_enable,
    input  logic flush_mode_exit,
    input  logic packetizer_empty,

    output logic [VLT_PACKET_WIDTH-1:0] vlt_packet,
    output logic [VLT_PACKET_WIDTH/8-1:0] vlt_packet_byte_enable,
    output logic [$clog2(VLT_PACKET_WIDTH/8):0] request_packet_space_in_bytes, // This will be available one clock before vlt_packet.
                                                                      // This will be used to calculate if packet can be accepted by the dfd_packetizer
    input logic requested_packet_space_granted,                        //Indication from dfd_packetizer that the next packet will be lost.
    // Stream full signal from packetiser
    input logic stream_full

);
    //Output from XOR Compression
    logic [DEBUG_SIGNAL_WIDTH-1:0] xor_debug_bus;
    logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  xor_debug_bus_byte_enable;
    logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] xor_trace_info;
    logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH];
    logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH];
    dst_format_mode_e dst_format_mode;

  assign dst_format_mode = dst_format_mode_e'(Cr4BCsrTrdstcontrol.Trdstformat);
     
  // Flush Support
  logic trace_start_effective;
  logic trdst_enable, trdst_enable_dly, next_flush_mode_enable;
  logic trace_disable_due_to_hw_flush; 
  logic trace_stop_from_hw_flush, trace_stop_from_hw_flush_d1, trace_start_after_hw_flush;
  logic sw_tracing_in_progress, tracing_in_progress_flop;

  logic trace_hardware_stop_d1, trace_hardware_flush_d1;
  logic trace_stop_from_hw_overflow, trace_hardware_flush_pulse;

  logic trace_hw_flush_inprogress, trace_hw_flush_inprogress_d1;
  logic trace_stop_from_sw_when_hw_flush_inprogress;
  logic trace_info_xmt_pending;

  assign trdst_enable = Cr4BCsrTrdstcontrol.Trdstenable & ~trace_disable_due_to_hw_flush & ~(~sw_tracing_in_progress & trace_hardware_flush_pulse & ~trace_stop);
  always@ (posedge clock) begin
    if(reset_n == 0) begin
        flush_mode_enable <= 1'b0;
        trdst_enable_dly  <= 1'b0;
      end 
    else begin
        flush_mode_enable <= next_flush_mode_enable;
        trdst_enable_dly  <= trdst_enable;
      end 
  end

  always@(*)
    begin
     if (flush_mode_enable == 1'b0)
        next_flush_mode_enable = (trdst_enable_dly == 1'b1) && (trdst_enable == 1'b0); //Set flush mode on transition of trdst enable from 1->0;
     else  
        next_flush_mode_enable = (flush_mode_exit == 1'b0) | trace_info_xmt_pending; //Exit flush mode on indication from dfd_packetizer.
    end
  always_comb begin  
       Cr4BCsrTrdstcontrolWr = '0; 
       Cr4BCsrTrdstcontrolWr.TrdstinsttracingWrEn = trace_hardware_stop;
       Cr4BCsrTrdstcontrolWr.Data.Trdstinsttracing = 1'b0;
       Cr4BCsrTrdstcontrolWr.TrdstemptyWrEn=1'b1;
       Cr4BCsrTrdstcontrolWr.Data.Trdstempty = packetizer_empty;
  end 

   //Packet loss   
   // If requested packet space is not granted, retain original.
   logic retain_original_input;

  generic_dff #(.WIDTH(1)) trace_hardware_stop_d1_ff (.out(trace_hardware_stop_d1), .in(trace_hardware_stop), .en(1'b1), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trace_hardware_flush_d1_ff (.out(trace_hardware_flush_d1), .in(trace_hardware_flush), .en(1'b1), .clk(clock), .rst_n(reset_n));
  
  assign trace_stop_from_hw_overflow = trace_hardware_stop & ~trace_hardware_stop_d1;  
  assign trace_hardware_flush_pulse = trace_hardware_flush & ~trace_hardware_flush_d1; 
 
  generic_dff_clr #(.WIDTH(1)) trace_hardware_flush_inprogress_ff (.out(trace_hw_flush_inprogress), .in(1'b1), .clr(flush_mode_enable & flush_mode_exit), .en(sw_tracing_in_progress & trace_hardware_flush_pulse), .clk(clock), .rst_n(reset_n));
  generic_dff #(.WIDTH(1)) trace_hardware_flush_inprogress_d1_ff (.out(trace_hw_flush_inprogress_d1), .in(trace_hw_flush_inprogress), .en(1'b1), .clk(clock), .rst_n(reset_n));

  generic_dff_clr #(.WIDTH(1)) trace_stop_from_sw_when_flush_inprogress_ff (.out(trace_stop_from_sw_when_hw_flush_inprogress), .in(1'b1), .clr(trace_hw_flush_inprogress_d1 & ~trace_hw_flush_inprogress), .en(trace_hw_flush_inprogress & trace_stop), .clk(clock), .rst_n(reset_n)); 
  
  assign trace_start_after_hw_flush = ~trace_hw_flush_inprogress & trace_hw_flush_inprogress_d1 & ~trace_stop_from_sw_when_hw_flush_inprogress & ~trace_stop; 
  assign trace_stop_from_hw_flush = trace_hw_flush_inprogress & ~trace_hw_flush_inprogress_d1; 

  generic_dff #(.WIDTH(1)) trace_stop_from_hw_flush_d1_ff (.out(trace_stop_from_hw_flush_d1), .in(trace_stop_from_hw_flush), .en(1'b1), .clk(clock), .rst_n(reset_n));
  
  assign trace_disable_due_to_hw_flush = ~trace_stop_from_hw_flush & trace_stop_from_hw_flush_d1; 

  generic_dff_clr #(.WIDTH(1)) tracing_in_progress_flop_ff (.out(tracing_in_progress_flop), .in(1'b1), .clr(trace_stop), .en(trace_start_effective), .clk(clock), .rst_n(reset_n));
  assign sw_tracing_in_progress = (tracing_in_progress_flop | trace_start_effective) & ~trace_stop;

  assign trace_start_effective = trace_start & ~trace_hardware_stop; 

   // Instantiate XOR Compressor
   dfd_xor_compression  dfd_xor_compression
    (
    // Input from top
    .clock (clock),
    .reset_n (reset_n),
    .debug_bus_in (debug_bus_in),
    .trace_start (trace_start_effective | trace_start_after_hw_flush),
    .trace_stop  (trace_stop | trace_stop_from_hw_overflow | trace_stop_from_hw_flush),
    .trace_pulse (trace_pulse),
    .trace_enable(trdst_enable),
    .retain_original_input (retain_original_input),
    .dst_format_mode(dst_format_mode),
    //Output to VLT packet compression
    .debug_bus_out (xor_debug_bus),
    .debug_bus_byte_enable (xor_debug_bus_byte_enable),
    .trace_info (xor_trace_info),
    .pyramid_of_byte_enable_sums (pyramid_of_byte_enable_sums),
    .pyramid_of_byte_enable_sums_next (pyramid_of_byte_enable_sums_next)
   );
   
   //Instantiate VLT Packet Compressor
    dfd_vlt_packet_compression dfd_vlt_packet_compression
    (
    // Input from top
    .clock (clock),
    .reset_n (reset_n),
    .debug_source (debug_source),  

    // Timestamp value and DST-CSR control
    .timestamp(timestamp),
    .Cr4BCsrTrdstcontrol(Cr4BCsrTrdstcontrol),

    //Incoming Data from XOR compression
    .xor_debug_bus_in (xor_debug_bus),
    .xor_debug_bus_byte_enable_in (xor_debug_bus_byte_enable),
    .trace_info (xor_trace_info),
    .pyramid_of_byte_enable_sums (pyramid_of_byte_enable_sums),
    .pyramid_of_byte_enable_sums_next (pyramid_of_byte_enable_sums_next),

    //Flush Support
    .flush_mode_enable(flush_mode_enable),
    .flush_mode_exit(flush_mode_exit),
    .trace_info_xmt_pending(trace_info_xmt_pending),

    // Interface to Packetizer
    .vlt_packet (vlt_packet),
    .vlt_packet_byte_enable (vlt_packet_byte_enable),
    .request_packet_space_in_bytes (request_packet_space_in_bytes), // This will be available one clock before vlt_packet.
                                                                                  // This will be used to calculate if packet can be accepted by the dfd_packetizer
    .requested_packet_space_granted (requested_packet_space_granted),
    .retain_original_input  (retain_original_input),                                 //Indication from Accumulator Control next packet will be lost.
    .stream_full (stream_full)

);
endmodule

