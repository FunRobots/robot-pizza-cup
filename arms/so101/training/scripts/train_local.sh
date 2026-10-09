#!/usr/bin/env bash
# Local smoke test via lerobot-train (20 steps). Full runs belong on Nebius GPU.
# Usage: bash training/scripts/train_local.sh [POLICY] [DATASET] [STEPS]
#
# Examples:
#   bash training/scripts/train_local.sh act lerobot/pusht 20
#   bash training/scripts/train_local.sh act mnrozhkov/pizza_hack_v1_fake_ingredients 20
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
  echo "Refusing ${STEPS} local steps. Smoke-test with 20, then:" >&2
  echo "  bash training/scripts/run_serverless.sh --debug ${POLICY}" >&2
  echo "  bash training/scripts/run_serverless.sh ${POLICY} ${STEPS}" >&2
  exit 1
fi

if [[ -n "${TRAIN_DEVICE:-}" ]]; then
  DEVICE="$TRAIN_DEVICE"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  DEVICE="mps"
else
  DEVICE="cpu"
fi

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
if [[ -n "$DATASET" ]]; then
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

echo "Local smoke: policy=$POLICY device=$DEVICE steps=$STEPS (full training is cloud-only)"
"${CMD[@]}"
