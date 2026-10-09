#!/usr/bin/env bash
# Copy a checkpoint from the shared filesystem mount to this machine.
# Usage: bash training/scripts/download_checkpoint.sh <RUN_NAME> [LOCAL_DIR]
#
# The Mac cannot see Nebius FS until you mount it (organizer jump host, or
# CHECKPOINT_FS_ROOT pointing at that mount). Hub alternative:
#   POLICY_PUSH_TO_HUB=true bash training/scripts/run_serverless.sh act 30000
#   bash scripts/rollout.sh "$HF_USER/pizza-act"   # or POLICY_REPO_ID if you overrode it
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

RUN_NAME="${1:-}"
if [[ -z "$RUN_NAME" ]]; then
  echo "Usage: bash training/scripts/download_checkpoint.sh <RUN_NAME> [LOCAL_DIR]" >&2
  echo "Set CHECKPOINT_FS_ROOT to the local mount of the hackathon filesystem." >&2
  exit 2
fi

USER_SLUG="${HF_USER:-team}"
USER_SLUG="${USER_SLUG//\//-}"
FS_ROOT="${CHECKPOINT_FS_ROOT:-}"
LOCAL_DIR="${2:-$ROOT/lerobot-outputs/$RUN_NAME}"

if [[ -z "$FS_ROOT" ]]; then
  echo "CHECKPOINT_FS_ROOT is not set. Mount the shared filesystem and point this" >&2
  echo "variable at it, or roll out from Hugging Face if you trained with POLICY_PUSH_TO_HUB=true." >&2
  echo "Remote layout: /mnt/checkpoints/${USER_SLUG}/${RUN_NAME}/checkpoints/last/pretrained_model" >&2
  exit 1
fi

SRC="${FS_ROOT}/${USER_SLUG}/${RUN_NAME}"
if [[ ! -d "$SRC" ]]; then
  echo "Not found: $SRC" >&2
  exit 1
fi

mkdir -p "$LOCAL_DIR"
echo "Copying $SRC → $LOCAL_DIR"
cp -R "$SRC/." "$LOCAL_DIR/"

CKPT="$LOCAL_DIR/checkpoints/last/pretrained_model"
if [[ -f "$CKPT/config.json" && -f "$CKPT/model.safetensors" ]]; then
  echo "Checkpoint ready: $CKPT"
  echo "Verify: uv run python -m training.eval $CKPT"
  echo "Deploy: bash scripts/rollout.sh $CKPT"
else
  echo "Copied to $LOCAL_DIR — look for checkpoints/last/pretrained_model" >&2
fi
