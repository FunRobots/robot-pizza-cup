# Evaluation stubs

Official scoring scripts land here after Gate E in the [technical spec](../docs/03-technical-spec.md).

Until then, use physical success rate:

1. Reset the scene the same way every episode.
2. Run `bash scripts/rollout.sh <policy>` for 10 episodes.
3. Score success / fail by hand.
4. Compare to a teleoperated baseline.

Target for Challenge 1 with ~50 clean ACT episodes on the training configuration: **>70% success**. If you are far below that, collect more consistent data before changing the model.
