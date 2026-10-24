#!/usr/bin/env bash
# CPU dev smoke via lerobot-train (20 steps, max 200). GPU fine-tune: DevLab lerobot-train or a Job.
# Usage: bash training/scripts/train_local.sh [POLICY] [DATASET] [STEPS]
#
# Examples:
#   bash training/scripts/train_local.sh act lerobot/pusht 20
#   bash training/scripts/train_local.sh act robotpizzacup/robot-pizza-cup-1 20
#   bash training/scripts/train_local.sh act ../data/robot-pizza-cup-1-ep0-39 20
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPO="$(cd "${ROOT}/.." && pwd)"
if [[ -f "${REPO}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${REPO}/.env"
  set +a
fi

POLICY="${1:-act}"
DATASET="${2:-}"
STEPS="${3:-20}"
BATCH_SIZE="${BATCH_SIZE:-2}"
CONFIG="${ROOT}/training/policy/${POLICY}/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  echo "Unknown policy '$POLICY' (expected training/policy/${POLICY}/config.yaml)" >&2
  exit 1
fi

if [[ "$STEPS" -gt 200 ]]; then
  echo "Refusing ${STEPS} steps. train_local.sh is a CPU dev smoke (max 200)." >&2
  echo "  DevLab: uv run lerobot-train --config_path=training/policy/${POLICY}/config.yaml --policy.device=cuda --steps=${STEPS}" >&2
  echo "  Job:    bash training/scripts/run_serverless.sh ${POLICY} ${STEPS}" >&2
  exit 1
fi

# CPU unless the caller sets TRAIN_DEVICE. GPU fine-tunes do not use this script.
DEVICE="${TRAIN_DEVICE:-cpu}"

WANDB_ENABLE=false
if [[ -n "${WANDB_API_KEY:-}" && "${WANDB_MODE:-}" != "disabled" ]]; then
  WANDB_ENABLE=true
fi

CMD=(
  uv run lerobot-train
  --config_path="$CONFIG"
  --policy.device="$DEVICE"
  --steps="$STEPS"
  --batch_size="$BATCH_SIZE"
  --policy.push_to_hub=false
  --wandb.enable="$WANDB_ENABLE"
)
if [[ "$POLICY" == "smolvla" ]]; then
  CMD+=(--policy.type=smolvla --policy.empty_cameras=1)
fi
if [[ -n "$DATASET" && -d "$DATASET" ]]; then
  DATASET_PATH="$(cd "$DATASET" && pwd)"
  CMD+=(--dataset.root="$DATASET_PATH" --dataset.repo_id="local/$(basename "$DATASET_PATH")")
elif [[ -n "$DATASET" ]]; then
  CMD+=(--dataset.repo_id="$DATASET")
fi
if [[ -n "${DATASET_REVISION:-}" ]]; then
  CMD+=(--dataset.revision="$DATASET_REVISION")
fi
if [[ "$WANDB_ENABLE" == true && -n "${WANDB_PROJECT:-}" ]]; then
  CMD+=(--wandb.project="$WANDB_PROJECT")
fi
if [[ "$WANDB_ENABLE" == true && -n "${WANDB_ENTITY:-}" ]]; then
  CMD+=(--wandb.entity="$WANDB_ENTITY")
fi

echo "CPU smoke: policy=$POLICY device=$DEVICE steps=$STEPS"
"${CMD[@]}"
