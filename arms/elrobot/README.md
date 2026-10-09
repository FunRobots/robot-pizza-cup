# ElRobot + NormaCore Station

This directory is the ElRobot setup. Station is a single binary. It does not use the LeRobot `uv` environment in [arms/so101](../so101/README.md).

Pinned release: **v0.1.0-beta.10**.

Upstream: [NormaCore Station](https://github.com/norma-core/norma-core/tree/main/software/station/bin/station) · [releases](https://github.com/norma-core/norma-core/releases)

Event-day clamp and wiring: [Hardware and software](../../docs/04-hardware-and-soft.md).

Teleoperation, recording, and dataset export are not documented here yet. Station can mirror a leader bus to a follower bus; the event steps are TBC after the October rehearsal.

---

## 0. What you need

| Item | Notes |
| --- | --- |
| ElRobot follower + leader | 7 joints + gripper (8 ST3215 servos each). Pre-assembled. |
| Power | **12 V follower, 5 V leader.** Never swap supplies. |
| Laptop | **macOS (Apple Silicon)** or **Linux (x86_64 or ARM64)**. Windows is not supported. |
| USB | Data cables, one controller board per arm |

Do not build Station from source for the event. Use the release binary.

---

## 1. Install

Download **v0.1.0-beta.10** from the [releases page](https://github.com/norma-core/norma-core/releases).

| OS | File | What it is |
| --- | --- | --- |
| macOS Apple Silicon | `station-macos-arm64.dmg` | Desktop app. Drag NormaCore Station to Applications. The binary runs in the background. |
| macOS Apple Silicon | `station-macos-arm64.zip` | Command-line archive |
| Linux ARM64 | `station-linux-aarch64.tar.gz` | Command-line archive (Raspberry Pi and other ARM64) |
| Linux x86_64 | `station-linux-x86_64.tar.gz` | Command-line archive (Intel/AMD) |

### Linux USB access

Station needs your user in the `dialout` group to open servo boards without sudo:

```bash
sudo usermod -a -G dialout $USER
```

Log out and back in before you plug in the arms.

### Command-line binary

```bash
# Linux
tar -xzf station-linux-*.tar.gz

# macOS
unzip station-macos-arm64.zip
```

Run it from the directory that contains the binary (or the app on macOS):

```bash
./station --web --tcp
```

| Flag | Listens on |
| --- | --- |
| `--web` | `0.0.0.0:8889` (browser UI) |
| `--tcp` | `0.0.0.0:8888` (normfs TCP) |

Open http://localhost:8889. You should see the Station web interface.

The first run writes `station.yaml` next to the binary. A commented starter is [station.yaml.example](station.yaml.example). History defaults to `./station_data` (`--normfs-base-folder`).

```bash
./station --help
./station --config station.yaml --web --tcp
```

Useful flags:

| Flag | Default | Role |
| --- | --- | --- |
| `--config` | `station.yaml` | Driver and camera settings |
| `--normfs-base-folder` | `./station_data` | Stored history |
| `--max-queue-disk-size` | `2G` | Queue disk cap |
| `--max-memory-usage` | `256M` | In-memory buffer cap |

---

## 2. Clamp, wire, and identify the buses

1. Clamp the leader and follower to the table.
2. Wire each arm's servo cable to its own controller board. Label the boards EL-LEADER and EL-FOLLOWER.
3. Connect each arm's own power supply — **12 V follower, 5 V leader** — and leave it off until the data cables are in.
4. Connect both boards with USB data cables, then power the arms. USB does not power the motors.
5. Start Station and open http://localhost:8889. Each arm is a servo bus named by the controller board serial number. Each bus should show **8 servos**. Unplug one USB cable to see which serial is the leader and which is the follower. Write both serials down.

---

## 3. Calibrate

Click the arm's bus to open **Calibrating Bus: [serial]**. Opening this page resets that arm's calibration.

1. **Move every joint by hand through its full range,** including the gripper. Keep moving until Station has seen each joint move far enough.
2. **Follower (12 V): click Auto Calibrate.** The arm moves each joint to its mechanical stop, one joint at a time. Clear the workspace, keep hands out, and keep one person at the power switch. Click **Stop Calibration** to abort.
3. **Leader (5 V): skip Auto Calibrate.** Station disables it below 7 V and shows a low-voltage warning. That is expected. The ranges from step 1 are the calibration.
4. **Click Save.** The 3D view should follow your moves, and every motor should travel from 0% to 100%. Then click **Done**. Station locks the calibration.
5. If calibration fails: click **Reset**, then repeat, or calibrate by hand only (step 1, then Save).

Confirm this routine at the October rehearsal before teams rely on it.

---

## 4. Cameras

ElRobot cameras are UVC devices inside Station (`usb-video` in `station.yaml`). They do not appear in `lerobot-find-cameras`.

With `resolution: auto`, Station picks a format. An explicit `1280x720` is used only if the camera offers that size. `resize_target` is the stored frame size and is separate from capture resolution. `frame-skip` thins both the recording and the live preview.

Check the wrist and side views in the web UI at http://localhost:8889.
