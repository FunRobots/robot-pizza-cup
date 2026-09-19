#!/usr/bin/env bash
# Local Docker smoke test (CPU/amd64). GPU is used in the cloud job.
# Usage: bash scripts/run_docker.sh [--rebuild] [POLICY] [DATASET] [STEPS]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-pizza-robo-hack:dev}"
REBUILD=0
if [[ "${1:-}" == "--rebuild" ]]; then
  REBUILD=1
  shift
fi

POLICY="${1:-act}"
DATASET="${2:-lerobot/pusht}"
STEPS="${3:-20}"
BATCH_SIZE="${BATCH_SIZE:-2}"

mkdir -p "${ROOT}/lerobot-outputs"

if [[ "$REBUILD" -eq 1 ]]; then
  echo "Rebuilding image: $IMAGE"
  docker build --platform linux/amd64 -t "$IMAGE" "$ROOT"
else
  echo "Skipping build — using existing image: $IMAGE (pass --rebuild to build)"
fi

echo "Smoke test: policy=$POLICY dataset=$DATASET steps=$STEPS (CPU expected on macOS)"

docker run --rm \
  --platform linux/amd64 \
  --shm-size 2g \
  -v "${ROOT}/training:/lerobot/training" \
  -v "${ROOT}/lerobot-outputs:/lerobot/outputs" \
  ${HF_TOKEN:+--env "HF_TOKEN=$HF_TOKEN"} \
  ${WANDB_API_KEY:+--env "WANDB_API_KEY=$WANDB_API_KEY"} \
  --env "TRAIN_DEVICE=cpu" \
  "$IMAGE" \
  --policy "$POLICY" \
  --dataset "$DATASET" \
  --steps "$STEPS" \
  --batch-size "$BATCH_SIZE"
