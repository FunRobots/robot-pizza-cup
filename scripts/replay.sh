#!/usr/bin/env bash
# Replay one recorded episode on the follower.
# Usage: bash scripts/replay.sh [EPISODE_INDEX]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"

EPISODE="${1:-0}"
if [[ -z "${HF_USER:-}" || -z "${DATASET_NAME:-}" ]]; then
  echo "Set HF_USER and DATASET_NAME in .env" >&2
  exit 1
fi
REPO_ID="${HF_USER}/${DATASET_NAME}"

uv run lerobot-replay \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --dataset.repo_id="$REPO_ID" \
  --dataset.episode="$EPISODE"
