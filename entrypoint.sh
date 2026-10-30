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
# Restore existing registration before starting the listener.
for file in .runner .credentials .credentials_rsaparams; do
  if [[ -L "$file" ]]; then rm "$file"; fi
  if [[ -f "$state_dir/$file" ]]; then cp -p "$state_dir/$file" "$file"; fi
done
if [[ ! -s .runner || ! -s .credentials || ! -s .credentials_rsaparams ]]; then
  : "${RUNNER_TOKEN:?Set RUNNER_TOKEN to a fresh organization registration token}"
  # config.sh must create regular files; symlinks to nonexistent credentials break registration.
  rm -f .runner .credentials .credentials_rsaparams
  ./config.sh --unattended --url "https://github.com/$GITHUB_ORGANIZATION" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" --labels "$RUNNER_LABELS" --work "$RUNNER_WORKDIR" --replace
  for file in .runner .credentials .credentials_rsaparams; do
    test -s "$file" || { echo "Registration missing $file"; exit 1; }
    cp -p "$file" "$state_dir/$file"
  done
fi
unset RUNNER_TOKEN
# Credentials remain in the persistent state volume; restarting needs no new token.
exec ./run.sh
