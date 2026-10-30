#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_DIR="$ROOT_DIR/apb_uvm.sim/sim_1/behav/xsim"
REPORT_DIR="$ROOT_DIR/reports/coverage"

mkdir -p "$REPORT_DIR"

if [[ -d "$SIM_DIR/xsim.covdb" ]]; then
  rm -rf "$REPORT_DIR/xsim.covdb"
  cp -a "$SIM_DIR/xsim.covdb" "$REPORT_DIR/xsim.covdb"
  echo "Copied coverage database to $REPORT_DIR/xsim.covdb"
else
  echo "Coverage database not found at $SIM_DIR/xsim.covdb" >&2
fi

if command -v xcrg >/dev/null 2>&1; then
  echo "xcrg is available; generate the desired HTML or text report from $REPORT_DIR/xsim.covdb using your local Vivado/XSim workflow."
else
  echo "xcrg is not available on PATH; copied the existing coverage database only."
fi
