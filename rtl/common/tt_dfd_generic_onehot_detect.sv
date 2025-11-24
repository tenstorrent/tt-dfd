// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module tt_dfd_generic_onehot_detect #(
      parameter WIDTH       = 8,      
      parameter ZERO_ONEHOT = 0                                         // Detect one-hot instead of zero-one-hot
	)           		  
   
( 
   input  logic [WIDTH-1:0] in, 
   output logic             out
);

      logic temp;

      assign temp = (in != 0) && (in & (in - 1)) == 0;
      assign out = (ZERO_ONEHOT == 0) ? temp : (temp | in == 0);

endmodule