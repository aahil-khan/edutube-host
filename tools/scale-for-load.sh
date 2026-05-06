#!/usr/bin/env bash
set -euo pipefail

# Scale frontend and backend for load testing while keeping DB and Redis singletons.
# Usage: bash tools/scale-for-load.sh [backend_instances] [frontend_instances]

BACKEND=${1:-2}
FRONTEND=${2:-2}

if docker compose version >/dev/null 2>&1; then
	DC="docker compose"
else
	DC="docker-compose"
fi

echo "Scaling backend to $BACKEND and frontend to $FRONTEND (postgres/redis remain 1)"

$DC up -d --build --scale backend="$BACKEND" --scale frontend="$FRONTEND"

echo "Refreshing backend/frontend load balancers"
$DC up -d --force-recreate backend-lb frontend-lb

echo "Scaled. Use 'docker-compose ps' to verify containers and 'docker-compose logs -f' to monitor."
