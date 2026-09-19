# Participant quickstart — SO-101 + LeRobot

Teach the follower arm a pizza task in this order:

```text
Install → find ports → (one-time) motor IDs → calibrate → teleoperate → record → train → rollout
```

Official references:

- LeRobot install: https://huggingface.co/docs/lerobot/installation
- SO-101 hardware: https://huggingface.co/docs/lerobot/so101
- Imitation learning on real robots: https://huggingface.co/docs/lerobot/il_robots
- SmolVLA: https://huggingface.co/docs/lerobot/smolvla
- Cloud fine-tune pattern: [lerobot-finetune-job](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/lerobot-finetune-job) and [smolva-ft-norma-core](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/smolva-ft-norma-core)

This machine is macOS Apple Silicon. Robot control and data collection run in a local `uv` venv (MPS). Real training runs in Docker / Nebius GPU jobs (CUDA).

---

## 0. What you need

| Item | Notes |
| --- | --- |
| SO-101 follower + leader | Powered, daisy-chained, matching voltage PSU |
| 1–2 USB webcams | Fixed mounts, 640×480 @ 30 FPS. Front is required; overhead (`top`) is optional |
| Hugging Face account | `hf auth login` to push datasets |
| `uv` | Already used by this repo |
| `ffmpeg` | `brew install ffmpeg` (already typical on this Mac) |
| Docker (optional) | Local CPU smoke test of the cloud image |
| Nebius CLI (optional) | GPU fine-tune |

---

## 1. Install (local uv environment)

From the repo root:

```bash
uv python install 3.12
uv sync
source .venv/bin/activate
hf auth login
```

This pulls LeRobot **0.6.1** (current PyPI release) with:

| Extra | Why |
| --- | --- |
| `core_scripts` | `lerobot-calibrate`, `lerobot-record`, `lerobot-replay`, `lerobot-teleoperate` |
| `training` | `lerobot-train`, W&B, datasets |
| `feetech` | SO-101 motors |
| `smolvla` | headline VLA |
| `diffusion` | second visuomotor baseline |
| `pi` | π0 / π0.5 deps |
| `pusht` | tiny public dataset for a no-robot smoke test |

ACT has no extra — it ships in the core package.

Check:

```bash
uv run python -c "import torch, lerobot; print('torch', torch.__version__, 'mps', torch.backends.mps.is_available())"
uv run lerobot-calibrate --help
uv run lerobot-train --help
```

On this Mac, `mps` should be `True`. CUDA is for the cloud image.

Copy station + secrets templates:

```bash
cp hardware/station.env.example hardware/station.env
cp .env.example .env
```

---

## 2. Find USB ports and set motor IDs (once per arm)

Connect **one** MotorBus USB cable to the Mac (and power the arm), then:

```bash
bash scripts/list_ports.sh
```

On macOS the MotorBus is `/dev/tty.usbmodem...`. Plug one arm, copy the path into `FOLLOWER_PORT` or `LEADER_PORT` in `hardware/station.env`, then swap cables and repeat.

`lerobot-find-port` is optional. It only works if you unplug the **USB cable from the Mac** (not the PSU) and wait ~2 s before Enter. If it errors with `No difference was found`, ignore it and use `list_ports.sh`.

**New motors only** (default id `1` on every servo). Connect **one motor at a time** as instructed:

```bash
uv run lerobot-setup-motors --robot.type=so101_follower --robot.port="$FOLLOWER_PORT"
uv run lerobot-setup-motors --teleop.type=so101_leader --teleop.port="$LEADER_PORT"
```

Skip this if the kit was already ID'd.

Find the webcams (index `0` is often FaceTime on a Mac):

```bash
uv run python scripts/list_cameras.py
```

Set `CAMERA_INDEX` (front) and optionally `CAMERA_INDEX_TOP` (overhead) in `hardware/station.env`. Framing notes: [hardware/camera_setup.md](../hardware/camera_setup.md).

---

## 3. Calibrate

The `id` is the calibration key. Reuse it everywhere.

```bash
set -a && source hardware/station.env && set +a
bash scripts/calibrate.sh follower
bash scripts/calibrate.sh leader
```

For each arm: move to mid-range, press Enter, sweep **every joint through its full range**.

If teleop later looks skewed, recalibrate — do not keep recording.

Hardware faults: [hardware/troubleshooting.md](../hardware/troubleshooting.md).

---

## 4. Teleoperate (no recording)

```bash
bash scripts/teleoperate.sh
```

Confirm:

- follower tracks leader smoothly
- gripper opens/closes
- Rerun window shows the **workspace** camera, not FaceTime (and the overhead view if `CAMERA_INDEX_TOP` is set)
- you can complete the task looking only at the camera view(s)

Practice 5–10 demos before recording.

---

## 5. Collect data (leader / follower)

Full guide: **[Data collection](data-collection.md)** (format, storage, H.264 video, LeRobot doc links).

Log in if you later want to push datasets (`hf upload`). Recording itself stays local:

```bash
hf auth login
HF_USER=$(NO_COLOR=1 hf auth whoami | awk -F': *' 'NR==1 {print $2}')
```

Put `HF_USER`, `DATASET_NAME`, and `TASK` in `hardware/station.env`. The task sentence is part of the dataset — **use the same words at train and rollout**.

```bash
bash scripts/record.sh
```

