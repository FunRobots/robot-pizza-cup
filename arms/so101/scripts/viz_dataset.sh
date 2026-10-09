#!/usr/bin/env bash
# Preview a recorded LeRobot dataset in Rerun (video + joints).
# Usage: bash scripts/viz_dataset.sh [DATASET_ROOT]
#        bash scripts/viz_dataset.sh 0 [DATASET_ROOT]  # 0 is ignored (old episode-index)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"

CACHE_HOME="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}"
DATASET_PARENT="${CACHE_HOME}/${HF_USER}"

list_local_datasets() {
  find "$DATASET_PARENT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort
}

newest_matching() {
  local prefix="$1"
  ls -td "${DATASET_PARENT}/${prefix}"* 2>/dev/null | head -1 || true
}

ARG1="${1:-}"
ARG2="${2:-}"

if [[ -n "$ARG2" ]]; then
  DATASET_ROOT="$ARG2"
elif [[ -n "$ARG1" && -d "$ARG1" ]]; then
  DATASET_ROOT="$ARG1"
else
  DATASET_ROOT="$(newest_matching "$DATASET_NAME")"
  if [[ -z "$DATASET_ROOT" || ! -d "$DATASET_ROOT" ]]; then
    DATASET_ROOT="$(ls -td "${DATASET_PARENT}"/*/ 2>/dev/null | head -1 || true)"
    DATASET_ROOT="${DATASET_ROOT%/}"
    if [[ -n "$DATASET_ROOT" && -d "$DATASET_ROOT" ]]; then
      echo "No folder matching DATASET_NAME=${DATASET_NAME}" >&2
      echo "Using newest local dataset instead:" >&2
      echo "  $DATASET_ROOT" >&2
      echo "Available:" >&2
      list_local_datasets | sed 's/^/  /' >&2
    fi
  fi
fi

if [[ -z "$DATASET_ROOT" || ! -d "$DATASET_ROOT" ]]; then
  echo "No dataset folder found under ${DATASET_PARENT}" >&2
  echo "Pass the path:" >&2
  echo "  bash scripts/viz_dataset.sh ${HOME}/.cache/huggingface/lerobot/${HF_USER}/<folder>" >&2
  exit 1
fi

echo "Dataset: ${DATASET_ROOT}"
echo "uv run rerun ${DATASET_ROOT}"
uv run rerun "$DATASET_ROOT"
