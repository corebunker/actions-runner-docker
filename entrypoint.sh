#!/bin/bash
set -e

if [[ -z "$GITHUB_URL" || -z "$GITHUB_TOKEN" ]]; then
  echo "ERROR: GITHUB_URL and GITHUB_TOKEN must be set"
  exit 1
fi

export RUNNER_NAME="${RUNNER_NAME:-github-runner}"
export RUNNER_WORK_DIR="${Runner_Work_Dir:-${RUNNER_WORK_DIR:-/opt/actions-runner/_work}}"
export Runner_Work_Dir="$RUNNER_WORK_DIR"

echo "Runner name: $RUNNER_NAME"
echo "Using work directory: $RUNNER_WORK_DIR"

if [ ! -d "$RUNNER_WORK_DIR" ]; then
  mkdir -p "$RUNNER_WORK_DIR"
fi
chown -R runner:runner "$RUNNER_WORK_DIR"

# Align docker group GID with the host socket so the runner user can access it
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
  if getent group docker > /dev/null 2>&1; then
    CURRENT_GID=$(getent group docker | cut -d: -f3)
    if [ "$CURRENT_GID" != "$DOCKER_GID" ]; then
      groupmod -g "$DOCKER_GID" docker
    fi
  else
    groupadd -g "$DOCKER_GID" docker
  fi
  usermod -aG docker runner
  echo "Docker socket GID=$DOCKER_GID; runner added to group docker"
fi

# setpriv applies supplementary groups correctly (su often does not)
if command -v setpriv > /dev/null 2>&1; then
  exec setpriv --reuid=runner --regid=runner --init-groups --inh-caps=-all /bin/bash -c '
cd /opt/actions-runner

if [ ! -f .runner ]; then
  echo "Configuring runner..."
  ./config.sh --unattended \
    --url "'"$GITHUB_URL"'" \
    --token "'"$GITHUB_TOKEN"'" \
    --name "'"$RUNNER_NAME"'" \
    --work "'"$RUNNER_WORK_DIR"'" \
    --replace
fi

cleanup() {
  ./config.sh remove --unattended --token "'"$GITHUB_TOKEN"'"
}
trap cleanup EXIT

./run.sh
'
fi

# Fallback if setpriv is unavailable
exec su runner -c '
cd /opt/actions-runner

if [ ! -f .runner ]; then
  echo "Configuring runner..."
  ./config.sh --unattended \
    --url "'"$GITHUB_URL"'" \
    --token "'"$GITHUB_TOKEN"'" \
    --name "'"$RUNNER_NAME"'" \
    --work "'"$RUNNER_WORK_DIR"'" \
    --replace
fi

cleanup() {
  ./config.sh remove --unattended --token "'"$GITHUB_TOKEN"'"
}
trap cleanup EXIT

./run.sh
'
