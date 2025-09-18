//Generate VLT packets.
module dfd_vlt_packet_compression
import dfd_cr_csr_pkg::*;
import dfd_cr_4b_csr_pkg::*;
import dfd_dst_pkg::*;
(
    input logic clock,
    input logic reset_n,

    // Timestamp value and DST-CSR control
    input  Cr4BTrdstcontrolCsr_s      Cr4BCsrTrdstcontrol,
    input  timestamp_s                timestamp,

    //Incoming Data from XOR compression
    input logic [DEBUG_SIGNAL_WIDTH-1:0] xor_debug_bus_in,
    input logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0]  xor_debug_bus_byte_enable_in,
    input logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info,
    input logic [DEBUG_SIGNALS_SOURCE_ID_WIDTH-1:0] debug_source, 
    input logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH],
    input logic [WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD-1:0] pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH],
    // Interface to Packetizer
    output logic [VLT_PACKET_WIDTH-1:0] vlt_packet,
    output logic [VLT_PACKET_WIDTH/8-1:0] vlt_packet_byte_enable,
    input  logic flush_mode_enable,
    input  logic flush_mode_exit,
    output logic trace_info_xmt_pending,
    output logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0] request_packet_space_in_bytes, // This will be available one clock before vlt_packet.
                                                                                  // This will be used to calculate if packet can be accepted by the dfd_packetizer
    input logic requested_packet_space_granted,                                   //Indication from Accumulator Control next packet will be lost.
    output logic retain_original_input,                                           // If requested packet space is not granted or timestamp packet is to be sent, retain original.
    // stream full signal
    input logic stream_full
);

