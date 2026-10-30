`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver driver;
    apb_monitor monitor;
    uvm_sequencer #(apb_transaction) sequencer; // Standard UVM sequencer

    function new(string name = "apb_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = apb_driver::type_id::create("driver", this);
        monitor   = apb_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(apb_transaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Wire the Driver's request port to the Sequencer's export
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass

`endif