`record.sh` records **H.264** MP4s (QuickTime-friendly on Mac) with streaming encoding. See [streaming video encoding](https://huggingface.co/docs/lerobot/streaming_video_encoding).

Keys while recording (terminal must stay focused on macOS without Accessibility permission):

| Key | Action |
| --- | --- |
| `n` or `→` | save episode, go to next |
| `r` or `←` | redo this episode |
| `q` or `Esc` | finish session, encode locally (no Hub upload) |

Press **`n` after each demo you want to keep** — quitting with `q` mid-episode does not save it.

Defaults in `station.env`: 50 episodes × 30 s + 10 s reset. That is the SmolVLA starting point.

**Data quality beats model choice.** First 50 episodes: one object, fixed pizza pose, fixed camera, one operator, deliberate grasps.

After recording, `record.sh` prints a Rerun command. Preview the saved episodes (video + joints):

```bash
uv run rerun ~/.cache/huggingface/lerobot/${HF_USER}/${DATASET_NAME}_<timestamp>
# or: bash scripts/viz_dataset.sh
```

Live Rerun during record does **not** play video (images are logged static). Use the commands above. Hub visualizer: https://huggingface.co/spaces/lerobot/visualize_dataset

Replay episode 0 on the follower:

```bash
bash scripts/replay.sh 0
```

Resume more episodes later with `--resume=true` and `--dataset.num_episodes` set to the **additional** count (see [il_robots — checkpointing](https://huggingface.co/docs/lerobot/il_robots#2-checkpointing-and-resuming)).

---

## 6. Train

### 6a. Local smoke test (no robot, public dataset)

Proves the install. On a Mac this uses MPS/CPU and should finish in a few minutes:

```bash
bash scripts/train_local.sh act lerobot/pusht 20
```

Or via Docker (CPU, amd64 — same pattern as the [cookbook local step](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/lerobot-finetune-job#step-1--try-it-locally-first-optional-but-recommended)):

```bash
bash scripts/run_docker.sh --rebuild act lerobot/pusht 20
```

`Using device: cpu` in Docker on macOS is expected.

### 6b. Local ACT on your dataset (first real policy)

ACT is the hackathon fallback: fastest, ~1 GB VRAM, good for a single pick-and-place.

```bash
source .venv/bin/activate
set -a && source hardware/station.env && set +a

uv run python -m training.run \
  --policy act \
  --dataset "${HF_USER}/${DATASET_NAME}" \
  --steps 30000 \
  --batch-size 8
```

Apple Silicon: the wrapper sets `--policy.device=mps` automatically.

### 6c. SmolVLA / longer runs in the cloud

SmolVLA is the headline path (~50 demos, language-conditioned). Do **not** train 20k steps on this laptop.

1. Smoke-test the container locally (6a).
2. Push the dataset to the Hub when you want (`hf upload` — recording does not upload).
3. Submit a GPU job, same shape as [lerobot-finetune-job](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/lerobot-finetune-job):

```bash
set -a && source .env && set +a
bash scripts/run_serverless.sh smolvla "${HF_USER}/${DATASET_NAME}" 20000
```

Or the NormaCore / parquet bundle path: [smolva-ft-norma-core](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/smolva-ft-norma-core).

Unfreeze the vision encoder for real-task gains (already on in `training/smolvla/config.yaml`):

```text
--policy.freeze_vision_encoder=false
--policy.train_expert_only=false
```

| Profile | Policy | Batch | Steps | Where |
| --- | --- | --- | --- | --- |
| Install check | ACT | 2 | 20 | local MPS / Docker CPU |
| First robot policy | ACT | 8 | 30k–80k | local GPU or L40S |
| Headline VLA | SmolVLA | 8 | 20k | L40S / H100 |
| Optional | Diffusion | 8 | 20k+ | L40S / H100 |

---

## 7. Deploy on the arm

Camera key, resolution, robot id, and **task sentence** must match the dataset.

```bash
bash scripts/rollout.sh outputs/train/act/checkpoints/last/pretrained_model
```

Or a Hub repo:

```bash
bash scripts/rollout.sh ${HF_USER}/act_pizza_topping_v1
```

Record 10 eval episodes (policy drives the follower, no leader):

```bash
uv run lerobot-record \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="{ front: {type: opencv, index_or_path: ${CAMERA_INDEX}, width: 640, height: 480, fps: 30}, top: {type: opencv, index_or_path: ${CAMERA_INDEX_TOP}, width: 640, height: 480, fps: 30}}" \
  --dataset.repo_id="${HF_USER}/eval_${DATASET_NAME}" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes=10 \
  --policy.path="${HF_USER}/act_pizza_topping_v1"
```

If ACT is below ~70% on the **same** scene you trained on, collect more consistent demos. Do not jump to π0 first.

---

## Policy cheat-sheet

| Policy | Extra | VRAM (indicative) | Use |
| --- | --- | --- | --- |
| ACT | core | ~1 GB | First success, laptops, single task |
| Diffusion | `diffusion` | ~5 GB | Multimodal actions |
| SmolVLA | `smolvla` | ~4 GB+ | Language / multi-task, hackathon headline |
| π0 / π0.5 | `pi` | ~16 GB | After ACT works, 24 GB+ GPU |

---

## Repo map

```text
hardware/           station.env, camera notes, calibration, troubleshooting
docs/               quickstart, data-collection (format + recording), challenge specs
scripts/            calibrate, teleop, record, replay, train, docker, serverless, rollout
training/           ACT / SmolVLA / Diffusion configs + Python job wrapper
inference/          how to run a checkpoint on the follower
evaluation/         scoring stubs
datasets/sample/    pointers to public datasets (no large files)
Dockerfile          CUDA image for cloud jobs
```
