#!/usr/bin/env bash
# Calibrate follower or leader SO-101.
# Usage: bash scripts/calibrate.sh [follower|leader]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"

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
