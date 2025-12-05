# GitHub Actions Runner in Docker

A self-hosted GitHub Actions runner that runs in Docker. Built using only the official GitHub runner binaries - no third-party images.

Works on any Linux host, including Alpine (uses Ubuntu inside the container for glibc compatibility).

## What you need

- Docker
- Docker Compose v2
- A GitHub runner token

## Getting started

### 1. Clone and setup

```bash
git clone https://github.com/YOUR_USER/actions-runner-docker.git
cd actions-runner-docker
make env
```

Edit the `.env` file with your values.

### 2. Configure your runner

For **organization runners** (available to all repos in the org):

```env
GITHUB_URL=https://github.com/your-org
GITHUB_TOKEN=YOUR_TOKEN_HERE
```

For **repository runners** (specific to one repo):

```env
GITHUB_URL=https://github.com/user/repo
GITHUB_TOKEN=YOUR_TOKEN_HERE
```

**Getting a token:**
- Repository: Settings → Actions → Runners → New self-hosted runner
- Organization: Settings → Actions → Runners → New runner

### 3. Build and run

```bash
make build
make up
```

That's it. Check the logs with `make logs` to see if it connected.

## Building for a registry

If you want to push the image to GitHub Container Registry or Docker Hub, set the image name in your `.env`:

```env
DOCKER_IMAGE=ghcr.io/your-org/actions-runner:v1.0.0
```

Then:

```bash
make build
make push
```

You can also override the runner version:

```bash
RUNNER_VERSION=2.330.0 make build
```

## Available commands

```
make build      - Build the image
make up         - Start the runner
make down       - Stop the runner
make restart    - Restart the runner
make logs       - Follow logs
make logs-tail  - Show last 100 lines
make shell      - Open shell in container
make status     - Show container status
make clean      - Remove everything
make rebuild    - Clean + build + start
make push       - Push to registry
```

## Project structure

```
actions-runner-docker/
├── Dockerfile           - Ubuntu image with GitHub runner
├── docker-compose.yaml  - Container config
├── entrypoint.sh        - Startup script
├── Makefile             - Commands
├── .env_example         - Template
└── runner/              - Runner data (created on first run)
```

## How it works

When you start the container:
1. It validates your `GITHUB_URL` and `GITHUB_TOKEN`
2. Registers the runner with GitHub
3. Starts listening for jobs
4. When you stop it, it unregisters automatically

## Advanced stuff

### Custom runner name

Edit `entrypoint.sh` and change the `--name` parameter:

```bash
--name "my-runner" \
```

### Multiple runners

Add more services to `docker-compose.yaml`:

```yaml
services:
  runner-1:
    image: actions-runner-docker
    container_name: github-runner-1
    environment:
      GITHUB_URL: "${GITHUB_URL}"
      GITHUB_TOKEN: "${GITHUB_TOKEN_1}"
    volumes:
      - ./runner-1:/home/runner

  runner-2:
    image: actions-runner-docker
    container_name: github-runner-2
    environment:
      GITHUB_URL: "${GITHUB_URL}"
      GITHUB_TOKEN: "${GITHUB_TOKEN_2}"
    volumes:
      - ./runner-2:/home/runner
```

### Docker-in-Docker

If your workflows need Docker, mount the socket:

```yaml
volumes:
  - ./runner:/home/runner
  - /var/run/docker.sock:/var/run/docker.sock
```

## Common issues

**Runner not showing up in GitHub:**
- Check if the token is valid (they expire and are single-use)
- Look at the logs: `make logs`
- Try regenerating the token

**Permission errors:**
```bash
sudo chown -R $USER:$USER ./runner
```

**Container keeps restarting:**

The runner might be registered elsewhere. Clean it up:

```bash
make down
rm -rf ./runner/.runner
make up
```

## License

MIT - do whatever you want with it.
