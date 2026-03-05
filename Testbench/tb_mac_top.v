`timescale 1ns / 1ps

// =========================================================================
// MODULE: TESTBENCH FOR MAC-APB INTEGRATION
// DESCRIPTION: Simulates an AMBA APB Master to verify the MAC Core.
// =========================================================================
module tb_mac_top();

    // =========================================================================
    // SIGNAL DECLARATIONS
    // =========================================================================
    reg         PCLK;
    reg         PRESETn;
    reg  [31:0] PADDR;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;

    // Temporary register for read data monitoring
    reg  [31:0] read_data_temp; 

    // =========================================================================
    // DEVICE UNDER TEST (DUT) INSTANTIATION
    // =========================================================================
    mac_top u_mac_top (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY)
    );

    // =========================================================================
    // CLOCK GENERATION (100MHz -> 10ns Period)
    // =========================================================================
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK; 
    end

    // =========================================================================
    // APB MASTER BUS FUNCTIONAL MODEL (BFM) TASKS
    // =========================================================================
    
    // Task 1: APB Write Transaction
    task apb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge PCLK); 
            // APB Setup Phase
            PADDR   = addr;
            PWDATA  = data;
            PWRITE  = 1'b1;
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            
            @(posedge PCLK); 
            // APB Access Phase
            PENABLE = 1'b1;
            
            @(posedge PCLK);
            // Transaction Complete
            PSEL    = 1'b0;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
        end
    endtask

    // Task 2: APB Read Transaction
    task apb_read(input [31:0] addr, output [31:0] data_out);
        begin
            @(posedge PCLK);
            // APB Setup Phase
            PADDR   = addr;
            PWRITE  = 1'b0; 
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            
            @(posedge PCLK);
            // APB Access Phase
            PENABLE  = 1'b1; 
            
            @(posedge PCLK); 
            // Capture data at the end of Access Phase
            data_out = PRDATA; 
            
            // Transaction Complete
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
    endtask

    // =========================================================================
    // MAIN TEST SCENARIO / STIMULUS
    // =========================================================================
    initial begin
        // 1. INITIALIZATION & SYSTEM RESET
        PRESETn = 1'b0; // Assert active-low reset
        PADDR   = 0; PSEL = 0; PENABLE = 0; PWRITE = 0; PWDATA = 0;
        #20;            
        PRESETn = 1'b1; // Deassert reset
        #10;

        $display("--- BAT DAU TEST APB-MAC ---");

        // 2. WRITE OPERANDS TO SLAVE REGISTERS
        // Addresses: 0x08 = OP_A, 0x0C = OP_B
        apb_write(32'h0000_0008, 32'd15); // Write Operand A = 15
        apb_write(32'h0000_000C, 32'd4);  // Write Operand B = 4
        
        $display("Da ghi Toan hang A = 15, B = 4");

        // 3. TRIGGER MAC OPERATION
        // Address: 0x00 = CTRL_REG, Bit 0 = Start
        apb_write(32'h0000_0000, 32'h0000_0001); 
        $display("Da gui lenh START!");

        // 4. WAIT FOR PIPELINE LATENCY
        // Allow 5 clock cycles for operation to complete safely
        #50;

        // 5. READ & VERIFY RESULTS
        // Read STATUS_REG (0x04) to check valid_out flag
        apb_read(32'h0000_0004, read_data_temp);
        $display("Status Register = %0d", read_data_temp);

        // Read RESULT_REG (0x10) to get MAC output (Expected: 15 * 4 = 60)
        apb_read(32'h0000_0010, read_data_temp);
        $display("Result Register = %0d (Ky vong: 60)", read_data_temp);

        #50;
        $display("--- HOAN THANH MO PHONG ---");
        $finish; // End simulation
    end

endmodule