FROM ubuntu:22.04

ARG RUNNER_VERSION=2.330.0

RUN apt-get update && apt-get install -y \
    curl \
    git \
    tar \
    bash \
    libc6 \
    libssl3 \
    libicu70 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /opt/actions-runner runner

WORKDIR /opt/actions-runner

RUN curl -L -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /opt/actions-runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
