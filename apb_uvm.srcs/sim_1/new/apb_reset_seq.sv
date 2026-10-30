`ifndef APB_RESET_SEQ_SV
`define APB_RESET_SEQ_SV

// ============================================================
// APB Reset Sequence
//
// Validates that a mid-test hardware reset correctly clears all
// DUT memory locations back to 0x0.
//
// Flow:
//   1. Write 0xDEADBEEF to address 3 and read it back (sanity).
//   2. Assert PRESETn=0 (between transactions, not mid-transfer).
//      The monitor detects this negedge and tells the scoreboard
//      to flush its golden memory model.
//   3. Wait for reset to propagate, then deassert.
//   4. Read address 3 - scoreboard expects 0x0 (DUT RAM cleared).
//   5. Write and read address 5 to prove DUT is fully functional
//      after reset recovery.
//
// PRESETn is now an internal logic in apb_if (not a port), so
// this sequence can drive it directly via the virtual interface.
// ============================================================
class apb_reset_test_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_reset_test_seq)

    virtual apb_if reset_vif;

    function new(string name = "apb_reset_test_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;

        if (!uvm_config_db#(virtual apb_if)::get(null, get_full_name(), "reset_vif", reset_vif))
            `uvm_fatal("RESET_SEQ", "reset_vif not found in config_db!")

        // --------------------------------------------------------
        // Step 1: Write a known value so reset has something to erase
        // --------------------------------------------------------
        `uvm_info("RESET_SEQ", "Step 1: Writing 0xDEADBEEF to addr 3", UVM_LOW)
        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 1; paddr == 3; pwdata == 32'hDEADBEEF; });
        finish_item(req);

        // --------------------------------------------------------
        // Step 2: Read it back - should be 0xDEADBEEF
        // --------------------------------------------------------
        `uvm_info("RESET_SEQ", "Step 2: Reading addr 3 - expect 0xDEADBEEF", UVM_LOW)
        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 0; paddr == 3; });
        finish_item(req);

        // --------------------------------------------------------
        // Step 3: Assert reset NOW (between transactions - bus is idle)
        //         The monitor's detect_reset() thread will fire on negedge
        //         PRESETn and broadcast a flush sentinel to the scoreboard.
        // --------------------------------------------------------
        `uvm_info("RESET_SEQ", "Step 3: Asserting PRESETn = 0", UVM_LOW)
        reset_vif.PRESETn = 1'b0;
        repeat(4) @(posedge reset_vif.PCLK);  // Hold reset for 4 cycles
        reset_vif.PRESETn = 1'b1;
        repeat(2) @(posedge reset_vif.PCLK);  // Allow DUT to recover
        `uvm_info("RESET_SEQ", "Step 3: PRESETn restored to 1 - DUT recovered", UVM_LOW)

        // --------------------------------------------------------
        // Step 4: Read addr 3 post-reset - scoreboard's golden model
        //         was cleared by the flush sentinel, so it expects 0x0.
        //         DUT memory was also cleared by reset, so prdata == 0x0.
        // --------------------------------------------------------
        `uvm_info("RESET_SEQ", "Step 4: Reading addr 3 post-reset - expect 0x0", UVM_LOW)
        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 0; paddr == 3; });
        finish_item(req);

        // --------------------------------------------------------
        // Step 5: Full functional check post-reset
        // --------------------------------------------------------
        `uvm_info("RESET_SEQ", "Step 5: Write/read addr 5 to verify DUT is functional post-reset", UVM_LOW)
        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 1; paddr == 5; });
        finish_item(req);

        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 0; paddr == 5; });
        finish_item(req);

        `uvm_info("RESET_SEQ", "Reset sequence complete.", UVM_LOW)
    endtask

endclass

`endif