#!/usr/bin/env bash
# Mirror the leader bus onto the follower. Serials come from elrobot.env.
# Upstream example: norma-core/software/station/examples/st3215-remote-teleop-py
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"
require_var LEADER_SERIAL
require_var FOLLOWER_SERIAL

EXAMPLE="${NORMA_CORE_ROOT}/software/station/examples/st3215-remote-teleop-py/main.py"
if [[ ! -f "$EXAMPLE" ]]; then
  echo "Missing ${EXAMPLE}. Run: bash scripts/install.sh" >&2
  exit 1
fi

exec python3 "$EXAMPLE" \
  --leader-server "$STATION_HOST" --leader-bus "$LEADER_SERIAL" \
  --follower-server "$STATION_HOST" --follower-bus "$FOLLOWER_SERIAL"
