// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
module apb2mmr
import ntr_sink_mmr_pkg::*;
import dst_sink_mmr_pkg::*;
#(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 17,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = 0,
    localparam APB_STRB_WIDTH = DATA_WIDTH / 8,
    localparam STRB_WIDTH = 2,
    parameter NUM_MMR_BLOCKS = 1
) (
    input  logic clk,
    input  logic reset_n,

    input  logic [ADDR_WIDTH-1:0]  paddr,
    input  logic                   psel,
    input  logic                   penable,
    input  logic [APB_STRB_WIDTH -1:0] pstrb,
    input  logic                   pwrite,
    input  logic [DATA_WIDTH-1:0]  pwdata,
    output logic                   pready,
    output logic [DATA_WIDTH-1:0]  prdata,
    output logic                   pslverr,

    output  logic                   MmrCs,
    output  logic                   MmrWrEn,
    output  logic  [STRB_WIDTH-1:0] MmrWrStrb,
    output  logic  [12-1:0]         MmrAddr,
    output  logic  [DATA_WIDTH-1:0] MmrWrData,
    input   logic  [DATA_WIDTH-1:0] MmrRdData,

    input   logic                   rsp_vld,
    input   logic                   rsp_err
);

    localparam [ADDR_WIDTH-1:0] MMR_END_ADDR = (ADDR_WIDTH)'(BASE_ADDR) + ((ADDR_WIDTH)'(NUM_MMR_BLOCKS) << 12);

    logic [ADDR_WIDTH-1:0]                paddr_base;
    logic int_MmrCs;
    logic int_MmrWrEn;
    logic [12-1:0] int_MmrAddr;
    logic [DATA_WIDTH-1:0] int_MmrWrData;
    logic [STRB_WIDTH-1:0] int_MmrWrStrb;

    assign int_MmrAddr = paddr[12-1:0];
    assign int_MmrWrEn = pwrite;
    assign int_MmrWrData = pwdata;
    assign prdata = MmrRdData;
    assign paddr_base = paddr & {{(ADDR_WIDTH-12){1'b1}}, 12'h0};

    logic decode_miss;
    assign decode_miss = psel && penable
                       && ~((paddr_base >= (ADDR_WIDTH)'(BASE_ADDR))
                         &&  (paddr_base <  (ADDR_WIDTH)'(MMR_END_ADDR)));

    assign pready = (psel && penable && rsp_vld);

    assign int_MmrCs = psel && ~pready;

    assign pslverr = psel && penable && pready &&(rsp_err || decode_miss);

    always_comb begin
        int_MmrWrStrb = '0;
        for (int ii = 0; ii < DATA_WIDTH / 32; ii++) begin
            int_MmrWrStrb[ii] = &(pstrb[ii*4+:4]);
        end
    end

    always_comb begin
        if (~reset_n) begin
            MmrCs = '0;
            MmrWrEn = '0;
            MmrWrStrb = '0;
            MmrAddr = '0;
            MmrWrData = '0;
        end else begin
            MmrCs = int_MmrCs;
            MmrWrEn = int_MmrWrEn;
            MmrWrStrb = int_MmrWrStrb;
            MmrAddr = int_MmrAddr;
            MmrWrData = int_MmrWrData;
        end
    end

endmodule
