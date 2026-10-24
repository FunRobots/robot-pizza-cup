# SO-101 — Train and deploy on the arm

End-to-end guide for the **LeRobot SO-101** stack: fine-tune a policy on a HuggingFace dataset (CPU smoke, [DevLab](devlab.md), or a Job), persist the checkpoint, and run it on the follower. ElRobot fine-tune lives in [elrobot/docs/train-and-deploy.md](../../elrobot/docs/train-and-deploy.md).

**Prerequisites:** SO-101 calibrated and a dataset on the Hub (or use the shared baseline `robotpizzacup/robot-pizza-cup-1`). For recording, see [SO-101 data collection](data-collection.md) and [SO-101 setup](../README.md).

Run the commands on this page from `so101`. That directory is the LeRobot `uv` project. Secrets stay in the repo-root `.env`.

## Contents

- [Prerequisites](#prerequisites)
- [Default dataset](#default-dataset)
- [Train on CPU](#cpu-training)
- [Train on a DevLab](#devlab-training)
- [Train with a Job](#cloud-training)
- [Later: job cold start](#later-job-cold-start)
- [Deploy on the arm](#deploy-on-arm)
- [Record eval episodes](#record-eval-episodes)
- [Evaluation](#evaluation)
- [Troubleshooting](#troubleshooting)
- [Policy profiles](#policy-profiles)

---

<a id="prerequisites"></a>

## 1. Prerequisites

| Requirement | Purpose | Setup |
| --- | --- | --- |
| Python 3.13 + `uv` | Laptop robot + CPU `lerobot-train` smoke | `uv sync --managed-python --python 3.13` in `so101` |
| `ffmpeg` | Video encoding during record | `brew install ffmpeg` |
| Hugging Face account **(yours)** | Datasets / optional policy push | `uv run hf auth login`; set `HF_USER` |
| `so101/station.env` | Ports, cameras, task, episode timing | Copy from `so101/station.env.example` |
| `.env` | Secrets (HF, W&B, Nebius FS) | Copy from repo-root `.env.example` |
| Docker (optional) | CPU smoke of the cloud image | Docker Desktop |
| [Nebius CLI](https://docs.nebius.com/cli/install) | Optional GPU jobs | `nebius` auth; `PARENT_ID` organizer default or **your** project |
| DevLab (recommended) | Interactive GPU fine-tune | [DevLab guide](devlab.md); RTX PRO 6000, or L40S / H100 |
| Weights & Biases **(yours)** | Training metrics | `WANDB_API_KEY` + `WANDB_ENTITY`; project `robotpizzacup` |

### Config files — what goes where

| File | Gitignored | Contains |
| --- | --- | --- |
| `so101/station.env` | yes | `FOLLOWER_PORT`, `CAMERA_INDEX`, `TASK`, episode timing |
| repo-root `.env` | yes | `HF_TOKEN`, `HF_USER`, `DATASET_NAME`, `WANDB_*`, `FILESYSTEM_ID`, `SUBNET_ID`, `IMAGE`, `PARENT_ID` |

From `so101`, training scripts load the repo-root `.env` themselves. To load both in a shell:

```bash
cd so101
set -a && source ../.env && source station.env && set +a
```

### Shared filesystem (cloud checkpoints)

Organizers provide a Nebius **POSIX filesystem** (`FILESYSTEM_ID` in `.env`). Jobs mount it at `/mnt/checkpoints`. This is not Object Storage — bucket FUSE breaks checkpoint renames.

Use **your** `HF_USER` so runs are isolated: `/mnt/checkpoints/<HF_USER>/<job-name>/`.

`PARENT_ID` and `IMAGE` in `.env.example` are organizer defaults. Point them at your own project/image if you are not on the shared tenancy (you will also need your own filesystem and subnet).

If your Nebius project has **multiple subnets**, set `SUBNET_ID` (the job and the filesystem must be able to attach).

---

<a id="default-dataset"></a>

## 2. Default dataset

| Field | Value |
| --- | --- |
| Hub repo | `robotpizzacup/robot-pizza-cup-1` |
| Episodes / frames | 397 / 176039 at 30 fps |
| Cameras | `observation.images.front`, `observation.images.top` (640×480) |
| Task | One task: pick the toppings and place them on the pizza. |

Override with `DATASET_REPO_ID` or `HF_USER` / `DATASET_NAME` in `.env`.

---

<a id="cpu-training"></a>
<a id="local-training"></a>

## 3. Train on CPU (dev smoke)

**20 steps, 200 maximum.** `train_local.sh` always uses `cpu` (override with `TRAIN_DEVICE` only for a debug experiment). Full ACT and SmolVLA run on a [DevLab](#devlab-training) or a [Job](#cloud-training).

```bash
cd so101

# Public pusht, 20 steps
bash training/scripts/train_local.sh act lerobot/pusht 20

# Pizza YAML, 20 steps
bash training/scripts/train_pizza.sh act 20
```

Same thing without the wrapper:

```bash
uv run lerobot-train \
  --config_path=training/policy/act/config.yaml \
  --policy.device=cpu \
  --steps=20 \
  --batch_size=2 \
  --policy.push_to_hub=false
```

W&B: set `WANDB_API_KEY` and **your** `WANDB_ENTITY`. Shared project name: `robotpizzacup`. Chart `train/loss` under **Charts** (not System). Checkpoints are not W&B artifacts.

Smoke outputs go under `outputs/train/` (LeRobot default layout). Verify the files exist:

```bash
uv run python -m training.eval \
  outputs/train/<run>/checkpoints/last/pretrained_model
```

---

<a id="devlab-training"></a>

## 4. Train on a DevLab (recommended)

JupyterLab on a GPU, from the terminal or a notebook. Default platform is **RTX PRO 6000** (`gpu-rtx6000-a` / `1gpu-24vcpu-218gb`). L40S and H100 are the closest alternatives. Setup, disk size, and the policy-server proxy: **[DevLab](devlab.md)**.

From `so101` on the DevLab:

Create `../.env` from [`.env-devlab.example`](../../.env-devlab.example) first (`cp .env-devlab.example .env` at the repo root, in the terminal). Then:

```bash
uv run lerobot-train \
  --config_path=training/policy/act/config.yaml \
  --policy.device=cuda \
  --policy.push_to_hub=false \
  --dataset.repo_id=robotpizzacup/robot-pizza-cup-1
```

Steps and batch size come from the YAML (ACT 100k / 16). Checkpoints stay on the DevLab disk under `outputs/train/`. SmolVLA: `--config_path=training/policy/smolvla/config.yaml --policy.type=smolvla --dataset.repo_id=robotpizzacup/robot-pizza-cup-1` (60k / 16). To push to the Hub at the end of training so the laptop can roll the policy out directly, pass `--policy.push_to_hub=true --policy.type=act --policy.repo_id="$HF_USER/pizza-act"`.

---

<a id="cloud-training"></a>

## 5. Train with a Job (optional)

Unattended fine-tune. Pull the published image; only rebuild if you change deps. Default GPU is **RTX PRO 6000**. Set both `JOB_PLATFORM` and `JOB_PRESET` to switch:

| GPU | `JOB_PLATFORM` | `JOB_PRESET` |
| --- | --- | --- |
| RTX PRO 6000 (default, `eu-south1` / `uk-south2`) | `gpu-rtx6000-a` | `1gpu-24vcpu-218gb` |
| RTX PRO 6000 (`us-central1`) | `gpu-rtx6000` | `1gpu-24vcpu-218gb` |
| L40S (`eu-north1`) | `gpu-l40s-a` | `1gpu-24vcpu-96gb` |
| H100 (`eu-north1`) | `gpu-h100-sxm` | `1gpu-16vcpu-200gb` |

### Step A — Image

Organizer default: `IMAGE=mnrozhkov/pizza-robo-hack:latest` (linux/amd64, public). Details: [training/README.md — Docker image](../training/README.md#docker-image).

```bash
# Organizers / custom forks
bash training/scripts/build_docker.sh --push
```

### Step B — Submit (only cloud entry)

```bash
cd so101

# Canary: 500 steps, 1h timeout, still mounts the filesystem
bash training/scripts/run_serverless.sh --debug act

# Full ACT (100k steps, batch 16 — from the YAML)
bash training/scripts/run_serverless.sh act

# SmolVLA (60k steps, batch 16)
bash training/scripts/run_serverless.sh smolvla
```

Save the printed **job name**. Follow status with `nebius ai job get --id <id> --format json` (do not `--follow` logs in unattended sessions). Healthy run: `Using device: cuda` and a W&B URL.

Optional Hub push for laptop rollout without mounting the FS:

```bash
POLICY_PUSH_TO_HUB=true bash training/scripts/run_serverless.sh act
# Hub repo defaults to $HF_USER/pizza-<policy> (override with POLICY_REPO_ID)
```

### Step C — Checkpoint onto the arm

From a machine that has the filesystem mounted (`CHECKPOINT_FS_ROOT`):

```bash
bash training/scripts/download_checkpoint.sh "$RUN_NAME"
# → lerobot-outputs/<run-name>/checkpoints/last/pretrained_model
```

Or rollout a Hub id if you pushed.

Resume after a cancelled/failed job (same checkpoint dir, **new** job — do not `job restart` a from-scratch spec):

```bash
export RUN_NAME=pizza-<hf-user>-act-...   # original job name
bash training/scripts/run_serverless.sh --resume act
```

Preemptible VMs and `job restart` caveats: [training/README.md](../training/README.md#preemptible--restart-usually-skip-this).

<a id="later-job-cold-start"></a>

### Later — job cold start (ideas to test)

Image pull from Docker Hub currently takes about **1–2 minutes** before the job is `RUNNING`. First try hosting `:deps` / `:latest` in **Nebius Container Registry** in the same region as the job.

If pull is still slow, test a **small image + mounted env** — **without nested Docker**. Serverless jobs have no privileged Docker-in-Docker / GPU-in-inner-container path.

| Idea | How | Notes |
| --- | --- | --- |
| Thin job image | CUDA runtime only, or existing `:deps` | Outer container is what gets the GPU. |
| Pre-extracted venv | Mount a filesystem (not S3 FUSE) with `site-packages` / `.venv` already unpacked | FUSE is read-mostly and rejects chmod/rename/mmap that Python envs often need. |
| Squashfs or tar from S3 | Copy onto local disk (`--disk-size` is already `450Gi` in `run_serverless.sh`), unpack, `source` the venv | Moves wait into `RUNNING` (billable). Compare wall-clock vs in-region registry pull. |

Do **not** `docker load` a fat tarball inside the job. Check that the mounted venv ABI matches the CUDA base (torch wheels vs `nvidia/cuda` major).

---

<a id="deploy-on-arm"></a>

## 6. Deploy on the arm

### Pre-flight checklist

| Must match training data | Where to check |
| --- | --- |
| Camera keys (`front`, `top`) | `so101/station.env` → `so101/scripts/cameras.sh` |
| Resolution 640×480 @ 30 FPS | `CAMERA_WIDTH`, `CAMERA_HEIGHT`, `CAMERA_FPS` |
| `FOLLOWER_ID` (calibration) | Same id used in record / calibrate |
| Task sentence | `TASK` in `station.env` — **exact same words** as recording |

```bash
cd so101
set -a && source station.env && set +a
```

### Run the policy

Local or downloaded checkpoint:

```bash
bash scripts/rollout.sh \
  lerobot-outputs/<run-name>/checkpoints/last/pretrained_model
```

Or a local train output:

```bash
bash scripts/rollout.sh \
  outputs/train/<run-name>/checkpoints/last/pretrained_model
```

Hub model (if you pushed the checkpoint):

```bash
bash scripts/rollout.sh "$HF_USER/my_act_policy"
```

### SmolVLA / slow models

On the laptop, use real-time chunking (RTC). A heavy VLA can instead run remotely on a GPU:

- **DevLab policy server:** run the server inside your DevLab and connect through Jupyter Server Proxy — see [Policy server on the DevLab](devlab.md#policy-server-on-the-devlab-optional).
- **Nebius Endpoint:** serve a policy container over HTTPS when you want a stable URL, no Jupyter token, and the DevLab stopped. Create it in **Serverless AI → Endpoints** with the same GPU platform/preset pair as [Jobs](#cloud-training) (`gpu-rtx6000-a` / `1gpu-24vcpu-218gb`, or L40S / H100). This repo has no Endpoint wrapper script.

```bash
cd so101
set -a && source ../.env && source station.env && set +a
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

<a id="record-eval-episodes"></a>

### Record eval episodes

Policy drives the follower (no leader), 10 episodes:

```bash
cd so101
set -a && source ../.env && source station.env && set +a
# shellcheck source=cameras.sh
source scripts/cameras.sh
POLICY=lerobot-outputs/<run-name>/checkpoints/last/pretrained_model

uv run lerobot-record \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$(build_cameras_dict)" \
  --dataset.repo_id="${HF_USER}/eval_${DATASET_NAME}" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes=10 \
  --policy.path="$POLICY"
```

<a id="evaluation"></a>

## 7. Evaluation

Scoring scripts are not in this repo yet.

Until then, use physical success rate on the SO-101 follower:

1. Reset the scene the same way every episode.
2. From `so101`, run `bash scripts/rollout.sh <policy>` for 10 episodes.
3. Score success / fail by hand.
4. Compare to a teleoperated baseline.

Target for Challenge 1 with ~50 clean ACT episodes on the training configuration: **>70% success**. If you are far below that, collect more consistent data before changing the model.

---

<a id="troubleshooting"></a>

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| W&B only shows System metrics | Before first `log_freq` step, or wrong tab | Open run URL; add `train/loss` chart; wait until step 50+ |
| `--wandb.enable=false` | Empty `WANDB_API_KEY` in saved `.env` | Fill key and save `.env` |
| Cloud job, no files on FS | Missing `FILESYSTEM_ID` / mount | Check `.env`; `job get` volumes |
| Stuck in `STARTING` > 10 min | Image pull (wrong arch or private image) | Cancel (it bills); pin public amd64 `IMAGE` |
| `multiple subnets found` | Nebius tenancy | Set `SUBNET_ID` in `.env` |
| `no preset found with name = "..."` | `--preset` does not match `--platform` | Default is `gpu-rtx6000-a` + `1gpu-24vcpu-218gb`. L40S: `gpu-l40s-a` + `1gpu-24vcpu-96gb` (`gpu-l40s-d` uses `1gpu-16vcpu-96gb`). H100: `gpu-h100-sxm` + `1gpu-16vcpu-200gb` |
| Policy loads, arm barely moves | Scene/camera mismatch vs training | Fix camera index, task string, reset scene |
| `Feature mismatch` / missing `camera1` | SmolVLA base vs pizza `front`/`top` | Local YAML `rename_map` is injected into the job; no image rebuild |
| `Checkpoint not found` | Wrong path | Use `.../checkpoints/last/pretrained_model` |
| Teleop/comms errors | Hardware | [troubleshooting.md](troubleshooting.md) |

---

<a id="policy-profiles"></a>

## 9. Policy profiles

Default GPU below is RTX PRO 6000. The same step counts run on L40S or H100 if you set `JOB_PLATFORM` and `JOB_PRESET` together ([table](#cloud-training)).

| Profile | Policy | Steps | Batch | Where | Checkpoint |
| --- | --- | --- | --- | --- | --- |
| Install check | ACT | 20 | 2 | CPU / Docker CPU | throwaway local |
| Job canary | ACT | 500 | 16 | RTX PRO 6000 `--debug` | shared FS |
| First robot policy | ACT | 100k | 16 | RTX PRO 6000 Job or DevLab | FS / Hub → rollout |
| Headline VLA | SmolVLA | 60k | 16 | RTX PRO 6000 Job or DevLab | same |
| Optional | Diffusion | 60k | 32 | RTX PRO 6000 Job or DevLab | same |

More detail: [training/README.md](../training/README.md). Cloud pattern: [lerobot-finetune-job](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/lerobot-finetune-job).
