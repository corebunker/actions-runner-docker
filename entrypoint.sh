#!/bin/bash
set -e

if [[ -z "$GITHUB_URL" || -z "$GITHUB_TOKEN" ]]; then
  echo "ERROR: GITHUB_URL and GITHUB_TOKEN must be set"
  exit 1
fi

if [ -n "$Runner_Work_Dir" ]; then
  echo "Using custom work directory: $Runner_Work_Dir"
  if [ ! -d "$Runner_Work_Dir" ]; then
    mkdir -p "$Runner_Work_Dir"
  fi
  chown -R runner:runner "$Runner_Work_Dir"
elif [ -d "/opt/actions-runner/_work" ]; then
  chown -R runner:runner /opt/actions-runner/_work
fi

if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
  if ! getent group docker > /dev/null 2>&1; then
    groupadd -g "$DOCKER_GID" docker
  fi
  usermod -aG docker runner
fi

exec su runner -c '
cd /opt/actions-runner

if [ ! -f .runner ]; then
  echo "Configuring runner..."
  ./config.sh --unattended \
    --url "'"$GITHUB_URL"'" \
    --token "'"$GITHUB_TOKEN"'" \
    --name "$(hostname)" \
    --work "'"${Runner_Work_Dir:-_work}"'" \
    --replace
fi

cleanup() {
  ./config.sh remove --unattended --token "'"$GITHUB_TOKEN"'"
}
trap cleanup EXIT

./run.sh
'
