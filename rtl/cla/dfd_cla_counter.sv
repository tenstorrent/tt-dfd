//Note:for now, we will override the counter width as 31...
module dfd_cla_counter
import dfd_cr_csr_pkg::*;
import dfd_cla_pkg::*;
 #(
   parameter COUNTER_WIDTH = 31
) (
     input  logic clock,
     input  logic reset_n,
     input  counter_controls cla_counter_controls,
     input  ClacounterCfgCsr_s ClacounterCfgCsr,
     output logic target_match,
     output logic target_overflow,
     output logic below_target, 
     output ClacounterCfgCsrWr_s next_WrData  
);
   logic [COUNTER_WIDTH-1:0] next_counter,current_counter; 
   enum logic {STOP=1'b0, INCREMENT=1'b1} state, next_state;
   logic reset_counter;
 

  always @ (posedge clock)
   begin
     if (!reset_n) 
       state   <= STOP;
     else 
        state   <= next_state;
   end    

   assign  next_WrData.Data.Rsvd    = '0;
   assign  next_WrData.Data.ResetOnTarget    = '0;
   assign  next_WrData.Data.UpperTarget      = '0;
   assign  next_WrData.Data.Target    = '0;
   assign  next_WrData.Data.Counter = next_counter[15:0];
   assign  next_WrData.Data.UpperCounter = next_counter[COUNTER_WIDTH-1:16];
   assign  next_WrData.CounterWrEn  = 1'b1;
   assign  next_WrData.UpperCounterWrEn  = 1'b1;
   assign  reset_counter = ClacounterCfgCsr.ResetOnTarget && target_match;
  assign current_counter = {ClacounterCfgCsr.UpperCounter,ClacounterCfgCsr.Counter};
   always @ (*)
   begin
     next_state = state;
     next_counter = current_counter;
     case (state)
       STOP:begin 
           //Change Next State and Counter Value as per Counter Controls.
           if (cla_counter_controls.clear_ctr == 1'b1) begin
              next_state   = STOP;
              next_counter = {COUNTER_WIDTH{1'b0}};
             end 
           else if (cla_counter_controls.increment_pulse == 1'b1) begin
              next_state   = STOP;
              next_counter = (reset_counter == 1'b1)?{COUNTER_WIDTH{1'b0}}:current_counter+1'b1; 
             end 
           else if (cla_counter_controls.auto_increment == 1'b1) begin
              next_state   = INCREMENT;
              next_counter = (reset_counter == 1'b1)?{COUNTER_WIDTH{1'b0}}:current_counter+1'b1; 
             end 
           else  begin
              next_state   = STOP;
              next_counter = current_counter;
           end 
       end
       INCREMENT:begin 
           if (cla_counter_controls.clear_ctr == 1'b1) begin
              next_state   = STOP;
              next_counter = {COUNTER_WIDTH{1'b0}};
             end 
           else if (cla_counter_controls.stop_auto_increment == 1'b1) begin
              next_state   = STOP;
              next_counter = current_counter; 
             end 
           else  begin
              next_state   = INCREMENT;
              next_counter = (reset_counter == 1'b1)? {COUNTER_WIDTH{1'b0}}:current_counter + 1'b1;
           end 
       end
     endcase 
   end 

  always @(posedge clock)
     if (!reset_n)
      begin
       target_match    <= 1'b0;
       target_overflow <= 1'b0;
       below_target    <= 1'b0;
      end
      else 
      begin
       target_match    <= (next_counter == {ClacounterCfgCsr.UpperTarget,ClacounterCfgCsr.Target});
       target_overflow <= (next_counter >  {ClacounterCfgCsr.UpperTarget,ClacounterCfgCsr.Target});
       below_target    <= (next_counter <  {ClacounterCfgCsr.UpperTarget,ClacounterCfgCsr.Target});
      end
endmodule

