#!/usr/bin/env bash
set -Eeuo pipefail
: "${GITHUB_ORGANIZATION:?Set GITHUB_ORGANIZATION to your GitHub organization}"
: "${GH_PAT:?Set GH_PAT to a token authorized to manage organization self-hosted runners}"
export RUNNER_NAME="${RUNNER_NAME:-android-runner-$(hostname)}"
export RUNNER_LABELS="${RUNNER_LABELS:-android-emulator}"
export RUNNER_WORKDIR="${RUNNER_WORKDIR:-/home/runner/_work}"
mkdir -p "$RUNNER_WORKDIR" "$ANDROID_AVD_HOME"
if ! command -v emulator >/dev/null; then echo "Android emulator missing"; exit 1; fi
echo no | avdmanager create avd -n ci-android -k 'system-images;android-35;google_apis;x86_64' --force
api="https://api.github.com/orgs/$GITHUB_ORGANIZATION/actions/runners"
github_token() {
  curl -fsS -X POST -H "Authorization: Bearer $GH_PAT" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$api/$1" | jq -er .token
}
cleanup() {
  trap - EXIT INT TERM
  if [[ -f .runner ]]; then
    token=$(github_token remove-token) && ./config.sh remove --unattended --token "$token" || true
  fi
}
trap cleanup EXIT
./config.sh --unattended --url "https://github.com/$GITHUB_ORGANIZATION" --token "$(github_token registration-token)" --name "$RUNNER_NAME" --labels "$RUNNER_LABELS" --work "$RUNNER_WORKDIR" --replace
./run.sh &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; cleanup; exit 143' INT TERM
wait "$pid"
