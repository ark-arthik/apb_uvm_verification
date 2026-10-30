#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_DIR="$ROOT_DIR/apb_uvm.sim/sim_1/behav/xsim"
SIM_SCRIPT="$SIM_DIR/simulate.sh"

if [[ ! -f "$SIM_SCRIPT" ]]; then
  echo "Expected Vivado simulation script not found: $SIM_SCRIPT" >&2
  exit 1
fi

cd "$SIM_DIR"
exec bash "$SIM_SCRIPT"
