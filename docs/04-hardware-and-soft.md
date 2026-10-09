<aside>
🎯

**Target: your first recorded episode by the end of Friday's setup block (20:00).** Your arms come pre-assembled. Your team clamps them to the table, wires them to the motor controller boards and calibrates them. Start with the LeRobot SO-101 set (fully documented path), then set up the ElRobot.

</aside>

## 🧭 How to Use This Page

Work through the milestones in order. Each ends with a 🎯 milestone check. Software install and calibration commands live in the arm directories, not in a shared environment at the repo root:

| Arm | Setup |
| --- | --- |
| LeRobot SO-101 | [arms/so101/README.md](../arms/so101/README.md) |
| ElRobot | [arms/elrobot/README.md](../arms/elrobot/README.md) |

This page is the kit, the clamp-and-wire steps, and the milestone checks. For routine issues, see Troubleshooting at the end. For unsafe motion, hot or damaged equipment, or if you are unsure a step is safe, stop and ask staff.

## 🏠 Before the Event

Save time on Friday by doing this at home.

**For LeRobot SO-101**

Follow [arms/so101/README.md](../arms/so101/README.md). That directory is its own `uv` project (LeRobot with Feetech motor support). Do not `uv sync` at the repo root.

- [ ]  Install from `arms/so101` and confirm `lerobot-calibrate --help` runs.
- [ ]  Watch the calibration video in the official SO-101 guide.

**For ElRobot — NormaCore Station**

Follow [arms/elrobot/README.md](../arms/elrobot/README.md). Station is a single binary. It does not use the SO-101 virtualenv.

- [ ]  Check your laptop: Station runs on **macOS (Apple Silicon)** and **Linux (x86_64 or ARM64)**. Windows is not supported. If your team only has Windows laptops, tell us in #help-technical before the event.
- [ ]  Download Station **v0.1.0-beta.10** (the pin in the ElRobot guide).
- [ ]  Start it once (`./station --web --tcp`, or the NormaCore Station app) and open http://localhost:8889.

**For everyone**

- [ ]  Create a Hugging Face account and a write-access token. Put it in the repo-root `.env` (see `.env.example`). SO-101 scripts read that file. ElRobot recording steps are still TBC.

## 🧰 Your Team Kit

Your team receives **two leader/follower sets: one ElRobot and one LeRobot SO-101**. The arms are pre-assembled; they are not clamped, wired or calibrated. Check the kit with your team lead at handover and report anything missing in #help-hardware.

| Item | Qty per team | Note |
| --- | --- | --- |
| LeRobot SO-101 leader arm + follower arm | 1 + 1 | Pre-assembled, 6 motors each; label them SO-LEADER / SO-FOLLOWER |
| ElRobot leader arm + follower arm | 1 + 1 | Pre-assembled, 7 joints + gripper (8 ST3215 servos each); label them EL-LEADER / EL-FOLLOWER |
| Motor controller boards (serial bus servo drivers, USB) | 4 | One per arm; not yet connected to the arms |
| Power supplies | 4 | One per arm, labelled. **Never swap them: the follower uses 12 V, the leader 5 V.** |
| USB data cables | 4 | Data-capable cables only; charge-only cables won't show the board |
| Table clamps | 8 | To fix each arm to the table |
| Cameras + stands/clamps | 4 | LeRobot SO-101: 1 wrist (on follower) + 1 top view. ElRobot: 1 wrist (on follower) + 1 side/45° view. Label them SO-WRIST / SO-TOP / EL-WRIST / EL-SIDE |
| Powered USB hub + power strip | 2 | The hub mainly carries the cameras; at least 3 sockets per set including laptop |
| Practice kit: fake pizza base and toppings | 1 set | For practice only. Scored runs use a sealed kit. |
| Baking paper, tape | — | New baking paper for every pizza |

**Spare parts are not included.** If something breaks (a motor, cable or board), ask in #help-hardware and staff will bring a replacement.

