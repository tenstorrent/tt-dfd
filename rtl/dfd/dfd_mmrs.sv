// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

/*
    The register memory map is as follows:

    MCR (Master Config Registers) - 0x0000 - 0x0FFF
    CLA (Core Logic Analyzer)     - 0x1000 - 0x1FFF
    DST (Debug Signal Trace)      - 0x2000 - 0x2FFF
    NTR (Nexus Trace)             - 0x3000 - 0x3FFF
    TR  (Trace Funnel)            - 0x4000 - 0x8FFF

    Some modules such as CLA, DST, and NTR have multiple MMR instances depending
    on the number of NUM_TRACE_AND_ANALYZER_INST defined.

    The base address of each ADDITIONAL instance is base address of module +
    + 0x9000 * (additional instance #).

    For example, instance 1 and 2 of DST is
    DST Instance 1 : 0x2000 + 0x9000 * 1 = 0xB000
    DST Instance 2 : 0x2000 + 0x9000 * 2 = 0x14000

    Modules that are not replicated use the original base address
*/

module dfd_mmrs
import dfd_pkg::*;
import dfd_cla_csr_pkg::*;
import dfd_tr_csr_pkg::*;
import dfd_mcr_csr_pkg::*;
import dfd_ntr_csr_pkg::*;
import dfd_dst_csr_pkg::*;
#(
    parameter INTERNAL_MMRS = 1,
    parameter NTRACE_SUPPORT = 1,
    parameter DST_SUPPORT = 1,
    parameter CLA_SUPPORT = 1,
    parameter NUM_TRACE_AND_ANALYZER_INST = 1,
    parameter BASE_ADDR = 23'h0,
    parameter TRC_SIZE_IN_B = 32'h8000
) (
    input logic        clk,
    input logic        reset_n,
    input logic        reset_n_warm_ovrride,
    input logic        cold_reset_n,

    // dfd_mmr & modules interface
    // verilint W240 off
    output DfdCsrs_s   DfdCsrs,
    input  DfdCsrsWr_s DfdCsrsWr,

    // external MMR flatbus (Used if INTERNAL_MMRS == 0)
    input  DfdCsrs_s   DfdCsrs_external,
    output DfdCsrsWr_s DfdCsrsWr_external,
    // verilint W240 off

    // APB Interface (Used if INTERNAL_MMRS == 1)
    input  logic [DFD_APB_ADDR_WIDTH-1:0]   paddr,
    input  logic                            psel,
    input  logic                            penable,
    input  logic [DFD_APB_PSTRB_WIDTH-1:0]  pstrb,
    input  logic                            pwrite,
    input  logic [DFD_APB_DATA_WIDTH-1:0]   pwdata,
    output logic                            pready,
    output logic [DFD_APB_DATA_WIDTH-1:0]   prdata,
    output logic                            pslverr
);

    if (INTERNAL_MMRS) begin : gen_internal_mmrs_blk
        assign DfdCsrsWr_external = '0;

        // APB to MMR Signals
        logic                         			  CsrCs;
        logic                         			  CsrWrEn;
        logic 							  [2-1:0] CsrWrStrb;
        logic 							  [2-1:0] CsrWrStrb8B;
        logic                         			  CsrRegSel;
        logic        		  			  [2-1:0] CsrWrInstrType;
        logic            [DFD_APB_ADDR_WIDTH-1:0] CsrAddr;
        logic            [DFD_APB_ADDR_WIDTH-1:0] CsrAddr8B; // 8 Byte Aligned
        logic            [DFD_APB_DATA_WIDTH-1:0] CsrWrData;
        logic                            [64-1:0] CsrWrData8B;

        logic                 			          CsrHit;
        logic            [DFD_APB_DATA_WIDTH-1:0] CsrRdData;
        logic 									  CsrError_n;

        // MCR (8B)
        logic                                    CsrHit_MCR;
        logic           [DFD_APB_DATA_WIDTH-1:0] CsrRdData_MCR;
        logic                           [64-1:0] CsrRdData8B_MCR;

        // DST
        logic                          [NUM_TRACE_AND_ANALYZER_INST-1:0] CsrHit_DST;
        logic  [NUM_TRACE_AND_ANALYZER_INST-1:0][DFD_APB_DATA_WIDTH-1:0] CsrRdData_DST;

        // NTR
        logic                          [NUM_TRACE_AND_ANALYZER_INST-1:0] CsrHit_NTR;
        logic  [NUM_TRACE_AND_ANALYZER_INST-1:0][DFD_APB_DATA_WIDTH-1:0] CsrRdData_NTR;

        // CLA (8B)
        logic                          [NUM_TRACE_AND_ANALYZER_INST-1:0] CsrHit_CLA;
        logic  [NUM_TRACE_AND_ANALYZER_INST-1:0][DFD_APB_DATA_WIDTH-1:0] CsrRdData_CLA;
        logic                  [NUM_TRACE_AND_ANALYZER_INST-1:0][64-1:0] CsrRdData8B_CLA;

        // TR
        logic                                    CsrHit_TR;
        logic           [DFD_APB_DATA_WIDTH-1:0] CsrRdData_TR;

        assign CsrAddr8B   = {CsrAddr[DFD_APB_ADDR_WIDTH-1:3], 3'b000};
        assign CsrWrData8B = {(64/DFD_APB_DATA_WIDTH){CsrWrData}};


        assign CsrHit = |{CsrHit_CLA, CsrHit_DST, CsrHit_NTR, CsrHit_MCR, CsrHit_TR};

		generic_decoded_mux #(
			.DISABLE_ASSERTIONS(0),
			.VALUE_WIDTH(DFD_APB_DATA_WIDTH),
			.MUX_WIDTH(2+3*NUM_TRACE_AND_ANALYZER_INST)
		) u_csrrddata_mux (
			.clk      (clk),
			.rst_n  (reset_n),
			.en   (CsrHit),
			.in   ({CsrRdData_CLA,CsrRdData_DST,CsrRdData_NTR,CsrRdData_MCR, CsrRdData_TR}),
			.sel   ({CsrHit_CLA, CsrHit_DST, CsrHit_NTR, CsrHit_MCR, CsrHit_TR}),
			.out   (CsrRdData)
		);

		generic_onehot_detect #(.WIDTH(2+3*NUM_TRACE_AND_ANALYZER_INST), .ZERO_ONEHOT(1)) u_csrerror_det (
			.in   ({CsrHit_CLA, CsrHit_DST, CsrHit_NTR, CsrHit_MCR, CsrHit_TR}),
			.out         (CsrError_n)
		);

		dfd_apb2mmr #(
            .BASE_ADDR(BASE_ADDR),
			.DATA_WIDTH(DFD_APB_DATA_WIDTH),
			.APB_ADDR_WIDTH(DFD_APB_ADDR_WIDTH),
            .MMR_ADDR_WIDTH(DFD_APB_ADDR_WIDTH),
			.INST_WIDTH(2)
		) u_dfd_apb2mmr (
			.clk        (clk),
			.reset_n    (reset_n),
            .paddr      (paddr),
            .psel       (psel),
            .penable    (penable),
            .pstrb      (pstrb),
            .pwrite     (pwrite),
            .pwdata     (pwdata),
            .pready     (pready),
            .prdata     (prdata),
            .pslverr    (pslverr),
			.CsrCs      (CsrCs),
			.CsrWrEn    (CsrWrEn),
			.CsrWrStrb  (CsrWrStrb),
            .CsrWrStrb8B(CsrWrStrb8B),
			.CsrRegSel  (CsrRegSel),
			.CsrAddr    (CsrAddr),
			.CsrWrData  (CsrWrData),
			.CsrWrInstrType(CsrWrInstrType),
			.CsrHit     (CsrHit),
			.CsrRdData  (CsrRdData),
			.CsrError   (~CsrError_n)
		);

        assign CsrRdData_MCR = (CsrAddr[2] == 1'b0) ? CsrRdData8B_MCR[31:0] : CsrRdData8B_MCR[63:32];

        dfd_mcr_csr #(
            .BASE_ADDR(BASE_ADDR),
            .ADDR_W(DFD_APB_ADDR_WIDTH)
        ) u_dfd_top_mmr (
			.clk        (clk),
			.reset_n    (reset_n),
            .reset_n_warm_ovrride(reset_n_warm_ovrride),
			.CsrCs      (CsrCs),
			.CsrWrEn    (CsrWrEn),
            .CsrWrStrb  (CsrWrStrb8B),
            .CsrRegSel  (CsrRegSel),
			.CsrAddr    (CsrAddr8B),
			.CsrWrData  (CsrWrData8B),
			.CsrWrInstrType(CsrWrInstrType),
			.CsrWrReady (),
			.CsrHit     (CsrHit_MCR),
            .CsrHitList (),
			.CsrRdData  (CsrRdData8B_MCR),
			.CrCsrCdbgmuxsel(DfdCsrs.McrCsrs.CrCsrCdbgmuxsel),
            .CrCsrCdfdcsr(DfdCsrs.McrCsrs.CrCsrCdfdcsr),
            .CsrUpdateEn(),
            .CsrUpdateAddr(),
            .CsrUpdateData()
		);

        if (NTRACE_SUPPORT) begin : ntr_csr_gen_blk
            for (genvar ii = 0; ii < MAX_NUM_TRACE_INST; ii++) begin : ntr_csr_inst
                if (ii < NUM_TRACE_AND_ANALYZER_INST) begin
                    dfd_ntr_csr #(
                        .BASE_ADDR  (BASE_ADDR + 23'h9000 * ii),
                        .ADDR_W     (DFD_APB_ADDR_WIDTH)
                    ) u_ntr_csr (
                        .clk                        (clk),
                        .reset_n                    (reset_n),
                        .CsrCs                      (CsrCs),
                        .CsrWrEn                    (CsrWrEn),
                        .CsrWrStrb                  (CsrWrStrb),
                        .CsrRegSel                  (CsrRegSel),
                        .CsrAddr                    (CsrAddr),
                        .CsrWrData                  (CsrWrData),
                        .CsrWrInstrType             (CsrWrInstrType),
                        .CsrWrReady                 (), // Unused
                        .CsrHit                     (CsrHit_NTR[ii]),
                        .CsrHitList                 (), // Unused
                        .CsrRdData                  (CsrRdData_NTR[ii]),
                        .Cr4BCsrTrtecontrol			(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrtecontrol),
                        .Cr4BCsrTrtscontrol			(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrtscontrol),
                        .Cr4BCsrTrteimpl			(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrteimpl),
                        .Cr4BCsrTrteinstfeatures	(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrteinstfeatures),
                        .Cr4BCsrTrteinstfilters		(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrteinstfilters),
                        .Cr4BCsrTrtefilter0Control	(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrtefilter0Control),
                        .Cr4BCsrTrtefilter0Matchinst(DfdCsrs.NtrCsrs[ii].Cr4BCsrTrtefilter0Matchinst),
                        .Cr4BCsrCdbgntraceframecfg	(DfdCsrs.NtrCsrs[ii].Cr4BCsrCdbgntraceframecfg),
                        .Cr4BCsrTrtecontrolWr		(DfdCsrsWr.NtrCsrsWr[ii].Cr4BCsrTrtecontrolWr),
                        .CsrUpdateEn                (),
                        .CsrUpdateAddr              (),
                        .CsrUpdateData              ()
                    );
                end else begin
                    assign DfdCsrs.NtrCsrs[ii] = '0;
                end
            end
        end else begin : no_ntr_csr_gen_blk
            assign DfdCsrs.NtrCsrs = '0;
            assign CsrHit_NTR = '0;
            assign CsrRdData_NTR = '0;
        end

        if (DST_SUPPORT) begin : dst_csr_gen_blk
            for (genvar ii = 0; ii < MAX_NUM_TRACE_INST; ii++) begin : dst_csr_inst
                if (ii < NUM_TRACE_AND_ANALYZER_INST) begin
                    dfd_dst_csr #(
                        .BASE_ADDR  (BASE_ADDR + 23'h9000 * ii),
                        .ADDR_W     (DFD_APB_ADDR_WIDTH)
                    ) u_dst_csr (
                        .clk                        (clk),
                        .reset_n                    (reset_n),
                        .CsrCs                      (CsrCs),
                        .CsrWrEn                    (CsrWrEn),
                        .CsrWrStrb                  (CsrWrStrb),
                        .CsrRegSel                  (CsrRegSel),
                        .CsrAddr                    (CsrAddr),
                        .CsrWrData                  (CsrWrData),
                        .CsrWrInstrType             (CsrWrInstrType),
                        .CsrWrReady                 (), // Unused
                        .CsrHit                     (CsrHit_DST[ii]),
                        .CsrHitList                 (), // Unused
                        .CsrRdData                  (CsrRdData_DST[ii]),
                        .Cr4BCsrTrdstcontrol        (DfdCsrs.DstCsrs[ii].Cr4BCsrTrdstcontrol),
                        .Cr4BCsrTrdstimpl           (DfdCsrs.DstCsrs[ii].Cr4BCsrTrdstimpl),
                        .Cr4BCsrTrdstinstfeatures   (DfdCsrs.DstCsrs[ii].Cr4BCsrTrdstinstfeatures),
                        .Cr4BCsrCdbgdebugtracecfg   (DfdCsrs.DstCsrs[ii].Cr4BCsrCdbgdebugtracecfg),
                        .Cr4BCsrTrdstcontrolWr      (DfdCsrsWr.DstCsrsWr[ii].Cr4BCsrTrdstcontrolWr),
                        .CsrUpdateEn                (),
                        .CsrUpdateAddr              (),
                        .CsrUpdateData              ()
                    );
                end else begin
                    assign DfdCsrs.DstCsrs[ii] = '0;
                end
            end
        end else begin : no_dst_csr_gen_blk
            assign DfdCsrs.DstCsrs = '0;
            assign CsrHit_DST = '0;
            assign CsrRdData_DST = '0;
        end

        if (CLA_SUPPORT) begin : cla_csr_gen_blk
            for (genvar ii = 0; ii < MAX_NUM_TRACE_INST; ii++) begin : cla_csr_inst

                if (ii < NUM_TRACE_AND_ANALYZER_INST) begin
                    assign CsrRdData_CLA[ii] = (CsrAddr[2] == 1'b0) ? CsrRdData8B_CLA[ii][31:0] : CsrRdData8B_CLA[ii][63:32];

                    dfd_cla_csr #(
                        .BASE_ADDR(BASE_ADDR + 23'h9000 * ii ),
                        .ADDR_W(DFD_APB_ADDR_WIDTH)
                    ) u_cla_mmr (
                        .clk                    (clk),
                        .reset_n                (reset_n),
                        .reset_n_warm_ovrride   (reset_n_warm_ovrride),

                        .CsrCs          (CsrCs),
                        .CsrWrEn        (CsrWrEn),
                        .CsrWrStrb      (CsrWrStrb8B),
                        .CsrRegSel      (CsrRegSel),
                        .CsrAddr        (CsrAddr8B),
                        .CsrWrData      (CsrWrData8B),
                        .CsrWrInstrType (CsrWrInstrType),
                        .CsrWrReady     (),
                        .CsrHit         (CsrHit_CLA[ii]),
                        .CsrHitList     (),
                        .CsrRdData      (CsrRdData8B_CLA[ii]),

                        .CrCsrCdbgclacounter0Cfg    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter0Cfg),
                        .CrCsrCdbgclacounter1Cfg    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter1Cfg),
                        .CrCsrCdbgclacounter2Cfg    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter2Cfg),
                        .CrCsrCdbgclacounter3Cfg    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclacounter3Cfg),
                        .CrCsrCdbgnode0Eap0         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap0),
                        .CrCsrCdbgnode0Eap1         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap1),
                        .CrCsrCdbgnode0Eap2         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap2),
                        .CrCsrCdbgnode0Eap3         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode0Eap3),
                        .CrCsrCdbgnode1Eap0         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap0),
                        .CrCsrCdbgnode1Eap1         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap1),
                        .CrCsrCdbgnode1Eap2         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap2),
                        .CrCsrCdbgnode1Eap3         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode1Eap3),
                        .CrCsrCdbgnode2Eap0         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap0),
                        .CrCsrCdbgnode2Eap1         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap1),
                        .CrCsrCdbgnode2Eap2         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap2),
                        .CrCsrCdbgnode2Eap3         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode2Eap3),
                        .CrCsrCdbgnode3Eap0         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap0),
                        .CrCsrCdbgnode3Eap1         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap1),
                        .CrCsrCdbgnode3Eap2         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap2),
                        .CrCsrCdbgnode3Eap3         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgnode3Eap3),
                        .CrCsrCdbgsignalmask0       (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask0),
                        .CrCsrCdbgsignalmatch0      (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch0),
                        .CrCsrCdbgsignalmask1       (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask1),
                        .CrCsrCdbgsignalmatch1      (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch1),
                        .CrCsrCdbgsignalmask2       (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask2),
                        .CrCsrCdbgsignalmatch2      (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch2),
                        .CrCsrCdbgsignalmask3       (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmask3),
                        .CrCsrCdbgsignalmatch3      (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalmatch3),
                        .CrCsrCdbgsignaledgedetectcfg(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignaledgedetectcfg),
                        .CrCsrCdbgeapstatus         (DfdCsrs.ClaCsrs[ii].CrCsrCdbgeapstatus),
                        .CrCsrCdbgclactrlstatus     (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclactrlstatus),
                        .CrCsrCdbgrsvd0             (DfdCsrs.ClaCsrs[ii].CrCsrCdbgrsvd0),
                        .CrCsrCdbgrsvd1             (DfdCsrs.ClaCsrs[ii].CrCsrCdbgrsvd1),
                        .CrCsrCdbgrsvd2             (DfdCsrs.ClaCsrs[ii].CrCsrCdbgrsvd2),
                        .CrCsrCdbgtransitionmask    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitionmask),
                        .CrCsrCdbgtransitionfromvalue(DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitionfromvalue),
                        .CrCsrCdbgtransitiontovalue (DfdCsrs.ClaCsrs[ii].CrCsrCdbgtransitiontovalue),
                        .CrCsrCdbgonescountmask     (DfdCsrs.ClaCsrs[ii].CrCsrCdbgonescountmask),
                        .CrCsrCdbgonescountvalue    (DfdCsrs.ClaCsrs[ii].CrCsrCdbgonescountvalue),
                        .CrCsrCdbganychange         (DfdCsrs.ClaCsrs[ii].CrCsrCdbganychange),
                        .CrCsrCdbgsignalsnapshotnode0Eap0(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode0Eap0),
                        .CrCsrCdbgsignalsnapshotnode0Eap1(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode0Eap1),
                        .CrCsrCdbgsignalsnapshotnode0Eap2(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode0Eap2),
                        .CrCsrCdbgsignalsnapshotnode0Eap3(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode0Eap3),
                        .CrCsrCdbgsignalsnapshotnode1Eap0(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode1Eap0),
                        .CrCsrCdbgsignalsnapshotnode1Eap1(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode1Eap1),
                        .CrCsrCdbgsignalsnapshotnode1Eap2(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode1Eap2),
                        .CrCsrCdbgsignalsnapshotnode1Eap3(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode1Eap3),
                        .CrCsrCdbgsignalsnapshotnode2Eap0(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode2Eap0),
                        .CrCsrCdbgsignalsnapshotnode2Eap1(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode2Eap1),
                        .CrCsrCdbgsignalsnapshotnode2Eap2(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode2Eap2),
                        .CrCsrCdbgsignalsnapshotnode2Eap3(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode2Eap3),
                        .CrCsrCdbgsignalsnapshotnode3Eap0(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode3Eap0),
                        .CrCsrCdbgsignalsnapshotnode3Eap1(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode3Eap1),
                        .CrCsrCdbgsignalsnapshotnode3Eap2(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode3Eap2),
                        .CrCsrCdbgsignalsnapshotnode3Eap3(DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignalsnapshotnode3Eap3),
                        .CrCsrCdbgclatimematch      (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclatimematch),
                        .CrCsrCdbgclatimestampsync  (DfdCsrs.ClaCsrs[ii].CrCsrCdbgclatimestampsync),
                        .CrCsrCdbgsignaldelaymuxsel (DfdCsrs.ClaCsrs[ii].CrCsrCdbgsignaldelaymuxsel),
                        .CrCsrCdbgclaxtriggertimestretch(DfdCsrs.ClaCsrs[ii].CrCsrCdbgclaxtriggertimestretch),
                        .CrCsrCrscratchpad          (DfdCsrs.ClaCsrs[ii].CrCsrCrscratchpad),
                        .CrCsrScratch               (DfdCsrs.ClaCsrs[ii].CrCsrScratch),

                        .CrCsrCdbgclacounter0CfgWr  (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter0CfgWr),
                        .CrCsrCdbgclacounter1CfgWr  (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter1CfgWr),
                        .CrCsrCdbgclacounter2CfgWr  (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter2CfgWr),
                        .CrCsrCdbgclacounter3CfgWr  (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclacounter3CfgWr),
                        .CrCsrCdbgeapstatusWr       (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgeapstatusWr),
                        .CrCsrCdbgclactrlstatusWr   (DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgclactrlstatusWr),
                        .CrCsrCdbgsignalsnapshotnode0Eap0Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap0Wr),
                        .CrCsrCdbgsignalsnapshotnode0Eap1Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap1Wr),
                        .CrCsrCdbgsignalsnapshotnode0Eap2Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap2Wr),
                        .CrCsrCdbgsignalsnapshotnode0Eap3Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode0Eap3Wr),
                        .CrCsrCdbgsignalsnapshotnode1Eap0Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap0Wr),
                        .CrCsrCdbgsignalsnapshotnode1Eap1Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap1Wr),
                        .CrCsrCdbgsignalsnapshotnode1Eap2Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap2Wr),
                        .CrCsrCdbgsignalsnapshotnode1Eap3Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode1Eap3Wr),
                        .CrCsrCdbgsignalsnapshotnode2Eap0Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap0Wr),
                        .CrCsrCdbgsignalsnapshotnode2Eap1Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap1Wr),
                        .CrCsrCdbgsignalsnapshotnode2Eap2Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap2Wr),
                        .CrCsrCdbgsignalsnapshotnode2Eap3Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode2Eap3Wr),
                        .CrCsrCdbgsignalsnapshotnode3Eap0Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap0Wr),
                        .CrCsrCdbgsignalsnapshotnode3Eap1Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap1Wr),
                        .CrCsrCdbgsignalsnapshotnode3Eap2Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap2Wr),
                        .CrCsrCdbgsignalsnapshotnode3Eap3Wr(DfdCsrsWr.ClaCsrsWr[ii].CrCsrCdbgsignalsnapshotnode3Eap3Wr),
                        .CsrUpdateEn                (),
                        .CsrUpdateAddr              (),
                        .CsrUpdateData              ()
                    );
                end else begin
                    assign DfdCsrs.ClaCsrs[ii] = '0;
                end
            end
        end else begin : no_cla_csr_gen_blk
            assign DfdCsrs.ClaCsrs = '0;
            assign CsrHit_CLA = '0;
            assign CsrRdData_CLA = '0;
        end

        if ((DST_SUPPORT == 1 )|| (NTRACE_SUPPORT == 1)) begin : tr_csr_gen_blk
            // --------------------------------------------------------------------------
            // WARL Checks for Trace RAM Start and Limit
            // --------------------------------------------------------------------------

            localparam MAX_RAM_SIZE = TRC_SIZE_IN_B;
            localparam MIN_RAM_SIZE = 32'h0;
            localparam MAX_RAM_STARTLOW = MAX_RAM_SIZE - MIN_RAM_SIZE;

            logic         Trntrissrammode;
            logic         Trramstartlow_Warl_Check_ANY, Trramlimitlow_Warl_Check_ANY;
            logic         Trramstarthigh_Warl_Check_ANY, Trramlimithigh_Warl_Check_ANY;
            logic         Warl_Updated_WrEn_ANY;
            logic [31:0]  Trramstartlow_Warl_Data_ANY, Trramlimitlow_Warl_Data_ANY, Warl_Updated_Data_ANY, Warl_Muxed_CsrWrData;
            logic         Trfusedisabled;

            assign Trntrissrammode = ~DfdCsrs.TrCsrs.TrCsrTrramcontrol.Trrammode; // Check if the mode config is SRAM mode

            assign Trramstartlow_Warl_Check_ANY = (CsrAddr == (TR_TRRAMSTARTLOW_REG_OFFSET + BASE_ADDR));
            assign Trramlimitlow_Warl_Check_ANY = (CsrAddr == (TR_TRRAMLIMITLOW_REG_OFFSET + BASE_ADDR));

            assign Trramstarthigh_Warl_Check_ANY = (CsrAddr == (TR_TRRAMSTARTHIGH_REG_OFFSET + BASE_ADDR));
            assign Trramlimithigh_Warl_Check_ANY = (CsrAddr == (TR_TRRAMLIMITHIGH_REG_OFFSET + BASE_ADDR));

            assign Trramstartlow_Warl_Data_ANY = (CsrWrData > MAX_RAM_STARTLOW)?MAX_RAM_STARTLOW:CsrWrData;
            assign Trramlimitlow_Warl_Data_ANY = (CsrWrData > MAX_RAM_SIZE)?MAX_RAM_SIZE:CsrWrData;

            assign Warl_Updated_WrEn_ANY = ((Trramstarthigh_Warl_Check_ANY | Trramlimithigh_Warl_Check_ANY) & CsrWrEn & Trntrissrammode)?1'b0:CsrWrEn;

            assign Warl_Updated_Data_ANY = Trramstartlow_Warl_Check_ANY?Trramstartlow_Warl_Data_ANY:Trramlimitlow_Warl_Data_ANY;
            assign Warl_Muxed_CsrWrData = ((Trramstartlow_Warl_Check_ANY | Trramlimitlow_Warl_Check_ANY) & CsrWrEn & Trntrissrammode)?Warl_Updated_Data_ANY:CsrWrData;

            dfd_tr_csr #(
                .BASE_ADDR(BASE_ADDR), // Ensure that modifications to BASE_ADDR reflect in surrounding logic and dfd_apb2mmr.sv
                .ADDR_W(DFD_APB_ADDR_WIDTH)
            ) trace_sink_mmr (
                .clk                                      (clk),
                .reset_n                                  (reset_n),
                .cold_resetn                              (cold_reset_n),
                .CsrCs                                    (CsrCs),
                .CsrWrEn                                  (Warl_Updated_WrEn_ANY),
                .CsrWrStrb                                (CsrWrStrb),
                .CsrRegSel                                (CsrRegSel),
                .CsrAddr                                  (CsrAddr),
                .CsrWrData                                (Warl_Muxed_CsrWrData),
                .CsrWrInstrType                           (CsrWrInstrType),
                .CsrWrReady                               (),
                .CsrHit                                   (CsrHit_TR),
                .CsrRdData                                (CsrRdData_TR),
                .CsrHitList                               (),
                .CsrUpdateEn                              (),
                .CsrUpdateAddr                            (),
                .CsrUpdateData                            (),

                // Fuse MMRs
                .TrCsrTrclusterfusecfglow                 (DfdCsrs.TrCsrs.TrCsrTrclusterfusecfglow),
                .TrCsrTrclusterfusecfghi                  (DfdCsrs.TrCsrs.TrCsrTrclusterfusecfghi),

                // N-trace
                .TrCsrTrramcontrol                        (DfdCsrs.TrCsrs.TrCsrTrramcontrol),
                .TrCsrTrramimpl                           (DfdCsrs.TrCsrs.TrCsrTrramimpl),
                .TrCsrTrramstartlow                       (DfdCsrs.TrCsrs.TrCsrTrramstartlow),
                .TrCsrTrramstarthigh                      (DfdCsrs.TrCsrs.TrCsrTrramstarthigh),
                .TrCsrTrramlimitlow                       (DfdCsrs.TrCsrs.TrCsrTrramlimitlow),
                .TrCsrTrramlimithigh                      (DfdCsrs.TrCsrs.TrCsrTrramlimithigh),
                .TrCsrTrramwplow                          (DfdCsrs.TrCsrs.TrCsrTrramwplow),
                .TrCsrTrramwphigh                         (DfdCsrs.TrCsrs.TrCsrTrramwphigh),
                .TrCsrTrramrplow                          (DfdCsrs.TrCsrs.TrCsrTrramrplow),
                .TrCsrTrramrphigh                         (DfdCsrs.TrCsrs.TrCsrTrramrphigh),
                .TrCsrTrramdata                           (DfdCsrs.TrCsrs.TrCsrTrramdata),

                .TrCsrTrramcontrolWr                      (DfdCsrsWr.TrCsrsWr.TrCsrTrramcontrolWr),
                .TrCsrTrramstartlowWr                     ('0),
                .TrCsrTrramstarthighWr                    ('0),
                .TrCsrTrramlimitlowWr                     ('0),
                .TrCsrTrramlimithighWr                    ('0),
                .TrCsrTrramwplowWr                        (DfdCsrsWr.TrCsrsWr.TrCsrTrramwplowWr),
                .TrCsrTrramwphighWr                       (DfdCsrsWr.TrCsrsWr.TrCsrTrramwphighWr),
                .TrCsrTrramrplowWr                        (DfdCsrsWr.TrCsrsWr.TrCsrTrramrplowWr),
                .TrCsrTrramrphighWr                       (DfdCsrsWr.TrCsrsWr.TrCsrTrramrphighWr),
                .TrCsrTrramdataWr                         (DfdCsrsWr.TrCsrsWr.TrCsrTrramdataWr),

                // Custom - Vendor Implementation MMR
                .TrCsrTrcustomramsmemlimitlow             (DfdCsrs.TrCsrs.TrCsrTrcustomramsmemlimitlow),

                // DST
                .TrCsrTrdstramcontrol                     (DfdCsrs.TrCsrs.TrCsrTrdstramcontrol),
                .TrCsrTrdstramimpl                        (DfdCsrs.TrCsrs.TrCsrTrdstramimpl),
                .TrCsrTrdstramstartlow                    (DfdCsrs.TrCsrs.TrCsrTrdstramstartlow),
                .TrCsrTrdstramstarthigh                   (DfdCsrs.TrCsrs.TrCsrTrdstramstarthigh),
                .TrCsrTrdstramlimitlow                    (DfdCsrs.TrCsrs.TrCsrTrdstramlimitlow),
                .TrCsrTrdstramlimithigh                   (DfdCsrs.TrCsrs.TrCsrTrdstramlimithigh),
                .TrCsrTrdstramwplow                       (DfdCsrs.TrCsrs.TrCsrTrdstramwplow),
                .TrCsrTrdstramwphigh                      (DfdCsrs.TrCsrs.TrCsrTrdstramwphigh),
                .TrCsrTrdstramrplow                       (DfdCsrs.TrCsrs.TrCsrTrdstramrplow),
                .TrCsrTrdstramrphigh                      (DfdCsrs.TrCsrs.TrCsrTrdstramrphigh),
                .TrCsrTrdstramdata                        (DfdCsrs.TrCsrs.TrCsrTrdstramdata),

                .TrCsrTrdstramcontrolWr                   (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramcontrolWr),
                .TrCsrTrdstramstartlowWr                  ('0),
                .TrCsrTrdstramstarthighWr                 ('0),
                .TrCsrTrdstramlimitlowWr                  ('0),
                .TrCsrTrdstramlimithighWr                 ('0),
                .TrCsrTrdstramwplowWr                     (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramwplowWr),
                .TrCsrTrdstramwphighWr                    (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramwphighWr),
                .TrCsrTrdstramrplowWr                     (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramrplowWr),
                .TrCsrTrdstramrphighWr                    (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramrphighWr),
                .TrCsrTrdstramdataWr                      (DfdCsrsWr.TrCsrsWr.TrCsrTrdstramdataWr),

                // Funnel
                .TrCsrTrfunnelcontrol                     (DfdCsrs.TrCsrs.TrCsrTrfunnelcontrol),
                .TrCsrTrfunnelimpl                        (DfdCsrs.TrCsrs.TrCsrTrfunnelimpl),
                .TrCsrTrfunneldisinput                    (DfdCsrs.TrCsrs.TrCsrTrfunneldisinput),

                .TrCsrTrfunnelcontrolWr                   (DfdCsrsWr.TrCsrsWr.TrCsrTrfunnelcontrolWr),
                .TrCsrTrfunneldisinputWr                  ('0),

                .TrCsrTrscratchlo                         (DfdCsrs.TrCsrs.TrCsrTrscratchlo),
                .TrCsrTrscratchhi                         (DfdCsrs.TrCsrs.TrCsrTrscratchhi),
                .TrCsrTrscratchpadlo                      (DfdCsrs.TrCsrs.TrCsrTrscratchpadlo),
                .TrCsrTrscratchpadhi                      (DfdCsrs.TrCsrs.TrCsrTrscratchpadhi)
            );
        end else begin
            assign DfdCsrs.TrCsrs = '0;
            assign CsrHit_TR = '0;
            assign CsrRdData_TR = '0;
        end

    end else begin : gen_external_mmrs_blk
        assign pready = '0;
        assign prdata = '0;
        assign pslverr = '0;

        assign DfdCsrs.DstCsrs = DfdCsrs_external.DstCsrs;
        assign DfdCsrs.NtrCsrs = DfdCsrs_external.NtrCsrs;
        assign DfdCsrs.ClaCsrs = DfdCsrs_external.ClaCsrs;
        assign DfdCsrs.TrCsrs  = DfdCsrs_external.TrCsrs;
        assign DfdCsrs.McrCsrs = DfdCsrs_external.McrCsrs;

        assign DfdCsrsWr_external.DstCsrsWr = DfdCsrsWr.DstCsrsWr;
        assign DfdCsrsWr_external.NtrCsrsWr = DfdCsrsWr.NtrCsrsWr;
        assign DfdCsrsWr_external.ClaCsrsWr = DfdCsrsWr.ClaCsrsWr;
        assign DfdCsrsWr_external.TrCsrsWr  = DfdCsrsWr.TrCsrsWr;
    end



endmodule

