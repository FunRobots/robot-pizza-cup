# Camera setup

Hackathon V1 scoring uses a **fixed front RGB camera**. You can also record a second **overhead (`top`)** stream at the same time; both become part of the dataset schema.

| Setting | Value |
| --- | --- |
| Resolution | 640 × 480 minimum |
| FPS | 30 |
| Mount | fixed, same viewpoint on every station |
| Front camera | required (`observation.images.front`) |
| Overhead camera | optional (`observation.images.top`) |
| Wrist camera | not part of V1 scoring |

## Find camera indexes

```bash
uv run python scripts/list_cameras.py
```

This prints every OpenCV index that opens and writes a JPEG to `/tmp/lerobot-cameras/index-N.jpg`. Open those stills to tell FaceTime vs workspace vs overhead.

On macOS, OpenCV indexes are **0 … N−1** for the N devices in `system_profiler SPCameraDataType`. There is no index `2` until a third camera actually appears. ffmpeg’s `[2] Capture screen 0` is a screen grab, not a webcam.

Index `0` is often the built-in FaceTime camera, but it can swap with a USB cam. Always check the preview JPEGs. Prefer USB webcams for `front` and `top`; never record FaceTime.

Set indexes from the preview JPEGs, not by guessing the next integer:

```bash
CAMERA_INDEX=0          # USB workspace (example)
CAMERA_INDEX_TOP=       # empty until a second USB camera appears in system_profiler
```

Leave `CAMERA_INDEX_TOP` empty for a single front camera.

Quit Zoom, Photo Booth, and Chrome before listing or recording — they hold the webcam exclusive.

## Framing checklist

You should be able to do the task **from the camera images alone**:

**Front**

- pizza disk fully in frame
- topping pickup zone fully in frame
- gripper visible throughout the motion

**Top** (if used)

- full table / pizza / pickup zone from above
- arm does not occlude the pizza for the whole place motion

Shared:

- no motion blur at 30 FPS
- lighting is diffuse and stable (no moving shadows)
- do not move either camera after recording starts

## LeRobot camera dict

`scripts/record.sh`, `teleoperate.sh`, and `rollout.sh` expand `hardware/station.env` into:

```text
{ front: {type: opencv, index_or_path: <CAMERA_INDEX>, width: 640, height: 480, fps: 30},
  top:   {type: opencv, index_or_path: <CAMERA_INDEX_TOP>, width: 640, height: 480, fps: 30} }
```

Camera **names** (`front`, `top`) are part of the dataset schema. Record, train, and rollout must use the same keys.

- Adding `top` to an existing front-only dataset will fail — bump `DATASET_NAME` in `.env` (e.g. `pizza_hack_v2`) and start a new dataset.
- A policy trained on `{front, top}` must see **both** cameras at rollout.

Confirm both feeds in Rerun before recording:

```bash
bash scripts/teleoperate.sh
```
