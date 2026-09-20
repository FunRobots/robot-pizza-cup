# Train and deploy on the arm

End-to-end guide: fine-tune a policy on a HuggingFace dataset, persist the checkpoint (local or cloud), and run it on the SO-101 follower.

**Prerequisites:** hardware calibrated and a dataset on the Hub (or use the shared baseline `mnrozhkov/pizza_hack_v1_fake_ingredients`). For recording, see [Data collection](data-collection.md) and [Participant quickstart](participant_quickstart.md) (sections 1–5).

## Contents

- [Prerequisites](#prerequisites)
- [Default dataset](#default-dataset)
- [Train locally](#local-training)
- [Train in the cloud](#cloud-training)
- [Later: job cold start](#later-job-cold-start)
- [Deploy on the arm](#deploy-on-arm)
- [Record eval episodes](#record-eval-episodes)
- [Troubleshooting](#troubleshooting)
- [Policy profiles](#policy-profiles)

---

<a id="prerequisites"></a>

## 1. Prerequisites

| Requirement | Purpose | Setup |
| --- | --- | --- |
| Python 3.12 + `uv` | Local robot + `lerobot-train` smoke | `uv sync` (repo root) |
| `ffmpeg` | Video encoding during record | `brew install ffmpeg` |
| Hugging Face account **(yours)** | Datasets / optional policy push | `hf auth login`; set `HF_USER` |
| `hardware/station.env` | Ports, cameras, task, episode timing | Copy from `hardware/station.env.example` |
| `.env` | Secrets (HF, W&B, Nebius FS) | Copy from `.env.example` |
| Docker (optional) | CPU smoke of the cloud image | Docker Desktop |
| [Nebius CLI](https://docs.nebius.com/cli/install) | Submit GPU jobs | `nebius` auth; `PARENT_ID` organizer default or **your** project |
| Weights & Biases **(yours)** | Training metrics | `WANDB_API_KEY` + `WANDB_ENTITY`; project `robotpizzacup` |

### Config files — what goes where

| File | Gitignored | Contains |
| --- | --- | --- |
| `hardware/station.env` | yes | `FOLLOWER_PORT`, `CAMERA_INDEX`, `TASK`, episode timing |
| `.env` | yes | `HF_TOKEN`, `HF_USER`, `DATASET_NAME`, `WANDB_*`, `FILESYSTEM_ID`, `SUBNET_ID`, `IMAGE`, `PARENT_ID` |

Load both before training:

```bash
set -a && source .env && source hardware/station.env && set +a
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
| Hub repo | `mnrozhkov/pizza_hack_v1_fake_ingredients` |
| Cameras | `observation.images.front`, `observation.images.top` |
| Task | Pick a pepperoni token and place it on the pizza. |

Override with `DATASET_REPO_ID` or `HF_USER` / `DATASET_NAME` in `.env`.

---

<a id="local-training"></a>

## 3. Train locally (Mac / laptop)

**Smoke tests only (20 steps).** Full ACT (30k) and SmolVLA (20k) are cloud GPU jobs — do not train those on a Mac.

```bash
set -a && source .env && source hardware/station.env && set +a

# Public pusht, 20 steps
bash training/scripts/train_local.sh act lerobot/pusht 20

# Pizza YAML, 20 steps
bash training/scripts/train_pizza.sh act 20
```

Same thing without the wrapper:

```bash
uv run lerobot-train \
  --config_path=training/policy/act/config.yaml \
  --policy.device=mps \
  --steps=20 \
  --batch_size=2 \
  --policy.push_to_hub=false
```

W&B: set `WANDB_API_KEY` and **your** `WANDB_ENTITY`. Shared project name: `robotpizzacup`. Chart `train/loss` under **Charts** (not System). Checkpoints are not W&B artifacts.

Local smoke outputs go under `outputs/train/` (LeRobot default layout). Verify:

```bash
uv run python -m training.eval \
  outputs/train/<run>/checkpoints/last/pretrained_model
```

---

<a id="cloud-training"></a>

## 4. Train in the cloud (Nebius GPU)

Recommended for **ACT 30k** and required for **SmolVLA 20k**. Pull the published image; only rebuild if you change deps.

### Step A — Image

Organizer default: `IMAGE=mnrozhkov/pizza-robo-hack:latest` (linux/amd64, public). Details: [training/README.md — Docker image](../training/README.md#docker-image).

```bash
# Organizers / custom forks
bash training/scripts/build_docker.sh --push
```

### Step B — Submit (only cloud entry)

```bash
set -a && source .env && set +a

# Canary: 500 steps, 1h timeout, still mounts the filesystem
bash training/scripts/run_serverless.sh --debug act

# Full ACT
bash training/scripts/run_serverless.sh act 30000

# SmolVLA
bash training/scripts/run_serverless.sh smolvla 20000
```

Save the printed **job name**. Follow status with `nebius ai job get --id <id> --format json` (do not `--follow` logs in unattended sessions). Healthy run: `Using device: cuda` and a W&B URL.

Optional Hub push for laptop rollout without mounting the FS:

```bash
POLICY_PUSH_TO_HUB=true bash training/scripts/run_serverless.sh act 30000
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

## 5. Deploy on the arm

### Pre-flight checklist

| Must match training data | Where to check |
| --- | --- |
| Camera keys (`front`, `top`) | `hardware/station.env` → `scripts/cameras.sh` |
| Resolution 640×480 @ 30 FPS | `CAMERA_WIDTH`, `CAMERA_HEIGHT`, `CAMERA_FPS` |
| `FOLLOWER_ID` (calibration) | Same id used in record / calibrate |
| Task sentence | `TASK` in `station.env` — **exact same words** as recording |

```bash
set -a && source hardware/station.env && set +a
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

### SmolVLA / slow models on a laptop

Use real-time chunking (RTC) — see [inference/README.md](../inference/README.md).

<a id="record-eval-episodes"></a>

### Record eval episodes

Policy drives the follower (no leader), 10 episodes:

```bash
set -a && source .env && source hardware/station.env && set +a
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

Manual scoring: [evaluation/README.md](../evaluation/README.md). Target **>70% success** on the training scene before changing model architecture.

---

<a id="troubleshooting"></a>

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| W&B only shows System metrics | Before first `log_freq` step, or wrong tab | Open run URL; add `train/loss` chart; wait until step 50+ |
| `--wandb.enable=false` | Empty `WANDB_API_KEY` in saved `.env` | Fill key and save `.env` |
| Cloud job, no files on FS | Missing `FILESYSTEM_ID` / mount | Check `.env`; `job get` volumes |
| Stuck in `STARTING` > 10 min | Image pull (wrong arch or private image) | Cancel (it bills); pin public amd64 `IMAGE` |
| `multiple subnets found` | Nebius tenancy | Set `SUBNET_ID` in `.env` |
| `no preset found with name = "..."` | `--preset` does not match `--platform` | Default is `gpu-l40s-a` + `1gpu-24vcpu-96gb`; or use `gpu-l40s-d` + `1gpu-16vcpu-96gb` |
| Policy loads, arm barely moves | Scene/camera mismatch vs training | Fix camera index, task string, reset scene |
| `Feature mismatch` / missing `camera1` | SmolVLA base vs pizza `front`/`top` | Local YAML `rename_map` is injected into the job; no image rebuild |
| `Checkpoint not found` | Wrong path | Use `.../checkpoints/last/pretrained_model` |
| Teleop/comms errors | Hardware | [hardware/troubleshooting.md](../hardware/troubleshooting.md) |

---

<a id="policy-profiles"></a>

## 7. Policy profiles

| Profile | Policy | Steps | Where | Checkpoint |
| --- | --- | --- | --- | --- |
| Install check | ACT | 20 | local / Docker CPU | throwaway local |
| Cloud canary | ACT | 500 | 1× L40S `--debug` | shared FS |
| First robot policy | ACT | 30k–80k | 1× L40S | FS / Hub → rollout |
| Headline VLA | SmolVLA | 20k | 1× L40S | same |
| Optional | Diffusion | 20k+ | 1× L40S | same |

More detail: [training/README.md](../training/README.md). Cloud pattern: [lerobot-finetune-job](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics/lerobot-finetune-job).
