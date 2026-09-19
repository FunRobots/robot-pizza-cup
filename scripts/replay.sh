#!/usr/bin/env bash
# Replay one recorded episode on the follower.
# Usage: bash scripts/replay.sh [EPISODE_INDEX]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATION="${STATION_ENV:-$ROOT/hardware/station.env}"
if [[ ! -f "$STATION" ]]; then
  echo "Missing $STATION — copy hardware/station.env.example and fill in ports." >&2
  exit 1
fi
set -a && source "$STATION" && set +a

EPISODE="${1:-0}"
REPO_ID="${HF_USER}/${DATASET_NAME}"

uv run lerobot-replay \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --dataset.repo_id="$REPO_ID" \
  --dataset.episode="$EPISODE"
