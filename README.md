# GitHub Actions Runner in Docker

Self-hosted GitHub Actions runner using official GitHub runner binaries. No third-party images.

The runner is **ephemeral**: it registers on startup and automatically unregisters when the container stops.

## Quick Start

```bash
git clone https://github.com/codebunker/actions-runner-docker.git
cd actions-runner-docker
make env
```

Edit `.env` with your GitHub URL and token:

```env
GITHUB_URL=https://github.com/your-org        # or https://github.com/user/repo
GITHUB_TOKEN=YOUR_TOKEN_HERE
```

**Getting a token:**
- Repository: Settings → Actions → Runners → New self-hosted runner
- Organization: Settings → Actions → Runners → New runner

Build and start:

```bash
make build
make up
make logs  # Check if connected
```

## Project Structure

```
actions-runner-docker/
├── Dockerfile           # Ubuntu + GitHub runner + docker-job helper
├── docker-compose.yaml  # Container config (DooD)
├── entrypoint.sh        # Startup: register, docker GID, run
├── scripts/docker-job   # Safe docker run wrapper for workflows
├── Makefile             # Helper commands
└── _work/               # Job workspace (same path on host and container)
```

## Docker-out-of-Docker (DooD)

This runner mounts the **host** Docker socket (`/var/run/docker.sock`). Workflows talk to the host daemon — not a nested dockerd.

```
Host Docker daemon
  └── github-runner (CLI + socket)
        └── job containers
              └── optional 3rd-layer containers
```

### Why the work path must match

`-v` and Compose bind mounts are resolved on the **host**. The workspace path inside the runner must be the **same absolute path** on the host.

Default (already configured):

```text
/srv/actions-runner-docker/_work  →  /srv/actions-runner-docker/_work
```

Override with `RUNNER_WORK_DIR` in `.env` if you install elsewhere — keep host and container identical.

### Running containers from a job

**Recommended** — use the built-in helper (injects `--volumes-from` + socket):

```yaml
- name: Run pipeline in container
  run: |
    docker-job your-image:tag bash -lc "your-command"
```

**Manual equivalent:**

```yaml
- name: Run pipeline in container
  run: |
    docker run --rm \
      --volumes-from github-runner \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -w "${{ github.workspace }}" \
      your-image:tag \
      bash -lc "your-command"
```

`--volumes-from github-runner` is required so nested containers see the same workspace files. Without it, Docker may create an **empty** host directory and your files “disappear”.

### Third layer (container that also runs Docker)

`docker-job` already mounts the socket. If you call `docker run` yourself, pass both:

```bash
docker run --rm \
  --volumes-from github-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w "${{ github.workspace }}" \
  your-image:tag \
  bash -lc "docker build -t app . && docker run --rm app"
```

### Compose in the repo

With matching work paths, relative binds like `.:/app` resolve to the same host path and work as expected when you run compose from `${{ github.workspace }}`.

### Avoid

- Job-level `container:` on self-hosted DooD runners (different isolation; often breaks socket/workspace)
- Bind-mounting paths that exist only inside an intermediate container
- Assuming paths inside a nested container exist on the host without `--volumes-from` or a matching absolute path

## Available Commands

```
make build      - Build the runner image
make up         - Start the runner
make down       - Stop the runner
make restart    - Restart the runner
make logs       - Follow logs
make logs-tail  - Show last 100 lines
make shell      - Open bash in runner
make status     - Show container status
make env        - Create .env from template
make clean      - Remove containers/volumes/work dir
make rebuild    - clean + build + up
make push       - Push to registry (set DOCKER_IMAGE in .env)
```

## Push to Registry (Optional)

Set the image name in `.env`:

```env
DOCKER_IMAGE=ghcr.io/your-org/actions-runner:v1.0.0
```

Then:

```bash
make build
make push
```

Override runner version:

```bash
RUNNER_VERSION=2.330.0 make build
```

## Common Issues

**Runner not showing up in GitHub:**
- Check if token is valid (they expire and are single-use)
- View logs: `make logs`
- Regenerate token

**Permission denied on docker.sock:**
- The entrypoint aligns the `docker` group GID with the host socket
- Rebuild/restart after pulling these changes: `make rebuild`

**Empty volumes / missing workspace files:**
- Use `docker-job` or `--volumes-from github-runner`
- Confirm `RUNNER_WORK_DIR` is the same absolute path on host and container

**Container keeps restarting:**
- Token likely expired or already used
- Generate new token and update `.env`

## License

MIT
