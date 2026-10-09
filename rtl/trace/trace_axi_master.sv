// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module trace_axi_master #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 9,
    parameter int unsigned AXI_SRCID_WIDTH=  5,
    parameter int unsigned AXI_TXID_WIDTH =  4,
    parameter type         axi_req_t      = logic,
    parameter type         axi_resp_t     = logic
) (
    input   logic                           clk_i,
    input   logic                           rst_ni,
    input   logic  [AXI_SRCID_WIDTH-1:0]    id_i,
    output  axi_req_t                       axi_req_o,
    input   axi_resp_t                      axi_resp_i,
    input   logic                           valid_i,
    input   logic   [AXI_ADDR_WIDTH-1:0]    addr_i,
    input   logic   [AXI_DATA_WIDTH-1:0]    data_i,
    output  logic                           ready_o
);

    logic   [AXI_TXID_WIDTH-1:0]    tx_id;
    logic     [AXI_ID_WIDTH-1:0]    axi_id;

    generic_dff #(
        .WIDTH       ($bits(logic [AXI_TXID_WIDTH-1:0])),
        .RESET_VALUE ('0)
    ) tx_id_ff (
        .clk   (clk_i),
        .rst_n (rst_ni),
        .en    (valid_i),
        .in    ($bits(tx_id)'(tx_id + 1'b1)),
        .out   (tx_id)
    );

    assign axi_id = AXI_ID_WIDTH'({id_i, tx_id});

    typedef enum logic [2:0] {
        AWAIT_REQUEST,
        REQ_HANDSHAKE,
        AW_HANDSHAKE,
        W_HANDSHAKE,
        RESP_HANDSHAKE
    } state_t;

    state_t state, next_state;
    logic next_ready_o;
    axi_req_t next_axi_req_o;

    generic_dff #(
        .WIDTH       ($bits(state_t)),
        .RESET_VALUE (AWAIT_REQUEST)
    ) state_ff (
        .clk   (clk_i),
        .rst_n (rst_ni),
        .en    ('1),
        .in    (next_state),
        .out   (state)
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('1)
    ) ready_o_ff (
        .clk   (clk_i),
        .rst_n (rst_ni),
        .en    ('1),
        .in    (next_ready_o),
        .out   (ready_o)
    );
    generic_dff #(
        .WIDTH       ($bits(axi_req_t)),
        .RESET_VALUE ('0)
    ) axi_req_o_ff (
        .clk   (clk_i),
        .rst_n (rst_ni),
        .en    ('1),
        .in    (next_axi_req_o),
        .out   (axi_req_o)
    );

    always_comb begin
        next_state           = state;
        next_ready_o         = ready_o;
        next_axi_req_o       = axi_req_o;

        case (state)
            AWAIT_REQUEST: begin
                if (valid_i) begin
                    next_state               = REQ_HANDSHAKE;
                    next_ready_o             = 1'b0;
                    next_axi_req_o.aw_valid  = 1'b1;
                    next_axi_req_o.w_valid   = 1'b1;
                end
                next_axi_req_o.aw.id     = axi_id;
                next_axi_req_o.aw.size   = 3'b110;
                next_axi_req_o.aw.addr   = $bits(next_axi_req_o.aw.addr)'(addr_i);
                next_axi_req_o.aw.prot   = 3'b010;
                next_axi_req_o.w.data    = data_i;
                next_axi_req_o.w.last    = 1'b1;
                next_axi_req_o.w.strb    = '1;
                next_axi_req_o.w.user    = $bits(next_axi_req_o.w.user)'(axi_id);

            end
            REQ_HANDSHAKE: begin
                if (axi_resp_i.aw_ready & axi_resp_i.w_ready) begin
                    next_state               = RESP_HANDSHAKE;
                    next_axi_req_o.aw_valid  = 1'b0;
                    next_axi_req_o.aw.id     = '0;
                    next_axi_req_o.aw.addr   = '0;
                    next_axi_req_o.aw.prot   = 3'b010;
                    next_axi_req_o.w_valid   = 1'b0;
                    next_axi_req_o.w.data    = '0;
                    next_axi_req_o.w.last    = 1'b0;
                    next_axi_req_o.w.strb    = '0;
                    next_axi_req_o.w.user    = '0;
                    next_axi_req_o.b_ready   = 1'b1;
                end
                else if (axi_resp_i.aw_ready & ~axi_resp_i.w_ready) begin
                    next_state               = AW_HANDSHAKE;
                    next_axi_req_o.aw_valid  = 1'b0;
                    next_axi_req_o.aw.id     = '0;
                    next_axi_req_o.aw.addr   = '0;
                    next_axi_req_o.aw.prot   = 3'b010;
                end
                else if (~axi_resp_i.aw_ready & axi_resp_i.w_ready) begin
                    next_state               = W_HANDSHAKE;
                    next_axi_req_o.w_valid   = 1'b0;
                    next_axi_req_o.w.data    = '0;
                    next_axi_req_o.w.last    = 1'b0;
                    next_axi_req_o.w.strb    = '0;
                    next_axi_req_o.w.user    = '0;

                end
            end
            AW_HANDSHAKE: begin
                if (axi_resp_i.w_ready) begin
                    next_state               = RESP_HANDSHAKE;
                    next_axi_req_o.w_valid   = 1'b0;
                    next_axi_req_o.w.data    = '0;
                    next_axi_req_o.w.last    = 1'b0;
                    next_axi_req_o.w.strb    = '0;
                    next_axi_req_o.w.user    = '0;
                    next_axi_req_o.b_ready   = 1'b1;
                end
            end
            W_HANDSHAKE: begin
                if (axi_resp_i.aw_ready) begin
                    next_state               = RESP_HANDSHAKE;
                    next_axi_req_o.aw_valid  = 1'b0;
                    next_axi_req_o.aw.id     = '0;
                    next_axi_req_o.aw.addr   = '0;
                    next_axi_req_o.aw.prot   = 3'b010;
                    next_axi_req_o.b_ready   = 1'b1;
                end
            end
            RESP_HANDSHAKE: begin
                if (axi_resp_i.b_valid) begin
                    next_state               = AWAIT_REQUEST;
                    next_ready_o             = 1'b1;
                    next_axi_req_o.b_ready   = 1'b0;
                end
            end
            default: begin
                next_state           = AWAIT_REQUEST;
                next_ready_o         = 1'b1;
                next_axi_req_o       = '0;
            end
        endcase
    end

endmodule
