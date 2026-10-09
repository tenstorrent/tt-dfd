// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module te_mso import te_pkg::*; # (
    parameter MDO_BITS   = 6,
    parameter DATA_WIDTH = 64,
    parameter SIZE       = $clog2(DATA_WIDTH),
    parameter MSO_BITS   = 2,
    parameter MSG_BITS   = MDO_BITS + MSO_BITS,
    parameter DATA_OUT_BYTES = (DATA_WIDTH + MDO_BITS -1)/MDO_BITS,
    parameter DATA_OUT_WIDTH = DATA_OUT_BYTES*MSG_BITS
)
(

    input   logic [DATA_WIDTH-1:0]                      data_in,
    input   logic [SIZE:0]                              data_len,

    input   logic                                       is_var,
    input   logic                                       is_last,

    output  logic [DATA_OUT_WIDTH-1:0]                  data_out,
    output  logic [$clog2(DATA_OUT_BYTES):0]            data_out_len_in_bytes,
    output  logic [DATA_OUT_BYTES-1:0]                  data_out_be
);

    logic [DATA_WIDTH:0] [DATA_OUT_WIDTH-1:0] extend_data_in;
    logic [DATA_OUT_WIDTH-1:0] mod_data_in;

    logic [DATA_OUT_WIDTH-1:0]                  mod_data_out;
    logic [$clog2(DATA_OUT_BYTES):0]            mod_data_out_len_in_bytes;
    logic [DATA_OUT_BYTES-1:0]                  mod_data_out_be;

    assign mod_data_in = $bits(mod_data_in)'(data_in);

    for (genvar i=0; i<=DATA_WIDTH; i=i+1) begin : gen_extend_data_in
      for (genvar j=0; j<((i + MDO_BITS -1)/MDO_BITS); j=j+1) begin : gen_mseo
          if (j < ((i + MDO_BITS -1)/MDO_BITS -1))
              assign extend_data_in[i][(j+1)*MSG_BITS-1:j*MSG_BITS] = {mod_data_in[(j+1)*MDO_BITS-1:j*MDO_BITS],2'b00};
          else
              assign extend_data_in[i][(j+1)*MSG_BITS-1:j*MSG_BITS] = {mod_data_in[(j+1)*MDO_BITS-1:j*MDO_BITS],(is_last?2'b11:(is_var?2'b01:2'b00))};
      end
      if (i<61)
          assign extend_data_in[i][DATA_OUT_WIDTH-1:((i+MDO_BITS-1)/MDO_BITS)*MSG_BITS] = 0;
    end

    always_comb begin : mseo_mux
    mod_data_out = '0;
    mod_data_out_len_in_bytes = '0;
    mod_data_out_be = '0;
        for (int i=0; i<=DATA_WIDTH; i=i+1) begin
            if (((SIZE+1)'(i) == data_len) & |data_len) begin
                mod_data_out = extend_data_in[i][DATA_OUT_WIDTH-1:0];
                mod_data_out_len_in_bytes = ($clog2(DATA_OUT_BYTES)+1)'((data_len-1'b1)/(SIZE+1)'(MDO_BITS) + (SIZE+1)'(|data_len));
                mod_data_out_be = (1 << mod_data_out_len_in_bytes) - 1'b1;
                break;
            end
            else begin
                mod_data_out = (is_last?'b11:(is_var?'b01:'b00));
                mod_data_out_len_in_bytes = (is_last | is_var)?'b1:'b0;
                mod_data_out_be = (is_last | is_var)?'b1:'b0;
            end
        end
    end

    assign data_out = mod_data_out;
    assign data_out_len_in_bytes = mod_data_out_len_in_bytes;
    assign data_out_be = mod_data_out_be;

endmodule
