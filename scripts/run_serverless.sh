#!/usr/bin/env bash
# Submit a LeRobot fine-tune to Nebius AI Jobs.
# Usage: bash scripts/run_serverless.sh [--debug] [POLICY] [DATASET] [STEPS]
#
# Required env (unless --debug): AWS_*, S3_BUCKET, S3_PREFIX, S3_ENDPOINT_URL
# Optional: HF_TOKEN, WANDB_API_KEY, SUBNET_ID, IMAGE, JOB_PLATFORM, JOB_PRESET
set -euo pipefail

DEBUG_MODE=false
POSITIONAL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --debug) DEBUG_MODE=true ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

POLICY="${POSITIONAL_ARGS[0]:-act}"
DATASET="${POSITIONAL_ARGS[1]:-lerobot/pusht}"
STEPS="${POSITIONAL_ARGS[2]:-5000}"
DATASET_SLUG="${DATASET//\//-}"

IMAGE="${IMAGE:-mnrozhkov/lerobot-finetune:v0.1.0}"
JOB_PLATFORM="${JOB_PLATFORM:-gpu-l40s-a}"
JOB_PRESET="${JOB_PRESET:-1gpu-16vcpu-96gb}"
JOB_TIMEOUT="${JOB_TIMEOUT:-6h}"
JOB_DISK="${JOB_DISK:-450Gi}"

echo "Policy=$POLICY Dataset=$DATASET Steps=$STEPS Image=$IMAGE"

required_vars=(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION S3_BUCKET S3_PREFIX S3_ENDPOINT_URL)
missing_vars=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing_vars+=("$var")
  fi
done
if [[ ${#missing_vars[@]} -gt 0 && "$DEBUG_MODE" != true ]]; then
  echo "Missing env: ${missing_vars[*]}" >&2
  echo "Export them, or pass --debug (checkpoint will not persist)." >&2
  exit 1
fi

JOB_NAME="pizza-${POLICY}-${DATASET_SLUG}-$(date +%Y%m%d%H%M%S)"
ARGS="--policy ${POLICY} --dataset ${DATASET} --steps ${STEPS}"

CREATE_CMD=(
  nebius ai job create
  --name "$JOB_NAME"
  --image "$IMAGE"
  --platform "$JOB_PLATFORM"
  --preset "$JOB_PRESET"
  --timeout "$JOB_TIMEOUT"
  --disk-size "$JOB_DISK"
  --args "$ARGS"
  --format "jsonpath={.metadata.id}"
)

for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION S3_BUCKET S3_PREFIX S3_ENDPOINT_URL; do
  if [[ -n "${!var:-}" ]]; then
    CREATE_CMD+=(--env "$var=${!var}")
  fi
done
[[ -n "${HF_TOKEN:-}" ]] && CREATE_CMD+=(--env "HF_TOKEN=$HF_TOKEN")
[[ -n "${WANDB_API_KEY:-}" ]] && CREATE_CMD+=(--env "WANDB_API_KEY=$WANDB_API_KEY")
[[ -n "${SUBNET_ID:-}" ]] && CREATE_CMD+=(--subnet-id "$SUBNET_ID")

echo "Submitting $JOB_NAME"
JOB_ID=$("${CREATE_CMD[@]}")
echo "Job submitted: $JOB_ID"
echo "Follow logs: nebius ai logs $JOB_ID --follow"
