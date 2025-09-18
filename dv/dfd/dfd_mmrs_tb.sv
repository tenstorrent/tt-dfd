`timescale 1ns/10ps

module dfd_mmrs_tb 
  import dfd_pkg::*;
	import dfd_cla_csr_pkg::*;
	import dfd_tr_csr_pkg::*;            
	import dfd_mcr_csr_pkg::*;
	import dfd_dst_csr_pkg::*;
	import dfd_ntr_csr_pkg::*;
  ();

  // Clock and Reset
  reg PCLK;
  reg PRESETn;

  // APB Master signals
  reg [DFD_APB_ADDR_WIDTH-1:0] PADDR;
  reg PSEL;
  reg PENABLE;
  reg PWRITE;
  reg [DFD_APB_PSTRB_WIDTH-1:0] PSTRB;
  reg [DFD_APB_DATA_WIDTH-1:0] PWDATA;

  // APB Slave signals
  wire [DFD_APB_DATA_WIDTH-1:0] PRDATA;
  wire PREADY;
  wire PSLVERR;

  // File handling variables
  integer file, status;
  string operation;
  longint address, data;
  int pstrb_err;

  // Register HW RD/WR Intf
  DfdCsrs_s DfdCsrs;
  DfdCsrsWr_s DfdCsrsWr;
  DfdCsrs_s DfdCsrs_external;
  DfdCsrsWr_s DfdCsrsWr_external;

  // Clock generation (50 MHz clock, 20ns period)
  initial begin
    PCLK = 1'b0;
    forever #10 PCLK = ~PCLK; // 50 MHz clock
  end

  // Reset generation
  initial begin
    $display("Start Simulation \n");
    // PRESETn = 1'b1; 
    // #100;
    PRESETn = 1'b0; // Start with reset ACTIVE
    #100;
    PRESETn = 1'b1; // Deassert reset after 100 ticks  
    $display("Reset deasserted at %0t", $time);
  end

  initial begin
    `ifdef FSDB_DEBUG
    $fsdbDumpvars(0, dfd_mmrs_tb, "+fsdbfile+dfd_mmrs_novas.fsdb");
    `endif
  end

  // File-based test case setup
  initial begin
    // Initialize APB signals to prevent X values
    PADDR = '0;
    PSEL = 1'b0;
    PENABLE = 1'b0;
    PWRITE = 1'b0;
    PSTRB = '0;
    PWDATA = '0;
    
    // Wait for reset deassertion
    DfdCsrsWr = '0;
    // @(negedge PRESETn);
    // @(posedge PRESETn);
    wait(PRESETn == 1'b0);  // Wait for reset to be active
    wait(PRESETn == 1'b1);  // Wait for reset to be deasserted
    repeat(5) @(posedge PCLK);  // CRITICAL: Wait for design to settle after reset
    DfdCsrsWr.TrCsrsWr.TrCsrTrramdataWr.Data = 32'hCEED1020;
    DfdCsrsWr.TrCsrsWr.TrCsrTrramdataWr.TrramdataWrEn = 1'b1;


    // Open the input file 
    file = $fopen("dv/dfd/cla_apb_traffic.txt", "r");
    if (file == 0) begin
      $display("Error: Could not open input file!");
      $finish;
    end

    // Read the test cases from the file
    while (!$feof(file)) begin
      // Read operation, address, and data from each line
      status = $fscanf(file, "%s %h %h %h\n", operation, address, data, pstrb_err);
      if (status != 4) begin
        $display("Error: Incorrect file format! Expected format: <operation> <address> <data> <pstrb/err_expected>");
        $finish;
      end

      // Perform the operation
      if (operation == "write") begin
        $display("Performing Write Operation: Address = 0x%0h, Data = 0x%0h, pstrb = 0x%0h", address, data, pstrb_err);
        apb_write(address, data, pstrb_err); // Perform APB write
      end else if (operation == "read") begin
        $display("Performing Read Operation: Address = 0x%0h", address);
        apb_read(address, data, pstrb_err[0]); // Perform APB read
      end else begin
        $display("Error: Unsupported operation '%s'", operation);
      end
    end

    // Close the file after reading
    $fclose(file);

    // End the simulation after executing all test cases
    #1000; // Wait some time before ending simulation
    $finish;
  end

  // APB write task
  task apb_write(input [DFD_APB_ADDR_WIDTH-1:0] address, input [DFD_APB_DATA_WIDTH-1:0] data, input [DFD_APB_PSTRB_WIDTH-1:0] pstrb);
    begin
      @(posedge PCLK);
      PSEL = 1'b1;
      PWRITE = 1'b1;
      PADDR = address;
      PSTRB = pstrb;
      PWDATA = data;
      PENABLE = 1'b0;
      
      @(posedge PCLK);
      PENABLE = 1'b1; // Enable transfer
      
      // Wait for PREADY signal
      while ((!PREADY) && (!PSLVERR)) @(posedge PCLK);
      
      // Complete the transfer
      PSEL = 1'b0;
      PENABLE = 1'b0;

      if (PSLVERR) begin
        $display("Error: Received an PSLVERR");
      end

      $display("Write to address 0x%0h: data 0x%0h", address, data);
    end
  endtask

  // APB read task
  task apb_read(input [DFD_APB_ADDR_WIDTH-1:0] address, input [DFD_APB_DATA_WIDTH-1:0] data, input [0:0] err_expected);
    begin
      @(posedge PCLK);
      PSEL = 1'b1;
      PWRITE = 1'b0;
      PADDR = address;
      PENABLE = 1'b0;
      
      @(posedge PCLK);
      PENABLE = 1'b1; // Enable transfer

      // Wait for PREADY signal
      while ((!PREADY) && (!PSLVERR)) @(posedge PCLK);

      if (PSLVERR) begin
        if (err_expected) begin
          $display("Received an PSLVERR but expected!");
        end else begin
          $display("Error: Received an unexpected PSLVERR!");
        end
      end else if (err_expected) begin
        $display("Error: Expected an PSLVERR but didn't receive error!");
      end else begin
        // Capture the read data
        if (PRDATA != data) begin
          $display("Error: Read Data from 0x%0h: 0x%0h, BUT expected 0x%0h", address, PRDATA, data);
        end else begin
          $display("Read Data from 0x%0h: 0x%0h", address, PRDATA);
        end
      end

      // Complete the transfer
      PSEL = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  // Instantiate the dfd_mmrs module (DUT)
  dfd_mmrs #(
    .INTERNAL_MMRS(1),
    .NTRACE_SUPPORT(1),
    .DST_SUPPORT(1),
    .CLA_SUPPORT(1),
    .NUM_TRACE_INST(1),
    .BASE_ADDR(23'h000000)
  ) dut (
    .clk(PCLK),
    .reset_n(PRESETn),
    .reset_n_warm_ovrride(PRESETn),
    .cold_reset_n(PRESETn),
    // dfd_mmr & modules interface
    .DfdCsrs(DfdCsrs),
    .DfdCsrsWr(DfdCsrsWr),
    // external MMR flatbus (Used if INTERNAL_MMRS == 0)
    .DfdCsrs_external('0),
    .DfdCsrsWr_external(DfdCsrsWr_external),
    // APB Interface (Used if INTERNAL_MMRS == 1)
    .paddr(PADDR),
    .psel(PSEL),
    .penable(PENABLE),
    .pstrb(PSTRB),
    .pwrite(PWRITE),
    .pwdata(PWDATA),
    .pready(PREADY),
    .prdata(PRDATA),
    .pslverr(PSLVERR)
  );

endmodule


