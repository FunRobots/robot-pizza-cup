#!/usr/bin/env bash
# CPU pizza-dataset smoke (20 steps, max 200). GPU fine-tune: DevLab lerobot-train or run_serverless.sh.
# Usage: bash training/scripts/train_pizza.sh [POLICY] [STEPS]
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
STEPS="${2:-20}"

if [[ -n "${DATASET_REPO_ID:-}" ]]; then
  DATASET="$DATASET_REPO_ID"
elif [[ -n "${HF_USER:-}" && -n "${DATASET_NAME:-}" ]]; then
  DATASET="${HF_USER}/${DATASET_NAME}"
else
  DATASET="robotpizzacup/robot-pizza-cup-1"
fi

exec bash "$ROOT/training/scripts/train_local.sh" "$POLICY" "$DATASET" "$STEPS"
