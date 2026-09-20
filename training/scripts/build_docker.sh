#!/usr/bin/env bash
# Build CUDA training images for cloud GPUs (linux/amd64).
#
# Daily (training/ code changed):
#   bash training/scripts/build_docker.sh --push
#
# Rare (pyproject.toml / uv.lock changed):
#   bash training/scripts/build_docker.sh --target deps --push
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_DIR="${ROOT}/training/docker"

if [[ -f "${ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT}/.env"
  set +a
fi

IMAGE="${IMAGE:-mnrozhkov/pizza-robo-hack:latest}"
DEPS_IMAGE="${DEPS_IMAGE:-mnrozhkov/pizza-robo-hack:deps}"
TARGET="${TARGET:-app}"
PUSH=0
TAG_SET=0
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)
      IMAGE="$2"
      TAG_SET=1
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --push)
      PUSH=1
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

case "$TARGET" in
  deps | cuda-base)
    DOCKERFILE="${DOCKER_DIR}/Dockerfile.deps"
    if [[ "$TAG_SET" -eq 0 ]]; then
      IMAGE="$DEPS_IMAGE"
    fi
    ;;
  app)
    DOCKERFILE="${DOCKER_DIR}/Dockerfile"
    ;;
  *)
    echo "Unknown --target '$TARGET' (expected app, deps, or cuda-base)" >&2
    exit 1
    ;;
esac

echo "Building image=$IMAGE target=$TARGET platform=linux/amd64 file=${DOCKERFILE#"$ROOT"/}"

if [[ "$TARGET" == "app" ]]; then
  echo "Using DEPS_IMAGE=$DEPS_IMAGE"
  if ! docker pull "$DEPS_IMAGE"; then
    if docker image inspect "$DEPS_IMAGE" >/dev/null 2>&1; then
      echo "Hub has no $DEPS_IMAGE — using the local image."
      echo "Publish it with: bash training/scripts/build_docker.sh --target deps --push"
    else
      echo "Missing $DEPS_IMAGE on Hub and locally." >&2
      echo "Build it first: bash training/scripts/build_docker.sh --target deps --push" >&2
      exit 1
    fi
  fi
fi

DOCKER_BUILDKIT=1 docker build \
  --platform linux/amd64 \
  --file "$DOCKERFILE" \
  --target "$TARGET" \
  --build-arg "DEPS_IMAGE=$DEPS_IMAGE" \
  -t "$IMAGE" \
  ${EXTRA_ARGS+"${EXTRA_ARGS[@]}"} \
  "$ROOT"

if [[ "$PUSH" -eq 1 ]]; then
  echo "Pushing $IMAGE"
  docker push "$IMAGE"
fi
