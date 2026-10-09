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

module tt_debug_bus_mux
import tt_dbm_pkg::*;
#(
   parameter DEBUG_MUX_OUTPUT_WIDTH = 64,
             LANE_WIDTH             = 8,
             NUM_INPUT_LANES       =  8,
             DEBUG_MUX_ID           = 6'b0,
             DISABLE_OUTPUT_FLOP    = 0,
   localparam NUM_OUTPUT_LANES       = (DEBUG_MUX_OUTPUT_WIDTH/LANE_WIDTH)
)
(
   input  DbgMuxSelMmr_s                                         DbgMuxSelMmr,      // DBM ID, Mode, Mux selects

   input  logic           [NUM_INPUT_LANES-1:0] [LANE_WIDTH-1:0] debug_signals_in,
   output logic           [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_bus_out,

   output logic                                                  debug_clken,

   input  logic                                                  clk,
   input  logic                                                  reset_n,

   input  logic                                                  test_icg_en
);

//for 0                <= lane < NUM_OUTPUT_LANES-1, debug_signals_in[lane] can only be output on debug_bus_out[lane] ("STATIC" lanes)
//for NUM_OUTPUT_LANES <= lane < NUM_INPUT_LANES-1 , debug_signals_in[lane] can be output on any debug_bus_out lane   ("UPPER" lanes)

//for a given output lane, mux_sel = 0 will select its STATIC lane
//                         mux_sel = n will select debug_signals_in[NUM_OUTPUT_LANES+n-1]

//for example, for a 16:8 DBM, the following is the mux_sel encoding and corresponding output for each of its 8 output lanes
// [5:0] MuxSelSeg[0-7]  |  Output Lane
// ----------------------+-----------------
// 000000                |  Static Lane (i.e. output lane = segment number. so lanes 0~7 use this encoding)
// 000001                |  Lane 8
// 000010                |  Lane 9
// 000011                |  Lane 10
// 000100                |  Lane 11
// 000101                |  Lane 12
// 000110                |  Lane 13
// 000111                |  Lane 14
// 001000                |  Lane 15

//a 13:4 DBM would have the following mux_sel encodings and corresponding output for each of its 4 output lanes
// [5:0] MuxSelSeg[0-7]  |  Output Lane
// ----------------------+-----------------
// 000000                |  Static Lane (i.e. output lane = segment number. so lanes 0~3 use this encoding)
// 000001                |  Lane 4
// 000010                |  Lane 5
// 000011                |  Lane 6
// 000100                |  Lane 7
// 000101                |  Lane 8
// 000110                |  Lane 9
// 000111                |  Lane 10
// 001000                |  Lane 11
// 001001                |  Lane 12
// 001010                |  Lane 13

localparam MUX_SEL_WIDTH = 6;

logic id_match;
logic valid, valid_d1;
logic dbm_active;
logic input_lanes_enabled;
logic enable_set_sel;
logic [1:0] enable_mode, enable_mode_d1, enable_mode_d2;
logic ccg_clk;

logic                 [15:0][MUX_SEL_WIDTH-1:0] mux_sel_in;
logic [NUM_OUTPUT_LANES-1:0][MUX_SEL_WIDTH-1:0] mux_sel_q;

logic toggle_state_en;
logic toggle_state_in;
logic toggle_state_q;

logic [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_mux_out;
logic [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_bus;
logic [NUM_OUTPUT_LANES-1:0][LANE_WIDTH-1:0] debug_bus_q;

assign valid               = DbgMuxSelMmr.Valid;
assign id_match            = (DbgMuxSelMmr.DbmId == $bits(DbgMuxSelMmr.DbmId)'(DEBUG_MUX_ID));
assign dbm_active          = |enable_mode;
assign input_lanes_enabled = (enable_mode_d1 == 2'b01);
assign debug_clken         = (enable_mode == 2'b01); // one clock cycle before input lanes are enabled internally to allow the input signals to be flopped before being probed by the DBM
assign enable_set_sel      = valid_d1 & id_match & (enable_mode == 2'b01); // 2'b01 is functional mode

// enable_mode ff operates with the input clock, without any gating
generic_dff #(
    .WIDTH       ($bits(logic [1:0])),
    .RESET_VALUE ('0)
) enable_mode_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    (id_match & valid),
    .in    (DbgMuxSelMmr.DbmMode),
    .out   (enable_mode)
);
generic_dff #(
    .WIDTH       ($bits(logic)),
    .RESET_VALUE ('0)
) valid_ff (
    .clk   (clk),
    .rst_n (reset_n),
    .en    ('1),
    .in    (valid),
    .out   (valid_d1)
);
generic_dff #(
    .WIDTH       ($bits(logic [1:0])),
    .RESET_VALUE ('0)
) enable_mode_d1_ff (
    .clk   (ccg_clk),
    .rst_n (reset_n),
    .en    ('1),
    .in    (enable_mode),
    .out   (enable_mode_d1)
);
generic_dff_clr #(
    .WIDTH       ($bits(logic [1:0])),
    .RESET_VALUE ('0)
) enable_mode_d2_ff (
    .clk   (ccg_clk),
    .rst_n (reset_n),
    .en    ('1),
    .clr   (~dbm_active),
    .in    (enable_mode_d1),
    .out   (enable_mode_d2)
);

      generic_ccg #(.HYST_EN(0)) DbmGatedClock (.out_clk(ccg_clk), .clk(clk), .en(dbm_active), .rst_n(reset_n), .force_en('0), .hyst('0), .te(test_icg_en));

//unpack mux selects
////today the struct has 8 segments of width 8 bits. those could probably both be parameterized in the future

assign mux_sel_in[0][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg0;
assign mux_sel_in[1][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg1;
assign mux_sel_in[2][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg2;
assign mux_sel_in[3][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg3;
assign mux_sel_in[4][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg4;
assign mux_sel_in[5][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg5;
assign mux_sel_in[6][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg6;
assign mux_sel_in[7][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg7;

if ((DEBUG_MUX_OUTPUT_WIDTH == 128) && (LANE_WIDTH == 8)) begin : gen_16_lane_selects
   assign mux_sel_in[8][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg8;
   assign mux_sel_in[9][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg9;
   assign mux_sel_in[10][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg10;
   assign mux_sel_in[11][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg11;
   assign mux_sel_in[12][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg12;
   assign mux_sel_in[13][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg13;
   assign mux_sel_in[14][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg14;
   assign mux_sel_in[15][MUX_SEL_WIDTH-1:0] = DbgMuxSelMmr.Muxselseg15;
end else begin : gen_8_lane_selects
   assign mux_sel_in[8][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[9][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[10][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[11][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[12][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[13][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[14][MUX_SEL_WIDTH-1:0] = '0;
   assign mux_sel_in[15][MUX_SEL_WIDTH-1:0] = '0;
end

//mux debug signals
for(genvar lane=0; lane<NUM_OUTPUT_LANES; lane++) begin : gen_dbm
   generic_dff #(
       .WIDTH       ($bits(logic [MUX_SEL_WIDTH-1:0])),
       .RESET_VALUE ('0)
   ) mux_sel_ff (
       .clk   (ccg_clk),
       .rst_n (reset_n),
       .en    (enable_set_sel),
       .in    (mux_sel_in[lane]),
       .out   (mux_sel_q[lane])
   );

   always_comb begin
      debug_mux_out[lane] = {LANE_WIDTH{(mux_sel_q[lane] == MUX_SEL_WIDTH'(0))}} & debug_signals_in[lane];
      for(int i=1; i<=(NUM_INPUT_LANES-NUM_OUTPUT_LANES); i++) begin
         debug_mux_out[lane] |= {LANE_WIDTH{(mux_sel_q[lane] == MUX_SEL_WIDTH'(i))}} & debug_signals_in[NUM_OUTPUT_LANES+i-1];
      end

      debug_bus[lane] = LANE_WIDTH'(0);
      if           (enable_mode_d1 == 2'b01) begin            // functional debug mode
         debug_bus[lane] = debug_mux_out[lane];
      end else if (    (enable_mode_d1 == 2'b10)
                    || (enable_mode_d1 == 2'b11 && (DISABLE_OUTPUT_FLOP == 1))
                  ) begin                                                          // DBM ID output mode, or toggle mode with DISABLE_OUTPUT_FLOP=1
         debug_bus[lane] = (lane == 0) ? (LANE_WIDTH)'(DEBUG_MUX_ID)
                                       : (LANE_WIDTH)'(0)
                                       ;
      end else if ((enable_mode_d1 == 2'b11) && (DISABLE_OUTPUT_FLOP == '0)) begin // toggle mode (uses the debug_bus_ff if DISABLE_OUTPUT_FLOP=0)
         debug_bus[lane] = (enable_mode_d2 != 2'b11) ? ( (lane == 0) ? (LANE_WIDTH)'(DEBUG_MUX_ID)
                                                                     : (LANE_WIDTH)'(0)
                                                       )
                                                     : ~debug_bus_q[lane]
                                                     ;
      end
   end //always_comb
end

generate
   if (DISABLE_OUTPUT_FLOP) begin : gen_toggle_state_ff
      //if we are not instantiating the 64 (OUTPUT_WIDTH) output flops, then instantiate a single flop instead for toggle mode
      assign toggle_state_en = (enable_mode == 2'b11) | (enable_mode_d1 == 2'b11);
      assign toggle_state_in = (enable_mode == 2'b11) & ~toggle_state_q;
      generic_dff #(
          .WIDTH       ($bits(logic)),
          .RESET_VALUE ('0)
      ) toggle_state_ff (
          .clk   (ccg_clk),
          .rst_n (reset_n),
          .en    (toggle_state_en),
          .in    (toggle_state_in),
          .out   (toggle_state_q)
      );
   end else begin : gen_toggle_state
      assign toggle_state_en = '0;
      assign toggle_state_in = '0;
      assign toggle_state_q  = '0;
   end
   for(genvar lane=0; lane<NUM_OUTPUT_LANES; lane++) begin : gen_debug_bus_q
      if (DISABLE_OUTPUT_FLOP) begin : gen_dbm_toggle_state
         assign debug_bus_q[lane] = debug_bus[lane] ^ {LANE_WIDTH{toggle_state_q}}; //if DISABLE_OUTPUT_FLOP=1, use the toggle_state_ff for toggle mode
      end else begin : gen_debug_bus_ff
         generic_dff #(
             .WIDTH       ($bits(logic [LANE_WIDTH-1:0])),
             .RESET_VALUE ('0)
         ) debug_bus_ff (
             .clk   (ccg_clk),
             .rst_n (reset_n),
             .en    ('1),
             .in    (debug_bus[lane]),
             .out   (debug_bus_q[lane])
         );
      end
      `ifndef SYNTHESIS // Added to prevent x-prop in simulations; done to fix issue described in RVDE-21945
         for(genvar i=0; i<LANE_WIDTH; i++) begin : gen_debug_bus_sim_output
             assign debug_bus_out[lane][i] = ((debug_bus_q[lane][i] === 'x) || (debug_bus_q[lane][i] === 'z)) ? 1'b0 : debug_bus_q[lane][i];
         end
      `else
      assign debug_bus_out[lane] = debug_bus_q[lane];
      `endif
   end
endgenerate

endmodule
