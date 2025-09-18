// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 17/07/2017
// Description: AXI Lite compatible interface
//

// Louis notes:
// This file is modified upon open source file: https://aus-gitlab.local.tenstorrent.com/riscv/forks/cva6/-/blob/master/corev_apu/clint/axi_lite_interface.sv
// It is used as an AXI slave interface, it does: 

// This open source module is used as an AXI master module, it does: 
// Receive R/W req from Register bus
// Send Write Req:...
// ...

// FIXME_MUSTFIX_BABYLON: Lack id allocation logic... Lack Read request generated logic.. Lack Register Bus connection to MMR...  
// Don't forget to assign w_user = aw.id
// Is this Request a Write request or Read request?
// care about write request now

// need to keep track of the in-flight transactions? or error out 


module dfd_trace_axi_master #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 9,
    parameter int unsigned AXI_SRCID_WIDTH=  5,     // Axi Source ID portion Width
    parameter int unsigned AXI_TXID_WIDTH =  4,     // Axi Transaction ID portion Width
    parameter type         axi_req_t      = logic,
    parameter type         axi_resp_t     = logic
) (
    input   logic                           clk_i,
    input   logic                           rst_ni,
    input   logic  [AXI_SRCID_WIDTH-1:0]    id_i,      //Src ID
    output  axi_req_t                       axi_req_o, //AXI Bus
    input   axi_resp_t                      axi_resp_i,//AXI Bus
    input   logic                           valid_i,   //Register Bus : if the request from the register bus is valid 
    input   logic   [AXI_ADDR_WIDTH-1:0]    addr_i,    //Register Bus
    input   logic   [AXI_DATA_WIDTH-1:0]    data_i,    //Register Bus 
    output  logic                           ready_o    //Register Bus : if the master interface is ready to receive request
);

    // generate and assign tx id for each tx using a counter
    logic   [AXI_TXID_WIDTH-1:0]    tx_id;
    logic     [AXI_ID_WIDTH-1:0]    axi_id;

    // always_ff @(posedge clk_i) begin
    //     if (~rst_ni) begin
    //         tx_id <= '0;
    //     end else if (valid_i) begin
    //         tx_id <= tx_id + 1'b1;
    //     end
    // end

    generic_dff #(.WIDTH(AXI_TXID_WIDTH), .RESET_VALUE(0)) tx_id_ff (
        .out          (tx_id),
        .in          ($bits(tx_id)'(tx_id + 1'b1)), 
        .en         (valid_i),
        .clk        (clk_i),
        .rst_n    (rst_ni)
    );

    assign axi_id = {id_i, tx_id};

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

    generic_dff #(.WIDTH($bits(state_t)), .RESET_VALUE(AWAIT_REQUEST)) state_ff (
        .out          ({state}),
        .in          (next_state), 
        .en         (1'b1),
        .clk        (clk_i),
        .rst_n    (rst_ni)
    );
    
    generic_dff #(.WIDTH(1), .RESET_VALUE(1)) ready_o_ff (
        .out          (ready_o),
        .in          (next_ready_o), 
        .en         (1'b1),
        .clk        (clk_i),
        .rst_n    (rst_ni)
    );

    generic_dff #(.WIDTH($bits(axi_req_t)), .RESET_VALUE(0)) axi_req_o_ff (
        .out          (axi_req_o),
        .in          (next_axi_req_o), 
        .en         (1'b1),
        .clk        (clk_i),
        .rst_n    (rst_ni)
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
                next_axi_req_o.aw.size   = 3'b110; // 64-bytes Transfer
                next_axi_req_o.aw.addr   = $bits(next_axi_req_o.aw.addr)'(addr_i);
                next_axi_req_o.aw.prot   = 3'b010;
                next_axi_req_o.w.data    = data_i;
                next_axi_req_o.w.last    = 1'b1;
                next_axi_req_o.w.strb    = '1; // Write only full 64-byte transfer
                next_axi_req_o.w.user    = $bits(next_axi_req_o.w.user)'(axi_id);
                // next_axi_req_o.b_ready   = 1'b1;
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
                    // next_axi_req_o.b_ready   = 1'b1;
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
            //FIXME_MUSTFIX_BABYLON: Suppose b_ready always asserted...
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

    // always_ff @(posedge clk_i) begin
    //     if (~rst_ni) begin
    //         state           <= AWAIT_REQUEST;
    //         ready_o         <= 1'b1;

    //         axi_req_o   <= '0; 
    //     end 
    //     else begin
    //         case (state)
    //             AWAIT_REQUEST: begin
    //                 if (valid_i) begin
    //                     state               <= REQ_HANDSHAKE;
    //                     ready_o             <= 1'b0;
    //                     axi_req_o.aw_valid  <= 1'b1;
    //                     axi_req_o.w_valid   <= 1'b1;
    //                 end
    //                 axi_req_o.aw.id     <= axi_id;
    //                 axi_req_o.aw.size   <= 3'b110; // 64-bytes Transfer
    //                 axi_req_o.aw.addr   <= $bits(axi_req_o.aw.addr)'(addr_i);
    //                 axi_req_o.aw.prot   <= '0;
    //                 axi_req_o.w.data    <= data_i;
    //                 axi_req_o.w.last    <= 1'b1;
    //                 axi_req_o.w.strb    <= '1; // Write only full 64-byte transfer
    //                 axi_req_o.w.user    <= $bits(axi_req_o.w.user)'(axi_id);
    //                 // axi_req_o.b_ready   <= 1'b1;
    //             end
    //             REQ_HANDSHAKE: begin
    //                 if (axi_resp_i.aw_ready & axi_resp_i.w_ready) begin
    //                     state               <= RESP_HANDSHAKE;
    //                     axi_req_o.aw_valid  <= 1'b0;
    //                     axi_req_o.aw.id     <= '0;
    //                     axi_req_o.aw.addr   <= '0;
    //                     axi_req_o.aw.prot   <= '0;
    //                     axi_req_o.w_valid   <= 1'b0;
    //                     axi_req_o.w.data    <= '0;
    //                     axi_req_o.w.last    <= 1'b0;
    //                     axi_req_o.w.strb    <= '0;
    //                     axi_req_o.w.user    <= '0;
    //                     axi_req_o.b_ready   <= 1'b1;
    //                 end
    //                 else if (axi_resp_i.aw_ready & ~axi_resp_i.w_ready) begin
    //                     state               <= AW_HANDSHAKE;
    //                     axi_req_o.aw_valid  <= 1'b0;
    //                     axi_req_o.aw.id     <= '0;
    //                     axi_req_o.aw.addr   <= '0;
    //                     axi_req_o.aw.prot   <= '0; 
    //                 end
    //                 else if (~axi_resp_i.aw_ready & axi_resp_i.w_ready) begin
    //                     state               <= W_HANDSHAKE;
    //                     axi_req_o.w_valid   <= 1'b0;
    //                     axi_req_o.w.data    <= '0;
    //                     axi_req_o.w.last    <= 1'b0;
    //                     axi_req_o.w.strb    <= '0;
    //                     axi_req_o.w.user    <= '0;
    //                     // axi_req_o.b_ready   <= 1'b1;
    //                 end
    //             end
    //             AW_HANDSHAKE: begin
    //                 if (axi_resp_i.w_ready) begin
    //                     state               <= RESP_HANDSHAKE;
    //                     axi_req_o.w_valid   <= 1'b0;
    //                     axi_req_o.w.data    <= '0;
    //                     axi_req_o.w.last    <= 1'b0;
    //                     axi_req_o.w.strb    <= '0;
    //                     axi_req_o.w.user    <= '0;
    //                     axi_req_o.b_ready   <= 1'b1;
    //                 end 
    //             end
    //             W_HANDSHAKE: begin
    //                 if (axi_resp_i.aw_ready) begin
    //                     state               <= RESP_HANDSHAKE;
    //                     axi_req_o.aw_valid  <= 1'b0;
    //                     axi_req_o.aw.id     <= '0;
    //                     axi_req_o.aw.addr   <= '0;
    //                     axi_req_o.aw.prot   <= '0;
    //                     axi_req_o.b_ready   <= 1'b1;
    //                 end 
    //             end
    //             RESP_HANDSHAKE: begin
    //                 if (axi_resp_i.b_valid) begin
    //                     state               <= AWAIT_REQUEST;
    //                     ready_o             <= 1'b1;
    //                     axi_req_o.b_ready   <= 1'b0;
    //                 end
    //             end
    //             default: begin
    //                 state           <= AWAIT_REQUEST;
    //                 ready_o         <= 1'b1;

    //                 axi_req_o       <= '0; 
    //             end
    //         endcase
    //     end
    // end
endmodule

