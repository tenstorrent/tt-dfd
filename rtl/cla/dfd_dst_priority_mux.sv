module dfd_dst_priority_mux #(parameter WIDTH = 8, parameter LEVELS = 4) (
  input logic [WIDTH-1:0] inputs [0:LEVELS-1], // Input signals
  input logic [LEVELS-1:0] select, // Select signal
  output logic [WIDTH-1:0] mux_out // Output signal
);

  always_comb begin
    mux_out = {WIDTH{1'b0}}; 
    
//    for (int i = 0; i < LEVELS; i++) begin
    for (int i = 0; i < LEVELS; i++) begin
      if (select[(LEVELS-1)-i]) // Check if the current select bit is high
        mux_out = inputs[(LEVELS-1)-i]; // Override output if a higher priority input is detected
    end
  end

endmodule
