// =========================================================================
// MODULE: AMBA APB SLAVE INTERFACE & REGISTER FILE
// DESCRIPTION: APB 3.0 compliant slave interface for MAC Core control.
// =========================================================================
module apb_slave (
    // 1. SYSTEM BUS INTERFACE (AMBA APB 3.0)
    input  wire        PCLK,     
    input  wire        PRESETn,  
    input  wire [31:0] PADDR,    
    input  wire        PSEL,     
    input  wire        PENABLE,  
    input  wire        PWRITE,   
    input  wire [31:0] PWDATA,   
    output reg  [31:0] PRDATA,   
    output wire        PREADY,   

    // 2. MAC CORE INTERFACE (INTERNAL SIGNALS)
    output reg         mac_start,   
    output reg         mac_clr_acc, 
    output reg  [15:0] mac_a_in,    
    output reg  [15:0] mac_b_in,    
    input  wire [31:0] mac_out,     
    input  wire        mac_valid_out 
);

    // Slave is always ready (Zero wait states)
    assign PREADY = 1'b1;

    // APB Access Phase decoding
    wire apb_write_en = PSEL & PENABLE &  PWRITE;
    wire apb_read_en  = PSEL & PENABLE & ~PWRITE;

    // =========================================================================
    // PART 1: APB WRITE LOGIC (ADDRESS DECODING & REGISTER UPDATE)
    // =========================================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            mac_start   <= 1'b0;
            mac_clr_acc <= 1'b0;
            mac_a_in    <= 16'd0;
            mac_b_in    <= 16'd0;
        end else begin
            // Pulse generation: Auto-clear control signals after 1 clock cycle
            mac_start   <= 1'b0;  
            mac_clr_acc <= 1'b0;  

            if (apb_write_en) begin
                case (PADDR[7:0])
                    8'h00: begin // Write to CTRL_REG
                        mac_start   <= PWDATA[0]; 
                        mac_clr_acc <= PWDATA[1]; 
                    end
                    8'h08: begin // Write to OP_A_REG
                        mac_a_in    <= PWDATA[15:0]; 
                    end
                    8'h0C: begin // Write to OP_B_REG
                        mac_b_in    <= PWDATA[15:0]; 
                    end
                    default: begin
                        // Do nothing for undefined addresses
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // PART 2: APB READ LOGIC (DATA MULTIPLEXER)
    // =========================================================================
    always @(*) begin
        // Default assignment to prevent latch inference
        PRDATA = 32'd0; 

        if (apb_read_en) begin
            case (PADDR[7:0])
                8'h04: begin // Read STATUS_REG
                    PRDATA[0]    = mac_valid_out; 
                end
                8'h08: begin // Read OP_A_REG
                    PRDATA[15:0] = mac_a_in; 
                end
                8'h0C: begin // Read OP_B_REG
                    PRDATA[15:0] = mac_b_in; 
                end
                8'h10: begin // Read RESULT_REG
                    PRDATA       = mac_out; 
                end
                default: PRDATA = 32'd0;
            endcase
        end
    end

endmodule