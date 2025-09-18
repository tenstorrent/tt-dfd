

`ifndef TE_PKG_SVH
`define TE_PKG_SVH

package te_pkg;

  parameter IRETIRE_WIDTH = 4;
  parameter ITYPE_WIDTH = 3;
  parameter NUM_BLOCKS = 2;
  parameter HIST_WIDTH = 32;
  parameter BTYPE_WIDTH = 2;
  parameter PERIODIC_SYNC_COUNT_WIDTH = 20;
  // ----------------------------------------------------------------------
  parameter PC_WIDTH = 64;
  parameter PC_PFX_HI = 63;
  parameter PC_PFX_LO = 12;
  parameter PC_PFX_WIDTH = 4;
  parameter PC_PFX_ENTRIES = 16;
  parameter RETIRE_WIDTH = 4;
  parameter CONTEXT_WIDTH = 32;
  parameter TSTAMP_WIDTH = 64;
  parameter BCNT_WIDTH = 4;
  parameter ICOUNT_WIDTH = 12; 
  parameter TVAL_WIDTH = 64;
  
  parameter MSO_DATA_IN_WIDTH = 64;
  parameter MSO_DATA_OUT_WIDTH_IN_BYTES = 11;
  parameter MSO_DATA_OUT_WIDTH = MSO_DATA_OUT_WIDTH_IN_BYTES*8;
  parameter NUM_MSO = 5;
  parameter NTRACE_MAX_PACKET_WIDTH_IN_BYTES = 32;

  typedef enum logic [1:0] {
    TRIG_TRACE_NONE,
    TRIG_TRACE_ON,
    TRIG_TRACE_OFF,
    TRIG_TRACE_NOTIFY
  } TrigTraceControl_e; 
  
  typedef enum logic [2:0] {
    ITYPE_UNKNOWN,
    ITYPE_EXCEPTION,
    ITYPE_INTERRUPT,
    ITYPE_EXCEPTION_INTERRUPT_RETURN,
    ITYPE_NOT_TAKEN,
    ITYPE_TAKEN,
    ITYPE_JUMP,
    ITYPE_DIRECT_JUMP
  } RetireType_e;

  typedef enum logic [2:0] {
    PRIVMODE_USER = 3'h0,
    PRIVMODE_SUPERVISOR_HYPERVISOR = 3'h1,
    PRIVMODE_MACHINE = 3'h3,
    PRIVMODE_VIRTUAL_USER = 3'h4,
    PRIVMODE_VIRTUAL_SUPERVISOR = 3'h5,
    PRIVMODE_DEBUG = 3'h6
  } PrivMode_e;
  // ----------------------------------------------------------------------

  // Trace Retire Packet
  typedef struct packed {
    logic [PC_PFX_WIDTH-1:0]      PfxId;
    logic [PC_PFX_LO-1:0]         VaLo;
    logic                         isComp;
    RetireType_e                  IType;
  } TrcRetirePkt_s;

  // Branch Target History Buffer Packet
  parameter BTHB_SIZE = 10;
  parameter BTHB_WRPORTS = RETIRE_WIDTH;
  parameter BTHB_RDPORTS = NUM_BLOCKS;
  typedef struct packed {
    logic [IRETIRE_WIDTH-1:0]     ICount;
    logic [ITYPE_WIDTH-1:0]       IType;
    logic                         isError;
    logic [PC_PFX_WIDTH-1:0]      PfxId;
    logic [PC_PFX_LO-1:0]         VaLo;
    logic                         isComp;
  } BTHBPkt_s;

  typedef struct packed {
    logic [IRETIRE_WIDTH-1:0]     ICount;
    logic [ITYPE_WIDTH-1:0]       IType;
    logic                         isError;
    logic [PC_PFX_WIDTH-1:0]      PfxId;
    logic [PC_PFX_LO-1:0]         VaLo;
    logic                         isComp;
    logic [TSTAMP_WIDTH-1:0]      Timestamp;
  } BTHBTstampPkt_s;
  
  typedef enum logic [5:0] {
    OWNERSHIP = 6'h2,
    ERROR = 6'h8,
    PROGTRACESYNC = 6'h9,
    RESOURCEFULL = 6'h1b,
    INDIRECTBRANCHHIST = 6'h1c,
    INDIRECTBRANCHHISTSYNC = 6'h1d,
    REPEATBRANCH = 6'h1e,
    PROGTRACECORRELATION = 6'h21,
    VENDORDEFINED = 6'h38,
    PKT_UNKNOWN = 6'h3F
  } Pkt_TCode_e;

  typedef struct packed {
    logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES-1:0]           pkt_data_be;
    logic [$clog2(NTRACE_MAX_PACKET_WIDTH_IN_BYTES):0]     pkt_data_len;
    logic [NTRACE_MAX_PACKET_WIDTH_IN_BYTES*8-1:0]         pkt_data;
  } pkt_buffer_t;

  typedef enum logic [3:0] { 
    EXTERNAL_TRACE_TRIG = 4'h0,
    EXIT_FROM_RESET = 4'h1,
    PERIODIC_SYNC = 4'h2,
    EXIT_FROM_DEBUG = 4'h3,
    SEQ_INCT_OVERFLOW = 4'h4,
    TRACE_ENABLE = 4'h5,
    TRACE_EVENT = 4'h6,
    RESTART_FIFO_OVERFLOW = 4'h7,
    EXIT_FROM_POWER_DOWN = 4'h9
  } Sync_Cause_e;

  typedef enum logic [3:0] { 
    DEBUG_ENTRY = 4'h0,
    LOW_POWER_ENTRY = 4'h1,
    PROG_TRACE_DISABLE = 4'h4,
    TRACE_STOP_WITHOUT_SYNC_AFTER_ERROR = 4'h8
  } EvCode_e;

  typedef enum logic [1:0] { 
    SYNC_OFF = 2'h0,
    PKT_COUNT = 2'h1,
    CYCLE_COUNT = 2'h2,
    IRETIRE_COUNT = 2'h3
  } InstSyncMode_e;

endpackage

`endif
