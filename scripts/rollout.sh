#!/usr/bin/env bash
# Run a trained policy on the follower (no leader required).
# Usage: bash scripts/rollout.sh <POLICY_PATH>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"

POLICY_PATH="${1:-}"
if [[ -z "$POLICY_PATH" ]]; then
  echo "Usage: bash scripts/rollout.sh <HF_USER/policy or local checkpoint path>" >&2
  exit 2
fi

# shellcheck source=cameras.sh
source "$ROOT/scripts/cameras.sh"

CAMERAS="$(build_cameras_dict)"
echo "Cameras: ${CAMERAS}"

uv run lerobot-rollout \
  --strategy.type=base \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$CAMERAS" \
  --task="$TASK" \
  --duration=30 \
  --display_data=true \
  --policy.path="$POLICY_PATH"
