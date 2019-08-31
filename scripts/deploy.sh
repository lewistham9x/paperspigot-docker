#!/usr/bin/env bash

# Login to docker hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker build -t rmp9x/paperspigot
docker push rmp9x/paperspigot