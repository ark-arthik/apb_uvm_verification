#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_DIR="$ROOT_DIR/apb_uvm.sim/sim_1/behav/xsim"
REPORT_SIM_DIR="$ROOT_DIR/reports/simulation"
REPORT_COV_DIR="$ROOT_DIR/reports/coverage"

mkdir -p "$REPORT_SIM_DIR" "$REPORT_COV_DIR"

for file in simulate.log compile.log elaborate.log xvlog.log xelab.pb xsim.ini dump.vcd tb_top_behav.wdb; do
  if [[ -f "$SIM_DIR/$file" ]]; then
    cp -f "$SIM_DIR/$file" "$REPORT_SIM_DIR/"
  fi
done

if [[ -d "$SIM_DIR/xsim.covdb" ]]; then
  rm -rf "$REPORT_COV_DIR/xsim.covdb"
  cp -a "$SIM_DIR/xsim.covdb" "$REPORT_COV_DIR/xsim.covdb"
fi

echo "Collected existing Vivado/XSim artifacts into reports/"
