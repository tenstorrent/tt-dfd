// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

module dfd_time_sync #(
        parameter integer DFD_APB_ADDR_WIDTH = 32,
        parameter integer DFD_APB_DATA_WIDTH = 32,
        parameter integer DFD_APB_PSTRB_WIDTH = DFD_APB_DATA_WIDTH / 8,
        /* verilator lint_off WIDTHTRUNC */
        parameter bit [DFD_APB_ADDR_WIDTH-1:0] BASE_ADDR = 'h0,
        /* verilator lint_on WIDTHTRUNC */
        parameter bit [DFD_APB_ADDR_WIDTH-1:0] START_OFFSET = 'h200,
        localparam integer ADDR_W = DFD_APB_ADDR_WIDTH,
        localparam integer DATA_W = DFD_APB_DATA_WIDTH

    ) (
        input  logic                           i_clk,
        input  logic                           i_reset_n,
        input  logic                           i_reset_n_warm,
        input  logic [ DFD_APB_ADDR_WIDTH-1:0] i_paddr,
        input  logic                           i_psel,
        input  logic                           i_penable,
        input  logic [DFD_APB_PSTRB_WIDTH-1:0] i_pstrb,
        input  logic                           i_pwrite,
        input  logic [ DFD_APB_DATA_WIDTH-1:0] i_pwdata,
        output logic                           o_pready,
        output logic [ DFD_APB_DATA_WIDTH-1:0] o_prdata,
        output logic                           o_pslverr,
        output logic                           o_reg_hit,

        input logic                            i_xtrigger,
        input logic                            i_time_tick,
        output logic [63:0]                    o_timestamp,
        output logic [7:0]                     o_debug_marker


    );

    // Local regs for timestamping
    /* verilator lint_off WIDTHEXPAND */
    localparam [ADDR_W-1:0] ADDR_CSR_TIMESTAMP          = DFD_APB_ADDR_WIDTH'(BASE_ADDR + START_OFFSET);
    localparam [ADDR_W-1:0] ADDR_CSR_TIMESTAMP_SYNC     = DFD_APB_ADDR_WIDTH'(BASE_ADDR + START_OFFSET + 'h08);
    localparam [ADDR_W-1:0] ADDR_CSR_TIMESTAMP_CONFIG   = DFD_APB_ADDR_WIDTH'(BASE_ADDR + START_OFFSET + 'h10);
    /* verilator lint_on WIDTHEXPAND */

    logic i_xtrigger_ff;
    logic xtrigger_posedge;

    logic i_cs;
    logic reg_psel;
    logic reg_wr_en;
    logic reg_rd_en;
    logic reg_wr_strb;
    logic [ADDR_W-1:0] reg_addr;
    logic [DATA_W-1:0] reg_wr_data;
    logic [DATA_W-1:0] reg_rd_data;
    logic reg_wr_ready, reg_rd_ready;
    logic reg_hit;

    tt_dfd_generic_dff #(.WIDTH(1))  xtrigger_edge_det  ( .clk(i_clk), .rst_n(i_reset_n), .en(1'b1), .in(i_xtrigger), .out(i_xtrigger_ff));
    assign xtrigger_posedge = i_xtrigger && ~i_xtrigger_ff;

    assign o_pready = reg_wr_ready | reg_rd_ready;
    assign o_prdata = reg_rd_ready ? reg_rd_data : '0;
    assign o_pslverr = 1'b0;
    assign o_reg_hit = reg_psel && reg_hit; // early signal

    assign i_cs = i_psel & ~i_penable;

    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_psel_ff           (.out(reg_psel),     .in(i_psel)            , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_wr_strb_ff        (.out(reg_wr_strb),  .in(&i_pstrb)          , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(ADDR_W)      , .RESET_VALUE(0)) reg_addr_ff           (.out(reg_addr),     .in(i_paddr)           , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(DATA_W)      , .RESET_VALUE(0)) reg_wr_data_ff        (.out(reg_wr_data),  .in(i_pwdata)          , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_rd_sel_ff         (.out(reg_rd_en),    .in(i_cs && ~i_pwrite) , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_wr_sel_ff         (.out(reg_wr_en),    .in(i_cs && i_pwrite)  , .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));


    // Register write logic
    logic        timestamp_low_reg_wr_en;
    logic [31:0] timestamp_low_reg, timestamp_low_reg_nxt;
    logic        timestamp_high_reg_wr_en;
    logic [31:0] timestamp_high_reg, timestamp_high_reg_nxt;
    logic        timestamp_sync_low_reg_wr_en;
    logic [31:0] timestamp_sync_low_reg;
    logic        timestamp_sync_high_reg_wr_en;
    logic [31:0] timestamp_sync_high_reg;
    logic        timestamp_config_reg_wr_en;
    logic [31:0] timestamp_config_reg, timestamp_config_reg_nxt;
    logic        timestamp_load;
    logic [63:0] timestamp_nxt;
    logic        timestamp_resync;

    assign timestamp_resync = timestamp_config_reg[0];
    assign timestamp_load   = timestamp_resync && xtrigger_posedge;
    assign timestamp_nxt    = o_timestamp +1;
    assign o_timestamp      = {timestamp_high_reg, timestamp_low_reg};
    assign o_debug_marker   = timestamp_config_reg[8:1];

    assign timestamp_low_reg_wr_en = (reg_wr_en & reg_wr_strb & (reg_addr[ADDR_W-1:3] == ADDR_CSR_TIMESTAMP[ADDR_W-1:3]) && (reg_addr[2] == 1'b0));
    assign timestamp_low_reg_nxt  = timestamp_low_reg_wr_en ? reg_wr_data :
                                        timestamp_load      ? timestamp_sync_low_reg :
                                        i_time_tick         ? timestamp_nxt[31:0] :
                                                              timestamp_low_reg;
    tt_dfd_generic_dff #(.WIDTH(32), .RESET_VALUE(0)) timestamp_low_reg_ff   (.out(timestamp_low_reg), .in(timestamp_low_reg_nxt), .en(1'b1), .clk(i_clk), .rst_n(i_reset_n_warm));


    assign timestamp_high_reg_wr_en = (reg_wr_en & reg_wr_strb & (reg_addr[ADDR_W-1:3] == ADDR_CSR_TIMESTAMP[ADDR_W-1:3]) && (reg_addr[2] == 1'b1));
    assign timestamp_high_reg_nxt  = timestamp_high_reg_wr_en ? reg_wr_data :
                                        timestamp_load        ? timestamp_sync_high_reg :
                                        i_time_tick           ? timestamp_nxt[63:32] :
                                                                timestamp_high_reg;
    tt_dfd_generic_dff #(.WIDTH(32), .RESET_VALUE(0)) timestamp_high_reg_ff   (.out(timestamp_high_reg), .in(timestamp_high_reg_nxt), .en(1'b1), .clk(i_clk), .rst_n(i_reset_n_warm));


    assign timestamp_sync_low_reg_wr_en = (reg_wr_en & reg_wr_strb & (reg_addr[ADDR_W-1:3] == ADDR_CSR_TIMESTAMP_SYNC[ADDR_W-1:3]) && (reg_addr[2] == 1'b0));
    tt_dfd_generic_dff #(.WIDTH(32), .RESET_VALUE(0)) timestamp_sync_low_reg_ff   (.out(timestamp_sync_low_reg), .in(reg_wr_data), .en(timestamp_sync_low_reg_wr_en), .clk(i_clk), .rst_n(i_reset_n_warm));


    assign timestamp_sync_high_reg_wr_en = (reg_wr_en & reg_wr_strb & (reg_addr[ADDR_W-1:3] == ADDR_CSR_TIMESTAMP_SYNC[ADDR_W-1:3]) && (reg_addr[2] == 1'b1));
    tt_dfd_generic_dff #(.WIDTH(32), .RESET_VALUE(0)) timestamp_sync_high_reg_ff   (.out(timestamp_sync_high_reg), .in(reg_wr_data), .en(timestamp_sync_high_reg_wr_en), .clk(i_clk), .rst_n(i_reset_n_warm));


    assign timestamp_config_reg_wr_en = (reg_wr_en & reg_wr_strb & (reg_addr[ADDR_W-1:3] == ADDR_CSR_TIMESTAMP_CONFIG[ADDR_W-1:3]) && (reg_addr[2] == 1'b0));
    assign timestamp_config_reg_nxt   = timestamp_config_reg_wr_en  ? reg_wr_data :
                                        timestamp_load              ? {timestamp_config_reg[31:1],1'b0} :
                                                                      timestamp_config_reg;
    tt_dfd_generic_dff #(.WIDTH(32), .RESET_VALUE(0)) timestamp_config_reg_ff   (.out(timestamp_config_reg), .in(timestamp_config_reg_nxt), .en(1'b1), .clk(i_clk), .rst_n(i_reset_n_warm));


    // ready goes high 1 cycle after reg_hit
    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_wr_ready_ff       (.out(reg_wr_ready),  .in(reg_wr_en && reg_hit), .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));
    tt_dfd_generic_dff #(.WIDTH(1)           , .RESET_VALUE(0)) reg_rd_ready_ff       (.out(reg_rd_ready),  .in(reg_rd_en && reg_hit), .en(1'b1), .clk(i_clk), .rst_n(i_reset_n));

    // Register read logic
    always_comb begin
        reg_hit = 0;
        reg_rd_data = '0;
        case (reg_addr[ADDR_W-1:3])
            ADDR_CSR_TIMESTAMP[ADDR_W-1:3]:  begin
                reg_hit = 1;
                reg_rd_data = reg_addr[2] ? timestamp_high_reg : timestamp_low_reg;
            end
            ADDR_CSR_TIMESTAMP_SYNC[ADDR_W-1:3]: begin
                reg_hit = 1;
                reg_rd_data = reg_addr[2] ? timestamp_sync_high_reg : timestamp_sync_low_reg;
            end
            ADDR_CSR_TIMESTAMP_CONFIG[ADDR_W-1:3]:  begin
                reg_hit = 1;
                reg_rd_data = reg_addr[2] ? 32'h0 : timestamp_config_reg;
            end
            default: begin
                reg_hit = 0;
                reg_rd_data = '0;
            end
        endcase
    end

    // Timestamp logic

endmodule

