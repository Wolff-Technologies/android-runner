# Organization-level Android runner

Requires a Linux x86_64 host with working `/dev/kvm`, Docker Compose, and sufficient RAM (12 GB recommended).

## Initial registration

1. Copy `.env.example` to `.env` (do not commit it), or configure the same variables in Unraid Docker Manager.
2. Set `GITHUB_ORGANIZATION=Wolff-Technologies`. Set `KVM_GID` using `stat -c '%g' /dev/kvm` (100 on this Unraid host).
3. Open GitHub organization **Settings → Actions → Runners → New runner**. Copy the short-lived organization registration token from the generated `config.sh --token` command into `RUNNER_TOKEN`. **This is not a PAT.**
4. Start the container. It registers once, storing its runner identity in `/home/runner/runner-state`.
5. After successful registration, remove `RUNNER_TOKEN` from the Unraid template or `.env` and restart the container. The existing identity will be reused.
6. Restrict organization runner group access to trusted repositories, such as `opusdei`.

## Persistence on Unraid

Map `/mnt/user/appdata/android-runner/state` to `/home/runner/runner-state` and `/mnt/user/appdata/android-runner/work` to `/home/runner/_work`. Map the device `/dev/kvm` to `/dev/kvm`, and set Docker extra parameters `--group-add=100 --shm-size=2g`. Privileged mode is not required.

Keep the runner-state directory when recreating or upgrading the container. Do not wipe it as part of workspace cleanup. If you remove the runner in GitHub, stop the container, delete its persisted runner-state contents, and register again with a fresh token.

## Running emulator jobs

Trusted workflows in allowed repositories can use `runs-on: [self-hosted, Linux, X64, android-emulator]`.

The emulator is installed but not launched automatically. Start it inside a trusted workflow job:

```bash
emulator -avd ci-android -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -accel on > emulator.log 2>&1 &
wait-for-emulator
```

Run one emulator job at a time. Avoid untrusted pull requests on persistent self-hosted runners. Production hardening and emulator integration testing remain required.
