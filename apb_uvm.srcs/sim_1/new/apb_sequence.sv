`ifndef APB_SEQUENCE_SV
`define APB_SEQUENCE_SV

// ============================================================
// 1. Basic Write/Read Sanity Check (unchanged)
// ============================================================
class apb_sanity_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_sanity_seq)

    function new(string name = "apb_sanity_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;
        bit [4:0] target_addr;

        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 1; paddr <= 7; });
        target_addr = req.paddr;
        finish_item(req);

        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 0; paddr == target_addr; });
        finish_item(req);
    endtask
endclass

// ============================================================
// 2. APB 3.0 Error Check - single OOB address (unchanged)
// ============================================================
class apb_error_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_error_seq)

    function new(string name = "apb_error_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;
        `uvm_info("SEQ", "Intentionally generating Out-Of-Bounds APB Error...", UVM_LOW)

        req = apb_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { pwrite == 1; paddr == 15; });
        finish_item(req);
    endtask
endclass

// ============================================================
// 3. OOB Sweep - exercises ALL 24 out-of-bounds addresses
//    (0x08 - 0x1F) with both a write and a read each.
//    This drives cp_paddr_full and cross_err_op to 100%.
// ============================================================
class apb_oob_sweep_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_oob_sweep_seq)

    function new(string name = "apb_oob_sweep_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;
        `uvm_info("SEQ", "Starting full OOB address sweep (0x08-0x1F, R+W)...", UVM_LOW)

        for (int unsigned addr = 8; addr <= 31; addr++) begin
            // Write to OOB address - expect PSLVERR, write must NOT commit
            req = apb_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { pwrite == 1; paddr == addr[4:0]; });
            finish_item(req);

            // Read from same OOB address - expect PSLVERR again
            req = apb_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { pwrite == 0; paddr == addr[4:0]; });
            finish_item(req);
        end

        `uvm_info("SEQ", "OOB sweep complete.", UVM_LOW)
    endtask
endclass

// ============================================================
// 4. Read-Before-Write - reads every valid address immediately
//    after reset before anything is written to it.
//    Scoreboard must see prdata == 0x0 for each (reset value).
//    This covers the "uninitialised read" scoreboard path and
//    the zero_wait or multi_wait coverage bin depending on
//    the WAIT_CYCLES parameter.
// ============================================================
class apb_read_before_write_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_read_before_write_seq)

    function new(string name = "apb_read_before_write_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;
        `uvm_info("SEQ", "Reading all valid addresses before any write (expect 0x0)...", UVM_LOW)

        for (int unsigned addr = 0; addr <= 7; addr++) begin
            req = apb_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { pwrite == 0; paddr == addr[4:0]; });
            finish_item(req);
        end

        `uvm_info("SEQ", "Read-before-write sweep complete.", UVM_LOW)
    endtask
endclass

// ============================================================
// 5. Back-to-Back Sequence - submits transactions to the
//    sequencer with no deliberate gaps so the driver issues
//    them consecutively (one idle clock between each, which is
//    the minimum achievable with this driver architecture).
//    Exercises idle_cycles_before = 1 in the coverage model.
// ============================================================
class apb_back_to_back_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_back_to_back_seq)

    function new(string name = "apb_back_to_back_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction req;
        `uvm_info("SEQ", "Starting back-to-back write/read pairs...", UVM_LOW)

        // Write all 8 addresses back-to-back
        for (int unsigned addr = 0; addr <= 7; addr++) begin
            req = apb_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { pwrite == 1; paddr == addr[4:0]; });
            finish_item(req);
        end

        // Read all 8 addresses back-to-back
        for (int unsigned addr = 0; addr <= 7; addr++) begin
            req = apb_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { pwrite == 0; paddr == addr[4:0]; });
            finish_item(req);
        end

        `uvm_info("SEQ", "Back-to-back sequence complete.", UVM_LOW)
    endtask
endclass

// ============================================================
// 6. Master Sequence - orchestrates all sequences in order
// ============================================================
class apb_master_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_master_seq)

    apb_read_before_write_seq rbw_seq;   // Must run FIRST (before any writes)
    apb_sanity_seq            sanity_seq;
    apb_back_to_back_seq      b2b_seq;
    apb_error_seq             error_seq;
    apb_oob_sweep_seq         oob_seq;

    function new(string name = "apb_master_seq");
        super.new(name);
    endfunction

    task body();
        rbw_seq    = apb_read_before_write_seq::type_id::create("rbw_seq");
        sanity_seq = apb_sanity_seq::type_id::create("sanity_seq");
        b2b_seq    = apb_back_to_back_seq::type_id::create("b2b_seq");
        error_seq  = apb_error_seq::type_id::create("error_seq");
        oob_seq    = apb_oob_sweep_seq::type_id::create("oob_seq");

        // Phase 1: Read-before-write to verify reset values are 0x0
        rbw_seq.start(m_sequencer);

        // Phase 2: Random write/read hammer for valid-address functional coverage
        repeat(50) begin
            sanity_seq.start(m_sequencer);
        end

        // Phase 3: Back-to-back transfers
        b2b_seq.start(m_sequencer);

        // Phase 4: Single OOB error (kept for compatibility with original test log)
        error_seq.start(m_sequencer);

        // Phase 5: Full OOB sweep - all 24 illegal addresses, both R and W
        oob_seq.start(m_sequencer);

    endtask
endclass

`endif