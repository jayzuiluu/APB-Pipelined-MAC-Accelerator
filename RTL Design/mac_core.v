// =========================================================================
// MODULE: PIPELINED MAC CORE 
// DESCRIPTION: 32-bit Multiply-Accumulate block with 2-stage pipeline.
// =========================================================================
module mac_core (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              start,
    input  wire              clr_acc,
    input  wire signed [15:0] a_in,     // Operand A (Signed)
    input  wire signed [15:0] b_in,     // Operand B (Signed)
    output wire signed [31:0] mac_out,  // MAC operation result
    output reg               valid_out  // Output valid flag
);

    // =========================================================================
    // PART 1: INTERNAL REGISTERS DECLARATION
    // =========================================================================
    reg signed [31:0] mult_reg; 
    reg signed [31:0] acc_reg;  
    reg               pipe_en;  

    // =========================================================================
    // PART 2: SEQUENTIAL LOGIC
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        // Asynchronous active-low reset
        if (!rst_n) begin
            mult_reg  <= 32'sd0;
            acc_reg   <= 32'sd0;
            pipe_en   <= 1'b0;
            valid_out <= 1'b0;
        end 
        else begin
            // -------------------------------------------------------------
            // PIPELINE STAGE 1: MULTIPLICATION
            // -------------------------------------------------------------
            if (start) begin
                mult_reg <= a_in * b_in;
                pipe_en  <= 1'b1; 
            end else begin
                pipe_en  <= 1'b0;
            end

            // -------------------------------------------------------------
            // PIPELINE STAGE 2: ACCUMULATION & CLEAR CONTROL
            // -------------------------------------------------------------
            // Clear accumulator has highest priority
            if (clr_acc) begin
                acc_reg   <= 32'sd0; // Clear accumulator register
                valid_out <= 1'b0;   // Deassert valid flag
            end 
            else if (pipe_en) begin
                acc_reg   <= acc_reg + mult_reg; // Accumulate multiplier result
                valid_out <= 1'b1;               // Assert valid flag
            end 
            else begin
                valid_out <= 1'b0;               // Deassert valid flag when idle
            end
        end
    end

    // =========================================================================
    // PART 3: OUTPUT ASSIGNMENT
    // =========================================================================
    assign mac_out = acc_reg;

endmodule