# Testbench Architecture

This project uses a compact UVM environment built around the existing Vivado source tree.

## File Roles

- `APB_slave.sv`: RTL APB3 slave memory DUT with wait-state control, read data, and `PSLVERR` generation.
- `apb_if.sv`: APB interface carrying bus signals and SystemVerilog assertions for protocol checks.
- `apb_transaction.sv`: UVM sequence item for APB reads and writes, plus metadata captured by the monitor.
- `apb_sequence.sv`: Main traffic sequences, including read-before-write, sanity, OOB sweep, and back-to-back stimulus.
- `apb_reset_seq.sv`: Mid-test reset sequence that asserts `PRESETn` through the interface and validates recovery.
- `apb_driver.sv`: UVM driver that implements APB setup/access timing and waits for `PREADY`.
- `apb_monitor.sv`: Passive monitor that captures completed transfers, wait counts, idle counts, and reset events.
- `apb_agent.sv`: Standard UVM agent that instantiates the driver, monitor, and sequencer.
- `apb_scoreboard.sv`: Golden-model checker that compares reads, tracks writes, and validates OOB error handling.
- `apb_coverage.sv`: Functional coverage subscriber for addresses, operations, errors, and wait states.
- `apb_env.sv`: Environment that connects the agent monitor to the scoreboard and coverage collector.
- `apb_test.sv`: UVM tests that run the main sequence and the reset-validation flow.
- `tb_top.sv`: Simulation top that instantiates the interface, DUT, clock, reset, and UVM configuration.

## Data Flow

1. `tb_top.sv` instantiates `apb_if` and the DUT.
2. The test configures the virtual interface for the driver, monitor, and reset sequence.
3. Sequences generate APB transactions and send them through the sequencer.
4. The driver converts each item into APB bus activity.
5. The monitor observes completed transfers and publishes them.
6. The scoreboard checks correctness against the golden memory model.
7. The coverage subscriber samples the same observed transactions.

## Reset Handling

The reset flow is intentionally simple:

- `PRESETn` starts low at time zero.
- `apb_reset_test_seq` can drive a mid-test reset through the interface.
- The monitor emits a reset sentinel so the scoreboard flushes its expected memory image.

## Important Constraint

No source file locations are changed. The existing Vivado structure remains the authoritative project layout.
