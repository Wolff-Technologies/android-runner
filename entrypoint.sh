#!/usr/bin/env bash
set -Eeuo pipefail
: "${GITHUB_ORGANIZATION:?Set GITHUB_ORGANIZATION to your GitHub organization}"
export RUNNER_NAME="${RUNNER_NAME:-android-runner-$(hostname)}"
export RUNNER_LABELS="${RUNNER_LABELS:-android-emulator}"
export RUNNER_WORKDIR="${RUNNER_WORKDIR:-/home/runner/_work}"
state_dir="/home/runner/runner-state"
mkdir -p "$RUNNER_WORKDIR" "$ANDROID_AVD_HOME" "$state_dir"
if ! command -v emulator >/dev/null; then echo "Android emulator missing"; exit 1; fi
if ! avdmanager list avd | grep -q 'Name: ci-android'; then
  echo no | avdmanager create avd -n ci-android -k 'system-images;android-35;google_apis;x86_64' --force
fi
# Preserve runner identity across container restarts and image upgrades.
for file in .runner .credentials .credentials_rsaparams; do
  if [[ -f "$file" && ! -L "$file" && ! -e "$state_dir/$file" ]]; then
    mv "$file" "$state_dir/$file"
  fi
  ln -sfn "$state_dir/$file" "$file"
done
if [[ ! -s "$state_dir/.runner" ]]; then
  : "${RUNNER_TOKEN:?Set RUNNER_TOKEN to a fresh organization runner registration token}"
  ./config.sh --unattended --url "https://github.com/$GITHUB_ORGANIZATION" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" --labels "$RUNNER_LABELS" --work "$RUNNER_WORKDIR" --replace
fi
unset RUNNER_TOKEN
# Do not deregister on shutdown: registration tokens expire after about one hour.
# If GitHub removes this runner, delete its persisted state and supply a fresh token.
exec ./run.sh
