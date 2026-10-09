# Evaluation stubs

Scoring scripts are not in this repo yet.

Until then, use physical success rate on the SO-101 follower:

1. Reset the scene the same way every episode.
2. From `arms/so101`, run `bash scripts/rollout.sh <policy>` for 10 episodes.
3. Score success / fail by hand.
4. Compare to a teleoperated baseline.

Target for Challenge 1 with ~50 clean ACT episodes on the training configuration: **>70% success**. If you are far below that, collect more consistent data before changing the model.
