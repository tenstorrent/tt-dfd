`include "generic_macro_assertion.vh"

// AXI to MMR Coverter :: It Can Handle Single beat and 4/8B Byte aligned AXI Xfers on 8B/4B AXI Bus
module generic_axilitetommr
#(
  parameter type axi_req_t            = logic,
  parameter type axi_rsp_t            = logic,
  parameter      AXI_ID_WIDTH         = 16,
  parameter      PART_4B_WREN         = '0,
  // SRCID field width in USER[CPL_SRCID_WIDTH-1:0]; do not use $bits(CPL_SRCID)
  // (unsized decimal overrides can make $bits == 32).
  parameter int unsigned CPL_SRCID_WIDTH = 4,
  parameter      CPL_SRCID            = (CPL_SRCID_WIDTH)'(3),
  parameter      SRCID_CHKEN          = 1'b1,
  parameter      AXI_ADDR_WIDTH       = 23,
  parameter      AXI_DATA_WIDTH       = 64,
  parameter      NUM_SRCID_ENTRY      = 2,
  parameter      NUM_FUSE_ADDR_FILTERS= 2,
  parameter      FUSE_CHKEN           = 1'b1,
  parameter bit  AXI5LITE_MODE        = 1'b0, //AXI5-Lite channels have no LEN/BURST/LOCK/LAST and add IDUNQ/TRACE/POISON
  localparam     AXI_STRB_WIDTH       = AXI_DATA_WIDTH/8
 )
 (
    input logic                          clk,
    input logic                          reset_n, 
    //AXI I/F 
    input  axi_req_t                     axi_req_i,
    output axi_rsp_t                     axi_rsp_o, 
    //Memory Interface 
    output logic                                                   o_req_vld,
    input  logic                                                   i_req_rdy,//Slave Not Ready (Slave Busy) 
    input  logic                                                   i_wr_rsp_stall,
    output logic                                                   o_wr_init_req,
    output logic                                                   o_we,
    output logic [1:0]                                             o_wrstobe,//4 Byte Boundary
    output logic [(AXI_DATA_WIDTH/8)-1:0]                          o_wrbyteen,//1 Byte Boundary
    output logic [AXI_ADDR_WIDTH-1:0]                              o_addr,
    output logic [AXI_DATA_WIDTH-1:0]                              o_data,
    input  logic [AXI_DATA_WIDTH-1:0]                              i_data,
    input  logic                                                   i_data_valid, //Slave RData is Available
    output logic                                                   o_busy,
    input   logic [NUM_SRCID_ENTRY-1:0]    [AXI_ADDR_WIDTH-1:0]    FilStartAddr,
    input   logic [NUM_SRCID_ENTRY-1:0]    [AXI_ADDR_WIDTH-1:0]    FilAddrMask,

    input   logic [NUM_FUSE_ADDR_FILTERS-1:0]   [AXI_ADDR_WIDTH-1:0]    FuseFilStartAddr,
    input   logic [NUM_FUSE_ADDR_FILTERS-1:0]   [AXI_ADDR_WIDTH-1:0]    FuseFilAddrMask,
    input   logic [NUM_FUSE_ADDR_FILTERS-1:0]                           FuseBlockDisable,
    //Memory Response I/F
    //State debug signal output
    output  logic [2:0]                                            state_dbg_o
 );
//Interal Signals  Declaration
typedef enum logic [2:0] {
                         AXI2MMR_IDLE             = 3'h0,
                         AXI2MMR_MMR_RD_REQ       = 3'h1,
                         AXI2MMR_WAIT_AXI_WD      = 3'h2,
                         AXI2MMR_WAIT_MMR_RD_RESP = 3'h3, 
                         AXI2MMR_MMR_WR_REQ       = 3'h4,
                         AXI2MMR_WAIT_AXI_WR_RESP = 3'h5, 
                         AXI2MMR_AXI_RD_RESP      = 3'h6,
                         AXI2MMR_AXI_WR_RESP      = 3'h7 
} axitommr_fsm_e;

axitommr_fsm_e state_q;
axitommr_fsm_e state_d; 

logic          RdRespErr;
logic          RdRespErrEn;
logic          WrRespErr;
logic          WrRespErrEn;
// logic          BlockDisableErr;
// logic          BlockDisableErrEn;
logic          InValidWrStrb;
logic          WrStrbErrEn;
logic  [1:0]   NxtMmrWrStrb;
//RR Arbiteration 
logic          LastSel;
logic          NxtLastSel;
/* verilator lint_off UNOPTFLAT */
logic          BlkRd;
logic          BlkWr;
/* verilator lint_on UNOPTFLAT */
//AXI Signals 
logic [AXI_ID_WIDTH-1:0]                  AxId; 
axi_pkg::resp_t                           AxResp;
axi_pkg::resp_t                           NxtAxResp;
logic                                     AxRespEn;
logic                                     NxtAxUser;
logic                                     AxUser;
logic [2:0]                               AxSize;
logic [AXI_ADDR_WIDTH-1:0]                MmrAddr;
//AXI5-Lite gating helpers (fields absent from the AXI5-Lite channel structs)
logic                                     RdLenErr;
logic                                     WrLenErr;
logic                                     WLast;
logic                                     RLast;
logic                                     AxTrace;
//FSM Arcs
logic          arc_Idle_To_RdResp;
logic          arc_Idle_To_MmrRdReq;
logic          arc_Idle_To_MmrWaitAxiWd;
logic          arc_MmrRdReq_To_AxiRdResp;
logic          arc_MmrRdReq_To_WaitMmrRdRsp;
logic          arc_MmrRdResp_To_AxiRdResp;
logic          arc_AxiRdResp_To_Idle;
logic          arc_WaitAxiWd_To_MmrWrReq; 
logic          arc_WaitAxiWd_To_AxiWrResp;
logic          arc_MmrWrReq_To_AxiWrResp;
logic          arc_MmrWrReq_To_WaitMmrWrResp; 
logic          arc_WaitMmrWrResp_To_AxiWrResp;
logic          arc_AxiWrResp_To_Idle;

//Return Error Response for below scenarios:
//1. Unaligned 4B or 8B address requests
//2. 1B,2B Axi Requests
//3. Source ID != CPL Source ID
//4. AxLen != 0;
//5. Invalid WriteStrobe 
//Source ID Check 
logic [NUM_SRCID_ENTRY-1:0] WrAddrMatch;
logic [NUM_SRCID_ENTRY-1:0] WrSrcIDMatch; 
logic [NUM_SRCID_ENTRY-1:0] WrMatchVec; 
logic [NUM_SRCID_ENTRY-1:0] RdAddrMatch;
logic [NUM_SRCID_ENTRY-1:0] RdSrcIDMatch; 
logic [NUM_SRCID_ENTRY-1:0] RdMatchVec; 

assign state_dbg_o = state_q[2:0]; // FIXME_CALICUT , work around to avoid generated files dependency for ms_mmr

// SRCID uses only user[CPL_SRCID_WIDTH-1:0]; full USER may be wider.
// When SRCID_CHKEN, aw/ar.user must be at least CPL_SRCID_WIDTH wide.
if (SRCID_CHKEN) begin : gen_srcid_user_width_chk
  if ($bits(axi_req_i.aw.user) < CPL_SRCID_WIDTH || $bits(axi_req_i.ar.user) < CPL_SRCID_WIDTH) begin : gen_srcid_user_width_err
    $error("%m: aw/ar.user width (%0d/%0d) must be >= CPL_SRCID_WIDTH=%0d when SRCID_CHKEN=1",
           $bits(axi_req_i.aw.user), $bits(axi_req_i.ar.user), CPL_SRCID_WIDTH);
  end : gen_srcid_user_width_err
end : gen_srcid_user_width_chk

for (genvar i = 0 ; i < NUM_SRCID_ENTRY; i++) begin
   assign WrAddrMatch[i]     = ((axi_req_i.aw.addr & FilAddrMask[i]) == (FilStartAddr[i] & FilAddrMask[i])); 
   assign WrSrcIDMatch[i]    = (axi_req_i.aw.user[CPL_SRCID_WIDTH-1:0] == CPL_SRCID_WIDTH'(CPL_SRCID)); 
   assign WrMatchVec[i]      = !(SRCID_CHKEN) || (&axi_req_i.aw.user[CPL_SRCID_WIDTH-1:0]) || (WrAddrMatch[i] & WrSrcIDMatch[i]); //Allow SEP Soure ID
   assign RdAddrMatch[i]     = ((axi_req_i.ar.addr & FilAddrMask[i]) == (FilStartAddr[i] & FilAddrMask[i])); 
   assign RdSrcIDMatch[i]    = (axi_req_i.ar.user[CPL_SRCID_WIDTH-1:0] == CPL_SRCID_WIDTH'(CPL_SRCID)); 
   assign RdMatchVec[i]      = !(SRCID_CHKEN) || (&axi_req_i.ar.user[CPL_SRCID_WIDTH-1:0]) || (RdAddrMatch[i] & RdSrcIDMatch[i]);//Allow SEP Source ID
end

logic [NUM_FUSE_ADDR_FILTERS-1:0] FuseFilWrAddrMatch;
logic [NUM_FUSE_ADDR_FILTERS-1:0] FuseFilWrMatchVec; 
logic [NUM_FUSE_ADDR_FILTERS-1:0] FuseFilRdAddrMatch;
logic [NUM_FUSE_ADDR_FILTERS-1:0] FuseFilRdMatchVec; 
for (genvar i = 0 ; i < NUM_FUSE_ADDR_FILTERS; i++) begin
   assign FuseFilWrAddrMatch[i]     = ((axi_req_i.aw.addr & FuseFilAddrMask[i]) == (FuseFilStartAddr[i] & FuseFilAddrMask[i])); 
   assign FuseFilWrMatchVec[i]      = !(FUSE_CHKEN) || (FuseFilWrAddrMatch[i] & ~FuseBlockDisable[i]); // Allow access to the address range
   assign FuseFilRdAddrMatch[i]     = ((axi_req_i.ar.addr & FuseFilAddrMask[i]) == (FuseFilStartAddr[i] & FuseFilAddrMask[i])); 
   assign FuseFilRdMatchVec[i]      = !(FUSE_CHKEN) || (FuseFilRdAddrMatch[i] & ~FuseBlockDisable[i]); // Allow access to the address range
end

generate
if (!AXI5LITE_MODE) begin : gen_full_len_last
   assign RdLenErr = (|axi_req_i.ar.len);
   assign WrLenErr = (|axi_req_i.aw.len);
   assign WLast    = axi_req_i.w.last;
   assign RLast    = axi_rsp_o.r.last;
end : gen_full_len_last
else begin : gen_lite_len_last
   //AXI5-Lite is always single beat: no AxLEN, no WLAST/RLAST
   assign RdLenErr = 1'b0;
   assign WrLenErr = 1'b0;
   assign WLast    = 1'b1;
   assign RLast    = 1'b1;
end : gen_lite_len_last
endgenerate

assign RdRespErr                 =  (~((axi_req_i.ar.addr[1:0] == 2'b00))) || 
                                    ((AXI_DATA_WIDTH == 64) ? (PART_4B_WREN ? (~((axi_req_i.ar.size == 3'b010) || ((axi_req_i.ar.size == 3'b011)))) :
                                                                              ~(axi_req_i.ar.size == 3'b011)) : 
                                                                              ~(axi_req_i.ar.size == 3'b010)) ||
                                    RdLenErr || 
                                    ~((|RdMatchVec) || (~(|RdAddrMatch))) ||
                                    ~((|FuseFilRdMatchVec) || (~(|FuseFilRdAddrMatch))) ;

assign WrRespErr                 =  (~((axi_req_i.aw.addr[1:0] == 2'b00))) || 
                                    ((AXI_DATA_WIDTH == 64) ? (PART_4B_WREN ? (~((axi_req_i.aw.size == 3'b010) || ((axi_req_i.aw.size == 3'b011)))) :
                                                                              ~(axi_req_i.aw.size == 3'b011)) : 
                                                                            ~(axi_req_i.aw.size == 3'b010)) || 
                                    WrLenErr ||
                                    ~((|WrMatchVec) || (~(|WrAddrMatch))) ||
                                    ~((|FuseFilWrMatchVec) || (~(|FuseFilWrAddrMatch))) ;

assign InValidWrStrb             =  (AXI_DATA_WIDTH == 64) ? (PART_4B_WREN ? ~(((axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hF0))  || (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0F))) ||
                                                                              (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hFF)) || (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h00))) : 
                                                                              ~((axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hFF)) || (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h00)))) :
                                                                              ~((axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0F)) || (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h00)));

// assign BlockDisableErr            = i_block_disable;

//MMR WrIte Strobe Computation for 8B/4B Bus 
always_comb begin
    NxtMmrWrStrb = '0; 
  case (AxSize) 
  3'b010 : begin
              NxtMmrWrStrb = '0; 
            if (MmrAddr[2]  && (AXI_DATA_WIDTH == 64) && (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hF0))) 
                 NxtMmrWrStrb  = 2'b10; 
            if (~MmrAddr[2] && (AXI_DATA_WIDTH == 64) && (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0F)))
                NxtMmrWrStrb   = 2'b01;
            if (AXI_DATA_WIDTH == 32)
                NxtMmrWrStrb   =  (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0F)) ? 2'b01 : 2'b00;   
           end   
  3'b011 : begin 
              NxtMmrWrStrb = 0;
             if (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0))
                NxtMmrWrStrb = '0; 
             if (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'h0F))
                NxtMmrWrStrb = 2'b01;
             if (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hF0))
                NxtMmrWrStrb = 2'b10;  
             if (axi_req_i.w.strb == (AXI_STRB_WIDTH)'(8'hFF))
                NxtMmrWrStrb = 2'b11;       
           end   
  default : NxtMmrWrStrb = '0; 
  endcase 
end
generic_dff #(
    .WIDTH($bits(o_wrstobe))
) MmrWrStrb_ff (
    .clk(clk),
    .rst_n(reset_n),
    .in(NxtMmrWrStrb),
    .en(axi_req_i.w_valid && axi_rsp_o.w_ready),
    .out(o_wrstobe)
);

generic_dff #(
    .WIDTH($bits(o_wrbyteen))
) ByteEn_ff (
    .clk(clk),
    .rst_n(reset_n),
    .in(axi_req_i.w.strb),
    .en(axi_req_i.w_valid && axi_rsp_o.w_ready),
    .out(o_wrbyteen)
);
//FSM Arc
always_comb begin
    arc_Idle_To_RdResp                 =          axi_req_i.ar_valid && (RdRespErr) && ~BlkRd; 
    arc_Idle_To_MmrRdReq               =          axi_req_i.ar_valid && ~BlkRd;
    arc_Idle_To_MmrWaitAxiWd           =          axi_req_i.aw_valid && ~BlkWr;
    arc_MmrRdReq_To_AxiRdResp          =          1'b0;
    arc_MmrRdReq_To_WaitMmrRdRsp       =          i_req_rdy;//Slave Not Ready 
    arc_MmrRdResp_To_AxiRdResp         =          i_data_valid;
    arc_AxiRdResp_To_Idle              =          axi_req_i.r_ready && RLast;
    arc_WaitAxiWd_To_AxiWrResp         =          ((|AxResp) && (axi_req_i.w_valid) && WLast) || (axi_req_i.w_valid && (InValidWrStrb) && WLast);
    arc_WaitAxiWd_To_MmrWrReq          =          axi_req_i.w_valid && WLast;
    //arc_MmrWrReq_To_AxiWrResp          =          i_req_rdy;//Slave Not Ready
    arc_MmrWrReq_To_AxiWrResp          =          1'b0;
    arc_MmrWrReq_To_WaitMmrWrResp      =          i_req_rdy;
    arc_WaitMmrWrResp_To_AxiWrResp     =          ~i_wr_rsp_stall; 
    arc_AxiWrResp_To_Idle              =          axi_req_i.b_ready;
end     
//Control Path FSM
always_comb begin 
    state_d  = state_q;
    NxtLastSel = LastSel;
    case (state_q)
        AXI2MMR_IDLE: begin
            if (arc_Idle_To_RdResp) begin 
                state_d  = AXI2MMR_AXI_RD_RESP;
                NxtLastSel =  1'b0; 
            end     
            else if (arc_Idle_To_MmrRdReq) begin 
                state_d = AXI2MMR_MMR_RD_REQ; 
                NxtLastSel =  1'b0; 
            end     
            else if (arc_Idle_To_MmrWaitAxiWd) begin
                state_d = AXI2MMR_WAIT_AXI_WD;   
                NxtLastSel =  1'b1; 
            end               
        end  
        AXI2MMR_MMR_RD_REQ: begin
            if (arc_MmrRdReq_To_AxiRdResp) 
                state_d = AXI2MMR_AXI_RD_RESP;
            else if (arc_MmrRdReq_To_WaitMmrRdRsp)
                state_d = AXI2MMR_WAIT_MMR_RD_RESP;
        end 
        AXI2MMR_WAIT_MMR_RD_RESP: begin
            if (arc_MmrRdResp_To_AxiRdResp)
                state_d = AXI2MMR_AXI_RD_RESP;
        end 
        AXI2MMR_AXI_RD_RESP: begin
            if (arc_AxiRdResp_To_Idle)
                state_d = AXI2MMR_IDLE;
        end 
        AXI2MMR_WAIT_AXI_WD: begin
            if (arc_WaitAxiWd_To_AxiWrResp)
                state_d = AXI2MMR_AXI_WR_RESP;
            else if (arc_WaitAxiWd_To_MmrWrReq)
                state_d = AXI2MMR_MMR_WR_REQ;
        end
        AXI2MMR_MMR_WR_REQ: begin
            if (arc_MmrWrReq_To_AxiWrResp)
                state_d = AXI2MMR_AXI_WR_RESP;
            else if (arc_MmrWrReq_To_WaitMmrWrResp)
                state_d = AXI2MMR_WAIT_AXI_WR_RESP; 
        end 
        AXI2MMR_WAIT_AXI_WR_RESP: begin
            if (arc_WaitMmrWrResp_To_AxiWrResp) 
                state_d = AXI2MMR_AXI_WR_RESP;
        end 
        AXI2MMR_AXI_WR_RESP:begin
            if (arc_AxiWrResp_To_Idle)
                state_d = AXI2MMR_IDLE;
        end 
        default : state_d = AXI2MMR_IDLE;
    endcase  
end    
assign o_wr_init_req           = (state_q == AXI2MMR_MMR_WR_REQ);

//============================================================
// generic_dff drives an untyped logic vector, so the state register output is
// captured on a raw vector and cast back to the FSM enum (a direct connection
// to an enum-typed variable is an illegal enum assignment).
logic [$bits(axitommr_fsm_e)-1:0] state_q_raw;

generic_dff #(
    .WIDTH($bits(axitommr_fsm_e)),
    .RESET_VALUE(AXI2MMR_IDLE)
) CurrState_ff (
    .clk(clk),
    .rst_n(reset_n),
    .in(state_d),
    .en(1'b1),
    .out(state_q_raw)
);

assign state_q = axitommr_fsm_e'(state_q_raw);
//============================================================


//DMI Signals 
logic                         MmrReqEn;
logic                         MmrRdDataEn;
logic                         MmrWrDataEn;
logic [AXI_DATA_WIDTH-1:0]    MmrData;

assign MmrReqEn   = (state_q == AXI2MMR_IDLE) && (axi_req_i.ar_valid | axi_req_i.aw_valid);
assign o_addr     = (AXI_DATA_WIDTH == 64) ? {MmrAddr[AXI_ADDR_WIDTH-1:3],3'b0} : MmrAddr[AXI_ADDR_WIDTH-1:0]; 
always_ff @(posedge clk) begin
     if (MmrReqEn) begin 
        MmrAddr  <= axi_req_i.ar_valid & axi_rsp_o.ar_ready ? axi_req_i.ar.addr[AXI_ADDR_WIDTH-1:0] : axi_req_i.aw.addr[AXI_ADDR_WIDTH-1:0];
        AxId     <= axi_req_i.ar_valid & axi_rsp_o.ar_ready ? axi_req_i.ar.id : axi_req_i.aw.id;
     end    
end  
generate
if (AXI5LITE_MODE) begin : gen_lite_trace
   //Capture AxTRACE so that the generated B/R response can echo it back
   logic AxTrace_q;
   always_ff @(posedge clk) begin
        if (MmrReqEn) begin
           AxTrace_q <= axi_req_i.ar_valid & axi_rsp_o.ar_ready ? axi_req_i.ar.trace : axi_req_i.aw.trace;
        end
   end
   assign AxTrace = AxTrace_q;
end : gen_lite_trace
else begin : gen_full_trace
   assign AxTrace = 1'b0;
end : gen_full_trace
endgenerate
generic_dff #(
    .WIDTH(1)
) o_we_ff (
    .clk(clk),
    .rst_n(reset_n),
    .in(axi_req_i.ar_valid & axi_rsp_o.ar_ready ? 1'b0 : 1'b1),
    .en(MmrReqEn),
    .out(o_we)
);
assign MmrWrDataEn   = (state_q == AXI2MMR_WAIT_AXI_WD) && (axi_req_i.w_valid); 
assign MmrRdDataEn   = (state_q == AXI2MMR_WAIT_MMR_RD_RESP) && i_data_valid;

always_ff @(posedge clk) begin
     //if (MmrWrDataEn) begin
     //   MmrData <= axi_req_i.w.data; 
     //end   
     //if (MmrRdDataEn) begin
     //   MmrData <= i_data; 
     //end    
     if (state_q == AXI2MMR_IDLE)
        MmrData <= '0;
     else if (MmrRdDataEn) begin
        MmrData <= i_data; 
     end    
     else if (MmrWrDataEn) begin
        MmrData <= axi_req_i.w.data; 
     end   
end    

assign RdRespErrEn  = (axi_req_i.ar_valid && axi_rsp_o.ar_ready) && RdRespErr;
assign WrRespErrEn  = (axi_req_i.aw_valid) && (axi_rsp_o.aw_ready) && WrRespErr;
assign WrStrbErrEn  = (axi_req_i.w_valid) && (axi_rsp_o.w_ready) && (InValidWrStrb || (AxResp == axi_pkg::RESP_DECERR));
// assign BlockDisableErrEn  = ((axi_req_i.ar_valid && axi_rsp_o.ar_ready) || (axi_req_i.aw_valid && axi_rsp_o.aw_ready)) && BlockDisableErr;
assign AxRespEn     = (axi_req_i.ar_valid && axi_rsp_o.ar_ready) ||
                      (axi_req_i.aw_valid) && (axi_rsp_o.aw_ready) || 
                      (axi_req_i.w_valid  && axi_rsp_o.w_ready);  
always_comb begin
    casez ({RdRespErrEn | WrRespErrEn | WrStrbErrEn}) // | BlockDisableErrEn})  
    1'b1 : begin
                NxtAxResp = axi_pkg::RESP_DECERR;
                NxtAxUser = '0; 
             end    
    1'b0 : begin 
                NxtAxResp = axi_pkg::RESP_OKAY;
                NxtAxUser = '0; 
            end    
    endcase 
end     
always_ff @(posedge clk) begin
     if ((axi_req_i.r_ready && axi_rsp_o.r_valid) || (axi_req_i.b_ready && axi_rsp_o.b_valid)) begin 
        AxResp <= '0;
        AxUser <= '0;
     end  
     else if (AxRespEn) begin
        AxResp <= NxtAxResp;
        AxUser <= NxtAxUser;
     end   
end     

always_ff @(posedge clk) begin
   if ((axi_req_i.ar_valid && axi_rsp_o.ar_ready) || (axi_req_i.aw_valid && axi_rsp_o.aw_ready))
        AxSize <= axi_req_i.ar_valid & axi_rsp_o.ar_ready ? axi_req_i.ar.size : axi_req_i.aw.size;
end     
//DMI Control and Data Packet Generation 
always_comb begin 
    o_req_vld               = (state_q == AXI2MMR_MMR_RD_REQ) || (state_q == AXI2MMR_MMR_WR_REQ);
    o_data                   = MmrData;
    //Mmr_Rsp_Rdy              = (state_q == AXI2MMR_WAIT_MMR_RD_RESP) || (state_q == AXI2MMR_WAIT_MMR_WR_RESP) || (state_q == AXI2MMR_IDLE);
end 
//AXI Control and Data Packet Generation 
//Incoming WPOISON is ignored: the MMR interface has no poison concept
axi_rsp_t axi_rsp_int;
always_comb begin 
    axi_rsp_int          = '0; 
    axi_rsp_int.aw_ready = (state_q == AXI2MMR_IDLE) && ~BlkWr;
    axi_rsp_int.ar_ready = (state_q == AXI2MMR_IDLE) && ~BlkRd;
    axi_rsp_int.w_ready  = (state_q == AXI2MMR_WAIT_AXI_WD);
    //AXI Write Response channel 
    axi_rsp_int.b_valid  = (state_q == AXI2MMR_AXI_WR_RESP);
    axi_rsp_int.b.id     = AxId;
    axi_rsp_int.b.resp   = AxResp;
    axi_rsp_int.b.user   = ($bits(axi_rsp_int.b.user))'(AxUser);
    //AXI Read Response Channel 
    axi_rsp_int.r_valid  = (state_q == AXI2MMR_AXI_RD_RESP);
    axi_rsp_int.r.id     = AxId;
    axi_rsp_int.r.data   = MmrData;
    axi_rsp_int.r.resp   = AxResp; 
    axi_rsp_int.r.user   = '0; 
end
generate
if (!AXI5LITE_MODE) begin : gen_full_rsp
    always_comb begin
        axi_rsp_o          = axi_rsp_int;
        axi_rsp_o.r.last   = 1'b1;
    end
end : gen_full_rsp
else begin : gen_lite_rsp
    always_comb begin
        axi_rsp_o          = axi_rsp_int;
        axi_rsp_o.b.idunq  = 1'b0;
        axi_rsp_o.b.trace  = AxTrace;
        axi_rsp_o.r.idunq  = 1'b0;
        axi_rsp_o.r.trace  = AxTrace;
        axi_rsp_o.r.poison = '0;
    end
end : gen_lite_rsp
endgenerate
assign o_busy      =  (state_q != AXI2MMR_IDLE);

//RR Arbiter for Read and Write
assign BlkWr = (LastSel == 1'b1) && axi_req_i.ar_valid && (state_q == AXI2MMR_IDLE);
assign BlkRd = (LastSel == 1'b0) && axi_req_i.aw_valid && (state_q == AXI2MMR_IDLE); 
generic_dff #(
    .WIDTH(1)
) o_rr_ptr (
    .clk(clk),
    .rst_n(reset_n),
    .in(NxtLastSel),
    .en(1'b1),
    .out(LastSel)
);

`ifdef ASSERTION_ENABLE

