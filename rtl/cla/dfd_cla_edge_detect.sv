module dfd_cla_edge_detect
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
(
   input  logic clock,
   input  logic reset_n,
   input  DebugsignaledgedetectcfgCsr_s  DebugsignaledgedetectcfgCsr,
   input  logic [DEBUG_SIGNALS_WIDTH-1:0] debug_signals,
   output logic [1:0] debug_signal_edge_detect 
);
  //assign cfg variables
  logic  signal4edge_detect_0;
  logic  signal4edge_detect_0_dly1;
  logic  signal4edge_detect_1;
  logic  signal4edge_detect_1_dly1;
  logic [DEBUG_SIGNALS_WIDTH-1:0] signal0_select_qualified_debug_signals; //Debug Bus And-ed with 1 for Bit position selected by Signal0 Select
  logic [DEBUG_SIGNALS_WIDTH-1:0] signal1_select_qualified_debug_signals; //Debug Bus And-ed with 1 for Bit position selected by Signal1 Select
  
  //signal Select Mux
  genvar i;
  generate
     for(i=0;i<DEBUG_SIGNALS_WIDTH;i=i+1) begin
        assign signal0_select_qualified_debug_signals[i] = (DebugsignaledgedetectcfgCsr.Signal0Select==$clog2(DEBUG_SIGNALS_WIDTH)'(i))? debug_signals[i]:1'b0;
        assign signal1_select_qualified_debug_signals[i] = (DebugsignaledgedetectcfgCsr.Signal1Select==$clog2(DEBUG_SIGNALS_WIDTH)'(i))? debug_signals[i]:1'b0;
     end
  endgenerate
  assign signal4edge_detect_0 = |signal0_select_qualified_debug_signals;
  assign signal4edge_detect_1 = |signal1_select_qualified_debug_signals;

  //Detect Posedge
  always @(posedge clock)
      if (!reset_n)
        begin

         debug_signal_edge_detect[1:0] <= 2'b0;   
         signal4edge_detect_0_dly1 <= 1'b0;
         signal4edge_detect_1_dly1 <= 1'b0;
        end
      else 
        begin
         debug_signal_edge_detect[0] <= (DebugsignaledgedetectcfgCsr.PosEdgeSignal0 == 1)?
                                     (signal4edge_detect_0_dly1==0 && signal4edge_detect_0==1 ):
                                     (signal4edge_detect_0_dly1==1 && signal4edge_detect_0==0 );
         debug_signal_edge_detect[1] <= (DebugsignaledgedetectcfgCsr.PosEdgeSignal1 == 1)?
                                     (signal4edge_detect_1_dly1==0 && signal4edge_detect_1==1 ):
                                     (signal4edge_detect_1_dly1==1 && signal4edge_detect_1==0 );
         signal4edge_detect_0_dly1 <= signal4edge_detect_0;
         signal4edge_detect_1_dly1 <= signal4edge_detect_1;
        end

endmodule
     

