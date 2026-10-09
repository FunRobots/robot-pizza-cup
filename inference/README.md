# Inference

Run a trained policy on the SO-101 follower (no leader). Full checklist and cloud download steps: **[Train and deploy — Deploy on the arm](../docs/train-and-deploy.md#deploy-on-arm)**.

`arms/so101/scripts/rollout.sh` builds the camera dict from `arms/so101/station.env` — camera keys (`front`, `top`), resolution, FPS, and `TASK` must match recording.

```bash
cd arms/so101

# Local checkpoint
bash scripts/rollout.sh \
  outputs/train/<run-name>/checkpoints/last/pretrained_model

# After filesystem download
bash scripts/rollout.sh \
  lerobot-outputs/<run-name>/checkpoints/last/pretrained_model
```

For slow VLAs (SmolVLA, π0) on a laptop, add RTC:

```bash
cd arms/so101
set -a && source station.env && set +a
# shellcheck source=cameras.sh
source scripts/cameras.sh

uv run lerobot-rollout \
  --strategy.type=base \
  --inference.type=rtc \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$(build_cameras_dict)" \
  --task="$TASK" \
  --policy.path="$POLICY_PATH"
```

Manual eval scoring: [evaluation/README.md](../evaluation/README.md).
