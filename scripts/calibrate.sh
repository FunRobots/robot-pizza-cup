#!/usr/bin/env bash
# Calibrate follower or leader SO-101.
# Usage: bash scripts/calibrate.sh [follower|leader]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATION="${STATION_ENV:-$ROOT/hardware/station.env}"
if [[ ! -f "$STATION" ]]; then
  echo "Missing $STATION — copy hardware/station.env.example and fill in ports." >&2
  exit 1
fi
set -a && source "$STATION" && set +a

TARGET="${1:-follower}"
case "$TARGET" in
  follower)
    uv run lerobot-calibrate \
      --robot.type=so101_follower \
      --robot.port="$FOLLOWER_PORT" \
      --robot.id="$FOLLOWER_ID"
    ;;
  leader)
    uv run lerobot-calibrate \
      --teleop.type=so101_leader \
      --teleop.port="$LEADER_PORT" \
      --teleop.id="$LEADER_ID"
    ;;
  *)
    echo "Usage: bash scripts/calibrate.sh [follower|leader]" >&2
    exit 2
    ;;
esac
