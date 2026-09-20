# Source repo config. Order: .env (identity, cloud, datasets) then station.env (hardware).
# shellcheck shell=bash
if [[ -f "${ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT}/.env"
  set +a
fi
STATION="${STATION_ENV:-$ROOT/hardware/station.env}"
if [[ ! -f "$STATION" ]]; then
  echo "Missing $STATION — copy hardware/station.env.example and fill in ports." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
source "$STATION"
set +a
