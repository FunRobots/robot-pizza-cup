#!/usr/bin/env bash
# List SO-101 MotorBus serial ports. Prefer this on macOS over lerobot-find-port.
# Plug in ONE arm at a time; the tty.usbmodem* path is that arm.
set -euo pipefail

shopt -s nullglob
ports=(/dev/tty.usbmodem* /dev/ttyACM* /dev/ttyUSB*)
found=0
for port in "${ports[@]}"; do
  echo "$port"
  found=1
done

if [[ "$found" -eq 0 ]]; then
  echo "No MotorBus found. Plug USB into the Mac (not just the arm PSU), wait 2s, retry." >&2
  exit 1
fi
