# GitHub Actions Runner - Docker
# ================================

-include .env

IMAGE_NAME ?= $(DOCKER_IMAGE)
IMAGE_NAME ?= actions-runner-docker
CONTAINER_NAME := github-runner
RUNNER_VERSION ?= 2.330.0

.PHONY: help build up down restart logs shell clean status env push

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build:
	@echo "Building image: $(IMAGE_NAME) with runner version $(RUNNER_VERSION)"
	docker build --build-arg RUNNER_VERSION=$(RUNNER_VERSION) -t $(IMAGE_NAME) .

up:
	docker compose up -d

down:
	docker compose down

restart: down up

logs:
	docker compose logs -f

logs-tail:
	docker compose logs --tail=100

shell:
	docker exec -it $(CONTAINER_NAME) bash

status:
	@docker ps -a --filter "name=$(CONTAINER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

env:
	@if [ ! -f .env ]; then \
		cp .env_example .env; \
		echo "Created .env file. Please edit it with your values."; \
	else \
		echo ".env file already exists."; \
	fi

clean:
	docker compose down --rmi local -v 2>/dev/null || true
	rm -rf ./runner/_work 2>/dev/null || true
	@echo "Cleaned up successfully."

rebuild: clean build up

push:
	@if [ "$(IMAGE_NAME)" = "actions-runner-docker" ]; then \
		echo "Error: Set DOCKER_IMAGE env var to push to a registry"; \
		echo "Example: DOCKER_IMAGE=ghcr.io/user/actions-runner:tag make push"; \
		exit 1; \
	fi
	docker push $(IMAGE_NAME)
