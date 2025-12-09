#!/bin/bash
set -e

if [[ -z "$GITHUB_URL" || -z "$GITHUB_TOKEN" ]]; then
  echo "ERROR: GITHUB_URL and GITHUB_TOKEN must be set"
  exit 1
fi

if [ -d "/opt/actions-runner/_work" ]; then
  chown -R runner:runner /opt/actions-runner/_work
fi

exec su runner -c '
cd /opt/actions-runner

if [ ! -f .runner ]; then
  echo "Configuring runner..."
  ./config.sh --unattended \
    --url "'"$GITHUB_URL"'" \
    --token "'"$GITHUB_TOKEN"'" \
    --name "$(hostname)" \
    --work _work
fi

cleanup() {
  ./config.sh remove --unattended --token "'"$GITHUB_TOKEN"'"
}
trap cleanup EXIT

./run.sh
'
