#!/usr/bin/env bash
# Local training wrapper (uses MPS on Apple Silicon, CUDA if present).
# Usage: bash scripts/train_local.sh [POLICY] [DATASET] [STEPS]
# Examples:
#   bash scripts/train_local.sh act lerobot/pusht 20
#   bash scripts/train_local.sh smolvla $HF_USER/pizza_topping_v1 200
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

POLICY="${1:-act}"
DATASET="${2:-lerobot/pusht}"
STEPS="${3:-20}"
BATCH_SIZE="${BATCH_SIZE:-2}"

uv run python -m training.run \
  --policy "$POLICY" \
  --dataset "$DATASET" \
  --steps "$STEPS" \
  --batch-size "$BATCH_SIZE"
