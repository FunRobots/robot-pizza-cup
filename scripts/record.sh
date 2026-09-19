#!/usr/bin/env bash
# Record leader/follower demonstrations to a LeRobot dataset.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATION="${STATION_ENV:-$ROOT/hardware/station.env}"
if [[ ! -f "$STATION" ]]; then
  echo "Missing $STATION — copy hardware/station.env.example and fill in ports." >&2
  exit 1
fi
set -a && source "$STATION" && set +a
# shellcheck source=cameras.sh
source "$ROOT/scripts/cameras.sh"

CAMERAS="$(build_cameras_dict)"
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
  --dataset.encoder_threads="$ENCODER_THREADS"
