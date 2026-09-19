# Inference

After training, run the follower autonomously with the **same** robot id, camera names (`front`, and `top` if you recorded it), resolution, FPS, and task sentence used during recording. `scripts/rollout.sh` builds the camera dict from `hardware/station.env`.

```bash
bash scripts/rollout.sh ${HF_USER}/act_pizza_topping_v1
# or a local checkpoint:
bash scripts/rollout.sh outputs/train/act/checkpoints/last/pretrained_model
```

For slow VLAs (SmolVLA, π0) on a laptop, add RTC in a one-off command:

```bash
uv run lerobot-rollout \
  --strategy.type=base \
  --inference.type=rtc \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="{ front: {type: opencv, index_or_path: ${CAMERA_INDEX}, width: 640, height: 480, fps: 30}, top: {type: opencv, index_or_path: ${CAMERA_INDEX_TOP}, width: 640, height: 480, fps: 30}}" \
  --task="$TASK" \
  --policy.path="$POLICY_PATH"
```

See [Participant quickstart](../docs/participant_quickstart.md#6-deploy-on-the-arm).
