#!/usr/bin/env bash
# Submit lerobot-train to Nebius AI Jobs (one GPU VM per job; no multi-node).
#
# Usage:
#   bash training/scripts/run_serverless.sh [--debug|--resume|--dry-run|--preemptible] [POLICY] [DATASET] [STEPS]
#
# Examples:
#   set -a && source .env && set +a
#   bash training/scripts/run_serverless.sh --debug act          # 500 steps, 1h, proves CUDA + Hub + FS
#   bash training/scripts/run_serverless.sh act 30000
#   bash training/scripts/run_serverless.sh smolvla 20000
#   RUN_NAME=pizza-alice-act-... bash training/scripts/run_serverless.sh --resume act
#
# Required: FILESYSTEM_ID, and usually SUBNET_ID when the project has multiple subnets.
# Organizer defaults: IMAGE, PARENT_ID in .env.example — override for your own project.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DEBUG_MODE=false
RESUME_MODE=false
DRY_RUN=false
PREEMPTIBLE_MODE=false
POSITIONAL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --debug) DEBUG_MODE=true ;;
    --resume) RESUME_MODE=true ;;
    --dry-run) DRY_RUN=true ;;
    --preemptible) PREEMPTIBLE_MODE=true ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

POLICY="${POSITIONAL_ARGS[0]:-act}"
CONFIG="training/policy/${POLICY}/config.yaml"
if [[ ! -f "$CONFIG" ]]; then
  echo "Unknown policy '$POLICY' (expected $CONFIG)" >&2
  exit 1
fi

if [[ -n "${DATASET_REPO_ID:-}" ]]; then
  DATASET="$DATASET_REPO_ID"
elif [[ -n "${HF_USER:-}" && -n "${DATASET_NAME:-}" ]]; then
  DATASET="${HF_USER}/${DATASET_NAME}"
else
  DATASET="mnrozhkov/pizza_hack_v1_fake_ingredients"
fi

STEPS=""
if [[ -n "${POSITIONAL_ARGS[1]:-}" ]]; then
  if [[ "${POSITIONAL_ARGS[1]}" =~ ^[0-9]+$ ]]; then
    STEPS="${POSITIONAL_ARGS[1]}"
  else
    DATASET="${POSITIONAL_ARGS[1]}"
    STEPS="${POSITIONAL_ARGS[2]:-}"
  fi
fi
if [[ "$DEBUG_MODE" == true && -z "$STEPS" ]]; then
  STEPS=500
fi

DATASET_SLUG="${DATASET//\//-}"
USER_SLUG="${HF_USER:-team}"
USER_SLUG="${USER_SLUG//\//-}"

PARENT_ID="${PARENT_ID:-project-e00qfhq9pr00hmgrkch9z4}"
IMAGE="${IMAGE:-mnrozhkov/pizza-robo-hack:latest}"
JOB_PLATFORM="${JOB_PLATFORM:-gpu-l40s-a}"
JOB_PRESET="${JOB_PRESET:-1gpu-24vcpu-96gb}"
JOB_DISK="${JOB_DISK:-450Gi}"
CHECKPOINT_MOUNT="${CHECKPOINT_MOUNT:-/mnt/checkpoints}"
RESTART_POLICY="never"

if [[ "$DEBUG_MODE" == true ]]; then
  JOB_TIMEOUT="${DEBUG_JOB_TIMEOUT:-1h}"
else
  JOB_TIMEOUT="${JOB_TIMEOUT:-6h}"
fi

if [[ -z "${FILESYSTEM_ID:-}" ]]; then
  echo "FILESYSTEM_ID is required (shared POSIX filesystem, not an S3 bucket)." >&2
  echo "Set it in .env. Checkpoints are written under ${CHECKPOINT_MOUNT}/\$HF_USER/<job-name>." >&2
  exit 1
fi

if [[ -z "${HF_USER:-}" ]]; then
  echo "Warning: HF_USER is unset; job paths will use 'team'. Set HF_USER to isolate checkpoints." >&2
fi
if [[ -z "${DATASET_REVISION:-}" ]]; then
  echo "Warning: DATASET_REVISION is not set. Tagged Hub datasets may fail on a fresh container." >&2
fi

if [[ "$RESUME_MODE" == true ]]; then
  if [[ -z "${RUN_NAME:-}" ]]; then
    echo "--resume needs RUN_NAME=<job-name from the original submit>." >&2
    exit 1
  fi
  JOB_NAME="pizza-${USER_SLUG}-${POLICY}-resume-$(date +%Y%m%d%H%M%S)"
  OUTPUT_DIR="${CHECKPOINT_MOUNT}/${USER_SLUG}/${RUN_NAME}"
else
  JOB_NAME="pizza-${USER_SLUG}-${POLICY}-${DATASET_SLUG}-$(date +%Y%m%d%H%M%S)"
  OUTPUT_DIR="${CHECKPOINT_MOUNT}/${USER_SLUG}/${JOB_NAME}"
fi

WANDB_ENABLE=false
if [[ -n "${WANDB_API_KEY:-}" && "${WANDB_MODE:-}" != "disabled" ]]; then
  WANDB_ENABLE=true
fi

HF_TOKEN_VALUE="${HF_TOKEN:-${HUGGING_FACE_HUB_TOKEN:-}}"

