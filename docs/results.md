# Results

The recorded passing run is the `apb_reset_test` flow executed with Vivado/XSim 2023.2.

## Run Summary

- Tool: Vivado/XSim 2023.2
- Test: `apb_reset_test`
- UVM_INFO: `142`
- UVM_WARNING: `0`
- UVM_ERROR: `0`
- UVM_FATAL: `0`
- Simulation completed at `8985 ns`
- XSim ran for `100000 ns`

## Evidence From the Log

The simulation transcript in `apb_uvm.sim/sim_1/behav/xsim/simulate.log` shows the transaction-by-transaction PASS messages, and the matching Vivado backup log for the same run contains the final summary block.

Observed scoreboard passes include:

- read-before-write
- valid write/read
- back-to-back transfers
- OOB `PSLVERR` checks
- mid-test reset recovery

## Key Passes

- Reads of untouched valid addresses returned `0x0` after reset.
- Valid write/read pairs matched the scoreboard golden model.
- Back-to-back valid transactions completed with `WAIT_CYCLES=2`.
- OOB reads and writes from `0x08` to `0x1F` asserted `PSLVERR`.
- A mid-test reset cleared the DUT memory and the scoreboard model.

## Note

The raw `simulate.log` file in this checkout stops before the summary footer, so the final counts are taken from the matching Vivado backup log of the same run.
