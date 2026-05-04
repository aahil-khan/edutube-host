#!/usr/bin/env bash
set -euo pipefail

# Scale frontend and backend for load testing while keeping DB and Redis singletons.
# Usage: bash tools/scale-for-load.sh [backend_instances] [frontend_instances]

BACKEND=${1:-2}
FRONTEND=${2:-2}

echo "Scaling backend to $BACKEND and frontend to $FRONTEND (postgres/redis remain 1)"

docker-compose up -d --build --scale backend="$BACKEND" --scale frontend="$FRONTEND"

echo "Scaled. Use 'docker-compose ps' to verify containers and 'docker-compose logs -f' to monitor."
