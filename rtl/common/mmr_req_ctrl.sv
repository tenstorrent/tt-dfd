module mmr_req_ctrl #(
    parameter int unsigned NUM_MMR_BLOCKS     = 1,
    parameter int unsigned MMR_PIPE_LAT       = 2,
    parameter bit          NTR_SINK_EN        = 1'b1,
    parameter bit          DST_SINK_EN        = 1'b1,
    parameter int unsigned NTR_SINK_BLK_IDX   = 0,
    parameter int unsigned DST_SINK_BLK_IDX   = 0,
    parameter logic [11:0] NTR_RAMDATA_OFFSET = 12'h0,
    parameter logic [11:0] DST_RAMDATA_OFFSET = 12'h0
) (
    input  logic                      clk,
    input  logic                      reset_n,

    // Bus request (APB or AXI).  Held until bus_req_rdy.
    input  logic                      bus_req_vld,
    input  logic                      bus_req_we,
    input  logic [NUM_MMR_BLOCKS-1:0] bus_req_blk_sel,
    input  logic               [11:0] bus_req_addr,
    input  logic               [31:0] bus_req_data,
    input  logic                [1:0] bus_req_strb,
    input  logic                      bus_req_err,
    output logic                      bus_req_rdy,

    // JTAG request.  Held until jt_rsp_vld.  Higher priority than the bus.
    input  logic                      jt_req_vld,
    input  logic                      jt_req_we,
    input  logic [NUM_MMR_BLOCKS-1:0] jt_req_blk_sel,
    input  logic               [11:0] jt_req_addr,
    input  logic               [31:0] jt_req_data,
    output logic                      jt_rsp_vld,

    // Trace sink interface
    input  logic                      TraceRamWrEn,
    output logic                      ram_rd_en_ntr,
    output logic                      ram_rd_en_dst,

    // MMR fabric
    output logic [NUM_MMR_BLOCKS-1:0] MmrCs,
    output logic                      MmrWrEn,
    output logic                      MmrRegSel,
    output logic                [1:0] MmrWrStrb,
    output logic               [11:0] MmrAddr,
    output logic               [31:0] MmrWrData,

    // Bus response
    output logic                      rsp_vld,
    output logic                      rsp_err
);

    logic gnt, gnt_is_jtag, gnt_we, gnt_err;
    logic [NUM_MMR_BLOCKS-1:0] gnt_blk_sel;
    logic [11:0] gnt_addr;
    logic [31:0] gnt_data;
    logic  [1:0] gnt_strb;

    logic fabric_rdy;
    logic rsp_busy;
    logic ram_pend_q;

    assign fabric_rdy  = ~rsp_busy & ~ram_pend_q;
    assign bus_req_rdy = fabric_rdy & ~jt_req_vld;
    assign gnt         = fabric_rdy & (jt_req_vld | bus_req_vld);
    assign gnt_is_jtag = jt_req_vld;

    // Payload is a pure mux of the two requesters - neither is registered here.
    assign gnt_blk_sel = gnt_is_jtag ? jt_req_blk_sel : bus_req_blk_sel;
    assign gnt_addr    = gnt_is_jtag ? jt_req_addr    : bus_req_addr;
    assign gnt_data    = gnt_is_jtag ? jt_req_data    : bus_req_data;
    assign gnt_we      = gnt_is_jtag ? jt_req_we      : bus_req_we;
    // JTAG has no byte strobes: a write covers the low 4B lane.
    assign gnt_strb    = gnt_is_jtag ? {1'b0, jt_req_we} : bus_req_strb;
    assign gnt_err     = gnt_is_jtag ? 1'b0             : bus_req_err;

    // --------------------------------------------------------------------------
    // Trace RAM data read decode.  Writes to Tr[dst]ramdata are ordinary
    // register writes and take the regular path.
    // --------------------------------------------------------------------------
    logic gnt_ram_rd_ntr, gnt_ram_rd_dst, gnt_ram_rd;

    assign gnt_ram_rd_ntr = NTR_SINK_EN & gnt & ~gnt_we & gnt_blk_sel[NTR_SINK_BLK_IDX]
                          & (gnt_addr == NTR_RAMDATA_OFFSET);
    assign gnt_ram_rd_dst = DST_SINK_EN & gnt & ~gnt_we & gnt_blk_sel[DST_SINK_BLK_IDX]
                          & (gnt_addr == DST_RAMDATA_OFFSET);
    assign gnt_ram_rd     = gnt_ram_rd_ntr | gnt_ram_rd_dst;

    logic ram_req_active, ram_launched_q;
    logic ram_rd_en, ram_cs;
    logic ram_is_ntr_q, ram_is_jtag_q, ram_err_q;
    logic ram_cs_is_ntr, ram_cs_is_jtag, ram_cs_err;

    assign ram_req_active = ram_pend_q;

    // Launched once per accepted read, only while the sink is not writing.
    assign ram_rd_en      = ram_req_active & ~TraceRamWrEn & ~ram_launched_q;
    assign ram_cs         = ram_launched_q;

    generic_dff_clr #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_ram_pend_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (gnt_ram_rd),
        .clr   (ram_cs),
        .in    (1'b1),
        .out   (ram_pend_q)
    );
    generic_dff_clr #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_ram_launched_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (ram_rd_en),
        .clr   (ram_cs),
        .in    (1'b1),
        .out   (ram_launched_q)
    );

    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_ram_is_ntr_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (gnt_ram_rd),
        .in    (gnt_ram_rd_ntr),
        .out   (ram_is_ntr_q)
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_ram_is_jtag_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (gnt_ram_rd),
        .in    (gnt_is_jtag),
        .out   (ram_is_jtag_q)
    );
    generic_dff #(
        .WIDTH       ($bits(logic)),
        .RESET_VALUE ('0)
    ) u_ram_err_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    (gnt_ram_rd),
        .in    (gnt_err),
        .out   (ram_err_q)
    );

    assign ram_cs_is_ntr  = ram_is_ntr_q;
    assign ram_cs_is_jtag = ram_is_jtag_q;
    assign ram_cs_err     = ram_err_q;

    assign ram_rd_en_ntr  = ram_rd_en &  ram_cs_is_ntr;
    assign ram_rd_en_dst  = ram_rd_en & ~ram_cs_is_ntr;

    // --------------------------------------------------------------------------
    // Fabric drive.  MmrCs is always a single-cycle one-hot pulse.
    // --------------------------------------------------------------------------
    logic reg_cs;

    assign reg_cs = gnt & ~gnt_ram_rd;

    always_comb begin
        MmrCs = {NUM_MMR_BLOCKS{reg_cs}} & gnt_blk_sel;
        if (NTR_SINK_EN) MmrCs[NTR_SINK_BLK_IDX] = MmrCs[NTR_SINK_BLK_IDX] | (ram_cs &  ram_cs_is_ntr);
        if (DST_SINK_EN) MmrCs[DST_SINK_BLK_IDX] = MmrCs[DST_SINK_BLK_IDX] | (ram_cs & ~ram_cs_is_ntr);
    end

    assign MmrAddr   = ~ram_cs        ? gnt_addr           :
                       ram_cs_is_ntr  ? NTR_RAMDATA_OFFSET : DST_RAMDATA_OFFSET;
    assign MmrWrEn   = gnt & gnt_we;
    assign MmrWrStrb = MmrWrEn ? gnt_strb : '0;
    assign MmrWrData = gnt_data;
    assign MmrRegSel = MmrWrEn;

    // --------------------------------------------------------------------------
    // Response pipe: MMR_PIPE_LAT-deep shift register carrying the pending
    // access, its requester and its captured error condition.  MmrHit plays no
    // part in the timing.
    // --------------------------------------------------------------------------
    logic launch, launch_is_jtag, launch_err;
    logic [MMR_PIPE_LAT-1:0] rsp_vld_sr, rsp_jtag_sr, rsp_err_sr;
    logic rsp_done, rsp_is_jtag;

    assign launch         = reg_cs | ram_cs;
    assign launch_is_jtag = ram_cs ? ram_cs_is_jtag : gnt_is_jtag;
    assign launch_err     = ram_cs ? ram_cs_err     : gnt_err;

    generic_dff #(
        .WIDTH       ($bits(logic [MMR_PIPE_LAT-1:0])),
        .RESET_VALUE ('0)
    ) u_rsp_vld_sr_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    ('1),
        .in    ({rsp_vld_sr [MMR_PIPE_LAT-2:0], launch}),
        .out   (rsp_vld_sr)
    );
    generic_dff #(
        .WIDTH       ($bits(logic [MMR_PIPE_LAT-1:0])),
        .RESET_VALUE ('0)
    ) u_rsp_jtag_sr_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    ('1),
        .in    ({rsp_jtag_sr[MMR_PIPE_LAT-2:0], launch_is_jtag}),
        .out   (rsp_jtag_sr)
    );
    generic_dff #(
        .WIDTH       ($bits(logic [MMR_PIPE_LAT-1:0])),
        .RESET_VALUE ('0)
    ) u_rsp_err_sr_ff (
        .clk   (clk),
        .rst_n (reset_n),
        .en    ('1),
        .in    ({rsp_err_sr [MMR_PIPE_LAT-2:0], launch_err}),
        .out   (rsp_err_sr)
    );

    assign rsp_busy    = |rsp_vld_sr;
    assign rsp_done    = rsp_vld_sr [MMR_PIPE_LAT-1];
    assign rsp_is_jtag = rsp_jtag_sr[MMR_PIPE_LAT-1];

    assign rsp_vld     = rsp_done & ~rsp_is_jtag;
    assign rsp_err     = rsp_err_sr[MMR_PIPE_LAT-1];
    assign jt_rsp_vld  = rsp_done &  rsp_is_jtag;

endmodule
