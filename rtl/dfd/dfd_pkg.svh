package dfd_pkg;



    import dfd_cla_csr_pkg::ClaCsrs_s;
    import dfd_tr_csr_pkg::TrCsrs_s;
    import dfd_mcr_csr_pkg::McrCsrs_s;
    import dfd_ntr_csr_pkg::NtrCsrs_s;
    import dfd_dst_csr_pkg::DstCsrs_s;

    import dfd_ntr_csr_pkg::NtrCsrsWr_s;
    import dfd_dst_csr_pkg::DstCsrsWr_s;
    import dfd_cla_csr_pkg::ClaCsrsWr_s;
    import dfd_tr_csr_pkg::TrCsrsWr_s;

    parameter DFD_APB_DATA_WIDTH = 32;
    parameter DFD_APB_ADDR_WIDTH = 23;
    localparam DFD_APB_PSTRB_WIDTH = DFD_APB_DATA_WIDTH / 8;
    
    parameter MAX_NUM_TRACE_INST = 8; 

    typedef struct packed {
        DstCsrs_s [MAX_NUM_TRACE_INST-1:0] DstCsrs;
        NtrCsrs_s [MAX_NUM_TRACE_INST-1:0] NtrCsrs;
        ClaCsrs_s [MAX_NUM_TRACE_INST-1:0] ClaCsrs;
        TrCsrs_s  TrCsrs;
        McrCsrs_s McrCsrs;
    } DfdCsrs_s;

    typedef struct packed {
        DstCsrsWr_s [MAX_NUM_TRACE_INST-1:0] DstCsrsWr;
        NtrCsrsWr_s [MAX_NUM_TRACE_INST-1:0] NtrCsrsWr;
        ClaCsrsWr_s [MAX_NUM_TRACE_INST-1:0] ClaCsrsWr;
        TrCsrsWr_s  TrCsrsWr;
    } DfdCsrsWr_s;

endpackage




