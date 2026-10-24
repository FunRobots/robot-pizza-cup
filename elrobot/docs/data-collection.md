Commands below run from `elrobot`. SO-101 recordings use a different format: [SO-101 data collection](../../so101/docs/data-collection.md).

# ElRobot (NormaCore Station)

Station **always logs** motor and camera data into on-disk history (normfs under `norma-core/bin/station_data/`). You do **not** run `lerobot-record`. For ML, you **tag** a time range in the web UI and **export** a `.parquet` file with `dataset-generator`.

Upstream export walkthrough: [datasets-export.md](https://github.com/norma-core/norma-core/blob/v0.1.0-beta.10/docs/datasets/export-parquet/datasets-export.md).

## Prerequisites

1. `bash scripts/install.sh` — NormaCore **v0.1.0-beta.10** under `norma-core/`
2. `bash scripts/run.sh` — web UI at http://localhost:8889
3. Both ST3215 buses calibrated — [ElRobot README — Calibrate](../README.md#3-calibrate)

Cameras are configured in Station (`usb-video` in `norma-core/bin/station.yaml`). They do **not** use `lerobot-find-cameras` or SO-101 `station.env` indexes. Framing notes: [ElRobot README — Connect](../README.md#2-connect-the-arms).

## Configure `elrobot.env`

```bash
cd elrobot
cp elrobot.env.example elrobot.env
```

| Variable | Purpose |
| --- | --- |
| `LEADER_SERIAL` / `FOLLOWER_SERIAL` | Bus serials from the Station UI (8 servos each) |
| `STATION_HOST` | Where Station runs (`localhost` on the laptop wired to the arms) |
| `TASK` | Task sentence on **every exported frame** — match train/deploy verbatim |
| `EPISODE_DURATION` | Minimum episode length in seconds for export (default **45**) |
| `DATASET_OUTPUT` | Path **prefix**; export writes `${DATASET_OUTPUT}.parquet`. Default `../data/elrobot-pizza` → repo-root `data/` |

## Teleoperate before you tag

Station must be running. Leader mirrors to follower via the upstream teleop example:

```bash
bash scripts/teleop.sh
```

Ctrl+C stops teleop and disables follower torque. Practice smooth demos before tagging history.

Timing for export (defaults):

- Each kept episode should be at least **`EPISODE_DURATION`** seconds (45 by default). Longer demos are kept; shorter ones may be dropped.
- Wait **at least 5 seconds** between episodes; **~8 seconds** reset is comfortable.

## Tag, export, preview

Recording is **tagged slices** of Station history, not a separate recorder.

1. In http://localhost:8889, press **Tag** and note the **start** tag name.
2. Run `bash scripts/teleop.sh` and perform one or more episodes (respect duration and reset gaps).
3. Press **Tag** again and note the **end** tag name.
4. Open **History**, find both tags, and copy their **frame pointers** (start and end).
5. Export:

```bash
bash scripts/export_dataset.sh <START_FRAME> <END_FRAME>
```

The script runs `dataset-generator` (reads the live Station at `STATION_HOST`) then `dataset-mp4` for a QuickTime-friendly preview next to the parquet.

Manual equivalent:

```bash
norma-core/bin/dataset-generator \
  -episode.duration 45 \
  -from <START_FRAME> \
  -to <END_FRAME> \
  -robot localhost \
  -output ../data/elrobot-pizza \
  -task "place pepperoni on pizza"
```

| Export flag | Meaning |
| --- | --- |
| `-episode.duration` | Minimum episode length (seconds) |
| `-from` / `-to` | Frame pointers from History tags |
| `-robot` | Station host (`STATION_HOST`) |
| `-output` | Parquet path prefix |
| `-task` | Same string as `TASK` in `elrobot.env` |
| `-episode.min-commands` | Drop episodes with too few commands (default **100**) |

Read the CLI log: it lists kept and discarded episodes. If you see `insufficient commands`, re-run `dataset-generator` with a lower `-episode.min-commands`.

## Where data is stored

| Location | Contents |
| --- | --- |
| `elrobot/norma-core/bin/station_data/` | Raw Station history (normfs). Grows while Station runs; bounded by Station disk/memory limits. |
| `${DATASET_OUTPUT}.parquet` | Exported ML dataset (e.g. `data/elrobot-pizza.parquet` at repo root) |
| `${DATASET_OUTPUT}.mp4` | Optional preview from `export_dataset.sh` |

Parquet files are local artifacts — not committed to git. Back them up before wiping `station_data`.

Do not commit large episode exports to this repo. Keep parquets on disk or on the Hub ([upload](#upload)).

## Dataset format (Station parquet)

One row = one frame. Schema (v0.1.0-beta.10 export):

| Column | Meaning |
| --- | --- |
| `episode_start_ns` | Wall-clock ns of the episode’s first frame (episode id) |
| `global_frame_id` | Frame id (binary, little-endian) |
| `timestamp_ns_since_episode_start` | Time within episode |
| `joints` | Per-servo telemetry: raw position/goal, **`position_norm` / `goal_norm`**, current, velocity, calibrated ranges, … |
| `images` | List of `{jpeg: binary}` — one embedded JPEG per camera |
| `task` | Your `-task` / `TASK` string |

ElRobot has **8** servos per bus; exported `joints` lists reflect what Station recorded on the follower/leader buses during teleop.

<a id="convert-to-lerobot"></a>

## Convert a Station parquet to LeRobot v2.1

`scripts/export_to_lerobot.py` turns a **folder** of Station `.parquet` files into one LeRobot **v2.1** dataset (v2.0 if you pass `--format-version v2.0`). Use it when a LeRobot v2.1 loader should read ElRobot demonstrations.

NormaCore `smolvla_py` trains on the Station parquet itself. Steps for that path: [Train and deploy](train-and-deploy.md). SO-101 recording and `lerobot-train` in this repo use LeRobot **0.6.1 / dataset v3** — see [SO-101 data collection](../../so101/docs/data-collection.md). A folder from this script is v2.1, aimed at the [LeRobot v0.3.3 dataset layout](https://github.com/huggingface/lerobot/tree/v0.3.3/src/lerobot/datasets).

The CLI takes a directory and searches it recursively. One exported file such as `data/elrobot-pizza.parquet` has to sit in a directory of its own. An existing output directory is refused. Each `(source file, episode_start_ns)` pair becomes one episode. Files are not stitched together.

From `elrobot`:

```bash
python3 -m venv .venv-export
.venv-export/bin/pip install numpy pyarrow av pillow datasets
mkdir -p ../data/elrobot-parquets
cp ../data/elrobot-pizza.parquet ../data/elrobot-parquets/
.venv-export/bin/python scripts/export_to_lerobot.py \
  ../data/elrobot-parquets \
  ../data/elrobot-lerobot
```

Video mode needs FFmpeg with **libx264** on `PATH` (`brew install ffmpeg` on macOS). `.venv-export/` is gitignored. Output under `data/` is gitignored; do not commit it. `meta/conversion.json` stores the absolute input path, and `meta/source_frames/` keeps the original non-image columns.

| Output | Source |
| --- | --- |
| `observation.state` | `joints[].position_norm` |
| `action` | `joints[].goal_norm` on the **same** row |
| `observation.images.camera_N` | `images[N].jpeg`, original width and height |
| `task` | Station `task` string |

Normalized joint values are copied through. There is no rescaling and no shift of `action` to the next frame. FPS is the median gap between source timestamps, unless you pass `--fps`. Each episode is resampled onto that grid with nearest-neighbor frames, so rows can repeat or drop. A long gap does not fail the run; `max_source_gap_seconds` is recorded per episode in `meta/conversion.json`.

Default names are `joint_0`… and `camera_0`… in Station list order. Pass `--joint-names` and `--camera-names` only when you know that order (one name per joint, one per camera). ElRobot has **8** servos. The whole dataset must keep the same joint count, camera count, and per-camera resolution; mixed sizes fail because images are never resized. Odd width or height is encoded as `yuv444p`; even sizes (including 1280×720) use `yuv420p`. H.264 CRF 18 is lossy. `--image-storage image` stores the original JPEG bytes and writes no MP4s.

Each source file is loaded whole, JPEGs included. A long recording can exhaust memory. The converter also decodes every selected frame to compute image statistics.

<a id="upload"></a>

## Upload to Hugging Face Hub

Export stays local (`export_dataset.sh` writes `${DATASET_OUTPUT}.parquet` and a preview `.mp4`). Push a copy when the team should train from a shared dataset. The `hf` CLI is in the SO-101 environment (`so101/`, `uv run hf`). Log in once; the token needs write access:

```bash
cd so101
uv run hf auth login
```

Hub repo name: [`team-<N>-<team-name>-<dataset-name>-<version>`](../../README.md#hub-dataset-names). Brackets are placeholders. Use lowercase letters, digits, and hyphens.

```text
RobotPizzaCup/team-3-your-team-elrobot-precision-topping-v1
```

`HF_USER` is the namespace (your username, or `RobotPizzaCup` if you can create datasets there). Put the arm in the dataset name (`elrobot-precision-topping`) so an SO-101 upload from the same team does not overwrite this repo. A LeRobot v2.1 conversion of the same demos gets its own name, for example `team-3-your-team-elrobot-precision-topping-lerobot-v1`.

Build a folder with the parquet, the preview video, and a dataset card. `README.md` is the Hub dataset card.

```text
data/team-3-your-team-elrobot-precision-topping-v1/
  README.md
  elrobot-precision-topping.parquet
  preview.mp4
```

```markdown
# team-3-your-team-elrobot-precision-topping-v1

- **Task:** place one pepperoni on the pizza
- **Episodes:** 40
- **Robot:** ElRobot follower, 8 servos, NormaCore Station teleop
- **Cameras:** wrist, side (Station image order)
- **Varied:** pepperoni start position. Pizza pose, cameras, and task text stayed fixed.
- **Format:** Station parquet (v0.1.0-beta.10). `action` in a LeRobot conversion is `goal_norm` on the same frame as `position_norm`.
```

Match **Task** to `TASK` in `elrobot.env`. From `so101`:

```bash
uv run hf upload RobotPizzaCup/team-3-your-team-elrobot-precision-topping-v1 \
  ../data/team-3-your-team-elrobot-precision-topping-v1 \
  --repo-type dataset
```

Add `--private` to keep it private until you publish it. Uploading the same repo id again updates that dataset. Bump `-v1` to `-v2` when the task sentence, cameras, or episode timing change.

`smolvla_py` still trains on a local parquet path. Download a shared export with:

```bash
uv run hf download RobotPizzaCup/team-3-your-team-elrobot-precision-topping-v1 \
  --repo-type dataset \
  --local-dir ../data/team-3-your-team-elrobot-precision-topping-v1
```

To publish the LeRobot v2.1 folder instead, add the same style of `README.md` at its root and `hf upload` that directory. Say **Format: LeRobot v2.1** in the card.

## After export — training and deploy

Fine-tune and run policies on the Station parquet: **[Train and deploy](train-and-deploy.md)** (SmolVLA in `smolvla_py`, CUDA, 6 vs 8 DoF limits).

For a LeRobot v2.1 folder, use a loader that reads that format. Point training at `observation.state`, `action`, and `observation.images.*` as written above, with all 8 joint dimensions. SO-101 + `lerobot-train`: [SO-101 data collection](../../so101/docs/data-collection.md).

## Data quality checklist

Before fine-tuning or sharing a parquet:

- [ ] Wrist and side cameras look correct in the Station UI before tagging
- [ ] Same `TASK` string in `elrobot.env`, export, and deploy
- [ ] Export log shows the expected number of episodes kept (not mostly “too short” or “insufficient commands”)
- [ ] Preview MP4 motion matches what you demonstrated
- [ ] Leader and follower were calibrated; follower tracked during `teleop.sh`
- [ ] Hub `README.md` lists task, episode count, robot, cameras, and what you varied

Setup: [ElRobot setup](../README.md).
