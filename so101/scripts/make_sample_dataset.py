#!/usr/bin/env python3
"""Save episodes 0-39 of robotpizzacup/robot-pizza-cup-1 as a local LeRobot dataset.

Those 40 episodes are the first video file of each camera (about 380 MB).
The full Hub dataset is about 3 GB. Source indexes 0-39 stay 0-39.

Run from so101:

    uv run python scripts/make_sample_dataset.py
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from lerobot.datasets import LeRobotDataset, delete_episodes

SOURCE_REPO_ID = "robotpizzacup/robot-pizza-cup-1"
SAMPLE_REPO_ID = "robotpizzacup/robot-pizza-cup-1-ep0-39"
EPISODES = list(range(40))


def sample_dir() -> Path:
    return Path(__file__).resolve().parents[2] / "data" / "robot-pizza-cup-1-ep0-39"


def main() -> None:
    output = sample_dir()
    info_path = output / "meta" / "info.json"
    if info_path.is_file():
        info = json.loads(info_path.read_text())
        print(f"Sample ready: {info['total_episodes']} episodes, {info['total_frames']} frames")
        print(output)
        return
    if output.exists():
        shutil.rmtree(output)

    print(f"Downloading episodes 0-39 from {SOURCE_REPO_ID}")
    source = LeRobotDataset(SOURCE_REPO_ID, episodes=EPISODES)
    drop = [idx for idx in range(source.meta.total_episodes) if idx not in EPISODES]
    sample = delete_episodes(
        source,
        episode_indices=drop,
        output_dir=output,
        repo_id=SAMPLE_REPO_ID,
    )
    print(f"Sample ready: {sample.meta.total_episodes} episodes, {sample.meta.total_frames} frames")
    print(output)


if __name__ == "__main__":
    main()
