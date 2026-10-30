`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_transaction) ap;

    function new(string name = "apb_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get vif")
    endfunction

    task run_phase(uvm_phase phase);
        // Run both threads in parallel forever
        fork
            detect_reset();
            monitor_transactions();
        join
    endtask

    // ----------------------------------------------------------------
    // Thread 1: Watch for PRESETn falling edge.
    // When it fires, broadcast a sentinel transaction so the scoreboard
    // can flush its golden memory model back to all-zeros.
    // ----------------------------------------------------------------
    task detect_reset();
        forever begin
            @(negedge vif.PRESETn);
            begin
                apb_transaction reset_trans;
                reset_trans          = apb_transaction::type_id::create("reset_trans");
                reset_trans.is_reset = 1'b1;
                ap.write(reset_trans);
                `uvm_info("MON", "PRESETn deasserted - broadcasting reset flush to scoreboard", UVM_LOW)
            end
        end
    endtask

    // ----------------------------------------------------------------
    // Thread 2: Normal APB transaction monitoring.
    // Captures: address, direction, data, pslverr, wait cycle count,
    // and idle cycle count between consecutive transactions.
    // ----------------------------------------------------------------
    task monitor_transactions();
        int wait_count;     // wait states seen in current ACCESS phase
        int idle_count;     // idle cycles since last completed transaction
        bit last_txn_done;  // tracks whether we just finished a transaction

        wait_count    = 0;
        idle_count    = 0;
        last_txn_done = 0;

        forever begin
            @(posedge vif.PCLK);

            // During reset: clear all counters and restart
            if (!vif.PRESETn) begin
                wait_count    = 0;
                idle_count    = 0;
                last_txn_done = 0;
            end else begin

                // Count idle cycles when the bus is quiet between transactions
                if (!vif.PSELx && last_txn_done)
                    idle_count++;

                // Reset wait counter at the START of each new transaction's Setup phase
                // (PSELx high, PENABLE still low means we're in Setup)
                if (vif.PSELx && !vif.PENABLE)
                    wait_count = 0;

                // Accumulate wait states: ACCESS phase but slave not yet ready
                if (vif.PSELx && vif.PENABLE && !vif.PREADY)
                    wait_count++;

                // Transaction completes when all three signals align
                if (vif.PSELx && vif.PENABLE && vif.PREADY) begin
                    apb_transaction trans;
                    trans = apb_transaction::type_id::create("trans");

                    trans.is_reset           = 1'b0;
                    trans.paddr              = vif.PADDR;
                    trans.pwrite             = vif.PWRITE;
                    trans.pslverr            = vif.PSLVERR;
                    trans.wait_cycles_seen   = wait_count;
                    trans.idle_cycles_before = idle_count;

                    if (vif.PWRITE)
                        trans.pwdata = vif.PWDATA;
                    else
                        trans.prdata = vif.PRDATA;

                    ap.write(trans);

                    // Reset per-transaction counters
                    wait_count    = 0;
                    idle_count    = 0;
                    last_txn_done = 1;
                end

            end // else (!PRESETn)
        end // forever
    endtask

endclass

`endif