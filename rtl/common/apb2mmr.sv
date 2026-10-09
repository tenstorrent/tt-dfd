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

module apb2mmr
import ntr_sink_mmr_pkg::*;
import dst_sink_mmr_pkg::*;
#(
    parameter DATA_WIDTH = 64, // Must be multiple of 32
    parameter ADDR_WIDTH = 17,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = 0,
    localparam APB_STRB_WIDTH = DATA_WIDTH / 8, // APB byte strobe (pstrb)
    localparam STRB_WIDTH = 2,                  // MMR 4-byte-lane strobe (MmrWrStrb)
    parameter NUM_MMR_BLOCKS = 1
) (
    input  logic clk,
    input  logic reset_n,

    // APB
    input  logic [ADDR_WIDTH-1:0]  paddr,
    input  logic                   psel,
    input  logic                   penable,
    input  logic [APB_STRB_WIDTH -1:0] pstrb,
    input  logic                   pwrite,
    input  logic [DATA_WIDTH-1:0]  pwdata,
    output logic                   pready,
    output logic [DATA_WIDTH-1:0]  prdata,
    output logic                   pslverr,

    // MMR
    // Level request, held until the response; the one-hot block select is
    // decoded externally and the request is accepted once by mmr_req_ctrl.
    output  logic                   MmrCs,
    output  logic                   MmrWrEn,
    output  logic  [STRB_WIDTH-1:0] MmrWrStrb,
    output  logic  [12-1:0]         MmrAddr,
    output  logic  [DATA_WIDTH-1:0] MmrWrData,
    input   logic  [DATA_WIDTH-1:0] MmrRdData,
    // Counter-timed response from mmr_req_ctrl (never MmrHit: an access to an
    // unimplemented offset produces no hit and must still complete).
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

    //APB <<--> MMR interface
    assign int_MmrAddr = paddr[12-1:0];
    assign int_MmrWrEn = pwrite;
    assign int_MmrWrData = pwdata;
    assign prdata = MmrRdData;
    assign paddr_base = paddr & {{(ADDR_WIDTH-12){1'b1}}, 12'h0};

    // Decode miss: a valid access targeting an address outside the mapped MMR
    // region [BASE_ADDR, MMR_END_ADDR) selects no block, so it must be
    // completed with a slave error rather than left to hang.
    logic decode_miss;
    assign decode_miss = psel && penable
                       && ~((paddr_base >= (ADDR_WIDTH)'(BASE_ADDR))
                         &&  (paddr_base <  (ADDR_WIDTH)'(MMR_END_ADDR)));

    assign pready = (psel && penable && rsp_vld);

    // Level request, asserted from the setup phase until the transfer
    // completes.  A single-cycle setup pulse cannot be back-pressured, so it
    // would be dropped whenever the fabric is busy; holding it lets
    // mmr_req_ctrl accept the request when it is ready.
    assign int_MmrCs = psel && ~pready;

    assign pslverr = psel && penable && pready &&(rsp_err || decode_miss);

    always_comb begin
        int_MmrWrStrb = '0;
        for (int ii = 0; ii < DATA_WIDTH / 32; ii++) begin
            int_MmrWrStrb[ii] = &(pstrb[ii*4+:4]);
        end
    end

    // MmrRegSel, MmrWrStrb8B and MmrWrInstrType are derived centrally in
    // mmrs.sv from the request held by mmr_req_ctrl, so they are no longer
    // driven per-interface here.
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
