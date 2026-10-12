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

RENAME_ARGS=()
if [[ -n "${RENAME_MAP:-}" ]]; then
  RENAME_ARGS+=(--rename_map="$RENAME_MAP")
elif [[ "$POLICY_PATH" == *smolvla* ]]; then
  # Robot cameras are front/top; smolvla_base slots are camera1/2/3.
  RENAME_ARGS+=(--rename_map='{"observation.images.front":"observation.images.camera1","observation.images.top":"observation.images.camera2"}')
fi

uv run lerobot-rollout \
  --strategy.type=base \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$CAMERAS" \
  --task="$TASK" \
  --duration=30 \
  --display_data=true \
  --policy.path="$POLICY_PATH" \
  "${RENAME_ARGS[@]}"
