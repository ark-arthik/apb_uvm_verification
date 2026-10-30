`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name = "apb_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get vif")
    endfunction

    task run_phase(uvm_phase phase);
        // 1. Initialize bus to idle state
        vif.PSELx   <= 0;
        vif.PENABLE <= 0;
        vif.PADDR   <= 0;
        vif.PWDATA  <= 0;
        vif.PWRITE  <= 0;

        // --- FIXED: Wait for physical reset to lift! ---
        wait(vif.PRESETn == 1'b1);
        @(posedge vif.PCLK); // Sync to the next clock edge after reset

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    // --- The APB 3.0 Protocol Engine ---
    task drive_transfer(apb_transaction req);
        
        // Wait for the next positive clock edge to align with the synchronous bus
        @(posedge vif.PCLK);

        // --- PHASE 1: SETUP ---
        vif.PSELx   <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PADDR   <= req.paddr;
        vif.PWRITE  <= req.pwrite;
        if (req.pwrite) begin
            vif.PWDATA <= req.pwdata;
        end

        // --- PHASE 2: ACCESS ---
        @(posedge vif.PCLK);
        vif.PENABLE <= 1'b1;

        // --- APB 3.0 WAIT STATE HANDLING ---
        // The master MUST hold the bus steady until the slave drives PREADY high
        forever begin
            @(posedge vif.PCLK);
            if (vif.PREADY === 1'b1) begin
                break; // Slave accepted/provided the data, break the wait loop
            end
        end

        // --- RETURN TO IDLE ---
        // Drop the control signals. (Address and Data can remain as they don't matter unless PSEL is high)
        vif.PSELx   <= 1'b0;
        vif.PENABLE <= 1'b0;

    endtask

endclass

`endif