#!/usr/bin/env bash
# Auto-calibrate the follower bus with the upstream SO-101 sequence.
# It drives motors to mechanical stops. Calibrate the 5 V leader by hand in the web UI.
# Upstream example: norma-core/software/station/examples/so101-autocalibration-py
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"
require_var FOLLOWER_SERIAL

EXAMPLE="${NORMA_CORE_ROOT}/software/station/examples/so101-autocalibration-py/main.py"
if [[ ! -f "$EXAMPLE" ]]; then
  echo "Missing ${EXAMPLE}. Run: bash scripts/install.sh" >&2
  exit 1
fi

echo "Auto-cal moves follower ${FOLLOWER_SERIAL} to mechanical stops. Clear the workspace."
exec python3 "$EXAMPLE" --server "$STATION_HOST" --bus-serial "$FOLLOWER_SERIAL"