## 🔧 Milestone 1 — Robot Arms: Clamp, Wire and Calibrate

### LeRobot SO-101

1. **Clamp** the leader and follower arms to the table. Leave room for the camera stands and the pizza workspace.
2. **Wire** each arm's motor cable to its own controller board and label the board (SO-LEADER / SO-FOLLOWER). Connect the arm's own power supply to the board but don't switch it on yet. Leader and follower use differently geared motors, so never swap boards, cables or power supplies between them.
3. **Connect** both boards to the laptop with data cables, then power the arms.
4. **Find the USB ports and calibrate** from `arms/so101`, using the steps in [arms/so101/README.md](../arms/so101/README.md). Write the leader and follower ports and the calibration ids on your card.

Motor IDs are already set on pre-assembled arms. Run `lerobot-setup-motors` only if staff ask you to. Power off before touching motors or cables.

### ElRobot

1. **Clamp** the leader and follower arms to the table.
2. **Wire** each arm's servo cable to its own controller board and label the board (EL-LEADER / EL-FOLLOWER). Connect the arm's own power supply to the board — **12 V for the follower, 5 V for the leader** — but don't switch it on yet. The boards use USB for data only; the motors get power from the supplies.
3. **Connect** both boards to the laptop with data cables, then power the arms.
4. **Identify the buses and calibrate** in Station, using [arms/elrobot/README.md](../arms/elrobot/README.md). Write down which serial is EL-LEADER and which is EL-FOLLOWER. Follower (12 V) uses Auto Calibrate. Leader (5 V) does not: Station disables auto-calibrate below 7 V.

**Teleoperation, recording and dataset export for ElRobot** stay TBC until after the October rehearsal.

<aside>
🎯

**Milestone 1: both LeRobot SO-101 and ElRobot arm sets are clamped, wired and calibrated, and you know their ports and IDs.**

</aside>

## 🔌 Milestone 2 — Cameras Ready (target: 30 min)

1. Mount the cameras and connect them to the powered hub.
2. **SO-101:** from `arms/so101`, run `uv run python scripts/list_cameras.py` (or `lerobot-find-cameras`). Note which index is SO-WRIST and SO-TOP, and write them into `station.env`. If you replug a motor board, list the serial ports again.
3. **ElRobot:** cameras show up in the Station web UI (`usb-video` in `station.yaml`). They do not use the LeRobot camera index. Confirm EL-WRIST and EL-SIDE in http://localhost:8889.

<aside>
🎯

**Milestone 2: SO-101 ports and camera indexes are written down, ElRobot wrist and side views are visible in Station, and a short preview shows the right frames.**

</aside>

## 🎮 Milestone 3 — Leader and Follower Are Synced (target: 15 min)

SO-101 only. ElRobot mirroring is TBC.

1. From `arms/so101`, run `bash scripts/teleoperate.sh` ([setup guide](../arms/so101/README.md)).
2. Move the leader slowly through all joints. The follower must mirror it without jitter or delay. If it doesn't, recalibrate both arms.
3. Open and close the gripper 5 times. The follower gripper must fully open and close.
4. Pick up one pepperoni from the practice kit and drop it into the bin.

<aside>
🎯

**Milestone 3: you can pick and place one topping without stopping the teleoperation.**

</aside>

## 🎥 Milestone 4 — Data Is Recorded (target: 20 min)

SO-101 only. ElRobot dataset export is TBC.

1. Log in to Hugging Face: `hf auth login` (write-access token). Put `HF_USER` in the repo-root `.env`.
2. Choose your repo id using the naming convention: `[TEAM-N]-[TEAM-NAME]-[DATASET-NAME]`, e.g. `07-slice-savers-pepperoni-v1`.
3. From `arms/so101`, record 3 test episodes with `bash scripts/record.sh`. Use one task string (for example "place pepperoni on pizza").
4. Replay one episode (`bash scripts/replay.sh 0`) to confirm it looks right.

