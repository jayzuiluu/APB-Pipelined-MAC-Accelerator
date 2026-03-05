// =========================================================================
// MODULE: MAC ACCELERATOR TOP
// DESCRIPTION: Top-level wrapper integrating the MAC Core and APB Slave interface.
// =========================================================================
module mac_top (
    // AMBA APB 3.0 System Interface
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire        PREADY
);

    // =========================================================================
    // PART 1: INTERNAL INTERCONNECT (NETS)
    // =========================================================================
    wire        mac_start_wire;
    wire        mac_clr_acc_wire;
    wire [15:0] mac_a_wire;
    wire [15:0] mac_b_wire;
    wire [31:0] mac_out_wire;
    wire        mac_valid_wire;

    // =========================================================================
    // PART 2: APB SLAVE CONTROLLER INSTANTIATION
    // =========================================================================
    apb_slave u_apb_slave (
        // APB Bus Interface
        .PCLK          (PCLK),
        .PRESETn       (PRESETn),
        .PADDR         (PADDR),
        .PSEL          (PSEL),
        .PENABLE       (PENABLE),
        .PWRITE        (PWRITE),
        .PWDATA        (PWDATA),
        .PRDATA        (PRDATA),
        .PREADY        (PREADY),

        // Internal Control & Data Signals to/from MAC Core
        .mac_start     (mac_start_wire),
        .mac_clr_acc   (mac_clr_acc_wire),
        .mac_a_in      (mac_a_wire),
        .mac_b_in      (mac_b_wire),
        .mac_out       (mac_out_wire),
        .mac_valid_out (mac_valid_wire)
    );

    // =========================================================================
    // PART 3: MAC ACCELERATOR CORE INSTANTIATION
    // =========================================================================
    mac_core u_mac_core (
        // System Clock & Reset
        .clk       (PCLK),             
        .rst_n     (PRESETn),          

        // Control & Data Signals from/to APB Slave
        .start     (mac_start_wire),   
        .clr_acc   (mac_clr_acc_wire), 
        .a_in      (mac_a_wire),       
        .b_in      (mac_b_wire),       
        .mac_out   (mac_out_wire),     
        .valid_out (mac_valid_wire)    
    );

endmodule