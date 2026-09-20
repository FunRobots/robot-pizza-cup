#!/usr/bin/env bash
# Record leader/follower demonstrations to a LeRobot dataset.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"
# shellcheck source=cameras.sh
source "$ROOT/scripts/cameras.sh"

CAMERAS="$(build_cameras_dict)"
if [[ -z "${HF_USER:-}" || -z "${DATASET_NAME:-}" ]]; then
  echo "Set HF_USER and DATASET_NAME in .env (not station.env)" >&2
  exit 1
fi
REPO_ID="${HF_USER}/${DATASET_NAME}"
ENCODER_THREADS="$(($(camera_count) * 2))"

# H.264 plays in QuickTime/Finder; AV1 (LeRobot default) often does not on macOS.
# macOS: hardware VideoToolbox encoder. Linux: use h264 (software) or h264_vaapi / h264_nvenc.
if [[ "$(uname)" == "Darwin" ]]; then
  VIDEO_CODEC=h264_videotoolbox
else
  VIDEO_CODEC=h264
fi

echo "Recording ${NUM_EPISODES} episodes → ${REPO_ID}"
echo "Task: ${TASK}"
echo "Cameras: ${CAMERAS}"
echo "Video: ${VIDEO_CODEC}  encoder_threads=${ENCODER_THREADS}"
echo "Keys: n/→ next  r/← redo  q/Esc finish"
echo "Hub upload: off (--dataset.push_to_hub=false)"

CACHE_HOME="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}"
DATASET_PARENT="${CACHE_HOME}/${HF_USER}"
mkdir -p "$DATASET_PARENT"

uv run lerobot-record \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$CAMERAS" \
  --teleop.type=so101_leader \
  --teleop.port="$LEADER_PORT" \
  --teleop.id="$LEADER_ID" \
  --display_data=true \
  --dataset.repo_id="$REPO_ID" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes="$NUM_EPISODES" \
  --dataset.episode_time_s="$EPISODE_TIME_S" \
  --dataset.reset_time_s="$RESET_TIME_S" \
  --dataset.rgb_encoder.vcodec="$VIDEO_CODEC" \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads="$ENCODER_THREADS" \
  --dataset.push_to_hub=false

# Newest stamped folder for this DATASET_NAME (lerobot appends _YYYYMMDD_HHMMSS).
LATEST_ROOT="$(ls -td "${DATASET_PARENT}/${DATASET_NAME}"* 2>/dev/null | head -1 || true)"
if [[ -z "$LATEST_ROOT" || ! -d "$LATEST_ROOT" ]]; then
  echo "No local dataset folder found under ${DATASET_PARENT}/${DATASET_NAME}*"
  echo "If you quit before pressing n, nothing was saved."
  exit 0
fi

STAMPED_REPO="${HF_USER}/$(basename "$LATEST_ROOT")"

echo
echo "======== Preview in Rerun (copy-paste) ========"
echo "uv run rerun ${LATEST_ROOT}"
echo "=============================================="
echo "Or: bash scripts/viz_dataset.sh"
echo

echo "Hub upload is off. Optional later:"
echo "  uv run hf upload ${STAMPED_REPO} \\"
echo "    ${LATEST_ROOT} \\"
echo "    --repo-type dataset"
