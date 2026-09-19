#!/usr/bin/env bash
# Build the LeRobot --robot.cameras dict from hardware/station.env.
# Camera keys become dataset features: observation.images.<name>
# Leave CAMERA_INDEX_TOP empty for a single front camera.

opencv_cam() {
  local index="$1"
  echo "{type: opencv, index_or_path: ${index}, width: ${CAMERA_WIDTH}, height: ${CAMERA_HEIGHT}, fps: ${CAMERA_FPS}}"
}

macos_camera_count() {
  system_profiler SPCameraDataType 2>/dev/null | grep -c 'Unique ID:' || true
}

build_cameras_dict() {
  if [[ -z "${CAMERA_INDEX:-}" ]]; then
    echo "CAMERA_INDEX is required in station.env" >&2
    return 1
  fi
  if [[ -n "${CAMERA_INDEX_TOP:-}" && "$CAMERA_INDEX_TOP" == "$CAMERA_INDEX" ]]; then
    echo "CAMERA_INDEX_TOP must differ from CAMERA_INDEX (got ${CAMERA_INDEX} for both)." >&2
    return 1
  fi
  # FaceTime + one USB = 2 devices. Using the leftover index records the laptop camera.
  if [[ "$(uname)" == "Darwin" && -n "${CAMERA_INDEX_TOP:-}" ]]; then
    local n
    n="$(macos_camera_count)"
    if [[ "$n" -lt 3 ]]; then
      echo "macOS lists ${n} camera(s); CAMERA_INDEX_TOP=${CAMERA_INDEX_TOP} is almost certainly FaceTime." >&2
      echo "Plug in the overhead USB camera until system_profiler SPCameraDataType shows a third device, then re-run list_cameras.py." >&2
      return 1
    fi
  fi

  local dict="{ front: $(opencv_cam "$CAMERA_INDEX")"
  if [[ -n "${CAMERA_INDEX_TOP:-}" ]]; then
    dict+=", top: $(opencv_cam "$CAMERA_INDEX_TOP")"
  fi
  dict+=" }"
  echo "$dict"
}

camera_count() {
  if [[ -n "${CAMERA_INDEX_TOP:-}" ]]; then
    echo 2
  else
    echo 1
  fi
}
