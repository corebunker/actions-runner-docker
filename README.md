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
├── Dockerfile           # Ubuntu + GitHub runner
├── docker-compose.yaml  # Container config
├── entrypoint.sh        # Startup script
├── Makefile             # Helper commands
└── _work/               # Job workspace (mounted volume)
```

## Docker-out-of-Docker

This runner exposes the host Docker daemon via `/var/run/docker.sock`, allowing workflows to run containers.

### The Empty Volume Problem

When you run `docker run -v "${{ github.workspace }}:/app" ...` inside a job, the command goes to the **host Docker daemon**. The daemon resolves `-v` paths on the **host filesystem**, not inside the runner container.

If the path doesn't exist on the host, Docker creates an empty directory → your files "disappear".

### Solution: `--volumes-from`

Use `--volumes-from "$(hostname)"` to inherit the runner's mounted volumes:

```yaml
- name: Run pipeline in container
  run: |
    docker run --rm \
      --volumes-from "$(hostname)" \
      -w "${{ github.workspace }}" \
      your-image:tag \
      bash -lc "your-command"
```

Now the nested container sees the same workspace as the runner, with all your files intact.

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
make clean      - Remove containers/volumes
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

**Permission errors:**
```bash
sudo chown -R $USER:$USER ./_work
```

**Container keeps restarting:**
- Token likely expired or already used
- Generate new token and update `.env`

## License

MIT
