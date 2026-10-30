#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

shopt -s nullglob

rm -rf \
  "$ROOT_DIR/apb_uvm.cache" \
  "$ROOT_DIR/apb_uvm.hw" \
  "$ROOT_DIR/apb_uvm.ip_user_files" \
  "$ROOT_DIR/apb_uvm.sim"

rm -f \
  "$ROOT_DIR"/vivado*.log \
  "$ROOT_DIR"/vivado*.jou \
  "$ROOT_DIR"/vivado_pid*.str \
  "$ROOT_DIR"/*.wdb \
  "$ROOT_DIR"/*.vcd

echo "Generated Vivado/XSim artifacts removed."
