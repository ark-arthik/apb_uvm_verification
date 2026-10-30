# Verification Plan

| Feature                         | Verification Method                               | Status                    |
| ------------------------------- | ------------------------------------------------- | ------------------------- |
| Reset clears memory             | Read-before-write + mid-test reset sequence       | Passing                   |
| Valid APB write                 | Driver writes, scoreboard updates golden model    | Passing                   |
| Valid APB read                  | Monitor captures PRDATA, scoreboard compares      | Passing                   |
| Wait-state handling             | Driver holds bus until PREADY                     | Passing for WAIT_CYCLES=2 |
| Back-to-back traffic            | Dedicated back-to-back sequence                   | Passing                   |
| OOB address handling            | Full 0x08-0x1F read/write sweep                   | Passing                   |
| PSLVERR behavior                | Scoreboard checks error only on invalid addresses | Passing                   |
| APB setup/access timing         | SystemVerilog assertions in apb_if.sv             | Implemented               |
| Functional coverage             | apb_coverage subscriber                           | Implemented               |
| Multiple WAIT_CYCLES regression | Run with WAIT_CYCLES=0/1/2+                       | Future work               |

## Notes

- Reset coverage is exercised both at time zero and during the mid-test reset scenario.
- The current published run uses `WAIT_CYCLES=2`, so multi-wait behavior is covered.
- Additional regression runs are needed to close the zero-wait and one-wait coverage bins.
