# Sample datasets

Do not commit large episode files here. Use Hugging Face Hub or Object Storage.

**Recording guide:** [docs/data-collection.md](../../docs/data-collection.md)

## Public smoke-test datasets (no robot required)

| Dataset | Use |
| --- | --- |
| [`lerobot/pusht`](https://huggingface.co/datasets/lerobot/pusht) | Tiny ACT smoke test (local CPU / Docker) |
| [`lerobot/svla_so100_pickplace`](https://huggingface.co/datasets/lerobot/svla_so100_pickplace) | SmolVLA paper-style pick-place reference |

## Your station data

After `bash scripts/record.sh` from `arms/so101`, local files land in:

```text
~/.cache/huggingface/lerobot/${HF_USER}/${DATASET_NAME}_<timestamp>/
```

LeRobot appends a timestamp to each new recording session unless you pass `--dataset.no_stamp=true`. Example:

```text
~/.cache/huggingface/lerobot/your-hf-username/pizza_topping_v1_20260919_145422/
```

Hub URL (after upload):

```text
https://huggingface.co/datasets/${HF_USER}/${DATASET_NAME}_<timestamp>
```

Videos are encoded as **H.264** by `scripts/record.sh` so they play in QuickTime on macOS. LeRobot’s default AV1 codec is smaller but often won’t open in Finder — see [streaming video encoding](https://huggingface.co/docs/lerobot/streaming_video_encoding).

Visualize any LeRobot dataset: https://huggingface.co/spaces/lerobot/visualize_dataset
