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

module dfd_apb2mmr
import dfd_tr_csr_pkg::*;
#(
    parameter BASE_ADDR = 23'h0,
    parameter DATA_WIDTH = 64, // Must be multiple of 32
    parameter APB_ADDR_WIDTH = 23,
    parameter MMR_ADDR_WIDTH = 23,
    localparam APB_STRB_WIDTH = DATA_WIDTH / 8,
    parameter STRB_WIDTH = 2,
    parameter INST_WIDTH = 2
) (
    input  logic clk,
    input  logic reset_n,

    // APB
    input  logic [APB_ADDR_WIDTH-1:0]  paddr,
    input  logic                   psel,
    input  logic                   penable,
    input  logic [APB_STRB_WIDTH -1:0] pstrb,
    input  logic                   pwrite,
    input  logic [DATA_WIDTH-1:0]  pwdata,
    output logic                   pready,
    output logic [DATA_WIDTH-1:0]  prdata,
    output logic                   pslverr,

    // MMR
    output  logic                   CsrCs,
    output  logic                   CsrWrEn,
    output  logic  [STRB_WIDTH-1:0] CsrWrStrb,
    output  logic  [STRB_WIDTH-1:0] CsrWrStrb8B, // For 8B Csrs
    output  logic                   CsrRegSel,
    output  logic  [MMR_ADDR_WIDTH-1:0] CsrAddr,
    output  logic  [DATA_WIDTH-1:0] CsrWrData,
    output  logic  [INST_WIDTH-1:0] CsrWrInstrType,
    input   logic                   CsrHit,
    input   logic  [DATA_WIDTH-1:0] CsrRdData,
    input   logic                   CsrError
);

    logic                                     CsrError_d1;

    logic                                     trRamDataRdEn_ANY;
    logic                                     trdstRamDataRdEn_ANY;
    logic                                     apb_delay, apb_delay_d1;

    // Read data takes 3 cycles to be reflected on the `trramdata` register
    //  - Cycle 1 -> Set-up SRAM read enables, prioritize writes
    //  - Cycle 2 -> SRAM data available and set-up write to trramdata
    //  - Cycle 3 -> trramdata read data is now available
    assign apb_delay = psel && ~penable && ~pwrite &&
                       ((paddr == (BASE_ADDR + TR_TRRAMDATA_REG_OFFSET)) || (paddr == (BASE_ADDR + TR_TRDSTRAMDATA_REG_OFFSET)));

    generic_dff #(.WIDTH(1), .RESET_VALUE(1'b0), .BYPASS(0)) u_apb_delay (
        .clk(clk),
        .rst_n(reset_n),
        .en(1'b1),
        .in(apb_delay),
        .out(apb_delay_d1)
    );

    //APB <<--> CSR interface
    logic reg_xfer, reg_xfer_d1, reg_xfer_mux;
    assign CsrWrInstrType = {INST_WIDTH{1'b0}};
    assign reg_xfer = (psel && ~penable && ~apb_delay) || apb_delay_d1; // End of Setup Phase
    assign CsrAddr = paddr[MMR_ADDR_WIDTH-1:0];
    assign CsrCs = reg_xfer;
    assign CsrRegSel = reg_xfer && pwrite;
    assign CsrWrEn = pwrite;
    assign CsrWrData = pwdata;
    assign prdata = CsrRdData;

    assign pslverr = (pready && ~CsrHit) || CsrError; // FIXME: Check with PD if this will make timing

    always_comb begin
        CsrWrStrb = '0;
        for (int ii = 0; ii < DATA_WIDTH / 32; ii++) begin
            CsrWrStrb[ii] = &(pstrb[ii*4+:4]);
        end
    end

    if (DATA_WIDTH <= 32) begin : gen_wstrb_8b_d32
        assign CsrWrStrb8B = (CsrAddr[2] == 1'b0) ? {1'b0, CsrWrStrb[0]}: {CsrWrStrb[0], 1'b0} ;
    end else begin : gen_wstrb_8b_d64
        assign CsrWrStrb8B = CsrWrStrb;
    end

    generic_dff #(.WIDTH(1), .RESET_VALUE(1'b0), .BYPASS(0)) u_dff_pready (
        .clk(clk),
        .rst_n(reset_n),
        .en(1'b1),
        .in(reg_xfer_d1),
        .out(pready)
    );

    generic_dff #(.WIDTH(1), .RESET_VALUE(1'b0), .BYPASS(0)) u_dff_reg_xfer_d1 (
        .clk(clk),
        .rst_n(reset_n),
        .en(1'b1),
        .in(reg_xfer),
        .out(reg_xfer_d1)
    );


endmodule

