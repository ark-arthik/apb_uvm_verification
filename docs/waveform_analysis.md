# Waveform Analysis

Example screenshot:

- `docs/images/apb_wait_state_waveform.png`

The waveform shows an APB read transaction with wait-state-aware behavior.

## Observations

- `PSELx` is asserted during the transfer.
- `PENABLE` marks the access phase.
- `PWRITE=0` means this is a read.
- `PREADY` is delayed by the configured wait-state count.
- `wait_cnt` reaches `2`, matching `WAIT_CYCLES=2`.
- `PRDATA` becomes valid when the transfer completes.

## Interpretation

This waveform proves the testbench is checking more than a zero-wait APB transfer. The driver holds the bus active until the slave accepts the access, and the monitor records the number of wait cycles seen so the scoreboard and coverage model can validate the timing behavior.
