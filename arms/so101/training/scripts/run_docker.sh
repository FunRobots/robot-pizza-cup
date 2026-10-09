#!/usr/bin/env bash
# Local Docker smoke test (CPU/amd64). GPU is used in the cloud job.
# Usage: bash training/scripts/run_docker.sh [--rebuild] [POLICY] [DATASET] [STEPS]
#
# Examples:
#   bash training/scripts/run_docker.sh --rebuild act lerobot/pusht 20
#   bash training/scripts/run_docker.sh act 20
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPO="$(cd "${ROOT}/../.." && pwd)"
if [[ -f "${REPO}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${REPO}/.env"
  set +a
fi

IMAGE="${IMAGE:-pizza-robo-hack:dev}"
REBUILD=0
if [[ "${1:-}" == "--rebuild" ]]; then
  REBUILD=1
  shift
fi

POLICY="${1:-act}"
DATASET="${2:-}"
STEPS="${3:-20}"
BATCH_SIZE="${BATCH_SIZE:-2}"
CONFIG="training/policy/${POLICY}/config.yaml"

if [[ -n "${DATASET:-}" && "$DATASET" =~ ^[0-9]+$ ]]; then
  STEPS="$DATASET"
  DATASET=""
fi

mkdir -p "${ROOT}/lerobot-outputs"

if [[ "$REBUILD" -eq 1 ]]; then
  echo "Rebuilding image: $IMAGE"
  bash "${ROOT}/training/scripts/build_docker.sh" --tag "$IMAGE"
else
  echo "Skipping build — using existing image: $IMAGE (pass --rebuild to build)"
fi

echo "Smoke test: policy=$POLICY steps=$STEPS (CPU expected on macOS)"

RUN_ARGS=(
  --config_path="$CONFIG"
  --policy.device=cpu
  --steps="$STEPS"
  --batch_size="$BATCH_SIZE"
  --policy.push_to_hub=false
  --wandb.enable=false
  --output_dir=/lerobot/outputs/smoke
)
if [[ "$POLICY" == "smolvla" ]]; then
  RUN_ARGS+=(--policy.type=smolvla --policy.empty_cameras=1)
fi
if [[ -n "$DATASET" ]]; then
  RUN_ARGS+=(--dataset.repo_id="$DATASET")
fi

docker run --rm \
  --platform linux/amd64 \
  --shm-size 2g \
  -v "${ROOT}/training/policy:/lerobot/training/policy" \
  -v "${ROOT}/lerobot-outputs:/lerobot/outputs" \
  ${HF_TOKEN:+--env "HF_TOKEN=$HF_TOKEN"} \
  ${HF_TOKEN:+--env "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN"} \
  ${DATASET_REVISION:+--env "DATASET_REVISION=$DATASET_REVISION"} \
  --env "TRAIN_DEVICE=cpu" \
  "$IMAGE" \
  "${RUN_ARGS[@]}"
