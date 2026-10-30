`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// --- Include UVM Architecture ---
`include "apb_if.sv"
`include "apb_transaction.sv"
`include "apb_sequence.sv"
`include "apb_reset_seq.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_agent.sv"
`include "apb_scoreboard.sv"
`include "apb_coverage.sv"
`include "apb_env.sv"
`include "apb_test.sv"

module tb_top;

    // PCLK is the only TB-level signal now.
    // PRESETn has been moved INSIDE apb_if so that sequences can
    // backdoor-drive it without needing a separate hierarchical path.
    logic PCLK;

    // 1. Instantiate the interface (PCLK only - PRESETn is internal)
    apb_if apb_if_inst (.PCLK(PCLK));

    // 2. Instantiate the DUT
    //    Change WAIT_CYCLES to 0 to exercise the zero-wait-state path
    //    and push cp_wait_states.zero_wait in coverage.
    APB_slave #(.WAIT_CYCLES(2)) DUT (
        .PCLK    (PCLK),
        .PRESETn (apb_if_inst.PRESETn),   // driven from inside the interface
        .PADDR   (apb_if_inst.PADDR),
        .PSELx   (apb_if_inst.PSELx),
        .PENABLE (apb_if_inst.PENABLE),
        .PWRITE  (apb_if_inst.PWRITE),
        .PWDATA  (apb_if_inst.PWDATA),
        .PREADY  (apb_if_inst.PREADY),
        .PRDATA  (apb_if_inst.PRDATA),
        .PSLVERR (apb_if_inst.PSLVERR)
    );

    // 3. Clock Generation (100 MHz)
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    // 4. Initial Reset
    //    Drives the interface's internal PRESETn directly.
    //    The reset sequence also drives this same signal for mid-test resets.
    initial begin
        apb_if_inst.PRESETn = 1'b0;
        #20;
        apb_if_inst.PRESETn = 1'b1;
    end

    // 5. UVM Startup
    initial begin
        // Pass the interface handle for the Driver and Monitor
        uvm_config_db #(virtual apb_if)::set(null, "*", "vif",       apb_if_inst);

        // Pass the same handle for the Reset Sequence to drive PRESETn
        uvm_config_db #(virtual apb_if)::set(null, "*", "reset_vif", apb_if_inst);

        // --- Test Selection ---
        // "apb_test"       : full coverage run (read-before-write, 50x random,
        //                    back-to-back, OOB single + full sweep)
        // "apb_reset_test" : all of the above, then mid-test reset validation
        run_test("apb_reset_test");
    end

    // 6. Waveform Dumping
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
