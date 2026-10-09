# Robotics Pizza Hackathon 2026

**Teach a Robot to Make Pizza in 48 Hours**

October 30 – November 1, 2026 · [Venue / City] · 8–12 teams · 2–4 participants per team

Each team has two kits: a LeRobot SO-101 pair and an ElRobot pair. Pick the arm directory for the stack you are on. They do not share a Python environment.

| Arm | Directory | Stack |
| --- | --- | --- |
| LeRobot SO-101 | [arms/so101](arms/so101/README.md) | `uv` + LeRobot 0.6.1 |
| ElRobot | [arms/elrobot](arms/elrobot/README.md) | NormaCore Station binary |

**Event-day hardware:** [Hardware and software](docs/04-hardware-and-soft.md) · **SO-101 train → deploy:** [Train and deploy](docs/train-and-deploy.md)

Status: **Draft v0.1**.

---

## SO-101 (LeRobot)

From `arms/so101`. Full steps: [arms/so101/README.md](arms/so101/README.md).

```bash
cd arms/so101
uv python install 3.12
uv sync
hf auth login
cp station.env.example station.env
cp ../../.env.example ../../.env
```

That install includes LeRobot **0.6.1** with robot CLIs (`core_scripts` + `feetech`) and policy extras **ACT** (core), **SmolVLA**, **Diffusion**, and **π0 / π0.5**.

| Step | Command (from `arms/so101`) |
| --- | --- |
| Find USB ports | `bash scripts/list_ports.sh` |
| Calibrate | `bash scripts/calibrate.sh follower` then `leader` |
| Teleop | `bash scripts/teleoperate.sh` |
| Record 50 demos | `bash scripts/record.sh` |
| Preview in Rerun | `bash scripts/viz_dataset.sh` |
| Local ACT smoke (20 steps) | `bash training/scripts/train_local.sh act lerobot/pusht 20` |
| Cloud canary (500 steps) | `bash training/scripts/run_serverless.sh --debug act` |
| Cloud ACT | `bash training/scripts/run_serverless.sh act 30000` |
| Copy checkpoint from FS mount | `bash training/scripts/download_checkpoint.sh <job-name>` |
| Run policy | `bash scripts/rollout.sh <checkpoint>` |

Local robot work uses the `uv` venv in `arms/so101` (MPS on Apple Silicon). Real SmolVLA training uses Docker / [Nebius AI Jobs](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics), not this laptop.

Upstream: [LeRobot install](https://huggingface.co/docs/lerobot/installation) · [SO-101](https://huggingface.co/docs/lerobot/so101) · [real-robot IL](https://huggingface.co/docs/lerobot/il_robots)

## ElRobot (NormaCore Station)

No `uv sync`. Download the pinned Station binary and follow [arms/elrobot/README.md](arms/elrobot/README.md).

Upstream: [NormaCore Station](https://github.com/norma-core/norma-core/tree/main/software/station/bin/station)

---

## Document map

| Document | Covers |
| --- | --- |
| [SO-101 setup](arms/so101/README.md) | Install, calibrate, collect, train, deploy |
| [ElRobot setup](arms/elrobot/README.md) | Station install and calibration |
| [Hardware and software](docs/04-hardware-and-soft.md) | Kit, clamp, wire, milestone checks |
| [Train and deploy](docs/train-and-deploy.md) | SO-101 local smoke, Nebius GPU, rollout |
| [Data collection](docs/data-collection.md) | SO-101 recording, dataset format, H.264 video |

---

## Quick facts

- **Format:** Teleoperate → Collect Data → Fine-Tune → Deploy → Compete
- **Three challenges:** Precision Topping (30 pts) · Recipe Assembly (40 pts) · Mystery Pizza (30 pts) — 100 pts total
- **Primary KPI:** ≥70% of participating teams successfully deploy one autonomous learned policy to a real robot
- **Platforms:** each team uses both the SO-101 kit (LeRobot) and the ElRobot kit (NormaCore Station)
