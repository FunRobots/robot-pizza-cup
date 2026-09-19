# Hardware calibration

LeRobot stores SO-101 calibration under `~/.cache/huggingface/lerobot/calibration/`, keyed by `--robot.id` / `--teleop.id`.

Reuse the same ids (`FOLLOWER_ID`, `LEADER_ID` in `hardware/station.env`) for:

- `lerobot-calibrate`
- `lerobot-teleoperate`
- `lerobot-record`
- `lerobot-replay`
- `lerobot-rollout`

If you change the id, you are starting a new robot identity and must recalibrate.

## Procedure

1. Power both arms. Confirm every motor LED is a steady red from gripper to base.
2. Source `hardware/station.env`.
3. Run `bash scripts/calibrate.sh follower`, then `bash scripts/calibrate.sh leader`.
4. Move the arm to the mid-range pose, press Enter, then sweep **each joint through its full range**.

See [Participant quickstart](../docs/participant_quickstart.md) for the full command sequence.