/* verilator lint_off SYNCASYNCNET */
   `ASSERT_MACRO(InvalidAxiDataWidth, clk, reset_n, 1'b1,
              ((AXI_DATA_WIDTH == 64) || (AXI_DATA_WIDTH == 32)),
              "AXI_DATA_WIDTH must be 32 or 64")
   `ASSERT_MACRO(InvalidAxiUserWidthForSrcId, clk, reset_n, 1'b1,
              (!SRCID_CHKEN) ||
              (($bits(axi_req_i.aw.user) >= CPL_SRCID_WIDTH) && ($bits(axi_req_i.ar.user) >= CPL_SRCID_WIDTH)),
              "aw/ar.user width must be >= CPL_SRCID_WIDTH when SRCID_CHKEN=1")
generate
if (!AXI5LITE_MODE) begin : gen_full_len_assert
   `ASSERT_MACRO(InvalidArBurstLen, clk, reset_n, axi_req_i.ar_valid,
              (axi_req_i.ar.len == 0), "AXI-Lite ARLEN must be 0")
   `ASSERT_MACRO(InvalidAwBurstLen, clk, reset_n, axi_req_i.aw_valid,
              (axi_req_i.aw.len == 0), "AXI-Lite AWLEN must be 0")
end : gen_full_len_assert
endgenerate
  // InvalidArSize                   : assert property (@(posedge clk) disable iff (~reset_n) 
  //                                         axi_req_i.ar_valid |-> ((axi_req_i.ar.size == 3'b010) ||(axi_req_i.ar.size == 3'b011)));
  // InvalidAwSize                   : assert property (@(posedge clk) disable iff (~reset_n) 
  //                                         axi_req_i.aw_valid |-> ((axi_req_i.aw.size == 3'b010) || (axi_req_i.aw.size == 3'b011)));   
   //MmrRspValidWhenFull             : assert property (@(posedge clk) disable iff (~reset_n) 
   //                                         i_data_valid |-> (state_q == AXI2MMR_WAIT_MMR_RD_RESP) || (state_q == AXI2MMR_WAIT_MMR_WR_RESP)); 
   `ASSERT_MACRO(AxiRdPayldUnknownChk, clk, reset_n, axi_req_i.ar_valid,
              !$isunknown(axi_req_i.ar), "X on AR payload while ar_valid")
   `ASSERT_MACRO(AxiWrPayldUnknownChk, clk, reset_n, axi_req_i.aw_valid,
              !$isunknown(axi_req_i.aw), "X on AW payload while aw_valid")
   `ASSERT_MACRO(AxiRdWrValidUnknownChk, clk, reset_n, 1'b1,
              !$isunknown({axi_req_i.aw_valid,axi_req_i.ar_valid}), "X on aw_valid/ar_valid")
   `ASSERT_MACRO(InvalidRdWrBlockCheck, clk, reset_n, 1'b1,
              $onehot0({BlkWr,BlkRd}), "BlkWr and BlkRd both asserted")
/* verilator lint_on SYNCASYNCNET */
`endif 
endmodule 
