`ifndef APB_TEST_SV
`define APB_TEST_SV

// ============================================================
// Test 1: apb_test (original - full coverage run)
// Select with: run_test("apb_test")
// ============================================================
class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env        env;
    apb_master_seq seq;

    function new(string name = "apb_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        seq = apb_master_seq::type_id::create("seq");
        phase.raise_objection(this);
        `uvm_info("TEST", "Starting APB 3.0 Master Sequence...", UVM_LOW)
        seq.start(env.agent.sequencer);
        `uvm_info("TEST", "APB 3.0 Master Sequence Complete.", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

// ============================================================
// Test 2: apb_reset_test
// Runs the standard sequence first, then the mid-test reset
// scenario to verify DUT memory is cleared on PRESETn.
// Select with: run_test("apb_reset_test")
// ============================================================
class apb_reset_test extends uvm_test;
    `uvm_component_utils(apb_reset_test)

    apb_env              env;
    apb_master_seq       main_seq;
    apb_reset_test_seq   reset_seq;

    function new(string name = "apb_reset_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        main_seq  = apb_master_seq::type_id::create("main_seq");
        reset_seq = apb_reset_test_seq::type_id::create("reset_seq");

        phase.raise_objection(this);

        `uvm_info("TEST", "Phase 1: Standard coverage run...", UVM_LOW)
        main_seq.start(env.agent.sequencer);

        `uvm_info("TEST", "Phase 2: Mid-test reset validation...", UVM_LOW)
        reset_seq.start(env.agent.sequencer);

        `uvm_info("TEST", "apb_reset_test complete.", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif