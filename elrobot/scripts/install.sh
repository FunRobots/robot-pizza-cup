#!/usr/bin/env bash
# Install NormaCore Station v0.1.0-beta.10: release binary + full norma-core tag.
#
# Layout under elrobot/norma-core/:
#   .git                     — shallow clone of norma-core at STATION_VERSION
#   software/station/...     — station_py and upstream examples
#   software/ai/smolvla_py/  — parquet fine-tune and on-arm deploy
#   target/gen_python/...    — generated protobuf (imported by the examples)
#   shared/gremlin_py/...    — protobuf runtime
#   bin/station              — release CLI (download; not part of the git tree)
#
# Usage:
#   bash scripts/install.sh [--binary-only] [--python-only] [--force]
set -euo pipefail

STATION_VERSION="${STATION_VERSION:-v0.1.0-beta.10}"
GITHUB_REPO="norma-core/norma-core"
GITHUB_CLONE_URL="https://github.com/${GITHUB_REPO}.git"
DOWNLOAD_BASE="https://github.com/${GITHUB_REPO}/releases/download/${STATION_VERSION}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATION_DIR="${NORMA_CORE_ROOT:-${STATION_INSTALL_DIR:-$ROOT/norma-core}}"
BIN_DIR="${STATION_DIR}/bin"
VERSION_FILE="${BIN_DIR}/.station-version"
EXAMPLE_MAIN="${STATION_DIR}/software/station/examples/st3215-remote-teleop-py/main.py"

INSTALL_BINARY=true
INSTALL_PYTHON=true
FORCE=false

usage() {
  echo "Usage: bash scripts/install.sh [--binary-only] [--python-only] [--force]" >&2
  echo "  Shallow-clones the whole norma-core tag into ./norma-core/." >&2
  echo "  Release CLI goes to ./norma-core/bin/station" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary-only) INSTALL_PYTHON=false ;;
    --python-only) INSTALL_BINARY=false ;;
    --force) FORCE=true ;;
    -h | --help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
  shift
done

if ! $INSTALL_BINARY && ! $INSTALL_PYTHON; then
  echo "Nothing to install (use default or drop --binary-only / --python-only)." >&2
  exit 1
fi

# Older installs cloned into ./station. The hackathon tree now uses ./norma-core.
if [[ -z "${NORMA_CORE_ROOT:-}" && -z "${STATION_INSTALL_DIR:-}" \
  && -d "${ROOT}/station" && ! -e "${ROOT}/norma-core" ]]; then
  echo "Moving ${ROOT}/station → ${ROOT}/norma-core"
  mv "${ROOT}/station" "${ROOT}/norma-core"
fi

migrate_legacy_binaries() {
  mkdir -p "$BIN_DIR"
  local name
  for name in station dataset-generator dataset-mp4 .station-version; do
    if [[ -e "${STATION_DIR}/${name}" && ! -e "${BIN_DIR}/${name}" ]]; then
      mv "${STATION_DIR}/${name}" "${BIN_DIR}/"
    fi
  done
}

linux_usb_hint() {
  if [[ "$(uname -s)" != Linux ]]; then
    return
  fi
  if id -nG "$USER" | tr ' ' '\n' | grep -qx dialout; then
    return
  fi
  cat >&2 <<'EOF'

Linux: add your user to the dialout group so Station can open USB servo boards without sudo:
  sudo usermod -a -G dialout $USER
Then log out and back in before you plug in the arms.

EOF
}

platform_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin)
      if [[ "$arch" != arm64 ]]; then
        echo "Station ${STATION_VERSION} supports macOS Apple Silicon only (got Darwin ${arch})." >&2
        exit 1
      fi
      echo "station-macos-arm64.zip"
      ;;
    Linux)
      case "$arch" in
        x86_64 | amd64) echo "station-linux-amd64.tar.gz" ;;
        aarch64 | arm64) echo "station-linux-arm64.tar.gz" ;;
        *)
          echo "Unsupported Linux architecture: ${arch}" >&2
          exit 1
          ;;
      esac
      ;;
    *)
      echo "Unsupported OS: ${os}. Use macOS (Apple Silicon) or Linux." >&2
      exit 1
      ;;
  esac
}

install_cli_binary() {
  local asset="$1"
  local url="$DOWNLOAD_BASE/$asset"
  local tmp archive binary
  binary="${BIN_DIR}/station"

  migrate_legacy_binaries

  if [[ -x "$binary" && -f "$VERSION_FILE" && "$(cat "$VERSION_FILE")" == "$STATION_VERSION" && "$FORCE" == false ]]; then
    echo "Station binary ${STATION_VERSION} already at ${binary}"
    return 0
  fi

  tmp="$(mktemp -d)"
  archive="$tmp/$asset"
  echo "Downloading ${url} ..."
  curl -fsSL -o "$archive" "$url"

  mkdir -p "$BIN_DIR"
  case "$asset" in
    *.zip) unzip -qo "$archive" -d "$BIN_DIR" ;;
    *.tar.gz) tar -xzf "$archive" -C "$BIN_DIR" ;;
    *)
      echo "Unknown archive type: ${asset}" >&2
      exit 1
      ;;
  esac
  rm -rf "$tmp"

  chmod +x "${BIN_DIR}/station" "${BIN_DIR}/dataset-generator" "${BIN_DIR}/dataset-mp4" 2>/dev/null \
    || chmod +x "${BIN_DIR}/station"
  echo "$STATION_VERSION" >"$VERSION_FILE"
  echo "Installed Station binary ${STATION_VERSION} → ${binary}"
}

