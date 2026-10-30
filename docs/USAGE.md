# Organization-level Android runner

Requires a Linux x86_64 host with working `/dev/kvm`, Docker Compose, and sufficient RAM (12 GB recommended).

1. Copy `.env.example` to `.env`. Do not commit `.env`.
2. Set `KVM_GID` from `stat -c '%g' /dev/kvm` (100 on the configured Unraid host).
3. Set `GITHUB_ORGANIZATION` to your GitHub organization, e.g. `Wolff-Technologies`.
4. Supply `GH_PAT` securely. The token must have **organization Self-hosted runners: Read and write** permission (fine-grained PAT) or `admin:org` for a classic PAT, subject to organization policies. The token is used to request short-lived registration and removal tokens.
5. Run `docker compose up -d --build`.
6. In the GitHub organization, configure **Settings → Actions → Runners → Runner groups** to restrict repository access to trusted repositories such as `opusdei`.

Trusted workflows in permitted repositories can use `runs-on: [self-hosted, Linux, X64, android-emulator]`.

This image installs the emulator but does not launch it automatically. Start it during a trusted workflow job:
```bash
emulator -avd ci-android -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -accel on > emulator.log 2>&1 &
wait-for-emulator
```

Use one emulator job at a time. Do not execute untrusted PR code on a persistent organization runner. Restrict runner groups, rotate credentials, and clean the workspace between jobs. Production hardening and emulator integration testing remain required.
