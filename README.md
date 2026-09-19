# Robotics Pizza Hackathon 2026

**Teach a Robot to Make Pizza in 48 Hours**

October 30 – November 1, 2026 · [Venue / City] · 8–12 teams · 2–4 participants per team

This repository is both the event documentation set **and** the starter environment for SO-101 + LeRobot: install, calibrate a leader/follower pair, collect demonstrations, train ACT locally, and fine-tune SmolVLA in the cloud.

**Start here (hardware + training):** [Participant quickstart](docs/participant_quickstart.md)

Status: **Draft v0.1** — technical validation phase (see [Launch Plan](docs/05-launch-plan.md)).

---

## Install (uv)

Requires Python **3.12+**, `uv`, and `ffmpeg` (`brew install ffmpeg` on this Mac).

```bash
uv python install 3.12
uv sync
source .venv/bin/activate
hf auth login
cp hardware/station.env.example hardware/station.env
```

That install includes LeRobot **0.6.1** with robot CLIs (`core_scripts` + `feetech`) and policy extras **ACT** (core), **SmolVLA**, **Diffusion**, and **π0 / π0.5**.

Then: find ports → calibrate → teleoperate → record → train. Full commands are in the [quickstart](docs/participant_quickstart.md).

| Step | Command |
| --- | --- |
| Find USB ports | `uv run lerobot-find-port` |
| Calibrate | `bash scripts/calibrate.sh follower` then `leader` |
| Teleop | `bash scripts/teleoperate.sh` |
| Record 50 demos | `bash scripts/record.sh` |
| Local ACT smoke | `bash scripts/train_local.sh act lerobot/pusht 20` |
| Cloud GPU job | `bash scripts/run_serverless.sh smolvla $HF_USER/$DATASET_NAME 20000` |
| Run policy | `bash scripts/rollout.sh <checkpoint>` |

Local robot work uses the `uv` venv (MPS on Apple Silicon). Real SmolVLA training uses Docker / [Nebius AI Jobs](https://github.com/mnrozhkov/serverless-ai-cookbook/tree/clawbio/robotics), not this laptop.

Upstream: [LeRobot install](https://huggingface.co/docs/lerobot/installation) · [SO-101](https://huggingface.co/docs/lerobot/so101) · [real-robot IL](https://huggingface.co/docs/lerobot/il_robots)

---

## Key decisions (locked for planning purposes)

- **Platform:** SO-101 (leader/follower teleoperation pair) + LeRobot — the standardized physical
platform for every team and station.
- **Headline model path:** SmolVLA (450M-parameter VLA), fine-tuned per task, ~50 demonstrations as
a starting point.
- **Fallback / reference baseline:** ACT — used to prove the hardware and dataset pipeline and as an
easier diagnostic reference. The event succeeds even if teams only reach ACT-level autonomy.
- **Vision:** one fixed front RGB camera per station (640×480 @ 30 FPS minimum). No participant-controlled camera placement in V1; wrist camera is a possible future extension, not part of the inaugural benchmark.
- **Props:** standardized rigid, reusable pizza/topping props for scored evaluation (not real food).
Real ingredients are reserved for the live showcase final, after benchmarking is complete.
- **Simulation:** LeIsaac + Isaac Lab + LeRobot EnvHub, reusing existing SO-101 manipulation tasks.
Simulation exists to de-risk the event, not to solve sim-to-real for V1 — see the priority order in
the [Simulation Spec](docs/04-simulation-spec.md#30-most-important-simulation-rule).
- **Event dates:** Friday, October 30 – Sunday, November 1, 2026 (48 hours).

---

## Document map

| #   | Document                                                                          | Covers |
| --- | --------------------------------------------------------------------------------- | ------ |
| —   | [Participant quickstart](docs/participant_quickstart.md)                          | Install, calibrate, collect, train, deploy |
| —   | [Data collection](docs/data-collection.md)                                        | Recording, dataset format, storage, H.264 video |
| 1   | [Challenge Brief](docs/01-challenge-brief.md)                                     | Public-facing challenge document |
| 2   | [Landing Page Copy](docs/02-landing-page-copy.md)                                 | Marketing site copy, CTAs, FAQ |
| 3   | [Technical Competition Spec](docs/03-technical-spec.md)                           | Hardware, vision, workspace, evaluation |
| 4   | [Simulation Spec](docs/04-simulation-spec.md)                                     | Simulation stack |
| 5   | [Launch Plan](docs/05-launch-plan.md)                                             | 11-phase timeline |
| 6   | [Team Structure](docs/06-team-structure.md)                                       | Organizer roles |
| 7   | [Marketing Plan](docs/07-marketing-plan.md)                                       | Audience and campaign |
| 8   | [Media Specification](docs/08-media-spec.md)                                      | Creative direction |
| 9   | [References & Next Steps](docs/09-references-and-next-steps.md)                   | Technical references |
| 10  | [Scope Validation & Global Vision](docs/10-scope-validation-and-global-vision.md) | Comparable events and roadmap |

---

## Quick facts

- **Format:** Teleoperate → Collect Data → Fine-Tune → Deploy → Compete
- **Three challenges:** Precision Topping (30 pts) · Recipe Assembly (40 pts) · Mystery Pizza (30 pts) — 100 pts total
- **Primary KPI:** ≥70% of participating teams successfully deploy one autonomous learned policy to a real robot
- **Critical path:** technical validation, not marketing — no large public registration push until teleoperation → dataset → training → autonomous deployment has worked on the intended hardware at least once (see Phase 1 in the Launch Plan)
