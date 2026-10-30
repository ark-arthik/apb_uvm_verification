`ifndef APB_TRANSACTION_SV
`define APB_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_transaction extends uvm_sequence_item;

    // --- Randomized Inputs (Driven by the Master) ---
    rand bit [4:0]  paddr;
    rand bit [31:0] pwdata;
    rand bit        pwrite;

    // --- Captured Outputs (Received from the Slave) ---
    bit [31:0] prdata;
    bit        pslverr;

    // --- Metadata (Populated by Monitor) ---
    // How many cycles PREADY was held low during the ACCESS phase
    int wait_cycles_seen;
    // How many idle cycles (PSELx=0) elapsed between the previous transaction and this one
    int idle_cycles_before;
    // Special sentinel flag: 1 = this is a reset event, not a real APB transaction.
    // The scoreboard uses this to flush its golden memory model.
    bit is_reset;

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(paddr,              UVM_ALL_ON)
        `uvm_field_int(pwdata,             UVM_ALL_ON)
        `uvm_field_int(pwrite,             UVM_ALL_ON)
        `uvm_field_int(prdata,             UVM_ALL_ON)
        `uvm_field_int(pslverr,            UVM_ALL_ON)
        `uvm_field_int(wait_cycles_seen,   UVM_ALL_ON)
        `uvm_field_int(idle_cycles_before, UVM_ALL_ON)
        `uvm_field_int(is_reset,           UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

    // Constraint: Make reads and writes equally likely
    constraint c_op_type {
        pwrite dist {1 := 50, 0 := 50};
    }

endclass

`endif