if [[ "$RESUME_MODE" == true ]]; then
  ARGS=""
  echo "Resume: OUTPUT_DIR=$OUTPUT_DIR (must contain checkpoints/last/)"
else
  # Do not pass --policy.device / --policy.push_to_hub alone: draccus replaces the
  # whole policy dict and drops `type` (and SmolVLA `path`). Those live in YAML.
  ARGS="--config_path=${CONFIG} --dataset.repo_id=${DATASET} --output_dir=${OUTPUT_DIR} --job_name=${JOB_NAME} --wandb.enable=${WANDB_ENABLE} --wandb.disable_artifact=true"
  if [[ -n "$STEPS" ]]; then
    ARGS+=" --steps=${STEPS}"
  fi
  if [[ -n "${DATASET_REVISION:-}" ]]; then
    ARGS+=" --dataset.revision=${DATASET_REVISION}"
  fi
  if [[ "${POLICY_PUSH_TO_HUB:-}" == "true" ]]; then
    ARGS+=" --policy.type=${POLICY} --policy.push_to_hub=true"
  fi
  if [[ "$WANDB_ENABLE" == true && -n "${WANDB_PROJECT:-}" ]]; then
    ARGS+=" --wandb.project=${WANDB_PROJECT}"
  fi
  if [[ "$WANDB_ENABLE" == true && -n "${WANDB_ENTITY:-}" ]]; then
    ARGS+=" --wandb.entity=${WANDB_ENTITY}"
  fi
fi

echo "Policy=$POLICY Dataset=$DATASET Steps=${STEPS:-<yaml>} Image=$IMAGE Parent=$PARENT_ID"
echo "Job name (save this): $JOB_NAME"
echo "Checkpoints: $OUTPUT_DIR"
echo "Container: train_entrypoint.sh ${ARGS}"
if [[ "$WANDB_ENABLE" == true ]]; then
  echo "W&B: ${WANDB_ENTITY:-<set WANDB_ENTITY>}/${WANDB_PROJECT:-robotpizzacup}"
fi
if [[ "$PREEMPTIBLE_MODE" == true ]]; then
  RESTART_POLICY="on-failure"
  echo "WARNING: preemptible VMs can stop at any time. Auto-resume only works if a" >&2
  echo "checkpoint already exists on the filesystem (see training/README.md)." >&2
  echo "Prefer on-demand GPUs during the event." >&2
fi

CREATE_CMD=(
  nebius ai job create
  --parent-id "$PARENT_ID"
  --name "$JOB_NAME"
  --image "$IMAGE"
  --platform "$JOB_PLATFORM"
  --preset "$JOB_PRESET"
  --timeout "$JOB_TIMEOUT"
  --disk-size "$JOB_DISK"
  --working-dir /lerobot
  --volume "${FILESYSTEM_ID}:${CHECKPOINT_MOUNT}:rw"
  --env "OUTPUT_DIR=${OUTPUT_DIR}"
  --env "TRAIN_DEVICE=cuda"
  --env "HF_HOME=${CHECKPOINT_MOUNT}/hf-cache"
  --restart-policy "$RESTART_POLICY"
  --format "jsonpath={.metadata.id}"
)
if [[ -n "$ARGS" ]]; then
  CREATE_CMD+=(--args "$ARGS")
fi

if [[ "$PREEMPTIBLE_MODE" == true ]]; then
  CREATE_CMD+=(--preemptible)
fi
if [[ "$DRY_RUN" == true ]]; then
  CREATE_CMD+=(--dry-run)
fi
[[ -n "${DATASET_REVISION:-}" ]] && CREATE_CMD+=(--env "DATASET_REVISION=$DATASET_REVISION")
[[ -n "$HF_TOKEN_VALUE" ]] && CREATE_CMD+=(--env "HF_TOKEN=$HF_TOKEN_VALUE")
[[ -n "$HF_TOKEN_VALUE" ]] && CREATE_CMD+=(--env "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN_VALUE")
[[ -n "${WANDB_API_KEY:-}" ]] && CREATE_CMD+=(--env "WANDB_API_KEY=$WANDB_API_KEY")
[[ -n "${WANDB_PROJECT:-}" ]] && CREATE_CMD+=(--env "WANDB_PROJECT=$WANDB_PROJECT")
[[ -n "${WANDB_ENTITY:-}" ]] && CREATE_CMD+=(--env "WANDB_ENTITY=$WANDB_ENTITY")
[[ -n "${RESUME_STEPS:-}" ]] && CREATE_CMD+=(--env "RESUME_STEPS=$RESUME_STEPS")
[[ -n "${SUBNET_ID:-}" ]] && CREATE_CMD+=(--subnet-id "$SUBNET_ID")

echo "Submitting $JOB_NAME"
if [[ "$DRY_RUN" == true ]]; then
  "${CREATE_CMD[@]}"
  echo "Dry-run only — no job created."
  exit 0
fi

JOB_ID=$("${CREATE_CMD[@]}")
echo "Job submitted: $JOB_ID"
echo "Follow: nebius ai job get --id $JOB_ID --format json"
echo "Logs:   nebius ai job logs $JOB_ID --tail 200"
SAVED_NAME="$JOB_NAME"
if [[ "$RESUME_MODE" == true ]]; then
  SAVED_NAME="$RUN_NAME"
fi
echo "Resume later: RUN_NAME=${SAVED_NAME} bash training/scripts/run_serverless.sh --resume ${POLICY}"