<aside>
🎯

**Milestone 4: 3 episodes are stored locally and replay correctly.**

</aside>

## ☁️ Milestone 5 — Sample Data Uploaded to Hugging Face (target: 10 min)

1. Push the dataset: `hf upload`, or a later record with `--dataset.push_to_hub=true`. The starter `record.sh` keeps episodes local.
2. Open the dataset page on the Hub and check the video preview.
3. Send the dataset link in the team channel.

<aside>
🎯

**Milestone 5: the dataset is visible on the Hub with 3 episodes and working video.**

</aside>

## ➡️ After Setup

Continue with data collection (first 30–50 episodes = Milestone 6): [Data collection](data-collection.md).

## 🔎 Troubleshooting

Find your symptom and try the fix. Still stuck? Post in #help-technical (software, data, training) or #help-hardware (arms, cameras), or ask a mentor on site. Include your team name, hardware ID, what you tried, the exact error text and a photo of the setup.

SO-101 detail: [arms/so101/troubleshooting.md](../arms/so101/troubleshooting.md).

### SO-101 — USB and ports

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Port not found | Cable is charge-only, or hub unpowered | Swap the cable; power the hub; replug and run `bash scripts/list_ports.sh` from `arms/so101` |
| `lerobot-find-port` says no difference | Unplugged the PSU, or pressed Enter too soon | Ignore it and use `list_ports.sh`. Unplug the USB cable from the laptop, wait ~2 s |
| Ports change after replug | Different USB slot | Label hub slots; update `arms/so101/station.env` |
| Motor not responding / overload error | Loose servo cable, low power | Reseat the daisy chain cable; check the power supply |
| Arm jitters | Low voltage, bad calibration | Check the supply; recalibrate that arm |
| Arm slides on the table | Not clamped | Use the table clamp |

### ElRobot — bus and power

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Bus missing in Station | Charge-only cable, board unpowered, or no USB permission | Use a data cable; power the matching supply (12 V follower, 5 V leader); on Linux join `dialout` and log out and back in |
| Only one bus with both arms plugged in | Second board not enumerated | Unplug one USB cable to see which serial remains; reseat the other cable |
| Auto Calibrate disabled | Leader is on 5 V | Expected below 7 V. Calibrate the leader by moving joints by hand, then Save |
| Arm jitters or will not hold | Wrong supply, or calibration not saved | Confirm 12 V on the follower and 5 V on the leader; recalibrate that bus |
| Arm slides on the table | Not clamped | Use the table clamp |

### Cameras

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| SO-101 camera index wrong | Order changed | Re-run `scripts/list_cameras.py`; update `station.env` |
| ElRobot view missing | Camera not opened by Station | Check `usb-video` in `station.yaml` and the video panel at http://localhost:8889. Do not use `lerobot-find-cameras` for these |
| Frames dropped or lag | Too many cameras on one USB controller | Lower resolution or fps; move a camera to a different laptop port |
| Image too dark or glare | Lighting, glossy props | Move the lamp; use matte laminated faces |

### Calibration and teleoperation (SO-101)

| Symptom | Fix |
| --- | --- |
| Follower mirrors wrongly | Recalibrate both arms in the same order |
| Gripper does not close fully | Check the gripper limit in calibration; check for obstruction |
| Keyboard control does not work on macOS | Use the leader arm or a gamepad |

## 📚 Official Guides

- [LeRobot — SO-101](https://huggingface.co/docs/lerobot/so101)
- [LeRobot — installation](https://huggingface.co/docs/lerobot/installation)
- [LeRobot — real-world robots](https://huggingface.co/docs/lerobot/il_robots)
- [NormaCore — Station](https://github.com/norma-core/norma-core/tree/main/software/station/bin/station)
- [NormaCore — releases](https://github.com/norma-core/norma-core/releases)
- Event copies: [SO-101 setup](../arms/so101/README.md) · [ElRobot setup](../arms/elrobot/README.md)
