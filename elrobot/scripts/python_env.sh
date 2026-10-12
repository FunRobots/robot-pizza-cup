#!/usr/bin/env bash
# station_py PYTHONPATH. Source in a shell, or run Python: bash scripts/python_env.sh script.py
# shellcheck shell=bash

_elrobot_root="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")/.." && pwd)"
NORMA_CORE_ROOT="${NORMA_CORE_ROOT:-${_elrobot_root}/norma-core}"
_STATION_PY_SHARED="${NORMA_CORE_ROOT}/software/station/shared"

if [[ ! -d "${_STATION_PY_SHARED}/station_py" ]]; then
  echo "Missing station_py at ${_STATION_PY_SHARED}/station_py" >&2
  echo "Run: bash scripts/install.sh" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ ! -d "${NORMA_CORE_ROOT}/target/gen_python" ]]; then
  echo "Missing protobuf stubs at ${NORMA_CORE_ROOT}/target/gen_python" >&2
  echo "Run: bash scripts/install.sh" >&2
  return 1 2>/dev/null || exit 1
fi

export NORMA_CORE_ROOT
export PYTHONPATH="${_STATION_PY_SHARED}:${NORMA_CORE_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  exec python3 "$@"
fi
