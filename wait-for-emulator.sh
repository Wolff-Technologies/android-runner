#!/usr/bin/env bash
set -Eeuo pipefail
timeout="${ANDROID_BOOT_TIMEOUT:-300}"
adb wait-for-device
start=$SECONDS
while (( SECONDS - start < timeout )); do
  if [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]; then
    adb shell input keyevent 82 || true
    echo "Android emulator booted"
    exit 0
  fi
  sleep 5
done
adb devices -l || true
echo "Emulator boot timed out" >&2
exit 1
