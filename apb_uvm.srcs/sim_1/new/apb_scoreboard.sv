`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_transaction, apb_scoreboard) item_collected_export;

    // Golden model: associative array acting as a perfect software RAM.
    // Key = address, Value = last written data.
    // When PRESETn fires, this is cleared back to empty (all addresses read as 0).
    bit [31:0] expected_mem [int];

    function new(string name = "apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write(apb_transaction trans);

        // ----------------------------------------------------------------
        // 0. Reset Event: flush the golden model back to all-zeros.
        //    The monitor sends this sentinel when it sees PRESETn fall.
        // ----------------------------------------------------------------
        if (trans.is_reset) begin
            expected_mem.delete();
            `uvm_info("SCB", "PRESETn detected - golden memory model cleared to 0x0", UVM_LOW)
            return;
        end

        // ----------------------------------------------------------------
        // 1. Error Transactions (PSLVERR = 1)
        //    BUG FIX: was '>= 7' which incorrectly flagged address 7 (valid).
        //    DUT fires PSLVERR for PADDR > 7 (i.e. addresses 8-31).
        // ----------------------------------------------------------------
        if (trans.pslverr) begin
            if (trans.paddr > 7) begin
                `uvm_info("SCB", $sformatf("PASS: PSLVERR correctly set for OOB address 0x%0h (op=%s)",
                    trans.paddr, trans.pwrite ? "WRITE" : "READ"), UVM_LOW)
            end else begin
                `uvm_error("SCB", $sformatf("FAIL: Unexpected PSLVERR on valid address 0x%0h!", trans.paddr))
            end
            // Do NOT update golden model - an errored write did not commit.
            return;
        end

        // ----------------------------------------------------------------
        // 2. Successful Write: update the golden model.
        // ----------------------------------------------------------------
        if (trans.pwrite) begin
            expected_mem[trans.paddr] = trans.pwdata;
            `uvm_info("SCB", $sformatf("WRITE  Addr:0x%0h  Data:0x%0h  WaitCycles:%0d",
                trans.paddr, trans.pwdata, trans.wait_cycles_seen), UVM_HIGH)
        end

        // ----------------------------------------------------------------
        // 3. Successful Read: compare against golden model.
        // ----------------------------------------------------------------
        else begin
            if (expected_mem.exists(trans.paddr)) begin
                // Address was previously written - check exact match
                if (expected_mem[trans.paddr] == trans.prdata) begin
                    `uvm_info("SCB", $sformatf("PASS!  Addr:0x%0h  Exp:0x%0h  Act:0x%0h  WaitCycles:%0d",
                        trans.paddr, expected_mem[trans.paddr], trans.prdata,
                        trans.wait_cycles_seen), UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("FAIL!  Addr:0x%0h  Exp:0x%0h  Act:0x%0h",
                        trans.paddr, expected_mem[trans.paddr], trans.prdata))
                end
            end else begin
                // Address never written (or cleared by reset) - DUT must return 0x0
                if (trans.prdata == 32'h0) begin
                    `uvm_info("SCB", $sformatf("PASS!  Read uninitialised Addr:0x%0h returned 0x0 (correct reset value)",
                        trans.paddr), UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("FAIL!  Read uninitialised Addr:0x%0h - Expected 0x0, got 0x%0h",
                        trans.paddr, trans.prdata))
                end
            end
        end

    endfunction

endclass

`endif