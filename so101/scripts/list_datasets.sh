#!/usr/bin/env bash
# List local LeRobot datasets and print ready-to-paste hf upload commands.
set -euo pipefail

CACHE="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}"

if [[ ! -d "$CACHE" ]]; then
  echo "No LeRobot cache at $CACHE" >&2
  exit 0
fi

echo "Local LeRobot datasets under: $CACHE"
echo

found=0
while IFS= read -r -d '' info; do
  root="$(dirname "$(dirname "$info")")"
  namespace="$(basename "$(dirname "$root")")"
  name="$(basename "$root")"
  episodes="$(python3 -c "import json; print(json.load(open('$info')).get('total_episodes', '?'))" 2>/dev/null || echo "?")"
  found=1
  echo "  $namespace/$name  ($episodes episodes)"
  echo "    path: $root"
  echo "    upload: uv run hf upload <namespace>/<repo> \"$root\" --repo-type dataset"
  echo
done < <(find "$CACHE" -path '*/meta/info.json' -not -path '*/calibration/*' -print0 2>/dev/null | sort -z)

if [[ "$found" -eq 0 ]]; then
  echo "  (none — record with: bash scripts/record.sh)"
fi
