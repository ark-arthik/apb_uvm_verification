# Coverage Plan

The coverage model in `apb_coverage.sv` is built around the observed APB transactions and reset sentinel handling.

## Implemented Coverage

- valid address coverage: `0x0` to `0x7`
- full address coverage: valid plus OOB `0x8` to `0x1F`
- read/write operation coverage
- `PSLVERR` coverage
- wait-state coverage
- address x operation cross
- `PSLVERR` x operation cross

## Wait-State Closure

The current run with `WAIT_CYCLES=2` is expected to hit the multi-wait coverage bin.

Additional runs with `WAIT_CYCLES=0` and `WAIT_CYCLES=1` are needed to close the zero-wait and one-wait bins.

## Notes

- Reset sentinels are excluded from coverage sampling.
- The OOB sweep is designed to cover both read and write errors across the illegal address range.