function automatic logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] get_trace_info;
 input logic [VLT_PACKET_WIDTH-1:0] vlt_packet_in;
 begin
  if (vlt_packet_in[7] == 1'b0) //Data Packet
      get_trace_info = vlt_packet_in[1:0];
  else //Support Packet: Check Support Infor only if extended Header is set.
      get_trace_info = (vlt_packet_in[1] == 1'b1) ? vlt_packet_in[9:8] : 2'b00; 
 end
endfunction

//Vlt_payload(“variable-length-transmit” payload): Use the following logic to purge the inactive bytes
//Determine vlt_payload[7:0]
//     If be[0] : vlt_payload[7:0] = debug_bus[7:0]
//Else If be[1] : vlt_payload[7:0] = debug_bus[15:8]
//Else If be[2] : vlt_payload[7:0] = debug_bus[23:16]
// .. and so on (go all the way till be[7].
//Determine vlt_payload[15:8]
//     If be[1] && (sum(be[0])               ==1) :vlt_payload[15:8] = debug_bus[15:8]
//Else If be[2] && (sum(be[1], be[0])        ==1) :vlt_payload[15:8] = debug_bus[23:16]
//Else If be[3] && (sum(be[2], be[1], be[0]) =1) :vlt_payload[15:8] = debug_bus[31:24]
//.. and so on (go all the way till be[7].
//Determine vlt_payload[23:16]
//     If be[2] && (sum(be[1],be[0])             == 2) :vlt_payload[23:16] = debug_bus[23:16]
//Else If be[3] && (sum(be[2],be[1],be[0])       == 2) :vlt_payload[23:16] = debug_bus[31:24]
//Else If be[4] && (sum(be[3],be[2],be[1],be[0]) == 2) :vlt_payload[23:16] = debug_bus[49:32]
//.. and so on (go all the way till be[7].
// Since we have an adder in the mux-select, we will run into synthesis timing issues.
// To avoid this, generate sum(be[1], be[0]), sum(be[2],be[1],be[0]) , as flopped o/p along with data & be
// .. in the XOR compression block.
//sum(be[0],sum(be[1], be[0]),sum(be[1], be[2], be[0]),.. is named as pyramid_of_byte_enable_sums.
//we use dst priority mux to implement above logic.
//to ease coding, we can rewrite 
// be[2] && (sum(be[1],be[0])==2) 
// as be[2] && (pyramid_of_byte_enable_sums[1])=2) and furhter more...
// ({$clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH){be[1]} & pyramid_of_byte_enable_sums[0]) == 2

localparam  MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD = DEBUG_SIGNAL_WIDTH/8 ;
localparam  VLT_PAYLOAD_WIDTH = DEBUG_SIGNAL_WIDTH;


logic [VLT_PACKET_WIDTH-1:0] next_vlt_packet;
logic [VLT_PACKET_WIDTH/8-1:0] next_vlt_packet_byte_enable;
logic [VLT_PAYLOAD_WIDTH-1:0] vlt_payload;
logic [VLT_PAYLOAD_WIDTH/8-1:0] vlt_payload_byte_enable;
logic [VLT_PACKET_WIDTH-1:0] retry_vlt_packet;
logic [VLT_PACKET_WIDTH/8-1:0] retry_vlt_packet_byte_enable;
logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0]   retry_vlt_packet_length_in_bytes;
logic [$clog2(VLT_PACKET_WIDTH_IN_BYTES):0]   incoming_packet_length_in_bytes;
logic retry_data_packet_tx, retry_ts_packet_tx,retry_trace_info_tx;
vlt_data_header_s vlt_data_header;
vlt_support_pkt_header0_s vlt_flush_header;
vlt_support_pkt_header vlt_ts_header;
vlt_support_pkt_header vlt_tinfo_header;
logic trace_in_progress_flop, trace_in_progress;
logic packet_lost;
logic next_packet_lost;
logic trace_start_in_trace_info,trace_stop_in_trace_info;
logic trace_start_in_xmitted_vlt_packet,trace_stop_in_xmitted_vlt_packet;
logic trace_start_in_next_xmitted_vlt_packet,trace_stop_in_next_xmitted_vlt_packet;
logic trace_start_to_xmt,trace_stop_to_xmt;
logic [VLT_HDR_TRACE_INFO_WIDTH-1:0] trace_info_to_xmt,next_vlt_packet_trace_info;
logic trace_start_xmt_pending,trace_stop_xmt_pending; //,trace_info_xmt_pending;
logic incoming_packet;
logic trace_flush; 
logic ts_packet_enable;
logic stream_full_d1, stream_full_posedge, stream_full_till_next_input_packet, stream_full_till_next_input_packet_next;

logic [PERIODIC_SYNC_CTR_MAX_WIDTH - 1 : 0] periodic_sync_counter, next_periodic_sync_counter, periodic_sync_max_count;
logic periodic_sync_count_match, next_periodic_sync_count_match, periodic_sync_count_clr, periodic_sync_count_en;
logic dstStarted;

//Control Signals.
// Enable for preiodic counter
assign dstStarted = (Cr4BCsrTrdstcontrol.Trdstenable); 
// Max value of the periodic counter, after which the ts packet needs to be sent 
assign periodic_sync_max_count = PERIODIC_SYNC_CTR_MAX_WIDTH'({1 << (Cr4BCsrTrdstcontrol.Trdstsyncmax + 4)});
// Enable signal for the counter flop to be active only when the count off dst mode (2'b00) is off and dst is enabled
assign periodic_sync_count_en = (Cr4BCsrTrdstcontrol.Trdstsyncmode != COUNT_OFF_DST_MODE) & trace_in_progress;

// Denotes periodic counter overflow
assign next_periodic_sync_count_match = (next_periodic_sync_counter == (periodic_sync_max_count - PERIODIC_SYNC_CTR_MAX_WIDTH'(1)));
generic_dff #(.WIDTH(1)) periodic_sync_count_match_ff (.out(periodic_sync_count_match), .in(next_periodic_sync_count_match), .en(1'b1), .clk(clock), .rst_n(reset_n));
// Generates a clear signal when the counter overflows or when the dst is not enabled
assign periodic_sync_count_clr = periodic_sync_count_match | !trace_in_progress;
// Compute the next value of the periodic sync counter; periodic counter gets updated only when the enable is asserted to the following can be done unconditionally
assign next_periodic_sync_counter = periodic_sync_counter + 1'b1;
generic_dff_clr #(.WIDTH(PERIODIC_SYNC_CTR_MAX_WIDTH)) periodic_sync_count_ff (.out(periodic_sync_counter), .in(next_periodic_sync_counter), .clr(periodic_sync_count_clr), .en(periodic_sync_count_en), .clk(clock), .rst_n(reset_n)); 

// Enable for sending timestamp packets
assign ts_packet_enable = (Cr4BCsrTrdstcontrol.Trdstsyncmode == CYCLE_COUNT_DST_MODE) && periodic_sync_count_match & trace_in_progress;

//Packet loss   
// If requested packet space is not granted or timestamp packet is to be sent, retain original.
assign retain_original_input = (!requested_packet_space_granted | ts_packet_enable | retry_ts_packet_tx | stream_full_till_next_input_packet | trace_flush) & (xor_debug_bus_byte_enable_in != '0);

//Arrange debug bus as array of bytes.
logic [7:0] xor_debug_bus_bytes [MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD];
always @(*) begin
  for (int i = 0; i < MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD; i++) begin
    xor_debug_bus_bytes[i] = xor_debug_bus_in[(i*8) +: 8];
  end
end

//Do we have incoming packet?
always @(*) begin
  if (xor_debug_bus_byte_enable_in != 0)
    incoming_packet = 1'b1;
  else 
    incoming_packet = 1'b0;
end
    
// Stream full handling
generic_dff_clr #(.WIDTH(1)) stream_full_till_next_input_packet_ff (.out(stream_full_till_next_input_packet), .in(stream_full_till_next_input_packet_next), .clr(trace_info == 2'h2), .en(trace_in_progress), .clk(clock), .rst_n(reset_n));
generic_dff #(.WIDTH(1)) stream_full_ff (.out(stream_full_d1), .in(stream_full), .en(1'b1), .clk(clock), .rst_n(reset_n));

generic_dff_clr #(.WIDTH(1)) trace_in_progress_ff (.out(trace_in_progress_flop), .in(1'b1), .clr(trace_info == 2'h2), .en(trace_info == 2'h1), .clk(clock), .rst_n(reset_n));

assign trace_in_progress = ((trace_info == 2'h1) | trace_in_progress_flop) & ~(trace_info == 2'h2); 

assign stream_full_posedge = stream_full & !stream_full_d1;

always_comb
begin
  stream_full_till_next_input_packet_next = stream_full_till_next_input_packet;
  if(stream_full_till_next_input_packet && (xor_debug_bus_byte_enable_in != '0))
  begin
    stream_full_till_next_input_packet_next = 1'b0;
  end
  else if(stream_full_posedge)
  begin
    stream_full_till_next_input_packet_next = 1'b1;
  end
end

//generate mux selects: each bit of mux select is as follows:
// mux_select...[0] = be[7:0]
//                          bit[1]                                     ,bit[0]
// mux_select...[1] = ..., (be[2] &&       (sum(be[1],be[0])== 1)      ,(be[1] && (sum(be[0])== 1))
// mux_select...[2] = ..., (be[3] && (sum(be[2],be[1],be[0])== 2)      ,(be[2] && (sum(be[1],be[0])== 2))
// mux_select...[3] = ..., (be[4] && (sum(be[3],be[2],be[1],be[0])== 3),(be[3] && (sum(be[2],be[1],be[0])== 3))
logic [DEBUG_BUS_BYTE_ENABLE_WIDTH-1:0] mux_select_for_vlt_payload_calculation [0:MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-1];
always @(*) begin
  mux_select_for_vlt_payload_calculation[0] = xor_debug_bus_byte_enable_in;  
  for (int i = 1; i < MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD ; i=i+1) begin
    mux_select_for_vlt_payload_calculation[i] = {DEBUG_BUS_BYTE_ENABLE_WIDTH{1'b0}};
    for (int j = i; j < DEBUG_BUS_BYTE_ENABLE_WIDTH ; j=j+1)begin
     mux_select_for_vlt_payload_calculation[i][j-i] = ((pyramid_of_byte_enable_sums[j-1] &
                                                     {WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD{xor_debug_bus_byte_enable_in[j]}})
                                                     == (($clog2(MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD)+1))'(i)) ;  
    end
  end
end

generate
    for(genvar i=0;i<MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD;i=i+1) begin
       dfd_dst_priority_mux
       #(.LEVELS(MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-i)) vlt_instance (                            //8,      7,      6,       5,...
         .inputs(xor_debug_bus_bytes[i:MAX_NUMBER_OF_BYTES_IN_VLT_PAYLOAD-1]),                    //[0:7],  [1:7],  [2:7],  [3:7],...
         .select(mux_select_for_vlt_payload_calculation[i][DEBUG_BUS_BYTE_ENABLE_WIDTH-1-i:0]),   //[0],    [1],    [2],... 
         .mux_out(vlt_payload[(i*8) +: 8]));                                                      //[7:0],  [15:8], [16:23],[24:31],...
    end
endgenerate

//Generate vlt_payload_byte_enable 
//encode sum of byte-enables (sum(be[7],….,be[2],be[1],be[0]) as below:
//                   case (sum of byte enables)
//                     1: vlt_payload_byte_enable = 8’b1,
//                     2: vlt_payload_byte_enable = 8’b11,
//                     3: vlt_payload_byte_enable = 8’b111,
//                   …
//                           endcase  
//    input logic [$clog2(DEBUG_BUS_BYTE_ENABLE_WIDTH)+1:0] pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH],
always@(*) begin
   vlt_payload_byte_enable ={VLT_PAYLOAD_WIDTH/8{1'b0}};
   for(int i=0;i<VLT_PAYLOAD_WIDTH/8+1;i=i+1) begin
      if(pyramid_of_byte_enable_sums[DEBUG_BUS_BYTE_ENABLE_WIDTH-1] == (WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD)'(i)) begin 
        vlt_payload_byte_enable = (VLT_PAYLOAD_WIDTH/8)'(2**i-1);//{{VLT_PAYLOAD_WIDTH/8-1-i}{1'b0},i{1'b1}};
      end
   end 
end

//Create a VLT header.
//For regular packet
assign vlt_data_header.pkt_type = 1'b0;
assign vlt_data_header.source_id = debug_source;
assign vlt_data_header.packet_lost = packet_lost | (retry_ts_packet_tx & (trace_info == 2'h2));
assign vlt_data_header.trace_info = trace_info_to_xmt;
assign vlt_data_header.byte_enable = xor_debug_bus_byte_enable_in;
//For flush packet (null packet)
assign vlt_flush_header.pkt_type = 1'b1;
assign vlt_flush_header.source_id = debug_source;
assign vlt_flush_header.packet_lost = packet_lost;
assign vlt_flush_header.hdr_extended = 1'b0;
assign vlt_flush_header.null_packet  = 1'b1;
//For timestamp support packets
assign vlt_ts_header.header0.pkt_type = 1'b1;
assign vlt_ts_header.header0.source_id = debug_source;
assign vlt_ts_header.header0.packet_lost = packet_lost;
assign vlt_ts_header.header0.hdr_extended = 1'b1;
assign vlt_ts_header.header0.null_packet  = 1'b0;
assign vlt_ts_header.header1.support_form = 4'b0;
assign vlt_ts_header.header1.support_info = {2'b00, trace_info_to_xmt};
//For trace_info support packets
assign vlt_tinfo_header.header0.pkt_type = 1'b1;
assign vlt_tinfo_header.header0.source_id = debug_source;
assign vlt_tinfo_header.header0.packet_lost = packet_lost;
assign vlt_tinfo_header.header0.hdr_extended = 1'b1;
assign vlt_tinfo_header.header0.null_packet  = 1'b0;
assign vlt_tinfo_header.header1.support_form = 4'b1;
assign vlt_tinfo_header.header1.support_info = {2'b00, trace_info_to_xmt};

assign trace_start_in_trace_info = trace_info[TRACE_INFO_TRACE_START_POS]; 
assign trace_stop_in_trace_info  = trace_info[TRACE_INFO_TRACE_STOP_POS]; 
assign next_vlt_packet_trace_info = get_trace_info(next_vlt_packet);
assign trace_start_in_next_xmitted_vlt_packet = next_vlt_packet_trace_info[TRACE_INFO_TRACE_START_POS] && requested_packet_space_granted;
assign trace_stop_in_next_xmitted_vlt_packet  = next_vlt_packet_trace_info[TRACE_INFO_TRACE_STOP_POS]  && requested_packet_space_granted;

always@(posedge clock)
  if (!reset_n)
    trace_start_xmt_pending <= 1'b0;
  else if ( trace_stop_to_xmt )
    trace_start_xmt_pending <= 1'b0; // If trace stop comes while this is pending, clear it.
  else if (trace_start_to_xmt & ~trace_start_in_next_xmitted_vlt_packet) 
    trace_start_xmt_pending <= 1'b1;
  else if (trace_start_xmt_pending ==  trace_start_in_next_xmitted_vlt_packet)
    trace_start_xmt_pending <= 1'b0;

always@(posedge clock)
  if (!reset_n)
    trace_stop_xmt_pending <= 1'b0;
  else if ( trace_start_to_xmt )
    trace_stop_xmt_pending <= 1'b0;  // If trace start comes while this is pending, clear it.
  else if (trace_stop_to_xmt & ~trace_stop_in_next_xmitted_vlt_packet)
    trace_stop_xmt_pending <= 1'b1;
  else if (trace_stop_xmt_pending == trace_stop_in_next_xmitted_vlt_packet)
    trace_stop_xmt_pending <= 1'b0;

assign trace_start_to_xmt = trace_start_in_trace_info | trace_start_xmt_pending;
assign trace_stop_to_xmt  = trace_stop_in_trace_info  | trace_stop_xmt_pending;
assign trace_info_to_xmt  = {trace_stop_to_xmt,trace_start_to_xmt} ; 
assign trace_info_xmt_pending = (trace_start_xmt_pending | trace_stop_xmt_pending);

//Trace Flush Pulse.
assign trace_flush =  flush_mode_enable && (flush_mode_exit == 1'b0) && ~trace_info_xmt_pending; // Says Flush has started

// Retry  Flop: Store any incoming packets, for trasnmit retry om packet lost
always@(posedge clock)
  if (!reset_n) 
  begin
    retry_vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    retry_vlt_packet_length_in_bytes <= {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};
  end
  else if (ts_packet_enable)
  begin
    retry_vlt_packet                 <= {timestamp,vlt_ts_header};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b1}};
    retry_vlt_packet_length_in_bytes <= ($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1)'(NUMBER_OF_BYTES_IN_TS_PACKET);
  end
  else if (retry_ts_packet_tx && (trace_info == 2'h2))
  begin
    retry_vlt_packet                 <= {timestamp,vlt_ts_header};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b1}};
    retry_vlt_packet_length_in_bytes <= ($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1)'(NUMBER_OF_BYTES_IN_TS_PACKET);
  end
  else if (incoming_packet && !retry_ts_packet_tx) 
  begin
    retry_vlt_packet                 <= {vlt_payload,vlt_data_header};
    retry_vlt_packet_byte_enable     <= {vlt_payload_byte_enable,{VLT_HDR_WIDTH/8{1'b1}} };
    retry_vlt_packet_length_in_bytes <= request_packet_space_in_bytes;
  end
  // Reset the retry_vlt_packet if there are no incoming data or ts packets or trace info to xmit.
  else if (!retry_data_packet_tx && !retry_ts_packet_tx) 
  begin
    retry_vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    retry_vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    retry_vlt_packet_length_in_bytes <= {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};
  end 

// Retry Flag
always@(posedge clock)
  if (!reset_n)
  begin
     retry_data_packet_tx  <= 1'b0;
     retry_ts_packet_tx    <= 1'b0;
  end
  else if (flush_mode_enable) //(trace_flush)
  begin
     retry_data_packet_tx  <= 1'b0;
     retry_ts_packet_tx    <= 1'b0;
  end
  // The following assumes if ts fails, any case of previous data pkt is lost and won't be retried
  else if ((ts_packet_enable || retry_ts_packet_tx) && (!requested_packet_space_granted))
  begin
    retry_data_packet_tx  <= 1'b0; // this implies that only one (ts) of the previous packets can be retried
    retry_ts_packet_tx    <= 1'b1;
  end
  // The following implies that a pending data pkt (if any) will be retried next  
  else if ((ts_packet_enable || retry_ts_packet_tx) && requested_packet_space_granted)
  begin
      // After ts_packet_enable, retain_original_input will disable XOR 
      // compression and entire packet will come in.
      // if retry_ts_packet_tx is asserted, previous data packet
      // is already lost
      retry_data_packet_tx  <= 1'b0;
      retry_ts_packet_tx    <= 1'b0;
  end
  // At this point, the assumption is no ts pkt needs to be retried
  else if (incoming_packet && (!requested_packet_space_granted))  
  begin
      retry_data_packet_tx  <= 1'b1;
      retry_ts_packet_tx    <= 1'b0;
  end
  else if (retry_data_packet_tx && requested_packet_space_granted)
  begin
      retry_data_packet_tx  <= 1'b0;
      retry_ts_packet_tx    <= 1'b0;
  end 

always@(posedge clock)
  if (!reset_n) 
   begin
    vlt_packet                 <= {VLT_PACKET_WIDTH{1'b0}};
    vlt_packet_byte_enable     <= {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    packet_lost                <= 1'b0;
   end
  else 
   begin
    vlt_packet                 <= next_vlt_packet              ;
    vlt_packet_byte_enable     <= next_vlt_packet_byte_enable  ;
    packet_lost                <= next_packet_lost             ;
   end

always@(*)
  //Trace flush on Trace Stop
  if (trace_flush) 
  begin
    next_vlt_packet                 =  {NUMBER_OF_BYTES_ON_FLUSH{vlt_flush_header}};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {NUMBER_OF_BYTES_ON_FLUSH{1'b1}} : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted | ts_packet_enable | incoming_packet;
  end     
  // if timestamp pkt is available and there is no trace flush signal

  else if (ts_packet_enable)
  begin
    next_vlt_packet                 = {timestamp,vlt_ts_header};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {VLT_PACKET_WIDTH_IN_BYTES{1'b1}}: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = (incoming_packet | retry_data_packet_tx);
  end
  // if the last ts packet was not sent and there is no trace flush signal
  else if (retry_ts_packet_tx)
  begin
    next_vlt_packet                 = retry_vlt_packet;
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? retry_vlt_packet_byte_enable: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = (incoming_packet | retry_data_packet_tx | retry_ts_packet_tx);
  end
  // At this point, no ts packet is available, data packet is available
  else if (incoming_packet) 
  begin
    next_vlt_packet                 = {vlt_payload,vlt_data_header};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {vlt_payload_byte_enable,{VLT_HDR_WIDTH/8{1'b1}} }: {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted;
  end
  // retry sending data pkt 
  else if (retry_data_packet_tx) 
  begin
    next_vlt_packet                 = retry_vlt_packet;
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? retry_vlt_packet_byte_enable : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = !requested_packet_space_granted;
  end
  //Resend Trace Info (reuse TINFO packet)
  else if (trace_info_xmt_pending) 
  begin
    next_vlt_packet                 = {{DEBUG_SIGNAL_WIDTH{1'b0}},vlt_tinfo_header};
    next_vlt_packet_byte_enable     = requested_packet_space_granted ? {{VLT_PACKET_WIDTH_IN_BYTES-NUMBER_OF_BYTES_IN_TINFO_PACKET{1'b0}},{NUMBER_OF_BYTES_IN_TINFO_PACKET{1'b1}}} : {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = packet_lost;
  end
  else 
  begin
    next_vlt_packet                 = {VLT_PACKET_WIDTH{1'b0}};
    next_vlt_packet_byte_enable     = {VLT_PACKET_WIDTH_IN_BYTES{1'b0}};
    next_packet_lost                = packet_lost;
  end

//FIXME_TIMING: MOve the fixed value add to previous clock. (Check with PD to see if this is needed)
always@(posedge clock)
  if (!reset_n) 
    incoming_packet_length_in_bytes <= '0;
  else 
    incoming_packet_length_in_bytes <= pyramid_of_byte_enable_sums_next[DEBUG_BUS_BYTE_ENABLE_WIDTH-1] + WIDTH_OF_DEBUG_BUS_BYTE_ENABLE_SUM_FIELD'(VLT_HDR_WIDTH/8);  
 
always@(*)
   if (trace_flush) //Trace flush on Trace Stop; request space for flush;
      request_packet_space_in_bytes = NUMBER_OF_BYTES_ON_FLUSH;  
   else if (ts_packet_enable) // if timestamp pkt is available and there is no trace flush signal
      request_packet_space_in_bytes = NUMBER_OF_BYTES_IN_TS_PACKET;
   else if (retry_ts_packet_tx) // if the last ts packet was not sent and there is no trace flush signal
      request_packet_space_in_bytes = retry_vlt_packet_length_in_bytes;     
   else if (vlt_payload_byte_enable != 0)// Have a packet to send? 
      request_packet_space_in_bytes = incoming_packet_length_in_bytes;
   else if (retry_data_packet_tx) // retry Send 
      request_packet_space_in_bytes = retry_vlt_packet_length_in_bytes;
   else if (trace_info_xmt_pending) //Resend Trace Info (reuse TINFO packet)
      request_packet_space_in_bytes = NUMBER_OF_BYTES_IN_TINFO_PACKET;
   else //If not, dont request packet.
      request_packet_space_in_bytes = {($clog2(VLT_PACKET_WIDTH_IN_BYTES)+1){1'b0}};


endmodule

