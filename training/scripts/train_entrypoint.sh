#!/usr/bin/env bash
# Container entrypoint for Nebius jobs.
# If OUTPUT_DIR already has a LeRobot checkpoint, resume from it.
# Otherwise run `lerobot-train` with the job's argv (fresh run).
set -euo pipefail

DEVICE="${TRAIN_DEVICE:-cuda}"
OUT="${OUTPUT_DIR:-}"
LAST="${OUT}/checkpoints/last/pretrained_model/train_config.json"

if [[ -n "$OUT" && -f "$LAST" ]]; then
  echo "Resuming from $LAST"
  extra=()
  if [[ -n "${RESUME_STEPS:-}" ]]; then
    extra+=(--steps="${RESUME_STEPS}")
  fi
  # Do not pass --policy.device: it replaces the checkpoint policy dict and drops `type`.
  exec lerobot-train \
    --config_path="$LAST" \
    --resume=true \
    "${extra[@]}"
fi

exec lerobot-train "$@"
