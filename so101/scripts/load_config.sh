# Source repo config. Order: repo-root .env (identity, cloud, datasets) then station.env (hardware).
# shellcheck shell=bash
REPO="$(cd "${ROOT}/.." && pwd)"
if [[ -f "${REPO}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${REPO}/.env"
  set +a
fi
STATION="${STATION_ENV:-$ROOT/station.env}"
if [[ ! -f "$STATION" ]]; then
  echo "Missing $STATION — copy station.env.example and fill in ports." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
source "$STATION"
set +a
