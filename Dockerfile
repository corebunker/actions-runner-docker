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
    ca-certificates \
    gnupg \
    lsb-release \
    tree \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /opt/actions-runner runner \
    && usermod -aG docker runner || true

WORKDIR /opt/actions-runner

# Github Runner
RUN curl -L -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /opt/actions-runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /opt/actions-runner/_work \
    && chown -R runner:runner /opt/actions-runner/_work

ENTRYPOINT ["/entrypoint.sh"]
