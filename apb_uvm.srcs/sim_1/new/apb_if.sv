`ifndef APB_IF_SV
`define APB_IF_SV

// PRESETn is declared as an internal logic (not a port) so that both
// tb_top AND the reset sequence can drive it at different simulation times.
interface apb_if (input logic PCLK);

    // APB Control & Address
    logic [4:0]  PADDR;
    logic        PSELx;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;

    // APB 3.0 Responses from the Slave
    logic        PREADY;
    logic [31:0] PRDATA;
    logic        PSLVERR;

    // PRESETn is internal so sequences can backdoor-drive it
    logic        PRESETn;

    // =========================================================
    // SYSTEMVERILOG ASSERTIONS (Protocol Compliance)
    // =========================================================

    // 1. Setup Phase Rule: PENABLE must be LOW when PSEL first rises.
    property p_setup_phase;
        @(posedge PCLK) disable iff (!PRESETn)
        $rose(PSELx) |-> !PENABLE;
    endproperty
    assert_setup_phase: assert property (p_setup_phase);

    // 2. Access Phase Rule: PENABLE must follow PSEL exactly one cycle later.
    property p_access_phase;
        @(posedge PCLK) disable iff (!PRESETn)
        $rose(PSELx) |=> PENABLE;
    endproperty
    assert_access_phase: assert property (p_access_phase);

    // 3. Stability Rule: PADDR must stay stable throughout any wait states.
    //    FIXED: antecedent now requires PENABLE so this only fires in the
    //    ACCESS phase, not during the Setup phase where PREADY is irrelevant.
    property p_paddr_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSELx && PENABLE && !PREADY) |=> $stable(PADDR);
    endproperty
    assert_paddr_stable: assert property (p_paddr_stable);

    // 4. Stability Rule: PWDATA must stay stable during a Write's wait states.
    //    FIXED: same correction - PENABLE added to antecedent.
    property p_pwdata_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSELx && PENABLE && PWRITE && !PREADY) |=> $stable(PWDATA);
    endproperty
    assert_pwdata_stable: assert property (p_pwdata_stable);

    // 5. Completion Rule: PENABLE must deassert the cycle after PREADY goes high.
    //    FIXED (was p_trans_end): PSELx is NOT forced low here because a master
    //    may legally keep PSELx high between back-to-back transfers. Only
    //    PENABLE is required to deassert.
    property p_penable_deassert;
        @(posedge PCLK) disable iff (!PRESETn)
        (PENABLE && PREADY) |=> !PENABLE;
    endproperty
    assert_penable_deassert: assert property (p_penable_deassert);

    // 6. APB3 Spec: PSLVERR is only meaningful when PREADY is also asserted.
    //    The DUT gates PSLVERR on PREADY, so this assertion guards
    //    against a regression that drives PSLVERR during wait states.
    property p_slverr_requires_pready;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSELx && PENABLE && PSLVERR) |-> PREADY;
    endproperty
    assert_slverr_requires_pready: assert property (p_slverr_requires_pready);

endinterface

`endif