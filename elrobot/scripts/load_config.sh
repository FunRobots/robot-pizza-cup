# Source elrobot/elrobot.env. Caller sets ROOT to elrobot.
# shellcheck shell=bash

ENV_FILE="${ELROBOT_ENV:-$ROOT/elrobot.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing ${ENV_FILE} — copy elrobot.env.example and fill in bus serials." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$ENV_FILE"
set +a

NORMA_CORE_ROOT="${NORMA_CORE_ROOT:-$ROOT/norma-core}"
STATION_HOST="${STATION_HOST:-localhost}"

require_var() {
  local name="$1"
  # Bash 3.2 (macOS): do not combine `local name=… value="${!name}"` on one line — value stays empty.
  local value="${!name:-}"
  if [[ -z "$value" ]]; then
    echo "Set ${name} in ${ENV_FILE}." >&2
    exit 1
  fi
}
