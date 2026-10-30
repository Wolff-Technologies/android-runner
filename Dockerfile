FROM ubuntu:24.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG RUNNER_VERSION=2.338.2
ARG RUNNER_SHA256=baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40
ENV DEBIAN_FRONTEND=noninteractive ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk ANDROID_AVD_HOME=/home/runner/.android/avd PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:$PATH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates unzip git jq python3 python3-pip openjdk-17-jdk libglu1-mesa libpulse0 libnss3 libx11-6 libxcb1 libxcomposite1 libxcursor1 libxi6 libxtst6 libxrandr2 libasound2t64 libicu74 libdbus-1-3 libgbm1 libxkbcommon0 && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner && mkdir -p /opt/actions-runner /opt/android-sdk && chown -R runner:runner /opt/actions-runner /opt/android-sdk
WORKDIR /opt/actions-runner
RUN set -eux; \
    curl -fSL --retry 3 "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" -o /tmp/actions-runner.tar.gz; \
    echo "${RUNNER_SHA256}  /tmp/actions-runner.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/actions-runner.tar.gz; \
    rm /tmp/actions-runner.tar.gz; \
    ./bin/installdependencies.sh
RUN curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmd.zip && mkdir -p /opt/android-sdk/cmdline-tools && unzip -q /tmp/cmd.zip -d /opt/android-sdk/cmdline-tools && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && rm /tmp/cmd.zip
RUN yes | sdkmanager --licenses >/dev/null || test "${PIPESTATUS[1]}" -eq 0
RUN sdkmanager "platform-tools" "emulator" "platforms;android-35" "system-images;android-35;google_apis;x86_64" && chown -R runner:runner /opt/android-sdk
COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY --chmod=755 wait-for-emulator.sh /usr/local/bin/wait-for-emulator
USER runner
# Install Maestro once in the runner image instead of downloading it per CI job.
ENV PATH=/home/runner/.maestro/bin:$PATH
RUN curl -fsSL https://get.maestro.mobile.dev | bash
ENTRYPOINT ["/entrypoint.sh"]
