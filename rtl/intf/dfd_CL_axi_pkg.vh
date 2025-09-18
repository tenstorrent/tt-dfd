`include "axi/typedef.svh"

package dfd_CL_axi_pkg;

   localparam Dfd_SRCID = 4'h3;

    localparam int unsigned DfdNumMasters            = 4;
    localparam int unsigned DfdAxiIdWidthSlvPorts    = 10;
    localparam int unsigned DfdAxiIdWidthMstPorts    = DfdAxiIdWidthSlvPorts + $clog2(DfdNumMasters);

    localparam int unsigned DfdTrAxiAddrWidth          = 52;
    localparam int unsigned DfdTrAxiDataWidth          = 512;
    localparam int unsigned DfdAxiStrbWidth          = DfdTrAxiDataWidth / 8;
    localparam int unsigned DfdAxiUserWidth          = 8;


    typedef logic [DfdAxiIdWidthSlvPorts-1:0] dfd_id_slv_t;
    typedef logic [DfdAxiIdWidthMstPorts-1:0] dfd_id_mst_t;
    typedef logic       [DfdTrAxiAddrWidth-1:0]   dfd_addr_t;
    typedef logic       [DfdTrAxiDataWidth-1:0]   dfd_data_t;
    typedef logic       [DfdAxiStrbWidth-1:0]   dfd_strb_t;
    typedef logic       [DfdAxiUserWidth-1:0]   dfd_user_t;

    `AXI_TYPEDEF_ALL_CT(dfd_mst, dfd_mst_axi_req_t, dfd_mst_axi_rsp_t, dfd_addr_t, dfd_id_mst_t, dfd_data_t, dfd_strb_t, dfd_user_t)
    `AXI_TYPEDEF_ALL_CT(dfd_slv, dfd_slv_axi_req_t, dfd_slv_axi_rsp_t, dfd_addr_t, dfd_id_slv_t, dfd_data_t, dfd_strb_t, dfd_user_t)    

    localparam int unsigned TrAxiIdWidthSlvPorts = DfdAxiIdWidthSlvPorts - 1;
    typedef logic [TrAxiIdWidthSlvPorts-1:0] dfd_tr_id_slv_t;

    `AXI_TYPEDEF_ALL_CT(dfd_tr_slv, dfd_tr_slv_axi_req_t, dfd_tr_slv_axi_rsp_t, dfd_addr_t, dfd_tr_id_slv_t, dfd_data_t, dfd_strb_t, dfd_user_t) 

    
    localparam int unsigned DfdAxiAddrWidth          = 23;
    localparam int unsigned DfdAxiDataWidth          = 64;

endpackage



