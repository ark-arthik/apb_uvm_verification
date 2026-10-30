`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    apb_transaction trans;

    covergroup apb_cg;
        option.per_instance = 1;

        // ------------------------------------------------------------------
        // Coverpoint 1: All valid RAM addresses (0-7).
        // Each address gets its own bin - ensures every slot is exercised.
        // ------------------------------------------------------------------
        cp_paddr: coverpoint trans.paddr {
            bins all_ram_addrs[] = {[0:7]};
            // OOB addresses are ignored here; they appear in cp_paddr_full below.
            ignore_bins oob = {[8:31]};
        }

        // ------------------------------------------------------------------
        // Coverpoint 2: Full 5-bit address space.
        // Splits valid vs. out-of-bounds (8-31) to confirm OOB sweep ran.
        // ------------------------------------------------------------------
        cp_paddr_full: coverpoint trans.paddr {
            bins valid_addrs[] = {[0:7]};
            bins oob_addrs[]   = {[8:31]};
        }

        // ------------------------------------------------------------------
        // Coverpoint 3: Read / Write direction.
        // ------------------------------------------------------------------
        cp_pwrite: coverpoint trans.pwrite {
            bins read_op  = {0};
            bins write_op = {1};
        }

        // ------------------------------------------------------------------
        // Coverpoint 4: PSLVERR - were errors seen and suppressed correctly?
        // ------------------------------------------------------------------
        cp_pslverr: coverpoint trans.pslverr {
            bins no_error    = {0};
            bins error_fired = {1};
        }

        // ------------------------------------------------------------------
        // Coverpoint 5: Wait-state depth seen during transactions.
        // With WAIT_CYCLES=0  → zero_wait fires.
        // With WAIT_CYCLES=2  → multi_wait fires.
        // Running the testbench with different WAIT_CYCLES parameters will
        // push coverage into all three bins.
        // ------------------------------------------------------------------
        cp_wait_states: coverpoint trans.wait_cycles_seen {
            bins zero_wait  = {0};
            bins one_wait   = {1};
            bins multi_wait = {[2:$]};
        }

        // ------------------------------------------------------------------
        // Cross 1: Read AND Write to EVERY valid address.
        // ------------------------------------------------------------------
        cross_addr_op: cross cp_paddr, cp_pwrite;

        // ------------------------------------------------------------------
        // Cross 2: Errors on both reads AND writes.
        // Confirms the OOB sequence hit both directions.
        // ------------------------------------------------------------------
        cross_err_op: cross cp_pwrite, cp_pslverr;

    endgroup

    function new(string name = "apb_coverage", uvm_component parent);
        super.new(name, parent);
        apb_cg = new();
    endfunction

    virtual function void write(apb_transaction t);
        // Skip the reset sentinel - it carries no coverage-relevant fields
        if (t.is_reset) return;
        trans = t;
        apb_cg.sample();
    endfunction

endclass

`endif