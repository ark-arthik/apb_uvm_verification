module APB_slave #(
    parameter WAIT_CYCLES = 2 // Unified Control: Set 0 for instant, >0 for delay
)(
    input  wire        PCLK,      
    input  wire        PRESETn,   
    input  wire [4:0]  PADDR,     
    input  wire        PSELx,     
    input  wire        PENABLE,   
    input  wire        PWRITE,    
    input  wire [31:0] PWDATA,    
    output wire        PREADY,    
    output reg  [31:0] PRDATA,    
    output wire        PSLVERR    
);
    
    // Memory array (Still 8 locations)
    reg [31:0] mem [0:7]; 
    integer i;

    // --- Unified Wait State Logic ---
    // This counter tracks how many cycles the slave has been in the ACCESS phase
    reg [7:0] wait_cnt;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            wait_cnt <= 8'd0;
        end 
        else if (PSELx && !PENABLE) begin
            // Setup Phase: Reset counter to 0
            wait_cnt <= 8'd0;
        end 
        else if (PSELx && PENABLE && wait_cnt < WAIT_CYCLES) begin
            // Access Phase: Increment until we hit the target wait cycles
            wait_cnt <= wait_cnt + 1'b1;
        end
    end

    // 1. Unified PREADY: Only goes high when wait_cnt reaches WAIT_CYCLES
    assign PREADY = (wait_cnt == WAIT_CYCLES);

    // --- 2. Synchronous Write Logic (Guarded by PREADY) ---
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            for (i = 0; i < 8; i = i + 1) mem[i] <= 32'h0;
        end
        else begin
            // Added PREADY check: Only write when the slave is actually READY
            if (PSELx && PENABLE && PWRITE && !PSLVERR && PREADY) begin
                mem[PADDR] <= PWDATA;
            end
        end
    end

    // --- 3. Combinational Read Logic (Guarded by PREADY) ---
    always @(*) begin
        PRDATA = 32'h0; 
        // Added PREADY check: Only output data when the slave is actually READY
        if (PSELx && PENABLE && !PWRITE && !PSLVERR && PREADY) begin
            PRDATA = mem[PADDR];
        end
    end
    assign PSLVERR = (PSELx && PENABLE && PREADY && PADDR > 5'd7) ? 1'b1 : 1'b0;
    
endmodule
