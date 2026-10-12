#!/usr/bin/env bash
# Export a Station history range to parquet, then preview it as mp4.
# Frame pointers come from History tags in the web UI.
#
# Usage: bash scripts/export_dataset.sh <start-frame> <end-frame>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash scripts/export_dataset.sh <start-frame> <end-frame>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=load_config.sh
source "$ROOT/scripts/load_config.sh"
require_var TASK

START_FRAME="$1"
END_FRAME="$2"
EPISODE_DURATION="${EPISODE_DURATION:-45}"
DATASET_OUTPUT="${DATASET_OUTPUT:-../data/elrobot-pizza}"
# Expand ~ and resolve relative paths from elrobot/ (not the caller's cwd).
DATASET_OUTPUT="${DATASET_OUTPUT/#\~/$HOME}"
if [[ "$DATASET_OUTPUT" != /* ]]; then
  DATASET_OUTPUT="$(cd "$ROOT" && cd "$(dirname "$DATASET_OUTPUT")" && pwd)/$(basename "$DATASET_OUTPUT")"
fi

GENERATOR="${NORMA_CORE_ROOT}/bin/dataset-generator"
MP4="${NORMA_CORE_ROOT}/bin/dataset-mp4"
if [[ ! -x "$GENERATOR" ]]; then
  echo "Missing ${GENERATOR}. Run: bash scripts/install.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$DATASET_OUTPUT")"
"$GENERATOR" \
  -episode.duration "$EPISODE_DURATION" \
  -from "$START_FRAME" \
  -to "$END_FRAME" \
  -robot "$STATION_HOST" \
  -output "$DATASET_OUTPUT" \
  -task "$TASK"

PARQUET="${DATASET_OUTPUT}.parquet"
if [[ ! -f "$PARQUET" && -f "$DATASET_OUTPUT" ]]; then
  PARQUET="$DATASET_OUTPUT"
fi
if [[ ! -f "$PARQUET" ]]; then
  echo "Export finished but no parquet at ${DATASET_OUTPUT} or ${DATASET_OUTPUT}.parquet" >&2
  exit 1
fi
if [[ ! -x "$MP4" ]]; then
  echo "Parquet: ${PARQUET}"
  exit 0
fi

"$MP4" --input "$PARQUET" --output "${PARQUET%.parquet}.mp4"
echo "Parquet: ${PARQUET}"
echo "Video:   ${PARQUET%.parquet}.mp4"
