#!/usr/bin/env bash
# Leader/follower teleop with the station camera.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"
# shellcheck source=cameras.sh
source "$ROOT/scripts/cameras.sh"

CAMERAS="$(build_cameras_dict)"
echo "Cameras: ${CAMERAS}"

uv run lerobot-teleoperate \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$CAMERAS" \
  --robot.num_read_retries=5 \
  --robot.max_relative_target=10 \
  --teleop.type=so101_leader \
  --teleop.port="$LEADER_PORT" \
  --teleop.id="$LEADER_ID" \
  --teleop.num_read_retries=5 \
  --display_data=true