norma_core_is_current() {
  [[ -d "${STATION_DIR}/.git" && -f "$EXAMPLE_MAIN" ]] || return 1
  local head_tag
  head_tag="$(git -C "$STATION_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)"
  [[ "$head_tag" == "$STATION_VERSION" ]]
}

# Move release binaries, config, and history out of the way so git clone can
# create STATION_DIR. Restored next to the binary under norma-core/bin/.
stash_local_station() {
  local hold="$1"
  [[ -d "$STATION_DIR" ]] || return 0
  local name
  for name in bin station_data station.yaml station dataset-generator dataset-mp4 .station-version; do
    if [[ -e "${STATION_DIR}/${name}" ]]; then
      mv "${STATION_DIR}/${name}" "${hold}/"
    fi
  done
}

restore_local_station() {
  local hold="$1"
  mkdir -p "$BIN_DIR"
  local name item base
  for name in station dataset-generator dataset-mp4 .station-version; do
    if [[ -e "${hold}/${name}" && ! -e "${BIN_DIR}/${name}" ]]; then
      mv "${hold}/${name}" "${BIN_DIR}/"
    fi
  done
  if [[ -d "${hold}/bin" ]]; then
    for item in "${hold}/bin"/* "${hold}/bin"/.[!.]*; do
      [[ -e "$item" ]] || continue
      base="$(basename "$item")"
      if [[ ! -e "${BIN_DIR}/${base}" ]]; then
        mv "$item" "${BIN_DIR}/"
      fi
    done
  fi
  if [[ -f "${hold}/station.yaml" && ! -f "${BIN_DIR}/station.yaml" ]]; then
    mv "${hold}/station.yaml" "${BIN_DIR}/station.yaml"
  fi
  if [[ -d "${hold}/station_data" && ! -d "${BIN_DIR}/station_data" ]]; then
    mv "${hold}/station_data" "${BIN_DIR}/station_data"
  fi
}

clone_norma_core() {
  if [[ "$FORCE" == false ]] && norma_core_is_current; then
    echo "norma-core ${STATION_VERSION} already at ${STATION_DIR}"
    return 0
  fi

  local hold
  hold="$(mktemp -d)"
  stash_local_station "$hold"
  rm -rf "$STATION_DIR"

  echo "Cloning ${GITHUB_CLONE_URL} (${STATION_VERSION}) into ${STATION_DIR} ..."
  if ! git clone --depth 1 --branch "$STATION_VERSION" "$GITHUB_CLONE_URL" "$STATION_DIR"; then
    echo "Clone failed; restoring local Station files." >&2
    mkdir -p "$STATION_DIR"
    restore_local_station "$hold"
    rm -rf "$hold"
    exit 1
  fi
  restore_local_station "$hold"
  rm -rf "$hold"
  echo "Cloned norma-core ${STATION_VERSION} → ${STATION_DIR}"
}

install_station_py() {
  clone_norma_core

  # shellcheck source=python_env.sh
  source "$ROOT/scripts/python_env.sh"
  python3 - <<'PY'
import os
import sys
from pathlib import Path

repo = Path(os.environ["NORMA_CORE_ROOT"])
sys.path.insert(0, str(repo))
from software.station.shared.station_py import new_station_client
from target.gen_python.protobuf.drivers.st3215 import st3215
import shared.gremlin_py.gremlin  # noqa: F401

example = repo / "software/station/examples/st3215-remote-teleop-py/main.py"
root = example.resolve().parent.parent.parent.parent.parent
if root != repo:
    raise SystemExit(f"example sys.path root {root} != {repo}")
print("station_py import check OK")
PY

  local autocal_main="${STATION_DIR}/software/station/examples/so101-autocalibration-py/main.py"
  if [[ ! -f "$autocal_main" ]]; then
    echo "Missing ${autocal_main}" >&2
    exit 1
  fi
  python3 "$EXAMPLE_MAIN" --help >/dev/null
  python3 "$autocal_main" --help >/dev/null
  echo "Example CLIs (teleop, auto-cal) OK"
}

print_next_steps() {
  echo ""
  if $INSTALL_BINARY; then
    linux_usb_hint
    echo "Start Station:  bash scripts/run.sh"
  fi
  if $INSTALL_PYTHON; then
    echo "norma-core:     ${STATION_DIR}  (${STATION_VERSION})"
    echo "Config:         cp elrobot.env.example elrobot.env"
    echo "Teleop:         bash scripts/teleop.sh"
  fi
}

if $INSTALL_BINARY; then
  install_cli_binary "$(platform_asset)"
fi

if $INSTALL_PYTHON; then
  install_station_py
fi

print_next_steps
