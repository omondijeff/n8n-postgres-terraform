#!/bin/bash

# Deploy Docker Compose setup locally
docker-compose -f docker/docker-compose.yml up -d

echo "Local Docker Compose setup is up and running."
